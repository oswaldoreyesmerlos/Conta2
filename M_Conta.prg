/*
 * ARCHIVO  : M_Conta.prg
 * PROPOSITO: Funciones contables - Plan Cuentas, Libro Diario, Asientos.
 */

#include "OOp.ch"


// ============================================================================
// PlanCuentasView()
// ============================================================================
FUNCTION PlanCuentasView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "CATALOGO", "CAT", "CAT_CTA" )
        RETURN NIL
    ENDIF

    aData := _CatCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "PLAN DE CUENTAS" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 1

    oGrid:AddColumn( "Cuenta",      10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Nombre",      40, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "Nivel",       3, "9",          { |a| a[3] } )
    oGrid:AddColumn( "Tipo",        2, "@!",         { |a| a[4] } )
    oGrid:AddColumn( "Naturaleza",  2, "@!",         { |a| a[5] } )
    oGrid:AddColumn( "Suma en",    10, "@!",         { |a| a[6] } )
    oGrid:AddColumn( "Saldo Act.", 14, "999,999.99", { |a| a[7] } )
    oGrid:AddColumn( "Baja",         4, "@!",         { |a| If( a[8], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        PlanCuentasForm( g:CurrentRow()[1] ), ;
        aData := _CatCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "Letras: busqueda por cuenta. ENTER: editar. F5: nueva cuenta.", oWin )

    oBtNvo := TButton():New( 33, 2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| PlanCuentasForm( "" ), ;
            aData := _CatCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 33, 108, 34, 124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLbl   )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    CAT->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _CatCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "CAT" )
    OrdSetFocus( "CAT_CTA" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( CAT->CUENTA   ), ;
                AllTrim( CAT->NOMBRE   ), ;
                CAT->NIVEL, ;
                AllTrim( CAT->TIPO     ), ;
                AllTrim( CAT->NATURALE ), ;
                AllTrim( CAT->SUMA_EN  ), ;
                CAT->SALDO_AC, ;
                CAT->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


// ============================================================================
// PlanCuentasForm()
// ============================================================================
FUNCTION PlanCuentasForm( cCuenta )

    LOCAL oWin
    LOCAL nArea
    LOCAL cCuenta_
    LOCAL cNombre
    LOCAL nNivel
    LOCAL cTipo
    LOCAL cNaturale
    LOCAL cSumaEn
    LOCAL nSaldoAn
    LOCAL nDebeAnu
    LOCAL nHaberAnu
    LOCAL nSaldoAc
    LOCAL nPresupue
    LOCAL lBloqued
    LOCAL lReqAnal
    LOCAL lEsBanco
    LOCAL lBaja
    LOCAL oGCta
    LOCAL oGNom
    LOCAL oGNiv
    LOCAL oGTip
    LOCAL oGNat
    LOCAL oGSuma
    LOCAL oGSA
    LOCAL oGDA
    LOCAL oGHA
    LOCAL oGSAc
    LOCAL oGPre
    LOCAL oChkBloq
    LOCAL oChkAna
    LOCAL oChkBanc
    LOCAL oChkBaja
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL lNuevo

    DEFAULT cCuenta TO ""

    lNuevo   := Empty( AllTrim( cCuenta ) )
    nArea    := Select()
    cCuenta_ := Space( 10 )
    cNombre  := Space( 60 )
    nNivel   := 3
    cTipo    := Space(  1 )
    cNaturale := Space(  1 )
    cSumaEn  := Space( 10 )
    nSaldoAn  := 0.00
    nDebeAnu  := 0.00
    nHaberAnu  := 0.00
    nSaldoAc  := 0.00
    nPresupue := 0.00
    lBloqued  := .F.
    lReqAnal  := .F.
    lEsBanco  := .F.
    lBaja     := .F.

    IF !ABRIR_TABLA( "CATALOGO", "CAT", "CAT_CTA" )
        RETURN NIL
    ENDIF

    IF !lNuevo
        DbSelectArea( "CAT" )
        OrdSetFocus( "CAT_CTA" )
        IF DbSeek( AllTrim( cCuenta ) )
            cCuenta_  := PadR( AllTrim( CAT->CUENTA   ), 10 )
            cNombre  := PadR( AllTrim( CAT->NOMBRE   ), 60 )
            nNivel   := CAT->NIVEL
            cTipo    := PadR( AllTrim( CAT->TIPO     ),  1 )
            cNaturale := PadR( AllTrim( CAT->NATURALE ),  1 )
            cSumaEn  := PadR( AllTrim( CAT->SUMA_EN  ), 10 )
            nSaldoAn  := CAT->SALDO_AN
            nDebeAnu  := CAT->DEBE_ANU
            nHaberAnu  := CAT->HABER_AN
            nSaldoAc  := CAT->SALDO_AC
            nPresupue := CAT->PRESUPUE
            lBloqued  := CAT->BLOQUEAD
            lReqAnal  := CAT->REQ_ANAL
            lEsBanco  := CAT->ES_BANCO
            lBaja     := CAT->BAJA
        ENDIF
    ENDIF

    oWin := TWindow():New( 1, 2, 37, 129, ;
        If( lNuevo, "NUEVA CUENTA", "EDITAR CUENTA: " + AllTrim( cCuenta_ ) ) )

    oWin:AddCtrl( TLabel():New(  2,  2, "Cuenta       :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Nombre       :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Nivel (1-4)  :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Tipo (A/P/G/I/N):", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  2, "Naturaleza (D/A):", oWin ) )
    oWin:AddCtrl( TLabel():New( 12,  2, "Suma en      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 14,  2, "Saldo Ant.   :", oWin ) )
    oWin:AddCtrl( TLabel():New( 16,  2, "Debe Año     :", oWin ) )
    oWin:AddCtrl( TLabel():New( 18,  2, "Haber Año    :", oWin ) )
    oWin:AddCtrl( TLabel():New( 20,  2, "Saldo Actual :", oWin ) )
    oWin:AddCtrl( TLabel():New( 22,  2, "Presupuesto  :", oWin ) )

    oGCta   := TGet():New(  2, 20, cCuenta_, "@!",    oWin )
    oGCta:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    IF !lNuevo
        oGCta:lEnabled := .F.
    ENDIF

    oGNom   := TGet():New(  4, 20, cNombre, "@!",    oWin )
    oGNom:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGNiv   := TGet():New(  6, 20, nNivel,   "9",     oWin )
    oGTip   := TGet():New(  8, 20, cTipo,    "@!",    oWin )
    oGNat   := TGet():New( 10, 20, cNaturale,"@!",     oWin )
    oGSuma  := TGet():New( 12, 20, cSumaEn, "@!",    oWin )
    oGSA    := TGet():New( 14, 20, nSaldoAn, "999,999.99", oWin )
    oGDA    := TGet():New( 16, 20, nDebeAnu, "999,999.99", oWin )
    oGHA    := TGet():New( 18, 20, nHaberAnu,"999,999.99", oWin )
    oGSAc   := TGet():New( 20, 20, nSaldoAc, "999,999.99", oWin )
    oGPre   := TGet():New( 22, 20, nPresupue,"999,999.99", oWin )

    oChkBloq := TCheck():New( 24,  2, "Bloqueada",     lBloqued, oWin )
    oChkAna  := TCheck():New( 24, 20, "Requiere analitica", lReqAnal, oWin )
    oChkBanc := TCheck():New( 24, 45, "Es banco",        lEsBanco, oWin )
    oChkBaja := TCheck():New( 24, 60, "Baja",           lBaja,    oWin )

    oBtGua := TButton():New( 33, 40, 34, 59, oWin, "GUARDAR", ;
        {|| _CatGuardar( oGCta, oGNom, oGNiv, oGTip, oGNat, ;
                         oGSuma, oGSA, oGDA, oGHA, oGSAc, oGPre, ;
                         oChkBloq, oChkAna, oChkBanc, oChkBaja, ;
                         lNuevo, oWin ) } )

    oBtCan := TButton():New( 33, 63, 34, 82, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGCta    )
    oWin:AddCtrl( oGNom    )
    oWin:AddCtrl( oGNiv    )
    oWin:AddCtrl( oGTip    )
    oWin:AddCtrl( oGNat    )
    oWin:AddCtrl( oGSuma   )
    oWin:AddCtrl( oGSA     )
    oWin:AddCtrl( oGDA     )
    oWin:AddCtrl( oGHA     )
    oWin:AddCtrl( oGSAc    )
    oWin:AddCtrl( oGPre    )
    oWin:AddCtrl( oChkBloq )
    oWin:AddCtrl( oChkAna  )
    oWin:AddCtrl( oChkBanc )
    oWin:AddCtrl( oChkBaja )
    oWin:AddCtrl( oBtGua   )
    oWin:AddCtrl( oBtCan   )

    oWin:Run()

    CAT->( DbCloseArea() )
    Select( nArea )

RETURN NIL


STATIC FUNCTION _CatGuardar( oGC, oGN, oGi, oGT, oGNt, ;
                             oGS, oGSA, oGDA, oGHA, oGSAc, oGPre, ;
                             oCB, oCA, oCBc, oCBj, ;
                             lNuevo, oWin )

    LOCAL cCuenta

    cCuenta := AllTrim( oGC:uVar )

    DbSelectArea( "CAT" )
    OrdSetFocus( "CAT_CTA" )

    IF lNuevo
        IF DbSeek( cCuenta )
            MsgStop( "La cuenta " + cCuenta + " ya existe.", "Alta cuenta" )
            RETURN NIL
        ENDIF
        IF !NetFLock()
            RETURN NIL
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCuenta ) .OR. !NetRLock()
            RETURN NIL
        ENDIF
    ENDIF

    REPLACE CAT->CUENTA   WITH cCuenta
    REPLACE CAT->NOMBRE   WITH AllTrim( oGN:uVar  )
    REPLACE CAT->NIVEL    WITH oGi:uVar
    REPLACE CAT->TIPO     WITH AllTrim( oGT:uVar  )
    REPLACE CAT->NATURALE WITH AllTrim( oGNt:uVar )
    REPLACE CAT->SUMA_EN  WITH AllTrim( oGS:uVar  )
    REPLACE CAT->SALDO_AN WITH oGSA:uVar
    REPLACE CAT->DEBE_ANU WITH oGDA:uVar
    REPLACE CAT->HABER_AN WITH oGHA:uVar
    REPLACE CAT->SALDO_AC WITH oGSAc:uVar
    REPLACE CAT->PRESUPUE WITH oGPre:uVar
    REPLACE CAT->BLOQUEAD WITH oCB:lValue
    REPLACE CAT->REQ_ANAL WITH oCA:lValue
    REPLACE CAT->ES_BANCO WITH oCBc:lValue
    REPLACE CAT->BAJA     WITH oCBj:lValue

    IF lNuevo
        REPLACE CAT->FECHA_AL WITH Date()
    ENDIF

    DbCommit()
    DbUnlock()

    oWin:Close()

RETURN NIL


// ============================================================================
// LibroDiarioView()
// ============================================================================
FUNCTION LibroDiarioView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "LDIARIO", "DIA", "DIA_FEC" )
        RETURN NIL
    ENDIF

    aData := _DiaCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "LIBRO DIARIO" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Asiento",   10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Fecha",     10, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "Cuenta",    10, "@!",         { |a| a[3] } )
    oGrid:AddColumn( "Debe",      14, "999,999.99", { |a| a[4] } )
    oGrid:AddColumn( "Haber",     14, "999,999.99", { |a| a[5] } )
    oGrid:AddColumn( "Descripcion",40, "@!",         { |a| a[6] } )
    oGrid:AddColumn( "C.Coste",  10, "@!",         { |a| a[7] } )

    oGrid:bEnter := {| g | ;
        _DiaEditar( g:CurrentRow()[1] ), ;
        aData := _DiaCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "Letras: busqueda por descripcion. ENTER: ver asiento.", oWin )

    oBtNvo := TButton():New( 33, 2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| _DiaNuevo(), ;
            aData := _DiaCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 33, 108, 34, 124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLbl   )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    DIA->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _DiaCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "DIA" )
    OrdSetFocus( "DIA_FEC" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( DIA->D_ASIENT ), ;
                DToC(    DIA->D_FECHA  ), ;
                AllTrim( DIA->D_CUENTA ), ;
                DIA->D_DEBE, ;
                DIA->D_HABER, ;
                AllTrim( DIA->D_DESCRI ), ;
                AllTrim( DIA->D_CCOSTE ) } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _DiaNuevo()
RETURN _DiaForm( "" )


STATIC FUNCTION _DiaEditar( cAsiento )
RETURN _DiaForm( cAsiento )


STATIC FUNCTION _DiaForm( cAsiento )

    LOCAL oWin
    LOCAL nArea
    LOCAL cAsiento_
    LOCAL dFecha
    LOCAL cCuenta
    LOCAL nDebe
    LOCAL nHaber
    LOCAL cDescrip
    LOCAL cCCoste
    LOCAL cDocEx
    LOCAL lPunteado
    LOCAL dPunteo
    LOCAL cDivisa
    LOCAL nImpDiv
    LOCAL nCambio
    LOCAL cUsuario
    LOCAL cTipOrig
    LOCAL cDocOrig
    LOCAL nLinea
    LOCAL aLineas
    LOCAL oGAsi
    LOCAL oGFec
    LOCAL oGDes
    LOCAL oGrid
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL oBtNLin
    LOCAL oBtELin
    LOCAL oBtDLin
    LOCAL lNuevo
    LOCAL cAsientoDisp

    DEFAULT cAsiento TO ""

    lNuevo := Empty( AllTrim( cAsiento ) )
    nArea  := Select()
    cAsiento_  := Space( 10 )
    dFecha    := Date()
    cCuenta   := Space( 10 )
    nDebe     := 0.00
    nHaber    := 0.00
    cDescrip  := Space( 100 )
    cCCoste   := Space( 10 )
    cDocEx    := Space( 20 )
    lPunteado := .F.
    dPunteo   := CToD( "" )
    cDivisa   := Space(  3 )
    nImpDiv   := 0.00
    nCambio   := 0.000000
    cUsuario  := Space( 10 )
    cTipOrig  := Space(  3 )
    cDocOrig  := Space( 10 )
    nLinea    := 1
    aLineas   := {}
    cAsientoDisp := If( lNuevo, "(se asigna al grabar)", AllTrim( cAsiento ) )

    IF !lNuevo
        IF !_DiaCargarCab( cAsiento, @cAsiento_, @dFecha, @cDescrip, @cUsuario )
            RETURN NIL
        ENDIF
        _DiaCargarLins( cAsiento, @aLineas )
    ENDIF

    oWin := TWindow():New( 1, 2, 37, 129, ;
        If( lNuevo, "NUEVO ASIENTO", "EDITAR ASIENTO: " + cAsientoDisp ) )

    oWin:AddCtrl( TLabel():New(  2,  2, "Asiento :", oWin ) )
    oWin:AddCtrl( TLabel():New(  2, 40, "Fecha   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Descripcion:", oWin ) )

    oWin:AddCtrl( TLabel():New(  2, 70, "Usuario:", oWin ) )

    oGAsi := TLabel():New(  2, 14, PadR( cAsientoDisp, 24 ), oWin )
    oGAsi:cColor := "W+/B"
    oWin:AddCtrl( oGAsi )

    oGFec := TGet():New(  2, 52, dFecha, "99/99/9999", oWin )
    oWin:AddCtrl( oGFec )

    oGDes := TGet():New(  4, 14, cDescrip, "@!", oWin )
    oWin:AddCtrl( oGDes )

    oWin:AddCtrl( TLabel():New(  4, 70, PadR( cUsuario, 20 ), oWin ) )

    oGrid := TGrid():New( 6, 2, 26, 124, oWin )
    oGrid:aData    := aLineas

    oGrid:AddColumn( "#",          3, "999",       { |a| a[1] } )
    oGrid:AddColumn( "Cuenta",    10, "@!",        { |a| a[2] } )
    oGrid:AddColumn( "Debe",      14, "999,999.99", { |a| a[3] } )
    oGrid:AddColumn( "Haber",     14, "999,999.99", { |a| a[4] } )
    oGrid:AddColumn( "C.Coste",  10, "@!",        { |a| a[5] } )
    oGrid:AddColumn( "Descripcion",40, "@!",        { |a| a[6] } )

    oGrid:bEnter := {| g | _DiaEditLin( g, @aLineas, oGrid ) }

    oBtNLin := TButton():New( 32,  2, 33, 18, oWin, "NUEVA LINEA (F5)", ;
        {|| _DiaNuevaLin( oGrid, @aLineas ) } )

    oBtELin := TButton():New( 32, 20, 33, 38, oWin, "EDITAR LINEA", ;
        {|| _DiaEditLin( oGrid, @aLineas ) } )

    oBtDLin := TButton():New( 32, 38, 33, 56, oWin, "BORRAR LINEA", ;
        {|| _DiaBorrarLin( oGrid, @aLineas ) } )

    oBtGua := TButton():New( 33, 63, 34, 82, oWin, "GUARDAR", ;
        {|| _DiaGuardar( oGAsi, oGFec, oGDes, aLineas, lNuevo, oWin ) } )

    oBtCan := TButton():New( 33, 86, 34, 105, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid   )
    oWin:AddCtrl( oBtNLin )
    oWin:AddCtrl( oBtELin )
    oWin:AddCtrl( oBtDLin )
    oWin:AddCtrl( oBtGua  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

    Select( nArea )

RETURN NIL


STATIC FUNCTION _DiaCargarCab( cAsiento, cAsi, dFec, cDes, cUsr )

    IF !ABRIR_TABLA( "LDIARIO", "DIA_C", "DIA_ASI" )
        RETURN .F.
    ENDIF

    DbSelectArea( "DIA_C" )
    OrdSetFocus( "DIA_ASI" )

    IF !DbSeek( PadR( cAsiento, 10 ) + "   1" )
        MsgStop( "Asiento " + cAsiento + " no encontrado.", "Error" )
        RETURN .F.
    ENDIF

    cAsi := AllTrim( DIA_C->D_ASIENT )
    dFec := DIA_C->D_FECHA
    cDes := AllTrim( DIA_C->D_DESCRI )
    cUsr := AllTrim( DIA_C->USUARIO_ )

    DIA_C->( DbCloseArea() )

RETURN .T.


STATIC FUNCTION _DiaCargarLins( cAsiento, aLins )

    LOCAL nL

    nL   := 0
    aLins := {}

    IF !ABRIR_TABLA( "LDIARIO", "DIA_L", "DIA_ASI" )
        RETURN NIL
    ENDIF

    DbSelectArea( "DIA_L" )
    OrdSetFocus( "DIA_ASI" )
    DbSeek( PadR( cAsiento, 10 ) + "   1" )

    DO WHILE !Eof() .AND. AllTrim( DIA_L->D_ASIENT ) == AllTrim( cAsiento )
        IF !Deleted()
            nL++
            AAdd( aLins, { ;
                nL, ;
                AllTrim( DIA_L->D_CUENTA ), ;
                DIA_L->D_DEBE, ;
                DIA_L->D_HABER, ;
                AllTrim( DIA_L->D_CCOSTE ), ;
                AllTrim( DIA_L->D_DESCRI ) } )
        ENDIF
        DbSkip()
    ENDDO

    DIA_L->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _DiaNuevaLin( oGrid, aLins )

    LOCAL nNum
    LOCAL aLin

    nNum := Len( aLins ) + 1
    aLin := { nNum, Space( 10 ), 0.00, 0.00, Space( 10 ), Space( 100 ) }

    IF _DiaFormLin( @aLin, .T. )
        AAdd( aLins, aLin )
        oGrid:aData   := aLins
        oGrid:nCurRow := Len( aLins )
        oGrid:Paint()
    ENDIF

RETURN NIL


STATIC FUNCTION _DiaEditLin( oGrid, aLins )

    LOCAL nPos
    LOCAL aLin

    nPos := oGrid:nCurRow

    IF nPos < 1 .OR. nPos > Len( aLins )
        RETURN NIL
    ENDIF

    aLin := AClone( aLins[nPos] )

    IF _DiaFormLin( @aLin, .F. )
        aLins[nPos] := aLin
        oGrid:aData  := aLins
        oGrid:Paint()
    ENDIF

RETURN NIL


STATIC FUNCTION _DiaBorrarLin( oGrid, aLins )

    LOCAL nPos
    LOCAL i

    nPos := oGrid:nCurRow

    IF nPos < 1 .OR. nPos > Len( aLins )
        RETURN NIL
    ENDIF

    IF !MsgYesNo( "Borrar linea " + AllTrim( Str( nPos ) ) + "?", "Confirmar" )
        RETURN NIL
    ENDIF

    ADel( aLins, nPos )
    ASize( aLins, Len( aLins ) - 1 )

    FOR i := 1 TO Len( aLins )
        aLins[i, 1] := i
    NEXT

    IF oGrid:nCurRow > Len( aLins ) .AND. Len( aLins ) > 0
        oGrid:nCurRow := Len( aLins )
    ENDIF

    oGrid:aData := aLins
    oGrid:Paint()

RETURN NIL


STATIC FUNCTION _DiaFormLin( aLin, lNuevo )

    LOCAL oWin
    LOCAL oGCta
    LOCAL oGDeb
    LOCAL oGHab
    LOCAL oGCC
    LOCAL oGDes
    LOCAL oBtAcep
    LOCAL oBtCanc
    LOCAL lOK
    LOCAL cCuenta
    LOCAL nDebe
    LOCAL nHaber
    LOCAL cCCoste
    LOCAL cDescrip

    lOK     := .F.
    cCuenta  := PadR( aLin[2], 10 )
    nDebe   := aLin[3]
    nHaber  := aLin[4]
    cCCoste  := PadR( aLin[5], 10 )
    cDescrip := PadR( aLin[6], 100 )

    oWin := TWindow():New( 10, 15, 26, 115, ;
        If( lNuevo, "NUEVA LINEA", "EDITAR LINEA " + AllTrim( Str( aLin[1] ) ) ) )

    oWin:AddCtrl( TLabel():New( 2,  3, "Cuenta     :", oWin ) )
    oWin:AddCtrl( TLabel():New( 4,  3, "Debe       :", oWin ) )
    oWin:AddCtrl( TLabel():New( 6,  3, "Haber      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 8,  3, "C.Coste    :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10, 3, "Descripcion:", oWin ) )

    oGCta := TGet():New(  2, 17, cCuenta, "@!",    oWin )
    oGDeb := TGet():New(  4, 17, nDebe,   "999,999.99", oWin )
    oGHab := TGet():New(  6, 17, nHaber,  "999,999.99", oWin )
    oGCC  := TGet():New(  8, 17, cCCoste, "@!",    oWin )
    oGDes := TGet():New( 10, 17, cDescrip,"@!",        oWin )

    oBtAcep := TButton():New( 12, 25, 13, 44, oWin, "ACEPTAR", ;
        {|| lOK := .T., oWin:Close() } )

    oBtCanc := TButton():New( 12, 48, 13, 67, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGCta )
    oWin:AddCtrl( oGDeb )
    oWin:AddCtrl( oGHab )
    oWin:AddCtrl( oGCC  )
    oWin:AddCtrl( oGDes )
    oWin:AddCtrl( oBtAcep )
    oWin:AddCtrl( oBtCanc )

    oWin:Run()

    IF lOK
        aLin[2] := AllTrim( oGCta:uVar )
        aLin[3] := oGDeb:uVar
        aLin[4] := oGHab:uVar
        aLin[5] := AllTrim( oGCC:uVar )
        aLin[6] := AllTrim( oGDes:uVar )
    ENDIF

RETURN lOK


STATIC FUNCTION _DiaGuardar( oLAsi, oGFec, oGDes, aLins, lNuevo, oWin )

    LOCAL cAsiento
    LOCAL dFecha
    LOCAL cDescrip
    LOCAL i
    LOCAL nDebeTotal
    LOCAL nHaberTotal

    IF Len( aLins ) < 2
        MsgStop( "Debe introducir al menos dos lineas.", "Guardar" )
        RETURN NIL
    ENDIF

    nDebeTotal := 0
    nHaberTotal := 0
    FOR i := 1 TO Len( aLins )
        nDebeTotal += aLins[i, 3]
        nHaberTotal += aLins[i, 4]
    NEXT

    IF Abs( nDebeTotal - nHaberTotal ) > 0.01
        MsgStop( "El asiento no cuadra. Debe: " + AllTrim( Str( nDebeTotal ) ) + ;
                      " - Haber: " + AllTrim( Str( nHaberTotal ) ), "Error" )
        RETURN NIL
    ENDIF

    IF lNuevo
        cAsiento := _DiaSiguiente()
        IF Empty( cAsiento )
            RETURN NIL
        ENDIF
    ELSE
        cAsiento := AllTrim( oLAsi:GetText() )
    ENDIF

    dFecha   := oGFec:uVar
    cDescrip := AllTrim( oGDes:uVar )

    IF !ABRIR_TABLA( "LDIARIO", "DIA_G", "DIA_ASI" )
        RETURN NIL
    ENDIF

    DbSelectArea( "DIA_G" )
    OrdSetFocus( "DIA_ASI" )

    IF lNuevo
        IF !NetFLock()
            RETURN NIL
        ENDIF
    ELSE
        _DiaBorrarLinsDB( cAsiento )
    ENDIF

    IF NetFLock()
        FOR i := 1 TO Len( aLins )
            DbAppend()
            REPLACE DIA_G->D_ASIENT WITH cAsiento
            REPLACE DIA_G->D_LINEA  WITH aLins[i, 1]
            REPLACE DIA_G->D_FECHA  WITH dFecha
            REPLACE DIA_G->D_CUENTA WITH aLins[i, 2]
            REPLACE DIA_G->D_DEBE   WITH aLins[i, 3]
            REPLACE DIA_G->D_HABER  WITH aLins[i, 4]
            REPLACE DIA_G->D_DESCRI WITH aLins[i, 6]
            REPLACE DIA_G->D_CCOSTE WITH aLins[i, 5]
            REPLACE DIA_G->USUARIO_ WITH If( Type( "cUserID" ) == "C", PadR( cUserID, 10 ), "" )
            REPLACE DIA_G->FECHA_AL WITH Date()
        NEXT
        DbUnlock()
    ENDIF

    DIA_G->( DbCloseArea() )

    IF lNuevo
        oLAsi:SetText( PadR( cAsiento, 24 ) )
    ENDIF

    MsgInfo( "Asiento " + cAsiento + " guardado.", "Guardado" )

RETURN NIL


STATIC FUNCTION _DiaSiguiente()

    LOCAL cAnio
    LOCAL cCod

    cAnio := AllTrim( Str( Year( Date() ) ) )
    cCod  := "DIA" + cAnio

RETURN GetNextNum( cCod, "Asientos " + cAnio )


STATIC FUNCTION _DiaBorrarLinsDB( cAsiento )

    IF !ABRIR_TABLA( "LDIARIO", "DIA_B", "DIA_ASI" )
        RETURN NIL
    ENDIF

    DbSelectArea( "DIA_B" )
    OrdSetFocus( "DIA_ASI" )
    DbSeek( PadR( cAsiento, 10 ) + "   1" )

    DO WHILE !Eof() .AND. AllTrim( DIA_B->D_ASIENT ) == AllTrim( cAsiento )
        IF NetRLock()
            DIA_B->( DbDelete() )
            DbUnlock()
        ENDIF
        DbSkip()
    ENDDO

    DIA_B->( DbCloseArea() )

RETURN NIL


// ============================================================================
// FIN DE M_Conta.prg
// ============================================================================
