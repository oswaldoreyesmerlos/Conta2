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

    LOCAL oWin, hData
    LOCAL oGCon, oGLar, oGAlt, oGMod
    LOCAL oGSis, oGPer1, oGPer2, oGPla1, oGPla2, oGNumP
    LOCAL oChkSame, oChkAis, oChkBand
    LOCAL oBtBusP1, oBtBusP2, oBtBusA, oBtBusB, oBtBusAis
    LOCAL oBtGua, oBtCan, lSave := .F.

    hData := _InitData( "TABIQUE", cTit )
    hData["MODUL"]      := 0.60
    hData["NUM_PLACAS"] := 1
    hData["SAME_B"]     := "S"
    hData["AIS"]        := "N"
    hData["BANDA"]      := "N"
    hData["SISTEMA"]    := "48"

    oWin := TWindow():New( 2, 5, 27, 105, "NUEVO TABIQUE" )

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
    oGSis:bValid := {|o| Val(o:cBuffer) $ {48,70,90} .OR. (MsgStop("Sistema: 48, 70 o 90","Validacion"),.F.) }

    // -- FILA 6: Montante + buscar, Canal + buscar --
    oWin:AddCtrl( TLabel():New( 7,  2, "Montante..:", oWin ) )
    oGPer1 := TGet():New( 7, 16, hData["ID_PERFIL"], "@!", oWin )
    oBtBusP1 := TButton():New( 7, 48, 7, 62, oWin, "BUSCAR", {|| _BtnPick(oGPer1,hData,"ID_PERFIL","PERFIL") } )
    oWin:AddCtrl( TLabel():New( 8,  2, "Canal.....:", oWin ) )
    oGPer2 := TGet():New( 8, 16, hData["ID_PERFIL2"], "@!", oWin )
    oBtBusP2 := TButton():New( 8, 48, 8, 62, oWin, "BUSCAR", {|| _BtnPick(oGPer2,hData,"ID_PERFIL2","PERFIL") } )

    // -- FILA 10: Placa A + buscar, Capas --
    oWin:AddCtrl( TLabel():New( 10, 2, "Placa A...:", oWin ) )
    oGPla1 := TGet():New( 10,16, hData["ID_PLACA_A"], "@!", oWin )
    oBtBusA := TButton():New( 10,48, 10,62, oWin, "BUSCAR", {|| _BtnPick(oGPla1,hData,"ID_PLACA_A","PLACA") } )
    oWin:AddCtrl( TLabel():New( 10,66, "Capas:", oWin ) )
    oGNumP := TGet():New( 10,74, hData["NUM_PLACAS"], "9", oWin )
    oGNumP:bValid := {|o| o:uVar >=1 .AND. o:uVar <=5 .OR. (MsgStop("Maximo 5 capas","Validacion"),.F.) }

    // -- FILA 12: Igual Cara B (checkbox) --
    oChkSame := TCheck():New( 12,16, "Igual Cara B", .T., oWin )
    oChkSame:bChange := {|| _TabqToggleSame( oChkSame, oGPla2, oBtBusB, hData ) }
    oWin:AddCtrl( oChkSame )

    // -- FILA 13: Placa B + buscar (deshabilitado si Same B) --
    oWin:AddCtrl( TLabel():New( 13, 2, "Placa B...:", oWin ) )
    oGPla2 := TGet():New( 13,16, hData["ID_PLACA_B"], "@!", oWin )
    oGPla2:lEnabled := .F.
    oBtBusB := TButton():New( 13,48, 13,62, oWin, "BUSCAR", {|| _BtnPick(oGPla2,hData,"ID_PLACA_B","PLACA") } )
    oBtBusB:lEnabled := .F.

    // -- FILA 15: Lleva Aislan (checkbox) --
    oChkAis := TCheck():New( 15,16, "Lleva Aislante", .F., oWin )
    oChkAis:bChange := {|| _TabqToggleAis( oChkAis, oGAisCod, oBtBusAis, hData ) }
    oWin:AddCtrl( oChkAis )

    // -- FILA 16: Mat Aislante + buscar (deshabilitado si no Ais) --
    oWin:AddCtrl( TLabel():New( 16, 2, "Aislante..:", oWin ) )
    oGAisCod := TGet():New( 16,16, hData["ID_AISLAN"], "@!", oWin )
    oGAisCod:lEnabled := .F.
    oBtBusAis := TButton():New( 16,48, 16,62, oWin, "BUSCAR", {|| _BtnPick(oGAisCod,hData,"ID_AISLAN","AISLAN") } )
    oBtBusAis:lEnabled := .F.

    // -- FILA 18: Banda Acustica (checkbox) --
    oChkBand := TCheck():New( 18,16, "Banda Acustica", .F., oWin )
    oChkBand:bChange := {|| hData["BANDA"] := If( oChkBand:GetValue(), "S", "N" ) }
    oWin:AddCtrl( oChkBand )

    // -- Botones --
    oBtGua := TButton():New( 23,30, 24,49, oWin, "GUARDAR", {|| lSave := .T., oWin:Close() } )
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
    oWin:AddCtrl( oGPla2 )
    oWin:AddCtrl( oBtBusB )
    oWin:AddCtrl( oGAisCod )
    oWin:AddCtrl( oBtBusAis )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]    := oGCon:GetValue()
        hData["LARGO"]       := oGLar:GetValue()
        hData["ALTO"]        := oGAlt:GetValue()
        hData["MODUL"]       := oGMod:GetValue()
        hData["SISTEMA"]     := AllTrim(oGSis:GetValue())
        hData["ID_PERFIL"]   := oGPer1:GetValue()
        hData["ID_PERFIL2"]  := oGPer2:GetValue()
        hData["ID_PLACA_A"]  := oGPla1:GetValue()
        hData["NUM_PLACAS"]  := oGNumP:GetValue()
        IF oChkSame:GetValue()
            hData["ID_PLACA_B"] := hData["ID_PLACA_A"]
        ELSE
            hData["ID_PLACA_B"] := oGPla2:GetValue()
        ENDIF
        hData["CARAS_REALES"] := 2
        _CoreSave( hData )
        RETURN .T.
    ENDIF

