/*
 * ARCHIVO  : drywall_main.prg
 * PROPOSITO: Punto de entrada para Drywall standalone con GfxStack.
 */

#include "OOp.ch"
#include "inkey.ch"

STATIC s_oDryMenu := NIL

FUNCTION Main()

    LOCAL oMenu, aMenuDef

    rddSetDefault( "DBFCDX" )

    ErrorBlock( { |e| ErrSys( e ) } )

    SET DATE BRIT
    SET DATE FORMAT TO "DD/MM/YYYY"
    SET CENTURY ON

    GfxSetFont( "Lucida Console", 16, 8 )
    SetMode( 40, 132 )
    GfxFixSize( .T. )
    GfxThemeLoad()
    CLS
    GfxCursor( SC_NONE )

    BEGIN SEQUENCE
        SET EVENTMASK TO ( INKEY_KEYBOARD + INKEY_LDOWN + INKEY_LUP + INKEY_RDOWN + INKEY_RUP )
        wvt_SetMouseMove( .T. )
    RECOVER
    END SEQUENCE

    IF !InicioDrywall()
        MsgStop( "Error creando tablas Drywall", "Inicio" )
        RETURN 1
    ENDIF

    aMenuDef := _DrywallMenu()
    oMenu := TMenu():New( aMenuDef, 0 )
    s_oDryMenu := oMenu
    oMenu:Activate()

RETURN 0


STATIC FUNCTION _DrywallMenu()

    LOCAL aMenu      := {}
    LOCAL aMaestros  := {}
    LOCAL aSistema   := {}

    AAdd( aMaestros, { "Articulos",  {|| ArticulosView() }, 		NIL, "Base de Datos de Materiales" } )
    AAdd( aMaestros, { "Familias",   {|| M_Familias()    }, 		NIL, "Familias de articulos" } )
    AAdd( aMaestros, { "Sistemas",   {|| SistemasView()  }, 		NIL, "Sistemas y rendimientos por m2" } )
    AAdd( aMaestros, { "Familias Art.", {|| EditAux("FAMILIA") },	NIL, "Placas, Perfiles..." } )
    AAdd( aMaestros, { "Unidad Medida", {|| EditAux("UNIDAD")  }, 	NIL, "Metros, Unidades..." } )
    AAdd( aMaestros, { "Tipos Obra",    {|| EditAux("OBRA")    }, 	NIL, "Tabique, Techo..." } )

    AAdd( aSistema, { "Tema Visual", {|| _DrywallTemaVisual() }, 	NIL, "Cambiar colores de la interfaz" } )
    AAdd( aSistema, { "Salir",       {|| __Quit() },             	NIL, "Cerrar aplicacion" } )

    AAdd( aMenu, { "Proyecto", NIL, { ;
        { "Proyecto Actual",    {|| ProyectoActual() },     		NIL, "Crear o editar cabecera" }, ;
        { "Proyectos en Curso", {|| VisorProyectosCurso() },		NIL, "Trabajos temporales TMP" }, ;
        { "Proyectos Historicos",{|| VisorProyectosHistorico() }, 	NIL, "Calculados y cerrados HIS" }, ;
        { "Eliminar Actual",    {|| _LimpiaTemporales() },  		NIL, "Borrar borrador" } }, "Ciclo de Presupuestacion" } )
    AAdd( aMenu, { "Maestros", NIL, aMaestros, "Bases de Datos" } )
    AAdd( aMenu, { "Informes", NIL, { ;
        { "Proyectos en Curso", {|| VisorProyectosCurso() },      NIL, "Trabajos temporales TMP" }, ;
        { "Proyectos Historicos",{|| VisorProyectosHistorico() }, NIL, "Calculados y cerrados HIS" }, ;
        { "Proyectos (texto)",  {|| InformeProyectos() },         NIL, "Listado de proyectos activos" }, ;
        { "Historicos",         {|| InformeHistoricos() },        NIL, "Proyectos archivados" }, ;
        { "Clientes",           {|| InformeClientesDrywall() },   NIL, "Listado de clientes" }, ;
        { "Articulos",          {|| InformeArticulos() },         NIL, "Listado de articulos" }, ;
        { "Stock Minimo",       {|| InformeStockMinimo() },       NIL, "Alertas de stock" } }, "Impresion y Salidas" } )
    AAdd( aMenu, { "Sistema",  NIL, aSistema,  "Configuracion" } )

RETURN aMenu


STATIC FUNCTION _DrywallTemaVisual()

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

    IF s_oDryMenu != NIL
        s_oDryMenu:Paint()
    ENDIF

RETURN NIL
