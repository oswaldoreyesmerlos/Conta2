// ============================================================================
// MODULO: Gfx.prg
// ----------------------------------------------------------------------------
//
// PROPOSITO
// =========
// Capa de servicios graficos.  Es el UNICO lugar del proyecto que llama
// directamente a funciones GTWVG (Wvt_*, WvtSetPaint) y a primitivas
// de pantalla Clipper (DispOutAt, DispBox, Scroll, SaveScreen, etc.).
//
// Todo el resto del codigo (clases TControl/TWindow/TGet/..., utilidades,
// formularios) llama EXCLUSIVAMENTE a las funciones Gfx*() de este archivo.
//
// VENTAJA DE ESTA ENCAPSULACION
// =============================
// Si manyana queremos cambiar de GTWVG a otro GT (GTWVT puro, GTSLN para
// Linux, GTCGI para web), basta con reescribir este unico archivo.  El
// resto de la libreria sigue funcionando sin tocar una sola linea.
//
//
// CONTENIDO DEL ARCHIVO (POR BLOQUES)
// ===================================
// 1) Bloqueo / desbloqueo de refresco       (GfxLock / GfxUnlock)
// 2) Pintado basico                          (GfxClear, GfxBox, GfxText)
// 3) Relieves WVG                            (GfxRaised, GfxRecessed, GfxGroup,
//                                             GfxFillSolid, GfxColor2RGB)
// 4) Save / Restore de pantalla              (GfxSave, GfxRestore, GfxInvalidate)
// 5) Cursor y posicion                       (GfxCursor, GfxSetPos)
// 6) Inicializacion de entorno               (GfxSetFont, GfxFixSize, MaxRow/Col)
// 7) Atajos compuestos                       (GfxShadow, GfxPanel, GfxField)
// 8) Stack de bloques de pintado             (GfxPaintPush/Pop/Add/Get/Clear)
//
// ============================================================================

#include "OOp.ch"
#include "hbgtinfo.ch"

// ============================================================================
// 0) TEMA VISUAL
// ----------------------------------------------------------------------------
// Centraliza los colores de la API en tiempo de ejecucion.  Las constantes
// CLR_* de OOp.ch llaman a GfxThemeColor(), de modo que los controles nuevos y
// los repintados toman siempre la paleta activa.
// ============================================================================

STATIC s_cTheme := "CLASICO"


FUNCTION GfxThemeSet( cTheme )

    LOCAL cNew := Upper( AllTrim( hb_CStr( cTheme ) ) )

    IF Empty( cNew )
        cNew := "CLASICO"
    ENDIF

    DO CASE
    CASE cNew == "CLASICO" .OR. cNew == "N/W"
        s_cTheme := "CLASICO"

    CASE cNew == "AZUL" .OR. cNew == "W/B"
        s_cTheme := "AZUL"

    CASE cNew == "CYAN" .OR. cNew == "N/BG"
        s_cTheme := "CYAN"

    OTHERWISE
        s_cTheme := "CLASICO"
    ENDCASE

    SetColor( GfxThemeColor( "WINDOW" ) )

    // Persistir cambio
    GfxThemeSave()

RETURN s_cTheme


FUNCTION GfxThemeLoad()

    LOCAL cFile := hb_DirBase() + "gfx_theme.ini"
    LOCAL cTheme

    IF File( cFile )
        cTheme := Memoread( cFile )
        // Quitar \r, \n y espacios sobrantes
        cTheme := StrTran( cTheme, Chr( 13 ), "" )
        cTheme := StrTran( cTheme, Chr( 10 ), "" )
        cTheme := AllTrim( cTheme )
    ENDIF

    GfxThemeSet( cTheme )

RETURN NIL


FUNCTION GfxThemeSave()

    LOCAL cFile := hb_DirBase() + "gfx_theme.ini"

    // SILENT — si no se puede escribir, no importa
    BEGIN SEQUENCE
        Memowrit( cFile, s_cTheme )
    RECOVER
    END SEQUENCE

RETURN NIL


FUNCTION GfxThemeName()
RETURN s_cTheme


