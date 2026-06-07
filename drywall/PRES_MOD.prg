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
FUNCTION GrabaPres( lConfirmar, lLimpiar )
    // --- REGLA DEL BOY SCOUT: VARIABLES DE ESTADO LOCAL ---
    LOCAL nAreaOri
    LOCAL nOrdOri
    
    // --- VARIABLES DE NEGOCIO ---
    LOCAL cNueNum
    LOCAL cProyecto := DrywallProyectoActualNumero()
    LOCAL nTotal := 0
    LOCAL lOk := .T.

    IF ValType( lConfirmar ) != "L"
        lConfirmar := .T.
    ENDIF
    IF ValType( lLimpiar ) != "L"
        lLimpiar := .T.
    ENDIF

    // 1. GUARDAMOS EL ESTADO ACTUAL
    nAreaOri := Select()
    nOrdOri := IndexOrd()

    // 2. VALIDACIONES PREVIAS
    IF !DrywallValidarParaHistorico( cProyecto )
        RETURN NIL
    ENDIF

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
    nTotal := _TotalTmpRes( cProyecto )

    // 6. FASE DE TRANSFERENCIA (con proteccion contra errores)
    BEGIN SEQUENCE WITH {|oErr| Break( oErr )}

        // A. Copiado de Cabecera
        _MoverCabecera( cNueNum, nTotal, "C", cProyecto )

        // B. Copiado de Tramos
        _MoverTramos( cNueNum, cProyecto )

        // C. Copiado de Resumen de Materiales
        _MoverResumen( cNueNum, cProyecto )

    RECOVER
        MsgStop( "Error al guardar el presupuesto. Operacion cancelada.", "Error" )
        IF nAreaOri > 0
            dbSelectArea( nAreaOri )
            dbSetOrder( nOrdOri )
        ENDIF
        RETURN NIL
    END SEQUENCE

    // 7. LIMPIEZA DEL BORRADOR (fuera de secuencia)
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
STATIC FUNCTION _MoverTramos( cDocNum, cProyecto )
    LOCAL nAreaAct := Select()

    IF ValType( cProyecto ) != "C"
        cProyecto := cDocNum
    ENDIF

    dbSelectArea( "HIS_TRA" )
    IF !NetFLock()
        MsgStop( "No se pudo bloquear HIS_TRA.", "Guardar en Firme" )
        dbSelectArea( nAreaAct )
        RETURN NIL
    ENDIF
    
    dbSelectArea( "TMP_TRA" )
    dbGoTop()
    
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( TMP_TRA->NUMERO ) == AllTrim( cProyecto )
            dbSelectArea( "HIS_TRA" )
            dbAppend()

            REPLACE Field->NUMERO       WITH cDocNum
            REPLACE Field->ID_LINEA     WITH TMP_TRA->ID_LINEA
            REPLACE Field->CONCEPTO     WITH TMP_TRA->CONCEPTO
            REPLACE Field->TIPO_OBRA    WITH TMP_TRA->TIPO_OBRA
            IF FieldPos( "SISTEMA_ID" ) > 0 .AND. TMP_TRA->( FieldPos( "SISTEMA_ID" ) ) > 0
                REPLACE Field->SISTEMA_ID WITH TMP_TRA->SISTEMA_ID
            ENDIF
            REPLACE Field->LARGO        WITH TMP_TRA->LARGO
            REPLACE Field->ALTO         WITH TMP_TRA->ALTO
            REPLACE Field->MODUL        WITH TMP_TRA->MODUL
            IF FieldPos( "ANCHO_PERF" ) > 0 .AND. TMP_TRA->( FieldPos( "ANCHO_PERF" ) ) > 0
                REPLACE Field->ANCHO_PERF WITH TMP_TRA->ANCHO_PERF
            ENDIF
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
            REPLACE Field->L_AISLANT    WITH TMP_TRA->L_AISLANT
            REPLACE Field->L_BANDA      WITH TMP_TRA->L_BANDA
            REPLACE Field->METROS       WITH TMP_TRA->METROS
        ENDIF
        
        dbSelectArea( "TMP_TRA" )
        dbSkip()
    ENDDO

    dbSelectArea( "HIS_TRA" )
    dbCommit()
    dbUnlock()
    
    dbSelectArea( nAreaAct )
