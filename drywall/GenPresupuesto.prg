#include "OOp.ch"
#include "inkey.ch"

#define IVA_DEF 21.00

FUNCTION DrywallGenPresupuesto( cNumProyecto )

    LOCAL nArea := Select()
    LOCAL aLineas := {}
    LOCAL nSubtotal := 0, nIva := 0, nTotal := 0, nRetenc := 0
    LOCAL nPorcIva := IVA_DEF, nPorcRet := 0
    LOCAL dFecha, dValidez
    LOCAL cCliId := "", cCliNom := ""
    LOCAL cObs := ""
    LOCAL oWin, oGCli, oGFec, oGVal, oGIva, oGRet, oGObs
    LOCAL oGrid, oLblTot, oBtBus, oBtOk, oBtCan
    LOCAL lOk := .F.
    LOCAL lRet := .F.
    LOCAL i, nFila, nCols

    DEFAULT cNumProyecto TO ""

    IF Empty( cNumProyecto )
        IF Select( "TMP_CAB" ) > 0
            dbSelectArea( "TMP_CAB" )
            IF LastRec() > 0 .AND. !Eof()
                cNumProyecto := AllTrim( TMP_CAB->NUMERO )
                cCliId := AllTrim( TMP_CAB->ID_CLIENTE )
                cObs   := AllTrim( TMP_CAB->OBSERV )
            ENDIF
        ENDIF
    ENDIF

    IF Empty( cNumProyecto )
        MsgStop( "No hay proyecto activo.", "Generar Presupuesto" )
        IF nArea > 0; dbSelectArea( nArea ); ENDIF
        RETURN .F.
    ENDIF

    IF _PreExisteOrigen( cNumProyecto )
        MsgStop( "Ya existe un presupuesto generado para el proyecto " + cNumProyecto + ".", ;
                 "Generar Presupuesto" )
        IF nArea > 0; dbSelectArea( nArea ); ENDIF
        RETURN .F.
    ENDIF

    IF Select( "TMP_RES" ) == 0
        IF !File( "TMP_RES.DBF" )
            MsgStop( "No hay datos de calculo para el proyecto.", "Generar Presupuesto" )
            IF nArea > 0; dbSelectArea( nArea ); ENDIF
            RETURN .F.
        ENDIF
        USE TMP_RES NEW SHARED VIA "DBFCDX" ALIAS "TMP_RES"
    ENDIF

    dbSelectArea( "TMP_RES" )
    BEGIN SEQUENCE WITH {|oErr| Break( oErr )}
        OrdSetFocus( "RES_PK" )
        dbSeek( PadR( cNumProyecto, 6 ) )
    RECOVER
        MsgStop( "No se pudo activar el indice RES_PK de TMP_RES.", "Generar Presupuesto" )
        IF nArea > 0; dbSelectArea( nArea ); ENDIF
        RETURN .F.
    END SEQUENCE

    IF !Found()
        MsgStop( "El proyecto '" + cNumProyecto + "' no tiene calculo valorado.", "Generar Presupuesto" )
        IF nArea > 0; dbSelectArea( nArea ); ENDIF
        RETURN .F.
    ENDIF

    DO WHILE !Eof() .AND. AllTrim( FIELD->NUMERO ) == cNumProyecto
        IF !Deleted()
            AAdd( aLineas, { ;
                AllTrim( FIELD->DESCRIP ), ;
                FIELD->CANT_TOT, ;
                FIELD->PRECIO, ;
                0, ;
                nPorcIva, ;
                FIELD->IMP_TOT } )
            nSubtotal += FIELD->IMP_TOT
        ENDIF
        dbSkip()
    ENDDO

    nIva    := Round( nSubtotal * nPorcIva / 100, 2 )
    nRetenc := Round( nSubtotal * nPorcRet / 100, 2 )
    nTotal  := nSubtotal + nIva - nRetenc

    IF !Empty( cCliId )
        IF ABRIR_TABLA( "CLIENTES", "CLI_BUS", "CLI_ID" )
            dbSelectArea( "CLI_BUS" )
            IF dbSeek( PadR( cCliId, 10 ) )
                cCliNom := AllTrim( CLI_BUS->NOMBRE ) + " " + AllTrim( CLI_BUS->APELLIDO )
            ELSE
                cCliNom := cCliId
                cCliId  := ""
            ENDIF
            CLI_BUS->( DbCloseArea() )
        ENDIF
    ENDIF

    dFecha   := Date()
    dValidez := dFecha + 30
    nFila    := 1
    nCols    := GfxMaxCol()

    oWin := TWindow():New( 2, 2, GfxMaxRow() - 2, nCols - 2, "GENERAR PRESUPUESTO - Proy. " + cNumProyecto )

    oWin:AddCtrl( TLabel():New( nFila, 2, "Cliente ID:", oWin ) )
    oGCli := TGet():New( nFila, 14, PadR( cCliId, 10 ), "@!", oWin )

    oBtBus := TButton():New( nFila, 26, nFila + 1, 38, oWin, "BUSCAR", ;
        {|| cCliId := _CliSeleccionar(), oGCli:SetText( PadR( cCliId, 10 ) ) } )

    nFila++
    oWin:AddCtrl( TLabel():New( nFila, 2, "Nombre:", oWin ) )
    oWin:AddCtrl( TLabel():New( nFila, 14, cCliNom, oWin ) )

    nFila += 2
    oWin:AddCtrl( TLabel():New( nFila, 2, "Fecha:", oWin ) )
    oGFec := TGet():New( nFila, 14, dFecha, NIL, oWin )

    nFila++
    oWin:AddCtrl( TLabel():New( nFila, 2, "Validez:", oWin ) )
    oGVal := TGet():New( nFila, 14, dValidez, NIL, oWin )

    nFila += 2
    oWin:AddCtrl( TLabel():New( nFila, 2, "IVA %:", oWin ) )
    oGIva := TGet():New( nFila, 14, nPorcIva, "99.99", oWin )

    nFila++
    oWin:AddCtrl( TLabel():New( nFila, 2, "IRPF %:", oWin ) )
    oGRet := TGet():New( nFila, 14, nPorcRet, "99.99", oWin )

    nFila += 2
    oWin:AddCtrl( TLabel():New( nFila, 2, "Observaciones:", oWin ) )
    oGObs := TGet():New( nFila, 18, PadR( cObs, 60 ), "@!", oWin )

    nFila += 2
    oGrid := TGrid():New( nFila, 1, GfxMaxRow() - 8, nCols - 6, oWin )
    oGrid:aData := aLineas
    oGrid:AddColumn( "DESCRIPCION", 40, "@!",          { |a| a[1] } )
    oGrid:AddColumn( "CANTIDAD",    12, "999,999.999", { |a| a[2] } )
    oGrid:AddColumn( "PRECIO",      10, "999,999.99",  { |a| a[3] } )
    oGrid:AddColumn( "DTO %",        6, "99.99",       { |a| a[4] } )
    oGrid:AddColumn( "IVA %",        6, "99.99",       { |a| a[5] } )
    oGrid:AddColumn( "IMPORTE",     14, "999,999.99",  { |a| a[6] } )
    oWin:AddCtrl( oGrid )

    oLblTot := TLabel():New( GfxMaxRow() - 6, 2, ;
        "Subtotal: " + Transform( nSubtotal, "999,999,999.99" ) + ;
        "   IVA: " + Transform( nIva, "999,999,999.99" ) + ;
        "   Total: " + Transform( nTotal, "999,999,999.99" ), oWin )
    oWin:AddCtrl( oLblTot )

    oBtOk := TButton():New( GfxMaxRow() - 4, 2, GfxMaxRow() - 3, 28, oWin, "GUARDAR PRESUPUESTO", ;
        {|| lOk := .T., oWin:Close() } )

    oBtCan := TButton():New( GfxMaxRow() - 4, nCols - 16, GfxMaxRow() - 3, nCols - 4, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGCli  )
    oWin:AddCtrl( oBtBus )
    oWin:AddCtrl( oGFec  )
    oWin:AddCtrl( oGVal  )
    oWin:AddCtrl( oGIva  )
    oWin:AddCtrl( oGRet  )
    oWin:AddCtrl( oGObs  )
    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLblTot )
    oWin:AddCtrl( oBtOk  )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lOk
        cCliId   := AllTrim( oGCli:GetValue() )
        dFecha   := oGFec:GetValue()
        dValidez := oGVal:GetValue()
        nPorcIva := oGIva:GetValue()
        nPorcRet := oGRet:GetValue()
        cObs     := AllTrim( oGObs:GetValue() )

        nIva    := Round( nSubtotal * nPorcIva / 100, 2 )
        nRetenc := Round( nSubtotal * nPorcRet / 100, 2 )
        nTotal  := nSubtotal + nIva - nRetenc

        FOR i := 1 TO Len( aLineas )
            aLineas[i, 5] := nPorcIva
        NEXT

        lRet := _PreGuardarDrywall( cNumProyecto, cCliId, dFecha, dValidez, nPorcIva, nPorcRet, ;
                                    cObs, nSubtotal, nIva, nRetenc, nTotal, aLineas )
    ENDIF

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN lRet