FUNCTION GfxThemeColor( cKey )

    LOCAL cK := Upper( AllTrim( hb_CStr( cKey ) ) )
    LOCAL cRet := "N/W"

    DO CASE
    CASE s_cTheme == "AZUL"
        DO CASE
        CASE cK == "FOCUS"        ; cRet := "N/W+"
        CASE cK == "WINDOW"       ; cRet := "W/B"
        CASE cK == "GET"          ; cRet := "W+/B"
        CASE cK == "GET_FOC"      ; cRet := "N/W+"
        CASE cK == "BUTTON"       ; cRet := "W/B"
        CASE cK == "BUTTON_FOC"   ; cRet := "N/W+"
        CASE cK == "WIN_TITLE_ACT"; cRet := "W+/N"
        CASE cK == "WIN_TITLE_INA"; cRet := "W/N"
        CASE cK == "GRID_HDR"     ; cRet := "W+/N"
        CASE cK == "GRID_SEL"     ; cRet := "N/W+"
        CASE cK == "GRID_INA"     ; cRet := "W/BG"
        CASE cK == "MENU"         ; cRet := "W/B"
        CASE cK == "MENU_SEL"     ; cRet := "N/W+"
        CASE cK == "MENU_MSG"     ; cRet := "W/B"
        ENDCASE

    CASE s_cTheme == "CYAN"
        DO CASE
        CASE cK == "FOCUS"        ; cRet := "W+/N"
        CASE cK == "WINDOW"       ; cRet := "N/BG"
        CASE cK == "GET"          ; cRet := "N/BG"
        CASE cK == "GET_FOC"      ; cRet := "W+/N"
        CASE cK == "BUTTON"       ; cRet := "N/BG"
        CASE cK == "BUTTON_FOC"   ; cRet := "W+/N"
        CASE cK == "WIN_TITLE_ACT"; cRet := "W+/B"
        CASE cK == "WIN_TITLE_INA"; cRet := "W+/N"
        CASE cK == "GRID_HDR"     ; cRet := "W+/B"
        CASE cK == "GRID_SEL"     ; cRet := "W+/N"
        CASE cK == "GRID_INA"     ; cRet := "N/W"
        CASE cK == "MENU"         ; cRet := "N/BG"
        CASE cK == "MENU_SEL"     ; cRet := "W+/N"
        CASE cK == "MENU_MSG"     ; cRet := "N/BG"
        ENDCASE

    OTHERWISE
        DO CASE
        CASE cK == "FOCUS"        ; cRet := "W+/BG"
        CASE cK == "WINDOW"       ; cRet := "N/W"
        CASE cK == "GET"          ; cRet := "N/W*"
        CASE cK == "GET_FOC"      ; cRet := "W+/BG"
        CASE cK == "BUTTON"       ; cRet := "N/W"
        CASE cK == "BUTTON_FOC"   ; cRet := "W+/BG"
        CASE cK == "WIN_TITLE_ACT"; cRet := "W+/B"
        CASE cK == "WIN_TITLE_INA"; cRet := "W+/N"
        CASE cK == "GRID_HDR"     ; cRet := "W+/B"
        CASE cK == "GRID_SEL"     ; cRet := "W+/BG"
        CASE cK == "GRID_INA"     ; cRet := "N/BG"
        CASE cK == "MENU"         ; cRet := "N/W"
        CASE cK == "MENU_SEL"     ; cRet := "W+/B"
        CASE cK == "MENU_MSG"     ; cRet := "N/W"
        ENDCASE
    ENDCASE

RETURN cRet


// ============================================================================
// 1) BLOQUEO Y DESBLOQUEO DE REFRESCO
// ----------------------------------------------------------------------------
// Cuando hacemos VARIAS operaciones de pintado seguidas (limpiar, dibujar
// borde, escribir titulo, pintar hijos...), conviene que GTWVG NO refresque
// la ventana entre cada operacion: produciria parpadeo y operaciones
// intermedias visibles ("vi un instante el fondo gris antes del marco").
//
// La solucion es agrupar todas las operaciones entre Lock/Unlock.  GTWVG
// acumula los cambios y los pinta de una sola vez al hacer Unlock.
//
// IMPORTANTE: cada Lock debe tener su Unlock correspondiente.  Si un error
// rompe el flujo entre ambos, la ventana queda "congelada".
// ============================================================================

FUNCTION GfxLock()
    hb_gtLock()
RETURN NIL


FUNCTION GfxUnlock()
    hb_gtUnlock()
RETURN NIL



// ============================================================================
// 2) PINTADO BASICO DE CARACTERES
// ----------------------------------------------------------------------------
// Estas funciones operan en la "capa de caracteres" (la matriz fila x columna
// que hereda Clipper).  No tocan la capa grafica WVG (relieves).
//
// Las coordenadas son siempre fila/columna en base 0 (fila 0 = primera fila
// de la pantalla, columna 0 = primera columna).
// ============================================================================


// ----------------------------------------------------------------------------
// GfxClear( nT, nL, nB, nR, cColor )
// Limpia un rectangulo de la pantalla rellenandolo con espacios del color
// indicado.  Equivale al SCROLL clasico de Clipper con desplazamiento 0.
// ----------------------------------------------------------------------------
FUNCTION GfxClear( nT, nL, nB, nR, cColor )

    DEFAULT cColor TO CLR_WINDOW

    Scroll( nT, nL, nB, nR, 0, cColor )

