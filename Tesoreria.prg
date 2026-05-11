/*
 * ARCHIVO  : Tesoreria.prg
 * PROPOSITO: Mantenimiento de bancos y tesoreria.
 */

#include "OOp.ch"


// ============================================================================
// TesoreriaView()
// ============================================================================
FUNCTION BancosView()

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


FUNCTION BancoNuevo()

    LOCAL nArea := Select()
    LOCAL lAbierta := DBUSED( "BAN" )

    IF !lAbierta .AND. !ABRIR_TABLA( "BANCOS", "BAN", "BAN_COD" )
        RETURN NIL
    ENDIF

    DbSelectArea( "BAN" )
    TesoreriaForm( .T., "" )

    IF !lAbierta
        BAN->( DbCloseArea() )
    ENDIF

    IF nArea > 0
        Select( nArea )
    ENDIF

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

    oWin:AddCtrl( TLabel():New(  2,  3, "Codigo    :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  3, "Nombre    :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  3, "IBAN      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  3, "Cta.Cont. :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  3, "Saldo     :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12,  3, "Chequera  :", oWin ) )

    oGet[1] := TGet():New(  2, 15, cCodigo_,  "@!",              oWin )
    oGet[2] := TGet():New(  4, 15, cNombre,   "@!",              oWin )
    oGet[3] := TGet():New(  6, 15, cIban,     "@!",              oWin )
    oGet[4] := TGet():New(  8, 15, cCtaCont,  "@!",              oWin )
    oGet[5] := TGet():New( 10, 15, nSaldo,    "999999999999.99", oWin )
    oGet[6] := TGet():New( 12, 15, cChequera, "@!",              oWin )
    oGet[7] := TCheck():New( 14, 15, "Baja", lBaja, oWin )

    IF !lNuevo
        oGet[1]:bWhen := {|| .F. }
    ENDIF

    oBtOk := TButton():New( 16, 15, 16, 34, oWin, "GRABAR", ;
        {|| lGrabar := .T., oWin:Close() } )

    oBtCan := TButton():New( 16, 37, 16, 56, oWin, "CANCELAR", ;
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
        cCodigo_  := AllTrim( oGet[1]:uVar )
        cNombre   := AllTrim( oGet[2]:uVar )
        cIban     := AllTrim( oGet[3]:uVar )
        cCtaCont  := AllTrim( oGet[4]:uVar )
        nSaldo    := oGet[5]:uVar
        cChequera := AllTrim( oGet[6]:uVar )
        lBaja     := oGet[7]:lValue

        _BanGuardar( lNuevo, cCodigo_, cNombre, cIban, cCtaCont, ;
            nSaldo, cChequera, lBaja )
    ENDIF

RETURN NIL


STATIC FUNCTION _BanGuardar( lNuevo, cCodigo, cNombre, cIban, ;
    cCtaCont, nSaldo, cChequera, lBaja )

    IF lNuevo
        IF NetFLock()
            DbAppend()
            IF !NetRLock()
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
        IF !Found() .OR. !NetRLock()
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


// ============================================================================
// TesoreriaView() — alias de compatibilidad con el menu anterior
// ============================================================================
FUNCTION TesoreriaView()
RETURN BancosView()


// ============================================================================
// CajaView() — gestion de recibos de caja y cobros
// ============================================================================
FUNCTION CajaView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "RECIBOS", "REC", "REC_FEC" )
        RETURN NIL
    ENDIF

    aData := _RecCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "RECIBOS DE CAJA" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 3

    oGrid:AddColumn( "Numero",     10, "@!",          { |a| a[1] } )
    oGrid:AddColumn( "Fecha",      10, "@!",          { |a| a[2] } )
    oGrid:AddColumn( "Cliente",    35, "@!",          { |a| a[3] } )
    oGrid:AddColumn( "Forma pago",  9, "@!",          { |a| a[4] } )
    oGrid:AddColumn( "Total",      12, "999,999.99",  { |a| a[5] } )
    oGrid:AddColumn( "Facturas",   30, "@!",          { |a| a[6] } )

    oGrid:bEnter := {| g | ;
        If( g:CurrentRow() != NIL, ;
            MsgInfo( "Recibo: " + g:CurrentRow()[1], "Detalle" ), NIL ) }

    oLbl := TLabel():New( 32, 2, ;
        "ENTER: ver recibo   F5: nuevo recibo", oWin )

    oBtNvo := TButton():New( 33, 2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| _RecForm(), ;
            aData := _RecCargar(), ;
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

    REC->( DbCloseArea() )

RETURN NIL


FUNCTION ReciboNuevo()
RETURN _RecForm( "" )


FUNCTION CobroNuevo()
RETURN _RecForm( "" )


FUNCTION PagoNuevo()
RETURN _PagoForm( "", 0 )


STATIC FUNCTION _RecCargar()

    LOCAL aData
    LOCAL cFacs

    aData := {}

    REC->( OrdSetFocus( "REC_FEC" ) )
    REC->( DbGoTop() )

    DO WHILE !REC->( Eof() )
        IF !REC->( Deleted() )
            cFacs := _RecListarFacs( AllTrim( REC->NUMERO ) )
            AAdd( aData, { ;
                AllTrim( REC->NUMERO   ), ;
                DToC(    REC->FECHA    ), ;
                _RecNomCli( AllTrim( REC->CLIENTE_ ) ), ;
                _RecDescFP( AllTrim( REC->FORMA_PA ) ), ;
                REC->TOTAL, ;
                cFacs } )
        ENDIF
        REC->( DbSkip() )
    ENDDO

RETURN aData


STATIC FUNCTION _RecDescFP( cFP )

    DO CASE
    CASE cFP == "EFE" ; RETURN "Efectivo"
    CASE cFP == "TRF" ; RETURN "Transf."
    CASE cFP == "TAR" ; RETURN "Tarjeta"
    CASE cFP == "CHQ" ; RETURN "Cheque"
    ENDCASE

RETURN "Otro"


STATIC FUNCTION _RecNomCli( cId )

    LOCAL cNom

    cNom := cId

    IF ABRIR_TABLA( "CLIENTES", "CLI_RC", "CLI_ID" )
        IF CLI_RC->( DbSeek( cId ) )
            cNom := AllTrim( CLI_RC->NOMBRE + " " + CLI_RC->APELLIDO )
        ENDIF
        CLI_RC->( DbCloseArea() )
    ENDIF

RETURN cNom


STATIC FUNCTION _RecListarFacs( cNumRec )

    LOCAL cLista

    cLista := ""

    IF !ABRIR_TABLA( "RC_DETAL", "RCD_RC", "RCD_NUM" )
        RETURN cLista
    ENDIF

    RCD_RC->( OrdSetFocus( "RCD_NUM" ) )
    RCD_RC->( DbSeek( PadR( cNumRec, 10 ) + "  1" ) )

    DO WHILE !RCD_RC->( Eof() ) .AND. AllTrim( RCD_RC->NUMERO ) == cNumRec
        IF !RCD_RC->( Deleted() )
            IF !Empty( cLista )
                cLista += ", "
            ENDIF
            cLista += AllTrim( RCD_RC->NUM_FAC )
        ENDIF
        RCD_RC->( DbSkip() )
    ENDDO

    RCD_RC->( DbCloseArea() )

RETURN cLista


STATIC FUNCTION _RecForm( cNumFac )

    LOCAL oWin
    LOCAL oGNum
    LOCAL oGFec
    LOCAL oGCli
    LOCAL oGCon
    LOCAL oGFP
    LOCAL oGTot
    LOCAL oBtOk
    LOCAL oBtCan
    LOCAL lOK
    LOCAL cNumRec
    LOCAL dFecha
    LOCAL cCliente
    LOCAL cConcepto
    LOCAL cFormaPa
    LOCAL nTotal

    DEFAULT cNumFac TO ""

    lOK       := .F.
    cNumRec   := _RecNextNum()
    dFecha    := Date()
    cCliente  := Space( 10 )
    cConcepto := Space(100 )
    cFormaPa  := Space(  3 )
    nTotal    := 0

    IF Empty( cNumRec )
        RETURN NIL
    ENDIF

    IF !Empty( AllTrim( cNumFac ) )
        _RecDatosFactura( cNumFac, @cCliente, @cFormaPa, @nTotal )
        cConcepto := PadR( "Cobro factura " + AllTrim( cNumFac ), 100 )
    ENDIF

    oWin := TWindow():New( 7, 28, 25, 100, "NUEVO RECIBO / COBRO" )

    oWin:AddCtrl( TLabel():New(  2,  3, "Numero    :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  3, "Fecha     :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  3, "Cliente   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  3, "Concepto  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  3, "Forma pago:", oWin ) )
    oWin:AddCtrl( TLabel():New( 12,  3, "Total     :", oWin ) )

    oGNum := TGet():New(  2, 16, cNumRec,   "@!",              oWin )
    oGFec := TGet():New(  4, 16, dFecha,    "99/99/9999",     oWin )
    oGCli := TGet():New(  6, 16, cCliente,  "@!",              oWin )
    oGCon := TGet():New(  8, 16, cConcepto, "@S50!",           oWin )
    oGFP  := TGet():New( 10, 16, cFormaPa,  "@!",              oWin )
    oGTot := TGet():New( 12, 16, nTotal,    "999999999.99",    oWin )

    oGNum:bWhen := {|| .F. }

    oBtOk  := TButton():New( 15, 16, 16, 34, oWin, "GRABAR", ;
        {|| lOK := .T., oWin:Close() } )

    oBtCan := TButton():New( 15, 38, 16, 56, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGNum  )
    oWin:AddCtrl( oGFec  )
    oWin:AddCtrl( oGCli  )
    oWin:AddCtrl( oGCon  )
    oWin:AddCtrl( oGFP   )
    oWin:AddCtrl( oGTot  )
    oWin:AddCtrl( oBtOk  )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF !lOK
        RETURN NIL
    ENDIF

    cCliente  := AllTrim( oGCli:GetValue() )
    cConcepto := AllTrim( oGCon:GetValue() )
    cFormaPa  := AllTrim( oGFP:GetValue() )
    nTotal    := oGTot:GetValue()

    IF Empty( cCliente )
        MsgStop( "Debe indicar el cliente.", "Recibo" )
        RETURN NIL
    ENDIF

    IF nTotal <= 0
        MsgStop( "El total debe ser mayor que cero.", "Recibo" )
        RETURN NIL
    ENDIF

    IF _RecGuardar( cNumRec, oGFec:GetValue(), cCliente, cConcepto, ;
                    cFormaPa, nTotal, cNumFac )
        MsgInfo( "Recibo guardado correctamente.", "Caja" )
    ENDIF

RETURN NIL


STATIC FUNCTION _RecNextNum()
RETURN GetNextNum( "REC" + AllTrim( Str( Year( Date() ) ) ), ;
                   "Recibos " + AllTrim( Str( Year( Date() ) ) ) )


STATIC FUNCTION _RecDatosFactura( cNumFac, cCliente, cFormaPa, nTotal )

    cCliente := Space( 10 )
    cFormaPa := Space(  3 )
    nTotal   := 0

    IF !ABRIR_TABLA( "FACTURA", "FAC_RF", "FAC_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "FAC_RF" )
    OrdSetFocus( "FAC_NUM" )

    IF DbSeek( PadR( "A", 4 ) + PadR( AllTrim( cNumFac ), 10 ) )
        cCliente := PadR( AllTrim( FAC_RF->CLIENTE_ ), 10 )
        cFormaPa := PadR( AllTrim( FAC_RF->FORMA_PA ),  3 )
        nTotal   := FAC_RF->TOTAL
    ENDIF

    FAC_RF->( DbCloseArea() )

RETURN !Empty( AllTrim( cCliente ) )


STATIC FUNCTION _RecGuardar( cNumRec, dFecha, cCliente, cConcepto, ;
    cFormaPa, nTotal, cNumFac )

    LOCAL cUsuario := "SISTEMA"

    MEMVAR cUserID

    IF Type( "cUserID" ) == "C" .AND. !Empty( cUserID )
        cUsuario := AllTrim( cUserID )
    ENDIF

    IF !ABRIR_TABLA( "RECIBOS", "REC_G", "REC_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "REC_G" )
    OrdSetFocus( "REC_NUM" )

    IF DbSeek( PadR( cNumRec, 10 ) )
        REC_G->( DbCloseArea() )
        MsgStop( "El recibo ya existe.", "Recibo" )
        RETURN .F.
    ENDIF

    IF !NetFLock()
        REC_G->( DbCloseArea() )
        RETURN .F.
    ENDIF

    DbAppend()
    IF !NetRLock()
        DbUnlock()
        REC_G->( DbCloseArea() )
        RETURN .F.
    ENDIF

    REPLACE REC_G->NUMERO   WITH PadR( cNumRec, 10 )
    REPLACE REC_G->FECHA    WITH dFecha
    REPLACE REC_G->CLIENTE_ WITH PadR( cCliente, 10 )
    REPLACE REC_G->CONCEPTO WITH PadR( cConcepto, 100 )
    REPLACE REC_G->FORMA_PA WITH PadR( cFormaPa, 3 )
    REPLACE REC_G->TOTAL    WITH nTotal
    REPLACE REC_G->ASIENTO  WITH Space( 10 )
    REPLACE REC_G->USUARIO_ WITH PadR( cUsuario, 10 )
    DbCommit()
    DbUnlock()
    REC_G->( DbCloseArea() )

    IF !Empty( AllTrim( cNumFac ) )
        _RecGuardarDetalle( cNumRec, cNumFac, nTotal )
        _RecMarcarFactura( cNumFac )
    ENDIF

    AsientoAutomatico( "REC", cNumRec )

RETURN .T.


STATIC FUNCTION _RecGuardarDetalle( cNumRec, cNumFac, nTotal )

    IF !ABRIR_TABLA( "RC_DETAL", "RCD_G", "RCD_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "RCD_G" )
    IF !NetFLock()
        RCD_G->( DbCloseArea() )
        RETURN .F.
    ENDIF

    DbAppend()
    IF NetRLock()
        REPLACE RCD_G->NUMERO  WITH PadR( cNumRec, 10 )
        REPLACE RCD_G->LINEA   WITH 1
        REPLACE RCD_G->NUM_FAC WITH PadR( cNumFac, 10 )
        REPLACE RCD_G->IMPORTE WITH nTotal
        DbCommit()
        DbUnlock()
    ENDIF

    RCD_G->( DbCloseArea() )

RETURN .T.


STATIC FUNCTION _RecMarcarFactura( cNumFac )

    IF FacturaContabilizada( "A", cNumFac )
        RETURN .T.
    ENDIF

    IF !ABRIR_TABLA( "FACTURA", "FAC_RG", "FAC_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "FAC_RG" )
    OrdSetFocus( "FAC_NUM" )

    IF DbSeek( PadR( "A", 4 ) + PadR( AllTrim( cNumFac ), 10 ) ) .AND. NetRLock()
        IF FieldPos( "COBRADA" ) > 0
            REPLACE FAC_RG->COBRADA WITH .T.
        ENDIF
        DbCommit()
        DbUnlock()
    ENDIF

    FAC_RG->( DbCloseArea() )

RETURN .T.


// ============================================================================
// CobrosView()
// ----------------------------------------------------------------------------
// Grid de facturas pendientes de cobro ordenadas por vencimiento.
// Permite registrar el cobro directamente desde aqui abriendo ReciboForm.
// ============================================================================
FUNCTION CobrosView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtCob
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData
    LOCAL nTotal
    LOCAL oLTotal

    IF !ABRIR_TABLA( "FACTURA", "FAC_CV", "FAC_VTO" )
        RETURN NIL
    ENDIF

    aData  := _CobCargar()
    nTotal := _CobTotal( aData )

    oWin  := TWindow():New( 1, 2, 37, 129, "VENCIMIENTOS PENDIENTES DE COBRO" )
    oGrid := TGrid():New( 2, 2, 28, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 3

    oGrid:AddColumn( "Factura",    10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "F.Emision",  10, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "F.Vencto",   10, "@!",         { |a| a[3] } )
    oGrid:AddColumn( "Cliente",    35, "@!",         { |a| a[4] } )
    oGrid:AddColumn( "Total",      12, "999,999.99", { |a| a[5] } )
    oGrid:AddColumn( "Estado",     10, "@!",         { |a| a[6] } )

    oGrid:bEnter := {| g | ;
        If( g:CurrentRow() != NIL, ;
            _CobRegistrar( g:CurrentRow()[1] ), NIL ), ;
        aData := _CobCargar(), ;
        nTotal := _CobTotal( aData ), ;
        oGrid:aData := aData, ;
        oLTotal:SetText( "TOTAL PENDIENTE: " + ;
            Transform( nTotal, "999,999,999.99" ) + " EUR" ), ;
        oGrid:Paint() }

    oLbl := TLabel():New( 30, 2, ;
        "ENTER: registrar cobro   Letras: buscar cliente", oWin )

    oLTotal := TLabel():New( 31, 2, ;
        "TOTAL PENDIENTE: " + Transform( nTotal, "999,999,999.99" ) + " EUR", oWin )
    oLTotal:cColor := "W+/B"

    oBtCob := TButton():New( 33,  2, 34, 20, oWin, "REGISTRAR COBRO", ;
        {|| If( oGrid:CurrentRow() != NIL, ;
               _CobRegistrar( oGrid:CurrentRow()[1] ), NIL ), ;
            aData := _CobCargar(), ;
            nTotal := _CobTotal( aData ), ;
            oGrid:aData := aData, ;
            oLTotal:SetText( "TOTAL PENDIENTE: " + ;
                Transform( nTotal, "999,999,999.99" ) + " EUR" ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 33, 108, 34, 124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid   )
    oWin:AddCtrl( oLbl    )
    oWin:AddCtrl( oLTotal )
    oWin:AddCtrl( oBtCob  )
    oWin:AddCtrl( oBtSal  )

    oWin:Run()

    FAC_CV->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _CobCargar()

    LOCAL aData
    LOCAL nDias
    LOCAL cEst

    aData := {}

    DbSelectArea( "FAC_CV" )
    OrdSetFocus( "FAC_VTO" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. !_AliasLogical( "FAC_CV", "COBRADA", .F. ) .AND. ;
           !_AliasLogical( "FAC_CV", "ANULADA", .F. )
            nDias := Date() - FAC_CV->FECHA_VT
            DO CASE
            CASE nDias > 30  ; cEst := "VENCIDA +" + AllTrim( Str( nDias ) ) + "d"
            CASE nDias > 0   ; cEst := "VENCIDA"
            CASE nDias > -7  ; cEst := "PROXIMA"
            OTHERWISE        ; cEst := "Pendiente"
            ENDCASE
            AAdd( aData, { ;
                AllTrim( FAC_CV->NUMERO   ), ;
                DToC(    FAC_CV->FECHA    ), ;
                DToC(    FAC_CV->FECHA_VT ), ;
                AllTrim( FAC_CV->CLIENTE_ ), ;
                FAC_CV->TOTAL, ;
                cEst } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _CobTotal( aData )

    LOCAL nTot
    LOCAL i

    nTot := 0

    FOR i := 1 TO Len( aData )
        nTot += aData[i, 5]
    NEXT

RETURN nTot


STATIC FUNCTION _CobRegistrar( cNumFac )

    LOCAL cCliID

    cCliID := ""

    IF Empty( AllTrim( cNumFac ) )
        RETURN NIL
    ENDIF

    // Obtener cliente de la factura
    IF ABRIR_TABLA( "FACTURA", "FAC_CR", "FAC_NUM" )
        DbSelectArea( "FAC_CR" )
        OrdSetFocus( "FAC_NUM" )
        IF DbSeek( PadR( "A", 4 ) + PadR( AllTrim( cNumFac ), 10 ) )
            cCliID := AllTrim( FAC_CR->CLIENTE_ )
        ENDIF
        FAC_CR->( DbCloseArea() )
    ENDIF

    IF Empty( cCliID )
        MsgStop( "No se pudo localizar el cliente de la factura.", "Error" )
        RETURN NIL
    ENDIF

    IF !MsgYesNo( "Registrar cobro de factura " + AllTrim( cNumFac ) + "?", ;
                  "Registrar cobro" )
        RETURN NIL
    ENDIF

    // Abrir formulario de recibo prellenado con este cliente
    // El usuario seleccionara la factura en el grid de pendientes
    _RecForm( cNumFac )

RETURN NIL


// ============================================================================
// PagosView()
// ----------------------------------------------------------------------------
// Grid de facturas de compra pendientes de pago al proveedor.
// Permite registrar el pago generando el movimiento bancario correspondiente.
// ============================================================================
FUNCTION PagosView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtPag
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL oLTotal
    LOCAL aData
    LOCAL nTotal

    IF !ABRIR_TABLA( "COMPRAS", "COM_PV", "COM_VTO" )
        RETURN NIL
    ENDIF

    aData  := _PagCargar()
    nTotal := _PagTotal( aData )

    oWin  := TWindow():New( 1, 2, 37, 129, "PAGOS PENDIENTES A PROVEEDORES" )
    oGrid := TGrid():New( 2, 2, 28, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 4

    oGrid:AddColumn( "Num.Int.",    10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "F.Factura",   10, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "F.Vencto",    10, "@!",         { |a| a[3] } )
    oGrid:AddColumn( "Proveedor",   30, "@!",         { |a| a[4] } )
    oGrid:AddColumn( "Total",       12, "999,999.99", { |a| a[5] } )
    oGrid:AddColumn( "Estado",      10, "@!",         { |a| a[6] } )

    oGrid:bEnter := {| g | ;
        If( g:CurrentRow() != NIL, ;
            _PagRegistrar( g:CurrentRow()[1], g:CurrentRow()[5] ), NIL ), ;
        aData := _PagCargar(), ;
        nTotal := _PagTotal( aData ), ;
        oGrid:aData := aData, ;
        oLTotal:SetText( "TOTAL PENDIENTE: " + ;
            Transform( nTotal, "999,999,999.99" ) + " EUR" ), ;
        oGrid:Paint() }

    oLbl := TLabel():New( 30, 2, ;
        "ENTER: registrar pago   Letras: buscar proveedor", oWin )

    oLTotal := TLabel():New( 31, 2, ;
        "TOTAL PENDIENTE: " + Transform( nTotal, "999,999,999.99" ) + " EUR", oWin )
    oLTotal:cColor := "W+/B"

    oBtPag := TButton():New( 33,  2, 34, 20, oWin, "REGISTRAR PAGO", ;
        {|| If( oGrid:CurrentRow() != NIL, ;
               _PagRegistrar( oGrid:CurrentRow()[1], oGrid:CurrentRow()[5] ), NIL ), ;
            aData := _PagCargar(), ;
            nTotal := _PagTotal( aData ), ;
            oGrid:aData := aData, ;
            oLTotal:SetText( "TOTAL PENDIENTE: " + ;
                Transform( nTotal, "999,999,999.99" ) + " EUR" ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 33, 108, 34, 124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid   )
    oWin:AddCtrl( oLbl    )
    oWin:AddCtrl( oLTotal )
    oWin:AddCtrl( oBtPag  )
    oWin:AddCtrl( oBtSal  )

    oWin:Run()

    COM_PV->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _PagCargar()

    LOCAL aData
    LOCAL nDias
    LOCAL cEst

    aData := {}

    DbSelectArea( "COM_PV" )
    OrdSetFocus( "COM_VTO" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. !_AliasLogical( "COM_PV", "PAGADA", .F. )
            nDias := Date() - COM_PV->FECHA_VT
            DO CASE
            CASE nDias > 30  ; cEst := "VENCIDA +" + AllTrim( Str( nDias ) ) + "d"
            CASE nDias > 0   ; cEst := "VENCIDA"
            CASE nDias > -7  ; cEst := "PROXIMA"
            OTHERWISE        ; cEst := "Pendiente"
            ENDCASE
            AAdd( aData, { ;
                AllTrim( COM_PV->NUM_INTE  ), ;
                DToC(    COM_PV->FECHA     ), ;
                DToC(    COM_PV->FECHA_VT  ), ;
                AllTrim( COM_PV->PROV_ID   ), ;
                COM_PV->TOTAL, ;
                cEst } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _PagTotal( aData )

    LOCAL nTot
    LOCAL i

    nTot := 0

    FOR i := 1 TO Len( aData )
        nTot += aData[i, 5]
    NEXT

RETURN nTot


STATIC FUNCTION _PagRegistrar( cNumCom, nImporte )

RETURN _PagoForm( cNumCom, nImporte )


STATIC FUNCTION _PagoForm( cNumCom, nImporte )

    LOCAL oWin
    LOCAL oGNum
    LOCAL oGFec
    LOCAL oGPrv
    LOCAL oGBen
    LOCAL oGCon
    LOCAL oGFP
    LOCAL oGRef
    LOCAL oGBan
    LOCAL oGDebe
    LOCAL oGHaber
    LOCAL oGTot
    LOCAL oBtOk
    LOCAL oBtCan
    LOCAL lOK
    LOCAL cNumPag
    LOCAL dFec
    LOCAL cProv
    LOCAL cBenef
    LOCAL cConcepto
    LOCAL cFormPag
    LOCAL cRef
    LOCAL cBanco
    LOCAL cCtaDebe
    LOCAL cCtaHaber
    LOCAL nTotal

    DEFAULT cNumCom TO ""
    DEFAULT nImporte TO 0

    lOK       := .F.
    cNumPag   := _PagoNextNum()
    dFec      := Date()
    cProv     := Space( 10 )
    cBenef    := Space( 60 )
    cConcepto := Space(100 )
    cFormPag  := PadR( "TRF", 3 )
    cRef      := Space( 20 )
    cBanco    := Space( 10 )
    cCtaDebe  := PadR( "400", 10 )
    cCtaHaber := PadR( "572", 10 )
    nTotal    := nImporte

    IF Empty( cNumPag )
        RETURN NIL
    ENDIF

    IF !Empty( AllTrim( cNumCom ) )
        _PagoDatosCompra( cNumCom, @cProv, @cBenef, @cCtaDebe, @nTotal )
        cConcepto := PadR( "Pago compra " + AllTrim( cNumCom ), 100 )
    ENDIF

    oWin := TWindow():New( 5, 18, 31, 116, "NUEVO PAGO" )

    oWin:AddCtrl( TLabel():New(  2,  3, "Numero    :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  3, "Fecha     :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  3, "Proveedor :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  3, "Benefic.  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  3, "Concepto  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12,  3, "Forma pago:", oWin ) )
    oWin:AddCtrl( TLabel():New( 14,  3, "Referencia:", oWin ) )
    oWin:AddCtrl( TLabel():New( 16,  3, "Banco     :", oWin ) )
    oWin:AddCtrl( TLabel():New( 18,  3, "Cta debe  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 20,  3, "Cta haber :", oWin ) )
    oWin:AddCtrl( TLabel():New( 22,  3, "Importe   :", oWin ) )

    oGNum   := TGet():New(  2, 16, cNumPag,   "@!",           oWin )
    oGFec   := TGet():New(  4, 16, dFec,      "99/99/9999",  oWin )
    oGPrv   := TGet():New(  6, 16, cProv,     "@!",           oWin )
    oGBen   := TGet():New(  8, 16, cBenef,    "@!",           oWin )
    oGCon   := TGet():New( 10, 16, cConcepto, "@!",           oWin )
    oGFP    := TGet():New( 12, 16, cFormPag,  "@!",           oWin )
    oGRef   := TGet():New( 14, 16, cRef,      "@!",           oWin )
    oGBan   := TGet():New( 16, 16, cBanco,    "@!",           oWin )
    oGDebe  := TGet():New( 18, 16, cCtaDebe,  "@!",           oWin )
    oGHaber := TGet():New( 20, 16, cCtaHaber, "@!",           oWin )
    oGTot   := TGet():New( 22, 16, nTotal,    "999999999.99", oWin )

    oGNum:bWhen := {|| .F. }

    oBtOk  := TButton():New( 24, 16, 25, 34, oWin, "GRABAR", ;
        {|| lOK := .T., oWin:Close() } )

    oBtCan := TButton():New( 24, 38, 25, 56, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGNum   )
    oWin:AddCtrl( oGFec   )
    oWin:AddCtrl( oGPrv   )
    oWin:AddCtrl( oGBen   )
    oWin:AddCtrl( oGCon   )
    oWin:AddCtrl( oGFP    )
    oWin:AddCtrl( oGRef   )
    oWin:AddCtrl( oGBan   )
    oWin:AddCtrl( oGDebe  )
    oWin:AddCtrl( oGHaber )
    oWin:AddCtrl( oGTot   )
    oWin:AddCtrl( oBtOk   )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

    IF !lOK
        RETURN NIL
    ENDIF

    cProv     := AllTrim( oGPrv:GetValue() )
    cBenef    := AllTrim( oGBen:GetValue() )
    cConcepto := AllTrim( oGCon:GetValue() )
    cFormPag  := Upper( AllTrim( oGFP:GetValue() ) )
    cRef      := AllTrim( oGRef:GetValue() )
    cBanco    := AllTrim( oGBan:GetValue() )
    cCtaDebe  := AllTrim( oGDebe:GetValue() )
    cCtaHaber := AllTrim( oGHaber:GetValue() )
    nTotal    := oGTot:GetValue()

    IF Empty( cFormPag )
        MsgStop( "Debe indicar forma de pago: CHQ, TRF, EFE, TAR u OTR.", "Pago" )
        RETURN NIL
    ENDIF

    IF Empty( cCtaDebe ) .OR. Empty( cCtaHaber )
        MsgStop( "Debe indicar cuenta debe y cuenta haber.", "Pago" )
        RETURN NIL
    ENDIF

    IF nTotal <= 0
        MsgStop( "El importe debe ser mayor que cero.", "Pago" )
        RETURN NIL
    ENDIF

    IF _PagoGuardar( cNumPag, oGFec:GetValue(), cProv, cBenef, cConcepto, ;
                     cFormPag, cRef, cBanco, cCtaDebe, cCtaHaber, nTotal, cNumCom )
        MsgInfo( "Pago registrado correctamente.", "Pago" )
    ENDIF

RETURN NIL


STATIC FUNCTION _PagoNextNum()
RETURN GetNextNum( "PAG", "Pagos" )


STATIC FUNCTION _PagoDatosCompra( cNumCom, cProv, cBenef, cCtaDebe, nTotal )

    cProv    := Space( 10 )
    cBenef   := Space( 60 )
    cCtaDebe := PadR( "400", 10 )
    nTotal   := 0

    IF !ABRIR_TABLA( "COMPRAS", "COM_PF", "COM_INT" )
        RETURN .F.
    ENDIF

    DbSelectArea( "COM_PF" )
    OrdSetFocus( "COM_INT" )

    IF DbSeek( cNumCom )
        cProv    := PadR( AllTrim( COM_PF->PROV_ID ), 10 )
        nTotal   := COM_PF->TOTAL
        cCtaDebe := PadR( _PagoCtaProveedor( AllTrim( COM_PF->PROV_ID ), @cBenef ), 10 )
    ENDIF

    COM_PF->( DbCloseArea() )

RETURN !Empty( AllTrim( cProv ) )


STATIC FUNCTION _PagoCtaProveedor( cProv, cBenef )

    LOCAL cCta := "400"

    cBenef := Space( 60 )

    IF ABRIR_TABLA( "PROVEED", "PRV_PF", "PRV_ID" )
        IF PRV_PF->( DbSeek( cProv ) )
            cBenef := PadR( AllTrim( PRV_PF->NOMBRE + " " + PRV_PF->APELLIDO ), 60 )
            IF !Empty( AllTrim( PRV_PF->CTA_CONT ) )
                cCta := AllTrim( PRV_PF->CTA_CONT )
            ENDIF
        ENDIF
        PRV_PF->( DbCloseArea() )
    ENDIF

RETURN cCta


STATIC FUNCTION _PagoGuardar( cNumPag, dFecha, cProv, cBenef, cConcepto, ;
    cFormPag, cRef, cBanco, cCtaDebe, cCtaHaber, nTotal, cNumCom )

    LOCAL cUsuario := "SISTEMA"
    LOCAL cAsi

    MEMVAR cUserID

    IF Type( "cUserID" ) == "C" .AND. !Empty( cUserID )
        cUsuario := AllTrim( cUserID )
    ENDIF

    IF !ABRIR_TABLA( "PAGOS", "PAG_G", "PAG_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PAG_G" )
    OrdSetFocus( "PAG_NUM" )

    IF DbSeek( PadR( cNumPag, 10 ) )
        PAG_G->( DbCloseArea() )
        MsgStop( "El pago ya existe.", "Pago" )
        RETURN .F.
    ENDIF

    IF !NetFLock()
        PAG_G->( DbCloseArea() )
        RETURN .F.
    ENDIF

    DbAppend()
    IF !NetRLock()
        DbUnlock()
        PAG_G->( DbCloseArea() )
        RETURN .F.
    ENDIF

    REPLACE PAG_G->NUMERO   WITH PadR( cNumPag, 10 )
    REPLACE PAG_G->FECHA    WITH dFecha
    REPLACE PAG_G->PROV_ID  WITH PadR( cProv, 10 )
    REPLACE PAG_G->BENEFIC  WITH PadR( cBenef, 60 )
    REPLACE PAG_G->CONCEPTO WITH PadR( cConcepto, 100 )
    REPLACE PAG_G->FORMA_PA WITH PadR( cFormPag, 3 )
    REPLACE PAG_G->REFERENC WITH PadR( cRef, 20 )
    REPLACE PAG_G->BANCO    WITH PadR( cBanco, 10 )
    REPLACE PAG_G->CTA_DEBE WITH PadR( cCtaDebe, 10 )
    REPLACE PAG_G->CTA_HABER WITH PadR( cCtaHaber, 10 )
    REPLACE PAG_G->TOTAL    WITH nTotal
    REPLACE PAG_G->ASIENTO  WITH Space( 10 )
    REPLACE PAG_G->DOC_ORIG WITH PadR( cNumCom, 10 )
    REPLACE PAG_G->USUARIO_ WITH PadR( cUsuario, 10 )
    DbCommit()
    DbUnlock()
    PAG_G->( DbCloseArea() )

    _PagoGuardarDetalle( cNumPag, cNumCom, cConcepto, nTotal, cCtaDebe )
    cAsi := _PagoAsiento( cNumPag )

    IF !Empty( cAsi )
        _PagoActualizarAsiento( cNumPag, cAsi )
        IF !Empty( AllTrim( cNumCom ) )
            _PagoMarcarCompra( cNumCom, cFormPag )
        ENDIF
    ENDIF

RETURN !Empty( cAsi )


STATIC FUNCTION _PagoGuardarDetalle( cNumPag, cRefDoc, cConcepto, nTotal, cCtaDebe )

    IF !ABRIR_TABLA( "PAGO_DET", "PGD_G", "PGD_LIN" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PGD_G" )
    IF !NetFLock()
        PGD_G->( DbCloseArea() )
        RETURN .F.
    ENDIF

    DbAppend()
    IF NetRLock()
        REPLACE PGD_G->NUMERO   WITH PadR( cNumPag, 10 )
        REPLACE PGD_G->LINEA    WITH 1
        REPLACE PGD_G->REF_DOC  WITH PadR( cRefDoc, 15 )
        REPLACE PGD_G->CONCEPTO WITH PadR( cConcepto, 60 )
        REPLACE PGD_G->IMPORTE  WITH nTotal
        REPLACE PGD_G->CTA_CONT WITH PadR( cCtaDebe, 10 )
        DbCommit()
        DbUnlock()
    ENDIF

    PGD_G->( DbCloseArea() )

RETURN .T.


STATIC FUNCTION _PagoAsiento( cNumPag )

    LOCAL cAsi
    LOCAL dFec
    LOCAL cCtaDebe
    LOCAL cCtaHaber
    LOCAL nTotal
    LOCAL cConc

    IF !ABRIR_TABLA( "PAGOS", "PAG_AS", "PAG_NUM" )
        RETURN ""
    ENDIF

    DbSelectArea( "PAG_AS" )
    OrdSetFocus( "PAG_NUM" )

    IF !DbSeek( PadR( cNumPag, 10 ) )
        PAG_AS->( DbCloseArea() )
        RETURN ""
    ENDIF

    dFec      := PAG_AS->FECHA
    cCtaDebe  := AllTrim( PAG_AS->CTA_DEBE )
    cCtaHaber := AllTrim( PAG_AS->CTA_HABER )
    nTotal    := PAG_AS->TOTAL
    cConc     := "Pago " + AllTrim( PAG_AS->FORMA_PA ) + " " + ;
                 AllTrim( PAG_AS->REFERENC ) + " / " + AllTrim( PAG_AS->CONCEPTO )

    PAG_AS->( DbCloseArea() )

    cAsi := GetNextNum( "ASI" + AllTrim( Str( Year( dFec ) ) ), "Asientos" )

    IF Empty( cAsi ) .OR. !ABRIR_TABLA( "LDIARIO", "DIA_PN", "DIA_ASI" )
        RETURN ""
    ENDIF

    DbSelectArea( "DIA_PN" )

    IF NetFLock()
        DbAppend()
        REPLACE DIA_PN->D_ASIENT WITH cAsi
        REPLACE DIA_PN->D_LINEA  WITH 1
        REPLACE DIA_PN->D_FECHA  WITH dFec
        REPLACE DIA_PN->D_CUENTA WITH PadR( cCtaDebe, 10 )
        REPLACE DIA_PN->D_DEBE   WITH nTotal
        REPLACE DIA_PN->D_HABER  WITH 0
        REPLACE DIA_PN->D_DESCRI WITH PadR( cConc, 100 )
        REPLACE DIA_PN->TIP_ORIG WITH "PAG"
        REPLACE DIA_PN->DOC_ORIG WITH PadR( cNumPag, 10 )

        DbAppend()
        REPLACE DIA_PN->D_ASIENT WITH cAsi
        REPLACE DIA_PN->D_LINEA  WITH 2
        REPLACE DIA_PN->D_FECHA  WITH dFec
        REPLACE DIA_PN->D_CUENTA WITH PadR( cCtaHaber, 10 )
        REPLACE DIA_PN->D_DEBE   WITH 0
        REPLACE DIA_PN->D_HABER  WITH nTotal
        REPLACE DIA_PN->D_DESCRI WITH PadR( cConc, 100 )
        REPLACE DIA_PN->TIP_ORIG WITH "PAG"
        REPLACE DIA_PN->DOC_ORIG WITH PadR( cNumPag, 10 )

        DbCommit()
        DbUnlock()
    ELSE
        cAsi := ""
    ENDIF

    DIA_PN->( DbCloseArea() )

RETURN cAsi


STATIC FUNCTION _PagoActualizarAsiento( cNumPag, cAsi )

    IF !ABRIR_TABLA( "PAGOS", "PAG_AU", "PAG_NUM" )
        RETURN .F.
    ENDIF

    DbSelectArea( "PAG_AU" )
    OrdSetFocus( "PAG_NUM" )

    IF DbSeek( PadR( cNumPag, 10 ) ) .AND. NetRLock()
        REPLACE PAG_AU->ASIENTO WITH PadR( cAsi, 10 )
        DbCommit()
        DbUnlock()
    ENDIF

    PAG_AU->( DbCloseArea() )

RETURN .T.


STATIC FUNCTION _PagoMarcarCompra( cNumCom, cFormPag )

    IF CompraContabilizada( cNumCom )
        RETURN .T.
    ENDIF

    IF !ABRIR_TABLA( "COMPRAS", "COM_PR", "COM_INT" )
        RETURN .F.
    ENDIF

    DbSelectArea( "COM_PR" )
    OrdSetFocus( "COM_INT" )

    IF DbSeek( cNumCom ) .AND. NetRLock()
        REPLACE COM_PR->PAGADA WITH .T.
        IF FieldPos( "METODO_P" ) > 0
            REPLACE COM_PR->METODO_P WITH PadR( cFormPag, 3 )
        ENDIF
        DbCommit()
        DbUnlock()
    ENDIF

    COM_PR->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _AliasLogical( cAlias, cField, lDefault )

    LOCAL nOldArea
    LOCAL lValue

    nOldArea := Select()
    lValue   := lDefault

    IF Select( cAlias ) > 0
        DbSelectArea( cAlias )
        IF FieldPos( cField ) > 0
            lValue := FieldGet( FieldPos( cField ) )
        ENDIF
    ENDIF

    IF nOldArea > 0
        DbSelectArea( nOldArea )
    ENDIF

RETURN lValue


// ============================================================================
// FIN DE Tesoreria.prg
// ============================================================================
