/*==============================================================================
   Menu.Prg
   Demostración de menú jerárquico con TMenu / TMenuPop
   Estilo: construcción por ramas con AAdd() — más legible que arrays literales
==============================================================================*/

FUNCTION Main()

   LOCAL aMenu

   /* Fondo gris clásico Windows para toda la aplicación */
   SetColor( "N/W" )
   CLS

   aMenu := DefinirMenu()

   TMenu():New( aMenu, 0 ):Run()

RETURN NIL


/*------------------------------------------------------------------------------
   DefinirMenu
   Construye la estructura jerárquica del menú por ramas.
   Cada item tiene la forma { cTitulo, bAccion, aSubMenu/NIL, cAyuda }
------------------------------------------------------------------------------*/
STATIC FUNCTION DefinirMenu()

   LOCAL aMenu      := {}
   LOCAL aArchivo   := {}
   LOCAL aExportar  := {}
   LOCAL aImprimir  := {}
   LOCAL aEdicion   := {}
   LOCAL aBuscar    := {}
   LOCAL aVer       := {}
   LOCAL aZoom      := {}
   LOCAL aClientes  := {}
   LOCAL aInformes  := {}
   LOCAL aHerram    := {}
   LOCAL aOpciones  := {}
   LOCAL aRed       := {}
   LOCAL aAyuda     := {}

   /*--- SUBMENÚ EXPORTAR (2º nivel) ---*/
   AAdd( aExportar, { "PDF",         {|| MsgInfo("Exportar a PDF")   }, NIL, "Formato PDF" } )
   AAdd( aExportar, { "Excel",       {|| MsgInfo("Exportar a Excel") }, NIL, "Hoja Excel" } )
   AAdd( aExportar, { "Word",        {|| MsgInfo("Exportar a Word")  }, NIL, "Documento Word" } )
   AAdd( aExportar, { "Texto plano", {|| MsgInfo("Exportar TXT")     }, NIL, "Archivo de texto" } )

   /*--- SUBMENÚ IMPRIMIR (2º nivel) ---*/
   AAdd( aImprimir, { "Vista previa", {|| MsgInfo("Vista previa")  }, NIL, "Previsualizar" } )
   AAdd( aImprimir, { "Imprimir",     {|| MsgInfo("Imprimiendo...")}, NIL, "Enviar a impresora" } )
   AAdd( aImprimir, { "Configurar",   {|| MsgInfo("Config impr.")  }, NIL, "Configurar impresora" } )

   /*--- RAMA ARCHIVO ---*/
   AAdd( aArchivo, { "Nuevo",        {|| MsgInfo("Nuevo archivo")  }, NIL,       "Crear un nuevo archivo" } )
   AAdd( aArchivo, { "Abrir",        {|| MsgInfo("Abrir archivo")  }, NIL,       "Abrir archivo existente" } )
   AAdd( aArchivo, { "Guardar",      {|| MsgInfo("Guardar")        }, NIL,       "Guardar cambios" } )
   AAdd( aArchivo, { "Guardar como", {|| MsgInfo("Guardar como")   }, NIL,       "Guardar con otro nombre" } )
   AAdd( aArchivo, { "-------------",NIL,                            NIL,       "" } )
   AAdd( aArchivo, { "Exportar",     NIL,                            aExportar, "Exportar archivo" } )
   AAdd( aArchivo, { "Imprimir",     NIL,                            aImprimir, "Opciones de impresión" } )
   AAdd( aArchivo, { "-------------",NIL,                            NIL,       "" } )
   AAdd( aArchivo, { "Salir",        {|| MsgInfo("Cerrando...")    }, NIL,       "Salir del programa" } )

   /*--- SUBMENÚ BUSCAR (2º nivel) ---*/
   AAdd( aBuscar, { "Buscar",     {|| MsgInfo("Buscar texto")     }, NIL, "Buscar en el documento" } )
   AAdd( aBuscar, { "Reemplazar", {|| MsgInfo("Buscar y reempl.") }, NIL, "Buscar y reemplazar" } )
   AAdd( aBuscar, { "Ir a línea", {|| MsgInfo("Ir a línea...")    }, NIL, "Saltar a número de línea" } )

   /*--- RAMA EDICIÓN ---*/
   AAdd( aEdicion, { "Deshacer", {|| MsgInfo("Deshacer") }, NIL,     "Deshacer última acción" } )
   AAdd( aEdicion, { "Rehacer",  {|| MsgInfo("Rehacer")  }, NIL,     "Rehacer acción" } )
   AAdd( aEdicion, { "---------",NIL,                       NIL,     "" } )
   AAdd( aEdicion, { "Cortar",   {|| MsgInfo("Cortar")   }, NIL,     "Cortar al portapapeles" } )
   AAdd( aEdicion, { "Copiar",   {|| MsgInfo("Copiar")   }, NIL,     "Copiar al portapapeles" } )
   AAdd( aEdicion, { "Pegar",    {|| MsgInfo("Pegar")    }, NIL,     "Pegar del portapapeles" } )
   AAdd( aEdicion, { "---------",NIL,                       NIL,     "" } )
   AAdd( aEdicion, { "Buscar",   NIL,                       aBuscar, "Opciones de búsqueda" } )

   /*--- SUBMENÚ ZOOM (2º nivel) ---*/
   AAdd( aZoom, { "Aumentar", {|| MsgInfo("Zoom +")      }, NIL, "Aumentar zoom" } )
   AAdd( aZoom, { "Reducir",  {|| MsgInfo("Zoom -")      }, NIL, "Reducir zoom" } )
   AAdd( aZoom, { "100%",     {|| MsgInfo("Zoom 100%")   }, NIL, "Tamaño real" } )
   AAdd( aZoom, { "Ajustar",  {|| MsgInfo("Zoom ajuste") }, NIL, "Ajustar a ventana" } )

   /*--- RAMA VER ---*/
   AAdd( aVer, { "Zoom",              NIL,                          aZoom, "Nivel de zoom" } )
   AAdd( aVer, { "Barra estado",      {|| MsgInfo("Toggle estado")},NIL,   "Mostrar/ocultar barra" } )
   AAdd( aVer, { "Pantalla completa", {|| MsgInfo("F. Screen")    },NIL,   "Modo pantalla completa" } )

   /*--- SUBMENÚ INFORMES (2º nivel) ---*/
   AAdd( aInformes, { "Por provincia", {|| MsgInfo("Rep.provincia") }, NIL, "Informe provincial" } )
   AAdd( aInformes, { "Por ventas",    {|| MsgInfo("Rep.ventas")    }, NIL, "Ranking ventas" } )
   AAdd( aInformes, { "Morosos",       {|| MsgInfo("Rep.morosos")   }, NIL, "Clientes con deuda" } )

   /*--- RAMA CLIENTES ---*/
   AAdd( aClientes, { "Nuevo cliente", {|| MsgInfo("Alta cliente")   }, NIL,       "Alta de cliente" } )
   AAdd( aClientes, { "Buscar",        {|| MsgInfo("Buscar cliente") }, NIL,       "Buscar cliente" } )
   AAdd( aClientes, { "Listado",       {|| MsgInfo("Listado")        }, NIL,       "Listar clientes" } )
   AAdd( aClientes, { "-------------", NIL,                             NIL,       "" } )
   AAdd( aClientes, { "Informes",      NIL,                             aInformes, "Informes de clientes" } )

   /*--- SUBMENÚ RED (3er nivel, dentro de Opciones) ---*/
   AAdd( aRed, { "Proxy",   {|| MsgInfo("Config. proxy")   }, NIL, "Servidor proxy" } )
   AAdd( aRed, { "Puertos", {|| MsgInfo("Config. puertos") }, NIL, "Puertos TCP/IP" } )

   /*--- SUBMENÚ OPCIONES (2º nivel) ---*/
   AAdd( aOpciones, { "General",    {|| MsgInfo("Opc.General")    }, NIL,  "Opciones generales" } )
   AAdd( aOpciones, { "Apariencia", {|| MsgInfo("Opc.Apariencia") }, NIL,  "Colores y fuentes" } )
   AAdd( aOpciones, { "Red",        NIL,                             aRed, "Configuración de red" } )

   /*--- RAMA HERRAMIENTAS ---*/
   AAdd( aHerram, { "Calculadora", {|| MsgInfo("Calculadora") }, NIL,       "Abrir calculadora" } )
   AAdd( aHerram, { "Calendario",  {|| MsgInfo("Calendario")  }, NIL,       "Ver calendario" } )
   AAdd( aHerram, { "-----------", NIL,                          NIL,       "" } )
   AAdd( aHerram, { "Opciones",    NIL,                          aOpciones, "Configuración" } )

   /*--- RAMA AYUDA ---*/
   AAdd( aAyuda, { "Índice",       {|| MsgInfo("Índice ayuda") }, NIL, "Índice de ayuda" } )
   AAdd( aAyuda, { "Buscar ayuda", {|| MsgInfo("Buscar ayuda") }, NIL, "Buscar en ayuda" } )
   AAdd( aAyuda, { "Acerca de...", {|| MsgInfo("OopMenu v1.0") }, NIL, "Información programa" } )

   /*--- ENSAMBLADO FINAL DE LA BARRA ---*/
   AAdd( aMenu, { "Archivo",      NIL,             aArchivo,  "Operaciones de archivo" } )
   AAdd( aMenu, { "Edición",      NIL,             aEdicion,  "Editar documento" } )
   AAdd( aMenu, { "Ver",          NIL,             aVer,      "Opciones de vista" } )
   AAdd( aMenu, { "Clientes",     NIL,             aClientes, "Gestión de clientes" } )
   AAdd( aMenu, { "Herramientas", NIL,             aHerram,   "Herramientas auxiliares" } )
   AAdd( aMenu, { "Ayuda",        NIL,             aAyuda,    "Ayuda del programa" } )
   AAdd( aMenu, { "Salir",        {|| NIL },       NIL,       "Salir del programa" } )

RETURN aMenu
