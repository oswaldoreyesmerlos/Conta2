/*
 * ARCHIVO  : M_Obras.prg
 * PROPOSITO: Motor de negocio para obras.
 *
 * Este modulo contiene logica interna, no pantallas:
 * - crear obra desde presupuesto aceptado
 * - crear obra manual
 * - calcular estado economico de obra
 * - emitir factura de anticipo/certificacion/final vinculada a obra
 *
 * Flujo de negocio:
 *   PRESUPUESTO -> OBRA -> FACTURA -> RECIBO
 */

#include "OOp.ch"

// ============================================================================
// CrearObraDesdePresupuesto()
// Crea una obra a partir de un presupuesto aceptado.
// Devuelve ID de obra o "" si no se pudo crear.
// ============================================================================
FUNCTION CrearObraDesdePresupuesto( cNumPre, cDescripcion, cDireccionObra, dFechaIn, dFechaFin )

   LOCAL cIdObra  := ""
   LOCAL cCliente := ""
   LOCAL nTotal   := 0.00
   LOCAL cObs     := ""
   LOCAL nArea    := Select()

   DEFAULT cDescripcion   TO ""
   DEFAULT cDireccionObra TO ""
   DEFAULT dFechaIn       TO Date()
   DEFAULT dFechaFin      TO CToD( "" )

   IF !ValidarCrearObraDesdePresupuesto( cNumPre )
      Select( nArea )
      RETURN ""
   ENDIF

   IF !ABRIR_TABLA( "PRESUPUEST", "PRE_OBR_C", "PRE_NUM" )
      Select( nArea )
      RETURN ""
   ENDIF

   DbSelectArea( "PRE_OBR_C" )
   OrdSetFocus( "PRE_NUM" )

   IF !( DbSeek( PadR( cNumPre, 10 ) ) .OR. DbSeek( cNumPre ) )
      PRE_OBR_C->( DbCloseArea() )
      MsgStop( "No se encontro el presupuesto indicado.", "Obras" )
      Select( nArea )
      RETURN ""
   ENDIF

   cCliente := PRE_OBR_C->CLIENTE_
   nTotal   := PRE_OBR_C->TOTAL
   cObs     := AllTrim( PRE_OBR_C->OBSERVA )

   IF Empty( cDescripcion )
      cDescripcion := "Obra segun presupuesto " + AllTrim( cNumPre )
   ENDIF

   cIdObra := _ObraSiguiente()
   IF Empty( cIdObra )
      PRE_OBR_C->( DbCloseArea() )
      Select( nArea )
      RETURN ""
   ENDIF

   IF !_ObraAppend( cIdObra, cNumPre, cCliente, cDescripcion, cDireccionObra, ;
                    dFechaIn, dFechaFin, nTotal, "A", cObs )
      PRE_OBR_C->( DbCloseArea() )
      Select( nArea )
      RETURN ""
   ENDIF

   // Marcar el presupuesto con la obra creada.
   DbSelectArea( "PRE_OBR_C" )
   IF NetRLock()
      REPLACE PRE_OBR_C->ID_OBRA WITH cIdObra
      IF Empty( PRE_OBR_C->TIPO )
         REPLACE PRE_OBR_C->TIPO WITH "C"
      ENDIF
      DbCommit()
      DbUnlock()
   ENDIF

   PRE_OBR_C->( DbCloseArea() )
   Select( nArea )

RETURN cIdObra


// ============================================================================
// CrearObraManual()
// Permite crear una obra sin presupuesto origen.
// Util para trabajos internos o casos excepcionales controlados.
// ============================================================================
FUNCTION CrearObraManual( cCliente, cDescripcion, cDireccionObra, nTotal, dFechaIn, dFechaFin )

   LOCAL cIdObra := ""
   LOCAL nArea   := Select()

   DEFAULT cCliente       TO ""
   DEFAULT cDescripcion   TO ""
   DEFAULT cDireccionObra TO ""
   DEFAULT nTotal         TO 0.00
   DEFAULT dFechaIn       TO Date()
   DEFAULT dFechaFin      TO CToD( "" )

   IF Empty( cCliente )
      MsgStop( "Debe indicar el cliente de la obra.", "Obras" )
      Select( nArea )
      RETURN ""
   ENDIF

   IF Empty( cDescripcion )
      MsgStop( "Debe indicar una descripcion de la obra.", "Obras" )
      Select( nArea )
      RETURN ""
   ENDIF

   IF nTotal <= 0
      MsgStop( "El total de la obra debe ser mayor que cero.", "Obras" )
      Select( nArea )
      RETURN ""
   ENDIF

   cIdObra := _ObraSiguiente()
   IF Empty( cIdObra )
      Select( nArea )
      RETURN ""
   ENDIF

   IF !_ObraAppend( cIdObra, "", cCliente, cDescripcion, cDireccionObra, ;
                    dFechaIn, dFechaFin, nTotal, "A", "" )
      Select( nArea )
      RETURN ""
   ENDIF

   AuditLog( "ALTA", "OBRAS", cIdObra, ;
             "Obra manual creada", .T. )

   Select( nArea )

RETURN cIdObra


// ============================================================================
// GetResumenObra()
// Devuelve { total, facturado, pendiente, estado }
// ============================================================================
FUNCTION GetResumenObra( cIdObra )

   LOCAL nArea      := Select()
   LOCAL nTotal     := GetTotalObra( cIdObra )
   LOCAL nFacturado := GetFacturadoObra( cIdObra )
   LOCAL nPendiente := nTotal - nFacturado
   LOCAL cEstado    := ""

   IF ABRIR_TABLA( "OBRAS", "OBR_RES", "OBR_ID" )
      DbSelectArea( "OBR_RES" )
      OrdSetFocus( "OBR_ID" )
      IF DbSeek( PadR( cIdObra, 12 ) ) .OR. DbSeek( cIdObra )
         cEstado := DbFieldValue( "ESTADO", "" )
      ENDIF
      OBR_RES->( DbCloseArea() )
   ENDIF

   Select( nArea )

RETURN { nTotal, nFacturado, nPendiente, cEstado }


