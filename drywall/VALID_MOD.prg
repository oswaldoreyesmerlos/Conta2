#include "OOp.ch"

// DV_MAX_MSG eliminado — se muestran todos los errores

FUNCTION DrywallMarkCalcDirty( cProyecto )

    LOCAL nArea := Select()

    IF ValType( cProyecto ) != "C"
        cProyecto := DrywallProyectoActualNumero()
    ENDIF
    cProyecto := AllTrim( cProyecto )

    IF Empty( cProyecto )
        RETURN .F.
    ENDIF

    IF !_DvOpen( "TMP_CAB", "TMP_CAB", "" )
        RETURN .F.
    ENDIF

    dbSelectArea( "TMP_CAB" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            IF NetRLock()
                IF FieldPos( "ESTADO" ) > 0
                    REPLACE FIELD->ESTADO WITH "P"
                ENDIF
                IF FieldPos( "L_CALC_DIR" ) > 0
                    REPLACE FIELD->L_CALC_DIR WITH .T.
                ENDIF
                IF FieldPos( "L_SUCIO" ) > 0
                    REPLACE FIELD->L_SUCIO WITH .T.
                ENDIF
                dbCommit()
                dbUnlock()
            ENDIF
            EXIT
        ENDIF
        dbSkip()
    ENDDO

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN .T.


FUNCTION DrywallMarkCabDirty( cProyecto )

    LOCAL nArea := Select()

    IF ValType( cProyecto ) != "C"
        cProyecto := DrywallProyectoActualNumero()
    ENDIF
    cProyecto := AllTrim( cProyecto )

    IF Empty( cProyecto )
        RETURN .F.
    ENDIF

    IF !_DvOpen( "TMP_CAB", "TMP_CAB", "" )
        RETURN .F.
    ENDIF

    dbSelectArea( "TMP_CAB" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            IF NetRLock()
                IF FieldPos( "L_CAB_DIR" ) > 0
                    REPLACE FIELD->L_CAB_DIR WITH .T.
                ENDIF
                dbCommit()
                dbUnlock()
            ENDIF
            EXIT
        ENDIF
        dbSkip()
    ENDDO

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN .T.


FUNCTION DrywallMarkCalculated( cProyecto )

    LOCAL nArea := Select()

    IF ValType( cProyecto ) != "C"
        cProyecto := DrywallProyectoActualNumero()
    ENDIF
    cProyecto := AllTrim( cProyecto )

    IF Empty( cProyecto )
        RETURN .F.
    ENDIF

    IF !_DvOpen( "TMP_CAB", "TMP_CAB", "" )
        RETURN .F.
    ENDIF

    dbSelectArea( "TMP_CAB" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            IF NetRLock()
                REPLACE FIELD->ESTADO WITH "C"
                IF FieldPos( "L_CALC_DIR" ) > 0
                    REPLACE FIELD->L_CALC_DIR WITH .F.
                ENDIF
                IF FieldPos( "L_SUCIO" ) > 0
                    REPLACE FIELD->L_SUCIO WITH .F.
                ENDIF
                dbCommit()
                dbUnlock()
            ENDIF
            EXIT
        ENDIF
        dbSkip()
    ENDDO

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN .T.


FUNCTION DrywallValidarTramos( cProyecto, lMostrar )

    LOCAL nArea := Select()
    LOCAL aErr := {}
    LOCAL nCount := 0

    IF ValType( cProyecto ) != "C"
        cProyecto := DrywallProyectoActualNumero()
    ENDIF
    IF ValType( lMostrar ) != "L"
        lMostrar := .T.
    ENDIF
    cProyecto := AllTrim( cProyecto )

    IF Empty( cProyecto )
        AAdd( aErr, "No hay proyecto activo." )
    ENDIF

    IF Len( aErr ) == 0 .AND. !_DvOpen( "TMP_TRA", "TMP_TRA", "TTRA_ORD" )
        AAdd( aErr, "No se pudo abrir TMP_TRA." )
    ENDIF

    IF Len( aErr ) == 0 .AND. !_DvOpen( "ARTICULOS", "ARTICULOS", "ART_COD" )
        AAdd( aErr, "No se pudo abrir ARTICULOS." )
    ENDIF

    IF Len( aErr ) == 0
        dbSelectArea( "TMP_TRA" )
        dbGoTop()
        DO WHILE !Eof()
            IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
                nCount++
                _DvValidaTramoActual( @aErr )
            ENDIF
            dbSkip()
        ENDDO

        IF nCount == 0
            AAdd( aErr, "No hay tramos cargados." )
        ENDIF
    ENDIF

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

    IF Len( aErr ) > 0 .AND. lMostrar
        _DvShow( "Validacion de tramos", aErr )
    ENDIF

RETURN Len( aErr ) == 0


FUNCTION DrywallValidarParaHistorico( cProyecto )

    LOCAL nArea := Select()
    LOCAL aErr := {}

    IF ValType( cProyecto ) != "C"
        cProyecto := DrywallProyectoActualNumero()
    ENDIF
    cProyecto := AllTrim( cProyecto )

    _DvValidaCabecera( "TMP_CAB", cProyecto, .T., @aErr )

    IF !_DvCalcLimpio( cProyecto )
        AAdd( aErr, "El proyecto tiene cambios de tramos sin recalcular." )
    ENDIF

    IF !DrywallValidarTramos( cProyecto, .F. )
        AAdd( aErr, "Revise los tramos antes de guardar en historico." )
    ENDIF

    _DvValidaResumen( "TMP_RES", cProyecto, .F., @aErr )
    _DvValidaCuenta( "TMP_MAT", cProyecto, "No hay despiece de materiales.", @aErr )

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

    IF Len( aErr ) > 0
        _DvShow( "Validacion para historico", aErr )
    ENDIF

RETURN Len( aErr ) == 0


FUNCTION DrywallValidarParaPresupuesto( cProyecto, cOrigen )

    LOCAL nArea := Select()
    LOCAL aErr := {}
    LOCAL cCab := "TMP_CAB"
    LOCAL cRes := "TMP_RES"

    DEFAULT cProyecto TO ""
    DEFAULT cOrigen TO "TMP"

    cProyecto := AllTrim( cProyecto )
    cOrigen := Upper( AllTrim( cOrigen ) )

    IF cOrigen == "HIS"
        cCab := "HIS_CAB"
        cRes := "HIS_RES"
    ENDIF

    _DvValidaCabecera( cCab, cProyecto, .T., @aErr )
    _DvValidaResumen( cRes, cProyecto, .T., @aErr )

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

    IF Len( aErr ) > 0
        _DvShow( "Validacion para presupuesto", aErr )
    ENDIF

RETURN Len( aErr ) == 0


STATIC FUNCTION _DvValidaTramoActual( aErr )

    LOCAL nLin := TMP_TRA->ID_LINEA
    LOCAL cTipo := Upper( AllTrim( TMP_TRA->TIPO_OBRA ) )
    LOCAL nCapas := TMP_TRA->PLAC_CARA

    IF !TipoObraDrywallValido( cTipo )
        AAdd( aErr, _DvLin( nLin, "tipo de obra no valido [" + cTipo + "]." ) )
        RETURN NIL
    ENDIF

    IF Empty( AllTrim( TMP_TRA->CONCEPTO ) )
        AAdd( aErr, _DvLin( nLin, "falta concepto." ) )
    ENDIF

    IF TMP_TRA->LARGO <= 0
        AAdd( aErr, _DvLin( nLin, "largo debe ser mayor a cero." ) )
    ENDIF

    IF TMP_TRA->ALTO <= 0
        AAdd( aErr, _DvLin( nLin, "alto/ancho debe ser mayor a cero." ) )
    ENDIF

    IF nCapas < 1 .OR. nCapas > 5
        AAdd( aErr, _DvLin( nLin, "capas debe estar entre 1 y 5." ) )
    ENDIF

    IF cTipo != "GENERICO" .AND. cTipo != "TRASDOSADO_DIR" .AND. TMP_TRA->MODUL <= 0
        AAdd( aErr, _DvLin( nLin, "modulacion debe ser mayor a cero." ) )
    ENDIF

    DO CASE
    CASE cTipo == "TABIQUE"
        _DvArticuloReq( TMP_TRA->ID_PER_VER, "PERFIL", nLin, "perfil principal", @aErr )
        _DvArticuloReq( TMP_TRA->ID_PER_HOR, "PERFIL", nLin, "canal", @aErr )
        _DvArticuloReq( TMP_TRA->ID_PLACA_A, "PLACA", nLin, "placa cara A", @aErr )
        _DvArticuloReq( TMP_TRA->ID_PLACA_B, "PLACA", nLin, "placa cara B", @aErr )

    CASE cTipo == "TECHO"
        IF Empty( AllTrim( TMP_TRA->SISTEMA_ID ) )
            AAdd( aErr, _DvLin( nLin, "debe tener un sistema de techo." ) )
        ENDIF
        _DvArticuloReq( TMP_TRA->ID_PER_VER, "PERFIL", nLin, "perfil secundario", @aErr )
        _DvArticuloReq( TMP_TRA->ID_PLACA_A, "PLACA", nLin, "placa", @aErr )
        IF TMP_TRA->SEP_PRIM > 0
            _DvArticuloReq( TMP_TRA->ID_PER_HOR, "PERFIL", nLin, "perfil primario", @aErr )
        ENDIF
        _DvArticuloOpt( TMP_TRA->ID_PER_PER, "PERFIL", nLin, "perfil perimetral", @aErr )

    CASE cTipo == "TRASDOSADO_DIR"
        _DvArticuloReq( TMP_TRA->ID_PLACA_A, "PLACA", nLin, "placa", @aErr )

    CASE cTipo == "TRASDOSADO_AUT"
        _DvArticuloReq( TMP_TRA->ID_PER_VER, "PERFIL", nLin, "perfil principal", @aErr )
        _DvArticuloReq( TMP_TRA->ID_PER_HOR, "PERFIL", nLin, "canal", @aErr )
        _DvArticuloReq( TMP_TRA->ID_PLACA_A, "PLACA", nLin, "placa", @aErr )

    CASE "TRAS" $ cTipo
        _DvArticuloReq( TMP_TRA->ID_PER_VER, "PERFIL", nLin, "perfil principal", @aErr )
        _DvArticuloOpt( TMP_TRA->ID_PER_HOR, "PERFIL", nLin, "perfil secundario", @aErr )
        _DvArticuloReq( TMP_TRA->ID_PLACA_A, "PLACA", nLin, "placa", @aErr )

    CASE cTipo == "GENERICO"
        _DvArticuloReq( TMP_TRA->ID_PLACA_A, "", nLin, "material generico", @aErr )
    ENDCASE

    IF If( ValType( TMP_TRA->L_AISLANT ) == "L", TMP_TRA->L_AISLANT, .F. )
        _DvArticuloReq( TMP_TRA->ID_AISLANT, "AISLAN", nLin, "aislante", @aErr )
    ENDIF

RETURN NIL


STATIC FUNCTION _DvValidaCabecera( cAlias, cProyecto, lClienteReq, aErr )

    IF Empty( cProyecto )
        AAdd( aErr, "No hay proyecto activo." )
        RETURN NIL
    ENDIF

    IF !_DvOpen( cAlias, cAlias, "" )
        AAdd( aErr, "No se pudo abrir " + cAlias + "." )
        RETURN NIL
    ENDIF

    dbSelectArea( cAlias )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            EXIT
        ENDIF
        dbSkip()
    ENDDO

    IF Eof()
        AAdd( aErr, "No se encontro la cabecera del proyecto " + cProyecto + "." )
        RETURN NIL
    ENDIF

    IF Empty( AllTrim( FIELD->TITULO ) )
        AAdd( aErr, "Falta titulo del proyecto." )
    ENDIF

    IF Empty( FIELD->FECHA )
        AAdd( aErr, "Falta fecha del proyecto." )
    ENDIF

    IF lClienteReq
        IF Empty( AllTrim( FIELD->ID_CLIENTE ) )
            AAdd( aErr, "Falta cliente del proyecto." )
        ELSEIF !_DvClienteExiste( FIELD->ID_CLIENTE )
            AAdd( aErr, "Cliente del proyecto no existe: " + AllTrim( FIELD->ID_CLIENTE ) )
        ENDIF
    ENDIF

    IF FieldPos( "MARGEN" ) > 0 .AND. FIELD->MARGEN < 0
        AAdd( aErr, "El margen no puede ser negativo." )
    ENDIF

RETURN NIL


STATIC FUNCTION _DvValidaResumen( cAlias, cProyecto, lPrecioReq, aErr )

    LOCAL nCount := 0
    LOCAL nTotal := 0
    LOCAL cCod

    IF !_DvOpen( cAlias, cAlias, If( cAlias == "HIS_RES", "HRES_PK", "RES_PK" ) )
        AAdd( aErr, "No se pudo abrir " + cAlias + "." )
        RETURN NIL
    ENDIF

    dbSelectArea( cAlias )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            nCount++
            cCod := AllTrim( FIELD->CODIGO )
            nTotal += FIELD->IMP_TOT

            IF Empty( cCod )
                AAdd( aErr, "Resumen con articulo vacio." )
            ELSEIF !_DvArticuloExiste( cCod, "" )
                AAdd( aErr, "Resumen: articulo no existe [" + cCod + "]." )
            ENDIF

            IF FIELD->CANT_TOT <= 0
                AAdd( aErr, "Resumen: cantidad no valida en [" + cCod + "]." )
            ENDIF

            IF FIELD->PRECIO < 0 .OR. ( lPrecioReq .AND. FIELD->PRECIO <= 0 )
                AAdd( aErr, "Resumen: precio no valido en [" + cCod + "]." )
            ENDIF

            IF FIELD->IMP_TOT < 0 .OR. ;
               Abs( FIELD->IMP_TOT - Round( FIELD->CANT_TOT * FIELD->PRECIO, 2 ) ) > 0.02
                AAdd( aErr, "Resumen: importe incoherente en [" + cCod + "]." )
            ENDIF
        ENDIF
        dbSkip()
    ENDDO

    IF nCount == 0
        AAdd( aErr, "No hay resumen economico." )
    ELSEIF nTotal <= 0
        AAdd( aErr, "El total economico debe ser mayor a cero." )
    ENDIF

RETURN NIL


STATIC FUNCTION _DvValidaCuenta( cAlias, cProyecto, cMsg, aErr )

    LOCAL nCount := 0

    IF !_DvOpen( cAlias, cAlias, "" )
        AAdd( aErr, "No se pudo abrir " + cAlias + "." )
        RETURN NIL
    ENDIF

    dbSelectArea( cAlias )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            nCount++
        ENDIF
        dbSkip()
    ENDDO

    IF nCount == 0
        AAdd( aErr, cMsg )
    ENDIF

RETURN NIL


STATIC FUNCTION _DvCalcLimpio( cProyecto )

    LOCAL lOk := .T.

    IF !_DvOpen( "TMP_CAB", "TMP_CAB", "" )
        RETURN .F.
    ENDIF

    dbSelectArea( "TMP_CAB" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            IF FieldPos( "L_CALC_DIR" ) > 0
                lOk := !FIELD->L_CALC_DIR
            ELSEIF FieldPos( "L_SUCIO" ) > 0
                lOk := !FIELD->L_SUCIO
            ENDIF
            EXIT
        ENDIF
        dbSkip()
    ENDDO

RETURN lOk


STATIC FUNCTION _DvArticuloReq( cCod, cFam, nLin, cLabel, aErr )

    IF _OptionalCode( cCod )
        AAdd( aErr, _DvLin( nLin, "falta " + cLabel + "." ) )
        RETURN .F.
    ENDIF

    IF !_DvArticuloExiste( cCod, cFam )
        AAdd( aErr, _DvLin( nLin, cLabel + " no existe o no es familia " + ;
                            If( Empty( cFam ), "valida", cFam ) + ;
                            " [" + AllTrim( cCod ) + "]." ) )
        RETURN .F.
    ENDIF

RETURN .T.


STATIC FUNCTION _DvArticuloOpt( cCod, cFam, nLin, cLabel, aErr )

    IF _OptionalCode( cCod )
        RETURN .T.
    ENDIF

    IF !_DvArticuloExiste( cCod, cFam )
        AAdd( aErr, _DvLin( nLin, cLabel + " no existe [" + AllTrim( cCod ) + "]." ) )
        RETURN .F.
    ENDIF

RETURN .T.


STATIC FUNCTION _DvArticuloExiste( cCod, cFam )

    LOCAL nArea := Select()
    LOCAL nOrd := 0
    LOCAL lOk := .F.

    cCod := Upper( AllTrim( cCod ) )
    cFam := Upper( AllTrim( cFam ) )

    IF Empty( cCod )
        RETURN .F.
    ENDIF

    IF !_DvOpen( "ARTICULOS", "ARTICULOS", "ART_COD" )
        RETURN .F.
    ENDIF

    dbSelectArea( "ARTICULOS" )
    nOrd := IndexOrd()
    OrdSetFocus( "ART_COD" )

    IF dbSeek( cCod )
        lOk := Deleted() == .F.
    ELSE
        dbGoTop()
        DO WHILE !Eof()
            IF !Deleted() .AND. Upper( AllTrim( ARTICULOS->CODIGO ) ) == cCod
                lOk := .T.
                EXIT
            ENDIF
            dbSkip()
        ENDDO
    ENDIF

    IF lOk .AND. !Empty( cFam )
        lOk := Upper( AllTrim( ARTICULOS->FAMILIA ) ) == cFam
    ENDIF

    dbSetOrder( nOrd )

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN lOk


STATIC FUNCTION _DvClienteExiste( cCliente )

    LOCAL nArea := Select()
    LOCAL nOrd := 0
    LOCAL lOk := .F.

    cCliente := AllTrim( cCliente )

    IF Empty( cCliente )
        RETURN .F.
    ENDIF

    IF !_DvOpen( "CLIENTES", "CLIENTES", "CLI_ID" )
        RETURN .F.
    ENDIF

    dbSelectArea( "CLIENTES" )
    nOrd := IndexOrd()
    OrdSetFocus( "CLI_ID" )
    lOk := dbSeek( PadR( cCliente, 10 ) ) .AND. !Deleted()
    dbSetOrder( nOrd )

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN lOk


STATIC FUNCTION _DvOpen( cFile, cAlias, cOrder )

    IF Select( cAlias ) == 0
        IF !ABRIR_TABLA( cFile, cAlias, cOrder )
            RETURN .F.
        ENDIF
    ELSEIF !Empty( cOrder )
        dbSelectArea( cAlias )
        BEGIN SEQUENCE WITH {|oErr| Break( oErr )}
            OrdSetFocus( cOrder )
        RECOVER
        END SEQUENCE
    ENDIF

RETURN .T.


STATIC FUNCTION _DvLin( nLin, cMsg )

RETURN "Lin " + AllTrim( Str( nLin ) ) + ": " + cMsg


STATIC FUNCTION _DvShow( cTitle, aErr )

    LOCAL cMsg := ""
    LOCAL i

    FOR i := 1 TO Len( aErr )
        cMsg += aErr[i] + Chr( 13 )
    NEXT

    MsgStop( cMsg, cTitle )

RETURN NIL
