/*
 * ARCHIVO  : M_Vendedor.prg
 * PROPOSITO: Mantenimiento completo del fichero de vendedores.
 */

#include "OOp.ch"


// ============================================================================
// VendedoresView()
// ============================================================================
FUNCTION VendedoresView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "VENDEDOR", "VEN", "VEN_NOM" )
        RETURN NIL
    ENDIF

    aData := _VendCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "FICHERO DE VENDEDORES" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Codigo",      10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Nombre",      35, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "DNI",         15, "@!",         { |a| a[3] } )
    oGrid:AddColumn( "Telefono",    12, "@!",         { |a| a[4] } )
    oGrid:AddColumn( "Comision %",  8, "99.99",      { |a| a[5] } )
    oGrid:AddColumn( "Cta.Cont.",   10, "@!",         { |a| a[6] } )
    oGrid:AddColumn( "Baja",         4, "@!",         { |a| If( a[7], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        VendedoresForm( .F., g:CurrentRow()[1] ), ;
        aData := _VendCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "Letras: busqueda por nombre. ENTER: editar. F5: nuevo.", oWin )

    oBtNvo := TButton():New( 33, 2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| VendedoresForm( .T., "" ), ;
            aData := _VendCargar(), ;
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

    VEN->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _VendCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "VEN" )
    OrdSetFocus( "VEN_NOM" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( VEN->ID       ), ;
                AllTrim( VEN->NOMBRE   ), ;
                AllTrim( VEN->DNI      ), ;
                AllTrim( VEN->TELEFONO ), ;
                VEN->COMISION, ;
                AllTrim( VEN->CTA_CONT ), ;
                VEN->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


// ============================================================================
// VendedoresForm()
// ============================================================================
FUNCTION VendedoresForm( lNuevo, cId )

    LOCAL oWin
    LOCAL nArea
    LOCAL cId_
    LOCAL cNombre
    LOCAL cDni
    LOCAL cTelef
    LOCAL nComision
    LOCAL cCtaCon
    LOCAL lBaja
    LOCAL oGId
    LOCAL oGNom
    LOCAL oGDni
    LOCAL oGTel
    LOCAL oGCom
    LOCAL oGCta
    LOCAL oChkBaja
    LOCAL oBtGua
    LOCAL oBtCan

    DEFAULT lNuevo TO .T.
    DEFAULT cId    TO ""

    nArea    := Select()
    cId_     := Space( 10 )
    cNombre  := Space( 40 )
    cDni     := Space( 15 )
    cTelef   := Space( 15 )
    nComision:= 0.00
    cCtaCon  := Space( 10 )
    lBaja    := .F.

    IF !ABRIR_TABLA( "VENDEDOR", "VEN", "VEN_ID" )
        RETURN NIL
    ENDIF

    IF !lNuevo .AND. !Empty( AllTrim( cId ) )
        DbSelectArea( "VEN" )
        OrdSetFocus( "VEN_ID" )
        IF DbSeek( AllTrim( cId ) )
            cId_     := PadR( AllTrim( VEN->ID       ), 10 )
            cNombre  := PadR( AllTrim( VEN->NOMBRE   ), 40 )
            cDni     := PadR( AllTrim( VEN->DNI      ), 15 )
            cTelef   := PadR( AllTrim( VEN->TELEFONO ), 15 )
            nComision:= VEN->COMISION
            cCtaCon  := PadR( AllTrim( VEN->CTA_CONT ), 10 )
            lBaja    := VEN->BAJA
        ENDIF
    ENDIF

    oWin := TWindow():New( 5, 20, 28, 110, ;
        If( lNuevo, "NUEVO VENDEDOR", "EDITAR VENDEDOR: " + AllTrim( cId_ ) ) )

    oWin:AddCtrl( TLabel():New(  2,  2, "Codigo     :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Nombre     :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "DNI         :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Telefono   :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  2, "Comision % :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12,  2, "Cta.Cont.  :", oWin ) )

    oGId := TGet():New(  2, 16, cId_, "@!", oWin )
    oGId:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    IF !lNuevo
        oGId:lEnabled := .F.
    ENDIF

    oGNom := TGet():New(  4, 16, cNombre, "@!", oWin )
    oGNom:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGDni := TGet():New(  6, 16, cDni, "@!", oWin )
    oGTel := TGet():New(  8, 16, cTelef, "@!", oWin )
    oGCom := TGet():New( 10, 16, nComision, "99.99", oWin )
    oGCta := TGet():New( 12, 16, cCtaCon, "@!", oWin )

    oChkBaja := TCheck():New( 14, 16, "Baja", lBaja, oWin )

    oBtGua := TButton():New( 16,  8, 17, 24, oWin, "GUARDAR", ;
        {|| If( VendedorGuardar( _VendFormHash( oGId, oGNom, oGDni, oGTel, ;
                                                 oGCom, oGCta, oChkBaja ), ;
                                   lNuevo ), ;
                 oWin:Close(), NIL ) } )

    oBtCan := TButton():New( 16, 28, 17, 44, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGId     )
    oWin:AddCtrl( oGNom    )
    oWin:AddCtrl( oGDni    )
    oWin:AddCtrl( oGTel    )
    oWin:AddCtrl( oGCom    )
    oWin:AddCtrl( oGCta    )
    oWin:AddCtrl( oChkBaja )
    oWin:AddCtrl( oBtGua   )
    oWin:AddCtrl( oBtCan   )

    oWin:Run()

    VEN->( DbCloseArea() )
    Select( nArea )

RETURN NIL


STATIC FUNCTION _VendFormHash( oGC, oGN, oGD, oGT, oGCo, oGCt, oChk )

    LOCAL hVendedor := {=>}

    hVendedor[ "ID"       ] := AllTrim( oGC:GetValue() )
    hVendedor[ "NOMBRE"   ] := AllTrim( oGN:GetValue() )
    hVendedor[ "DNI"      ] := AllTrim( oGD:GetValue() )
    hVendedor[ "TELEFONO" ] := AllTrim( oGT:GetValue() )
    hVendedor[ "COMISION" ] := oGCo:GetValue()
    hVendedor[ "CTA_CONT" ] := AllTrim( oGCt:GetValue() )
    hVendedor[ "BAJA"     ] := oChk:GetValue()

RETURN hVendedor


FUNCTION VendedorGuardar( hVendedor, lNuevo )

    LOCAL cId

    cId := hVendedor[ "ID" ]

    DbSelectArea( "VEN" )
    OrdSetFocus( "VEN_ID" )

    IF lNuevo
        IF DbSeek( cId )
            MsgStop( "El codigo " + cId + " ya existe.", "Alta vendedor" )
            RETURN .F.
        ENDIF
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cId ) .OR. !NetRLock()
            RETURN .F.
        ENDIF
    ENDIF

    REPLACE VEN->ID       WITH cId
    REPLACE VEN->NOMBRE   WITH hVendedor[ "NOMBRE"   ]
    REPLACE VEN->DNI      WITH hVendedor[ "DNI"      ]
    REPLACE VEN->TELEFONO WITH hVendedor[ "TELEFONO" ]
    REPLACE VEN->COMISION WITH hVendedor[ "COMISION" ]
    REPLACE VEN->CTA_CONT WITH hVendedor[ "CTA_CONT" ]
    REPLACE VEN->BAJA     WITH hVendedor[ "BAJA"     ]

    IF lNuevo
        REPLACE VEN->FECHA_AL WITH Date()
    ENDIF

    DbCommit()
    DbUnlock()

RETURN .T.


// ============================================================================
// FIN DE M_Vendedor.prg
// ============================================================================
