#include "OOp.ch"

FUNCTION PartidasView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtEdt
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    IF !ABRIR_TABLA( "PARTIDAS", "PAR", "PAR_DES" )
        RETURN NIL
    ENDIF

    aData := _ParCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "CATALOGO DE PARTIDAS TECNICAS" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Codigo",     10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Descripcion",53, "@!",          { |a| a[2] } )
    oGrid:AddColumn( "Precio",     12, "999,999.99", { |a| a[3] } )
    oGrid:AddColumn( "IVA %",       6, "99.99",      { |a| a[4] } )
    oGrid:AddColumn( "Ud.",         4, "@!",          { |a| a[5] } )
    oGrid:AddColumn( "Baja",        4, "@!",          { |a| If( a[6], "SI", "NO" ) } )

    oGrid:bEnter := {| g | _ParForm( g:CurrentRow()[1], @aData, oGrid ) }

    oLbl := TLabel():New( 32, 2, ;
        "ENTER: editar   F5: nueva partida   Letras: buscar", oWin )

    oBtNvo := TButton():New( 33,  2, 34, 18, oWin, "NUEVA (F5)", ;
        {|| _ParForm( "", @aData, oGrid ), ;
            aData := _ParCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtEdt := TButton():New( 33, 20, 34, 36, oWin, "EDITAR", ;
        {|| If( oGrid:CurrentRow() != NIL, ;
                _ParForm( oGrid:CurrentRow()[1], @aData, oGrid ), NIL ) } )

    oBtSal := TButton():New( 33,108, 34,124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLbl   )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtEdt )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    PAR->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _ParCargar()

    LOCAL aData := {}

    DbSelectArea( "PAR" )
    OrdSetFocus( "PAR_DES" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( PAR->CODIGO   ), ;
                AllTrim( PAR->DESCRIP  ), ;
                PAR->PRECIO, ;
                PAR->PORC_IVA, ;
                AllTrim( DbFieldValue( "UNIDAD", "" ) ), ;
                DbFieldValue( "BAJA", .F. ) } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _ParForm( cCod, aData, oGrid )

    LOCAL oWin
    LOCAL lNuevo := Empty( AllTrim( cCod ) )
    LOCAL nArea  := Select()
    LOCAL cCod_  := Space( 10 )
    LOCAL cDesc  := Space( 60 )
    LOCAL nPre   := 0.00
    LOCAL nIva   := 21.00
    LOCAL cUd    := Space( 3 )
    LOCAL lBaja  := .F.
    LOCAL oGCod
    LOCAL oGDes
    LOCAL oGPre
    LOCAL oGIva
    LOCAL oGUd
    LOCAL oChkBaja
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL lOK    := .F.

    IF !lNuevo
        IF ABRIR_TABLA( "PARTIDAS", "PAR_F", "PAR_COD" )
            DbSelectArea( "PAR_F" )
            OrdSetFocus( "PAR_COD" )
            IF DbSeek( PadR( AllTrim( cCod ), 10 ) )
                cCod_  := PadR( AllTrim( PAR_F->CODIGO ), 10 )
                cDesc  := PadR( AllTrim( PAR_F->DESCRIP ), 60 )
                nPre   := PAR_F->PRECIO
                nIva   := PAR_F->PORC_IVA
                cUd    := PadR( AllTrim( DbFieldValue( "UNIDAD", "" ) ), 3 )
                lBaja  := DbFieldValue( "BAJA", .F. )
            ENDIF
            PAR_F->( DbCloseArea() )
        ENDIF
    ENDIF

    oWin := TWindow():New( 6, 12, 28, 118, ;
        If( lNuevo, "NUEVA PARTIDA TECNICA", "EDITAR PARTIDA: " + AllTrim( cCod_ ) ) )

    oWin:AddCtrl( TLabel():New(  2,  3, "Codigo     :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  3, "Descripcion:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  3, "Precio     :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  3, "IVA %      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  3, "Unidad     :", oWin ) )

    oGCod := TGet():New( 2, 18, cCod_, "@!", oWin )
    oGCod:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    IF !lNuevo
        oGCod:lEnabled := .F.
    ENDIF

    oGDes := TGet():New(  4, 18, cDesc, "@!",        oWin )
    oGDes:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGPre := TGet():New(  6, 18, nPre,  "999,999.99", oWin )
    oGIva := TGet():New(  8, 18, nIva,  "99.99",      oWin )
    oGUd  := TGet():New( 10, 18, cUd,   "@!",         oWin )

    oChkBaja := TCheck():New( 12, 18, "Baja", lBaja, oWin )

    oBtGua := TButton():New( 18, 34, 19, 53, oWin, "GUARDAR", ;
        {|| lOK := _ParGuardar( lNuevo, oGCod, oGDes, oGPre, oGIva, oGUd, oChkBaja ), ;
            If( lOK, ( oGrid:aData := _ParCargar(), oGrid:Paint(), oWin:Close() ), NIL ) } )

    oBtCan := TButton():New( 18, 57, 19, 76, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGCod    )
    oWin:AddCtrl( oGDes    )
    oWin:AddCtrl( oGPre    )
    oWin:AddCtrl( oGIva    )
    oWin:AddCtrl( oGUd     )
    oWin:AddCtrl( oChkBaja )
    oWin:AddCtrl( oBtGua   )
    oWin:AddCtrl( oBtCan   )

    oWin:Run()

    Select( nArea )

RETURN NIL


STATIC FUNCTION _ParGuardar( lNuevo, oGCod, oGDes, oGPre, oGIva, oGUd, oChkBaja )

    LOCAL cCod  := AllTrim( oGCod:GetValue() )
    LOCAL cDesc := AllTrim( oGDes:GetValue() )
    LOCAL nPre  := oGPre:GetValue()
    LOCAL nIva  := oGIva:GetValue()
    LOCAL cUd   := AllTrim( oGUd:GetValue() )
    LOCAL lBaja := oChkBaja:GetValue()
    LOCAL nArea := Select()

    IF !ABRIR_TABLA( "PARTIDAS", "PAR_G", "PAR_COD" )
        Select( nArea )
        RETURN .F.
    ENDIF

    DbSelectArea( "PAR_G" )
    OrdSetFocus( "PAR_COD" )

    IF lNuevo
        IF DbSeek( PadR( cCod, 10 ) )
            PAR_G->( DbCloseArea() )
            MsgStop( "Ya existe una partida con codigo " + cCod, "Guardar" )
            Select( nArea )
            RETURN .F.
        ENDIF
        IF !NetFLock()
            PAR_G->( DbCloseArea() )
            Select( nArea )
            RETURN .F.
        ENDIF
        DbAppend()
        REPLACE PAR_G->CODIGO WITH PadR( cCod, 10 )
    ELSE
        IF !DbSeek( PadR( cCod, 10 ) )
            PAR_G->( DbCloseArea() )
            Select( nArea )
            RETURN .F.
        ENDIF
        IF !NetRLock()
            PAR_G->( DbCloseArea() )
            Select( nArea )
            RETURN .F.
        ENDIF
    ENDIF

    REPLACE PAR_G->DESCRIP  WITH PadR( cDesc, 60 )
    REPLACE PAR_G->PRECIO   WITH nPre
    REPLACE PAR_G->PORC_IVA WITH nIva
    IF !Empty( cUd )
        REPLACE PAR_G->UNIDAD WITH PadR( cUd, 3 )
    ENDIF
    REPLACE PAR_G->BAJA     WITH lBaja

    DbCommit()
    DbUnlock()
    PAR_G->( DbCloseArea() )
    Select( nArea )

RETURN .T.


FUNCTION PartidaLookup( cCod )

    LOCAL aData := {}
    LOCAL aCombo := {}
    LOCAL i
    LOCAL nArea := Select()

    IF !ABRIR_TABLA( "PARTIDAS", "PAR_L", "PAR_DES" )
        Select( nArea )
        RETURN NIL
    ENDIF

    DbSelectArea( "PAR_L" )
    OrdSetFocus( "PAR_DES" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. !DbFieldValue( "BAJA", .F. )
            AAdd( aData, { ;
                AllTrim( PAR_L->CODIGO ), ;
                AllTrim( PAR_L->DESCRIP ), ;
                PAR_L->PRECIO, ;
                PAR_L->PORC_IVA, ;
                AllTrim( DbFieldValue( "UNIDAD", "" ) ) } )
        ENDIF
        DbSkip()
    ENDDO

    PAR_L->( DbCloseArea() )
    Select( nArea )

    IF Empty( aData )
        Return NIL
    ENDIF

    FOR i := 1 TO Len( aData )
        AAdd( aCombo, { i, AllTrim( aData[i, 2] ) + "  (" + ;
                        Transform( aData[i, 3], "999,999.99" ) + ")" } )
    NEXT

    i := PopupSelect( "SELECCIONAR PARTIDA TECNICA", aCombo, ;
                       { { "Descripcion", 72, "@!", 2 } }, 1 )

    IF i > 0 .AND. i <= Len( aData )
        cCod := aData[i, 1]
    ENDIF

RETURN cCod
