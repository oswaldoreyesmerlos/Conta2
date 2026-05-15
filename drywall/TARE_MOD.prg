/*
 * ARCHIVO  : TARE_MOD.prg
 * PROPOSITO: Gestion del proyecto (cabecera + tramos)
 * MIGRADO A: GfxStack API
 */

#include "OOp.ch"

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
    IF LastRec() == 0
        dbAppend()
        REPLACE FIELD->NUMERO     WITH "000001"
        REPLACE FIELD->FECHA      WITH Date()
        REPLACE FIELD->TITULO     WITH "NUEVO PRESUPUESTO"
        REPLACE FIELD->ID_CLIENTE WITH Space(15)
        REPLACE FIELD->ESTADO     WITH "P"
        REPLACE FIELD->MARGEN     WITH 0
        REPLACE FIELD->L_SUCIO    WITH .T.
    ENDIF
    dbGoTop()

    cNum := FIELD->NUMERO
    dFec := FIELD->FECHA
    cTit := FIELD->TITULO
    cCli := FIELD->ID_CLIENTE
    cObs := FIELD->OBSERV

    aData := _TareCargar()

    oWin := TWindow():New( 2, 2, 24, 98, "GESTION DEL PROYECTO - " + AllTrim( cNum ) )

    oWin:AddCtrl( TLabel():New( 1,  2, "TITULO...:", oWin ) )
    oGTit := TGet():New( 1, 14, cTit, "@S40!", oWin )

    oWin:AddCtrl( TLabel():New( 1, 60, "NUM:", oWin ) )
    oWin:AddCtrl( TLabel():New( 1, 65, AllTrim( cNum ), oWin ) )

    oWin:AddCtrl( TLabel():New( 2,  2, "CLIENTE..:", oWin ) )
    oGCli := TGet():New( 2, 14, cCli, "@S15!", oWin )
    oGCli:bValid := {| o | _ValidarCli( @cCli ) }

    oWin:AddCtrl( TLabel():New( 2, 60, "FEC:", oWin ) )
    oGFec := TGet():New( 2, 65, dFec, "99/99/9999", oWin )

    oWin:AddCtrl( TLabel():New( 3,  2, "NOTAS....:", oWin ) )
    oGObs := TGet():New( 3, 14, cObs, "@S60!", oWin )

    oGrid := TGrid():New( 5, 1, 17, 93, oWin )
    oGrid:aData    := aData
    oGrid:nSeekCol := 2
    oGrid:AddColumn( "CODIGO",     10, "@!",     { |a| a[1] } )
    oGrid:AddColumn( "SISTEMA",    12, "@!",     { |a| a[2] } )
    oGrid:AddColumn( "DESCRIPCION",35, "@!",     { |a| a[3] } )
    oGrid:AddColumn( "LARGO",      8,  "999.99", { |a| a[4] } )
    oGrid:AddColumn( "ALTO",       8,  "999.99", { |a| a[5] } )
    oGrid:AddColumn( "MODUL",      6,  "99.99",  { |a| a[6] } )
    oGrid:bEnter := {|| _OnEdit( oGrid ), aData := _TareCargar(), oGrid:aData := aData, oGrid:Paint() }

    // Controles de cabecera primero (foco inicial)
    oWin:AddCtrl( oGTit )
    oWin:AddCtrl( TButton():New( 1, 56, 1, 70, oWin, "BUSCAR CLI", {|| _BuscarCli( oGCli ) } ) )
    oWin:AddCtrl( oGCli )
    oWin:AddCtrl( oGFec )
    oWin:AddCtrl( oGObs )
    // Luego el grid y botones de accion
    oWin:AddCtrl( oGrid )
    oWin:AddCtrl( TLabel():New( 19, 2, "[F5] Nuevo [ENTER] Editar [DEL] Borrar", oWin ) )
    oWin:AddCtrl( TButton():New( 20,  2, 21, 18, oWin, "NUEVO (F5)", {|| _OnAppend( oGrid ), aData := _TareCargar(), oGrid:aData := aData, oGrid:Paint() } ) )
    oWin:AddCtrl( TButton():New( 20, 20, 21, 38, oWin, "CALCULAR", {|| Procesa(), aData := _TareCargar(), oGrid:aData := aData, oGrid:Paint() } ) )
    oWin:AddCtrl( TButton():New( 20, 78, 21, 94, oWin, "CERRAR", {|| oWin:Close() } ) )

    oWin:Run()

    IF nArea > 0; dbSelectArea( nArea ); dbSetOrder( nOrd ); ENDIF