RETURN NIL

// ============================================================================
// FUNCION: _GetNextDoc
// Descripción: Gestiona el contador de la empresa de forma aislada.
// ============================================================================
STATIC FUNCTION _GetNextDoc()

RETURN GetNextNum( "PRE", "Presupuestos" )

// ============================================================================
// FUNCION: _LimpiaTemporales
// Descripcion: Borra solo el proyecto temporal activo.
// ============================================================================
FUNCTION _LimpiaTemporales()

    LOCAL nOld := Select()
    LOCAL cProyecto := DrywallProyectoActualNumero()

    IF Empty( cProyecto )
        MsgStop( "No hay proyecto temporal activo para eliminar.", "Eliminar Proyecto" )
        RETURN NIL
    ENDIF

    // 0. CONFIRMACION
    IF !MsgYesNo( "Desea eliminar el proyecto temporal " + cProyecto + "?" + Chr(13) + ;
                  "Los demas proyectos en curso se conservaran.", "Eliminar Proyecto" )
        RETURN NIL
    ENDIF

    _BorraTemporalProyecto( cProyecto )
    _ActivaPrimerTemporal()

    // 5. Boy Scout: Volvemos al area donde estabamos
    IF nOld > 0
        dbSelectArea( nOld )
    ENDIF

RETURN NIL


// ============================================================================
// AUXILIAR OBSOLETO: no usar para limpiar proyectos temporales.
// ============================================================================
STATIC FUNCTION _BorradoTotalObsoleto( cFile )

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
            // Rutina obsoleta: no vaciar temporales completos desde Drywall.
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


STATIC FUNCTION _BorraTemporalProyecto( cProyecto )

    LOCAL aTabs := { "TMP_RES", "TMP_MAT", "TMP_TRA", "TMP_CAB" }
    LOCAL i

    cProyecto := AllTrim( cProyecto )
    IF Empty( cProyecto )
        RETURN .F.
    ENDIF

    FOR i := 1 TO Len( aTabs )
        IF Select( aTabs[i] ) == 0
            IF File( aTabs[i] + ".DBF" )
                ABRIR_TABLA( aTabs[i], aTabs[i], "" )
            ELSE
                MsgStop( "Falta archivo " + aTabs[i] + ".DBF.", "Eliminar Proyecto" )
                RETURN .F.
            ENDIF
        ENDIF

        dbSelectArea( aTabs[i] )
        IF !NetFLock()
            MsgStop( "No se pudo bloquear " + aTabs[i] + ".", "Eliminar Proyecto" )
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
    NEXT

RETURN .T.