// ============================================================================
// FacturarObra()
// Crea una factura de obra con una sola linea descriptiva.
//
// cTipoFac: A=Anticipo, C=Certificacion, F=Final, R=Rectificativa
// nImporte: TOTAL factura, IVA incluido si nPorcIva > 0.
// nPorcIva: 21, 10, 0, etc. Para inversion sujeto pasivo usar 0.
//
// Devuelve numero de factura o "" si no se pudo emitir.
// ============================================================================
FUNCTION FacturarObra( cIdObra, nImporte, cTipoFac, nPorcIva, cConcepto, dFecha )

   LOCAL cNumFac   := ""
   LOCAL cCliente  := ""
   LOCAL cNumPre   := ""
   LOCAL cDescObra := ""
   LOCAL cSerie    := "A"
   LOCAL nBase     := 0.00
   LOCAL nIva      := 0.00
   LOCAL nTotal    := 0.00
   LOCAL dVto
   LOCAL nDias     := 0
   LOCAL cFormaPa  := ""
   LOCAL nArea     := Select()

   DEFAULT cTipoFac TO "C"
   DEFAULT nPorcIva TO 21.00
   DEFAULT cConcepto TO ""
   DEFAULT dFecha TO Date()

   cTipoFac := Upper( AllTrim( cTipoFac ) )

   IF !( cTipoFac $ "ACFR" )
      MsgStop( "Tipo de factura de obra no valido.", "Obras" )
      Select( nArea )
      RETURN ""
   ENDIF

   IF !ValidarFacturaObra( cIdObra, nImporte )
      Select( nArea )
      RETURN ""
   ENDIF

   IF !_ObraLeerCab( cIdObra, @cCliente, @cNumPre, @cDescObra )
      Select( nArea )
      RETURN ""
   ENDIF

   _ObraFormaPagoCliente( cCliente, @cFormaPa, @nDias )
   dVto := dFecha + nDias

   nTotal := Round( nImporte, 2 )
   IF nPorcIva > 0
      nBase := Round( nTotal / ( 1 + ( nPorcIva / 100 ) ), 2 )
      nIva  := Round( nTotal - nBase, 2 )
   ELSE
      nBase := nTotal
      nIva  := 0.00
   ENDIF

   IF Empty( cConcepto )
      cConcepto := _ObraConceptoFactura( cTipoFac, cIdObra, cDescObra )
   ENDIF

   cNumFac := _ObraSiguienteFactura()
   IF Empty( cNumFac )
      Select( nArea )
      RETURN ""
   ENDIF

   IF !_ObraCrearFacturaCab( cSerie, cNumFac, cCliente, dFecha, dVto, ;
                             nBase, nIva, nTotal, cFormaPa, cNumPre, ;
                             cIdObra, cTipoFac, cConcepto )
      Select( nArea )
      RETURN ""
   ENDIF

   IF !_ObraCrearFacturaLin( cSerie, cNumFac, cConcepto, nBase, nPorcIva )
      Select( nArea )
      RETURN ""
   ENDIF

   _ObraGenVencimiento( cSerie, cNumFac, cCliente, dVto, nTotal, cIdObra )
   _ObraActualizarEstado( cIdObra )

   AuditLog( "FACTURA", "OBRAS", AllTrim( cIdObra ), ;
             "Factura " + cNumFac + " tipo " + cTipoFac, .T. )

   Select( nArea )

RETURN cNumFac


// ============================================================================
// MarcarObraEnCurso()
// ============================================================================
FUNCTION MarcarObraEnCurso( cIdObra )
RETURN _ObraCambiarEstado( cIdObra, "E" )


// ============================================================================
// CerrarObra()
// ============================================================================
FUNCTION CerrarObra( cIdObra )

   IF !ValidarCerrarObra( cIdObra )
      RETURN .F.
   ENDIF

RETURN _ObraCambiarEstado( cIdObra, "F" )


// ============================================================================
// CancelarObra()
// Regla prudente: no cancela si ya hay facturas emitidas.
// ============================================================================
FUNCTION CancelarObra( cIdObra )

   IF _ObraTieneFacturas( cIdObra )
      MsgStop( "No se puede cancelar una obra que ya tuvo facturas emitidas." + Chr(13) + ;
               "Use nota de abono o regularizacion para conservar trazabilidad.", ;
               "Obras" )
      RETURN .F.
   ENDIF

RETURN _ObraCambiarEstado( cIdObra, "C" )


STATIC FUNCTION _ObraTieneFacturas( cIdObra )

   LOCAL lTiene := .F.
   LOCAL nArea  := Select()

   IF Empty( cIdObra )
      RETURN .F.
   ENDIF

   IF !ABRIR_TABLA( "FACTURA", "FAC_OBR_H", "FAC_OBR" )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbSelectArea( "FAC_OBR_H" )
   OrdSetFocus( "FAC_OBR" )
   DbGoTop()

   DO WHILE !Eof() .AND. !lTiene
      IF !Deleted() .AND. AllTrim( FAC_OBR_H->ID_OBRA ) == AllTrim( cIdObra )
         lTiene := .T.
      ENDIF
      DbSkip()
   ENDDO

   FAC_OBR_H->( DbCloseArea() )
   Select( nArea )

RETURN lTiene


// ============================================================================
// _ObraAppend()
// ============================================================================
STATIC FUNCTION _ObraAppend( cIdObra, cNumPre, cCliente, cDescripcion, cDireccionObra, ;
                             dFechaIn, dFechaFin, nTotal, cEstado, cObserva )

   LOCAL cUsuario := "SISTEMA"
   LOCAL nArea    := Select()

   MEMVAR cUserID

   IF Type( "cUserID" ) == "C" .AND. !Empty( cUserID )
      cUsuario := AllTrim( cUserID )
   ENDIF

   IF !ABRIR_TABLA( "OBRAS", "OBR_APP", "OBR_ID" )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbSelectArea( "OBR_APP" )
   IF !NetFLock()
      OBR_APP->( DbCloseArea() )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbAppend()
   REPLACE OBR_APP->ID        WITH PadR( AllTrim( cIdObra ), 12 )
   REPLACE OBR_APP->NUM_PRE   WITH PadR( AllTrim( cNumPre ), 10 )
   REPLACE OBR_APP->CLIENTE_  WITH PadR( AllTrim( cCliente ), 10 )
   REPLACE OBR_APP->DESCRIP   WITH PadR( AllTrim( cDescripcion ), 80 )
   REPLACE OBR_APP->DIRECC_OB WITH PadR( AllTrim( cDireccionObra ), 80 )
   REPLACE OBR_APP->FECHA_IN  WITH dFechaIn
   REPLACE OBR_APP->FECHA_FIN WITH dFechaFin
   REPLACE OBR_APP->TOTAL     WITH nTotal
   REPLACE OBR_APP->ESTADO    WITH cEstado
   REPLACE OBR_APP->USUARIO_  WITH PadR( cUsuario, 10 )
   REPLACE OBR_APP->FECHA_AL  WITH Date()
   REPLACE OBR_APP->OBSERVA   WITH cObserva

   DbCommit()
   DbUnlock()
   OBR_APP->( DbCloseArea() )
   Select( nArea )

RETURN .T.


