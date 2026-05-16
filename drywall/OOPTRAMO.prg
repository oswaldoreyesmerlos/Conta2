#include "OOp.ch"
#include "hbclass.ch"
 
// Constantes de Rendimiento
#define K_DESP_PLA   1.05
#define K_DESP_PER   1.10
#define K_TORN_M2    15  
#define K_TORN_MM    4   
#define K_PASTA_M2   0.40
#define K_CINTA_M2   1.45

CLASS OOPTRAMO
   
   DATA nErrores  INIT 0
   DATA aLog      INIT {}  // <--- Nuevo: Historial de incidencias

   METHOD New()
   METHOD Procesar( lTodo )
   METHOD MostrarErrores() // <--- Nuevo: Reporte final
   
   PROTECTED:
      METHOD LimpiarLinea( nIdLin )
      METHOD Calc_Tabique()
      METHOD Calc_Techo()
       METHOD Calc_Trasdos()
       METHOD Calc_Generico()
       METHOD AddMat( cFam, cCod, nCant, cDet )
       METHOD DesgloseAnclaje( cIdAnc, nArea, nSepPrim )

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
   
   // Limpiamos errores previos al iniciar proceso
   ::nErrores := 0
   ::aLog     := {}
   
   IF lTodo
      dbSelectArea( "TMP_TRA" )
      dbGoTop()
   ENDIF

   dbSelectArea( "TMP_TRA" )
   
   WHILE !Eof()
      
      ::LimpiarLinea( FIELD->ID_LINEA )

      DO CASE
         CASE AllTrim( FIELD->TIPO_OBRA ) == "TABIQUE"
            ::Calc_Tabique()
            
         CASE AllTrim( FIELD->TIPO_OBRA ) == "TECHO"
            ::Calc_Techo()
            
      CASE "TRAS" $ AllTrim( FIELD->TIPO_OBRA )
         ::Calc_Trasdos()
      CASE AllTrim( FIELD->TIPO_OBRA ) == "GENERICO"
         ::Calc_Generico()
      ENDCASE

      dbSkip()
   ENDDO
   
   // <--- PUNTO CLAVE: Si hubo errores, avisamos al final
   IF ::nErrores > 0
      ::MostrarErrores()
   ENDIF

   dbSelectArea( nArea )

RETURN NIL

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
   
   LOCAL nOrdAnt := IndexOrd()
   
   dbSelectArea( "TMP_MAT" )
   dbSetOrder( 1 ) 
   
   IF dbSeek( TMP_TRA->NUMERO + Str( nIdLin, 4 ) )
      WHILE !Eof() .AND. TMP_MAT->ID_LINEA == nIdLin
         IF !FIELD->L_MANUAL
            dbDelete()
         ENDIF
         dbSkip()
      ENDDO
   ENDIF
   
   dbSetOrder( nOrdAnt )
   dbSelectArea( "TMP_TRA" )

RETURN NIL

METHOD Calc_Tabique() CLASS OOPTRAMO
   LOCAL nLargo   := FIELD->LARGO
   LOCAL nAlto    := FIELD->ALTO
   LOCAL nMod     := FIELD->MODUL
   LOCAL nArea    := nLargo * nAlto
   LOCAL nCapas   := FIELD->PLAC_CARA
   LOCAL nMetMont, nMetCan, nM2Total

   nMetMont := ( ( nLargo / nMod ) + 1 ) * nAlto
   nMetCan  := nLargo * 2
   nM2Total := nArea * 2 
   
   ::AddMat( "PERFIL", FIELD->ID_PER_VER, nMetMont * K_DESP_PER, "Estructura Vertical" )
   ::AddMat( "PERFIL", FIELD->ID_PER_HOR, nMetCan  * K_DESP_PER, "Guia Suelo/Techo" )
   
   IF FIELD->L_BANDA
      ::AddMat( "ACCESORIO", "BANDA_ACUS", nMetCan, "Banda Estanqueidad" )
   ENDIF

   ::AddMat( "PLACA", FIELD->ID_PLACA_A, nArea * K_DESP_PLA, "Revestimiento Cara A" )

   IF !Empty( FIELD->ID_PLACA_B )
      ::AddMat( "PLACA", FIELD->ID_PLACA_B, nArea * K_DESP_PLA, "Revestimiento Cara B" )
   ENDIF
   
   ::AddMat( "TORNILLO", "TORN_PM_25", nM2Total * K_TORN_M2, "Fijacion 1a Capa" )
   
   IF nCapas > 1
      ::AddMat( "TORNILLO", "TORN_PM_35", nM2Total * K_TORN_M2, "Fijacion 2a Capa" )
      ::AddMat( "PLACA", FIELD->ID_PLACA_A, nArea * K_DESP_PLA, "2a Capa Cara A" )
      ::AddMat( "PLACA", FIELD->ID_PLACA_B, nArea * K_DESP_PLA, "2a Capa Cara B" )
   ENDIF
   
   ::AddMat( "PASTA", "PASTA_JUNT", nM2Total * K_PASTA_M2, "Tratamiento Juntas" )
   ::AddMat( "CINTA", "CINTA_PAP",  nM2Total * K_CINTA_M2, "Cinta Papel" )
   
   IF FIELD->L_AISLANT
      ::AddMat( "AISLAN", FIELD->ID_AISLANT, nArea * K_DESP_PLA, "Lana Mineral Interior" )
   ENDIF
