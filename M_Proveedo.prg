/*
 * ARCHIVO  : M_Proveedo.prg
 * PROPOSITO: Mantenimiento completo del fichero de proveedores.
 */

#include "OOp.ch"


// ============================================================================
// ProveedView()
// ============================================================================
FUNCTION ProveedView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "PROVEED", "PRV", "PRV_NOM" )
        RETURN NIL
    ENDIF

    aData := _PrvCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "FICHERO DE PROVEEDORES" )
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
        ProveedForm( .F., g:CurrentRow()[1] ), ;
        aData := _PrvCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "Letras: busqueda por nombre. ENTER: editar. F5: nuevo.", oWin )

    oBtNvo := TButton():New( 33, 2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| ProveedForm( .T., "" ), ;
            aData := _PrvCargar(), ;
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

    PRV->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _PrvCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "PRV" )
    OrdSetFocus( "PRV_NOM" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( PRV->ID       ), ;
                AllTrim( PRV->NOMBRE + " " + PRV->APELLIDO ), ;
                AllTrim( PRV->NIF      ), ;
                AllTrim( PRV->CIUDAD   ), ;
                AllTrim( PRV->TELEFONO ), ;
                AllTrim( PRV->FORPAGO  ), ;
                AllTrim( PRV->CTA_CONT ), ;
                PRV->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


// ============================================================================
// ProveedForm()
// ============================================================================
FUNCTION ProveedForm( lNuevo, cId )

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
    LOCAL oGCtaCon
    LOCAL oGCtaAnt
    LOCAL oChkBaja
    LOCAL lFueAbierta
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
    cCtaCon  := Space( 10 )
    cCtaAnt  := Space( 10 )
    lBaja    := .F.

    lFueAbierta := IsDbUsed( "PRV" )

    IF !ABRIR_TABLA( "PROVEED", "PRV", "PRV_ID" )
        RETURN NIL
    ENDIF

    IF !lNuevo .AND. !Empty( AllTrim( cId ) )
        DbSelectArea( "PRV" )
        OrdSetFocus( "PRV_ID" )
        IF DbSeek( AllTrim( cId ) )
            cId_    := PadR( AllTrim( PRV->ID       ), 10 )
            cNif    := PadR( AllTrim( PRV->NIF      ), 13 )
            cNombre := PadR( AllTrim( PRV->NOMBRE   ), 30 )
            cApell  := PadR( AllTrim( PRV->APELLIDO ), 30 )
            cDir    := PadR( AllTrim( PRV->DIRECCIO ), 50 )
            cCiudad := PadR( AllTrim( PRV->CIUDAD   ), 40 )
            cProvin := PadR( AllTrim( PRV->PROVINCI ), 30 )
            cPais   := PadR( AllTrim( PRV->PAIS     ), 40 )
            cCP     := PadR( AllTrim( PRV->CP       ),  5 )
            cTelef  := PadR( AllTrim( PRV->TELEFONO ), 12 )
            cMovil  := PadR( AllTrim( PRV->MOVIL    ), 12 )
            cEmail  := PadR( AllTrim( PRV->EMAIL    ), 50 )
            cWeb    := PadR( AllTrim( PRV->WEB      ), 50 )
            cIban   := PadR( AllTrim( PRV->CTA_BANC ), 34 )
            cForPag := PadR( AllTrim( PRV->FORPAGO  ),  3 )
            nDias   := PRV->DIAS_PAG
            cCtaCon := PadR( AllTrim( PRV->CTA_CONT ), 10 )
            cCtaAnt := PadR( AllTrim( PRV->CTA_ANTI ), 10 )
            lBaja   := PRV->BAJA
        ENDIF
    ENDIF

    oWin := TWindow():New( 1, 2, 37, 129, ;
        If( lNuevo, "NUEVO PROVEEDOR", "EDITAR PROVEEDOR: " + AllTrim( cId_ ) ) )

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
    oWin:AddCtrl( TLabel():New(  6, 72, "Cta. contable  :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 72, "Cta. anticipos :", oWin ) )

    oGId := TGet():New(  2, 20, cId_, "@!", oWin )
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
    oGCtaCon := TGet():New(  6, 90, cCtaCon, "@!",             oWin )
    oGCtaAnt := TGet():New(  8, 90, cCtaAnt, "@!",             oWin )

    oChkBaja := TCheck():New( 28, 72, "Baja", lBaja, oWin )

    oBtGua := TButton():New( 33, 40, 34, 59, oWin, "GUARDAR", ;
        {|| If( ProveedorGuardar( _PrvFormHash( oGId, oGNif, oGNom, oGApe, ;
                                                oGDir, oGCiu, oGPro, oGPais, ;
                                                oGCP, oGTel, oGMov, oGMail, ;
                                                oGWeb, oGIban, oGFP, oGDias, ;
                                                oGCtaCon, oGCtaAnt, oChkBaja ), ;
                                  lNuevo ), ;
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
    oWin:AddCtrl( oGCtaCon )
    oWin:AddCtrl( oGCtaAnt )
    oWin:AddCtrl( oChkBaja )
    oWin:AddCtrl( oBtGua   )
    oWin:AddCtrl( oBtCan   )

    oWin:Run()

    IF !lFueAbierta
        PRV->( DbCloseArea() )
    ENDIF
    Select( nArea )

RETURN NIL


STATIC FUNCTION _PrvFormHash( oGId, oGNif, oGNom, oGApe, oGDir, ;
                                oGCiu, oGPro, oGPais, oGCP, oGTel, ;
                                oGMov, oGMail, oGWeb, oGIban, oGFP, ;
                                oGDias, oGCtaCon, oGCtaAnt, oChkBaja )

    LOCAL hProveedor := {=>}

    hProveedor[ "ID"       ] := AllTrim( oGId:GetValue() )
    hProveedor[ "NIF"      ] := AllTrim( oGNif:GetValue() )
    hProveedor[ "NOMBRE"   ] := AllTrim( oGNom:GetValue() )
    hProveedor[ "APELLIDO" ] := AllTrim( oGApe:GetValue() )
    hProveedor[ "DIRECCIO" ] := AllTrim( oGDir:GetValue() )
    hProveedor[ "CIUDAD"   ] := AllTrim( oGCiu:GetValue() )
    hProveedor[ "PROVINCI" ] := AllTrim( oGPro:GetValue() )
    hProveedor[ "PAIS"     ] := AllTrim( oGPais:GetValue() )
    hProveedor[ "CP"       ] := AllTrim( oGCP:GetValue() )
    hProveedor[ "TELEFONO" ] := AllTrim( oGTel:GetValue() )
    hProveedor[ "MOVIL"    ] := AllTrim( oGMov:GetValue() )
    hProveedor[ "EMAIL"    ] := AllTrim( oGMail:GetValue() )
    hProveedor[ "WEB"      ] := AllTrim( oGWeb:GetValue() )
    hProveedor[ "CTA_BANC" ] := AllTrim( oGIban:GetValue() )
    hProveedor[ "FORPAGO"  ] := AllTrim( oGFP:GetValue() )
    hProveedor[ "DIAS_PAG" ] := oGDias:GetValue()
    hProveedor[ "CTA_CONT" ] := AllTrim( oGCtaCon:GetValue() )
    hProveedor[ "CTA_ANTI" ] := AllTrim( oGCtaAnt:GetValue() )
    hProveedor[ "BAJA"     ] := oChkBaja:GetValue()

RETURN hProveedor


STATIC FUNCTION ProveedorGuardar( hProveedor, lNuevo )

    LOCAL cId
    LOCAL cNif
    LOCAL cCtaCon

    cId     := hProveedor[ "ID" ]
    cNif    := hProveedor[ "NIF" ]
    cCtaCon := hProveedor[ "CTA_CONT" ]

    IF !ValidNifFormato( cNif, .T. )
        MsgInfo( "El NIF/CIF no tiene formato fiscal reconocido." + Chr(13) + ;
                 "Se guardara igualmente para permitir datos provisionales.", ;
                 "Aviso NIF" )
    ENDIF

    DbSelectArea( "PRV" )
    OrdSetFocus( "PRV_ID" )

    IF lNuevo
        IF DbSeek( cId )
            MsgStop( "El codigo " + cId + " ya existe.", "Alta proveedor" )
            RETURN .F.
        ENDIF
        IF !Empty( cNif )
            OrdSetFocus( "PRV_NIF" )
            IF DbSeek( Upper( cNif ) )
                MsgStop( "El NIF " + cNif + " ya esta registrado.", "Alta proveedor" )
                OrdSetFocus( "PRV_ID" )
                RETURN .F.
            ENDIF
            OrdSetFocus( "PRV_ID" )
        ENDIF
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
        IF Empty( cCtaCon )
            cCtaCon := _PrvSubcuenta( cId )
        ENDIF
    ELSE
        IF !DbSeek( cId )
            RETURN .F.
        ENDIF
        IF !NetRLock()
            RETURN .F.
        ENDIF
        IF Empty( cCtaCon )
            cCtaCon := _PrvSubcuenta( cId )
        ENDIF
    ENDIF

    REPLACE PRV->ID       WITH cId
    REPLACE PRV->NIF      WITH hProveedor[ "NIF"      ]
    REPLACE PRV->NOMBRE   WITH hProveedor[ "NOMBRE"   ]
    REPLACE PRV->APELLIDO WITH hProveedor[ "APELLIDO" ]
    REPLACE PRV->DIRECCIO WITH hProveedor[ "DIRECCIO" ]
    REPLACE PRV->CIUDAD   WITH hProveedor[ "CIUDAD"   ]
    REPLACE PRV->PROVINCI WITH hProveedor[ "PROVINCI" ]
    REPLACE PRV->PAIS     WITH hProveedor[ "PAIS"     ]
    REPLACE PRV->CP       WITH hProveedor[ "CP"       ]
    REPLACE PRV->TELEFONO WITH hProveedor[ "TELEFONO" ]
    REPLACE PRV->MOVIL    WITH hProveedor[ "MOVIL"    ]
    REPLACE PRV->EMAIL    WITH hProveedor[ "EMAIL"    ]
    REPLACE PRV->WEB      WITH hProveedor[ "WEB"      ]
    REPLACE PRV->CTA_BANC WITH hProveedor[ "CTA_BANC" ]
    REPLACE PRV->FORPAGO  WITH hProveedor[ "FORPAGO"  ]
    REPLACE PRV->DIAS_PAG WITH hProveedor[ "DIAS_PAG" ]
    REPLACE PRV->CTA_CONT WITH cCtaCon
    REPLACE PRV->CTA_ANTI WITH hProveedor[ "CTA_ANTI" ]
    REPLACE PRV->BAJA     WITH hProveedor[ "BAJA"     ]

    IF lNuevo
        REPLACE PRV->FECHA_AL WITH Date()
    ENDIF

    DbCommit()
    DbUnlock()

RETURN .T.


STATIC FUNCTION _PrvSubcuenta( cId )

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

RETURN "400" + StrZero( Val( cNum ), 7 )


// ============================================================================
// FIN DE M_Proveedo.prg
// ============================================================================