// ============================================================================
// _ObraLeerCab()
// ============================================================================
STATIC FUNCTION _ObraLeerCab( cIdObra, cCliente, cNumPre, cDescObra )

   LOCAL lOk   := .F.
   LOCAL nArea := Select()

   IF !ABRIR_TABLA( "OBRAS", "OBR_LEE", "OBR_ID" )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbSelectArea( "OBR_LEE" )
   OrdSetFocus( "OBR_ID" )

   IF DbSeek( PadR( cIdObra, 12 ) ) .OR. DbSeek( cIdObra )
      cCliente  := OBR_LEE->CLIENTE_
      cNumPre   := OBR_LEE->NUM_PRE
      cDescObra := AllTrim( OBR_LEE->DESCRIP )
      lOk       := .T.
   ENDIF

   OBR_LEE->( DbCloseArea() )
   Select( nArea )

   IF !lOk
      MsgStop( "No se encontro la obra indicada.", "Obras" )
   ENDIF

RETURN lOk


// ============================================================================
// _ObraFormaPagoCliente()
// ============================================================================
STATIC FUNCTION _ObraFormaPagoCliente( cCliente, cFormaPa, nDias )

   LOCAL nArea := Select()

   cFormaPa := ""
   nDias    := 0

   IF ABRIR_TABLA( "CLIENTES", "CLI_OBR", "CLI_ID" )
      DbSelectArea( "CLI_OBR" )
      OrdSetFocus( "CLI_ID" )
      IF DbSeek( PadR( cCliente, 10 ) ) .OR. DbSeek( cCliente )
         cFormaPa := CLI_OBR->FORPAGO
         nDias    := CLI_OBR->DIAS_PAG
      ENDIF
      CLI_OBR->( DbCloseArea() )
   ENDIF

   Select( nArea )

RETURN NIL


// ============================================================================
// _ObraCrearFacturaCab()
// ============================================================================
STATIC FUNCTION _ObraCrearFacturaCab( cSerie, cNumFac, cCliente, dFecha, dVto, ;
                                      nBase, nIva, nTotal, cFormaPa, cNumPre, ;
                                      cIdObra, cTipoFac, cConcepto )

   LOCAL nArea := Select()

   IF !ABRIR_TABLA( "FACTURA", "FAC_OBR_C", "FAC_NUM" )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbSelectArea( "FAC_OBR_C" )
   IF !NetFLock()
      FAC_OBR_C->( DbCloseArea() )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbAppend()
   REPLACE FAC_OBR_C->SERIE    WITH PadR( cSerie, 4 )
   REPLACE FAC_OBR_C->NUMERO   WITH PadR( cNumFac, 10 )
   REPLACE FAC_OBR_C->CLIENTE_ WITH PadR( AllTrim( cCliente ), 10 )
   REPLACE FAC_OBR_C->FECHA    WITH dFecha
   REPLACE FAC_OBR_C->FECHA_OP WITH Date()
   REPLACE FAC_OBR_C->HORA     WITH Time()
   REPLACE FAC_OBR_C->SUBTOTAL WITH nBase
   REPLACE FAC_OBR_C->IVA      WITH nIva
   REPLACE FAC_OBR_C->RE_EQUIP WITH 0.00
   REPLACE FAC_OBR_C->RETENCIO WITH 0.00
   REPLACE FAC_OBR_C->PORC_RET WITH 0.00
   REPLACE FAC_OBR_C->TOTAL    WITH nTotal
   REPLACE FAC_OBR_C->FORMA_PA WITH PadR( AllTrim( cFormaPa ), 3 )
   REPLACE FAC_OBR_C->FECHA_VT WITH dVto
   REPLACE FAC_OBR_C->COBRADA  WITH .F.
   REPLACE FAC_OBR_C->COBRADO  WITH 0.00
   REPLACE FAC_OBR_C->ANULADA  WITH .F.
   REPLACE FAC_OBR_C->TIPO_DOC WITH "F"
   REPLACE FAC_OBR_C->OBSERVA  WITH PadR( AllTrim( cConcepto ), 80 )
   REPLACE FAC_OBR_C->NUM_PRE  WITH PadR( AllTrim( cNumPre ), 10 )
   REPLACE FAC_OBR_C->ID_OBRA  WITH PadR( AllTrim( cIdObra ), 12 )
   REPLACE FAC_OBR_C->TIPO_FAC WITH cTipoFac

   DbCommit()
   DbUnlock()
   FAC_OBR_C->( DbCloseArea() )
   Select( nArea )

RETURN .T.


// ============================================================================
// _ObraCrearFacturaLin()
// ============================================================================
STATIC FUNCTION _ObraCrearFacturaLin( cSerie, cNumFac, cConcepto, nBase, nPorcIva )

   LOCAL nArea := Select()

   IF !ABRIR_TABLA( "FACTUR_DE", "FAD_OBR", "FAC_LIN" )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbSelectArea( "FAD_OBR" )
   IF !NetFLock()
      FAD_OBR->( DbCloseArea() )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbAppend()
   REPLACE FAD_OBR->SERIE    WITH PadR( cSerie, 4 )
   REPLACE FAD_OBR->NUMERO   WITH PadR( cNumFac, 10 )
   REPLACE FAD_OBR->LINEA    WITH 1
   REPLACE FAD_OBR->ARTICULO WITH Space( 10 )
   REPLACE FAD_OBR->DESCRIPC WITH PadR( AllTrim( cConcepto ), 60 )
   REPLACE FAD_OBR->CANTIDAD WITH 1
   REPLACE FAD_OBR->PRECIO   WITH nBase
   REPLACE FAD_OBR->DESCUENT WITH 0.00
   REPLACE FAD_OBR->IMPORTE  WITH nBase
   REPLACE FAD_OBR->COSTO    WITH 0.00
   REPLACE FAD_OBR->CTA_CONT WITH "705"
   REPLACE FAD_OBR->TIP_IVA  WITH If( nPorcIva == 0, "E", "G" )
   REPLACE FAD_OBR->PORC_IVA WITH nPorcIva

   DbCommit()
   DbUnlock()
   FAD_OBR->( DbCloseArea() )
   Select( nArea )

RETURN .T.