STATIC FUNCTION _ActivaPrimerTemporal()

    LOCAL cProyecto := ""

    IF Select( "TMP_CAB" ) == 0
        IF File( "TMP_CAB.DBF" )
            ABRIR_TABLA( "TMP_CAB", "TMP_CAB", "" )
        ELSE
            RETURN .F.
        ENDIF
    ENDIF

    dbSelectArea( "TMP_CAB" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted()
            cProyecto := AllTrim( FIELD->NUMERO )
            EXIT
        ENDIF
        dbSkip()
    ENDDO

    IF !Empty( cProyecto )
        RETURN DrywallActivarProyecto( cProyecto )
    ENDIF

RETURN .T.


// ============================================================================
// FUNCION: _MoverCabecera
// Descripción: Transfiere los datos de la cabecera al histórico HIS_CAB.
// ============================================================================
STATIC FUNCTION _MoverCabecera( cDoc, nTot, cEstado, cProyecto )

    LOCAL nArea := Select()

    IF ValType( cEstado ) != "C"
        cEstado := "C"
    ENDIF

    IF ValType( cProyecto ) != "C"
        cProyecto := DrywallProyectoActualNumero()
    ENDIF
    cProyecto := AllTrim( cProyecto )

    IF Select( "TMP_CAB" ) == 0
        MsgStop( "No hay cabecera de presupuesto activa.", "Error" )
        RETURN NIL
    ENDIF

    dbSelectArea( "TMP_CAB" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            EXIT
        ENDIF
        dbSkip()
    ENDDO

    IF Eof()
        MsgStop( "No se encontro la cabecera temporal " + cProyecto + ".", "Guardar en Firme" )
        RETURN NIL
    ENDIF

    dbSelectArea( "HIS_CAB" )
    IF !NetFLock()
        MsgStop( "No se pudo bloquear HIS_CAB.", "Guardar en Firme" )
        dbSelectArea( nArea )
        RETURN NIL
    ENDIF

    dbAppend()
    IF !NetErr()
        REPLACE Field->NUMERO     WITH cDoc
        REPLACE Field->FECHA      WITH TMP_CAB->FECHA
        REPLACE Field->TITULO     WITH TMP_CAB->TITULO
        REPLACE Field->ID_CLIENTE WITH TMP_CAB->ID_CLIENTE
        REPLACE Field->OBSERV     WITH TMP_CAB->OBSERV
        REPLACE Field->MARGEN     WITH TMP_CAB->MARGEN
        REPLACE Field->ESTADO     WITH cEstado
        DbFieldPutIf( "PRES_NUM",   Space( 10 ) )
        DbFieldPutIf( "FEC_CALC",   Date() )
        DbFieldPutIf( "FEC_CIERRE", Ctod( "" ) )
        dbCommit()
    ENDIF
    dbUnlock()
    dbSelectArea( nArea )
RETURN NIL

// ============================================================================
// FUNCION: _MoverResumen
// Descripción: Transfiere el resumen económico final a HIS_RES.
// ============================================================================
STATIC FUNCTION _MoverResumen( cDoc, cProyecto )
    LOCAL nArea := Select()

    IF ValType( cProyecto ) != "C"
        cProyecto := cDoc
    ENDIF

    dbSelectArea( "HIS_RES" )
    IF !NetFLock()
        MsgStop( "No se pudo bloquear HIS_RES.", "Guardar en Firme" )
        dbSelectArea( nArea )
        RETURN NIL
    ENDIF

    dbSelectArea( "TMP_RES" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( TMP_RES->NUMERO ) == AllTrim( cProyecto )
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
        ENDIF
        dbSelectArea( "TMP_RES" )
        dbSkip()
    ENDDO

    dbSelectArea( "HIS_RES" )
    dbCommit()
    dbUnlock()

    dbSelectArea( nArea )
RETURN NIL


FUNCTION DrywallGuardarCalculado()

    LOCAL nArea := Select()
    LOCAL cProyecto := ""

    IF !_ValidaCierreProyecto( @cProyecto )
        IF nArea > 0
            dbSelectArea( nArea )
        ENDIF
        RETURN .F.
    ENDIF

    IF !MsgYesNo( "Se guardara el proyecto como CALCULADO en historico." + Chr(13) + ;
                  "El proyecto temporal sera limpiado." + Chr(13) + ;
                  "Desea continuar?", "Guardar en Firme" )
        IF nArea > 0
            dbSelectArea( nArea )
        ENDIF
        RETURN .F.
    ENDIF

    IF !_EnsureHistoricoTables()
        IF nArea > 0
            dbSelectArea( nArea )
        ENDIF
        RETURN .F.
    ENDIF

    IF !_BorraHistoricoProyecto( cProyecto )
        IF nArea > 0
            dbSelectArea( nArea )
        ENDIF
        RETURN .F.
    ENDIF

    BEGIN SEQUENCE WITH {|oErr| Break( oErr )}

        _MoverCabecera( cProyecto, _TotalTmpRes( cProyecto ), "C", cProyecto )
        _MoverTramos( cProyecto, cProyecto )
        _MoverResumen( cProyecto, cProyecto )
        _MoverMateriales( cProyecto, cProyecto )

    RECOVER
        IF nArea > 0
            dbSelectArea( nArea )
        ENDIF
        MsgStop( "Error al guardar el proyecto. No se realizaron cambios.", "Guardar en Firme" )
        RETURN .F.
    END SEQUENCE

    _VaciarTemporales( cProyecto )

    MsgInfo( "Proyecto " + cProyecto + " guardado como calculado.", "Guardar en Firme" )

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN .T.


FUNCTION DrywallGuardarGenerar()

RETURN DrywallGuardarCalculado()


FUNCTION DrywallCerrarHistorico( cProyecto )

    LOCAL nArea := Select()
    LOCAL lOk := .F.

    cProyecto := AllTrim( cProyecto )

    IF Empty( cProyecto )
        MsgStop( "No se ha indicado proyecto historico.", "Cerrar Proyecto" )
        RETURN .F.
    ENDIF

    IF !_EnsureHistoricoTables()
        RETURN .F.
    ENDIF

    dbSelectArea( "HIS_CAB" )
    OrdSetFocus( "HIS_NUM" )
    IF !dbSeek( PadR( cProyecto, 6 ) )
        MsgStop( "No se encontro el historico " + cProyecto + ".", "Cerrar Proyecto" )
        RETURN .F.
    ENDIF

    IF FIELD->ESTADO == "F"
        MsgInfo( "El proyecto " + cProyecto + " ya esta cerrado.", "Cerrar Proyecto" )
        RETURN .F.
    ENDIF

    IF !DrywallValidarParaPresupuesto( cProyecto, "HIS" )
        IF nArea > 0
            dbSelectArea( nArea )
        ENDIF
        RETURN .F.
    ENDIF

    IF !MsgYesNo( "Se cerrara el proyecto " + cProyecto + "." + Chr(13) + ;
                  "Despues solo podra consultarse." + Chr(13) + ;
                  "Desea continuar?", "Cerrar Proyecto" )
        RETURN .F.
    ENDIF

    lOk := DrywallGenPresupuesto( cProyecto, "HIS" )

    IF lOk
        dbSelectArea( "HIS_CAB" )
        OrdSetFocus( "HIS_NUM" )
        IF dbSeek( PadR( cProyecto, 6 ) ) .AND. NetRLock()
            REPLACE FIELD->ESTADO WITH "F"
            DbFieldPutIf( "PRES_NUM", DrywallPresupuestoOrigenNumero( cProyecto ) )
            DbFieldPutIf( "FEC_CIERRE", Date() )
            dbCommit()
            dbUnlock()
        ENDIF
        MsgInfo( "Proyecto " + cProyecto + " cerrado.", "Cerrar Proyecto" )
    ENDIF

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN lOk


STATIC FUNCTION _MarkTmpGuardado()

    LOCAL nArea := Select()
    LOCAL cProyecto := DrywallProyectoActualNumero()

    IF Select( "TMP_CAB" ) > 0
        dbSelectArea( "TMP_CAB" )
        dbGoTop()
        DO WHILE !Eof()
            IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
                IF NetRLock()
                    REPLACE FIELD->ESTADO WITH "G"
                    IF FieldPos( "L_SUCIO" ) > 0
                        REPLACE FIELD->L_SUCIO WITH .F.
                    ENDIF
                    IF FieldPos( "L_CALC_DIR" ) > 0
                        REPLACE FIELD->L_CALC_DIR WITH .F.
                    ENDIF
                    dbCommit()
                    dbUnlock()
                ENDIF
                EXIT
            ENDIF
            dbSkip()
        ENDDO
    ENDIF

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN NIL


STATIC FUNCTION _EnsureHistoricoTables()

    IF !ABRIR_TABLA( "HIS_CAB", "HIS_CAB", "HIS_NUM" )
        RETURN .F.
    ENDIF
    IF !ABRIR_TABLA( "HIS_TRA", "HIS_TRA", "HTRA_NUM" )
        RETURN .F.
    ENDIF
    IF !ABRIR_TABLA( "HIS_MAT", "HIS_MAT", "HMAT_LIN" )
        RETURN .F.
    ENDIF
    IF !ABRIR_TABLA( "HIS_RES", "HIS_RES", "HRES_PK" )
        RETURN .F.
    ENDIF

RETURN .T.


STATIC FUNCTION _ValidaCierreProyecto( cProyecto )

    cProyecto := DrywallProyectoActualNumero()

    IF Empty( cProyecto )
        MsgStop( "No hay cabecera de proyecto activa.", "Guardar en Firme" )
        RETURN .F.
    ENDIF

RETURN DrywallValidarParaHistorico( cProyecto )


STATIC FUNCTION _TotalTmpRes( cProyecto )

    LOCAL nArea := Select()
    LOCAL nTotal := 0

    dbSelectArea( "TMP_RES" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == AllTrim( cProyecto )
            nTotal += FIELD->IMP_TOT
        ENDIF
        dbSkip()
    ENDDO

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN nTotal


STATIC FUNCTION _MoverMateriales( cDoc, cProyecto )

    LOCAL nArea := Select()

    IF ValType( cProyecto ) != "C"
        cProyecto := cDoc
    ENDIF

    dbSelectArea( "HIS_MAT" )
    IF !NetFLock()
        MsgStop( "No se pudo bloquear HIS_MAT.", "Guardar en Firme" )
        dbSelectArea( nArea )
        RETURN NIL
    ENDIF

    dbSelectArea( "TMP_MAT" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( TMP_MAT->NUMERO ) == AllTrim( cProyecto )
            dbSelectArea( "HIS_MAT" )
            dbAppend()
            REPLACE Field->NUMERO    WITH cDoc
            REPLACE Field->ID_LINEA  WITH TMP_MAT->ID_LINEA
            REPLACE Field->L_MANUAL  WITH TMP_MAT->L_MANUAL
            REPLACE Field->ORIGEN    WITH TMP_MAT->ORIGEN
            REPLACE Field->FAMILIA   WITH TMP_MAT->FAMILIA
            REPLACE Field->CODIGO    WITH TMP_MAT->CODIGO
            REPLACE Field->DESCRIP   WITH TMP_MAT->DESCRIP
            REPLACE Field->UNIDAD    WITH TMP_MAT->UNIDAD
            REPLACE Field->PESO_TOT  WITH TMP_MAT->PESO_TOT
            REPLACE Field->RENDIM    WITH TMP_MAT->RENDIM
            REPLACE Field->CANTIDAD  WITH TMP_MAT->CANTIDAD
            REPLACE Field->PRECIO    WITH TMP_MAT->PRECIO
            REPLACE Field->IMPORTE   WITH TMP_MAT->IMPORTE
            REPLACE Field->DETALLE   WITH TMP_MAT->DETALLE
            dbCommit()
        ENDIF
        dbSelectArea( "TMP_MAT" )
        dbSkip()
    ENDDO

    dbSelectArea( "HIS_MAT" )
    dbCommit()
    dbUnlock()

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN NIL


STATIC FUNCTION _CuentaProyecto( cAlias, cProyecto )

    LOCAL nArea := Select()
    LOCAL nCount := 0

    dbSelectArea( cAlias )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == AllTrim( cProyecto )
            nCount++
        ENDIF
        dbSkip()
    ENDDO

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN nCount


STATIC FUNCTION _BorraHistoricoProyecto( cProyecto )

    LOCAL aTabs := { "HIS_CAB", "HIS_TRA", "HIS_MAT", "HIS_RES" }
    LOCAL i

    FOR i := 1 TO Len( aTabs )
        dbSelectArea( aTabs[i] )
        dbGoTop()

        IF !NetFLock()
            MsgStop( "No se pudo bloquear " + aTabs[i] + ".", "Guardar en Firme" )
            RETURN .F.
        ENDIF

        DO WHILE !Eof()
            IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == AllTrim( cProyecto )
                dbDelete()
            ENDIF
            dbSkip()
        ENDDO

        dbCommit()
        dbUnlock()
    NEXT

RETURN .T.


STATIC FUNCTION _VaciarTemporales( cProyecto )

    _BorraTemporalProyecto( cProyecto )
    _ActivaPrimerTemporal()

RETURN NIL
