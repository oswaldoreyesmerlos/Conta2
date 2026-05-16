/*
 * ARCHIVO  : M_Familias.prg
 * PROPOSITO: Mantenimiento de familias de articulos aislado del build principal.
 */

#include "OOp.ch"


// ============================================================================
// M_Familias()
// ============================================================================
FUNCTION M_Familias()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL aData

    IF !ABRIR_TABLA( "FAMILIAS", "FAM", "FAM_COD" )
        RETURN NIL
    ENDIF

    aData := _FamCargar()

    oWin  := TWindow():New( 3, 10, 34, 119, "FAMILIAS DE ARTICULOS" )
    oGrid := TGrid():New( 2, 2, 25, 106, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 1

    oGrid:AddColumn( "Codigo",      5, "@!",     { |a| a[1] } )
    oGrid:AddColumn( "Descripcion",30, "@!",     { |a| a[2] } )
    oGrid:AddColumn( "IVA Def",     7, "@!",     { |a| a[3] } )
    oGrid:AddColumn( "Cta.Venta",  10, "@!",     { |a| a[4] } )
    oGrid:AddColumn( "Cta.Compra", 10, "@!",     { |a| a[5] } )
    oGrid:AddColumn( "Margen %",    8, "99.99",  { |a| a[6] } )
    oGrid:AddColumn( "Baja",        4, "@!",     { |a| If( a[7], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        _FamForm( g:CurrentRow(), .F. ), ;
        aData := _FamCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oBtNvo := TButton():New( 27, 2, 28, 18, oWin, "NUEVO (F5)", ;
        {|| _FamForm( NIL, .T. ), ;
            aData := _FamCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 27, 55, 28, 71, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    FAM->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _FamCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "FAM" )
    OrdSetFocus( "FAM_COD" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( FAM->CODIGO  ), ;
                AllTrim( FAM->DESCRIP ), ;
                AllTrim( FAM->DEF_IVA ), ;
                AllTrim( FAM->CTA_VTA ), ;
                AllTrim( FAM->CTA_COM ), ;
                FAM->MARGEN, ;
                FAM->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _FamForm( aFila, lNuevo )

    LOCAL oWin
    LOCAL oGetCod
    LOCAL oGetDes
    LOCAL oGetIva
    LOCAL oGetVta
    LOCAL oGetCom
    LOCAL oGetMar
    LOCAL oChkBaj
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL cCodigo
    LOCAL cDescri
    LOCAL cIva
    LOCAL cCtaVta
    LOCAL cCtaCom
    LOCAL nMargen
    LOCAL lBaja
    LOCAL cTit

    DEFAULT lNuevo TO .F.

    cCodigo := Space(  3 )
    cDescri := Space( 30 )
    cIva    := Space(  1 )
    cCtaVta := Space( 10 )
    cCtaCom := Space( 10 )
    nMargen := 0.00
    lBaja   := .F.

    IF !lNuevo .AND. aFila != NIL
        cCodigo := PadR( aFila[1], 3  )
        cDescri := PadR( aFila[2], 30 )
        cIva    := PadR( aFila[3], 1  )
        cCtaVta := PadR( aFila[4], 10 )
        cCtaCom := PadR( aFila[5], 10 )
        nMargen := aFila[6]
        lBaja   := aFila[7]
    ENDIF

    cTit := If( lNuevo, "NUEVA FAMILIA", "EDITAR FAMILIA" )

    oWin := TWindow():New( 8, 30, 28, 100, cTit )

    oWin:AddCtrl( TLabel():New(  2, 3, "Codigo      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 3, "Descripcion :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 3, "Tipo IVA    :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 3, "Cta. Venta  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10, 3, "Cta. Compra :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12, 3, "Margen %    :", oWin ) )

    oGetCod := TGet():New(  2, 17, cCodigo, "@!",    oWin )
    oGetCod:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    IF !lNuevo
        oGetCod:lEnabled := .F.
    ENDIF

    oGetDes := TGet():New(  4, 17, cDescri, "@!", oWin )
    oGetDes:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGetIva := TGet():New(  6, 17, cIva,    "@!", oWin )
    oGetVta := TGet():New(  8, 17, cCtaVta, "@!", oWin )
    oGetCom := TGet():New( 10, 17, cCtaCom, "@!", oWin )
    oGetMar := TGet():New( 12, 17, nMargen, "99.99", oWin )

    oChkBaj := TCheck():New( 14, 17, "Baja", lBaja, oWin )

    oBtGua := TButton():New( 16, 10, 17, 26, oWin, "GUARDAR", ;
        {|| If( FamiliaGuardar( _FamFormHash( oGetCod, oGetDes, oGetIva, oGetVta, ;
                                              oGetCom, oGetMar, oChkBaj ), ;
                                lNuevo ), ;
                 oWin:Close(), NIL ) } )

    oBtCan := TButton():New( 16, 30, 17, 46, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGetCod )
    oWin:AddCtrl( oGetDes )
    oWin:AddCtrl( oGetIva )
    oWin:AddCtrl( oGetVta )
    oWin:AddCtrl( oGetCom )
    oWin:AddCtrl( oGetMar )
    oWin:AddCtrl( oChkBaj )
    oWin:AddCtrl( oBtGua  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _FamFormHash( oGC, oGD, oGI, oGV, oGCo, oGM, oChk )

    LOCAL hFamilia := {=>}

    hFamilia[ "CODIGO"  ] := AllTrim( oGC:GetValue() )
    hFamilia[ "DESCRIP" ] := AllTrim( oGD:GetValue() )
    hFamilia[ "DEF_IVA" ] := AllTrim( oGI:GetValue() )
    hFamilia[ "CTA_VTA" ] := AllTrim( oGV:GetValue() )
    hFamilia[ "CTA_COM" ] := AllTrim( oGCo:GetValue() )
    hFamilia[ "MARGEN"  ] := oGM:GetValue()
    hFamilia[ "BAJA"    ] := oChk:GetValue()

RETURN hFamilia


FUNCTION FamiliaGuardar( hFamilia, lNuevo )

    LOCAL cCod

    cCod := hFamilia[ "CODIGO" ]

    DbSelectArea( "FAM" )
    OrdSetFocus( "FAM_COD" )

    IF lNuevo
        IF DbSeek( cCod )
            MsgStop( "El codigo " + cCod + " ya existe.", "Alta" )
            RETURN .F.
        ENDIF
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCod )
            RETURN .F.
        ENDIF
        IF !NetRLock()
            RETURN .F.
        ENDIF
    ENDIF

    REPLACE FAM->CODIGO  WITH hFamilia[ "CODIGO"  ]
    REPLACE FAM->DESCRIP WITH hFamilia[ "DESCRIP" ]
    REPLACE FAM->DEF_IVA WITH hFamilia[ "DEF_IVA" ]
    REPLACE FAM->CTA_VTA WITH hFamilia[ "CTA_VTA" ]
    REPLACE FAM->CTA_COM WITH hFamilia[ "CTA_COM" ]
    REPLACE FAM->MARGEN  WITH hFamilia[ "MARGEN"  ]
    REPLACE FAM->BAJA    WITH hFamilia[ "BAJA"    ]

    DbUnlock()

RETURN .T.
