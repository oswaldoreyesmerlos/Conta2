/*
 * ARCHIVO  : V_Imprimir.prg
 * PROPOSITO: Genera HTML de factura o presupuesto y abre el navegador.
 *
 * FUNCIONES PUBLICAS
 * ------------------
 *   ImprimirFactura( cNumero )
 *   ImprimirPresup(  cNumero )
 */

#include "OOp.ch"

// ============================================================================
// ImprimirFactura / ImprimirPresup
// ============================================================================
FUNCTION ImprimirFactura( cNumero )
RETURN _ImpDoc( "F", cNumero )


FUNCTION ImprimirPresup( cNumero )
RETURN _ImpDoc( "P", cNumero )


// ============================================================================
// _ImpDoc
// ============================================================================
STATIC FUNCTION _ImpDoc( cTipo, cNumero )

    LOCAL aEmp
    LOCAL aCab
    LOCAL aLins
    LOCAL cHtml
    LOCAL cFile
    LOCAL cTitDoc

    aEmp  := _ImpCargarEmp()
    aCab  := _ImpCargarCab( cTipo, cNumero )
    aLins := _ImpCargarLins( cTipo, cNumero )

    IF aEmp == NIL .OR. aCab == NIL
        MsgStop( "No se pudieron cargar los datos del documento.", "Imprimir" )
        RETURN NIL
    ENDIF

    cTitDoc := If( cTipo == "F", "FACTURA", "PRESUPUESTO" )
    cHtml   := _ImpGenHTML( cTitDoc, aEmp, aCab, aLins )
    cFile   := hb_DirTemp() + "doc_" + AllTrim( cNumero ) + ".html"

    hb_MemoWrit( cFile, cHtml )

    OS_OPEN( cFile )

RETURN NIL


// ============================================================================
// _ImpCargarEmp
// ============================================================================
STATIC FUNCTION _ImpCargarEmp()

    LOCAL aE

    aE := {}

    IF !ABRIR_TABLA( "EMPRESA", "EMP_I", "" )
        RETURN NIL
    ENDIF

    EMP_I->( DbGoTop() )

    IF EMP_I->( Eof() )
        EMP_I->( DbCloseArea() )
        RETURN NIL
    ENDIF

    AAdd( aE, AllTrim( EMP_I->NIF      ) )
    AAdd( aE, AllTrim( EMP_I->NOMBRE   ) )
    AAdd( aE, AllTrim( EMP_I->DIRECCIO ) )
    AAdd( aE, AllTrim( EMP_I->CIUDAD   ) )
    AAdd( aE, AllTrim( EMP_I->CP       ) )
    AAdd( aE, AllTrim( EMP_I->PROVINCI ) )
    AAdd( aE, AllTrim( EMP_I->TELEFONO ) )
    AAdd( aE, AllTrim( EMP_I->MOVIL    ) )
    AAdd( aE, AllTrim( EMP_I->EMAIL    ) )
    AAdd( aE, AllTrim( EMP_I->WEB      ) )
    AAdd( aE, AllTrim( EMP_I->IBANPPAL ) )
    AAdd( aE, AllTrim( EMP_I->LOGO     ) )
    AAdd( aE, EMP_I->PIE_DOC            )
    AAdd( aE, AllTrim( EMP_I->REG_TOMO ) )
    AAdd( aE, AllTrim( EMP_I->REG_FOL  ) )

    EMP_I->( DbCloseArea() )

RETURN aE


