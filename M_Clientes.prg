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
    LOCAL lFueAbierta
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
    LOCAL oGTipCli
    LOCAL oGCtaCon
    LOCAL oGCtaAnt
    LOCAL oChkRe
    LOCAL oChkIrf
    LOCAL oChkLopd
    LOCAL oChkMail
    LOCAL oChkBaja
    LOCAL oBtDir
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

    lFueAbierta := DBUSED( "CLI" )

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
    oGTipCli := TGet():New( 12, 90, cTipCli, "@!",             oWin )
    oGCtaCon := TGet():New( 14, 90, cCtaCon, "@!",             oWin )
    oGCtaAnt := TGet():New( 16, 90, cCtaAnt, "@!",             oWin )

    oChkRe   := TCheck():New( 18, 72, "Aplica recargo equivalencia", lAplRe,  oWin )
    oChkIrf  := TCheck():New( 20, 72, "Aplica retencion IRPF",       lAplIrf, oWin )
    oChkLopd := TCheck():New( 22, 72, "LOPD / RGPD aceptado",        lLopd,   oWin )
    oChkMail := TCheck():New( 24, 72, "Acepta comunicaciones email",  lMail,   oWin )
    oChkBaja := TCheck():New( 26, 72, "Baja",                         lBaja,   oWin )

    oBtDir := TButton():New( 30, 2, 31, 16, oWin, "DIR.OBRA", ;
        {|| _CliDiresGestion( AllTrim( oGId:GetValue() ) ) } )

    oBtGua := TButton():New( 33, 40, 34, 59, oWin, "GUARDAR", ;
        {|| If( ClienteGuardar( _CliFormHash( oGId, oGNif, oGNom, oGApe, oGDir, ;
                                             oGCiu, oGPro, oGPais, oGCP, oGTel, ;
                                             oGMov, oGMail, oGWeb, oGIban, oGFP, ;
                                             oGDias, oGLim, oGTar, oGDesc, ;
                                             oGTipCli, oGCtaCon, oGCtaAnt, ;
                                             oChkRe, oChkIrf, oChkLopd, oChkMail, ;
                                             oChkBaja ), lNuevo ), ;
                 oWin:Close(), NIL ) } )

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
    oWin:AddCtrl( oGTipCli )
    oWin:AddCtrl( oGCtaCon )
    oWin:AddCtrl( oGCtaAnt )
    oWin:AddCtrl( oChkRe   )
    oWin:AddCtrl( oChkIrf  )
    oWin:AddCtrl( oChkLopd )
    oWin:AddCtrl( oChkMail )
    oWin:AddCtrl( oChkBaja )
    oWin:AddCtrl( oBtDir   )
    oWin:AddCtrl( oBtGua   )
    oWin:AddCtrl( oBtCan   )

    oWin:Run()

    IF !lFueAbierta
        CLI->( DbCloseArea() )
    ENDIF
    Select( nArea )

RETURN NIL


