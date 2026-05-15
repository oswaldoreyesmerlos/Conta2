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
    LOCAL nAreaAct
    LOCAL oCalc
    LOCAL lOk := .T.

    nAreaAct := Select()

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
        RETURN NIL
    ENDIF

    // 2. CONFIRMACIÓN NATIVA WVG
    IF !MsgYesNo( "¿Desea iniciar el cálculo de materiales de toda la obra?", "Atencion" )
        RETURN NIL
    ENDIF

    // 3. PREPARACIÓN DEL TERRENO (Limpieza)
    _LimpiaBD( "TMP_MAT" )
    _LimpiaBD( "TMP_RES" )

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
        MsgInfo( "Cálculo finalizado con éxito.", "Proceso Completado" )
    ENDIF

    // 7. RESTAURACIÓN DEL ÁREA (BOY SCOUT)
    IF nAreaAct > 0
        dbSelectArea( nAreaAct )
    ENDIF

RETURN NIL

// ============================================================================
// FUNCION: _LimpiaBD
// Descripción: Borrado físico seguro de tablas temporales.
// ============================================================================
STATIC FUNCTION _LimpiaBD( cAlias )
    LOCAL nArea
    nArea := Select()
    dbSelectArea( cAlias )
    // Bloqueo de archivo para borrado masivo
    IF NetFLock()
        __dbZap()
        dbUnlock()
    ENDIF
    dbSelectArea( nArea )
RETURN NIL

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
                dbUnlock()
            ENDIF
        ELSE
            // Si no existe, creamos la entrada nueva
            IF NetRLock()
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
                dbUnlock()
            ENDIF
        ENDIF

        dbSelectArea( "TMP_MAT" )
        dbSkip()
    ENDDO
RETURN NIL