/*
 * ARCHIVO  : VAL_MOD.prg
 * PROPOSITO: Valoracion Economica (Edicion de precios en el resumen).
 * MIGRADO A: GfxStack API
 */

#include "OOp.ch"

FUNCTION Valorar()

    LOCAL nAreaAnt := Select()
    LOCAL nOrdAnt  := IndexOrd()
    LOCAL oWin, oGrid, aData

    IF !IsDbUsed( "TMP_RES" )
        MsgStop( "No existe el resumen de materiales. Debe calcular primero.", "Atencion" )
        RETURN NIL
    ENDIF

    dbSelectArea( "TMP_RES" )
    IF LastRec() == 0
        MsgInfo( "El resumen esta vacio. No hay materiales que valorar.", "Aviso" )
        RETURN NIL
    ENDIF

    aData := _ValCargar()

    oWin := TWindow():New( 4, 4, GfxMaxRow() - 4, GfxMaxCol() - 4, "VALORACION ECONOMICA" )

    oWin:AddCtrl( TLabel():New( 0, 2, "[ENTER] Editar Precio   [ESC] Salir", oWin ) )

    oGrid := TGrid():New( 2, 1, GfxMaxRow() - 6, GfxMaxCol() - 6, oWin )
    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "CODIGO",      15, "@!",          { |a| a[1] } )
    oGrid:AddColumn( "DESCRIPCION", 40, "@!",          { |a| a[2] } )
    oGrid:AddColumn( "UNIDAD",      6,  "@!",          { |a| a[3] } )
    oGrid:AddColumn( "CANTIDAD",    10, "999,999.999", { |a| a[4] } )
    oGrid:AddColumn( "PRECIO",      10, "999,999.99",  { |a| a[5] } )
    oGrid:AddColumn( "IMPORTE",     14, "999,999.99",  { |a| a[6] } )

    oGrid:bEnter := {|| _ValEditarPrecio( oGrid, @aData ), oGrid:aData := aData, oGrid:Paint() }

    oWin:AddCtrl( oGrid )
    oWin:Run()

    _ValGuardar( aData )

    MsgInfo( "Valoracion completada.", "Valoracion" )

    IF nAreaAnt > 0
        dbSelectArea( nAreaAnt )
        dbSetOrder( nOrdAnt )
    ENDIF

RETURN NIL


STATIC FUNCTION _ValCargar()

    LOCAL aData := {}

    dbSelectArea( "TMP_RES" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( FIELD->CODIGO ), ;
                AllTrim( FIELD->DESCRIP ), ;
                AllTrim( FIELD->UNIDAD ), ;
                FIELD->CANT_TOT, ;
                FIELD->PRECIO, ;
                FIELD->IMP_TOT } )
        ENDIF
        dbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _ValEditarPrecio( oGrid, aData )

    LOCAL aRow := oGrid:CurrentRow()
    LOCAL oWin, oGPre, oBtOk, oBtCan
    LOCAL nNuevo := 0
    LOCAL lOk := .F.

    IF aRow == NIL
        RETURN NIL
    ENDIF

    nNuevo := aRow[5]

    oWin := TWindow():New( 12, 30, 20, 90, "EDITAR PRECIO" )

    oWin:AddCtrl( TLabel():New( 2, 3, "Articulo : " + aRow[1] + " - " + aRow[2], oWin ) )
    oWin:AddCtrl( TLabel():New( 4, 3, "Precio actual: " + Transform( aRow[5], "999,999.99" ), oWin ) )
    oWin:AddCtrl( TLabel():New( 6, 3, "Nuevo precio:", oWin ) )

    oGPre := TGet():New( 6, 18, nNuevo, "999,999.99", oWin )

    oBtOk := TButton():New( 8, 10, 9, 26, oWin, "ACEPTAR", {|| lOk := .T., nNuevo := oGPre:GetValue(), oWin:Close() } )
    oBtCan := TButton():New( 8, 28, 9, 44, oWin, "CANCELAR", {|| oWin:Close() } )

    oWin:AddCtrl( oGPre )
    oWin:AddCtrl( oBtOk )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lOk
        aRow[5] := nNuevo
        aRow[6] := aRow[4] * nNuevo
    ENDIF

RETURN NIL


STATIC FUNCTION _ValGuardar( aData )

    LOCAL i

    dbSelectArea( "TMP_RES" )
    dbGoTop()

    FOR i := 1 TO Len( aData )
        IF !Eof()
            IF NetRLock()
                REPLACE FIELD->PRECIO  WITH aData[i, 5]
                REPLACE FIELD->IMP_TOT WITH aData[i, 6]
                dbCommit()
                dbUnlock()
            ENDIF
            dbSkip()
        ENDIF
    NEXT

RETURN NIL
