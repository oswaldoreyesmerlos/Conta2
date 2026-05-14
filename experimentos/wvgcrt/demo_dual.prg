/*
 * DEMO: TWindow vs TWvgCrtWindow
 *
 * Muestra ambas ventanas una al lado de la otra para comparar:
 *   - TWindow: pseudo-ventana dibujada sobre el GT compartido
 *   - TWvgCrtWindow: HWND real con GT propio
 */

#include "OOp.ch"
#include "hbgtinfo.ch"
#include "inkey.ch"

REQUEST DBFCDX

FUNCTION Main()

    LOCAL oWinStd, oWinNat
    LOCAL pGtMain

    rddSetDefault( "DBFCDX" )

    // GT principal
    hb_gtReload( "WVG" )
    SetMode( 40, 132 )
    GfxSetFont( "Lucida Console", 16, 8 )
    GfxFixSize( .T. )
    SetColor( "N/W" )
    CLS
    GfxCursor( SC_NONE )

    pGtMain := hb_gtSelect()

    // === Ventana 1: TWindow (pseudo-ventana) ===
    oWinStd := TWindow():New( 2, 2, 16, 64, "TWindow (pseudo)" )
    oWinStd:AddCtrl( TLabel():New( 2, 3, "Ventana clasica GfxStack.", oWinStd ) )
    oWinStd:AddCtrl( TLabel():New( 4, 3, "Se dibuja sobre el GT", oWinStd ) )
    oWinStd:AddCtrl( TLabel():New( 5, 3, "compartido. No es un", oWinStd ) )
    oWinStd:AddCtrl( TLabel():New( 6, 3, "HWND independiente.", oWinStd ) )
    oWinStd:AddCtrl( TLabel():New( 8, 3, "ESC para cerrar", oWinStd ) )

    // === Ventana 2: TWvgCrtWindow (nativa) ===
    oWinNat := TWvgCrtWindow():New( 2, 66, 16, 128, "TWvgCrtWindow (nativa)" )
    oWinNat:AddCtrl( TLabel():New( 2, 3, "Ventana nativa con GT propio.", oWinNat ) )
    oWinNat:AddCtrl( TLabel():New( 4, 3, "Creada via hb_gtCreate(WVG).", oWinNat ) )
    oWinNat:AddCtrl( TLabel():New( 5, 3, "Tiene su propio HWND y buffer.", oWinNat ) )
    oWinNat:AddCtrl( TLabel():New( 6, 3, "Independiente, movible.", oWinNat ) )
    oWinNat:AddCtrl( TLabel():New( 8, 3, "ESC para cerrar", oWinNat ) )

    // === Ejecutar ambas ===
    oWinStd:Run()
    oWinNat:Run()

    CLS
    @ 18, 2 SAY "Ambas ventanas cerradas. Demo finalizada." COLOR "W+/B"
    @ 20, 2 SAY "Presiona ESC para salir..."
    Inkey( 0 )

RETURN NIL
