/*
 * SeedDrywall.prg
 * Inserta datos maestros y proyectos de prueba en las tablas Drywall.
 * Ejecutar: SeedDrywall.exe
 */

REQUEST DBFCDX

FUNCTION Main()

    rddSetDefault("DBFCDX")
    SET DEFAULT TO "C:/Users/ferna/Desktop/Prgs/GptWvg/GfxStack/DATA"

    ? "Sembrando datos maestros..."

    _SeedAuxiliares()
    _SeedArticulos()
    _SeedProyectos()

    ? ""
    ? "Datos de prueba creados."
    ? "Abrir Drywall -> Proyecto -> Definir Tramos"

RETURN 0


// ============================================================================
// TABLAS_AUX: catalogos para los pickers (_PickArt)
// ============================================================================
STATIC FUNCTION _SeedAuxiliares()

    // -- PERFILES --
    _Aux( "PERFIL", "MON_48",    "Montante 48mm x 3m" )
    _Aux( "PERFIL", "MON_70",    "Montante 70mm x 3m" )
    _Aux( "PERFIL", "MON_90",    "Montante 90mm x 3m" )
    _Aux( "PERFIL", "CAN_48",    "Canal 48mm x 3m" )
    _Aux( "PERFIL", "CAN_70",    "Canal 70mm x 3m" )
    _Aux( "PERFIL", "CAN_90",    "Canal 90mm x 3m" )
    _Aux( "PERFIL", "OMEGA_30",  "Perfil Omega 30mm x 3m" )
    _Aux( "PERFIL", "SIERRA_30", "Perfil Sierra 30mm x 3m" )
    _Aux( "PERFIL", "TC_46",     "Perfil TC 46mm x 3m" )
    _Aux( "PERFIL", "ANG_30",    "Angulo 30x30mm x 3m" )

    // -- PLACAS --
    _Aux( "PLACA", "PLA_15M",   "Placa hidrofuga 2,70m x 15mm" )
    _Aux( "PLACA", "PLA_13M",   "Placa hidrofuga 2,50m x 13mm" )
    _Aux( "PLACA", "PLA_ST15",  "Placa estandar 2,70m x 15mm" )
    _Aux( "PLACA", "PLA_ST13",  "Placa estandar 2,50m x 13mm" )

    // -- AISLANTES --
    _Aux( "AISLAN", "LANA_50",  "Lana roca 400mm x 50mm" )
    _Aux( "AISLAN", "LANA_80",  "Lana roca 400mm x 80mm" )
    _Aux( "AISLAN", "POL_30",   "Poliestireno 30mm" )

    // -- ANCLAJES --
    _Aux( "ANCLAJE", "VARILLA", "Varilla roscada M6" )
    _Aux( "ANCLAJE", "NONIUS",  "Nonius suspension" )
    _Aux( "ANCLAJE", "DIRECT",  "Horquilla directa" )

    // -- TORNILLERIA --
    _Aux( "TORNILLO", "TORN_PM_25", "Tornillo punta m. 25mm" )
    _Aux( "TORNILLO", "TORN_PM_35", "Tornillo punta m. 35mm" )
    _Aux( "TORNILLO", "TORN_MM_9",  "Tornillo metal-metal 9mm" )

    // -- PASTAS --
    _Aux( "PASTA", "PASTA_JUNT", "Pasta para juntas 20kg" )
    _Aux( "PASTA", "PASTA_AGAR", "Pasta de agarre 20kg" )

    // -- CINTAS --
    _Aux( "CINTA", "CINTA_PAP",  "Cinta papel juntas 90m" )
    _Aux( "CINTA", "CINTA_GUAR", "Cinta guardavivos" )

    // -- ACCESORIOS --
    _Aux( "ACCESORIO", "BANDA_ACUS", "Banda estanqueidad acustica" )
    _Aux( "ACCESORIO", "PIEZA_CRUCE","Pieza de cruce prim-sec" )

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

    // Perfiles
    _Art( "MON_48",    "Montante 48mm x 3m",     "PERFIL", "ud", 3.25, 48, 3000, 0 )
    _Art( "CAN_48",    "Canal 48mm x 3m",        "PERFIL", "ud", 2.75, 48, 3000, 0 )
    _Art( "OMEGA_30",  "Perfil Omega 30mm x 3m", "PERFIL", "ud", 4.00, 30, 3000, 0 )
    _Art( "SIERRA_30", "Perfil Sierra 30mm x 3m","PERFIL", "ud", 3.89, 30, 3000, 0 )
    _Art( "TC_46",     "Perfil TC 46mm x 3m",    "PERFIL", "ud", 2.10, 46, 3000, 0 )
    _Art( "ANG_30",    "Angulo 30x30mm x 3m",    "PERFIL", "ud", 2.67, 30, 3000, 0 )

    // Placas
    _Art( "PLA_15M",   "Placa hidrofuga 2,70x15mm", "PLACA", "ud", 25.00, 15, 2700, 600 )
    _Art( "PLA_13M",   "Placa hidrofuga 2,50x13mm", "PLACA", "ud", 16.75, 13, 2500, 600 )
    _Art( "PLA_ST15",  "Placa estandar 2,70x15mm",  "PLACA", "ud", 22.00, 15, 2700, 600 )
    _Art( "PLA_ST13",  "Placa estandar 2,50x13mm",  "PLACA", "ud", 14.50, 13, 2500, 600 )

    // Aislantes
    _Art( "LANA_50",   "Lana roca 400x50mm",   "AISLAN", "m2", 3.00, 50, 0, 0 )
    _Art( "LANA_80",   "Lana roca 400x80mm",   "AISLAN", "m2", 4.50, 80, 0, 0 )

    // Tornilleria
    _Art( "TORN_PM_25","Tornillo punta m. 25mm","TORNILLO","caja",8.26, 0, 0, 0 )
    _Art( "TORN_PM_35","Tornillo punta m. 35mm","TORNILLO","caja",9.50, 0, 0, 0 )
    _Art( "TORN_MM_9", "Tornillo metal 9mm",    "TORNILLO","caja",9.00, 0, 0, 0 )

    // Pastas
    _Art( "PASTA_JUNT","Pasta juntas 20kg",  "PASTA", "saco", 15.99, 0, 0, 0 )
    _Art( "PASTA_AGAR","Pasta agarre 20kg",  "PASTA", "saco", 9.70,  0, 0, 0 )

    // Cintas
    _Art( "CINTA_PAP", "Cinta papel 90m",    "CINTA", "rollo",5.95,  0, 0, 0 )
    _Art( "CINTA_GUAR","Cinta guardavivos",  "CINTA", "ud",   12.60, 0, 0, 0 )

    // Accesorios
    _Art( "BANDA_ACUS","Banda estanqueidad", "ACCESORIO","m", 2.50, 0, 0, 0 )
    _Art( "PIEZA_CRUCE","Pieza cruce",       "ACCESORIO","ud",1.20, 0, 0, 0 )

    _Log( "ARTICULOS" )

