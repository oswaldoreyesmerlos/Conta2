// ============================================================================
// MINI-TEST: TestSolid.prg - VERSION 4
// ----------------------------------------------------------------------------
// PROPOSITO
//   Reproducir el caso real "ventana madre con relieves + ventana hija con
//   relieves" para entender el comportamiento de capas en GTWVG.
//
// FASES (con tecla entre cada una)
//
//   FASE 1: pantalla base ("madre")
//     - Marco grande raised (4..18, 5..70).
//     - Dentro: 2 cajas recessed peque;as (simulan TGets) + 2 cajas
//       raised peque;as (simulan TButtons).
//     - Texto en cada caja.
//
//   FASE 2: aplicamos wvg_ShadedRect SOLO (sin pintar nada despues)
//     - Bloque azul cubriendo zona de los 4 relieves peque;os.
//     - Verifica que tapa todo (caracteres y relieves) -> confirmado.
//
//   FASE 3: pintamos relieves NUEVOS encima del ShadedRect
//     - 2 nuevas cajas (1 raised + 1 recessed) DENTRO del area azul.
//     - Texto encima.
//     - Verifica si:
//        a) Los nuevos relieves se ven (estan en la capa grafica
//           que el ShadedRect ya pinto).
//        b) El texto se ve (esta en la capa de caracteres).
//
// COMPILACION
//   hbmk2 testsolid.hbp
// ============================================================================

#include "inkey.ch"


PROCEDURE Main()

    LOCAL aRGB

    // Inicializacion minima
    Wvt_SetGui( .T. )
    SetMode( 25, 80 )
    SetColor( "N/W" )
    CLS

    Wvt_SetFont( "Lucida Console", 16, 8, 0 )

    // ============================================================
    //  FASE 1: pantalla base ("madre") con relieves variados
    // ============================================================

    SetColor( "N/W" )
    Scroll( 4, 5, 18, 70, 0 )
    Wvt_DrawBoxRaised( 4, 5, 18, 70 )

    DispOutAt(  5, 7, " VENTANA MADRE con relieves variados        ", "W+/B" )

    // Caja recessed 1 (simula TGet) en (7,10) - (8,30)
    Wvt_DrawBoxRecessed( 7, 10, 8, 30 )
    DispOutAt( 7, 12, "Get1: aaaaaaa     ", "N/W" )

    // Caja recessed 2 (simula TGet) en (7,40) - (8,65)
    Wvt_DrawBoxRecessed( 7, 40, 8, 65 )
    DispOutAt( 7, 42, "Get2: bbbbbbb     ", "N/W" )

    // Caja raised 1 (simula TButton) en (10,15) - (11,28)
    Wvt_DrawBoxRaised( 10, 15, 11, 28 )
    DispOutAt( 10, 17, "  Boton 1   ", "N/W" )

    // Caja raised 2 (simula TButton) en (10,40) - (11,53)
    Wvt_DrawBoxRaised( 10, 40, 11, 53 )
    DispOutAt( 10, 42, "  Boton 2   ", "N/W" )

    DispOutAt( 16, 7, " Pulsa tecla -> aplicamos wvg_ShadedRect... ", "N/W" )

    Inkey( 0 )

    // ============================================================
    //  FASE 2: wvg_ShadedRect cubriendo la zona de los 4 relieves
    // ============================================================

    // Color GRIS CLARO (equivalente a "W" de Clipper, fondo de ventana
    // tipico).  Esto simula lo que harian las ventanas modales reales
    // de la libreria, que usan CLR_WINDOW = "N/W".
    aRGB := { 49152, 49152, 49152, 0 }   // Gris claro

    wvg_ShadedRect( 6, 8, 13, 67, NIL, 0, aRGB, aRGB )

    // (no pintamos nada mas, solo el ShadedRect)

    DispOutAt( 16, 7, " Pulsa tecla -> intentamos pintar ENCIMA... ", "N/W" )

    Inkey( 0 )

    // ============================================================
    //  FASE 3: pintamos relieves NUEVOS y caracteres encima
    // ============================================================

    // Caracteres dentro de la zona gris (negro sobre blanco/gris)
    DispOutAt(  7, 11, " CARACTER ENCIMA GRIS    ", "N/W" )
    DispOutAt(  8, 11, " (capa caracteres)       ", "N/W" )

    // Nueva caja raised dentro de la zona gris
    Wvt_DrawBoxRaised( 10, 15, 11, 30 )
    DispOutAt( 10, 17, " RAISED nuevo  ", "N/W" )

    // Nueva caja recessed dentro de la zona gris
    Wvt_DrawBoxRecessed( 10, 40, 11, 55 )
    DispOutAt( 10, 42, " RECESS nuevo  ", "N/W" )

    DispOutAt( 16, 7, " Pulsa tecla para salir...                  ", "N/W" )

    Inkey( 0 )

RETURN
