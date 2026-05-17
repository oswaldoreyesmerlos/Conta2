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
    hData["MODUL"]      := 0.60
    hData["NUM_PLACAS"] := 1
    hData["SAME_B"]     := "S"
    hData["AIS"]        := "N"
    hData["BANDA"]      := "N"
    hData["SISTEMA"]    := "48"

RETURN Form_Tabique( hData, .T. )


FUNCTION Form_Tabique( hData, lNuevo )

    LOCAL oWin
    LOCAL oGCon, oGLar, oGAlt, oGMod
    LOCAL oGSis, oGPer1, oGPer2, oGPla1, oGPla2, oGNumP
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

    // -- FILA 4: Modulacion, Sistema --
    oWin:AddCtrl( TLabel():New( 5,  2, "Modulacion:", oWin ) )
    oGMod := TGet():New( 5, 16, hData["MODUL"],  "9.99", oWin )
    oWin:AddCtrl( TLabel():New( 5, 32, "Sistema mm:", oWin ) )
    oGSis := TGet():New( 5, 46, hData["SISTEMA"], "99", oWin )
    oGSis:bValid := {|o| _ValidSistema( o ) }

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
    oWin:AddCtrl( oGSis )
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
        hData["SISTEMA"]     := _SysAncho( oGSis:GetValue() )
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

    LOCAL oWin
    LOCAL hData
    LOCAL oGCon, oGLar, oGAnc
    LOCAL oGMod, oGSepP
    LOCAL oGPer1, oGPer2
    LOCAL oGPla1, oGNumP
    LOCAL oGAis, oGAisCod
    LOCAL oBtBusP1, oBtBusP2, oBtBusA
    LOCAL oBtGua, oBtCan
    LOCAL lSave := .F.

    hData := _InitData( "TECHO", cTit )
    hData["MODUL"]      := 0.50
    hData["SEP_PRIM"]   := 1.00
    hData["NUM_PLACAS"] := 1
    hData["ID_PERFIL2"] := "0"

    oWin := TWindow():New( 2, 5, 24, 95, "NUEVO TECHO CONTINUO" )

    oWin:AddCtrl( TLabel():New(  2,  2, "Concepto.....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Largo (m)....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 30, "Ancho (m)....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Sep. Secundar:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 30, "Sep. Primario:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Secundario...:", oWin ) )
    oWin:AddCtrl( TLabel():New(  9,  2, "Primario....:", oWin ) )
    oWin:AddCtrl( TLabel():New( 11,  2, "Placa........:", oWin ) )
    oWin:AddCtrl( TLabel():New( 11, 40, "Num. Capas...:", oWin ) )
    oWin:AddCtrl( TLabel():New( 13,  2, "Lleva Aislan?:", oWin ) )
    oWin:AddCtrl( TLabel():New( 13, 40, "Mat. Aislante:", oWin ) )

    oGCon  := TGet():New( 2, 18, hData["CONCEPTO"], "@!",     oWin )
    oGLar  := TGet():New( 4, 18, hData["LARGO"],    "999.99", oWin )
    oGAnc  := TGet():New( 4, 43, hData["ALTO"],     "999.99", oWin )
    oGMod  := TGet():New( 6, 18, hData["MODUL"],    "9.99",   oWin )
    oGSepP := TGet():New( 6, 45, hData["SEP_PRIM"], "9.99",   oWin )

    oGPer1 := TGet():New( 8, 18, hData["ID_PERFIL"],  "@!", oWin )
    oBtBusP1 := TButton():New( 8, 33, 8, 47, oWin, "BUSCAR", {|| _BtnPick( oGPer1, hData, "ID_PERFIL", "PERFIL" ) } )

    oGPer2 := TGet():New( 9, 18, hData["ID_PERFIL2"], "@!", oWin )
    oBtBusP2 := TButton():New( 9, 48, 9, 62, oWin, "BUSCAR", {|| _BtnPick( oGPer2, hData, "ID_PERFIL2", "PERFIL" ) } )
    oBtBusP2:lEnabled := !_OptionalCode( hData["ID_PERFIL2"] )
    oGPer2:bValid := {|o| _TechoValidPrim( o, oBtBusP2, hData ) }

    oGPla1 := TGet():New( 11, 18, hData["ID_PLACA_A"], "@!", oWin )
    oBtBusA := TButton():New( 11, 33, 11, 47, oWin, "BUSCAR", {|| _BtnPick( oGPla1, hData, "ID_PLACA_A", "PLACA" ) } )

    oGNumP := TGet():New( 11, 56, hData["NUM_PLACAS"], "9", oWin )

    // FIXME: aislamiento interactivo

    oBtGua := TButton():New( 20, 30, 21, 49, oWin, "GUARDAR", {|| lSave := .T., oWin:Close() } )
    oBtCan := TButton():New( 20, 52, 21, 71, oWin, "VOLVER",  {|| oWin:Close() } )

    oWin:AddCtrl( oGCon  )
    oWin:AddCtrl( oGLar  )
    oWin:AddCtrl( oGAnc  )
    oWin:AddCtrl( oGMod  )
    oWin:AddCtrl( oGSepP )
    oWin:AddCtrl( oGPer1 )
    oWin:AddCtrl( oBtBusP1 )
    oWin:AddCtrl( oGPer2 )
    oWin:AddCtrl( oBtBusP2 )
    oWin:AddCtrl( oGPla1 )
    oWin:AddCtrl( oBtBusA )
    oWin:AddCtrl( oGNumP )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]  := oGCon:GetValue()
        hData["LARGO"]     := oGLar:GetValue()
        hData["ALTO"]      := oGAnc:GetValue()
        hData["MODUL"]     := oGMod:GetValue()
        hData["SEP_PRIM"]  := oGSepP:GetValue()
        hData["ID_PERFIL"] := oGPer1:GetValue()
        IF _OptionalCode( oGPer2:GetValue() )
            hData["ID_PERFIL2"] := "0"
        ELSE
            hData["ID_PERFIL2"] := oGPer2:GetValue()
        ENDIF
        hData["ID_PLACA_A"]:= oGPla1:GetValue()
        hData["NUM_PLACAS"]:= oGNumP:GetValue()
        hData["CARAS_REALES"] := 1
        _CoreSave( hData )
        RETURN .T.
    ENDIF

