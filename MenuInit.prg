/*
 * ARCHIVO  : MenuInit.prg
 * PROPOSITO: Definicion del arbol de menu de la aplicacion.
 *
 * MODULOS ACTIVOS
 * ---------------
 *   M_Auxiliar.prg    -> M_FormaPago, M_TiposIva, M_CCostes
 *   M_Empresa.prg     -> Empresa
 *   M_Clientes.prg    -> ClientesView, ClientesForm
 *   M_Proveedo.prg    -> ProveedView, ProveedForm
 *   M_Vendedor.prg    -> VendedoresView, VendedoresForm
 *   M_Usuarios.prg    -> UsuariosView
 *   M_Conta.prg       -> PlanCuentasView, LibroDiarioView
 *   V_Facturas.prg    -> FacturasView
 *   V_Presupuesto.prg -> PresupuestosView, AltaPresupuesto
 *   Tesoreria.prg     -> TesoreriaView
 *   Informes.prg      -> InformeClientes, InformeFacturas, InformePresupuestos
 *   Seguridad.prg     -> RolesEdit
 *   Main.prg          -> App_Exit
 */

#include "OOp.ch"

EXTERNAL M_FormaPago
EXTERNAL M_TiposIva
EXTERNAL M_CCostes
EXTERNAL Empresa
EXTERNAL ClientesView
EXTERNAL ClientesForm
EXTERNAL ProveedView
EXTERNAL ProveedForm
EXTERNAL VendedoresView
EXTERNAL VendedoresForm
EXTERNAL UsuariosView
EXTERNAL PlanCuentasView
EXTERNAL AsientoAutomatico
EXTERNAL CierreEjercicio
EXTERNAL LibroDiarioView
EXTERNAL LibroDiarioNuevo
EXTERNAL FacturasView
EXTERNAL ObrasView
EXTERNAL NotaAbonoForm
EXTERNAL PresupuestosView
EXTERNAL AltaPresupuesto
EXTERNAL AceptarPresupuesto
EXTERNAL RechazarPresupuesto
EXTERNAL CajaView
EXTERNAL BancosView
EXTERNAL CobrosView
EXTERNAL PagosView
EXTERNAL InformeClientes
EXTERNAL InformeFacturas
EXTERNAL InformePresupuestos
EXTERNAL InformeVencimientos
EXTERNAL InformeProveedores
EXTERNAL InformeDiario
EXTERNAL InformeMayor
EXTERNAL InformeBalanceSumasSaldos
EXTERNAL InformeBalanceGeneral
EXTERNAL InformePerdidasGanancias
EXTERNAL RolesEdit
EXTERNAL ReindexarTodo
EXTERNAL App_Exit