STATIC FUNCTION _CliFormHash( oGId, oGNif, oGNom, oGApe, oGDir, ;
                                oGCiu, oGPro, oGPais, oGCP, oGTel, ;
                                oGMov, oGMail, oGWeb, oGIban, oGFP, ;
                                oGDias, oGLim, oGTar, oGDesc, ;
                                oGTipCli, oGCtaCon, oGCtaAnt, ;
                                oChkRe, oChkIrf, oChkLopd, oChkMail, oChkBaja )

    LOCAL hCliente := {=>}

    hCliente[ "ID"       ] := AllTrim( oGId:GetValue() )
    hCliente[ "NIF"      ] := AllTrim( oGNif:GetValue() )
    hCliente[ "NOMBRE"   ] := AllTrim( oGNom:GetValue() )
    hCliente[ "APELLIDO" ] := AllTrim( oGApe:GetValue() )
    hCliente[ "DIRECCIO" ] := AllTrim( oGDir:GetValue() )
    hCliente[ "CIUDAD"   ] := AllTrim( oGCiu:GetValue() )
    hCliente[ "PROVINCI" ] := AllTrim( oGPro:GetValue() )
    hCliente[ "PAIS"     ] := AllTrim( oGPais:GetValue() )
    hCliente[ "CP"       ] := AllTrim( oGCP:GetValue() )
    hCliente[ "TELEFONO" ] := AllTrim( oGTel:GetValue() )
    hCliente[ "MOVIL"    ] := AllTrim( oGMov:GetValue() )
    hCliente[ "EMAIL"    ] := AllTrim( oGMail:GetValue() )
    hCliente[ "WEB"      ] := AllTrim( oGWeb:GetValue() )
    hCliente[ "CTA_BANC" ] := AllTrim( oGIban:GetValue() )
    hCliente[ "FORPAGO"  ] := AllTrim( oGFP:GetValue() )
    hCliente[ "DIAS_PAG" ] := oGDias:GetValue()
    hCliente[ "LIMITE_C" ] := oGLim:GetValue()
    hCliente[ "TARIFA"   ] := oGTar:GetValue()
    hCliente[ "DESC_COM" ] := oGDesc:GetValue()
    hCliente[ "TIP_CLI"  ] := AllTrim( oGTipCli:GetValue() )
    hCliente[ "CTA_CONT" ] := AllTrim( oGCtaCon:GetValue() )
    hCliente[ "CTA_ANTI" ] := AllTrim( oGCtaAnt:GetValue() )
    hCliente[ "APL_RE"   ] := oChkRe:GetValue()
    hCliente[ "APL_IRPF" ] := oChkIrf:GetValue()
    hCliente[ "LOPD_OK"  ] := oChkLopd:GetValue()
    hCliente[ "ENV_MAIL" ] := oChkMail:GetValue()
    hCliente[ "BAJA"     ] := oChkBaja:GetValue()

RETURN hCliente


STATIC FUNCTION ClienteGuardar( hCliente, lNuevo )

    LOCAL cId
    LOCAL cNif
    LOCAL cCtaCon

    cId     := hCliente[ "ID" ]
    cNif    := hCliente[ "NIF" ]
    cCtaCon := hCliente[ "CTA_CONT" ]

    IF !ValidNifFormato( cNif, .T. )
        MsgInfo( "El NIF/CIF no tiene formato fiscal reconocido." + Chr(13) + ;
                 "Se guardara igualmente para permitir datos provisionales.", ;
                 "Aviso NIF" )
    ENDIF

    DbSelectArea( "CLI" )
    OrdSetFocus( "CLI_ID" )

    IF lNuevo
        IF DbSeek( cId )
            MsgStop( "El codigo " + cId + " ya existe.", "Alta cliente" )
            RETURN .F.
        ENDIF
        IF !Empty( cNif )
            OrdSetFocus( "CLI_NIF" )
            IF DbSeek( Upper( cNif ) )
                MsgStop( "El NIF " + cNif + " ya esta registrado.", "Alta cliente" )
                OrdSetFocus( "CLI_ID" )
                RETURN .F.
            ENDIF
            OrdSetFocus( "CLI_ID" )
        ENDIF
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
        IF Empty( cCtaCon )
            cCtaCon := _CliSubcuenta( cId )
        ENDIF
    ELSE
        IF !DbSeek( cId )
            RETURN .F.
        ENDIF
        IF !NetRLock()
            RETURN .F.
        ENDIF
        IF Empty( cCtaCon )
            cCtaCon := _CliSubcuenta( cId )
        ENDIF
    ENDIF

    REPLACE CLI->ID       WITH cId
    REPLACE CLI->NIF      WITH hCliente[ "NIF"      ]
    REPLACE CLI->NOMBRE   WITH hCliente[ "NOMBRE"   ]
    REPLACE CLI->APELLIDO WITH hCliente[ "APELLIDO" ]
    REPLACE CLI->DIRECCIO WITH hCliente[ "DIRECCIO" ]
    REPLACE CLI->CIUDAD   WITH hCliente[ "CIUDAD"   ]
    REPLACE CLI->PROVINCI WITH hCliente[ "PROVINCI" ]
    REPLACE CLI->PAIS     WITH hCliente[ "PAIS"     ]
    REPLACE CLI->CP       WITH hCliente[ "CP"       ]
    REPLACE CLI->TELEFONO WITH hCliente[ "TELEFONO" ]
    REPLACE CLI->MOVIL    WITH hCliente[ "MOVIL"    ]
    REPLACE CLI->EMAIL    WITH hCliente[ "EMAIL"    ]
    REPLACE CLI->WEB      WITH hCliente[ "WEB"      ]
    REPLACE CLI->CTA_BANC WITH hCliente[ "CTA_BANC" ]
    REPLACE CLI->FORPAGO  WITH hCliente[ "FORPAGO"  ]
    REPLACE CLI->DIAS_PAG WITH hCliente[ "DIAS_PAG" ]
    REPLACE CLI->LIMITE_C WITH hCliente[ "LIMITE_C" ]
    REPLACE CLI->TARIFA   WITH hCliente[ "TARIFA"   ]
    REPLACE CLI->DESC_COM WITH hCliente[ "DESC_COM" ]
    REPLACE CLI->TIP_CLI  WITH hCliente[ "TIP_CLI"  ]
    REPLACE CLI->APL_RE   WITH hCliente[ "APL_RE"   ]
    REPLACE CLI->APL_IRPF WITH hCliente[ "APL_IRPF" ]
    REPLACE CLI->LOPD_OK  WITH hCliente[ "LOPD_OK"  ]
    REPLACE CLI->ENV_MAIL WITH hCliente[ "ENV_MAIL" ]
    REPLACE CLI->CTA_CONT WITH cCtaCon
    REPLACE CLI->CTA_ANTI WITH hCliente[ "CTA_ANTI" ]
    REPLACE CLI->BAJA     WITH hCliente[ "BAJA"     ]

    IF lNuevo
        REPLACE CLI->FECHA_AL WITH Date()
    ENDIF

    DbCommit()
    DbUnlock()

