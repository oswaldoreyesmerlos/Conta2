#include "OOp.ch"
#include "hbclass.ch"
 
// Constantes de Rendimiento
#define K_DESP_PLA   1.05
#define K_DESP_PER   1.10
#define K_TORN_M2    15  
#define K_TORN_MM    4   
#define K_PASTA_M2   0.40
#define K_CINTA_M2   1.45
#define K_GUARDA_M2  0.15

CLASS OOPTRAMO
   
   DATA nErrores  INIT 0
   DATA aLog      INIT {}  // <--- Nuevo: Historial de incidencias

   METHOD New()
   METHOD Procesar( lTodo )
   METHOD MostrarErrores() // <--- Nuevo: Reporte final
   
   PROTECTED:
      METHOD LimpiarLinea( nIdLin )
      METHOD Calc_Rendimientos()
      METHOD CodigoRendimiento( cRol, cCodDef )
      METHOD MatchRendimiento( cSistema, cTipo, nMod, nCaras, nCapas, nAncho )
      METHOD Calc_Tabique()
      METHOD Calc_Techo()
       METHOD Calc_Trasdos()
       METHOD Calc_Generico()
       METHOD AddMat( cFam, cCod, nCant, cDet, cUdTec )
         METHOD DesgloseAnclaje( cIdAnc, nArea, nSepPrim, nMod )
         METHOD GetRendimientoRol( cRolRendimiento, nRendimientoDefecto )

ENDCLASS

// ----------------------------------------------------------------------------
// CONSTRUCTOR
// ----------------------------------------------------------------------------
METHOD New() CLASS OOPTRAMO
   ::aLog := {}
   ::nErrores := 0
RETURN Self

// ----------------------------------------------------------------------------
// METODO PRINCIPAL
// ----------------------------------------------------------------------------
METHOD Procesar( lTodo ) CLASS OOPTRAMO

   LOCAL nArea := Select()
   LOCAL cTipo
   LOCAL cSistema
   LOCAL lRendimientos
   LOCAL cProyecto := _OopProyectoActual()
   
   DEFAULT lTodo TO .T.

   // Limpiamos errores previos al iniciar proceso
   ::nErrores := 0
   ::aLog     := {}
   
   IF lTodo
      dbSelectArea( "TMP_TRA" )
      dbGoTop()
   ENDIF

   dbSelectArea( "TMP_TRA" )
   
   WHILE !Eof()

      IF !Deleted() .AND. AllTrim( FIELD->NUMERO ) == cProyecto
         ::LimpiarLinea( FIELD->ID_LINEA )
         cTipo := Upper( AllTrim( FIELD->TIPO_OBRA ) )
         cSistema := ""
         IF FieldPos( "SISTEMA_ID" ) > 0
            cSistema := Upper( AllTrim( FIELD->SISTEMA_ID ) )
         ENDIF

         lRendimientos := ::Calc_Rendimientos()

         IF !lRendimientos
            IF cTipo == "TECHO" .AND. !Empty( cSistema )
               ::nErrores++
               AAdd( ::aLog, "Lin " + AllTrim( Str( FIELD->ID_LINEA ) ) + ;
                              ": El sistema de techo [" + cSistema + ;
                              "] no tiene una receta SYS_REND compatible." )
            ELSE
               DO CASE
               CASE cTipo == "TABIQUE"
                  ::Calc_Tabique()

               CASE cTipo == "TECHO"
                  ::Calc_Techo()

               CASE "TRAS" $ cTipo
                  ::Calc_Trasdos()

               CASE cTipo == "GENERICO"
                  ::Calc_Generico()

               OTHERWISE
                  ::nErrores++
                  AAdd( ::aLog, "Lin " + AllTrim( Str( FIELD->ID_LINEA ) ) + ;
                                 ": Tipo de obra [" + cTipo + "] no soportado." )
               ENDCASE
            ENDIF
         ENDIF
      ENDIF

      IF !lTodo
         EXIT
      ENDIF

      dbSkip()
   ENDDO
   
   dbSelectArea( nArea )