RETURN NIL


// ----------------------------------------------------------------------------
// GfxBox( nT, nL, nB, nR, cColor )
// Dibuja un borde sencillo de un solo trazo (caracteres ASCII) alrededor
// del rectangulo indicado.  Util cuando NO queremos relieve grafico WVG
// sino solo un marco de caracteres tipo Clipper clasico.
// ----------------------------------------------------------------------------
FUNCTION GfxBox( nT, nL, nB, nR, cColor )

    DEFAULT cColor TO CLR_WINDOW

    DispBox( nT, nL, nB, nR, 0, cColor )

RETURN NIL


// ----------------------------------------------------------------------------
// GfxText( nRow, nCol, cTxt, cColor )
// Escribe un texto en una posicion de pantalla con un color determinado.
// Es la unica forma "permitida" de pintar texto desde fuera de Gfx.prg.
// ----------------------------------------------------------------------------
FUNCTION GfxText( nRow, nCol, cTxt, cColor )

    DEFAULT cColor TO CLR_WINDOW

    DispOutAt( nRow, nCol, cTxt, cColor )

RETURN NIL



// ============================================================================
// 3) RELIEVES DE LA CAPA GRAFICA WVG
// ----------------------------------------------------------------------------
// Estas funciones pintan en la CAPA GRAFICA de WVG (no en la matriz de
// caracteres).  WVG dibuja lineas finas de pixel entre las celdas de
// caracteres para crear ilusion 3D: hundido (Recessed), levantado (Raised),
// agrupacion (Group).
//
// PARTICULARIDAD CRITICA
// ======================
// Una vez pintados, los relieves NO se borran con SaveScreen / RestScreen
// clasicos NI con Wvt_SaveScreen / Wvt_RestScreen.  Es una limitacion
// confirmada por el propio Pritpal Bedi (autor de GTWVG) en el grupo de
// Harbour Users.
//
// Por eso hemos implementado al final de este archivo el "stack de bloques
// de pintado" que es la SOLUCION OFICIAL para gestionar relieves modales.
//
// Las funciones de esta seccion siguen siendo utiles para llamadas puntuales
// y son llamadas internamente desde los codeblocks que se registran en el
// stack (ver seccion 8).
// ============================================================================


// ----------------------------------------------------------------------------
// GfxRaised( nT, nL, nB, nR )
// Cuadro con efecto de relieve hacia AFUERA.  Ejemplos de uso:
//   - Marco de una ventana completa.
//   - Boton sin pulsar (sobresale).
//   - Panel "tapa" sobre una zona.
// ----------------------------------------------------------------------------
FUNCTION GfxRaised( nT, nL, nB, nR )
    Wvt_DrawBoxRaised( nT, nL, nB, nR )
RETURN NIL


// ----------------------------------------------------------------------------
// GfxRecessed( nT, nL, nB, nR )
// Cuadro con efecto de relieve hacia ADENTRO.  Ejemplos de uso:
//   - Campo de entrada (Get).
//   - Lista desplegable de un Combo.
//   - Boton pulsado (en el momento del click).
// ----------------------------------------------------------------------------
FUNCTION GfxRecessed( nT, nL, nB, nR )
    Wvt_DrawBoxRecessed( nT, nL, nB, nR )
RETURN NIL


// ----------------------------------------------------------------------------
// GfxGroup( nT, nL, nB, nR )
// Cuadro de agrupacion: linea fina sin relieve marcado.  Util para
// separar grupos visualmente sin destacar:
//   - "Datos personales" / "Datos profesionales".
//   - "Filtros" / "Resultados".
// ----------------------------------------------------------------------------
FUNCTION GfxGroup( nT, nL, nB, nR )
    Wvt_DrawBoxGroup( nT, nL, nB, nR )
RETURN NIL


