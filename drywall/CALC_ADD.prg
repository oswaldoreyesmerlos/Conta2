/*
 * ARCHIVO  : CALC_ADD.prg
 * PROPOSITO: Altas Especializadas (Tabique, Techo, Trasdosado)
 * MIGRADO A: GfxStack API
 */

#include "OOp.ch"

#define LIN_NUM   1
#define LIN_DESC  2
#define LIN_CANT  3
#define LIN_PRE   4
#define LIN_IMP   5

// ============================================================================
// 1. ALTA DE TABIQUES (Doble Cara, Estructura Montante/Canal)
// ============================================================================
FUNCTION Add_Tabique( cTit )

    LOCAL hData

    hData := _InitData( "TABIQUE", cTit )
    IF hData == NIL
        RETURN .F.
    ENDIF

    hData["MODUL"]      := 0.60
    hData["NUM_PLACAS"] := 1
    hData["SAME_B"]     := "S"
    hData["AIS"]        := "N"
    hData["BANDA"]      := "N"
    hData["ANCHO_PERF"] := "48"

RETURN Form_Tabique( hData, .T. )


FUNCTION Form_Tabique( hData, lNuevo )

    LOCAL oWin
    LOCAL oGCon, oGLar, oGAlt, oGMod
    LOCAL oGAncho, oGPer1, oGPer2, oGPla1, oGPla2, oGNumP
    LOCAL oChkSame, oChkAis, oChkBand
    LOCAL oGAisCod
    LOCAL oBtBusP1, oBtBusP2, oBtBusA, oBtBusB, oBtBusAis
    LOCAL oBtGua, oBtCan, lSave := .F.
    LOCAL cTitulo := If( lNuevo, "NUEVO TABIQUE", "EDITAR TABIQUE" )
    LOCAL cBoton  := If( lNuevo, "GUARDAR", "ACTUALIZAR" )
    LOCAL lDiffB  := ( hData["SAME_B"] == "N" )
    LOCAL lAis    := ( hData["AIS"] == "S" )
    LOCAL lBand   := ( hData["BANDA"] == "S" )

    oWin := TWindow():New( 2, 5, 27, 105, cTitulo )

    // -- FILA 1: Concepto --
    oWin:AddCtrl( TLabel():New( 1,  2, "Concepto..:", oWin ) )
    oGCon := TGet():New( 1, 16, hData["CONCEPTO"], "@!", oWin )

    // -- FILA 2: Largo, Alto --
    oWin:AddCtrl( TLabel():New( 3,  2, "Largo (m).:", oWin ) )
    oGLar := TGet():New( 3, 16, hData["LARGO"],   "999.99", oWin )
    oWin:AddCtrl( TLabel():New( 3, 32, "Alto (m)..:", oWin ) )
    oGAlt := TGet():New( 3, 46, hData["ALTO"],    "999.99", oWin )

    // -- FILA 4: Modulacion, ancho de perfileria --
    oWin:AddCtrl( TLabel():New( 5,  2, "Modulacion:", oWin ) )
    oGMod := TGet():New( 5, 16, hData["MODUL"],  "9.99", oWin )
    oWin:AddCtrl( TLabel():New( 5, 32, "Ancho perf.:", oWin ) )
    oGAncho := TGet():New( 5, 46, hData["ANCHO_PERF"], "99", oWin )
    oGAncho:bValid := {|o| _ValidAnchoPerf( o ) }

    // -- FILA 6: Montante + buscar, Canal + buscar --
    oWin:AddCtrl( TLabel():New( 7,  2, "Montante..:", oWin ) )
    oGPer1 := TGet():New( 7, 16, hData["ID_PERFIL"], "@!", oWin )
    oBtBusP1 := TButton():New( 7, 48, 7, 62, oWin, "BUSCAR", {|| _BtnPick(oGPer1,hData,"ID_PERFIL","PERFIL") } )
    oWin:AddCtrl( TLabel():New( 9,  2, "Canal.....:", oWin ) )
    oGPer2 := TGet():New( 9, 16, hData["ID_PERFIL2"], "@!", oWin )
    oBtBusP2 := TButton():New( 9, 48, 9, 62, oWin, "BUSCAR", {|| _BtnPick(oGPer2,hData,"ID_PERFIL2","PERFIL") } )

    // -- FILA 10: Placa A + buscar, Capas --
    oWin:AddCtrl( TLabel():New( 11, 2, "Placa A...:", oWin ) )
    oGPla1 := TGet():New( 11,16, hData["ID_PLACA_A"], "@!", oWin )
    oBtBusA := TButton():New( 11,48, 11,62, oWin, "BUSCAR", {|| _BtnPick(oGPla1,hData,"ID_PLACA_A","PLACA") } )
    oWin:AddCtrl( TLabel():New( 11,66, "Capas:", oWin ) )
    oGNumP := TGet():New( 11,74, hData["NUM_PLACAS"], "9", oWin )
    oGNumP:bValid := {|o| o:uVar >=1 .AND. o:uVar <=5 .OR. (MsgStop("Maximo 5 capas","Validacion"),.F.) }

    // -- FILA 12: Cara B distinta de A (habilita placa B) --
    oChkSame := TCheck():New( 13,16, "Cara B distinta de A", lDiffB, oWin )
    oChkSame:bChange := {|| _TabqToggleSame( oChkSame, oGPla2, oBtBusB, hData ) }

    // -- FILA 13: Placa B + buscar (solo si es distinta) --
    oWin:AddCtrl( TLabel():New( 14, 2, "Placa B...:", oWin ) )
    oGPla2 := TGet():New( 14,16, hData["ID_PLACA_B"], "@!", oWin )
    oGPla2:lEnabled := lDiffB
    oBtBusB := TButton():New( 14,48, 14,62, oWin, "BUSCAR", {|| _BtnPick(oGPla2,hData,"ID_PLACA_B","PLACA") } )
    oBtBusB:lEnabled := lDiffB

    // -- FILA 15: Lana de roca (checkbox) --
    oChkAis := TCheck():New( 16,16, "Lana de roca", lAis, oWin )
    oChkAis:bChange := {|| _TabqToggleAis( oChkAis, oGAisCod, oBtBusAis, hData ) }

    // -- FILA 16: Mat Aislante + buscar (deshabilitado si no Ais) --
    oWin:AddCtrl( TLabel():New( 17, 2, "Aislante..:", oWin ) )
    oGAisCod := TGet():New( 17,16, hData["ID_AISLAN"], "@!", oWin )
    oGAisCod:lEnabled := lAis
    oBtBusAis := TButton():New( 17,48, 17,62, oWin, "BUSCAR", {|| _BtnPick(oGAisCod,hData,"ID_AISLAN","AISLAN") } )
    oBtBusAis:lEnabled := lAis

    // -- FILA 18: Banda Acustica (checkbox) --
    oChkBand := TCheck():New( 19,16, "Banda Acustica", lBand, oWin )
    oChkBand:bChange := {|| hData["BANDA"] := If( oChkBand:GetValue(), "S", "N" ) }

    // -- Botones --
    oBtGua := TButton():New( 23,30, 24,49, oWin, cBoton, {|| lSave := .T., oWin:Close() } )
    oBtCan := TButton():New( 23,52, 24,71, oWin, "CANCELAR", {|| oWin:Close() } )

    // -- AddCtrl ordenado para foco correcto --
    oWin:AddCtrl( oGCon )
    oWin:AddCtrl( oGLar )
    oWin:AddCtrl( oGAlt )
    oWin:AddCtrl( oGMod )
    oWin:AddCtrl( oGAncho )
    oWin:AddCtrl( oGPer1 )
    oWin:AddCtrl( oBtBusP1 )
    oWin:AddCtrl( oGPer2 )
    oWin:AddCtrl( oBtBusP2 )
    oWin:AddCtrl( oGPla1 )
    oWin:AddCtrl( oBtBusA )
    oWin:AddCtrl( oGNumP )
    oWin:AddCtrl( oChkSame )
    oWin:AddCtrl( oGPla2 )
    oWin:AddCtrl( oBtBusB )
    oWin:AddCtrl( oChkAis )
    oWin:AddCtrl( oGAisCod )
    oWin:AddCtrl( oBtBusAis )
    oWin:AddCtrl( oChkBand )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]    := oGCon:GetValue()
        hData["LARGO"]       := oGLar:GetValue()
        hData["ALTO"]        := oGAlt:GetValue()
        hData["MODUL"]       := oGMod:GetValue()
        hData["ANCHO_PERF"]  := _SysAncho( oGAncho:GetValue() )
        hData["ID_PERFIL"]   := oGPer1:GetValue()
        hData["ID_PERFIL2"]  := oGPer2:GetValue()
        hData["ID_PLACA_A"]  := oGPla1:GetValue()
        hData["NUM_PLACAS"]  := oGNumP:GetValue()
        hData["SAME_B"]      := If( oChkSame:GetValue(), "N", "S" )
        IF oChkSame:GetValue()
            hData["ID_PLACA_B"] := oGPla2:GetValue()
        ELSE
            hData["ID_PLACA_B"] := hData["ID_PLACA_A"]
        ENDIF
        hData["AIS"] := If( oChkAis:GetValue(), "S", "N" )
        IF oChkAis:GetValue()
            hData["ID_AISLAN"] := oGAisCod:GetValue()
        ELSE
            hData["ID_AISLAN"] := Space(15)
        ENDIF
        hData["BANDA"] := If( oChkBand:GetValue(), "S", "N" )
        hData["CARAS_REALES"] := 2
        IF lNuevo
            RETURN _CoreSave( hData )
        ENDIF
        RETURN UpdateTramoData( hData )
    ENDIF

