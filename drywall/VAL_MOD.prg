/*
------------------------------------------------------------------------------
 PROYECTO    : Sistema de Gestión Integral
 ARCHIVO     : VAL_MOD.PRG
 DESCRIPCION : Valoración Económica (Edición de precios en el resumen).
               Implementación OOP con estrategia Boy Scout y WVG.
------------------------------------------------------------------------------
*/

#include "inkey.ch"

// ============================================================================
// FUNCION: Valorar
// Descripción: Permite editar los precios unitarios del resumen de materiales.
// ============================================================================
FUNCTION Valorar()
    // --- REGLA DEL BOY SCOUT: VARIABLES DE ESTADO LOCAL ---
    LOCAL nAreaAnt
    LOCAL nOrdAnt
    
    // --- VARIABLES DE INTERFAZ ---
    LOCAL oWin
    LOCAL oGrd
    LOCAL nTop
    LOCAL nLft
    LOCAL nBot
    LOCAL nRgt
    
    // --- VARIABLES DE NEGOCIO ---
    LOCAL nTot := 0

    // 1. GUARDAMOS EL ESTADO ACTUAL (BOY SCOUT)
    nAreaAnt := Select()
    nOrdAnt := IndexOrd()

    // 2. VALIDACIONES DE DATOS CON WVG
    IF !IsDbUsed( "TMP_RES" )
        MsgStop( "No existe el resumen de materiales. Debe calcular primero.", "Atencion" )
        RETURN NIL
    ENDIF

    dbSelectArea( "TMP_RES" )
    
    IF RecCount() == 0
        MsgInfo( "El resumen esta vacio. No hay materiales que valorar.", "Aviso" )
        RETURN NIL
    ENDIF

    // 3. CONFIGURACIÓN DE GEOMETRÍA (Una línea por instrucción)
    nTop := 4
    nLft := 4
    nBot := MaxRow() - 4
    nRgt := MaxCol() - 4
    
    // 4. CREACIÓN DE LA VENTANA PROFESIONAL (OOP)
    oWin := TWindow():New( nTop, nLft, nBot, nRgt )
    oWin:SetTitle( " VALORACION ECONOMICA (Edicion de Precios) " )
    oWin:SetColor( "N/W" ) 
    oWin:Open()

    // Indicaciones para el usuario
    oWin:Say( 0, 2, " [ENTER]: Editar Precio | [ESC]: Salir y Totalizar ", "W+/W" )

    // 5. CONFIGURACIÓN DEL GRID DE VALORACIÓN
    oGrd := TGrid():New( nTop + 2, nLft + 1, nBot - 2, nRgt - 1 )
    oGrd:SetAlias( "TMP_RES" )
    
    // Definición de columnas (Regla de Oro)
    oGrd:AddColumn( "CODIGO", 12, {|| TMP_RES->CODIGO }, "@!", "RES_PK" )
    oGrd:AddColumn( "DESCRIPCION", 30, {|| TMP_RES->DESCRIP }, "@!", NIL )
    oGrd:AddColumn( "CANTIDAD", 10, {|| TMP_RES->CANT_TOT }, "999,999.99", NIL )
    oGrd:AddColumn( "UNIDAD", 6, {|| TMP_RES->UNIDAD }, "@!", NIL )
    
    // Columna de Precio (La que el usuario editará)
    oGrd:AddColumn( "PRECIO", 10, {|| TMP_RES->PRECIO }, "@E 999.99", NIL )
    oGrd:AddColumn( "IMPORTE", 12, {|| TMP_RES->IMP_TOT }, "@E 9,999,999.99", NIL )

    // 6. ASIGNACIÓN DE EVENTOS
    // Al pulsar ENTER, llamamos a la función de edición
    oGrd:MapKey( K_ENTER, {|| _GestionarEdicion( oGrd ) } ) 
    
    // 7. EJECUCIÓN DEL MÓDULO
    oWin:AddControl( oGrd )
    oWin:Run()
    
    // 8. TOTALIZACIÓN FINAL
    // Calculamos el importe total después de las ediciones
    dbSelectArea( "TMP_RES" )
    SUM Field->IMP_TOT TO nTot
    
    oWin:Close()
    
    // Notificación final con diálogo nativo
    MsgInfo( "Total del Presupuesto Valorizado: " + Transform( nTot, "@E 9,999,999.99" ), "Valoracion" )

    // 9. REGLA DEL BOY SCOUT: RESTAURACIÓN
    IF nAreaAnt > 0
        dbSelectArea( nAreaAnt )
        dbSetOrder( nOrdAnt )
    ENDIF