// ----------------------------------------------------------------------------
// GfxFillSolid( nT, nL, nB, nR, cColor )
// ----------------------------------------------------------------------------
// PROPOSITO
//   Rellena la capa grafica WVG de un rectangulo con un color SOLIDO,
//   sobreescribiendo cualquier relieve (Raised/Recessed/Group) que
//   hubiera previamente en esa zona.
//
// USO TIPICO
//   Cuando una ventana modal se abre encima de otra ventana que tiene
//   relieves WVG en su interior (botones, gets, etc.), la nueva ventana
//   llama a Scroll/GfxClear para tapar los CARACTERES, pero los relieves
//   WVG anteriores SIGUEN VISIBLES porque viven en una capa separada.
//
//   GfxFillSolid actua como un "escudo opaco" que limpia esa capa
//   grafica antes de pintar los relieves propios de la ventana modal.
//
// IMPLEMENTACION
//   Internamente usa wvg_ShadedRect (funcion oficial GTWVG segun
//   gtwvg.hbx).  Es una funcion nativa, NO depende de Win32.
//
//   Firma de wvg_ShadedRect:
//     wvg_ShadedRect( nT, nL, nB, nR, aOffset, nGradient, aRGBb, aRGBe )
//       aOffset   : { dT, dL, dB, dR } ajuste fino en pixeles, NIL = 0
//       nGradient : 0 = sin gradiente (color solido)
//       aRGBb     : color inicial { R, G, B, A } valores 0-65535
//       aRGBe     : color final (igual; si == aRGBb -> color solido)
//
// PARAMETROS
//   nT, nL, nB, nR : coordenadas del rectangulo en filas/columnas.
//   cColor         : color en notacion Clipper, p.ej. "N/W" o "W+/B".
//                    Solo se usa el color de FONDO (lo que hay tras "/").
//                    Si se omite, se usa CLR_WINDOW.
//
// EJEMPLOS
//   GfxFillSolid( 5, 10, 15, 50 )                  // fondo blanco N/W
//   GfxFillSolid( 5, 10, 15, 50, "W+/B" )          // azul Clipper
//   GfxFillSolid( 5, 10, 15, 50, CLR_GET_FOC )     // cian foco
// ----------------------------------------------------------------------------
FUNCTION GfxFillSolid( nT, nL, nB, nR, cColor )

    LOCAL aRGB

    DEFAULT cColor TO CLR_WINDOW

    aRGB := GfxColor2RGB( cColor )

    wvg_ShadedRect( nT, nL, nB, nR, NIL, 0, aRGB, aRGB )

RETURN NIL



// ----------------------------------------------------------------------------
// GfxColor2RGB( cColor )
// ----------------------------------------------------------------------------
// PROPOSITO
//   Convierte un color en notacion Clipper ("N/W", "W+/B", etc.) a un
//   array RGB { R, G, B, A } compatible con wvg_ShadedRect.
//
//   Solo se considera el color de FONDO (lo que va tras la "/").  El
//   color de tinta (delante de la "/") se ignora porque GfxFillSolid
//   no pinta texto, solo el fondo.
//
//   Los valores RGBA estan en rango 0-65535 (formato GTWVG, no 0-255).
//
// COLORES CLIPPER ESTANDAR
//   Letra | Nombre        | RGB (0-65535)
//   ------|---------------|----------------------
//    N    | Negro         | { 0, 0, 0 }
//    B    | Azul          | { 0, 0, 32768 }
//    G    | Verde         | { 0, 32768, 0 }
//    BG   | Cian          | { 0, 32768, 32768 }
//    R    | Rojo          | { 32768, 0, 0 }
//    RB   | Magenta       | { 32768, 0, 32768 }
//    GR   | Marron/Amar.  | { 32768, 32768, 0 }
//    W    | Blanco        | { 49152, 49152, 49152 }     <- gris claro
//    N+   | Gris          | { 32768, 32768, 32768 }
//    B+   | Azul intenso  | { 0, 0, 65535 }
//    G+   | Verde intenso | { 0, 65535, 0 }
//    BG+  | Cian intenso  | { 0, 65535, 65535 }
//    R+   | Rojo intenso  | { 65535, 0, 0 }
//    RB+  | Magenta int.  | { 65535, 0, 65535 }
//    GR+  | Amarillo      | { 65535, 65535, 0 }
//    W+   | Blanco brillo | { 65535, 65535, 65535 }
//
// PARAMETROS
//   cColor : string Clipper, p.ej. "N/W*", "W+/BG", "GR+/N"...
//
// DEVUELVE
//   Array RGB { R, G, B, A } donde A=0 (alfa opaco).  Si el color es
//   desconocido, devuelve blanco.
// ----------------------------------------------------------------------------
FUNCTION GfxColor2RGB( cColor )

    LOCAL cBack
    LOCAL nSlash

    DEFAULT cColor TO CLR_WINDOW

    // Extraer el color de FONDO (tras la "/")
    nSlash := At( "/", cColor )

    IF nSlash == 0
        cBack := AllTrim( cColor )                  // sin "/" : todo es fondo
    ELSE
        cBack := AllTrim( SubStr( cColor, nSlash + 1 ) )
    ENDIF

    // Quitar marca de parpadeo "*" si existe
    cBack := StrTran( cBack, "*", "" )
    cBack := Upper( cBack )

    // Tabla de equivalencias
    DO CASE
    CASE cBack == "N"     ; RETURN { 0,     0,     0,     0 }
    CASE cBack == "B"     ; RETURN { 0,     0,     32768, 0 }
    CASE cBack == "G"     ; RETURN { 0,     32768, 0,     0 }
    CASE cBack == "BG"    ; RETURN { 0,     32768, 32768, 0 }
    CASE cBack == "R"     ; RETURN { 32768, 0,     0,     0 }
    CASE cBack == "RB"    ; RETURN { 32768, 0,     32768, 0 }
    CASE cBack == "GR"    ; RETURN { 32768, 32768, 0,     0 }
    CASE cBack == "W"     ; RETURN { 49152, 49152, 49152, 0 }
    CASE cBack == "N+"    ; RETURN { 32768, 32768, 32768, 0 }
    CASE cBack == "B+"    ; RETURN { 0,     0,     65535, 0 }
    CASE cBack == "G+"    ; RETURN { 0,     65535, 0,     0 }
    CASE cBack == "BG+"   ; RETURN { 0,     65535, 65535, 0 }
    CASE cBack == "R+"    ; RETURN { 65535, 0,     0,     0 }
    CASE cBack == "RB+"   ; RETURN { 65535, 0,     65535, 0 }
    CASE cBack == "GR+"   ; RETURN { 65535, 65535, 0,     0 }
    CASE cBack == "W+"    ; RETURN { 65535, 65535, 65535, 0 }
    ENDCASE

    // Color desconocido -> blanco por defecto
