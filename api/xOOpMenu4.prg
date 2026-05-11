/*==============================================================================
   OOpMenu_v3.prg
   Reconstrucción profesional basada en estructura original del usuario

   Filosofía:
   - Mantiene TMenu / TMenuPop
   - Mantiene arrays clásicos
   - Barra horizontal manual
   - Popup vertical con AChoice()
   - Sin TWindow()
   - GTWVT Raised Box (sustituir función renderer según build)
   - Métodos separados
   - Restore expandido anti-residuos
==============================================================================*/

#include "hbclass.ch"
#include "inkey.ch"
#include "achoice.ch"

#ifndef AC_ABORT
   #define AC_ABORT  0
   #define AC_SELECT 1
   #define AC_CONT   2
#endif

#define I_TITU  1
#define I_ACTI  2
#define I_HIJO  3
#define I_HELP  4

#define PADWIN  2

STATIC aPopStack := {}

/* Señal de navegación entre popups/barra sin inyectar teclas al buffer.
   Valores: 0 = ninguna, K_LEFT = ir al menú izquierdo, K_RIGHT = ir al derecho */
STATIC s_nNavKey := 0

/*==============================================================================
   MENU PRINCIPAL
==============================================================================*/
CLASS TMenu
   DATA nTop
   DATA aItems
   DATA nAct
   DATA cN
   DATA cS
   DATA cM

   METHOD New( aDef, nTop )
   METHOD Build( aDef )
   METHOD Paint()
   METHOD ShowMsg()
   METHOD Activate()
   METHOD Run() INLINE ::Activate()
   METHOD ProcKey( nKey )
   METHOD OpenPopup()
ENDCLASS

/*==============================================================================
   POPUP
==============================================================================*/
CLASS TMenuPop
   DATA aItems
   DATA nTop
   DATA nLeft
   DATA nBottom
   DATA nRight
   DATA cBack
   DATA nSel

   METHOD New( aDef )
   METHOD Build( aDef )
   METHOD Open( nT, nL )
   METHOD Paint()
   METHOD Run()
   METHOD ExecItem()
   METHOD Close()
   METHOD CalcSize()
ENDCLASS

/*==============================================================================
   TMenu
==============================================================================*/
METHOD New( aDef, nTop ) CLASS TMenu

   ::nTop   := iif( nTop == NIL, 0, nTop )
   ::nAct   := 1
   ::aItems := {}

   /* Paleta Windows clásico:
      cN = Normal      -> texto negro sobre gris claro
      cS = Seleccionado-> blanco brillante sobre azul (highlight Windows)
      cM = Mensaje     -> texto negro sobre gris (barra de estado) */
   ::cN := "N/W"
   ::cS := "W+/B"
   ::cM := "N/W"

   ::Build( aDef )

RETURN Self

/*----------------------------------------------------------------------------*/
METHOD Build( aDef ) CLASS TMenu

   LOCAL nI
   LOCAL cT, bA, aH, cM
   LOCAL nLen

   FOR nI := 1 TO Len(aDef)

      nLen := Len( aDef[nI] )

      cT := aDef[nI,I_TITU]
      bA := iif( nLen >= I_ACTI, aDef[nI,I_ACTI], NIL )
      aH := iif( nLen >= I_HIJO, aDef[nI,I_HIJO], {}  )
      cM := iif( nLen >= I_HELP, aDef[nI,I_HELP], ""  )

      IF ValType(aH) == "A" .AND. !Empty(aH)
         /* IMPORTANTE: generamos el codeblock en una función auxiliar
            para que cada closure capture SU propio oPop y no la variable
            compartida del bucle. */
         bA := _MakePopOpener( TMenuPop():New( aH ) )
      ENDIF

      AAdd( ::aItems, { cT,bA,cM } )

   NEXT

RETURN NIL

