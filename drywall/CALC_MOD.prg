/*
------------------------------------------------------------------------------
 PROYECTO    : Sistema de Gestión Integral
 ARCHIVO     : CALC_MOD.PRG
 DESCRIPCION : Controlador principal del proceso de cálculo.
               Delega la matemática en OOPTRAMO y gestiona el resumen.
------------------------------------------------------------------------------
*/

#include "inkey.ch"

// ============================================================================
// FUNCION: Procesa
// Descripción: Punto de entrada para el recálculo total del presupuesto.
// Limpia los resultados previos y lanza el motor de objetos.
// ============================================================================
FUNCTION Procesa()
    // --- REGLA DEL BOY SCOUT: VARIABLES LOCALES ---
    LOCAL cAreaAct := Alias()
    LOCAL oCalc
    LOCAL lOk := .T.

    lOk := _EnsureCalcTables()

    // 1. VERIFICACIÓN DE TABLAS ABIERTAS (Individual para depuración clara)
    IF Select( "TMP_TRA" ) == 0
        MsgStop( "La tabla de Tramos no está abierta.", "Error de Proceso" )
        lOk := .F.
    ENDIF

    IF lOk .AND. Select( "TMP_MAT" ) == 0
        MsgStop( "La tabla de Materiales no está abierta.", "Error de Proceso" )
        lOk := .F.
    ENDIF

    IF lOk .AND. Select( "TMP_RES" ) == 0
        MsgStop( "La tabla de Resumen no está abierta.", "Error de Proceso" )
        lOk := .F.
    ENDIF

    IF !lOk
        IF !Empty( cAreaAct ) .AND. Select( cAreaAct ) > 0
            dbSelectArea( cAreaAct )
        ENDIF
        RETURN NIL
    ENDIF

    // 2. CONFIRMACIÓN NATIVA WVG
    IF !MsgYesNo( "¿Desea iniciar el cálculo de materiales de toda la obra?", "Atencion" )
        RETURN NIL
    ENDIF

    // 3. PREPARACIÓN DEL TERRENO (Limpieza)
    IF !_LimpiaBD( "TMP_MAT" ) .OR. !_LimpiaBD( "TMP_RES" )
        IF !Empty( cAreaAct ) .AND. Select( cAreaAct ) > 0
            dbSelectArea( cAreaAct )
        ENDIF
        RETURN NIL
    ENDIF

    // 4. INVOCACIÓN DEL MOTOR OOP (OOPTRAMO)
    // Creamos una instancia del "ingeniero" de cálculos
    oCalc := OOPTRAMO():New()

    // Ejecutamos el procesamiento de todos los tramos (.T.)
    oCalc:Procesar( .T. )

    // 5. CONSOLIDACIÓN DE RESULTADOS
    // Generamos el resumen agrupado por artículo
    _GeneraResumen()

    // 6. REPORTE FINAL DE INCIDENCIAS
    IF oCalc:nErrores > 0
        oCalc:MostrarErrores()
    ELSE
        _MarkCabCalculated()
        MsgInfo( "Cálculo finalizado con éxito.", "Proceso Completado" )
    ENDIF

    // 7. RESTAURACIÓN DEL ÁREA (BOY SCOUT)
    IF !Empty( cAreaAct ) .AND. Select( cAreaAct ) > 0
        dbSelectArea( cAreaAct )
    ENDIF

RETURN NIL


STATIC FUNCTION _EnsureCalcTables()

    LOCAL aTabs := { "TMP_TRA", "TMP_MAT", "TMP_RES", "TMP_CAB", "ARTICULOS" }
    LOCAL i

    FOR i := 1 TO Len( aTabs )
        IF Select( aTabs[i] ) == 0
            IF !_OpenShared( aTabs[i] )
                MsgStop( "No se pudo abrir la tabla " + aTabs[i] + " en modo compartido.", "Error de Proceso" )
                RETURN .F.
            ENDIF
        ELSE
            dbSelectArea( aTabs[i] )
        ENDIF
    NEXT

RETURN .T.


STATIC FUNCTION _OpenShared( cAlias )

    BEGIN SEQUENCE WITH {|oErr| Break( oErr )}
        USE ( cAlias ) NEW SHARED VIA "DBFCDX" ALIAS ( cAlias )
    RECOVER
        RETURN .F.
    END SEQUENCE