RETURN NIL


STATIC FUNCTION _TareCargar()

    LOCAL aData := {}

    dbSelectArea( "TMP_TRA" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                FIELD->ID_LINEA, ;
                AllTrim( FIELD->TIPO_OBRA ), ;
                AllTrim( FIELD->CONCEPTO ), ;
                FIELD->LARGO, ;
                FIELD->ALTO, ;
                FIELD->MODUL } )
        ENDIF
        dbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _OnAppend( oGrid )

    LOCAL nId := 0
    LOCAL cTipo

    cTipo := _PickTipoObra()
    IF Empty( cTipo )
        RETURN NIL
    ENDIF

    dbSelectArea( "TMP_TRA" )
    dbGoBottom()
    nId := FIELD->ID_LINEA + 1

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


STATIC FUNCTION _OnDelete( oGrid )

    LOCAL aRow := oGrid:CurrentRow()
    LOCAL nId

    IF aRow == NIL
        RETURN NIL
    ENDIF

    IF !MsgYesNo( "Borrar tramo " + AllTrim( Str( aRow[1] ) ) + "?", "Confirmar" )
        RETURN NIL
    ENDIF

    nId := aRow[1]
    dbSelectArea( "TMP_TRA" )
    dbGoTop()
    DO WHILE !Eof()
        IF FIELD->ID_LINEA == nId .AND. NetRLock()
            dbDelete()
            dbCommit()
            dbUnlock()
            EXIT
        ENDIF
        dbSkip()
    ENDDO

RETURN NIL


STATIC FUNCTION _PickTipoObra()

    LOCAL aData := { {"TABIQUE","Tabique pladur"}, {"TECHO","Techo pladur"}, {"TRASDOSADO","Trasdosado"}, {"TRASDOSADO_DIR","Trasdosado Directo"}, {"TRASDOSADO_AUT","Trasdosado Autoportante"}, {"GENERICO","Material generico (m2)"} }
    LOCAL aCombo := {}
    LOCAL i

    FOR i := 1 TO Len( aData )
        AAdd( aCombo, { aData[i, 1], aData[i, 2] } )
    NEXT

RETURN PopupSelect( "SELECCIONAR TIPO", aCombo, { { "Tipo", 20, "@!", 2 } }, 1 )


STATIC FUNCTION _AbrirTablas()

    LOCAL lOk := .T.
    LOCAL aTabs := { "TMP_TRA", "TMP_MAT", "TMP_RES", "TMP_CAB", "TABLAS_AUX" }
    LOCAL i

    FOR i := 1 TO Len( aTabs )
        IF Select( aTabs[i] ) == 0
            IF File( aTabs[i] + ".DBF" )
                USE ( aTabs[i] ) NEW SHARED VIA "DBFCDX"
            ELSE
                MsgStop( "Falta archivo " + aTabs[i] + ".DBF" )
                lOk := .F.
            ENDIF
        ENDIF
    NEXT

RETURN lOk


STATIC FUNCTION _ValidarCli( cCli )

    LOCAL cCod := AllTrim( cCli )

    IF Empty( cCod )
        RETURN .T.
    ENDIF

    IF Select( "CLIENTES" ) == 0
        IF File( "CLIENTES.DBF" )
            USE CLIENTES NEW SHARED VIA "DBFCDX"
        ELSE
            RETURN .T.
        ENDIF
    ENDIF

    dbSelectArea( "CLIENTES" )
    IF dbSeek( PadR( cCod, 10 ) )
        cCli := PadR( AllTrim( FIELD->NOMBRE ), 15 )
        RETURN .T.
    ENDIF

    MsgStop( "Cliente no encontrado." )
RETURN .F.


STATIC FUNCTION _BuscarCli( oGCli )

    LOCAL aData := {}, aCombo := {}, i, cSel
    LOCAL nArea := Select()

    IF Select( "CLIENTES" ) == 0
        IF File( "CLIENTES.DBF" )
            USE CLIENTES NEW SHARED VIA "DBFCDX"
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
