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
#define CLR_FOCUS       GfxThemeColor( "FOCUS" )

// Colores base
#define CLR_WINDOW      GfxThemeColor( "WINDOW" )
#define CLR_GET         GfxThemeColor( "GET" )
#define CLR_GET_FOC     GfxThemeColor( "GET_FOC" )
#define CLR_BUTTON      GfxThemeColor( "BUTTON" )
#define CLR_BUT_FOC     GfxThemeColor( "BUTTON_FOC" )

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
#define CLR_WIN_TITLE_ACT   GfxThemeColor( "WIN_TITLE_ACT" )
#define CLR_WIN_TITLE_INA   GfxThemeColor( "WIN_TITLE_INA" )
#define CLR_WIN_STATUS      GfxThemeColor( "WIN_STATUS" )
#define CLR_WIN_BODY        CLR_WINDOW  // Cuerpo ventana



// Color de la cabecera del grid
#define CLR_GRID_HDR    GfxThemeColor( "GRID_HDR" )

// Color de la fila SELECCIONADA cuando el grid TIENE el foco.
// Es el color universal de foco (cian).
#define CLR_GRID_SEL    GfxThemeColor( "GRID_SEL" )

// Color de la fila SELECCIONADA cuando el grid NO tiene el foco.
// Indica visualmente "aqui esta el cursor pero no soy el control activo".
// Tono mas tenue para no llamar tanto la atencion.
#define CLR_GRID_INA    GfxThemeColor( "GRID_INA" )

// Colores de menu
#define CLR_MENU        GfxThemeColor( "MENU" )
#define CLR_MENU_SEL    GfxThemeColor( "MENU_SEL" )
#define CLR_MENU_MSG    GfxThemeColor( "MENU_MSG" )

#define SC_NONE         0
#define SC_NORMAL       1

// ============================================================================
// CONSTANTES DE RATON
// ============================================================================
#define K_MOUSEMOVE      1001
#define K_LBUTTONDOWN    1002
#define K_LBUTTONUP      1003
#define K_RBUTTONDOWN    1004
#define K_RBUTTONUP      1005
#define K_LDBLCLK        1006
#define K_RDBLCLK        1007

#command DEFAULT <v> TO <val> => IF <v> == NIL ; <v> := <val> ; ENDIF

// ============================================================================
// COMANDOS DE TRANSACCION (DBFCDX RDD)
// ----------------------------------------------------------------------------
// Harbour soporta transacciones atomicas via RDD_INFO_API.
// Estos comandos envuelven las llamadas para que el codigo quede mas claro.
// Uso: BEGIN TRANSACTION ... [ROLLBACK] ... END TRANSACTION
// ============================================================================
#ifndef RDDI_TRANSACTION_BEGIN
#define RDDI_TRANSACTION_BEGIN    102
#define RDDI_TRANSACTION_COMMIT   103
#define RDDI_TRANSACTION_ROLLBACK 104
#define HB_TRANSACTION_DBF         1
#endif

#xcommand BEGIN TRANSACTION => RddInfo( RDDI_TRANSACTION_BEGIN, HB_TRANSACTION_DBF )
#xcommand END TRANSACTION => RddInfo( RDDI_TRANSACTION_COMMIT )
#xcommand ROLLBACK => RddInfo( RDDI_TRANSACTION_ROLLBACK )

#endif