/*----------------------------------------------------------------------------*/
METHOD Paint() CLASS TMenu

   LOCAL nI
   LOCAL nC := 2
   LOCAL cOld := SetColor()

   SetColor( ::cN )
   DispOutAt( ::nTop,0, Space(MaxCol()+1) )

   FOR nI := 1 TO Len(::aItems)

      SetColor( iif(nI==::nAct,::cS,::cN) )

      DispOutAt( ::nTop,nC, ;
         " " + ::aItems[nI,1] + " " )

      nC += Len(::aItems[nI,1]) + 4

   NEXT

   SetColor( cOld )

   ::ShowMsg()

RETURN NIL

/*----------------------------------------------------------------------------*/
METHOD ShowMsg() CLASS TMenu

   LOCAL cTxt := ""
   LOCAL cOld := SetColor()

   IF Len(::aItems) > 0
      cTxt := iif( ::aItems[::nAct,3]==NIL,"",::aItems[::nAct,3] )
   ENDIF

   SetColor( ::cM )
   DispOutAt( MaxRow(),0, ;
      PadC(" INFO: "+cTxt, MaxCol()+1 ) )

   SetColor( cOld )

RETURN NIL

/*----------------------------------------------------------------------------*/
METHOD Activate() CLASS TMenu

   LOCAL nK

   ::Paint()

   DO WHILE .T.

      nK := Inkey(0)

      IF nK == K_ESC
         EXIT
      ENDIF

      /* ProcKey ignora con DO CASE cualquier tecla que no reconozca,
         así que pasamos todas sin filtro de rango. */
      ::ProcKey( nK )

   ENDDO

RETURN NIL

/*----------------------------------------------------------------------------*/
METHOD ProcKey( nKey ) CLASS TMenu

   DO CASE

   CASE nKey == K_RIGHT

      ::nAct++
      IF ::nAct > Len(::aItems)
         ::nAct := 1
      ENDIF
      ::Paint()

   CASE nKey == K_LEFT

      ::nAct--
      IF ::nAct < 1
         ::nAct := Len(::aItems)
      ENDIF
      ::Paint()

   CASE nKey == K_ENTER .OR. nKey == K_DOWN

      ::OpenPopup()

   ENDCASE

RETURN NIL

/*----------------------------------------------------------------------------*/
METHOD OpenPopup() CLASS TMenu

   LOCAL bA
   LOCAL nCol

   DO WHILE .T.

      nCol := _MenuCol( ::aItems, ::nAct )
      bA   := ::aItems[::nAct,2]

      IF ValType( bA ) == "B"
         Eval( bA, ::nTop+1, nCol )
      ENDIF

      ::Paint()

      /* Si el popup pidió moverse al menú adyacente, lo hacemos aquí
         sin pasar por el buffer de teclado. */
      DO CASE
      CASE s_nNavKey == K_RIGHT
         s_nNavKey := 0
         ::nAct++
         IF ::nAct > Len(::aItems)
            ::nAct := 1
         ENDIF
         ::Paint()
         LOOP                        /* Abrir el siguiente popup */

      CASE s_nNavKey == K_LEFT
         s_nNavKey := 0
         ::nAct--
         IF ::nAct < 1
            ::nAct := Len(::aItems)
         ENDIF
         ::Paint()
         LOOP

      ENDCASE

      EXIT

   ENDDO

RETURN NIL

/*==============================================================================
   TMenuPop
==============================================================================*/
METHOD New( aDef ) CLASS TMenuPop

   ::aItems := {}
   ::nSel   := 1

   ::Build( aDef )

RETURN Self

/*----------------------------------------------------------------------------*/
METHOD Build( aDef ) CLASS TMenuPop

   LOCAL nI
   LOCAL cT,bA,aH
   LOCAL nLen
   LOCAL lSub

   FOR nI := 1 TO Len(aDef)

      nLen := Len( aDef[nI] )

      cT := aDef[nI,I_TITU]
      bA := iif( nLen >= I_ACTI, aDef[nI,I_ACTI], NIL )
      aH := iif( nLen >= I_HIJO, aDef[nI,I_HIJO], {}  )
      lSub := .F.

      IF ValType(aH) == "A" .AND. !Empty(aH)

         /* IMPORTANTE: codeblock generado en función auxiliar para
            que cada closure capture su propio popup y no la variable
            compartida del bucle. */
         bA   := _MakePopOpener( TMenuPop():New( aH ) )
         lSub := .T.

         /* Aseguramos mínimo 15 pero no truncamos si es mayor */
         cT := PadR( cT, Max( 15, Len(cT) ) ) + " " + Chr(16)

      ELSE

         /* Aseguramos mínimo 17 sin truncar */
         cT := PadR( cT, Max( 17, Len(cT) + 2 ) )

      ENDIF

      /* Item: { cTitulo, bAccion, lEsSubmenu } */
      AAdd( ::aItems, { cT, bA, lSub } )

   NEXT