RETURN NIL

METHOD Calc_Techo() CLASS OOPTRAMO
   LOCAL nLargo   := FIELD->LARGO
   LOCAL nAlto    := FIELD->ALTO 
   LOCAL nArea    := nLargo * nAlto
   LOCAL nPerim   := ( nLargo + nAlto ) * 2
   LOCAL nMod     := FIELD->MODUL    
   LOCAL nSepPrim := FIELD->SEP_PRIM 
   LOCAL lPri     := !Empty( FIELD->ID_PER_HOR )
   LOCAL nMetSec, nMetPri, nCruces
   
   IF nMod == 0; nMod := 0.50; ENDIF
   IF nSepPrim == 0; nSepPrim := 1.00; ENDIF

   nMetSec := nArea / nMod

   ::AddMat( "PERFIL", FIELD->ID_PER_VER, nMetSec * K_DESP_PER, "Perfil Secundario" )

   IF lPri
       nMetPri := nArea / nSepPrim
       nCruces := nArea / ( nMod * nSepPrim )
       ::AddMat( "PERFIL", FIELD->ID_PER_HOR, nMetPri * K_DESP_PER, "Perfil Primario" )
       ::AddMat( "ACCESORIO", "PIEZA_CRUCE", nCruces, "Union Prim-Sec" )
   ENDIF

   ::AddMat( "PERFIL", FIELD->ID_PER_PER, nPerim  * K_DESP_PER, "Angular Perimetral" )
   
   ::AddMat( "PLACA", FIELD->ID_PLACA_A, nArea * K_DESP_PLA, "Techo Continuo" )
   ::DesgloseAnclaje( FIELD->ID_ANCLAJE, nArea, nSepPrim )
   ::AddMat( "TORNILLO", "TORN_PM_25", nArea * K_TORN_M2, "Fijacion Placa" )
   ::AddMat( "PASTA",    "PASTA_JUNT", nArea * K_PASTA_M2, "Juntas Techo" )
   ::AddMat( "CINTA",    "CINTA_PAP",  nArea * K_CINTA_M2, "Cinta Techo" )
   
   IF FIELD->L_AISLANT
      ::AddMat( "AISLAN", FIELD->ID_AISLANT, nArea * K_DESP_PLA, "Aislamiento Plenum" )
   ENDIF
RETURN NIL

METHOD Calc_Trasdos() CLASS OOPTRAMO

   LOCAL nLargo := FIELD->LARGO
   LOCAL nAlto  := FIELD->ALTO
   LOCAL nArea  := nLargo * nAlto
   LOCAL nMod   := FIELD->MODUL
   
   LOCAL nMetVert
   LOCAL nMetHor
   
   nMetVert := ( ( nLargo / nMod ) + 1 ) * nAlto
   nMetHor  := nLargo * 2
   
    ::AddMat( "PERFIL", FIELD->ID_PER_VER, nMetVert * K_DESP_PER, "Maestra/Montante" )

    IF ! "DIR" $ FIELD->TIPO_OBRA
       ::AddMat( "PERFIL", FIELD->ID_PER_HOR, nMetHor * K_DESP_PER, "Canal Suelo/Techo" )
    ENDIF
   
   ::AddMat( "PLACA", FIELD->ID_PLACA_A, nArea * K_DESP_PLA, "Trasdosado" )
   ::AddMat( "TORNILLO", "TORN_PM_25", nArea * K_TORN_M2, "Fijacion" )
   ::AddMat( "PASTA", "PASTA_JUNT", nArea * K_PASTA_M2, "Juntas" )
   
   IF FIELD->L_AISLANT
      ::AddMat( "AISLAN", FIELD->ID_AISLANT, nArea * K_DESP_PLA, "Aislamiento" )
   ENDIF

RETURN NIL

METHOD Calc_Generico() CLASS OOPTRAMO

   LOCAL nLargo := FIELD->LARGO
   LOCAL nAlto  := FIELD->ALTO
   LOCAL nArea  := nLargo * nAlto
   LOCAL cMat   := FIELD->ID_PLACA_A

   IF !Empty( cMat )
      ::AddMat( "GENERICO", cMat, nArea * K_DESP_PLA, "Material base" )
   ENDIF

   IF FIELD->L_AISLANT
      ::AddMat( "AISLAN", FIELD->ID_AISLANT, nArea * K_DESP_PLA, "Aislamiento" )
   ENDIF

