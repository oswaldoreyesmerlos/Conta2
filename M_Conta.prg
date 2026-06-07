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
    oGrid:bChange  := NIL

    oGrid:AddColumn( "Cuenta",      10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Nombre",      40, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "Nivel",       3, "9",          { |a| a[3] } )
    oGrid:AddColumn( "Tipo",        2, "@!",         { |a| a[4] } )
    oGrid:AddColumn( "Naturaleza",  2, "@!",         { |a| a[5] } )
    oGrid:AddColumn( "Suma en",    10, "@!",         { |a| a[6] } )
    oGrid:AddColumn( "Saldo Act.", 14, "999,999.99", { |a| a[7] } )
    oGrid:AddColumn( "Baja",         4, "@!",         { |a| If( a[8], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        If( g:CurrentRow() != NIL, PlanCuentasForm( g:CurrentRow()[1] ), NIL ), ;
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

    IF !ABRIR_TABLA( "CATALOGO", "CATF", "CAT_CTA" )
        RETURN NIL
    ENDIF

    IF !lNuevo
        DbSelectArea( "CATF" )
        OrdSetFocus( "CAT_CTA" )
        IF DbSeek( AllTrim( cCuenta ) )
            cCuenta_  := PadR( AllTrim( CATF->CUENTA   ), 10 )
            cNombre  := PadR( AllTrim( CATF->NOMBRE   ), 60 )
            nNivel   := CATF->NIVEL
            cTipo    := PadR( AllTrim( CATF->TIPO     ),  1 )
            cNaturale := PadR( AllTrim( CATF->NATURALE ),  1 )
            cSumaEn  := PadR( AllTrim( CATF->SUMA_EN  ), 10 )
            nSaldoAn  := CATF->SALDO_AN
            nDebeAnu  := CATF->DEBE_ANU
            nHaberAnu  := CATF->HABER_AN
            nSaldoAc  := CATF->SALDO_AC
            nPresupue := CATF->PRESUPUE
            lBloqued  := CATF->BLOQUEAD
            lReqAnal  := CATF->REQ_ANAL
            lEsBanco  := CATF->ES_BANCO
            lBaja     := CATF->BAJA
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

    CATF->( DbCloseArea() )
    Select( nArea )

RETURN NIL


STATIC FUNCTION _CatGuardar( oGC, oGN, oGi, oGT, oGNt, ;
                             oGS, oGSA, oGDA, oGHA, oGSAc, oGPre, ;
                             oCB, oCA, oCBc, oCBj, ;
                             lNuevo, oWin )

    LOCAL cCuenta

    cCuenta := AllTrim( oGC:uVar )

    DbSelectArea( "CATF" )
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

    REPLACE CATF->CUENTA   WITH cCuenta
    REPLACE CATF->NOMBRE   WITH AllTrim( oGN:uVar  )
    REPLACE CATF->NIVEL    WITH oGi:uVar
    REPLACE CATF->TIPO     WITH AllTrim( oGT:uVar  )
    REPLACE CATF->NATURALE WITH AllTrim( oGNt:uVar )
    REPLACE CATF->SUMA_EN  WITH AllTrim( oGS:uVar  )
    REPLACE CATF->SALDO_AN WITH oGSA:uVar
    REPLACE CATF->DEBE_ANU WITH oGDA:uVar
    REPLACE CATF->HABER_AN WITH oGHA:uVar
    REPLACE CATF->SALDO_AC WITH oGSAc:uVar
    REPLACE CATF->PRESUPUE WITH oGPre:uVar
    REPLACE CATF->BLOQUEAD WITH oCB:lValue
    REPLACE CATF->REQ_ANAL WITH oCA:lValue
    REPLACE CATF->ES_BANCO WITH oCBc:lValue
    REPLACE CATF->BAJA     WITH oCBj:lValue

    IF lNuevo
        REPLACE CATF->FECHA_AL WITH Date()
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


FUNCTION LibroDiarioNuevo()
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
        If( lNuevo, "NUEVO ASIENTO", "VER ASIENTO: " + cAsientoDisp ) )

    oWin:AddCtrl( TLabel():New(  2,  2, "Asiento :", oWin ) )
    oWin:AddCtrl( TLabel():New(  2, 40, "Fecha   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Descripcion:", oWin ) )

    oWin:AddCtrl( TLabel():New(  2, 70, "Usuario:", oWin ) )

    oGAsi := TLabel():New(  2, 14, PadR( cAsientoDisp, 24 ), oWin )
    oGAsi:cColor := "W+/B"
    oWin:AddCtrl( oGAsi )

    oGFec := TGet():New(  2, 52, dFecha, "99/99/9999", oWin )
    IF !lNuevo
        oGFec:bWhen := {|| .F. }
    ENDIF
    oWin:AddCtrl( oGFec )

    oGDes := TGet():New(  4, 14, cDescrip, "@!", oWin )
    IF !lNuevo
        oGDes:bWhen := {|| .F. }
    ENDIF
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

    IF lNuevo
        oGrid:bEnter := {| g | _DiaEditLin( g, @aLineas, oGrid ) }

        oBtNLin := TButton():New( 32,  2, 33, 18, oWin, "NUEVA LINEA (F5)", ;
            {|| _DiaNuevaLin( oGrid, @aLineas ) } )

        oBtELin := TButton():New( 32, 20, 33, 38, oWin, "EDITAR LINEA", ;
            {|| _DiaEditLin( oGrid, @aLineas ) } )

        oBtDLin := TButton():New( 32, 38, 33, 56, oWin, "BORRAR LINEA", ;
            {|| _DiaBorrarLin( oGrid, @aLineas ) } )

        oBtGua := TButton():New( 33, 63, 34, 82, oWin, "GUARDAR", ;
            {|| _DiaGuardar( oGAsi, oGFec, oGDes, aLineas, lNuevo, oWin ) } )
    ENDIF

    oBtCan := TButton():New( 33, 86, 34, 105, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid   )
    IF lNuevo
        oWin:AddCtrl( oBtNLin )
        oWin:AddCtrl( oBtELin )
        oWin:AddCtrl( oBtDLin )
        oWin:AddCtrl( oBtGua  )
    ENDIF
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

    Select( nArea )

RETURN NIL


STATIC FUNCTION _DiaCargarCab( cAsiento, cAsi, dFec, cDes, cUsr )

    IF !ABRIR_TABLA( "LDIARIO", "DIA_CC", "DIA_ASI" )
        RETURN .F.
    ENDIF

    DbSelectArea( "DIA_CC" )
    OrdSetFocus( "DIA_ASI" )

    IF !DbSeek( PadR( cAsiento, 10 ) + "   1" )
        MsgStop( "Asiento " + cAsiento + " no encontrado.", "Error" )
        DIA_CC->( DbCloseArea() )
        RETURN .F.
    ENDIF

    cAsi := AllTrim( DIA_CC->D_ASIENT )
    dFec := DIA_CC->D_FECHA
    cDes := AllTrim( DIA_CC->D_DESCRI )
    cUsr := AllTrim( DIA_CC->USUARIO_ )

    DIA_CC->( DbCloseArea() )

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

    IF !lNuevo
        MsgStop( "Un asiento ya grabado no se modifica." + Chr(13) + ;
                 "Use un contraasiento o un asiento de ajuste.", ;
                 "Asiento contabilizado" )
        RETURN NIL
    ENDIF

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
// AsientoAutomatico( cTipo, cNumDoc )
// ----------------------------------------------------------------------------
// Genera el asiento contable de un documento ya grabado.
// cTipo  : "FAC" factura emitida / "COM" factura compra / "REC" recibo caja
//          "PAG" pago a proveedor
// cNumDoc: numero del documento
//
// Cuentas utilizadas (configuracion estandar PGC):
//   FAC : D 430xxx Cliente   H 700 Ventas   H 477 IVA repercutido
//   COM : D 600 Compras  D 472 IVA soportado  H 400xxx Proveedor
//   REC : D 570/572 Caja/Banco  H 430xxx Cliente
//   PAG : D 400xxx Proveedor  H 570/572 Caja/Banco
// ============================================================================
FUNCTION AsientoAutomatico( cTipo, cNumDoc )

    LOCAL cTipo_
    LOCAL cNumDoc_
    LOCAL lOK

    cTipo_   := Upper( AllTrim( cTipo   ) )
    cNumDoc_ := AllTrim( cNumDoc )
    lOK      := .F.

    IF Empty( cTipo_ ) .OR. Empty( cNumDoc_ )
        MsgStop( "Tipo y numero de documento son obligatorios.", "Asiento" )
        RETURN .F.
    ENDIF

    DO CASE
    CASE cTipo_ == "FAC"
        lOK := _AsiFactura( cNumDoc_ )
    CASE cTipo_ == "COM"
        lOK := _AsiCompra( cNumDoc_ )
    CASE cTipo_ == "REC"
        lOK := _AsiRecibo( cNumDoc_ )
    CASE cTipo_ == "PAG"
        lOK := _AsiPago( cNumDoc_ )
    CASE cTipo_ == "CER"
        lOK := _AsiCertificacion( cNumDoc_ )
    OTHERWISE
        MsgStop( "Tipo de documento desconocido: " + cTipo_, "Asiento" )
    ENDCASE

RETURN lOK


STATIC FUNCTION _AsiFactura( cNumFac )

    LOCAL cAsi
    LOCAL dFec
    LOCAL cCli
    LOCAL cCtaCli
    LOCAL nBase
    LOCAL nIva
    LOCAL nTotal
    LOCAL cConc
    LOCAL lAsientoOK

    // Cargar datos de la factura
    IF !ABRIR_TABLA( "FACTURA", "FAC_AS", "FAC_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "FAC_AS" )
    OrdSetFocus( "FAC_NUM" )

    IF !DbSeek( PadR( "A", 4 ) + PadR( cNumFac, 10 ) )
        FAC_AS->( DbCloseArea() )
        MsgStop( "Factura " + cNumFac + " no encontrada.", "Asiento" )
        RETURN .F.
    ENDIF

    IF !Empty( AllTrim( FAC_AS->ASIENTO ) )
        FAC_AS->( DbCloseArea() )
        MsgStop( "La factura " + cNumFac + " ya tiene asiento: " + ;
                 AllTrim( FAC_AS->ASIENTO ), "Asiento" )
        RETURN .F.
    ENDIF

    dFec   := FAC_AS->FECHA
    cCli   := AllTrim( FAC_AS->CLIENTE_ )
    nBase  := FAC_AS->SUBTOTAL
    nIva   := FAC_AS->IVA
    nTotal := FAC_AS->TOTAL

    FAC_AS->( DbCloseArea() )

    // Cuenta contable del cliente
    cCtaCli := "430"
    IF ABRIR_TABLA( "CLIENTES", "CLI_AS", "CLI_ID" )
        IF CLI_AS->( DbSeek( cCli ) ) .AND. !Empty( AllTrim( CLI_AS->CTA_CONT ) )
            cCtaCli := AllTrim( CLI_AS->CTA_CONT )
        ENDIF
        CLI_AS->( DbCloseArea() )
    ENDIF

    cAsi  := GetNextNum( "ASI" + AllTrim( Str( Year( Date() ) ) ), "Asientos" )
    IF Empty( cAsi )
        RETURN .F.
    ENDIF

    cConc := "Factura " + cNumFac + " / " + cCli
    lAsientoOK := .F.

    IF !ABRIR_TABLA( "LDIARIO", "DIA_AS", "DIA_ASI" )
        RETURN .F.
    ENDIF

    DbSelectArea( "DIA_AS" )

    IF NetFLock()

        // D 430xxx Cliente
        DbAppend()
        REPLACE DIA_AS->D_ASIENT WITH cAsi
        REPLACE DIA_AS->D_LINEA  WITH 1
        REPLACE DIA_AS->D_FECHA  WITH dFec
        REPLACE DIA_AS->D_CUENTA WITH cCtaCli
        REPLACE DIA_AS->D_DEBE   WITH nTotal
        REPLACE DIA_AS->D_HABER  WITH 0
        REPLACE DIA_AS->D_DESCRI WITH cConc
        REPLACE DIA_AS->TIP_ORIG WITH "FAC"
        REPLACE DIA_AS->DOC_ORIG WITH cNumFac

        // H 700 Ventas
        DbAppend()
        REPLACE DIA_AS->D_ASIENT WITH cAsi
        REPLACE DIA_AS->D_LINEA  WITH 2
        REPLACE DIA_AS->D_FECHA  WITH dFec
        REPLACE DIA_AS->D_CUENTA WITH "700"
        REPLACE DIA_AS->D_DEBE   WITH 0
        REPLACE DIA_AS->D_HABER  WITH nBase
        REPLACE DIA_AS->D_DESCRI WITH cConc
        REPLACE DIA_AS->TIP_ORIG WITH "FAC"
        REPLACE DIA_AS->DOC_ORIG WITH cNumFac

        // H 477 IVA repercutido
        IF nIva > 0
            DbAppend()
            REPLACE DIA_AS->D_ASIENT WITH cAsi
            REPLACE DIA_AS->D_LINEA  WITH 3
            REPLACE DIA_AS->D_FECHA  WITH dFec
            REPLACE DIA_AS->D_CUENTA WITH "477"
            REPLACE DIA_AS->D_DEBE   WITH 0
            REPLACE DIA_AS->D_HABER  WITH nIva
            REPLACE DIA_AS->D_DESCRI WITH cConc
            REPLACE DIA_AS->TIP_ORIG WITH "FAC"
            REPLACE DIA_AS->DOC_ORIG WITH cNumFac
        ENDIF

        DbCommit()
        DbUnlock()
        lAsientoOK := .T.

    ENDIF

    DIA_AS->( DbCloseArea() )

    IF !lAsientoOK
        MsgStop( "No se pudo bloquear el diario. La factura no se ha marcado como contabilizada.", ;
                 "Asiento" )
        RETURN .F.
    ENDIF

    // Actualizar referencia asiento en la factura
    IF ABRIR_TABLA( "FACTURA", "FAC_AU", "FAC_NUM" )
        DbSelectArea( "FAC_AU" )
        OrdSetFocus( "FAC_NUM" )
        IF DbSeek( PadR( "A", 4 ) + PadR( cNumFac, 10 ) ) .AND. NetRLock()
            REPLACE FAC_AU->ASIENTO WITH cAsi
            DbUnlock()
        ENDIF
        FAC_AU->( DbCloseArea() )
    ENDIF

    MsgInfo( "Asiento " + cAsi + " generado para factura " + cNumFac, "Asiento" )

RETURN .T.


STATIC FUNCTION _AsiCertificacion( cIdCert )

   LOCAL cAsi
   LOCAL dFec
   LOCAL cCli
   LOCAL cCtaCli
   LOCAL nBase
   LOCAL nIva
   LOCAL nTotal
   LOCAL cConc
   LOCAL lAsientoOK
   LOCAL cIdObra
   LOCAL nArea := Select()

   IF !ABRIR_TABLA( "CERTIFICA", "CER_AS", "CERT_NUM" )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbSelectArea( "CER_AS" )
   OrdSetFocus( "CERT_NUM" )

   IF !( DbSeek( PadR( AllTrim( cIdCert ), 12 ) ) .OR. DbSeek( AllTrim( cIdCert ) ) )
      CER_AS->( DbCloseArea() )
      MsgStop( "Certificacion " + cIdCert + " no encontrada.", "Asiento" )
      Select( nArea )
      RETURN .F.
   ENDIF

   IF !Empty( AllTrim( DbFieldValue( "ASIENTO", "" ) ) )
      CER_AS->( DbCloseArea() )
      MsgStop( "Certificacion " + cIdCert + " ya tiene asiento.", "Asiento" )
      Select( nArea )
      RETURN .F.
   ENDIF

   dFec    := CER_AS->FECHA
   nBase   := CER_AS->BASE
   nIva    := CER_AS->IVA
   nTotal  := CER_AS->TOTAL
   cIdObra := AllTrim( CER_AS->ID_OBRA )

   CER_AS->( DbCloseArea() )
   Select( nArea )

   cCli := ""
   IF ABRIR_TABLA( "OBRAS", "OBR_AS", "OBR_ID" )
      DbSelectArea( "OBR_AS" )
      OrdSetFocus( "OBR_ID" )
      IF DbSeek( PadR( cIdObra, 12 ) ) .OR. DbSeek( cIdObra )
         cCli := AllTrim( OBR_AS->CLIENTE_ )
      ENDIF
      OBR_AS->( DbCloseArea() )
   ENDIF

   cCtaCli := "430"
   IF !Empty( cCli ) .AND. ABRIR_TABLA( "CLIENTES", "CLI_AC", "CLI_ID" )
      DbSelectArea( "CLI_AC" )
      OrdSetFocus( "CLI_ID" )
      IF CLI_AC->( DbSeek( cCli ) ) .AND. !Empty( AllTrim( CLI_AC->CTA_CONT ) )
         cCtaCli := AllTrim( CLI_AC->CTA_CONT )
      ENDIF
      CLI_AC->( DbCloseArea() )
   ENDIF

   cAsi := GetNextNum( "ASI" + AllTrim( Str( Year( Date() ) ) ), "Asientos" )
   IF Empty( cAsi )
      Select( nArea )
      RETURN .F.
   ENDIF

   cConc := "Certificacion " + cIdCert + " / " + cCli
   lAsientoOK := .F.

   IF !ABRIR_TABLA( "LDIARIO", "DIA_AC", "DIA_ASI" )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbSelectArea( "DIA_AC" )

   IF NetFLock()
      DbAppend()
      REPLACE DIA_AC->D_ASIENT WITH cAsi
      REPLACE DIA_AC->D_LINEA  WITH 1
      REPLACE DIA_AC->D_FECHA  WITH dFec
      REPLACE DIA_AC->D_CUENTA WITH PadR( cCtaCli, 10 )
      REPLACE DIA_AC->D_DEBE   WITH nTotal
      REPLACE DIA_AC->D_HABER  WITH 0.00
      REPLACE DIA_AC->D_DESCRI WITH cConc
      REPLACE DIA_AC->TIP_ORIG WITH "CER"
      REPLACE DIA_AC->DOC_ORIG WITH cIdCert

      DbAppend()
      REPLACE DIA_AC->D_ASIENT WITH cAsi
      REPLACE DIA_AC->D_LINEA  WITH 2
      REPLACE DIA_AC->D_FECHA  WITH dFec
      REPLACE DIA_AC->D_CUENTA WITH "7050000"
      REPLACE DIA_AC->D_DEBE   WITH 0.00
      REPLACE DIA_AC->D_HABER  WITH nBase
      REPLACE DIA_AC->D_DESCRI WITH cConc
      REPLACE DIA_AC->TIP_ORIG WITH "CER"
      REPLACE DIA_AC->DOC_ORIG WITH cIdCert

      IF nIva > 0
         DbAppend()
         REPLACE DIA_AC->D_ASIENT WITH cAsi
         REPLACE DIA_AC->D_LINEA  WITH 3
         REPLACE DIA_AC->D_FECHA  WITH dFec
         REPLACE DIA_AC->D_CUENTA WITH "4770000"
         REPLACE DIA_AC->D_DEBE   WITH 0.00
         REPLACE DIA_AC->D_HABER  WITH nIva
         REPLACE DIA_AC->D_DESCRI WITH cConc
         REPLACE DIA_AC->TIP_ORIG WITH "CER"
         REPLACE DIA_AC->DOC_ORIG WITH cIdCert
      ENDIF

      DbCommit()
      DbUnlock()
      lAsientoOK := .T.
   ENDIF

   DIA_AC->( DbCloseArea() )

   IF !lAsientoOK
      MsgStop( "No se pudo bloquear el diario.", "Asiento" )
      Select( nArea )
      RETURN .F.
   ENDIF

   IF ABRIR_TABLA( "CERTIFICA", "CER_AU", "CERT_NUM" )
      DbSelectArea( "CER_AU" )
      OrdSetFocus( "CERT_NUM" )
      IF DbSeek( PadR( AllTrim( cIdCert ), 12 ) ) .AND. NetRLock()
         REPLACE CER_AU->ASIENTO WITH cAsi
         DbUnlock()
      ENDIF
      CER_AU->( DbCloseArea() )
   ENDIF

   MsgInfo( "Asiento " + cAsi + " generado para certificacion " + cIdCert, "Asiento" )
   Select( nArea )

RETURN .T.


STATIC FUNCTION _AsiCompra( cNumCom )

    LOCAL cAsi
    LOCAL dFec
    LOCAL cPrv
    LOCAL cCtaPrv
    LOCAL nBase
    LOCAL nIva
    LOCAL nTotal
    LOCAL cConc
    LOCAL lAsientoOK

    IF !ABRIR_TABLA( "COMPRAS", "COM_AS", "COM_INT" )
        RETURN .F.
    ENDIF

    DbSelectArea( "COM_AS" )
    OrdSetFocus( "COM_INT" )

    IF !DbSeek( cNumCom )
        COM_AS->( DbCloseArea() )
        MsgStop( "Compra " + cNumCom + " no encontrada.", "Asiento" )
        RETURN .F.
    ENDIF

    IF !Empty( AllTrim( COM_AS->ASIENTO ) )
        COM_AS->( DbCloseArea() )
        MsgStop( "Esta compra ya tiene asiento: " + AllTrim( COM_AS->ASIENTO ), "Asiento" )
        RETURN .F.
    ENDIF

    dFec   := COM_AS->FECHA
    cPrv   := AllTrim( COM_AS->PROV_ID  )
    nBase  := COM_AS->SUBTOTAL
    nIva   := COM_AS->IVA
    nTotal := COM_AS->TOTAL

    COM_AS->( DbCloseArea() )

    cCtaPrv := "400"
    IF ABRIR_TABLA( "PROVEED", "PRV_AS", "PRV_ID" )
        IF PRV_AS->( DbSeek( cPrv ) ) .AND. !Empty( AllTrim( PRV_AS->CTA_CONT ) )
            cCtaPrv := AllTrim( PRV_AS->CTA_CONT )
        ENDIF
        PRV_AS->( DbCloseArea() )
    ENDIF

    cAsi  := GetNextNum( "ASI" + AllTrim( Str( Year( Date() ) ) ), "Asientos" )
    IF Empty( cAsi )
        RETURN .F.
    ENDIF

    cConc := "Compra " + cNumCom + " / " + cPrv
    lAsientoOK := .F.

    IF !ABRIR_TABLA( "LDIARIO", "DIA_C", "DIA_ASI" )
        RETURN .F.
    ENDIF

    DbSelectArea( "DIA_C" )

    IF NetFLock()

        // D 600 Compras
        DbAppend()
        REPLACE DIA_C->D_ASIENT WITH cAsi
        REPLACE DIA_C->D_LINEA  WITH 1
        REPLACE DIA_C->D_FECHA  WITH dFec
        REPLACE DIA_C->D_CUENTA WITH "600"
        REPLACE DIA_C->D_DEBE   WITH nBase
        REPLACE DIA_C->D_HABER  WITH 0
        REPLACE DIA_C->D_DESCRI WITH cConc
        REPLACE DIA_C->TIP_ORIG WITH "COM"
        REPLACE DIA_C->DOC_ORIG WITH cNumCom

        // D 472 IVA soportado
        IF nIva > 0
            DbAppend()
            REPLACE DIA_C->D_ASIENT WITH cAsi
            REPLACE DIA_C->D_LINEA  WITH 2
            REPLACE DIA_C->D_FECHA  WITH dFec
            REPLACE DIA_C->D_CUENTA WITH "472"
            REPLACE DIA_C->D_DEBE   WITH nIva
            REPLACE DIA_C->D_HABER  WITH 0
            REPLACE DIA_C->D_DESCRI WITH cConc
            REPLACE DIA_C->TIP_ORIG WITH "COM"
            REPLACE DIA_C->DOC_ORIG WITH cNumCom
        ENDIF

        // H 400xxx Proveedor
        DbAppend()
        REPLACE DIA_C->D_ASIENT WITH cAsi
        REPLACE DIA_C->D_LINEA  WITH 3
        REPLACE DIA_C->D_FECHA  WITH dFec
        REPLACE DIA_C->D_CUENTA WITH cCtaPrv
        REPLACE DIA_C->D_DEBE   WITH 0
        REPLACE DIA_C->D_HABER  WITH nTotal
        REPLACE DIA_C->D_DESCRI WITH cConc
        REPLACE DIA_C->TIP_ORIG WITH "COM"
        REPLACE DIA_C->DOC_ORIG WITH cNumCom

        DbCommit()
        DbUnlock()
        lAsientoOK := .T.

    ENDIF

    DIA_C->( DbCloseArea() )

    IF !lAsientoOK
        MsgStop( "No se pudo bloquear el diario. La compra no se ha marcado como contabilizada.", ;
                 "Asiento" )
        RETURN .F.
    ENDIF

    IF ABRIR_TABLA( "COMPRAS", "COM_AU", "COM_INT" )
        DbSelectArea( "COM_AU" )
        OrdSetFocus( "COM_INT" )
        IF DbSeek( cNumCom ) .AND. NetRLock()
            REPLACE COM_AU->ASIENTO WITH cAsi
            DbUnlock()
        ENDIF
        COM_AU->( DbCloseArea() )
    ENDIF

    MsgInfo( "Asiento " + cAsi + " generado para compra " + cNumCom, "Asiento" )

RETURN .T.


STATIC FUNCTION _AsiPago( cNumCom )

    LOCAL cAsi
    LOCAL dFec
    LOCAL cPrv
    LOCAL cCtaPrv
    LOCAL cCtaHaber
    LOCAL nTotal
    LOCAL cConc
    LOCAL lAsientoOK

    IF !ABRIR_TABLA( "COMPRAS", "COM_PG", "COM_INT" )
        RETURN .F.
    ENDIF

    DbSelectArea( "COM_PG" )
    OrdSetFocus( "COM_INT" )

    IF !DbSeek( cNumCom )
        COM_PG->( DbCloseArea() )
        MsgStop( "Compra " + cNumCom + " no encontrada.", "Asiento pago" )
        RETURN .F.
    ENDIF

    dFec   := Date()
    cPrv   := AllTrim( COM_PG->PROV_ID )
    nTotal := COM_PG->TOTAL

    COM_PG->( DbCloseArea() )

    cCtaPrv   := "400"
    cCtaHaber := "572"

    IF ABRIR_TABLA( "PROVEED", "PRV_PG", "PRV_ID" )
        IF PRV_PG->( DbSeek( cPrv ) ) .AND. !Empty( AllTrim( PRV_PG->CTA_CONT ) )
            cCtaPrv := AllTrim( PRV_PG->CTA_CONT )
        ENDIF
        PRV_PG->( DbCloseArea() )
    ENDIF

    cAsi  := GetNextNum( "ASI" + AllTrim( Str( Year( Date() ) ) ), "Asientos" )
    IF Empty( cAsi )
        RETURN .F.
    ENDIF

    cConc := "Pago compra " + cNumCom + " / " + cPrv
    lAsientoOK := .F.

    IF !ABRIR_TABLA( "LDIARIO", "DIA_PG", "DIA_ASI" )
        RETURN .F.
    ENDIF

    DbSelectArea( "DIA_PG" )

    IF NetFLock()
        DbAppend()
        REPLACE DIA_PG->D_ASIENT WITH cAsi
        REPLACE DIA_PG->D_LINEA  WITH 1
        REPLACE DIA_PG->D_FECHA  WITH dFec
        REPLACE DIA_PG->D_CUENTA WITH cCtaPrv
        REPLACE DIA_PG->D_DEBE   WITH nTotal
        REPLACE DIA_PG->D_HABER  WITH 0
        REPLACE DIA_PG->D_DESCRI WITH cConc
        REPLACE DIA_PG->TIP_ORIG WITH "PAG"
        REPLACE DIA_PG->DOC_ORIG WITH cNumCom

        DbAppend()
        REPLACE DIA_PG->D_ASIENT WITH cAsi
        REPLACE DIA_PG->D_LINEA  WITH 2
        REPLACE DIA_PG->D_FECHA  WITH dFec
        REPLACE DIA_PG->D_CUENTA WITH cCtaHaber
        REPLACE DIA_PG->D_DEBE   WITH 0
        REPLACE DIA_PG->D_HABER  WITH nTotal
        REPLACE DIA_PG->D_DESCRI WITH cConc
        REPLACE DIA_PG->TIP_ORIG WITH "PAG"
        REPLACE DIA_PG->DOC_ORIG WITH cNumCom

        DbCommit()
        DbUnlock()
        lAsientoOK := .T.
    ENDIF

    DIA_PG->( DbCloseArea() )

    IF !lAsientoOK
        MsgStop( "No se pudo bloquear el diario. No se ha generado el asiento de pago.", ;
                 "Asiento" )
        RETURN .F.
    ENDIF

    MsgInfo( "Asiento " + cAsi + " generado para pago " + cNumCom, "Asiento" )

RETURN .T.


STATIC FUNCTION _AsiRecibo( cNumRec )

    LOCAL cAsi
    LOCAL dFec
    LOCAL cCli
    LOCAL cCtaCli
    LOCAL cCtaDebe
    LOCAL nTotal
    LOCAL cConc
    LOCAL lAsientoOK

    IF !ABRIR_TABLA( "RECIBOS", "REC_AS", "REC_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "REC_AS" )
    OrdSetFocus( "REC_NUM" )

    IF !DbSeek( cNumRec )
        REC_AS->( DbCloseArea() )
        MsgStop( "Recibo " + cNumRec + " no encontrado.", "Asiento" )
        RETURN .F.
    ENDIF

    IF !Empty( AllTrim( REC_AS->ASIENTO ) )
        REC_AS->( DbCloseArea() )
        MsgStop( "Este recibo ya tiene asiento: " + AllTrim( REC_AS->ASIENTO ), "Asiento" )
        RETURN .F.
    ENDIF

    dFec   := REC_AS->FECHA
    cCli   := AllTrim( REC_AS->CLIENTE_ )
    nTotal := REC_AS->TOTAL

    REC_AS->( DbCloseArea() )

    cCtaCli  := "430"
    cCtaDebe := "570"

    IF ABRIR_TABLA( "CLIENTES", "CLI_RA", "CLI_ID" )
        IF CLI_RA->( DbSeek( cCli ) ) .AND. !Empty( AllTrim( CLI_RA->CTA_CONT ) )
            cCtaCli := AllTrim( CLI_RA->CTA_CONT )
        ENDIF
        CLI_RA->( DbCloseArea() )
    ENDIF

    cAsi  := GetNextNum( "ASI" + AllTrim( Str( Year( Date() ) ) ), "Asientos" )
    IF Empty( cAsi )
        RETURN .F.
    ENDIF

    cConc := "Cobro recibo " + cNumRec + " / " + cCli
    lAsientoOK := .F.

    IF !ABRIR_TABLA( "LDIARIO", "DIA_R", "DIA_ASI" )
        RETURN .F.
    ENDIF

    DbSelectArea( "DIA_R" )

    IF NetFLock()

        DbAppend()
        REPLACE DIA_R->D_ASIENT WITH cAsi
        REPLACE DIA_R->D_LINEA  WITH 1
        REPLACE DIA_R->D_FECHA  WITH dFec
        REPLACE DIA_R->D_CUENTA WITH cCtaDebe
        REPLACE DIA_R->D_DEBE   WITH nTotal
        REPLACE DIA_R->D_HABER  WITH 0
        REPLACE DIA_R->D_DESCRI WITH cConc
        REPLACE DIA_R->TIP_ORIG WITH "REC"
        REPLACE DIA_R->DOC_ORIG WITH cNumRec

        DbAppend()
        REPLACE DIA_R->D_ASIENT WITH cAsi
        REPLACE DIA_R->D_LINEA  WITH 2
        REPLACE DIA_R->D_FECHA  WITH dFec
        REPLACE DIA_R->D_CUENTA WITH cCtaCli
        REPLACE DIA_R->D_DEBE   WITH 0
        REPLACE DIA_R->D_HABER  WITH nTotal
        REPLACE DIA_R->D_DESCRI WITH cConc
        REPLACE DIA_R->TIP_ORIG WITH "REC"
        REPLACE DIA_R->DOC_ORIG WITH cNumRec

        DbCommit()
        DbUnlock()
        lAsientoOK := .T.

    ENDIF

    DIA_R->( DbCloseArea() )

    IF !lAsientoOK
        MsgStop( "No se pudo bloquear el diario. El recibo no se ha marcado como contabilizado.", ;
                 "Asiento" )
        RETURN .F.
    ENDIF

    IF ABRIR_TABLA( "RECIBOS", "REC_AU", "REC_NUM" )
        DbSelectArea( "REC_AU" )
        OrdSetFocus( "REC_NUM" )
        IF DbSeek( cNumRec ) .AND. NetRLock()
            REPLACE REC_AU->ASIENTO WITH cAsi
            DbUnlock()
        ENDIF
        REC_AU->( DbCloseArea() )
    ENDIF

    MsgInfo( "Asiento " + cAsi + " generado para recibo " + cNumRec, "Asiento" )

RETURN .T.


// ============================================================================
// CierreEjercicio()
// ----------------------------------------------------------------------------
// Proceso de cierre contable anual.
// Pasos:
//   1. Verificar que no hay asientos sin cuadrar (D != H)
//   2. Generar asiento de regularizacion (cierre cuentas P&G)
//   3. Generar asiento de cierre (saldos a cuenta 129 Resultado)
//   4. Generar asiento de apertura del nuevo ejercicio
//   5. Marcar ejercicio como cerrado en EMPRESA
//
// IMPORTANTE: ejecutar con copia de seguridad previa.
// Solo accesible para ADM.
// ============================================================================
FUNCTION CierreEjercicio()

    LOCAL nYear, nNext
    LOCAL aBal   := {}
    LOCAL aPgAux := {}
    LOCAL nDebe, nHaber
    LOCAL hBal
    LOCAL i
    LOCAL cMsg
    LOCAL aReg  := {}
    LOCAL aCie  := {}
    LOCAL aApe  := {}
    LOCAL nSaldo
    LOCAL cAsiReg, cAsiCie, cAsiApe
    LOCAL lOk := .F.

    nYear := _EjInputYear()
    IF nYear == 0
        RETURN .F.
    ENDIF

    IF nYear >= Year( Date() )
        MsgStop( "No se puede cerrar el ejercicio en curso o futuro.", "Cierre" )
        RETURN .F.
    ENDIF

    IF !MsgYesNo( "Va a cerrar el ejercicio " + AllTrim( Str( nYear ) ) + "." + Chr(13) + ;
                  "Se generaran automaticamente:" + Chr(13) + ;
                  "- Asiento de regularizacion (cuentas 6/7 a 129)" + Chr(13) + ;
                  "- Asiento de cierre (balance a 129)" + Chr(13) + ;
                  "- Asiento de apertura " + AllTrim( Str( nYear + 1 ) ) + Chr(13) + ;
                  Chr(13) + "Tenga una copia de seguridad antes de continuar." + Chr(13) + ;
                  Chr(13) + "Desea continuar?", "Cierre ejercicio" )
        RETURN .F.
    ENDIF

    // -- 1. Verificar asientos cuadrados en LDIARIO --
    IF !ABRIR_TABLA( "LDIARIO", "DIA_CJ", "DIA_FEC" )
        RETURN .F.
    ENDIF

    DbSelectArea( "DIA_CJ" )
    OrdSetFocus( "DIA_FEC" )
    DbSeek( DToS( CToD( "01/01/" + AllTrim( Str( nYear ) ) ) ) )

    nDebe  := 0
    nHaber := 0
    aPgAux := {}

    DO WHILE !Eof() .AND. Year( DIA_CJ->D_FECHA ) == nYear
        nDebe   += DIA_CJ->D_DEBE
        nHaber  += DIA_CJ->D_HABER
        AAdd( aPgAux, { DIA_CJ->D_ASIENT, DIA_CJ->D_LINEA, ;
                        DIA_CJ->D_CUENTA, DIA_CJ->D_DEBE, DIA_CJ->D_HABER, ;
                        DIA_CJ->D_DESCRI, DIA_CJ->D_FECHA, DIA_CJ->TIP_ORIG, ;
                        DIA_CJ->DOC_ORIG } )
        DbSkip()
    ENDDO

    DIA_CJ->( DbCloseArea() )

    IF nDebe == 0 .AND. nHaber == 0
        MsgStop( "El ejercicio " + AllTrim( Str( nYear ) ) + ;
                 " no tiene movimientos contables.", "Cierre" )
        RETURN .F.
    ENDIF

    // Verificar cuadre por asiento
    ASort( aPgAux,,, {|x,y| x[1] < y[1] } )
    nDebe  := 0
    nHaber := 0
    FOR i := 1 TO Len( aPgAux )
        nDebe  += aPgAux[i, 4]
        nHaber += aPgAux[i, 5]
        IF i == Len( aPgAux ) .OR. aPgAux[i, 1] != aPgAux[i+1, 1]
            IF Abs( nDebe - nHaber ) > 0.005
                MsgStop( "El asiento " + AllTrim( aPgAux[i, 1] ) + ;
                         " no esta cuadrado (" + AllTrim( Str( nDebe, 16, 2 ) ) + ;
                         " / " + AllTrim( Str( nHaber, 16, 2 ) ) + ").", "Cierre" )
                RETURN .F.
            ENDIF
            nDebe  := 0
            nHaber := 0
        ENDIF
    NEXT

    // -- 2. Acumular saldos por cuenta --
    aBal := {}
    FOR i := 1 TO Len( aPgAux )
        hBal := AScan( aBal, {|x| x[1] == aPgAux[i, 3] } )
        IF hBal == 0
            AAdd( aBal, { aPgAux[i, 3], aPgAux[i, 4], aPgAux[i, 5] } )
        ELSE
            aBal[hBal, 2] += aPgAux[i, 4]
            aBal[hBal, 3] += aPgAux[i, 5]
        ENDIF
    NEXT

    // -- 3. Generar asiento de regularizacion (cuentas 6/7 a 129) --
    cAsiReg := _EjGenAsiento( nYear, 1, aBal, "REGULARIZACION", @aReg )
    IF Empty( cAsiReg )
        RETURN .F.
    ENDIF

    // -- 4. Generar asiento de cierre --
    cAsiCie := _EjGenAsiento( nYear, 2, aBal, "CIERRE", @aCie )
    IF Empty( cAsiCie )
        RETURN .F.
    ENDIF

    // -- 5. Generar asiento de apertura --
    nNext := nYear + 1
    cAsiApe := _EjGenAsiento( nNext, 3, aBal, "APERTURA", @aApe )
    IF Empty( cAsiApe )
        RETURN .F.
    ENDIF

    // -- 6. Mostrar resumen y confirmar escritura --
    cMsg := "RESUMEN DEL CIERRE DE " + AllTrim( Str( nYear ) ) + Chr(13) + ;
            Chr(13) + ;
            "Asiento de regularizacion: " + cAsiReg + Chr(13) + ;
            "  Lineas: " + AllTrim( Str( Len( aReg ) ) ) + Chr(13) + ;
            Chr(13) + ;
            "Asiento de cierre: " + cAsiCie + Chr(13) + ;
            "  Lineas: " + AllTrim( Str( Len( aCie ) ) ) + Chr(13) + ;
            Chr(13) + ;
            "Asiento de apertura " + AllTrim( Str( nNext ) ) + ": " + cAsiApe + Chr(13) + ;
            "  Lineas: " + AllTrim( Str( Len( aApe ) ) ) + Chr(13) + ;
            Chr(13) + ;
            "Se escribiran " + AllTrim( Str( Len( aReg ) + Len( aCie ) + Len( aApe ) ) ) + ;
            " lineas en LDIARIO." + Chr(13) + ;
            Chr(13) + "Desea grabar los asientos?"

    IF !MsgYesNo( cMsg, "Confirmar cierre" )
        RETURN .F.
    ENDIF

    // -- 7. Escribir asientos --
    BEGIN SEQUENCE
        IF !_EjGuardarAsiento( cAsiReg, "REGULARIZACION " + AllTrim( Str( nYear ) ), ;
                               CToD( "31/12/" + AllTrim( Str( nYear ) ) ), aReg )
            BREAK
        ENDIF

        IF !_EjGuardarAsiento( cAsiCie, "CIERRE " + AllTrim( Str( nYear ) ), ;
                               CToD( "31/12/" + AllTrim( Str( nYear ) ) ), aCie )
            BREAK
        ENDIF

        IF !_EjGuardarAsiento( cAsiApe, "APERTURA " + AllTrim( Str( nNext ) ), ;
                               CToD( "01/01/" + AllTrim( Str( nNext ) ) ), aApe )
            BREAK
        ENDIF

        BEGIN TRANSACTION
            IF ABRIR_TABLA( "EMPRESA", "EMP_CJ", "" )
                IF NetFLock()
                    EMP_CJ->FEC_CIER := CToD( "31/12/" + AllTrim( Str( nYear ) ) )
                    DbUnlock()
                ENDIF
                EMP_CJ->( DbCloseArea() )
            ENDIF
        END TRANSACTION

        lOk := .T.

    RECOVER
        lOk := .F.
        MsgStop( "Error al escribir los asientos. " + ;
                 "Los datos pueden quedar inconsistentes.", "Error" )
    END SEQUENCE

    IF lOk
        MsgInfo( "Cierre del ejercicio " + AllTrim( Str( nYear ) ) + ;
                 " completado." + Chr(13) + ;
                 "Asientos generados:" + Chr(13) + ;
                 "  " + cAsiReg + " (regularizacion)" + Chr(13) + ;
                 "  " + cAsiCie + " (cierre)" + Chr(13) + ;
                 "  " + cAsiApe + " (apertura)", "Cierre" )
    ENDIF

RETURN lOk


// ============================================================================
// _EjGenAsiento(cYear, nTipo, aBal, cPrefijo, aLineas)
// Genera las lineas de un asiento de cierre/regularizacion/apertura
//   nTipo: 1=Regularizacion, 2=Cierre, 3=Apertura
//   aBal  := { { cCuenta, nDebe, nHaber }, ... }
//   aLineas := { { nLinea, cCuenta, nDebe, nHaber, cDescrip }, ... }
// Retorna el numero de asiento o "" si error
// ============================================================================
STATIC FUNCTION _EjGetCat()

    LOCAL aCat := {}
    LOCAL nArea := Select()

    IF !ABRIR_TABLA( "CATALOGO", "CAT_EJ", "CAT_CTA" )
        RETURN aCat
    ENDIF

    DbSelectArea( "CAT_EJ" )
    DbGoTop()
    DO WHILE !Eof()
        AAdd( aCat, { CAT_EJ->CUENTA, CAT_EJ->TIPO, CAT_EJ->NATURALE, ;
                      CAT_EJ->NIVEL, CAT_EJ->NOMBRE } )
        DbSkip()
    ENDDO
    CAT_EJ->( DbCloseArea() )
    Select( nArea )

RETURN aCat


STATIC FUNCTION _EjGetUsuario()

    LOCAL cUsr := "SISTEMA"
    MEMVAR cUserID
    IF Type( "cUserID" ) == "C" .AND. !Empty( cUserID )
        cUsr := PadR( AllTrim( cUserID ), 10 )
    ENDIF
RETURN cUsr


STATIC FUNCTION _EjGenAsiento( nYear, nTipo, aBal, cPrefijo, aLineas )

    LOCAL aCat
    LOCAL i, h
    LOCAL nSaldo
    LOCAL nDebe := 0
    LOCAL nHaber := 0
    LOCAL nResult := 0
    LOCAL nLin := 0
    LOCAL cCta

    aLineas := {}
    aCat := _EjGetCat()
    IF Empty( aCat )
        RETURN ""
    ENDIF

    DO CASE
    CASE nTipo == 1    // REGULARIZACION: cerrar 6/7 contra 129
        nResult := 0
        FOR i := 1 TO Len( aBal )
            cCta := aBal[i, 1]
            h := AScan( aCat, {|x| x[1] == cCta .AND. ( x[2] == "G" .OR. x[2] == "I" ) } )
            IF h == 0
                LOOP
            ENDIF
            nSaldo := aBal[i, 2] - aBal[i, 3]
            IF nSaldo == 0
                LOOP
            ENDIF

            nLin++
            IF aCat[h, 2] == "G"     // Gasto: cerrar con Haber
                AAdd( aLineas, { nLin, cCta, 0, nSaldo, "REG " + aCat[h, 5] } )
                nHaber += nSaldo
                nResult -= nSaldo
            ELSE                     // Ingreso: cerrar con Debe
                AAdd( aLineas, { nLin, cCta, nSaldo, 0, "REG " + aCat[h, 5] } )
                nDebe += nSaldo
                nResult += nSaldo
            ENDIF
        NEXT

        IF nLin == 0
            MsgStop( "No hay cuentas de gasto/ingreso en el ejercicio.", "Cierre" )
            RETURN ""
        ENDIF

        nLin++
        nSaldo := Abs( nDebe - nHaber )
        IF nResult >= 0  // Beneficio
            AAdd( aLineas, { nLin, "129", nSaldo, 0, "REG RESULTADO DEL EJERCICIO" } )
        ELSE              // Perdida
            AAdd( aLineas, { nLin, "129", 0, nSaldo, "REG RESULTADO DEL EJERCICIO" } )
        ENDIF

    CASE nTipo == 2    // CIERRE: cerrar balance contra 129
        nDebe := 0; nHaber := 0
        FOR i := 1 TO Len( aBal )
            cCta := aBal[i, 1]
            h := AScan( aCat, {|x| x[1] == cCta .AND. ;
                                   ( x[2] == "A" .OR. x[2] == "P" .OR. x[2] == "N" ) } )
            IF h == 0
                LOOP
            ENDIF
            nSaldo := aBal[i, 2] - aBal[i, 3]
            IF nSaldo == 0
                LOOP
            ENDIF

            nLin++
            IF aCat[h, 3] == "D"    // Deudora: saldo a credito
                AAdd( aLineas, { nLin, cCta, 0, nSaldo, "CIE " + aCat[h, 5] } )
                nHaber += nSaldo
            ELSE                     // Acreedora: saldo a debito
                AAdd( aLineas, { nLin, cCta, nSaldo, 0, "CIE " + aCat[h, 5] } )
                nDebe += nSaldo
            ENDIF
        NEXT

        // Incluir 129 (resultado del ejercicio)
        h := AScan( aBal, {|x| x[1] == "129" } )
        IF h > 0
            nSaldo := aBal[h, 2] - aBal[h, 3]
            IF Abs( nSaldo ) > 0.005
                nLin++
                IF nSaldo > 0
                    AAdd( aLineas, { nLin, "129", nSaldo, 0, "CIE RESULTADO DEL EJERCICIO" } )
                    nDebe += nSaldo
                ELSE
                    AAdd( aLineas, { nLin, "129", 0, -nSaldo, "CIE RESULTADO DEL EJERCICIO" } )
                    nHaber += -nSaldo
                ENDIF
            ENDIF
        ENDIF

        IF nLin == 0
            MsgStop( "No hay cuentas de balance que cerrar.", "Cierre" )
            RETURN ""
        ENDIF

        // Diferencia a 129 (debe cuadrar a cero)
        nSaldo := Abs( nDebe - nHaber )
        IF nSaldo > 0.005
            nLin++
            IF nDebe > nHaber
                AAdd( aLineas, { nLin, "129", 0, nSaldo, "CIE AJUSTE CIERRE" } )
            ELSE
                AAdd( aLineas, { nLin, "129", nSaldo, 0, "CIE AJUSTE CIERRE" } )
            ENDIF
        ENDIF

    CASE nTipo == 3    // APERTURA: invertir saldos del balance
        FOR i := 1 TO Len( aBal )
            cCta := aBal[i, 1]
            h := AScan( aCat, {|x| x[1] == cCta .AND. ;
                                   ( x[2] == "A" .OR. x[2] == "P" .OR. x[2] == "N" ) } )
            IF h == 0
                LOOP
            ENDIF
            nSaldo := aBal[i, 2] - aBal[i, 3]
            IF nSaldo == 0
                LOOP
            ENDIF

            nLin++
            IF aCat[h, 3] == "D"
                AAdd( aLineas, { nLin, cCta, nSaldo, 0, "APE " + aCat[h, 5] } )
            ELSE
                AAdd( aLineas, { nLin, cCta, 0, nSaldo, "APE " + aCat[h, 5] } )
            ENDIF
        NEXT

        // Incluir 129 con saldo invertido
        h := AScan( aBal, {|x| x[1] == "129" } )
        IF h > 0
            nSaldo := aBal[h, 2] - aBal[h, 3]
            IF Abs( nSaldo ) > 0.005
                nLin++
                AAdd( aLineas, { nLin, "129", 0, nSaldo, "APE RESULTADO DEL EJERCICIO" } )
            ENDIF
        ENDIF

        IF nLin == 0
            MsgStop( "No hay cuentas que abrir.", "Cierre" )
            RETURN ""
        ENDIF

    ENDCASE

RETURN GetNextNum( "ASI" + AllTrim( Str( nYear ) ), "Asientos " + AllTrim( Str( nYear ) ) )


STATIC FUNCTION _EjGuardarAsiento( cAsi, cDesc, dFec, aLineas )

    LOCAL i

    IF Empty( cAsi )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "LDIARIO", "DIA_EJ", "DIA_ASI" )
        RETURN .F.
    ENDIF

    DbSelectArea( "DIA_EJ" )

    IF !NetFLock()
        DIA_EJ->( DbCloseArea() )
        RETURN .F.
    ENDIF

    FOR i := 1 TO Len( aLineas )
        DbAppend()
        REPLACE DIA_EJ->D_ASIENT WITH cAsi
        REPLACE DIA_EJ->D_LINEA  WITH aLineas[i, 1]
        REPLACE DIA_EJ->D_FECHA  WITH dFec
        REPLACE DIA_EJ->D_CUENTA WITH aLineas[i, 2]
        REPLACE DIA_EJ->D_DEBE   WITH aLineas[i, 3]
        REPLACE DIA_EJ->D_HABER  WITH aLineas[i, 4]
        REPLACE DIA_EJ->D_DESCRI WITH cDesc + " (" + aLineas[i, 5] + ")"
        REPLACE DIA_EJ->TIP_ORIG WITH "CIE"
        REPLACE DIA_EJ->DOC_ORIG WITH cAsi
        REPLACE DIA_EJ->USUARIO_ WITH _EjGetUsuario()
        REPLACE DIA_EJ->FECHA_AL WITH Date()
    NEXT

    DbCommit()
    DbUnlock()
    DIA_EJ->( DbCloseArea() )

RETURN .T.


STATIC FUNCTION _EjInputYear()

    LOCAL oWin, oGet, oBtn
    LOCAL cYear := Str( Year( Date() ), 4 )
    LOCAL nYear := 0
    LOCAL lOk := .F.

    oWin := TWindow():New( 8, 40, 16, 76, "Cierre de ejercicio" )
    oWin:AddCtrl( TLabel():New(  2,  3, "Ejercicio a cerrar:", oWin ) )
    oGet := TGet():New( 2, 24, cYear, "9999", oWin )
    oBtn := TButton():New( 4, 10, "[  Aceptar  ]", oWin )
    oBtn:bAction := {|| lOk := .T., oWin:Close() }

    oWin:Activate( ,,, {|| oGet:SetFocus() } )

    IF lOk
        nYear := Val( cYear )
    ENDIF

RETURN nYear


// ============================================================================
// FIN DE M_Conta.prg
// ============================================================================
