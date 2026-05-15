/*
------------------------------------------------------------------------------
 PROYECTO    : Sistema de Gestión Integral
 ARCHIVO     : PRES_MOD.PRG
 DESCRIPCION : Grabación definitiva del presupuesto (Paso a Histórico).
               Aplica Estrategia Boy Scout y Regla de Oro.
------------------------------------------------------------------------------
*/

#include "inkey.ch"

// ============================================================================
// FUNCION: GrabaPres
// Descripción: Mueve los datos de las tablas TMP_* a las tablas HIS_*.
// ============================================================================
FUNCTION GrabaPres()
    // --- REGLA DEL BOY SCOUT: VARIABLES DE ESTADO LOCAL ---
    LOCAL nAreaOri
    LOCAL nOrdOri
    
    // --- VARIABLES DE NEGOCIO ---
    LOCAL cNueNum
    LOCAL nTotal := 0
    LOCAL lOk := .T.

    // 1. GUARDAMOS EL ESTADO ACTUAL
    nAreaOri := Select()
    nOrdOri := IndexOrd()

    // 2. VALIDACIONES PREVIAS
    IF Select( "TMP_TRA" ) == 0
        MsgStop( "La tabla de tramos no está disponible.", "Error" )
        RETURN NIL
    ENDIF

    dbSelectArea( "TMP_TRA" )
    
    IF LastRec() == 0
        MsgStop( "No hay tramos cargados en el presupuesto actual.", "Atencion" )
        RETURN NIL
    ENDIF

    // 3. CONFIRMACIÓN CON DIÁLOGO NATIVO WVG
    IF !MsgYesNo( "¿Desea CERRAR el presupuesto y pasarlo al Histórico?", "Confirmar Cierre" )
        RETURN NIL
    ENDIF

    // 4. OBTENCIÓN DEL NÚMERO CORRELATIVO
    cNueNum := _GetNextDoc()
    
    IF Empty( cNueNum )
        MsgStop( "Error al generar el número de presupuesto. Verifique empresa.", "Error" )
        RETURN NIL
    ENDIF

    // 5. CÁLCULO DEL TOTAL DESDE EL RESUMEN VALORADO
    dbSelectArea( "TMP_RES" )
    SUM Field->IMP_TOT TO nTotal

    // 6. FASE DE TRANSFERENCIA (Paso a paso para facilitar el debug)
    
    // A. Copiado de Cabecera
    _MoverCabecera( cNueNum, nTotal )
    
    // B. Copiado de Tramos
    _MoverTramos( cNueNum )
    
    // C. Copiado de Resumen de Materiales
    _MoverResumen( cNueNum )

    // 7. LIMPIEZA DEL BORRADOR (Boy Scout deja el sitio limpio)
    _LimpiaTemporales()

    // 8. NOTIFICACIÓN FINAL NATIVA
    MsgInfo( "Presupuesto guardado correctamente con el número: " + cNueNum, "Proceso Finalizado" )

    // 9. RESTAURACIÓN DEL "CAMPAMENTO"
    IF nAreaOri > 0
        dbSelectArea( nAreaOri )
        dbSetOrder( nOrdOri )
    ENDIF

RETURN NIL

