/*
 * ARCHIVO  : drywall_main.prg
 * PROPOSITO: Punto de entrada para Drywall standalone con GfxStack.
 */

#include "OOp.ch"
#include "inkey.ch"

FUNCTION Main()

    LOCAL oMenu, aMenuDef

    rddSetDefault( "DBFCDX" )

    GfxSetFont( "Lucida Console", 16, 8 )
    SetMode( 40, 132 )
    GfxFixSize( .T. )
    SetColor( "N/W" )
    CLS
    GfxCursor( SC_NONE )

    IF !InicioDrywall()
        MsgStop( "Error creando tablas Drywall", "Inicio" )
        RETURN 1
    ENDIF

    aMenuDef := _DrywallMenu()
    oMenu := TMenu():New( aMenuDef, 0 )
    oMenu:Activate()

RETURN 0


STATIC FUNCTION _DrywallMenu()

    LOCAL aMenu      := {}
    LOCAL aProyecto  := {}
    LOCAL aMaestros  := {}
    LOCAL aAux       := {}
    LOCAL aInformes  := {}
    LOCAL aSistema   := {}

    AAdd( aProyecto, { "Definir Tramos",    {|| VerTareas() },        NIL, "Panel de diseno de tramos" } )
    AAdd( aProyecto, { "Calcular Material", {|| Procesa()  },         NIL, "Generar despiece y computo" } )
    AAdd( aProyecto, { "Valorar Economico", {|| Valorar()  },         NIL, "Ajuste final de precios" } )
    AAdd( aProyecto, { "Guardar Historico", {|| GrabaPres() },        NIL, "Cerrar presupuesto definitivo" } )
    AAdd( aProyecto, { "Nuevo Proyecto",    {|| _DrywallLimpiar() }, NIL, "Borrar borrador" } )

    AAdd( aAux, { "Familias Art.", {|| EditAux("FAMILIA") }, NIL, "Placas, Perfiles..." } )
    AAdd( aAux, { "Unidad Medida", {|| EditAux("UNIDAD")  }, NIL, "Metros, Unidades..." } )
    AAdd( aAux, { "Tipos Obra",    {|| EditAux("OBRA")    }, NIL, "Tabique, Techo..." } )

    AAdd( aMaestros, { "Articulos",  {|| ArticulosView() }, NIL, "Base de Datos de Materiales" } )
    AAdd( aMaestros, { "Familias",   {|| M_Familias()    }, NIL, "Familias de articulos" } )
    AAdd( aMaestros, { "Tablas Aux", NIL, aAux, "Configuracion general" } )

    AAdd( aInformes, { "Articulos",       {|| InformeArticulos() },     NIL, "Listado de articulos" } )
    AAdd( aInformes, { "Stock Minimo",    {|| InformeStockMinimo() },   NIL, "Alertas de stock" } )

    AAdd( aSistema, { "Salir", {|| __Quit() }, NIL, "Cerrar aplicacion" } )

    AAdd( aMenu, { "Proyecto", NIL, aProyecto, "Ciclo de Presupuestacion" } )
    AAdd( aMenu, { "Maestros", NIL, aMaestros, "Bases de Datos" } )
    AAdd( aMenu, { "Informes", NIL, aInformes, "Impresion y Salidas" } )
    AAdd( aMenu, { "Sistema",  NIL, aSistema,  "Configuracion" } )

RETURN aMenu


STATIC FUNCTION _DrywallLimpiar()

    IF !MsgYesNo( "Borrar todos los datos del presupuesto actual?", "Nuevo Proyecto" )
        RETURN NIL
    ENDIF

    GrabaPres()

RETURN NIL
