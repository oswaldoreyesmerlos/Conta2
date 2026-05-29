/*
 * SeedDrywall.prg
 * Inserta datos maestros y proyectos de prueba en las tablas Drywall.
 * Ejecutar: SeedDrywall.exe
 */

REQUEST DBFCDX

FUNCTION SeedDrywall()

    _CrearTablas()
    _SeedAuxiliares()
    _SeedArticulos()
    _SeedProyectos()

RETURN NIL


// ============================================================================
// TABLAS_AUX: catalogos para los pickers (_PickArt)
// ============================================================================
STATIC FUNCTION _CrearTablas()

    LOCAL aFlds := {}
    LOCAL aInds := {}
    LOCAL nAreaAnt := Select()
    LOCAL i

    // Crear ARTICULOS si no existe (15 chars CODIGO para códigos tipo "TORN_PM_25")
    IF !File( "ARTICULOS.DBF" )
        AAdd( aFlds, { "CODIGO",    "C", 15, 0 } )
        AAdd( aFlds, { "DESCRIP",   "C", 60, 0 } )
        AAdd( aFlds, { "FAMILIA",   "C", 10, 0 } )
        AAdd( aFlds, { "TIPO",      "C", 10, 0 } )
        AAdd( aFlds, { "PROVEEDO",  "C", 10, 0 } )
        AAdd( aFlds, { "COD_BARR",  "C", 15, 0 } )
        AAdd( aFlds, { "QR_DATA",   "C", 80, 0 } )
        AAdd( aFlds, { "STOCK",     "N", 12, 4 } )
        AAdd( aFlds, { "STO_MIN",   "N", 10, 4 } )
        AAdd( aFlds, { "STO_MAX",   "N", 10, 4 } )
        AAdd( aFlds, { "UNIDAD",    "C",  5, 0 } )
        AAdd( aFlds, { "ES_SERV",   "L",  1, 0 } )
        AAdd( aFlds, { "ESPESOR",   "N",  6, 2 } )
        AAdd( aFlds, { "ANCHO_PERF","N",  3, 0 } )
        AAdd( aFlds, { "LARGO",     "N",  9, 2 } )
        AAdd( aFlds, { "ANCHO",     "N",  9, 2 } )
        AAdd( aFlds, { "PESO_UNI",  "N", 10, 3 } )
        AAdd( aFlds, { "CTA_VTA",   "C", 10, 0 } )
        AAdd( aFlds, { "CTA_COM",   "C", 10, 0 } )
        AAdd( aFlds, { "COSTO_PR",  "N", 12, 4 } )
        AAdd( aFlds, { "PRECIO",    "N", 12, 2 } )
        AAdd( aFlds, { "IVA",       "N",  5, 2 } )
        AAdd( aFlds, { "TIPO_IVA",  "C",  1, 0 } )
        AAdd( aFlds, { "DESCUENT",  "N",  5, 2 } )
        AAdd( aFlds, { "FECHA_AL",  "D",  8, 0 } )
        AAdd( aFlds, { "BAJA",      "L",  1, 0 } )

        AAdd( aInds, { "ART_COD", "CODIGO" } )
        AAdd( aInds, { "ART_DES", "Upper(DESCRIP)" } )
        AAdd( aInds, { "ART_FAM", "FAMILIA" } )
        AAdd( aInds, { "ART_BAR", "COD_BARR" } )

        DbCreate( "ARTICULOS", aFlds, "DBFCDX" )
        USE ARTICULOS EXCLUSIVE VIA "DBFCDX"
        FOR i := 1 TO Len( aInds )
            INDEX ON &( aInds[i, 2] ) TAG ( aInds[i, 1] )
        NEXT
        DbCloseArea()
    ENDIF

    IF nAreaAnt > 0
        dbSelectArea( nAreaAnt )
    ENDIF

RETURN NIL