// ============================================================================
// _ImpCargarCab
// ============================================================================
STATIC FUNCTION _ImpCargarCab( cTipo, cNum )

    LOCAL aC
    LOCAL cCli
    LOCAL cAlias

    aC    := {}
    cCli  := ""
    cAlias := ""

    IF cTipo == "F"
        cAlias := "FAC_I"
        IF !ABRIR_TABLA( "FACTURA", cAlias, "FAC_NUM" )
            RETURN NIL
        ENDIF
        DbSelectArea( cAlias )
        OrdSetFocus( "FAC_NUM" )
        IF !DbSeek( PadR( "A", 4 ) + PadR( AllTrim( cNum ), 10 ) )
            DbCloseArea()
            RETURN NIL
        ENDIF
        AAdd( aC, AllTrim( FAC_I->NUMERO   ) )
        AAdd( aC, DToC(    FAC_I->FECHA    ) )
        AAdd( aC, AllTrim( FAC_I->CLIENTE_ ) )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, FAC_I->SUBTOTAL )
        AAdd( aC, FAC_I->IVA      )
        AAdd( aC, FAC_I->RETENCIO )
        AAdd( aC, FAC_I->PORC_RET )
        AAdd( aC, FAC_I->TOTAL    )
        AAdd( aC, AllTrim( FAC_I->FORMA_PA ) )
        AAdd( aC, AllTrim( FAC_I->OBSERVA  ) )
        AAdd( aC, ""  )
        cCli := aC[3]
        DbSelectArea( cAlias )
        DbCloseArea()
    ELSE
        cAlias := "PRE_I"
        IF !ABRIR_TABLA( "PRESUPUEST", cAlias, "PRE_NUM" )
            RETURN NIL
        ENDIF
        DbSelectArea( cAlias )
        OrdSetFocus( "PRE_NUM" )
        IF !( DbSeek( PadR( AllTrim( cNum ), 10 ) ) .OR. DbSeek( AllTrim( cNum ) ) )
            DbCloseArea()
            RETURN NIL
        ENDIF
        AAdd( aC, AllTrim( PRE_I->NUMERO   ) )
        AAdd( aC, DToC(    PRE_I->FECHA    ) )
        AAdd( aC, AllTrim( PRE_I->CLIENTE_ ) )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, ""  )
        AAdd( aC, PRE_I->SUBTOTAL )
        AAdd( aC, PRE_I->IVA      )
        AAdd( aC, PRE_I->RETENCIO )
        AAdd( aC, PRE_I->PORC_RET )
        AAdd( aC, PRE_I->TOTAL    )
        AAdd( aC, AllTrim( DbFieldValue( "FORMA_PA", "" ) ) )
        AAdd( aC, AllTrim( PRE_I->OBSERVA  ) )
        AAdd( aC, DToC( PRE_I->VALIDEZ ) )
        cCli := aC[3]
        DbSelectArea( cAlias )
        DbCloseArea()
    ENDIF

    IF !Empty( cCli ) .AND. ABRIR_TABLA( "CLIENTES", "CLI_I", "CLI_ID" )
        IF CLI_I->( DbSeek( cCli ) )
            aC[4]  := AllTrim( CLI_I->NOMBRE + " " + CLI_I->APELLIDO )
            aC[5]  := AllTrim( CLI_I->NIF      )
            aC[6]  := AllTrim( CLI_I->DIRECCIO )
            aC[7]  := AllTrim( CLI_I->CIUDAD   )
            aC[8]  := AllTrim( CLI_I->CP       )
            aC[9]  := AllTrim( CLI_I->TELEFONO )
            aC[10] := AllTrim( CLI_I->EMAIL    )
        ENDIF
        CLI_I->( DbCloseArea() )
    ENDIF

RETURN aC


// ============================================================================
// _ImpCargarLins
// ============================================================================
STATIC FUNCTION _ImpCargarLins( cTipo, cNum )

    LOCAL aL
    LOCAL nL
    LOCAL cAlias
    LOCAL cTag

    aL    := {}
    nL    := 0
    cAlias := ""
    cTag   := ""

    IF cTipo == "F"
        cAlias := "FAC_DI"
        cTag   := "FAC_LIN"
        IF !ABRIR_TABLA( "FACTUR_DE", cAlias, cTag )
            RETURN aL
        ENDIF
        DbSelectArea( cAlias )
        OrdSetFocus( cTag )
        DbSeek( PadR( "A", 4 ) + PadR( cNum, 10 ) )
        DO WHILE !Eof() .AND. AllTrim( FAC_DI->NUMERO ) == AllTrim( cNum )
            IF !Deleted()
                nL++
                AAdd( aL, { nL, AllTrim( FAC_DI->DESCRIPC ), ;
                    FAC_DI->CANTIDAD, FAC_DI->PRECIO, ;
                    FAC_DI->DESCUENT, FAC_DI->PORC_IVA, ;
                    FAC_DI->IMPORTE } )
            ENDIF
            DbSkip()
        ENDDO
        DbSelectArea( cAlias )
        DbCloseArea()
    ELSE
        cAlias := "PRD_I"
        cTag   := "PRD_LIN"
        IF !ABRIR_TABLA( "PRESUP_DE", cAlias, cTag )
            RETURN aL
        ENDIF
        DbSelectArea( cAlias )
        OrdSetFocus( cTag )
        DbSeek( PadR( cNum, 10 ) + "  1" )
        DO WHILE !Eof() .AND. AllTrim( PRD_I->NUMERO ) == AllTrim( cNum )
            IF !Deleted()
                nL++
                AAdd( aL, { nL, AllTrim( PRD_I->DESCRIPC ), ;
                    PRD_I->CANTIDAD, PRD_I->PRECIO, ;
                    PRD_I->DESCUENT, PRD_I->PORC_IVA, ;
                    PRD_I->IMPORTE } )
            ENDIF
            DbSkip()
        ENDDO
        DbSelectArea( cAlias )
        DbCloseArea()
    ENDIF

