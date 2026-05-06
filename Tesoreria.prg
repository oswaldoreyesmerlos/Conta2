/*
 * ARCHIVO  : Tesoreria.prg
 * PROPOSITO: Mantenimiento de bancos y tesoreria.
 */

#include "OOp.ch"


// ============================================================================
// TesoreriaView()
// ============================================================================
FUNCTION TesoreriaView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "BANCOS", "BAN", "BAN_NOM" )
        RETURN NIL
    ENDIF

    aData := _BanCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "TESORERIA - BANCOS" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Codigo",      10, "@!", { |a| a[1] } )
    oGrid:AddColumn( "Nombre",      35, "@!", { |a| a[2] } )
    oGrid:AddColumn( "IBAN",        34, "@!", { |a| a[3] } )
    oGrid:AddColumn( "Cta.Cont.",   10, "@!", { |a| a[4] } )
    oGrid:AddColumn( "Saldo",       16, "@E 999,999,999.99", { |a| a[5] } )
    oGrid:AddColumn( "Chequera",    15, "@!", { |a| a[6] } )
    oGrid:AddColumn( "Baja",         4, "@!", { |a| If( a[7], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        TesoreriaForm( .F., g:CurrentRow()[1] ), ;
        aData := _BanCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "Letras: busqueda por nombre. ENTER: editar. F5: nuevo.", oWin )

    oBtNvo := TButton():New( 33, 2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| TesoreriaForm( .T., "" ), ;
            aData := _BanCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 33, 108, 34, 124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLbl   )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    BAN->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _BanCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "BAN" )
    OrdSetFocus( "BAN_NOM" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( BAN->BAN_COD  ), ;
                AllTrim( BAN->BAN_NOM  ), ;
                AllTrim( BAN->BAN_IBAN ), ;
                AllTrim( BAN->CTA_CONT ), ;
                BAN->BAN_SALI, ;
                AllTrim( BAN->CHEQUERA ), ;
                BAN->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


// ============================================================================
// TesoreriaForm( lNuevo, cCodigo )
// ============================================================================
STATIC FUNCTION TesoreriaForm( lNuevo, cCodigo )

    LOCAL oWin
    LOCAL oGet[7]
    LOCAL oBtOk
    LOCAL oBtCan
    LOCAL cCodigo_ := Space(10)
    LOCAL cNombre  := Space(40)
    LOCAL cIban    := Space(34)
    LOCAL cCtaCont := Space(10)
    LOCAL nSaldo   := 0
    LOCAL cChequera:= Space(15)
    LOCAL lBaja    := .F.
    LOCAL lGrabar  := .F.

    IF !lNuevo
        DbSelectArea( "BAN" )
        OrdSetFocus( "BAN_COD" )
        DbSeek( cCodigo )
        IF Found()
            cCodigo_ := BAN->BAN_COD
            cNombre  := BAN->BAN_NOM
            cIban    := BAN->BAN_IBAN
            cCtaCont := BAN->CTA_CONT
            nSaldo   := BAN->BAN_SALI
            cChequera:= BAN->CHEQUERA
            lBaja    := BAN->BAJA
        ELSE
            MsgStop( "Banco no encontrado", "Error" )
            RETURN NIL
        ENDIF
    ENDIF

    oWin := TWindow():New( 5, 20, 25, 100, ;
        If( lNuevo, "NUEVO BANCO", "EDITAR BANCO" ) )

    TLabel():New( 6, 22, "Codigo:", oWin )
    oGet[1] := TGet():New( 6, 30, 7, 38, oWin, ;
        If( lNuevo, @cCodigo_, BAN->BAN_COD ), ;
        "9999999999", If( lNuevo, nil, {|| .F. } ) )

    TLabel():New( 8, 22, "Nombre:", oWin )
    oGet[2] := TGet():New( 8, 30, 9, 68, oWin, @cNombre, "@!" )

    TLabel():New( 10, 22, "IBAN:", oWin )
    oGet[3] := TGet():New( 10, 30, 11, 68, oWin, @cIban, "@!" )

    TLabel():New( 12, 22, "Cta.Cont.:", oWin )
    oGet[4] := TGet():New( 12, 30, 13, 40, oWin, @cCtaCont, "@!" )

    TLabel():New( 14, 22, "Saldo:", oWin )
    oGet[5] := TGet():New( 14, 30, 15, 48, oWin, @nSaldo, ;
        "@E 999,999,999.99" )

    TLabel():New( 16, 22, "Chequera:", oWin )
    oGet[6] := TGet():New( 16, 30, 17, 48, oWin, @cChequera, "@!" )

    TLabel():New( 18, 22, "Baja:", oWin )
    oGet[7] := TCheck():New( 18, 30, 19, 40, oWin, @lBaja, "SI/NO" )

    oBtOk := TButton():New( 20, 30, 22, 50, oWin, "GRABAR", ;
        {|| lGrabar := .T., oWin:Close() } )

    oBtCan := TButton():New( 20, 52, 22, 72, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGet[1] )
    oWin:AddCtrl( oGet[2] )
    oWin:AddCtrl( oGet[3] )
    oWin:AddCtrl( oGet[4] )
    oWin:AddCtrl( oGet[5] )
    oWin:AddCtrl( oGet[6] )
    oWin:AddCtrl( oGet[7] )
    oWin:AddCtrl( oBtOk )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lGrabar
        _BanGuardar( lNuevo, cCodigo_, cNombre, cIban, cCtaCont, ;
            nSaldo, cChequera, lBaja )
    ENDIF

RETURN NIL


STATIC FUNCTION _BanGuardar( lNuevo, cCodigo, cNombre, cIban, ;
    cCtaCont, nSaldo, cChequera, lBaja )

    IF lNuevo
        IF NetFLock( "BAN", 0.5 )
            DbAppend()
            IF !NetFLock( "BAN", 0.5 )
                MsgStop( "No se pudo bloquear el registro", "Error" )
                RETURN .F.
            ENDIF
        ELSE
            MsgStop( "No se pudo bloquear la tabla BANCOS", "Error" )
            RETURN .F.
        ENDIF
    ELSE
        DbSelectArea( "BAN" )
        OrdSetFocus( "BAN_COD" )
        DbSeek( cCodigo )
        IF !Found() .OR. !NetFLock( "BAN", 0.5 )
            MsgStop( "No se pudo bloquear el registro", "Error" )
            RETURN .F.
        ENDIF
    ENDIF

    REPLACE BAN->BAN_COD  WITH cCodigo
    REPLACE BAN->BAN_NOM  WITH cNombre
    REPLACE BAN->BAN_IBAN WITH cIban
    REPLACE BAN->CTA_CONT WITH cCtaCont
    REPLACE BAN->BAN_SALI WITH nSaldo
    REPLACE BAN->CHEQUERA WITH cChequera
    REPLACE BAN->BAJA     WITH lBaja
    BAN->( DbUnlock() )

    MsgInfo( "Banco guardado correctamente", "Informacion" )

RETURN .T.
