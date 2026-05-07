#ifndef OOP_CH
#define OOP_CH

#include "hbclass.ch"
#include "inkey.ch"
#include "setcurs.ch"

// ============================================================================
// CONSTANTES DE COLOR
// ----------------------------------------------------------------------------
// CLR_FOCUS es el color universal de foco: cualquier control activo
// (Get, Button, Combo, Check, ...) debe pintarse con este color cuando
// tenga el foco.  Los CLR_*_FOC especificos se derivan de el para
// mantener coherencia visual en toda la aplicacion.
//
// Para cambiar el "color de seleccion" en toda la app, basta con
// modificar CLR_FOCUS aqui.
// ============================================================================

// Color universal de foco (control activo)
#define CLR_FOCUS       "W+/BG"      // Blanco brillante sobre Cian

// Colores base
#define CLR_WINDOW      "N/W"        // Negro sobre Blanco (fondo de ventana)
#define CLR_GET         "N/W*"       // Get normal (Gris)
#define CLR_GET_FOC     CLR_FOCUS    // Get con foco
#define CLR_BUTTON      "N/W"        // Boton normal (Negro sobre Blanco)
#define CLR_BUT_FOC     CLR_FOCUS    // Boton con foco

// Macro para conversion RGB a Entero Long
#ifndef RGB
   #define RGB(r,g,b) ( r + ( g * 256 ) + ( b * 65536 ) )
#endif

// ============================================================================
// CONSTANTES PARA TGRID
// ----------------------------------------------------------------------------
// Cada columna del grid es un array con esta estructura:
//   { cTitle, nWidth, cPicture, bGetVal }
// Los indices abajo dan acceso simbolico a cada campo.
// ============================================================================
#define COL_TITLE    1   // Texto de cabecera
#define COL_WIDTH    2   // Ancho en columnas (caracteres)
#define COL_PICTURE  3   // Picture de visualizacion (formato)
#define COL_GETVAL   4   // Codeblock { |aRow| ... } que devuelve el valor

// ============================================================================
// COLORES DE VENTANAS
// ============================================================================
#define CLR_WIN_TITLE_ACT   "W+/B"      // Titulo ventana activa
#define CLR_WIN_TITLE_INA   "W+/N"      // Futuro: titulo ventana inactiva
#define CLR_WIN_BODY        CLR_WINDOW  // Cuerpo ventana



// Color de la cabecera del grid
#define CLR_GRID_HDR    "W+/B"       // Blanco brillante sobre Azul

// Color de la fila SELECCIONADA cuando el grid TIENE el foco.
// Es el color universal de foco (cian).
#define CLR_GRID_SEL    CLR_FOCUS    // Cian (W+/BG)

// Color de la fila SELECCIONADA cuando el grid NO tiene el foco.
// Indica visualmente "aqui esta el cursor pero no soy el control activo".
// Tono mas tenue para no llamar tanto la atencion.
#define CLR_GRID_INA    "N/BG"       // Negro sobre Cian (mas suave)

#define SC_NONE         0
#define SC_NORMAL       1

#command DEFAULT <v> TO <val> => IF <v> == NIL ; <v> := <val> ; ENDIF

#endif