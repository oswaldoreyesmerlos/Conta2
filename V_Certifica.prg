#include "OOp.ch"

#define LIN_C_NUM   1
#define LIN_C_DESC  2
#define LIN_C_CANT  3
#define LIN_C_PRE   4
#define LIN_C_IMP   5

#define MAX_LINS  50
#define IVA_DEF   21.00

FUNCTION CertificacionesView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtFac
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "CERTIFICA", "CER", "CERT_NUM" )
        RETURN NIL
    ENDIF

    aData := _CertCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "CERTIFICACIONES DE OBRA" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "ID Cert",    12, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Obra",       12, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "Fecha",      10, "@!",         { |a| a[3] } )
    oGrid:AddColumn( "%",           6, "99.99",      { |a| a[4] } )
    oGrid:AddColumn( "Importe",    12, "999,999.99", { |a| a[5] } )
    oGrid:AddColumn( "Base",       12, "999,999.99", { |a| a[6] } )
    oGrid:AddColumn( "IVA",        10, "999,999.99", { |a| a[7] } )
    oGrid:AddColumn( "Estado",      8, "@!",         { |a| a[8] } )
    oGrid:AddColumn( "Factura",    10, "@!",         { |a| a[9] } )

    oGrid:bEnter := {| g | _CertViewDetalle( g:CurrentRow()[1] ), ;
                           aData := _CertCargar(), ;
                           g:aData := aData, ;
                           g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "ENTER: ver detalle   F5: nueva certificacion   F2: facturar desde certificacion", oWin )

    oBtNvo := TButton():New( 33,  2, 34, 22, oWin, "NUEVA (F5)", ;
        {|| _CertAltaForm(), aData := _CertCargar(), oGrid:aData := aData, oGrid:nCurRow := Len( aData ), oGrid:Paint() } )

    oBtFac := TButton():New( 33, 24, 34, 44, oWin, "FACTURAR (F2)", ;
        {|| If( oGrid:CurrentRow() != NIL, ;
                _CertFacturar( oGrid:CurrentRow()[1] ), NIL ), ;
            aData := _CertCargar(), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 33,108, 34,124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLbl   )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtFac )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    CER->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _CertCargar()

    LOCAL aData := {}

    DbSelectArea( "CER" )
    OrdSetFocus( "CERT_NUM" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( CER->ID ), ;
                AllTrim( CER->ID_OBRA ), ;
                DToC(    CER->FECHA ), ;
                CER->PORCENTAJE, ;
                CER->IMPORTE, ;
                CER->BASE, ;
                CER->IVA, ;
                If( CER->ESTADO == "F", "FACTURADA", "PENDIENTE" ), ;
                AllTrim( DbFieldValue( "NUM_FAC", "" ) ) } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _CertSiguiente()

    LOCAL cAnio := StrZero( Year( Date() ), 4 )
    LOCAL cPref := "CER" + cAnio
    LOCAL nMax  := 0
    LOCAL cNum
    LOCAL nSeq

    IF !ABRIR_TABLA( "CERTIFICA", "CER_N", "CERT_NUM" )
        RETURN ""
    ENDIF

    DbSelectArea( "CER_N" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            cNum := AllTrim( CER_N->ID )
            IF Left( cNum, Len( cPref ) ) == cPref
                nSeq := Val( SubStr( cNum, Len( cPref ) + 1, 4 ) )
                IF nSeq > nMax
                    nMax := nSeq
                ENDIF
            ENDIF
        ENDIF
        DbSkip()
    ENDDO

    CER_N->( DbCloseArea() )

RETURN cPref + StrZero( nMax + 1, 4 )


STATIC FUNCTION _CertObraPresupuesto( cIdObra )

    LOCAL cNumPre := ""
    LOCAL nArea   := Select()

    IF !ABRIR_TABLA( "OBRAS", "OBR_CP", "OBR_ID" )
        RETURN ""
    ENDIF

    DbSelectArea( "OBR_CP" )
    OrdSetFocus( "OBR_ID" )

    IF DbSeek( PadR( cIdObra, 12 ) ) .OR. DbSeek( cIdObra )
        cNumPre := AllTrim( DbFieldValue( "NUM_PRE", "" ) )
    ENDIF

    OBR_CP->( DbCloseArea() )
    Select( nArea )

RETURN cNumPre


STATIC FUNCTION _CertCargarLinesObra( cIdObra, aLins )

    LOCAL cNumPre := _CertObraPresupuesto( cIdObra )
    LOCAL nL      := 0
    LOCAL nArea   := Select()
    LOCAL nTotalObra

    IF Empty( cNumPre )
        aLins := {}
        RETURN 0
    ENDIF

    IF !ABRIR_TABLA( "PRESUP_DE", "PRD_CE", "PRD_LIN" )
        Select( nArea )
        RETURN 0
    ENDIF

    nTotalObra := 0
    DbSelectArea( "PRD_CE" )
    OrdSetFocus( "PRD_LIN" )
    DbSeek( PadR( cNumPre, 10 ) + "  1" )

    DO WHILE !Eof() .AND. AllTrim( PRD_CE->NUMERO ) == AllTrim( cNumPre )
        IF !Deleted()
            nL++
            AAdd( aLins, { ;
                nL, ;
                AllTrim( PRD_CE->DESCRIPC ), ;
                PRD_CE->CANTIDAD, ;
                PRD_CE->PRECIO, ;
                PRD_CE->IMPORTE } )
            nTotalObra += PRD_CE->IMPORTE
        ENDIF
        DbSkip()
    ENDDO

    PRD_CE->( DbCloseArea() )
    Select( nArea )

RETURN nTotalObra


STATIC FUNCTION _CertAltaForm()

    LOCAL oWin
    LOCAL hCert := {=>}
    LOCAL oBtGua
    LOCAL oBtCan

    hCert["aLineas"]     := {}
    hCert["cIdObra"]     := Space( 12 )
    hCert["dFecha"]      := Date()
    hCert["nPorcentaje"] := 0.00
    hCert["nTotalObra"]  := 0.00
    hCert["nIvaFijo"]    := IVA_DEF
    hCert["cObs"]        := Space( 80 )
    hCert["lInv"]        := .F.
    hCert["oGrid"]       := NIL

    oWin := TWindow():New( 1, 2, 37, 129, "NUEVA CERTIFICACION" )

    oWin:AddCtrl( TLabel():New(  2,  2, "Obra        :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Fecha       :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 40, "% acumulado :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Total obra  :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 60, "Total certif.:", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  2, "Observ.     :", oWin ) )

    hCert["oLblObra"] := TLabel():New( 2, 16, Space( 60 ), oWin )
    oWin:AddCtrl( hCert["oLblObra"] )

    hCert["oLTotalObra"] := TLabel():New( 6, 16, Space( 16 ), oWin )
    hCert["oLTotalObra"]:cColor := "W+/B"
    oWin:AddCtrl( hCert["oLTotalObra"] )

    hCert["oLTotalCert"] := TLabel():New( 6, 74, Space( 16 ), oWin )
    hCert["oLTotalCert"]:cColor := "W+/B"
    oWin:AddCtrl( hCert["oLTotalCert"] )

    hCert["oGrid"] := TGrid():New( 12, 2, 26, 124, oWin )
    hCert["oGrid"]:aData    := hCert["aLineas"]
    hCert["oGrid"]:nSeekCol := 2
    hCert["oGrid"]:AddColumn( "#",          3, "999",       { |a| a[LIN_C_NUM]  } )
    hCert["oGrid"]:AddColumn( "Descripcion",53, "@!",       { |a| a[LIN_C_DESC] } )
    hCert["oGrid"]:AddColumn( "Cantidad",   8, "9,999.99",  { |a| a[LIN_C_CANT] } )
    hCert["oGrid"]:AddColumn( "Precio",    10, "9,999.99",  { |a| a[LIN_C_PRE]  } )
    hCert["oGrid"]:AddColumn( "Importe",   12, "99,999.99", { |a| a[LIN_C_IMP]  } )

    hCert["oGIdObr"] := TGet():New( 2, 16, hCert["cIdObra"], "@!", oWin )
    oBtBus := TButton():New( 2, 56, 2, 72, oWin, "BUSCAR OBRA", ;
        {|| _CertLookupObra( hCert ) } )

    hCert["oGFec"] := TGet():New( 4, 16, hCert["dFecha"], "99/99/9999", oWin )
    hCert["oGPorc"] := TGet():New( 4, 56, hCert["nPorcentaje"], "99.99", oWin )
    hCert["oGPorc"]:bValid := {| o | _CertCalcPorc( o, hCert ) }
    hCert["oGObs"] := TGet():New( 10, 16, hCert["cObs"], "@S60!", oWin )

    oBtGua := TButton():New( 33,  2, 34, 18, oWin, "GUARDAR", ;
        {|| _CertGuardar( hCert, oWin ) } )

    oBtCan := TButton():New( 33,108, 34,124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( hCert["oGIdObr"] )     // 1er foco
    oWin:AddCtrl( oBtBus  )               // 2o (boton)
    oWin:AddCtrl( hCert["oGFec"]  )       // 3o
    oWin:AddCtrl( hCert["oGPorc"] )       // 4o
    oWin:AddCtrl( hCert["oGObs"]  )       // 5o
    oWin:AddCtrl( hCert["oGrid"] )        // 6o (grid)
    oWin:AddCtrl( oBtGua  )               // 7o
    oWin:AddCtrl( oBtCan  )               // 8o

    oWin:Run()

RETURN NIL


STATIC FUNCTION _CertLookupObra( hCert )

    LOCAL aData := {}
    LOCAL aCombo := {}
    LOCAL i, cId
    LOCAL nArea := Select()

    IF !ABRIR_TABLA( "OBRAS", "OBR_LK", "OBR_ID" )
        Select( nArea )
        RETURN NIL
    ENDIF

    DbSelectArea( "OBR_LK" )
    OrdSetFocus( "OBR_ID" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( OBR_LK->ID ), ;
                AllTrim( OBR_LK->CLIENTE_ ), ;
                AllTrim( OBR_LK->DESCRIP ), ;
                _CertEstadoTexto( DbFieldValue( "ESTADO", "" ) ) } )
        ENDIF
        DbSkip()
    ENDDO

    OBR_LK->( DbCloseArea() )
    Select( nArea )

    IF Empty( aData )
        MsgInfo( "No hay obras registradas.", "Certificacion" )
        RETURN NIL
    ENDIF

    FOR i := 1 TO Len( aData )
        AAdd( aCombo, { i, aData[i, 1] + " - " + aData[i, 3] + " (" + aData[i, 4] + ")" } )
    NEXT

    i := PopupSelect( "SELECCIONAR OBRA", aCombo, ;
                       { { "Obra", 72, "@!", 2 } }, 1 )

    IF i > 0 .AND. i <= Len( aData )
        hCert["oGIdObr"]:SetValue( PadR( aData[i, 1], 12 ) )
        _CertBuscarObra( hCert )
    ENDIF

RETURN NIL


STATIC FUNCTION _CertEstadoTexto( cEstado )

    DO CASE
    CASE cEstado == "A" ; RETURN "Abierta"
    CASE cEstado == "E" ; RETURN "En curso"
    CASE cEstado == "F" ; RETURN "Finalizada"
    CASE cEstado == "C" ; RETURN "Cancelada"
    ENDCASE

RETURN "Sin estado"


STATIC FUNCTION _CertBuscarObra( hCert )

    LOCAL cId  := AllTrim( hCert["oGIdObr"]:GetValue() )
    LOCAL nArea := Select()
    LOCAL cDesc := ""
    LOCAL cNumPre := ""
    LOCAL nIva  := 21.00
    LOCAL lInvObra := .F.

    IF Empty( cId )
        RETURN NIL
    ENDIF

    IF !ABRIR_TABLA( "OBRAS", "OBR_CE", "OBR_ID" )
        Select( nArea )
        RETURN NIL
    ENDIF

    DbSelectArea( "OBR_CE" )
    OrdSetFocus( "OBR_ID" )

    IF !( DbSeek( PadR( cId, 12 ) ) .OR. DbSeek( cId ) )
        OBR_CE->( DbCloseArea() )
        MsgStop( "Obra no encontrada.", "Certificacion" )
        Select( nArea )
        RETURN NIL
    ENDIF

    hCert["cIdObra"] := AllTrim( OBR_CE->ID )
    cDesc   := AllTrim( OBR_CE->DESCRIP )
    cNumPre := AllTrim( DbFieldValue( "NUM_PRE", "" ) )

    OBR_CE->( DbCloseArea() )
    Select( nArea )

    hCert["oLblObra"]:SetText( PadR( hCert["cIdObra"] + " - " + cDesc, 60 ) )

    hCert["aLineas"] := {}
    hCert["nTotalObra"] := _CertCargarLinesObra( hCert["cIdObra"], @hCert["aLineas"] )
    hCert["oLTotalObra"]:SetText( Transform( hCert["nTotalObra"], "999,999.99" ) )

    IF !Empty( cNumPre )
        _CertIvaPresupuesto( cNumPre, @nIva, @lInvObra )
    ENDIF
    hCert["nIvaFijo"] := nIva
    hCert["lInv"]     := lInvObra

    IF hCert["oGrid"] != NIL
        hCert["oGrid"]:aData := hCert["aLineas"]
        hCert["oGrid"]:Paint()
    ENDIF

    IF hCert["oGPorc"] != NIL
        hCert["oGPorc"]:SetValue( 0 )
    ENDIF

RETURN NIL


STATIC FUNCTION _CertIvaPresupuesto( cNumPre, nIva, lInv )

    LOCAL nArea := Select()

    nIva  := 21.00
    lInv  := .F.

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_IV", "PRE_NUM" )
        RETURN NIL
    ENDIF

    DbSelectArea( "PRE_IV" )
    OrdSetFocus( "PRE_NUM" )

    IF DbSeek( PadR( cNumPre, 10 ) ) .OR. DbSeek( cNumPre )
        lInv := DbFieldValue( "INVERSION", .F. )
        nIva := If( lInv, 0.00, 21.00 )
    ENDIF

    PRE_IV->( DbCloseArea() )
    Select( nArea )

RETURN NIL


STATIC FUNCTION _CertCalcPorc( oGet, hCert )

    LOCAL i
    LOCAL nTotalCert := 0
    LOCAL aLins := hCert["aLineas"]

    hCert["nPorcentaje"] := oGet:GetValue()

    IF hCert["nPorcentaje"] <= 0 .OR. hCert["nPorcentaje"] > 100
        MsgStop( "El % debe estar entre 1 y 100.", "Certificacion" )
        RETURN .F.
    ENDIF

    FOR i := 1 TO Len( aLins )
        aLins[i, LIN_C_IMP] := Round( aLins[i, LIN_C_CANT] * aLins[i, LIN_C_PRE] * hCert["nPorcentaje"] / 100, 2 )
        nTotalCert += aLins[i, LIN_C_IMP]
    NEXT

    hCert["oGrid"]:aData := aLins
    hCert["oGrid"]:Paint()
    hCert["oLTotalCert"]:SetText( Transform( nTotalCert, "999,999.99" ) )

    hCert["nPorcentaje"] := oGet:GetValue()

RETURN .T.


STATIC FUNCTION _CertGuardar( hCert, oWin )

    LOCAL cIdCert   := ""
    LOCAL cIdObra   := AllTrim( hCert["oGIdObr"]:GetValue() )
    LOCAL dFecha    := hCert["oGFec"]:GetValue()
    LOCAL nPorc     := hCert["oGPorc"]:GetValue()
    LOCAL cObs      := AllTrim( hCert["oGObs"]:GetValue() )
    LOCAL aLins     := hCert["aLineas"]
    LOCAL nBase     := 0
    LOCAL nIva      := 0
    LOCAL nTotal    := 0
    LOCAL i

    IF Empty( cIdObra )
        MsgStop( "Debe indicar una obra.", "Guardar" )
        RETURN NIL
    ENDIF

    IF Empty( dFecha )
        dFecha := Date()
    ENDIF

    IF nPorc <= 0 .OR. nPorc > 100
        MsgStop( "El % debe estar entre 1 y 100.", "Guardar" )
        RETURN NIL
    ENDIF

    IF Len( aLins ) == 0
        MsgStop( "La obra no tiene lineas de presupuesto para certificar.", "Guardar" )
        RETURN NIL
    ENDIF

    cIdCert := _CertSiguiente()
    IF Empty( cIdCert )
        RETURN NIL
    ENDIF

    FOR i := 1 TO Len( aLins )
        nBase += aLins[i, LIN_C_IMP]
    NEXT
    nIva   := Round( nBase * hCert["nIvaFijo"] / 100, 2 )
    nTotal := nBase + nIva

    IF !_CertDBCrear( cIdCert, cIdObra, dFecha, nPorc, nBase, nIva, hCert["nIvaFijo"], nTotal, cObs )
        RETURN NIL
    ENDIF

    IF !_CertDBCrearLineas( cIdCert, aLins )
        RETURN NIL
    ENDIF

    AuditLog( "ALTA", "CERTIFICA", cIdCert, ;
              "Certificacion " + cIdCert + " obra " + cIdObra, .T. )

    MsgInfo( "Certificacion " + cIdCert + " guardada.", "Guardado" )

    IF MsgYesNo( "Desea emitir la factura ahora?", "Facturar" )
        _CertFacturar( cIdCert )
    ENDIF

    oWin:Close()

RETURN NIL


STATIC FUNCTION _CertDBCrear( cIdCert, cIdObra, dFecha, nPorc, nBase, nIva, nPorcIva, nTotal, cObs )

    LOCAL nArea := Select()

    IF !ABRIR_TABLA( "CERTIFICA", "CER_G", "CERT_NUM" )
        Select( nArea )
        RETURN .F.
    ENDIF

    DbSelectArea( "CER_G" )
    IF !NetFLock()
        CER_G->( DbCloseArea() )
        Select( nArea )
        RETURN .F.
    ENDIF

    DbAppend()
    REPLACE CER_G->ID        WITH PadR( cIdCert, 12 )
    REPLACE CER_G->ID_OBRA   WITH PadR( cIdObra, 12 )
    REPLACE CER_G->FECHA     WITH dFecha
    REPLACE CER_G->PORCENTAJE WITH nPorc
    REPLACE CER_G->IMPORTE   WITH nBase
    REPLACE CER_G->BASE      WITH nBase
    REPLACE CER_G->IVA       WITH nIva
    REPLACE CER_G->PORC_IVA  WITH nPorcIva
    REPLACE CER_G->TOTAL     WITH nTotal
    REPLACE CER_G->ESTADO    WITH "P"
    REPLACE CER_G->NUM_FAC   WITH Space( 10 )
    DbFieldPutIf( "OBSERVA", PadR( cObs, 80 ) )

    DbCommit()
    DbUnlock()
    CER_G->( DbCloseArea() )
    Select( nArea )

RETURN .T.


STATIC FUNCTION _CertDBCrearLineas( cIdCert, aLins )

    LOCAL nArea := Select()
    LOCAL i

    IF !ABRIR_TABLA( "CERTIF_DE", "CDE_G", "CDE_NUM" )
        Select( nArea )
        RETURN .F.
    ENDIF

    DbSelectArea( "CDE_G" )
    IF !NetFLock()
        CDE_G->( DbCloseArea() )
        Select( nArea )
        RETURN .F.
    ENDIF

    FOR i := 1 TO Len( aLins )
        DbAppend()
        REPLACE CDE_G->ID_CERT  WITH PadR( cIdCert, 12 )
        REPLACE CDE_G->LINEA    WITH i
        REPLACE CDE_G->DESCRIPC WITH PadR( aLins[i, LIN_C_DESC], 60 )
        REPLACE CDE_G->CANTIDAD WITH aLins[i, LIN_C_CANT]
        REPLACE CDE_G->PRECIO   WITH aLins[i, LIN_C_PRE]
        REPLACE CDE_G->IMPORTE  WITH aLins[i, LIN_C_IMP]
    NEXT

    DbCommit()
    DbUnlock()
    CDE_G->( DbCloseArea() )
    Select( nArea )

RETURN .T.


STATIC FUNCTION _CertFacturar( cIdCert )

    LOCAL cIdObra  := ""
    LOCAL cCliente := ""
    LOCAL cNumPre  := ""
    LOCAL cDescObra:= ""
    LOCAL nBase    := 0.00
    LOCAL nIva     := 0.00
    LOCAL nPorcIva := 0.00
    LOCAL nTotal   := 0.00
    LOCAL dFecha
    LOCAL cFormaPa := ""
    LOCAL nDias    := 0
    LOCAL dVto
    LOCAL cNumFac  := ""
    LOCAL nArea    := Select()

    IF Empty( AllTrim( cIdCert ) )
        MsgStop( "Seleccione una certificacion.", "Facturar" )
        Select( nArea )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "CERTIFICA", "CER_F", "CERT_NUM" )
        Select( nArea )
        RETURN .F.
    ENDIF

    DbSelectArea( "CER_F" )
    OrdSetFocus( "CERT_NUM" )

    IF !( DbSeek( PadR( AllTrim( cIdCert ), 12 ) ) .OR. DbSeek( AllTrim( cIdCert ) ) )
        CER_F->( DbCloseArea() )
        MsgStop( "Certificacion no encontrada.", "Facturar" )
        Select( nArea )
        RETURN .F.
    ENDIF

    IF CER_F->ESTADO == "F"
        CER_F->( DbCloseArea() )
        MsgStop( "Esta certificacion ya fue facturada." + Chr(13) + ;
                 "Factura: " + AllTrim( CER_F->NUM_FAC ), "Facturar" )
        Select( nArea )
        RETURN .F.
    ENDIF

    cIdObra  := AllTrim( CER_F->ID_OBRA )
    nBase    := CER_F->BASE
    nIva     := CER_F->IVA
    nPorcIva := CER_F->PORC_IVA
    nTotal   := CER_F->TOTAL
    dFecha   := Date()

    CER_F->( DbCloseArea() )
    Select( nArea )

    IF !_ObraLeerCab( cIdObra, @cCliente, @cNumPre, @cDescObra )
        RETURN .F.
    ENDIF

    _ObraFormaPagoCliente( cCliente, @cFormaPa, @nDias )
    dVto := dFecha + nDias

    cNumFac := _ObraSiguienteFactura()
    IF Empty( cNumFac )
        RETURN .F.
    ENDIF

    IF !_ObraCrearFacturaCab( "A", cNumFac, cCliente, dFecha, dVto, ;
                              nBase, nIva, nTotal, cFormaPa, cNumPre, ;
                              cIdObra, "C", "Certificacion " + cIdCert )
        RETURN .F.
    ENDIF

    IF !_ObraCrearFacturaLin( "A", cNumFac, "Certificacion " + cIdCert + " - " + cDescObra, ;
                              nBase, nPorcIva )
        RETURN .F.
    ENDIF

    _ObraGenVencimiento( "A", cNumFac, cCliente, dVto, nTotal, cIdObra )
    _ObraActualizarEstado( cIdObra )

    _CertMarcarFacturada( cIdCert, cNumFac )
    AsientoAutomatico( "CER", cIdCert )

    AuditLog( "FACTURA", "CERTIFICA", cIdCert, ;
              "Factura " + cNumFac + " desde certificacion " + cIdCert, .T. )

    MsgInfo( "Factura " + cNumFac + " emitida desde certificacion " + cIdCert + ".", "Facturar" )

    Select( nArea )

