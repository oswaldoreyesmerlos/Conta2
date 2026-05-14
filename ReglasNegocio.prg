/*
 * ARCHIVO  : ReglasNegocio.prg
 * PROPOSITO: Validaciones centrales del modelo de negocio.
 *
 * Este modulo NO sustituye el criterio de un gestor fiscal/contable.
 * Su objetivo es evitar incoherencias internas del sistema:
 * - cobrar mas que el pendiente de una factura
 * - facturar mas que el total pendiente de una obra
 * - crear obras duplicadas desde un mismo presupuesto
 * - cerrar/anular documentos en estados peligrosos
 */

#include "OOp.ch"

// ============================================================================
// ValidarCobroFactura()
// Evita cobrar mas que el pendiente de una factura.
// ============================================================================
FUNCTION ValidarCobroFactura( cSerie, cNumero, nImporte )

   LOCAL nTotal
   LOCAL nCobrado
   LOCAL nPendiente

   DEFAULT cSerie TO "A"

   nTotal     := GetTotalFactura( cSerie, cNumero )
   nCobrado   := GetCobradoFactura( cSerie, cNumero )
   nPendiente := nTotal - nCobrado

   IF Empty( cNumero )
      MsgStop( "Debe indicar una factura.", "Validacion" )
      RETURN .F.
   ENDIF

   IF nTotal <= 0
      MsgStop( "La factura no existe o su total no es valido.", "Validacion" )
      RETURN .F.
   ENDIF

   IF nImporte <= 0
      MsgStop( "El importe del cobro debe ser mayor que cero.", "Validacion" )
      RETURN .F.
   ENDIF

   IF nImporte > nPendiente
      MsgStop( "El cobro supera el importe pendiente de la factura.", "Validacion" )
      RETURN .F.
   ENDIF

RETURN .T.


// ============================================================================
// ValidarFacturaObra()
// Evita facturar mas que el pendiente total de una obra.
// Los anticipos se permiten sin controlar pendiente porque pueden emitirse
// antes de certificar ejecucion.
// ============================================================================
FUNCTION ValidarFacturaObra( cIdObra, nImporte, cTipoFac )

   LOCAL nTotal
   LOCAL nFacturado
   LOCAL nPendiente
   LOCAL cTipo

   DEFAULT cTipoFac TO "C"

   cTipo := Upper( AllTrim( cTipoFac ) )

   IF Empty( cIdObra )
      MsgStop( "Debe indicar una obra.", "Validacion" )
      RETURN .F.
   ENDIF

   IF !ObraExiste( cIdObra )
      MsgStop( "La obra indicada no existe.", "Validacion" )
      RETURN .F.
   ENDIF

   nTotal     := GetTotalObra( cIdObra )
   nFacturado := GetFacturadoObra( cIdObra )
   nPendiente := nTotal - nFacturado

   IF !( cTipo $ "ACFR" )
      MsgStop( "Tipo de facturacion de obra no valido.", "Validacion" )
      RETURN .F.
   ENDIF

   IF nImporte <= 0
      MsgStop( "El importe a facturar debe ser mayor que cero.", "Validacion" )
      RETURN .F.
   ENDIF

   IF cTipo == "A"
      RETURN .T.
   ENDIF

   IF nTotal <= 0
      MsgStop( "La obra no tiene total presupuestado para certificar.", "Validacion" )
      RETURN .F.
   ENDIF

   IF nPendiente <= 0.01
      MsgStop( "La obra no tiene pendiente de facturar.", "Validacion" )
      RETURN .F.
   ENDIF

   IF nImporte > nPendiente
      MsgStop( "No se puede facturar mas del pendiente de la obra.", "Validacion" )
      RETURN .F.
   ENDIF

RETURN .T.


// ============================================================================
// ValidarCrearObraDesdePresupuesto()
// Evita crear obras duplicadas o desde presupuestos no aceptados.
// Estados previstos de PRESUPUEST->ESTADO:
//   P=Pendiente/Borrador, A=Aceptado, R=Rechazado
// ============================================================================
FUNCTION ValidarCrearObraDesdePresupuesto( cNumPre )

   IF Empty( cNumPre )
      MsgStop( "Debe indicar un presupuesto.", "Validacion" )
      RETURN .F.
   ENDIF

   IF PresupuestoTieneObra( cNumPre )
      MsgStop( "Este presupuesto ya tiene una obra asociada.", "Validacion" )
      RETURN .F.
   ENDIF

   IF !PresupuestoAceptado( cNumPre )
      MsgStop( "Solo se puede crear obra desde un presupuesto aceptado.", ;
               "Validacion" )
      RETURN .F.
   ENDIF