// ============================================================================
// FUNCION: _MoverTramos
// Descripción: Transfiere línea a línea los tramos técnicos al histórico.
// ============================================================================
STATIC FUNCTION _MoverTramos( cDocNum )
    LOCAL nAreaAct := Select()
    
    dbSelectArea( "TMP_TRA" )
    dbGoTop()
    
    DO WHILE !Eof()
        dbSelectArea( "HIS_TRA" )
        dbAppend()
        
        REPLACE Field->NUMERO       WITH cDocNum
        REPLACE Field->ID_LINEA     WITH TMP_TRA->ID_LINEA
        REPLACE Field->CONCEPTO     WITH TMP_TRA->CONCEPTO
        REPLACE Field->TIPO_OBRA    WITH TMP_TRA->TIPO_OBRA
        REPLACE Field->LARGO        WITH TMP_TRA->LARGO
        REPLACE Field->ALTO         WITH TMP_TRA->ALTO
        REPLACE Field->MODUL        WITH TMP_TRA->MODUL
        REPLACE Field->SEP_PRIM     WITH TMP_TRA->SEP_PRIM
        REPLACE Field->CARAS        WITH TMP_TRA->CARAS
        REPLACE Field->PLAC_CARA    WITH TMP_TRA->PLAC_CARA
        REPLACE Field->ID_PER_VER   WITH TMP_TRA->ID_PER_VER
        REPLACE Field->ID_PER_HOR   WITH TMP_TRA->ID_PER_HOR
        REPLACE Field->ID_PER_PER   WITH TMP_TRA->ID_PER_PER
        REPLACE Field->ID_PLACA_A   WITH TMP_TRA->ID_PLACA_A
        REPLACE Field->ID_PLACA_B   WITH TMP_TRA->ID_PLACA_B
        REPLACE Field->ID_AISLANT   WITH TMP_TRA->ID_AISLANT
        REPLACE Field->ID_ANCLAJE   WITH TMP_TRA->ID_ANCLAJE
        REPLACE Field->ID_AISLAN    WITH TMP_TRA->ID_AISLAN
        REPLACE Field->L_AISLANT    WITH TMP_TRA->L_AISLANT
        REPLACE Field->L_BANDA      WITH TMP_TRA->L_BANDA
        REPLACE Field->METROS       WITH TMP_TRA->METROS
        
        dbSelectArea( "TMP_TRA" )
        dbSkip()
    ENDDO
    
    dbSelectArea( nAreaAct )
RETURN NIL

// ============================================================================
// FUNCION: _GetNextDoc
// Descripción: Gestiona el contador de la empresa de forma aislada.
// ============================================================================
STATIC FUNCTION _GetNextDoc()
    LOCAL cNum := ""
    LOCAL nVal := 0
    LOCAL nAreaTmp := Select()

    // Usa la tabla Contador (compartida con AppGestion)
    IF Select( "CONTADOR" ) == 0
        USE CONTADOR NEW SHARED VIA "DBFCDX"
    ENDIF

    dbSelectArea( "CONTADOR" )
    IF DbSeek( "PRE" )
        IF NetRLock()
            nVal := FIELD->ULT_NUM + 1
            REPLACE FIELD->ULT_NUM WITH nVal
            DbCommit()
            dbUnlock()
        ENDIF
    ELSE
        IF NetFLock()
            DbAppend()
            REPLACE FIELD->COD_DOC WITH "PRE"
            REPLACE FIELD->ULT_NUM WITH 1
            nVal := 1
            DbCommit()
            dbUnlock()
        ENDIF
    ENDIF

    cNum := PadL( AllTrim( Str( nVal ) ), 6, "0" )
    dbSelectArea( nAreaTmp )
RETURN cNum

// ============================================================================
// FUNCION: _LimpiaTemporales
// Descripción: Vaciado total de tablas temporales (Requiere Exclusivo)
// ============================================================================
FUNCTION _LimpiaTemporales()

    LOCAL nOld := Select()

    // 0. CONFIRMACION
    IF !MsgYesNo( "¿Desea eliminar el proyecto actual y empezar uno nuevo?" + Chr(13) + ;
                  "Se perderán todos los datos no guardados.", "Nuevo Proyecto" )
        RETURN NIL
    ENDIF

    // 1. Limpiamos Tramos
    _SafeZap( "TMP_TRA" )

    // 2. Limpiamos Cabeceras
    _SafeZap( "TMP_CAB" )

    // 3. Limpiamos Materiales
    _SafeZap( "TMP_MAT" )

    // 4. Limpiamos Resumen
    _SafeZap( "TMP_RES" )

    // 5. Boy Scout: Volvemos al area donde estabamos
    IF nOld > 0
        dbSelectArea( nOld )
    ENDIF

