/*
 * ARCHIVO  : M_Sistemas.prg
 * PROPOSITO: Mantenimiento de sistemas constructivos y rendimientos SYS_REND.
 */

#include "OOp.ch"


// ============================================================================
// SistemasView()
// ============================================================================
FUNCTION SistemasView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtCab
    LOCAL oBtLin
    LOCAL oBtSal
    LOCAL aData
    LOCAL nArea := Select()

    IF !ABRIR_TABLA( "SYS_REND", "SYS", "SR_SIS" )
        MsgStop( "No se pudo abrir SYS_REND.", "Sistemas" )
        RETURN NIL
    ENDIF

    aData := _SisCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "SISTEMAS CONSTRUCTIVOS" )
    oGrid := TGrid():New( 2, 2, 29, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 1

    oGrid:AddColumn( "Sistema",     20, "@!",     { |a| a[1] } )
    oGrid:AddColumn( "Tipo obra",   15, "@!",     { |a| a[2] } )
    oGrid:AddColumn( "Descripcion", 42, "@!",     { |a| a[3] } )
    oGrid:AddColumn( "Modul",        6, "9.99",   { |a| a[4] } )
    oGrid:AddColumn( "Sep.Pr",        6, "9.99",   { |a| a[5] } )
    oGrid:AddColumn( "Car",           3, "9",      { |a| a[6] } )
    oGrid:AddColumn( "Cap",           3, "9",      { |a| a[7] } )
    oGrid:AddColumn( "Ancho",         5, "999",    { |a| a[8] } )
    oGrid:AddColumn( "Lin",           4, "999",    { |a| a[9] } )

    oGrid:bEnter := {| g | ;
        If( g:CurrentRow() != NIL, _SisLineas( g:CurrentRow()[1] ), NIL ), ;
        aData := _SisCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oBtNvo := TButton():New( 31, 2, 32, 18, oWin, "NUEVO (F5)", ;
        {|| _SisNuevo( oGrid ) } )

    oBtCab := TButton():New( 31, 21, 32, 39, oWin, "CABECERA", ;
        {|| _SisEditarCab( oGrid ) } )

    oBtLin := TButton():New( 31, 42, 32, 60, oWin, "RENDIMIENTOS", ;
        {|| If( oGrid:CurrentRow() != NIL, _SisLineas( oGrid:CurrentRow()[1] ), NIL ), ;
            aData := _SisCargar(), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 31, 108, 32, 124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtCab )
    oWin:AddCtrl( oBtLin )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    IF Select( "SYS" ) > 0
        SYS->( DbCloseArea() )
    ENDIF

    IF nArea > 0
        Select( nArea )
    ENDIF

RETURN NIL


STATIC FUNCTION _SisNuevo( oGrid )

    LOCAL aData
    LOCAL cSis

    cSis := _SisCabForm( NIL, .T. )
    IF !Empty( cSis )
        _SisLineas( cSis )
    ENDIF

    aData := _SisCargar()
    oGrid:aData := aData
    oGrid:nCurRow := Max( 1, Len( aData ) )
    oGrid:Paint()

RETURN NIL


STATIC FUNCTION _SisEditarCab( oGrid )

    LOCAL aRow := oGrid:CurrentRow()
    LOCAL aData

    IF aRow == NIL
        RETURN NIL
    ENDIF

    _SisCabForm( aRow, .F. )
    aData := _SisCargar()
    oGrid:aData := aData
    oGrid:Paint()

RETURN NIL


STATIC FUNCTION _SisCargar()

    LOCAL aData := {}
    LOCAL hPos := {=>}
    LOCAL cSis
    LOCAL nPos

    DbSelectArea( "SYS" )
    OrdSetFocus( "SR_SIS" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            cSis := Upper( AllTrim( SYS->SISTEMA_ID ) )
            IF !Empty( cSis )
                IF hb_HHasKey( hPos, cSis )
                    nPos := hPos[ cSis ]
                    aData[nPos, 9]++
                ELSE
                    AAdd( aData, { ;
                        cSis, ;
                        AllTrim( SYS->TIPO_OBRA ), ;
                        AllTrim( SYS->DESC_SIS ), ;
                        SYS->MODUL, ;
                        If( FieldPos( "SEP_PRIM" ) > 0, SYS->SEP_PRIM, 0 ), ;
                        SYS->CARAS, ;
                        SYS->CAPAS, ;
                        SYS->ANCHO_PERF, ;
                        1 } )
                    hPos[ cSis ] := Len( aData )
                ENDIF
            ENDIF
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


// ============================================================================
// Cabecera del sistema
// ============================================================================
STATIC FUNCTION _SisCabForm( aRow, lNuevo )

    LOCAL oWin
    LOCAL oGSis
    LOCAL oGTip
    LOCAL oGDes
    LOCAL oGMod
    LOCAL oGSep
    LOCAL oGCar
    LOCAL oGCap
    LOCAL oGAnc
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL cOldSis
    LOCAL cSis
    LOCAL cTipo
    LOCAL cDesc
    LOCAL nMod
    LOCAL nSepPrim
    LOCAL nCaras
    LOCAL nCapas
    LOCAL nAncho
    LOCAL lSave := .F.

    DEFAULT lNuevo TO .F.

    cOldSis := ""
    cSis    := Space( 20 )
    cTipo   := Space( 15 )
    cDesc   := Space( 60 )
    nMod    := 0.60
    nSepPrim := 0
    nCaras  := 1
    nCapas  := 1
    nAncho  := 0

    IF !lNuevo .AND. aRow != NIL
        cOldSis := aRow[1]
        cSis    := PadR( aRow[1], 20 )
        cTipo   := PadR( aRow[2], 15 )
        cDesc   := PadR( aRow[3], 60 )
        nMod    := aRow[4]
        nSepPrim := aRow[5]
        nCaras  := aRow[6]
        nCapas  := aRow[7]
        nAncho  := aRow[8]
    ENDIF

    oWin := TWindow():New( 7, 20, 27, 115, ;
        If( lNuevo, "NUEVO SISTEMA", "EDITAR SISTEMA" ) )
    oWin:lStatusBar := .T.
    oWin:SetStatus( "ORDEN 0 se usa como cabecera; las demas lineas son rendimientos." )

    oWin:AddCtrl( TLabel():New(  2, 3, "Sistema ID :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 3, "Tipo obra  :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 3, "Descripcion:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 3, "Modulacion :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10, 3, "Sep. prim. :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12, 3, "Caras      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 14, 3, "Capas      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 16, 3, "Ancho perf.:", oWin ) )

    oGSis := TGet():New(  2, 17, cSis,   "@!",   oWin )
    oGTip := TGet():New(  4, 17, cTipo,  "@!",   oWin )
    oGDes := TGet():New(  6, 17, cDesc,  "@!",   oWin )
    oGMod := TGet():New(  8, 17, nMod,   "9.99", oWin )
    oGSep := TGet():New( 10, 17, nSepPrim, "9.99", oWin )
    oGCar := TGet():New( 12, 17, nCaras, "9",    oWin )
    oGCap := TGet():New( 14, 17, nCapas, "9",    oWin )
    oGAnc := TGet():New( 16, 17, nAncho, "999",  oWin )

    oGSis:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    oGTip:bValid := {| o | TipoObraDrywallValido( Upper( AllTrim( o:cBuffer ) ) ) .OR. ;
                            ( MsgStop( "Tipo obra no valido.", "Sistema" ), .F. ) }
    oGMod:bValid := {| o | o:uVar >= 0 }
    oGSep:bValid := {| o | o:uVar >= 0 }
    oGCar:bValid := {| o | o:uVar >= 0 .AND. o:uVar <= 2 }
    oGCap:bValid := {| o | o:uVar >= 0 .AND. o:uVar <= 5 }

    IF !lNuevo
        oGSis:lEnabled := .F.
    ENDIF

    oBtGua := TButton():New( 18, 18, 19, 36, oWin, "GUARDAR", ;
        {|| lSave := _SisGuardarCab( cOldSis, ;
                    _SisCabHash( oGSis, oGTip, oGDes, oGMod, oGSep, oGCar, oGCap, oGAnc ), ;
                    lNuevo ), ;
            If( lSave, oWin:Close(), NIL ) } )

    oBtCan := TButton():New( 18, 40, 19, 58, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGSis )
    oWin:AddCtrl( oGTip )
    oWin:AddCtrl( oGDes )
    oWin:AddCtrl( oGMod )
    oWin:AddCtrl( oGSep )
    oWin:AddCtrl( oGCar )
    oWin:AddCtrl( oGCap )
    oWin:AddCtrl( oGAnc )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lSave
        RETURN Upper( AllTrim( oGSis:GetValue() ) )
    ENDIF

RETURN ""


STATIC FUNCTION _SisCabHash( oGSis, oGTip, oGDes, oGMod, oGSep, oGCar, oGCap, oGAnc )

    LOCAL h := {=>}

    h[ "SISTEMA_ID" ] := Upper( AllTrim( oGSis:GetValue() ) )
    h[ "TIPO_OBRA"  ] := Upper( AllTrim( oGTip:GetValue() ) )
    h[ "DESC_SIS"   ] := AllTrim( oGDes:GetValue() )
    h[ "MODUL"      ] := oGMod:GetValue()
    h[ "SEP_PRIM"   ] := oGSep:GetValue()
    h[ "CARAS"      ] := oGCar:GetValue()
    h[ "CAPAS"      ] := oGCap:GetValue()
    h[ "ANCHO_PERF" ] := oGAnc:GetValue()

RETURN h


STATIC FUNCTION _SisGuardarCab( cOldSis, h, lNuevo )

    LOCAL cSis := h[ "SISTEMA_ID" ]
    LOCAL lFound := .F.

    DbSelectArea( "SYS" )
    OrdSetFocus( "SR_SIS" )

    IF lNuevo
        IF _SisExiste( cSis )
            MsgStop( "El sistema " + cSis + " ya existe.", "Alta sistema" )
            RETURN .F.
        ENDIF

        IF !NetFLock()
            MsgStop( "No se pudo bloquear SYS_REND.", "Alta sistema" )
            RETURN .F.
        ENDIF

        DbAppend()
        _SisReplaceHeader( h )
        REPLACE SYS->ORDEN      WITH 0
        REPLACE SYS->FAMILIA    WITH "SISTEMA"
        REPLACE SYS->ROL_MAT    WITH "INFO"
        REPLACE SYS->CODIGO_DEF WITH ""
        REPLACE SYS->UD_TEC     WITH ""
        REPLACE SYS->REND_M2    WITH 0
        REPLACE SYS->L_EDIT     WITH .T.
        DbCommit()
        DbUnlock()
        RETURN .T.
    ENDIF

    DbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. Upper( AllTrim( SYS->SISTEMA_ID ) ) == Upper( AllTrim( cOldSis ) )
            lFound := .T.
            IF NetRLock()
                _SisReplaceHeader( h )
                DbCommit()
                DbUnlock()
            ENDIF
        ENDIF
        DbSkip()
    ENDDO

    IF !lFound
        MsgStop( "No se encontro el sistema " + cOldSis + ".", "Sistema" )
    ENDIF

RETURN lFound


STATIC FUNCTION _SisReplaceHeader( h )

    REPLACE SYS->SISTEMA_ID WITH h[ "SISTEMA_ID" ]
    REPLACE SYS->TIPO_OBRA  WITH h[ "TIPO_OBRA"  ]
    REPLACE SYS->DESC_SIS   WITH h[ "DESC_SIS"   ]
    REPLACE SYS->MODUL      WITH h[ "MODUL"      ]
    IF FieldPos( "SEP_PRIM" ) > 0
        REPLACE SYS->SEP_PRIM WITH h[ "SEP_PRIM" ]
    ENDIF
    REPLACE SYS->CARAS      WITH h[ "CARAS"      ]
    REPLACE SYS->CAPAS      WITH h[ "CAPAS"      ]
    REPLACE SYS->ANCHO_PERF WITH h[ "ANCHO_PERF" ]

RETURN NIL


STATIC FUNCTION _SisExiste( cSis )

    DbSelectArea( "SYS" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. Upper( AllTrim( SYS->SISTEMA_ID ) ) == Upper( AllTrim( cSis ) )
            RETURN .T.
        ENDIF
        DbSkip()
    ENDDO

RETURN .F.


// ============================================================================
// Lineas de rendimiento
// ============================================================================
STATIC FUNCTION _SisLineas( cSis )

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtEdi
    LOCAL oBtBor
    LOCAL oBtSal
    LOCAL aData

    cSis := Upper( AllTrim( cSis ) )
    aData := _LinCargar( cSis )

    oWin  := TWindow():New( 1, 2, 37, 129, "RENDIMIENTOS: " + cSis )
    oGrid := TGrid():New( 2, 2, 29, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 3

    oGrid:AddColumn( "Ord",       4, "9999",    { |a| a[1] } )
    oGrid:AddColumn( "Familia",  10, "@!",      { |a| a[2] } )
    oGrid:AddColumn( "Rol",      15, "@!",      { |a| a[3] } )
    oGrid:AddColumn( "Cod.Def",  15, "@!",      { |a| a[4] } )
    oGrid:AddColumn( "Ud",        5, "@!",      { |a| a[5] } )
    oGrid:AddColumn( "Rend/m2",  12, "999.999", { |a| a[6] } )
    oGrid:AddColumn( "Edit",      4, "@!",      { |a| If( a[7], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        If( g:CurrentRow() != NIL, _LinForm( cSis, g:CurrentRow(), .F. ), NIL ), ;
        aData := _LinCargar( cSis ), ;
        g:aData := aData, ;
        g:Paint() }

    oBtNvo := TButton():New( 31, 2, 32, 18, oWin, "NUEVA", ;
        {|| _LinForm( cSis, NIL, .T. ), ;
            aData := _LinCargar( cSis ), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Max( 1, Len( aData ) ), ;
            oGrid:Paint() } )

    oBtEdi := TButton():New( 31, 21, 32, 37, oWin, "EDITAR", ;
        {|| If( oGrid:CurrentRow() != NIL, _LinForm( cSis, oGrid:CurrentRow(), .F. ), NIL ), ;
            aData := _LinCargar( cSis ), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } )

    oBtBor := TButton():New( 31, 40, 32, 56, oWin, "BORRAR", ;
        {|| _LinBorrar( cSis, oGrid:CurrentRow() ), ;
            aData := _LinCargar( cSis ), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 31, 108, 32, 124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtEdi )
    oWin:AddCtrl( oBtBor )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _LinCargar( cSis )

    LOCAL aData := {}

    DbSelectArea( "SYS" )
    OrdSetFocus( "SR_SIS" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. Upper( AllTrim( SYS->SISTEMA_ID ) ) == cSis
            AAdd( aData, { ;
                SYS->ORDEN, ;
                AllTrim( SYS->FAMILIA ), ;
                AllTrim( SYS->ROL_MAT ), ;
                AllTrim( SYS->CODIGO_DEF ), ;
                AllTrim( SYS->UD_TEC ), ;
                SYS->REND_M2, ;
                SYS->L_EDIT } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _LinForm( cSis, aRow, lNuevo )

    LOCAL oWin
    LOCAL oGOrd
    LOCAL oGFam
    LOCAL oGRol
    LOCAL oGCod
    LOCAL oGUd
    LOCAL oGRen
    LOCAL oChk
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL nOrden
    LOCAL cFam
    LOCAL cRol
    LOCAL cCod
    LOCAL cUd
    LOCAL nRend
    LOCAL lEdit
    LOCAL lSave := .F.

    DEFAULT lNuevo TO .F.

    nOrden := _LinNextOrden( cSis )
    cFam   := Space( 10 )
    cRol   := Space( 15 )
    cCod   := Space( 15 )
    cUd    := Space( 5 )
    nRend  := 0
    lEdit  := .T.

    IF !lNuevo .AND. aRow != NIL
        nOrden := aRow[1]
        cFam   := PadR( aRow[2], 10 )
        cRol   := PadR( aRow[3], 15 )
        cCod   := PadR( aRow[4], 15 )
        cUd    := PadR( aRow[5], 5 )
        nRend  := aRow[6]
        lEdit  := aRow[7]
    ENDIF

    oWin := TWindow():New( 7, 22, 28, 111, ;
        If( lNuevo, "NUEVO RENDIMIENTO", "EDITAR RENDIMIENTO" ) )
    oWin:lStatusBar := .T.
    oWin:SetStatus( "Techo: PERF_SEC, PERF_PRI, PERF_PER, PLACA_A y componentes CUELGUE_*" )

    oWin:AddCtrl( TLabel():New(  2, 3, "Orden      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 3, "Familia    :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 3, "Rol mat.   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 3, "Codigo def.:", oWin ) )
    oWin:AddCtrl( TLabel():New( 10, 3, "Ud tecnica :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12, 3, "Rend/m2    :", oWin ) )

    oGOrd := TGet():New(  2, 17, nOrden, "9999",    oWin )
    oGFam := TGet():New(  4, 17, cFam,   "@!",      oWin )
    oGRol := TGet():New(  6, 17, cRol,   "@!",      oWin )
    oGCod := TGet():New(  8, 17, cCod,   "@!",      oWin )
    oGUd  := TGet():New( 10, 17, cUd,    "@!",      oWin )
    oGRen := TGet():New( 12, 17, nRend,  "999.999", oWin )
    oChk  := TCheck():New( 14, 17, "Editable", lEdit, oWin )

    oGOrd:bValid := {| o | o:uVar >= 0 }
    oGFam:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    oGRol:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    oGUd:bValid  := {| o | !Empty( AllTrim( o:cBuffer ) ) .OR. oGOrd:uVar == 0 }
    oGRen:bValid := {| o | o:uVar >= 0 }

    IF !lNuevo .AND. nOrden == 0
        oGOrd:lEnabled := .F.
        oGFam:lEnabled := .F.
        oGRol:lEnabled := .F.
    ENDIF

    oBtGua := TButton():New( 17, 18, 18, 36, oWin, "GUARDAR", ;
        {|| lSave := _LinGuardar( cSis, ;
                    _LinHash( oGOrd, oGFam, oGRol, oGCod, oGUd, oGRen, oChk ), ;
                    lNuevo, nOrden ), ;
            If( lSave, oWin:Close(), NIL ) } )

    oBtCan := TButton():New( 17, 40, 18, 58, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGOrd )
    oWin:AddCtrl( oGFam )
    oWin:AddCtrl( oGRol )
    oWin:AddCtrl( oGCod )
    oWin:AddCtrl( oGUd  )
    oWin:AddCtrl( oGRen )
    oWin:AddCtrl( oChk  )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

RETURN NIL


STATIC FUNCTION _LinHash( oGOrd, oGFam, oGRol, oGCod, oGUd, oGRen, oChk )

    LOCAL h := {=>}

    h[ "ORDEN"      ] := oGOrd:GetValue()
    h[ "FAMILIA"    ] := Upper( AllTrim( oGFam:GetValue() ) )
    h[ "ROL_MAT"    ] := Upper( AllTrim( oGRol:GetValue() ) )
    h[ "CODIGO_DEF" ] := Upper( AllTrim( oGCod:GetValue() ) )
    h[ "UD_TEC"     ] := Upper( AllTrim( oGUd:GetValue() ) )
    h[ "REND_M2"    ] := oGRen:GetValue()
    h[ "L_EDIT"     ] := oChk:GetValue()

RETURN h


STATIC FUNCTION _LinGuardar( cSis, hLin, lNuevo, nOldOrden )

    LOCAL hCab := _SisHeader( cSis )

    IF hCab == NIL
        MsgStop( "No se encontro la cabecera del sistema.", "Rendimientos" )
        RETURN .F.
    ENDIF

    DbSelectArea( "SYS" )

    IF lNuevo
        IF _LinExiste( cSis, hLin[ "ORDEN" ] )
            MsgStop( "Ya existe una linea con ese orden.", "Rendimientos" )
            RETURN .F.
        ENDIF
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
    ELSE
        IF !_LinSeek( cSis, nOldOrden )
            RETURN .F.
        ENDIF
        IF !NetRLock()
            RETURN .F.
        ENDIF
    ENDIF

    _SisReplaceHeader( hCab )
    REPLACE SYS->ORDEN      WITH hLin[ "ORDEN"      ]
    REPLACE SYS->FAMILIA    WITH hLin[ "FAMILIA"    ]
    REPLACE SYS->ROL_MAT    WITH hLin[ "ROL_MAT"    ]
    REPLACE SYS->CODIGO_DEF WITH hLin[ "CODIGO_DEF" ]
    REPLACE SYS->UD_TEC     WITH hLin[ "UD_TEC"     ]
    REPLACE SYS->REND_M2    WITH hLin[ "REND_M2"    ]
    REPLACE SYS->L_EDIT     WITH hLin[ "L_EDIT"     ]
    DbCommit()
    DbUnlock()

RETURN .T.


STATIC FUNCTION _SisHeader( cSis )

    LOCAL h := NIL

    DbSelectArea( "SYS" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. Upper( AllTrim( SYS->SISTEMA_ID ) ) == cSis
            h := {=>}
            h[ "SISTEMA_ID" ] := cSis
            h[ "TIPO_OBRA"  ] := AllTrim( SYS->TIPO_OBRA )
            h[ "DESC_SIS"   ] := AllTrim( SYS->DESC_SIS )
            h[ "MODUL"      ] := SYS->MODUL
            h[ "SEP_PRIM"   ] := If( FieldPos( "SEP_PRIM" ) > 0, SYS->SEP_PRIM, 0 )
            h[ "CARAS"      ] := SYS->CARAS
            h[ "CAPAS"      ] := SYS->CAPAS
            h[ "ANCHO_PERF" ] := SYS->ANCHO_PERF
            EXIT
        ENDIF
        DbSkip()
    ENDDO

RETURN h


STATIC FUNCTION _LinNextOrden( cSis )

    LOCAL nMax := 0

    DbSelectArea( "SYS" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. Upper( AllTrim( SYS->SISTEMA_ID ) ) == cSis
            IF SYS->ORDEN > nMax
                nMax := SYS->ORDEN
            ENDIF
        ENDIF
        DbSkip()
    ENDDO

RETURN nMax + 10


STATIC FUNCTION _LinExiste( cSis, nOrden )

    RETURN _LinSeek( cSis, nOrden )


STATIC FUNCTION _LinSeek( cSis, nOrden )

    DbSelectArea( "SYS" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. ;
           Upper( AllTrim( SYS->SISTEMA_ID ) ) == cSis .AND. ;
           SYS->ORDEN == nOrden
            RETURN .T.
        ENDIF
        DbSkip()
    ENDDO

RETURN .F.


STATIC FUNCTION _LinBorrar( cSis, aRow )

    IF aRow == NIL
        RETURN NIL
    ENDIF

    IF aRow[1] == 0
        MsgStop( "La linea 0 es la cabecera del sistema y no se puede borrar.", "Rendimientos" )
        RETURN NIL
    ENDIF

    IF !MsgYesNo( "Borrar linea " + AllTrim( Str( aRow[1] ) ) + " del sistema " + cSis + "?", ;
                  "Rendimientos" )
        RETURN NIL
    ENDIF

    IF _LinSeek( cSis, aRow[1] )
        IF NetRLock()
            DbDelete()
            DbCommit()
            DbUnlock()
        ENDIF
    ENDIF

RETURN NIL