RETURN .F.


STATIC FUNCTION _TabqToggleSame( oChk, oGPlB, oBtnB, hData )
    LOCAL lSame := oChk:GetValue()
    oGPlB:lEnabled := !lSame
    oBtnB:lEnabled := !lSame
    IF lSame
        oGPlB:SetValue( Space(15) )
    ENDIF
    hData["SAME_B"] := If( lSame, "S", "N" )
RETURN NIL


STATIC FUNCTION _TabqToggleAis( oChk, oGAisCod, oBtnAis, hData )
    LOCAL lAis := oChk:GetValue()
    oGAisCod:lEnabled := lAis
    oBtnAis:lEnabled := lAis
    IF !lAis
        oGAisCod:SetValue( Space(15) )
    ENDIF
    hData["AIS"] := If( lAis, "S", "N" )
RETURN NIL


STATIC FUNCTION _BtnPick( oGet, hData, cKey, cFam )
    LOCAL cCod := AllTrim( oGet:GetValue() )
    LOCAL cRet
    IF Empty( cCod )
        cRet := _PickArt( cFam )
        IF !Empty( cRet )
            hData[ cKey ] := cRet
            oGet:SetValue( PadR( cRet, 15 ) )
        ENDIF
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
    LOCAL oBtGua, oBtCan
    LOCAL lSave := .F.

    hData := _InitData( "TECHO", cTit )
    hData["MODUL"]      := 0.50
    hData["SEP_PRIM"]   := 1.00
    hData["NUM_PLACAS"] := 1

    oWin := TWindow():New( 2, 5, 24, 95, "NUEVO TECHO CONTINUO" )

    oWin:AddCtrl( TLabel():New(  2,  2, "Concepto.....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Largo (m)....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 30, "Ancho (m)....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Sep. Secundar:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 30, "Sep. Primario:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Secundario...:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 40, "Primario.....:", oWin ) )
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
    oGPer1:bValid := {|| _ValPick( hData, "ID_PERFIL", "PERFIL" ) }

    oGPer2 := TGet():New( 8, 56, hData["ID_PERFIL2"], "@!", oWin )
    oGPer2:bValid := {|| _ValPick( hData, "ID_PERFIL2", "PERFIL" ) }

    oGPla1 := TGet():New( 11, 18, hData["ID_PLACA_A"], "@!", oWin )
    oGPla1:bValid := {|| _ValPick( hData, "ID_PLACA_A", "PLACA" ) }

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
    oWin:AddCtrl( oGPer2 )
    oWin:AddCtrl( oGPla1 )
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
        hData["ID_PERFIL2"]:= oGPer2:GetValue()
        hData["ID_PLACA_A"]:= oGPla1:GetValue()
        hData["NUM_PLACAS"]:= oGNumP:GetValue()
        hData["CARAS_REALES"] := 1
        _CoreSave( hData )
        RETURN .T.
    ENDIF

RETURN .F.


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
    LOCAL oBtGua, oBtCan
    LOCAL lSave := .F.
    LOCAL cLbl1 := "Perfil.......:"
    LOCAL cLbl2 := "Canal........:"
    LOCAL lPideCanal := .T.

    hData := _InitData( cTipo, cTit )
    hData["MODUL"] := 0.60

    DO CASE
    CASE cTipo == "TRASDOSADO"
        cLbl1 := "Montante.....:"
        cLbl2 := "Canal........:"
        lPideCanal := .T.
    CASE cTipo == "TRASDOSADO_DIR"
        cLbl1 := "Montante.....:"
        cLbl2 := ""
        lPideCanal := .F.
    CASE cTipo == "TRASDOSADO_AUT"
        cLbl1 := "Autoportante.:"
        cLbl2 := ""
        lPideCanal := .F.
    ENDCASE

    oWin := TWindow():New( 2, 5, 22, 95, "NUEVO TRASDOSADO - " + cTit )

    oWin:AddCtrl( TLabel():New(  2,  2, "Concepto.....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Largo (m)....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 30, "Alto (m).....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Modulacion...:", oWin ) )
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
    oGMod  := TGet():New( 6, 18, hData["MODUL"],    "9.99",   oWin )

    oGPer1 := TGet():New( 8, 18, hData["ID_PERFIL"], "@!", oWin )
    oGPer1:bValid := {|| _ValPick( hData, "ID_PERFIL", "PERFIL" ) }

    IF lPideCanal
        oGPer2 := TGet():New( 8, 56, hData["ID_PERFIL2"], "@!", oWin )
        oGPer2:bValid := {|| _ValPick( hData, "ID_PERFIL2", "PERFIL" ) }
    ENDIF

    oGPla1 := TGet():New( 11, 18, hData["ID_PLACA_A"], "@!", oWin )
    oGPla1:bValid := {|| _ValPick( hData, "ID_PLACA_A", "PLACA" ) }

    // FIXME: aislamiento interactivo

    oBtGua := TButton():New( 18, 30, 19, 49, oWin, "GUARDAR", {|| lSave := .T., oWin:Close() } )
    oBtCan := TButton():New( 18, 52, 19, 71, oWin, "VOLVER",  {|| oWin:Close() } )

    oWin:AddCtrl( oGCon  )
    oWin:AddCtrl( oGLar  )
    oWin:AddCtrl( oGAlt  )
    oWin:AddCtrl( oGMod  )
    oWin:AddCtrl( oGPer1 )
    IF lPideCanal
        oWin:AddCtrl( oGPer2 )
    ENDIF
    oWin:AddCtrl( oGPla1 )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]  := oGCon:GetValue()
        hData["LARGO"]     := oGLar:GetValue()
        hData["ALTO"]      := oGAlt:GetValue()
        hData["MODUL"]     := oGMod:GetValue()
        hData["ID_PERFIL"] := oGPer1:GetValue()
        IF lPideCanal
            hData["ID_PERFIL2"] := oGPer2:GetValue()
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
    oGMat:bValid := {|| _ValPick( hData, "ID_PLACA_A", "GENERICO" ) }

    oWin:AddCtrl( TButton():New( 16, 30, 17, 49, oWin, "GUARDAR", {|| lSave := .T., oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 16, 52, 17, 71, oWin, "CANCELAR", {|| oWin:Close() } ) )

    oWin:AddCtrl( oGCon )
    oWin:AddCtrl( oGLar )
    oWin:AddCtrl( oGAlt )
    oWin:AddCtrl( oGMat )

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

    IF Empty( hData["CONCEPTO"] )
        MsgStop( "Falta Concepto" )
        RETURN .F.
    ENDIF

    IF hData["LARGO"] <= 0
        MsgStop( "Largo debe ser mayor a 0" )
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