// ============================================================================
// _ObraGenVencimiento()
// ============================================================================
STATIC FUNCTION _ObraGenVencimiento( cSerie, cNumFac, cCliente, dVto, nTotal, cIdObra )

   LOCAL cNombre := ""
   LOCAL nArea   := Select()

   IF ABRIR_TABLA( "CLIENTES", "CLI_VOB", "CLI_ID" )
      DbSelectArea( "CLI_VOB" )
      OrdSetFocus( "CLI_ID" )
      IF DbSeek( PadR( cCliente, 10 ) ) .OR. DbSeek( cCliente )
         cNombre := AllTrim( CLI_VOB->NOMBRE + " " + CLI_VOB->APELLIDO )
      ENDIF
      CLI_VOB->( DbCloseArea() )
   ENDIF

   IF !ABRIR_TABLA( "VENCIMIEN", "VEN_OBR_A", "VEN_NUM" )
      Select( nArea )
      RETURN NIL
   ENDIF

   DbSelectArea( "VEN_OBR_A" )
   IF NetFLock()
      DbAppend()
      REPLACE VEN_OBR_A->EJERCICIO WITH Year( dVto )
      REPLACE VEN_OBR_A->TIPO      WITH "C"
      REPLACE VEN_OBR_A->NUMERO    WITH PadR( cNumFac, 10 )
      REPLACE VEN_OBR_A->SERIE     WITH PadR( cSerie, 4 )
      REPLACE VEN_OBR_A->VENCTO    WITH dVto
      REPLACE VEN_OBR_A->IMPORTE   WITH nTotal
      REPLACE VEN_OBR_A->COBRADO   WITH .F.
      REPLACE VEN_OBR_A->CODTERCE  WITH PadR( AllTrim( cCliente ), 10 )
      REPLACE VEN_OBR_A->NOMBRE    WITH PadR( cNombre, 60 )
      REPLACE VEN_OBR_A->ID_OBRA   WITH PadR( AllTrim( cIdObra ), 12 )
      DbCommit()
      DbUnlock()
   ENDIF

   VEN_OBR_A->( DbCloseArea() )
   Select( nArea )

RETURN NIL


// ============================================================================
// _ObraCambiarEstado()
// ============================================================================
STATIC FUNCTION _ObraCambiarEstado( cIdObra, cEstado )

   LOCAL lOk   := .F.
   LOCAL nArea := Select()

   IF !ABRIR_TABLA( "OBRAS", "OBR_EST", "OBR_ID" )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbSelectArea( "OBR_EST" )
   OrdSetFocus( "OBR_ID" )

   IF DbSeek( PadR( cIdObra, 12 ) ) .OR. DbSeek( cIdObra )
      IF NetRLock()
         REPLACE OBR_EST->ESTADO WITH cEstado
         DbCommit()
         DbUnlock()
         lOk := .T.
         AuditLog( "ESTADO", "OBRAS", AllTrim( cIdObra ), ;
                   "Cambio de estado a " + cEstado, .T. )
      ENDIF
   ENDIF

   OBR_EST->( DbCloseArea() )
   Select( nArea )

RETURN lOk


// ============================================================================
// _ObraActualizarEstado()
// Si queda pendiente cero, marca finalizada. Si no, en curso.
// ============================================================================
STATIC FUNCTION _ObraActualizarEstado( cIdObra )

   LOCAL nPendiente := GetPendienteObra( cIdObra )
   LOCAL cEstado    := If( nPendiente <= 0.01, "F", "E" )

RETURN _ObraCambiarEstado( cIdObra, cEstado )


// ============================================================================
// _ObraConceptoFactura()
// ============================================================================
STATIC FUNCTION _ObraConceptoFactura( cTipoFac, cIdObra, cDescObra )

   LOCAL cTipo := "Certificacion de obra"

   DO CASE
   CASE cTipoFac == "A"
      cTipo := "Anticipo de obra"
   CASE cTipoFac == "C"
      cTipo := "Certificacion de obra"
   CASE cTipoFac == "F"
      cTipo := "Factura final de obra"
   CASE cTipoFac == "R"
      cTipo := "Regularizacion de obra"
   ENDCASE

RETURN cTipo + " " + AllTrim( cIdObra ) + " - " + AllTrim( cDescObra )


// ============================================================================
// _ObraSiguienteFactura()
// Usa el mismo contador de facturas que V_Facturas.prg.
// ============================================================================
STATIC FUNCTION _ObraSiguienteFactura()

   LOCAL cAnio := AllTrim( Str( Year( Date() ) ) )

RETURN GetNextNum( "FAC" + cAnio, "Facturas " + cAnio )


// ============================================================================
// _ObraSiguiente()
// Genera ID OBR+año+4dig: OBR20260001
// ============================================================================
STATIC FUNCTION _ObraSiguiente()

   LOCAL cId      := ""
   LOCAL cCodDoc  := PadR( "OBR", 3 )
   LOCAL cPrefijo := "OBR" + AllTrim( Str( Year( Date() ) ) )
   LOCAL nUltNum  := 0
   LOCAL cUsuario := "SISTEMA"
   LOCAL nArea    := Select()

   MEMVAR cUserID

   IF Type( "cUserID" ) == "C" .AND. !Empty( cUserID )
      cUsuario := PadR( AllTrim( cUserID ), 10 )
   ENDIF

   IF !ABRIR_TABLA( "CONTADOR", "CON_OBR", "COD_DOC" )
      Select( nArea )
      RETURN ""
   ENDIF

   DbSelectArea( "CON_OBR" )
   OrdSetFocus( "COD_DOC" )

   IF DbSeek( cCodDoc )
      IF !NetRLock()
         CON_OBR->( DbCloseArea() )
         Select( nArea )
         RETURN ""
      ENDIF
      nUltNum := CON_OBR->ULT_NUM
      // Si cambia el año, reinicia la serie anual.
      IF AllTrim( CON_OBR->PREFIJO ) != cPrefijo
         nUltNum := 0
         REPLACE CON_OBR->PREFIJO WITH cPrefijo
         REPLACE CON_OBR->DIGITOS WITH 4
      ENDIF
   ELSE
      IF !NetFLock()
         CON_OBR->( DbCloseArea() )
         Select( nArea )
         RETURN ""
      ENDIF
      DbAppend()
      REPLACE CON_OBR->COD_DOC WITH cCodDoc
      REPLACE CON_OBR->DESCRIP WITH "Obras"
      REPLACE CON_OBR->PREFIJO WITH cPrefijo
      REPLACE CON_OBR->DIGITOS WITH 4
   ENDIF

   nUltNum++
   cId := cPrefijo + StrZero( nUltNum, 4 )

   REPLACE CON_OBR->ULT_NUM WITH nUltNum
   REPLACE CON_OBR->ULT_USR WITH cUsuario
   REPLACE CON_OBR->ULT_FEC WITH Date()
   REPLACE CON_OBR->ULT_HOR WITH Time()

   DbCommit()
   DbUnlock()
   CON_OBR->( DbCloseArea() )
   Select( nArea )

RETURN cId




