/*
 * ARCHIVO  : TARE_MOD.prg
 * PROPOSITO: Gestion del proyecto (cabecera + tramos)
 * MIGRADO A: GfxStack API
 */

#include "OOp.ch"

// ============================================================================
// FORMS - Formularios principales
// ============================================================================

FUNCTION ProyectoActual()

    IF !_AbrirTablas()
        RETURN NIL
    ENDIF

    IF Empty( DrywallProyectoActualNumero() )
        IF !_CrearProyectoActual()
            RETURN NIL
        ENDIF
    ENDIF

    _EditarCabeceraActual()

RETURN NIL


FUNCTION VerTareas( cTipo )

    LOCAL nArea  := Select()
    LOCAL nOrd   := IndexOrd()
    LOCAL oWin, oGrid, aData
    LOCAL cNum, dFec, cTit, cCli, cObs
    LOCAL oGCli, oGFec, oGTit, oGObs

    IF !_AbrirTablas()
        RETURN NIL
    ENDIF

    dbSelectArea( "TMP_CAB" )
    IF !_CabeceraActiva()
        MsgStop( "Debe crear un proyecto antes de agregar tramos.", "Proyecto requerido" )
        IF nArea > 0
            dbSelectArea( nArea )
            dbSetOrder( nOrd )
        ENDIF
        RETURN NIL
    ENDIF

    cNum := FIELD->NUMERO
    dFec := FIELD->FECHA
    cTit := FIELD->TITULO
    cCli := FIELD->ID_CLIENTE
    cObs := FIELD->OBSERV

    _AdoptaTramosSinProyecto( AllTrim( cNum ) )
    aData := _TareCargar()

    oWin := TWindow():New( 2, 2, 27, 105, "GESTION DEL PROYECTO - " + AllTrim( cNum ) )

    oWin:AddCtrl( TLabel():New( 1,  2, "TITULO...:", oWin ) )
    oGTit := TGet():New( 1, 14, cTit, "@S40!", oWin )

    oWin:AddCtrl( TLabel():New( 1, 60, "NUM:", oWin ) )
    oWin:AddCtrl( TLabel():New( 1, 65, AllTrim( cNum ), oWin ) )

    oWin:AddCtrl( TLabel():New( 3,  2, "CLIENTE..:", oWin ) )
    oGCli := TGet():New( 3, 14, cCli, "@S15!", oWin )
    oGCli:bValid := {| o | _ValidarCli( o ) }

    oWin:AddCtrl( TLabel():New( 3, 60, "FEC:", oWin ) )
    oGFec := TGet():New( 3, 65, dFec, "99/99/9999", oWin )

    oWin:AddCtrl( TLabel():New( 5,  2, "NOTAS....:", oWin ) )
    oGObs := TGet():New( 5, 14, cObs, "@S60!", oWin )

    oGrid := TGrid():New( 7, 1, 20, 100, oWin )
    oGrid:aData    := aData
    oGrid:nSeekCol := 2
    oGrid:AddColumn( "CODIGO",     10, "@!",     { |a| a[1] } )
    oGrid:AddColumn( "TIPO OBRA",  18, "@!",     { |a| a[2] } )
    oGrid:AddColumn( "DESCRIPCION",35, "@!",     { |a| a[3] } )
    oGrid:AddColumn( "LARGO",      8,  "999.99", { |a| a[4] } )
    oGrid:AddColumn( "ALTO",       8,  "999.99", { |a| a[5] } )
    oGrid:AddColumn( "MODUL",      6,  "99.99",  { |a| a[6] } )
    oGrid:bEnter := {|| _OnEdit( oGrid ), aData := _TareCargar(), oGrid:aData := aData, oGrid:Paint() }
    oGrid:bInsert := {|| _OnAppend( oGrid ), aData := _TareCargar(), oGrid:aData := aData, oGrid:Paint() }

    // Controles de cabecera primero (foco inicial)
    oWin:AddCtrl( oGTit )
    oWin:AddCtrl( oGCli )
    oWin:AddCtrl( TButton():New( 3, 33, 3, 47, oWin, "BUSCAR CLI", {|| _BuscarCli( oGCli ) } ) )
    oWin:AddCtrl( oGFec )
    oWin:AddCtrl( oGObs )
    // Luego el grid y botones de accion
    oWin:AddCtrl( oGrid )
    oWin:AddCtrl( TLabel():New( 22, 2, "[NUEVO] Agregar tramo   [ENTER] Editar", oWin ) )
    oWin:AddCtrl( TButton():New( 23,  2, 24, 18, oWin, "NUEVO (F5)", {|| _OnAppend( oGrid ), aData := _TareCargar(), oGrid:aData := aData, oGrid:Paint() } ) )
    oWin:AddCtrl( TButton():New( 23, 20, 24, 36, oWin, "CALCULAR", ;
        {|| _GuardarCabeceraTrabajo( cNum, oGTit, oGFec, oGCli, oGObs ), ;
            Procesa(), ;
            aData := _TareCargar(), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } ) )
    oWin:AddCtrl( TButton():New( 23, 38, 24, 54, oWin, "RESUMEN", {|| ResultadoResumen() } ) )
    oWin:AddCtrl( TButton():New( 23, 56, 24, 72, oWin, "DESPIECE", {|| ResultadoDetalle() } ) )
    oWin:AddCtrl( TButton():New( 25,  2, 26, 28, oWin, "VALORAR / CERRAR", ;
        {|| _GuardarCabeceraTrabajo( cNum, oGTit, oGFec, oGCli, oGObs ), ;
            Valorar() } ) )
    oWin:AddCtrl( TButton():New( 23, 85, 24, 101, oWin, "CERRAR", {|| oWin:Close() } ) )

    oWin:Run()

    _GuardarCabeceraTrabajo( cNum, oGTit, oGFec, oGCli, oGObs )

    IF nArea > 0
        dbSelectArea( nArea )
        dbSetOrder( nOrd )
    ENDIF
