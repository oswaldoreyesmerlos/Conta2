#include "inkey.ch"
#include "fileio.ch"

REQUEST DBFCDX

#define TEST_PROJECT "TSTSAT"
#define TEST_LINES   320

PROCEDURE Main()

    LOCAL oCalc
    LOCAL nMat
    LOCAL nLines
    LOCAL nOk := 0
    LOCAL nFail := 0
    LOCAL nStart
    LOCAL nElapsed

    RddSetDefault( "DBFCDX" )
    SET EXCLUSIVE OFF
    SET DELETED ON

    FErase( "TestOopSaturacion.log" )
    _Trace( "Inicio" )

    ? "Test saturacion OOPTRAMO"
    ? "Proyecto temporal:", TEST_PROJECT
    ?

    IF !_OpenTables()
        _Trace( "Fallo abriendo tablas" )
        ? "ERROR: no se pudieron abrir las tablas necesarias."
        RETURN
    ENDIF
    _Trace( "Tablas abiertas" )

    IF !_RequireArticles()
        _Trace( "Faltan articulos" )
        _CloseAll()
        RETURN
    ENDIF
    _Trace( "Articulos verificados" )

    _CleanProject( "TMP_MAT", TEST_PROJECT )
    _CleanProject( "TMP_TRA", TEST_PROJECT )
    _Trace( "Proyecto limpio" )

    IF !_SeedFixtures()
        _Trace( "Fallo seed fixtures" )
        ? "ERROR: no se pudieron crear tramos de prueba."
        _CleanProject( "TMP_MAT", TEST_PROJECT )
        _CleanProject( "TMP_TRA", TEST_PROJECT )
        _CloseAll()
        RETURN
    ENDIF
    _Trace( "Fixtures creados" )

    dbSelectArea( "TMP_TRA" )
    dbGoTop()

    _Trace( "Antes de OOPTRAMO" )
    nStart := Seconds()
    oCalc := OOPTRAMO():New()
    oCalc:Procesar( .T. )
    nElapsed := Seconds() - nStart
    _Trace( "Despues de OOPTRAMO" )

    nLines := _CountProject( "TMP_TRA", TEST_PROJECT )
    nMat   := _CountProject( "TMP_MAT", TEST_PROJECT )

    _Assert( "Tramos generados", nLines == TEST_LINES, @nOk, @nFail )
    _Assert( "Materiales generados", nMat > TEST_LINES, @nOk, @nFail )
    _Assert( "Errores OOPTRAMO", oCalc:nErrores == 0, @nOk, @nFail )
    _Assert( "Techo con primario genera T45", _HasCodeLine( 3, "T45" ), @nOk, @nFail )
    _Assert( "Techo con primario genera pieza cruce", _HasCodeLine( 3, "PIEZA_CRUCE" ), @nOk, @nFail )
    _Assert( "Techo sin primario no genera T45", !_HasCodeLine( 4, "T45" ), @nOk, @nFail )
    _Assert( "Techo sin primario no genera pieza cruce", !_HasCodeLine( 4, "PIEZA_CRUCE" ), @nOk, @nFail )
    _Assert( "Sistema SYS_REND genera pasta", _HasCodeLine( 1, "PASTA_JUNT" ), @nOk, @nFail )
    _Assert( "Fallback tabique genera canal", _HasCodeLine( 2, "CAN_48" ), @nOk, @nFail )
    _Assert( "Trasdosado directo genera pasta agarre", _HasCodeLine( 7, "PASTA_AGAR" ), @nOk, @nFail )

    IF oCalc:nErrores > 0
        _PrintErrors( oCalc )
    ENDIF

    ?
    ? "Tramos:", nLines
    ? "Lineas TMP_MAT:", nMat
    ? "Tiempo seg.:", LTrim( Str( nElapsed, 10, 3 ) )
    ? "OK:", nOk, "FAIL:", nFail
    _Trace( "Resumen tramos=" + AllTrim( Str( nLines ) ) + ;
            " tmp_mat=" + AllTrim( Str( nMat ) ) + ;
            " errores=" + AllTrim( Str( oCalc:nErrores ) ) + ;
            " ok=" + AllTrim( Str( nOk ) ) + ;
            " fail=" + AllTrim( Str( nFail ) ) + ;
            " tiempo=" + LTrim( Str( nElapsed, 10, 3 ) ) )

    _CleanProject( "TMP_MAT", TEST_PROJECT )
    _CleanProject( "TMP_TRA", TEST_PROJECT )
    _Trace( "Proyecto limpiado al final" )
    _CloseAll()

    IF nFail == 0
        ? "RESULTADO: OK"
        _Trace( "RESULTADO OK" )
    ELSE
        ? "RESULTADO: FALLA"
        _Trace( "RESULTADO FALLA" )
    ENDIF

