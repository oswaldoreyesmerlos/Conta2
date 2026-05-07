/*
 * ARCHIVO  : V_Presupuesto.prg
 * PROPOSITO: Gestion completa de presupuestos.
 *
 * FUNCIONES PUBLICAS
 * ------------------
 *   PresupuestosView()    - grid listado de presupuestos
 *   AltaPresupuesto()     - alta directa de presupuesto nuevo
 *
 * NUMERACION
 * ----------
 *   Formato : P + año 4 digitos + 4 digitos secuencial
 *   Ejemplo : P20260001
 *   Se asigna AL GRABAR, no al abrir el formulario.
 *
 * LINEAS EN MEMORIA
 * -----------------
 *   { nLinea, cDesc, nCant, nPrecio, nDto, nPorcIva, nImporte }
 */

#include "OOp.ch"

#define LIN_NUM   1
#define LIN_DESC  2
#define LIN_CANT  3
#define LIN_PRE   4
#define LIN_DTO   5
#define LIN_IVA   6
#define LIN_IMP   7

#define IVA_DEF   21.00
#define MAX_LINS  20


// ============================================================================
// PresupuestosView()
// ============================================================================
FUNCTION PresupuestosView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE", "PRE_FEC" )
        RETURN NIL
    ENDIF

    aData := _PreCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "PRESUPUESTOS" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 3

    oGrid:AddColumn( "Numero",    10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Fecha",     10, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "Cliente",   35, "@!",         { |a| a[3] } )
    oGrid:AddColumn( "Base",      12, "999,999.99", { |a| a[4] } )
    oGrid:AddColumn( "IVA",       10, "999,999.99", { |a| a[5] } )
    oGrid:AddColumn( "Total",     12, "999,999.99", { |a| a[6] } )
    oGrid:AddColumn( "Estado",     8, "@!",         { |a| a[7] } )
    oGrid:AddColumn( "F.Actual",  10, "@!",         { |a| a[8] } )

    oGrid:bEnter := {| g | ;
        _PreEditar( g:CurrentRow()[1] ), ;
        aData := _PreCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "ENTER: ver/editar   F5: nuevo presupuesto   Letras: buscar cliente", oWin )

    oBtNvo := TButton():New( 33,  2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| AltaPresupuesto(), ;
            aData := _PreCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtFac := TButton():New( 33, 20, 34, 38, oWin, "FACTURAR", ;
        {|| If( oGrid:CurrentRow() != NIL, ;
               ConvertirAFactura( oGrid:CurrentRow()[1] ), NIL ), ;
            aData := _PreCargar(), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } )

    oBtRec := TButton():New( 33, 40, 34, 58, oWin, "RECHAZAR", ;
        {|| If( oGrid:CurrentRow() != NIL, ;
               RechazarPresupuesto( oGrid:CurrentRow()[1] ), NIL ), ;
            aData := _PreCargar(), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 33, 108, 34, 124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLbl   )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtFac )
    oWin:AddCtrl( oBtRec )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    PRE->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _PreCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "PRE" )
    OrdSetFocus( "PRE_FEC" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( PRE->NUMERO   ), ;
                DToC(    PRE->FECHA    ), ;
                AllTrim( PRE->CLIENTE_ ), ;
                PRE->SUBTOTAL, ;
                PRE->IVA, ;
                PRE->TOTAL, ;
                If( PRE->ESTADO == "F", "FACTURADO", If( PRE->ESTADO == "A", "ACEPTADO", "PENDIENTE" ) ), ;
                AllTrim( PRE->NUM_FAC ) } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


// ============================================================================
// AltaPresupuesto / _PreEditar
// ============================================================================
FUNCTION AltaPresupuesto()
RETURN _PreForm( "", NIL )

STATIC FUNCTION _PreEditar( cNumero )
RETURN _PreForm( cNumero, NIL )


// ============================================================================
// _PreForm
// ============================================================================
STATIC FUNCTION _PreForm( cNumero, cNumFac )

    LOCAL oWin
    LOCAL lNuevo
    LOCAL nArea
    LOCAL cCliID
    LOCAL cCliNom
    LOCAL dFecha
    LOCAL dValidez
    LOCAL cFormPag
    LOCAL nDias
    LOCAL nPorcRet
    LOCAL cObserva
    LOCAL cPieDoc
    LOCAL lAnulada
    LOCAL aLineas
    LOCAL nBase
    LOCAL nIva
    LOCAL nRet
    LOCAL nTotal
    LOCAL oGCli
    LOCAL oGFec
    LOCAL oGVal
    LOCAL oGFP
    LOCAL oGDias
    LOCAL oGRet
    LOCAL oGObs
    LOCAL oLNumero
    LOCAL oLCliNom
    LOCAL oLBase
    LOCAL oLIva
    LOCAL oLRet
    LOCAL oLTotal
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL oBtImp
    LOCAL oBtNLin
    LOCAL oBtELin
    LOCAL oBtDLin
    LOCAL oGrid

    lNuevo   := Empty( AllTrim( cNumero ) )
    nArea    := Select()
    cCliID   := Space( 10 )
    cCliNom  := Space( 50 )
    dFecha   := Date()
    dValidez := Date() + 30
    cFormPag := Space(  3 )
    nDias    := 0
    nPorcRet := 0.00
    cObserva := Space( 60 )
    cPieDoc  := ""
    lAnulada := .F.
    aLineas  := {}
    nBase    := 0.00
    nIva     := 0.00
    nRet     := 0.00
    nTotal   := 0.00

    _PreCargarEmpPie( @cPieDoc )

    IF !lNuevo
        IF !_PreCargarCab( cNumero, @cCliID, @cCliNom, @dFecha, @dValidez, ;
                             @cFormPag, @nDias, @nPorcRet, @cObserva, @lAnulada )
            RETURN NIL
        ENDIF
        _PreCargarLins( cNumero, @aLineas )
    ENDIF

    _PreCalcTot( aLineas, nPorcRet, @nBase, @nIva, @nRet, @nTotal )

    oWin := TWindow():New( 1, 2, 37, 129, ;
        If( lNuevo, "NUEVO PRESUPUESTO", "PRESUPUESTO: " + cNumero ) )

    oWin:AddCtrl( TLabel():New(  2,  2, "Numero    :", oWin ) )
    oWin:AddCtrl( TLabel():New(  2, 40, "Fecha     :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Cliente   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 40, "Validez   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Forma pago:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 40, "Dias pago :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 70, "Ret.IRPF %:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Observ.   :", oWin ) )

    oLNumero := TLabel():New( 2, 14, PadR( If( lNuevo, "(se asigna al grabar)", cNumero ), 24 ), oWin )
    oLNumero:cColor := "W+/B"
    oWin:AddCtrl( oLNumero )

    oGCli := TGet():New( 4, 14, cCliID, "@!", oWin )
    oGCli:bValid := {| o | _PreBuscarCli( o, @cCliNom, @cFormPag, ;
                                               @nDias, @nPorcRet, oWin ) }

    oLCliNom := TLabel():New( 4, 40, PadR( cCliNom, 50 ), oWin )
    oWin:AddCtrl( oLCliNom )

    oGFec  := TGet():New(  2, 52, dFecha,   "99/99/9999", oWin )
    oGVal  := TGet():New(  4, 52, dValidez, "99/99/9999", oWin )
    oGFP   := TGet():New(  6, 14, cFormPag, "@!",         oWin )
    oGDias := TGet():New(  6, 52, nDias,    "999",        oWin )
    oGRet  := TGet():New(  6, 82, nPorcRet, "99.99",      oWin )
    oGObs  := TGet():New(  8, 14, cObserva, "@!",         oWin )

    oGrid := TGrid():New( 10, 2, 26, 124, oWin )
    oGrid:aData    := aLineas
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "#",          3, "999",       { |a| a[LIN_NUM]  } )
    oGrid:AddColumn( "Descripcion",53, "@!",        { |a| a[LIN_DESC] } )
    oGrid:AddColumn( "Cantidad",   8, "9,999.99",  { |a| a[LIN_CANT] } )
    oGrid:AddColumn( "Precio",    10, "9,999.99",  { |a| a[LIN_PRE]  } )
    oGrid:AddColumn( "Dto %",      6, "99.99",     { |a| a[LIN_DTO]  } )
    oGrid:AddColumn( "IVA %",      6, "99.99",     { |a| a[LIN_IVA]  } )
    oGrid:AddColumn( "Importe",   12, "99,999.99", { |a| a[LIN_IMP]  } )

    oGrid:bEnter := {| g | ;
        _PreEditLin( g, @aLineas, nPorcRet, ;
                     @nBase, @nIva, @nRet, @nTotal, ;
                     oLBase, oLIva, oLRet, oLTotal ) }

    oWin:AddCtrl( TLabel():New( 26,  2, "BASE IMPONIBLE :", oWin ) )
    oWin:AddCtrl( TLabel():New( 27,  2, "TOTAL IVA      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 28,  2, "RETENCION IRPF :", oWin ) )
    oWin:AddCtrl( TLabel():New( 29,  2, "TOTAL PRESUP.:", oWin ) )

    oLBase  := TLabel():New( 26, 20, _FmtNP( nBase  ), oWin )
    oLIva   := TLabel():New( 27, 20, _FmtNP( nIva   ), oWin )
    oLRet   := TLabel():New( 28, 20, _FmtNP( nRet   ), oWin )
    oLTotal := TLabel():New( 29, 20, _FmtNP( nTotal ), oWin )
    oLTotal:cColor := "W+/B"

    oWin:AddCtrl( oLBase  )
    oWin:AddCtrl( oLIva   )
    oWin:AddCtrl( oLRet   )
    oWin:AddCtrl( oLTotal )

    oBtNLin := TButton():New( 26, 60, 27, 78, oWin, "NUEVA LINEA (F5)", ;
        {|| _PreNuevaLin( oGrid, @aLineas, nPorcRet, ;
                          @nBase, @nIva, @nRet, @nTotal, ;
                          oLBase, oLIva, oLRet, oLTotal ) } )

    oBtELin := TButton():New( 26, 80, 27, 98, oWin, "EDITAR LINEA", ;
        {|| _PreEditLin( oGrid, @aLineas, nPorcRet, ;
                         @nBase, @nIva, @nRet, @nTotal, ;
                         oLBase, oLIva, oLRet, oLTotal ) } )

    oBtDLin := TButton():New( 26,100, 27,118, oWin, "BORRAR LINEA", ;
        {|| _PreBorrarLin( oGrid, @aLineas, nPorcRet, ;
                           @nBase, @nIva, @nRet, @nTotal, ;
                           oLBase, oLIva, oLRet, oLTotal ) } )

    oBtGua := TButton():New( 33,  2, 34, 18, oWin, "GUARDAR", ;
        {|| _PreGuardar( oGCli, oGFec, oGVal, oGFP, oGDias, oGRet, oGObs, ;
                           aLineas, cPieDoc, cNumero, lNuevo, ;
                           nBase, nIva, nRet, nTotal, oLNumero, oWin ) } )

    oBtImp := TButton():New( 33, 20, 34, 36, oWin, "IMPRIMIR", ;
        {|| ImprimirPresupuesto( cNumero ) } )

    oBtCan := TButton():New( 33,108, 34,124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGCli   )
    oWin:AddCtrl( oGFec   )
    oWin:AddCtrl( oGVal   )
    oWin:AddCtrl( oGFP    )
    oWin:AddCtrl( oGDias  )
    oWin:AddCtrl( oGRet   )
    oWin:AddCtrl( oGObs   )
    oWin:AddCtrl( oGrid   )
    oWin:AddCtrl( oBtNLin )
    oWin:AddCtrl( oBtELin )
    oWin:AddCtrl( oBtDLin )
    oWin:AddCtrl( oBtGua  )
    oWin:AddCtrl( oBtImp  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

    Select( nArea )

RETURN NIL


// ============================================================================
// HELPERS DE CARGA
// ============================================================================

STATIC FUNCTION _PreCargarEmpPie( cPie )

    IF ABRIR_TABLA( "EMPRESA", "EMP_P", "" )
        EMP_P->( DbGoTop() )
        IF !EMP_P->( Eof() )
            cPie := EMP_P->PIE_DOC
        ENDIF
        EMP_P->( DbCloseArea() )
    ENDIF

RETURN NIL


STATIC FUNCTION _PreCargarCab( cNum, cCli, cNom, dFec, dVal, cFP, nDias, nRet, cObs, lAnu )

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_C", "PRE_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PRE_C" )
    OrdSetFocus( "PRE_NUM" )

    IF !DbSeek( cNum )
        MsgStop( "Presupuesto " + cNum + " no encontrado.", "Error" )
        RETURN .F.
    ENDIF

    cCli  := AllTrim( PRE_C->CLIENTE_ )
    dFec  := PRE_C->FECHA
    dVal  := PRE_C->VALIDEZ
    cFP   := AllTrim( PRE_C->FORMA_PA )
    nRet  := PRE_C->PORC_RET
    cObs  := AllTrim( PRE_C->OBSERVA  )
    lAnu  := ( PRE_C->ESTADO == "A" .OR. PRE_C->ESTADO == "F" )

    IF ABRIR_TABLA( "CLIENTES", "CLI_P", "CLI_ID" )
        IF CLI_P->( DbSeek( cCli ) )
            cNom := AllTrim( CLI_P->NOMBRE + " " + CLI_P->APELLIDO )
        ENDIF
        CLI_P->( DbCloseArea() )
    ENDIF

RETURN .T.


STATIC FUNCTION _PreCargarLins( cNum, aLins )

    LOCAL nL

    nL   := 0
    aLins := {}

    IF !ABRIR_TABLA( "PRESUP_DE", "PRD_C", "PRD_LIN" )
        RETURN NIL
    ENDIF

    DbSelectArea( "PRD_C" )
    OrdSetFocus( "PRD_LIN" )
    DbSeek( PadR( cNum, 10 ) + "  1" )

    DO WHILE !Eof() .AND. AllTrim( PRD_C->NUMERO ) == AllTrim( cNum )
        IF !Deleted()
            nL++
            AAdd( aLins, { ;
                nL, ;
                AllTrim( PRD_C->DESCRIPC ), ;
                PRD_C->CANTIDAD, ;
                PRD_C->PRECIO, ;
                PRD_C->DESCUENT, ;
                PRD_C->PORC_IVA, ;
                PRD_C->IMPORTE } )
        ENDIF
        DbSkip()
    ENDDO

    PRD_C->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _PreBuscarCli( oGet, cNom, cFP, nDias, nRet, oWin )

    LOCAL cId

    cId := AllTrim( oGet:uVar )

    IF Empty( cId )
        RETURN .T.
    ENDIF

    IF !ABRIR_TABLA( "CLIENTES", "CLI_BP", "CLI_ID" )
        RETURN .T.
    ENDIF

    IF CLI_BP->( DbSeek( cId ) )
        cNom  := AllTrim( CLI_BP->NOMBRE + " " + CLI_BP->APELLIDO )
        cFP   := AllTrim( CLI_BP->FORPAGO )
        nDias := CLI_BP->DIAS_PAG
        nRet  := If( CLI_BP->APL_IRPF, 15.00, 0.00 )
    ELSE
        MsgStop( "Cliente " + cId + " no encontrado.", "Busqueda" )
        CLI_BP->( DbCloseArea() )
        RETURN .F.
    ENDIF

    CLI_BP->( DbCloseArea() )

    oWin:Refresh()

RETURN .T.


// ============================================================================
// CALCULOS
// ============================================================================

STATIC FUNCTION _PreCalcTot( aLins, nPRet, nBase, nIva, nRet, nTotal )

    LOCAL i

    nBase := 0
    nIva  := 0

    FOR i := 1 TO Len( aLins )
        nBase += aLins[i, LIN_IMP]
        nIva  += aLins[i, LIN_IMP] * aLins[i, LIN_IVA] / 100
    NEXT

    nRet   := nBase * nPRet / 100
    nTotal := nBase + nIva - nRet

RETURN NIL


STATIC FUNCTION _FmtNP( nVal )
RETURN Transform( nVal, "999,999.99" )


STATIC FUNCTION _ActTotales( aLins, nPRet, nBase, nIva, nRet, nTotal, ;
                               oLBase, oLIva, oLRet, oLTotal )

    _PreCalcTot( aLins, nPRet, @nBase, @nIva, @nRet, @nTotal )

    oLBase:SetText(  _FmtNP( nBase  ) )
    oLIva:SetText(   _FmtNP( nIva   ) )
    oLRet:SetText(   _FmtNP( nRet   ) )
    oLTotal:SetText( _FmtNP( nTotal ) )

RETURN NIL


// ============================================================================
// GESTION DE LINEAS
// ============================================================================

STATIC FUNCTION _PreNuevaLin( oGrid, aLins, nPRet, nBase, nIva, nRet, nTotal, ;
                                oLBase, oLIva, oLRet, oLTotal )

    LOCAL nNum
    LOCAL aLin

    nNum := Len( aLins ) + 1

    IF nNum > MAX_LINS
        MsgStop( "Maximo " + AllTrim( Str( MAX_LINS ) ) + " lineas.", "Limite" )
        RETURN NIL
    ENDIF

    aLin := { nNum, "", 1, 0.00, 0.00, IVA_DEF, 0.00 }

    IF _PreFormLin( @aLin, .T. )
        AAdd( aLins, aLin )
        oGrid:aData   := aLins
        oGrid:nCurRow := Len( aLins )
        oGrid:Paint()
        _ActTotales( aLins, nPRet, @nBase, @nIva, @nRet, @nTotal, ;
                     oLBase, oLIva, oLRet, oLTotal )
    ENDIF

RETURN NIL


STATIC FUNCTION _PreEditLin( oGrid, aLins, nPRet, nBase, nIva, nRet, nTotal, ;
                               oLBase, oLIva, oLRet, oLTotal )

    LOCAL nPos
    LOCAL aLin

    nPos := oGrid:nCurRow

    IF nPos < 1 .OR. nPos > Len( aLins )
        RETURN NIL
    ENDIF

    aLin := AClone( aLins[nPos] )

    IF _PreFormLin( @aLin, .F. )
        aLins[nPos] := aLin
        oGrid:aData  := aLins
        oGrid:Paint()
        _ActTotales( aLins, nPRet, @nBase, @nIva, @nRet, @nTotal, ;
                     oLBase, oLIva, oLRet, oLTotal )
    ENDIF

RETURN NIL


STATIC FUNCTION _PreBorrarLin( oGrid, aLins, nPRet, nBase, nIva, nRet, nTotal, ;
                                 oLBase, oLIva, oLRet, oLTotal )

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
        aLins[i, LIN_NUM] := i
    NEXT

    IF oGrid:nCurRow > Len( aLins ) .AND. Len( aLins ) > 0
        oGrid:nCurRow := Len( aLins )
    ENDIF

    oGrid:aData := aLins
    oGrid:Paint()

    _ActTotales( aLins, nPRet, @nBase, @nIva, @nRet, @nTotal, ;
                 oLBase, oLIva, oLRet, oLTotal )

RETURN NIL


STATIC FUNCTION _PreFormLin( aLin, lNuevo )

    LOCAL oWin
    LOCAL oGDesc
    LOCAL oGCant
    LOCAL oGPre
    LOCAL oGDto
    LOCAL oGIva
    LOCAL oLImp
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL bRecalc
    LOCAL lOK
    LOCAL cDesc
    LOCAL nCant
    LOCAL nPre
    LOCAL nDto
    LOCAL nIva
    LOCAL nImp

    lOK   := .F.
    cDesc := PadR( aLin[LIN_DESC], 60 )
    nCant := aLin[LIN_CANT]
    nPre  := aLin[LIN_PRE]
    nDto  := aLin[LIN_DTO]
    nIva  := aLin[LIN_IVA]
    nImp  := aLin[LIN_IMP]

    oWin := TWindow():New( 10, 15, 26, 115, ;
        If( lNuevo, "NUEVA LINEA", "EDITAR LINEA " + AllTrim( Str( aLin[LIN_NUM] ) ) ) )

    oWin:AddCtrl( TLabel():New( 2,  3, "Descripcion :", oWin ) )
    oWin:AddCtrl( TLabel():New( 4,  3, "Cantidad    :", oWin ) )
    oWin:AddCtrl( TLabel():New( 4, 35, "Precio unit.:", oWin ) )
    oWin:AddCtrl( TLabel():New( 6,  3, "Dto. %      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 6, 35, "IVA %       :", oWin ) )
    oWin:AddCtrl( TLabel():New( 8,  3, "IMPORTE     :", oWin ) )

    oGDesc := TGet():New( 2, 17, cDesc, "@!", oWin )
    oGDesc:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGCant := TGet():New( 4, 17, nCant, "9,999.99", oWin )
    oGPre  := TGet():New( 4, 48, nPre,  "9,999.99", oWin )
    oGDto  := TGet():New( 6, 17, nDto,  "99.99",    oWin )
    oGIva  := TGet():New( 6, 48, nIva,  "99.99",    oWin )

    oLImp := TLabel():New( 8, 17, _FmtNP( nImp ), oWin )
    oLImp:cColor := "W+/B"
    oWin:AddCtrl( oLImp )

    bRecalc := {|| ;
        nImp := ( oGCant:uVar * oGPre:uVar ) * ( 1 - oGDto:uVar / 100 ), ;
        oLImp:SetText( _FmtNP( nImp ) ), ;
        .T. }

    oGCant:bValid := bRecalc
    oGPre:bValid  := bRecalc
    oGDto:bValid  := bRecalc

    oBtGua := TButton():New( 11, 25, 12, 44, oWin, "ACEPTAR", ;
        {|| lOK := .T., oWin:Close() } )

    oBtCan := TButton():New( 11, 48, 12, 67, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGDesc )
    oWin:AddCtrl( oGCant )
    oWin:AddCtrl( oGPre  )
    oWin:AddCtrl( oGDto  )
    oWin:AddCtrl( oGIva  )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lOK
        aLin[LIN_DESC] := AllTrim( oGDesc:uVar )
        aLin[LIN_CANT] := oGCant:uVar
        aLin[LIN_PRE]  := oGPre:uVar
        aLin[LIN_DTO]  := oGDto:uVar
        aLin[LIN_IVA]  := oGIva:uVar
        aLin[LIN_IMP]  := ( oGCant:uVar * oGPre:uVar ) * ( 1 - oGDto:uVar / 100 )
    ENDIF

RETURN lOK


// ============================================================================
// GUARDAR
// ============================================================================
STATIC FUNCTION _PreGuardar( oGCli, oGFec, oGVal, oGFP, oGDias, oGRet, oGObs, ;
                               aLins, cPieDoc, cNumero, lNuevo, ;
                               nBase, nIva, nRet, nTotal, oLNumero, oWin )

    LOCAL cCli
    LOCAL dFec
    LOCAL dVal
    LOCAL cFP
    LOCAL nDias
    LOCAL nPRet
    LOCAL cObs
    LOCAL cNum
    LOCAL i

    cCli  := AllTrim( oGCli:uVar  )
    dFec  := oGFec:uVar
    dVal  := oGVal:uVar
    cFP   := AllTrim( oGFP:uVar   )
    nDias := oGDias:uVar
    nPRet := oGRet:uVar
    cObs  := AllTrim( oGObs:uVar  )
    cNum  := cNumero

    IF Empty( cCli )
        MsgStop( "Debe indicar el cliente.", "Guardar" )
        RETURN NIL
    ENDIF

    IF Len( aLins ) == 0
        MsgStop( "Debe introducir al menos una linea.", "Guardar" )
        RETURN NIL
    ENDIF

    IF lNuevo
        cNum := _PreSiguiente()
        IF Empty( cNum )
            RETURN NIL
        ENDIF
    ENDIF

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_G", "PRE_NUM" )
        RETURN NIL
    ENDIF

    DbSelectArea( "PRE_G" )
    OrdSetFocus( "PRE_NUM" )

    IF lNuevo
        IF !NetFLock()
            RETURN NIL
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cNum ) .OR. !NetRLock()
            RETURN NIL
        ENDIF
    ENDIF

    REPLACE PRE_G->NUMERO   WITH cNum
    REPLACE PRE_G->FECHA    WITH dFec
    REPLACE PRE_G->VALIDEZ  WITH dVal
    REPLACE PRE_G->CLIENTE_ WITH cCli
    REPLACE PRE_G->VENDEDOR WITH Space( 10 )
    REPLACE PRE_G->SUBTOTAL WITH nBase
    REPLACE PRE_G->IVA      WITH nIva
    REPLACE PRE_G->TOTAL    WITH nTotal
    REPLACE PRE_G->ESTADO   WITH "P"
    REPLACE PRE_G->OBSERVA  WITH cObs
    REPLACE PRE_G->PIE_DOC  WITH cPieDoc
    REPLACE PRE_G->PORC_RET WITH nPRet
    REPLACE PRE_G->NUM_FAC  WITH Space( 10 )

    DbUnlock()

    IF !lNuevo
        _PreBorrarLinsDB( cNum )
    ENDIF

    IF !ABRIR_TABLA( "PRESUP_DE", "PRD_G", "PRD_LIN" )
        RETURN NIL
    ENDIF

    DbSelectArea( "PRD_G" )

    IF NetFLock()
        FOR i := 1 TO Len( aLins )
            DbAppend()
            REPLACE PRD_G->NUMERO   WITH cNum
            REPLACE PRD_G->LINEA    WITH i
            REPLACE PRD_G->DESCRIPC WITH aLins[i, LIN_DESC]
            REPLACE PRD_G->CANTIDAD WITH aLins[i, LIN_CANT]
            REPLACE PRD_G->PRECIO   WITH aLins[i, LIN_PRE]
            REPLACE PRD_G->DESCUENT WITH aLins[i, LIN_DTO]
            REPLACE PRD_G->PORC_IVA WITH aLins[i, LIN_IVA]
            REPLACE PRD_G->IMPORTE  WITH aLins[i, LIN_IMP]
        NEXT
        DbUnlock()
    ENDIF

    PRD_G->( DbCloseArea() )

    IF lNuevo
        oLNumero:SetText( PadR( cNum, 24 ) )
        cNumero := cNum
    ENDIF

    MsgInfo( "Presupuesto " + cNum + " guardado.", "Guardado" )

    IF MsgYesNo( "Desea imprimir el presupuesto ahora?", "Imprimir" )
        ImprimirPresupuesto( cNum )
    ENDIF

RETURN NIL


STATIC FUNCTION _PreSiguiente()

    LOCAL cAnio
    LOCAL cCod

    cAnio := AllTrim( Str( Year( Date() ) ) )
    cCod  := "PRE" + cAnio

RETURN GetNextNum( cCod, "Presupuestos " + cAnio )


STATIC FUNCTION _PreBorrarLinsDB( cNum )

    IF !ABRIR_TABLA( "PRESUP_DE", "PRD_B", "PRD_LIN" )
        RETURN NIL
    ENDIF

    DbSelectArea( "PRD_B" )
    OrdSetFocus( "PRD_LIN" )
    DbSeek( PadR( cNum, 10 ) + "  1" )

    DO WHILE !Eof() .AND. AllTrim( PRD_B->NUMERO ) == AllTrim( cNum )
        IF NetRLock()
            PRD_B->( DbDelete() )
            DbUnlock()
        ENDIF
        DbSkip()
    ENDDO

    PRD_B->( DbCloseArea() )

RETURN NIL


// ============================================================================
// ImprimirPresupuesto( cNumero )
// Llama a la funcion de impresion de presupuestos
// ============================================================================
FUNCTION ImprimirPresupuesto( cNumero )

    IF !File( ".\\DATA\\PRESUP_G.DBF" )
        MsgStop( "No existe la tabla de presupuestos", "Error" )
        RETURN .F.
    ENDIF

    IF ValType( cNumero ) != "C" .OR. Empty( cNumero )
        MsgStop( "Numero de presupuesto invalido", "Error" )
        RETURN .F.
    ENDIF

    // Llama a la funcion en V_Imprimir.prg
    ImprimirPresup( cNumero )

RETURN .T.



// ============================================================================
// ConvertirAFactura( cNumPre )
// ----------------------------------------------------------------------------
// Convierte un presupuesto en factura.
// Verifica estado — solo presupuestos pendientes o aceptados se pueden facturar.
// ============================================================================
FUNCTION ConvertirAFactura( cNumPre )

    LOCAL cEstado
    LOCAL cNumFac

    cEstado := ""
    cNumFac := ""

    IF Empty( AllTrim( cNumPre ) )
        MsgStop( "Seleccione un presupuesto.", "Facturar" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_CV", "PRE_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PRE_CV" )
    OrdSetFocus( "PRE_NUM" )

    IF !DbSeek( AllTrim( cNumPre ) )
        PRE_CV->( DbCloseArea() )
        MsgStop( "Presupuesto " + cNumPre + " no encontrado.", "Facturar" )
        RETURN .F.
    ENDIF

    cEstado := AllTrim( PRE_CV->ESTADO  )
    cNumFac := AllTrim( PRE_CV->NUM_FAC )

    PRE_CV->( DbCloseArea() )

    DO CASE
    CASE cEstado == "F"
        MsgStop( "Este presupuesto ya fue facturado." + Chr(13) + ;
                 "Factura: " + cNumFac, "Facturar" )
        RETURN .F.
    CASE cEstado == "R"
        MsgStop( "No se puede facturar un presupuesto rechazado.", "Facturar" )
        RETURN .F.
    ENDCASE

    IF !MsgYesNo( "Convertir presupuesto " + AllTrim( cNumPre ) + ;
                  " en factura?", "Facturar" )
        RETURN .F.
    ENDIF

    AltaFactDesdePre( AllTrim( cNumPre ) )

RETURN .T.


// ============================================================================
// RechazarPresupuesto( cNumPre )
// ----------------------------------------------------------------------------
// Marca un presupuesto como rechazado por el cliente.
// No genera ningun documento — solo cambia el estado.
// ============================================================================
FUNCTION RechazarPresupuesto( cNumPre )

    LOCAL cEstado
    LOCAL cMotivo
    LOCAL oWin
    LOCAL oGMot
    LOCAL oBtOk
    LOCAL oBtCan
    LOCAL lOK

    cEstado := ""
    cMotivo := Space( 60 )
    lOK     := .F.

    IF Empty( AllTrim( cNumPre ) )
        MsgStop( "Seleccione un presupuesto.", "Rechazar" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_RV", "PRE_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PRE_RV" )
    OrdSetFocus( "PRE_NUM" )

    IF !DbSeek( AllTrim( cNumPre ) )
        PRE_RV->( DbCloseArea() )
        MsgStop( "Presupuesto no encontrado.", "Rechazar" )
        RETURN .F.
    ENDIF

    cEstado := AllTrim( PRE_RV->ESTADO )

    PRE_RV->( DbCloseArea() )

    DO CASE
    CASE cEstado == "F"
        MsgStop( "No se puede rechazar un presupuesto ya facturado.", "Rechazar" )
        RETURN .F.
    CASE cEstado == "R"
        MsgStop( "Este presupuesto ya esta rechazado.", "Rechazar" )
        RETURN .F.
    ENDCASE

    // Pedir motivo del rechazo
    IF !MsgYesNo( "Marcar presupuesto " + AllTrim( cNumPre ) + ;
                  " como RECHAZADO?" + Chr(13) + ;
                  "Esta accion no genera documentos adicionales.", "Rechazar" )
        RETURN .F.
    ENDIF

    oWin := TWindow():New( 12, 30, 22, 100, "MOTIVO DEL RECHAZO" )

    oWin:AddCtrl( TLabel():New( 2, 3, "Presupuesto :", oWin ) )
    oWin:AddCtrl( TLabel():New( 2, 17, PadR( AllTrim( cNumPre ), 10 ), oWin ) )
    oWin:AddCtrl( TLabel():New( 4, 3, "Motivo      :", oWin ) )

    oGMot := TGet():New( 4, 17, cMotivo, "@!", oWin )
    oGMot:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) .OR. ;
        ( MsgStop( "Indique el motivo del rechazo.", "Validacion" ), .F. ) }

    oBtOk  := TButton():New( 7, 12, 8, 28, oWin, "CONFIRMAR", ;
        {|| lOK := .T., oWin:Close() } )

    oBtCan := TButton():New( 7, 32, 8, 48, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGMot  )
    oWin:AddCtrl( oBtOk  )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF !lOK
        RETURN .F.
    ENDIF

    cMotivo := AllTrim( oGMot:uVar )

    IF Empty( cMotivo )
        RETURN .F.
    ENDIF

    // Actualizar estado
    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_RM", "PRE_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PRE_RM" )
    OrdSetFocus( "PRE_NUM" )

    IF DbSeek( AllTrim( cNumPre ) ) .AND. NetRLock()
        REPLACE PRE_RM->ESTADO  WITH "R"
        REPLACE PRE_RM->OBSERVA WITH "RECHAZADO: " + cMotivo
        DbUnlock()
    ENDIF

    PRE_RM->( DbCloseArea() )

    MsgInfo( "Presupuesto " + AllTrim( cNumPre ) + " marcado como rechazado.", ;
             "Rechazar" )

RETURN .T.


// ============================================================================
// FIN DE V_Presupuesto.prg
// ============================================================================