RETURN NIL


STATIC FUNCTION _OopProyectoActual()

RETURN DrywallProyectoActualNumero()

// ----------------------------------------------------------------------------
// REPORTE DE ERRORES (Visualización)
// ----------------------------------------------------------------------------
METHOD MostrarErrores() CLASS OOPTRAMO
   
   LOCAL cMsg := "ATENCION: Se detectaron " + AllTrim(Str(::nErrores)) + " errores:" + Chr(13)
   LOCAL nI
   LOCAL nMax := 5 // Solo mostramos los 5 primeros para no saturar
   
   FOR nI := 1 TO Len( ::aLog )
      IF nI > nMax
         cMsg += "... y otros " + AllTrim(Str(Len(::aLog)-nMax)) + " mas."
         EXIT
      ENDIF
      
      cMsg += "- " + ::aLog[ nI ] + Chr(13)
   NEXT
   
   Alert( cMsg )

RETURN NIL


// ----------------------------------------------------------------------------
// METODOS DE LIMPIEZA Y CALCULO (Sin Cambios)
// ----------------------------------------------------------------------------
METHOD LimpiarLinea( nIdLin ) CLASS OOPTRAMO
   
   LOCAL nOrdAnt := 0
   LOCAL cNum := TMP_TRA->NUMERO
   
   dbSelectArea( "TMP_MAT" )
   nOrdAnt := IndexOrd()
    OrdSetFocus( "MAT_LIN" )
   
   IF dbSeek( cNum + Str( nIdLin, 4 ) )
      WHILE !Eof() .AND. TMP_MAT->NUMERO == cNum .AND. TMP_MAT->ID_LINEA == nIdLin
         IF !FIELD->L_MANUAL
            IF NetRLock()
               dbDelete()
               dbCommit()
               dbUnlock()
            ELSE
               ::nErrores++
               AAdd( ::aLog, "Lin " + AllTrim( Str( nIdLin ) ) + ;
                              ": No se pudo bloquear TMP_MAT para limpiar material previo." )
            ENDIF
         ENDIF
         dbSkip()
      ENDDO
   ENDIF
   
   dbSetOrder( nOrdAnt )
   dbSelectArea( "TMP_TRA" )

RETURN NIL

METHOD Calc_Rendimientos() CLASS OOPTRAMO

   LOCAL nAreaAnt := Select()
   LOCAL cSistema := ""
   LOCAL cTipo    := Upper( AllTrim( TMP_TRA->TIPO_OBRA ) )
   LOCAL nMod     := TMP_TRA->MODUL
    LOCAL nCaras   := If( ValType( TMP_TRA->CARAS ) == "N", TMP_TRA->CARAS, 0 )
    LOCAL nCapas   := Max( TMP_TRA->PLAC_CARA, 1 )
   LOCAL nAncho   := 0
   LOCAL nArea    := TMP_TRA->LARGO * TMP_TRA->ALTO
   LOCAL cFam
   LOCAL cRol
   LOCAL cCod
   LOCAL cUd
   LOCAL nCant
   LOCAL lTieneRend := .F.
   LOCAL lAbriRend  := .F.

   IF nArea <= 0
      RETURN .F.
   ENDIF

   IF nMod == 0
      IF cTipo == "TECHO"
         nMod := 0.50
      ELSE
         nMod := 0.60
      ENDIF
   ENDIF

   IF nCaras <= 0
      nCaras := If( cTipo == "TABIQUE", 2, 1 )
   ENDIF

   IF FieldPos( "SISTEMA_ID" ) > 0
      cSistema := Upper( AllTrim( TMP_TRA->SISTEMA_ID ) )
   ENDIF

   IF FieldPos( "ANCHO_PERF" ) > 0
      nAncho := TMP_TRA->ANCHO_PERF
   ENDIF

   IF Select( "SYS_REND" ) == 0
      IF !File( "SYS_REND.DBF" )
         RETURN .F.
      ENDIF
      BEGIN SEQUENCE WITH {|oErr| Break( oErr )}
         USE SYS_REND NEW SHARED VIA "DBFCDX" ALIAS SYS_REND
         lAbriRend := .T.
      RECOVER
         RETURN .F.
      END SEQUENCE
   ENDIF

   dbSelectArea( "SYS_REND" )
   dbGoTop()

   DO WHILE !Eof()
      IF !Deleted() .AND. ;
         ::MatchRendimiento( cSistema, cTipo, nMod, nCaras, nCapas, nAncho )
         cFam  := Upper( AllTrim( FIELD->FAMILIA ) )
         cRol  := Upper( AllTrim( FIELD->ROL_MAT ) )
         cUd   := Upper( AllTrim( FIELD->UD_TEC ) )
         cCod  := ::CodigoRendimiento( cRol, FIELD->CODIGO_DEF )
         nCant := nArea * FIELD->REND_M2

         IF !_OptionalCode( cCod ) .AND. nCant > 0
            ::AddMat( cFam, cCod, nCant, cRol, cUd )
            lTieneRend := .T.
         ENDIF
      ENDIF
      dbSkip()
   ENDDO

   IF lAbriRend
      dbCloseArea()
   ENDIF

   IF nAreaAnt > 0
      dbSelectArea( nAreaAnt )
   ENDIF