RETURN


FUNCTION DrywallProyectoActualNumero()

RETURN TEST_PROJECT


FUNCTION NetFLock()

RETURN .T.


FUNCTION NetRLock()

RETURN RLock()


FUNCTION Ceiling( nValue )

    LOCAL nInt := Int( nValue )

    IF nValue > nInt
        nInt++
    ENDIF

RETURN nInt


STATIC FUNCTION _OpenTables()

    LOCAL cData := "test_tmp\"
    LOCAL aTabs := { "ARTICULOS", "SYS_REND", "TMP_TRA", "TMP_MAT" }
    LOCAL i

    IF !_PrepareTables( cData )
        RETURN .F.
    ENDIF

    FOR i := 1 TO Len( aTabs )
        BEGIN SEQUENCE WITH {|oErr| Break( oErr )}
            USE ( cData + aTabs[i] ) NEW EXCLUSIVE VIA "DBFCDX" ALIAS ( aTabs[i] )
        RECOVER
            ? "No se pudo abrir:", aTabs[i]
            RETURN .F.
        END SEQUENCE
    NEXT

RETURN .T.


STATIC FUNCTION _PrepareTables( cPath )

    IF !hb_DirExists( cPath )
        hb_DirCreate( cPath )
    ENDIF

    _EraseTable( cPath, "ARTICULOS" )
    _EraseTable( cPath, "SYS_REND" )
    _EraseTable( cPath, "TMP_TRA" )
    _EraseTable( cPath, "TMP_MAT" )

    _CreateArticulos( cPath )
    _CreateSysRend( cPath )
    _CreateTmpTra( cPath )
    _CreateTmpMat( cPath )

RETURN .T.


STATIC FUNCTION _EraseTable( cPath, cName )

    FErase( cPath + cName + ".dbf" )
    FErase( cPath + cName + ".cdx" )
    FErase( cPath + cName + ".fpt" )

RETURN NIL