STATIC FUNCTION _SeedAuxiliares()

    // -- PERFILES --
    _Aux( "PERFIL", "MON_48",    "Montante 48mm x 3m" )
    _Aux( "PERFIL", "MON_70",    "Montante 70mm x 3m" )
    _Aux( "PERFIL", "MON_90",    "Montante 90mm x 3m" )
    _Aux( "PERFIL", "CAN_48",    "Canal 48mm x 3m" )
    _Aux( "PERFIL", "CAN_70",    "Canal 70mm x 3m" )
    _Aux( "PERFIL", "CAN_90",    "Canal 90mm x 3m" )
    _Aux( "PERFIL", "MAS_82x16", "Maestra techo 82x16mm x 4m" )
    _Aux( "PERFIL", "MAS_80x16", "Maestra techo 80x16mm x 4m" )
    _Aux( "PERFIL", "T45",       "Primario techo T-45 x 3m" )
    _Aux( "PERFIL", "T60",       "Primario techo T-60 x 3m" )
    _Aux( "PERFIL", "OMEGA_30",  "Omega 30mm x 3m" )
    _Aux( "PERFIL", "SIERRA_30", "Sierra 30mm x 3m" )
    _Aux( "PERFIL", "TC_46",     "TC 46mm x 3m" )
    _Aux( "PERFIL", "ANG_30",    "Angulo 30x30mm x 3m" )

    // -- PLACAS --
    _Aux( "PLACA", "PLA_N13",    "Placa estandar N 13x1200mm" )
    _Aux( "PLACA", "PLA_N15",    "Placa estandar N 15x1200mm" )
    _Aux( "PLACA", "PLA_H113",   "Placa hidrofuga H1 13x1200mm" )
    _Aux( "PLACA", "PLA_H115",   "Placa hidrofuga H1 15x1200mm" )
    _Aux( "PLACA", "PLA_F13",    "Placa ignifuga F 13x1200mm" )
    _Aux( "PLACA", "PLA_F15",    "Placa ignifuga F 15x1200mm" )
    _Aux( "PLACA", "PLA_I13",    "Placa dureza I 13x1200mm" )
    _Aux( "PLACA", "PLA_OM13",   "Placa Omnia 13x1200mm" )
    _Aux( "PLACA", "PLA_SX13",   "Placa Solidtex 13x1200mm" )

    // -- AISLANTES --
    _Aux( "AISLAN", "LANA_40",   "Lana roca 40mm x m2" )
    _Aux( "AISLAN", "LANA_45",   "Lana roca 45mm x m2" )
    _Aux( "AISLAN", "LANA_50",   "Lana roca 50mm x m2" )
    _Aux( "AISLAN", "LANA_60",   "Lana roca 60mm x m2" )
    _Aux( "AISLAN", "LANA_80",   "Lana roca 80mm x m2" )
    _Aux( "AISLAN", "LANA_90",   "Lana roca 90mm x m2" )
    _Aux( "AISLAN", "POL_20",    "Poliestireno 20mm x m2" )
    _Aux( "AISLAN", "POL_30",    "Poliestireno 30mm x m2" )

    // -- ANCLAJES --
    _Aux( "ANCLAJE", "TACO_LATON","Taco expansion laton" )
    _Aux( "ANCLAJE", "VARILLA_M6","Varilla roscada M6 x m" )
    _Aux( "ANCLAJE", "TUERCA_M6", "Tuerca M6 cuelgue" )
    _Aux( "ANCLAJE", "PIVOT_TC60","Cuelgue perfil TC-60" )
    _Aux( "ANCLAJE", "NONIUS_SUP","Nonius sup suspension" )
    _Aux( "ANCLAJE", "NONIUS_INF","Nonius inf suspension" )
    _Aux( "ANCLAJE", "NONIUS_PAS","Pasador nonius" )
    _Aux( "ANCLAJE", "HORQ_TC60", "Horquilla directa TC-60" )
    _Aux( "ANCLAJE", "TORN_MM_LN","Tornillo metal-metal largo" )

    // -- TORNILLERIA --
    _Aux( "TORNILLO", "TORN_PM_25", "Tornillo punta m. 25mm" )
    _Aux( "TORNILLO", "TORN_PM_35", "Tornillo punta m. 35mm" )
    _Aux( "TORNILLO", "TORN_PM_45", "Tornillo punta m. 45mm" )
    _Aux( "TORNILLO", "TORN_MM_9",  "Tornillo metal-metal 9mm" )
    _Aux( "TORNILLO", "TORN_MM_13", "Tornillo metal-metal 13mm" )

    // -- PASTAS --
    _Aux( "PASTA", "PASTA_JUNT", "Pasta juntas 20kg" )
    _Aux( "PASTA", "PASTA_JF",   "Pasta juntas fraguado rapido 5kg" )
    _Aux( "PASTA", "PASTA_AGAR", "Pasta agarre 20kg" )

    // -- CINTAS --
    _Aux( "CINTA", "CINTA_PAP",  "Cinta papel juntas 90m" )
    _Aux( "CINTA", "CINTA_PAP50","Cinta papel juntas 50m" )
    _Aux( "CINTA", "CINTA_GUAR", "Cinta guardavivos" )

    // -- ACCESORIOS --
    _Aux( "ACCESORIO", "BANDA_ACUS", "Banda estanqueidad acustica" )
    _Aux( "ACCESORIO", "PIEZA_CRUCE","Pieza cruce primario-secundario" )
    _Aux( "ACCESORIO", "ESQUINERO",  "Esquinero metalico" )

    // -- GENERICOS (materiales varios) --
    _Aux( "GENERICO", "LAD_H10",   "Ladrillo hueco 10cm x m2" )
    _Aux( "GENERICO", "LAD_H7",    "Ladrillo hueco 7cm x m2" )
    _Aux( "GENERICO", "BLO_L20",   "Bloque hormigon 20cm x m2" )
    _Aux( "GENERICO", "MORTERO",   "Mortero cemento x m2" )
    _Aux( "GENERICO", "FIBRA_40",  "Fibra vidrio 40mm x m2" )

    _Log( "TABLAS_AUX" )

