/*
------------------------------------------------------------------------------
 PROYECTO    : Sistema de Gestión Integral
 ARCHIVO     : MAT_EDIT.PRG
 DESCRIPCION : Gestión de despiece de materiales por tramo.
               Implementación OOP con colores condicionales y WVG.
------------------------------------------------------------------------------
*/

#include "inkey.ch"

// ============================================================================
// FUNCION: Mat_Edit
// Descripción: Muestra y gestiona los materiales asignados a un tramo técnico.
// ============================================================================
FUNCTION Mat_Edit( nIdLin )
    // --- REGLA DEL BOY SCOUT: ESTADO LOCAL ---
    LOCAL nAreaOri
    LOCAL cScope
    
    // --- VARIABLES DE INTERFAZ ---
    LOCAL oWin
    LOCAL oGrid
    LOCAL nI
    LOCAL oCol
    LOCAL bColorBlock

    nAreaOri := Select()

    // 1. PREPARACION DE DATOS Y FILTRO (Scope)
    IF Select( "TMP_MAT" ) == 0
        MsgStop( "La tabla de materiales temporales no esta abierta.", "Error" )
        RETURN NIL
    ENDIF
    
    dbSelectArea( "TMP_MAT" )
    dbSetOrder( 1 ) // NUMERO + STR(ID_LINEA)
    
    // Filtramos para ver solo los materiales del tramo actual
    cScope := TMP_TRA->NUMERO + Str( nIdLin, 4 )
    OrdScope( 0, cScope )
    OrdScope( 1, cScope )
    dbGoTop()

    // 2. VENTANA CONTENEDORA (OOP)
    oWin := TWindow():New( 6, 10, 22, 90, " DESGLOSE DE MATERIALES " )
    oWin:SetColor( "N/W" )
    oWin:Open()

    // 3. CONFIGURACION DEL GRID PROFESIONAL
    oGrid := TGrid():New( 1, 1, oWin:Height() - 2, oWin:Width() - 2 )
    oGrid:SetAlias( "TMP_MAT" )
    
    // Definimos paleta: 1=AutoNormal, 2=AutoSel, 3=ManNormal, 4=ManSel
    oGrid:SetColor( "N/W, W+/B, G+/W, W+/G" )

    // --- DEFINICION DE COLUMNAS ---
    oGrid:AddCol( "ST", 4, {|| iif( Field->L_MANUAL, "MAN", "AUT" ) }, "@!" )
    oGrid:AddCol( "CODIGO", 15, {|| Field->CODIGO }, "@!" )
    oGrid:AddCol( "DESCRIPCION", 30, {|| Field->DESCRIP }, "@!S25" )
    oGrid:AddCol( "CANT", 10, {|| Field->CANTIDAD }, "999,999.99" )
    oGrid:AddCol( "IMPORTE", 12, {|| Field->IMPORTE }, "999,999.99" )

    // 4. MAPEO DE EVENTOS (TECLADO)
    //oGrid:MapKey( K_INS, {|| _AddNewMat( nIdLin ) } )
    oGrid:MapKey( K_F9, {|| _ToggleState() } )
    oGrid:MapKey( K_ENTER, {|| _ProcessEnter() } )
    oGrid:MapKey( K_DEL, {|| _ProcessDel() } )

    // 5. LOGICA VISUAL: COLORES SEGUN ESTADO
    // Bloque que devuelve el par de colores {Normal, Seleccionado}
    bColorBlock := {|| iif( Field->L_MANUAL, { 3, 4 }, { 1, 2 } ) }

    // Aplicamos el bloque de color a todas las columnas del browse interno
    FOR nI := 1 TO Len( oGrid:aColumns )
        oCol := oGrid:GetColumn( nI )
        oCol:bColorBlock := bColorBlock
    NEXT

    // 6. EJECUCION
    oWin:AddControl( oGrid )
    oWin:Run()

    // 7. LIMPIEZA DEL CAMPAMENTO (BOY SCOUT)
    OrdScope( 0, NIL )
    OrdScope( 1, NIL )
    oWin:Close()
    
    IF nAreaOri > 0
        dbSelectArea( nAreaOri )
    ENDIF

RETURN NIL

// ============================================================================
// FUNCION: _ProcessEnter
// Descripción: Gestiona la edición de cantidad si el registro es manual.
// ============================================================================
STATIC FUNCTION _ProcessEnter()
    LOCAL lDoEdit := .F.
    IF FIELD->L_MANUAL
        lDoEdit := .T.
    ELSE
        IF MsgYesNo( "Registro Automático. ¿Convertir a MANUAL?", "Atención" )
            IF NetRLock()
                REPLACE FIELD->L_MANUAL WITH .T.
                dbUnlock()
                lDoEdit := .T.
            ENDIF
        ENDIF
    ENDIF
    IF lDoEdit
        _EditQty()
    ENDIF
RETURN NIL

// ============================================================================
// FUNCION: _ProcessDel
// Descripción: Borrado seguro de líneas manuales.
// ============================================================================
STATIC FUNCTION _ProcessDel()
    IF !Field->L_MANUAL
        MsgInfo( "Los registros AUTOMATICOS no pueden borrarse. Use F9 para cambiar estado.", "Aviso" )
        RETURN NIL
    ENDIF
    
    IF MsgYesNo( "¿Desea eliminar esta linea de material manual?", "Confirmar" )
        IF NetRLock()
            dbDelete()
            dbUnlock()
        ENDIF
    ENDIF
    
RETURN NIL




STATIC FUNCTION _ToggleState()
    // Sustitución de NetRLock por NetRLock estándar
    IF NetRLock()
        REPLACE FIELD->L_MANUAL WITH !FIELD->L_MANUAL
        dbUnlock()
    ENDIF
RETURN NIL

STATIC FUNCTION _EditQty()
    LOCAL nVal := Field->CANTIDAD
    // Para simplificar, usamos un MsgGet o similar si lo tienes en OOpLib
    // Aquí iría el GET/READ sobre la celda
RETURN NIL