STATIC FUNCTION _CreateArticulos( cPath )

    LOCAL aFlds := {}

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

    DbCreate( cPath + "ARTICULOS", aFlds, "DBFCDX" )
    USE ( cPath + "ARTICULOS" ) NEW EXCLUSIVE VIA "DBFCDX" ALIAS ARTICULOS

    _AddArt( "MON_48",     "Montante 48mm x 3m",           "PERFIL",    "ud",    3.25, 3000, 0,    0.800 )
    _AddArt( "CAN_48",     "Canal 48mm x 3m",              "PERFIL",    "ud",    2.75, 3000, 0,    0.650 )
    _AddArt( "MAS_82X16",  "Maestra techo 82x16mm x 4m",   "PERFIL",    "ud",    6.50, 4000, 16,   0.750 )
    _AddArt( "T45",        "Primario techo T-45 x 3m",     "PERFIL",    "ud",    4.50, 3000, 0,    0.400 )
    _AddArt( "ANG_30",     "Angulo 30x30mm x 3m",          "PERFIL",    "ud",    2.67, 3000, 0,    0.220 )
    _AddArt( "PLA_N13",    "Placa estandar N 13x1200",     "PLACA",     "ud",   14.50, 2500, 1200,20.000 )
    _AddArt( "LANA_40",    "Lana roca 40mm x m2",          "AISLAN",    "m2",    2.50, 0,    0,   10.000 )
    _AddArt( "PASTA_JUNT", "Pasta juntas 20kg",            "PASTA",     "saco", 15.99, 0,    0,   20.000 )
    _AddArt( "PASTA_AGAR", "Pasta agarre 20kg",            "PASTA",     "saco",  9.70, 0,    0,   20.000 )
    _AddArt( "CINTA_PAP",  "Cinta papel juntas 90m",       "CINTA",     "rollo", 5.95, 0,    0,    0.200 )
    _AddArt( "TORN_PM_25", "Tornillo PM 25mm caja 1000",   "TORNILLO",  "caja",  8.95, 0,    0,    0.001 )
    _AddArt( "BANDA_ACUS", "Banda estanqueidad acustica",  "ACCESORIO", "rollo", 2.50, 30000,0,    0.050 )
    _AddArt( "PIEZA_CRUCE","Pieza cruce primario-sec",     "ACCESORIO", "ud",    1.20, 0,    0,    0.020 )
    _AddArt( "TACO_LATON", "Taco expansion laton",         "ANCLAJE",   "ud",    0.35, 0,    0,    0.000 )
    _AddArt( "VARILLA_M6", "Varilla roscada M6 x m",       "ANCLAJE",   "m",     1.20, 0,    0,    0.220 )
    _AddArt( "TUERCA_M6",  "Tuerca M6 cuelgue",            "ANCLAJE",   "ud",    0.15, 0,    0,    0.000 )
    _AddArt( "PIVOT_TC60", "Cuelgue perfil TC-60",         "ANCLAJE",   "ud",    0.80, 0,    0,    0.050 )

    INDEX ON CODIGO TAG ART_COD
    dbCloseArea()

RETURN NIL


STATIC FUNCTION _AddArt( cCod, cDesc, cFam, cUni, nPrecio, nLargo, nAncho, nPeso )

    DbAppend()
    REPLACE FIELD->CODIGO   WITH cCod
    REPLACE FIELD->DESCRIP  WITH cDesc
    REPLACE FIELD->FAMILIA  WITH cFam
    REPLACE FIELD->UNIDAD   WITH cUni
    REPLACE FIELD->LARGO    WITH nLargo
    REPLACE FIELD->ANCHO    WITH nAncho
    REPLACE FIELD->PESO_UNI WITH nPeso
    REPLACE FIELD->PRECIO   WITH nPrecio

RETURN NIL