RETURN .F.


STATIC FUNCTION _TabqToggleSame( oChk, oGPlB, oBtnB, hData )
    LOCAL lDiff := oChk:GetValue()
    oGPlB:lEnabled := lDiff
    oBtnB:lEnabled := lDiff
    IF !lDiff
        oGPlB:SetValue( Space(15) )
    ENDIF
    oGPlB:Paint()
    oBtnB:Paint()
    hData["SAME_B"] := If( lDiff, "N", "S" )
RETURN NIL


STATIC FUNCTION _TabqToggleAis( oChk, oGAisCod, oBtnAis, hData )
    LOCAL lAis := oChk:GetValue()
    oGAisCod:lEnabled := lAis
    oBtnAis:lEnabled := lAis
    IF !lAis
        oGAisCod:SetValue( Space(15) )
    ENDIF
    oGAisCod:Paint()
    oBtnAis:Paint()
    hData["AIS"] := If( lAis, "S", "N" )
RETURN NIL


STATIC FUNCTION _BtnPick( oGet, hData, cKey, cFam )
    LOCAL cRet

    cRet := _PickArt( cFam )
    IF !Empty( cRet )
        hData[ cKey ] := cRet
        oGet:SetValue( PadR( cRet, 15 ) )
    ENDIF

RETURN NIL