// ============================================================================
// ObrasView()
// Pantalla principal de obras.
// ============================================================================
FUNCTION ObrasView()

   LOCAL oWin
   LOCAL oGrid
   LOCAL oLbl
   LOCAL oBtMan
   LOCAL oBtPre
   LOCAL oBtAnt
   LOCAL oBtCer
   LOCAL oBtFin
   LOCAL oBtCur
   LOCAL oBtCan
   LOCAL oBtSal
   LOCAL aData

   IF !ABRIR_TABLA( "OBRAS", "OBR", "OBR_ID" )
      RETURN NIL
   ENDIF

   aData := _ObrasCargar()

   oWin  := TWindow():New( 1, 2, 37, 129, "OBRAS - CONTROL ECONOMICO" )
   oGrid := TGrid():New( 2, 2, 28, 124, oWin )

   oGrid:aData    := aData
   oGrid:nSeekCol := 2

   oGrid:AddColumn( "Obra",       12, "@!",         { |a| a[1] } )
   oGrid:AddColumn( "Cliente",    10, "@!",         { |a| a[2] } )
   oGrid:AddColumn( "Descripcion",35, "@!",         { |a| a[3] } )
   oGrid:AddColumn( "Estado",     12, "@!",         { |a| a[4] } )
   oGrid:AddColumn( "Total",      12, "999,999.99", { |a| a[5] } )
   oGrid:AddColumn( "Facturado",  12, "999,999.99", { |a| a[6] } )
   oGrid:AddColumn( "Pendiente",  12, "999,999.99", { |a| a[7] } )
   oGrid:AddColumn( "Presup.",    10, "@!",         { |a| a[8] } )

   oGrid:bEnter := {| g | _ObraEstadoForm( g:CurrentRow()[1] ) }

   oLbl := TLabel():New( 30, 2, ;
      "ENTER: estado economico   Nueva manual / Desde presupuesto / Anticipo / Certificacion / Final", oWin )

   oBtMan := TButton():New( 31,  2, 32, 18, oWin, "NUEVA MAN.", ;
      {|| _ObraManualForm(), ;
          aData := _ObrasCargar(), ;
          oGrid:aData := aData, ;
          oGrid:nCurRow := Len( aData ), ;
          oGrid:Paint() } )

   oBtPre := TButton():New( 31, 20, 32, 39, oWin, "DESDE PRESUP.", ;
      {|| _ObraDesdePreForm(), ;
          aData := _ObrasCargar(), ;
          oGrid:aData := aData, ;
          oGrid:nCurRow := Len( aData ), ;
          oGrid:Paint() } )

   oBtAnt := TButton():New( 31, 41, 32, 56, oWin, "ANTICIPO", ;
      {|| If( oGrid:CurrentRow() != NIL, _ObraFacturaForm( oGrid:CurrentRow()[1], "A" ), NIL ), ;
          aData := _ObrasCargar(), ;
          oGrid:aData := aData, ;
          oGrid:Paint() } )

   oBtCer := TButton():New( 31, 58, 32, 76, oWin, "CERTIFICAR", ;
      {|| If( oGrid:CurrentRow() != NIL, _ObraFacturaForm( oGrid:CurrentRow()[1], "C" ), NIL ), ;
          aData := _ObrasCargar(), ;
          oGrid:aData := aData, ;
          oGrid:Paint() } )

   oBtFin := TButton():New( 31, 78, 32, 93, oWin, "FINAL", ;
      {|| If( oGrid:CurrentRow() != NIL, _ObraFacturaForm( oGrid:CurrentRow()[1], "F" ), NIL ), ;
          aData := _ObrasCargar(), ;
          oGrid:aData := aData, ;
          oGrid:Paint() } )

   oBtCur := TButton():New( 33,  2, 34, 20, oWin, "EN CURSO", ;
      {|| If( oGrid:CurrentRow() != NIL, MarcarObraEnCurso( oGrid:CurrentRow()[1] ), NIL ), ;
          aData := _ObrasCargar(), ;
          oGrid:aData := aData, ;
          oGrid:Paint() } )

   oBtCan := TButton():New( 33, 22, 34, 40, oWin, "CANCELAR", ;
      {|| If( oGrid:CurrentRow() != NIL .AND. MsgYesNo( "Cancelar la obra seleccionada?", "Obras" ), ;
               CancelarObra( oGrid:CurrentRow()[1] ), NIL ), ;
          aData := _ObrasCargar(), ;
          oGrid:aData := aData, ;
          oGrid:Paint() } )

   oBtSal := TButton():New( 33,108, 34,124, oWin, "CERRAR", ;
      {|| oWin:Close() } )

   oWin:AddCtrl( oGrid  )
   oWin:AddCtrl( oLbl   )
   oWin:AddCtrl( oBtMan )
   oWin:AddCtrl( oBtPre )
   oWin:AddCtrl( oBtAnt )
   oWin:AddCtrl( oBtCer )
   oWin:AddCtrl( oBtFin )
   oWin:AddCtrl( oBtCur )
   oWin:AddCtrl( oBtCan )
   oWin:AddCtrl( oBtSal )

   oWin:Run()

   OBR->( DbCloseArea() )

RETURN NIL


// ============================================================================
// _ObrasCargar()
// ============================================================================
STATIC FUNCTION _ObrasCargar()

   LOCAL aData := {}
   LOCAL aRes

   DbSelectArea( "OBR" )
   OrdSetFocus( "OBR_ID" )
   DbGoTop()

   DO WHILE !Eof()
      IF !Deleted()
         aRes := GetResumenObra( AllTrim( OBR->ID ) )
         DbSelectArea( "OBR" )
         AAdd( aData, { ;
            AllTrim( OBR->ID       ), ;
            AllTrim( OBR->CLIENTE_ ), ;
            AllTrim( OBR->DESCRIP  ), ;
            _ObraEstadoTexto( DbFieldValue( "ESTADO", "" ) ), ;
            aRes[1], ;
            aRes[2], ;
            aRes[3], ;
            AllTrim( DbFieldValue( "NUM_PRE", "" ) ) } )
      ENDIF
      OBR->( DbSkip() )
   ENDDO

RETURN aData