RETURN { 49152, 49152, 49152, 0 }



// ============================================================================
// 4) SAVE / RESTORE DE PANTALLA
// ----------------------------------------------------------------------------
// IMPORTANTE: en GTWVG, Wvt_SaveScreen / Wvt_RestScreen SOLO preservan
// caracteres y atributos de color.  NO preservan la capa grafica WVG
// (relieves).  Por eso tras un Restore puede quedar el rastro gris de un
// relieve que pintamos antes.
//
// Para gestionar relieves modales, NO usar estas funciones: usar el stack
// de bloques de pintado (seccion 8).
//
// Estas funciones siguen siendo utiles para guardar zonas de PANTALLA DE
// CARACTERES (un fondo de menu por ejemplo) cuando NO hay relieves WVG
// implicados.
// ============================================================================


// ----------------------------------------------------------------------------
// GfxSave( nT, nL, nB, nR )
// Guarda el contenido actual de un rectangulo de pantalla y devuelve un
// handle (en realidad un array de bytes) para poder restaurarlo despues.
// ----------------------------------------------------------------------------
FUNCTION GfxSave( nT, nL, nB, nR )
RETURN Wvt_SaveScreen( nT, nL, nB, nR )


// ----------------------------------------------------------------------------
// GfxRestore( nT, nL, nB, nR, xData )
// Restaura un rectangulo de pantalla con los datos que devolvio GfxSave.
// ----------------------------------------------------------------------------
FUNCTION GfxRestore( nT, nL, nB, nR, xData )
    Wvt_RestScreen( nT, nL, nB, nR, xData )
RETURN NIL


// ----------------------------------------------------------------------------
// GfxInvalidate( nT, nL, nB, nR )
// Marca un rectangulo como "sucio" para forzar a WVG a redibujarlo en el
// proximo refresco.  No borra contenido, solo invalida el cache de pintado.
// Util para "despertar" zonas que se han quedado con artefactos.
// ----------------------------------------------------------------------------
FUNCTION GfxInvalidate( nT, nL, nB, nR )
    Wvt_InvalidateRect( nT, nL, nB, nR )
RETURN NIL



// ============================================================================
// 5) CURSOR Y POSICION
// ----------------------------------------------------------------------------
// Politica unificada del cursor en esta libreria: solo se muestra cuando
// estamos editando dentro de un TGet con foco.  En cualquier otro momento
// (botones, labels, msgboxes, listas desplegadas) se mantiene apagado.
// ============================================================================


// ----------------------------------------------------------------------------
// GfxCursor( nMode )
// Cambia la visibilidad del cursor.
//   nMode = SC_NONE   -> cursor invisible
//   nMode = SC_NORMAL -> cursor visible (subrayado parpadeante)
// ----------------------------------------------------------------------------
FUNCTION GfxCursor( nMode )
    SetCursor( nMode )
RETURN NIL


// ----------------------------------------------------------------------------
// GfxSetPos( nRow, nCol )
// Coloca el cursor en una posicion concreta.  Solo tiene efecto visible
// si el cursor esta encendido (GfxCursor( SC_NORMAL )).
// ----------------------------------------------------------------------------
FUNCTION GfxSetPos( nRow, nCol )
    SetPos( nRow, nCol )