RETURN NIL


STATIC FUNCTION _Art( cCod, cDesc, cFam, cUd, nPre, nEsp, nLar, nAnc, nPeso )

    IF ValType( nPeso ) != "N"
        nPeso := 0
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

    _Proyecto( "PR001", "Banyo 6 modulos", "TST0001", "Banyo completo 6m" )
    _Proyecto( "PR002", "Reforma salon 30m2", "TST0002", "Tabiques + techo continuo" )

    _Log( "Proyectos" )

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
        _Tramo( cNum, 1, "GENERICO", "Pared exterior ladrillo", 7.50, 2.70, 0.60, "LAD_H10" )
        _Tramo( cNum, 2, "GENERICO", "Tabique interior pladur",  5.90, 2.70, 0.60, "PLA_15M" )
        _Tramo( cNum, 3, "GENERICO", "Falso techo continuo",     7.50, 2.70, 0.50, "PLA_13M" )

    CASE cNum == "PR002"
        _Tramo( cNum, 1, "TABIQUE", "Tabique separador",  8.00, 2.70, 0.60, "PLA_15M" )
        _Tramo( cNum, 2, "TECHO",   "Techo pladur",       6.00, 4.00, 0.50, "PLA_13M" )
        _Tramo( cNum, 3, "TRASDOSADO", "Trasdosado pared", 4.00, 2.70, 0.60, "PLA_15M" )

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
