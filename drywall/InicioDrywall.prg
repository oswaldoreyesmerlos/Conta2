/*
 * ARCHIVO  : InicioDrywall.prg
 * PROPOSITO: Crear tablas DBF especificas del modulo Drywall
 *            (calculos de tabiquería seca, presupuestos tecnicos).
 *
 * LLAMAR DESDE Main() después de InicioDBF().
 *
 * Tablas:
 *   TMP_TRA    - Tramos temporales (parametros de calculo)
 *   TMP_MAT    - Materiales calculados
 *   TMP_RES    - Resumen valorado
 *   TMP_CAB    - Cabecera temporal
 *   ARTICULOS  - Catalogo de materiales Drywall
 *   TABLAS_AUX - Tablas auxiliares (perfiles, placas, aislamientos, etc.)
 *   PRESUPUEST - Cabecera de presupuesto (AppGestion)
 *   PRESUP_DE  - Lineas de presupuesto (AppGestion)
 */

#include "OOp.ch"

REQUEST DBFCDX

FUNCTION InicioDrywall()

    LOCAL aAllDefs  := {}
    LOCAL aCampos   := {}
    LOCAL aIndices  := {}
    LOCAL aCamposR  := {}
    LOCAL aIndicesR := {}
    LOCAL tmp
    LOCAL i, nCdx
    LOCAL cDbf, cCdx
    LOCAL aFlds, aInds

    IF hb_DirExists( hb_DirBase() + "DATA" )
        SET DEFAULT TO ( hb_DirBase() + "DATA" )
    ELSE
        SET DEFAULT TO ( hb_DirBase() + "..\DATA" )
    ENDIF

    // =========================================================
        // 4. TMP_CAB
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "NUMERO",     "C",  6, 0 } )
        AAdd( aFlds, { "FECHA",      "D",  8, 0 } )
        AAdd( aFlds, { "TITULO",     "C", 60, 0 } )
        AAdd( aFlds, { "ID_CLIENTE", "C", 15, 0 } )
        AAdd( aFlds, { "ESTADO",     "C",  1, 0 } )
        AAdd( aFlds, { "MARGEN",     "N",  5, 2 } )  //% utilidad a ese cliente
        AAdd( aFlds, { "OBSERV",     "C",200, 0 } )
        AAdd( aFlds, { "L_ACTIVO",   "L",  1, 0 } )
        AAdd( aFlds, { "L_SUCIO",    "L",  1, 0 } )
        AAdd( aFlds, { "L_CALC_DIR", "L",  1, 0 } )
        AAdd( aFlds, { "L_CAB_DIR",  "L",  1, 0 } )

        aInds := {}
        AAdd( aInds, { "TMP_NUM", "NUMERO" } )

        AAdd( aAllDefs, { "TMP_CAB", aFlds, aInds, .T. } )

        
        // =========================================================
		// 5. TMP_TRA (TABLA MAESTRA DE TRAMOS)
		// =========================================================
		aFlds := {}
		// --- Identificación ---
		AAdd( aFlds, { "NUMERO",        "C",  6, 0 } ) 
		AAdd( aFlds, { "ID_LINEA",      "N",  4, 0 } ) 
		AAdd( aFlds, { "TIPO_OBRA",     "C", 15, 0 } ) // TABIQUE, TECHO, TRASDOSADO_...
		AAdd( aFlds, { "SISTEMA_ID",    "C", 20, 0 } ) // Sistema tecnico de rendimientos
		AAdd( aFlds, { "CONCEPTO",      "C", 40, 0 } ) 
		
		// --- Geometría ---
		AAdd( aFlds, { "LARGO",         "N",  6, 2 } ) 
		AAdd( aFlds, { "ALTO",          "N",  6, 2 } ) 
		AAdd( aFlds, { "MODUL",         "N",  5, 2 } ) // Separación Perfil VERTICAL (Placa)
		AAdd( aFlds, { "ANCHO_PERF",    "N",  3, 0 } ) // Ancho de perfileria: 48, 70, 90
		AAdd( aFlds, { "SEP_PRIM",      "N",  5, 2 } ) // Separación Perfil HORIZ (Estructura) - Solo Techos

		// --- Configuración Capas ---
		AAdd( aFlds, { "CARAS",         "N",  1, 0 } ) // 1 o 2 (Auto según sistema)
		AAdd( aFlds, { "PLAC_CARA",     "N",  1, 0 } ) // Nº Capas por cara (1, 2, 3...)

		// --- Materiales Principales ---
		AAdd( aFlds, { "ID_PER_VER",    "C", 15, 0 } )
		AAdd( aFlds, { "ID_PER_HOR",    "C", 15, 0 } )
		AAdd( aFlds, { "ID_PER_PER",    "C", 15, 0 } )

		// --- Placas (Asimetría soportada) ---
		AAdd( aFlds, { "ID_PLACA_A",    "C", 15, 0 } ) // Cara Vista / Base
		AAdd( aFlds, { "ID_PLACA_B",    "C", 15, 0 } ) // Cara Oculta / Reverso (Si CARAS=2)

		// --- Aislamiento ---
		AAdd( aFlds, { "L_AISLANT",     "L",  1, 0 } ) 
		AAdd( aFlds, { "ID_AISLANT",    "C", 15, 0 } )

		// --- Accesorios y Detalles (NUEVOS) ---
		AAdd( aFlds, { "ID_ANCLAJE",    "C", 15, 0 } ) // "Varilla", "Nonius"... (Solo Techos)
		AAdd( aFlds, { "L_BANDA",       "L",  1, 0 } ) // Banda Acústica bajo perfiles?

		// --- Resultado ---
		AAdd( aFlds, { "METROS",        "N", 10, 2 } ) 

        aInds := {}
        AAdd( aInds, { "TTRA_ORD", "NUMERO + Str(ID_LINEA,4)" } )
        AAdd( aAllDefs, { "TMP_TRA", aFlds, aInds, .T. } )

        aInds := {}
        AAdd( aInds, { "HTRA_NUM", "NUMERO + Str(ID_LINEA,4)" } )
        AAdd( aAllDefs, { "HIS_TRA", aFlds, aInds } )

        // =========================================================
        // 6. TMP_MAT
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "NUMERO",    "C",  6, 0 } ) 
        AAdd( aFlds, { "ID_LINEA",  "N",  4, 0 } ) 
		
		// --- Control (OPTIMIZADO) ---
		// .T. = Introducido manual (Proteger)
		// .F. = Calculado auto (Borrar al recalcular)
		AAdd( aFlds, { "L_MANUAL", "L",  1, 0 } )
		
        AAdd( aFlds, { "ORIGEN",    "C",  4, 0 } ) // 'AUTO' / 'MAN'
        AAdd( aFlds, { "FAMILIA",   "C", 10, 0 } ) 
        
        AAdd( aFlds, { "CODIGO",    "C", 15, 0 } ) 
        AAdd( aFlds, { "DESCRIP",   "C", 40, 0 } ) 
        AAdd( aFlds, { "UNIDAD",    "C",  5, 0 } )
        
        // --- LOGISTICA ---
        AAdd( aFlds, { "PESO_TOT",  "N", 12, 3 } ) // Peso Total Línea (Kg)
		
		AAdd( aFlds, { "RENDIM",    "N", 12, 3 } )
        AAdd( aFlds, { "CANTIDAD",  "N", 12, 3 } ) 
        AAdd( aFlds, { "PRECIO",    "N", 10, 2 } ) 
        AAdd( aFlds, { "IMPORTE",   "N", 12, 2 } ) 
        AAdd( aFlds, { "DETALLE",   "C", 30, 0 } )
		
        aInds := {}
        AAdd( aInds, { "MAT_NUM", "NUMERO" } )
        AAdd( aInds, { "MAT_LIN", "NUMERO + Str(ID_LINEA,4)" } )
        AAdd( aInds, { "MAT_COD", "CODIGO" } )

        AAdd( aAllDefs, { "TMP_MAT", aFlds, aInds, .T. } )

        aInds := {}
        AAdd( aInds, { "HMAT_NUM", "NUMERO" } )
        AAdd( aInds, { "HMAT_LIN", "NUMERO + Str(ID_LINEA,4)" } )
        AAdd( aAllDefs, { "HIS_MAT", aFlds, aInds } )


        // =========================================================
        // 7. TMP_RES   (Resumen del proyecto temporal)
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "NUMERO",    "C",  6, 0 } ) 
        AAdd( aFlds, { "FAMILIA",   "C", 10, 0 } ) 
        AAdd( aFlds, { "CODIGO",    "C", 15, 0 } ) 
        AAdd( aFlds, { "DESCRIP",   "C", 40, 0 } ) 
        AAdd( aFlds, { "UNIDAD",    "C",  5, 0 } )
        AAdd( aFlds, { "CANT_TOT",  "N", 12, 3 } )
		
		// --- LOGISTICA ---
        AAdd( aFlds, { "PESO_TOT",  "N", 12, 3 } ) // Peso Total Agrupado (Kg)
		
        AAdd( aFlds, { "PRECIO",    "N", 10, 2 } ) 
        AAdd( aFlds, { "IMP_TOT",   "N", 12, 2 } )

        aInds := {}
        AAdd( aInds, { "RES_PK", "NUMERO + CODIGO" } )

        AAdd( aAllDefs, { "TMP_RES", aFlds, aInds, .T. } )

        aInds := {}
        AAdd( aInds, { "HRES_PK", "NUMERO + CODIGO" } )
        AAdd( aAllDefs, { "HIS_RES", aFlds, aInds } )

        // =========================================================
        // 8. HIS_CAB   (Cabecera histórica)
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "NUMERO",      "C",  6, 0 } )
        AAdd( aFlds, { "FECHA",       "D",  8, 0 } )
        AAdd( aFlds, { "TITULO",      "C", 60, 0 } )
        AAdd( aFlds, { "ID_CLIENTE",  "C", 15, 0 } )
        AAdd( aFlds, { "ESTADO",      "C",  1, 0 } )
        AAdd( aFlds, { "MARGEN",     "N",  5, 2 } )
        AAdd( aFlds, { "OBSERV",      "C",200, 0 } )
        AAdd( aFlds, { "PRES_NUM",    "C", 10, 0 } )
        AAdd( aFlds, { "FEC_CALC",    "D",  8, 0 } )
        AAdd( aFlds, { "FEC_CIERRE",  "D",  8, 0 } )

        aInds := {}
        AAdd( aInds, { "HIS_NUM", "NUMERO" } )
        AAdd( aInds, { "HIS_CLI", "ID_CLIENTE" } )

        AAdd( aAllDefs, { "HIS_CAB", aFlds, aInds } )

        // =========================================================
        // 9. TABLAS_AUX   (Maestro de listas auxiliares)
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "TIPO",    "C", 10, 0 } )
        AAdd( aFlds, { "CODIGO",  "C", 15, 0 } )
        AAdd( aFlds, { "DESCRIP", "C", 40, 0 } )

        aInds := {}
        AAdd( aInds, { "AUX_PK", "Upper(TIPO) + Upper(CODIGO)" } )

        AAdd( aAllDefs, { "TABLAS_AUX", aFlds, aInds } )

        // =========================================================
        // 10. SYS_REND   (Rendimientos tecnicos por sistema)
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "SISTEMA_ID", "C", 20, 0 } )
        AAdd( aFlds, { "TIPO_OBRA",  "C", 15, 0 } )
        AAdd( aFlds, { "DESC_SIS",   "C", 60, 0 } )
        AAdd( aFlds, { "MODUL",      "N",  5, 2 } )
        AAdd( aFlds, { "SEP_PRIM",   "N",  5, 2 } )
        AAdd( aFlds, { "CARAS",      "N",  1, 0 } )
        AAdd( aFlds, { "CAPAS",      "N",  1, 0 } )
        AAdd( aFlds, { "ANCHO_PERF", "N",  3, 0 } )
        AAdd( aFlds, { "ORDEN",      "N",  4, 0 } )
        AAdd( aFlds, { "FAMILIA",    "C", 10, 0 } )
        AAdd( aFlds, { "ROL_MAT",    "C", 15, 0 } )
        AAdd( aFlds, { "CODIGO_DEF", "C", 15, 0 } )
        AAdd( aFlds, { "UD_TEC",     "C",  5, 0 } )
        AAdd( aFlds, { "REND_M2",    "N", 12, 3 } )
        AAdd( aFlds, { "L_EDIT",     "L",  1, 0 } )

        aInds := {}
        AAdd( aInds, { "SR_SIS", "Upper(SISTEMA_ID) + Str(ORDEN,4)" } )
        AAdd( aInds, { "SR_TIPO", "Upper(TIPO_OBRA) + Str(MODUL,5,2) + Str(CARAS,1) + Str(CAPAS,1) + Str(ANCHO_PERF,3) + Str(ORDEN,4)" } )

        AAdd( aAllDefs, { "SYS_REND", aFlds, aInds } )

        // =========================================================
        // 11. PRESUPUEST   (Cabecera de presupuesto AppGestion)
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "NUMERO",   "C", 10, 0 } )
        AAdd( aFlds, { "FECHA",    "D",  8, 0 } )
        AAdd( aFlds, { "VALIDEZ",  "D",  8, 0 } )
        AAdd( aFlds, { "CLIENTE_", "C", 10, 0 } )
        AAdd( aFlds, { "VENDEDOR", "C", 10, 0 } )
        AAdd( aFlds, { "SUBTOTAL", "N", 12, 2 } )
        AAdd( aFlds, { "IVA",      "N", 12, 2 } )
        AAdd( aFlds, { "TOTAL",    "N", 12, 2 } )
        AAdd( aFlds, { "ESTADO",   "C",  1, 0 } )
        AAdd( aFlds, { "OBSERVA",  "C", 60, 0 } )
        AAdd( aFlds, { "PIE_DOC",  "M", 10, 0 } )
        AAdd( aFlds, { "NUM_FAC",  "C", 10, 0 } )
        AAdd( aFlds, { "ID_OBRA",  "C", 12, 0 } )
        AAdd( aFlds, { "TIPO",     "C",  1, 0 } )
        AAdd( aFlds, { "FORMA_PA", "C",  3, 0 } )
        AAdd( aFlds, { "DIAS_PAG", "N",  3, 0 } )
        AAdd( aFlds, { "RETENCIO", "N", 12, 2 } )
        AAdd( aFlds, { "PORC_RET", "N",  5, 2 } )
        AAdd( aFlds, { "INVERSION","L",  1, 0 } )
        AAdd( aFlds, { "FECHA_ACE","D",  8, 0 } )
        AAdd( aFlds, { "ACEPTA_POR","C",30, 0 } )
        aInds := {}
        AAdd( aInds, { "PRE_NUM", "NUMERO" } )
        AAdd( aInds, { "PRE_CLI", "CLIENTE_" } )
        AAdd( aInds, { "PRE_FEC", "DtoS(FECHA)" } )
        AAdd( aInds, { "PRE_OBR", "ID_OBRA" } )
        AAdd( aAllDefs, { "PRESUPUEST", aFlds, aInds } )

        // =========================================================
        // 12. PRESUP_DE   (Lineas de presupuesto AppGestion)
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "NUMERO",   "C", 10, 0 } )
        AAdd( aFlds, { "LINEA",    "N",  3, 0 } )
        AAdd( aFlds, { "ARTICULO", "C", 15, 0 } )
        AAdd( aFlds, { "DESCRIPC", "C", 60, 0 } )
        AAdd( aFlds, { "CANTIDAD", "N", 10, 4 } )
        AAdd( aFlds, { "PRECIO",   "N", 12, 2 } )
        AAdd( aFlds, { "DESCUENT", "N",  5, 2 } )
        AAdd( aFlds, { "IMPORTE",  "N", 12, 2 } )
        AAdd( aFlds, { "PORC_IVA", "N",  5, 2 } )
        aInds := {}
        AAdd( aInds, { "PRD_LIN", "NUMERO+Str(LINEA,3)" } )
        AAdd( aAllDefs, { "PRESUP_DE", aFlds, aInds } )

    // =========================================================================
    // CREACION FISICA DE TABLAS E INDICES
    // =========================================================================

    FOR i := 1 TO Len( aAllDefs )

        cDbf        := aAllDefs[i, 1]
        aCamposR    := aAllDefs[i, 2]
        aIndicesR   := aAllDefs[i, 3]

        IF File( cDbf + ".DBF" ) .AND. !_TieneCampos( cDbf, aCamposR )
            _BorraDbf( cDbf )
        ENDIF

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


