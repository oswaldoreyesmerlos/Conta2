#include "OOp.ch"

// ============================================================================
// FUNCION: MsgYesNo
// ----------------------------------------------------------------------------
// Caja de confirmacion modal.
// Devuelve:
//    .T. = Si
//    .F. = No / ESC
//
// Uso:
//    IF MsgYesNo( "Desea guardar cambios?", "Confirmacion" )
//       ...
//    ENDIF
// ============================================================================
FUNCTION MsgYesNo( cMsg, cTit )

    LOCAL xSave
    LOCAL nT, nL, nB, nR
    LOCAL nAncho
    LOCAL nAlto
    LOCAL nKey
    LOCAL lYes

    hb_Default( @cTit, "Confirmacion" )
    hb_Default( @cMsg, "" )

    lYes := .T.

    // ------------------------------------------------------------------------
    // Calculo de dimensiones
    // ------------------------------------------------------------------------
    nAncho := Min( ;
					Max( Max( Len( cMsg ) + 10, ;
					Len( cTit ) + 12 ), ;
					28 ), ;
					GfxMaxCol() - 4 )

    nAlto := 7

    nT := Int( ( GfxMaxRow() - nAlto ) / 2 )
    nL := Int( ( GfxMaxCol() - nAncho ) / 2 )

    nB := nT + nAlto
    nR := nL + nAncho

    // Guardamos fondo (+margen por sombra)
    xSave := GfxSave( nT, nL, nB + 1, nR + 2 )

    GfxCursor( SC_NONE )

    // ------------------------------------------------------------------------
    // Bucle modal
    // ------------------------------------------------------------------------
    DO WHILE .T.

        GfxLock()

        // Fondo
        GfxShadow( nT, nL, nB, nR )
        GfxClear( nT, nL, nB, nR, CLR_WINDOW )
        GfxRaised( nT, nL, nB, nR )

        // Barra titulo
        GfxClear( nT, nL + 1, nT, nR - 1, "W+/B" )
        GfxText( nT, nL + 2, cTit, "W+/B" )

        // Mensaje
        GfxText( nT + 2, nL + 3, ;
                 PadR( cMsg, nAncho - 5 ), ;
                 CLR_WINDOW )

        // Boton SI
        IF lYes
            GfxRecessed( nB - 2, nL + 6, nB - 2, nL + 13 )
            GfxText( nB - 2, nL + 8, "SI", "W+/B" )
        ELSE
            GfxRaised( nB - 2, nL + 6, nB - 2, nL + 13 )
            GfxText( nB - 2, nL + 8, "SI", CLR_WINDOW )
        ENDIF

        // Boton NO
        IF ! lYes
            GfxRecessed( nB - 2, nR - 13, nB - 2, nR - 6 )
            GfxText( nB - 2, nR - 11, "NO", "W+/B" )
        ELSE
            GfxRaised( nB - 2, nR - 13, nB - 2, nR - 6 )
            GfxText( nB - 2, nR - 11, "NO", CLR_WINDOW )
        ENDIF

        GfxUnlock()

        // --------------------------------------------------------------------
        // Espera tecla
        // --------------------------------------------------------------------
        nKey := Inkey( 0 )

        DO CASE

        CASE nKey == K_LEFT .OR. nKey == K_RIGHT .OR. ;
             nKey == K_TAB  .OR. nKey == K_SH_TAB

            lYes := ! lYes

        CASE nKey == K_ENTER
            EXIT

        CASE nKey == K_ESC
            lYes := .F.
            EXIT

        CASE nKey == Asc("S") .OR. nKey == Asc("s")
            lYes := .T.
            EXIT

        CASE nKey == Asc("N") .OR. nKey == Asc("n")
            lYes := .F.
            EXIT

        ENDCASE

    ENDDO

    // Restaurar pantalla
    GfxRestore( nT, nL, nB + 1, nR + 2, xSave )

    GfxCursor( SC_NONE )

RETURN lYes


// ============================================================================
// WRAPPER OPCIONAL
// ----------------------------------------------------------------------------
// MsgConfirm() alias amigable
// ============================================================================
FUNCTION MsgConfirm( cMsg, cTit )
RETURN MsgYesNo( cMsg, cTit )