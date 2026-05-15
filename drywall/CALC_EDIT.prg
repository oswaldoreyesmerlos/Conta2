/*
 * ARCHIVO  : CALC_EDIT.prg
 * PROPOSITO: Edicion Especializada de calculos (Tabique, Techo, Trasdosado)
 * MIGRADO A: GfxStack API
 */

#include "OOp.ch"

FUNCTION EditTramo( nIdLinea )

    LOCAL lRet := .F.
    LOCAL hData
    LOCAL cTipo

    hData := _LoadData( nIdLinea )
    IF hData == NIL
        RETURN .F.
    ENDIF

    cTipo := AllTrim( hData["TIPO"] )

    DO CASE
    CASE cTipo == "TABIQUE"
        lRet := Edit_Tabique( hData )
    CASE cTipo == "TECHO"
        lRet := Edit_Techo( hData )
    CASE "TRAS" $ cTipo
        lRet := Edit_Trasdosado( hData )
    OTHERWISE
        MsgStop( "Tipo de obra desconocido: [" + cTipo + "]" )
    ENDCASE

RETURN lRet


FUNCTION Edit_Tabique( hData )

    LOCAL oWin
    LOCAL oGCon, oGLar, oGAlt, oGMod
    LOCAL oGPer1, oGPer2, oGBand
    LOCAL oGPla1, oGNumP
    LOCAL oGSame, oGPla2
    LOCAL oGAis, oGAisCod
    LOCAL lSave := .F.

    oWin := TWindow():New( 2, 5, 26, 95, "EDITAR TABIQUE" )

    oWin:AddCtrl( TLabel():New(  2,  2, "Concepto.....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Largo (m)....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 30, "Alto (m).....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Modulacion...:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Montante.....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 40, "Canal........:", oWin ) )
    oWin:AddCtrl( TLabel():New(  9, 40, "Banda Acust?.:", oWin ) )
    oWin:AddCtrl( TLabel():New( 11,  2, "Placa A......:", oWin ) )
    oWin:AddCtrl( TLabel():New( 11, 40, "Capas p/cara.:", oWin ) )
    oWin:AddCtrl( TLabel():New( 13,  2, "Igual Cara B?:", oWin ) )
    oWin:AddCtrl( TLabel():New( 13, 40, "Placa B......:", oWin ) )
    oWin:AddCtrl( TLabel():New( 15,  2, "Lleva Aislan?:", oWin ) )
    oWin:AddCtrl( TLabel():New( 15, 40, "Mat. Aislante:", oWin ) )

    oGCon  := TGet():New( 2, 18, hData["CONCEPTO"], "@!",     oWin )
    oGLar  := TGet():New( 4, 18, hData["LARGO"],    "999.99", oWin )
    oGAlt  := TGet():New( 4, 45, hData["ALTO"],     "999.99", oWin )
    oGMod  := TGet():New( 6, 18, hData["MODUL"],    "9.99",   oWin )

    oGPer1 := TGet():New( 8, 18, hData["ID_PERFIL"],  "@!", oWin )
    oGPer1:bValid := {|| _ValPick( hData, "ID_PERFIL", "PERFIL" ) }

    oGPer2 := TGet():New( 8, 56, hData["ID_PERFIL2"], "@!", oWin )
    oGPer2:bValid := {|| _ValPick( hData, "ID_PERFIL2", "PERFIL" ) }

    oGPla1 := TGet():New( 11, 18, hData["ID_PLACA_A"], "@!", oWin )
    oGPla1:bValid := {|| _ValPick( hData, "ID_PLACA_A", "PLACA" ) }

    oGNumP := TGet():New( 11, 56, hData["NUM_PLACAS"], "9", oWin )

    oGPla2 := TGet():New( 13, 56, hData["ID_PLACA_B"], "@!", oWin )
    oGPla2:bValid := {|| _ValPick( hData, "ID_PLACA_B", "PLACA" ) }

    oWin:AddCtrl( TButton():New( 22, 30, 23, 49, oWin, "ACTUALIZAR", {|| lSave := .T., oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 22, 52, 23, 71, oWin, "CANCELAR",  {|| oWin:Close() } ) )

    oWin:AddCtrl( oGCon  )
    oWin:AddCtrl( oGLar  )
    oWin:AddCtrl( oGAlt  )
    oWin:AddCtrl( oGMod  )
    oWin:AddCtrl( oGPer1 )
    oWin:AddCtrl( oGPer2 )
    oWin:AddCtrl( oGPla1 )
    oWin:AddCtrl( oGNumP )
    oWin:AddCtrl( oGPla2 )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]    := oGCon:GetValue()
        hData["LARGO"]       := oGLar:GetValue()
        hData["ALTO"]        := oGAlt:GetValue()
        hData["MODUL"]       := oGMod:GetValue()
        hData["ID_PERFIL"]   := oGPer1:GetValue()
        hData["ID_PERFIL2"]  := oGPer2:GetValue()
        hData["ID_PLACA_A"]  := oGPla1:GetValue()
        hData["NUM_PLACAS"]  := oGNumP:GetValue()
        hData["ID_PLACA_B"]  := oGPla2:GetValue()
        hData["CARAS_REALES"] := 2
        _UpdateData( hData )
        RETURN .T.
    ENDIF