RETURN aL


// ============================================================================
// _ImpGenHTML
// ============================================================================
STATIC FUNCTION _ImpGenHTML( cTitDoc, aEmp, aCab, aLins )

    LOCAL cH
    LOCAL i
    LOCAL cLogo
    LOCAL nIva21
    LOCAL nIva10
    LOCAL nIva4
    LOCAL nPorcIva
    LOCAL cPie
    LOCAL cConcepto
    LOCAL cMetaTotal
    LOCAL cTipoDesc

    cH     := ""
    cLogo  := ""
    nIva21 := 0
    nIva10 := 0
    nIva4  := 0

    FOR i := 1 TO Len( aLins )
        nPorcIva := aLins[i, 6]
        DO CASE
        CASE nPorcIva == 21 ; nIva21 += aLins[i, 7] * 21 / 100
        CASE nPorcIva == 10 ; nIva10 += aLins[i, 7] * 10 / 100
        CASE nPorcIva == 4  ; nIva4  += aLins[i, 7] *  4 / 100
        ENDCASE
    NEXT

    IF !Empty( aEmp[12] ) .AND. File( aEmp[12] )
        cLogo := '<img src="' + aEmp[12] + '" style="max-height:80px;max-width:200px;">'
    ENDIF

    cPie := AllTrim( aEmp[13] )
    IF Empty( cPie ) .AND. cTitDoc == "PRESUPUESTO"
        cPie := _ImpCondicionesPresup()
    ENDIF
    cPie := _HtmlLines( cPie )

    cConcepto := AllTrim( aCab[17] )
    IF Empty( cConcepto )
        cConcepto := If( cTitDoc == "PRESUPUESTO", "Servicio de construccion", ;
                         "Servicio facturado" )
    ENDIF

    cMetaTotal := If( cTitDoc == "PRESUPUESTO", "Precio total:", "Total:" )
    cTipoDesc  := If( cTitDoc == "PRESUPUESTO", ;
                      "DESCRIPCI&Oacute;N DE LA REFORMA Y PRESUPUESTO:", ;
                      "DESCRIPCI&Oacute;N DEL SERVICIO FACTURADO:" )

    cH += '<!DOCTYPE html>' + Chr(10)
    cH += '<html lang="es"><head><meta charset="UTF-8">' + Chr(10)
    cH += '<title>' + cTitDoc + ' ' + aCab[1] + '</title>' + Chr(10)
    cH += '<style>' + Chr(10)
    cH += '* { box-sizing:border-box; margin:0; padding:0; font-family:Arial,sans-serif; font-size:10px; }' + Chr(10)
    cH += 'body { padding:10mm; background:#fff; color:#111; }' + Chr(10)
    cH += '@page { size:A4; margin:10mm; }' + Chr(10)
    cH += '@media print { body { padding:0; } .noprint { display:none; } .hoja { border:1px solid #000; } }' + Chr(10)
    cH += '.hoja { min-height:277mm; border:1px solid #000; padding:8px 10px 12px; }' + Chr(10)
    cH += '.top { display:grid; grid-template-columns:150px 1fr 170px; align-items:start; min-height:100px; }' + Chr(10)
    cH += '.logo { padding:6px 0 0 10px; min-height:90px; }' + Chr(10)
    cH += '.logo img { max-height:88px; max-width:135px; }' + Chr(10)
    cH += '.titulo { font-family:Georgia,serif; font-style:italic; font-size:28px; font-weight:bold; color:#c00; text-align:center; letter-spacing:1px; padding-top:4px; }' + Chr(10)
    cH += '.cab-info { margin-top:58px; text-align:right; line-height:1.35; }' + Chr(10)
    cH += '.cab-info span { display:inline-block; min-width:72px; font-weight:bold; background:#cfe8ff; padding:1px 4px; }' + Chr(10)
    cH += '.dos-col { display:grid; grid-template-columns:1fr 1fr; gap:46px; margin-bottom:18px; }' + Chr(10)
    cH += '.col h3 { background:#000; color:#fff; text-align:center; font-size:13px; font-style:italic; padding:3px 6px; margin-bottom:12px; }' + Chr(10)
    cH += '.col p { margin:2px 0; min-height:13px; }' + Chr(10)
    cH += '.concepto { font-weight:bold; padding:0 0 2px 28px; }' + Chr(10)
    cH += 'table { width:100%; border-collapse:collapse; }' + Chr(10)
    cH += 'thead tr { background:#222; color:#fff; }' + Chr(10)
    cH += 'thead th { padding:2px 5px; text-align:left; border-right:1px solid #777; }' + Chr(10)
    cH += 'thead th.r { text-align:right; }' + Chr(10)
    cH += 'tbody tr td { padding:3px 5px; border-right:1px solid #777; vertical-align:top; }' + Chr(10)
    cH += 'tbody tr td.r { text-align:right; }' + Chr(10)
    cH += 'tbody tr td.c { text-align:center; }' + Chr(10)
    cH += '.lineas { border:1px solid #777; border-bottom:0; }' + Chr(10)
    cH += '.lineas tbody { height:145px; }' + Chr(10)
    cH += '.firma-total { display:grid; grid-template-columns:1fr 215px; border:1px solid #777; border-top:0; min-height:70px; }' + Chr(10)
    cH += '.firma-empresa { padding:10px 4px; border-right:1px solid #777; line-height:1.35; }' + Chr(10)
    cH += '.totales { width:100%; }' + Chr(10)
    cH += '.totales tr td { padding:3px 8px; }' + Chr(10)
    cH += '.totales tr td:first-child { text-align:right; font-weight:bold; }' + Chr(10)
    cH += '.totales tr td:last-child { text-align:right; border-left:1px solid #777; }' + Chr(10)
    cH += '.total-final td { font-weight:bold; font-size:11px; }' + Chr(10)
    cH += '.pie { margin-top:10px; padding:0 0 0 2px; line-height:1.25; }' + Chr(10)
    cH += '.pie h3 { font-size:12px; margin-bottom:10px; }' + Chr(10)
    cH += '.pie p { margin:0 0 10px 12px; }' + Chr(10)
    cH += '.btnprint { display:block; margin:10px auto; padding:8px 30px; background:#c00; color:#fff; border:none; font-size:14px; cursor:pointer; border-radius:4px; }' + Chr(10)
    cH += '</style></head><body>' + Chr(10)

    cH += '<button class="btnprint noprint" onclick="window.print()">&#128424; Imprimir / Guardar PDF</button>' + Chr(10)

    cH += '<div class="hoja">' + Chr(10)
    cH += '<div class="top">' + Chr(10)
    cH += '<div class="logo">'
    IF !Empty( cLogo )
        cH += cLogo
    ENDIF
    cH += '</div>' + Chr(10)
    cH += '<div class="titulo">' + cTitDoc + '</div>' + Chr(10)
    cH += '<div class="cab-info">'
    cH += '<b>Fecha:</b> <span>' + aCab[2] + '</span><br>'
    cH += '<b>' + cMetaTotal + '</b> <span>' + _FmtH( aCab[15] ) + ' &euro;</span><br>'
    cH += '<b>N&ordm;:</b> <span>' + aCab[1] + '</span>'
    IF !Empty( aCab[18] )
        cH += '<br><b>Validez:</b> <span>' + aCab[18] + '</span>'
    ENDIF
    cH += '</div>' + Chr(10)
    cH += '</div>' + Chr(10)

    cH += '<div class="dos-col">' + Chr(10)

    cH += '<div class="col"><h3>EMPRESA</h3>'
    cH += '<p><b>Denominaci&oacute;n social:</b> ' + _Esc( aEmp[2] ) + '</p>'
    cH += '<p><b>Contacto:</b> </p>'
    cH += '<p><b>NIF/CIF:</b> '              + _Esc( aEmp[1] ) + '</p>'
    cH += '<p><b>Direcci&oacute;n:</b> '     + _Esc( aEmp[3] ) + '</p>'
    cH += '<p>' + _Esc( aEmp[5] ) + ' ' + _Esc( aEmp[4] ) + ' ' + _Esc( aEmp[6] ) + '</p>'
    IF !Empty( aEmp[7] )
        cH += '<p><b>Tel&eacute;fono:</b> '  + _Esc( aEmp[7] ) + '</p>'
    ENDIF
    IF !Empty( aEmp[8] )
        cH += '<p><b>M&oacute;vil:</b> '     + _Esc( aEmp[8] ) + '</p>'
    ENDIF
    IF !Empty( aEmp[9] )
        cH += '<p><b>Email:</b> '            + _Esc( aEmp[9] ) + '</p>'
    ENDIF
    cH += '</div>' + Chr(10)

    cH += '<div class="col"><h3>CLIENTE</h3>'
    cH += '<p><b>Nombre:</b> '           + _Esc( aCab[4] ) + '</p>'
    cH += '<p><b>Denominaci&oacute;n social:</b> </p>'
    cH += '<p><b>NIF/CIF:</b> '          + _Esc( aCab[5] ) + '</p>'
    cH += '<p><b>Direcci&oacute;n:</b> ' + _Esc( aCab[6] ) + '</p>'
    cH += '<p>' + _Esc( aCab[8] ) + ' ' + _Esc( aCab[7] ) + '</p>'
    IF !Empty( aCab[9] )
        cH += '<p><b>Tel&eacute;fono:</b> ' + _Esc( aCab[9]  ) + '</p>'
    ENDIF
    IF !Empty( aCab[10] )
        cH += '<p><b>Email:</b> '           + _Esc( aCab[10] ) + '</p>'
    ENDIF
    cH += '</div>' + Chr(10)

    cH += '</div>' + Chr(10)

    cH += '<div class="concepto">' + cTipoDesc + ' ' + _Esc( cConcepto ) + '</div>' + Chr(10)

    cH += '<table class="lineas">' + Chr(10)
    cH += '<thead><tr>'
    cH += '<th style="width:40px;" class="c">ID</th>'
    cH += '<th>DESCRIPCI&Oacute;N</th>'
    cH += '<th class="r" style="width:70px;">CANTIDAD</th>'
    cH += '<th class="r" style="width:90px;">PRECIO</th>'
    cH += '<th class="r" style="width:100px;">TOTAL</th>'
    cH += '</tr></thead><tbody>' + Chr(10)

    FOR i := 1 TO Len( aLins )
        cH += '<tr>'
        cH += '<td class="c">' + AllTrim( Str( aLins[i,1] ) ) + '</td>'
        cH += '<td>' + _Esc( aLins[i,2] ) + '</td>'
        cH += '<td class="r">' + _FmtH( aLins[i,3] ) + '</td>'
        cH += '<td class="r">' + _FmtH( aLins[i,4] ) + ' &euro;</td>'
        cH += '<td class="r">' + _FmtH( aLins[i,7] ) + ' &euro;</td>'
        cH += '</tr>' + Chr(10)
    NEXT

    FOR i := Len( aLins ) + 1 TO 7
        cH += '<tr><td class="c">&nbsp;</td><td>&nbsp;</td><td></td><td></td><td></td></tr>' + Chr(10)
    NEXT

    cH += '</tbody></table>' + Chr(10)

    cH += '<div class="firma-total">' + Chr(10)
    cH += '<div class="firma-empresa"><b>FIRMA EMPRESA</b><br>'
    cH += '<b>Firma y sello:</b><br>'
    cH += '<b>Lugar y fecha:</b></div>' + Chr(10)

    cH += '<table class="totales">'
    cH += '<tr><td>SUBTOTAL</td><td>' + _FmtH( aCab[11] ) + ' &euro;</td></tr>'

    IF nIva21 > 0
        cH += '<tr><td>IVA 21%</td><td>' + _FmtH( nIva21 ) + ' &euro;</td></tr>'
    ENDIF
    IF nIva10 > 0
        cH += '<tr><td>IVA 10%</td><td>' + _FmtH( nIva10 ) + ' &euro;</td></tr>'
    ENDIF
    IF nIva4 > 0
        cH += '<tr><td>IVA 4%</td><td>'  + _FmtH( nIva4  ) + ' &euro;</td></tr>'
    ENDIF
    IF aCab[14] > 0
        cH += '<tr><td>RETENCI&Oacute;N ' + AllTrim( Str( aCab[14], 5, 2 ) ) + '%</td>'
        cH += '<td>- ' + _FmtH( aCab[13] ) + ' &euro;</td></tr>'
    ENDIF

    cH += '<tr class="total-final"><td>TOTAL</td><td>' + _FmtH( aCab[15] ) + ' &euro;</td></tr>'
    cH += '</table>' + Chr(10)
    cH += '</div>' + Chr(10)

    IF !Empty( cPie )
        cH += '<div class="pie"><h3>CONDICIONES GENERALES Y FORMA DE PAGO</h3>' + cPie + '</div>' + Chr(10)
    ENDIF

    cH += '</div>' + Chr(10)
    cH += '</body></html>' + Chr(10)