RETURN lTieneRend


METHOD MatchRendimiento( cSistema, cTipo, nMod, nCaras, nCapas, nAncho ) CLASS OOPTRAMO

   IF !Empty( cSistema ) .AND. Upper( AllTrim( FIELD->SISTEMA_ID ) ) != cSistema
      RETURN .F.
   ENDIF

   IF Empty( cSistema ) .AND. Upper( AllTrim( FIELD->TIPO_OBRA ) ) != cTipo
      RETURN .F.
   ENDIF

   IF FIELD->CARAS != nCaras
      RETURN .F.
   ENDIF

   IF FIELD->CAPAS != nCapas
      RETURN .F.
   ENDIF

   IF Abs( FIELD->MODUL - nMod ) > 0.001
      RETURN .F.
   ENDIF

   IF FIELD->ANCHO_PERF > 0 .AND. nAncho > 0 .AND. FIELD->ANCHO_PERF != nAncho
      RETURN .F.
   ENDIF

RETURN .T.


METHOD CodigoRendimiento( cRol, cCodDef ) CLASS OOPTRAMO

   LOCAL cCod := Upper( AllTrim( hb_CStr( cCodDef ) ) )

   DO CASE
   CASE cRol == "PLACA_A"
      cCod := TMP_TRA->ID_PLACA_A

   CASE cRol == "PLACA_B"
      cCod := TMP_TRA->ID_PLACA_B

   CASE cRol == "MONTANTE" .OR. cRol == "PERF_SEC"
      cCod := TMP_TRA->ID_PER_VER

   CASE cRol == "CANAL" .OR. cRol == "PERF_PRI"
      cCod := TMP_TRA->ID_PER_HOR

   CASE cRol == "PERF_PER"
      cCod := TMP_TRA->ID_PER_PER

   CASE cRol == "PASTA_AGAR"
      IF !_OptionalCode( TMP_TRA->ID_PER_VER )
         cCod := TMP_TRA->ID_PER_VER
      ELSEIF Empty( cCod )
         cCod := "PASTA_AGAR"
      ENDIF

   CASE cRol == "AISLANTE"
       IF !If( ValType( TMP_TRA->L_AISLANT ) == "L", TMP_TRA->L_AISLANT, .F. )
         RETURN ""
      ENDIF
      cCod := TMP_TRA->ID_AISLANT

   CASE cRol == "JUNTA_EST"
       IF !If( ValType( TMP_TRA->L_BANDA ) == "L", TMP_TRA->L_BANDA, .F. )
         RETURN ""
      ENDIF

   CASE Empty( cCod )
      DO CASE
      CASE cRol == "PASTA_JUNT"
         cCod := "PASTA_JUNT"
      CASE cRol == "CINTA_JUNT"
         cCod := "CINTA_PAP"
      CASE cRol == "CINTA_GUAR"
         cCod := "CINTA_GUAR"
      CASE cRol == "TORN_PM_1"
         cCod := "TORN_PM_25"
      CASE cRol == "TORN_PM_2"
         cCod := "TORN_PM_35"
      CASE cRol == "TORN_PM_3"
         cCod := "TORN_PM_45"
      CASE cRol == "TORN_MM"
         cCod := "TORN_MM_9"
      ENDCASE
   ENDCASE

