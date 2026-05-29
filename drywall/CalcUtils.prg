FUNCTION _OptionalCode( cCod )

RETURN Empty( AllTrim( cCod ) ) .OR. AllTrim( cCod ) == "0"


FUNCTION _CantidadCompra( cFam, cCod, cUni, nConsumo, cUdTec, nLargo, nAncho, nPesoU )

    LOCAL cF := Upper( AllTrim( hb_CStr( cFam ) ) )
    LOCAL cU := Upper( AllTrim( hb_CStr( cUni ) ) )
    LOCAL cT := Upper( AllTrim( hb_CStr( cUdTec ) ) )
    LOCAL cC := Upper( AllTrim( hb_CStr( cCod ) ) )
    LOCAL nContenido := 0
    LOCAL nAreaPieza := 0

    IF nConsumo == NIL; nConsumo := 0; ENDIF
    IF nLargo   == NIL; nLargo   := 0; ENDIF
    IF nAncho   == NIL; nAncho   := 0; ENDIF
    IF nPesoU   == NIL; nPesoU   := 0; ENDIF

    IF nConsumo <= 0
        RETURN 0
    ENDIF

    DO CASE
    CASE cF == "TORNILLO" .AND. ( cT == "UD" .OR. cU == "CAJA" )
        nContenido := 1000
        RETURN _RoundUp( nConsumo / nContenido )

    CASE cT == "UD"
        RETURN _RoundUp( nConsumo )

    CASE cF == "PERFIL" .AND. cT == "ML"
        nContenido := If( nLargo > 0, nLargo / 1000, 3 )
        RETURN _RoundUp( nConsumo / nContenido )

    CASE cF == "PLACA" .AND. cT == "M2"
        nAreaPieza := ( nLargo / 1000 ) * ( nAncho / 1000 )
        IF nAreaPieza <= 0
            nAreaPieza := 3.00
        ENDIF
        RETURN _RoundUp( nConsumo / nAreaPieza )

    CASE cF == "PASTA" .AND. cT == "KG"
        nContenido := If( nPesoU > 0, nPesoU, 20 )
        RETURN _RoundUp( nConsumo / nContenido )

    CASE cF == "CINTA" .AND. cT == "ML"
        nContenido := If( nLargo > 0, nLargo / 1000, 0 )
        IF nContenido <= 0
            nContenido := If( "50" $ cC, 50, 90 )
        ENDIF
        RETURN _RoundUp( nConsumo / nContenido )

    CASE cF == "ACCESORIO" .AND. cT == "ML" .AND. ;
         ( "BANDA" $ cC .OR. "CINTA" $ cC )
        nContenido := If( nLargo > 0, nLargo / 1000, 30 )
        RETURN _RoundUp( nConsumo / nContenido )

    OTHERWISE
        RETURN nConsumo
    ENDCASE

RETURN nConsumo


FUNCTION _RoundUp( nValue )

    LOCAL nInt

    IF nValue <= 0
        RETURN 0
    ENDIF

    nInt := Int( nValue )
    IF nValue > nInt
        nInt++
    ENDIF

RETURN nInt


FUNCTION _SysAncho( xSistema )

    DO CASE
    CASE ValType( xSistema ) == "N"
        RETURN xSistema
    CASE ValType( xSistema ) == "C"
        RETURN Val( AllTrim( xSistema ) )
    ENDCASE

RETURN 0


FUNCTION _GetAuxTitle( cTipo )

    DO CASE
    CASE cTipo == "PERFIL"   ; RETURN "PERFILES"
    CASE cTipo == "PLACA"    ; RETURN "PLACAS DE YESO"
    CASE cTipo == "AISLAN"   ; RETURN "AISLAMIENTOS"
    CASE cTipo == "ANCLAJE"  ; RETURN "ANCLAJES"
    CASE cTipo == "TORNILLO" ; RETURN "TORNILLERIA"
    CASE cTipo == "PASTA"    ; RETURN "PASTAS"
    CASE cTipo == "CINTA"    ; RETURN "CINTAS"
    CASE cTipo == "ACCESORIO"; RETURN "ACCESORIOS"
    ENDCASE

RETURN cTipo


FUNCTION _InformeTextoLineas( cTexto )

    LOCAL aLineas := {}
    LOCAL nStart  := 1
    LOCAL nPos
    LOCAL cLine

    IF cTexto == NIL; cTexto := ""; ENDIF

    cTexto := StrTran( cTexto, Chr( 13 ) + Chr( 10 ), Chr( 10 ) )
    cTexto := StrTran( cTexto, Chr( 13 ), Chr( 10 ) )

    DO WHILE nStart <= Len( cTexto ) + 1
        nPos := At( Chr( 10 ), SubStr( cTexto, nStart ) )
        IF nPos == 0
            cLine := SubStr( cTexto, nStart )
            AAdd( aLineas, { cLine } )
            EXIT
        ENDIF
        cLine := SubStr( cTexto, nStart, nPos - 1 )
        AAdd( aLineas, { cLine } )
        nStart += nPos
    ENDDO

    IF Empty( aLineas )
        AAdd( aLineas, { "" } )
    ENDIF

RETURN aLineas
