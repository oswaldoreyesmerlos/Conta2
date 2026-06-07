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
    LOCAL cProyecto := ""

    lOk := _EnsureCalcTables()
    cProyecto := _CalcProyectoActual()

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

    IF Empty( cProyecto )
        MsgStop( "Debe activar o crear un proyecto antes de calcular.", "Error de Proceso" )
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
    IF !DrywallValidarTramos( cProyecto, .T. )
        IF !Empty( cAreaAct ) .AND. Select( cAreaAct ) > 0
            dbSelectArea( cAreaAct )
        ENDIF
        RETURN NIL
    ENDIF

    IF !_LimpiaBD( "TMP_MAT", cProyecto ) .OR. !_LimpiaBD( "TMP_RES", cProyecto )
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
    LOCAL cProyecto := _CalcProyectoActual()

    IF Select( cAlias ) > 0
        dbSelectArea( cAlias )
        dbGoTop()
        DO WHILE !Eof()
            IF !Deleted() .AND. ;
               ( FieldPos( "NUMERO" ) == 0 .OR. AllTrim( FIELD->NUMERO ) == cProyecto )
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

    IF !ABRIR_TABLA( cAlias, cAlias, "" )
        RETURN .F.
    ENDIF

RETURN ( Select( cAlias ) > 0 )


STATIC FUNCTION _MarkCabCalculated()

    LOCAL cProyecto := _CalcProyectoActual()

    DrywallMarkCalculated( cProyecto )

RETURN NIL

// ============================================================================
// FUNCION: _LimpiaBD
// Descripción: Borrado físico seguro de tablas temporales.
// ============================================================================
STATIC FUNCTION _LimpiaBD( cAlias, cProyecto )

    LOCAL cAreaAct := Alias()

    cProyecto := AllTrim( cProyecto )

    IF Empty( cProyecto )
        MsgStop( "No hay proyecto activo para limpiar " + cAlias + ".", "Error de Proceso" )
        RETURN .F.
    ENDIF

    IF Select( cAlias ) == 0
        IF !_OpenShared( cAlias )
            MsgStop( "No se pudo abrir la tabla " + cAlias + " en modo compartido.", "Error de Proceso" )
            RETURN .F.
        ENDIF
    ENDIF

    dbSelectArea( cAlias )
    IF !NetFLock()
        MsgStop( "No se pudo bloquear " + cAlias + " para limpiar el proyecto.", "Error de Proceso" )
        IF !Empty( cAreaAct ) .AND. Select( cAreaAct ) > 0
            dbSelectArea( cAreaAct )
        ENDIF
        RETURN .F.
    ENDIF

    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            dbDelete()
        ENDIF
        dbSkip()
    ENDDO

    dbCommit()
    dbUnlock()

    IF !Empty( cAreaAct ) .AND. Select( cAreaAct ) > 0
        dbSelectArea( cAreaAct )
    ENDIF

RETURN .T.

// ============================================================================
// FUNCION: _GeneraResumen
// Descripción: Recorre TMP_MAT y agrupa cantidades en TMP_RES.
// ============================================================================
STATIC FUNCTION _GeneraResumen()
    LOCAL hResumen := hb_Hash()
    LOCAL aKeys := {}
    LOCAL aRow
    LOCAL cKey
    LOCAL cProyecto := _CalcProyectoActual()
    LOCAL cNum
    LOCAL cCod
    LOCAL nCan
    LOCAL i
    
    dbSelectArea( "TMP_MAT" )
    dbGoTop()

    DO WHILE !Eof()
        // Captura de datos de la línea de material
        IF !Deleted() .AND. AllTrim( Field->NUMERO ) == cProyecto
            cNum := AllTrim( Field->NUMERO )
            cCod := Upper( AllTrim( Field->CODIGO ) )
            nCan := Field->CANTIDAD
            cKey := cNum + "|" + cCod

            IF hb_HHasKey( hResumen, cKey )
                aRow := hResumen[ cKey ]
                aRow[3] += nCan
                hResumen[ cKey ] := aRow
            ELSE
                AAdd( aKeys, cKey )
                hResumen[ cKey ] := { ;
                    cNum, ;
                    cCod, ;
                    nCan, ;
                    AllTrim( Field->FAMILIA ), ;
                    AllTrim( Field->DESCRIP ), ;
                    AllTrim( Field->UNIDAD ), ;
                    Field->PRECIO }
            ENDIF
        ENDIF

        dbSkip()
    ENDDO

    dbSelectArea( "TMP_RES" )
    IF !NetFLock()
        MsgStop( "No se pudo bloquear TMP_RES para generar el resumen.", "Error de Proceso" )
        RETURN NIL
    ENDIF

    FOR i := 1 TO Len( aKeys )
        aRow := hResumen[ aKeys[i] ]

        DbAppend()
        IF NetErr()
            EXIT
        ENDIF

        REPLACE Field->NUMERO    WITH aRow[1]
        REPLACE Field->CODIGO    WITH aRow[2]
        REPLACE Field->CANT_TOT  WITH aRow[3]
        REPLACE Field->IMP_TOT   WITH 0
        REPLACE Field->PESO_TOT  WITH 0
        REPLACE Field->FAMILIA   WITH aRow[4]
        REPLACE Field->DESCRIP   WITH aRow[5]
        REPLACE Field->UNIDAD    WITH aRow[6]
        REPLACE Field->PRECIO    WITH aRow[7]
    NEXT

    dbCommit()
    dbUnlock()

    _ConvierteResumenCompra()

RETURN NIL


STATIC FUNCTION _CalcProyectoActual()

RETURN DrywallProyectoActualNumero()


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
    LOCAL cProyecto := _CalcProyectoActual()

    IF Select( "ARTICULOS" ) == 0 .OR. Select( "TMP_RES" ) == 0
        RETURN NIL
    ENDIF

    dbSelectArea( "ARTICULOS" )
    nOrdArt := IndexOrd()
    OrdSetFocus( "ART_COD" )

    dbSelectArea( "TMP_RES" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
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