RETURN cCod


METHOD Calc_Tabique() CLASS OOPTRAMO
   LOCAL nLargo   := FIELD->LARGO
   LOCAL nAlto    := FIELD->ALTO
   LOCAL nMod     := FIELD->MODUL
   LOCAL nArea    := nLargo * nAlto
    LOCAL nCapas   := If( ValType( FIELD->PLAC_CARA ) == "N", FIELD->PLAC_CARA, 0 )
    LOCAL nMont, nMetCan, nM2Total
    LOCAL nCaras   := If( ValType( FIELD->CARAS ) == "N", FIELD->CARAS, 0 )
   LOCAL lCaraB   := ( !_OptionalCode( FIELD->ID_PLACA_B ) .AND. ;
                        ( nCaras == 0 .OR. nCaras > 1 ) )
   LOCAL nCapa

   IF nMod == 0; nMod := 0.60; ENDIF
   nCaras := If( lCaraB, 2, 1 )

   nMont   := Ceiling( ( nLargo / nMod ) + 1 )
   nMetCan  := nLargo * 2
   nM2Total := nArea * nCaras * Max( nCapas, 1 )
   
   ::AddMat( "PERFIL", FIELD->ID_PER_VER, nMont, "Montantes verticales", "UD" )
   ::AddMat( "PERFIL", FIELD->ID_PER_HOR, nMetCan * K_DESP_PER, "Guia Suelo/Techo", "ML" )
   
    IF If( ValType( FIELD->L_BANDA ) == "L", FIELD->L_BANDA, .F. )
      ::AddMat( "ACCESORIO", "BANDA_ACUS", nMetCan, "Banda Estanqueidad", "ML" )
   ENDIF

   FOR nCapa := 1 TO Max( nCapas, 1 )
      ::AddMat( "PLACA", FIELD->ID_PLACA_A, nArea * K_DESP_PLA, ;
         If( nCapa == 1, "Revestimiento Cara A", AllTrim( Str( nCapa ) ) + "a Capa Cara A" ), "M2" )

      IF lCaraB
         ::AddMat( "PLACA", FIELD->ID_PLACA_B, nArea * K_DESP_PLA, ;
            If( nCapa == 1, "Revestimiento Cara B", AllTrim( Str( nCapa ) ) + "a Capa Cara B" ), "M2" )
      ENDIF

      ::AddMat( "TORNILLO", If( nCapa == 1, "TORN_PM_25", "TORN_PM_35" ), ;
         nArea * nCaras * K_TORN_M2, "Fijacion " + AllTrim( Str( nCapa ) ) + "a Capa", "UD" )
   NEXT
   
   ::AddMat( "PASTA", "PASTA_JUNT", nM2Total * K_PASTA_M2, "Tratamiento Juntas", "KG" )
    ::AddMat( "CINTA", "CINTA_PAP", ;
       nM2Total * ::GetRendimientoRol( "CINTA_JUNT", K_CINTA_M2 ), ;
       "Cinta Papel", "ML" )
   
    IF If( ValType( FIELD->L_AISLANT ) == "L", FIELD->L_AISLANT, .F. )
       ::AddMat( "AISLAN", FIELD->ID_AISLANT, nArea * K_DESP_PLA, "Lana Mineral Interior", "M2" )
   ENDIF
RETURN NIL

