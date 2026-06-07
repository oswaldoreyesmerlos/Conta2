/*
 * ARCHIVO  : Informes_Inventario.prg
 * PROPOSITO: Informes de articulos/stock aislados del build principal.
 *
 * NOTA
 * ----
 * Este archivo conserva trabajo reutilizable para una app con inventario.
 * Si se reactiva, hay que compilarlo junto con un modulo que aporte
 * _MostrarInformeTexto() o adaptar estas funciones al sistema de informes
 * de la nueva aplicacion.
 */

#include "OOp.ch"


// ============================================================================
// InformeArticulos()
// ============================================================================
FUNCTION InformeArticulos()

    LOCAL cTexto

    IF Select( "ART_I" ) == 0
        IF !ABRIR_TABLA( "ARTICULOS", "ART_I", "ART_DES" )
            RETURN NIL
        ENDIF
    ENDIF

    DbSelectArea( "ART_I" )
    OrdSetFocus( "ART_DES" )
    DbGoTop()

    cTexto := PadC( "INFORME DE ARTICULOS", 80 ) + hb_Eol()
    cTexto += Replicate( "-", 80 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol() + hb_Eol()
    cTexto += PadR( "CODIGO", 10 ) + " " + PadR( "DESCRIPCION", 40 ) + " "
    cTexto += PadL( "STOCK", 12 ) + " " + PadL( "PRECIO", 12 ) + " "
    cTexto += PadR( "FAMILIA", 3 ) + " BAJA" + hb_Eol()
    cTexto += Replicate( "-", 80 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted()
            cTexto += PadR( AllTrim( ART_I->CODIGO ), 10 ) + " "
            cTexto += PadR( AllTrim( ART_I->DESCRIP ), 40 ) + " "
            cTexto += PadL( Transform( ART_I->STOCK, "999,999.99" ), 12 ) + " "
            cTexto += PadL( Transform( ART_I->PRECIO, "999,999.99" ), 12 ) + " "
            cTexto += PadR( AllTrim( ART_I->FAMILIA ), 3 ) + " "
            cTexto += If( ART_I->BAJA, "SI", "NO" ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

RETURN _MostrarInformeTexto( "INFORME DE ARTICULOS", cTexto, "INFORME_ARTICULOS.TXT" )


// ============================================================================
// InformeStockMinimo()
// Articulos con stock actual por debajo del minimo definido
// ============================================================================
FUNCTION InformeStockMinimo()

    LOCAL cTexto
    LOCAL nCont := 0

    IF Select( "ART_SM" ) == 0
        IF !ABRIR_TABLA( "ARTICULOS", "ART_SM", "ART_DES" )
            RETURN NIL
        ENDIF
    ENDIF

    DbSelectArea( "ART_SM" )
    OrdSetFocus( "ART_DES" )
    DbGoTop()

    cTexto := PadC( "ARTICULOS POR DEBAJO DE STOCK MINIMO", 85 ) + hb_Eol()
    cTexto += Replicate( "-", 85 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol() + hb_Eol()
    cTexto += PadR( "CODIGO", 10 ) + " " + PadR( "DESCRIPCION", 40 ) + " "
    cTexto += PadL( "STOCK ACT.", 10 ) + " " + PadL( "STOCK MIN.", 10 ) + " "
    cTexto += PadL( "DIFERENCIA", 10 ) + " UNIDAD" + hb_Eol()
    cTexto += Replicate( "-", 85 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted() .AND. !ART_SM->BAJA .AND. !ART_SM->ES_SERV
            IF ART_SM->STOCK < ART_SM->STO_MIN
                nCont++
                cTexto += PadR( AllTrim( ART_SM->CODIGO  ), 10 ) + " "
                cTexto += PadR( AllTrim( ART_SM->DESCRIP ), 40 ) + " "
                cTexto += PadL( AllTrim( Str( ART_SM->STOCK, 10, 2 ) ), 10 ) + " "
                cTexto += PadL( AllTrim( Str( ART_SM->STO_MIN, 10, 2 ) ), 10 ) + " "
                cTexto += PadL( AllTrim( Str( ART_SM->STO_MIN - ART_SM->STOCK, 10, 2 ) ), 10 ) + " "
                cTexto += AllTrim( ART_SM->UNIDAD ) + hb_Eol()
            ENDIF
        ENDIF
        DbSkip()
    ENDDO

    cTexto += Replicate( "-", 85 ) + hb_Eol()
    cTexto += "Total articulos bajo minimo: " + AllTrim( Str( nCont ) ) + hb_Eol()

RETURN _MostrarInformeTexto( "ARTICULOS BAJO STOCK MINIMO", cTexto, "STOCK_MINIMO.TXT" )


// ============================================================================
// InformeClientesDrywall()
// ============================================================================
FUNCTION InformeClientesDrywall()

    LOCAL cTexto := ""

    IF Select( "CLI_ID" ) == 0
        IF !File( "CLIENTES.DBF" )
            MsgStop( "La tabla CLIENTES no existe. Ejecute Seed primero.", "Informe" )
            RETURN NIL
        ENDIF
        IF !ABRIR_TABLA( "CLIENTES", "CLI_ID", "CLI_NOM" )
            RETURN NIL
        ENDIF
    ENDIF

    DbSelectArea( "CLI_ID" )
    BEGIN SEQUENCE WITH {|oErr| Break(oErr)}
        OrdSetFocus( "CLI_NOM" )
    RECOVER
        MsgStop( "El indice CLI_NOM no esta disponible en CLIENTES.", "Informe" )
        RETURN NIL
    END SEQUENCE
    DbGoTop()

    cTexto := PadC( "INFORME DE CLIENTES", 80 ) + hb_Eol()
    cTexto += Replicate( "-", 80 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol() + hb_Eol()

    cTexto += PadR( "CODIGO", 10 ) + " "
    cTexto += PadR( "NOMBRE", 30 ) + " "
    cTexto += PadR( "NIF", 13 ) + " "
    cTexto += PadR( "CIUDAD", 20 ) + " "
    cTexto += PadR( "TELEFONO", 12 ) + " "
    cTexto += "BAJA" + hb_Eol()
    cTexto += Replicate( "-", 80 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted()
            cTexto += PadR( AllTrim( CLI_ID->ID ), 10 ) + " "
            cTexto += PadR( AllTrim( CLI_ID->NOMBRE + " " + CLI_ID->APELLIDO ), 30 ) + " "
            cTexto += PadR( AllTrim( CLI_ID->NIF ), 13 ) + " "
            cTexto += PadR( AllTrim( CLI_ID->CIUDAD ), 20 ) + " "
            cTexto += PadR( AllTrim( CLI_ID->TELEFONO ), 12 ) + " "
            cTexto += If( CLI_ID->BAJA, "SI", "NO" ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

RETURN _MostrarInformeTexto( "INFORME DE CLIENTES", cTexto, "INFORME_CLIENTES.TXT" )


// ============================================================================
// InformeProyectos()
// Solo cabeceras de proyectos activos (TMP_CAB)
// ============================================================================
FUNCTION InformeProyectos()

    LOCAL cTexto := ""

    IF Select( "TPC_I" ) == 0
        IF !ABRIR_TABLA( "TMP_CAB", "TPC_I", "" )
            RETURN NIL
        ENDIF
    ENDIF

    DbSelectArea( "TPC_I" )
    DbGoTop()

    cTexto += PadC( "LISTADO DE PROYECTOS", 90 ) + hb_Eol()
    cTexto += Replicate( "-", 90 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol() + hb_Eol()

    cTexto += PadR( "NUMERO", 8 ) + " "
    cTexto += PadR( "FECHA", 12 ) + " "
    cTexto += PadR( "CLIENTE", 15 ) + " "
    cTexto += "TITULO" + hb_Eol()
    cTexto += Replicate( "-", 90 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted()
            cTexto += PadR( AllTrim( TPC_I->NUMERO ), 8 ) + " "
            cTexto += PadR( DToC( TPC_I->FECHA ), 12 ) + " "
            cTexto += PadR( AllTrim( TPC_I->ID_CLIENTE ), 15 ) + " "
            cTexto += AllTrim( TPC_I->TITULO ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

RETURN _MostrarInformeTexto( "LISTADO DE PROYECTOS", cTexto, "LISTADO_PROYECTOS.TXT" )


// ============================================================================
// InformeHistoricos()
// Cabeceras de proyectos archivados (HIS_CAB)
// ============================================================================
FUNCTION InformeHistoricos()

    LOCAL cTexto := ""

    IF Select( "HIS_I" ) == 0
        IF !ABRIR_TABLA( "HIS_CAB", "HIS_I", "" )
            RETURN NIL
        ENDIF
    ENDIF

    DbSelectArea( "HIS_I" )
    DbGoTop()

    cTexto += PadC( "LISTADO DE PROYECTOS HISTORICOS", 90 ) + hb_Eol()
    cTexto += Replicate( "-", 90 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol() + hb_Eol()

    cTexto += PadR( "NUMERO", 8 ) + " "
    cTexto += PadR( "FECHA", 12 ) + " "
    cTexto += PadR( "CLIENTE", 15 ) + " "
    cTexto += "TITULO" + hb_Eol()
    cTexto += Replicate( "-", 90 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted()
            cTexto += PadR( AllTrim( HIS_I->NUMERO ), 8 ) + " "
            cTexto += PadR( DToC( HIS_I->FECHA ), 12 ) + " "
            cTexto += PadR( AllTrim( HIS_I->ID_CLIENTE ), 15 ) + " "
            cTexto += AllTrim( HIS_I->TITULO ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

RETURN _MostrarInformeTexto( "PROYECTOS HISTORICOS", cTexto, "LISTADO_HISTORICOS.TXT" )


// ============================================================================
// VisorProyectos()
// Grid interactivo de todos los proyectos (TMP + HIS).
// ENTER sobre un proyecto → muestra su cálculo (TMP_RES / HIS_RES).
// ============================================================================
FUNCTION VisorProyectos( cModo )

    LOCAL nArea := Select()
    LOCAL oWin, oGrid, aData
    LOCAL cTitulo
    LOCAL cAyuda

    DEFAULT cModo TO "ALL"
    cModo := Upper( AllTrim( cModo ) )

    aData := _VisorCargarDatos( cModo )

    IF Empty( aData )
        MsgInfo( _VisorMensajeVacio( cModo ), "Visor" )
        RETURN NIL
    ENDIF

    cTitulo := _VisorTitulo( cModo )
    cAyuda  := _VisorAyuda( cModo )

    oWin := TWindow():New( 2, 2, GfxMaxRow() - 2, GfxMaxCol() - 2, cTitulo )

    oWin:AddCtrl( TLabel():New( 1, 2, cAyuda, oWin ) )

    oGrid := TGrid():New( 3, 1, GfxMaxRow() - 6, GfxMaxCol() - 4, oWin )
    oGrid:aData    := aData
    oGrid:nSeekCol := 3
    oGrid:AddColumn( "ORIGEN",   6,  "@!", { |a| a[1] } )
    oGrid:AddColumn( "NUMERO",   8,  "@!", { |a| a[2] } )
    oGrid:AddColumn( "FECHA",   12,  "@!", { |a| a[3] } )
    oGrid:AddColumn( "CLIENTE", 15,  "@!", { |a| a[4] } )
    oGrid:AddColumn( "TITULO",  35,  "@!", { |a| a[5] } )
    oGrid:AddColumn( "ESTADO",  12,  "@!", { |a| a[6] } )

    oGrid:bEnter := {|| _VisorVerCalculo( oGrid ) }

    oWin:AddCtrl( oGrid )
    oWin:AddCtrl( TButton():New( GfxMaxRow() - 4, 2, GfxMaxRow() - 3, 18, oWin, "REFRESCAR", ;
        {|| aData := _VisorCargarDatos( cModo ), oGrid:aData := aData, oGrid:Paint() } ) )
    oWin:AddCtrl( TButton():New( GfxMaxRow() - 4, 20, GfxMaxRow() - 3, 38, oWin, _VisorBotonAccion( cModo ), ;
        {|| _VisorAccionProyecto( oGrid, cModo ), ;
            aData := _VisorCargarDatos( cModo ), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } ) )
    oWin:AddCtrl( TButton():New( GfxMaxRow() - 4, 40, GfxMaxRow() - 3, 56, oWin, "VALORAR", ;
        {|| _VisorValorarHistorico( oGrid ), ;
            aData := _VisorCargarDatos( cModo ), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } ) )
    oWin:AddCtrl( TButton():New( GfxMaxRow() - 4, GfxMaxCol() - 20, GfxMaxRow() - 3, GfxMaxCol() - 4, oWin, "CERRAR", ;
        {|| oWin:Close() } ) )

    oWin:Run()

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN NIL


FUNCTION VisorProyectosCurso()

RETURN VisorProyectos( "TMP" )


FUNCTION VisorProyectosHistorico()

RETURN VisorProyectos( "HIS" )


STATIC FUNCTION _VisorTitulo( cModo )

    DO CASE
    CASE cModo == "TMP"
        RETURN "PROYECTOS EN CURSO"
    CASE cModo == "HIS"
        RETURN "PROYECTOS HISTORICOS"
    OTHERWISE
        RETURN "VISOR DE PROYECTOS"
    ENDCASE

RETURN "VISOR DE PROYECTOS"


STATIC FUNCTION _VisorAyuda( cModo )

    DO CASE
    CASE cModo == "TMP"
        RETURN "[ENTER] Ver calculo   [ACTIVAR] Proyecto actual   [VALORAR] Valoracion temporal"
    CASE cModo == "HIS"
        RETURN "[ENTER] Ver calculo   [RECUPERAR] Reabrir calculado   [VALORAR] Historico"
    OTHERWISE
        RETURN "[ENTER] Ver calculo   [ACCION] Activar/Reabrir   [VALORAR] Editar valoracion"
    ENDCASE

RETURN ""


STATIC FUNCTION _VisorBotonAccion( cModo )

    IF cModo == "TMP"
        RETURN "ACTIVAR"
    ENDIF

RETURN "RECUPERAR"


STATIC FUNCTION _VisorMensajeVacio( cModo )

    DO CASE
    CASE cModo == "TMP"
        RETURN "No hay proyectos en curso."
    CASE cModo == "HIS"
        RETURN "No hay proyectos historicos."
    OTHERWISE
        RETURN "No hay proyectos registrados."
    ENDCASE

RETURN "No hay proyectos registrados."


STATIC FUNCTION _VisorCargarDatos( cModo )

    LOCAL aData := {}
    LOCAL cEstado
    LOCAL lResAbierta

    DEFAULT cModo TO "ALL"
    cModo := Upper( AllTrim( cModo ) )

    // Asegurar TMP_CAB abierta
    IF cModo != "HIS" .AND. Select( "TMP_CAB" ) == 0
        IF !ABRIR_TABLA( "TMP_CAB", "TMP_CAB", "" )
            // No se pudo abrir, omitimos proyectos activos
        ENDIF
    ENDIF

    // Asegurar TMP_RES abierta (para consultar estado)
    lResAbierta := .F.
    IF cModo != "HIS" .AND. Select( "TMP_RES" ) == 0
        IF ABRIR_TABLA( "TMP_RES", "TMP_RES", "RES_PK" )
            lResAbierta := .T.
        ENDIF
    ELSEIF cModo != "HIS"
        dbSelectArea( "TMP_RES" )
        BEGIN SEQUENCE WITH {|oErr| Break(oErr)}
            OrdSetFocus( "RES_PK" )
        RECOVER
        END SEQUENCE
        lResAbierta := .T.
    ENDIF

    // Proyectos activos (TMP_CAB)
    IF cModo != "HIS" .AND. Select( "TMP_CAB" ) > 0
        dbSelectArea( "TMP_CAB" )
        dbGoTop()
        DO WHILE !Eof()
            IF !Deleted()
                cEstado := "Pendiente"
                IF lResAbierta
                    BEGIN SEQUENCE WITH {|oErr| Break(oErr)}
                        TMP_RES->( dbSeek( AllTrim( TMP_CAB->NUMERO ) ) )
                        IF TMP_RES->( Found() )
                            cEstado := "Calculado"
                        ENDIF
                    RECOVER
                    END SEQUENCE
                ENDIF
                IF FieldPos( "L_ACTIVO" ) > 0 .AND. TMP_CAB->L_ACTIVO
                    cEstado := "Actual"
                ENDIF
                AAdd( aData, { ;
                    "TMP", ;
                    AllTrim( TMP_CAB->NUMERO ), ;
                    DToC( TMP_CAB->FECHA ), ;
                    AllTrim( TMP_CAB->ID_CLIENTE ), ;
                    AllTrim( TMP_CAB->TITULO ), ;
                    cEstado } )
            ENDIF
            dbSkip()
        ENDDO
    ENDIF

    // Asegurar HIS_CAB abierta
    IF cModo != "TMP" .AND. Select( "HIS_CAB" ) == 0
        IF !ABRIR_TABLA( "HIS_CAB", "HIS_CAB", "" )
            // No se pudo abrir, omitimos archivados
        ENDIF
    ENDIF

    // Proyectos archivados (HIS_CAB)
    IF cModo != "TMP" .AND. Select( "HIS_CAB" ) > 0
        dbSelectArea( "HIS_CAB" )
        dbGoTop()
        DO WHILE !Eof()
            IF !Deleted()
                AAdd( aData, { ;
                    "HIS", ;
                    AllTrim( HIS_CAB->NUMERO ), ;
                    DToC( HIS_CAB->FECHA ), ;
                    AllTrim( HIS_CAB->ID_CLIENTE ), ;
                    AllTrim( HIS_CAB->TITULO ), ;
                    _VisorEstadoHis( HIS_CAB->ESTADO ) } )
            ENDIF
            dbSkip()
        ENDDO
    ENDIF

RETURN aData


STATIC FUNCTION _VisorEstadoHis( cEstado )

    cEstado := Upper( AllTrim( cEstado ) )

    DO CASE
    CASE cEstado == "C"
        RETURN "Calculado"
    CASE cEstado == "F"
        RETURN "Cerrado"
    OTHERWISE
        RETURN "Calculado"
    ENDCASE

RETURN "Calculado"


STATIC FUNCTION _VisorVerCalculo( oGrid )

    LOCAL aRow := oGrid:CurrentRow()
    LOCAL cOrigen, cNum

    IF aRow == NIL
        RETURN NIL
    ENDIF

    cOrigen := aRow[1]   // "TMP" o "HIS"
    cNum    := aRow[2]   // Número de proyecto

    IF cOrigen == "TMP"
        _VisorMostrarResultado( "TMP_RES", cNum, "RESULTADO - Proyecto " + cNum )
    ELSEIF cOrigen == "HIS"
        _VisorMostrarResultado( "HIS_RES", cNum, "HISTORICO - Proyecto " + cNum )
    ENDIF

RETURN NIL


STATIC FUNCTION _VisorValorarHistorico( oGrid )

    LOCAL aRow := oGrid:CurrentRow()

    IF aRow == NIL
        RETURN NIL
    ENDIF

    IF aRow[1] == "TMP"
        DrywallActivarProyecto( aRow[2] )
        Valorar()
    ELSE
        ValorarHistorico( aRow[2] )
    ENDIF

RETURN NIL


STATIC FUNCTION _VisorAccionProyecto( oGrid, cModo )

    LOCAL aRow := oGrid:CurrentRow()

    IF aRow == NIL
        RETURN .F.
    ENDIF

    IF aRow[1] == "TMP"
        IF DrywallActivarProyecto( aRow[2] )
            MsgInfo( "Proyecto " + aRow[2] + " marcado como actual.", "Proyectos en Curso" )
            RETURN .T.
        ENDIF
        RETURN .F.
    ENDIF

RETURN _VisorRecuperarHistorico( oGrid )


STATIC FUNCTION _VisorRecuperarHistorico( oGrid )

    LOCAL aRow := oGrid:CurrentRow()
    LOCAL cOrigen
    LOCAL cNum

    IF aRow == NIL
        RETURN .F.
    ENDIF

    cOrigen := aRow[1]
    cNum    := aRow[2]

    IF cOrigen != "HIS"
        MsgInfo( "Solo se pueden recuperar proyectos historicos.", "Recuperar" )
        RETURN .F.
    ENDIF

    IF aRow[6] == "Cerrado"
        MsgInfo( "El proyecto cerrado solo puede consultarse.", "Recuperar" )
        RETURN .F.
    ENDIF

RETURN DrywallRecuperarHistorico( cNum )


FUNCTION DrywallRecuperarHistorico( cHisNum )

    LOCAL nArea := Select()
    LOCAL nOrd  := IndexOrd()
    LOCAL nTramos := 0
    LOCAL lOk := .F.

    cHisNum := AllTrim( cHisNum )

    IF Empty( cHisNum )
        MsgStop( "No se ha indicado historico a recuperar.", "Recuperar" )
        _RecRestoreArea( nArea, nOrd )
        RETURN .F.
    ENDIF

    IF !_RecAbrirTablas()
        _RecRestoreArea( nArea, nOrd )
        RETURN .F.
    ENDIF

    IF !_RecSeekHistorico( cHisNum )
        MsgStop( "No se encontro el historico " + cHisNum + ".", "Recuperar" )
        _RecRestoreArea( nArea, nOrd )
        RETURN .F.
    ENDIF

    IF HIS_CAB->ESTADO == "F"
        MsgInfo( "El proyecto " + cHisNum + " esta cerrado. Solo puede consultarse.", "Recuperar" )
        _RecRestoreArea( nArea, nOrd )
        RETURN .F.
    ENDIF

    IF !MsgYesNo( "Se reabrira el historico " + cHisNum + " como proyecto actual." + Chr(13) + ;
                  "Los demas proyectos temporales se conservaran." + Chr(13) + ;
                  "El historico original no se modifica. Continuar?", "Recuperar" )
        _RecRestoreArea( nArea, nOrd )
        RETURN .F.
    ENDIF

    IF !_RecBorrarTemporal( cHisNum )
        _RecRestoreArea( nArea, nOrd )
        RETURN .F.
    ENDIF

    IF !_RecAbrirTablas()
        _RecRestoreArea( nArea, nOrd )
        RETURN .F.
    ENDIF

    IF _RecCopiarCabecera( cHisNum )
        nTramos := _RecCopiarTramos( cHisNum )
        lOk := ( nTramos > 0 )
    ENDIF

    IF lOk
        MsgInfo( "Historico " + cHisNum + " recuperado como proyecto actual." + Chr(13) + ;
                 "Revise los tramos y ejecute Calcular antes de guardar en firme.", "Recuperar" )
    ELSE
        MsgStop( "No se pudo recuperar el historico " + cHisNum + ".", "Recuperar" )
    ENDIF

    _RecRestoreArea( nArea, nOrd )

RETURN lOk


STATIC FUNCTION _RecAbrirTablas()

    IF !ABRIR_TABLA( "HIS_CAB", "HIS_CAB", "HIS_NUM" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "HIS_TRA", "HIS_TRA", "HTRA_NUM" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "TMP_CAB", "TMP_CAB", "" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "TMP_TRA", "TMP_TRA", "TTRA_ORD" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "TMP_MAT", "TMP_MAT", "MAT_NUM" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "TMP_RES", "TMP_RES", "RES_PK" )
        RETURN .F.
    ENDIF

RETURN .T.


STATIC FUNCTION _RecSeekHistorico( cHisNum )

    dbSelectArea( "HIS_CAB" )
    OrdSetFocus( "HIS_NUM" )

RETURN dbSeek( PadR( cHisNum, 6 ) )


STATIC FUNCTION _RecBorrarTemporal( cProyecto )

    LOCAL aTabs := { "TMP_CAB", "TMP_TRA", "TMP_MAT", "TMP_RES" }
    LOCAL i

    cProyecto := AllTrim( cProyecto )

    FOR i := 1 TO Len( aTabs )
        IF Select( aTabs[i] ) == 0
            IF !ABRIR_TABLA( aTabs[i], aTabs[i], "" )
                RETURN .F.
            ENDIF
        ENDIF

        dbSelectArea( aTabs[i] )
        IF !NetFLock()
            MsgStop( "No se pudo bloquear " + aTabs[i] + ".", "Recuperar" )
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


STATIC FUNCTION _RecCopiarCabecera( cHisNum )

    IF !_RecSeekHistorico( cHisNum )
        RETURN .F.
    ENDIF

    dbSelectArea( "TMP_CAB" )
    IF !NetFLock()
        MsgStop( "No se pudo bloquear TMP_CAB.", "Recuperar" )
        RETURN .F.
    ENDIF

    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. FieldPos( "L_ACTIVO" ) > 0
            REPLACE FIELD->L_ACTIVO WITH .F.
        ENDIF
        dbSkip()
    ENDDO

    DbAppend()
    IF NetErr()
        dbUnlock()
        RETURN .F.
    ENDIF

    REPLACE FIELD->NUMERO     WITH cHisNum
    REPLACE FIELD->FECHA      WITH HIS_CAB->FECHA
    REPLACE FIELD->TITULO     WITH HIS_CAB->TITULO
    REPLACE FIELD->ID_CLIENTE WITH HIS_CAB->ID_CLIENTE
    REPLACE FIELD->ESTADO     WITH "P"
    REPLACE FIELD->MARGEN     WITH HIS_CAB->MARGEN
    REPLACE FIELD->OBSERV     WITH HIS_CAB->OBSERV
    REPLACE FIELD->L_ACTIVO   WITH .T.
    REPLACE FIELD->L_SUCIO    WITH .T.
    IF FieldPos( "L_CALC_DIR" ) > 0
        REPLACE FIELD->L_CALC_DIR WITH .T.
    ENDIF
    IF FieldPos( "L_CAB_DIR" ) > 0
        REPLACE FIELD->L_CAB_DIR WITH .F.
    ENDIF
    dbCommit()
    dbUnlock()

RETURN .T.


STATIC FUNCTION _RecCopiarTramos( cHisNum )

    LOCAL nCopiados := 0

    dbSelectArea( "HIS_TRA" )
    OrdSetFocus( "HTRA_NUM" )
    dbSeek( PadR( cHisNum, 6 ) )

    dbSelectArea( "TMP_TRA" )
    IF !NetFLock()
        MsgStop( "No se pudo bloquear TMP_TRA.", "Recuperar" )
        RETURN 0
    ENDIF

    dbSelectArea( "HIS_TRA" )
    DO WHILE !Eof() .AND. AllTrim( FIELD->NUMERO ) == cHisNum
        IF !Deleted()
            dbSelectArea( "TMP_TRA" )
            DbAppend()
            IF NetErr()
                dbUnlock()
                RETURN nCopiados
            ENDIF

            REPLACE FIELD->NUMERO      WITH cHisNum
            REPLACE FIELD->ID_LINEA    WITH HIS_TRA->ID_LINEA
            REPLACE FIELD->TIPO_OBRA   WITH HIS_TRA->TIPO_OBRA
            IF FieldPos( "SISTEMA_ID" ) > 0 .AND. HIS_TRA->( FieldPos( "SISTEMA_ID" ) ) > 0
                REPLACE FIELD->SISTEMA_ID WITH HIS_TRA->SISTEMA_ID
            ENDIF
            REPLACE FIELD->CONCEPTO    WITH HIS_TRA->CONCEPTO
            REPLACE FIELD->LARGO       WITH HIS_TRA->LARGO
            REPLACE FIELD->ALTO        WITH HIS_TRA->ALTO
            REPLACE FIELD->MODUL       WITH HIS_TRA->MODUL
            REPLACE FIELD->ANCHO_PERF  WITH HIS_TRA->ANCHO_PERF
            REPLACE FIELD->SEP_PRIM    WITH HIS_TRA->SEP_PRIM
            REPLACE FIELD->CARAS       WITH HIS_TRA->CARAS
            REPLACE FIELD->PLAC_CARA   WITH HIS_TRA->PLAC_CARA
            REPLACE FIELD->ID_PER_VER  WITH HIS_TRA->ID_PER_VER
            REPLACE FIELD->ID_PER_HOR  WITH HIS_TRA->ID_PER_HOR
            REPLACE FIELD->ID_PER_PER  WITH HIS_TRA->ID_PER_PER
            REPLACE FIELD->ID_PLACA_A  WITH HIS_TRA->ID_PLACA_A
            REPLACE FIELD->ID_PLACA_B  WITH HIS_TRA->ID_PLACA_B
            REPLACE FIELD->L_AISLANT   WITH HIS_TRA->L_AISLANT
            REPLACE FIELD->ID_AISLANT  WITH HIS_TRA->ID_AISLANT
            REPLACE FIELD->ID_ANCLAJE  WITH HIS_TRA->ID_ANCLAJE
            REPLACE FIELD->L_BANDA     WITH HIS_TRA->L_BANDA
            REPLACE FIELD->METROS      WITH HIS_TRA->METROS
            nCopiados++
        ENDIF
        dbSelectArea( "HIS_TRA" )
        dbSkip()
    ENDDO

    dbSelectArea( "TMP_TRA" )
    dbCommit()
    dbUnlock()

RETURN nCopiados


STATIC FUNCTION _RecRestoreArea( nArea, nOrd )

    IF nArea > 0 .AND. !Empty( Alias( nArea ) )
        dbSelectArea( nArea )
        IF nOrd > 0
            dbSetOrder( nOrd )
        ENDIF
    ENDIF

RETURN NIL


STATIC FUNCTION _VisorMostrarResultado( cAlias, cNum, cTitulo )

    LOCAL nArea := Select()
    LOCAL aData := {}
    LOCAL oWin, oGrid
    LOCAL nTotalImp := 0
    LOCAL nTotalPeso := 0
    LOCAL lAbierta := .F.

    // Abrir tabla si no está en uso
    IF Select( cAlias ) == 0
        IF File( cAlias + ".DBF" )
            ABRIR_TABLA( cAlias, cAlias, "" )
            lAbierta := ( Select( cAlias ) > 0 )
        ENDIF
    ELSE
        lAbierta := .T.
    ENDIF

    IF !lAbierta
        MsgStop( "No hay datos de calculo disponibles.", "Aviso" )
        RETURN NIL
    ENDIF

    dbSelectArea( cAlias )
    BEGIN SEQUENCE WITH {|oErr| Break(oErr)}
        OrdSetFocus( 1 )
        dbSeek( PadR( cNum, 6 ) )
    RECOVER
        MsgInfo( "Error al acceder a los datos de '" + cNum + "'.", "Aviso" )
        IF nArea > 0; dbSelectArea( nArea ); ENDIF
        RETURN NIL
    END SEQUENCE

    IF !Found()
        MsgInfo( "El proyecto '" + cNum + "' no tiene calculo.", "Aviso" )
        IF nArea > 0; dbSelectArea( nArea ); ENDIF
        RETURN NIL
    ENDIF

    DO WHILE !Eof() .AND. AllTrim( FIELD->NUMERO ) == AllTrim( cNum )
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( FIELD->FAMILIA ), ;
                AllTrim( FIELD->CODIGO ), ;
                AllTrim( FIELD->DESCRIP ), ;
                AllTrim( FIELD->UNIDAD ), ;
                FIELD->CANT_TOT, ;
                FIELD->PRECIO, ;
                FIELD->IMP_TOT, ;
                FIELD->PESO_TOT } )
            nTotalImp  += FIELD->IMP_TOT
            nTotalPeso += FIELD->PESO_TOT
        ENDIF
        dbSkip()
    ENDDO

    oWin := TWindow():New( 4, 4, GfxMaxRow() - 4, GfxMaxCol() - 4, cTitulo )

    oWin:AddCtrl( TLabel():New( 1, 2, ;
        "Total: " + Transform( nTotalImp, "999,999,999.99" ) + ;
        "   Peso: " + Transform( nTotalPeso, "999,999,999.999" ), oWin ) )

    oGrid := TGrid():New( 3, 1, GfxMaxRow() - 8, GfxMaxCol() - 6, oWin )
    oGrid:aData    := aData
    oGrid:nSeekCol := 2
    oGrid:AddColumn( "FAMILIA",     10, "@!",          { |a| a[1] } )
    oGrid:AddColumn( "CODIGO",      15, "@!",          { |a| a[2] } )
    oGrid:AddColumn( "DESCRIPCION", 40, "@!",          { |a| a[3] } )
    oGrid:AddColumn( "UD",           4, "@!",          { |a| a[4] } )
    oGrid:AddColumn( "CANTIDAD",    12, "999,999.999", { |a| a[5] } )
    oGrid:AddColumn( "PRECIO",      10, "999,999.99",  { |a| a[6] } )
    oGrid:AddColumn( "IMPORTE",     14, "999,999.99",  { |a| a[7] } )
    oGrid:AddColumn( "PESO",        12, "999,999.999", { |a| a[8] } )

    oWin:AddCtrl( oGrid )
    oWin:AddCtrl( TButton():New( GfxMaxRow() - 6, 2, GfxMaxRow() - 5, 18, oWin, "IMPRIMIR", ;
        {|| _VisorImpResultado( aData, cTitulo, nTotalImp, nTotalPeso ) } ) )
    oWin:AddCtrl( TButton():New( GfxMaxRow() - 6, GfxMaxCol() - 20, GfxMaxRow() - 5, GfxMaxCol() - 4, oWin, "CERRAR", ;
        {|| oWin:Close() } ) )

    oWin:Run()

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN NIL


STATIC FUNCTION _VisorImpResultado( aData, cTitulo, nTotalImp, nTotalPeso )

    LOCAL cTexto := ""
    LOCAL i

    cTexto += PadC( cTitulo, 100 ) + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol() + hb_Eol()

    cTexto += PadR( "FAMILIA", 10 ) + " "
    cTexto += PadR( "CODIGO", 15 ) + " "
    cTexto += PadR( "DESCRIPCION", 40 ) + " "
    cTexto += PadR( "UD", 4 ) + " "
    cTexto += PadL( "CANTIDAD", 12 ) + " "
    cTexto += PadL( "PRECIO", 10 ) + " "
    cTexto += PadL( "IMPORTE", 14 ) + " "
    cTexto += PadL( "PESO", 12 ) + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()

    FOR i := 1 TO Len( aData )
        cTexto += PadR( aData[i, 1], 10 ) + " "
        cTexto += PadR( aData[i, 2], 15 ) + " "
        cTexto += PadR( aData[i, 3], 40 ) + " "
        cTexto += PadR( aData[i, 4],  4 ) + " "
        cTexto += PadL( Transform( aData[i, 5], "999,999.999" ), 12 ) + " "
        cTexto += PadL( Transform( aData[i, 6], "999,999.99" ),  10 ) + " "
        cTexto += PadL( Transform( aData[i, 7], "999,999.99" ),  14 ) + " "
        cTexto += PadL( Transform( aData[i, 8], "999,999.999" ), 12 ) + hb_Eol()
    NEXT

    cTexto += Replicate( "-", 100 ) + hb_Eol()
    cTexto += PadR( "TOTALES", 70 ) + " "
    cTexto += PadL( Transform( nTotalImp, "999,999,999.99" ), 14 ) + " "
    cTexto += PadL( Transform( nTotalPeso, "999,999,999.999" ), 12 ) + hb_Eol()

    _ImpTexto( cTexto, "RESULTADO_" + StrTran( cTitulo, " ", "_" ) + ".TXT" )

RETURN NIL


// ============================================================================
// FUNCIONES DE APOYO (adaptadas de Informes.prg)
// ============================================================================
FUNCTION _MostrarInformeTexto( cTitulo, cTexto, cFile )

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtPrn
    LOCAL oBtSal
    LOCAL aLineas := _InformeTextoLineas( cTexto )

    oWin   := TWindow():New( 1, 2, 37, 129, cTitulo )
    oGrid  := TGrid():New( 2, 2, 30, 124, oWin )
    oGrid:aData    := aLineas
    oGrid:nSeekCol := 1
    oGrid:AddColumn( "Vista previa TXT", 118, "@!", { |a| a[1] } )

    oWin:AddCtrl( TLabel():New( 32, 2, ;
        "Flechas/PgUp/PgDn: navegar   Letras: buscar texto   GUARDAR TXT: exportar", oWin ) )

    oBtPrn := TButton():New( 33, 40, 34, 59, oWin, "GUARDAR TXT", ;
        {|| _ImpTexto( cTexto, cFile ) } )
    oBtSal := TButton():New( 33, 63, 34, 82, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oBtPrn )
    oWin:AddCtrl( oBtSal )
    oWin:Run()

RETURN NIL


STATIC FUNCTION _ImpTexto( cTexto, cFile )

    LOCAL cPath := ".\INFORME\"

    IF !DirExiste( cPath )
        DirMake( cPath )
    ENDIF

    hb_MemoWrit( cPath + cFile, cTexto )
    MsgInfo( "Informe guardado en: " + cPath + cFile, "Impresion" )

RETURN NIL