STATIC FUNCTION _CreateSysRend( cPath )

    LOCAL aFlds := {}

    AAdd( aFlds, { "SISTEMA_ID", "C", 20, 0 } )
    AAdd( aFlds, { "TIPO_OBRA",  "C", 15, 0 } )
    AAdd( aFlds, { "DESC_SIS",   "C", 60, 0 } )
    AAdd( aFlds, { "MODUL",      "N",  5, 2 } )
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

    DbCreate( cPath + "SYS_REND", aFlds, "DBFCDX" )
    USE ( cPath + "SYS_REND" ) NEW EXCLUSIVE VIA "DBFCDX" ALIAS SYS_REND

    _Rend( "TAB_SENCILLO_1X1", "TABIQUE", 0.60, 2, 1, 0, 10, "PLACA",    "PLACA_A",    "",           "M2", 1.050 )
    _Rend( "TAB_SENCILLO_1X1", "TABIQUE", 0.60, 2, 1, 0, 20, "PLACA",    "PLACA_B",    "",           "M2", 1.050 )
    _Rend( "TAB_SENCILLO_1X1", "TABIQUE", 0.60, 2, 1, 0, 30, "PERFIL",   "MONTANTE",   "",           "ML", 2.330 )
    _Rend( "TAB_SENCILLO_1X1", "TABIQUE", 0.60, 2, 1, 0, 40, "PERFIL",   "CANAL",      "",           "ML", 0.950 )
    _Rend( "TAB_SENCILLO_1X1", "TABIQUE", 0.60, 2, 1, 0, 50, "PASTA",    "PASTA_JUNT", "PASTA_JUNT", "KG", 0.810 )
    _Rend( "TAB_SENCILLO_1X1", "TABIQUE", 0.60, 2, 1, 0, 60, "TORNILLO", "TORN_PM_1",  "TORN_PM_25", "UD", 13.000 )
    _Rend( "TAB_SENCILLO_1X1", "TABIQUE", 0.60, 2, 1, 0, 70, "CINTA",    "CINTA_JUNT", "CINTA_PAP",  "ML", 3.150 )
    _Rend( "TAB_SENCILLO_1X1", "TABIQUE", 0.60, 2, 1, 0, 80, "ACCESORIO","JUNTA_EST",  "BANDA_ACUS", "ML", 1.720 )
    _Rend( "TAB_SENCILLO_1X1", "TABIQUE", 0.60, 2, 1, 0, 90, "AISLAN",   "AISLANTE",   "",           "M2", 1.050 )

    _Rend( "TR_AUT_MONT_1P", "TRASDOSADO_AUT", 0.60, 1, 1, 0, 10, "PLACA",    "PLACA_A",    "",           "M2", 1.050 )
    _Rend( "TR_AUT_MONT_1P", "TRASDOSADO_AUT", 0.60, 1, 1, 0, 20, "PERFIL",   "MONTANTE",   "",           "ML", 2.330 )
    _Rend( "TR_AUT_MONT_1P", "TRASDOSADO_AUT", 0.60, 1, 1, 0, 30, "PERFIL",   "CANAL",      "",           "ML", 0.950 )
    _Rend( "TR_AUT_MONT_1P", "TRASDOSADO_AUT", 0.60, 1, 1, 0, 40, "PASTA",    "PASTA_JUNT", "PASTA_JUNT", "KG", 0.360 )
    _Rend( "TR_AUT_MONT_1P", "TRASDOSADO_AUT", 0.60, 1, 1, 0, 50, "CINTA",    "CINTA_JUNT", "CINTA_PAP",  "ML", 1.300 )
    _Rend( "TR_AUT_MONT_1P", "TRASDOSADO_AUT", 0.60, 1, 1, 0, 60, "AISLAN",   "AISLANTE",   "",           "M2", 1.050 )

    _Rend( "TECHO_SEMI_MAES_1P", "TECHO", 0.60, 1, 1, 0, 10, "PLACA",    "PLACA_A",    "",           "M2", 1.050 )
    _Rend( "TECHO_SEMI_MAES_1P", "TECHO", 0.60, 1, 1, 0, 20, "PERFIL",   "PERF_SEC",   "",           "ML", 2.450 )
    _Rend( "TECHO_SEMI_MAES_1P", "TECHO", 0.60, 1, 1, 0, 30, "PASTA",    "PASTA_JUNT", "PASTA_JUNT", "KG", 0.420 )
    _Rend( "TECHO_SEMI_MAES_1P", "TECHO", 0.60, 1, 1, 0, 40, "TORNILLO", "TORN_PM_1",  "TORN_PM_25", "UD", 13.000 )
    _Rend( "TECHO_SEMI_MAES_1P", "TECHO", 0.60, 1, 1, 0, 50, "CINTA",    "CINTA_JUNT", "CINTA_PAP",  "ML", 1.890 )

    INDEX ON Upper( SISTEMA_ID ) + Str( ORDEN, 4 ) TAG SR_SIS
    dbCloseArea()

RETURN NIL