RETURN ( Select( cAlias ) > 0 )


STATIC FUNCTION _MarkCabCalculated()

    LOCAL nArea := Select()

    IF Select( "TMP_CAB" ) > 0
        dbSelectArea( "TMP_CAB" )
        dbGoTop()
        IF NetRLock()
            REPLACE FIELD->L_SUCIO WITH .F.
            dbCommit()
            dbUnlock()
        ENDIF
    ENDIF

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN NIL

// ============================================================================
// FUNCION: _LimpiaBD
// Descripción: Borrado físico seguro de tablas temporales.
// ============================================================================
STATIC FUNCTION _LimpiaBD( cAlias )
    LOCAL cAreaAct := Alias()
    LOCAL lOk := .T.

    IF Select( cAlias ) > 0
        dbSelectArea( cAlias )
        dbCloseArea()
    ENDIF

    BEGIN SEQUENCE WITH {|oErr| Break( oErr )}
        USE ( cAlias ) NEW EXCLUSIVE VIA "DBFCDX" ALIAS ( cAlias )
        __dbZap()
        dbCloseArea()
    RECOVER
        lOk := .F.
    END SEQUENCE

    IF Select( cAlias ) > 0
        dbSelectArea( cAlias )
        dbCloseArea()
    ENDIF

    IF !_OpenShared( cAlias )
        MsgStop( "No se pudo reabrir la tabla " + cAlias + " en modo compartido.", "Error de Proceso" )
        IF !Empty( cAreaAct ) .AND. Select( cAreaAct ) > 0
            dbSelectArea( cAreaAct )
        ENDIF
        RETURN .F.
    ENDIF

    IF !lOk
        MsgStop( "No se pudo limpiar la tabla " + cAlias + " en modo exclusivo.", "Error de Proceso" )
        IF !Empty( cAreaAct ) .AND. Select( cAreaAct ) > 0
            dbSelectArea( cAreaAct )
        ENDIF
        RETURN .F.
    ENDIF

    IF !Empty( cAreaAct ) .AND. Select( cAreaAct ) > 0
        dbSelectArea( cAreaAct )
    ENDIF

RETURN .T.

// ============================================================================
// FUNCION: _GeneraResumen
// Descripción: Recorre TMP_MAT y agrupa cantidades en TMP_RES.
// ============================================================================
STATIC FUNCTION _GeneraResumen()
    LOCAL cNum
    LOCAL cCod
    LOCAL nCan
    LOCAL nImp
    LOCAL nPes
    
    dbSelectArea( "TMP_MAT" )
    dbGoTop()
    dbSelectArea( "TMP_RES" )
    dbSetOrder( 1 )
    dbSelectArea( "TMP_MAT" )

    DO WHILE !Eof()
        // Captura de datos de la línea de material
        cNum := Field->NUMERO
        cCod := Field->CODIGO
        nCan := Field->CANTIDAD
        nImp := Field->IMPORTE
        nPes := Field->PESO_TOT

        dbSelectArea( "TMP_RES" )
        // Buscamos si el material ya existe en el resumen actual
        IF dbSeek( cNum + cCod )
            IF NetRLock()
                REPLACE Field->CANT_TOT WITH Field->CANT_TOT + nCan
                REPLACE Field->IMP_TOT  WITH Field->IMP_TOT  + nImp
                REPLACE Field->PESO_TOT WITH Field->PESO_TOT + nPes
                dbCommit()
                dbUnlock()
            ENDIF
        ELSE
            // Si no existe, creamos la entrada nueva
            dbAppend()
            REPLACE Field->NUMERO    WITH cNum
            REPLACE Field->CODIGO    WITH cCod
            REPLACE Field->CANT_TOT  WITH nCan
            REPLACE Field->IMP_TOT   WITH nImp
            REPLACE Field->PESO_TOT  WITH nPes
            REPLACE Field->FAMILIA   WITH TMP_MAT->FAMILIA
            REPLACE Field->DESCRIP   WITH TMP_MAT->DESCRIP
            REPLACE Field->UNIDAD    WITH TMP_MAT->UNIDAD
            REPLACE Field->PRECIO    WITH TMP_MAT->PRECIO
            dbCommit()
        ENDIF

        dbSelectArea( "TMP_MAT" )
        dbSkip()
    ENDDO
RETURN NIL
