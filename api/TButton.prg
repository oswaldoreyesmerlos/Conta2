#include "OOp.ch"

// ============================================================================
// CLASE: TButton
// ----------------------------------------------------------------------------
// Boton pulsable con foco propio.  Se enfoca con TAB; ENTER o SPACE lo
// activan ejecutando ::bAction.  Apariencia con relieve raised normal y
// recessed cuando esta enfocado o pulsado (efecto de "hundimiento" al click).
// ============================================================================
//
// CONTRATO DEL CONSTRUCTOR ::New
// ==============================
// Aunque la firma admite cuatro coordenadas (nTop, nLeft, nBottom, nRight)
// por COHERENCIA con el resto de controles del framework (TWindow, TGrid,
// TCombo, etc.), el boton tiene restricciones propias que se aplican
// silenciosamente:
//
//   1) ALTURA FIJA = 1 FILA
//      El valor de nBottom que pase el llamador SE IGNORA y se reemplaza
//      internamente por nTop.  Visualmente un boton siempre ocupa una
//      unica fila.  Pasar nBottom != nTop NO produce error, pero el boton
//      se pinta como si nBottom == nTop.
//
//   2) ANCHO MINIMO = 10 COLUMNAS
//      Si (nRight - nLeft + 1) < 10, nRight se ajusta automaticamente a
//      nLeft + 9.  Asi captions cortos ("OK", "SI", "NO", "Si") quedan
//      legibles con suficiente margen lateral.
//
//   3) CAPTION CENTRADO
//      ::cCaption se centra horizontalmente con PadC sobre el ancho final
//      (despues del ajuste de minimo).  Si el texto excede el ancho, se
//      recorta sin aviso.
//
// EJEMPLOS DE USO
//
//   // Boton ancho explicito (16 columnas: 5..20)
//   TButton():New( 25, 5, 25, 20, oWin, "GUARDAR", { || ::Save() } )
//
//   // Boton corto: nRight da igual, se fuerza el minimo de 10
//   TButton():New( 25, 5, 25, 5,  oWin, "OK",      { || oWin:Close() } )
//   //                       ^^                       (queda 5..14)
//
//   // Boton con nBottom != nTop: el segundo se ignora, no rompe nada
//   TButton():New( 25, 5, 28, 20, oWin, "PROBAR",  { || Probar() } )
//   //                    ^^                          (se trata como 25)
//
// ============================================================================

CLASS TButton FROM TControl

    DATA cCaption
    DATA bAction
    DATA lPressed
    DATA lSkipValid

    METHOD New()
    METHOD Paint()
    METHOD Click()
    METHOD HandleKey()

ENDCLASS


METHOD New( nTop, nLeft, nBottom, nRight, oPar, cCap, bAct ) CLASS TButton

    LOCAL nMinWidth := 10
    LOCAL nWidth

    // Regla 1 del contrato: el boton SIEMPRE ocupa una sola fila.
    // Aunque nBottom venga del llamador, lo forzamos a nTop.
    // (Ver "CONTRATO DEL CONSTRUCTOR" en cabecera de este archivo.)
    nBottom := nTop

    // Regla 2 del contrato: ancho minimo 10 columnas para que captions
    // cortos como "OK", "SI", "NO" queden con aire visual suficiente.
    nWidth := nRight - nLeft + 1
    IF nWidth < nMinWidth
        nRight := nLeft + nMinWidth - 1
    ENDIF

    ::TControl:New( nTop, nLeft, nBottom, nRight, oPar )

    ::cCaption := cCap
    ::bAction  := bAct
    ::lPressed := .F.
    ::lSkipValid := .F.
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
        cCol := CLR_BUTTON
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

    GfxCursor( SC_NONE )

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
        EvalSafe( ::bAction, "TButton:" + ::cCaption, Self )
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