STATIC FUNCTION _Rend( cSis, cTipo, nMod, nCaras, nCapas, nAncho, nOrden, cFam, cRol, cCod, cUd, nRend )

    DbAppend()
    REPLACE FIELD->SISTEMA_ID WITH cSis
    REPLACE FIELD->TIPO_OBRA  WITH cTipo
    REPLACE FIELD->DESC_SIS   WITH cSis
    REPLACE FIELD->MODUL      WITH nMod
    REPLACE FIELD->CARAS      WITH nCaras
    REPLACE FIELD->CAPAS      WITH nCapas
    REPLACE FIELD->ANCHO_PERF WITH nAncho
    REPLACE FIELD->ORDEN      WITH nOrden
    REPLACE FIELD->FAMILIA    WITH cFam
    REPLACE FIELD->ROL_MAT    WITH cRol
    REPLACE FIELD->CODIGO_DEF WITH cCod
    REPLACE FIELD->UD_TEC     WITH cUd
    REPLACE FIELD->REND_M2    WITH nRend
    REPLACE FIELD->L_EDIT     WITH .T.

RETURN NIL


STATIC FUNCTION _CreateTmpTra( cPath )

    LOCAL aFlds := {}

    AAdd( aFlds, { "NUMERO",       "C",  6, 0 } )
    AAdd( aFlds, { "ID_LINEA",     "N",  4, 0 } )
    AAdd( aFlds, { "TIPO_OBRA",    "C", 15, 0 } )
    AAdd( aFlds, { "SISTEMA_ID",   "C", 20, 0 } )
    AAdd( aFlds, { "CONCEPTO",     "C", 40, 0 } )
    AAdd( aFlds, { "LARGO",        "N",  6, 2 } )
    AAdd( aFlds, { "ALTO",         "N",  6, 2 } )
    AAdd( aFlds, { "MODUL",        "N",  5, 2 } )
    AAdd( aFlds, { "ANCHO_PERF",   "N",  3, 0 } )
    AAdd( aFlds, { "SEP_PRIM",     "N",  5, 2 } )
    AAdd( aFlds, { "CARAS",        "N",  1, 0 } )
    AAdd( aFlds, { "PLAC_CARA",    "N",  1, 0 } )
    AAdd( aFlds, { "ID_PER_VER",   "C", 15, 0 } )
    AAdd( aFlds, { "ID_PER_HOR",   "C", 15, 0 } )
    AAdd( aFlds, { "ID_PER_PER",   "C", 15, 0 } )
    AAdd( aFlds, { "ID_PLACA_A",   "C", 15, 0 } )
    AAdd( aFlds, { "ID_PLACA_B",   "C", 15, 0 } )
    AAdd( aFlds, { "L_AISLANT",    "L",  1, 0 } )
    AAdd( aFlds, { "ID_AISLANT",   "C", 15, 0 } )
    AAdd( aFlds, { "ID_ANCLAJE",   "C", 15, 0 } )
    AAdd( aFlds, { "L_BANDA",      "L",  1, 0 } )
    AAdd( aFlds, { "METROS",       "N", 10, 2 } )

    DbCreate( cPath + "TMP_TRA", aFlds, "DBFCDX" )
    USE ( cPath + "TMP_TRA" ) NEW EXCLUSIVE VIA "DBFCDX" ALIAS TMP_TRA
    INDEX ON NUMERO + Str( ID_LINEA, 4 ) TAG TTRA_ORD
    dbCloseArea()

RETURN NIL