FUNCTION Menu_Init()

    LOCAL aMenu
    LOCAL aMaest
    LOCAL aVentas
    LOCAL aTeso
    LOCAL aContab
    LOCAL aInform
    LOCAL aSistema
    LOCAL aSubCli
    LOCAL aSubPro
    LOCAL aSubVen
    LOCAL aSubFac
    LOCAL aSubObr
    LOCAL aSubPre
    LOCAL lEsAdm
    LOCAL lEsCont
    LOCAL lEsCaja

    MEMVAR cUserRol

    aMenu    := {}
    aMaest   := {}
    aVentas  := {}
    aTeso    := {}
    aContab  := {}
    aInform  := {}
    aSistema := {}
    aSubCli  := {}
    aSubPro  := {}
    aSubVen  := {}
    aSubFac  := {}
    aSubObr  := {}
    aSubPre  := {}

    lEsAdm  := Upper( AllTrim( cUserRol ) ) == "ADM" .OR. ;
               HasPerm( "SEG_USR" ) .OR. HasPerm( "SEG_ROL" )
    lEsCont := lEsAdm .OR. HasPerm( "CONT" )
    lEsCaja := lEsAdm .OR. HasPerm( "TESO" )

    // -------------------------------------------------------------------------
    // SUBMENUS
    // -------------------------------------------------------------------------

    // Clientes
    AAdd( aSubCli, { "Listado", {|| ClientesView()          }, NIL, "Ver clientes" } )
    AAdd( aSubCli, { "Alta",    {|| ClientesForm( .T., "" ) }, NIL, "Nuevo cliente" } )

    // Proveedores
    AAdd( aSubPro, { "Listado", {|| ProveedView()           }, NIL, "Ver proveedores" } )
    AAdd( aSubPro, { "Alta",    {|| ProveedForm( .T., "" )  }, NIL, "Nuevo proveedor" } )

    // Vendedores
    AAdd( aSubVen, { "Listado", {|| VendedoresView()            }, NIL, "Ver vendedores" } )
    AAdd( aSubVen, { "Alta",    {|| VendedoresForm( .T., "" )   }, NIL, "Nuevo vendedor" } )

    // Presupuestos
    AAdd( aSubPre, { "Historial", {|| PresupuestosView()  }, NIL, "Presupuestos emitidos" } )
    AAdd( aSubPre, { "Nuevo",     {|| AltaPresupuesto()   }, NIL, "Nuevo presupuesto" } )

    // Obras
    AAdd( aSubObr, { "Historial", {|| ObrasView() }, NIL, "Gestion y certificacion de obras" } )

    // Facturas
    AAdd( aSubFac, { "Historial", {|| FacturasView() }, NIL, "Facturas emitidas" } )
    AAdd( aSubFac, { "Nueva directa", {|| AltaFact() }, NIL, "Factura sin presupuesto ni obra" } )

    // -------------------------------------------------------------------------
    // MAESTROS
    // -------------------------------------------------------------------------
    AAdd( aMaest, { "Clientes",    NIL, aSubCli, "Fichero de clientes" } )
    AAdd( aMaest, { "Proveedores", NIL, aSubPro, "Fichero de proveedores" } )
    AAdd( aMaest, { "Vendedores",  NIL, aSubVen, "Comerciales" } )
    AAdd( aMaest, { "Formas Pago", {|| M_FormaPago() }, NIL, "Formas de pago" } )
    AAdd( aMaest, { "Tipos IVA",   {|| M_TiposIva()  }, NIL, "Tipos de IVA" } )

    IF lEsAdm
        AAdd( aMaest, { "Empresa", {|| Empresa() }, NIL, "Datos de la empresa" } )
    ENDIF

    // -------------------------------------------------------------------------
    // VENTAS
    // -------------------------------------------------------------------------
    AAdd( aVentas, { "Presupuestos", NIL, aSubPre, "Gestion de presupuestos" } )
    AAdd( aVentas, { "Obras",        NIL, aSubObr, "Gestion de obras y certificaciones" } )
    AAdd( aVentas, { "Facturas",     NIL, aSubFac, "Gestion de facturas" } )

    // -------------------------------------------------------------------------
    // TESORERIA
    // -------------------------------------------------------------------------
    IF lEsCaja
        AAdd( aTeso, { "Caja",    {|| CajaView()    }, NIL, "Recibos de caja y cobros" } )
        AAdd( aTeso, { "Cobros",  {|| CobrosView()  }, NIL, "Vencimientos pendientes de cobro" } )
        AAdd( aTeso, { "Pagos",   {|| PagosView()   }, NIL, "Pagos pendientes a proveedores" } )
        AAdd( aTeso, { "Bancos",  {|| BancosView()  }, NIL, "Cuentas bancarias y movimientos" } )
    ENDIF

    // -------------------------------------------------------------------------
    // CONTABILIDAD
    // -------------------------------------------------------------------------
    IF lEsCont
        AAdd( aContab, { "Plan de Cuentas", {|| PlanCuentasView() }, NIL, "Plan contable PGC" } )
        AAdd( aContab, { "Libro Diario",    {|| LibroDiarioView() }, NIL, "Consulta asientos" } )
        AAdd( aContab, { "Nuevo Asiento",   {|| LibroDiarioNuevo() }, NIL, "Crear asiento manual" } )
        AAdd( aContab, { "Centros Coste",   {|| M_CCostes()       }, NIL, "Analitica" } )
        AAdd( aContab, { "Informe Diario",  {|| InformeDiario()   }, NIL, "Libro diario contable" } )
        AAdd( aContab, { "Libro Mayor",     {|| InformeMayor()    }, NIL, "Mayor por cuenta" } )
        AAdd( aContab, { "Sumas/Saldos",    {|| InformeBalanceSumasSaldos() }, NIL, "Balance de sumas y saldos" } )
        AAdd( aContab, { "Balance Gral.",   {|| InformeBalanceGeneral() }, NIL, "Balance general" } )
        AAdd( aContab, { "Perd./Gan.",      {|| InformePerdidasGanancias() }, NIL, "Estado de perdidas y ganancias" } )
        AAdd( aContab, { "Cierre Ejercicio", {|| CierreEjercicio() }, NIL, "Cierre contable anual (solo ADM)" } )
    ENDIF

    // -------------------------------------------------------------------------
    // INFORMES
    // -------------------------------------------------------------------------
    AAdd( aInform, { "Clientes",     {|| InformeClientes()     }, NIL, "Listado de clientes" } )
    AAdd( aInform, { "Facturas",     {|| InformeFacturas()     }, NIL, "Listado de facturas" } )
    AAdd( aInform, { "Presupuestos",  {|| InformePresupuestos()  }, NIL, "Listado de presupuestos" } )
    AAdd( aInform, { "Vencimientos",  {|| InformeVencimientos()  }, NIL, "Cobros pendientes" } )
    AAdd( aInform, { "Proveedores",   {|| InformeProveedores()   }, NIL, "Listado de proveedores" } )

    // -------------------------------------------------------------------------
    // SISTEMA
    // -------------------------------------------------------------------------
    IF lEsAdm
        AAdd( aSistema, { "Usuarios", {|| UsuariosView() }, NIL, "Mantenimiento usuarios" } )
        AAdd( aSistema, { "Roles",      {|| RolesEdit()      }, NIL, "Mantenimiento roles" } )
        AAdd( aSistema, { "Reindexar",  {|| ReindexarTodo()  }, NIL, "Reindexar tablas (ADM + backup previo)" } )
    ENDIF
    AAdd( aSistema, { "Salir", {|| App_Exit() }, NIL, "Salir del sistema" } )

    // -------------------------------------------------------------------------
    // ENSAMBLAJE BARRA PRINCIPAL
    // -------------------------------------------------------------------------
    AAdd( aMenu, { "MAESTROS", NIL, aMaest,  "Tablas maestras" } )
    AAdd( aMenu, { "VENTAS",   NIL, aVentas, "Gestion de ventas" } )

    IF lEsCaja
        AAdd( aMenu, { "TESORERIA", NIL, aTeso, "Tesoreria y bancos" } )
    ENDIF

    IF lEsCont
        AAdd( aMenu, { "CONTABILIDAD", NIL, aContab, "Contabilidad general" } )
    ENDIF

    AAdd( aMenu, { "INFORMES", NIL, aInform,  "Centro de reportes" } )
    AAdd( aMenu, { "SISTEMA",  NIL, aSistema, "Configuracion del sistema" } )

RETURN aMenu

// ============================================================================
// FIN DE MenuInit.prg
// ============================================================================
