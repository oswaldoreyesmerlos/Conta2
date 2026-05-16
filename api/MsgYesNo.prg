#include "OOp.ch"

STATIC s_lMsgYesNoActive := .F.

// ============================================================================
// FUNCION: MsgYesNo
// ----------------------------------------------------------------------------
// Caja de confirmacion modal construida con:
//
//    TWindow + TLabel + TButton
//
// Devuelve:
//    .T. = Si
//    .F. = No / ESC
// ============================================================================
FUNCTION MsgYesNo( cMsg, cTit )

    LOCAL oWin
    LOCAL oLbl
    LOCAL oBtnSi
    LOCAL oBtnNo

    LOCAL nMsgLen
    LOCAL nWidth
    LOCAL nHeight
    LOCAL nTop
    LOCAL nLeft

    LOCAL lResp := .F.

    hb_Default( @cTit, "Confirmacion" )
    hb_Default( @cMsg, "" )

    IF s_lMsgYesNoActive
        CLEAR TYPEAHEAD
        RETURN lResp
    ENDIF

    s_lMsgYesNoActive := .T.
    CLEAR TYPEAHEAD

    nMsgLen := Len( AllTrim( cMsg ) )

    nWidth  := Max( 36, Max( nMsgLen + 8, Len( cTit ) + 12 ) )
    nWidth  := Min( nWidth, GfxMaxCol() - 4 )

    nHeight := 8

    nTop  := Int( ( GfxMaxRow() - nHeight ) / 2 )
    nLeft := Int( ( GfxMaxCol() - nWidth  ) / 2 )

    oWin := TWindow():New( ;
        nTop, ;
        nLeft, ;
        nTop + nHeight, ;
        nLeft + nWidth, ;
        cTit )

    oLbl := TLabel():New( ;
        2, ;
        3, ;
        PadR( cMsg, nWidth - 6 ), ;
        oWin )

    oBtnSi := TButton():New( ;
        5, ;
        Int( ( nWidth - 26 ) / 2 ), ;
        5, ;
        Int( ( nWidth - 26 ) / 2 ) + 11, ;
        oWin, ;
        "SI", ;
        { || lResp := .T., oWin:Close() } )
    oBtnSi:lSkipValid := .T.

    oBtnNo := TButton():New( ;
        5, ;
        Int( ( nWidth - 26 ) / 2 ) + 15, ;
        5, ;
        Int( ( nWidth - 26 ) / 2 ) + 26, ;
        oWin, ;
        "NO", ;
        { || lResp := .F., oWin:Close() } )
    oBtnNo:lSkipValid := .T.

    oWin:AddCtrl( oLbl )
    oWin:AddCtrl( oBtnSi )
    oWin:AddCtrl( oBtnNo )

    oWin:Run()

    CLEAR TYPEAHEAD
    s_lMsgYesNoActive := .F.

RETURN lResp


// ============================================================================
// WRAPPER OPCIONAL
// ============================================================================
FUNCTION MsgConfirm( cMsg, cTit )
RETURN MsgYesNo( cMsg, cTit )
