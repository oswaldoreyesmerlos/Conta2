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
 *   V_Presupuesto.prg -> PresupuestosView, PresupuestoNuevo, AltaPresupuesto
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
EXTERNAL PartidasView
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
EXTERNAL ObraNuevaManual
EXTERNAL ObraDesdePresupuesto
EXTERNAL CertificacionesView
EXTERNAL NotaAbonoForm
EXTERNAL PresupuestosView
EXTERNAL PresupuestoNuevo
EXTERNAL AltaPresupuesto
EXTERNAL AceptarPresupuesto
EXTERNAL RechazarPresupuesto
EXTERNAL CajaView
EXTERNAL BancosView
EXTERNAL CobrosView
EXTERNAL PagosView
EXTERNAL BancoNuevo
EXTERNAL ReciboNuevo
EXTERNAL CobroNuevo
EXTERNAL PagoNuevo
EXTERNAL InformeClientes
EXTERNAL InformeFacturas
EXTERNAL InformePresupuestos
EXTERNAL InformeObras
EXTERNAL InformeVencimientos
EXTERNAL InformeProveedores
EXTERNAL InformeDiario
EXTERNAL InformeMayor
EXTERNAL InformeAsientosDescuadrados
EXTERNAL InformeIVA
EXTERNAL InformeBalanceSumasSaldos
EXTERNAL InformeBalanceGeneral
EXTERNAL InformePerdidasGanancias
EXTERNAL RolesEdit
EXTERNAL ReindexarTodo
EXTERNAL App_Exit