STATIC FUNCTION _CreateTmpMat( cPath )

    LOCAL aFlds := {}

    AAdd( aFlds, { "NUMERO",   "C",  6, 0 } )
    AAdd( aFlds, { "ID_LINEA", "N",  4, 0 } )
    AAdd( aFlds, { "L_MANUAL", "L",  1, 0 } )
    AAdd( aFlds, { "ORIGEN",   "C",  4, 0 } )
    AAdd( aFlds, { "FAMILIA",  "C", 10, 0 } )
    AAdd( aFlds, { "CODIGO",   "C", 15, 0 } )
    AAdd( aFlds, { "DESCRIP",  "C", 40, 0 } )
    AAdd( aFlds, { "UNIDAD",   "C",  5, 0 } )
    AAdd( aFlds, { "PESO_TOT", "N", 12, 3 } )
    AAdd( aFlds, { "RENDIM",   "N", 12, 3 } )
    AAdd( aFlds, { "CANTIDAD", "N", 12, 3 } )
    AAdd( aFlds, { "PRECIO",   "N", 10, 2 } )
    AAdd( aFlds, { "IMPORTE",  "N", 12, 2 } )
    AAdd( aFlds, { "DETALLE",  "C", 30, 0 } )

    DbCreate( cPath + "TMP_MAT", aFlds, "DBFCDX" )
    USE ( cPath + "TMP_MAT" ) NEW EXCLUSIVE VIA "DBFCDX" ALIAS TMP_MAT
    INDEX ON NUMERO TAG MAT_NUM
    INDEX ON NUMERO + Str( ID_LINEA, 4 ) TAG MAT_LIN
    INDEX ON CODIGO TAG MAT_COD
    dbCloseArea()

RETURN NIL


STATIC FUNCTION _CloseAll()

    dbCloseAll()

RETURN NIL


STATIC FUNCTION _RequireArticles()

    LOCAL aCodes := { ;
        "MON_48", "CAN_48", "MAS_82X16", "T45", "ANG_30", ;
        "PLA_N13", "LANA_40", "PASTA_JUNT", "PASTA_AGAR", ;
        "CINTA_PAP", "TORN_PM_25", "BANDA_ACUS", "PIEZA_CRUCE", "TACO_LATON", ;
        "VARILLA_M6", "TUERCA_M6", "PIVOT_TC60" }
    LOCAL i
    LOCAL lOk := .T.

    FOR i := 1 TO Len( aCodes )
        IF !_ArticleExists( aCodes[i] )
            ? "Falta articulo:", aCodes[i]
            lOk := .F.
        ENDIF
    NEXT

RETURN lOk


STATIC FUNCTION _ArticleExists( cCode )

    LOCAL nOrd
    LOCAL lFound := .F.

    dbSelectArea( "ARTICULOS" )
    nOrd := IndexOrd()
    dbSetOrder( 1 )

    IF dbSeek( Upper( AllTrim( cCode ) ) )
        lFound := .T.
    ELSE
        dbGoTop()
        DO WHILE !Eof()
            IF !Deleted() .AND. Upper( AllTrim( FIELD->CODIGO ) ) == Upper( AllTrim( cCode ) )
                lFound := .T.
                EXIT
            ENDIF
            dbSkip()
        ENDDO
    ENDIF

    dbSetOrder( nOrd )

RETURN lFound


STATIC FUNCTION _CleanProject( cAlias, cProject )

    dbSelectArea( cAlias )

    IF !NetFLock()
        ? "No se pudo bloquear para limpiar:", cAlias
        RETURN .F.
    ENDIF

    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProject
            dbDelete()
        ENDIF
        dbSkip()
    ENDDO

    dbCommit()
    dbUnlock()

RETURN .T.


STATIC FUNCTION _SeedFixtures()

    LOCAL i
    LOCAL nPattern

    dbSelectArea( "TMP_TRA" )

    IF !NetFLock()
        RETURN .F.
    ENDIF

    FOR i := 1 TO TEST_LINES
        IF i == 1 .OR. i % 20 == 0
            _Trace( "Seed linea " + AllTrim( Str( i ) ) )
        ENDIF
        nPattern := ( ( i - 1 ) % 8 ) + 1
        DbAppend()
        IF NetErr()
            dbUnlock()
            RETURN .F.
        ENDIF
        _FillFixture( i, nPattern )
    NEXT

    dbCommit()
    dbUnlock()
    _Trace( "Seed commit" )

RETURN .T.