RETURN .T.


// ============================================================================
// ValidarCerrarObra()
// Regla prudente: no cerrar obra con importe pendiente de facturar.
// ============================================================================
FUNCTION ValidarCerrarObra( cIdObra )

   LOCAL nPendiente

   IF Empty( cIdObra )
      MsgStop( "Debe indicar una obra.", "Validacion" )
      RETURN .F.
   ENDIF

   nPendiente := GetPendienteObra( cIdObra )

   IF nPendiente > 0.01
      MsgStop( "No se puede cerrar la obra: queda importe pendiente de facturar.", ;
               "Validacion" )
      RETURN .F.
   ENDIF

RETURN .T.


// ============================================================================
// ValidarAnularFactura()
// Regla prudente: no anular directamente facturas cobradas.
// ============================================================================
FUNCTION ValidarAnularFactura( cSerie, cNumero )

   DEFAULT cSerie TO "A"

   IF Empty( cNumero )
      MsgStop( "Debe indicar una factura.", "Validacion" )
      RETURN .F.
   ENDIF

   IF FacturaCobrada( cSerie, cNumero )
      MsgStop( "No se puede anular directamente una factura cobrada." + Chr(13) + ;
               "Use un proceso controlado de rectificacion.", "Validacion" )
      RETURN .F.
   ENDIF

RETURN .T.


// ============================================================================
// FacturaContabilizada()
// Una factura con asiento informado queda congelada: no se modifica.
// ============================================================================
FUNCTION FacturaContabilizada( cSerie, cNumero )

   LOCAL lContab := .F.

   DEFAULT cSerie TO "A"

   IF Empty( cNumero )
      RETURN .F.
   ENDIF

   IF !ABRIR_TABLA( "FACTURA", "FAC_BLQ", "FAC_NUM" )
      RETURN .F.
   ENDIF

   DbSelectArea( "FAC_BLQ" )
   OrdSetFocus( "FAC_NUM" )

   IF DbSeek( PadR( cSerie, 4 ) + PadR( cNumero, 10 ) ) .OR. ;
      DbSeek( cSerie + cNumero )
      lContab := !Empty( AllTrim( DbFieldValue( "ASIENTO", "" ) ) )
   ENDIF

   FAC_BLQ->( DbCloseArea() )

RETURN lContab


// ============================================================================
// ValidarFacturaNoContabilizada()
// Bloquea cualquier modificacion directa de facturas ya contabilizadas.
// ============================================================================
FUNCTION ValidarFacturaNoContabilizada( cSerie, cNumero, cAccion )

   LOCAL cAcc

   DEFAULT cSerie TO "A"
   DEFAULT cAccion TO "modificar"

   cAcc := Lower( AllTrim( cAccion ) )

   IF FacturaContabilizada( cSerie, cNumero )
      MsgStop( "No se puede " + cAcc + " la factura " + ;
               AllTrim( cNumero ) + " porque ya esta contabilizada." + Chr(13) + ;
               "Debe usar un documento corrector o un asiento nuevo.", ;
               "Documento contabilizado" )
      RETURN .F.
   ENDIF

RETURN .T.


// ============================================================================
// CompraContabilizada()
// Una compra con asiento informado queda congelada: no se modifica.
// ============================================================================
FUNCTION CompraContabilizada( cNumero )

   LOCAL lContab := .F.

   IF Empty( cNumero )
      RETURN .F.
   ENDIF

   IF !ABRIR_TABLA( "COMPRAS", "COM_BLQ", "COM_INT" )
      RETURN .F.
   ENDIF

   DbSelectArea( "COM_BLQ" )
   OrdSetFocus( "COM_INT" )

   IF DbSeek( cNumero )
      lContab := !Empty( AllTrim( DbFieldValue( "ASIENTO", "" ) ) )
   ENDIF

   COM_BLQ->( DbCloseArea() )

RETURN lContab


