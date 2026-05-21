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
   LOCAL nMont, nMetCan, nM2Total
   LOCAL nCapa

   IF nMod == 0; nMod := 0.60; ENDIF

   nMont   := Ceiling( ( nLargo / nMod ) + 1 )
   nMetCan  := nLargo * 2
   nM2Total := nArea * 2 * Max( nCapas, 1 )
   
   ::AddMat( "PERFIL", FIELD->ID_PER_VER, nMont, "Montantes verticales", "UD" )
   ::AddMat( "PERFIL", FIELD->ID_PER_HOR, nMetCan * K_DESP_PER, "Guia Suelo/Techo", "ML" )
   
   IF FIELD->L_BANDA
      ::AddMat( "ACCESORIO", "BANDA_ACUS", nMetCan, "Banda Estanqueidad", "ML" )
   ENDIF

   FOR nCapa := 1 TO Max( nCapas, 1 )
      ::AddMat( "PLACA", FIELD->ID_PLACA_A, nArea * K_DESP_PLA, ;
         If( nCapa == 1, "Revestimiento Cara A", AllTrim( Str( nCapa ) ) + "a Capa Cara A" ), "M2" )

      IF !Empty( FIELD->ID_PLACA_B )
         ::AddMat( "PLACA", FIELD->ID_PLACA_B, nArea * K_DESP_PLA, ;
            If( nCapa == 1, "Revestimiento Cara B", AllTrim( Str( nCapa ) ) + "a Capa Cara B" ), "M2" )
      ENDIF

      ::AddMat( "TORNILLO", If( nCapa == 1, "TORN_PM_25", "TORN_PM_35" ), ;
         nArea * 2 * K_TORN_M2, "Fijacion " + AllTrim( Str( nCapa ) ) + "a Capa", "UD" )
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
   
   LOCAL nMont := 0
   LOCAL nMetHor  := 0
   
   IF "DIR" $ FIELD->TIPO_OBRA
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
      ::AddMat( "TORNILLO", If( nCapa == 1, "TORN_PM_25", "TORN_PM_35" ), ;
         nArea * K_TORN_M2, "Fijacion " + AllTrim( Str( nCapa ) ) + "a Capa", "UD" )
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
   
   LOCAL nPuntos := nArea / ( nSepPrim * 1.00 )
   
   IF Empty( cIdAnc ); RETURN NIL; ENDIF
   
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
   LOCAL cMsgErr := ""
   LOCAL nCompra := 0
   LOCAL nPesoTot := 0

   DEFAULT cUdTec TO ""
   
   IF _OptionalCode( cCod )
      RETURN NIL
   ENDIF
   
   nAreaArt := Select()
   
    IF Select( "ARTICULOS" ) > 0
       dbSelectArea( "ARTICULOS" )
       dbSetOrder( 1 )
       
       IF dbSeek( Upper( AllTrim( cCod ) ) )
          nPrecio := ARTICULOS->PRECIO
          nPesoU  := ARTICULOS->PESO_UNI
          nLargo  := ARTICULOS->LARGO
          nAncho  := ARTICULOS->ANCHO
          cDesc   := ARTICULOS->DESCRIP
          cUni    := ARTICULOS->UNIDAD
          cFam    := ARTICULOS->FAMILIA 
          IF Upper( AllTrim( cFam ) ) == "ACCESORIO" .AND. ;
             Upper( AllTrim( cUdTec ) ) == "ML" .AND. ;
             ( "BANDA" $ Upper( AllTrim( cCod ) ) .OR. "CINTA" $ Upper( AllTrim( cCod ) ) )
             cUni := "rollo"
          ENDIF
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

   nCompra := _CantidadCompra( cFam, cCod, cUni, nCant, cUdTec, nLargo, nAncho, nPesoU )
   nPesoTot := If( nPesoU > 0, nCompra * nPesoU, 0 )
   
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
   
   REPLACE FIELD->RENDIM    WITH nCant
   REPLACE FIELD->CANTIDAD  WITH nCompra
   REPLACE FIELD->PESO_TOT  WITH nPesoTot
   REPLACE FIELD->PRECIO    WITH nPrecio
   REPLACE FIELD->IMPORTE   WITH ( nCompra * nPrecio )
   REPLACE FIELD->DETALLE   WITH cDet
   dbCommit()
   
   dbSelectArea( nAreaArt )

RETURN NIL


STATIC FUNCTION _OptionalCode( cCod )

RETURN Empty( AllTrim( cCod ) ) .OR. AllTrim( cCod ) == "0"


STATIC FUNCTION _CantidadCompra( cFam, cCod, cUni, nConsumo, cUdTec, nLargo, nAncho, nPesoU )

    LOCAL cF := Upper( AllTrim( hb_CStr( cFam ) ) )
    LOCAL cU := Upper( AllTrim( hb_CStr( cUni ) ) )
    LOCAL cT := Upper( AllTrim( hb_CStr( cUdTec ) ) )
    LOCAL cC := Upper( AllTrim( hb_CStr( cCod ) ) )
    LOCAL nContenido := 0
    LOCAL nAreaPieza := 0

    DEFAULT nConsumo TO 0
    DEFAULT nLargo   TO 0
    DEFAULT nAncho   TO 0
    DEFAULT nPesoU   TO 0

    IF nConsumo <= 0
        RETURN 0
    ENDIF

    DO CASE
    CASE cF == "TORNILLO" .AND. ( cT == "UD" .OR. cU == "CAJA" )
        nContenido := 1000
        RETURN _RoundUp( nConsumo / nContenido )

    CASE cT == "UD"
        RETURN _RoundUp( nConsumo )

    CASE cF == "PERFIL" .AND. cT == "ML"
        nContenido := If( nLargo > 0, nLargo / 1000, 3 )
        RETURN _RoundUp( nConsumo / nContenido )

    CASE cF == "PLACA" .AND. cT == "M2"
        nAreaPieza := ( nLargo / 1000 ) * ( nAncho / 1000 )
        IF nAreaPieza <= 0
            nAreaPieza := 3.00
        ENDIF
        RETURN _RoundUp( nConsumo / nAreaPieza )

    CASE cF == "PASTA" .AND. cT == "KG"
        nContenido := If( nPesoU > 0, nPesoU, 20 )
        RETURN _RoundUp( nConsumo / nContenido )

    CASE cF == "CINTA" .AND. cT == "ML"
        nContenido := If( nLargo > 0, nLargo / 1000, 0 )
        IF nContenido <= 0
            nContenido := If( "50" $ cC, 50, 90 )
        ENDIF
        RETURN _RoundUp( nConsumo / nContenido )

    CASE cF == "ACCESORIO" .AND. cT == "ML" .AND. ;
         ( "BANDA" $ cC .OR. "CINTA" $ cC )
        nContenido := If( nLargo > 0, nLargo / 1000, 30 )
        RETURN _RoundUp( nConsumo / nContenido )

    OTHERWISE
        RETURN nConsumo
    ENDCASE

RETURN nConsumo


STATIC FUNCTION _RoundUp( nValue )

    LOCAL nInt

    IF nValue <= 0
        RETURN 0
    ENDIF

    nInt := Int( nValue )
    IF nValue > nInt
        nInt++
    ENDIF

RETURN nInt