RETURN NIL


STATIC FUNCTION _Aux( cTipo, cCod, cDesc )

    IF Select( "TABLAS_AUX" ) == 0
        USE TABLAS_AUX NEW SHARED VIA "DBFCDX"
    ENDIF
    dbSelectArea( "TABLAS_AUX" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->TIPO ) == cTipo .AND. AllTrim( FIELD->CODIGO ) == cCod
            RETURN NIL  // ya existe
        ENDIF
        dbSkip()
    ENDDO
    IF FLock()
        DbAppend()
        REPLACE FIELD->TIPO    WITH cTipo
        REPLACE FIELD->CODIGO  WITH cCod
        REPLACE FIELD->DESCRIP WITH cDesc
        DbCommit()
        dbUnlock()
    ENDIF

RETURN NIL


// ============================================================================
// ARTICULOS: catalogo de materiales con precios
// ============================================================================
STATIC FUNCTION _SeedArticulos()

    // ============================
    // PERFILES (ud, 3m salvo indicados)
    // ============================
    _Art( "MON_48",    "Montante 48mm x 3m",            "PERFIL", "ud", 3.25,   48, 3000, 0,   0.800 )
    _Art( "MON_70",    "Montante 70mm x 3m",            "PERFIL", "ud", 4.50,   70, 3000, 0,   1.050 )
    _Art( "MON_90",    "Montante 90mm x 3m",            "PERFIL", "ud", 5.50,   90, 3000, 0,   1.350 )
    _Art( "CAN_48",    "Canal 48mm x 3m",               "PERFIL", "ud", 2.75,   48, 3000, 0,   0.650 )
    _Art( "CAN_70",    "Canal 70mm x 3m",               "PERFIL", "ud", 3.50,   70, 3000, 0,   0.850 )
    _Art( "CAN_90",    "Canal 90mm x 3m",               "PERFIL", "ud", 4.25,   90, 3000, 0,   1.100 )
    _Art( "MAS_82x16", "Maestra techo 82x16mm x 4m",    "PERFIL", "ud", 6.50,   82, 4000, 16,  0.750 )
    _Art( "MAS_80x16", "Maestra techo 80x16mm x 4m",    "PERFIL", "ud", 6.00,   80, 4000, 16,  0.700 )
    _Art( "T45",       "Primario techo T-45 x 3m",      "PERFIL", "ud", 4.50,   45, 3000, 0,   0.400 )
    _Art( "T60",       "Primario techo T-60 x 3m",      "PERFIL", "ud", 5.20,   60, 3000, 0,   0.550 )
    _Art( "OMEGA_30",  "Omega 30mm x 3m",               "PERFIL", "ud", 4.00,   30, 3000, 0,   0.350 )
    _Art( "SIERRA_30", "Sierra 30mm x 3m",              "PERFIL", "ud", 3.89,   30, 3000, 0,   0.300 )
    _Art( "TC_46",     "TC 46mm x 3m",                  "PERFIL", "ud", 2.10,   46, 3000, 0,   0.250 )
    _Art( "ANG_30",    "Angulo 30x30mm x 3m",           "PERFIL", "ud", 2.67,   30, 3000, 0,   0.220 )

    // ============================
    // PLACAS (ud, 1200mm ancho)
    // ============================
    _Art( "PLA_N13",   "Placa estandar N 13x1200",      "PLACA",  "ud",14.50,  13, 2500, 1200, 20.000 )
    _Art( "PLA_N15",   "Placa estandar N 15x1200",      "PLACA",  "ud",22.00,  15, 2500, 1200, 25.000 )
    _Art( "PLA_H113",  "Placa hidrofuga H1 13x1200",    "PLACA",  "ud",19.50,  13, 2500, 1200, 21.500 )
    _Art( "PLA_H115",  "Placa hidrofuga H1 15x1200",    "PLACA",  "ud",27.00,  15, 2700, 1200, 28.000 )
    _Art( "PLA_F13",   "Placa ignifuga F 13x1200",      "PLACA",  "ud",23.00,  13, 2500, 1200, 21.000 )
    _Art( "PLA_F15",   "Placa ignifuga F 15x1200",      "PLACA",  "ud",32.00,  15, 2500, 1200, 26.000 )
    _Art( "PLA_I13",   "Placa dureza I 13x1200",        "PLACA",  "ud",26.00,  13, 2500, 1200, 22.000 )
    _Art( "PLA_OM13",  "Placa Omnia 13x1200",           "PLACA",  "ud",21.00,  13, 2500, 1200, 21.000 )
    _Art( "PLA_SX13",  "Placa Solidtex 13x1200",        "PLACA",  "ud",29.00,  13, 2500, 1200, 23.500 )

    // ============================
    // AISLANTES (m2)
    // ============================
    _Art( "LANA_40",   "Lana roca 40mm x m2",          "AISLAN", "m2", 2.50,   40,  0, 0,  10.000 )
    _Art( "LANA_45",   "Lana roca 45mm x m2",          "AISLAN", "m2", 3.00,   45,  0, 0,  12.000 )
    _Art( "LANA_50",   "Lana roca 50mm x m2",          "AISLAN", "m2", 3.50,   50,  0, 0,  14.000 )
    _Art( "LANA_60",   "Lana roca 60mm x m2",          "AISLAN", "m2", 4.00,   60,  0, 0,  16.000 )
    _Art( "LANA_80",   "Lana roca 80mm x m2",          "AISLAN", "m2", 5.00,   80,  0, 0,  20.000 )
    _Art( "LANA_90",   "Lana roca 90mm x m2",          "AISLAN", "m2", 5.50,   90,  0, 0,  22.000 )
    _Art( "POL_20",    "Poliestireno 20mm x m2",       "AISLAN", "m2", 1.80,   20,  0, 0,   0.500 )
    _Art( "POL_30",    "Poliestireno 30mm x m2",       "AISLAN", "m2", 2.50,   30,  0, 0,   0.750 )

    // ============================
    // TORNILLERIA (caja)
    // ============================
    _Art( "TORN_PM_25","Tornillo punta m. 25mm",       "TORNILLO","caja",8.26, 0, 0, 0, 0 )
    _Art( "TORN_PM_35","Tornillo punta m. 35mm",       "TORNILLO","caja",9.50, 0, 0, 0, 0 )
    _Art( "TORN_PM_45","Tornillo punta m. 45mm",       "TORNILLO","caja",11.00,0, 0, 0, 0 )
    _Art( "TORN_MM_9", "Tornillo metal-metal 9mm",     "TORNILLO","caja",9.00, 0, 0, 0, 0 )
    _Art( "TORN_MM_13","Tornillo metal-metal 13mm",    "TORNILLO","caja",10.50,0, 0, 0, 0 )

    // ============================
    // PASTAS
    // ============================
    _Art( "PASTA_JUNT","Pasta juntas 20kg",            "PASTA",  "saco",15.99, 0, 0, 0, 20.000 )
    _Art( "PASTA_JF",  "Pasta juntas fraguado 5kg",    "PASTA",  "saco",8.50,  0, 0, 0,  5.000 )
    _Art( "PASTA_AGAR","Pasta agarre 20kg",            "PASTA",  "saco",9.70,  0, 0, 0, 20.000 )

    // ============================
    // CINTAS
    // ============================
    _Art( "CINTA_PAP", "Cinta papel juntas 90m",       "CINTA",  "rollo",5.95, 0, 0, 0, 0.200 )
    _Art( "CINTA_PAP50","Cinta papel juntas 50m",      "CINTA",  "rollo",3.50, 0, 0, 0, 0.120 )
    _Art( "CINTA_GUAR","Cinta guardavivos",            "CINTA",  "ud",12.60,  0, 0, 0, 0.150 )

    // ============================
    // ACCESORIOS
    // ============================
    _Art( "BANDA_ACUS","Banda estanqueidad acustica",  "ACCESORIO","rollo", 2.50, 0, 30000, 0, 0.050 )
    _Art( "PIEZA_CRUCE","Pieza cruce primario-sec",    "ACCESORIO","ud", 1.20, 0, 0, 0, 0.020 )
    _Art( "ESQUINERO", "Esquinero metalico",            "ACCESORIO","ud", 0.90, 0, 0, 0, 0.030 )

    // ============================
    // ANCLAJES
    // ============================
    _Art( "TACO_LATON","Taco expansion laton",          "ANCLAJE","ud",  0.35, 0, 0, 0, 0 )
    _Art( "VARILLA_M6","Varilla roscada M6 x m",        "ANCLAJE","m",   1.20, 6, 0, 0, 0.220 )
    _Art( "TUERCA_M6", "Tuerca M6 cuelgue",             "ANCLAJE","ud",  0.15, 0, 0, 0, 0 )
    _Art( "PIVOT_TC60","Cuelgue perfil TC-60",          "ANCLAJE","ud",  0.80, 0, 0, 0, 0.050 )
    _Art( "NONIUS_SUP","Nonius superior suspension",    "ANCLAJE","ud",  1.50, 0, 0, 0, 0.080 )
    _Art( "NONIUS_INF","Nonius inferior suspension",    "ANCLAJE","ud",  1.50, 0, 0, 0, 0.080 )
    _Art( "NONIUS_PAS","Pasador nonius",                "ANCLAJE","ud",  0.25, 0, 0, 0, 0 )
    _Art( "HORQ_TC60", "Horquilla directa TC-60",       "ANCLAJE","ud",  1.80, 0, 0, 0, 0.100 )
    _Art( "TORN_MM_LN","Tornillo metal-metal largo",    "ANCLAJE","ud",  0.20, 0, 0, 0, 0 )

    // ============================
    // GENERICOS
    // ============================
    _Art( "LAD_H10",   "Ladrillo hueco 10cm x m2",     "GENERICO","m2", 8.00, 100,0, 0, 80.000 )
    _Art( "LAD_H7",    "Ladrillo hueco 7cm x m2",      "GENERICO","m2", 6.50, 70, 0, 0, 60.000 )
    _Art( "BLO_L20",   "Bloque hormigon 20cm x m2",    "GENERICO","m2",12.00, 200,0, 0, 150.00 )
    _Art( "MORTERO",   "Mortero cemento x m2",         "GENERICO","m2", 3.00, 0,  0, 0, 4.000 )
    _Art( "FIBRA_40",  "Fibra vidrio 40mm x m2",       "GENERICO","m2", 4.00, 40, 0, 0, 0.500 )

    _Log( "ARTICULOS" )