METHOD Calc_Techo() CLASS OOPTRAMO
   LOCAL nLargo   := FIELD->LARGO
   LOCAL nAlto    := FIELD->ALTO 
   LOCAL nArea    := nLargo * nAlto
   LOCAL nPerim   := ( nLargo + nAlto ) * 2
   LOCAL nMod     := FIELD->MODUL    
   LOCAL nSepPrim := FIELD->SEP_PRIM 
   LOCAL nMetSec, nMetPri, nCruces
   LOCAL nCapas   := Max( FIELD->PLAC_CARA, 1 )
   LOCAL nCapa
   
   IF nMod == 0; nMod := 0.50; ENDIF

   nMetSec := nArea / nMod

   ::AddMat( "PERFIL", FIELD->ID_PER_VER, nMetSec * K_DESP_PER, "Perfil Secundario", "ML" )

   IF nSepPrim > 0 .AND. !_OptionalCode( FIELD->ID_PER_HOR )
       nMetPri := nArea / nSepPrim
       nCruces := nArea / ( nMod * nSepPrim )
       ::AddMat( "PERFIL", FIELD->ID_PER_HOR, nMetPri * K_DESP_PER, "Perfil Primario", "ML" )
       ::AddMat( "ACCESORIO", "PIEZA_CRUCE", nCruces, "Union Prim-Sec", "UD" )
   ENDIF

   ::AddMat( "PERFIL", FIELD->ID_PER_PER, nPerim  * K_DESP_PER, "Angular Perimetral", "ML" )
   
   FOR nCapa := 1 TO nCapas
      ::AddMat( "PLACA", FIELD->ID_PLACA_A, nArea * K_DESP_PLA, ;
         If( nCapa == 1, "Techo Continuo", AllTrim( Str( nCapa ) ) + "a Capa Techo" ), "M2" )
      ::AddMat( "TORNILLO", If( nCapa == 1, "TORN_PM_25", "TORN_PM_35" ), ;
         nArea * K_TORN_M2, "Fijacion Placa " + AllTrim( Str( nCapa ) ) + "a Capa", "UD" )
   NEXT

    ::DesgloseAnclaje( FIELD->ID_ANCLAJE, nArea, If( nSepPrim > 0, nSepPrim, 1.00 ), nMod )
   ::AddMat( "PASTA",    "PASTA_JUNT", nArea * nCapas * K_PASTA_M2, "Juntas Techo", "KG" )
    ::AddMat( "CINTA", "CINTA_PAP", ;
       nArea * nCapas * ::GetRendimientoRol( "CINTA_JUNT", K_CINTA_M2 ), ;
       "Cinta Techo", "ML" )
   
    IF If( ValType( FIELD->L_AISLANT ) == "L", FIELD->L_AISLANT, .F. )
       ::AddMat( "AISLAN", FIELD->ID_AISLANT, nArea * K_DESP_PLA, "Aislamiento", "M2" )
    ENDIF

RETURN NIL

