#include "OOp.ch"

// ============================================================================
// CLASE: TGet
// Get inteligente limpio para Harbour clásico
// ============================================================================
CLASS TGet FROM TControl

    DATA uVar
    DATA cBuffer
    DATA cPicture
    DATA cType
    DATA lPassword

    DATA nLen
    DATA nBufLen
    DATA nPos
    DATA nOffset
    DATA lNumFresh

    DATA bWhen
    DATA bValid

    METHOD New()
    METHOD Paint()

    METHOD SetFocus()
    METHOD KillFocus()

    METHOD Validate()
    METHOD HandleKey()
    METHOD GetValue()
    METHOD SetValue()

ENDCLASS


// ----------------------------------------------------------------------------
// Constructor
// ----------------------------------------------------------------------------
METHOD New( nRow, nCol, uValue, cPic, oPar ) CLASS TGet

    LOCAL nScroll

    DEFAULT cPic TO ""

    ::uVar     := uValue
    ::cPicture := cPic
    ::cType    := ValType( uValue )
    ::lPassword := .F.
    nScroll := _TGetScrollLen( cPic )

    DO CASE

	CASE ! Empty( cPic ) .AND. Left( cPic, 1 ) != "@"
		::nLen := Len( cPic )

	CASE ::cType == "C"
		::nLen := Max( Len( uValue ), 10 )
        IF nScroll > 0
            ::nLen := Min( nScroll, ::nLen )
        ENDIF

	CASE ::cType == "N"
		::nLen := 8

	CASE ::cType == "D"
		::nLen := 10

	CASE ::cType == "L"
		::nLen := 3

	OTHERWISE
		::nLen := 10

	ENDCASE

    IF ::cType == "C"
        ::nBufLen := Max( Len( uValue ), ::nLen )
    ELSE
        ::nBufLen := ::nLen
    ENDIF

    ::TControl:New( nRow, nCol, nRow, nCol + ::nLen - 1, oPar )

    ::nPos := 1
    ::nOffset := 0
    ::lNumFresh := .F.

    ::bWhen  := NIL
    ::bValid := NIL

    ::lTabStop := .T.

    DO CASE
    CASE ::cType == "C"
        ::cBuffer := PadR( hb_CStr( uValue ), ::nLen )

    CASE ::cType == "N"
        ::cBuffer := _TGetFormatNum( uValue, ::cPicture, ::nLen )

    CASE ::cType == "D"
        ::cBuffer := DToC( uValue )

    CASE ::cType == "L"
        ::cBuffer := If( uValue, "Si ", "No " )

    OTHERWISE
        ::cBuffer := Space( ::nLen )
    ENDCASE

RETURN Self


// ----------------------------------------------------------------------------
// Pintado
// ----------------------------------------------------------------------------
METHOD Paint() CLASS TGet

    LOCAL cCol
    LOCAL cShow

    IF ! ::lVisible
        RETURN NIL
    ENDIF

    cCol := If( ::lFocused, CLR_GET_FOC, CLR_GET )

    IF ::lPassword
        _TGetFixOffset( Self )
        cShow := PadR( SubStr( PadR( Replicate( "*", Len( RTrim( ::cBuffer ) ) ), ;
                                      ::nBufLen ), ::nOffset + 1, ::nLen ), ::nLen )
    ELSEIF ::cType == "N"
        cShow := PadL( AllTrim( ::cBuffer ), ::nLen )
    ELSEIF ::cType == "C"
        _TGetFixOffset( Self )
        cShow := PadR( SubStr( PadR( ::cBuffer, ::nBufLen ), ;
                               ::nOffset + 1, ::nLen ), ::nLen )
    ELSE
        cShow := PadR( ::cBuffer, ::nLen )
    ENDIF

    ::Lock()

    ::DrawRecessed()
    ::DrawText( 0, 0, cShow, cCol )

    IF ::lFocused
        GfxCursor( SC_NORMAL )
        GfxSetPos( ::nTop, ::nLeft + ::nPos - ::nOffset - 1 )
    ELSE
        GfxCursor( SC_NONE )
    ENDIF

    ::Unlock()

RETURN NIL


// ----------------------------------------------------------------------------
// Entrada foco
// ----------------------------------------------------------------------------
METHOD SetFocus() CLASS TGet

    IF ::bWhen != NIL
        IF EvalSafe( ::bWhen, "TGet:bWhen", Self ) != .T.
            RETURN NIL
        ENDIF
    ENDIF

    IF ::cType == "N"
        ::nPos      := ::nLen
        ::lNumFresh := .T.
    ENDIF