RETURN NIL


STATIC FUNCTION _Art( cCod, cDesc, cFam, cUd, nPre, nEsp, nLar, nAnc, nPeso )

    LOCAL nAnchoPerf := 0

    IF ValType( nPeso ) != "N"
        nPeso := 0
    ENDIF

    IF Upper( AllTrim( cFam ) ) == "PERFIL" .AND. AScan( { 48, 70, 90 }, nEsp ) > 0
        nAnchoPerf := nEsp
    ENDIF

    IF Select( "ARTICULOS" ) == 0
        USE ARTICULOS NEW SHARED VIA "DBFCDX"
    ENDIF
    dbSelectArea( "ARTICULOS" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->CODIGO ) == cCod
            RETURN NIL
        ENDIF
        dbSkip()
    ENDDO
    IF FLock()
        DbAppend()
        REPLACE FIELD->CODIGO   WITH cCod
        REPLACE FIELD->DESCRIP  WITH cDesc
        REPLACE FIELD->FAMILIA  WITH cFam
        REPLACE FIELD->UNIDAD   WITH cUd
        REPLACE FIELD->PRECIO   WITH nPre
        REPLACE FIELD->ESPESOR  WITH nEsp
        IF FieldPos( "ANCHO_PERF" ) > 0
            REPLACE FIELD->ANCHO_PERF WITH nAnchoPerf
        ENDIF
        REPLACE FIELD->LARGO    WITH nLar
        REPLACE FIELD->ANCHO    WITH nAnc
        REPLACE FIELD->PESO_UNI WITH nPeso
        DbCommit()
        dbUnlock()
    ENDIF

