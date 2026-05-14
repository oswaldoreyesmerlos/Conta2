/*
 * ARCHIVO  : V_Presupuesto.prg
 * PROPOSITO: Gestion completa de presupuestos.
 *
 * FUNCIONES PUBLICAS
 * ------------------
 *   PresupuestosView()    - grid listado de presupuestos
 *   PresupuestoNuevo()    - alias semantico para alta directa
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
    LOCAL oBtObr
    LOCAL oBtRec
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
    oGrid:AddColumn( "Estado",    10, "@!",         { |a| a[7] } )
    oGrid:AddColumn( "Obra",      10, "@!",         { |a| a[8] } )

    oGrid:bEnter := {| g | ;
        _PreEditar( g:CurrentRow()[1] ), ;
        aData := _PreCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "ENTER: ver/editar   F5: nuevo presupuesto   ACEPTAR: crea obra   Letras: buscar cliente", oWin )

    oBtNvo := TButton():New( 33,  2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| AltaPresupuesto(), ;
            aData := _PreCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtObr := TButton():New( 33, 20, 34, 38, oWin, "ACEPTAR", ;
        {|| If( oGrid:CurrentRow() != NIL, ;
               AceptarPresupuesto( oGrid:CurrentRow()[1] ), NIL ), ;
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
    oWin:AddCtrl( oBtObr )
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
                _PreEstadoTexto( DbFieldValue( "ESTADO", "P" ), ;
                                  DbFieldValue( "ID_OBRA", "" ) ), ;
                AllTrim( DbFieldValue( "ID_OBRA", "" ) ) } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _PreEstadoTexto( cEstado, cIdObra )

    IF !Empty( AllTrim( cIdObra ) )
        RETURN "OBRA"
    ENDIF

    DO CASE
    CASE AllTrim( cEstado ) == "A"
        RETURN "ACEPTADO"
    CASE AllTrim( cEstado ) == "R"
        RETURN "RECHAZADO"
    OTHERWISE
        RETURN "PENDIENTE"
    ENDCASE

RETURN "PENDIENTE"


// ============================================================================
// AltaPresupuesto / _PreEditar
// ============================================================================
FUNCTION AltaPresupuesto()
RETURN _PreForm( "", NIL )

FUNCTION PresupuestoNuevo()
RETURN AltaPresupuesto()

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
    LOCAL cCliInfo
    LOCAL dFecha
    LOCAL dFechaAce
    LOCAL cAcepPor
    LOCAL dValidez
    LOCAL cFormPag
    LOCAL nDias
    LOCAL nPorcRet
    LOCAL cObserva
    LOCAL cPieDoc
    LOCAL lAnulada
    LOCAL lInv
    LOCAL dFechaAce
    LOCAL cAcepPor
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
    LOCAL oLCliInfo
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
    cCliID   := Space( 10 )
    cCliNom  := Space( 70 )
    cCliInfo := Space( 80 )
    dFecha   := Date()
    dValidez := Date() + 30
    cFormPag := Space(  3 )
    nDias    := 0
    nPorcRet := 0.00
    cObserva := Space( 60 )
    cPieDoc  := ""
    lAnulada := .F.
    lInv     := .F.
    dFechaAce := CToD( "" )
    cAcepPor := ""
    aLineas  := {}
    nBase    := 0.00
    nIva     := 0.00
    nRet     := 0.00
    nTotal   := 0.00

    _PreCargarEmpPie( @cPieDoc )

    IF !lNuevo
        IF !_PreCargarCab( cNumero, @cCliID, @cCliNom, @cCliInfo, @dFecha, @dValidez, ;
                             @cFormPag, @nDias, @nPorcRet, @cObserva, @lAnulada, @lInv, ;
                             @dFechaAce, @cAcepPor )
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
    oWin:AddCtrl( TLabel():New(  4, 28, "Nombre    :", oWin ) )
    oWin:AddCtrl( TLabel():New(  5, 28, "Datos     :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Validez   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 32, "Forma pago:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 62, "Dias pago :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 86, "Ret.IRPF %:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Observ.   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  7, 86, "Inv.Suj.Pas:", oWin ) )
    IF !Empty( dFechaAce )
        oWin:AddCtrl( TLabel():New( 9, 40, "Aceptado: " + DToC( dFechaAce ) + " por " + AllTrim( cAcepPor ), oWin ) )
    ENDIF

    oLNumero := TLabel():New( 2, 14, PadR( If( lNuevo, "(se asigna al grabar)", cNumero ), 24 ), oWin )
    oLNumero:cColor := "W+/B"
    oWin:AddCtrl( oLNumero )

    oGCli := TGet():New( 4, 14, cCliID, "@!", oWin )
    oGCli:bValid := {| o | _PreBuscarCli( o, @cCliNom, @cCliInfo, @cFormPag, ;
                                               @nDias, @nPorcRet, oLCliNom, ;
                                               oLCliInfo, oGFP, oGDias, oGRet ) }

    oLCliNom := TLabel():New( 4, 40, PadR( cCliNom, 70 ), oWin )
    oWin:AddCtrl( oLCliNom )

    oLCliInfo := TLabel():New( 5, 40, PadR( cCliInfo, 80 ), oWin )
    oWin:AddCtrl( oLCliInfo )

    oGFec  := TGet():New(  2, 52, dFecha,   "99/99/9999", oWin )
    oGVal  := TGet():New(  6, 14, dValidez, "99/99/9999", oWin )
    oGFP   := TGet():New(  6, 44, cFormPag, "@!",         oWin )
    oGDias := TGet():New(  6, 74, nDias,    "999",        oWin )
    oGRet  := TGet():New(  6, 98, nPorcRet, "99.99",      oWin )
    oGObs  := TGet():New(  8, 14, cObserva, "@S60!",      oWin )

    oGInv  := TCheck():New( 7, 100, "Inversion", lInv, oWin )
    oGInv:bChange := {|| _PreInvToggle( oGInv, @aLineas, nPorcRet, ;
                                         @nBase, @nIva, @nRet, @nTotal, ;
                                         oLBase, oLIva, oLRet, oLTotal, oGrid ) }

    IF lNuevo
        oBtCli := TButton():New( 3, 14, 3, 25, oWin, "BUSCAR CLI", ;
            {|| _PreLookupCli( oGCli, @cCliNom, @cCliInfo, @cFormPag, ;
                               @nDias, @nPorcRet, oLCliNom, oLCliInfo, ;
                               oGFP, oGDias, oGRet ) } )

        oBtFP := TButton():New( 7, 44, 7, 53, oWin, "BUSCAR", ;
            {|| _PreLookupFP( oGFP ) } )
    ENDIF

    oGrid := TGrid():New( 10, 2, 24, 124, oWin )
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

    oWin:AddCtrl( TLabel():New( 27,  2, "BASE IMPONIBLE :", oWin ) )
    oWin:AddCtrl( TLabel():New( 28,  2, "TOTAL IVA      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 29,  2, "RETENCION IRPF :", oWin ) )
    oWin:AddCtrl( TLabel():New( 30,  2, "TOTAL PRESUP.:", oWin ) )

    oLBase  := TLabel():New( 27, 20, _FmtNP( nBase  ), oWin )
    oLIva   := TLabel():New( 28, 20, _FmtNP( nIva   ), oWin )
    oLRet   := TLabel():New( 29, 20, _FmtNP( nRet   ), oWin )
    oLTotal := TLabel():New( 30, 20, _FmtNP( nTotal ), oWin )
    oLTotal:cColor := "W+/B"

    oWin:AddCtrl( oLBase  )
    oWin:AddCtrl( oLIva   )
    oWin:AddCtrl( oLRet   )
    oWin:AddCtrl( oLTotal )

    oBtNLin := TButton():New( 28, 60, 28, 78, oWin, "NUEVA LINEA (F5)", ;
        {|| _PreNuevaLin( oGrid, @aLineas, nPorcRet, ;
                          @nBase, @nIva, @nRet, @nTotal, ;
                          oLBase, oLIva, oLRet, oLTotal ) } )

    oBtELin := TButton():New( 28, 80, 28, 98, oWin, "EDITAR LINEA", ;
        {|| _PreEditLin( oGrid, @aLineas, nPorcRet, ;
                         @nBase, @nIva, @nRet, @nTotal, ;
                         oLBase, oLIva, oLRet, oLTotal ) } )

    oBtDLin := TButton():New( 28,100, 28,118, oWin, "BORRAR LINEA", ;
        {|| _PreBorrarLin( oGrid, @aLineas, nPorcRet, ;
                           @nBase, @nIva, @nRet, @nTotal, ;
                           oLBase, oLIva, oLRet, oLTotal ) } )

    oBtGua := TButton():New( 33,  2, 34, 18, oWin, "GUARDAR", ;
        {|| If( PreGuardar( _PreFormHash( oGCli, oGFec, oGVal, oGFP, oGDias, oGRet, oGObs, oGInv ), ;
                           aLineas, cPieDoc, cNumero, lNuevo, ;
                           nBase, nIva, nRet, nTotal, @cNumero, oLNumero ), ;
                oWin:Close(), NIL ) } )

    oBtImp := TButton():New( 33, 20, 34, 36, oWin, "IMPRIMIR", ;
        {|| _PreImprimirActual( cNumero ) } )

    oBtCan := TButton():New( 33,108, 34,124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGCli   )
    IF lNuevo
        oWin:AddCtrl( oBtCli )
    ENDIF
    oWin:AddCtrl( oGFec   )
    oWin:AddCtrl( oGVal   )
    oWin:AddCtrl( oGFP    )
    IF lNuevo
        oWin:AddCtrl( oBtFP  )
    ENDIF
    oWin:AddCtrl( oGDias  )
    oWin:AddCtrl( oGRet   )
    oWin:AddCtrl( oGObs   )
    oWin:AddCtrl( oGInv   )
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


STATIC FUNCTION _PreCargarCab( cNum, cCli, cNom, cInfo, dFec, dVal, cFP, nDias, nRet, cObs, lAnu, lInv, ;
                               dFecAce, cAcepPor )

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
    dVal  := DbFieldValue( "VALIDEZ", PRE_C->FECHA )
    cFP   := AllTrim( DbFieldValue( "FORMA_PA", "" ) )
    nDias := DbFieldValue( "DIAS_PAG", 0 )
    nRet  := DbFieldValue( "PORC_RET", 0 )
    cObs  := AllTrim( DbFieldValue( "OBSERVA", "" ) )
    lAnu  := ( DbFieldValue( "ESTADO", "P" ) == "A" .OR. ;
               DbFieldValue( "ESTADO", "P" ) == "F" )
    lInv      := DbFieldValue( "INVERSION", .F. )
    dFecAce   := DbFieldValue( "FECHA_ACE", CToD( "" ) )
    cAcepPor  := AllTrim( DbFieldValue( "ACEPTA_POR", "" ) )

    IF ABRIR_TABLA( "CLIENTES", "CLI_P", "CLI_ID" )
        IF CLI_P->( DbSeek( cCli ) )
            cNom := AllTrim( CLI_P->NOMBRE + " " + CLI_P->APELLIDO )
            cInfo := _PreClienteInfo( CLI_P->NIF, CLI_P->TELEFONO, CLI_P->MOVIL, ;
                                      CLI_P->CIUDAD )
        ENDIF
        CLI_P->( DbCloseArea() )
    ENDIF

RETURN .T.


STATIC FUNCTION _PreClienteInfo( cNif, cTel, cMovil, cCiudad )

    LOCAL cInfo

    cInfo := ""

    IF !Empty( AllTrim( cNif ) )
        cInfo += "NIF: " + AllTrim( cNif )
    ENDIF

    IF !Empty( AllTrim( cTel ) )
        cInfo += If( Empty( cInfo ), "", "  " ) + "Tel: " + AllTrim( cTel )
    ELSEIF !Empty( AllTrim( cMovil ) )
        cInfo += If( Empty( cInfo ), "", "  " ) + "Movil: " + AllTrim( cMovil )
    ENDIF

    IF !Empty( AllTrim( cCiudad ) )
        cInfo += If( Empty( cInfo ), "", "  " ) + AllTrim( cCiudad )
    ENDIF

RETURN cInfo


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


STATIC FUNCTION _PreBuscarCli( oGet, cNom, cInfo, cFP, nDias, nRet, ;
                               oLCliNom, oLCliInfo, oGFP, oGDias, oGRet )

    LOCAL cId

    cId := AllTrim( oGet:cBuffer )

    IF Empty( cId )
        RETURN .T.
    ENDIF

    IF !ABRIR_TABLA( "CLIENTES", "CLI_BP", "CLI_ID" )
        RETURN .T.
    ENDIF

    IF CLI_BP->( DbSeek( cId ) )
        cNom  := AllTrim( CLI_BP->NOMBRE + " " + CLI_BP->APELLIDO )
        cInfo := _PreClienteInfo( CLI_BP->NIF, CLI_BP->TELEFONO, CLI_BP->MOVIL, ;
                                  CLI_BP->CIUDAD )
        cFP   := AllTrim( CLI_BP->FORPAGO )
        nDias := CLI_BP->DIAS_PAG
        nRet  := If( CLI_BP->APL_IRPF, 15.00, 0.00 )
    ELSE
        MsgStop( "Cliente " + cId + " no encontrado.", "Busqueda" )
        CLI_BP->( DbCloseArea() )
        RETURN .F.
    ENDIF

    CLI_BP->( DbCloseArea() )

    oLCliNom:SetText( PadR( cNom, 70 ) )
    oLCliInfo:SetText( PadR( cInfo, 80 ) )

    oGFP:SetValue( cFP )
    oGDias:SetValue( nDias )
    oGRet:SetValue( nRet )

RETURN .T.


STATIC FUNCTION _PreLookupCli( oGet, cNom, cInfo, cFP, nDias, nRet, ;
                               oLCliNom, oLCliInfo, oGFP, oGDias, oGRet )

    LOCAL cId

    cId := LookupCliente()
    IF Empty( cId )
        RETURN NIL
    ENDIF

    oGet:SetValue( cId )

RETURN _PreBuscarCli( oGet, @cNom, @cInfo, @cFP, @nDias, @nRet, ;
                      oLCliNom, oLCliInfo, oGFP, oGDias, oGRet )


STATIC FUNCTION _PreLookupFP( oGFP )

    LOCAL cFP

    cFP := LookupFormaPago()
    IF !Empty( cFP )
        oGFP:SetValue( cFP )
    ENDIF

RETURN NIL


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


STATIC FUNCTION _PreInvToggle( oInv, aLins, nPRet, nBase, nIva, nRet, nTotal, ;
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
    _PreCalcTot( aLins, nPRet, @nBase, @nIva, @nRet, @nTotal )
    oLBase:SetText(  _FmtNP( nBase  ) )
    oLIva:SetText(   _FmtNP( nIva   ) )
    oLRet:SetText(   _FmtNP( nRet   ) )
    oLTotal:SetText( _FmtNP( nTotal ) )

RETURN NIL


STATIC FUNCTION _PreMostrarCondiciones( cNumPre )

    LOCAL oWin
    LOCAL oLbl
    LOCAL oBtOk
    LOCAL cCond

    cCond := ""
    IF ABRIR_TABLA( "EMPRESA", "EMP_CD", "" )
        EMP_CD->( DbGoTop() )
        IF !EMP_CD->( Eof() )
            cCond := AllTrim( DbFieldValue( "PIE_DOC", "" ) )
        ENDIF
        EMP_CD->( DbCloseArea() )
    ENDIF

    IF Empty( cCond )
        cCond := "CONDICIONES GENERALES" + Chr(13) + Chr(10) + Chr(13) + Chr(10) + ;
                 "1. Validez: 15 dias desde la fecha del presupuesto." + Chr(13) + Chr(10) + ;
                 "2. Forma de Pago: Segun condiciones pactadas." + Chr(13) + Chr(10) + ;
                 "3. Los trabajos no especificados se facturaran aparte." + Chr(13) + Chr(10) + ;
                 "4. No se incluyen tasas ni licencias municipales." + Chr(13) + Chr(10) + Chr(13) + Chr(10) + ;
                 "Al aceptar este presupuesto, el cliente declara estar conforme" + Chr(13) + Chr(10) + ;
                 "con las condiciones generales y el alcance descrito."
    ENDIF

    oWin := TWindow():New( 3, 6, 25, 122, "CONDICIONES GENERALES - " + AllTrim( cNumPre ) )
    oLbl := TLabel():New( 2, 3, PadR( cCond, 115 ), oWin )
    oWin:AddCtrl( oLbl )

    oBtOk := TButton():New( 18, 50, 19, 72, oWin, "CONTINUAR", ;
        {|| oWin:Close() } )
    oWin:AddCtrl( oBtOk )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _PreFormAceptacion( cAceptaPor, cNumPre )

    LOCAL oWin
    LOCAL oGAcep
    LOCAL oBtOk
    LOCAL oBtCan
    LOCAL lOK := .F.

    oWin := TWindow():New( 12, 22, 24, 106, "ACEPTACION DEL PRESUPUESTO" )

    oWin:AddCtrl( TLabel():New(  2,  3, "Presupuesto : " + AllTrim( cNumPre ), oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  3, "Fecha       : " + DToC( Date() ), oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  3, "Aceptado por:", oWin ) )

    oGAcep := TGet():New( 6, 18, PadR( cAceptaPor, 30 ), "@!", oWin )
    oGAcep:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oBtOk := TButton():New( 10, 16, 11, 38, oWin, "ACEPTAR Y CREAR OBRA", ;
        {|| lOK := .T., cAceptaPor := AllTrim( oGAcep:GetValue() ), oWin:Close() } )

    oBtCan := TButton():New( 10, 42, 11, 64, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGAcep )
    oWin:AddCtrl( oBtOk  )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

RETURN lOK


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
        nImp := ( _PreGetNum( oGCant ) * _PreGetNum( oGPre ) ) * ;
                ( 1 - _PreGetNum( oGDto ) / 100 ), ;
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
        aLin[LIN_DESC] := AllTrim( oGDesc:GetValue() )
        aLin[LIN_CANT] := _PreGetNum( oGCant )
        aLin[LIN_PRE]  := _PreGetNum( oGPre )
        aLin[LIN_DTO]  := _PreGetNum( oGDto )
        aLin[LIN_IVA]  := _PreGetNum( oGIva )
        aLin[LIN_IMP]  := ( aLin[LIN_CANT] * aLin[LIN_PRE] ) * ;
                          ( 1 - aLin[LIN_DTO] / 100 )
    ENDIF

RETURN lOK


STATIC FUNCTION _PreGetNum( oGet )

    IF oGet == NIL
        RETURN 0
    ENDIF

RETURN Val( StrTran( AllTrim( oGet:cBuffer ), ",", "" ) )


// ============================================================================
// FORM HASH
// ============================================================================
STATIC FUNCTION _PreFormHash( oGCli, oGFec, oGVal, oGFP, oGDias, oGRet, oGObs, oGInv )

    LOCAL hPre := {=>}

    hPre[ "CLIENTE_" ] := AllTrim( oGCli:GetValue() )
    hPre[ "FECHA"    ] := oGFec:GetValue()
    hPre[ "VALIDEZ"  ] := oGVal:GetValue()
    hPre[ "FORMA_PA" ] := AllTrim( oGFP:GetValue() )
    hPre[ "DIAS_PAG" ] := oGDias:GetValue()
    hPre[ "PORC_RET" ] := oGRet:GetValue()
    hPre[ "OBSERVA"  ] := AllTrim( oGObs:GetValue() )
    hPre[ "INVERSION" ] := oGInv:GetValue()

RETURN hPre


// ============================================================================
// GUARDAR
// ============================================================================
FUNCTION PreGuardar( hPre, aLins, cPieDoc, cNumero, lNuevo, ;
                       nBase, nIva, nRet, nTotal, cNumRef, oLNumero )

    LOCAL cCli
    LOCAL dFec
    LOCAL dVal
    LOCAL cFP
    LOCAL nDias
    LOCAL nPRet
    LOCAL cObs
    LOCAL cNum
    LOCAL i

    cCli  := hPre[ "CLIENTE_" ]
    dFec  := hPre[ "FECHA"    ]
    dVal  := hPre[ "VALIDEZ"  ]
    cFP   := hPre[ "FORMA_PA" ]
    nDias := hPre[ "DIAS_PAG" ]
    nPRet := hPre[ "PORC_RET" ]
    cObs  := hPre[ "OBSERVA"  ]
    cNum  := cNumero

    IF Empty( cCli )
        MsgStop( "Debe indicar el cliente.", "Guardar" )
        RETURN .F.
    ENDIF

    IF !_PreClienteExiste( cCli )
        MsgStop( "Cliente " + AllTrim( cCli ) + " no encontrado.", "Guardar" )
        RETURN .F.
    ENDIF

    IF Len( aLins ) == 0
        MsgStop( "Debe introducir al menos una linea.", "Guardar" )
        RETURN .F.
    ENDIF

    IF lNuevo
        cNum := _PreSiguiente()
        IF Empty( cNum )
            RETURN .F.
        ENDIF
    ENDIF

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_G", "PRE_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PRE_G" )
    OrdSetFocus( "PRE_NUM" )

    IF lNuevo
        IF !NetFLock()
            PRE_G->( DbCloseArea() )
            RETURN .F.
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cNum )
            PRE_G->( DbCloseArea() )
            RETURN .F.
        ENDIF

        IF !Empty( AllTrim( DbFieldValue( "ID_OBRA", "" ) ) ) .OR. ;
           AllTrim( DbFieldValue( "ESTADO", "P" ) ) == "A" .OR. ;
           AllTrim( DbFieldValue( "ESTADO", "P" ) ) == "R"
            MsgStop( "No se puede modificar un presupuesto aceptado, rechazado o con obra creada.", ;
                     "Guardar" )
            PRE_G->( DbCloseArea() )
            RETURN .F.
        ENDIF

        IF !NetRLock()
            PRE_G->( DbCloseArea() )
            RETURN .F.
        ENDIF
    ENDIF

    IF !ABRIR_TABLA( "PRESUP_DE", "PRD_G", "PRD_LIN" )
        PRE_G->( DbUnlock() )
        PRE_G->( DbCloseArea() )
        RETURN .F.
    ENDIF

    DbSelectArea( "PRD_G" )

    IF !NetFLock()
        PRD_G->( DbCloseArea() )
        PRE_G->( DbUnlock() )
        PRE_G->( DbCloseArea() )
        RETURN .F.
    ENDIF

    IF !lNuevo
        _PreBorrarLinsArea( cNum )
    ENDIF

    BEGIN SEQUENCE

        BEGIN TRANSACTION

            DbSelectArea( "PRE_G" )

            REPLACE PRE_G->NUMERO   WITH cNum
            REPLACE PRE_G->FECHA    WITH dFec
            DbFieldPutIf( "VALIDEZ", dVal )
            REPLACE PRE_G->CLIENTE_ WITH cCli
            REPLACE PRE_G->VENDEDOR WITH Space( 10 )
            REPLACE PRE_G->SUBTOTAL WITH nBase
            REPLACE PRE_G->IVA      WITH nIva
            REPLACE PRE_G->TOTAL    WITH nTotal
            DbFieldPutIf( "OBSERVA",  cObs )
            DbFieldPutIf( "PIE_DOC",  cPieDoc )
            DbFieldPutIf( "FORMA_PA", PadR( cFP, 3 ) )
            DbFieldPutIf( "DIAS_PAG", nDias )
            DbFieldPutIf( "RETENCIO", nRet )
            DbFieldPutIf( "PORC_RET", nPRet )
            DbFieldPutIf( "INVERSION", hPre[ "INVERSION" ] )

            IF lNuevo
                DbFieldPutIf( "ESTADO",  "P" )
                DbFieldPutIf( "NUM_FAC", Space( 10 ) )
                DbFieldPutIf( "ID_OBRA", Space( 10 ) )
                DbFieldPutIf( "TIPO",    "C" )
            ENDIF

            DbSelectArea( "PRD_G" )

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

        END TRANSACTION

    RECOVER
        ROLLBACK
        PRD_G->( DbUnlock() )
        PRD_G->( DbCloseArea() )
        PRE_G->( DbUnlock() )
        PRE_G->( DbCloseArea() )
        MsgStop( "Error al guardar el presupuesto. No se realizaron cambios.", "Error" )
        RETURN .F.

    END SEQUENCE

    PRD_G->( DbUnlock() )
    PRD_G->( DbCloseArea() )
    PRE_G->( DbUnlock() )
    PRE_G->( DbCloseArea() )

    IF lNuevo .AND. oLNumero != NIL
        oLNumero:SetText( PadR( cNum, 24 ) )
    ENDIF

    cNumRef := cNum

    MsgInfo( "Presupuesto " + cNum + " guardado.", "Guardado" )

    IF MsgYesNo( "Desea imprimir el presupuesto ahora?", "Imprimir" )
        ImprimirPresupuesto( cNum )
    ENDIF

RETURN .T.


STATIC FUNCTION _PreBorrarCabDB( cNum )

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_B", "PRE_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PRE_B" )
    OrdSetFocus( "PRE_NUM" )

    IF DbSeek( cNum ) .AND. NetRLock()
        PRE_B->( DbDelete() )
        DbUnlock()
        PRE_B->( DbCloseArea() )
        RETURN .T.
    ENDIF

    PRE_B->( DbCloseArea() )

RETURN .F.


STATIC FUNCTION _PreSiguiente()

    LOCAL cAnio
    LOCAL cPref
    LOCAL cNum
    LOCAL nMax
    LOCAL nSeq

    cAnio := StrZero( Year( Date() ), 4 )
    cPref := "P" + cAnio
    nMax  := 0

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_N", "PRE_NUM" )
        RETURN ""
    ENDIF

    DbSelectArea( "PRE_N" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            cNum := AllTrim( PRE_N->NUMERO )
            IF Left( cNum, Len( cPref ) ) == cPref
                nSeq := Val( SubStr( cNum, Len( cPref ) + 1, 4 ) )
                IF nSeq > nMax
                    nMax := nSeq
                ENDIF
            ENDIF
        ENDIF
        DbSkip()
    ENDDO

    PRE_N->( DbCloseArea() )

RETURN cPref + StrZero( nMax + 1, 4 )


STATIC FUNCTION _PreClienteExiste( cCli )

    LOCAL lExiste

    lExiste := .F.

    IF Empty( AllTrim( cCli ) )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "CLIENTES", "CLI_PV", "CLI_ID" )
        RETURN .F.
    ENDIF

    DbSelectArea( "CLI_PV" )
    OrdSetFocus( "CLI_ID" )
    lExiste := DbSeek( PadR( AllTrim( cCli ), 10 ) ) .OR. DbSeek( AllTrim( cCli ) )

    CLI_PV->( DbCloseArea() )

RETURN lExiste


STATIC FUNCTION _PreImprimirActual( cNumero )

    IF Empty( AllTrim( cNumero ) )
        MsgStop( "Guarde el presupuesto antes de imprimir.", "Imprimir" )
        RETURN .F.
    ENDIF

RETURN ImprimirPresupuesto( cNumero )


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


STATIC FUNCTION _PreBorrarLinsArea( cNum )

    OrdSetFocus( "PRD_LIN" )
    DbSeek( PadR( cNum, 10 ) + "  1" )

    DO WHILE !Eof() .AND. AllTrim( PRD_G->NUMERO ) == AllTrim( cNum )
        PRD_G->( DbDelete() )
        DbSkip()
    ENDDO

RETURN NIL


// ============================================================================
// ImprimirPresupuesto( cNumero )
// Llama a la funcion de impresion de presupuestos
// ============================================================================
FUNCTION ImprimirPresupuesto( cNumero )

    IF ValType( cNumero ) != "C" .OR. Empty( cNumero )
        MsgStop( "Numero de presupuesto invalido", "Error" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_IP", "PRE_NUM" )
        MsgStop( "No existe la tabla de presupuestos", "Error" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PRE_IP" )
    OrdSetFocus( "PRE_NUM" )
    IF !( DbSeek( PadR( AllTrim( cNumero ), 10 ) ) .OR. DbSeek( AllTrim( cNumero ) ) )
        PRE_IP->( DbCloseArea() )
        MsgStop( "Presupuesto " + AllTrim( cNumero ) + " no encontrado.", "Error" )
        RETURN .F.
    ENDIF

    PRE_IP->( DbCloseArea() )

    ImprimirPresup( cNumero )

RETURN .T.



// ============================================================================
// AceptarPresupuesto( cNumPre )
// ----------------------------------------------------------------------------
// Acepta un presupuesto y crea una obra.
// La factura fiscal nace despues, siempre vinculada a esa obra.
// ============================================================================
FUNCTION AceptarPresupuesto( cNumPre )

    LOCAL cEstado
    LOCAL cIdObra
    LOCAL cDesc
    LOCAL cAceptaPor
    LOCAL nArea

    cEstado    := ""
    cIdObra    := ""
    cDesc      := ""
    cAceptaPor := ""

    MEMVAR cUserID

    IF Empty( AllTrim( cNumPre ) )
        MsgStop( "Seleccione un presupuesto.", "Aceptar" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_AC", "PRE_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PRE_AC" )
    OrdSetFocus( "PRE_NUM" )

    IF !( DbSeek( PadR( AllTrim( cNumPre ), 10 ) ) .OR. DbSeek( AllTrim( cNumPre ) ) )
        PRE_AC->( DbCloseArea() )
        MsgStop( "Presupuesto " + cNumPre + " no encontrado.", "Aceptar" )
        RETURN .F.
    ENDIF

    cEstado := AllTrim( DbFieldValue( "ESTADO", "P" ) )
    cIdObra := AllTrim( DbFieldValue( "ID_OBRA", "" ) )

    PRE_AC->( DbCloseArea() )

    DO CASE
    CASE !Empty( cIdObra )
        MsgStop( "Este presupuesto ya tiene obra creada." + Chr(13) + ;
                 "Obra: " + cIdObra, "Aceptar" )
        RETURN .F.
    CASE cEstado == "R"
        MsgStop( "No se puede aceptar un presupuesto rechazado.", "Aceptar" )
        RETURN .F.
    ENDCASE

    _PreMostrarCondiciones( cNumPre )

    IF Type( "cUserID" ) == "C" .AND. !Empty( cUserID )
        cAceptaPor := AllTrim( cUserID )
    ELSE
        cAceptaPor := "SISTEMA"
    ENDIF

    nArea := Select()

    IF !_PreFormAceptacion( @cAceptaPor, cNumPre )
        Select( nArea )
        RETURN .F.
    ENDIF

    IF !MsgYesNo( "Confirmar aceptacion del presupuesto " + AllTrim( cNumPre ) + ;
                  " y crear la obra?", "Aceptar" )
        Select( nArea )
        RETURN .F.
    ENDIF

    cDesc := _PreDescripcionObra( AllTrim( cNumPre ) )

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_AM", "PRE_NUM" )
        Select( nArea )
        RETURN .F.
    ENDIF

    DbSelectArea( "PRE_AM" )
    OrdSetFocus( "PRE_NUM" )

    IF ( DbSeek( PadR( AllTrim( cNumPre ), 10 ) ) .OR. DbSeek( AllTrim( cNumPre ) ) ) .AND. NetRLock()
        DbFieldPutIf( "ESTADO", "A" )
        DbFieldPutIf( "FECHA_ACE", Date() )
        DbFieldPutIf( "ACEPTA_POR", PadR( cAceptaPor, 30 ) )
        DbCommit()
        DbUnlock()
    ELSE
        PRE_AM->( DbCloseArea() )
        MsgStop( "No se pudo marcar el presupuesto como aceptado.", "Aceptar" )
        Select( nArea )
        RETURN .F.
    ENDIF

    PRE_AM->( DbCloseArea() )

    AuditLog( "ACEPTA", "PRESUPUEST", AllTrim( cNumPre ), ;
              "Presupuesto aceptado por " + cAceptaPor, .T. )

    cIdObra := CrearObraDesdePresupuesto( AllTrim( cNumPre ), cDesc, "", Date(), CToD( "" ) )

    IF Empty( cIdObra )
        MsgStop( "El presupuesto quedo aceptado, pero no se pudo crear la obra.", "Aceptar" )
        RETURN .F.
    ENDIF

    AuditLog( "ALTA", "OBRAS", cIdObra, ;
              "Obra creada desde presupuesto " + AllTrim( cNumPre ), .T. )

    MsgInfo( "Presupuesto aceptado." + Chr(13) + ;
             "Obra creada: " + cIdObra, "Aceptar" )

RETURN .T.


STATIC FUNCTION _PreDescripcionObra( cNumPre )

    LOCAL cDesc

    cDesc := ""

    IF !ABRIR_TABLA( "PRESUP_DE", "PRD_DESC", "PRD_LIN" )
        RETURN "Obra segun presupuesto " + AllTrim( cNumPre )
    ENDIF

    DbSelectArea( "PRD_DESC" )
    OrdSetFocus( "PRD_LIN" )

    IF DbSeek( PadR( AllTrim( cNumPre ), 10 ) + "  1" )
        cDesc := AllTrim( PRD_DESC->DESCRIPC )
    ENDIF

    PRD_DESC->( DbCloseArea() )

    IF Empty( cDesc )
        cDesc := "Obra segun presupuesto " + AllTrim( cNumPre )
    ENDIF

RETURN cDesc


// ============================================================================
// RechazarPresupuesto( cNumPre )
// ----------------------------------------------------------------------------
// Marca un presupuesto como rechazado por el cliente.
// No genera ningun documento — solo cambia el estado.
// ============================================================================
FUNCTION RechazarPresupuesto( cNumPre )

    LOCAL cEstado
    LOCAL cMotivo
    LOCAL cIdObra
    LOCAL oWin
    LOCAL oGMot
    LOCAL oBtOk
    LOCAL oBtCan
    LOCAL lOK

    cEstado := ""
    cMotivo := Space( 60 )
    cIdObra := ""
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

    cEstado := AllTrim( DbFieldValue( "ESTADO", "P" ) )
    cIdObra := AllTrim( DbFieldValue( "ID_OBRA", "" ) )

    PRE_RV->( DbCloseArea() )

    DO CASE
    CASE !Empty( cIdObra )
        MsgStop( "No se puede rechazar un presupuesto con obra creada." + Chr(13) + ;
                 "Cancele la obra si procede.", "Rechazar" )
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

    cMotivo := AllTrim( oGMot:GetValue() )

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
        DbFieldPutIf( "ESTADO", "R" )
        DbFieldPutIf( "OBSERVA", "RECHAZADO: " + cMotivo )
        DbCommit()
        DbUnlock()
    ENDIF

    PRE_RM->( DbCloseArea() )

    AuditLog( "RECHAZA", "PRESUPUEST", AllTrim( cNumPre ), cMotivo, .T. )

    MsgInfo( "Presupuesto " + AllTrim( cNumPre ) + " marcado como rechazado.", ;
             "Rechazar" )

RETURN .T.


// ============================================================================
// FIN DE V_Presupuesto.prg
// ============================================================================