RETURN NIL



// ============================================================================
// 6) INICIALIZACION DE ENTORNO
// ----------------------------------------------------------------------------
// Estas funciones se llaman habitualmente UNA SOLA VEZ desde InitApp().
// ============================================================================


// ----------------------------------------------------------------------------
// GfxSetFont( cName, nHeight, nWidth )
// Establece la fuente de la consola WVG.  Debe ser una fuente monoespaciada
// (todos los caracteres del mismo ancho).  El cuarto parametro de Wvt_SetFont
// es el "weight" (0 = normal); lo dejamos fijo para simplicidad.
// ----------------------------------------------------------------------------
FUNCTION GfxSetFont( cName, nHeight, nWidth )
    Wvt_SetFont( cName, nHeight, nWidth, 0 )
RETURN NIL


// ----------------------------------------------------------------------------
// GfxFixSize( lFix )
// Bloquea o permite el redimensionamiento de la ventana del SO por parte
// del usuario.  Normalmente lFix = .T. para apps de gestion (tamano fijo
// 40x132), de modo que el usuario no pueda romper el layout arrastrando
// el borde.
// ----------------------------------------------------------------------------
FUNCTION GfxFixSize( lFix )

    DEFAULT lFix TO .T.

    Wvt_SetGui( lFix )

RETURN NIL


// ----------------------------------------------------------------------------
// GfxMaxRow / GfxMaxCol
// Numero de filas y columnas actuales de la pantalla.  Con SetMode(40,132)
// devolvera 39 y 131 respectivamente (base 0).
// ----------------------------------------------------------------------------
FUNCTION GfxMaxRow()
RETURN MaxRow()


FUNCTION GfxMaxCol()
RETURN MaxCol()



// ============================================================================
// 7) ATAJOS COMPUESTOS
// ----------------------------------------------------------------------------
// Combinaciones frecuentes de las primitivas anteriores.  No son
// estrictamente necesarias pero ahorran codigo en los lugares donde
// se usan a menudo (TWindow, TGet).
// ============================================================================


// ----------------------------------------------------------------------------
// GfxShadow( nT, nL, nB, nR )
// Pinta una sombra negra a la derecha y debajo del rectangulo indicado.
// Da efecto de "profundidad" tipo Norton Commander / Lotus 1-2-3.
// ----------------------------------------------------------------------------
FUNCTION GfxShadow( nT, nL, nB, nR )

    LOCAL n

    // Sombra vertical: una columna a la derecha, desde nT+1 hasta nB+1
    FOR n := nT + 1 TO nB + 1
        DispOutAt( n, nR + 1, " ", "N/N+" )
    NEXT

    // Sombra horizontal: una fila debajo, desde nL+1 hasta nR+1
    DispOutAt( nB + 1, nL + 1, Replicate( " ", nR - nL + 1 ), "N/N+" )

RETURN NIL


// ----------------------------------------------------------------------------
// GfxPanel( nT, nL, nB, nR, cColor )
// Atajo: limpiar un rectangulo + pintar relieve raised alrededor.
// Es lo que define visualmente "un area sobresaliente" como una ventana.
// ----------------------------------------------------------------------------
FUNCTION GfxPanel( nT, nL, nB, nR, cColor )

    DEFAULT cColor TO CLR_WINDOW

    GfxClear(  nT, nL, nB, nR, cColor )
    GfxRaised( nT, nL, nB, nR )

RETURN NIL


// ----------------------------------------------------------------------------
// GfxField( nT, nL, nB, nR, cColor )
// Atajo: limpiar un rectangulo + pintar relieve recessed alrededor.
// Es lo que define visualmente "un area hundida" como un campo Get.
// ----------------------------------------------------------------------------
FUNCTION GfxField( nT, nL, nB, nR, cColor )

    DEFAULT cColor TO CLR_GET

    GfxClear(    nT, nL, nB, nR, cColor )
    GfxRecessed( nT, nL, nB, nR )

RETURN NIL



// ############################################################################
// ############################################################################
// ##                                                                        ##
// ##  7b) CONFIGURACION DE LA VENTANA DEL SO (titulo, icono, portapapeles)  ##
// ##                                                                        ##
// ##  Estas funciones encapsulan hb_gtInfo() para no depender directamente  ##
// ##  de las constantes HB_GTI_* en el resto del codigo.  hb_gtInfo() es    ##
// ##  la API portable de Harbour para configurar el GT activo (sea WVG,    ##
// ##  WIN, STD, etc).  Cada GT implementa lo que puede.                     ##
// ##                                                                        ##
// ############################################################################
// ############################################################################