// ============================================================================
// FacturaTieneAbono()
// Detecta abonos por marca en FACTURA o por documento NOTASDC vinculado.
// ============================================================================
FUNCTION FacturaTieneAbono( cSerie, cNumero )

   LOCAL lTiene := .F.

   DEFAULT cSerie TO "A"

   IF Empty( cNumero )
      RETURN .F.
   ENDIF

   IF ABRIR_TABLA( "FACTURA", "FAC_ABO", "FAC_NUM" )
      DbSelectArea( "FAC_ABO" )
      OrdSetFocus( "FAC_NUM" )
      IF DbSeek( PadR( cSerie, 4 ) + PadR( cNumero, 10 ) ) .OR. ;
         DbSeek( cSerie + cNumero )
         lTiene := !Empty( AllTrim( DbFieldValue( "NUM_ABONO", "" ) ) )
      ENDIF
      FAC_ABO->( DbCloseArea() )
   ENDIF

   IF !lTiene .AND. ABRIR_TABLA( "NOTASDC", "NDC_ABO", "NDC_NUM" )
      DbSelectArea( "NDC_ABO" )
      DbGoTop()
      DO WHILE !Eof()
         IF !Deleted() .AND. AllTrim( DbFieldValue( "REF_DOC", "" ) ) == AllTrim( cNumero ) .AND. ;
            AllTrim( DbFieldValue( "TIPO", "" ) ) == "C"
            lTiene := .T.
            EXIT
         ENDIF
         DbSkip()
      ENDDO
      NDC_ABO->( DbCloseArea() )
   ENDIF

RETURN lTiene


// ============================================================================
// GetTotalFactura()
// ============================================================================
FUNCTION GetTotalFactura( cSerie, cNumero )

   LOCAL nTotal := 0

   DEFAULT cSerie TO "A"

   IF !ABRIR_TABLA( "FACTURA", "FAC_RN", "FAC_NUM" )
      RETURN 0
   ENDIF

   DbSelectArea( "FAC_RN" )
   OrdSetFocus( "FAC_NUM" )

   IF DbSeek( PadR( cSerie, 4 ) + PadR( cNumero, 10 ) ) .OR. ;
      DbSeek( cSerie + cNumero )
      IF !FAC_RN->ANULADA
         nTotal := FAC_RN->TOTAL
      ENDIF
   ENDIF

   FAC_RN->( DbCloseArea() )

RETURN nTotal


// ============================================================================
// GetCobradoFactura()
// Prioriza FACTURA->COBRADO; si estuviera a cero, suma RC_DETAL por NUM_FAC.
// ============================================================================
FUNCTION GetCobradoFactura( cSerie, cNumero )

   LOCAL nCobrado := 0

   DEFAULT cSerie TO "A"

   IF ABRIR_TABLA( "FACTURA", "FAC_RC", "FAC_NUM" )
      DbSelectArea( "FAC_RC" )
      OrdSetFocus( "FAC_NUM" )
      IF DbSeek( PadR( cSerie, 4 ) + PadR( cNumero, 10 ) ) .OR. ;
         DbSeek( cSerie + cNumero )
         nCobrado := FAC_RC->COBRADO
      ENDIF
      FAC_RC->( DbCloseArea() )
   ENDIF

   IF nCobrado <= 0 .AND. ABRIR_TABLA( "RC_DETAL", "RCD_RC", "RCD_FAC" )
      DbSelectArea( "RCD_RC" )
      OrdSetFocus( "RCD_FAC" )
      DbGoTop()
      DO WHILE !Eof()
         IF !Deleted() .AND. AllTrim( RCD_RC->NUM_FAC ) == AllTrim( cNumero )
            nCobrado += RCD_RC->IMPORTE
         ENDIF
         DbSkip()
      ENDDO
      RCD_RC->( DbCloseArea() )
   ENDIF

RETURN nCobrado


// ============================================================================
// FacturaCobrada()
// ============================================================================
FUNCTION FacturaCobrada( cSerie, cNumero )

   LOCAL lCobrada := .F.

   DEFAULT cSerie TO "A"

   IF !ABRIR_TABLA( "FACTURA", "FAC_CB", "FAC_NUM" )
      RETURN .F.
   ENDIF

   DbSelectArea( "FAC_CB" )
   OrdSetFocus( "FAC_NUM" )

   IF DbSeek( PadR( cSerie, 4 ) + PadR( cNumero, 10 ) ) .OR. ;
      DbSeek( cSerie + cNumero )
      lCobrada := FAC_CB->COBRADA .OR. FAC_CB->COBRADO >= FAC_CB->TOTAL
   ENDIF

   FAC_CB->( DbCloseArea() )

RETURN lCobrada


// ============================================================================
// ObraExiste()
// ============================================================================
FUNCTION ObraExiste( cIdObra )

   LOCAL lExiste := .F.

   IF !ABRIR_TABLA( "OBRAS", "OBR_EX", "OBR_ID" )
      RETURN .F.
   ENDIF

   DbSelectArea( "OBR_EX" )
   OrdSetFocus( "OBR_ID" )
   lExiste := DbSeek( PadR( cIdObra, 12 ) ) .OR. DbSeek( cIdObra )
   OBR_EX->( DbCloseArea() )