RETURN NIL


// ============================================================================
// PROYECTOS DE PRUEBA
// ============================================================================
STATIC FUNCTION _SeedProyectos()

    _LimpiarTmp()
    _Proyecto( "PR001", "Banyo 6 modulos", "TST0001", "Banyo completo 6m" )
    _Proyecto( "PR002", "Reforma salon 30m2", "TST0002", "Tabiques + techo continuo" )

    _Log( "Proyectos" )

RETURN NIL


STATIC FUNCTION _LimpiarTmp()

    _Zap( "TMP_CAB" )
    _Zap( "TMP_TRA" )
    _Zap( "TMP_MAT" )
    _Zap( "TMP_RES" )

RETURN NIL


STATIC FUNCTION _Zap( cAlias )

    LOCAL cAreaAnt := Alias()

    IF Select( cAlias ) > 0
        dbSelectArea( cAlias )
        dbCloseArea()
    ENDIF

    BEGIN SEQUENCE WITH {|oErr| Break( oErr )}
        USE ( cAlias ) NEW EXCLUSIVE VIA "DBFCDX" ALIAS ( cAlias )
        __dbZap()
        DbCloseArea()
    RECOVER
    END SEQUENCE

    IF !Empty( cAreaAnt ) .AND. Select( cAreaAnt ) > 0
        dbSelectArea( cAreaAnt )
    ENDIF