RETURN NIL


METHOD DesgloseAnclaje( cIdAnc, nArea, nSepPrim ) CLASS OOPTRAMO
   
   LOCAL nPuntos := nArea / ( nSepPrim * 1.00 )
   
   IF Empty( cIdAnc ); RETURN NIL; ENDIF
   
   DO CASE
      CASE "VARILLA" $ Upper( cIdAnc )
         ::AddMat( "ANCLAJE", "TACO_LATON", nPuntos, "Taco Expansion" )
         ::AddMat( "ANCLAJE", "VARILLA_M6", nPuntos * 0.50, "Varilla Roscada (Media)" )
         ::AddMat( "ANCLAJE", "TUERCA_M6",  nPuntos * 2, "Tuercas Nivelacion" )
         ::AddMat( "ANCLAJE", "PIVOT_TC60", nPuntos, "Cuelgue Perfil" )
         
      CASE "NONIUS" $ Upper( cIdAnc )
         ::AddMat( "ANCLAJE", "NONIUS_SUP", nPuntos, "Parte Superior" )
         ::AddMat( "ANCLAJE", "NONIUS_INF", nPuntos, "Parte Inferior" )
         ::AddMat( "ANCLAJE", "NONIUS_PAS", nPuntos * 2, "Pasadores" )
         
      CASE "DIRECT" $ Upper( cIdAnc )
         ::AddMat( "ANCLAJE", "HORQ_TC60",  nPuntos, "Horquilla Directa" )
         ::AddMat( "ANCLAJE", "TORN_MM_LN", nPuntos * 2, "Tornillo Fijacion" )
         
      OTHERWISE
         ::AddMat( "ANCLAJE", cIdAnc, nPuntos, "Sistema Cuelgue" )
   ENDCASE

RETURN NIL

// ----------------------------------------------------------------------------
// HERRAMIENTA CENTRAL: Añadir Material (CON VALIDACION DE ERRORES)
// ----------------------------------------------------------------------------
METHOD AddMat( cFam, cCod, nCant, cDet ) CLASS OOPTRAMO

   LOCAL nPrecio := 0
   LOCAL nPesoU  := 0
   LOCAL cDesc   := ""
   LOCAL cUni    := ""
   LOCAL nAreaArt
   LOCAL cMsgErr := ""
   
   IF Empty( cCod )
      RETURN NIL
   ENDIF
   
   nAreaArt := Select()
   
    IF Select( "ARTICULOS" ) > 0
       dbSelectArea( "ARTICULOS" )
       dbSetOrder( 1 )
       
       IF dbSeek( Upper( AllTrim( cCod ) ) )
          nPrecio := ARTICULOS->PRECIO
          nPesoU  := ARTICULOS->PESO_UNI
          cDesc   := ARTICULOS->DESCRIP
          cUni    := ARTICULOS->UNIDAD
          cFam    := ARTICULOS->FAMILIA 
       ELSE
          ::nErrores++
          cDesc   := "ERROR: ART. NO EXISTE"
          cMsgErr := "Lin " + AllTrim(Str(TMP_TRA->ID_LINEA)) + ": Articulo [" + cCod + "] no existe."
          AAdd( ::aLog, cMsgErr )
       ENDIF
    ELSE
        Alert("Error Critico: Tabla ARTICULOS no abierta")
        RETURN NIL
    ENDIF
   
   dbSelectArea( "TMP_MAT" )
   APPEND BLANK
   
   REPLACE FIELD->NUMERO    WITH TMP_TRA->NUMERO
   REPLACE FIELD->ID_LINEA  WITH TMP_TRA->ID_LINEA
    REPLACE FIELD->L_MANUAL  WITH .F.
    REPLACE FIELD->ORIGEN    WITH "AUTO"
    
    REPLACE FIELD->FAMILIA   WITH cFam
   REPLACE FIELD->CODIGO    WITH cCod
   REPLACE FIELD->DESCRIP   WITH cDesc
   REPLACE FIELD->UNIDAD    WITH cUni
   
   REPLACE FIELD->CANTIDAD  WITH nCant
   REPLACE FIELD->PESO_TOT  WITH ( nCant * nPesoU )
   REPLACE FIELD->PRECIO    WITH nPrecio
   REPLACE FIELD->IMPORTE   WITH ( nCant * nPrecio )
   REPLACE FIELD->DETALLE   WITH cDet
   
   dbSelectArea( nAreaArt )

RETURN NIL