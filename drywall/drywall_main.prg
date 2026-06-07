/*
 * ARCHIVO  : drywall_main.prg
 * PROPOSITO: Punto de entrada para Drywall standalone con GfxStack.
 */

#include "OOp.ch"
#include "inkey.ch"

STATIC s_oDryMenu := NIL

FUNCTION Main()

    LOCAL oMenu, aMenuDef
    LOCAL cArg := Lower( hb_CStr( hb_ArgV( 0 ) ) + " " + ;
                         hb_CStr( hb_ArgV( 1 ) ) + " " + ;
                         hb_CStr( hb_ArgV( 2 ) ) + " " + ;
                         hb_CStr( hb_ArgV( 3 ) ) )

    rddSetDefault( "DBFCDX" )

    // Modo seed desde linea de comandos
    IF "seed" $ cArg
        SET DATE BRIT
        SET DATE FORMAT TO "DD/MM/YYYY"
        SET CENTURY ON
        InicioDrywall()
        SeedDrywall()
        ? "Seed completado."
        RETURN 0
    ENDIF

    // Modo inicializacion: crea tablas/indices y sale sin abrir interfaz.
    IF "migrate" $ cArg
        SET DATE BRIT
        SET DATE FORMAT TO "DD/MM/YYYY"
        SET CENTURY ON
        IF InicioDrywall()
            ? "Inicializacion Drywall completada."
            RETURN 0
        ENDIF
        ? "Error inicializando tablas Drywall."
        RETURN 1
    ENDIF

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

    // Activar raton
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
    LOCAL aProyecto  := {}
    LOCAL aMaestros  := {}
    LOCAL aAux       := {}
    LOCAL aInformes  := {}
    LOCAL aSistema   := {}

    AAdd( aProyecto, { "Proyecto Actual",         {|| ProyectoActual() },     NIL, "Crear o editar cabecera" } )
    AAdd( aProyecto, { "Proyectos en Curso",      {|| VisorProyectosCurso() },NIL, "Trabajos temporales TMP" } )
    AAdd( aProyecto, { "Proyectos Historicos",    {|| VisorProyectosHistorico() }, NIL, "Calculados y cerrados HIS" } )
    AAdd( aProyecto, { "Eliminar Proyecto Actual",{|| _DrywallLimpiar() },    NIL, "Borrar borrador" } )

    AAdd( aAux, { "Familias Art.", {|| EditAux("FAMILIA") }, NIL, "Placas, Perfiles..." } )
    AAdd( aAux, { "Unidad Medida", {|| EditAux("UNIDAD")  }, NIL, "Metros, Unidades..." } )
    AAdd( aAux, { "Tipos Obra",    {|| EditAux("OBRA")    }, NIL, "Tabique, Techo..." } )

    AAdd( aMaestros, { "Articulos",  {|| ArticulosView() }, NIL, "Base de Datos de Materiales" } )
    AAdd( aMaestros, { "Familias",   {|| M_Familias()    }, NIL, "Familias de articulos" } )
    AAdd( aMaestros, { "Sistemas",   {|| SistemasView()  }, NIL, "Sistemas y rendimientos por m2" } )
    AAdd( aMaestros, { "Tablas Aux", NIL, aAux, "Configuracion general" } )

    AAdd( aInformes, { "Proyectos en Curso", {|| VisorProyectosCurso() },      NIL, "Trabajos temporales TMP" } )
    AAdd( aInformes, { "Proyectos Historicos",{|| VisorProyectosHistorico() }, NIL, "Calculados y cerrados HIS" } )
    AAdd( aInformes, { "Proyectos (texto)",  {|| InformeProyectos() },         NIL, "Listado de proyectos activos" } )
    AAdd( aInformes, { "Historicos",         {|| InformeHistoricos() },        NIL, "Proyectos archivados" } )
    AAdd( aInformes, { "Clientes",           {|| InformeClientesDrywall() },   NIL, "Listado de clientes" } )
    AAdd( aInformes, { "Articulos",          {|| InformeArticulos() },         NIL, "Listado de articulos" } )
    AAdd( aInformes, { "Stock Minimo",       {|| InformeStockMinimo() },       NIL, "Alertas de stock" } )

    AAdd( aSistema, { "Tema Visual", {|| _DrywallTemaVisual() }, NIL, "Cambiar colores de la interfaz" } )
    AAdd( aSistema, { "Salir",       {|| __Quit() },             NIL, "Cerrar aplicacion" } )

    AAdd( aMenu, { "Proyecto", NIL, aProyecto, "Ciclo de Presupuestacion" } )
    AAdd( aMenu, { "Maestros", NIL, aMaestros, "Bases de Datos" } )
    AAdd( aMenu, { "Informes", NIL, aInformes, "Impresion y Salidas" } )
    AAdd( aMenu, { "Sistema",  NIL, aSistema,  "Configuracion" } )

RETURN aMenu


STATIC FUNCTION _DrywallLimpiar()

    _LimpiaTemporales()

RETURN NIL


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

    // Cerrar popups primero para que restauren sus fondos (aun en color viejo)
    TMenuCloseAll()

    GfxThemeSet( cSel )

    CLS

    IF s_oDryMenu != NIL
        s_oDryMenu:Paint()
    ENDIF

RETURN NIL