RETURN NIL


STATIC FUNCTION _TareCargar()

    LOCAL aData := {}
    LOCAL cSistema
    LOCAL cProyecto := DrywallProyectoActualNumero()

    dbSelectArea( "TMP_TRA" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            cSistema := Upper( AllTrim( FIELD->TIPO_OBRA ) )
            IF !TipoObraDrywallValido( cSistema )
                cSistema := "**SIN TIPO OBRA**"
            ENDIF

            IF FieldPos( "ANCHO_PERF" ) > 0 .AND. FIELD->ANCHO_PERF > 0
                cSistema += " " + AllTrim( Str( FIELD->ANCHO_PERF ) ) + "mm"
            ENDIF
            AAdd( aData, { ;
                FIELD->ID_LINEA, ;
                cSistema, ;
                AllTrim( FIELD->CONCEPTO ), ;
                FIELD->LARGO, ;
                FIELD->ALTO, ;
                FIELD->MODUL } )
        ENDIF
        dbSkip()
    ENDDO

RETURN aData


// ============================================================================
// DBF - Acceso a base de datos
// ============================================================================

STATIC FUNCTION _AdoptaTramosSinProyecto( cProyecto )

    LOCAL nArea := Select()
    LOCAL nAdoptados := 0
    LOCAL nLinea

    cProyecto := AllTrim( cProyecto )
    IF Empty( cProyecto )
        RETURN 0
    ENDIF

    IF Select( "TMP_TRA" ) == 0
        RETURN 0
    ENDIF

    nLinea := _TareNextLinea( cProyecto )

    dbSelectArea( "TMP_TRA" )
    IF !NetFLock()
        IF nArea > 0
            dbSelectArea( nArea )
        ENDIF
        RETURN 0
    ENDIF

    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. ;
           Empty( AllTrim( FIELD->NUMERO ) ) .AND. ;
           TipoObraDrywallValido( FIELD->TIPO_OBRA )
            REPLACE FIELD->NUMERO   WITH cProyecto
            REPLACE FIELD->ID_LINEA WITH nLinea
            nLinea++
            nAdoptados++
        ENDIF
        dbSkip()
    ENDDO

    dbCommit()
    dbUnlock()

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

    IF nAdoptados > 0
        MsgInfo( "Se recuperaron " + AllTrim( Str( nAdoptados ) ) + ;
                 " tramos sin proyecto.", "Definir Tramos" )
    ENDIF

RETURN nAdoptados


STATIC FUNCTION _TareNextLinea( cProyecto )

    LOCAL nArea := Select()
    LOCAL nMax := 0

    dbSelectArea( "TMP_TRA" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == AllTrim( cProyecto )
            IF FIELD->ID_LINEA > nMax
                nMax := FIELD->ID_LINEA
            ENDIF
        ENDIF
        dbSkip()
    ENDDO

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN nMax + 1

STATIC FUNCTION _OnAppend( oGrid )

    LOCAL cTipo

    dbSelectArea( "TMP_CAB" )
    IF !_CabeceraActiva()
        MsgStop( "Debe crear un proyecto antes de agregar tramos.", "Proyecto requerido" )
        RETURN NIL
    ENDIF

    cTipo := _PickTipoObra()
    IF Empty( cTipo )
        RETURN NIL
    ENDIF

    DO CASE
    CASE cTipo == "TABIQUE"
        Add_Tabique( "Nuevo tabique" )
    CASE cTipo == "TECHO"
        Add_Techo( "Nuevo techo" )
    CASE "TRAS" $ cTipo
        Add_Trasdosado( cTipo, "Nuevo trasdosado" )
    CASE cTipo == "GENERICO"
        Add_Generico( "Material generico" )
    ENDCASE

RETURN NIL


STATIC FUNCTION _OnEdit( oGrid )


    LOCAL aRow := oGrid:CurrentRow()
    LOCAL nId

    IF aRow == NIL
        RETURN NIL
    ENDIF

    nId := aRow[1]
    EditTramo( nId )

RETURN NIL


// ============================================================================
// UI HELPERS - Dialogos de seleccion
// ============================================================================

STATIC FUNCTION _PickTipoObra()

    LOCAL aData := { }
    LOCAL aCombo := {}
    LOCAL i

    AAdd( aData, {"TABIQUE","Tabique pladur"} )
    AAdd( aData,  {"TECHO","Techo pladur"} )
    AAdd( aData,  {"TRASDOSADO_AUT","Trasdosado Autoportante"} )
    AAdd( aData,  {"TRASDOSADO_SEMI","Trasdosado  Semi Directo"} )
    AAdd( aData,  {"TRASDOSADO_DIR","Trasdosado Directo"} )
    AAdd( aData,  {"GENERICO","Material generico (m2)"} )
    

    FOR i := 1 TO Len( aData )
        AAdd( aCombo, { aData[i, 1], aData[i, 2] } )
    NEXT

RETURN PopupSelect( "SELECCIONAR TIPO", aCombo, { { "Tipo", 30, "@!", 2 } }, 1 )


STATIC FUNCTION _AbrirTablas()

    LOCAL lOk := .T.
    LOCAL aTabs := { "TMP_TRA", "TMP_MAT", "TMP_RES", "TMP_CAB", "TABLAS_AUX" }
    LOCAL i

    FOR i := 1 TO Len( aTabs )
        IF Select( aTabs[i] ) == 0
            IF File( aTabs[i] + ".DBF" )
                ABRIR_TABLA( aTabs[i], aTabs[i], "" )
            ELSE
                MsgStop( "Falta archivo " + aTabs[i] + ".DBF" )
                lOk := .F.
            ENDIF
        ENDIF
    NEXT

RETURN lOk


STATIC FUNCTION _CabeceraActiva()

    LOCAL cProyecto := DrywallProyectoActualNumero()

    IF Empty( cProyecto )
        RETURN .F.
    ENDIF

    dbSelectArea( "TMP_CAB" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
            RETURN .T.
        ENDIF
        dbSkip()
    ENDDO

RETURN .F.


STATIC FUNCTION _SeleccionaProyectoTrabajo()

    LOCAL aData := _ProyectosTemporalesData()
    LOCAL cSel

    IF Len( aData ) == 0
        RETURN _CrearProyectoActual()
    ENDIF

    cSel := PopupSelect( "PROYECTOS EN CURSO", aData, ;
        { { "NUMERO",   8, "@!", 1 }, ;
          { "FECHA",   12, "@!", 2 }, ;
          { "TITULO",  38, "@!", 3 }, ;
          { "CLIENTE", 15, "@!", 4 }, ;
          { "ESTADO",  12, "@!", 5 }, ;
          { "ACT",      4, "@!", 6 } }, 3, "NUEVO" )

    IF cSel == "__POPUP_NEW__"
        RETURN _CrearProyectoActual()
    ENDIF

    IF Empty( cSel )
        RETURN .F.
    ENDIF

RETURN DrywallActivarProyecto( cSel )


STATIC FUNCTION _ProyectosTemporalesData()

    LOCAL aData := {}
    LOCAL cEstado
    LOCAL cActivo

    dbSelectArea( "TMP_CAB" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted()
            cEstado := "Pendiente"
            IF FieldPos( "L_CALC_DIR" ) > 0
                IF !FIELD->L_CALC_DIR
                    cEstado := "Calculado"
                ENDIF
            ELSEIF FieldPos( "L_SUCIO" ) > 0 .AND. !FIELD->L_SUCIO
                cEstado := "Calculado"
            ENDIF

            cActivo := ""
            IF FieldPos( "L_ACTIVO" ) > 0 .AND. FIELD->L_ACTIVO
                cActivo := "SI"
            ENDIF

            AAdd( aData, { ;
                AllTrim( FIELD->NUMERO ), ;
                DToC( FIELD->FECHA ), ;
                AllTrim( FIELD->TITULO ), ;
                AllTrim( FIELD->ID_CLIENTE ), ;
                cEstado, ;
                cActivo } )
        ENDIF
        dbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _CrearProyectoActual()

    LOCAL cNum := _NextProyectoNumero()

    dbSelectArea( "TMP_CAB" )
    IF !NetFLock()
        MsgStop( "No se pudo bloquear TMP_CAB para crear el proyecto.", "Proyecto Actual" )
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
        MsgStop( "No se pudo crear la cabecera del proyecto.", "Proyecto Actual" )
        RETURN .F.
    ENDIF

    REPLACE FIELD->NUMERO     WITH cNum
    REPLACE FIELD->FECHA      WITH Date()
    REPLACE FIELD->TITULO     WITH Space(60)
    REPLACE FIELD->ID_CLIENTE WITH Space(15)
    REPLACE FIELD->ESTADO     WITH "P"
    REPLACE FIELD->MARGEN     WITH 0
    REPLACE FIELD->OBSERV     WITH Space(200)
    REPLACE FIELD->L_ACTIVO   WITH .T.
    REPLACE FIELD->L_SUCIO    WITH .T.
    IF FieldPos( "L_CALC_DIR" ) > 0
        REPLACE FIELD->L_CALC_DIR WITH .T.
    ENDIF
    IF FieldPos( "L_CAB_DIR" ) > 0
        REPLACE FIELD->L_CAB_DIR WITH .T.
    ENDIF
    dbCommit()
    dbUnlock()

RETURN .T.


STATIC FUNCTION _EditarCabeceraActual()

    LOCAL oWin
    LOCAL cNum
    LOCAL dFec
    LOCAL cTit
    LOCAL cCli
    LOCAL cObs
    LOCAL oGCli
    LOCAL oGFec
    LOCAL oGTit
    LOCAL oGObs
    LOCAL lAbrirTramos := .F.
    LOCAL lCambiar := .F.

    dbSelectArea( "TMP_CAB" )
    IF !_CabeceraActiva()
        RETURN NIL
    ENDIF

    cNum := FIELD->NUMERO
    dFec := FIELD->FECHA
    cTit := FIELD->TITULO
    cCli := FIELD->ID_CLIENTE
    cObs := FIELD->OBSERV

    oWin := TWindow():New( 5, 8, 15, 90, "PROYECTO ACTUAL - " + AllTrim( cNum ) )

    oWin:AddCtrl( TLabel():New( 1,  2, "TITULO...:", oWin ) )
    oGTit := TGet():New( 1, 14, cTit, "@S60!", oWin )

    oWin:AddCtrl( TLabel():New( 3,  2, "CLIENTE..:", oWin ) )
    oGCli := TGet():New( 3, 14, cCli, "@S15!", oWin )
    oGCli:bValid := {| o | _ValidarCli( o ) }

    oWin:AddCtrl( TLabel():New( 3, 40, "FEC:", oWin ) )
    oGFec := TGet():New( 3, 46, dFec, "99/99/9999", oWin )

    oWin:AddCtrl( TLabel():New( 5,  2, "NOTAS....:", oWin ) )
    oGObs := TGet():New( 5, 14, cObs, "@S60!", oWin )

    oWin:AddCtrl( oGTit )
    oWin:AddCtrl( oGCli )
    oWin:AddCtrl( TButton():New( 3, 31, 3, 38, oWin, "BUSCAR", {|| _BuscarCli( oGCli ) } ) )
    oWin:AddCtrl( oGFec )
    oWin:AddCtrl( oGObs )
    oWin:AddCtrl( TButton():New( 8,  2, 9, 18, oWin, "GUARDAR", {|| oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 8, 20, 9, 36, oWin, "TRAMOS", {|| lAbrirTramos := .T., oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 8, 38, 9, 56, oWin, "CAMBIAR", {|| lCambiar := .T., oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 8, 62, 9, 78, oWin, "CERRAR", {|| oWin:Close() } ) )

    oWin:Run()

    _GuardarCabeceraTrabajo( cNum, oGTit, oGFec, oGCli, oGObs )

    IF lCambiar
        IF _SeleccionaProyectoTrabajo()
            _EditarCabeceraActual()
        ENDIF
    ELSEIF lAbrirTramos
        VerTareas()
    ENDIF

RETURN NIL


STATIC FUNCTION _GuardarCabeceraTrabajo( cProyecto, oGTit, oGFec, oGCli, oGObs )

    LOCAL nArea := Select()
    LOCAL cTitNew := oGTit:GetValue()
    LOCAL dFecNew := oGFec:GetValue()
    LOCAL cCliNew := oGCli:GetValue()
    LOCAL cObsNew := oGObs:GetValue()
    LOCAL lChanged := .F.

    cProyecto := AllTrim( cProyecto )
    IF Empty( cProyecto )
        RETURN .F.
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
        IF nArea > 0
            dbSelectArea( nArea )
        ENDIF
        RETURN .F.
    ENDIF

    lChanged := ;
        AllTrim( FIELD->TITULO ) != AllTrim( cTitNew ) .OR. ;
        FIELD->FECHA != dFecNew .OR. ;
        AllTrim( FIELD->ID_CLIENTE ) != AllTrim( cCliNew ) .OR. ;
        AllTrim( FIELD->OBSERV ) != AllTrim( cObsNew )

    IF lChanged .AND. NetRLock()
        REPLACE FIELD->TITULO     WITH cTitNew
        REPLACE FIELD->FECHA      WITH dFecNew
        REPLACE FIELD->ID_CLIENTE WITH cCliNew
        REPLACE FIELD->OBSERV     WITH cObsNew
        dbCommit()
        dbUnlock()
        DrywallMarkCabDirty( cProyecto )
    ENDIF

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN .T.


STATIC FUNCTION _NextProyectoNumero()

    LOCAL nMax := 0

    nMax := _MaxProyectoAlias( "TMP_CAB", nMax )

    IF Select( "HIS_CAB" ) == 0 .AND. File( "HIS_CAB.DBF" )
        ABRIR_TABLA( "HIS_CAB", "HIS_CAB", "" )
    ENDIF

    IF Select( "HIS_CAB" ) > 0
        nMax := _MaxProyectoAlias( "HIS_CAB", nMax )
    ENDIF

RETURN PadL( AllTrim( Str( nMax + 1 ) ), 6, "0" )


STATIC FUNCTION _MaxProyectoAlias( cAlias, nMax )

    LOCAL nArea := Select()
    LOCAL nVal

    dbSelectArea( cAlias )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted()
            nVal := Val( AllTrim( FIELD->NUMERO ) )
            IF nVal > nMax
                nMax := nVal
            ENDIF
        ENDIF
        dbSkip()
    ENDDO

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN nMax


// ============================================================================
// VALIDACION - Validaciones
// ============================================================================

STATIC FUNCTION _ValidarCli( oGet )

    LOCAL nArea := Select()
    LOCAL nOrd  := IndexOrd()
    LOCAL cCod  := AllTrim( oGet:uVar )
    LOCAL lOk   := .T.

    IF Empty( cCod )
        RETURN .T.
    ENDIF

    IF Select( "CLIENTES" ) == 0
        IF File( "CLIENTES.DBF" )
            ABRIR_TABLA( "CLIENTES", "CLIENTES", "" )
        ELSE
            RETURN .T.
        ENDIF
    ENDIF

    dbSelectArea( "CLIENTES" )
    OrdSetFocus( "CLI_ID" )

    IF dbSeek( PadR( cCod, 10 ) )
        oGet:uVar    := PadR( AllTrim( FIELD->ID ), 15 )
        oGet:cBuffer := PadR( AllTrim( FIELD->ID ), oGet:nBufLen )
    ELSE
        MsgStop( "Cliente no encontrado." )
        lOk := .F.
    ENDIF

    IF nArea > 0
        dbSelectArea( nArea )
        dbSetOrder( nOrd )
    ENDIF

RETURN lOk


STATIC FUNCTION _BuscarCli( oGCli )

    LOCAL aData := {}, aCombo := {}, i, cSel
    LOCAL nArea := Select()

    IF Select( "CLIENTES" ) == 0
        IF File( "CLIENTES.DBF" )
            ABRIR_TABLA( "CLIENTES", "CLIENTES", "" )
        ELSE
            RETURN NIL
        ENDIF
    ENDIF

    dbSelectArea( "CLIENTES" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. !FIELD->BAJA
            AAdd( aData, { ;
                AllTrim( FIELD->ID ), ;
                AllTrim( FIELD->NOMBRE + " " + FIELD->APELLIDO ), ;
                AllTrim( FIELD->NIF ) } )
        ENDIF
        DbSkip()
    ENDDO

    IF Empty( aData )
        MsgInfo( "No hay clientes registrados.", "Buscar" )
        Select( nArea )
        RETURN NIL
    ENDIF

    FOR i := 1 TO Len( aData )
        AAdd( aCombo, { aData[i, 1], aData[i, 2] + " (" + aData[i, 3] + ")" } )
    NEXT

    cSel := PopupSelect( "SELECCIONAR CLIENTE", aCombo, ;
                          { { "Cliente", 72, "@!", 2 } }, 1 )

    IF !Empty( cSel )
        oGCli:SetValue( PadR( cSel, 15 ) )
    ENDIF

    Select( nArea )

RETURN NIL
