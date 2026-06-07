/*
 * ARCHIVO  : CALC_EDIT.prg
 * PROPOSITO: Edicion Especializada de calculos (Tabique, Techo, Trasdosado)
 * MIGRADO A: GfxStack API
 */

#include "OOp.ch"

FUNCTION EditTramo( nIdLinea )

    LOCAL lRet := .F.
    LOCAL hData
    LOCAL cTipo

    hData := _LoadData( nIdLinea )
    IF hData == NIL
        RETURN .F.
    ENDIF

    cTipo := AllTrim( hData["TIPO"] )

    DO CASE
    CASE cTipo == "TABIQUE"
        lRet := Edit_Tabique( hData )
    CASE cTipo == "TECHO"
        lRet := Edit_Techo( hData )
    CASE "TRAS" $ cTipo
        lRet := Edit_Trasdosado( hData )
    CASE cTipo == "GENERICO"
        lRet := Edit_Generico( hData )
    OTHERWISE
        MsgStop( "Tipo de obra desconocido: [" + cTipo + "]" )
    ENDCASE

RETURN lRet


STATIC FUNCTION Edit_Tabique( hData )

RETURN Form_Tabique( hData, .F. )


STATIC FUNCTION Edit_Techo( hData )

RETURN Form_Techo( hData, .F. )


STATIC FUNCTION Edit_Trasdosado( hData )

RETURN Form_Trasdosado( hData, .F. )


STATIC FUNCTION Edit_Generico( hData )

RETURN Form_Generico( hData, .F. )