// ============================================================================
// _ObraManualForm()
// ============================================================================
STATIC FUNCTION _ObraManualForm()

   LOCAL oWin
   LOCAL cCliente := Space( 10 )
   LOCAL cDesc    := Space( 80 )
   LOCAL cDir     := Space( 80 )
   LOCAL cFecIn   := DToC( Date() )
   LOCAL cFecFin  := Space( 10 )
   LOCAL nTotal   := 0.00
   LOCAL oGCli
   LOCAL oGDes
   LOCAL oGDir
   LOCAL oGFI
   LOCAL oGFF
   LOCAL oGTot
   LOCAL oBtGua
   LOCAL oBtCan

   oWin := TWindow():New( 5, 10, 26, 118, "NUEVA OBRA MANUAL" )

   oWin:AddCtrl( TLabel():New(  2,  2, "Cliente       :", oWin ) )
   oWin:AddCtrl( TLabel():New(  4,  2, "Descripcion   :", oWin ) )
   oWin:AddCtrl( TLabel():New(  6,  2, "Direccion obra:", oWin ) )
   oWin:AddCtrl( TLabel():New(  8,  2, "Fecha inicio  :", oWin ) )
   oWin:AddCtrl( TLabel():New( 10,  2, "Fecha fin prev:", oWin ) )
   oWin:AddCtrl( TLabel():New( 12,  2, "Total obra    :", oWin ) )

   oGCli := TGet():New(  2, 20, cCliente, "@!",          oWin )
   oGDes := TGet():New(  4, 20, cDesc,    "@!",          oWin )
   oGDir := TGet():New(  6, 20, cDir,     "@!",          oWin )
   oGFI  := TGet():New(  8, 20, cFecIn,   "@!",          oWin )
   oGFF  := TGet():New( 10, 20, cFecFin,  "@!",          oWin )
   oGTot := TGet():New( 12, 20, nTotal,   "999,999.99",  oWin )

   oBtGua := TButton():New( 17, 34, 18, 53, oWin, "GUARDAR", ;
      {|| _ObraManualGuardar( oGCli, oGDes, oGDir, oGFI, oGFF, oGTot, oWin ) } )

   oBtCan := TButton():New( 17, 57, 18, 76, oWin, "CANCELAR", ;
      {|| oWin:Close() } )

   oWin:AddCtrl( oGCli )
   oWin:AddCtrl( oGDes )
   oWin:AddCtrl( oGDir )
   oWin:AddCtrl( oGFI  )
   oWin:AddCtrl( oGFF  )
   oWin:AddCtrl( oGTot )
   oWin:AddCtrl( oBtGua )
   oWin:AddCtrl( oBtCan )

   oWin:Run()

RETURN NIL


STATIC FUNCTION _ObraManualGuardar( oGCli, oGDes, oGDir, oGFI, oGFF, oGTot, oWin )

   LOCAL cId
   LOCAL dFecIn  := CToD( AllTrim( oGFI:uVar ) )
   LOCAL dFecFin := CToD( AllTrim( oGFF:uVar ) )

   IF Empty( dFecIn )
      dFecIn := Date()
   ENDIF

   cId := CrearObraManual( AllTrim( oGCli:uVar ), ;
                            AllTrim( oGDes:uVar ), ;
                            AllTrim( oGDir:uVar ), ;
                            oGTot:uVar, dFecIn, dFecFin )

   IF !Empty( cId )
      MsgInfo( "Obra creada: " + cId, "Obras" )
      oWin:Close()
   ENDIF

RETURN NIL


// ============================================================================
// _ObraDesdePreForm()
// ============================================================================
STATIC FUNCTION _ObraDesdePreForm()

   LOCAL oWin
   LOCAL cNumPre := Space( 10 )
   LOCAL cDesc   := Space( 80 )
   LOCAL cDir    := Space( 80 )
   LOCAL cFecIn  := DToC( Date() )
   LOCAL cFecFin := Space( 10 )
   LOCAL oGPre
   LOCAL oGDes
   LOCAL oGDir
   LOCAL oGFI
   LOCAL oGFF
   LOCAL oBtGua
   LOCAL oBtCan

   oWin := TWindow():New( 5, 10, 25, 118, "CREAR OBRA DESDE PRESUPUESTO" )

   oWin:AddCtrl( TLabel():New(  2,  2, "Presupuesto   :", oWin ) )
   oWin:AddCtrl( TLabel():New(  4,  2, "Descripcion   :", oWin ) )
   oWin:AddCtrl( TLabel():New(  6,  2, "Direccion obra:", oWin ) )
   oWin:AddCtrl( TLabel():New(  8,  2, "Fecha inicio  :", oWin ) )
   oWin:AddCtrl( TLabel():New( 10,  2, "Fecha fin prev:", oWin ) )
   oWin:AddCtrl( TLabel():New( 13,  2, "Nota: el presupuesto debe estar aceptado (ESTADO=A).", oWin ) )

   oGPre := TGet():New(  2, 20, cNumPre, "@!", oWin )
   oGDes := TGet():New(  4, 20, cDesc,   "@!", oWin )
   oGDir := TGet():New(  6, 20, cDir,    "@!", oWin )
   oGFI  := TGet():New(  8, 20, cFecIn,  "@!", oWin )
   oGFF  := TGet():New( 10, 20, cFecFin, "@!", oWin )

   oBtGua := TButton():New( 16, 34, 17, 53, oWin, "CREAR", ;
      {|| _ObraDesdePreGuardar( oGPre, oGDes, oGDir, oGFI, oGFF, oWin ) } )

   oBtCan := TButton():New( 16, 57, 17, 76, oWin, "CANCELAR", ;
      {|| oWin:Close() } )

   oWin:AddCtrl( oGPre )
   oWin:AddCtrl( oGDes )
   oWin:AddCtrl( oGDir )
   oWin:AddCtrl( oGFI  )
   oWin:AddCtrl( oGFF  )
   oWin:AddCtrl( oBtGua )
   oWin:AddCtrl( oBtCan )

   oWin:Run()

RETURN NIL


STATIC FUNCTION _ObraDesdePreGuardar( oGPre, oGDes, oGDir, oGFI, oGFF, oWin )

   LOCAL cId
   LOCAL dFecIn  := CToD( AllTrim( oGFI:uVar ) )
   LOCAL dFecFin := CToD( AllTrim( oGFF:uVar ) )

   IF Empty( dFecIn )
      dFecIn := Date()
   ENDIF

   cId := CrearObraDesdePresupuesto( AllTrim( oGPre:uVar ), ;
                                      AllTrim( oGDes:uVar ), ;
                                      AllTrim( oGDir:uVar ), ;
                                      dFecIn, dFecFin )

   IF !Empty( cId )
      MsgInfo( "Obra creada: " + cId, "Obras" )
      oWin:Close()
   ENDIF

RETURN NIL