RETURN .F.


STATIC FUNCTION _TechoValidPrim( oGet, oBtn, hData )
    LOCAL lPrim := !_OptionalCode( oGet:uVar )

    oBtn:lEnabled := lPrim
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

    LOCAL oWin
    LOCAL hData
    LOCAL oGCon, oGLar, oGAlt, oGMod
    LOCAL oGPer1, oGPer2
    LOCAL oGPla1
    LOCAL oGAis, oGAisCod
    LOCAL oBtBusP1, oBtBusP2, oBtBusA
    LOCAL oBtGua, oBtCan
    LOCAL lSave := .F.
    LOCAL cLbl1 := "Perfil.......:"
    LOCAL cLbl2 := "Canal........:"
    LOCAL lPidePerfil := .T.
    LOCAL lPideCanal := .T.

    hData := _InitData( cTipo, cTit )
    hData["MODUL"] := 0.60

    DO CASE
    CASE cTipo == "TRASDOSADO"
        cLbl1 := "Montante.....:"
        cLbl2 := ""
        lPideCanal := .F.
        hData["ID_PERFIL2"] := "0"
    CASE cTipo == "TRASDOSADO_DIR"
        cLbl1 := ""
        cLbl2 := ""
        lPidePerfil := .F.
        lPideCanal := .F.
        hData["MODUL"] := 0.00
        hData["ID_PERFIL"] := "0"
        hData["ID_PERFIL2"] := "0"
    CASE cTipo == "TRASDOSADO_AUT"
        cLbl1 := "Montante.....:"
        cLbl2 := "Canal........:"
        lPideCanal := .T.
    ENDCASE

    oWin := TWindow():New( 2, 5, 22, 95, "NUEVO TRASDOSADO - " + cTit )

    oWin:AddCtrl( TLabel():New(  2,  2, "Concepto.....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Largo (m)....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 30, "Alto (m).....:", oWin ) )
    IF lPidePerfil
        oWin:AddCtrl( TLabel():New(  6,  2, "Modulacion...:", oWin ) )
        oWin:AddCtrl( TLabel():New(  8,  2, cLbl1, oWin ) )
    ENDIF
    IF lPideCanal
        oWin:AddCtrl( TLabel():New(  8, 40, cLbl2, oWin ) )
    ENDIF
    oWin:AddCtrl( TLabel():New( 11,  2, "Placa........:", oWin ) )
    oWin:AddCtrl( TLabel():New( 13,  2, "Lleva Aislan?:", oWin ) )
    oWin:AddCtrl( TLabel():New( 13, 40, "Mat. Aislante:", oWin ) )

    oGCon  := TGet():New( 2, 18, hData["CONCEPTO"], "@!",     oWin )
    oGLar  := TGet():New( 4, 18, hData["LARGO"],    "999.99", oWin )
    oGAlt  := TGet():New( 4, 43, hData["ALTO"],     "999.99", oWin )
    IF lPidePerfil
        oGMod := TGet():New( 6, 18, hData["MODUL"], "9.99", oWin )

        oGPer1 := TGet():New( 8, 18, hData["ID_PERFIL"], "@!", oWin )
        oBtBusP1 := TButton():New( 8, 33, 8, 47, oWin, "BUSCAR", {|| _BtnPick( oGPer1, hData, "ID_PERFIL", "PERFIL" ) } )
    ENDIF

    IF lPideCanal
        oGPer2 := TGet():New( 8, 56, hData["ID_PERFIL2"], "@!", oWin )
        oBtBusP2 := TButton():New( 8, 72, 8, 86, oWin, "BUSCAR", {|| _BtnPick( oGPer2, hData, "ID_PERFIL2", "PERFIL" ) } )
    ENDIF

    oGPla1 := TGet():New( 11, 18, hData["ID_PLACA_A"], "@!", oWin )
    oBtBusA := TButton():New( 11, 33, 11, 47, oWin, "BUSCAR", {|| _BtnPick( oGPla1, hData, "ID_PLACA_A", "PLACA" ) } )

    // FIXME: aislamiento interactivo

    oBtGua := TButton():New( 18, 30, 19, 49, oWin, "GUARDAR", {|| lSave := .T., oWin:Close() } )
    oBtCan := TButton():New( 18, 52, 19, 71, oWin, "VOLVER",  {|| oWin:Close() } )

    oWin:AddCtrl( oGCon  )
    oWin:AddCtrl( oGLar  )
    oWin:AddCtrl( oGAlt  )
    IF lPidePerfil
        oWin:AddCtrl( oGMod  )
        oWin:AddCtrl( oGPer1 )
        oWin:AddCtrl( oBtBusP1 )
    ENDIF
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
        IF lPidePerfil
            hData["MODUL"] := oGMod:GetValue()
            hData["ID_PERFIL"] := oGPer1:GetValue()
        ELSE
            hData["MODUL"] := 0.00
            hData["ID_PERFIL"] := "0"
        ENDIF
        IF lPideCanal
            hData["ID_PERFIL2"] := oGPer2:GetValue()
        ELSE
            hData["ID_PERFIL2"] := "0"
        ENDIF
        hData["ID_PLACA_A"] := oGPla1:GetValue()
        hData["CARAS_REALES"] := 1
        IF "DIR" $ cTipo
            hData["CARAS_REALES"] := 1
        ENDIF
        _CoreSave( hData )
        RETURN .T.
    ENDIF

RETURN .F.


// ============================================================================
// 4. ALTA GENERICA (material por m2: ladrillo, bloque, etc.)
// ============================================================================
FUNCTION Add_Generico( cTit )

    LOCAL oWin, hData
    LOCAL oGCon, oGLar, oGAlt
    LOCAL oGMat, oGAis, oGAisCod
    LOCAL oBtBusMat
    LOCAL lSave := .F.

    hData := _InitData( "GENERICO", cTit )
    hData["MODUL"] := 0.00

    oWin := TWindow():New( 2, 5, 20, 95, "MATERIAL GENERICO (m2)" )

    oWin:AddCtrl( TLabel():New(  2,  2, "Concepto..:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Largo (m).:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 30, "Alto (m)..:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Material..:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Aislante..:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 40, "Mat.Aislan:", oWin ) )

    oGCon := TGet():New( 2, 16, hData["CONCEPTO"], "@!",     oWin )
    oGLar := TGet():New( 4, 16, hData["LARGO"],    "999.99", oWin )
    oGAlt := TGet():New( 4, 43, hData["ALTO"],     "999.99", oWin )

    oGMat := TGet():New( 6, 16, hData["ID_PLACA_A"], "@!", oWin )
    oBtBusMat := TButton():New( 6, 48, 6, 62, oWin, "BUSCAR", {|| _BtnPick( oGMat, hData, "ID_PLACA_A", "GENERICO" ) } )

    oWin:AddCtrl( TButton():New( 16, 30, 17, 49, oWin, "GUARDAR", {|| lSave := .T., oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 16, 52, 17, 71, oWin, "CANCELAR", {|| oWin:Close() } ) )

    oWin:AddCtrl( oGCon )
    oWin:AddCtrl( oGLar )
    oWin:AddCtrl( oGAlt )
    oWin:AddCtrl( oGMat )
    oWin:AddCtrl( oBtBusMat )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]  := oGCon:GetValue()
        hData["LARGO"]     := oGLar:GetValue()
        hData["ALTO"]      := oGAlt:GetValue()
        hData["ID_PLACA_A"] := oGMat:GetValue()
        hData["CARAS_REALES"] := 1
        _CoreSave( hData )
        RETURN .T.
    ENDIF

RETURN .F.


// ============================================================================
// FUNCIONES DE APOYO
// ============================================================================
STATIC FUNCTION _InitData( cTipo, cTit )

    LOCAL hData := hb_Hash()

    IF Select("TMP_TRA") == 0
        USE TMP_TRA NEW SHARED VIA "DBFCDX"
    ENDIF

    IF Select("ARTICULOS") == 0
        USE ARTICULOS NEW SHARED VIA "DBFCDX"
    ENDIF

    hData["TIPO"]       := cTipo
    hData["CONCEPTO"]   := PadR( cTit, 30 )
    hData["LARGO"]      := 0.00
    hData["ALTO"]       := 2.50
    hData["MODUL"]      := 0.60
    hData["SISTEMA"]    := 0
    hData["SEP_PRIM"]   := 0.00

    hData["ID_PERFIL"]  := Space(15)
    hData["ID_PERFIL2"] := Space(15)
    hData["ID_PLACA_A"] := Space(15)
    hData["ID_PLACA_B"] := Space(15)
    hData["ID_AISLAN"]  := Space(15)
    hData["AIS"]        := "N"
    hData["BANDA"]      := "N"
    hData["NUM_PLACAS"] := 1

RETURN hData


STATIC FUNCTION _CoreSave( hData )

    LOCAL cTipo := AllTrim( hData["TIPO"] )

    IF Empty( hData["CONCEPTO"] )
        MsgStop( "Falta Concepto" )
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
        IF !( "DIR" $ cTipo )
            IF !_RequireCode( hData["ID_PERFIL"], "perfil principal" )
                RETURN .F.
            ENDIF
        ENDIF

        IF cTipo == "TECHO"
            IF !_OptionalCode( hData["ID_PERFIL2"] ) .AND. ;
               !_RequireCode( hData["ID_PERFIL2"], "perfil primario" )
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

    dbSelectArea( "TMP_TRA" )
    dbAppend()

    IF NetErr()
        MsgStop( "Error de Red: No se pudo anadir registro." )
        RETURN .F.
    ENDIF

    REPLACE FIELD->ID_LINEA   WITH RecNo()
    REPLACE FIELD->TIPO_OBRA  WITH hData["TIPO"]
    REPLACE FIELD->CONCEPTO   WITH hData["CONCEPTO"]
    REPLACE FIELD->LARGO      WITH hData["LARGO"]
    REPLACE FIELD->ALTO       WITH hData["ALTO"]
    REPLACE FIELD->MODUL      WITH hData["MODUL"]

    IF FieldPos("SISTEMA") > 0 .AND. hb_HHasKey( hData, "SISTEMA" )
        REPLACE FIELD->SISTEMA WITH _SysAncho( hData["SISTEMA"] )
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

    dbUnlock()

    IF Select("TMP_CAB") > 0
        dbSelectArea("TMP_CAB")
        dbGoto(1)
        IF NetRLock()
            REPLACE FIELD->L_SUCIO WITH .T.
            dbUnlock()
        ENDIF
    ENDIF

RETURN .T.


STATIC FUNCTION _SysAncho( xSistema )

    DO CASE
    CASE ValType( xSistema ) == "N"
        RETURN xSistema
    CASE ValType( xSistema ) == "C"
        RETURN Val( AllTrim( xSistema ) )
    ENDCASE

RETURN 0


STATIC FUNCTION _ValidSistema( oGet )

    LOCAL nSistema := _SysAncho( oGet:uVar )

    IF AScan( { 48, 70, 90 }, nSistema ) > 0
        RETURN .T.
    ENDIF

    MsgStop( "Sistema: 48, 70 o 90", "Validacion" )

RETURN .F.


STATIC FUNCTION _RequireCode( cCod, cLabel )

    IF Empty( AllTrim( cCod ) ) .OR. AllTrim( cCod ) == "0"
        MsgStop( "Falta seleccionar " + cLabel + ".", "Validacion" )
        RETURN .F.
    ENDIF

RETURN .T.


STATIC FUNCTION _OptionalCode( cCod )

RETURN Empty( AllTrim( cCod ) ) .OR. AllTrim( cCod ) == "0"


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

    IF Select( "TABLAS_AUX" ) == 0
        USE TABLAS_AUX NEW SHARED VIA "DBFCDX"
    ENDIF

    dbSelectArea( "TABLAS_AUX" )
    dbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( FIELD->TIPO ) == AllTrim( cFam )
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