RETURN NIL

/*----------------------------------------------------------------------------*/
METHOD Open( nT, nL ) CLASS TMenuPop

   ::nTop  := nT
   ::nLeft := nL + 1

   ::CalcSize()

   ::cBack := SaveScreen( ;
      Max(0,::nTop-PADWIN), ;
      Max(0,::nLeft-PADWIN), ;
      Min(MaxRow(),::nBottom+PADWIN), ;
      Min(MaxCol(),::nRight+PADWIN) )

   AAdd( aPopStack, Self )

   ::Paint()

   ::Run()

   ::Close()

RETURN NIL

/*----------------------------------------------------------------------------*/
METHOD CalcSize() CLASS TMenuPop

   LOCAL nI
   LOCAL nW := 0
   LOCAL nH

   FOR nI := 1 TO Len(::aItems)
      nW := Max( nW, Len(::aItems[nI,1]) )
   NEXT

   nH := Len( ::aItems )

   ::nBottom := ::nTop + nH + 1
   ::nRight  := ::nLeft + nW + 2

   /* Si el popup se sale por la derecha, lo movemos a la izquierda */
   IF ::nRight > MaxCol() - PADWIN
      ::nLeft  := Max( 0, MaxCol() - PADWIN - ( nW + 2 ) )
      ::nRight := ::nLeft + nW + 2
   ENDIF

   /* Si se sale por abajo, lo subimos */
   IF ::nBottom > MaxRow() - PADWIN
      ::nTop    := Max( 0, MaxRow() - PADWIN - ( nH + 1 ) )
      ::nBottom := ::nTop + nH + 1
   ENDIF

RETURN NIL

/*----------------------------------------------------------------------------*/
METHOD Paint() CLASS TMenuPop

   LOCAL cOld := SetColor()

   /* 1. Rellenamos el área completa del popup con color opaco.
      Esto blinda el fondo y evita que se vea el contenido detrás
      (popups padres, contenido de la pantalla, etc.). */
   SetColor( "N/W" )
   Scroll( ::nTop, ::nLeft, ::nBottom, ::nRight, 0 )

   /* 2. Dibujamos el marco "raised" con GDI encima. */
   wvt_DrawBoxRaised( ::nTop, ::nLeft, ::nBottom, ::nRight )

   SetColor( cOld )

RETURN NIL

/*----------------------------------------------------------------------------*/
METHOD Run() CLASS TMenuPop

   LOCAL aList := {}
   LOCAL nI
   LOCAL lSub

   FOR nI := 1 TO Len(::aItems)
      AAdd( aList, ::aItems[nI,1] )
   NEXT

   DO WHILE .T.

      /* Limpiamos la señal antes de entrar a AChoice */
      s_nNavKey := 0

      /* Colores popup estilo Windows:
         Normal    : negro sobre gris claro
         Selección : blanco sobre azul (highlight clásico) */
      SetColor( "N/W,W+/B" )

      ::nSel := AChoice( ;
         ::nTop+1, ;
         ::nLeft+1, ;
         ::nBottom-1, ;
         ::nRight-1, ;
         aList, ;
         .T., ;
         "PopHnd", ;
         ::nSel )

      /* Si el usuario pulsó flecha horizontal, salimos del popup.
         La señal s_nNavKey queda puesta para que TMenu:Activate la vea. */
      IF s_nNavKey == K_LEFT .OR. s_nNavKey == K_RIGHT
         EXIT
      ENDIF

      /* AChoice abortado sin navegación = ESC => cerrar popup */
      IF ::nSel == 0
         EXIT
      ENDIF

      lSub := ::ExecItem()

      _RedrawStack()

      /* Si el item ejecutado NO era un submenú (acción terminal),
         cerramos este popup también. Comportamiento tipo Windows. */
      IF !lSub
         EXIT
      ENDIF

   ENDDO

