/*
 * ARCHIVO  : M_Auxiliar.prg
 * PROPOSITO: Mantenimiento de tablas auxiliares del sistema.
 *
 * FUNCIONES PUBLICAS
 * ------------------
 *   M_FormaPago()  - ABM de formas de pago
 *   M_TiposIva()   - ABM de tipos de IVA
 *   M_CCostes()    - ABM de centros de coste
 */

#include "OOp.ch"


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
        {|| If( FormaPagoGuardar( _FPFormHash( oGetCod, oGetDes, oGetDia, oGetNPa, ;
                                                oGetCta, oChkBaj ), ;
                                  lNuevo ), ;
                 oWin:Close(), NIL ) } )

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


STATIC FUNCTION _FPFormHash( oGC, oGD, oGDi, oGN, oGCt, oChk )

    LOCAL hFP := {=>}

    hFP[ "CODIGO"   ] := AllTrim( oGC:GetValue() )
    hFP[ "DESCRIP"  ] := AllTrim( oGD:GetValue() )
    hFP[ "DIAS"     ] := oGDi:GetValue()
    hFP[ "NUM_PAGS" ] := oGN:GetValue()
    hFP[ "CTA_COB"  ] := AllTrim( oGCt:GetValue() )
    hFP[ "BAJA"     ] := oChk:GetValue()

RETURN hFP


FUNCTION FormaPagoGuardar( hFP, lNuevo )

    LOCAL cCod

    cCod := hFP[ "CODIGO" ]

    DbSelectArea( "FP" )
    OrdSetFocus( "FP_COD" )

    IF lNuevo
        IF DbSeek( cCod )
            MsgStop( "El codigo " + cCod + " ya existe.", "Alta" )
            RETURN .F.
        ENDIF
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCod )
            RETURN .F.
        ENDIF
        IF !NetRLock()
            RETURN .F.
        ENDIF
    ENDIF

    REPLACE FP->CODIGO   WITH hFP[ "CODIGO"   ]
    REPLACE FP->DESCRIP  WITH hFP[ "DESCRIP"  ]
    REPLACE FP->DIAS     WITH hFP[ "DIAS"     ]
    REPLACE FP->NUM_PAGS WITH hFP[ "NUM_PAGS" ]
    REPLACE FP->CTA_COB  WITH hFP[ "CTA_COB"  ]
    REPLACE FP->BAJA     WITH hFP[ "BAJA"     ]

    DbUnlock()

RETURN .T.


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
        {|| If( TipoIvaGuardar( _IVAFormHash( oGetCod, oGetDes, oGetIva, oGetRe, ;
                                              oChkBaj ), ;
                                lNuevo ), ;
                 oWin:Close(), NIL ) } )

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


STATIC FUNCTION _IVAFormHash( oGC, oGD, oGI, oGR, oChk )

    LOCAL hIVA := {=>}

    hIVA[ "CODIGO"   ] := AllTrim( oGC:GetValue() )
    hIVA[ "DESCRIP"  ] := AllTrim( oGD:GetValue() )
    hIVA[ "PORC_IVA" ] := oGI:GetValue()
    hIVA[ "PORC_RE"  ] := oGR:GetValue()
    hIVA[ "BAJA"     ] := oChk:GetValue()

RETURN hIVA


FUNCTION TipoIvaGuardar( hIVA, lNuevo )

    LOCAL cCod

    cCod := hIVA[ "CODIGO" ]

    IF !( cCod $ "GRSE" )
        MsgStop( "Codigo invalido. Use G, R, S o E.", "IVA" )
        RETURN .F.
    ENDIF

    DbSelectArea( "IVA" )
    OrdSetFocus( "IVA_COD" )

    IF lNuevo
        IF DbSeek( cCod )
            MsgStop( "El tipo " + cCod + " ya existe.", "Alta" )
            RETURN .F.
        ENDIF
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCod )
            RETURN .F.
        ENDIF
        IF !NetRLock()
            RETURN .F.
        ENDIF
    ENDIF

    REPLACE IVA->CODIGO   WITH cCod
    REPLACE IVA->DESCRIP  WITH hIVA[ "DESCRIP"  ]
    REPLACE IVA->PORC_IVA WITH hIVA[ "PORC_IVA" ]
    REPLACE IVA->PORC_RE  WITH hIVA[ "PORC_RE"  ]
    REPLACE IVA->BAJA     WITH hIVA[ "BAJA"     ]

    DbUnlock()

RETURN .T.


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
        {|| If( CCosteGuardar( _CCOFormHash( oGetCod, oGetDes, oGetRes, oGetPre, ;
                                             oChkBaj ), ;
                               lNuevo ), ;
                 oWin:Close(), NIL ) } )

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


STATIC FUNCTION _CCOFormHash( oGC, oGD, oGR, oGP, oChk )

    LOCAL hCCO := {=>}

    hCCO[ "CCO_COD"  ] := AllTrim( oGC:GetValue() )
    hCCO[ "CCO_DESC" ] := AllTrim( oGD:GetValue() )
    hCCO[ "CCO_RESP" ] := AllTrim( oGR:GetValue() )
    hCCO[ "CCO_PRES" ] := oGP:GetValue()
    hCCO[ "BAJA"      ] := oChk:GetValue()

RETURN hCCO


FUNCTION CCosteGuardar( hCCO, lNuevo )

    LOCAL cCod

    cCod := hCCO[ "CCO_COD" ]

    DbSelectArea( "CCO" )
    OrdSetFocus( "CCO_COD" )

    IF lNuevo
        IF DbSeek( cCod )
            MsgStop( "El codigo " + cCod + " ya existe.", "Alta" )
            RETURN .F.
        ENDIF
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCod )
            RETURN .F.
        ENDIF
        IF !NetRLock()
            RETURN .F.
        ENDIF
    ENDIF

    REPLACE CCO->CCO_COD  WITH cCod
    REPLACE CCO->CCO_DESC WITH hCCO[ "CCO_DESC" ]
    REPLACE CCO->CCO_RESP WITH hCCO[ "CCO_RESP" ]
    REPLACE CCO->CCO_PRES WITH hCCO[ "CCO_PRES" ]
    REPLACE CCO->BAJA     WITH hCCO[ "BAJA"     ]

    DbUnlock()

RETURN .T.


// ============================================================================
// FIN DE M_Auxiliar.prg
// ============================================================================
