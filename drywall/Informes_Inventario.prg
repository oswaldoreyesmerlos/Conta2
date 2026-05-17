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
FUNCTION VisorProyectos()

    LOCAL nArea := Select()
    LOCAL oWin, oGrid, aData

    aData := _VisorCargarDatos()

    IF Empty( aData )
        MsgInfo( "No hay proyectos registrados.", "Visor" )
        RETURN NIL
    ENDIF

    oWin := TWindow():New( 2, 2, GfxMaxRow() - 2, GfxMaxCol() - 2, "VISOR DE PROYECTOS" )

    oWin:AddCtrl( TLabel():New( 1, 2, ;
        "[ENTER] Ver cálculo   [Flechas] Navegar   [ESC] Salir", oWin ) )

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
        {|| aData := _VisorCargarDatos(), oGrid:aData := aData, oGrid:Paint() } ) )
    oWin:AddCtrl( TButton():New( GfxMaxRow() - 4, GfxMaxCol() - 20, GfxMaxRow() - 3, GfxMaxCol() - 4, oWin, "CERRAR", ;
        {|| oWin:Close() } ) )

    oWin:Run()

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN NIL


STATIC FUNCTION _VisorCargarDatos()

    LOCAL aData := {}
    LOCAL cEstado
    LOCAL lResAbierta

    // Asegurar TMP_CAB abierta
    IF Select( "TMP_CAB" ) == 0
        IF !ABRIR_TABLA( "TMP_CAB", "TMP_CAB", "" )
            // No se pudo abrir, omitimos proyectos activos
        ENDIF
    ENDIF

    // Asegurar TMP_RES abierta (para consultar estado)
    lResAbierta := .F.
    IF Select( "TMP_RES" ) == 0
        IF ABRIR_TABLA( "TMP_RES", "TMP_RES", "RES_PK" )
            lResAbierta := .T.
        ENDIF
    ELSE
        dbSelectArea( "TMP_RES" )
        BEGIN SEQUENCE WITH {|oErr| Break(oErr)}
            OrdSetFocus( "RES_PK" )
        RECOVER
        END SEQUENCE
        lResAbierta := .T.
    ENDIF

    // Proyectos activos (TMP_CAB)
    IF Select( "TMP_CAB" ) > 0
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
    IF Select( "HIS_CAB" ) == 0
        IF !ABRIR_TABLA( "HIS_CAB", "HIS_CAB", "" )
            // No se pudo abrir, omitimos archivados
        ENDIF
    ENDIF

    // Proyectos archivados (HIS_CAB)
    IF Select( "HIS_CAB" ) > 0
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
                    "Archivado" } )
            ENDIF
            dbSkip()
        ENDDO
    ENDIF

RETURN aData


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
            BEGIN SEQUENCE WITH {|oErr| Break(oErr)}
                USE ( cAlias ) NEW SHARED VIA "DBFCDX" ALIAS ( cAlias )
                lAbierta := ( Select( cAlias ) > 0 )
            RECOVER
            END SEQUENCE
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


STATIC FUNCTION _InformeTextoLineas( cTexto )

    LOCAL aLineas := {}
    LOCAL nStart  := 1
    LOCAL nPos
    LOCAL cLine

    DEFAULT cTexto TO ""

    cTexto := StrTran( cTexto, Chr( 13 ) + Chr( 10 ), Chr( 10 ) )
    cTexto := StrTran( cTexto, Chr( 13 ), Chr( 10 ) )

    DO WHILE nStart <= Len( cTexto ) + 1
        nPos := At( Chr( 10 ), SubStr( cTexto, nStart ) )
        IF nPos == 0
            cLine := SubStr( cTexto, nStart )
            AAdd( aLineas, { cLine } )
            EXIT
        ENDIF
        cLine := SubStr( cTexto, nStart, nPos - 1 )
        AAdd( aLineas, { cLine } )
        nStart += nPos
    ENDDO

    IF Empty( aLineas )
        AAdd( aLineas, { "" } )
    ENDIF

RETURN aLineas


STATIC FUNCTION _ImpTexto( cTexto, cFile )

    LOCAL cPath := ".\INFORME\"

    IF !DirExiste( cPath )
        DirMake( cPath )
    ENDIF

    hb_MemoWrit( cPath + cFile, cTexto )
    MsgInfo( "Informe guardado en: " + cPath + cFile, "Impresion" )

RETURN NIL