RETURN .T.


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


// ============================================================================
// DIRECCIONES DE OBRA POR CLIENTE
// ============================================================================

FUNCTION CliDiresListado( cCli )

    LOCAL aData := {}

    IF Empty( AllTrim( cCli ) )
        RETURN aData
    ENDIF

    IF ABRIR_TABLA( "CLI_DIRES", "CDR_L", "CDR_CLI" )
        DbSelectArea( "CDR_L" )
        OrdSetFocus( "CDR_CLI" )
        DbGoTop()

        DO WHILE !Eof()
            IF !Deleted() .AND. AllTrim( CDR_L->CLIENTE ) == AllTrim( cCli )
                AAdd( aData, { ;
                    AllTrim( CDR_L->CLIENTE   ), ;
                    AllTrim( CDR_L->DESCRIPC  ), ;
                    AllTrim( CDR_L->DIRECCION ), ;
                    AllTrim( CDR_L->CIUDAD    ), ;
                    AllTrim( CDR_L->CP        ) } )
            ENDIF
            DbSkip()
        ENDDO

        CDR_L->( DbCloseArea() )
    ENDIF

RETURN aData


STATIC FUNCTION _CliDiresGestion( cCli )

    LOCAL oWin
    LOCAL oGrid
    LOCAL aData
    LOCAL oBtNvo
    LOCAL oBtEdt
    LOCAL oBtDel
    LOCAL oBtSal

    IF Empty( AllTrim( cCli ) )
        MsgStop( "Guarde el cliente antes de gestionar direcciones.", "Direcciones" )
        RETURN NIL
    ENDIF

    aData := CliDiresListado( cCli )

    oWin := TWindow():New( 5, 10, 35, 120, "DIRECCIONES DE OBRA - " + AllTrim( cCli ) )
    oGrid := TGrid():New( 2, 2, 25, 106, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Descripcion", 30, "@!", { |a| a[2] } )
    oGrid:AddColumn( "Direccion",   50, "@!", { |a| a[3] } )
    oGrid:AddColumn( "Ciudad",      20, "@!", { |a| a[4] } )
    oGrid:AddColumn( "CP",          8, "@!",  { |a| a[5] } )

    oGrid:bEnter := {| g | _CliDiresForm( cCli, g:nCurRow, @aData, oGrid ) }

    oLbl := TLabel():New( 27, 2, ;
        "ENTER: editar   F5: nueva direccion   DEL: eliminar", oWin )

    oBtNvo := TButton():New( 28,  2, 29, 20, oWin, "NUEVA (F5)", ;
        {|| _CliDiresForm( cCli, 0, @aData, oGrid ) } )

    oBtEdt := TButton():New( 28, 22, 29, 40, oWin, "EDITAR", ;
        {|| If( oGrid:CurrentRow() != NIL, ;
                _CliDiresForm( cCli, oGrid:nCurRow, @aData, oGrid ), NIL ) } )

    oBtDel := TButton():New( 28, 42, 29, 60, oWin, "ELIMINAR", ;
        {|| If( oGrid:CurrentRow() != NIL .AND. ;
                MsgYesNo( "Eliminar " + AllTrim( oGrid:CurrentRow()[2] ) + "?", "Confirmar" ), ;
                _CliDiresBorrar( cCli, oGrid:CurrentRow()[2], @aData, oGrid ), NIL ) } )

    oBtSal := TButton():New( 28, 98, 29, 116, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLbl   )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtEdt )
    oWin:AddCtrl( oBtDel )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _CliDiresForm( cCli, nEdit, aData, oGrid )

    LOCAL oWin
    LOCAL cDesc  := Space( 30 )
    LOCAL cDir   := Space( 50 )
    LOCAL cCiudad:= Space( 40 )
    LOCAL cProv  := Space( 30 )
    LOCAL cPais  := Space( 40 )
    LOCAL cCP    := Space( 5 )
    LOCAL oGDesc
    LOCAL oGDir
    LOCAL oGCiu
    LOCAL oGProv
    LOCAL oGPais
    LOCAL oGCP
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL lOK := .F.
    LOCAL nArea := Select()

    DEFAULT nEdit TO 0

    IF nEdit > 0 .AND. nEdit <= Len( aData )
        cDesc   := PadR( aData[nEdit, 2], 30 )
        cDir    := PadR( aData[nEdit, 3], 50 )
        cCiudad := PadR( aData[nEdit, 4], 40 )
        cCP     := PadR( aData[nEdit, 5], 5 )
    ENDIF

    oWin := TWindow():New( 10, 18, 26, 110, ;
        If( nEdit == 0, "NUEVA DIRECCION DE OBRA", "EDITAR DIRECCION DE OBRA" ) )

    oWin:AddCtrl( TLabel():New(  2,  3, "Descripcion :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  3, "Direccion   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  3, "Ciudad      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  3, "Provincia   :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  3, "Pais        :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12,  3, "C.P.        :", oWin ) )

    oGDesc := TGet():New( 2, 18, cDesc,   "@!",      oWin )
    oGDesc:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGDir  := TGet():New( 4, 18, cDir,    "@!",      oWin )
    oGCiu  := TGet():New( 6, 18, cCiudad, "@!",      oWin )
    oGProv := TGet():New( 8, 18, cProv,   "@!",      oWin )
    oGPais := TGet():New( 10, 18, cPais,   "@!",      oWin )
    oGCP   := TGet():New( 12, 18, cCP,     "99999",   oWin )

    oBtGua := TButton():New( 14, 18, 15, 37, oWin, "GUARDAR", ;
        {|| lOK := _CliDiresGuardar( cCli, nEdit, @aData, ;
                                      oGDesc, oGDir, oGCiu, oGProv, oGPais, oGCP ), ;
            If( lOK, ( oGrid:aData := aData, oGrid:Paint(), oWin:Close() ), NIL ) } )

    oBtCan := TButton():New( 14, 40, 15, 59, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGDesc )
    oWin:AddCtrl( oGDir  )
    oWin:AddCtrl( oGCiu  )
    oWin:AddCtrl( oGProv )
    oWin:AddCtrl( oGPais )
    oWin:AddCtrl( oGCP   )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    Select( nArea )

RETURN NIL


STATIC FUNCTION _CliDiresGuardar( cCli, nEdit, aData, oGDesc, oGDir, oGCiu, oGProv, oGPais, oGCP )

    LOCAL cDesc   := AllTrim( oGDesc:GetValue() )
    LOCAL cDir    := AllTrim( oGDir:GetValue() )
    LOCAL cCiudad := AllTrim( oGCiu:GetValue() )
    LOCAL cProv   := AllTrim( oGProv:GetValue() )
    LOCAL cPais   := AllTrim( oGPais:GetValue() )
    LOCAL cCP     := AllTrim( oGCP:GetValue() )
    LOCAL nArea   := Select()
    LOCAL lOk     := .F.

    IF Empty( cDesc )
        MsgStop( "La descripcion es obligatoria.", "Guardar" )
        RETURN .F.
    ENDIF

    IF !ABRIR_TABLA( "CLI_DIRES", "CDR_G", "CDR_CLI" )
        Select( nArea )
        RETURN .F.
    ENDIF

    DbSelectArea( "CDR_G" )
    OrdSetFocus( "CDR_CLI" )

    IF nEdit > 0 .AND. nEdit <= Len( aData )
        IF DbSeek( PadR( AllTrim( cCli ), 10 ) + aData[nEdit, 2] ) .AND. NetRLock()
            REPLACE CDR_G->DIRECCION WITH PadR( cDir, 50 )
            REPLACE CDR_G->CIUDAD    WITH PadR( cCiudad, 40 )
            REPLACE CDR_G->PROVINCIA WITH PadR( cProv, 30 )
            REPLACE CDR_G->PAIS      WITH PadR( cPais, 40 )
            REPLACE CDR_G->CP        WITH PadR( cCP, 5 )
            DbCommit()
            DbUnlock()
            aData[nEdit, 3] := cDir
            aData[nEdit, 4] := cCiudad
            aData[nEdit, 5] := cCP
            lOk := .T.
        ENDIF
    ELSE
        IF !NetFLock()
            CDR_G->( DbCloseArea() )
            Select( nArea )
            RETURN .F.
        ENDIF
        DbAppend()
        REPLACE CDR_G->CLIENTE   WITH PadR( AllTrim( cCli ), 10 )
        REPLACE CDR_G->DESCRIPC  WITH PadR( cDesc, 30 )
        REPLACE CDR_G->DIRECCION WITH PadR( cDir, 50 )
        REPLACE CDR_G->CIUDAD    WITH PadR( cCiudad, 40 )
        REPLACE CDR_G->PROVINCIA WITH PadR( cProv, 30 )
        REPLACE CDR_G->PAIS      WITH PadR( cPais, 40 )
        REPLACE CDR_G->CP        WITH PadR( cCP, 5 )
        DbCommit()
        DbUnlock()
        AAdd( aData, { cCli, cDesc, cDir, cCiudad, cCP } )
        lOk := .T.
    ENDIF

    CDR_G->( DbCloseArea() )
    Select( nArea )

RETURN lOk


STATIC FUNCTION _CliDiresBorrar( cCli, cDesc, aData, oGrid )

    LOCAL nArea := Select()
    LOCAL nPos  := AScan( aData, {| a | a[2] == cDesc } )
    LOCAL i

    IF nPos == 0
        RETURN NIL
    ENDIF

    IF !ABRIR_TABLA( "CLI_DIRES", "CDR_B", "CDR_CLI" )
        Select( nArea )
        RETURN NIL
    ENDIF

    DbSelectArea( "CDR_B" )
    OrdSetFocus( "CDR_CLI" )

    IF DbSeek( PadR( AllTrim( cCli ), 10 ) + cDesc ) .AND. NetRLock()
        CDR_B->( DbDelete() )
        DbCommit()
        DbUnlock()
    ENDIF

    CDR_B->( DbCloseArea() )
    Select( nArea )

    ADel( aData, nPos )
    ASize( aData, Len( aData ) - 1 )

    IF oGrid:nCurRow > Len( aData ) .AND. Len( aData ) > 0
        oGrid:nCurRow := Len( aData )
    ENDIF
    oGrid:aData := aData
    oGrid:Paint()

RETURN NIL


// ============================================================================
// FIN DE M_Clientes.prg
// ============================================================================
