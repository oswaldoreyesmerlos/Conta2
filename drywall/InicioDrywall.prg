/*
 * ARCHIVO  : InicioDrywall.prg
 * PROPOSITO: Crear tablas DBF especificas del modulo Drywall
 *            (calculos de tabiquería seca, presupuestos tecnicos).
 *
 * LLAMAR DESDE Main() después de InicioDBF().
 *
 * Tablas:
 *   TMP_TRA   - Tramos temporales (parametros de calculo)
 *   TMP_MAT   - Materiales calculados
 *   TMP_RES   - Resumen valorado
 *   TMP_CAB   - Cabecera temporal
 *   ARTICULO  - Catalogo de materiales Drywall
 *   TABLAS_AUX- Tablas auxiliares (perfiles, placas, aislamientos, etc.)
 */

#include "OOp.ch"

FUNCTION InicioDrywall()

    LOCAL aTablas   := {}
    LOCAL aCampos
    LOCAL aIndices
    LOCAL aCamposR
    LOCAL aIndicesR
    LOCAL tmp
    LOCAL i, nCdx
    LOCAL cDbf, cCdx

    SET DEFAULT TO ".\DATA"

    // -- TMP_TRA (tramos/parametros de calculo) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",    "C", 10, 0 } )
    AAdd( aCampos, { "ID_LINEA",  "N",  4, 0 } )
    AAdd( aCampos, { "TIPO_OBRA", "C", 12, 0 } )
    AAdd( aCampos, { "CONCEPTO",  "C", 30, 0 } )
    AAdd( aCampos, { "LARGO",     "N",  7, 2 } )
    AAdd( aCampos, { "ALTO",      "N",  7, 2 } )
    AAdd( aCampos, { "MODUL",     "N",  5, 2 } )
    AAdd( aCampos, { "SEP_PRIM",  "N",  5, 2 } )
    AAdd( aCampos, { "PLAC_CARA", "N",  1, 0 } )
    AAdd( aCampos, { "CARAS",     "N",  1, 0 } )
    AAdd( aCampos, { "ID_PER_VER","C", 15, 0 } )
    AAdd( aCampos, { "ID_PER_HOR","C", 15, 0 } )
    AAdd( aCampos, { "ID_PER_PER","C", 15, 0 } )
    AAdd( aCampos, { "ID_PERF_VERT","C",15, 0 } )
    AAdd( aCampos, { "ID_PERF_HOR","C",15, 0 } )
    AAdd( aCampos, { "ID_PLACA_A","C", 15, 0 } )
    AAdd( aCampos, { "ID_PLACA_B","C", 15, 0 } )
    AAdd( aCampos, { "ID_AISLANT","C", 15, 0 } )
    AAdd( aCampos, { "ID_ANCLAJE","C", 15, 0 } )
    AAdd( aCampos, { "L_AISLANT", "L",  1, 0 } )
    AAdd( aCampos, { "L_BANDA",   "L",  1, 0 } )
    AAdd( aIndices, { "TRA_ID", "NUMERO+Str(ID_LINEA,4)" } )
    AAdd( aTablas, { "TMP_TRA", aCampos, aIndices } )

    // -- TMP_MAT (materiales calculados) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",    "C", 10, 0 } )
    AAdd( aCampos, { "ID_LINEA",  "N",  4, 0 } )
    AAdd( aCampos, { "FAMILIA",   "C", 10, 0 } )
    AAdd( aCampos, { "CODIGO",    "C", 15, 0 } )
    AAdd( aCampos, { "DESCRIP",   "C", 40, 0 } )
    AAdd( aCampos, { "UNIDAD",    "C",  3, 0 } )
    AAdd( aCampos, { "CANTIDAD",  "N", 10, 2 } )
    AAdd( aCampos, { "PRECIO",    "N",  8, 2 } )
    AAdd( aCampos, { "IMPORTE",   "N", 10, 2 } )
    AAdd( aCampos, { "PESO_TOT",  "N",  8, 2 } )
    AAdd( aCampos, { "DETALLE",   "C", 40, 0 } )
    AAdd( aCampos, { "L_MANUAL",  "L",  1, 0 } )
    AAdd( aIndices, { "MAT_ID",  "NUMERO+Str(ID_LINEA,4)" } )
    AAdd( aTablas, { "TMP_MAT", aCampos, aIndices } )

    // -- TMP_RES (resumen valorado) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",    "C", 10, 0 } )
    AAdd( aCampos, { "ID_LINEA",  "N",  4, 0 } )
    AAdd( aCampos, { "CONCEPTO",  "C", 30, 0 } )
    AAdd( aCampos, { "IMP_TOT",   "N", 10, 2 } )
    AAdd( aIndices, { "RES_ID",  "NUMERO+Str(ID_LINEA,4)" } )
    AAdd( aTablas, { "TMP_RES", aCampos, aIndices } )

    // -- TMP_CAB (cabecera temporal) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",    "C", 10, 0 } )
    AAdd( aCampos, { "L_SUCIO",   "L",  1, 0 } )
    AAdd( aCampos, { "FECHA",     "D",  8, 0 } )
    AAdd( aCampos, { "CLIENTE",   "C", 10, 0 } )
    AAdd( aCampos, { "TOTAL",     "N", 10, 2 } )
    AAdd( aIndices, { "CAB_NUM", "NUMERO" } )
    AAdd( aTablas, { "TMP_CAB", aCampos, aIndices } )

    // -- ARTICULO (catalogo de materiales Drywall) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CODIGO",    "C", 15, 0 } )
    AAdd( aCampos, { "DESCRIP",   "C", 40, 0 } )
    AAdd( aCampos, { "FAMILIA",   "C", 10, 0 } )
    AAdd( aCampos, { "PRECIO",    "N",  8, 2 } )
    AAdd( aCampos, { "UNIDAD",    "C",  3, 0 } )
    AAdd( aCampos, { "PESO_UNI",  "N",  8, 2 } )
    AAdd( aCampos, { "BAJA",      "L",  1, 0 } )
    AAdd( aIndices, { "ART_COD", "CODIGO" } )
    AAdd( aIndices, { "ART_FAM", "FAMILIA+CODIGO" } )
    AAdd( aTablas, { "ARTICULO", aCampos, aIndices } )

    // -- TABLAS_AUX (catalogo auxiliar: familias, perfiles, placas...) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "FAMILIA",   "C", 10, 0 } )
    AAdd( aCampos, { "CODIGO",    "C", 15, 0 } )
    AAdd( aCampos, { "DESCRIP",   "C", 40, 0 } )
    AAdd( aCampos, { "UNIDAD",    "C",  3, 0 } )
    AAdd( aCampos, { "PRECIO",    "N",  8, 2 } )
    AAdd( aCampos, { "BAJA",      "L",  1, 0 } )
    AAdd( aIndices, { "AUX_FAM", "FAMILIA+CODIGO" } )
    AAdd( aTablas, { "TABLAS_AUX", aCampos, aIndices } )

    // =========================================================================
    // CREACION FISICA DE TABLAS E INDICES
    // =========================================================================

    FOR i := 1 TO Len( aTablas )

        cDbf := aTablas[i, 1]
        aCamposR := aTablas[i, 2]
        aIndicesR := aTablas[i, 3]

        IF !File( cDbf + ".DBF" )
            DbCreate( cDbf, aCamposR, "DBFCDX", .T., "DRYWALL" )
            IF NetErr()
                MsgStop( "Error creando " + cDbf, "InicioDrywall" )
                RETURN .F.
            ENDIF
        ENDIF

        // Reconstruir CDX
        cCdx := cDbf + ".CDX"
        IF File( cCdx )
            FErase( cCdx )
        ENDIF

        tmp := DbUseArea( .F., "DBFCDX", cDbf, "CREA_TMP", .T., .F. )
        IF !tmp .OR. NetErr()
            MsgStop( "Error abriendo " + cDbf + " para crear CDX.", "InicioDrywall" )
            RETURN .F.
        ENDIF

        DbSelectArea( "CREA_TMP" )

        IF LastRec() > 0
            nCdx := IndexOrd()
            IF nCdx == 0 .AND. Len( aIndicesR ) > 0
                // Indice perdido, regenerar
                FOR tmp := 1 TO Len( aIndicesR )
                    INDEX ON &( aIndicesR[tmp, 2] ) TAG ( aIndicesR[tmp, 1] )
                NEXT
            ENDIF
        ELSE
            FOR tmp := 1 TO Len( aIndicesR )
                INDEX ON &( aIndicesR[tmp, 2] ) TAG ( aIndicesR[tmp, 1] )
            NEXT
        ENDIF

        DbCloseArea()

    NEXT

RETURN .T.