// ----------------------------------------------------------------------------
// GfxSetTitle( cTitle )
// Cambia el titulo de la ventana de la app.  Util para mostrar nombre del
// usuario, base de datos activa, etc.  Ejemplo:
//   GfxSetTitle( "AppGestion - Usuario: Juan" )
// ----------------------------------------------------------------------------
FUNCTION GfxSetTitle( cTitle )

    DEFAULT cTitle TO ""

    hb_gtInfo( HB_GTI_WINTITLE, cTitle )

RETURN NIL



// ----------------------------------------------------------------------------
// GfxGetTitle()
// Devuelve el titulo actual de la ventana de la app.
// ----------------------------------------------------------------------------
FUNCTION GfxGetTitle()
RETURN hb_gtInfo( HB_GTI_WINTITLE )



// ----------------------------------------------------------------------------
// GfxSetIcon( cFile )
// Carga un icono externo (archivo .ico) para la ventana de la app.
// Si el archivo no existe, no pasa nada (no rompe).
//
// Para usar un icono incrustado en el .exe (recomendado para distribucion),
// usa GfxSetIconRes() con el ID del recurso.
// ----------------------------------------------------------------------------
FUNCTION GfxSetIcon( cFile )

    DEFAULT cFile TO ""

    IF File( cFile )
        hb_gtInfo( HB_GTI_ICONFILE, cFile )
    ENDIF

RETURN NIL



// ----------------------------------------------------------------------------
// GfxSetIconRes( nResID )
// Asigna como icono de la ventana un recurso compilado dentro del propio
// .exe.  Para esto hay que linkear un .res que contenga el icono.
//
//   1. Crear icono.ico
//   2. Crear icono.rc con linea:   100 ICON "icono.ico"
//   3. Compilar:                   windres icono.rc -o icono.res
//   4. En el .hbp anyadir:         icono.res
//   5. En el codigo:               GfxSetIconRes( 100 )
// ----------------------------------------------------------------------------
FUNCTION GfxSetIconRes( nResID )

    DEFAULT nResID TO 0

    IF nResID > 0
        hb_gtInfo( HB_GTI_ICONRES, nResID )
    ENDIF

RETURN NIL



// ----------------------------------------------------------------------------
// GfxClipboardGet()
// Devuelve el texto actualmente en el portapapeles del SO.  Si no hay
// texto, devuelve "".
// ----------------------------------------------------------------------------
FUNCTION GfxClipboardGet()

    LOCAL cText := hb_gtInfo( HB_GTI_CLIPBOARDDATA )

    DEFAULT cText TO ""

RETURN cText



// ----------------------------------------------------------------------------
// GfxClipboardSet( cText )
// Coloca un texto en el portapapeles del SO.  Util para "Copiar" en
// formularios, exportar listados, etc.
// ----------------------------------------------------------------------------
FUNCTION GfxClipboardSet( cText )

    DEFAULT cText TO ""

    hb_gtInfo( HB_GTI_CLIPBOARDDATA, cText )

RETURN NIL



// ----------------------------------------------------------------------------
// GfxSetClosable( lAllow )
// Habilita o deshabilita el boton X de la ventana de la app.  Util en
// modo kiosko o durante operaciones criticas (no queremos que el usuario
// cierre la app a media transaccion).
// ----------------------------------------------------------------------------
FUNCTION GfxSetClosable( lAllow )

    DEFAULT lAllow TO .T.

    hb_gtInfo( HB_GTI_CLOSABLE, lAllow )

RETURN NIL



