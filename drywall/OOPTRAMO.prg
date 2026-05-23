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
       METHOD AddMat( cFam, cCod, nCant, cDet, cUdTec )
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
   LOCAL cTipo
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

      IF !lTodo
         EXIT
      ENDIF

      dbSkip()
   ENDDO
   
   dbSelectArea( nArea )

RETURN NIL


STATIC FUNCTION _OopProyectoActual()

   LOCAL nArea := Select()
   LOCAL cProyecto := ""

   IF Select( "TMP_CAB" ) > 0
      dbSelectArea( "TMP_CAB" )
      dbGoTop()
      DO WHILE !Eof()
         IF !Deleted()
            cProyecto := AllTrim( FIELD->NUMERO )
            EXIT
         ENDIF
         dbSkip()
      ENDDO
   ENDIF

   IF nArea > 0
      dbSelectArea( nArea )
   ENDIF

RETURN cProyecto

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
   dbSetOrder( 2 )
   
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

METHOD Calc_Tabique() CLASS OOPTRAMO
   LOCAL nLargo   := FIELD->LARGO
   LOCAL nAlto    := FIELD->ALTO
   LOCAL nMod     := FIELD->MODUL
   LOCAL nArea    := nLargo * nAlto
   LOCAL nCapas   := FIELD->PLAC_CARA
   LOCAL nMont, nMetCan, nM2Total
   LOCAL nCaras   := FIELD->CARAS
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
   
   IF FIELD->L_BANDA
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
   ::AddMat( "CINTA", "CINTA_PAP",  nM2Total * K_CINTA_M2, "Cinta Papel", "ML" )
   
   IF FIELD->L_AISLANT
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

   ::DesgloseAnclaje( FIELD->ID_ANCLAJE, nArea, If( nSepPrim > 0, nSepPrim, 1.00 ) )
   ::AddMat( "PASTA",    "PASTA_JUNT", nArea * nCapas * K_PASTA_M2, "Juntas Techo", "KG" )
   ::AddMat( "CINTA",    "CINTA_PAP",  nArea * nCapas * K_CINTA_M2, "Cinta Techo", "ML" )
   
   IF FIELD->L_AISLANT
      ::AddMat( "AISLAN", FIELD->ID_AISLANT, nArea * K_DESP_PLA, "Aislamiento Plenum", "M2" )
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
      ::AddMat( "PASTA", FIELD->ID_PER_VER, nArea * K_PASTA_M2, "Pasta Agarre", "KG" )
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
   
   IF FIELD->L_AISLANT
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

   IF FIELD->L_AISLANT
      ::AddMat( "AISLAN", FIELD->ID_AISLANT, nArea * K_DESP_PLA, "Aislamiento", "M2" )
   ENDIF

RETURN NIL


METHOD DesgloseAnclaje( cIdAnc, nArea, nSepPrim ) CLASS OOPTRAMO
   
   LOCAL nPuntos
   
   IF _OptionalCode( cIdAnc ) .OR. nSepPrim <= 0
      RETURN NIL
   ENDIF

   nPuntos := nArea / ( nSepPrim * 1.00 )
   
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
   dbSetOrder( 1 )

   IF dbSeek( cCod )
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
   IF !FLock()
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