RETURN NIL


// ============================================================================
// AUXILIAR: Gestiona el cierre, apertura exclusiva, zap y reapertura
// ============================================================================
STATIC FUNCTION _SafeZap( cFile )

    LOCAL cAlias   := Upper( cFile )
    LOCAL lWasOpen := .F.
    LOCAL cDriver  := "DBFCDX" // O el RDD que estés usando por defecto
    
    // 1. DIAGNOSTICO: ¿ESTA ABIERTA?
    IF Select( cAlias ) > 0
        lWasOpen := .T.
        dbSelectArea( cAlias )
        dbCloseArea()  // La cerramos para poder pedir Exclusivo
    ENDIF
    
    // 2. OPERACION DE BORRADO (EXCLUSIVO)
    IF File( cFile + ".DBF" )
        
        USE (cFile) NEW EXCLUSIVE ALIAS (cAlias)
        
        IF !NetErr()
            __dbZap()      // Vacía la DBF completamente (resetea RecNo)
            dbCloseArea()  // Cerramos el modo exclusivo
        ELSE
            MsgStop( "Error: No se pudo abrir " + cFile + " en modo exclusivo." + CRLF + ;
                     "Asegurese de que nadie más la está usando." )
            // Si falla, intentamos dejarla abierta como estaba si es posible
        ENDIF
        
    ENDIF
    
    // 3. RESTAURACION (BOY SCOUT)
    // Si estaba abierta al principio, la volvemos a abrir en modo COMPARTIDO
    IF lWasOpen
        IF File( cFile + ".DBF" ) .AND. Select( cAlias ) == 0
            USE (cFile) NEW SHARED VIA cDriver ALIAS (cAlias)
        ENDIF
    ENDIF

RETURN NIL

// ============================================================================
// FUNCION: _MoverCabecera
// Descripción: Transfiere los datos de la cabecera al histórico HIS_CAB.
// ============================================================================
STATIC FUNCTION _MoverCabecera( cDoc, nTot )
    LOCAL nArea := Select()
    dbSelectArea( "HIS_CAB" )
    dbAppend()
    IF !NetErr()
        REPLACE Field->NUMERO     WITH cDoc
        REPLACE Field->FECHA      WITH TMP_CAB->FECHA
        REPLACE Field->TITULO     WITH TMP_CAB->TITULO
        REPLACE Field->ID_CLIENTE WITH TMP_CAB->ID_CLIENTE
        REPLACE Field->OBSERV     WITH TMP_CAB->OBSERV
        REPLACE Field->MARGEN     WITH TMP_CAB->MARGEN
        dbUnlock()
    ENDIF
    dbSelectArea( nArea )
RETURN NIL

// ============================================================================
// FUNCION: _MoverResumen
// Descripción: Transfiere el resumen económico final a HIS_RES.
// ============================================================================
STATIC FUNCTION _MoverResumen( cDoc )
    LOCAL nArea := Select()
    dbSelectArea( "TMP_RES" )
    dbGoTop()
    DO WHILE !Eof()
        dbSelectArea( "HIS_RES" )
        dbAppend()
        REPLACE Field->NUMERO   WITH cDoc
        REPLACE Field->FAMILIA  WITH TMP_RES->FAMILIA
        REPLACE Field->CODIGO   WITH TMP_RES->CODIGO
        REPLACE Field->DESCRIP  WITH TMP_RES->DESCRIP
        REPLACE Field->UNIDAD   WITH TMP_RES->UNIDAD
        REPLACE Field->CANT_TOT WITH TMP_RES->CANT_TOT
        REPLACE Field->PRECIO   WITH TMP_RES->PRECIO
        REPLACE Field->IMP_TOT  WITH TMP_RES->IMP_TOT
        REPLACE Field->PESO_TOT WITH TMP_RES->PESO_TOT
        dbSelectArea( "TMP_RES" )
        dbSkip()
    ENDDO
    dbSelectArea( nArea )
RETURN NIL