/*
------------------------------------------------------------------------------
 PROYECTO    : Sistema de Gestión Integral
 ARCHIVO     : REPT_MOD.PRG
 DESCRIPCION : Módulo de generación de informes (Salida a Texto).
               Implementación con estrategia Boy Scout y diálogos WVG.
------------------------------------------------------------------------------
*/

#include "inkey.ch"

// ============================================================================
// FUNCION: RepTramos
// Descripción: Genera un listado técnico de los tramos (Borrador o Histórico).
// ============================================================================
FUNCTION RepTramos( cMode )
    // --- REGLA DEL BOY SCOUT: ESTADO LOCAL ---
    LOCAL nAreaOri
    LOCAL nOrdOri
    
    // --- VARIABLES DE INFORME ---
    LOCAL cAlias
    LOCAL cFile
    LOCAL cTit
    
    nAreaOri := Select()
    nOrdOri := IndexOrd()

    // 1. DETERMINACIÓN DEL MODO (Capa de lógica)
    IF cMode == NIL .OR. cMode == "TMP"
        cAlias := "TMP_TRA"
        cFile  := "RPT_TRA_T.TXT"
        cTit   := "PROYECTO ACTUAL: LISTADO DE TRAMOS"
    ELSE
        cAlias := "HIS_TRA"
        cFile  := "RPT_TRA_H.TXT"
        cTit   := "HISTORICO: LISTADO DE TRAMOS"
    ENDIF

    // 2. VALIDACIÓN DE DATOS (Uso de MsgStop nativo) 
    IF Select( cAlias ) == 0
        MsgStop( "La tabla " + cAlias + " no está abierta. No se puede generar el informe.", "Error" )
        RETURN NIL
    ENDIF

    dbSelectArea( cAlias )
    dbGoTop()

    // 3. REDIRECCIÓN A ARCHIVO
    FErase( cFile )
    SET PRINTER TO ( cFile )
    SET PRINTER ON

    // 4. CABECERA DEL INFORME
    ? cTit
    ? "Fecha: ", Date()
    ? "Hora.: ", Time()
    ? Replicate( "=", 85 )
    ? "ID    CONCEPTO                 TIPO             LARGO    ALTO   M2/ML"
    ? Replicate( "-", 85 )

    // 5. CUERPO DEL INFORME (Bucle de lectura)
    DO WHILE !Eof()
        ? PadR( Field->ID_LINEA, 5 )
        ?? PadR( Field->CONCEPTO, 25 )
        ?? PadR( Field->TIPO, 16 )
        ?? Str( Field->LARGO, 8, 2 )
        ?? Str( Field->ALTO, 8, 2 )
        ?? Str( Field->LARGO * Field->ALTO, 9, 2 )
        
        dbSkip()
    ENDDO

    // 6. PIE DE INFORME Y CIERRE DE CANAL
    ? Replicate( "-", 85 )
    ? "Fin del Informe"
    
    SET PRINTER OFF
    SET PRINTER TO
    SET PRINTER ON
    SET PRINTER TO

    // 7. NOTIFICACIÓN WVG 
    MsgInfo( "El informe se ha generado correctamente en: " + cFile, "Informe Finalizado" )

    // 8. RESTAURACIÓN DEL "CAMPAMENTO" (BOY SCOUT)
    IF nAreaOri > 0
        dbSelectArea( nAreaOri )
        dbSetOrder( nOrdOri )
    ENDIF

RETURN NIL

// ============================================================================
// FUNCION: RepMatRes
// Descripción: Genera el resumen económico agrupado de materiales.
// ============================================================================
FUNCTION RepMatRes()
    // --- REGLA DEL BOY SCOUT ---
    LOCAL nAreaOri
    LOCAL cAlias := "HIS_RES"
    LOCAL cFile  := "RPT_RESUMEN_HIS.TXT"

    nAreaOri := Select()

    // 1. VALIDACIÓN
    IF Select( cAlias ) == 0
        MsgStop( "No hay datos históricos cargados para el resumen.", "Aviso" )
        RETURN NIL
    ENDIF

    // 2. PROCESO DE IMPRESIÓN
    FErase( cFile )
    SET PRINTER TO ( cFile )
    SET PRINTER ON

    ? "HISTORICO: RESUMEN CONSOLIDADO DE MATERIALES"
    ? "Fecha de emisión: ", Date()
    ? Replicate( "=", 85 )
    ? "CODIGO          DESCRIPCION                    UNIDAD   CANTIDAD    IMPORTE"
    ? Replicate( "-", 85 )

    dbSelectArea( cAlias )
    dbGoTop()

    DO WHILE !Eof()
        ? PadR( Field->CODIGO, 15 )
        ?? PadR( Field->DESCRIP, 30 )
        ?? PadR( Field->UNIDAD, 8 )
        ?? Str( Field->CANT_TOT, 10, 2 )
        ?? Str( Field->IMP_TOT, 12, 2 )
        
        dbSkip()
    ENDDO

    ? Replicate( "-", 85 )
    
    SET PRINTER OFF
    SET PRINTER TO

    MsgInfo( "Resumen económico generado en: " + cFile, "Éxito" )

    // 3. RESTAURACIÓN
    IF nAreaOri > 0
        dbSelectArea( nAreaOri )
    ENDIF

RETURN NIL


FUNCTION RepMatDet()
    MsgInfo( "Generando Informe Detallado de Materiales...", "Informes" )
RETURN NIL