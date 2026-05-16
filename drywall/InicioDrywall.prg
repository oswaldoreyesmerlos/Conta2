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
        AAdd( aFlds, { "L_SUCIO",    "L",  1, 0 } )

        aInds := {}

        AAdd( aAllDefs, { "TMP_CAB", aFlds, aInds, .T. } )

        
        // =========================================================
		// 5. TMP_TRA (TABLA MAESTRA DE TRAMOS)
		// =========================================================
		aFlds := {}
		// --- Identificación ---
		AAdd( aFlds, { "NUMERO",        "C",  6, 0 } ) 
		AAdd( aFlds, { "ID_LINEA",      "N",  4, 0 } ) 
		AAdd( aFlds, { "TIPO_OBRA",     "C", 10, 0 } ) // TABIQUE, TECHO, TRAS_SEM...
		AAdd( aFlds, { "CONCEPTO",      "C", 40, 0 } ) 
		
		// --- Geometría ---
		AAdd( aFlds, { "LARGO",         "N",  6, 2 } ) 
		AAdd( aFlds, { "ALTO",          "N",  6, 2 } ) 
		AAdd( aFlds, { "MODUL",         "N",  5, 2 } ) // Separación Perfil VERTICAL (Placa)
		AAdd( aFlds, { "SISTEMA",       "N",  3, 0 } ) // Ancho de perfileria: 48, 70, 90
		AAdd( aFlds, { "SEP_PRIM",      "N",  5, 2 } ) // Separación Perfil HORIZ (Estructura) - Solo Techos

		// --- Configuración Capas ---
		AAdd( aFlds, { "CARAS",         "N",  1, 0 } ) // 1 o 2 (Auto según sistema)
		AAdd( aFlds, { "PLAC_CARA",     "N",  1, 0 } ) // Nº Capas por cara (1, 2, 3...)

		// --- Materiales Principales ---
		AAdd( aFlds, { "ID_PER_VER",    "C", 15, 0 } )
		AAdd( aFlds, { "ID_PER_HOR",    "C", 15, 0 } )
		AAdd( aFlds, { "ID_PER_PER",    "C", 15, 0 } )
		AAdd( aFlds, { "ID_AISLAN",     "C", 15, 0 } )

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
        AAdd( aFlds, { "UNIDAD",    "C",  3, 0 } ) 
        
        // --- LOGISTICA ---
        AAdd( aFlds, { "PESO_TOT",  "N", 12, 3 } ) // Peso Total Línea (Kg)
		
		AAdd( aFlds, { "RENDIM",    "N",  8, 4 } ) 
        AAdd( aFlds, { "CANTIDAD",  "N", 12, 3 } ) 
        AAdd( aFlds, { "PRECIO",    "N", 10, 2 } ) 
        AAdd( aFlds, { "IMPORTE",   "N", 12, 2 } ) 
        AAdd( aFlds, { "DETALLE",   "C", 30, 0 } )
		
        aInds := {}
        AAdd( aInds, { "MAT_NUM", "NUMERO" } )
        AAdd( aInds, { "MAT_LIN", "NUMERO + Str(ID_LINEA,4)" } )
        AAdd( aInds, { "MAT_COD", "CODIGO" } )

        AAdd( aAllDefs, { "TMP_MAT", aFlds, aInds, .T. } )


        // =========================================================
        // 7. TMP_RES   (Resumen del proyecto temporal)
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "NUMERO",    "C",  6, 0 } ) 
        AAdd( aFlds, { "FAMILIA",   "C", 10, 0 } ) 
        AAdd( aFlds, { "CODIGO",    "C", 15, 0 } ) 
        AAdd( aFlds, { "DESCRIP",   "C", 40, 0 } ) 
        AAdd( aFlds, { "UNIDAD",    "C",  3, 0 } ) 
        AAdd( aFlds, { "CANT_TOT",  "N", 12, 3 } )
		
		// --- LOGISTICA ---
        AAdd( aFlds, { "PESO_TOT",  "N", 12, 3 } ) // Peso Total Agrupado (Kg)
		
        AAdd( aFlds, { "PRECIO",    "N", 10, 2 } ) 
        AAdd( aFlds, { "IMP_TOT",   "N", 12, 2 } )

        aInds := {}
        AAdd( aInds, { "RES_PK", "NUMERO + CODIGO" } )

        AAdd( aAllDefs, { "TMP_RES", aFlds, aInds, .T. } )

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

        aInds := {}
        AAdd( aInds, { "HIS_NUM", "NUMERO" } )
        AAdd( aInds, { "HIS_CLI", "ID_CLIENTE" } )

        AAdd( aAllDefs, { "HIS_CAB", aFlds, aInds } )

        // =========================================================
        // 9. HIS_TRA   (Tramos históricos — espejo de TMP_TRA)
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "NUMERO",        "C",  6, 0 } ) 
		AAdd( aFlds, { "ID_LINEA",      "N",  4, 0 } ) 
		AAdd( aFlds, { "TIPO_OBRA",     "C", 10, 0 } ) // TABIQUE, TECHO, TRAS_SEM...
		AAdd( aFlds, { "CONCEPTO",      "C", 40, 0 } ) 

		// --- Geometría ---
		AAdd( aFlds, { "LARGO",         "N",  6, 2 } ) 
		AAdd( aFlds, { "ALTO",          "N",  6, 2 } ) 
		AAdd( aFlds, { "MODUL",         "N",  5, 2 } ) // Separación Perfil VERTICAL (Placa)
		AAdd( aFlds, { "SISTEMA",       "N",  3, 0 } ) // Ancho de perfileria: 48, 70, 90
		AAdd( aFlds, { "SEP_PRIM",      "N",  5, 2 } ) // Separación Perfil HORIZ (Estructura) - Solo Techos

		// --- Configuración Capas ---
		AAdd( aFlds, { "CARAS",         "N",  1, 0 } ) // 1 o 2 (Auto según sistema)
		AAdd( aFlds, { "PLAC_CARA",     "N",  1, 0 } ) // Nº Capas por cara (1, 2, 3...)

		// --- Materiales Principales ---
		AAdd( aFlds, { "ID_PER_VER",    "C", 15, 0 } )
		AAdd( aFlds, { "ID_PER_HOR",    "C", 15, 0 } )
		AAdd( aFlds, { "ID_PER_PER",    "C", 15, 0 } )
		AAdd( aFlds, { "ID_AISLAN",     "C", 15, 0 } )

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
        AAdd( aInds, { "HTRA_NUM", "NUMERO + Str(ID_LINEA,4)" } )

        AAdd( aAllDefs, { "HIS_TRA", aFlds, aInds } )


        // =========================================================
        // 10. HIS_MAT   (Material histórico — espejo de TMP_MAT)
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
        AAdd( aFlds, { "UNIDAD",    "C",  3, 0 } ) 
        
        // --- LOGISTICA ---
        AAdd( aFlds, { "PESO_TOT",  "N", 12, 3 } ) // Peso Total Línea (Kg)
		
		AAdd( aFlds, { "RENDIM",    "N",  8, 4 } ) 
        AAdd( aFlds, { "CANTIDAD",  "N", 12, 3 } ) 
        AAdd( aFlds, { "PRECIO",    "N", 10, 2 } ) 
        AAdd( aFlds, { "IMPORTE",   "N", 12, 2 } ) 
        AAdd( aFlds, { "DETALLE",   "C", 30, 0 } )

        aInds := {}
        AAdd( aInds, { "HMAT_NUM", "NUMERO" } )
        AAdd( aInds, { "HMAT_LIN", "NUMERO + Str(ID_LINEA,4)" } )

        AAdd( aAllDefs, { "HIS_MAT", aFlds, aInds } )

        // =========================================================
        // 11. HIS_RES   (Resumen histórico — espejo de TMP_RES)
        // =========================================================
        aFlds := {}
        aFlds := {}
        AAdd( aFlds, { "NUMERO",    "C",  6, 0 } )
        AAdd( aFlds, { "FAMILIA",   "C", 10, 0 } ) // Antes faltaba
        AAdd( aFlds, { "CODIGO",    "C", 15, 0 } )
        AAdd( aFlds, { "DESCRIP",   "C", 40, 0 } ) // Antes 60, ahora 40 (igual que TMP)
        AAdd( aFlds, { "UNIDAD",    "C",  3, 0 } ) 
        
        // Nombres unificados
        AAdd( aFlds, { "CANT_TOT",  "N", 12, 3 } ) // Antes CANT_T
        AAdd( aFlds, { "PESO_TOT",  "N", 12, 3 } ) // Antes PESO_T
        AAdd( aFlds, { "PRECIO",    "N", 10, 2 } ) 
        AAdd( aFlds, { "IMP_TOT",   "N", 12, 2 } ) // Antes IMPORT

        aInds := {}
        AAdd( aInds, { "HRES_PK", "NUMERO + CODIGO" } )

        AAdd( aAllDefs, { "HIS_RES", aFlds, aInds } )

        // =========================================================
        // 12. TABLAS_AUX   (Maestro de listas auxiliares)
        // =========================================================
        aFlds := {}
        AAdd( aFlds, { "TIPO",    "C", 10, 0 } )
        AAdd( aFlds, { "CODIGO",  "C", 10, 0 } )
        AAdd( aFlds, { "DESCRIP", "C", 40, 0 } )

        aInds := {}
        AAdd( aInds, { "AUX_PK", "Upper(TIPO) + Upper(CODIGO)" } )

        AAdd( aAllDefs, { "TABLAS_AUX", aFlds, aInds } )

    // =========================================================================
    // CREACION FISICA DE TABLAS E INDICES
    // =========================================================================

    FOR i := 1 TO Len( aAllDefs )

        cDbf        := aAllDefs[i, 1]
        aCamposR    := aAllDefs[i, 2]
        aIndicesR   := aAllDefs[i, 3]

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
