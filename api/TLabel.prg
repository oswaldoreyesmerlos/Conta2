#include "OOp.ch"

CLASS TLabel FROM TControl

    DATA cCaption

    METHOD New()

    METHOD Paint()

    METHOD SetText()

ENDCLASS


METHOD New( nRow, nCol, cText, oPar ) CLASS TLabel
    LOCAL nLen

    DEFAULT cText TO ""

    nLen := Max( Len( cText ), 1 )

    ::TControl:New( nRow, nCol, nRow, nCol + nLen - 1, oPar )

    ::cCaption := cText

    ::cColor := CLR_WINDOW

    ::lTabStop := .F.

RETURN Self


METHOD Paint() CLASS TLabel

    IF !::lVisible
        RETURN NIL
    ENDIF

    ::Lock()

    ::DrawText( 0, 0, ::cCaption, CLR_WINDOW )

    GfxCursor( SC_NONE )

    ::Unlock()

RETURN NIL


METHOD SetText( cNew ) CLASS TLabel

    DEFAULT cNew TO ""

    ::cCaption := cNew

    ::nRight := ::nLeft + Max( Len( cNew ), 1 ) - 1

    ::Paint()

RETURN Self
