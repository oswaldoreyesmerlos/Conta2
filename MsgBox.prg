#include "OOp.ch"

// ============================================================================
// FUNCION: MsgBox
// ----------------------------------------------------------------------------
// Dialogo modal construido con las clases del framework:
//
//    TWindow + TLabel + TButton
//
// Ventajas:
//   - Reutiliza controles reales de la libreria
//   - Misma apariencia que el resto del sistema
//   - Mismo sistema de foco y teclado
//   - Facil evolucion futura (Yes/No, Retry, etc.)
//
// Devuelve:
//   K_ENTER al cerrar con boton ACEPTAR
//
// Uso:
//   MsgBox( "Proceso terminado", "Informacion" )
// ============================================================================
FUNCTION MsgBox( cMsg, cTit )

    LOCAL oWin
    LOCAL oLbl
    LOCAL oBtn

    LOCAL nMsgLen
    LOCAL nWidth
    LOCAL nHeight

    LOCAL nTop
    LOCAL nLeft

    LOCAL nRet := K_ENTER

    // ------------------------------------------------------------------------
    // Valores por defecto
    // ------------------------------------------------------------------------
    hb_Default( @cTit, "Mensaje" )
    hb_Default( @cMsg, "" )

    // ------------------------------------------------------------------------
    // Calcular dimensiones del dialogo
    // ------------------------------------------------------------------------
    nMsgLen := Len( AllTrim( cMsg ) )

    nWidth  := Max( 30, nMsgLen + 8 )
    nWidth  := Min( nWidth, GfxMaxCol() - 4 )

    nHeight := 8

    // ------------------------------------------------------------------------
    // Centrado en pantalla
    // ------------------------------------------------------------------------
    nTop  := Int( ( GfxMaxRow() - nHeight ) / 2 )
    nLeft := Int( ( GfxMaxCol() - nWidth  ) / 2 )

    // ------------------------------------------------------------------------
    // Crear ventana modal
    // ------------------------------------------------------------------------
    oWin := TWindow():New( ;
        nTop, ;
        nLeft, ;
        nTop + nHeight, ;
        nLeft + nWidth, ;
        cTit )

    // ------------------------------------------------------------------------
    // Etiqueta del mensaje
    // ------------------------------------------------------------------------
    oLbl := TLabel():New( ;
        2, ;
        3, ;
        PadR( cMsg, nWidth - 6 ), ;
        oWin )

    // ------------------------------------------------------------------------
    // Boton aceptar
    // ------------------------------------------------------------------------
    oBtn := TButton():New( ;
        5, ;
        Int( ( nWidth - 14 ) / 2 ), ;
        7, ;
        Int( ( nWidth - 14 ) / 2 ) + 13, ;
        oWin, ;
        "ACEPTAR", ;
        { || oWin:Close() } )

    // ------------------------------------------------------------------------
    // Registrar controles
    // ------------------------------------------------------------------------
    oWin:AddCtrl( oLbl )
    oWin:AddCtrl( oBtn )

    // ------------------------------------------------------------------------
    // Ejecutar dialogo modal
    // ------------------------------------------------------------------------
    oWin:Run()

RETURN nRet


// ============================================================================
// FUNCION: MsgInfo
// ----------------------------------------------------------------------------
// Wrapper informativo
// ============================================================================
FUNCTION MsgInfo( cMsg, cTit )

    hb_Default( @cTit, "Informacion" )

RETURN MsgBox( cMsg, "INFO: " + cTit )


// ============================================================================
// FUNCION: MsgStop
// ----------------------------------------------------------------------------
// Wrapper de alerta / error
// ============================================================================
FUNCTION MsgStop( cMsg, cTit )

    hb_Default( @cTit, "Error" )

RETURN MsgBox( cMsg, "ALERTA: " + cTit )