RETURN ::TControl:SetFocus()


// ----------------------------------------------------------------------------
// Salida foco
// ----------------------------------------------------------------------------
METHOD KillFocus() CLASS TGet

    IF ! ::Validate()
        RETURN NIL
    ENDIF

    GfxCursor( SC_NONE )
    ::lNumFresh := .F.

RETURN ::TControl:KillFocus()


// ----------------------------------------------------------------------------
// Validación
// ----------------------------------------------------------------------------
METHOD Validate() CLASS TGet

    LOCAL lOk

    lOk := .T.

    DO CASE
    CASE ::cType == "C"
        ::uVar := RTrim( ::cBuffer )

    CASE ::cType == "N"
        ::uVar    := _TGetValNum( ::cBuffer )
        ::cBuffer := _TGetFormatNum( ::uVar, ::cPicture, ::nLen )
        ::nPos    := ::nLen

    CASE ::cType == "D"
        ::uVar := Ctod( ::cBuffer )

    CASE ::cType == "L"
        ::uVar := ( Upper( Left( AllTrim( ::cBuffer ), 1 ) ) == "S" )
    ENDCASE

    IF ::bValid != NIL
        lOk := EvalSafe( ::bValid, "TGet:bValid", Self ) == .T.
    ENDIF

RETURN lOk


// ----------------------------------------------------------------------------
// Teclado
// ----------------------------------------------------------------------------
METHOD HandleKey( nKey ) CLASS TGet

    LOCAL cChr
    LOCAL cNum

    // Navegación externa
    IF nKey == K_TAB .OR. nKey == K_SH_TAB .OR. ;
       nKey == K_ENTER .OR. nKey == K_UP .OR. nKey == K_DOWN
        RETURN .F.
    ENDIF


    // Lógico
    IF ::cType == "L"

        IF nKey == K_SPACE
            ::uVar := ! ::uVar
            ::cBuffer := If( ::uVar, "Si ", "No " )
            ::Paint()
        ENDIF

        RETURN .T.
    ENDIF


    // Movimiento
    IF nKey == K_LEFT
        IF ::nPos > 1
            ::nPos--
            ::Paint()
        ENDIF
        RETURN .T.
    ENDIF

    IF nKey == K_RIGHT
        IF ::nPos < ::nBufLen
            ::nPos++
            ::Paint()
        ENDIF
        RETURN .T.
    ENDIF

    IF nKey == K_HOME
        ::nPos := 1
        ::Paint()
        RETURN .T.
    ENDIF

    IF nKey == K_END
        ::nPos := ::nBufLen
        ::Paint()
        RETURN .T.
    ENDIF

    IF nKey == K_BS
        IF ::cType == "N"
            cNum := _TGetNumBuffer( ::cBuffer )
            IF Len( cNum ) > 0
                cNum := Left( cNum, Len( cNum ) - 1 )
            ENDIF
            ::cBuffer   := PadL( cNum, ::nLen )
            ::nPos      := ::nLen
            ::lNumFresh := .F.
            ::Paint()
        ELSEIF ::nPos > 1
            ::nPos--
            IF ::cType == "C"
                ::cBuffer := _TGetDeleteAt( ::cBuffer, ::nPos, ::nBufLen )
            ELSE
                ::cBuffer := Stuff( ::cBuffer, ::nPos, 1, " " )
            ENDIF
            ::Paint()
        ENDIF
        RETURN .T.
    ENDIF

    IF nKey == K_DEL
        IF ::cType == "N"
            ::cBuffer   := Space( ::nLen )
            ::nPos      := ::nLen
            ::lNumFresh := .F.
        ELSEIF ::cType == "C"
            ::cBuffer := _TGetDeleteAt( ::cBuffer, ::nPos, ::nBufLen )
        ELSE
            ::cBuffer := Stuff( ::cBuffer, ::nPos, 1, " " )
        ENDIF
        ::Paint()
        RETURN .T.
    ENDIF


    // Caracter imprimible
    IF nKey >= 32 .AND. nKey <= 255

        cChr := Chr( nKey )

        IF "!" $ Upper( ::cPicture )
            cChr := Upper( cChr )
        ENDIF

        DO CASE
        CASE ::cType == "N"
            IF ! ( cChr $ "0123456789.-" )
                RETURN .T.
            ENDIF

        CASE ::cType == "D"
            IF ! ( cChr $ "0123456789/-." )
                RETURN .T.
            ENDIF

        ENDCASE

        IF ::cType == "N"
            cNum := If( ::lNumFresh, "", _TGetNumBuffer( ::cBuffer ) )
            DO CASE
            CASE cChr == "-"
                cNum := If( Left( cNum, 1 ) == "-", SubStr( cNum, 2 ), "-" + cNum )
            CASE cChr == "."
                IF "." $ cNum
                    RETURN .T.
                ENDIF
                cNum += "."
            OTHERWISE
                cNum += cChr
            ENDCASE
            ::cBuffer   := PadL( cNum, ::nLen )
            ::nPos      := ::nLen
            ::lNumFresh := .F.
            ::Paint()
            RETURN .T.
        ENDIF

        ::cBuffer := Stuff( ::cBuffer, ::nPos, 1, cChr )

        IF ::nPos < ::nBufLen
            ::nPos++
        ENDIF

        ::Paint()

        RETURN .T.
    ENDIF