// ============================================================================
// _ObraFacturaForm()
// ============================================================================
STATIC FUNCTION _ObraFacturaForm( cIdObra, cTipoFac )

   LOCAL oWin
   LOCAL aRes      := GetResumenObra( cIdObra )
   LOCAL nImporte  := If( cTipoFac == "F", aRes[3], 0.00 )
   LOCAL nIva      := 21.00
   LOCAL cConcepto := PadR( _ObraTituloTipo( cTipoFac ) + " " + AllTrim( cIdObra ), 80 )
   LOCAL oGImp
   LOCAL oGIva
   LOCAL oGCon
   LOCAL oBtGua
   LOCAL oBtCan

   oWin := TWindow():New( 6, 12, 27, 118, _ObraTituloTipo( cTipoFac ) )

   oWin:AddCtrl( TLabel():New(  2,  2, "Obra          : " + AllTrim( cIdObra ), oWin ) )
   oWin:AddCtrl( TLabel():New(  4,  2, "Total obra    : " + Transform( aRes[1], "999,999,999.99" ), oWin ) )
   oWin:AddCtrl( TLabel():New(  5,  2, "Facturado     : " + Transform( aRes[2], "999,999,999.99" ), oWin ) )
   oWin:AddCtrl( TLabel():New(  6,  2, "Pendiente     : " + Transform( aRes[3], "999,999,999.99" ), oWin ) )
   oWin:AddCtrl( TLabel():New(  9,  2, "Importe TOTAL :", oWin ) )
   oWin:AddCtrl( TLabel():New( 11,  2, "IVA %         :", oWin ) )
   oWin:AddCtrl( TLabel():New( 13,  2, "Concepto      :", oWin ) )
   oWin:AddCtrl( TLabel():New( 16,  2, "Nota: el importe es total factura. Para ISP use IVA 0.", oWin ) )

   oGImp := TGet():New(  9, 20, nImporte,  "999,999.99", oWin )
   oGIva := TGet():New( 11, 20, nIva,      "99.99",      oWin )
   oGCon := TGet():New( 13, 20, cConcepto, "@!",         oWin )

   oBtGua := TButton():New( 18, 34, 19, 53, oWin, "EMITIR", ;
      {|| _ObraFacturaGuardar( cIdObra, cTipoFac, oGImp, oGIva, oGCon, oWin ) } )

   oBtCan := TButton():New( 18, 57, 19, 76, oWin, "CANCELAR", ;
      {|| oWin:Close() } )

   oWin:AddCtrl( oGImp )
   oWin:AddCtrl( oGIva )
   oWin:AddCtrl( oGCon )
   oWin:AddCtrl( oBtGua )
   oWin:AddCtrl( oBtCan )

   oWin:Run()

RETURN NIL


STATIC FUNCTION _ObraFacturaGuardar( cIdObra, cTipoFac, oGImp, oGIva, oGCon, oWin )

   LOCAL cFactura

   IF !MsgYesNo( "Emitir factura de obra?", "Obras" )
      RETURN NIL
   ENDIF

   cFactura := FacturarObra( cIdObra, oGImp:uVar, cTipoFac, oGIva:uVar, ;
                              AllTrim( oGCon:uVar ), Date() )

   IF !Empty( cFactura )
      MsgInfo( "Factura emitida: " + cFactura, "Obras" )
      oWin:Close()
   ENDIF

RETURN NIL


// ============================================================================
// _ObraEstadoForm()
// ============================================================================
STATIC FUNCTION _ObraEstadoForm( cIdObra )

   LOCAL oWin
   LOCAL oGrid
   LOCAL oBtSal
   LOCAL aRes := GetResumenObra( cIdObra )
   LOCAL aMov := _ObraMovCobros( cIdObra )

   oWin  := TWindow():New( 3, 6, 35, 126, "ESTADO ECONOMICO DE OBRA" )
   oGrid := TGrid():New( 8, 2, 28, 116, oWin )

   oWin:AddCtrl( TLabel():New(  2,  2, "Obra       : " + AllTrim( cIdObra ), oWin ) )
   oWin:AddCtrl( TLabel():New(  3,  2, "Total obra : " + Transform( aRes[1], "999,999,999.99" ), oWin ) )
   oWin:AddCtrl( TLabel():New(  4,  2, "Facturado  : " + Transform( aRes[2], "999,999,999.99" ), oWin ) )
   oWin:AddCtrl( TLabel():New(  5,  2, "Pendiente  : " + Transform( aRes[3], "999,999,999.99" ), oWin ) )
   oWin:AddCtrl( TLabel():New(  6,  2, "Estado     : " + _ObraEstadoTexto( aRes[4] ), oWin ) )
   oWin:AddCtrl( TLabel():New( 30,  2, "ENTER: detalle del movimiento   ESC/CERRAR: volver a obras", oWin ) )

   oGrid:aData    := aMov
   oGrid:nSeekCol := 3
   oGrid:AddColumn( "Tipo",      8, "@!",         { |a| a[1] } )
   oGrid:AddColumn( "Fecha",    10, "@!",         { |a| a[2] } )
   oGrid:AddColumn( "Documento",14, "@!",         { |a| a[3] } )
   oGrid:AddColumn( "Factura",  10, "@!",         { |a| a[4] } )
   oGrid:AddColumn( "Importe",  12, "999,999.99", { |a| a[5] } )
   oGrid:AddColumn( "Estado",   12, "@!",         { |a| a[6] } )
   oGrid:AddColumn( "Forma",     9, "@!",         { |a| a[7] } )
   oGrid:AddColumn( "Tercero",  28, "@!",         { |a| a[8] } )

   oGrid:bEnter := {| g | ;
      If( g:CurrentRow() != NIL, ;
          MsgInfo( "Tipo     : " + g:CurrentRow()[1] + Chr(13) + ;
                   "Fecha    : " + g:CurrentRow()[2] + Chr(13) + ;
                   "Documento: " + g:CurrentRow()[3] + Chr(13) + ;
                   "Factura  : " + g:CurrentRow()[4] + Chr(13) + ;
                   "Importe  : " + Transform( g:CurrentRow()[5], "999,999,999.99" ) + Chr(13) + ;
                   "Estado   : " + g:CurrentRow()[6] + Chr(13) + ;
                   "Forma    : " + g:CurrentRow()[7] + Chr(13) + ;
                   "Tercero  : " + g:CurrentRow()[8], ;
                   "Movimiento de cobro" ), NIL ) }

   oBtSal := TButton():New( 31, 98, 32, 116, oWin, "CERRAR", ;
      {|| oWin:Close() } )

   oWin:AddCtrl( oGrid  )
   oWin:AddCtrl( oBtSal )

   oWin:Run()

RETURN NIL


STATIC FUNCTION _ObraMovCobros( cIdObra )

   LOCAL aMov  := {}
   LOCAL aFacs := _ObraFacturas( cIdObra )

   _ObraMovVencimientos( cIdObra, @aMov )
   _ObraMovRecibos( aFacs, @aMov )

   IF Empty( aMov )
      AAdd( aMov, { "INFO", "", "Sin movimientos", "", 0.00, "", "", "" } )
   ENDIF

RETURN aMov


STATIC FUNCTION _ObraMovVencimientos( cIdObra, aMov )

   LOCAL nArea   := Select()
   LOCAL cEstado
   LOCAL cTercero

   IF !ABRIR_TABLA( "VENCIMIEN", "VEN_OM", "VEN_OBR" )
      Select( nArea )
      RETURN NIL
   ENDIF

   DbSelectArea( "VEN_OM" )
   DbGoTop()

   DO WHILE !Eof()
      IF !Deleted() .AND. ;
         AllTrim( DbFieldValue( "ID_OBRA", "" ) ) == AllTrim( cIdObra ) .AND. ;
         AllTrim( DbFieldValue( "TIPO", "" ) ) == "C"

         cEstado  := If( DbFieldValue( "COBRADO", .F. ), "COBRADO", "PENDIENTE" )
         cTercero := AllTrim( DbFieldValue( "NOMBRE", "" ) )
         IF Empty( cTercero )
            cTercero := AllTrim( DbFieldValue( "CODTERCE", "" ) )
         ENDIF

         AAdd( aMov, { ;
            "VTO", ;
            _ObraFechaTexto( DbFieldValue( "VENCTO", CToD( "" ) ) ), ;
            AllTrim( DbFieldValue( "NUMERO", "" ) ), ;
            AllTrim( DbFieldValue( "NUMERO", "" ) ), ;
            DbFieldValue( "IMPORTE", 0.00 ), ;
            cEstado, ;
            "", ;
            cTercero } )
      ENDIF
      VEN_OM->( DbSkip() )
   ENDDO

   VEN_OM->( DbCloseArea() )
   Select( nArea )

