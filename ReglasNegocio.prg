/*
 * ARCHIVO  : ReglasNegocio.prg
 * PROPOSITO: Validaciones centrales del modelo de negocio.
 *
 * Este modulo NO decide criterios fiscales complejos.
 * Su objetivo es evitar incoherencias internas:
 * - cobrar mas que una factura
 * - facturar mas que una obra
 * - duplicar obras desde presupuesto
 * - facturar documentos no validos
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

   nTotal     := GetTotalFactura( cSerie, cNumero )
   nCobrado   := GetCobradoFactura( cSerie, cNumero )
   nPendiente := nTotal - nCobrado

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
// Evita facturar mas que el pendiente de una obra.
// ============================================================================
FUNCTION ValidarFacturaObra( cIdObra, nImporte )

   LOCAL nTotal
   LOCAL nFacturado
   LOCAL nPendiente

   nTotal     := GetTotalObra( cIdObra )
   nFacturado := GetFacturadoObra( cIdObra )
   nPendiente := nTotal - nFacturado

   IF Empty( cIdObra )
      MsgStop( "Debe indicar una obra.", "Validacion" )
      RETURN .F.
   ENDIF

   IF nImporte <= 0
      MsgStop( "El importe a facturar debe ser mayor que cero.", "Validacion" )
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

   IF ! PresupuestoAceptado( cNumPre )
      MsgStop( "Solo se puede crear obra desde un presupuesto aceptado.", "Validacion" )
      RETURN .F.
   ENDIF

RETURN .T.


// ============================================================================
// ValidarCerrarObra()
// No permite cerrar obra con importe pendiente de facturar.
// ============================================================================
FUNCTION ValidarCerrarObra( cIdObra )

   LOCAL nPendiente

   nPendiente := GetPendienteObra( cIdObra )

   IF nPendiente > 0
      MsgStop( "No se puede cerrar la obra: queda importe pendiente de facturar.", ;
               "Validacion" )
      RETURN .F.
   ENDIF

RETURN .T.


// ============================================================================
// ValidarAnularFactura()
// Regla prudente: no anular facturas cobradas sin proceso controlado.
// ============================================================================
FUNCTION ValidarAnularFactura( cSerie, cNumero )

   IF FacturaCobrada( cSerie, cNumero )
      MsgStop( "No se puede anular directamente una factura cobrada. Use proceso rectificativo.", ;
               "Validacion" )
      RETURN .F.
   ENDIF

RETURN .T.