RETURN cH


// ============================================================================
// AUXILIARES
// ============================================================================

STATIC FUNCTION _Esc( cTxt )

    IF ValType( cTxt ) != "C"
        RETURN ""
    ENDIF

    cTxt := StrTran( cTxt, "&",  "&amp;"  )
    cTxt := StrTran( cTxt, "<",  "&lt;"   )
    cTxt := StrTran( cTxt, ">",  "&gt;"   )
    cTxt := StrTran( cTxt, '"',  "&quot;" )

RETURN cTxt


STATIC FUNCTION _HtmlLines( cTxt )

    IF ValType( cTxt ) != "C"
        RETURN ""
    ENDIF

    cTxt := _Esc( cTxt )
    cTxt := StrTran( cTxt, Chr(13)+Chr(10), "<br>" )
    cTxt := StrTran( cTxt, Chr(10), "<br>" )
    cTxt := StrTran( cTxt, "<br><br>", "</p><p>" )

    IF !Empty( cTxt )
        cTxt := "<p>" + cTxt + "</p>"
    ENDIF

RETURN cTxt


STATIC FUNCTION _ImpCondicionesPresup()

    LOCAL cTxt

    cTxt := "1. Validez. La firma de este presupuesto supone la aceptacion de las condiciones descritas. "
    cTxt += "Oferta valida durante 15 dias." + Chr(13) + Chr(10) + Chr(13) + Chr(10)
    cTxt += "2. Forma de Pago: 50% a la firma/aceptacion para reserva de fecha y materiales. "
    cTxt += "50% a la finalizacion de los trabajos o mediante certificaciones segun avance." + Chr(13) + Chr(10) + Chr(13) + Chr(10)
    cTxt += "3. Extras: Cualquier trabajo no especificado en la descripcion anterior se facturara aparte como partida adicional." + Chr(13) + Chr(10) + Chr(13) + Chr(10)
    cTxt += "4. Exclusiones: No se incluyen tasas municipales, licencias de obra, pintura ni limpieza final de obra salvo indicacion expresa." + Chr(13) + Chr(10) + Chr(13) + Chr(10)
    cTxt += "5. Fiscalidad: Operacion con inversion del sujeto pasivo conforme al Art. 84.1.2.f de la Ley 37/1992 del IVA. "
    cTxt += "El sujeto pasivo del impuesto es el destinatario de la operacion."