// ############################################################################
// ############################################################################
// ##                                                                        ##
// ##  8) STACK DE BLOQUES DE PINTADO (modelo oficial GTWVG)                 ##
// ##                                                                        ##
// ##     Modelo HIBRIDO en uso:                                             ##
// ##                                                                        ##
// ##     1) GfxPaintPush/Pop mantienen un stack de bloques que GTWVG        ##
// ##        re-ejecuta automaticamente cuando el SO manda eventos           ##
// ##        WM_PAINT (resize, restore desde minimizado, etc).               ##
// ##                                                                        ##
// ##     2) GfxSave/GfxRestore con margen amplio (PADWIN=2 en TWindow)      ##
// ##        capturan/restauran el contenido EXACTO de la zona, incluida     ##
// ##        la capa grafica WVG.  Esto es lo que borra los relieves de la   ##
// ##        ventana hija al cerrarla.                                       ##
// ##                                                                        ##
// ##     Las dos cosas se combinan en TWindow:Run:                          ##
// ##                                                                        ##
// ##        aPrev := GfxPaintPush()                  // (1)                 ##
// ##        ::xBackup := GfxSave( nT-2, nL-2, ;                             ##
// ##                              nB+2, nR+2 )       // (2)                 ##
// ##        ::Paint()                                                       ##
// ##        ... loop ...                                                    ##
// ##        GfxRestore( nT-2, nL-2, nB+2, nR+2, ;                           ##
// ##                    ::xBackup )                  // (2)                 ##
// ##        GfxPaintPop( aPrev )                     // (1)                 ##
// ##                                                                        ##
// ############################################################################
// ############################################################################
//
//
// COMO CAPTURAN VARIABLES LOS CODEBLOCKS
// ======================================
// En Harbour, un codeblock {|| ... } captura las variables locales del
// metodo o funcion donde se define.  Para que un bloque registrado en el
// stack siga siendo valido despues de que su funcion termine, conviene
// que las variables que use sean DATA del propio objeto (no LOCAL):
//
//   METHOD Paint() CLASS TWindow
//      LOCAL Self_ := Self    // referencia explicita a Self
//      GfxPaintAdd( "marco", ;
//                   {|| GfxRaised( Self_:nTop, Self_:nLeft, ;
//                                  Self_:nBottom, Self_:nRight ) } )
//   RETURN NIL
//
// Realmente Harbour gestiona Self correctamente en codeblocks de metodo,
// pero ser explicito con Self_ ayuda a entender que esta pasando.
// ############################################################################



// ----------------------------------------------------------------------------
// GfxPaintPush( aNuevos )
// ----------------------------------------------------------------------------
// Empila el array de bloques de pintado actual y empieza un nivel nuevo.
//
// PARAMETROS
//   aNuevos : array de elementos { cNombre, bBlock, aRect } que se
//             activara para este nivel.  Si se omite, empieza vacio.
//
// DEVUELVE
//   El array que estaba activo antes de la llamada.  El llamador DEBE
//   guardar este valor en una variable LOCAL y pasarlo despues a
//   GfxPaintPop para cerrar correctamente el nivel.
// ----------------------------------------------------------------------------
FUNCTION GfxPaintPush( aNuevos )

    DEFAULT aNuevos TO {}

RETURN WvtSetPaint( aNuevos )



// ----------------------------------------------------------------------------
// GfxPaintPop( aPrev )
// ----------------------------------------------------------------------------
// Cierra el nivel actual restaurando el array de bloques que estaba
// activo antes del Push correspondiente.
//
// PARAMETROS
//   aPrev : el array que devolvio GfxPaintPush.
// ----------------------------------------------------------------------------
FUNCTION GfxPaintPop( aPrev )

    DEFAULT aPrev TO {}

    WvtSetPaint( aPrev )

RETURN NIL



// ----------------------------------------------------------------------------
// GfxPaintAdd( cName, bBlock, aRect )
// ----------------------------------------------------------------------------
// Agrega un bloque de pintado al array activo y lo ejecuta de inmediato
// para reflejo visual instantaneo.
//
// PARAMETROS
//   cName  : nombre identificador del bloque (string, opcional).
//   bBlock : codeblock sin parametros que encapsula UNA operacion grafica.
//   aRect  : array opcional con rectangulo cubierto (NIL en la mayoria
//            de casos).
// ----------------------------------------------------------------------------
FUNCTION GfxPaintAdd( cName, bBlock, aRect )

    LOCAL aActual

    DEFAULT cName TO ""

    // 1. Consultar el array activo (sin args devuelve sin modificar)
    aActual := WvtSetPaint()

    IF !HB_ISARRAY( aActual )
        aActual := {}
    ENDIF

    // 2. Agregar el nuevo bloque con la estructura oficial GTWVG
    AAdd( aActual, { cName, bBlock, aRect } )

    // 3. Reinstalar para que GTWVG vea el bloque nuevo en repintados
    WvtSetPaint( aActual )

    // 4. Ejecutar AHORA mismo para reflejo visual instantaneo
    Eval( bBlock )

RETURN NIL



// ----------------------------------------------------------------------------
// GfxPaintGet()
// Devuelve el array activo (sin modificarlo).  Util para depuracion.
// ----------------------------------------------------------------------------
FUNCTION GfxPaintGet()
RETURN WvtSetPaint()



// ----------------------------------------------------------------------------
// GfxPaintClear()
// Vacia el array de bloques del nivel actual SIN desempilar.
// ----------------------------------------------------------------------------
FUNCTION GfxPaintClear()

    WvtSetPaint( {} )

RETURN NIL


// ============================================================================
// FIN DEL MODULO Gfx.prg
// ============================================================================