STATIC FUNCTION _PreExisteOrigen( cProy )

    LOCAL lExiste := .F.
    LOCAL nArea := Select()

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_ORI", "PRE_NUM" )
        RETURN .F.
    ENDIF

    dbSelectArea( "PRE_ORI" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. FieldPos( "ID_OBRA" ) > 0 .AND. ;
           AllTrim( PRE_ORI->ID_OBRA ) == AllTrim( cProy )
            lExiste := .T.
            EXIT
        ENDIF
        dbSkip()
    ENDDO

    PRE_ORI->( DbCloseArea() )

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN lExiste


STATIC FUNCTION _PreGuardarDrywall( cProy, cCli, dFec, dVal, nIvaPct, nRetPct, ;
                                    cObs, nBase, nIva, nRet, nTot, aLin )

    LOCAL cNum := ""
    LOCAL i

    cNum := _PreSiguienteDry()

    IF Empty( cNum )
        MsgStop( "Error al generar numero de presupuesto.", "Guardar" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_DRY", "PRE_NUM" )
        MsgStop( "No se pudo abrir PRESUPUEST.", "Guardar" )
        RETURN .F.
    ENDIF

    dbSelectArea( "PRE_DRY" )

    IF !NetFLock()
        PRE_DRY->( DbCloseArea() )
        RETURN .F.
    ENDIF

    DbAppend()

    IF NetErr()
        PRE_DRY->( DbUnlock() )
        PRE_DRY->( DbCloseArea() )
        MsgStop( "Error al crear el presupuesto.", "Guardar" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "PRESUP_DE", "PRD_DRY", "PRD_LIN" )
        PRE_DRY->( DbUnlock() )
        PRE_DRY->( DbCloseArea() )
        RETURN .F.
    ENDIF

    dbSelectArea( "PRD_DRY" )

    IF !NetFLock()
        PRD_DRY->( DbCloseArea() )
        PRE_DRY->( DbUnlock() )
        PRE_DRY->( DbCloseArea() )
        RETURN .F.
    ENDIF

    BEGIN SEQUENCE
        BEGIN TRANSACTION

            dbSelectArea( "PRE_DRY" )
            REPLACE PRE_DRY->NUMERO   WITH cNum
            REPLACE PRE_DRY->FECHA    WITH dFec
            REPLACE PRE_DRY->VALIDEZ  WITH dVal
            REPLACE PRE_DRY->CLIENTE_ WITH PadR( cCli, 10 )
            REPLACE PRE_DRY->VENDEDOR WITH Space( 10 )
            REPLACE PRE_DRY->SUBTOTAL WITH nBase
            REPLACE PRE_DRY->IVA      WITH nIva
            REPLACE PRE_DRY->TOTAL    WITH nTot
            REPLACE PRE_DRY->ESTADO   WITH "P"
            DbFieldPutIf( "OBSERVA",  cObs )
            DbFieldPutIf( "RETENCIO", nRet )
            DbFieldPutIf( "PORC_RET", nRetPct )
            DbFieldPutIf( "DIAS_PAG", 0 )
            DbFieldPutIf( "NUM_FAC",  Space( 10 ) )
            DbFieldPutIf( "ID_OBRA",  PadR( cProy, 12 ) )
            DbFieldPutIf( "TIPO",     "C" )
            DbFieldPutIf( "INVERSION", .F. )

            dbSelectArea( "PRD_DRY" )
            FOR i := 1 TO Len( aLin )
                DbAppend()
                REPLACE PRD_DRY->NUMERO   WITH cNum
                REPLACE PRD_DRY->LINEA    WITH i
                REPLACE PRD_DRY->DESCRIPC WITH PadR( aLin[i, 1], 60 )
                REPLACE PRD_DRY->CANTIDAD WITH aLin[i, 2]
                REPLACE PRD_DRY->PRECIO   WITH aLin[i, 3]
                REPLACE PRD_DRY->DESCUENT WITH aLin[i, 4]
                REPLACE PRD_DRY->PORC_IVA WITH aLin[i, 5]
                REPLACE PRD_DRY->IMPORTE  WITH aLin[i, 6]
            NEXT

        END TRANSACTION

    RECOVER
        ROLLBACK
        PRD_DRY->( DbUnlock() )
        PRD_DRY->( DbCloseArea() )
        PRE_DRY->( DbUnlock() )
        PRE_DRY->( DbCloseArea() )
        MsgStop( "Error al guardar el presupuesto.", "Error" )
        RETURN .F.

    END SEQUENCE

    PRD_DRY->( DbUnlock() )
    PRD_DRY->( DbCloseArea() )
    PRE_DRY->( DbUnlock() )
    PRE_DRY->( DbCloseArea() )

    MsgInfo( "Presupuesto " + cNum + " generado correctamente.", "Presupuesto Generado" )

    IF MsgYesNo( "Desea exportar a TXT e imprimir?", "Imprimir" )
        _ImpPresupuestoTxt( cNum, cCli, dFec, aLin, nBase, nIva, nTot )
    ENDIF

RETURN .T.


STATIC FUNCTION _PreSiguienteDry()

    LOCAL cAnio, cPref, cNum
    LOCAL nMax := 0, nSeq

    cAnio := StrZero( Year( Date() ), 4 )
    cPref := "P" + cAnio

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_SIG", "PRE_NUM" )
        RETURN ""
    ENDIF

    dbSelectArea( "PRE_SIG" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            cNum := AllTrim( PRE_SIG->NUMERO )
            IF Left( cNum, Len( cPref ) ) == cPref
                nSeq := Val( SubStr( cNum, Len( cPref ) + 1 ) )
                IF nSeq > nMax
                    nMax := nSeq
                ENDIF
            ENDIF
        ENDIF
        dbSkip()
    ENDDO

    PRE_SIG->( DbCloseArea() )

RETURN cPref + StrZero( nMax + 1, 4 )


STATIC FUNCTION _CliSeleccionar()

    LOCAL aData := {}
    LOCAL oWin, oGrid
    LOCAL cSel := ""
    LOCAL lOk := .F.

    IF !ABRIR_TABLA( "CLIENTES", "CLI_SEL", "CLI_ID" )
        RETURN ""
    ENDIF

    dbSelectArea( "CLI_SEL" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( CLI_SEL->ID ), ;
                AllTrim( CLI_SEL->NOMBRE ) + " " + AllTrim( CLI_SEL->APELLIDO ), ;
                AllTrim( CLI_SEL->NIF ) } )
        ENDIF
        dbSkip()
    ENDDO

    CLI_SEL->( DbCloseArea() )

    oWin := TWindow():New( 6, 10, GfxMaxRow() - 6, GfxMaxCol() - 10, "SELECCIONAR CLIENTE" )

    oGrid := TGrid():New( 2, 2, GfxMaxRow() - 10, GfxMaxCol() - 14, oWin )
    oGrid:aData := aData
    oGrid:nSeekCol := 2
    oGrid:AddColumn( "ID",      10, "@!", { |a| a[1] } )
    oGrid:AddColumn( "NOMBRE",  50, "@!", { |a| a[2] } )
    oGrid:AddColumn( "NIF",     15, "@!", { |a| a[3] } )

    oGrid:bEnter := {|| cSel := aData[ oGrid:nCurRow, 1 ], lOk := .T., oWin:Close() }

    oWin:AddCtrl( oGrid )
    oWin:AddCtrl( TButton():New( GfxMaxRow() - 8, 10, GfxMaxRow() - 7, 34, oWin, "SELECCIONAR", ;
        {|| cSel := aData[ oGrid:nCurRow, 1 ], lOk := .T., oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( GfxMaxRow() - 8, 36, GfxMaxRow() - 7, 56, oWin, "CANCELAR", ;
        {|| oWin:Close() } ) )

    oWin:Run()

RETURN cSel


STATIC FUNCTION _ImpPresupuestoTxt( cNum, cCli, dFec, aLin, nBase, nIva, nTot )

    LOCAL cTexto := ""
    LOCAL i
    LOCAL cPath := ".\INFORME\"
    LOCAL cFile := "PRESUP_" + StrTran( cNum, " ", "_" ) + ".TXT"

    cTexto += PadC( "PRESUPUESTO " + cNum, 100 ) + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()
    cTexto += "Cliente: " + cCli + hb_Eol()
    cTexto += "Fecha: " + DToC( dFec ) + hb_Eol() + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()

    cTexto += PadR( "DESCRIPCION", 40 ) + " "
    cTexto += PadL( "CANTIDAD", 12 ) + " "
    cTexto += PadL( "PRECIO", 10 ) + " "
    cTexto += PadL( "DTO %", 6 ) + " "
    cTexto += PadL( "IVA %", 6 ) + " "
    cTexto += PadL( "IMPORTE", 14 ) + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()

    FOR i := 1 TO Len( aLin )
        cTexto += PadR( aLin[i, 1], 40 ) + " "
        cTexto += PadL( Transform( aLin[i, 2], "999,999.999" ), 12 ) + " "
        cTexto += PadL( Transform( aLin[i, 3], "999,999.99" ), 10 ) + " "
        cTexto += PadL( Transform( aLin[i, 4], "99.99" ), 6 ) + " "
        cTexto += PadL( Transform( aLin[i, 5], "99.99" ), 6 ) + " "
        cTexto += PadL( Transform( aLin[i, 6], "999,999.99" ), 14 ) + hb_Eol()
    NEXT

    cTexto += Replicate( "-", 100 ) + hb_Eol()
    cTexto += PadR( "SUBTOTAL", 70 ) + PadL( Transform( nBase, "999,999,999.99" ), 14 ) + hb_Eol()
    cTexto += PadR( "IVA", 70 ) + PadL( Transform( nIva, "999,999,999.99" ), 14 ) + hb_Eol()
    cTexto += PadR( "TOTAL", 70 ) + PadL( Transform( nTot, "999,999,999.99" ), 14 ) + hb_Eol()

    IF !DirExiste( cPath )
        DirMake( cPath )
    ENDIF

    hb_MemoWrit( cPath + cFile, cTexto )
    MsgInfo( "Presupuesto exportado a: " + cPath + cFile, "Impresion" )

RETURN NIL
