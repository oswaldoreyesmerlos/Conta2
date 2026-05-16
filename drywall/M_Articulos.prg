/*
 * ARCHIVO  : M_Articulos.prg
 * PROPOSITO: Mantenimiento completo del catálogo de artículos.
 */

#include "OOp.ch"


// ============================================================================
// ArticulosView()
// ============================================================================
FUNCTION ArticulosView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData, nArea

    nArea := Select()

    IF !ABRIR_TABLA( "ARTICULOS", "ART", "ART_DES" )
        RETURN NIL
    ENDIF

    aData := _ArtCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "CATALOGO DE ARTICULOS" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Codigo",      10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Descripcion",  40, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "Familia",      3, "@!",         { |a| a[3] } )
    oGrid:AddColumn( "Stock",        12, "999,999.99", { |a| a[4] } )
    oGrid:AddColumn( "Precio",       12, "999,999.99", { |a| a[5] } )
    oGrid:AddColumn( "IVA %",         6, "99.99",      { |a| a[6] } )
    oGrid:AddColumn( "Baja",          4, "@!",         { |a| If( a[7], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        ArticulosForm( .F., g:CurrentRow()[1] ), ;
        aData := _ArtCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "Letras: busqueda por descripcion. ENTER: editar. F5: nuevo.", oWin )

    oBtNvo := TButton():New( 33, 2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| ArticulosForm( .T., "" ), ;
            aData := _ArtCargar(), ;
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

    Select( nArea )

RETURN NIL


STATIC FUNCTION _ArtCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "ART" )
    OrdSetFocus( "ART_DES" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( ART->CODIGO   ), ;
                AllTrim( ART->DESCRIP  ), ;
                AllTrim( ART->FAMILIA  ), ;
                ART->STOCK, ;
                ART->PRECIO, ;
                ART->IVA, ;
                ART->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


// ============================================================================
// ArticulosForm()
// ============================================================================
FUNCTION ArticulosForm( lNuevo, cCodigo )

    LOCAL oWin
    LOCAL nArea
    //LOCAL cCodigo
    LOCAL cDescrip
    LOCAL cFamilia
    LOCAL cProveed
    LOCAL cCodBarr
    LOCAL cUnidad
    LOCAL nStock
    LOCAL nStoMin
    LOCAL nStoMax
    LOCAL lEsServ
    LOCAL cCtaVta
    LOCAL cCtaCom
    LOCAL nCosto
    LOCAL nPrecio
    LOCAL nIva
    LOCAL cTipoIva
    LOCAL nDescuent
    LOCAL lBaja
    LOCAL oGCod
    LOCAL oGDes
    LOCAL oGFam
    LOCAL oGPrv
    LOCAL oGCB
    LOCAL oGUni
    LOCAL oGSto
    LOCAL oGMin
    LOCAL oGMax
    LOCAL oChkSer
    LOCAL oGCtaV
    LOCAL oGCtaC
    LOCAL oGCost
    LOCAL oGPre
    LOCAL oGIva
    LOCAL oGTip
    LOCAL oGDesc
    LOCAL oChkBaj
    LOCAL oBtGua
    LOCAL oBtCan

    DEFAULT lNuevo  TO .T.
    DEFAULT cCodigo TO ""

    nArea     := Select()
    IF !ABRIR_TABLA( "ARTICULOS", "ART", "ART_COD" )
        RETURN NIL
    ENDIF

    IF lNuevo
        cCodigo   := Space( 10 )
        cDescrip  := Space( 60 )
        cFamilia  := Space(  3 )
        cProveed  := Space( 10 )
        cCodBarr  := Space( 15 )
        cUnidad   := Space(  3 )
        nStock    := 0.0000
        nStoMin   := 0.0000
        nStoMax   := 0.0000
        lEsServ   := .F.
        cCtaVta   := Space( 10 )
        cCtaCom   := Space( 10 )
        nCosto    := 0.0000
        nPrecio   := 0.00
        nIva      := 21.00
        cTipoIva  := Space(  1 )
        nDescuent := 0.00
        lBaja     := .F.
    ELSEIF !Empty( AllTrim( cCodigo ) )
        DbSelectArea( "ART" )
        OrdSetFocus( "ART_COD" )
        IF DbSeek( AllTrim( cCodigo ) )
            cCodigo  := PadR( AllTrim( ART->CODIGO   ), 10 )
            cDescrip := PadR( AllTrim( ART->DESCRIP  ), 60 )
            cFamilia := PadR( AllTrim( ART->FAMILIA  ),  3 )
            cProveed := PadR( AllTrim( ART->PROVEEDO ), 10 )
            cCodBarr := PadR( AllTrim( ART->COD_BARR ), 15 )
            cUnidad  := PadR( AllTrim( ART->UNIDAD   ),  3 )
            nStock   := ART->STOCK
            nStoMin  := ART->STO_MIN
            nStoMax  := ART->STO_MAX
            lEsServ  := ART->ES_SERV
            cCtaVta  := PadR( AllTrim( ART->CTA_VTA  ), 10 )
            cCtaCom  := PadR( AllTrim( ART->CTA_COM  ), 10 )
            nCosto   := ART->COSTO_PR
            nPrecio  := ART->PRECIO
            nIva     := ART->IVA
            cTipoIva := PadR( AllTrim( ART->TIPO_IVA ),  1 )
            nDescuent:= ART->DESCUENT
            lBaja    := ART->BAJA
        ENDIF
    ENDIF

    oWin := TWindow():New( 1, 2, 37, 129, ;
        If( lNuevo, "NUEVO ARTICULO", "EDITAR ARTICULO: " + AllTrim( cCodigo ) ) )

    oWin:AddCtrl( TLabel():New(  2,  2, "Codigo        :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Descripcion   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Familia       :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Proveedor     :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  2, "Cod.Barras    :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12,  2, "Unidad        :", oWin ) )
    oWin:AddCtrl( TLabel():New( 14,  2, "Stock         :", oWin ) )
    oWin:AddCtrl( TLabel():New( 16,  2, "Stock Min.    :", oWin ) )
    oWin:AddCtrl( TLabel():New( 18,  2, "Stock Max.    :", oWin ) )

    oWin:AddCtrl( TLabel():New(  2, 82, "Es servicio   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 82, "Cta. Venta   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 82, "Cta. Compra  :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 82, "Costo         :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10, 82, "Precio        :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12, 82, "IVA %         :", oWin ) )
    oWin:AddCtrl( TLabel():New( 14, 82, "Tipo IVA      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 16, 82, "Dto. %        :", oWin ) )

    oGCod   := TGet():New(  2, 20, cCodigo,  "@!",        oWin )
    oGCod:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    IF !lNuevo
        oGCod:lEnabled := .F.
    ENDIF

    oGDes   := TGet():New(  4, 20, cDescrip, "@!",        oWin )
    oGDes:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGFam   := TGet():New(  6, 20, cFamilia, "@!",        oWin )
    oGPrv   := TGet():New(  8, 20, cProveed, "@!",        oWin )
    oGCB    := TGet():New( 10, 20, cCodBarr, "@!",        oWin )
    oGUni   := TGet():New( 12, 20, cUnidad,  "@!",        oWin )
    oGSto   := TGet():New( 14, 20, nStock,   "999,999.99", oWin )
    oGMin   := TGet():New( 16, 20, nStoMin, "999,999.99", oWin )
    oGMax   := TGet():New( 18, 20, nStoMax, "999,999.99", oWin )

    oChkSer := TCheck():New(  2, 97, "Es servicio", lEsServ, oWin )
    oGCtaV  := TGet():New(  4, 97, cCtaVta, "@!",        oWin )
    oGCtaC  := TGet():New(  6, 97, cCtaCom, "@!",        oWin )
    oGCost  := TGet():New(  8, 97, nCosto,  "999,999.99", oWin )
    oGPre   := TGet():New( 10, 97, nPrecio, "999,999.99", oWin )
    oGIva   := TGet():New( 12, 97, nIva,    "99.99",      oWin )
    oGTip   := TGet():New( 14, 97, cTipoIva,"@!",         oWin )
    oGDesc  := TGet():New( 16, 97, nDescuent,"99.99",      oWin )

    oChkBaj := TCheck():New( 18, 82, "Baja", lBaja, oWin )

    oBtGua := TButton():New( 33, 40, 34, 59, oWin, "GUARDAR", ;
        {|| If( ArticuloGuardar( _ArtFormHash( oGCod, oGDes, oGFam, oGPrv, oGCB, oGUni, ;
                                                oGSto, oGMin, oGMax, oChkSer, ;
                                                oGCtaV, oGCtaC, oGCost, oGPre, ;
                                                oGIva, oGTip, oGDesc, oChkBaj ), ;
                                  lNuevo ), ;
                 oWin:Close(), NIL ) } )

    oBtCan := TButton():New( 33, 63, 34, 82, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGCod   )
    oWin:AddCtrl( oGDes   )
    oWin:AddCtrl( oGFam   )
    oWin:AddCtrl( oGPrv   )
    oWin:AddCtrl( oGCB    )
    oWin:AddCtrl( oGUni   )
    oWin:AddCtrl( oGSto   )
    oWin:AddCtrl( oGMin   )
    oWin:AddCtrl( oGMax   )
    oWin:AddCtrl( oChkSer )
    oWin:AddCtrl( oGCtaV  )
    oWin:AddCtrl( oGCtaC  )
    oWin:AddCtrl( oGCost  )
    oWin:AddCtrl( oGPre   )
    oWin:AddCtrl( oGIva   )
    oWin:AddCtrl( oGTip   )
    oWin:AddCtrl( oGDesc  )
    oWin:AddCtrl( oChkBaj )
    oWin:AddCtrl( oBtGua  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

    Select( nArea )

RETURN NIL


STATIC FUNCTION _ArtFormHash( oGC, oGD, oGF, oGP, oGB, oGU, ;
                              oGS, oGMi, oGMa, oChkS, ;
                              oCV, oCC, oCo, oGPr, oGI, oGT, oGDs, oChkB )

    LOCAL hArticulo := {=>}

    hArticulo[ "CODIGO"   ] := AllTrim( oGC:GetValue() )
    hArticulo[ "DESCRIP"  ] := AllTrim( oGD:GetValue() )
    hArticulo[ "FAMILIA"  ] := AllTrim( oGF:GetValue() )
    hArticulo[ "PROVEEDO" ] := AllTrim( oGP:GetValue() )
    hArticulo[ "COD_BARR" ] := AllTrim( oGB:GetValue() )
    hArticulo[ "UNIDAD"   ] := AllTrim( oGU:GetValue() )
    hArticulo[ "STOCK"    ] := oGS:GetValue()
    hArticulo[ "STO_MIN"  ] := oGMi:GetValue()
    hArticulo[ "STO_MAX"  ] := oGMa:GetValue()
    hArticulo[ "ES_SERV"  ] := oChkS:GetValue()
    hArticulo[ "CTA_VTA"  ] := AllTrim( oCV:GetValue() )
    hArticulo[ "CTA_COM"  ] := AllTrim( oCC:GetValue() )
    hArticulo[ "COSTO_PR" ] := oCo:GetValue()
    hArticulo[ "PRECIO"   ] := oGPr:GetValue()
    hArticulo[ "IVA"      ] := oGI:GetValue()
    hArticulo[ "TIPO_IVA" ] := AllTrim( oGT:GetValue() )
    hArticulo[ "DESCUENT" ] := oGDs:GetValue()
    hArticulo[ "BAJA"     ] := oChkB:GetValue()

RETURN hArticulo


FUNCTION ArticuloGuardar( hArticulo, lNuevo )

    LOCAL cCodigo

    cCodigo := hArticulo[ "CODIGO" ]

    DbSelectArea( "ART" )
    OrdSetFocus( "ART_COD" )

    IF lNuevo
        IF DbSeek( cCodigo )
            MsgStop( "El codigo " + cCodigo + " ya existe.", "Alta articulo" )
            RETURN .F.
        ENDIF
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCodigo )
            RETURN .F.
        ENDIF
        IF !NetRLock()
            RETURN .F.
        ENDIF
    ENDIF

    REPLACE ART->CODIGO   WITH cCodigo
    REPLACE ART->DESCRIP  WITH hArticulo[ "DESCRIP"  ]
    REPLACE ART->FAMILIA  WITH hArticulo[ "FAMILIA"  ]
    REPLACE ART->PROVEEDO WITH hArticulo[ "PROVEEDO" ]
    REPLACE ART->COD_BARR WITH hArticulo[ "COD_BARR" ]
    REPLACE ART->UNIDAD   WITH hArticulo[ "UNIDAD"   ]
    REPLACE ART->STOCK    WITH hArticulo[ "STOCK"    ]
    REPLACE ART->STO_MIN  WITH hArticulo[ "STO_MIN"  ]
    REPLACE ART->STO_MAX  WITH hArticulo[ "STO_MAX"  ]
    REPLACE ART->ES_SERV  WITH hArticulo[ "ES_SERV"  ]
    REPLACE ART->CTA_VTA  WITH hArticulo[ "CTA_VTA"  ]
    REPLACE ART->CTA_COM  WITH hArticulo[ "CTA_COM"  ]
    REPLACE ART->COSTO_PR WITH hArticulo[ "COSTO_PR" ]
    REPLACE ART->PRECIO   WITH hArticulo[ "PRECIO"   ]
    REPLACE ART->IVA      WITH hArticulo[ "IVA"      ]
    REPLACE ART->TIPO_IVA WITH hArticulo[ "TIPO_IVA" ]
    REPLACE ART->DESCUENT WITH hArticulo[ "DESCUENT" ]
    REPLACE ART->BAJA     WITH hArticulo[ "BAJA"     ]

    IF lNuevo
        REPLACE ART->FECHA_AL WITH Date()
    ENDIF

    DbCommit()
    DbUnlock()

RETURN .T.


// ============================================================================
// FIN DE M_Articulos.prg
// ============================================================================