RETURN lExiste


// ============================================================================
// GetTotalObra()
// ============================================================================
FUNCTION GetTotalObra( cIdObra )

   LOCAL nTotal := 0

   IF !ABRIR_TABLA( "OBRAS", "OBR_TO", "OBR_ID" )
      RETURN 0
   ENDIF

   DbSelectArea( "OBR_TO" )
   OrdSetFocus( "OBR_ID" )

   IF DbSeek( PadR( cIdObra, 12 ) ) .OR. DbSeek( cIdObra )
      nTotal := OBR_TO->TOTAL
   ENDIF

   OBR_TO->( DbCloseArea() )

RETURN nTotal


// ============================================================================
// GetFacturadoObra()
// Suma facturas no anuladas asociadas a ID_OBRA.
// ============================================================================
FUNCTION GetFacturadoObra( cIdObra )

   LOCAL nFacturado := 0

   IF Empty( cIdObra )
      RETURN 0
   ENDIF

   IF !ABRIR_TABLA( "FACTURA", "FAC_OB", "FAC_OBR" )
      RETURN 0
   ENDIF

   DbSelectArea( "FAC_OB" )
   OrdSetFocus( "FAC_OBR" )
   DbGoTop()

   DO WHILE !Eof()
      IF !Deleted() .AND. !DbFieldValue( "ANULADA", .F. ) .AND. ;
         AllTrim( DbFieldValue( "ID_OBRA", "" ) ) == AllTrim( cIdObra )
         nFacturado += FAC_OB->TOTAL
      ENDIF
      FAC_OB->( DbSkip() )
   ENDDO

   FAC_OB->( DbCloseArea() )

RETURN nFacturado


// ============================================================================
// GetCobradoObra()
// Suma cobrado de facturas no anuladas vinculadas a ID_OBRA.
// ============================================================================
FUNCTION GetCobradoObra( cIdObra )

   LOCAL nCobrado := 0

   IF Empty( cIdObra )
      RETURN 0
   ENDIF

   IF !ABRIR_TABLA( "FACTURA", "FAC_CB", "FAC_OBR" )
      RETURN 0
   ENDIF

   DbSelectArea( "FAC_CB" )
   OrdSetFocus( "FAC_OBR" )
   DbGoTop()

   DO WHILE !Eof()
      IF !Deleted() .AND. !DbFieldValue( "ANULADA", .F. ) .AND. ;
         AllTrim( DbFieldValue( "ID_OBRA", "" ) ) == AllTrim( cIdObra )
         nCobrado += DbFieldValue( "COBRADO", 0.00 )
      ENDIF
      FAC_CB->( DbSkip() )
   ENDDO

   FAC_CB->( DbCloseArea() )

RETURN nCobrado


// ============================================================================
// GetPendienteObra()
// ============================================================================
FUNCTION GetPendienteObra( cIdObra )

RETURN GetTotalObra( cIdObra ) - GetFacturadoObra( cIdObra )


// ============================================================================
// PresupuestoTieneObra()
// ============================================================================
FUNCTION PresupuestoTieneObra( cNumPre )

   LOCAL lTiene := .F.

   IF !ABRIR_TABLA( "PRESUPUEST", "PRE_TO", "PRE_NUM" )
      RETURN .F.
   ENDIF

   DbSelectArea( "PRE_TO" )
   OrdSetFocus( "PRE_NUM" )

   IF DbSeek( PadR( cNumPre, 10 ) ) .OR. DbSeek( cNumPre )
      lTiene := !Empty( PRE_TO->ID_OBRA )
   ENDIF

   PRE_TO->( DbCloseArea() )

RETURN lTiene


// ============================================================================
// PresupuestoAceptado()
// Por prudencia, solo ESTADO = A permite crear obra.
// ============================================================================
FUNCTION PresupuestoAceptado( cNumPre )

   LOCAL lAceptado := .F.

   IF !ABRIR_TABLA( "PRESUPUEST", "PRE_AC", "PRE_NUM" )
      RETURN .F.
   ENDIF

   DbSelectArea( "PRE_AC" )
   OrdSetFocus( "PRE_NUM" )

   IF DbSeek( PadR( cNumPre, 10 ) ) .OR. DbSeek( cNumPre )
      lAceptado := AllTrim( PRE_AC->ESTADO ) == "A"
   ENDIF

   PRE_AC->( DbCloseArea() )

RETURN lAceptado


// ============================================================================
// FIN DE ReglasNegocio.prg
// ============================================================================
