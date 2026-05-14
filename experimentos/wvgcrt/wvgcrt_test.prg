/*
 * EXPERIMENTO: WvgCrt + GfxStack — Ventanas nativas multi-GT
 *
 * Demuestra cómo crear un HWND real independiente usando WvgCrt
 * mientras la ventana principal sigue usando GfxStack (TWindow).
 *
 * Compilar: hbmk2 wvgcrt_test.hbp
 */

#include "hbgtinfo.ch"
#include "hbclass.ch"
#include "inkey.ch"
#include "OOp.ch"

REQUEST DBFCDX

FUNCTION Main()

    LOCAL oWin, nKey
    LOCAL pGtMain, pGtChild

    rddSetDefault( "DBFCDX" )

    // --- Inicializar GT principal (WVG) ---
    hb_gtReload( "WVG" )
    SetMode( 40, 132 )
    GfxSetFont( "Lucida Console", 16, 8 )
    GfxFixSize( .T. )
    SetColor( "N/W" )
    CLS
    GfxCursor( SC_NONE )

    pGtMain := hb_gtSelect()  // GT actual

    // --- Ventana principal con GfxStack ---
    oWin := TWindow():New( 2, 2, 35, 128, "VENTANA PRINCIPAL (GfxStack)" )

    oWin:AddCtrl( TLabel():New( 2, 3, "Esta es la ventana principal del framework GfxStack.", oWin ) )
    oWin:AddCtrl( TLabel():New( 4, 3, "Presiona F2 para abrir una ventana nativa WvgCrt.", oWin ) )
    oWin:AddCtrl( TLabel():New( 6, 3, "Presiona ESC para cerrar.", oWin ) )

    oWin:AddCtrl( TButton():New( 10, 10, 11, 30, oWin, "ABRIR WvgCrt (F2)", ;
        {|| _TestWvgCrt( pGtMain ) } ) )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _TestWvgCrt( pGtMain )

    LOCAL pGtChild
    LOCAL nKey
    LOCAL nRow := 0, nCol := 0

    // --- Crear un GT independiente (WVG) ---
    // hb_gtCreate() devuelve el handle del nuevo GT
    pGtChild := hb_gtCreate( "WVG" )

    // --- Configurar el GT hijo desde el GT principal ---
    hb_gtSelect( pGtChild )
    hb_gtInfo( HB_GTI_WINTITLE, "Ventana Nativa GT independiente" )
    hb_gtInfo( HB_GTI_FONTNAME, "Lucida Console" )
    hb_gtInfo( HB_GTI_FONTWIDTH, 9 )
    hb_gtInfo( HB_GTI_FONTHEIGHT, 16 )
    hb_gtInfo( HB_GTI_ISGRAPHIC, .T. )
    SetMode( 20, 60 )
    SetColor( "N/W" )
    CLS

    // --- Bucle de eventos del GT hijo ---
    DO WHILE .T.
        @ 1, 2 SAY "VENTANA NATIVA (GT independiente)" COLOR "W+/B"
        @ 3, 2 SAY "Handle GT hijo: " + hb_ValToStr( pGtChild ) COLOR "N/W"
        @ 5, 2 SAY "Handle GT padre: " + hb_ValToStr( pGtMain )  COLOR "N/W"
        @ 8, 2 SAY "Fila: " + Str( nRow, 3 ) + "  Col: " + Str( nCol, 3 )
        @ 10, 2 SAY "[ESC] Cerrar   [Flechas] mover   [F2] Volver a principal"
        @ 12, 2 SAY "Cada GT = su propio HWND + buffer + cola de teclas"

        nKey := Inkey( 0 )  // Solo escucha teclas de ESTE GT

        DO CASE
        CASE nKey == K_ESC
            EXIT
        CASE nKey == K_UP
            nRow := Max( 0, nRow - 1 )
        CASE nKey == K_DOWN
            nRow++
        CASE nKey == K_LEFT
            nCol := Max( 0, nCol - 1 )
        CASE nKey == K_RIGHT
            nCol++
        CASE nKey == K_F2
            // Volvemos al principal — el GT hijo sigue vivo
            EXIT
        ENDCASE
    ENDDO

    // --- Volver al GT principal ---
    // El GT hijo se destruye automaticamente al salir del STATIC
    hb_gtSelect( pGtMain )

RETURN NIL
