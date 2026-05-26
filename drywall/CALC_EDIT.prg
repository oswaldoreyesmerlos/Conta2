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
        USE TMP_TRA NEW SHARED VIA "DBFCDX"
        lWeOpened := .T.
    ENDIF

    dbSelectArea( "TMP_TRA" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. ;
           AllTrim( FIELD->NUMERO ) == cProyecto .AND. ;
           FIELD->ID_LINEA == nIdLinea
            hData["ID_LINEA"]   := FIELD->ID_LINEA
            hData["TIPO"]       := FIELD->TIPO_OBRA
            hData["CONCEPTO"]   := FIELD->CONCEPTO
            hData["LARGO"]      := FIELD->LARGO
            hData["ALTO"]       := FIELD->ALTO
            hData["MODUL"]      := FIELD->MODUL
            hData["SISTEMA"]    := If( FieldPos( "SISTEMA" ) > 0, FIELD->SISTEMA, 0 )
            hData["SEP_PRIM"]   := FIELD->SEP_PRIM
            hData["NUM_PLACAS"] := FIELD->PLAC_CARA
            hData["SAME_B"]     := "S"
            hData["ID_PERFIL"]  := FIELD->ID_PER_VER
            hData["ID_PERFIL2"] := FIELD->ID_PER_HOR
            hData["ID_PERFIL3"] := FIELD->ID_PER_PER
            hData["ID_ANCLAJE"] := FIELD->ID_ANCLAJE
            hData["ID_PLACA_A"] := FIELD->ID_PLACA_A
            hData["ID_PLACA_B"] := FIELD->ID_PLACA_B
            hData["ID_AISLAN"]  := FIELD->ID_AISLANT
            hData["AIS"]        := If( FIELD->L_AISLANT, "S", "N" )
            hData["BANDA"]      := If( FIELD->L_BANDA, "S", "N" )

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

    IF Select( "TMP_TRA" ) == 0
        USE TMP_TRA NEW SHARED VIA "DBFCDX"
        lWeOpened := .T.
    ENDIF

    dbSelectArea( "TMP_TRA" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. ;
           AllTrim( FIELD->NUMERO ) == cProyecto .AND. ;
           FIELD->ID_LINEA == hData["ID_LINEA"]
            IF NetRLock()
                REPLACE FIELD->CONCEPTO   WITH hData["CONCEPTO"]
                REPLACE FIELD->LARGO      WITH hData["LARGO"]
                REPLACE FIELD->ALTO       WITH hData["ALTO"]
                REPLACE FIELD->MODUL      WITH hData["MODUL"]
                IF FieldPos( "SISTEMA" ) > 0 .AND. hb_HHasKey( hData, "SISTEMA" )
                    REPLACE FIELD->SISTEMA WITH _SysAncho( hData["SISTEMA"] )
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

    LOCAL nArea := Select()
    LOCAL cProyecto := ""

    IF Select( "TMP_CAB" ) > 0
        dbSelectArea( "TMP_CAB" )
        dbGoTop()
        DO WHILE !Eof()
            IF !Deleted()
                cProyecto := AllTrim( FIELD->NUMERO )
                EXIT
            ENDIF
            dbSkip()
        ENDDO
    ENDIF

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN cProyecto


STATIC FUNCTION _MarkCabDirty()

    LOCAL nArea := Select()

    IF Select( "TMP_CAB" ) > 0
        dbSelectArea( "TMP_CAB" )
        dbGoTop()
        IF NetRLock()
            REPLACE FIELD->L_SUCIO WITH .T.
            dbCommit()
            dbUnlock()
        ENDIF
    ENDIF

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN NIL


STATIC FUNCTION _ValidSistema( oGet )

    LOCAL nSistema := _SysAncho( oGet:uVar )

    IF AScan( { 48, 70, 90 }, nSistema ) > 0
        RETURN .T.
    ENDIF

    MsgStop( "Sistema: 48, 70 o 90", "Validacion" )

RETURN .F.

