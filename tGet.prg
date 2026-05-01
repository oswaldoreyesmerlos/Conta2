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

    DATA nLen
    DATA nPos

    DATA bWhen
    DATA bValid

    METHOD New()
    METHOD Paint()

    METHOD SetFocus()
    METHOD KillFocus()

    METHOD Validate()
    METHOD HandleKey()

ENDCLASS


// ----------------------------------------------------------------------------
// Constructor
// ----------------------------------------------------------------------------
METHOD New( nRow, nCol, uValue, cPic, oPar ) CLASS TGet

    ::uVar     := uValue
    ::cPicture := cPic
    ::cType    := ValType( uValue )

    DO CASE

	CASE ! Empty( cPic ) .AND. Left( cPic, 1 ) != "@"
		::nLen := Len( cPic )

	CASE ::cType == "C"
		::nLen := Max( Len( uValue ), 10 )

	CASE ::cType == "N"
		::nLen := 8

	CASE ::cType == "D"
		::nLen := 10

	CASE ::cType == "L"
		::nLen := 3

	OTHERWISE
		::nLen := 10

	ENDCASE

    ::TControl:New( nRow, nCol, nRow, nCol + ::nLen - 1, oPar )

    ::nPos := 1

    ::bWhen  := NIL
    ::bValid := NIL

    ::lTabStop := .T.

    DO CASE
    CASE ::cType == "C"
        ::cBuffer := PadR( hb_CStr( uValue ), ::nLen )

    CASE ::cType == "N"
        ::cBuffer := PadL( LTrim( Str( uValue ) ), ::nLen )

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

    IF ::cType == "N"
        cShow := PadL( AllTrim( ::cBuffer ), ::nLen )
    ELSE
        cShow := PadR( ::cBuffer, ::nLen )
    ENDIF

    ::Lock()

    ::DrawRecessed()
    ::DrawText( 0, 0, cShow, cCol )

    IF ::lFocused
        GfxCursor( SC_NORMAL )
        GfxSetPos( ::nTop, ::nLeft + ::nPos - 1 )
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
        IF ! Eval( ::bWhen, Self )
            RETURN NIL
        ENDIF
    ENDIF

RETURN ::TControl:SetFocus()


// ----------------------------------------------------------------------------
// Salida foco
// ----------------------------------------------------------------------------
METHOD KillFocus() CLASS TGet

    IF ! ::Validate()
        RETURN NIL
    ENDIF

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
        ::uVar := Val( AllTrim( ::cBuffer ) )

    CASE ::cType == "D"
        ::uVar := Ctod( ::cBuffer )

    CASE ::cType == "L"
        ::uVar := ( Upper( Left( AllTrim( ::cBuffer ), 1 ) ) == "S" )
    ENDCASE

    IF ::bValid != NIL
        lOk := Eval( ::bValid, Self )
    ENDIF

RETURN lOk


// ----------------------------------------------------------------------------
// Teclado
// ----------------------------------------------------------------------------
METHOD HandleKey( nKey ) CLASS TGet

    LOCAL cChr

    // Navegación externa
    IF nKey == K_TAB
        IF ! ::Validate()
            RETURN .T.
        ENDIF
        RETURN .F.
    ENDIF

    IF nKey == K_SH_TAB
        IF ! ::Validate()
            RETURN .T.
        ENDIF
        RETURN .F.
    ENDIF

    IF nKey == K_ENTER
        IF ! ::Validate()
            RETURN .T.
        ENDIF
        RETURN .F.
    ENDIF

    IF nKey == K_UP
        IF ! ::Validate()
            RETURN .T.
        ENDIF
        RETURN .F.
    ENDIF

    IF nKey == K_DOWN
        IF ! ::Validate()
            RETURN .T.
        ENDIF
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
        IF ::nPos < ::nLen
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
        ::nPos := ::nLen
        ::Paint()
        RETURN .T.
    ENDIF

    IF nKey == K_BS
        IF ::nPos > 1
            ::nPos--
            ::cBuffer := Stuff( ::cBuffer, ::nPos, 1, " " )
            ::Paint()
        ENDIF
        RETURN .T.
    ENDIF

    IF nKey == K_DEL
        ::cBuffer := Stuff( ::cBuffer, ::nPos, 1, " " )
        ::Paint()
        RETURN .T.
    ENDIF


    // Caracter imprimible
    IF nKey >= 32 .AND. nKey <= 255

        cChr := Chr( nKey )

        IF ::cPicture == "@!"
            cChr := Upper( cChr )
        ENDIF

        IF ::cType == "N" .OR. "9" $ ::cPicture
            IF ! ( cChr $ "0123456789.-" )
                RETURN .T.
            ENDIF
        ENDIF

        IF ::cPicture == "99/99/9999"
            IF ! ( cChr $ "0123456789/" )
                RETURN .T.
            ENDIF
        ENDIF

        ::cBuffer := Stuff( ::cBuffer, ::nPos, 1, cChr )

        IF ::nPos < ::nLen
            ::nPos++
        ENDIF

        ::Paint()

        RETURN .T.
    ENDIF

RETURN .F.