RETURN NIL


STATIC FUNCTION _Log( cMsg )
    ? "  " + cMsg
RETURN NIL


STATIC FUNCTION _Proyecto( cNum, cTit, cCli, cObs )

    LOCAL nArea := Select()

    // --- TMP_CAB (cabecera) ---
    IF Select("TMP_CAB") == 0
        USE TMP_CAB NEW SHARED VIA "DBFCDX"
    ENDIF
    dbSelectArea("TMP_CAB")
    dbGoTop()
    IF !Empty( FIELD->NUMERO )
        ? "Proyecto " + cNum + " ya existe, saltando."
        dbSelectArea( nArea )
        RETURN NIL
    ENDIF
    IF FLock()
        DbAppend()
        REPLACE FIELD->NUMERO     WITH cNum
        REPLACE FIELD->FECHA      WITH Date()
        REPLACE FIELD->TITULO     WITH cTit
        REPLACE FIELD->ID_CLIENTE WITH cCli
        REPLACE FIELD->ESTADO     WITH "P"
        REPLACE FIELD->MARGEN     WITH 0
        REPLACE FIELD->OBSERV     WITH cObs
        REPLACE FIELD->L_SUCIO    WITH .T.
        DbCommit()
        dbUnlock()
    ENDIF

    // --- TMP_TRA (tramos segun tipo de proyecto) ---
    DO CASE
    CASE cNum == "PR001"
        _Tramo( cNum, 1, "GENERICO", "Pared exterior ladrillo",  7.50, 2.70, 0.60, "LAD_H10" )
        _Tramo( cNum, 2, "TABIQUE", "Tabique separador 48mm",    5.90, 2.70, 0.60, "PLA_N13" )
        _Tramo( cNum, 3, "TECHO",   "Techo continuo 80x16",      7.50, 3.00, 0.50, "PLA_N13" )

    CASE cNum == "PR002"
        _Tramo( cNum, 1, "TABIQUE", "Tabique separador 70mm",   8.00, 2.70, 0.60, "PLA_H113" )
        _Tramo( cNum, 2, "TECHO",   "Techo pladur 82x16",       6.00, 4.00, 0.50, "PLA_N13" )
        _Tramo( cNum, 3, "TRASDOSADO_AUT", "Trasdosado autoportante", 4.00, 2.70, 0.60, "PLA_H113" )

    ENDCASE

    ? "Proyecto " + cNum + ": " + cTit + " creado."
    dbSelectArea( nArea )

RETURN NIL


STATIC FUNCTION _Tramo( cNum, nLin, cTipo, cConc, nLar, nAlt, nMod, cPlaca )

    IF Select("TMP_TRA") == 0
        USE TMP_TRA NEW SHARED VIA "DBFCDX"
    ENDIF
    dbSelectArea("TMP_TRA")

    IF FLock()
        DbAppend()
        REPLACE FIELD->NUMERO     WITH cNum
        REPLACE FIELD->ID_LINEA   WITH nLin
        REPLACE FIELD->TIPO_OBRA  WITH cTipo
        REPLACE FIELD->CONCEPTO   WITH cConc
        REPLACE FIELD->LARGO      WITH nLar
        REPLACE FIELD->ALTO       WITH nAlt
        REPLACE FIELD->MODUL      WITH nMod
        REPLACE FIELD->ID_PLACA_A WITH cPlaca
        REPLACE FIELD->PLAC_CARA  WITH 1
        REPLACE FIELD->CARAS      WITH 1
        DbCommit()
        dbUnlock()
    ENDIF

RETURN NIL
