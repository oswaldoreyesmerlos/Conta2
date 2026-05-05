/*
 * ARCHIVO  : M_Clientes.prg
 * PROPOSITO: Mantenimiento completo del fichero de clientes.
 */

#include "OOp.ch"


// ============================================================================
// ClientesView()
// ============================================================================
FUNCTION ClientesView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "CLIENTES", "CLI", "CLI_NOM" )
        RETURN NIL
    ENDIF

    aData := _CliCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "FICHERO DE CLIENTES" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Codigo",      10, "@!", { |a| a[1] } )
    oGrid:AddColumn( "Nombre / Razon Social", 35, "@!", { |a| a[2] } )
    oGrid:AddColumn( "NIF",         13, "@!", { |a| a[3] } )
    oGrid:AddColumn( "Ciudad",      20, "@!", { |a| a[4] } )
    oGrid:AddColumn( "Telefono",    12, "@!", { |a| a[5] } )
    oGrid:AddColumn( "Forma Pago",   3, "@!", { |a| a[6] } )
    oGrid:AddColumn( "Cta.Cont.",   10, "@!", { |a| a[7] } )
    oGrid:AddColumn( "Baja",         4, "@!", { |a| If( a[8], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        ClientesForm( .F., g:CurrentRow()[1] ), ;
        aData := _CliCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "Letras: busqueda por nombre. ENTER: editar. F5: nuevo.", oWin )

    oBtNvo := TButton():New( 33, 2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| ClientesForm( .T., "" ), ;
            aData := _CliCargar(), ;
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

    CLI->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _CliCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "CLI" )
    OrdSetFocus( "CLI_NOM" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( CLI->ID       ), ;
                AllTrim( CLI->NOMBRE + " " + CLI->APELLIDO ), ;
                AllTrim( CLI->NIF      ), ;
                AllTrim( CLI->CIUDAD   ), ;
                AllTrim( CLI->TELEFONO ), ;
                AllTrim( CLI->FORPAGO  ), ;
                AllTrim( CLI->CTA_CONT ), ;
                CLI->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


// ============================================================================
// ClientesForm()
// ============================================================================
FUNCTION ClientesForm( lNuevo, cId )

    LOCAL oWin
    LOCAL nArea
    LOCAL cId_
    LOCAL cNif
    LOCAL cNombre
    LOCAL cApell
    LOCAL cDir
    LOCAL cCiudad
    LOCAL cProvin
    LOCAL cPais
    LOCAL cCP
    LOCAL cTelef
    LOCAL cMovil
    LOCAL cEmail
    LOCAL cWeb
    LOCAL cIban
    LOCAL cForPag
    LOCAL nDias
    LOCAL nLimite
    LOCAL nTarifa
    LOCAL nDesc
    LOCAL lAplRe
    LOCAL lAplIrf
    LOCAL cTipCli
    LOCAL lLopd
    LOCAL lMail
    LOCAL cCtaCon
    LOCAL cCtaAnt
    LOCAL lBaja
    LOCAL oGId
    LOCAL oGNif
    LOCAL oGNom
    LOCAL oGApe
    LOCAL oGDir
    LOCAL oGCiu
    LOCAL oGPro
    LOCAL oGPais
    LOCAL oGCP
    LOCAL oGTel
    LOCAL oGMov
    LOCAL oGMail
    LOCAL oGWeb
    LOCAL oGIban
    LOCAL oGFP
    LOCAL oGDias
    LOCAL oGLim
    LOCAL oGTar
    LOCAL oGDesc
    LOCAL oGCtaCon
    LOCAL oGCtaAnt
    LOCAL oChkRe
    LOCAL oChkIrf
    LOCAL oChkLopd
    LOCAL oChkMail
    LOCAL oChkBaja
    LOCAL oBtGua
    LOCAL oBtCan

    DEFAULT lNuevo TO .T.
    DEFAULT cId    TO ""

    nArea    := Select()
    cId_     := Space( 10 )
    cNif     := Space( 13 )
    cNombre  := Space( 30 )
    cApell   := Space( 30 )
    cDir     := Space( 50 )
    cCiudad  := Space( 40 )
    cProvin  := Space( 30 )
    cPais    := Space( 40 )
    cCP      := Space(  5 )
    cTelef   := Space( 12 )
    cMovil   := Space( 12 )
    cEmail   := Space( 50 )
    cWeb     := Space( 50 )
    cIban    := Space( 34 )
    cForPag  := Space(  3 )
    nDias    := 0
    nLimite  := 0.00
    nTarifa  := 1
    nDesc    := 0.00
    lAplRe   := .F.
    lAplIrf  := .F.
    cTipCli  := Space(  1 )
    lLopd    := .F.
    lMail    := .F.
    cCtaCon  := Space( 10 )
    cCtaAnt  := Space( 10 )
    lBaja    := .F.

    IF !ABRIR_TABLA( "CLIENTES", "CLI", "CLI_ID" )
        RETURN NIL
    ENDIF

    IF !lNuevo .AND. !Empty( AllTrim( cId ) )
        DbSelectArea( "CLI" )
        OrdSetFocus( "CLI_ID" )
        IF DbSeek( AllTrim( cId ) )
            cId_    := PadR( AllTrim( CLI->ID       ), 10 )
            cNif    := PadR( AllTrim( CLI->NIF      ), 13 )
            cNombre := PadR( AllTrim( CLI->NOMBRE   ), 30 )
            cApell  := PadR( AllTrim( CLI->APELLIDO ), 30 )
            cDir    := PadR( AllTrim( CLI->DIRECCIO ), 50 )
            cCiudad := PadR( AllTrim( CLI->CIUDAD   ), 40 )
            cProvin := PadR( AllTrim( CLI->PROVINCI ), 30 )
            cPais   := PadR( AllTrim( CLI->PAIS     ), 40 )
            cCP     := PadR( AllTrim( CLI->CP       ),  5 )
            cTelef  := PadR( AllTrim( CLI->TELEFONO ), 12 )
            cMovil  := PadR( AllTrim( CLI->MOVIL    ), 12 )
            cEmail  := PadR( AllTrim( CLI->EMAIL    ), 50 )
            cWeb    := PadR( AllTrim( CLI->WEB      ), 50 )
            cIban   := PadR( AllTrim( CLI->CTA_BANC ), 34 )
            cForPag := PadR( AllTrim( CLI->FORPAGO  ),  3 )
            nDias   := CLI->DIAS_PAG
            nLimite := CLI->LIMITE_C
            nTarifa := CLI->TARIFA
            nDesc   := CLI->DESC_COM
            lAplRe  := CLI->APL_RE
            lAplIrf := CLI->APL_IRPF
            cTipCli := PadR( AllTrim( CLI->TIP_CLI  ),  1 )
            lLopd   := CLI->LOPD_OK
            lMail   := CLI->ENV_MAIL
            cCtaCon := PadR( AllTrim( CLI->CTA_CONT ), 10 )
            cCtaAnt := PadR( AllTrim( CLI->CTA_ANTI ), 10 )
            lBaja   := CLI->BAJA
        ENDIF
    ENDIF

    oWin := TWindow():New( 1, 2, 37, 129, ;
        If( lNuevo, "NUEVO CLIENTE", "EDITAR CLIENTE: " + AllTrim( cId_ ) ) )

    oWin:AddCtrl( TLabel():New(  2,  2, "Codigo         :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "NIF / CIF      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Nombre         :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Apellidos      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  2, "Direccion      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12,  2, "Ciudad         :", oWin ) )
    oWin:AddCtrl( TLabel():New( 14,  2, "Provincia      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 16,  2, "Pais           :", oWin ) )
    oWin:AddCtrl( TLabel():New( 18,  2, "C.P.           :", oWin ) )
    oWin:AddCtrl( TLabel():New( 20,  2, "Telefono       :", oWin ) )
    oWin:AddCtrl( TLabel():New( 22,  2, "Movil          :", oWin ) )
    oWin:AddCtrl( TLabel():New( 24,  2, "Email          :", oWin ) )
    oWin:AddCtrl( TLabel():New( 26,  2, "Web            :", oWin ) )
    oWin:AddCtrl( TLabel():New( 28,  2, "IBAN           :", oWin ) )

    oWin:AddCtrl( TLabel():New(  2, 72, "Forma de pago  :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 72, "Dias pago      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 72, "Limite credito :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 72, "Tarifa         :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10, 72, "Dto. comercial :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12, 72, "Tipo cli P/E/A :", oWin ) )
    oWin:AddCtrl( TLabel():New( 14, 72, "Cta. contable  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 16, 72, "Cta. anticipos :", oWin ) )

    oGId := TGet():New( 2, 20, cId_, "@!", oWin )
    oGId:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    IF !lNuevo
        oGId:lEnabled := .F.
    ENDIF

    oGNif := TGet():New(  4, 20, cNif,    "@!",    oWin )
    oGNif:bValid := {| o | _ValidNif( AllTrim( o:cBuffer ) ) }

    oGNom  := TGet():New(  6, 20, cNombre, "@!", oWin )
    oGNom:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGApe  := TGet():New(  8, 20, cApell,  "@!", oWin )
    oGDir  := TGet():New( 10, 20, cDir,    "@!", oWin )
    oGCiu  := TGet():New( 12, 20, cCiudad, "@!", oWin )
    oGPro  := TGet():New( 14, 20, cProvin, "@!", oWin )
    oGPais := TGet():New( 16, 20, cPais,   "@!", oWin )
    oGCP   := TGet():New( 18, 20, cCP,     "99999", oWin )
    oGTel  := TGet():New( 20, 20, cTelef,  "@!", oWin )
    oGMov  := TGet():New( 22, 20, cMovil,  "@!", oWin )
    oGMail := TGet():New( 24, 20, cEmail,  "@!", oWin )
    oGWeb  := TGet():New( 26, 20, cWeb,    "@!", oWin )
    oGIban := TGet():New( 28, 20, cIban,   "@!", oWin )

    oGFP     := TGet():New(  2, 90, cForPag, "@!",             oWin )
    oGDias   := TGet():New(  4, 90, nDias,   "999",            oWin )
    oGLim    := TGet():New(  6, 90, nLimite, "999,999,999.99", oWin )
    oGTar    := TGet():New(  8, 90, nTarifa, "9",              oWin )
    oGDesc   := TGet():New( 10, 90, nDesc,   "99.99",          oWin )
    oGCtaCon := TGet():New( 14, 90, cCtaCon, "@!",             oWin )
    oGCtaAnt := TGet():New( 16, 90, cCtaAnt, "@!",             oWin )

    // Tipo cliente en col 90 fila 12 (1 caracter)
    oWin:AddCtrl( TGet():New( 12, 90, cTipCli, "@!", oWin ) )

    oChkRe   := TCheck():New( 18, 72, "Aplica recargo equivalencia", lAplRe,  oWin )
    oChkIrf  := TCheck():New( 20, 72, "Aplica retencion IRPF",       lAplIrf, oWin )
    oChkLopd := TCheck():New( 22, 72, "LOPD / RGPD aceptado",        lLopd,   oWin )
    oChkMail := TCheck():New( 24, 72, "Acepta comunicaciones email",  lMail,   oWin )
    oChkBaja := TCheck():New( 26, 72, "Baja",                         lBaja,   oWin )

    oBtGua := TButton():New( 33, 40, 34, 59, oWin, "GUARDAR", ;
        {|| _CliGuardar( oGId, oGNif, oGNom, oGApe, oGDir, ;
                         oGCiu, oGPro, oGPais, oGCP, oGTel, ;
                         oGMov, oGMail, oGWeb, oGIban, oGFP, ;
                         oGDias, oGLim, oGTar, oGDesc, ;
                         oGCtaCon, oGCtaAnt, ;
                         oChkRe, oChkIrf, oChkLopd, oChkMail, oChkBaja, ;
                         lNuevo, oWin ) } )

    oBtCan := TButton():New( 33, 63, 34, 82, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGId     )
    oWin:AddCtrl( oGNif    )
    oWin:AddCtrl( oGNom    )
    oWin:AddCtrl( oGApe    )
    oWin:AddCtrl( oGDir    )
    oWin:AddCtrl( oGCiu    )
    oWin:AddCtrl( oGPro    )
    oWin:AddCtrl( oGPais   )
    oWin:AddCtrl( oGCP     )
    oWin:AddCtrl( oGTel    )
    oWin:AddCtrl( oGMov    )
    oWin:AddCtrl( oGMail   )
    oWin:AddCtrl( oGWeb    )
    oWin:AddCtrl( oGIban   )
    oWin:AddCtrl( oGFP     )
    oWin:AddCtrl( oGDias   )
    oWin:AddCtrl( oGLim    )
    oWin:AddCtrl( oGTar    )
    oWin:AddCtrl( oGDesc   )
    oWin:AddCtrl( oGCtaCon )
    oWin:AddCtrl( oGCtaAnt )
    oWin:AddCtrl( oChkRe   )
    oWin:AddCtrl( oChkIrf  )
    oWin:AddCtrl( oChkLopd )
    oWin:AddCtrl( oChkMail )
    oWin:AddCtrl( oChkBaja )
    oWin:AddCtrl( oBtGua   )
    oWin:AddCtrl( oBtCan   )

    oWin:Run()

    CLI->( DbCloseArea() )
    Select( nArea )

RETURN NIL


STATIC FUNCTION _CliGuardar( oGId, oGNif, oGNom, oGApe, oGDir, ;
                               oGCiu, oGPro, oGPais, oGCP, oGTel, ;
                               oGMov, oGMail, oGWeb, oGIban, oGFP, ;
                               oGDias, oGLim, oGTar, oGDesc, ;
                               oGCtaCon, oGCtaAnt, ;
                               oChkRe, oChkIrf, oChkLopd, oChkMail, oChkBaja, ;
                               lNuevo, oWin )

    LOCAL cId
    LOCAL cNif
    LOCAL cCtaCon

    cId     := AllTrim( oGId:uVar    )
    cNif    := AllTrim( oGNif:uVar   )
    cCtaCon := AllTrim( oGCtaCon:uVar )

    DbSelectArea( "CLI" )
    OrdSetFocus( "CLI_ID" )

    IF lNuevo
        IF DbSeek( cId )
            MsgStop( "El codigo " + cId + " ya existe.", "Alta cliente" )
            RETURN NIL
        ENDIF
        IF !Empty( cNif )
            OrdSetFocus( "CLI_NIF" )
            IF DbSeek( Upper( cNif ) )
                MsgStop( "El NIF " + cNif + " ya esta registrado.", "Alta cliente" )
                OrdSetFocus( "CLI_ID" )
                RETURN NIL
            ENDIF
            OrdSetFocus( "CLI_ID" )
        ENDIF
        IF !NetFLock()
            RETURN NIL
        ENDIF
        DbAppend()
        IF Empty( cCtaCon )
            cCtaCon := _CliSubcuenta( cId )
        ENDIF
    ELSE
        IF !DbSeek( cId )
            RETURN NIL
        ENDIF
        IF !NetRLock()
            RETURN NIL
        ENDIF
        IF Empty( cCtaCon )
            cCtaCon := _CliSubcuenta( cId )
        ENDIF
    ENDIF

    REPLACE CLI->ID       WITH cId
    REPLACE CLI->NIF      WITH AllTrim( oGNif:uVar  )
    REPLACE CLI->NOMBRE   WITH AllTrim( oGNom:uVar  )
    REPLACE CLI->APELLIDO WITH AllTrim( oGApe:uVar  )
    REPLACE CLI->DIRECCIO WITH AllTrim( oGDir:uVar  )
    REPLACE CLI->CIUDAD   WITH AllTrim( oGCiu:uVar  )
    REPLACE CLI->PROVINCI WITH AllTrim( oGPro:uVar  )
    REPLACE CLI->PAIS     WITH AllTrim( oGPais:uVar )
    REPLACE CLI->CP       WITH AllTrim( oGCP:uVar   )
    REPLACE CLI->TELEFONO WITH AllTrim( oGTel:uVar  )
    REPLACE CLI->MOVIL    WITH AllTrim( oGMov:uVar  )
    REPLACE CLI->EMAIL    WITH AllTrim( oGMail:uVar )
    REPLACE CLI->WEB      WITH AllTrim( oGWeb:uVar  )
    REPLACE CLI->CTA_BANC WITH AllTrim( oGIban:uVar )
    REPLACE CLI->FORPAGO  WITH AllTrim( oGFP:uVar   )
    REPLACE CLI->DIAS_PAG WITH oGDias:uVar
    REPLACE CLI->LIMITE_C WITH oGLim:uVar
    REPLACE CLI->TARIFA   WITH oGTar:uVar
    REPLACE CLI->DESC_COM WITH oGDesc:uVar
    REPLACE CLI->APL_RE   WITH oChkRe:lValue
    REPLACE CLI->APL_IRPF WITH oChkIrf:lValue
    REPLACE CLI->LOPD_OK  WITH oChkLopd:lValue
    REPLACE CLI->ENV_MAIL WITH oChkMail:lValue
    REPLACE CLI->CTA_CONT WITH cCtaCon
    REPLACE CLI->CTA_ANTI WITH AllTrim( oGCtaAnt:uVar )
    REPLACE CLI->BAJA     WITH oChkBaja:lValue

    IF lNuevo
        REPLACE CLI->FECHA_AL WITH Date()
    ENDIF

    DbCommit()
    DbUnlock()

    oWin:Close()

RETURN NIL


STATIC FUNCTION _CliSubcuenta( cId )

    LOCAL cNum
    LOCAL i
    LOCAL cChar

    cNum := ""

    FOR i := 1 TO Len( cId )
        cChar := SubStr( cId, i, 1 )
        IF cChar >= "0" .AND. cChar <= "9"
            cNum += cChar
        ENDIF
    NEXT

    IF Empty( cNum )
        RETURN ""
    ENDIF

RETURN "430" + StrZero( Val( cNum ), 7 )


STATIC FUNCTION _ValidNif( cNif )

    LOCAL cLetra
    LOCAL nNum
    LOCAL cLetraCalc
    LOCAL cTipo

    cLetra := "TRWAGMYFPDXBNJZSQVHLCKE"
    cNif   := Upper( AllTrim( cNif ) )

    IF Empty( cNif )
        RETURN .T.
    ENDIF

    IF Len( cNif ) < 7
        MsgStop( "NIF demasiado corto.", "Validacion NIF" )
        RETURN .F.
    ENDIF

    cTipo := Left( cNif, 1 )

    IF cTipo $ "XYZ"
        cNif  := If( cTipo == "X", "0", If( cTipo == "Y", "1", "2" ) ) + SubStr( cNif, 2 )
        cTipo := "0"
    ENDIF

    IF IsDigit( cTipo ) .AND. Len( cNif ) == 9
        nNum       := Val( Left( cNif, 8 ) )
        cLetraCalc := SubStr( cLetra, ( nNum % 23 ) + 1, 1 )
        IF Right( cNif, 1 ) != cLetraCalc
            MsgStop( "La letra del NIF no es correcta.", "Validacion NIF" )
            RETURN .F.
        ENDIF
        RETURN .T.
    ENDIF

    IF cTipo $ "ABCDEFGHJKLMNPQRSUVW"
        RETURN .T.
    ENDIF

    MsgStop( "Formato de NIF/CIF no reconocido.", "Validacion NIF" )

RETURN .F.


// ============================================================================
// FIN DE M_Clientes.prg
// ============================================================================