RETURN cTxt


STATIC FUNCTION _FmtH( nVal )

    LOCAL cStr
    LOCAL nPos
    LOCAL cDec
    LOCAL cEnt
    LOCAL cRes
    LOCAL nLen
    LOCAL nMod
    LOCAL j

    IF ValType( nVal ) != "N"
        RETURN "0,00"
    ENDIF

    cStr := AllTrim( Str( nVal, 12, 2 ) )
    nPos := At( ".", cStr )
    cDec := ""
    cEnt := cStr

    IF nPos > 0
        cDec := SubStr( cStr, nPos )
        cEnt := Left( cStr, nPos - 1 )
    ENDIF

    cRes := ""
    nLen := Len( cEnt )
    nMod := nLen % 3

    FOR j := 1 TO nLen
        IF j > 1 .AND. ( j - nMod - 1 ) % 3 == 0 .AND. j <= nLen
            cRes += "."
        ENDIF
        cRes += SubStr( cEnt, j, 1 )
    NEXT

    cDec := StrTran( cDec, ".", "," )

RETURN cRes + cDec


// ============================================================================
// OS_Open( cFile )
// Abre un archivo con la aplicacion predeterminada de Windows
// ============================================================================
FUNCTION OS_Open( cFile )

    IF !File( cFile )
        MsgStop( "Archivo no encontrado: " + cFile, "Error" )
        RETURN .F.
    ENDIF

    // Usa la funcion de Harbour para ejecutar comandos
    HB_Run( 'cmd /c start "" "' + cFile + '"' )

RETURN .T.


// ============================================================================
// FIN DE V_Imprimir.prg
// ============================================================================