RETURN NIL

/*----------------------------------------------------------------------------*/
METHOD ExecItem() CLASS TMenuPop

   LOCAL bA
   LOCAL lSub
   LOCAL nRT
   LOCAL nCL

   bA   := ::aItems[::nSel,2]
   lSub := ::aItems[::nSel,3]

   IF ValType(bA) == "B"

      nRT := ::nTop + ::nSel - 1
      nCL := ::nRight - 1

      Eval( bA, nRT, nCL )

   ENDIF

RETURN lSub

/*----------------------------------------------------------------------------*/
METHOD Close() CLASS TMenuPop

   RestScreen( ;
      Max(0,::nTop-PADWIN), ;
      Max(0,::nLeft-PADWIN), ;
      Min(MaxRow(),::nBottom+PADWIN), ;
      Min(MaxCol(),::nRight+PADWIN), ;
      ::cBack )

   /* Solo reducimos si este popup está en la cima del stack (LIFO) */
   IF !Empty( aPopStack ) .AND. ATail( aPopStack ) == Self
      ASize( aPopStack, Len(aPopStack)-1 )
   ENDIF

RETURN NIL

/*==============================================================================
   AUXILIARES
==============================================================================*/
FUNCTION PopHnd( nMode )

   LOCAL nK := LastKey()

   IF nMode == 3

      IF nK == K_RIGHT
         s_nNavKey := K_RIGHT
         RETURN 0                    /* Abortar AChoice */
      ENDIF

      IF nK == K_LEFT
         s_nNavKey := K_LEFT
         RETURN 0
      ENDIF

      IF nK == K_ESC
         s_nNavKey := 0
         RETURN 0
      ENDIF

      IF nK == K_ENTER
         RETURN 1                    /* Selección */
      ENDIF

   ENDIF

RETURN 2                             /* Continuar AChoice normalmente */

/*----------------------------------------------------------------------------*/
/* _MakePopOpener
   Crea un codeblock que abre el popup recibido como parámetro.
   La clave está en que 'oPop' aquí es el PARÁMETRO formal de esta función,
   así que cada invocación genera un ámbito nuevo y el codeblock captura
   SU propia referencia (no una variable compartida de un bucle externo).
   Arregla el bug de closures en bucles. */
STATIC FUNCTION _MakePopOpener( oPop )
RETURN {|nR,nC| oPop:Open(nR,nC) }

/*----------------------------------------------------------------------------*/
STATIC FUNCTION _RedrawStack()

   LOCAL nI

   FOR nI := 1 TO Len(aPopStack)
      aPopStack[nI]:Paint()
   NEXT

RETURN NIL

/*----------------------------------------------------------------------------*/
STATIC FUNCTION _MenuCol( aItems, nPos )

   LOCAL nI
   LOCAL nC := 2      // Debe coincidir con el nC inicial de TMenu:Paint

   FOR nI := 1 TO nPos-1
      nC += Len(aItems[nI,1]) + 4
   NEXT

RETURN nC

/*----------------------------------------------------------------------------*/
/* wvt_DrawBoxRaised: se usa la función NATIVA de GTWVG (no GTWVT).
   Requiere enlazar gtwvg.hbc además de gtwvt.
   Ejemplo de compilación:
      hbmk2 Menu.prg OOpMenu4.prg UTILIDAD.prg -gtwvt gtwvg.hbc

   Fallback en modo texto puro (si alguna vez se necesita sin GUI):

FUNCTION wvt_DrawBoxRaised( nT, nL, nB, nR )
   Scroll( nT, nL, nB, nR, 0 )
   DispBox( nT, nL, nB, nR, ;
      Chr(218)+Chr(196)+Chr(191)+Chr(179)+ ;
      Chr(217)+Chr(196)+Chr(192)+Chr(179)+" " )
RETURN NIL
*/