// ============================================================================
// 2. ALTA DE TECHOS
// ============================================================================
FUNCTION Add_Techo( cTit )

    LOCAL hData := _InitData( "TECHO", cTit )

    IF hData == NIL
        RETURN .F.
    ENDIF

    hData["MODUL"]      := 0.50
    hData["SEP_PRIM"]   := 1.00
    hData["NUM_PLACAS"] := 1
    hData["ID_PERFIL2"] := "0"

RETURN Form_Techo( hData, .T. )


FUNCTION Form_Techo( hData, lNuevo )

    LOCAL oWin
    LOCAL oGCon, oGLar, oGAnc
    LOCAL oGMod, oGSepP
    LOCAL oGPer1, oGPer2, oGPer3, oGAnc2
    LOCAL oGPla1, oGNumP
    LOCAL oBtBusP1, oBtBusP2, oBtBusP3, oBtBusAnc, oBtBusA
    LOCAL oBtGua, oBtCan, lSave := .F.
    LOCAL cTitulo := If( lNuevo, "NUEVO TECHO CONTINUO", "EDITAR TECHO" )
    LOCAL cBoton  := If( lNuevo, "GUARDAR", "ACTUALIZAR" )

    oWin := TWindow():New( 2, 5, 26, 95, cTitulo )

    // -- Concepto --
    oWin:AddCtrl( TLabel():New(  2,  2, "Concepto.....:", oWin ) )
    oGCon  := TGet():New( 2, 18, hData["CONCEPTO"], "@!",     oWin )

    // -- Largo --
    oWin:AddCtrl( TLabel():New(  4,  2, "Largo (m)....:", oWin ) )
    oGLar  := TGet():New( 4, 18, hData["LARGO"],    "999.99", oWin )

    // -- Ancho --
    oWin:AddCtrl( TLabel():New(  6,  2, "Ancho (m)....:", oWin ) )
    oGAnc  := TGet():New( 6, 18, hData["ALTO"],     "999.99", oWin )

    // -- Sep. Secundar --
    oWin:AddCtrl( TLabel():New(  8,  2, "Sep. Secundar:", oWin ) )
    oGMod  := TGet():New( 8, 18, hData["MODUL"],    "9.99",   oWin )

    // -- Sep. Primario --
    oWin:AddCtrl( TLabel():New( 10,  2, "Sep. Primario:", oWin ) )
    oGSepP := TGet():New(10, 18, hData["SEP_PRIM"], "9.99",   oWin )

    // -- Secundario --
    oWin:AddCtrl( TLabel():New( 12,  2, "Secundario...:", oWin ) )
    oGPer1 := TGet():New(12, 18, hData["ID_PERFIL"],  "@!", oWin )
    oBtBusP1 := TButton():New(12, 35, 12, 49, oWin, "BUSCAR", {|| _BtnPick( oGPer1, hData, "ID_PERFIL", "PERFIL" ) } )

    // -- Primario (opcional) --
    oWin:AddCtrl( TLabel():New( 14,  2, "Primario(opc):", oWin ) )
    oGPer2 := TGet():New(14, 18, hData["ID_PERFIL2"], "@!", oWin )
    oBtBusP2 := TButton():New(14, 35, 14, 49, oWin, "BUSCAR", {|| _BtnPick( oGPer2, hData, "ID_PERFIL2", "PERFIL" ) } )
    oGPer2:bValid := {|o| _TechoValidPrim( o, oBtBusP2, hData ) }
    oGSepP:bValid := {|o| _TechoValidSepPrim( o, oGPer2, oBtBusP2, hData ) }
    _TechoApplyPrimState( hData["SEP_PRIM"], oGPer2, oBtBusP2, hData )

    // -- Perimetral --
    oWin:AddCtrl( TLabel():New( 16,  2, "Perimetral...:", oWin ) )
    oGPer3 := TGet():New(16, 18, hData["ID_PERFIL3"], "@!", oWin )
    oBtBusP3 := TButton():New(16, 35, 16, 49, oWin, "BUSCAR", {|| _BtnPick( oGPer3, hData, "ID_PERFIL3", "PERFIL" ) } )

    // -- Anclaje/Susp. --
    oWin:AddCtrl( TLabel():New( 18,  2, "Anclaje/Susp.:", oWin ) )
    oGAnc2 := TGet():New(18, 18, hData["ID_ANCLAJE"], "@!", oWin )
    oBtBusAnc := TButton():New(18, 35, 18, 49, oWin, "BUSCAR", {|| _BtnPick( oGAnc2, hData, "ID_ANCLAJE", "ANCLAJE" ) } )

    // -- Placa --
    oWin:AddCtrl( TLabel():New( 20,  2, "Placa........:", oWin ) )
    oGPla1 := TGet():New(20, 18, hData["ID_PLACA_A"], "@!", oWin )
    oBtBusA := TButton():New(20, 35, 20, 49, oWin, "BUSCAR", {|| _BtnPick( oGPla1, hData, "ID_PLACA_A", "PLACA" ) } )

    // -- Num. Capas --
    oWin:AddCtrl( TLabel():New( 22,  2, "Num. Capas...:", oWin ) )
    oGNumP := TGet():New(22, 18, hData["NUM_PLACAS"], "9", oWin )

    // -- Botones --
    oBtGua := TButton():New( 24, 30, 25, 49, oWin, cBoton, {|| lSave := .T., oWin:Close() } )
    oBtCan := TButton():New( 24, 52, 25, 71, oWin, "CANCELAR",  {|| oWin:Close() } )

    oWin:AddCtrl( oGCon  )
    oWin:AddCtrl( oGLar  )
    oWin:AddCtrl( oGAnc  )
    oWin:AddCtrl( oGMod  )
    oWin:AddCtrl( oGSepP )
    oWin:AddCtrl( oGPer1 )
    oWin:AddCtrl( oBtBusP1 )
    oWin:AddCtrl( oGPer2 )
    oWin:AddCtrl( oBtBusP2 )
    oWin:AddCtrl( oGPer3 )
    oWin:AddCtrl( oBtBusP3 )
    oWin:AddCtrl( oGAnc2 )
    oWin:AddCtrl( oBtBusAnc )
    oWin:AddCtrl( oGPla1 )
    oWin:AddCtrl( oBtBusA )
    oWin:AddCtrl( oGNumP )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]   := oGCon:GetValue()
        hData["LARGO"]      := oGLar:GetValue()
        hData["ALTO"]       := oGAnc:GetValue()
        hData["MODUL"]      := oGMod:GetValue()
        hData["SEP_PRIM"]   := oGSepP:GetValue()
        hData["ID_PERFIL"]  := oGPer1:GetValue()
        IF hData["SEP_PRIM"] <= 0
            hData["ID_PERFIL2"] := "0"
        ELSE
            hData["ID_PERFIL2"] := oGPer2:GetValue()
        ENDIF
        hData["ID_PERFIL3"] := oGPer3:GetValue()
        hData["ID_ANCLAJE"] := oGAnc2:GetValue()
        hData["ID_PLACA_A"] := oGPla1:GetValue()
        hData["NUM_PLACAS"] := oGNumP:GetValue()
        hData["CARAS_REALES"] := 1
        IF lNuevo
            RETURN _CoreSave( hData )
        ENDIF
        RETURN UpdateTramoData( hData )
    ENDIF