RETURN NIL

// ============================================================================
// FUNCION: _GestionarEdicion
// Descripción: Lógica de edición en línea (Inline Edit) del precio.
// ============================================================================
STATIC FUNCTION _GestionarEdicion( oGrd )
    LOCAL nNuevoVal
    LOCAL nCant

    // 1. BLOQUEO DE REGISTRO SEGURO
    IF !NetRLock()
        MsgStop( "El registro esta siendo usado por otro proceso.", "Bloqueo" )
        RETURN NIL
    ENDIF

    // 2. LLAMADA AL METODO DE EDICIÓN DEL GRID
    // El método EditInline detiene el flujo, pone un GET y devuelve el valor
    nNuevoVal := oGrd:EditInline()

    // 3. PERSISTENCIA DE DATOS
    IF nNuevoVal != NIL
        nCant := TMP_RES->CANT_TOT
        
        // Actualizamos precio e importe total de la línea
        REPLACE Field->PRECIO  WITH nNuevoVal
        REPLACE Field->IMP_TOT WITH ( nCant * nNuevoVal )
        
        // Refrescamos la línea en el grid para ver el nuevo importe calculado
        oGrd:Refresh()
    ENDIF

    dbUnlock()

RETURN NIL


// ============================================================================
// FUNCION: _ClientesSave
// Descripción: Valida y persiste los datos del búfer en la tabla CLIENTES.
//              Gestiona el alta (dbAppend) o modificación según lNew.
// ============================================================================
FUNCTION _ClientesSave( lNew, cCod, cNom, cCif, nDto, cDir, cCiu, cPro, cC_P, cTel, cEma )
    LOCAL lOk := .F.

    // 1. VALIDACIÓN DE NEGOCIO (Diálogo WVG)
    IF Empty( AllTrim( cNom ) )
        MsgStop( "El Nombre o Razón Social es obligatorio para continuar.", "Validación" )
        RETURN .F.
    ENDIF

    // 2. CONFIRMACIÓN FINAL
    IF !MsgYesNo( "¿Desea guardar los cambios en la ficha del cliente?", "Confirmar" )
        RETURN .F.
    ENDIF

    // 3. OPERACIÓN DE ESCRITURA
    IF lNew
        // Si es un registro nuevo, creamos el hueco
        dbAppend()
        IF NetErr()
            MsgStop( "Error al intentar crear un nuevo registro de cliente.", "Error de Red" )
            RETURN .F.
        ENDIF
    ENDIF

    // Bloqueamos el registro (nuevo o existente) con nuestro estándar unificado
    IF NetRLock()
        
        // Regla de Oro: Un REPLACE por línea para facilitar el debug
        REPLACE Field->CODIGO    WITH cCod
        REPLACE Field->NOMBRE    WITH cNom
        REPLACE Field->CIF       WITH cCif
        REPLACE Field->DTO       WITH nDto
        REPLACE Field->DIRECCION WITH cDir
        REPLACE Field->CIUDAD    WITH cCiu
        REPLACE Field->PROVINCIA WITH cPro
        REPLACE Field->CP        WITH cC_P
        REPLACE Field->TELEFONO  WITH cTel
        REPLACE Field->EMAIL     WITH cEma
        
        // Forzamos el volcado a disco y liberamos
        dbCommit()
        dbUnlock()
        
        MsgInfo( "Los datos del cliente se han guardado correctamente.", "Éxito" )
        lOk := .T.
    ELSE
        // El mensaje de error ya lo lanza NetRLock() internamente
        lOk := .F.
    ENDIF

RETURN lOk