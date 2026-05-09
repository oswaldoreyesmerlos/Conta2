#include "OOp.ch"

// ============================================================================
// CLASE: TCheck
// ----------------------------------------------------------------------------
// Caja de verificacion para opciones booleanas.
// Apariencia clasica:
//   [ ] Texto descriptivo    (sin marcar)
//   [X] Texto descriptivo    (marcada)
//
// El control se enfoca con TAB; ESPACIO o ENTER alternan el estado.
// Al recibir foco, el texto se ve con CLR_GET_FOC.
// ============================================================================
CLASS TCheck FROM TControl

    DATA cCaption       // texto descriptivo a la derecha
    DATA lValue         // estado actual (.T./.F.)
    DATA bChange        // bloque opcional ejecutado al cambiar

    METHOD New()
    METHOD Paint()
    METHOD HandleKey()
    METHOD Toggle()
    METHOD GetValue()
    METHOD SetValue()

ENDCLASS


// ----------------------------------------------------------------------------
// Constructor
// nRow, nCol  : posicion (relativa al parent)
// cText       : texto descriptivo
// lDefault    : valor inicial (.T./.F.), default .F.
// oPar        : ventana contenedora
// ----------------------------------------------------------------------------
METHOD New( nRow, nCol, cText, lDefault, oPar ) CLASS TCheck

    LOCAL nLen

    DEFAULT lDefault TO .F.

    ::cCaption := cText
    ::lValue   := lDefault
    ::bChange  := NIL

    // Anchura total = "[X] " + texto = 4 + Len( cText )
    nLen := 4 + Len( cText )

    ::TControl:New( nRow, nCol, nRow, nCol + nLen - 1, oPar )

    ::cColor   := CLR_WINDOW
    ::lTabStop := .T.

RETURN Self


// ----------------------------------------------------------------------------
// Pintado
// ----------------------------------------------------------------------------
METHOD Paint() CLASS TCheck

    LOCAL cMark
    LOCAL cTxt
    LOCAL cCol

    IF ! ::lVisible
        RETURN NIL
    ENDIF

    cMark := If( ::lValue, "[X] ", "[ ] " )
    cTxt  := cMark + ::cCaption
    cCol  := If( ::lFocused, CLR_GET_FOC, CLR_WINDOW )

    ::Lock()

    ::DrawText( 0, 0, cTxt, cCol )

    // Cursor apagado: no es editable caracter a caracter
    GfxCursor( SC_NONE )

    ::Unlock()

RETURN NIL


// ----------------------------------------------------------------------------
// Alternar estado y notificar cambio
// ----------------------------------------------------------------------------
METHOD Toggle() CLASS TCheck

    ::lValue := ! ::lValue

    IF ::bChange != NIL
        Eval( ::bChange, Self )
    ENDIF

    ::Paint()

RETURN Self


// ----------------------------------------------------------------------------
// Teclado
// ----------------------------------------------------------------------------
METHOD HandleKey( nKey ) CLASS TCheck

    IF !::lVisible .OR. !::lEnabled
        RETURN .F.
    ENDIF

    // Espacio o ENTER alternan
    IF nKey == K_SPACE .OR. nKey == K_ENTER
        ::Toggle()
        RETURN .T.
    ENDIF

RETURN .F.


METHOD GetValue() CLASS TCheck
RETURN ::lValue


METHOD SetValue( lValue ) CLASS TCheck

    ::lValue := ( ValType( lValue ) == "L" .AND. lValue )
    ::Paint()

RETURN Self
