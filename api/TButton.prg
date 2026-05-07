#include "OOp.ch"

CLASS TButton FROM TControl

    DATA cCaption
    DATA bAction
    DATA lPressed

    METHOD New()

    METHOD Paint()

    METHOD Click()

    METHOD HandleKey()

ENDCLASS


METHOD New( nTop, nLeft, nBottom, nRight, oPar, cCap, bAct ) CLASS TButton

    LOCAL nMinWidth := 10
    LOCAL nWidth

    // Boton SIEMPRE de una sola fila
    nBottom := nTop

    // Mejor aspecto para captions cortos: SI, NO, OK, etc.
    nWidth := nRight - nLeft + 1

    IF nWidth < nMinWidth
        nRight := nLeft + nMinWidth - 1
    ENDIF

    ::TControl:New( nTop, nLeft, nBottom, nRight, oPar )

    ::cCaption := cCap
    ::bAction  := bAct
    ::lPressed := .F.

    ::cColor   := CLR_BUTTON
    ::lTabStop := .T.

RETURN Self


METHOD Paint() CLASS TButton

    LOCAL cCol
    LOCAL nWidth
    LOCAL cText

    IF !::lVisible
        RETURN NIL
    ENDIF

    // Garantia: el boton se pinta siempre en una sola fila
    ::nBottom := ::nTop

    nWidth := ::nRight - ::nLeft + 1

    DO CASE
    CASE ::lPressed
        cCol := __SwapColor( CLR_BUT_FOC )

    CASE ::lFocused
        cCol := CLR_BUT_FOC

    OTHERWISE
        cCol := ::cColor
    ENDCASE

    ::Lock()

    IF ::lPressed .OR. ::lFocused
        ::DrawRecessed()
    ELSE
        ::DrawRaised()
    ENDIF

    // Caption centrado horizontalmente.
    // Verticalmente queda centrado porque el boton mide una sola fila.
    cText := PadC( AllTrim( ::cCaption ), nWidth )

    GfxText( ::nTop, ::nLeft, cText, cCol )

    IF ::lFocused
        GfxCursor( SC_NONE )
    ENDIF

    ::Unlock()

RETURN NIL


METHOD Click() CLASS TButton

    IF !::lVisible .OR. !::lEnabled
        RETURN NIL
    ENDIF

    ::lPressed := .T.
    ::Paint()

    Inkey(0.05)

    IF ::bAction != NIL
        Eval( ::bAction, Self )
    ENDIF

    ::lPressed := .F.
    ::Paint()

RETURN Self


METHOD HandleKey( nKey ) CLASS TButton

    IF !::lVisible .OR. !::lEnabled
        RETURN .F.
    ENDIF

    IF nKey == K_ENTER .OR. nKey == K_SPACE
        ::Click()
        RETURN .T.
    ENDIF

RETURN .F.


// ----------------------------------------------------------------------------
// FUNCION ESTATICA: __SwapColor
// Invierte tinta/fondo de un atributo "F/B" (color Clipper)
// Ejemplo: "W+/N" -> "N/W+"   "GR+/B" -> "B/GR+"
// Usada para producir el flash visual al pulsar un boton.
// ----------------------------------------------------------------------------
STATIC FUNCTION __SwapColor( cClr )
    LOCAL nPos
    LOCAL cFG, cBG

    nPos := At( "/", cClr )
    IF nPos == 0
        RETURN cClr     // sin "/" no podemos invertir, devolvemos tal cual
    ENDIF

    cFG := SubStr( cClr, 1, nPos - 1 )
    cBG := SubStr( cClr, nPos + 1 )

RETURN cBG + "/" + cFG