STATIC FUNCTION _FillFixture( nLine, nPattern )

    LOCAL nLargo := 3.00 + ( ( nLine % 7 ) * 0.75 )
    LOCAL nAlto  := 2.50 + ( ( nLine % 4 ) * 0.10 )

    REPLACE FIELD->NUMERO      WITH TEST_PROJECT
    REPLACE FIELD->ID_LINEA    WITH nLine
    REPLACE FIELD->SISTEMA_ID  WITH Space( 20 )
    REPLACE FIELD->CONCEPTO    WITH "Test OOP " + AllTrim( Str( nLine ) )
    REPLACE FIELD->LARGO       WITH nLargo
    REPLACE FIELD->ALTO        WITH nAlto
    REPLACE FIELD->MODUL       WITH 0.60
    REPLACE FIELD->ANCHO_PERF  WITH 48
    REPLACE FIELD->SEP_PRIM    WITH 0.00
    REPLACE FIELD->CARAS       WITH 2
    REPLACE FIELD->PLAC_CARA   WITH 1
    REPLACE FIELD->ID_PER_VER  WITH "MON_48"
    REPLACE FIELD->ID_PER_HOR  WITH "CAN_48"
    REPLACE FIELD->ID_PER_PER  WITH "0"
    REPLACE FIELD->ID_PLACA_A  WITH "PLA_N13"
    REPLACE FIELD->ID_PLACA_B  WITH "PLA_N13"
    REPLACE FIELD->L_AISLANT   WITH .F.
    REPLACE FIELD->ID_AISLANT  WITH "0"
    REPLACE FIELD->ID_ANCLAJE  WITH "0"
    REPLACE FIELD->L_BANDA     WITH .F.
    REPLACE FIELD->METROS      WITH nLargo * nAlto

    DO CASE
    CASE nPattern == 1
        REPLACE FIELD->TIPO_OBRA   WITH "TABIQUE"
        REPLACE FIELD->SISTEMA_ID  WITH "TAB_SENCILLO_1X1"
        REPLACE FIELD->L_BANDA     WITH .T.
        REPLACE FIELD->L_AISLANT   WITH .T.
        REPLACE FIELD->ID_AISLANT  WITH "LANA_40"

    CASE nPattern == 2
        REPLACE FIELD->TIPO_OBRA   WITH "TABIQUE"
        REPLACE FIELD->SISTEMA_ID  WITH "NO_EXISTE"
        REPLACE FIELD->L_BANDA     WITH .T.

    CASE nPattern == 3
        REPLACE FIELD->TIPO_OBRA   WITH "TECHO"
        REPLACE FIELD->MODUL       WITH 0.50
        REPLACE FIELD->SEP_PRIM    WITH 1.00
        REPLACE FIELD->CARAS       WITH 1
        REPLACE FIELD->ID_PER_VER  WITH "MAS_82X16"
        REPLACE FIELD->ID_PER_HOR  WITH "T45"
        REPLACE FIELD->ID_PER_PER  WITH "ANG_30"
        REPLACE FIELD->ID_PLACA_B  WITH "0"
        REPLACE FIELD->ID_ANCLAJE  WITH "VARILLA_M6"

    CASE nPattern == 4
        REPLACE FIELD->TIPO_OBRA   WITH "TECHO"
        REPLACE FIELD->MODUL       WITH 0.50
        REPLACE FIELD->SEP_PRIM    WITH 0.00
        REPLACE FIELD->CARAS       WITH 1
        REPLACE FIELD->ID_PER_VER  WITH "MAS_82X16"
        REPLACE FIELD->ID_PER_HOR  WITH "T45"
        REPLACE FIELD->ID_PER_PER  WITH "ANG_30"
        REPLACE FIELD->ID_PLACA_B  WITH "0"

    CASE nPattern == 5
        REPLACE FIELD->TIPO_OBRA   WITH "TECHO"
        REPLACE FIELD->SISTEMA_ID  WITH "TECHO_SEMI_MAES_1P"
        REPLACE FIELD->MODUL       WITH 0.60
        REPLACE FIELD->CARAS       WITH 1
        REPLACE FIELD->ID_PER_VER  WITH "MAS_82X16"
        REPLACE FIELD->ID_PER_HOR  WITH "0"
        REPLACE FIELD->ID_PER_PER  WITH "ANG_30"
        REPLACE FIELD->ID_PLACA_B  WITH "0"

    CASE nPattern == 6
        REPLACE FIELD->TIPO_OBRA   WITH "TRASDOSADO_AUT"
        REPLACE FIELD->SISTEMA_ID  WITH "TR_AUT_MONT_1P"
        REPLACE FIELD->CARAS       WITH 1
        REPLACE FIELD->ID_PLACA_B  WITH "0"
        REPLACE FIELD->L_AISLANT   WITH .T.
        REPLACE FIELD->ID_AISLANT  WITH "LANA_40"

    CASE nPattern == 7
        REPLACE FIELD->TIPO_OBRA   WITH "TRASDOSADO_DIR"
        REPLACE FIELD->CARAS       WITH 1
        REPLACE FIELD->MODUL       WITH 0.00
        REPLACE FIELD->ID_PER_VER  WITH "PASTA_AGAR"
        REPLACE FIELD->ID_PER_HOR  WITH "0"
        REPLACE FIELD->ID_PLACA_B  WITH "0"

    CASE nPattern == 8
        REPLACE FIELD->TIPO_OBRA   WITH "GENERICO"
        REPLACE FIELD->CARAS       WITH 1
        REPLACE FIELD->ID_PER_VER  WITH "0"
        REPLACE FIELD->ID_PER_HOR  WITH "0"
        REPLACE FIELD->ID_PLACA_A  WITH "PLA_N13"
        REPLACE FIELD->ID_PLACA_B  WITH "0"
    ENDCASE

