#include "OOp.ch"

CLASS TControl

    DATA nTop
    DATA nLeft
    DATA nBottom
    DATA nRight

    DATA oParent

    DATA lVisible
    DATA lEnabled
    DATA lFocused
    DATA lTabStop

    DATA cColor

    METHOD New()

    METHOD Paint()
    METHOD Refresh()

    METHOD SetFocus()
    METHOD KillFocus()

    METHOD HandleKey()
    METHOD GetValue()
    METHOD SetValue()

    METHOD Show()
    METHOD Hide()

    METHOD Enable()
    METHOD Disable()

    METHOD IsHit()

    METHOD DrawRaised()   INLINE GfxRaised( ::nTop, ::nLeft, ::nBottom, ::nRight )
    METHOD DrawRecessed() INLINE GfxRecessed( ::nTop, ::nLeft, ::nBottom, ::nRight )
    METHOD DrawGroup()    INLINE GfxGroup( ::nTop, ::nLeft, ::nBottom, ::nRight )
    METHOD DrawClear()    INLINE GfxClear( ::nTop, ::nLeft, ::nBottom, ::nRight, ::cColor )
    METHOD DrawBox()      INLINE GfxBox( ::nTop, ::nLeft, ::nBottom, ::nRight, ::cColor )
    METHOD Invalidate()   INLINE GfxInvalidate( ::nTop, ::nLeft, ::nBottom, ::nRight )

    METHOD DrawText()

    METHOD Lock()   INLINE GfxLock()
    METHOD Unlock() INLINE GfxUnlock()

ENDCLASS


METHOD New( nT, nL, nB, nR, oPar ) CLASS TControl
    LOCAL nOffT := 0
    LOCAL nOffL := 0

    ::oParent := oPar

    IF oPar != NIL
        nOffT := oPar:nTop
        nOffL := oPar:nLeft
    ENDIF

    ::nTop    := nT + nOffT
    ::nLeft   := nL + nOffL
    ::nBottom := nB + nOffT
    ::nRight  := nR + nOffL

    ::lVisible := .T.
    ::lEnabled := .T.
    ::lFocused := .F.
    ::lTabStop := .F.

    ::cColor := CLR_WINDOW

RETURN Self


METHOD Paint() CLASS TControl

    IF !::lVisible
        RETURN NIL
    ENDIF

    ::Lock()

    IF ::lFocused
        ::DrawRaised()
    ELSE
        ::DrawGroup()
    ENDIF

    ::Unlock()

RETURN NIL


METHOD Refresh() CLASS TControl
    ::Paint()
RETURN Self


METHOD SetFocus() CLASS TControl

    IF !::lVisible .OR. !::lEnabled
        RETURN NIL
    ENDIF

    ::lFocused := .T.
    ::Paint()

RETURN Self


METHOD KillFocus() CLASS TControl

    ::lFocused := .F.

    IF ::lVisible
        ::Paint()
    ENDIF

RETURN Self


METHOD HandleKey( nKey ) CLASS TControl
    HB_SYMBOL_UNUSED( nKey )
RETURN .F.


METHOD GetValue() CLASS TControl
RETURN NIL


METHOD SetValue( uValue ) CLASS TControl
    HB_SYMBOL_UNUSED( uValue )
RETURN Self


METHOD Show() CLASS TControl
    ::lVisible := .T.
    ::Paint()
RETURN Self


METHOD Hide() CLASS TControl
    ::lVisible := .F.
    ::Invalidate()
RETURN Self


METHOD Enable() CLASS TControl
    ::lEnabled := .T.
RETURN Self


METHOD Disable() CLASS TControl
    ::lEnabled := .F.
RETURN Self


METHOD IsHit( nRow, nCol ) CLASS TControl
RETURN ( nRow >= ::nTop .AND. nRow <= ::nBottom .AND. ;
         nCol >= ::nLeft .AND. nCol <= ::nRight )


METHOD DrawText( nRowRel, nColRel, cTxt, cCol ) CLASS TControl

    DEFAULT nRowRel TO 0
    DEFAULT nColRel TO 0
    DEFAULT cCol    TO ::cColor

    GfxText( ::nTop + nRowRel, ::nLeft + nColRel, cTxt, cCol )

RETURN NIL