RETURN .F.


STATIC FUNCTION _TechoValidSepPrim( oGet, oPrim, oBtn, hData )

    _TechoApplyPrimState( oGet:uVar, oPrim, oBtn, hData )

RETURN .T.


STATIC FUNCTION _TechoApplyPrimState( nSepPrim, oPrim, oBtn, hData )
    LOCAL lPrim := ( nSepPrim > 0 )

    oPrim:lEnabled := lPrim
    oBtn:lEnabled  := lPrim

    IF !lPrim
        oPrim:SetValue( "0" )
        hData["ID_PERFIL2"] := "0"
    ENDIF

    oPrim:Paint()
    oBtn:Paint()

RETURN NIL


STATIC FUNCTION _TechoValidPrim( oGet, oBtn, hData )
    LOCAL lPrim := !_OptionalCode( oGet:uVar )

    oBtn:lEnabled := .T.
    IF !lPrim
        oGet:SetValue( "0" )
        hData["ID_PERFIL2"] := "0"
    ELSE
        hData["ID_PERFIL2"] := oGet:uVar
    ENDIF
    oGet:Paint()
    oBtn:Paint()

RETURN .T.


// ============================================================================
// 3. ALTA DE TRASDOSADOS
// ============================================================================
FUNCTION Add_Trasdosado( cTipo, cTit )

    LOCAL hData := _InitData( cTipo, cTit )

    IF hData == NIL
        RETURN .F.
    ENDIF

    hData["MODUL"] := 0.60

    DO CASE
    CASE cTipo == "TRASDOSADO_SEMI"
        hData["ID_PERFIL2"] := "0"
    CASE cTipo == "TRASDOSADO_DIR"
        hData["MODUL"] := 0.00
        hData["ID_PERFIL"] := "0"
        hData["ID_PERFIL2"] := "0"
    CASE cTipo == "TRASDOSADO_AUT"
        // defaults ok
    ENDCASE