METHOD Calc_Trasdos() CLASS OOPTRAMO

   LOCAL nLargo := FIELD->LARGO
   LOCAL nAlto  := FIELD->ALTO
   LOCAL nArea  := nLargo * nAlto
   LOCAL nMod   := FIELD->MODUL
   LOCAL nCapas := Max( FIELD->PLAC_CARA, 1 )
   LOCAL nCapa
   LOCAL lDirect := ( "DIR" $ Upper( AllTrim( FIELD->TIPO_OBRA ) ) )
   
   LOCAL nMont := 0
   LOCAL nMetHor  := 0
   
   IF lDirect
      ::AddMat( "PASTA", "PASTA_AGAR", nArea * K_PASTA_M2, "Pasta Agarre", "KG" )
   ELSE
      IF nMod == 0; nMod := 0.60; ENDIF

      nMont    := Ceiling( ( nLargo / nMod ) + 1 )
      nMetHor  := nLargo * 2

      ::AddMat( "PERFIL", FIELD->ID_PER_VER, nMont, "Maestra/Montante" , "UD" )

      IF !_OptionalCode( FIELD->ID_PER_HOR )
         ::AddMat( "PERFIL", FIELD->ID_PER_HOR, nMetHor * K_DESP_PER, "Canal Suelo/Techo", "ML" )
      ENDIF
   ENDIF
   
   FOR nCapa := 1 TO nCapas
      ::AddMat( "PLACA", FIELD->ID_PLACA_A, nArea * K_DESP_PLA, ;
         If( nCapa == 1, "Trasdosado", AllTrim( Str( nCapa ) ) + "a Capa Trasdosado" ), "M2" )
      IF !lDirect
         ::AddMat( "TORNILLO", If( nCapa == 1, "TORN_PM_25", "TORN_PM_35" ), ;
            nArea * K_TORN_M2, "Fijacion " + AllTrim( Str( nCapa ) ) + "a Capa", "UD" )
      ENDIF
   NEXT

   ::AddMat( "PASTA", "PASTA_JUNT", nArea * nCapas * K_PASTA_M2, "Juntas", "KG" )
    ::AddMat( "CINTA", "CINTA_PAP", ;
       nArea * nCapas * ::GetRendimientoRol( "CINTA_JUNT", K_CINTA_M2 ), ;
       "Cinta Juntas Trasdosado", "ML" )

   IF !lDirect
      ::AddMat( "TORNILLO", "TORN_MM_LN", nArea * K_TORN_MM, "Tornillo Fijacion Estructura", "UD" )
   ENDIF

   ::AddMat( "CINTA", "CINTA_GUAR", nArea * K_GUARDA_M2, "Guardavivos", "ML" )

    IF If( ValType( FIELD->L_AISLANT ) == "L", FIELD->L_AISLANT, .F. )
       ::AddMat( "AISLAN", FIELD->ID_AISLANT, nArea * K_DESP_PLA, "Aislamiento", "M2" )
    ENDIF

RETURN NIL

METHOD Calc_Generico() CLASS OOPTRAMO

   LOCAL nLargo := FIELD->LARGO
   LOCAL nAlto  := FIELD->ALTO
   LOCAL nArea  := nLargo * nAlto
   LOCAL cMat   := FIELD->ID_PLACA_A

   IF !Empty( cMat )
      ::AddMat( "GENERICO", cMat, nArea * K_DESP_PLA, "Material base", "M2" )
   ENDIF

    IF If( ValType( FIELD->L_AISLANT ) == "L", FIELD->L_AISLANT, .F. )
       ::AddMat( "AISLAN", FIELD->ID_AISLANT, nArea * K_DESP_PLA, "Aislamiento", "M2" )
    ENDIF

RETURN NIL


METHOD DesgloseAnclaje( cIdAnc, nArea, nSepPrim, nMod ) CLASS OOPTRAMO
    
    LOCAL nPuntos
    
    IF _OptionalCode( cIdAnc ) .OR. nSepPrim <= 0
       RETURN NIL
    ENDIF

    IF nMod == NIL .OR. nMod <= 0; nMod := 1.00; ENDIF
    nPuntos := nArea / ( nSepPrim * nMod )
   
   DO CASE
      CASE "VARILLA" $ Upper( cIdAnc )
         ::AddMat( "ANCLAJE", "TACO_LATON", nPuntos, "Taco Expansion", "UD" )
         ::AddMat( "ANCLAJE", "VARILLA_M6", nPuntos * 0.50, "Varilla Roscada (Media)", "ML" )
         ::AddMat( "ANCLAJE", "TUERCA_M6",  nPuntos * 2, "Tuercas Nivelacion", "UD" )
         ::AddMat( "ANCLAJE", "PIVOT_TC60", nPuntos, "Cuelgue Perfil", "UD" )
         
      CASE "NONIUS" $ Upper( cIdAnc )
         ::AddMat( "ANCLAJE", "NONIUS_SUP", nPuntos, "Parte Superior", "UD" )
         ::AddMat( "ANCLAJE", "NONIUS_INF", nPuntos, "Parte Inferior", "UD" )
         ::AddMat( "ANCLAJE", "NONIUS_PAS", nPuntos * 2, "Pasadores", "UD" )
         
      CASE "DIRECT" $ Upper( cIdAnc )
         ::AddMat( "ANCLAJE", "HORQ_TC60",  nPuntos, "Horquilla Directa", "UD" )
         ::AddMat( "ANCLAJE", "TORN_MM_LN", nPuntos * 2, "Tornillo Fijacion", "UD" )
         
      OTHERWISE
         ::AddMat( "ANCLAJE", cIdAnc, nPuntos, "Sistema Cuelgue", "UD" )
   ENDCASE

