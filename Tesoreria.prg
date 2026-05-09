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


STATIC FUNCTION _RecForm()

    MsgInfo( "Alta de recibos de caja disponible en proxima version.", "Caja" )

RETURN NIL


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
    _RecForm()

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

    LOCAL oWin
    LOCAL oGFec
    LOCAL oGFP
    LOCAL oGRef
    LOCAL oBtOk
    LOCAL oBtCan
    LOCAL lOK
    LOCAL dFec
    LOCAL cFormPag
    LOCAL cRef

    lOK      := .F.
    dFec     := Date()
    cFormPag := Space(  3 )
    cRef     := Space( 20 )

    IF !MsgYesNo( "Registrar pago de " + Transform( nImporte, "999,999.99" ) + ;
                  " EUR para compra " + AllTrim( cNumCom ) + "?", "Pago" )
        RETURN NIL
    ENDIF

    oWin := TWindow():New( 10, 35, 24, 105, "DATOS DEL PAGO" )

    oWin:AddCtrl( TLabel():New( 2, 3, "Fecha pago  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 4, 3, "Forma pago  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 6, 3, "Referencia  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 2,40, "Importe     :", oWin ) )
    oWin:AddCtrl( TLabel():New( 2,54, Transform( nImporte, "999,999.99" ) + " EUR", oWin ) )

    oGFec := TGet():New( 2, 17, dFec,     "99/99/9999", oWin )
    oGFP  := TGet():New( 4, 17, cFormPag, "@!",         oWin )
    oGRef := TGet():New( 6, 17, cRef,     "@!",         oWin )

    oBtOk  := TButton():New( 9, 10, 10, 28, oWin, "CONFIRMAR PAGO", ;
        {|| lOK := .T., oWin:Close() } )

    oBtCan := TButton():New( 9, 32, 10, 48, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGFec  )
    oWin:AddCtrl( oGFP   )
    oWin:AddCtrl( oGRef  )
    oWin:AddCtrl( oBtOk  )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF !lOK
        RETURN NIL
    ENDIF

    // Marcar compra como pagada
    IF ABRIR_TABLA( "COMPRAS", "COM_PR", "COM_INT" )
        DbSelectArea( "COM_PR" )
        OrdSetFocus( "COM_INT" )
        IF DbSeek( cNumCom ) .AND. NetRLock()
            REPLACE COM_PR->PAGADA   WITH .T.
            IF FieldPos( "METODO_P" ) > 0
                REPLACE COM_PR->METODO_P WITH AllTrim( oGFP:uVar )
            ENDIF
            DbUnlock()
        ENDIF
        COM_PR->( DbCloseArea() )
    ENDIF

    // Generar asiento contable del pago
    AsientoAutomatico( "PAG", cNumCom )

    MsgInfo( "Pago registrado correctamente.", "Pago" )

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
