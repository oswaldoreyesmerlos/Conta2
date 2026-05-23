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
    LOCAL nTramos := 0
    LOCAL nMat := 0
    LOCAL nRes := 0

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
    nTramos := _CountAlias( "TMP_TRA" )
    nMat    := _CountAlias( "TMP_MAT" )
    nRes    := _CountAlias( "TMP_RES" )

    IF oCalc:nErrores == 0 .AND. ( nTramos == 0 .OR. nMat == 0 .OR. nRes == 0 )
        MsgStop( "Calculo incompleto." + Chr(13) + ;
                 "Tramos: " + AllTrim( Str( nTramos ) ) + Chr(13) + ;
                 "Materiales: " + AllTrim( Str( nMat ) ) + Chr(13) + ;
                 "Resumen: " + AllTrim( Str( nRes ) ), "Proceso Completado" )
        IF !Empty( cAreaAct ) .AND. Select( cAreaAct ) > 0
            dbSelectArea( cAreaAct )
        ENDIF
        RETURN NIL
    ENDIF

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


STATIC FUNCTION _CountAlias( cAlias )

    LOCAL nArea := Select()
    LOCAL nCount := 0

    IF Select( cAlias ) > 0
        dbSelectArea( cAlias )
        dbGoTop()
        DO WHILE !Eof()
            IF !Deleted()
                nCount++
            ENDIF
            dbSkip()
        ENDDO
    ENDIF

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN nCount


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

        dbSelectArea( "TMP_RES" )
        // Buscamos si el material ya existe en el resumen actual
        IF dbSeek( cNum + cCod )
            IF NetRLock()
                REPLACE Field->CANT_TOT WITH Field->CANT_TOT + nCan
                dbCommit()
                dbUnlock()
            ENDIF
        ELSE
            // Si no existe, creamos la entrada nueva
            dbAppend()
            REPLACE Field->NUMERO    WITH cNum
            REPLACE Field->CODIGO    WITH cCod
            REPLACE Field->CANT_TOT  WITH nCan
            REPLACE Field->IMP_TOT   WITH 0
            REPLACE Field->PESO_TOT  WITH 0
            REPLACE Field->FAMILIA   WITH TMP_MAT->FAMILIA
            REPLACE Field->DESCRIP   WITH TMP_MAT->DESCRIP
            REPLACE Field->UNIDAD    WITH TMP_MAT->UNIDAD
            REPLACE Field->PRECIO    WITH TMP_MAT->PRECIO
            dbCommit()
        ENDIF

        dbSelectArea( "TMP_MAT" )
        dbSkip()
    ENDDO

    _ConvierteResumenCompra()

RETURN NIL


STATIC FUNCTION _ConvierteResumenCompra()

    LOCAL nArea := Select()
    LOCAL nOrdArt := 0
    LOCAL cCod
    LOCAL cFam
    LOCAL cUniCons
    LOCAL cUniCompra
    LOCAL nConsumo
    LOCAL nCompra
    LOCAL nPrecio
    LOCAL nPesoU
    LOCAL nLargo
    LOCAL nAncho
    LOCAL nPesoTot

    IF Select( "ARTICULOS" ) == 0 .OR. Select( "TMP_RES" ) == 0
        RETURN NIL
    ENDIF

    dbSelectArea( "ARTICULOS" )
    nOrdArt := IndexOrd()
    dbSetOrder( 1 )

    dbSelectArea( "TMP_RES" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            cCod       := Upper( AllTrim( FIELD->CODIGO ) )
            cFam       := AllTrim( FIELD->FAMILIA )
            cUniCons   := Upper( AllTrim( FIELD->UNIDAD ) )
            nConsumo   := FIELD->CANT_TOT
            nPrecio    := FIELD->PRECIO
            nPesoU     := 0
            nLargo     := 0
            nAncho     := 0
            cUniCompra := AllTrim( FIELD->UNIDAD )

            dbSelectArea( "ARTICULOS" )
            IF dbSeek( cCod )
                cFam       := AllTrim( ARTICULOS->FAMILIA )
                cUniCompra := AllTrim( ARTICULOS->UNIDAD )
                nPrecio    := ARTICULOS->PRECIO
                nPesoU     := ARTICULOS->PESO_UNI
                nLargo     := ARTICULOS->LARGO
                nAncho     := ARTICULOS->ANCHO

                IF Upper( AllTrim( cFam ) ) == "ACCESORIO" .AND. ;
                   cUniCons == "ML" .AND. ;
                   ( "BANDA" $ cCod .OR. "CINTA" $ cCod )
                    cUniCompra := "rollo"
                ENDIF
            ENDIF

            nCompra  := _CantidadCompra( cFam, cCod, cUniCompra, nConsumo, ;
                                          cUniCons, nLargo, nAncho, nPesoU )
            nPesoTot := If( nPesoU > 0, nCompra * nPesoU, 0 )

            dbSelectArea( "TMP_RES" )
            IF NetRLock()
                REPLACE FIELD->FAMILIA  WITH cFam
                REPLACE FIELD->UNIDAD   WITH cUniCompra
                REPLACE FIELD->CANT_TOT WITH nCompra
                REPLACE FIELD->PRECIO   WITH nPrecio
                REPLACE FIELD->IMP_TOT  WITH nCompra * nPrecio
                REPLACE FIELD->PESO_TOT WITH nPesoTot
                dbCommit()
                dbUnlock()
            ENDIF
        ENDIF

        dbSelectArea( "TMP_RES" )
        dbSkip()
    ENDDO

    dbSelectArea( "ARTICULOS" )
    dbSetOrder( nOrdArt )

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN NIL