RETURN NIL

// ----------------------------------------------------------------------------
// Busca un rendimiento por SISTEMA_ID + TIPO_OBRA + ROL_MAT.
// Si no encuentra, devuelve el rendimiento de respaldo.
// ----------------------------------------------------------------------------
METHOD GetRendimientoRol( cRolRendimiento, nRendimientoDefecto ) CLASS OOPTRAMO
   LOCAL nRendimiento := nRendimientoDefecto
   LOCAL nArea := Select()
   LOCAL cSistemaId := Upper( AllTrim( FIELD->SISTEMA_ID ) )
   LOCAL cTipoObra := Upper( AllTrim( FIELD->TIPO_OBRA ) )
   LOCAL lAbriRendimientos := .F.

   cRolRendimiento := Upper( AllTrim( cRolRendimiento ) )

   IF Select( "SYS_REND" ) == 0 .AND. File( "SYS_REND.DBF" )
      BEGIN SEQUENCE WITH {|oErr| Break( oErr )}
         USE SYS_REND NEW SHARED VIA "DBFCDX" ALIAS SYS_REND
         OrdSetFocus( "SR_SIS" )
         lAbriRendimientos := .T.
      RECOVER
         lAbriRendimientos := .F.
      END SEQUENCE
   ENDIF

   IF !Empty( cSistemaId ) .AND. Select( "SYS_REND" ) > 0
      dbSelectArea( "SYS_REND" )
      OrdSetFocus( "SR_SIS" )
      IF dbSeek( cSistemaId )
         DO WHILE !Eof() .AND. Upper( AllTrim( SYS_REND->SISTEMA_ID ) ) == cSistemaId
            IF Upper( AllTrim( SYS_REND->TIPO_OBRA ) ) == cTipoObra .AND. ;
               Upper( AllTrim( SYS_REND->ROL_MAT ) ) == cRolRendimiento
               nRendimiento := SYS_REND->REND_M2
               EXIT
            ENDIF
            dbSkip()
         ENDDO
      ENDIF
   ENDIF

   IF lAbriRendimientos
      dbSelectArea( "SYS_REND" )
      dbCloseArea()
   ENDIF

   IF nArea > 0
      dbSelectArea( nArea )
   ENDIF
RETURN nRendimiento