RETURN Form_Trasdosado( hData, .T. )


FUNCTION Form_Trasdosado( hData, lNuevo )

    LOCAL oWin
    LOCAL oGCon, oGLar, oGAlt, oGMod
    LOCAL oGPer1, oGPer2
    LOCAL oGPla1
    LOCAL oBtBusP1, oBtBusP2, oBtBusA
    LOCAL oBtGua, oBtCan, lSave := .F.
    LOCAL cTipo := hData["TIPO"]
    LOCAL cLbl1 := "Perfil.......:"
    LOCAL cLbl2 := "Canal........:"
    LOCAL cFam1 := "PERFIL"
    LOCAL lPidePerfil := .T., lPideCanal := .T., lPideMod := .T.
    LOCAL cTitulo := If( lNuevo, "NUEVO TRASDOSADO", "EDITAR TRASDOSADO" )
    LOCAL cBoton  := If( lNuevo, "GUARDAR", "ACTUALIZAR" )

    DO CASE
    CASE cTipo == "TRASDOSADO_SEMI" // Semi Directo
        cLbl1 := "Montante.....:"
        lPideCanal := .F.
    CASE cTipo == "TRASDOSADO_DIR"  // Directo
        cLbl1 := "Pasta Agarre.:"
        cFam1 := "PASTA"
        lPideCanal := .F.
        lPideMod := .F.
        lPidePerfil := .T.
    CASE cTipo == "TRASDOSADO_AUT"  // Autoportante
        cLbl1 := "Montante.....:"
        cLbl2 := "Canal........:"
    ENDCASE

    oWin := TWindow():New( 2, 5, 22, 95, cTitulo )

    oWin:AddCtrl( TLabel():New(  2,  2, "Concepto.....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Largo (m)....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 30, "Alto (m).....:", oWin ) )
    IF lPideMod
        oWin:AddCtrl( TLabel():New(  6,  2, "Modulacion...:", oWin ) )
    ENDIF
    oWin:AddCtrl( TLabel():New(  8,  2, cLbl1, oWin ) )
    IF lPideCanal
        oWin:AddCtrl( TLabel():New(  8, 40, cLbl2, oWin ) )
    ENDIF
    oWin:AddCtrl( TLabel():New( 11,  2, "Placa........:", oWin ) )
    oWin:AddCtrl( TLabel():New( 13,  2, "Lleva Aislan?:", oWin ) )
    oWin:AddCtrl( TLabel():New( 13, 40, "Mat. Aislante:", oWin ) )

    oGCon  := TGet():New( 2, 18, hData["CONCEPTO"], "@!",     oWin )
    oGLar  := TGet():New( 4, 18, hData["LARGO"],    "999.99", oWin )
    oGAlt  := TGet():New( 4, 43, hData["ALTO"],     "999.99", oWin )
    IF lPideMod
        oGMod := TGet():New( 6, 18, hData["MODUL"], "9.99",   oWin )
    ENDIF

    oGPer1 := TGet():New( 8, 18, hData["ID_PERFIL"], "@!", oWin )
    oBtBusP1 := TButton():New( 8, 33, 8, 47, oWin, "BUSCAR", {|| _BtnPick( oGPer1, hData, "ID_PERFIL", cFam1 ) } )

    IF lPideCanal
        oGPer2 := TGet():New( 8, 56, hData["ID_PERFIL2"], "@!", oWin )
        oBtBusP2 := TButton():New( 8, 72, 8, 86, oWin, "BUSCAR", {|| _BtnPick( oGPer2, hData, "ID_PERFIL2", "PERFIL" ) } )
    ENDIF

    oGPla1 := TGet():New( 11, 18, hData["ID_PLACA_A"], "@!", oWin )
    oBtBusA := TButton():New( 11, 33, 11, 47, oWin, "BUSCAR", {|| _BtnPick( oGPla1, hData, "ID_PLACA_A", "PLACA" ) } )

    oBtGua := TButton():New( 18, 30, 19, 49, oWin, cBoton, {|| lSave := .T., oWin:Close() } )
    oBtCan := TButton():New( 18, 52, 19, 71, oWin, "CANCELAR",  {|| oWin:Close() } )

    oWin:AddCtrl( oGCon  )
    oWin:AddCtrl( oGLar  )
    oWin:AddCtrl( oGAlt  )
    IF lPideMod
        oWin:AddCtrl( oGMod  )
    ENDIF
    oWin:AddCtrl( oGPer1 )
    oWin:AddCtrl( oBtBusP1 )
    IF lPideCanal
        oWin:AddCtrl( oGPer2 )
        oWin:AddCtrl( oBtBusP2 )
    ENDIF
    oWin:AddCtrl( oGPla1 )
    oWin:AddCtrl( oBtBusA )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]  := oGCon:GetValue()
        hData["LARGO"]     := oGLar:GetValue()
        hData["ALTO"]      := oGAlt:GetValue()
        IF lPideMod
            hData["MODUL"] := oGMod:GetValue()
        ELSE
            hData["MODUL"] := 0.00
        ENDIF
        hData["ID_PERFIL"] := oGPer1:GetValue()
        IF lPideCanal
            hData["ID_PERFIL2"] := oGPer2:GetValue()
        ELSE
            hData["ID_PERFIL2"] := "0"
        ENDIF
        hData["ID_PLACA_A"] := oGPla1:GetValue()
        hData["CARAS_REALES"] := 1
        IF lNuevo
            RETURN _CoreSave( hData )
        ENDIF
        RETURN UpdateTramoData( hData )
    ENDIF

RETURN .F.


// ============================================================================
// 4. ALTA GENERICA (material por m2: ladrillo, bloque, etc.)
// ============================================================================
FUNCTION Add_Generico( cTit )

    LOCAL hData := _InitData( "GENERICO", cTit )

    IF hData == NIL
        RETURN .F.
    ENDIF

    hData["MODUL"] := 0.00

RETURN Form_Generico( hData, .T. )


FUNCTION Form_Generico( hData, lNuevo )

    LOCAL oWin
    LOCAL oGCon, oGLar, oGAlt, oGMat
    LOCAL oBtBusMat, lSave := .F.
    LOCAL cTitulo := If( lNuevo, "MATERIAL GENERICO (m2)", "EDITAR MATERIAL GENERICO (m2)" )
    LOCAL cBoton  := If( lNuevo, "GUARDAR", "ACTUALIZAR" )

    oWin := TWindow():New( 2, 5, 20, 95, cTitulo )

    oWin:AddCtrl( TLabel():New(  2, 2, "Concepto..:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 2, "Largo (m).:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 30, "Alto (m)..:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 2, "Material..:", oWin ) )

    oGCon := TGet():New( 2, 16, hData["CONCEPTO"],   "@!",     oWin )
    oGLar := TGet():New( 4, 16, hData["LARGO"],      "999.99", oWin )
    oGAlt := TGet():New( 4, 43, hData["ALTO"],       "999.99", oWin )
    oGMat := TGet():New( 6, 16, hData["ID_PLACA_A"], "@!",     oWin )
    oBtBusMat := TButton():New( 6, 48, 6, 62, oWin, "BUSCAR", {|| _BtnPick( oGMat, hData, "ID_PLACA_A", "GENERICO" ) } )

    oWin:AddCtrl( TButton():New( 16, 30, 17, 49, oWin, cBoton, {|| lSave := .T., oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 16, 52, 17, 71, oWin, "CANCELAR",  {|| oWin:Close() } ) )

    oWin:AddCtrl( oGCon  )
    oWin:AddCtrl( oGLar  )
    oWin:AddCtrl( oGAlt  )
    oWin:AddCtrl( oGMat  )
    oWin:AddCtrl( oBtBusMat )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]    := oGCon:GetValue()
        hData["LARGO"]       := oGLar:GetValue()
        hData["ALTO"]        := oGAlt:GetValue()
        hData["ID_PLACA_A"]  := oGMat:GetValue()
        hData["CARAS_REALES"] := 1
        IF lNuevo
            RETURN _CoreSave( hData )
        ENDIF
        RETURN UpdateTramoData( hData )
    ENDIF

RETURN .F.


// ============================================================================
// FUNCIONES DE APOYO
// ============================================================================
STATIC FUNCTION _InitData( cTipo, cTit )

    LOCAL hData := hb_Hash()

    IF !ABRIR_TABLA( "TMP_TRA", "TMP_TRA", "TTRA_ORD" )
        MsgStop( "No se pudo abrir TMP_TRA.", "Nuevo Tramo" )
        RETURN NIL
    ENDIF

    IF !ABRIR_TABLA( "ARTICULOS", "ARTICULOS", "ART_COD" )
        MsgStop( "No se pudo abrir ARTICULOS." + Chr(13) + ;
                 "Ejecute AppGestion para crear la base de articulos.", ;
                 "Nuevo Tramo" )
        RETURN NIL
    ENDIF

    hData["TIPO"]       := cTipo
    hData["SISTEMA_ID"] := Space(20)
    hData["CONCEPTO"]   := PadR( cTit, 30 )
    hData["LARGO"]      := 0.00
    hData["ALTO"]       := 2.50
    hData["MODUL"]      := 0.60
    hData["ANCHO_PERF"] := 0
    hData["SEP_PRIM"]   := 0.00

    hData["ID_PERFIL"]  := Space(15)
    hData["ID_PERFIL2"] := Space(15)
    hData["ID_PERFIL3"] := Space(15)
    hData["ID_ANCLAJE"] := "0"
    hData["ID_PLACA_A"] := Space(15)
    hData["ID_PLACA_B"] := Space(15)
    hData["ID_AISLAN"]  := Space(15)
    hData["AIS"]        := "N"
    hData["BANDA"]      := "N"
    hData["NUM_PLACAS"] := 1

RETURN hData


STATIC FUNCTION _CoreSave( hData )

    LOCAL cTipo := Upper( AllTrim( hData["TIPO"] ) )
    LOCAL cProyecto := _CurrentProyectoNumero()
    LOCAL nLinea

    hData["TIPO"] := cTipo

    IF !_TipoObraValido( cTipo )
        MsgStop( "Sistema constructivo no valido: [" + cTipo + "].", "Nuevo Tramo" )
        RETURN .F.
    ENDIF

    IF Empty( hData["CONCEPTO"] )
        MsgStop( "Falta Concepto" )
        RETURN .F.
    ENDIF

    IF Empty( cProyecto )
        MsgStop( "Debe crear un proyecto antes de agregar tramos.", "Proyecto requerido" )
        RETURN .F.
    ENDIF

    IF hData["LARGO"] <= 0
        MsgStop( "Largo debe ser mayor a 0" )
        RETURN .F.
    ENDIF

    IF hData["ALTO"] <= 0
        MsgStop( "Alto/Ancho debe ser mayor a 0" )
        RETURN .F.
    ENDIF

    IF hData["NUM_PLACAS"] < 1 .OR. hData["NUM_PLACAS"] > 5
        MsgStop( "Capas debe estar entre 1 y 5", "Validacion" )
        RETURN .F.
    ENDIF

    IF cTipo != "GENERICO"
        IF cTipo == "TRASDOSADO_DIR"
            IF !_RequireCode( hData["ID_PERFIL"], "pasta de agarre" )
                RETURN .F.
            ENDIF
        ELSEIF !( "DIR" $ cTipo )
            IF !_RequireCode( hData["ID_PERFIL"], "perfil principal" )
                RETURN .F.
            ENDIF
        ENDIF

        IF cTipo == "TECHO"
            IF hData["SEP_PRIM"] <= 0
                hData["ID_PERFIL2"] := "0"
            ELSEIF !_RequireCode( hData["ID_PERFIL2"], "perfil primario" )
                RETURN .F.
            ENDIF
        ELSEIF cTipo == "TABIQUE" .AND. !_RequireCode( hData["ID_PERFIL2"], "perfil secundario/canal" )
            RETURN .F.
        ELSEIF cTipo == "TRASDOSADO_AUT" .AND. ;
               !_RequireCode( hData["ID_PERFIL2"], "canal" )
            RETURN .F.
        ELSEIF "TRAS" $ cTipo .AND. !_OptionalCode( hData["ID_PERFIL2"] ) .AND. ;
               !_RequireCode( hData["ID_PERFIL2"], "perfil secundario/canal" )
            RETURN .F.
        ENDIF
    ENDIF

    IF !_RequireCode( hData["ID_PLACA_A"], "placa/material" )
        RETURN .F.
    ENDIF

    IF cTipo == "TABIQUE" .AND. !_RequireCode( hData["ID_PLACA_B"], "placa cara B" )
        RETURN .F.
    ENDIF

    IF hData["AIS"] == "S" .AND. !_RequireCode( hData["ID_AISLAN"], "aislante" )
        RETURN .F.
    ENDIF

    nLinea := _NextTramoLinea( cProyecto )

    dbSelectArea( "TMP_TRA" )
    IF !NetFLock()
        MsgStop( "No se pudo bloquear TMP_TRA para anadir el tramo.", "Nuevo Tramo" )
        RETURN .F.
    ENDIF

    DbAppend()

    IF NetErr()
        dbUnlock()
        MsgStop( "Error de Red: No se pudo anadir registro." )
        RETURN .F.
    ENDIF

    REPLACE FIELD->NUMERO     WITH cProyecto
    REPLACE FIELD->ID_LINEA   WITH nLinea
    REPLACE FIELD->TIPO_OBRA  WITH hData["TIPO"]
    IF FieldPos( "SISTEMA_ID" ) > 0 .AND. hb_HHasKey( hData, "SISTEMA_ID" )
        REPLACE FIELD->SISTEMA_ID WITH hData["SISTEMA_ID"]
    ENDIF
    REPLACE FIELD->CONCEPTO   WITH hData["CONCEPTO"]
    REPLACE FIELD->LARGO      WITH hData["LARGO"]
    REPLACE FIELD->ALTO       WITH hData["ALTO"]
    REPLACE FIELD->MODUL      WITH hData["MODUL"]

    IF FieldPos("ANCHO_PERF") > 0 .AND. hb_HHasKey( hData, "ANCHO_PERF" )
        REPLACE FIELD->ANCHO_PERF WITH _SysAncho( hData["ANCHO_PERF"] )
    ENDIF

    IF FieldPos("SEP_PRIM") > 0
        REPLACE FIELD->SEP_PRIM WITH hData["SEP_PRIM"]
    ENDIF
    IF FieldPos("PLAC_CARA") > 0
        REPLACE FIELD->PLAC_CARA WITH hData["NUM_PLACAS"]
    ENDIF

    REPLACE FIELD->ID_PER_VER WITH hData["ID_PERFIL"]
    IF FieldPos("ID_PER_HOR") > 0
        REPLACE FIELD->ID_PER_HOR WITH hData["ID_PERFIL2"]
    ENDIF
    IF hb_HHasKey( hData, "ID_PERFIL3" ) .AND. FieldPos("ID_PER_PER") > 0
        REPLACE FIELD->ID_PER_PER WITH hData["ID_PERFIL3"]
    ENDIF
    IF hb_HHasKey( hData, "ID_ANCLAJE" ) .AND. FieldPos("ID_ANCLAJE") > 0
        REPLACE FIELD->ID_ANCLAJE WITH hData["ID_ANCLAJE"]
    ENDIF
    IF hb_HHasKey( hData, "BANDA" ) .AND. FieldPos("L_BANDA") > 0
        REPLACE FIELD->L_BANDA WITH ( hData["BANDA"] == "S" )
    ENDIF

    REPLACE FIELD->ID_PLACA_A WITH hData["ID_PLACA_A"]
    REPLACE FIELD->ID_PLACA_B WITH hData["ID_PLACA_B"]
    REPLACE FIELD->ID_AISLANT WITH hData["ID_AISLAN"]
    REPLACE FIELD->CARAS      WITH hData["CARAS_REALES"]
    REPLACE FIELD->L_AISLANT  WITH ( hData["AIS"] == "S" )

    dbCommit()
    dbUnlock()

    DrywallMarkCalcDirty( cProyecto )

RETURN .T.


STATIC FUNCTION _CurrentProyectoNumero()

RETURN DrywallProyectoActualNumero()


STATIC FUNCTION _NextTramoLinea( cProyecto )

    LOCAL nArea := Select()
    LOCAL nMax := 0

    dbSelectArea( "TMP_TRA" )
    dbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == AllTrim( cProyecto )
            IF FIELD->ID_LINEA > nMax
                nMax := FIELD->ID_LINEA
            ENDIF
        ENDIF
        dbSkip()
    ENDDO

    IF nArea > 0
        dbSelectArea( nArea )
    ENDIF

RETURN nMax + 1


FUNCTION TipoObraDrywallValido( cTipo )

RETURN _TipoObraValido( cTipo )


STATIC FUNCTION _TipoObraValido( cTipo )

    cTipo := Upper( AllTrim( cTipo ) )

RETURN AScan( { ;
    "TABIQUE", ;
    "TECHO", ;
    "TRASDOSADO_AUT", ;
    "TRASDOSADO_SEMI", ;
    "TRASDOSADO_DIR", ;
    "GENERICO" }, cTipo ) > 0


STATIC FUNCTION _ValidAnchoPerf( oGet )

    LOCAL nSistema := _SysAncho( oGet:uVar )

    IF AScan( { 48, 70, 90 }, nSistema ) > 0
        RETURN .T.
    ENDIF

    MsgStop( "Ancho perfil: 48, 70 o 90", "Validacion" )

RETURN .F.


STATIC FUNCTION _RequireCode( cCod, cLabel )

    IF Empty( AllTrim( cCod ) ) .OR. AllTrim( cCod ) == "0"
        MsgStop( "Falta seleccionar " + cLabel + ".", "Validacion" )
        RETURN .F.
    ENDIF

RETURN .T.





STATIC FUNCTION _ValPick( hData, cKey, cFam )

    LOCAL cCod := AllTrim( hData[ cKey ] )
    LOCAL cRet

    IF Empty( cCod ) .OR. LastKey() == K_F2
        cRet := _PickArt( cFam )

        IF !Empty( cRet )
            hData[ cKey ] := cRet
            RETURN .T.
        ENDIF

        IF Empty( cCod )
            RETURN .F.
        ENDIF
    ENDIF

RETURN .T.


STATIC FUNCTION _PickArt( cFam )

    LOCAL aData := {}
    LOCAL aCombo := {}
    LOCAL i, cRet
    LOCAL nArea := Select()

    IF !ABRIR_TABLA( "ARTICULOS", "ARTICULOS", "ART_FAM" )
        MsgStop( "No se pudo abrir ARTICULOS.", "Seleccion" )
        IF nArea > 0
            dbSelectArea( nArea )
        ENDIF
        RETURN ""
    ENDIF

    dbSelectArea( "ARTICULOS" )
    OrdSetFocus( "ART_FAM" )
    dbSeek( Upper( cFam ) )

    DO WHILE !Eof() .AND. Upper( AllTrim( FIELD->FAMILIA ) ) == Upper( AllTrim( cFam ) )
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( FIELD->CODIGO ), ;
                AllTrim( FIELD->DESCRIP ) } )
        ENDIF
        dbSkip()
    ENDDO

    IF Empty( aData )
        MsgInfo( "No hay articulos en la familia " + cFam, "Seleccion" )
        Select( nArea )
        RETURN ""
    ENDIF

    FOR i := 1 TO Len( aData )
        AAdd( aCombo, { aData[i, 1], aData[i, 2] } )
    NEXT

    cRet := PopupSelect( "SELECCIONAR " + cFam, aCombo, ;
                          { { "Descripcion", 72, "@!", 2 } }, 1 )

    Select( nArea )

RETURN cRet
