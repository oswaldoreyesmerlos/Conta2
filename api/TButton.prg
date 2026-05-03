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

    ::TControl:New( nTop, nLeft, nBottom, nRight, oPar )

    ::cCaption := cCap
    ::bAction  := bAct

    ::lPressed := .F.

    ::cColor := CLR_BUTTON

    ::lTabStop := .T.

RETURN Self


METHOD Paint() CLASS TButton
    LOCAL cCol
    LOCAL nRow
    LOCAL nWidth
    LOCAL nFila
    LOCAL cFondo

    IF !::lVisible
        RETURN NIL
    ENDIF

    // Anchura TOTAL del boton (de borde a borde, ambos inclusive).
    // El relieve WVG vive en lineas FINAS entre celdas, no ocupa columnas
    // de caracteres, asi que podemos rellenar de nLeft a nRight sin
    // tapar el efecto raised/recessed.
    nWidth := ::nRight - ::nLeft + 1

    // Fila central (para botones de 1 fila queda en nTop)
    nRow := Int( ( ::nBottom - ::nTop ) / 2 )

    // Color del texto:
    //  - Pulsado (flash de click)  -> CLR_BUT_FOC con tinta/fondo INVERTIDOS
    //  - Con foco (sin pulsar)     -> CLR_BUT_FOC normal
    //  - Sin foco                  -> CLR_BUTTON
    DO CASE
    CASE ::lPressed
        cCol := __SwapColor( CLR_BUT_FOC )
    CASE ::lFocused
        cCol := CLR_BUT_FOC
    OTHERWISE
        cCol := ::cColor
    ENDCASE

    ::Lock()

    // ----- Relieve segun estado -----
    IF ::lPressed .OR. ::lFocused
        ::DrawRecessed()
    ELSE
        ::DrawRaised()
    ENDIF

    // ----- Fondo COMPLETO con el color del estado -----
    // Rellena el ancho total. Si el boton tiene mas de una fila, las
    // filas intermedias tambien se rellenan.
    cFondo := Space( nWidth )
    FOR nFila := ::nTop TO ::nBottom
        GfxText( nFila, ::nLeft, cFondo, cCol )
    NEXT

    // ----- Caption centrado en el ancho TOTAL -----
    ::DrawText( nRow, 0, PadC( ::cCaption, nWidth ), cCol )

    // ----- Cursor invisible mientras el boton esta enfocado -----
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