// ----------------------------------------------------------------------------
// HERRAMIENTA CENTRAL: Añadir Material (CON VALIDACION DE ERRORES)
// ----------------------------------------------------------------------------
METHOD AddMat( cFam, cCod, nCant, cDet, cUdTec ) CLASS OOPTRAMO

   LOCAL nPrecio := 0
   LOCAL nPesoU  := 0
   LOCAL nLargo  := 0
   LOCAL nAncho  := 0
   LOCAL cDesc   := ""
   LOCAL cUni    := ""
   LOCAL nAreaArt
   LOCAL nOrdArt := 0
   LOCAL cMsgErr := ""
   LOCAL nPesoTot := 0
   LOCAL cUdCons := ""
   LOCAL lEncontrado := .F.

   DEFAULT cUdTec TO ""
   
   IF _OptionalCode( cCod )
      RETURN NIL
   ENDIF

   cCod := Upper( AllTrim( hb_CStr( cCod ) ) )
   cUdCons := Upper( AllTrim( hb_CStr( cUdTec ) ) )
   
   nAreaArt := Select()
   
   IF Select( "ARTICULOS" ) == 0
      ::nErrores++
      AAdd( ::aLog, "Lin " + AllTrim( Str( TMP_TRA->ID_LINEA ) ) + ;
                     ": Tabla ARTICULOS no abierta." )
      RETURN NIL
   ENDIF

   dbSelectArea( "ARTICULOS" )
   nOrdArt := IndexOrd()
    OrdSetFocus( "ART_COD" )

    IF dbSeek( cCod )
      lEncontrado := .T.
   ELSE
      dbGoTop()
      DO WHILE !Eof()
         IF !Deleted() .AND. Upper( AllTrim( ARTICULOS->CODIGO ) ) == cCod
            lEncontrado := .T.
            cCod := AllTrim( ARTICULOS->CODIGO )
            EXIT
         ENDIF
         dbSkip()
      ENDDO
   ENDIF

   IF lEncontrado
      nPrecio := ARTICULOS->PRECIO
      nPesoU  := ARTICULOS->PESO_UNI
      nLargo  := ARTICULOS->LARGO
      nAncho  := ARTICULOS->ANCHO
      cDesc   := ARTICULOS->DESCRIP
      cUni    := AllTrim( ARTICULOS->UNIDAD )
      cFam    := AllTrim( ARTICULOS->FAMILIA )
      IF Upper( AllTrim( cFam ) ) == "ACCESORIO" .AND. ;
         Upper( AllTrim( cUdTec ) ) == "ML" .AND. ;
         ( "BANDA" $ cCod .OR. "CINTA" $ cCod )
         cUni := "rollo"
      ENDIF
   ELSE
      ::nErrores++
      cMsgErr := "Lin " + AllTrim( Str( TMP_TRA->ID_LINEA ) ) + ;
                 ": Articulo [" + cCod + "] no existe."
      AAdd( ::aLog, cMsgErr )
      dbSetOrder( nOrdArt )
      dbSelectArea( nAreaArt )
      RETURN NIL
   ENDIF

   dbSetOrder( nOrdArt )

   IF Empty( cUdCons )
      cUdCons := Upper( AllTrim( cUni ) )
   ENDIF

   IF nPesoU > 0 .AND. cUdCons == "UD"
      nPesoTot := nCant * nPesoU
   ENDIF

   dbSelectArea( "TMP_MAT" )
   IF !NetFLock()
      ::nErrores++
      AAdd( ::aLog, "Lin " + AllTrim( Str( TMP_TRA->ID_LINEA ) ) + ;
                     ": No se pudo bloquear TMP_MAT para anadir material [" + cCod + "]." )
      dbSelectArea( nAreaArt )
      RETURN NIL
   ENDIF

   DbAppend()
   IF NetErr()
      dbUnlock()
      ::nErrores++
      AAdd( ::aLog, "Lin " + AllTrim( Str( TMP_TRA->ID_LINEA ) ) + ;
                     ": No se pudo anadir material [" + cCod + "]." )
      dbSelectArea( nAreaArt )
      RETURN NIL
   ENDIF
   
   REPLACE FIELD->NUMERO    WITH TMP_TRA->NUMERO
   REPLACE FIELD->ID_LINEA  WITH TMP_TRA->ID_LINEA
   REPLACE FIELD->L_MANUAL  WITH .F.
   REPLACE FIELD->ORIGEN    WITH "AUTO"
   REPLACE FIELD->FAMILIA   WITH cFam
   REPLACE FIELD->CODIGO    WITH cCod
   REPLACE FIELD->DESCRIP   WITH cDesc
   REPLACE FIELD->UNIDAD    WITH cUdCons
   
   REPLACE FIELD->RENDIM    WITH nCant
   REPLACE FIELD->CANTIDAD  WITH nCant
   REPLACE FIELD->PESO_TOT  WITH nPesoTot
   REPLACE FIELD->PRECIO    WITH nPrecio
   REPLACE FIELD->IMPORTE   WITH 0
   REPLACE FIELD->DETALLE   WITH cDet
   dbCommit()
   dbUnlock()
   
   dbSelectArea( nAreaArt )

RETURN NIL