EXTERNAL ProyectoActual
EXTERNAL VerTareas
EXTERNAL Procesa
EXTERNAL Valorar
EXTERNAL GrabaPres
EXTERNAL DrywallGenPresupuesto
EXTERNAL InformeClientesDrywall
EXTERNAL SistemasView


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
    LOCAL aSubCaja
    LOCAL aSubCob
    LOCAL aSubPag
    LOCAL aSubBan
    LOCAL aDryw
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
    aSubCaja := {}
    aSubCob  := {}
    aSubPag  := {}
    aSubBan  := {}

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

    // Partidas tecnicas
    AAdd( aSubVen, { "Partidas",    {|| PartidasView()           }, NIL, "Catalogo de partidas tecnicas reutilizables" } )

    // Vendedores
    AAdd( aSubVen, { "Listado", {|| VendedoresView()            }, NIL, "Ver vendedores" } )
    AAdd( aSubVen, { "Alta",    {|| VendedoresForm( .T., "" )   }, NIL, "Nuevo vendedor" } )

    // Presupuestos
    AAdd( aSubPre, { "Historial", {|| PresupuestosView()  }, NIL, "Presupuestos emitidos" } )
    AAdd( aSubPre, { "Nuevo",     {|| PresupuestoNuevo()  }, NIL, "Nuevo presupuesto" } )

    // Obras
    AAdd( aSubObr, { "Historial",          {|| ObrasView() }, NIL, "Listado y seguimiento de obras" } )
    AAdd( aSubObr, { "Nueva obra",         {|| ObraNuevaManual() }, NIL, "Crear una obra manual" } )
    AAdd( aSubObr, { "Desde presupuesto",  {|| ObraDesdePresupuesto() }, NIL, "Crear obra desde presupuesto aceptado" } )
    AAdd( aSubObr, { "Certificaciones",    {|| CertificacionesView() }, NIL, "Gestion de certificaciones de obra" } )

    // Facturas
    AAdd( aSubFac, { "Historial", {|| FacturasView() }, NIL, "Facturas emitidas" } )
    AAdd( aSubFac, { "Nueva directa", {|| AltaFact() }, NIL, "Factura sin presupuesto ni obra" } )

    // Tesoreria
    AAdd( aSubCaja, { "Listado", {|| CajaView()    }, NIL, "Recibos de caja" } )
    AAdd( aSubCaja, { "Nuevo",   {|| ReciboNuevo() }, NIL, "Nuevo recibo de caja" } )

    AAdd( aSubCob, { "Pendientes", {|| CobrosView() }, NIL, "Facturas pendientes de cobro" } )
    AAdd( aSubCob, { "Nuevo",      {|| CobroNuevo() }, NIL, "Nuevo cobro manual" } )

    AAdd( aSubPag, { "Pendientes compras", {|| PagosView() }, NIL, "Compras pendientes de pago" } )
    AAdd( aSubPag, { "Nuevo pago libre",   {|| PagoNuevo() }, NIL, "Cheque, transferencia u otro pago" } )

    AAdd( aSubBan, { "Listado", {|| BancosView() }, NIL, "Cuentas bancarias" } )
    AAdd( aSubBan, { "Nuevo",   {|| BancoNuevo() }, NIL, "Nueva cuenta bancaria" } )

    // Drywall
    aDryw := {}
    AAdd( aDryw, { "Proyecto Actual", {|| ProyectoActual() }, NIL, "Crear/editar proyecto activo de calculo" } )
    AAdd( aDryw, { "Ver Tareas",      {|| VerTareas() },      NIL, "Grid de tramos del proyecto activo" } )
    AAdd( aDryw, { "Calcular",        {|| Procesa() },        NIL, "Ejecutar calculo de materiales" } )
    AAdd( aDryw, { "Valorar",         {|| Valorar() },        NIL, "Editar precios y ver resultado" } )
    AAdd( aDryw, { "Guardar en firme", {|| GrabaPres() },     NIL, "Pasar a historico" } )
    AAdd( aDryw, { "Generar Presupuesto", {|| DrywallGenPresupuesto( NIL, NIL ) }, NIL, "Crear presupuesto formal" } )
    AAdd( aDryw, { "Sistemas",         {|| SistemasView() },   NIL, "Mantenimiento de sistemas constructivos" } )
    AAdd( aDryw, { "Clientes Drywall", {|| InformeClientesDrywall() }, NIL, "Listado de clientes" } )

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
        AAdd( aTeso, { "Caja",    NIL, aSubCaja, "Recibos de caja y cobros" } )
        AAdd( aTeso, { "Cobros",  NIL, aSubCob,  "Vencimientos pendientes de cobro" } )
        AAdd( aTeso, { "Pagos",   NIL, aSubPag,  "Pagos pendientes a proveedores" } )
        AAdd( aTeso, { "Bancos",  NIL, aSubBan,  "Cuentas bancarias y movimientos" } )
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
        AAdd( aContab, { "Descuadres",      {|| InformeAsientosDescuadrados() }, NIL, "Asientos con debe distinto de haber" } )
        AAdd( aContab, { "Informe IVA",     {|| InformeIVA() }, NIL, "IVA repercutido y soportado" } )
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
    AAdd( aInform, { "Obras",         {|| InformeObras()         }, NIL, "Estado economico de obras" } )
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
    AAdd( aSistema, { "Tema Visual", {|| _AppTemaVisual() }, NIL, "Cambiar colores de la interfaz" } )
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
    AAdd( aMenu, { "DRYWALL",  NIL, aDryw,    "Modulo de calculo de tabiqueria seca" } )
    AAdd( aMenu, { "SISTEMA",  NIL, aSistema, "Configuracion del sistema" } )

RETURN aMenu


STATIC FUNCTION _AppTemaVisual()

    LOCAL aData := { ;
        { "CLASICO", "Clasico N/W", "Negro sobre blanco" }, ;
        { "AZUL",    "Azul W/B",    "Blanco sobre azul" }, ;
        { "CYAN",    "Cyan N/BG",   "Negro sobre cyan" } }
    LOCAL cSel

    cSel := PopupSelect( "TEMA VISUAL", aData, ;
        { { "Codigo", 10, "@!", 1 }, ;
          { "Tema",   22, "@!", 2 }, ;
          { "Detalle", 28, "@!", 3 } }, 2 )

    IF Empty( cSel )
        RETURN NIL
    ENDIF

    TMenuCloseAll()
    GfxThemeSet( cSel )
    CLS

RETURN NIL


// ============================================================================
// FIN DE MenuInit.prg
// ============================================================================