STATIC FUNCTION _TieneCampos( cDbf, aCampos )

    LOCAL aActual := {}
    LOCAL i

    BEGIN SEQUENCE WITH {|oErr| Break( oErr )}
        DbUseArea( .T., "DBFCDX", cDbf, "CHK_DBF", .T., .T. )
        DbSelectArea( "CHK_DBF" )
        aActual := DbStruct()
        DbCloseArea()
    RECOVER
        RETURN .F.
    END SEQUENCE

    FOR i := 1 TO Len( aCampos )
        IF _StructFieldPos( aActual, aCampos[i, 1] ) == 0
            RETURN .F.
        ENDIF
    NEXT

RETURN .T.


STATIC FUNCTION _StructFieldPos( aStruct, cField )

    LOCAL i

    cField := Upper( AllTrim( cField ) )
    FOR i := 1 TO Len( aStruct )
        IF Upper( AllTrim( aStruct[i, 1] ) ) == cField
            RETURN i
        ENDIF
    NEXT

RETURN 0


STATIC FUNCTION _BorraDbf( cDbf )

    LOCAL aExt := { ".DBF", ".CDX", ".FPT", "_NEW.DBF", "_NEW.CDX", "_NEW.FPT" }
    LOCAL i

    IF Select( cDbf ) > 0
        DbSelectArea( cDbf )
        DbCloseArea()
    ENDIF

    FOR i := 1 TO Len( aExt )
        IF File( cDbf + aExt[i] )
            FErase( cDbf + aExt[i] )
        ENDIF
    NEXT

RETURN NIL
