/*
 * ARCHIVO  : V_Facturas.prg
 * PROPOSITO: Gestion completa de facturas emitidas.
 *
 * FUNCIONES PUBLICAS
 * ------------------
 *   FacturasView()           - grid listado de facturas
 *   AltaFact()               - alta directa sin presupuesto/obra
 *
 * NUMERACION
 * ----------
 *   Formato : F + año 4 digitos + 4 digitos secuencial
 *   Ejemplo : F20260001
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
// FacturasView()
// ============================================================================
FUNCTION FacturasView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtAbo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "FACTURA", "FAC", "FAC_FEC" )
        RETURN NIL
    ENDIF

    aData := _FacCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "FACTURAS EMITIDAS" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 3

    oGrid:AddColumn( "Numero",    10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Fecha",     10, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "Cliente",   35, "@!",         { |a| a[3] } )
    oGrid:AddColumn( "Base",      12, "999,999.99", { |a| a[4] } )
    oGrid:AddColumn( "IVA",       10, "999,999.99", { |a| a[5] } )
    oGrid:AddColumn( "Total",     12, "999,999.99", { |a| a[6] } )
    oGrid:AddColumn( "F.Pago",     6, "@!",         { |a| a[7] } )
    oGrid:AddColumn( "Cobrada",    7, "@!",         { |a| If( a[8], "SI", "NO" ) } )
    oGrid:AddColumn( "Anulada",    7, "@!",         { |a| If( a[9], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        _FacEditar( g:CurrentRow()[1] ), ;
        aData := _FacCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "ENTER: ver/editar   Nueva directa desde menu Facturas", oWin )

    oBtAbo := TButton():New( 33, 2, 34, 20, oWin, "NOTA ABONO", ;
        {|| If( oGrid:CurrentRow() != NIL, ;
               NotaAbonoForm( oGrid:CurrentRow()[1] ), NIL ), ;
            aData := _FacCargar(), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 33, 108, 34, 124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLbl   )
    oWin:AddCtrl( oBtAbo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    FAC->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _FacCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "FAC" )
    OrdSetFocus( "FAC_FEC" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( FAC->NUMERO   ), ;
                DToC(    FAC->FECHA    ), ;
                AllTrim( FAC->CLIENTE_ ), ;
                FAC->SUBTOTAL, ;
                FAC->IVA, ;
                FAC->TOTAL, ;
                AllTrim( DbFieldValue( "FORMA_PA", "" ) ), ;
                DbFieldValue( "COBRADA", .F. ), ;
                DbFieldValue( "ANULADA", .F. ) } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


// ============================================================================
// AltaFact / _FacEditar
// ============================================================================
FUNCTION AltaFact()
RETURN _FacForm( "", NIL )


STATIC FUNCTION _FacEditar( cNumero )
RETURN _FacForm( cNumero, NIL )


// ============================================================================
// _FacForm
// ============================================================================
STATIC FUNCTION _FacForm( cNumero, cNumPre )

    LOCAL oWin
    LOCAL lNuevo
    LOCAL nArea
    LOCAL cNumDisp
    LOCAL cCliID
    LOCAL cCliNom
    LOCAL dFecha
    LOCAL cFormPag
    LOCAL nDias
    LOCAL nPorcRet
    LOCAL cObserva
    LOCAL cPieDoc
    LOCAL lAnulada
    LOCAL lCobrada
    LOCAL lInv
    LOCAL aLineas
    LOCAL nBase
    LOCAL nIva
    LOCAL nRet
    LOCAL nTotal
    LOCAL oGCli
    LOCAL oGFec
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
    LOCAL oBtCli
    LOCAL oBtFP
    LOCAL oGInv
    LOCAL oGrid

    lNuevo   := Empty( AllTrim( cNumero ) )
    nArea    := Select()
    cNumDisp := If( lNuevo, "(se asigna al grabar)", AllTrim( cNumero ) )
    cCliID   := Space( 10 )
    cCliNom  := Space( 50 )
    dFecha   := Date()
    cFormPag := Space(  3 )
    nDias    := 0
    nPorcRet := 0.00
    cObserva := Space( 80 )
    cPieDoc  := ""
    lAnulada := .F.
    lCobrada := .F.
    lInv     := .F.
    aLineas  := {}
    nBase    := 0.00
    nIva     := 0.00
    nRet     := 0.00
    nTotal   := 0.00

    _FacCargarEmpPie( @cPieDoc )

    IF !lNuevo
        IF !_FacCargarCab( cNumero, @cCliID, @cCliNom, @dFecha, ;
                           @cFormPag, @nDias, @nPorcRet, ;
                           @cObserva, @lAnulada, @lCobrada, @lInv )
            RETURN NIL
        ENDIF
        _FacCargarLins( cNumero, @aLineas )
    ENDIF

    IF !Empty( cNumPre )
        _FacDesdePresup( cNumPre, @cCliID, @cCliNom, @dFecha, ;
                         @cFormPag, @nDias, @cObserva, @aLineas )
    ENDIF

    _FacCalcTot( aLineas, nPorcRet, @nBase, @nIva, @nRet, @nTotal )

    oWin := TWindow():New( 1, 2, 37, 129, ;
        If( lNuevo, "NUEVA FACTURA", "FACTURA: " + cNumDisp ) )

    oWin:AddCtrl( TLabel():New(  2,  2, "Numero    :", oWin ) )
    oWin:AddCtrl( TLabel():New(  2, 40, "Fecha     :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Cliente   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Forma pago:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 40, "Dias pago :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 70, "Ret.IRPF %:", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  2, "Observ.   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 70, "Inv.Suj.Pas:", oWin ) )

    oLNumero := TLabel():New( 2, 14, PadR( cNumDisp, 24 ), oWin )
    oLNumero:cColor := "W+/B"
    oWin:AddCtrl( oLNumero )

    oGCli := TGet():New( 4, 14, cCliID, "@!", oWin )
    oGCli:bValid := {| o | _FacBuscarCli( o, @cCliNom, @cFormPag, ;
                                           @nDias, @nPorcRet, ;
                                           oLCliNom, oGFP, oGDias, oGRet ) }

    oLCliNom := TLabel():New( 6, 14, PadR( cCliNom, 50 ), oWin )
    oWin:AddCtrl( oLCliNom )

    oGFec  := TGet():New(  2, 52, dFecha,   "99/99/9999", oWin )
    oGFP   := TGet():New(  8, 14, cFormPag, "@!",         oWin )
    oGDias := TGet():New(  8, 52, nDias,    "999",        oWin )
    oGRet  := TGet():New(  8, 82, nPorcRet, "99.99",      oWin )
    oGObs  := TGet():New( 10, 14, cObserva, "@!", oWin )

    oGInv  := TCheck():New( 6, 84, "Inversion", lInv, oWin )
    oGInv:bChange := {|| _FacInvToggle( oGInv, @aLineas, nPorcRet, ;
                                         @nBase, @nIva, @nRet, @nTotal, ;
                                         oLBase, oLIva, oLRet, oLTotal, oGrid ) }

    IF lNuevo
        oBtCli := TButton():New( 4, 25, 4, 34, oWin, "BUSCAR", ;
            {|| _FacLookupCli( oGCli, @cCliNom, @cFormPag, ;
                               @nDias, @nPorcRet, ;
                               oLCliNom, oGFP, oGDias, oGRet ) } )

        oBtFP := TButton():New( 8, 25, 8, 34, oWin, "BUSCAR", ;
            {|| _FacLookupFP( oGFP ) } )
    ENDIF

    oGrid := TGrid():New( 12, 2, 26, 124, oWin )
    oGrid:aData    := aLineas
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "#",          3, "999",       { |a| a[LIN_NUM]  } )
    oGrid:AddColumn( "Descripcion",53, "@!",        { |a| a[LIN_DESC] } )
    oGrid:AddColumn( "Cantidad",   8, "9,999.99",  { |a| a[LIN_CANT] } )
    oGrid:AddColumn( "Precio",    10, "9,999.99",  { |a| a[LIN_PRE]  } )
    oGrid:AddColumn( "Dto %",      6, "99.99",     { |a| a[LIN_DTO]  } )
    oGrid:AddColumn( "IVA %",      6, "99.99",     { |a| a[LIN_IVA]  } )
    oGrid:AddColumn( "Importe",   12, "99,999.99", { |a| a[LIN_IMP]  } )

    IF lNuevo
        oGrid:bEnter := {| g | ;
            _FacEditLin( g, @aLineas, nPorcRet, ;
                         @nBase, @nIva, @nRet, @nTotal, ;
                         oLBase, oLIva, oLRet, oLTotal ) }
    ENDIF

    oWin:AddCtrl( TLabel():New( 28,  2, "BASE IMPONIBLE :", oWin ) )
    oWin:AddCtrl( TLabel():New( 29,  2, "TOTAL IVA      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 30,  2, "RETENCION IRPF :", oWin ) )
    oWin:AddCtrl( TLabel():New( 31,  2, "TOTAL FACTURA  :", oWin ) )

    oLBase  := TLabel():New( 28, 20, _FmtN( nBase  ), oWin )
    oLIva   := TLabel():New( 29, 20, _FmtN( nIva   ), oWin )
    oLRet   := TLabel():New( 30, 20, _FmtN( nRet   ), oWin )
    oLTotal := TLabel():New( 31, 20, _FmtN( nTotal ), oWin )
    oLTotal:cColor := "W+/B"

    oWin:AddCtrl( oLBase  )
    oWin:AddCtrl( oLIva   )
    oWin:AddCtrl( oLRet   )
    oWin:AddCtrl( oLTotal )

    IF lNuevo
        oBtNLin := TButton():New( 28, 60, 29, 78, oWin, "NUEVA LINEA (F5)", ;
            {|| _FacNuevaLin( oGrid, @aLineas, nPorcRet, ;
                              @nBase, @nIva, @nRet, @nTotal, ;
                              oLBase, oLIva, oLRet, oLTotal ) } )

        oBtELin := TButton():New( 28, 80, 29, 98, oWin, "EDITAR LINEA", ;
            {|| _FacEditLin( oGrid, @aLineas, nPorcRet, ;
                             @nBase, @nIva, @nRet, @nTotal, ;
                             oLBase, oLIva, oLRet, oLTotal ) } )

        oBtDLin := TButton():New( 28,100, 29,118, oWin, "BORRAR LINEA", ;
            {|| _FacBorrarLin( oGrid, @aLineas, nPorcRet, ;
                               @nBase, @nIva, @nRet, @nTotal, ;
                               oLBase, oLIva, oLRet, oLTotal ) } )

        oBtGua := TButton():New( 33,  2, 34, 18, oWin, "GUARDAR", ;
           {|| _FacGuardarForm( _FacFormHash( oGCli, oGFec, oGFP, oGDias, oGRet, oGObs, oGInv, ;
                                                 cNumPre, nBase, nIva, nRet, nTotal, cPieDoc ), ;
                                  aLineas, lNuevo, @cNumero, oLNumero, oWin ) } )
    ENDIF

    oBtImp := TButton():New( 33, 20, 34, 36, oWin, "IMPRIMIR", ;
        {|| ImprimirFactura( cNumero ) } )

    oBtCan := TButton():New( 33,108, 34,124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGCli   )
    IF lNuevo
        oWin:AddCtrl( oBtCli )
    ENDIF
    oWin:AddCtrl( oGFec   )
    oWin:AddCtrl( oGFP    )
    IF lNuevo
        oWin:AddCtrl( oBtFP  )
    ENDIF
    oWin:AddCtrl( oGDias  )
    oWin:AddCtrl( oGRet   )
    oWin:AddCtrl( oGObs   )
    oWin:AddCtrl( oGInv   )
    oWin:AddCtrl( oGrid   )
    IF lNuevo
        oWin:AddCtrl( oBtNLin )
        oWin:AddCtrl( oBtELin )
        oWin:AddCtrl( oBtDLin )
        oWin:AddCtrl( oBtGua  )
    ENDIF
    oWin:AddCtrl( oBtImp  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

    Select( nArea )

RETURN NIL


// ============================================================================
// HELPERS DE CARGA
// ============================================================================

STATIC FUNCTION _FacCargarEmpPie( cPie )

    IF ABRIR_TABLA( "EMPRESA", "EMP_F", "" )
        EMP_F->( DbGoTop() )
        IF !EMP_F->( Eof() )
            cPie := EMP_F->( FieldGet( FieldPos( "PIE_DOC" ) ) )
        ENDIF
        EMP_F->( DbCloseArea() )
    ENDIF

RETURN NIL


STATIC FUNCTION _FacCargarCab( cNum, cCli, cNom, dFec, cFP, nDias, ;
                                nRet, cObs, lAnu, lCob, lInv )

    IF !ABRIR_TABLA( "FACTURA", "FAC", "FAC_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "FAC" )
    OrdSetFocus( "FAC_NUM" )

    IF !DbSeek( _FacKey( cNum ) )
        MsgStop( "Factura " + cNum + " no encontrada.", "Error" )
        RETURN .F.
    ENDIF

    cCli  := AllTrim( FAC->CLIENTE_ )
    dFec  := FAC->FECHA
    cFP   := AllTrim( DbFieldValue( "FORMA_PA", "" ) )
    nRet  := DbFieldValue( "PORC_RET", 0 )
    cObs  := AllTrim( DbFieldValue( "OBSERVA", "" ) )
    lAnu  := DbFieldValue( "ANULADA", .F. )
    lCob  := DbFieldValue( "COBRADA", .F. )
    lInv  := DbFieldValue( "INVERSION", .F. )

    // Cargar días de pago desde el cliente
    IF ABRIR_TABLA( "CLIENTES", "CLI_F2", "CLI_ID" )
        IF CLI_F2->( DbSeek( cCli ) )
            nDias := CLI_F2->DIAS_PAG
        ENDIF
        CLI_F2->( DbCloseArea() )
    ENDIF

    IF ABRIR_TABLA( "CLIENTES", "CLI_F", "CLI_ID" )
        IF CLI_F->( DbSeek( cCli ) )
            cNom := AllTrim( CLI_F->NOMBRE + " " + CLI_F->APELLIDO )
        ENDIF
        CLI_F->( DbCloseArea() )
    ENDIF

RETURN .T.


STATIC FUNCTION _FacCargarLins( cNum, aLins )

    LOCAL nL

    nL   := 0
    aLins := {}

    IF !ABRIR_TABLA( "FACTUR_DE", "FAC_D", "FAC_LIN" )
        RETURN NIL
    ENDIF

    DbSelectArea( "FAC_D" )
    OrdSetFocus( "FAC_LIN" )
    DbSeek( PadR( "A", 4 ) + PadR( cNum, 10 ) )

    DO WHILE !Eof() .AND. AllTrim( FAC_D->NUMERO ) == AllTrim( cNum )
        IF !Deleted()
            nL++
            AAdd( aLins, { ;
                nL, ;
                AllTrim( FAC_D->DESCRIPC ), ;
                FAC_D->CANTIDAD, ;
                FAC_D->PRECIO, ;
                FAC_D->DESCUENT, ;
                FAC_D->PORC_IVA, ;
                FAC_D->IMPORTE } )
        ENDIF
        DbSkip()
    ENDDO

    FAC_D->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _FacDesdePresup( cNumPre, cCli, cNom, dFec, cFP, nDias, cObs, aLins )

    LOCAL nL

    nL := 0

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_F", "PRE_NUM" )
        RETURN NIL
    ENDIF

    DbSelectArea( "PRE_F" )
    OrdSetFocus( "PRE_NUM" )

    IF DbSeek( cNumPre )
        cCli := AllTrim( PRE_F->CLIENTE_ )
        dFec := Date()
        cObs := AllTrim( DbFieldValue( "OBSERVA", "" ) )

        IF ABRIR_TABLA( "CLIENTES", "CLI_F2", "CLI_ID" )
            IF CLI_F2->( DbSeek( cCli ) )
                cNom  := AllTrim( CLI_F2->NOMBRE + " " + CLI_F2->APELLIDO )
                cFP   := AllTrim( CLI_F2->FORPAGO )
                nDias := CLI_F2->DIAS_PAG
            ENDIF
            CLI_F2->( DbCloseArea() )
        ENDIF
    ENDIF

    PRE_F->( DbCloseArea() )

    aLins := {}

    IF !ABRIR_TABLA( "PRESUP_DE", "PRD_F", "PRD_LIN" )
        RETURN NIL
    ENDIF

    DbSelectArea( "PRD_F" )
    OrdSetFocus( "PRD_LIN" )
    DbSeek( PadR( cNumPre, 10 ) + "  1" )

    DO WHILE !Eof() .AND. AllTrim( PRD_F->NUMERO ) == AllTrim( cNumPre )
        IF !Deleted()
            nL++
            AAdd( aLins, { ;
                nL, ;
                AllTrim( PRD_F->DESCRIPC ), ;
                PRD_F->CANTIDAD, ;
                PRD_F->PRECIO, ;
                PRD_F->DESCUENT, ;
                PRD_F->PORC_IVA, ;
                PRD_F->IMPORTE } )
        ENDIF
        DbSkip()
    ENDDO

    PRD_F->( DbCloseArea() )

RETURN NIL


// ============================================================================
// BUSQUEDA DE CLIENTE
// ============================================================================
STATIC FUNCTION _FacBuscarCli( oGet, cNom, cFP, nDias, nRet, ;
                               oLCliNom, oGFP, oGDias, oGRet )

    LOCAL cId

    cId := AllTrim( oGet:GetValue() )

    IF Empty( cId )
        RETURN .T.
    ENDIF

    IF !ABRIR_TABLA( "CLIENTES", "CLI_BF", "CLI_ID" )
        RETURN .T.
    ENDIF

    IF CLI_BF->( DbSeek( cId ) )
        cNom  := AllTrim( CLI_BF->NOMBRE + " " + CLI_BF->APELLIDO )
        cFP   := AllTrim( CLI_BF->FORPAGO )
        nDias := CLI_BF->DIAS_PAG
        nRet  := If( CLI_BF->APL_IRPF, 15.00, 0.00 )
    ELSE
        MsgStop( "Cliente " + cId + " no encontrado.", "Busqueda" )
        CLI_BF->( DbCloseArea() )
        RETURN .F.
    ENDIF

    CLI_BF->( DbCloseArea() )

    IF oLCliNom != NIL
        oLCliNom:SetText( PadR( cNom, 50 ) )
    ENDIF

    IF oGFP != NIL
        oGFP:SetValue( cFP )
    ENDIF

    IF oGDias != NIL
        oGDias:SetValue( nDias )
    ENDIF

    IF oGRet != NIL
        oGRet:SetValue( nRet )
    ENDIF

RETURN .T.


STATIC FUNCTION _FacLookupCli( oGet, cNom, cFP, nDias, nRet, ;
                               oLCliNom, oGFP, oGDias, oGRet )

    LOCAL cId

    cId := LookupCliente()
    IF Empty( cId )
        RETURN NIL
    ENDIF

    oGet:SetValue( cId )

RETURN _FacBuscarCli( oGet, @cNom, @cFP, @nDias, @nRet, ;
                      oLCliNom, oGFP, oGDias, oGRet )


STATIC FUNCTION _FacLookupFP( oGFP )

    LOCAL cFP

    cFP := LookupFormaPago()
    IF !Empty( cFP )
        oGFP:SetValue( cFP )
    ENDIF

RETURN NIL


// ============================================================================
// CALCULOS
// ============================================================================
STATIC FUNCTION _FacCalcTot( aLins, nPRet, nBase, nIva, nRet, nTotal )

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


STATIC FUNCTION _FmtN( nVal )
RETURN Transform( nVal, "999,999.99" )


STATIC FUNCTION _ActTotales( aLins, nPRet, nBase, nIva, nRet, nTotal, ;
                               oLBase, oLIva, oLRet, oLTotal )

    _FacCalcTot( aLins, nPRet, @nBase, @nIva, @nRet, @nTotal )

    oLBase:SetText(  _FmtN( nBase  ) )
    oLIva:SetText(   _FmtN( nIva   ) )
    oLRet:SetText(   _FmtN( nRet   ) )
    oLTotal:SetText( _FmtN( nTotal ) )

RETURN NIL


// ============================================================================
// GESTION DE LINEAS
// ============================================================================

STATIC FUNCTION _FacInvToggle( oInv, aLins, nPRet, nBase, nIva, nRet, nTotal, ;
                                oLBase, oLIva, oLRet, oLTotal, oGrid )

    LOCAL i
    LOCAL lInv := oInv:GetValue()

    FOR i := 1 TO Len( aLins )
        aLins[i, LIN_IVA] := If( lInv, 0, IVA_DEF )
        aLins[i, LIN_IMP] := ( aLins[i, LIN_CANT] * aLins[i, LIN_PRE] ) * ;
                              ( 1 - aLins[i, LIN_DTO] / 100 )
    NEXT

    oGrid:aData := aLins
    oGrid:Paint()
    _FacCalcTot( aLins, nPRet, @nBase, @nIva, @nRet, @nTotal )
    oLBase:SetText(  _FmtN( nBase  ) )
    oLIva:SetText(   _FmtN( nIva   ) )
    oLRet:SetText(   _FmtN( nRet   ) )
    oLTotal:SetText( _FmtN( nTotal ) )

RETURN NIL


STATIC FUNCTION _FacNuevaLin( oGrid, aLins, nPRet, nBase, nIva, nRet, nTotal, ;
                                oLBase, oLIva, oLRet, oLTotal )

    LOCAL nNum
    LOCAL aLin

    nNum := Len( aLins ) + 1

    IF nNum > MAX_LINS
        MsgStop( "Maximo " + AllTrim( Str( MAX_LINS ) ) + " lineas.", "Limite" )
        RETURN NIL
    ENDIF

    aLin := { nNum, "", 1, 0.00, 0.00, IVA_DEF, 0.00 }

    IF _FacFormLin( @aLin, .T. )
        AAdd( aLins, aLin )
        oGrid:aData   := aLins
        oGrid:nCurRow := Len( aLins )
        oGrid:Paint()
        _ActTotales( aLins, nPRet, @nBase, @nIva, @nRet, @nTotal, ;
                     oLBase, oLIva, oLRet, oLTotal )
    ENDIF

RETURN NIL


STATIC FUNCTION _FacEditLin( oGrid, aLins, nPRet, nBase, nIva, nRet, nTotal, ;
                               oLBase, oLIva, oLRet, oLTotal )

    LOCAL nPos
    LOCAL aLin

    nPos := oGrid:nCurRow

    IF nPos < 1 .OR. nPos > Len( aLins )
        RETURN NIL
    ENDIF

    aLin := AClone( aLins[nPos] )

    IF _FacFormLin( @aLin, .F. )
        aLins[nPos] := aLin
        oGrid:aData  := aLins
        oGrid:Paint()
        _ActTotales( aLins, nPRet, @nBase, @nIva, @nRet, @nTotal, ;
                     oLBase, oLIva, oLRet, oLTotal )
    ENDIF

RETURN NIL


STATIC FUNCTION _FacBorrarLin( oGrid, aLins, nPRet, nBase, nIva, nRet, nTotal, ;
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


STATIC FUNCTION _FacFormLin( aLin, lNuevo )

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

    oLImp := TLabel():New( 8, 17, _FmtN( nImp ), oWin )
    oLImp:cColor := "W+/B"
    oWin:AddCtrl( oLImp )

    bRecalc := {|| ;
        nImp := ( oGCant:GetValue() * oGPre:GetValue() ) * ( 1 - oGDto:GetValue() / 100 ), ;
        oLImp:SetText( _FmtN( nImp ) ), ;
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
        aLin[LIN_DESC] := AllTrim( oGDesc:GetValue() )
        aLin[LIN_CANT] := oGCant:GetValue()
        aLin[LIN_PRE]  := oGPre:GetValue()
        aLin[LIN_DTO]  := oGDto:GetValue()
        aLin[LIN_IVA]  := oGIva:GetValue()
        aLin[LIN_IMP]  := ( oGCant:GetValue() * oGPre:GetValue() ) * ( 1 - oGDto:GetValue() / 100 )
    ENDIF

RETURN lOK


// ============================================================================
// GUARDAR
// ============================================================================
STATIC FUNCTION _FacFormHash( oGCli, oGFec, oGFP, oGDias, oGRet, oGObs, oGInv, ;
                               cNumPre, nBase, nIva, nRet, nTotal, cPieDoc )

    LOCAL cCli
    LOCAL dFec
    LOCAL cFP
    LOCAL nDias
    LOCAL nPRet
    LOCAL cObs
    LOCAL dVto
    LOCAL hFac

    cCli  := AllTrim( oGCli:GetValue() )
    dFec  := oGFec:GetValue()
    cFP   := AllTrim( oGFP:GetValue() )
    nDias := oGDias:GetValue()
    nPRet := oGRet:GetValue()
    cObs  := AllTrim( oGObs:GetValue() )
    cNumPre := If( cNumPre == NIL, "", AllTrim( cNumPre ) )
    dVto  := dFec + nDias

    hFac := {=>}
    hFac[ "NUMERO"   ] := ""  // se asigna en guardar
    hFac[ "SERIE"    ] := "A"
    hFac[ "CLIENTE_" ] := cCli
    hFac[ "FECHA"    ] := dFec
    hFac[ "FORMA_PA" ] := cFP
    hFac[ "DIAS_PAG" ] := nDias
    hFac[ "PORC_RET" ] := nPRet
    hFac[ "SUBTOTAL" ] := nBase
    hFac[ "IVA"      ] := nIva
    hFac[ "RETENCIO" ] := nRet
    hFac[ "TOTAL"    ] := nTotal
    hFac[ "FECHA_VT" ] := dVto
    hFac[ "OBSERVA"  ] := cObs
    hFac[ "PIE_DOC"  ] := cPieDoc
    hFac[ "NUM_PRE"  ] := cNumPre
    hFac[ "ID_OBRA"  ] := ""
    hFac[ "TIPO_FAC" ] := ""
    hFac[ "TIPO_DOC" ] := "F"
    hFac[ "INVERSION" ] := oGInv:GetValue()

RETURN hFac


STATIC FUNCTION _FacGuardarForm( hFac, aLins, lNuevo, cNumero, oLNumero, oWin )

    LOCAL cNum

    IF Empty( hFac[ "CLIENTE_" ] )
        MsgStop( "Debe indicar el cliente.", "Guardar" )
        RETURN NIL
    ENDIF

    IF !lNuevo
        MsgStop( "Una factura emitida no se modifica." + Chr(13) + ;
                 "Use nota de abono o factura rectificativa para mantener trazabilidad.", ;
                 "Factura fiscal" )
        RETURN NIL
    ENDIF

    IF Len( aLins ) == 0
        MsgStop( "Debe introducir al menos una linea.", "Guardar" )
        RETURN NIL
    ENDIF

    cNum := _FacSiguiente()
    IF Empty( cNum )
        RETURN NIL
    ENDIF

    hFac[ "NUMERO" ] := cNum

    IF !FacturaGuardar( hFac, aLins, lNuevo )
        RETURN NIL
    ENDIF

    AsientoAutomatico( "FAC", cNum )

    oLNumero:SetText( PadR( cNum, 24 ) )
    cNumero := cNum

    MsgInfo( "Factura " + cNum + " guardada.", "Guardado" )

    IF MsgYesNo( "Desea imprimir la factura ahora?", "Imprimir" )
        ImprimirFactura( cNum )
    ENDIF

    oWin:Close()

RETURN NIL


FUNCTION FacturaGuardar( hFac, aLins, lNuevo )

    DEFAULT lNuevo TO .T.

    IF !lNuevo .AND. FacturaContabilizada( hFac[ "SERIE" ], hFac[ "NUMERO" ] )
        MsgStop( "No se puede guardar una factura contabilizada." + Chr(13) + ;
                 "Use nota de abono o documento corrector.", ;
                 "Documento contabilizado" )
        RETURN .F.
    ENDIF

    IF !_FacGuardarCab( hFac, lNuevo )
        RETURN .F.
    ENDIF

    IF !_FacGuardarLins( hFac, aLins )
        IF lNuevo
            _FacBorrarCabDB( hFac[ "NUMERO" ] )
        ENDIF
        RETURN .F.
    ENDIF

    IF !_FacGenVencim( hFac[ "NUMERO" ], hFac[ "CLIENTE_" ], ;
                       hFac[ "FECHA_VT" ], hFac[ "TOTAL" ] )
        IF lNuevo
            _FacBorrarLinsDB( hFac[ "NUMERO" ] )
            _FacBorrarCabDB( hFac[ "NUMERO" ] )
        ENDIF
        RETURN .F.
    ENDIF

RETURN .T.


STATIC FUNCTION _FacGuardarCab( hFac, lNuevo )

    IF !ABRIR_TABLA( "FACTURA", "FAC", "FAC_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "FAC" )
    OrdSetFocus( "FAC_NUM" )

    IF lNuevo
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( _FacKey( hFac[ "NUMERO" ] ) ) .OR. !NetRLock()
            RETURN .F.
        ENDIF
    ENDIF

    REPLACE FAC->NUMERO   WITH hFac[ "NUMERO"   ]
    REPLACE FAC->SERIE    WITH hFac[ "SERIE"    ]
    REPLACE FAC->CLIENTE_ WITH hFac[ "CLIENTE_" ]
    REPLACE FAC->FECHA    WITH hFac[ "FECHA"    ]
    DbFieldPutIf( "FORMA_PA", hFac[ "FORMA_PA" ] )
    REPLACE FAC->SUBTOTAL WITH hFac[ "SUBTOTAL" ]
    REPLACE FAC->IVA      WITH hFac[ "IVA"      ]
    REPLACE FAC->RETENCIO WITH hFac[ "RETENCIO" ]
    DbFieldPutIf( "PORC_RET", hFac[ "PORC_RET" ] )
    REPLACE FAC->TOTAL    WITH hFac[ "TOTAL"    ]
    DbFieldPutIf( "FECHA_VT", hFac[ "FECHA_VT" ] )
    DbFieldPutIf( "FECHA_OP", Date() )
    DbFieldPutIf( "OBSERVA",  hFac[ "OBSERVA"  ] )
    DbFieldPutIf( "PIE_DOC",  hFac[ "PIE_DOC"  ] )
    DbFieldPutIf( "ANULADA",  .F. )
    DbFieldPutIf( "COBRADA",  .F. )
    REPLACE FAC->HORA     WITH Time()
    DbFieldPutIf( "TIPO_DOC", hFac[ "TIPO_DOC" ] )
    DbFieldPutIf( "ID_OBRA",  hFac[ "ID_OBRA"  ] )
    DbFieldPutIf( "TIPO_FAC", hFac[ "TIPO_FAC" ] )
    DbFieldPutIf( "INVERSION", hFac[ "INVERSION" ] )

    IF !Empty( hFac[ "NUM_PRE" ] )
        REPLACE FAC->NUM_PRE WITH hFac[ "NUM_PRE" ]
    ENDIF

    DbCommit()
    DbUnlock()

RETURN .T.


STATIC FUNCTION _FacBorrarCabDB( cNum )

    IF !ABRIR_TABLA( "FACTURA", "FAC_B", "FAC_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "FAC_B" )
    OrdSetFocus( "FAC_NUM" )

    IF DbSeek( _FacKey( cNum ) ) .AND. NetRLock()
        FAC_B->( DbDelete() )
        DbUnlock()
        FAC_B->( DbCloseArea() )
        RETURN .T.
    ENDIF

    FAC_B->( DbCloseArea() )

RETURN .F.


STATIC FUNCTION _FacGuardarLins( hFac, aLins )

    LOCAL i

    IF !ABRIR_TABLA( "FACTUR_DE", "FAC_D", "FAC_LIN" )
        RETURN .F.
    ENDIF

    DbSelectArea( "FAC_D" )

    IF !NetFLock()
        FAC_D->( DbCloseArea() )
        RETURN .F.
    ENDIF

    FOR i := 1 TO Len( aLins )
        DbAppend()
        REPLACE FAC_D->SERIE    WITH hFac[ "SERIE"  ]
        REPLACE FAC_D->NUMERO   WITH hFac[ "NUMERO" ]
        REPLACE FAC_D->LINEA    WITH i
        REPLACE FAC_D->DESCRIPC WITH aLins[i, LIN_DESC]
        REPLACE FAC_D->CANTIDAD WITH aLins[i, LIN_CANT]
        REPLACE FAC_D->PRECIO   WITH aLins[i, LIN_PRE]
        REPLACE FAC_D->DESCUENT WITH aLins[i, LIN_DTO]
        REPLACE FAC_D->PORC_IVA WITH aLins[i, LIN_IVA]
        REPLACE FAC_D->IMPORTE  WITH aLins[i, LIN_IMP]
    NEXT

    DbCommit()
    DbUnlock()

    FAC_D->( DbCloseArea() )

RETURN .T.


STATIC FUNCTION _FacBorrarLinsDB( cNum )

    IF !ABRIR_TABLA( "FACTUR_DE", "FAD_B", "FAC_LIN" )
        RETURN .F.
    ENDIF

    DbSelectArea( "FAD_B" )
    OrdSetFocus( "FAC_LIN" )
    DbSeek( PadR( "A", 4 ) + PadR( AllTrim( cNum ), 10 ) + "  1" )

    DO WHILE !Eof() .AND. AllTrim( FAD_B->SERIE ) == "A" .AND. ;
          AllTrim( FAD_B->NUMERO ) == AllTrim( cNum )
        IF NetRLock()
            FAD_B->( DbDelete() )
            DbUnlock()
        ENDIF
        DbSkip()
    ENDDO

    FAD_B->( DbCloseArea() )

RETURN .T.


STATIC FUNCTION _FacSiguiente()

    LOCAL cAnio
    LOCAL cCod

    cAnio := AllTrim( Str( Year( Date() ) ) )
    cCod  := "FAC" + cAnio

RETURN GetNextNum( cCod, "Facturas " + cAnio )


STATIC FUNCTION _FacKey( cNum )

RETURN PadR( "A", 4 ) + PadR( AllTrim( cNum ), 10 )


STATIC FUNCTION _FacGenVencim( cNum, cCli, dVto, nTotal )

    LOCAL cNom

    cNom := ""

    IF !ABRIR_TABLA( "VENCIMIEN", "VEN_F", "VEN_NUM" )
        RETURN .F.
    ENDIF

    IF ABRIR_TABLA( "CLIENTES", "CLI_V", "CLI_ID" )
        IF CLI_V->( DbSeek( cCli ) )
            cNom := AllTrim( CLI_V->NOMBRE + " " + CLI_V->APELLIDO )
        ENDIF
        CLI_V->( DbCloseArea() )
    ENDIF

    DbSelectArea( "VEN_F" )

    IF !NetFLock()
        VEN_F->( DbCloseArea() )
        RETURN .F.
    ENDIF

    DbAppend()
    REPLACE VEN_F->EJERCICIO WITH Year( Date() )
    REPLACE VEN_F->TIPO      WITH "C"
    REPLACE VEN_F->NUMERO    WITH cNum
    REPLACE VEN_F->VENCTO    WITH dVto
    REPLACE VEN_F->IMPORTE   WITH nTotal
    REPLACE VEN_F->COBRADO   WITH .F.
    REPLACE VEN_F->CODTERCE  WITH cCli
    REPLACE VEN_F->NOMBRE    WITH cNom
    DbCommit()
    DbUnlock()

    VEN_F->( DbCloseArea() )

RETURN .T.


// ============================================================================
// NotaAbonoForm( cNumFac )
// ----------------------------------------------------------------------------
// Genera una nota de abono (nota de credito) que revierte una factura.
//
// Reglas:
//   - Solo se puede abonar una factura que NO tenga ya nota de abono
//   - El documento generado es NOTASDC con TIPO="C" (credito)
//   - REF_DOC apunta a la factura original
//   - Las lineas se copian de FACTUR_DE con importes en negativo
//   - Se genera asiento contable inverso al de la factura
//   - Si la factura NO esta contabilizada, queda marcada con el abono
//   - Si ya esta contabilizada, no se modifica: el abono queda vinculado por REF_DOC
//   - Si la factura estaba cobrada, se revierte tambien el cobro
// ============================================================================
FUNCTION NotaAbonoForm( cNumFac )

    LOCAL cNumFac_
    LOCAL cCliID
    LOCAL cCliNom
    LOCAL dFecha
    LOCAL cMotivo
    LOCAL nSubtotal
    LOCAL nIva
    LOCAL nRet
    LOCAL nTotal
    LOCAL cCtaCli
    LOCAL aLineas
    LOCAL oWin
    LOCAL oGrid
    LOCAL oLFac
    LOCAL oLCli
    LOCAL oGFec
    LOCAL oGMot
    LOCAL oLBase
    LOCAL oLIva
    LOCAL oLTotal
    LOCAL oBtGua
    LOCAL oBtCan

    cNumFac_  := AllTrim( cNumFac )
    cCliID    := ""
    cCliNom   := ""
    dFecha    := Date()
    cMotivo   := Space( 80 )
    nSubtotal := 0
    nIva      := 0
    nRet      := 0
    nTotal    := 0
    cCtaCli   := ""
    aLineas   := {}

    IF Empty( cNumFac_ )
        MsgStop( "Seleccione una factura.", "Nota de Abono" )
        RETURN NIL
    ENDIF

    // Verificar que la factura existe y no tiene ya abono
    IF !ABRIR_TABLA( "FACTURA", "FAC_NA", "FAC_NUM" )
        RETURN NIL
    ENDIF

    DbSelectArea( "FAC_NA" )
    OrdSetFocus( "FAC_NUM" )

    IF !DbSeek( PadR( "A", 4 ) + PadR( cNumFac_, 10 ) )
        FAC_NA->( DbCloseArea() )
        MsgStop( "Factura " + cNumFac_ + " no encontrada.", "Nota de Abono" )
        RETURN NIL
    ENDIF

    IF FacturaTieneAbono( "A", cNumFac_ )
        FAC_NA->( DbCloseArea() )
        MsgStop( "Esta factura ya tiene una nota de abono vinculada.", ;
                 "Nota de Abono" )
        RETURN NIL
    ENDIF

    cCliID    := AllTrim( FAC_NA->CLIENTE_ )
    nSubtotal := FAC_NA->SUBTOTAL
    nIva      := FAC_NA->IVA
    nRet      := FAC_NA->RETENCIO
    nTotal    := FAC_NA->TOTAL

    FAC_NA->( DbCloseArea() )

    // Cargar nombre y cuenta contable del cliente
    IF ABRIR_TABLA( "CLIENTES", "CLI_NA", "CLI_ID" )
        IF CLI_NA->( DbSeek( cCliID ) )
            cCliNom := AllTrim( CLI_NA->NOMBRE + " " + CLI_NA->APELLIDO )
            cCtaCli := AllTrim( CLI_NA->CTA_CONT )
        ENDIF
        CLI_NA->( DbCloseArea() )
    ENDIF

    // Cargar lineas de la factura
    _NaCargarLineas( cNumFac_, @aLineas )

    // Formulario
    oWin := TWindow():New( 3, 10, 30, 120, "NOTA DE ABONO — Factura: " + cNumFac_ )

    oWin:AddCtrl( TLabel():New( 2,  2, "Factura orig. :", oWin ) )
    oWin:AddCtrl( TLabel():New( 4,  2, "Cliente       :", oWin ) )
    oWin:AddCtrl( TLabel():New( 6,  2, "Fecha abono   :", oWin ) )
    oWin:AddCtrl( TLabel():New( 8,  2, "Motivo        :", oWin ) )

    oLFac := TLabel():New( 2, 18, PadR( cNumFac_, 12 ), oWin )
    oLFac:cColor := "W+/B"
    oWin:AddCtrl( oLFac )

    oLCli := TLabel():New( 4, 18, PadR( cCliNom, 50 ), oWin )
    oWin:AddCtrl( oLCli )

    oGFec := TGet():New( 6, 18, dFecha,   "99/99/9999", oWin )
    oGMot := TGet():New( 8, 18, cMotivo,  "@!",         oWin )
    oGMot:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) .OR. ;
        ( MsgStop( "El motivo del abono es obligatorio.", "Validacion" ), .F. ) }

    oWin:AddCtrl( TLabel():New( 12, 2, "Lineas de la factura (se abonan en su totalidad):", oWin ) )

    // Grid de lineas (solo lectura)
    oGrid := TGrid():New( 13, 2, 20, 106, oWin )
    oGrid:aData := aLineas
    oGrid:AddColumn( "#",          3, "999",      { |a| a[1] } )
    oGrid:AddColumn( "Descripcion",53, "@!",       { |a| a[2] } )
    oGrid:AddColumn( "Cantidad",   8, "9,999.99", { |a| a[3] } )
    oGrid:AddColumn( "Precio",    10, "9,999.99", { |a| a[4] } )
    oGrid:AddColumn( "IVA %",      6, "99.99",    { |a| a[6] } )
    oGrid:AddColumn( "Importe",   12, "99,999.99",{ |a| a[7] } )

    oWin:AddCtrl( TLabel():New( 22, 2,  "BASE:", oWin ) )
    oWin:AddCtrl( TLabel():New( 23, 2,  "IVA :", oWin ) )
    oWin:AddCtrl( TLabel():New( 24, 2,  "TOTAL:", oWin ) )

    oLBase  := TLabel():New( 22, 10, Transform( nSubtotal, "999,999.99" ) + " EUR", oWin )
    oLIva   := TLabel():New( 23, 10, Transform( nIva,      "999,999.99" ) + " EUR", oWin )
    oLTotal := TLabel():New( 24, 10, Transform( nTotal,    "999,999.99" ) + " EUR", oWin )
    oLTotal:cColor := "W+/B"

    oWin:AddCtrl( oLBase  )
    oWin:AddCtrl( oLIva   )
    oWin:AddCtrl( oLTotal )

    oBtGua := TButton():New( 25, 10, 26, 30, oWin, "EMITIR NOTA ABONO", ;
        {|| _NaGuardar( cNumFac_, cCliID, cCtaCli, oGFec, oGMot, ;
                        aLineas, nSubtotal, nIva, nRet, nTotal, oWin ) } )

    oBtCan := TButton():New( 25, 75, 26, 90, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGFec   )
    oWin:AddCtrl( oGMot   )
    oWin:AddCtrl( oGrid   )
    oWin:AddCtrl( oBtGua  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _NaCargarLineas( cNumFac, aLins )

    LOCAL nL

    nL   := 0
    aLins := {}

    IF !ABRIR_TABLA( "FACTUR_DE", "FAC_NL", "FAC_LIN" )
        RETURN NIL
    ENDIF

    DbSelectArea( "FAC_NL" )
    OrdSetFocus( "FAC_LIN" )
    DbSeek( PadR( "A", 4 ) + PadR( cNumFac, 10 ) )

    DO WHILE !Eof() .AND. AllTrim( FAC_NL->NUMERO ) == cNumFac
        IF !Deleted()
            nL++
            AAdd( aLins, { nL, AllTrim( FAC_NL->DESCRIPC ), ;
                FAC_NL->CANTIDAD, FAC_NL->PRECIO, ;
                FAC_NL->DESCUENT, FAC_NL->PORC_IVA, ;
                FAC_NL->IMPORTE } )
        ENDIF
        DbSkip()
    ENDDO

    FAC_NL->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _NaGuardar( cNumFac, cCliID, cCtaCli, oGFec, oGMot, ;
                              aLins, nBase, nIva, nRet, nTotal, oWin )

    LOCAL cNumNA
    LOCAL dFec
    LOCAL cMotivo
    LOCAL cCtaDebe
    LOCAL i

    dFec    := oGFec:GetValue()
    cMotivo := AllTrim( oGMot:GetValue() )

    IF Empty( cMotivo )
        MsgStop( "El motivo del abono es obligatorio.", "Validacion" )
        RETURN NIL
    ENDIF

    IF !MsgYesNo( "Emitir nota de abono por " + ;
                  Transform( nTotal, "999,999.99" ) + " EUR?" + Chr(13) + ;
                  "Esta accion no se puede deshacer.", "Confirmar" )
        RETURN NIL
    ENDIF

    // Numero de nota de abono
    cNumNA := GetNextNum( "NA" + AllTrim( Str( Year( Date() ) ) ), "Notas Abono" )
    IF Empty( cNumNA )
        RETURN NIL
    ENDIF

    // Asiento inverso de venta:
    // D 700/ingresos  nBase
    // D 477 IVA       nIva
    // H 430 cliente   nTotal
    cCtaDebe := If( Empty( cCtaCli ), "430", cCtaCli )

    // Grabar cabecera NOTASDC
    IF !ABRIR_TABLA( "NOTASDC", "NDC_G", "NDC_NUM" )
        RETURN NIL
    ENDIF

    DbSelectArea( "NDC_G" )

    IF !NetFLock()
        NDC_G->( DbCloseArea() )
        RETURN NIL
    ENDIF

    DbAppend()
    REPLACE NDC_G->NUMERO   WITH cNumNA
    REPLACE NDC_G->SERIE    WITH "NA"
    REPLACE NDC_G->TIPO     WITH "C"
    REPLACE NDC_G->CLIENTE_ WITH cCliID
    REPLACE NDC_G->FECHA    WITH dFec
    REPLACE NDC_G->FECHA_OP WITH Date()
    REPLACE NDC_G->REF_DOC  WITH cNumFac
    REPLACE NDC_G->MOTIVO   WITH cMotivo
    REPLACE NDC_G->SUBTOTAL WITH nBase
    REPLACE NDC_G->IVA      WITH nIva
    REPLACE NDC_G->RETENCIO WITH nRet
    REPLACE NDC_G->TOTAL    WITH nTotal
    REPLACE NDC_G->ESTADO   WITH "E"
    REPLACE NDC_G->OBSERVA  WITH "Abono factura " + cNumFac
    DbUnlock()

    NDC_G->( DbCloseArea() )

    // Grabar lineas en NOTASD_DE con importes negativos
    IF ABRIR_TABLA( "NOTASD_DE", "NDD_G", "NDC_LIN" )
        DbSelectArea( "NDD_G" )
        IF NetFLock()
            FOR i := 1 TO Len( aLins )
                DbAppend()
                REPLACE NDD_G->NUMERO   WITH cNumNA
                REPLACE NDD_G->LINEA    WITH i
                REPLACE NDD_G->DESCRIPC WITH aLins[i,2]
                REPLACE NDD_G->CANTIDAD WITH aLins[i,3]
                REPLACE NDD_G->PRECIO   WITH aLins[i,4]
                REPLACE NDD_G->DESCUENT WITH aLins[i,5]
                REPLACE NDD_G->IMPORTE  WITH -aLins[i,7]
                REPLACE NDD_G->PORC_IVA WITH aLins[i,6]
            NEXT
            DbUnlock()
        ENDIF
        NDD_G->( DbCloseArea() )
    ENDIF

    // Si la factura ya esta contabilizada, no se toca el documento original.
    IF !FacturaContabilizada( "A", cNumFac )
        IF ABRIR_TABLA( "FACTURA", "FAC_NA2", "FAC_NUM" )
            DbSelectArea( "FAC_NA2" )
            OrdSetFocus( "FAC_NUM" )
            IF DbSeek( PadR( "A", 4 ) + PadR( cNumFac, 10 ) ) .AND. NetRLock()
                DbFieldPutIf( "ANULADA", .T. )
                DbFieldPutIf( "NUM_ABONO", cNumNA )
                DbUnlock()
            ENDIF
            FAC_NA2->( DbCloseArea() )
        ENDIF
    ENDIF

    // Asiento contable inverso
    _NaAsiento( cNumNA, dFec, cCliID, cCtaDebe, nBase, nIva, nTotal, ;
                "Nota abono " + cNumNA + " / Fac " + cNumFac )

    MsgInfo( "Nota de abono " + cNumNA + " emitida correctamente." + Chr(13) + ;
             "La factura original queda sin cambios si ya estaba contabilizada.", ;
             "Nota de Abono" )

    oWin:Close()

RETURN NIL


STATIC FUNCTION _NaAsiento( cNumNA, dFec, cCliID, cCtaCli, ;
                              nBase, nIva, nTotal, cConcepto )

    LOCAL cAsi
    LOCAL cCta700

    cAsi   := GetNextNum( "ASI" + AllTrim( Str( Year( Date() ) ) ), "Asientos" )
    cCta700 := "700"

    IF Empty( cAsi ) .OR. !ABRIR_TABLA( "LDIARIO", "DIA_NA", "DIA_ASI" )
        RETURN NIL
    ENDIF

    DbSelectArea( "DIA_NA" )

    IF NetFLock()

        // D 430xxxxxxx — eliminamos deuda del cliente (abono)
        DbAppend()
        REPLACE DIA_NA->D_ASIENT WITH cAsi
        REPLACE DIA_NA->D_LINEA  WITH 1
        REPLACE DIA_NA->D_FECHA  WITH dFec
        REPLACE DIA_NA->D_CUENTA WITH cCta700
        REPLACE DIA_NA->D_DEBE   WITH nBase
        REPLACE DIA_NA->D_HABER  WITH 0
        REPLACE DIA_NA->D_DESCRI WITH cConcepto
        REPLACE DIA_NA->TIP_ORIG WITH "NA"
        REPLACE DIA_NA->DOC_ORIG WITH cNumNA

        // H 700 — menor ingreso por ventas
        DbAppend()
        REPLACE DIA_NA->D_ASIENT WITH cAsi
        REPLACE DIA_NA->D_LINEA  WITH 2
        REPLACE DIA_NA->D_FECHA  WITH dFec
        REPLACE DIA_NA->D_CUENTA WITH cCtaCli
        REPLACE DIA_NA->D_DEBE   WITH 0
        REPLACE DIA_NA->D_HABER  WITH nTotal
        REPLACE DIA_NA->D_DESCRI WITH cConcepto
        REPLACE DIA_NA->TIP_ORIG WITH "NA"
        REPLACE DIA_NA->DOC_ORIG WITH cNumNA

        // H 477 — IVA repercutido negativo
        IF nIva > 0
            DbAppend()
            REPLACE DIA_NA->D_ASIENT WITH cAsi
            REPLACE DIA_NA->D_LINEA  WITH 3
            REPLACE DIA_NA->D_FECHA  WITH dFec
            REPLACE DIA_NA->D_CUENTA WITH "477"
            REPLACE DIA_NA->D_DEBE   WITH nIva
            REPLACE DIA_NA->D_HABER  WITH 0
            REPLACE DIA_NA->D_DESCRI WITH cConcepto
            REPLACE DIA_NA->TIP_ORIG WITH "NA"
            REPLACE DIA_NA->DOC_ORIG WITH cNumNA
        ENDIF

        DbUnlock()

    ENDIF

    DIA_NA->( DbCloseArea() )

RETURN NIL


// ============================================================================
// FIN DE V_Facturas.prg
// ============================================================================