RETURN .F.


FUNCTION Edit_Techo( hData )

    LOCAL oWin
    LOCAL oGCon, oGLar, oGAnc
    LOCAL oGMod, oGSepP
    LOCAL oGPer1, oGPer2, oGPer3, oGAnc2
    LOCAL oGPla1, oGNumP
    LOCAL oGAis, oGAisCod
    LOCAL lSave := .F.

    oWin := TWindow():New( 2, 5, 27, 95, "EDITAR TECHO" )

    oWin:AddCtrl( TLabel():New(  2,  2, "Concepto.....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Largo (m)....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 30, "Ancho (m)....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Sep. Secundar:", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 30, "Sep. Primario:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Secundario...:", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 40, "Primario.....:", oWin ) )
    oWin:AddCtrl( TLabel():New(  9,  2, "Perimetral...:", oWin ) )
    oWin:AddCtrl( TLabel():New(  9, 40, "Anclaje/Susp.:", oWin ) )
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
    oGPer3 := TGet():New( 9, 18, hData["ID_PERFIL3"], "@!", oWin )
    oGPer3:bValid := {|| _ValPick( hData, "ID_PERFIL3", "PERFIL" ) }
    oGAnc2 := TGet():New( 9, 56, hData["ID_ANCLAJE"], "@!", oWin )
    oGAnc2:bValid := {|| _ValPick( hData, "ID_ANCLAJE", "ANCLAJE" ) }

    oGPla1 := TGet():New( 11, 18, hData["ID_PLACA_A"], "@!", oWin )
    oGPla1:bValid := {|| _ValPick( hData, "ID_PLACA_A", "PLACA" ) }
    oGNumP := TGet():New( 11, 56, hData["NUM_PLACAS"], "9", oWin )

    oWin:AddCtrl( TButton():New( 23, 30, 24, 49, oWin, "ACTUALIZAR", {|| lSave := .T., oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 23, 52, 24, 71, oWin, "CANCELAR",  {|| oWin:Close() } ) )

    oWin:AddCtrl( oGCon  )
    oWin:AddCtrl( oGLar  )
    oWin:AddCtrl( oGAnc  )
    oWin:AddCtrl( oGMod  )
    oWin:AddCtrl( oGSepP )
    oWin:AddCtrl( oGPer1 )
    oWin:AddCtrl( oGPer2 )
    oWin:AddCtrl( oGPer3 )
    oWin:AddCtrl( oGAnc2 )
    oWin:AddCtrl( oGPla1 )
    oWin:AddCtrl( oGNumP )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]   := oGCon:GetValue()
        hData["LARGO"]      := oGLar:GetValue()
        hData["ALTO"]       := oGAnc:GetValue()
        hData["MODUL"]      := oGMod:GetValue()
        hData["SEP_PRIM"]   := oGSepP:GetValue()
        hData["ID_PERFIL"]  := oGPer1:GetValue()
        hData["ID_PERFIL2"] := oGPer2:GetValue()
        hData["ID_PERFIL3"] := oGPer3:GetValue()
        hData["ID_ANCLAJE"] := oGAnc2:GetValue()
        hData["ID_PLACA_A"] := oGPla1:GetValue()
        hData["NUM_PLACAS"] := oGNumP:GetValue()
        hData["CARAS_REALES"] := 1
        _UpdateData( hData )
        RETURN .T.
    ENDIF

RETURN .F.


FUNCTION Edit_Trasdosado( hData )

    LOCAL oWin
    LOCAL oGCon, oGLar, oGAlt, oGMod
    LOCAL oGPer1, oGPer2
    LOCAL oGPla1
    LOCAL oGAis, oGAisCod
    LOCAL lSave := .F.
    LOCAL cTipo := hData["TIPO"]
    LOCAL cLbl1 := "Perfil.......:"
    LOCAL cLbl2 := "Canal........:"
    LOCAL lPideCanal := .T.
    LOCAL lPideMod := .T.

    DO CASE
    CASE cTipo == "TRAS_DIR"
        cLbl1 := "Pasta Agarre.:"
        lPideCanal := .F.
        lPideMod := .F.
    CASE cTipo == "TRAS_SEM"
        cLbl1 := "Perf. Omega..:"
        cLbl2 := "Angular......:"
    ENDCASE

    oWin := TWindow():New( 2, 5, 24, 95, "EDITAR TRASDOSADO" )

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
    oGAlt  := TGet():New( 4, 45, hData["ALTO"],     "999.99", oWin )
    IF lPideMod
        oGMod := TGet():New( 6, 18, hData["MODUL"], "9.99",   oWin )
    ENDIF

    oGPer1 := TGet():New( 8, 18, hData["ID_PERFIL"], "@!", oWin )
    oGPer1:bValid := {|| _ValPick( hData, "ID_PERFIL", "PERFIL" ) }

    IF lPideCanal
        oGPer2 := TGet():New( 8, 56, hData["ID_PERFIL2"], "@!", oWin )
        oGPer2:bValid := {|| _ValPick( hData, "ID_PERFIL2", "PERFIL" ) }
    ENDIF

    oGPla1 := TGet():New( 11, 18, hData["ID_PLACA_A"], "@!", oWin )
    oGPla1:bValid := {|| _ValPick( hData, "ID_PLACA_A", "PLACA" ) }

    oWin:AddCtrl( TButton():New( 20, 30, 21, 49, oWin, "ACTUALIZAR", {|| lSave := .T., oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 20, 52, 21, 71, oWin, "CANCELAR",  {|| oWin:Close() } ) )

    oWin:AddCtrl( oGCon  )
    oWin:AddCtrl( oGLar  )
    oWin:AddCtrl( oGAlt  )
    IF lPideMod
        oWin:AddCtrl( oGMod )
    ENDIF
    oWin:AddCtrl( oGPer1 )
    IF lPideCanal
        oWin:AddCtrl( oGPer2 )
    ENDIF
    oWin:AddCtrl( oGPla1 )

    oWin:Run()

    IF lSave
        hData["CONCEPTO"]  := oGCon:GetValue()
        hData["LARGO"]     := oGLar:GetValue()
        hData["ALTO"]      := oGAlt:GetValue()
        IF lPideMod
            hData["MODUL"] := oGMod:GetValue()
        ENDIF
        hData["ID_PERFIL"] := oGPer1:GetValue()
        IF lPideCanal
            hData["ID_PERFIL2"] := oGPer2:GetValue()
        ENDIF
        hData["ID_PLACA_A"] := oGPla1:GetValue()
        hData["CARAS_REALES"] := 1
        _UpdateData( hData )
        RETURN .T.
    ENDIF

RETURN .F.


// ============================================================================
// FUNCIONES DE APOYO
// ============================================================================
STATIC FUNCTION _LoadData( nIdLinea )

    LOCAL hData := hb_Hash()
    LOCAL cTipo

    IF Select( "TMP_TRA" ) == 0
        USE TMP_TRA NEW SHARED VIA "DBFCDX"
    ENDIF

    dbSelectArea( "TMP_TRA" )
    dbGoTop()

    DO WHILE !Eof()
        IF FIELD->ID_LINEA == nIdLinea
            hData["ID_LINEA"]   := FIELD->ID_LINEA
            hData["TIPO"]       := FIELD->TIPO_OBRA
            hData["CONCEPTO"]   := FIELD->CONCEPTO
            hData["LARGO"]      := FIELD->LARGO
            hData["ALTO"]       := FIELD->ALTO
            hData["MODUL"]      := FIELD->MODUL
            hData["SEP_PRIM"]   := FIELD->SEP_PRIM
            hData["NUM_PLACAS"] := FIELD->PLAC_CARA
            hData["SAME_B"]     := "S"
            hData["ID_PERFIL"]  := FIELD->ID_PER_VER
            hData["ID_PERFIL2"] := FIELD->ID_PER_HOR
            hData["ID_PERFIL3"] := FIELD->ID_PER_PER
            hData["ID_ANCLAJE"] := FIELD->ID_ANCLAJE
            hData["ID_PLACA_A"] := FIELD->ID_PLACA_A
            hData["ID_PLACA_B"] := FIELD->ID_PLACA_B
            hData["ID_AISLAN"]  := FIELD->ID_AISLANT
            hData["AIS"]        := If( FIELD->L_AISLANT, "S", "N" )
            hData["BANDA"]      := If( FIELD->L_BANDA, "S", "N" )

            cTipo := AllTrim( FIELD->TIPO_OBRA )
            IF cTipo == "TABIQUE" .AND. !Empty( FIELD->ID_PLACA_B ) .AND. ;
               FIELD->ID_PLACA_A == FIELD->ID_PLACA_B
                hData["SAME_B"] := "S"
            ELSE
                hData["SAME_B"] := "N"
            ENDIF

            dbCloseArea()
            RETURN hData
        ENDIF
        dbSkip()
    ENDDO

    MsgStop( "No se encontro el tramo " + AllTrim( Str( nIdLinea ) ) )
RETURN NIL


STATIC FUNCTION _UpdateData( hData )

    dbSelectArea( "TMP_TRA" )
    dbGoTop()

    DO WHILE !Eof()
        IF FIELD->ID_LINEA == hData["ID_LINEA"]
            IF NetRLock()
                REPLACE FIELD->CONCEPTO   WITH hData["CONCEPTO"]
                REPLACE FIELD->LARGO      WITH hData["LARGO"]
                REPLACE FIELD->ALTO       WITH hData["ALTO"]
                REPLACE FIELD->MODUL      WITH hData["MODUL"]
                REPLACE FIELD->SEP_PRIM   WITH hData["SEP_PRIM"]
                REPLACE FIELD->PLAC_CARA  WITH hData["NUM_PLACAS"]
                REPLACE FIELD->ID_PER_VER WITH hData["ID_PERFIL"]
                REPLACE FIELD->ID_PER_HOR WITH hData["ID_PERFIL2"]
                IF hb_HHasKey( hData, "ID_PERFIL3" )
                    REPLACE FIELD->ID_PER_PER WITH hData["ID_PERFIL3"]
                ENDIF
                IF hb_HHasKey( hData, "ID_ANCLAJE" )
                    REPLACE FIELD->ID_ANCLAJE WITH hData["ID_ANCLAJE"]
                ENDIF
                REPLACE FIELD->ID_PLACA_A WITH hData["ID_PLACA_A"]
                REPLACE FIELD->ID_PLACA_B WITH hData["ID_PLACA_B"]
                REPLACE FIELD->ID_AISLANT WITH hData["ID_AISLAN"]
                REPLACE FIELD->L_AISLANT  WITH ( hData["AIS"] == "S" )
                REPLACE FIELD->L_BANDA    WITH ( hData["BANDA"] == "S" )
                DbCommit()
                DbUnlock()
            ENDIF
            dbCloseArea()
            RETURN .T.
        ENDIF
        dbSkip()
    ENDDO

    MsgStop( "No se pudo actualizar el tramo." )
RETURN .F.


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