RETURN .F.


METHOD GetValue() CLASS TGet

    ::Validate()

RETURN ::uVar


METHOD SetValue( uValue ) CLASS TGet

    ::uVar  := uValue
    ::cType := ValType( uValue )

    DO CASE
    CASE ::cType == "C"
        ::cBuffer := PadR( hb_CStr( uValue ), ::nBufLen )

    CASE ::cType == "N"
        ::cBuffer := _TGetFormatNum( uValue, ::cPicture, ::nLen )

    CASE ::cType == "D"
        ::cBuffer := DToC( uValue )

    CASE ::cType == "L"
        ::cBuffer := If( uValue, "Si ", "No " )

    OTHERWISE
        ::cBuffer := Space( ::nLen )
    ENDCASE

    ::nPos := Min( ::nPos, ::nBufLen )
    ::nOffset := Min( ::nOffset, Max( 0, ::nBufLen - ::nLen ) )
    ::lNumFresh := .F.
    ::Paint()

RETURN Self


STATIC FUNCTION _TGetFormatNum( nValue, cPicture, nLen )

    LOCAL cText

    IF !Empty( cPicture ) .AND. "9" $ cPicture
        cText := Transform( nValue, cPicture )
    ELSE
        cText := LTrim( Str( nValue ) )
    ENDIF

RETURN PadL( AllTrim( cText ), nLen )


STATIC FUNCTION _TGetValNum( cBuffer )

RETURN Val( StrTran( AllTrim( cBuffer ), ",", "" ) )


STATIC FUNCTION _TGetDeleteAt( cBuffer, nPos, nLen )

    LOCAL cNew

    cNew := Left( cBuffer, nPos - 1 ) + SubStr( cBuffer, nPos + 1 ) + " "

RETURN PadR( Left( cNew, nLen ), nLen )


STATIC FUNCTION _TGetScrollLen( cPicture )

    LOCAL cPic
    LOCAL nAt
    LOCAL nPos
    LOCAL cNum
    LOCAL cChr

    IF ValType( cPicture ) != "C" .OR. Empty( cPicture ) .OR. Left( cPicture, 1 ) != "@"
        RETURN 0
    ENDIF

    cPic := Upper( cPicture )
    nAt  := At( "S", cPic )
    IF nAt == 0
        RETURN 0
    ENDIF

    cNum := ""
    FOR nPos := nAt + 1 TO Len( cPic )
        cChr := SubStr( cPic, nPos, 1 )
        IF !( cChr $ "0123456789" )
            EXIT
        ENDIF
        cNum += cChr
    NEXT

RETURN Val( cNum )


STATIC FUNCTION _TGetFixOffset( oGet )

    IF oGet:cType != "C"
        oGet:nOffset := 0
        RETURN NIL
    ENDIF

    oGet:nPos := Max( 1, Min( oGet:nPos, oGet:nBufLen ) )

    IF oGet:nPos <= oGet:nOffset
        oGet:nOffset := oGet:nPos - 1
    ELSEIF oGet:nPos > oGet:nOffset + oGet:nLen
        oGet:nOffset := oGet:nPos - oGet:nLen
    ENDIF

    oGet:nOffset := Max( 0, Min( oGet:nOffset, oGet:nBufLen - oGet:nLen ) )

RETURN NIL


STATIC FUNCTION _TGetNumBuffer( cBuffer )

    LOCAL cNum := AllTrim( cBuffer )

    cNum := StrTran( cNum, ",", "" )

    IF cNum == "0"
        cNum := ""
    ENDIF

RETURN cNum