RETURN NIL


STATIC FUNCTION _ObraMovRecibos( aFacs, aMov )

   LOCAL nArea := Select()
   LOCAL cFac
   LOCAL cFecha
   LOCAL cForma
   LOCAL cTercero

   IF Empty( aFacs )
      Select( nArea )
      RETURN NIL
   ENDIF

   IF !ABRIR_TABLA( "RC_DETAL", "RCD_OM", "RCD_FAC" )
      Select( nArea )
      RETURN NIL
   ENDIF

   DbSelectArea( "RCD_OM" )
   DbGoTop()

   DO WHILE !Eof()
      IF !Deleted()
         cFac := AllTrim( DbFieldValue( "NUM_FAC", "" ) )
         IF AScan( aFacs, {| c | c == cFac } ) > 0
            cFecha   := ""
            cForma   := ""
            cTercero := ""
            _ObraReciboDatos( AllTrim( DbFieldValue( "NUMERO", "" ) ), ;
                              @cFecha, @cForma, @cTercero )

            AAdd( aMov, { ;
               "COBRO", ;
               cFecha, ;
               AllTrim( DbFieldValue( "NUMERO", "" ) ), ;
               cFac, ;
               DbFieldValue( "IMPORTE", 0.00 ), ;
               "COBRADO", ;
               cForma, ;
               cTercero } )
         ENDIF
      ENDIF
      RCD_OM->( DbSkip() )
   ENDDO

   RCD_OM->( DbCloseArea() )
   Select( nArea )

RETURN NIL


STATIC FUNCTION _ObraFacturas( cIdObra )

   LOCAL nArea := Select()
   LOCAL aFacs := {}
   LOCAL cNum

   IF !ABRIR_TABLA( "FACTURA", "FAC_OM", "FAC_OBR" )
      Select( nArea )
      RETURN aFacs
   ENDIF

   DbSelectArea( "FAC_OM" )
   DbGoTop()

   DO WHILE !Eof()
      IF !Deleted() .AND. ;
         AllTrim( DbFieldValue( "ID_OBRA", "" ) ) == AllTrim( cIdObra ) .AND. ;
         !DbFieldValue( "ANULADA", .F. )

         cNum := AllTrim( DbFieldValue( "NUMERO", "" ) )
         IF !Empty( cNum ) .AND. AScan( aFacs, {| c | c == cNum } ) == 0
            AAdd( aFacs, cNum )
         ENDIF
      ENDIF
      FAC_OM->( DbSkip() )
   ENDDO

   FAC_OM->( DbCloseArea() )
   Select( nArea )

RETURN aFacs


STATIC FUNCTION _ObraReciboDatos( cNumRec, cFecha, cForma, cTercero )

   LOCAL nArea := Select()

   IF !ABRIR_TABLA( "RECIBOS", "REC_OM", "REC_NUM" )
      Select( nArea )
      RETURN .F.
   ENDIF

   DbSelectArea( "REC_OM" )
   OrdSetFocus( "REC_NUM" )

   IF DbSeek( PadR( cNumRec, 10 ) ) .OR. DbSeek( cNumRec )
      cFecha   := _ObraFechaTexto( DbFieldValue( "FECHA", CToD( "" ) ) )
      cForma   := _ObraFormaTexto( DbFieldValue( "FORMA_PA", "" ) )
      cTercero := _ObraClienteNombre( DbFieldValue( "CLIENTE_", "" ) )
   ENDIF

   REC_OM->( DbCloseArea() )
   Select( nArea )

RETURN .T.


STATIC FUNCTION _ObraClienteNombre( cCliente )

   LOCAL nArea := Select()
   LOCAL cNom  := AllTrim( cCliente )

   IF ABRIR_TABLA( "CLIENTES", "CLI_OM", "CLI_ID" )
      DbSelectArea( "CLI_OM" )
      IF DbSeek( PadR( cCliente, 10 ) ) .OR. DbSeek( cCliente )
         cNom := AllTrim( CLI_OM->NOMBRE + " " + CLI_OM->APELLIDO )
      ENDIF
      CLI_OM->( DbCloseArea() )
   ENDIF

   Select( nArea )

RETURN cNom


STATIC FUNCTION _ObraFechaTexto( dFecha )

   IF ValType( dFecha ) == "D" .AND. !Empty( dFecha )
      RETURN DToC( dFecha )
   ENDIF

RETURN ""


STATIC FUNCTION _ObraFormaTexto( cForma )

   cForma := Upper( AllTrim( cForma ) )

   DO CASE
   CASE cForma == "EFE"
      RETURN "Efectivo"
   CASE cForma == "TRF"
      RETURN "Transf."
   CASE cForma == "TAR"
      RETURN "Tarjeta"
   CASE cForma == "CHQ"
      RETURN "Cheque"
   CASE cForma == "OTR"
      RETURN "Otro"
   ENDCASE

RETURN cForma


STATIC FUNCTION _ObraEstadoTexto( cEstado )

   LOCAL cTexto := ""

   DO CASE
   CASE cEstado == "A"
      cTexto := "Abierta"
   CASE cEstado == "E"
      cTexto := "En curso"
   CASE cEstado == "F"
      cTexto := "Finalizada"
   CASE cEstado == "C"
      cTexto := "Cancelada"
   OTHERWISE
      cTexto := "Sin estado"
   ENDCASE

RETURN cTexto


STATIC FUNCTION _ObraTituloTipo( cTipoFac )

   LOCAL cTitulo := "CERTIFICACION"

   DO CASE
   CASE cTipoFac == "A"
      cTitulo := "ANTICIPO DE OBRA"
   CASE cTipoFac == "C"
      cTitulo := "CERTIFICACION DE OBRA"
   CASE cTipoFac == "F"
      cTitulo := "FACTURA FINAL DE OBRA"
   CASE cTipoFac == "R"
      cTitulo := "REGULARIZACION DE OBRA"
   ENDCASE

RETURN cTitulo


// ============================================================================
// FIN DE M_Obras.prg
// ============================================================================