// ============================================================================
// FUNCIONES DE APOYO
// ============================================================================
STATIC FUNCTION _LoadData( nIdLinea )

    LOCAL hData := hb_Hash()
    LOCAL cTipo
    LOCAL lWeOpened := .F.
    LOCAL cProyecto := _EditProyectoActual()

    IF Select( "TMP_TRA" ) == 0
        ABRIR_TABLA( "TMP_TRA", "TMP_TRA", "" )
        lWeOpened := .T.
    ENDIF

    dbSelectArea( "TMP_TRA" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. ;
           AllTrim( FIELD->NUMERO ) == cProyecto .AND. ;
           FIELD->ID_LINEA == nIdLinea
            hData["ID_LINEA"]   := FIELD->ID_LINEA
            hData["TIPO"]       := Upper( AllTrim( FIELD->TIPO_OBRA ) )
            hData["SISTEMA_ID"] := If( FieldPos( "SISTEMA_ID" ) > 0, FIELD->SISTEMA_ID, Space(20) )
            hData["CONCEPTO"]   := FIELD->CONCEPTO
            hData["LARGO"]      := FIELD->LARGO
            hData["ALTO"]       := FIELD->ALTO
            hData["MODUL"]      := FIELD->MODUL
            hData["ANCHO_PERF"] := If( FieldPos( "ANCHO_PERF" ) > 0, FIELD->ANCHO_PERF, 0 )
            hData["SEP_PRIM"]   := FIELD->SEP_PRIM
            hData["NUM_PLACAS"] := If( ValType( FIELD->PLAC_CARA ) == "N", FIELD->PLAC_CARA, 0 )
            hData["SAME_B"]     := "S"
            hData["ID_PERFIL"]  := FIELD->ID_PER_VER
            hData["ID_PERFIL2"] := FIELD->ID_PER_HOR
            hData["ID_PERFIL3"] := FIELD->ID_PER_PER
            hData["ID_ANCLAJE"] := FIELD->ID_ANCLAJE
            hData["ID_PLACA_A"] := FIELD->ID_PLACA_A
            hData["ID_PLACA_B"] := FIELD->ID_PLACA_B
            hData["ID_AISLAN"]  := FIELD->ID_AISLANT
            hData["AIS"]        := If( If( ValType( FIELD->L_AISLANT ) == "L", FIELD->L_AISLANT, .F. ), "S", "N" )
            hData["BANDA"]      := If( If( ValType( FIELD->L_BANDA ) == "L", FIELD->L_BANDA, .F. ), "S", "N" )

            cTipo := AllTrim( FIELD->TIPO_OBRA )
            IF cTipo == "TABIQUE" .AND. !Empty( FIELD->ID_PLACA_B ) .AND. ;
               FIELD->ID_PLACA_A == FIELD->ID_PLACA_B
                hData["SAME_B"] := "S"
            ELSE
                hData["SAME_B"] := "N"
            ENDIF

            IF lWeOpened
                dbCloseArea()
            ENDIF
            RETURN hData
        ENDIF
        dbSkip()
    ENDDO

    IF lWeOpened
        dbCloseArea()
    ENDIF
    MsgStop( "No se encontro el tramo " + AllTrim( Str( nIdLinea ) ) )
RETURN NIL
FUNCTION UpdateTramoData( hData )

RETURN _UpdateData( hData )


STATIC FUNCTION _UpdateData( hData )

    LOCAL lWeOpened := .F.
    LOCAL cProyecto := _EditProyectoActual()
    LOCAL cTipo := Upper( AllTrim( hData["TIPO"] ) )

    IF !TipoObraDrywallValido( cTipo )
        MsgStop( "Sistema constructivo no valido: [" + cTipo + "].", "Editar Tramo" )
        RETURN .F.
    ENDIF

    IF cTipo == "TECHO"
        IF Empty( AllTrim( hData["SISTEMA_ID"] ) )
            MsgStop( "Debe seleccionar un sistema de techo.", "Validacion" )
            RETURN .F.
        ENDIF
        IF hData["SEP_PRIM"] <= 0
            hData["ID_PERFIL2"] := Space( 15 )
        ELSEIF _OptionalCode( hData["ID_PERFIL2"] )
            MsgStop( "Falta seleccionar perfil primario.", "Validacion" )
            RETURN .F.
        ENDIF
    ENDIF

    IF Select( "TMP_TRA" ) == 0
        ABRIR_TABLA( "TMP_TRA", "TMP_TRA", "" )
        lWeOpened := .T.
    ENDIF

    dbSelectArea( "TMP_TRA" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. ;
           AllTrim( FIELD->NUMERO ) == cProyecto .AND. ;
           FIELD->ID_LINEA == hData["ID_LINEA"]
            IF NetRLock()
                REPLACE FIELD->TIPO_OBRA  WITH cTipo
                IF FieldPos( "SISTEMA_ID" ) > 0 .AND. hb_HHasKey( hData, "SISTEMA_ID" )
                    REPLACE FIELD->SISTEMA_ID WITH hData["SISTEMA_ID"]
                ENDIF
                REPLACE FIELD->CONCEPTO   WITH hData["CONCEPTO"]
                REPLACE FIELD->LARGO      WITH hData["LARGO"]
                REPLACE FIELD->ALTO       WITH hData["ALTO"]
                REPLACE FIELD->MODUL      WITH hData["MODUL"]
                IF FieldPos( "ANCHO_PERF" ) > 0 .AND. hb_HHasKey( hData, "ANCHO_PERF" )
                    REPLACE FIELD->ANCHO_PERF WITH _SysAncho( hData["ANCHO_PERF"] )
                ENDIF
                REPLACE FIELD->SEP_PRIM   WITH hData["SEP_PRIM"]
                REPLACE FIELD->PLAC_CARA  WITH hData["NUM_PLACAS"]
                REPLACE FIELD->ID_PER_VER WITH hData["ID_PERFIL"]
                REPLACE FIELD->ID_PER_HOR WITH hData["ID_PERFIL2"]
                IF hb_HHasKey( hData, "ID_PERFIL3" )
                    REPLACE FIELD->ID_PER_PER WITH hData["ID_PERFIL3"]
                ENDIF
                IF hb_HHasKey( hData, "ID_ANCLAJE" )
                    REPLACE FIELD->ID_ANCLAJE WITH hData["ID_ANCLAJE"]
                ENDIF
                REPLACE FIELD->ID_PLACA_A WITH hData["ID_PLACA_A"]
                REPLACE FIELD->ID_PLACA_B WITH hData["ID_PLACA_B"]
                REPLACE FIELD->ID_AISLANT WITH hData["ID_AISLAN"]
                REPLACE FIELD->L_AISLANT  WITH ( hData["AIS"] == "S" )
                REPLACE FIELD->L_BANDA    WITH ( hData["BANDA"] == "S" )
                DbCommit()
                DbUnlock()
            ENDIF
            _MarkCabDirty()
            IF lWeOpened
                dbCloseArea()
            ENDIF
            RETURN .T.
        ENDIF
        dbSkip()
    ENDDO

    IF lWeOpened
        dbCloseArea()
    ENDIF
    MsgStop( "No se pudo actualizar el tramo." )
RETURN .F.


STATIC FUNCTION _EditProyectoActual()

RETURN DrywallProyectoActualNumero()


STATIC FUNCTION _MarkCabDirty()

    LOCAL cProyecto := _EditProyectoActual()

    DrywallMarkCalcDirty( cProyecto )

RETURN NIL