RETURN .T.


STATIC FUNCTION _CertMarcarFacturada( cIdCert, cNumFac )

    LOCAL nArea := Select()

    IF !ABRIR_TABLA( "CERTIFICA", "CER_MF", "CERT_NUM" )
        Select( nArea )
        RETURN .F.
    ENDIF

    DbSelectArea( "CER_MF" )
    OrdSetFocus( "CERT_NUM" )

    IF DbSeek( PadR( AllTrim( cIdCert ), 12 ) ) .AND. NetRLock()
        REPLACE CER_MF->ESTADO  WITH "F"
        REPLACE CER_MF->NUM_FAC WITH PadR( AllTrim( cNumFac ), 10 )
        DbCommit()
        DbUnlock()
    ENDIF

    CER_MF->( DbCloseArea() )
    Select( nArea )

RETURN .T.


STATIC FUNCTION _CertViewDetalle( cIdCert )

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtSal
    LOCAL aData  := {}
    LOCAL aCab   := {}
    LOCAL nArea  := Select()

    IF Empty( AllTrim( cIdCert ) )
        Select( nArea )
        RETURN NIL
    ENDIF

    IF !ABRIR_TABLA( "CERTIFICA", "CER_V", "CERT_NUM" )
        Select( nArea )
        RETURN NIL
    ENDIF

    DbSelectArea( "CER_V" )
    OrdSetFocus( "CERT_NUM" )

    IF !DbSeek( PadR( AllTrim( cIdCert ), 12 ) )
        CER_V->( DbCloseArea() )
        Select( nArea )
        RETURN NIL
    ENDIF

    AAdd( aCab, AllTrim( CER_V->ID ) )
    AAdd( aCab, AllTrim( CER_V->ID_OBRA ) )
    AAdd( aCab, DToC( CER_V->FECHA ) )
    AAdd( aCab, CER_V->PORCENTAJE )
    AAdd( aCab, CER_V->IMPORTE )
    AAdd( aCab, CER_V->BASE )
    AAdd( aCab, CER_V->IVA )
    AAdd( aCab, CER_V->TOTAL )
    AAdd( aCab, If( CER_V->ESTADO == "F", "FACTURADA", "PENDIENTE" ) )
    AAdd( aCab, AllTrim( DbFieldValue( "NUM_FAC", "" ) ) )
    AAdd( aCab, AllTrim( DbFieldValue( "OBSERVA", "" ) ) )

    CER_V->( DbCloseArea() )
    Select( nArea )

    IF !ABRIR_TABLA( "CERTIF_DE", "CDE_V", "CDE_NUM" )
        Select( nArea )
        RETURN NIL
    ENDIF

    DbSelectArea( "CDE_V" )
    OrdSetFocus( "CDE_NUM" )
    DbSeek( PadR( AllTrim( cIdCert ), 12 ) )

    DO WHILE !Eof() .AND. AllTrim( CDE_V->ID_CERT ) == AllTrim( cIdCert )
        IF !Deleted()
            AAdd( aData, { ;
                CDE_V->LINEA, ;
                AllTrim( CDE_V->DESCRIPC ), ;
                CDE_V->CANTIDAD, ;
                CDE_V->PRECIO, ;
                CDE_V->IMPORTE } )
        ENDIF
        DbSkip()
    ENDDO

    CDE_V->( DbCloseArea() )
    Select( nArea )

    oWin := TWindow():New( 3, 8, 35, 122, "DETALLE CERTIFICACION: " + aCab[1] )

    oWin:AddCtrl( TLabel():New(  2,  2, "Obra       : " + aCab[2], oWin ) )
    oWin:AddCtrl( TLabel():New(  3,  2, "Fecha      : " + aCab[3], oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "% acumul.  : " + Transform( aCab[4], "99.99" ), oWin ) )
    oWin:AddCtrl( TLabel():New(  5,  2, "Base       : " + Transform( aCab[6], "999,999.99" ), oWin ) )
    oWin:AddCtrl( TLabel():New(  5, 40, "IVA        : " + Transform( aCab[7], "999,999.99" ), oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Total      : " + Transform( aCab[8], "999,999.99" ), oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 40, "Estado     : " + aCab[9], oWin ) )
    IF !Empty( aCab[10] )
        oWin:AddCtrl( TLabel():New(  7,  2, "Factura    : " + aCab[10], oWin ) )
    ENDIF
    IF !Empty( aCab[11] )
        oWin:AddCtrl( TLabel():New(  8,  2, "Observ.    : " + aCab[11], oWin ) )
    ENDIF

    oGrid := TGrid():New( 10, 2, 28, 110, oWin )
    oGrid:aData    := aData
    oGrid:nSeekCol := 2
    oGrid:AddColumn( "#",          3, "999",       { |a| a[1] } )
    oGrid:AddColumn( "Descripcion",53, "@!",        { |a| a[2] } )
    oGrid:AddColumn( "Cantidad",   8, "9,999.99",  { |a| a[3] } )
    oGrid:AddColumn( "Precio",    10, "9,999.99",  { |a| a[4] } )
    oGrid:AddColumn( "Importe",   12, "99,999.99", { |a| a[5] } )
    oWin:AddCtrl( oGrid )

    oBtSal := TButton():New( 31, 98, 32, 116, oWin, "CERRAR", ;
        {|| oWin:Close() } )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL
