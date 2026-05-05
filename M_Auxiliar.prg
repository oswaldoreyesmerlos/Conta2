/*
 * ARCHIVO  : M_Auxiliar.prg
 * PROPOSITO: Mantenimiento de tablas auxiliares del sistema.
 *
 * FUNCIONES PUBLICAS
 * ------------------
 *   M_Familias()   - ABM de familias de articulos
 *   M_FormaPago()  - ABM de formas de pago
 *   M_TiposIva()   - ABM de tipos de IVA
 *   M_CCostes()    - ABM de centros de coste
 */

#include "OOp.ch"


// ============================================================================
// M_Familias()
// ============================================================================
FUNCTION M_Familias()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL aData

    IF !ABRIR_TABLA( "FAMILIAS", "FAM", "FAM_COD" )
        RETURN NIL
    ENDIF

    aData := _FamCargar()

    oWin  := TWindow():New( 3, 10, 34, 119, "FAMILIAS DE ARTICULOS" )
    oGrid := TGrid():New( 2, 2, 26, 106, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 1

    oGrid:AddColumn( "Codigo",      5, "@!",     { |a| a[1] } )
    oGrid:AddColumn( "Descripcion",30, "@!",     { |a| a[2] } )
    oGrid:AddColumn( "IVA Def",     7, "@!",     { |a| a[3] } )
    oGrid:AddColumn( "Cta.Venta",  10, "@!",     { |a| a[4] } )
    oGrid:AddColumn( "Cta.Compra", 10, "@!",     { |a| a[5] } )
    oGrid:AddColumn( "Margen %",    8, "99.99",  { |a| a[6] } )
    oGrid:AddColumn( "Baja",        4, "@!",     { |a| If( a[7], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        _FamForm( g:CurrentRow(), .F. ), ;
        aData := _FamCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oBtNvo := TButton():New( 28, 2, 29, 18, oWin, "NUEVO (F5)", ;
        {|| _FamForm( NIL, .T. ), ;
            aData := _FamCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 28, 88, 29, 104, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    FAM->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _FamCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "FAM" )
    OrdSetFocus( "FAM_COD" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( FAM->CODIGO  ), ;
                AllTrim( FAM->DESCRIP ), ;
                AllTrim( FAM->DEF_IVA ), ;
                AllTrim( FAM->CTA_VTA ), ;
                AllTrim( FAM->CTA_COM ), ;
                FAM->MARGEN, ;
                FAM->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _FamForm( aFila, lNuevo )

    LOCAL oWin
    LOCAL oGetCod
    LOCAL oGetDes
    LOCAL oGetIva
    LOCAL oGetVta
    LOCAL oGetCom
    LOCAL oGetMar
    LOCAL oChkBaj
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL cCodigo
    LOCAL cDescri
    LOCAL cIva
    LOCAL cCtaVta
    LOCAL cCtaCom
    LOCAL nMargen
    LOCAL lBaja
    LOCAL cTit

    DEFAULT lNuevo TO .F.

    cCodigo := Space(  3 )
    cDescri := Space( 30 )
    cIva    := Space(  1 )
    cCtaVta := Space( 10 )
    cCtaCom := Space( 10 )
    nMargen := 0.00
    lBaja   := .F.

    IF !lNuevo .AND. aFila != NIL
        cCodigo := PadR( aFila[1], 3  )
        cDescri := PadR( aFila[2], 30 )
        cIva    := PadR( aFila[3], 1  )
        cCtaVta := PadR( aFila[4], 10 )
        cCtaCom := PadR( aFila[5], 10 )
        nMargen := aFila[6]
        lBaja   := aFila[7]
    ENDIF

    cTit := If( lNuevo, "NUEVA FAMILIA", "EDITAR FAMILIA" )

    oWin := TWindow():New( 8, 30, 28, 100, cTit )

    oWin:AddCtrl( TLabel():New(  2, 3, "Codigo      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 3, "Descripcion :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 3, "Tipo IVA    :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 3, "Cta. Venta  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10, 3, "Cta. Compra :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12, 3, "Margen %    :", oWin ) )

    oGetCod := TGet():New(  2, 17, cCodigo, "@!",    oWin )
    oGetCod:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    IF !lNuevo
        oGetCod:lEnabled := .F.
    ENDIF

    oGetDes := TGet():New(  4, 17, cDescri, "@!", oWin )
    oGetDes:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGetIva := TGet():New(  6, 17, cIva,    "@!", oWin )
    oGetVta := TGet():New(  8, 17, cCtaVta, "@!", oWin )
    oGetCom := TGet():New( 10, 17, cCtaCom, "@!", oWin )
    oGetMar := TGet():New( 12, 17, nMargen, "99.99", oWin )

    oChkBaj := TCheck():New( 14, 17, "Baja", lBaja, oWin )

    oBtGua := TButton():New( 16, 10, 17, 26, oWin, "GUARDAR", ;
        {|| _FamGuardar( oGetCod, oGetDes, oGetIva, oGetVta, ;
                         oGetCom, oGetMar, oChkBaj, lNuevo, oWin ) } )

    oBtCan := TButton():New( 16, 30, 17, 46, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGetCod )
    oWin:AddCtrl( oGetDes )
    oWin:AddCtrl( oGetIva )
    oWin:AddCtrl( oGetVta )
    oWin:AddCtrl( oGetCom )
    oWin:AddCtrl( oGetMar )
    oWin:AddCtrl( oChkBaj )
    oWin:AddCtrl( oBtGua  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _FamGuardar( oGC, oGD, oGI, oGV, oGCo, oGM, oChk, lNuevo, oWin )

    LOCAL cCod

    cCod := AllTrim( oGC:uVar )

    DbSelectArea( "FAM" )
    OrdSetFocus( "FAM_COD" )

    IF lNuevo
        IF DbSeek( cCod )
            MsgStop( "El codigo " + cCod + " ya existe.", "Alta" )
            RETURN NIL
        ENDIF
        IF !NetFLock()
            RETURN NIL
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCod )
            RETURN NIL
        ENDIF
        IF !NetRLock()
            RETURN NIL
        ENDIF
    ENDIF

    REPLACE FAM->CODIGO  WITH AllTrim( oGC:uVar  )
    REPLACE FAM->DESCRIP WITH AllTrim( oGD:uVar  )
    REPLACE FAM->DEF_IVA WITH AllTrim( oGI:uVar  )
    REPLACE FAM->CTA_VTA WITH AllTrim( oGV:uVar  )
    REPLACE FAM->CTA_COM WITH AllTrim( oGCo:uVar )
    REPLACE FAM->MARGEN  WITH oGM:uVar
    REPLACE FAM->BAJA    WITH oChk:lValue

    DbUnlock()
    oWin:Close()

RETURN NIL


// ============================================================================
// M_FormaPago()
// ============================================================================
FUNCTION M_FormaPago()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL aData

    IF !ABRIR_TABLA( "FORMAPAGO", "FP", "FP_COD" )
        RETURN NIL
    ENDIF

    aData := _FPCargar()

    oWin  := TWindow():New( 3, 10, 30, 100, "FORMAS DE PAGO" )
    oGrid := TGrid():New( 2, 2, 22, 87, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Codigo",      5, "@!",  { |a| a[1] } )
    oGrid:AddColumn( "Descripcion",30, "@!",  { |a| a[2] } )
    oGrid:AddColumn( "Dias",        4, "999", { |a| a[3] } )
    oGrid:AddColumn( "Num.Pagos",   9, "99",  { |a| a[4] } )
    oGrid:AddColumn( "Cta.Cobro",  10, "@!",  { |a| a[5] } )
    oGrid:AddColumn( "Baja",        4, "@!",  { |a| If( a[6], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        _FPForm( g:CurrentRow(), .F. ), ;
        aData := _FPCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oBtNvo := TButton():New( 24, 2, 25, 18, oWin, "NUEVO (F5)", ;
        {|| _FPForm( NIL, .T. ), ;
            aData := _FPCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 24, 71, 25, 85, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    FP->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _FPCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "FP" )
    OrdSetFocus( "FP_COD" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( FP->CODIGO  ), ;
                AllTrim( FP->DESCRIP ), ;
                FP->DIAS, ;
                FP->NUM_PAGS, ;
                AllTrim( FP->CTA_COB ), ;
                FP->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _FPForm( aFila, lNuevo )

    LOCAL oWin
    LOCAL oGetCod
    LOCAL oGetDes
    LOCAL oGetDia
    LOCAL oGetNPa
    LOCAL oGetCta
    LOCAL oChkBaj
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL cCodigo
    LOCAL cDescri
    LOCAL nDias
    LOCAL nNPagos
    LOCAL cCtaCob
    LOCAL lBaja
    LOCAL cTit

    DEFAULT lNuevo TO .F.

    cCodigo := Space(  3 )
    cDescri := Space( 30 )
    nDias   := 0
    nNPagos := 1
    cCtaCob := Space( 10 )
    lBaja   := .F.

    IF !lNuevo .AND. aFila != NIL
        cCodigo := PadR( aFila[1], 3  )
        cDescri := PadR( aFila[2], 30 )
        nDias   := aFila[3]
        nNPagos := aFila[4]
        cCtaCob := PadR( aFila[5], 10 )
        lBaja   := aFila[6]
    ENDIF

    cTit := If( lNuevo, "NUEVA FORMA DE PAGO", "EDITAR FORMA DE PAGO" )

    oWin := TWindow():New( 8, 30, 27, 95, cTit )

    oWin:AddCtrl( TLabel():New(  2, 3, "Codigo      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 3, "Descripcion :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 3, "Dias pago   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 3, "Num. pagos  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10, 3, "Cta. cobro  :", oWin ) )

    oGetCod := TGet():New(  2, 17, cCodigo, "@!",  oWin )
    oGetCod:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    IF !lNuevo
        oGetCod:lEnabled := .F.
    ENDIF

    oGetDes := TGet():New(  4, 17, cDescri, "@!",  oWin )
    oGetDes:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGetDia := TGet():New(  6, 17, nDias,   "999", oWin )
    oGetNPa := TGet():New(  8, 17, nNPagos, "99",  oWin )
    oGetCta := TGet():New( 10, 17, cCtaCob, "@!",  oWin )

    oChkBaj := TCheck():New( 12, 17, "Baja", lBaja, oWin )

    oBtGua := TButton():New( 14, 8, 15, 24, oWin, "GUARDAR", ;
        {|| _FPGuardar( oGetCod, oGetDes, oGetDia, oGetNPa, ;
                        oGetCta, oChkBaj, lNuevo, oWin ) } )

    oBtCan := TButton():New( 14, 28, 15, 44, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGetCod )
    oWin:AddCtrl( oGetDes )
    oWin:AddCtrl( oGetDia )
    oWin:AddCtrl( oGetNPa )
    oWin:AddCtrl( oGetCta )
    oWin:AddCtrl( oChkBaj )
    oWin:AddCtrl( oBtGua  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _FPGuardar( oGC, oGD, oGDi, oGN, oGCt, oChk, lNuevo, oWin )

    LOCAL cCod

    cCod := AllTrim( oGC:uVar )

    DbSelectArea( "FP" )
    OrdSetFocus( "FP_COD" )

    IF lNuevo
        IF DbSeek( cCod )
            MsgStop( "El codigo " + cCod + " ya existe.", "Alta" )
            RETURN NIL
        ENDIF
        IF !NetFLock()
            RETURN NIL
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCod )
            RETURN NIL
        ENDIF
        IF !NetRLock()
            RETURN NIL
        ENDIF
    ENDIF

    REPLACE FP->CODIGO   WITH AllTrim( oGC:uVar  )
    REPLACE FP->DESCRIP  WITH AllTrim( oGD:uVar  )
    REPLACE FP->DIAS     WITH oGDi:uVar
    REPLACE FP->NUM_PAGS WITH oGN:uVar
    REPLACE FP->CTA_COB  WITH AllTrim( oGCt:uVar )
    REPLACE FP->BAJA     WITH oChk:lValue

    DbUnlock()
    oWin:Close()

RETURN NIL


// ============================================================================
// M_TiposIva()
// ============================================================================
FUNCTION M_TiposIva()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL aData

    IF !ABRIR_TABLA( "TIPOSIVA", "IVA", "IVA_COD" )
        RETURN NIL
    ENDIF

    aData := _IVACargar()

    oWin  := TWindow():New( 5, 20, 28, 100, "TIPOS DE IVA" )
    oGrid := TGrid():New( 2, 2, 19, 77, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Cod",         3, "@!",    { |a| a[1] } )
    oGrid:AddColumn( "Descripcion",20, "@!",    { |a| a[2] } )
    oGrid:AddColumn( "% IVA",       6, "99.99", { |a| a[3] } )
    oGrid:AddColumn( "% Rec.Equiv.",11, "99.99", { |a| a[4] } )
    oGrid:AddColumn( "Baja",        4, "@!",    { |a| If( a[5], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        _IVAForm( g:CurrentRow(), .F. ), ;
        aData := _IVACargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oBtNvo := TButton():New( 21, 2, 22, 18, oWin, "NUEVO (F5)", ;
        {|| _IVAForm( NIL, .T. ), ;
            aData := _IVACargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 21, 61, 22, 75, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    IVA->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _IVACargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "IVA" )
    OrdSetFocus( "IVA_COD" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( IVA->CODIGO  ), ;
                AllTrim( IVA->DESCRIP ), ;
                IVA->PORC_IVA, ;
                IVA->PORC_RE, ;
                IVA->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _IVAForm( aFila, lNuevo )

    LOCAL oWin
    LOCAL oGetCod
    LOCAL oGetDes
    LOCAL oGetIva
    LOCAL oGetRe
    LOCAL oChkBaj
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL cCodigo
    LOCAL cDescri
    LOCAL nPIva
    LOCAL nPRe
    LOCAL lBaja
    LOCAL cTit

    DEFAULT lNuevo TO .F.

    cCodigo := Space(  1 )
    cDescri := Space( 20 )
    nPIva   := 0.00
    nPRe    := 0.00
    lBaja   := .F.

    IF !lNuevo .AND. aFila != NIL
        cCodigo := PadR( aFila[1], 1  )
        cDescri := PadR( aFila[2], 20 )
        nPIva   := aFila[3]
        nPRe    := aFila[4]
        lBaja   := aFila[5]
    ENDIF

    cTit := If( lNuevo, "NUEVO TIPO IVA", "EDITAR TIPO IVA" )

    oWin := TWindow():New( 9, 35, 27, 90, cTit )

    oWin:AddCtrl( TLabel():New(  2, 3, "Codigo (G/R/S/E) :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 3, "Descripcion      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 3, "% IVA            :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 3, "% Rec. Equiv.    :", oWin ) )

    oGetCod := TGet():New(  2, 22, cCodigo, "@!", oWin )
    oGetCod:bValid := {| o | AllTrim( o:cBuffer ) $ "GRSE" }
    IF !lNuevo
        oGetCod:lEnabled := .F.
    ENDIF

    oGetDes := TGet():New(  4, 22, cDescri, "@!",    oWin )
    oGetIva := TGet():New(  6, 22, nPIva,   "99.99", oWin )
    oGetRe  := TGet():New(  8, 22, nPRe,    "99.99", oWin )

    oChkBaj := TCheck():New( 10, 22, "Baja", lBaja, oWin )

    oBtGua := TButton():New( 12, 6, 13, 22, oWin, "GUARDAR", ;
        {|| _IVAGuardar( oGetCod, oGetDes, oGetIva, oGetRe, ;
                         oChkBaj, lNuevo, oWin ) } )

    oBtCan := TButton():New( 12, 26, 13, 42, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGetCod )
    oWin:AddCtrl( oGetDes )
    oWin:AddCtrl( oGetIva )
    oWin:AddCtrl( oGetRe  )
    oWin:AddCtrl( oChkBaj )
    oWin:AddCtrl( oBtGua  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _IVAGuardar( oGC, oGD, oGI, oGR, oChk, lNuevo, oWin )

    LOCAL cCod

    cCod := AllTrim( oGC:uVar )

    IF !( cCod $ "GRSE" )
        MsgStop( "Codigo invalido. Use G, R, S o E.", "IVA" )
        RETURN NIL
    ENDIF

    DbSelectArea( "IVA" )
    OrdSetFocus( "IVA_COD" )

    IF lNuevo
        IF DbSeek( cCod )
            MsgStop( "El tipo " + cCod + " ya existe.", "Alta" )
            RETURN NIL
        ENDIF
        IF !NetFLock()
            RETURN NIL
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCod )
            RETURN NIL
        ENDIF
        IF !NetRLock()
            RETURN NIL
        ENDIF
    ENDIF

    REPLACE IVA->CODIGO   WITH cCod
    REPLACE IVA->DESCRIP  WITH AllTrim( oGD:uVar )
    REPLACE IVA->PORC_IVA WITH oGI:uVar
    REPLACE IVA->PORC_RE  WITH oGR:uVar
    REPLACE IVA->BAJA     WITH oChk:lValue

    DbUnlock()
    oWin:Close()

RETURN NIL


// ============================================================================
// M_CCostes()
// ============================================================================
FUNCTION M_CCostes()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL aData

    IF !ABRIR_TABLA( "CCOSTOS", "CCO", "CCO_COD" )
        RETURN NIL
    ENDIF

    aData := _CCOCargar()

    oWin  := TWindow():New( 3, 10, 32, 119, "CENTROS DE COSTE" )
    oGrid := TGrid():New( 2, 2, 24, 106, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Codigo",      10, "@!",              { |a| a[1] } )
    oGrid:AddColumn( "Descripcion", 40, "@!",              { |a| a[2] } )
    oGrid:AddColumn( "Responsable", 30, "@!",              { |a| a[3] } )
    oGrid:AddColumn( "Presupuesto", 12, "999,999,999.99",  { |a| a[4] } )
    oGrid:AddColumn( "Baja",         4, "@!",              { |a| If( a[5], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        _CCOForm( g:CurrentRow(), .F. ), ;
        aData := _CCOCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oBtNvo := TButton():New( 26, 2, 27, 18, oWin, "NUEVO (F5)", ;
        {|| _CCOForm( NIL, .T. ), ;
            aData := _CCOCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 26, 88, 27, 104, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    CCO->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _CCOCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "CCO" )
    OrdSetFocus( "CCO_COD" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( CCO->CCO_COD  ), ;
                AllTrim( CCO->CCO_DESC ), ;
                AllTrim( CCO->CCO_RESP ), ;
                CCO->CCO_PRES, ;
                CCO->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _CCOForm( aFila, lNuevo )

    LOCAL oWin
    LOCAL oGetCod
    LOCAL oGetDes
    LOCAL oGetRes
    LOCAL oGetPre
    LOCAL oChkBaj
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL cCodigo
    LOCAL cDescri
    LOCAL cResp
    LOCAL nPresu
    LOCAL lBaja
    LOCAL cTit

    DEFAULT lNuevo TO .F.

    cCodigo := Space( 10 )
    cDescri := Space( 40 )
    cResp   := Space( 30 )
    nPresu  := 0.00
    lBaja   := .F.

    IF !lNuevo .AND. aFila != NIL
        cCodigo := PadR( aFila[1], 10 )
        cDescri := PadR( aFila[2], 40 )
        cResp   := PadR( aFila[3], 30 )
        nPresu  := aFila[4]
        lBaja   := aFila[5]
    ENDIF

    cTit := If( lNuevo, "NUEVO CENTRO COSTE", "EDITAR CENTRO COSTE" )

    oWin := TWindow():New( 7, 25, 26, 105, cTit )

    oWin:AddCtrl( TLabel():New(  2, 3, "Codigo      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 3, "Descripcion :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 3, "Responsable :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 3, "Presupuesto :", oWin ) )

    oGetCod := TGet():New(  2, 17, cCodigo, "@!", oWin )
    oGetCod:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    IF !lNuevo
        oGetCod:lEnabled := .F.
    ENDIF

    oGetDes := TGet():New(  4, 17, cDescri, "@!",             oWin )
    oGetDes:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGetRes := TGet():New(  6, 17, cResp,   "@!",             oWin )
    oGetPre := TGet():New(  8, 17, nPresu,  "999,999,999.99", oWin )

    oChkBaj := TCheck():New( 10, 17, "Baja", lBaja, oWin )

    oBtGua := TButton():New( 12, 10, 13, 26, oWin, "GUARDAR", ;
        {|| _CCOGuardar( oGetCod, oGetDes, oGetRes, oGetPre, ;
                         oChkBaj, lNuevo, oWin ) } )

    oBtCan := TButton():New( 12, 30, 13, 46, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGetCod )
    oWin:AddCtrl( oGetDes )
    oWin:AddCtrl( oGetRes )
    oWin:AddCtrl( oGetPre )
    oWin:AddCtrl( oChkBaj )
    oWin:AddCtrl( oBtGua  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _CCOGuardar( oGC, oGD, oGR, oGP, oChk, lNuevo, oWin )

    LOCAL cCod

    cCod := AllTrim( oGC:uVar )

    DbSelectArea( "CCO" )
    OrdSetFocus( "CCO_COD" )

    IF lNuevo
        IF DbSeek( cCod )
            MsgStop( "El codigo " + cCod + " ya existe.", "Alta" )
            RETURN NIL
        ENDIF
        IF !NetFLock()
            RETURN NIL
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCod )
            RETURN NIL
        ENDIF
        IF !NetRLock()
            RETURN NIL
        ENDIF
    ENDIF

    REPLACE CCO->CCO_COD  WITH cCod
    REPLACE CCO->CCO_DESC WITH AllTrim( oGD:uVar )
    REPLACE CCO->CCO_RESP WITH AllTrim( oGR:uVar )
    REPLACE CCO->CCO_PRES WITH oGP:uVar
    REPLACE CCO->BAJA     WITH oChk:lValue

    DbUnlock()
    oWin:Close()

RETURN NIL


// ============================================================================
// FIN DE M_Auxiliar.prg
// ============================================================================
