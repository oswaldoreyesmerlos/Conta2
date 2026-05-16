/*
 * ARCHIVO  : EDIT_MOD.prg
 * PROPOSITO: Mantenimiento de TABLAS_AUX (Familias, Unidades, etc.)
 * MIGRADO A: GfxStack API
 */

#include "OOp.ch"

FUNCTION EditAux( cTipo )

    LOCAL nArea, nOrd, oWin, oGrid, cTit, lOk := .T.
    LOCAL aData

    nArea := Select(); nOrd := IndexOrd()

    IF Select( "TABLAS_AUX" ) == 0
        IF File( "TABLAS_AUX.DBF" )
            USE TABLAS_AUX NEW SHARED VIA "DBFCDX"
        ELSE
            MsgStop( "Falta archivo TABLAS_AUX.DBF" )
            lOk := .F.
        ENDIF
    ENDIF

    IF lOk
        dbSelectArea( "TABLAS_AUX" )
        dbSetOrder( 1 )

        OrdScope( 0, PadR( cTipo, 10 ) )
        OrdScope( 1, PadR( cTipo, 10 ) )
        dbGoTop()

        cTit := _GetAuxTitle( cTipo )

        aData := _AuxLoadData()

        oWin := TWindow():New( 5, 10, 20, 70, " " + cTit + " " )

        oGrid := TGrid():New( 1, 1, 10, 57, oWin )
        oGrid:aData := aData
        oGrid:nSeekCol := 2
        oGrid:AddColumn( "CODIGO",     10, "@!", { |a| a[1] } )
        oGrid:AddColumn( "DESCRIPCION",45, "@!", { |a| a[2] } )
        oGrid:bEnter := {|| AuxForm( .F., cTipo ), aData := _AuxLoadData(), oGrid:aData := aData, oGrid:Paint() }

        oWin:AddCtrl( oGrid )
        oWin:AddCtrl( TLabel():New( 12, 2, "[F5] Nuevo [ENTER] Editar [DEL] Borrar", oWin ) )
        oWin:AddCtrl( TButton():New( 13, 2, 14, 18, oWin, "NUEVO (F5)", {|| AuxForm( .T., cTipo ), aData := _AuxLoadData(), oGrid:aData := aData, oGrid:Paint() } ) )
        oWin:AddCtrl( TButton():New( 13, 40, 14, 56, oWin, "CERRAR", {|| oWin:Close() } ) )

        oWin:Run()

        OrdScope( 0, NIL )
        OrdScope( 1, NIL )
    ENDIF

    IF nArea > 0; dbSelectArea( nArea ); dbSetOrder( nOrd ); ENDIF
RETURN NIL


FUNCTION AuxForm( lNew, cTipo )

    LOCAL nArea, oWin, lSave := .F.
    LOCAL hData := hb_Hash()
    LOCAL oGCod, oGDes
    LOCAL oBtGua, oBtCan

    nArea := Select(); dbSelectArea( "TABLAS_AUX" )

    IF lNew
        hData["TIPO"]    := cTipo
        hData["CODIGO"]  := Space( 10 )
        hData["DESCRIP"] := Space( 40 )
    ELSE
        hData["TIPO"]    := FIELD->TIPO
        hData["CODIGO"]  := FIELD->CODIGO
        hData["DESCRIP"] := FIELD->DESCRIP
    ENDIF

    oWin := TWindow():New( 8, 15, 18, 65, If( lNew, "NUEVO REGISTRO", "EDITAR REGISTRO" ) )

    oWin:AddCtrl( TLabel():New( 2, 2, "Codigo..:", oWin ) )
    oGCod := TGet():New( 2, 12, hData["CODIGO"], "@!", oWin )
    IF !lNew
        oGCod:lEnabled := .F.
    ENDIF

    oWin:AddCtrl( TLabel():New( 4, 2, "Descrip.:", oWin ) )
    oGDes := TGet():New( 4, 12, hData["DESCRIP"], "@S40!", oWin )

    oBtGua := TButton():New( 7, 10, 8, 26, oWin, "GUARDAR", {|| lSave := .T., hData["CODIGO"] := AllTrim( oGCod:GetValue() ), hData["DESCRIP"] := AllTrim( oGDes:GetValue() ), oWin:Close() } )
    oBtCan := TButton():New( 7, 28, 8, 44, oWin, "VOLVER", {|| oWin:Close() } )

    oWin:AddCtrl( oGCod )
    oWin:AddCtrl( oGDes )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lSave
        _AuxSave( lNew, hData )
    ENDIF

    dbSelectArea( nArea )
RETURN lSave


STATIC FUNCTION _AuxLoadData()

    LOCAL aData := {}

    dbSelectArea( "TABLAS_AUX" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( FIELD->CODIGO ), ;
                AllTrim( FIELD->DESCRIP ) } )
        ENDIF
        dbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _AuxSave( lNew, hData )

    IF lNew
        dbAppend()
        REPLACE FIELD->TIPO WITH hData["TIPO"]
    ELSE
        dbSelectArea( "TABLAS_AUX" )
        dbGoTop()
        DO WHILE !Eof()
            IF AllTrim( FIELD->CODIGO ) == AllTrim( hData["CODIGO"] ) .AND. ;
               AllTrim( FIELD->TIPO ) == AllTrim( hData["TIPO"] )
                EXIT
            ENDIF
            dbSkip()
        ENDDO
    ENDIF

    IF NetRLock()
        REPLACE FIELD->CODIGO  WITH hData["CODIGO"]
        REPLACE FIELD->DESCRIP WITH hData["DESCRIP"]
        dbCommit()
        dbUnlock()
    ENDIF

RETURN NIL


STATIC FUNCTION _GetAuxTitle( cTipo )

    DO CASE
    CASE cTipo == "PERFIL"   ; RETURN "PERFILES"
    CASE cTipo == "PLACA"    ; RETURN "PLACAS DE YESO"
    CASE cTipo == "AISLAN"   ; RETURN "AISLAMIENTOS"
    CASE cTipo == "ANCLAJE"  ; RETURN "SISTEMAS ANCLAJE"
    CASE cTipo == "TORNILLO" ; RETURN "TORNILLERIA"
    CASE cTipo == "PASTA"    ; RETURN "PASTAS"
    CASE cTipo == "CINTA"    ; RETURN "CINTAS"
    CASE cTipo == "ACCESORIO"; RETURN "ACCESORIOS"
    ENDCASE

RETURN cTipo