RETURN NIL


STATIC FUNCTION _CountProject( cAlias, cProject )

    LOCAL nCount := 0

    dbSelectArea( cAlias )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProject
            nCount++
        ENDIF
        dbSkip()
    ENDDO

RETURN nCount


STATIC FUNCTION _HasCodeLine( nLine, cCode )

    LOCAL lFound := .F.

    dbSelectArea( "TMP_MAT" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. ;
           AllTrim( FIELD->NUMERO ) == TEST_PROJECT .AND. ;
           FIELD->ID_LINEA == nLine .AND. ;
           Upper( AllTrim( FIELD->CODIGO ) ) == Upper( AllTrim( cCode ) )
            lFound := .T.
            EXIT
        ENDIF
        dbSkip()
    ENDDO

RETURN lFound


STATIC FUNCTION _Assert( cName, lCond, nOk, nFail )

    IF lCond
        nOk++
        ? "OK   - " + cName
        _Trace( "OK   - " + cName )
    ELSE
        nFail++
        ? "FAIL - " + cName
        _Trace( "FAIL - " + cName )
    ENDIF

RETURN NIL


STATIC FUNCTION _PrintErrors( oCalc )

    LOCAL i
    LOCAL nMax := Min( Len( oCalc:aLog ), 20 )

    ?
    ? "Errores detectados:"
    FOR i := 1 TO nMax
        ? oCalc:aLog[i]
        _Trace( oCalc:aLog[i] )
    NEXT

RETURN NIL


STATIC FUNCTION _Trace( cMsg )

    LOCAL cFile := "TestOopSaturacion.log"
    LOCAL nHandle

    IF File( cFile )
        nHandle := FOpen( cFile, FO_READWRITE )
        IF nHandle >= 0
            FSeek( nHandle, 0, FS_END )
        ENDIF
    ELSE
        nHandle := FCreate( cFile )
    ENDIF

    IF nHandle >= 0
        FWrite( nHandle, Time() + " " + cMsg + Chr( 13 ) + Chr( 10 ) )
        FClose( nHandle )
    ENDIF

RETURN NIL
