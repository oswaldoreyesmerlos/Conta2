/*
 * ARCHIVO  : MenuInit.prg
 * PROPOSITO: Definicion del arbol de menu de la aplicacion.
 *
 * MODULOS ACTIVOS
 * ---------------
 *   Fase 1: M_Auxiliar.prg -> M_Familias, M_FormaPago, M_TiposIva, M_CCostes
 *   Fase 2: M_Empresa.prg  -> Empresa
 *           M_Clientes.prg -> ClientesView, ClientesForm
 *   Fase 3: V_Facturas.prg -> FacturasView, AltaFact
 *           V_Imprimir.prg -> ImprimirFactura (interno, no en menu)
 *   Seguridad.prg          -> RolesEdit
 *   Main.prg               -> App_Exit
 */

#include "OOp.ch"

EXTERNAL M_Familias
EXTERNAL M_FormaPago
EXTERNAL M_TiposIva
EXTERNAL M_CCostes
EXTERNAL Empresa
EXTERNAL ClientesView
EXTERNAL ClientesForm
EXTERNAL FacturasView
EXTERNAL AltaFact
EXTERNAL ImprimirFactura
EXTERNAL RolesEdit
EXTERNAL App_Exit


FUNCTION Menu_Init()

    LOCAL aMenu     := {}
    LOCAL aMaest    := {}
    LOCAL aVentas   := {}
    LOCAL aInv      := {}
    LOCAL aTeso     := {}
    LOCAL aContab   := {}
    LOCAL aInform   := {}
    LOCAL aSistema  := {}
    LOCAL aSubCli   := {}
    LOCAL aSubPro   := {}
    LOCAL aSubArt   := {}
    LOCAL aSubFac   := {}
    LOCAL lEsAdm    := .F.
    LOCAL lEsCont   := .F.
    LOCAL lEsCaja   := .F.

    MEMVAR cUserRol

    lEsAdm  := ( AllTrim( cUserRol ) == "ADM" )
    lEsCont := ( AllTrim( cUserRol ) $ "ADM,CONT" )
    lEsCaja := ( AllTrim( cUserRol ) $ "ADM,CAJA" )

    // -------------------------------------------------------------------------
    // SUBMENUS
    // -------------------------------------------------------------------------

    // Clientes - ACTIVO
    AAdd( aSubCli, { "Listado", {|| ClientesView()         }, NIL, "Ver clientes" } )
    AAdd( aSubCli, { "Alta",    {|| ClientesForm( .T., "" )}, NIL, "Nuevo cliente" } )

    // Proveedores - pendiente
    AAdd( aSubPro, { "Listado", NIL, NIL, "Ver proveedores" } )
    AAdd( aSubPro, { "Alta",    NIL, NIL, "Nuevo proveedor" } )

    // Articulos - pendiente
    AAdd( aSubArt, { "Inventario", NIL, NIL, "Catalogo" } )
    AAdd( aSubArt, { "Alta",       NIL, NIL, "Nuevo articulo" } )

    // Facturas - ACTIVO
    AAdd( aSubFac, { "Historial",  {|| FacturasView() }, NIL, "Facturas emitidas" } )
    AAdd( aSubFac, { "Nueva",      {|| AltaFact()     }, NIL, "Nueva factura" } )

    // -------------------------------------------------------------------------
    // MAESTROS
    // -------------------------------------------------------------------------
    AAdd( aMaest, { "Clientes",    NIL, aSubCli, "Fichero de clientes" } )
    AAdd( aMaest, { "Proveedores", NIL, aSubPro, "Fichero de proveedores" } )
    AAdd( aMaest, { "Articulos",   NIL, aSubArt, "Catalogo de articulos" } )
    AAdd( aMaest, { "Vendedores",  NIL, NIL,     "Ficha comercial" } )
    AAdd( aMaest, { "Familias",    {|| M_Familias()  }, NIL, "Familias de articulos" } )
    AAdd( aMaest, { "Formas Pago", {|| M_FormaPago() }, NIL, "Formas de pago" } )
    AAdd( aMaest, { "Tipos IVA",   {|| M_TiposIva()  }, NIL, "Tipos de IVA" } )

    IF lEsAdm
        AAdd( aMaest, { "Localidades", NIL,            NIL, "Codigos postales" } )
        AAdd( aMaest, { "Empresa",     {|| Empresa() }, NIL, "Datos de la empresa" } )
    ENDIF

    // -------------------------------------------------------------------------
    // VENTAS
    // -------------------------------------------------------------------------
    AAdd( aVentas, { "Presupuestos", NIL,    NIL,     "Gestion de presupuestos" } )
    AAdd( aVentas, { "Facturas",     NIL,    aSubFac, "Gestion de facturas" } )

    // -------------------------------------------------------------------------
    // INVENTARIO
    // -------------------------------------------------------------------------
    AAdd( aInv, { "Movimientos", NIL, NIL, "Ajustes de stock" } )

    // -------------------------------------------------------------------------
    // TESORERIA
    // -------------------------------------------------------------------------
    IF lEsCaja
        AAdd( aTeso, { "Cobros/Caja", NIL, NIL, "Gestion de cobros" } )
        AAdd( aTeso, { "Bancos",      NIL, NIL, "Cuentas bancarias" } )
    ENDIF

    // -------------------------------------------------------------------------
    // CONTABILIDAD
    // -------------------------------------------------------------------------
    IF lEsCont
        AAdd( aContab, { "Plan Cuentas",  NIL, NIL, "Plan contable" } )
        AAdd( aContab, { "Libro Diario",  NIL, NIL, "Consulta asientos" } )
        AAdd( aContab, { "Nuevo Asiento", NIL, NIL, "Alta manual" } )
        AAdd( aContab, { "Centros Coste", {|| M_CCostes() }, NIL, "Analitica" } )
    ENDIF

    // -------------------------------------------------------------------------
    // INFORMES
    // -------------------------------------------------------------------------
    AAdd( aInform, { "Clientes",  NIL, NIL, "Listado de clientes" } )
    AAdd( aInform, { "Articulos", NIL, NIL, "Listado de precios" } )
    IF lEsCont
        AAdd( aInform, { "Libro Diario", NIL, NIL, "Asientos contables" } )
    ENDIF

    // -------------------------------------------------------------------------
    // SISTEMA
    // -------------------------------------------------------------------------
    IF lEsAdm
        AAdd( aSistema, { "Usuarios", NIL,              NIL, "Mantenimiento usuarios" } )
        AAdd( aSistema, { "Roles",    {|| RolesEdit() }, NIL, "Mantenimiento roles" } )
    ENDIF
    AAdd( aSistema, { "Salir", {|| App_Exit() }, NIL, "Salir del sistema" } )

    // -------------------------------------------------------------------------
    // ENSAMBLAJE
    // -------------------------------------------------------------------------
    AAdd( aMenu, { "MAESTROS",   NIL, aMaest,  "Tablas maestras" } )
    AAdd( aMenu, { "VENTAS",     NIL, aVentas, "Gestion de ventas" } )
    AAdd( aMenu, { "INVENTARIO", NIL, aInv,    "Control de stock" } )

    IF lEsCaja
        AAdd( aMenu, { "TESORERIA",    NIL, aTeso,   "Tesoreria y caja" } )
    ENDIF

    IF lEsCont
        AAdd( aMenu, { "CONTABILIDAD", NIL, aContab, "Contabilidad" } )
    ENDIF

    AAdd( aMenu, { "INFORMES", NIL, aInform,  "Centro de reportes" } )
    AAdd( aMenu, { "SISTEMA",  NIL, aSistema, "Configuracion del sistema" } )

RETURN aMenu

// ============================================================================
// FIN DE MenuInit.prg
// ============================================================================
