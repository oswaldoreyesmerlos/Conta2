/*
 * ARCHIVO  : API\TMenu.prg
 * PROPOSITO: Menu horizontal tipo Windows con popups verticales en cascada.
 *
 * BASADO EN: OOpMenu_v3.prg (estructura y logica de navegacion intactas)
 *
 * ADAPTACIONES AL FRAMEWORK (cambios minimos)
 * -------------------------------------------
 *   - #include "OOp.ch" en lugar de hbclass + inkey + achoice
 *   - SaveScreen/RestScreen -> GfxSave/GfxRestore
 *   - wvt_DrawBoxRaised    -> GfxRaised
 *   - SetColor/DispOutAt   -> GfxClear/GfxText
 *   - Scroll               -> GfxClear
 *   - MaxRow/MaxCol        -> GfxMaxRow/GfxMaxCol
 *   - AChoice + PopHnd     -> bucle Inkey propio
 *   - Separadores pintados como linea Chr(196)
 *
 * La variable estatica s_nNavKey y el mecanismo de senal global
 * se conservan exactamente como en el original.
 */

#include "OOp.ch"

#define I_TITU  1
#define I_ACTI  2
#define I_HIJO  3
#define I_HELP  4

#define PADWIN  2

STATIC s_nNavKey := 0
STATIC aPopStack := {}


// ============================================================================
// CLASE TMenu
// ============================================================================
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
    METHOD Run()    INLINE ::Activate()
    METHOD ProcKey( nKey )
    METHOD OpenPopup()
    METHOD SetItems( aDef )

ENDCLASS


METHOD New( aDef, nTop ) CLASS TMenu

    ::nTop   := If( nTop == NIL, 0, nTop )
    ::nAct   := 1
    ::aItems := {}
    ::cN     := CLR_MENU
    ::cS     := CLR_MENU_SEL
    ::cM     := CLR_MENU_MSG

    ::Build( aDef )

RETURN Self


METHOD Build( aDef ) CLASS TMenu

    LOCAL nI
    LOCAL cT, bA, aH, cM
    LOCAL nLen

    FOR nI := 1 TO Len( aDef )

        nLen := Len( aDef[nI] )
        cT   := aDef[nI, I_TITU]
        bA   := If( nLen >= I_ACTI, aDef[nI, I_ACTI], NIL )
        aH   := If( nLen >= I_HIJO, aDef[nI, I_HIJO], {}  )
        cM   := If( nLen >= I_HELP, aDef[nI, I_HELP], ""  )

        IF ValType( aH ) == "A" .AND. !Empty( aH )
            bA := _MakePopOpener( TMenuPop():New( aH ) )
        ENDIF

        AAdd( ::aItems, { cT, bA, cM } )

    NEXT

RETURN NIL


METHOD Paint() CLASS TMenu

    LOCAL nI
    LOCAL nC   := 2
    LOCAL cCol

    GfxLock()
    ::cN := CLR_MENU
    ::cS := CLR_MENU_SEL
    ::cM := CLR_MENU_MSG

    GfxClear( ::nTop, 0, ::nTop, GfxMaxCol(), ::cN )

    FOR nI := 1 TO Len( ::aItems )
        cCol := If( nI == ::nAct, ::cS, ::cN )
        GfxText( ::nTop, nC, " " + ::aItems[nI, 1] + " ", cCol )
        nC += Len( ::aItems[nI, 1] ) + 4
    NEXT

    GfxUnlock()
    ::ShowMsg()

RETURN NIL


METHOD ShowMsg() CLASS TMenu

    LOCAL cTxt := ""

    IF Len( ::aItems ) > 0
        cTxt := If( ::aItems[::nAct, 3] == NIL, "", ::aItems[::nAct, 3] )
    ENDIF

    GfxClear( GfxMaxRow(), 0, GfxMaxRow(), GfxMaxCol(), ::cM )
    GfxText( GfxMaxRow(), 0, PadR( " " + cTxt, GfxMaxCol() + 1 ), ::cM )

RETURN NIL


METHOD Activate() CLASS TMenu

    LOCAL nK

    ::Paint()

    DO WHILE .T.

        nK := Inkey( 0 )

        IF nK == K_ESC
            EXIT
        ENDIF

        ::ProcKey( nK )

    ENDDO

RETURN NIL


METHOD ProcKey( nKey ) CLASS TMenu

    LOCAL nI, nC, nML, nMR

    DO CASE

    CASE nKey == K_RIGHT
        ::nAct++
        IF ::nAct > Len( ::aItems )
            ::nAct := 1
        ENDIF
        ::Paint()

    CASE nKey == K_LEFT
        ::nAct--
        IF ::nAct < 1
            ::nAct := Len( ::aItems )
        ENDIF
        ::Paint()

    CASE nKey == K_ENTER .OR. nKey == K_DOWN
        ::OpenPopup()

    CASE nKey == K_LBUTTONDOWN
         nMR := MRow()
         nML := MCol()
         // Verificar si el click es en la fila del menu
         IF nMR == ::nTop
             nC := 2
             FOR nI := 1 TO Len( ::aItems )
                 IF nML >= nC .AND. nML <= nC + Len( ::aItems[nI, 1] ) + 2
                     ::nAct := nI
                     ::Paint()
                     ::OpenPopup()
                     EXIT
                 ENDIF
                 nC += Len( ::aItems[nI, 1] ) + 4
             NEXT
         ENDIF

    ENDCASE

RETURN NIL


METHOD SetItems( aDef ) CLASS TMenu
    ::Build( aDef )
    ::Paint()
RETURN Self


METHOD OpenPopup() CLASS TMenu

    LOCAL bA
    LOCAL nCol

    DO WHILE .T.

        nCol := _MenuCol( ::aItems, ::nAct )
        bA   := ::aItems[::nAct, 2]

        IF ValType( bA ) == "B"
            Eval( bA, ::nTop + 1, nCol )
        ENDIF

        ::Paint()

        DO CASE
        CASE s_nNavKey == K_RIGHT
            s_nNavKey := 0
            ::nAct++
            IF ::nAct > Len( ::aItems )
                ::nAct := 1
            ENDIF
            ::Paint()
            LOOP

        CASE s_nNavKey == K_LEFT
            s_nNavKey := 0
            ::nAct--
            IF ::nAct < 1
                ::nAct := Len( ::aItems )
            ENDIF
            ::Paint()
            LOOP
        ENDCASE

        EXIT

    ENDDO

RETURN NIL


// ============================================================================
// CLASE TMenuPop
// ============================================================================
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
    METHOD CalcSize()
    METHOD Paint()
    METHOD Run()
    METHOD ExecItem()
    METHOD Close()

ENDCLASS


METHOD New( aDef ) CLASS TMenuPop

    ::aItems := {}
    ::nSel   := 1

    ::Build( aDef )

RETURN Self


METHOD Build( aDef ) CLASS TMenuPop

    LOCAL nI
    LOCAL cT, bA, aH
    LOCAL nLen
    LOCAL lSub

    FOR nI := 1 TO Len( aDef )

        nLen := Len( aDef[nI] )
        cT   := aDef[nI, I_TITU]
        bA   := If( nLen >= I_ACTI, aDef[nI, I_ACTI], NIL )
        aH   := If( nLen >= I_HIJO, aDef[nI, I_HIJO], {}  )
        lSub := .F.

        IF ValType( aH ) == "A" .AND. !Empty( aH )
            bA   := _MakePopOpener( TMenuPop():New( aH ) )
            lSub := .T.
            cT   := PadR( cT, Max( 15, Len( cT ) ) ) + " " + Chr( 16 )
        ELSE
            cT   := PadR( cT, Max( 17, Len( cT ) + 2 ) )
        ENDIF

        AAdd( ::aItems, { cT, bA, lSub } )

    NEXT

RETURN NIL


METHOD Open( nT, nL ) CLASS TMenuPop

    ::nTop  := nT
    ::nLeft := nL + 1

    ::CalcSize()

    ::cBack := GfxSave( ;
        Max( 0,           ::nTop    - PADWIN ), ;
        Max( 0,           ::nLeft   - PADWIN ), ;
        Min( GfxMaxRow(), ::nBottom + PADWIN ), ;
        Min( GfxMaxCol(), ::nRight  + PADWIN ) )

    AAdd( aPopStack, Self )

    ::Paint()

    ::Run()

    ::Close()

RETURN NIL


METHOD CalcSize() CLASS TMenuPop

    LOCAL nI
    LOCAL nW := 0
    LOCAL nH

    FOR nI := 1 TO Len( ::aItems )
        nW := Max( nW, Len( ::aItems[nI, 1] ) )
    NEXT

    nH := Len( ::aItems )

    ::nBottom := ::nTop  + nH + 1
    ::nRight  := ::nLeft + nW + 2

    IF ::nRight > GfxMaxCol() - PADWIN
        ::nLeft  := Max( 0, GfxMaxCol() - PADWIN - ( nW + 2 ) )
        ::nRight := ::nLeft + nW + 2
    ENDIF

    IF ::nBottom > GfxMaxRow() - PADWIN
        ::nTop    := Max( 0, GfxMaxRow() - PADWIN - ( nH + 1 ) )
        ::nBottom := ::nTop + nH + 1
    ENDIF

RETURN NIL


METHOD Paint() CLASS TMenuPop

    LOCAL nI
    LOCAL cTit
    LOCAL cCol
    LOCAL lSep

    GfxLock()
    GfxClear( ::nTop, ::nLeft, ::nBottom, ::nRight, CLR_MENU )
    GfxRaised( ::nTop, ::nLeft, ::nBottom, ::nRight )

    FOR nI := 1 TO Len( ::aItems )
        cTit := ::aItems[nI, 1]
        lSep := ( Left( AllTrim( cTit ), 1 ) == "-" )

        IF lSep
            GfxText( ::nTop + nI, ::nLeft + 1, ;
                Replicate( Chr( 196 ), ::nRight - ::nLeft - 1 ), CLR_MENU )
        ELSE
            cCol := If( nI == ::nSel, CLR_MENU_SEL, CLR_MENU )
            GfxText( ::nTop + nI, ::nLeft + 1, cTit, cCol )
        ENDIF
    NEXT

    GfxUnlock()

RETURN NIL


METHOD Run() CLASS TMenuPop

    LOCAL nKey
    LOCAL lSub
    LOCAL lSep
    LOCAL nMR, nML, nTry

    DO WHILE .T.

        // Limpiar señal igual que el original antes de AChoice
        s_nNavKey := 0

        nKey := Inkey( 0 )

        DO CASE

        CASE nKey == K_UP
            DO WHILE .T.
                ::nSel--
                IF ::nSel < 1
                    ::nSel := Len( ::aItems )
                ENDIF
                lSep := ( Left( AllTrim( ::aItems[::nSel, 1] ), 1 ) == "-" )
                IF !lSep
                    EXIT
                ENDIF
            ENDDO
            ::Paint()

        CASE nKey == K_DOWN
            DO WHILE .T.
                ::nSel++
                IF ::nSel > Len( ::aItems )
                    ::nSel := 1
                ENDIF
                lSep := ( Left( AllTrim( ::aItems[::nSel, 1] ), 1 ) == "-" )
                IF !lSep
                    EXIT
                ENDIF
            ENDDO
            ::Paint()

        CASE nKey == K_HOME
            ::nSel := 1
            DO WHILE Left( AllTrim( ::aItems[::nSel, 1] ), 1 ) == "-"
                ::nSel++
            ENDDO
            ::Paint()

        CASE nKey == K_END
            ::nSel := Len( ::aItems )
            DO WHILE Left( AllTrim( ::aItems[::nSel, 1] ), 1 ) == "-"
                ::nSel--
            ENDDO
            ::Paint()

        CASE nKey == K_RIGHT
            // Poner señal y salir del bucle (igual que PopHnd en original)
            s_nNavKey := K_RIGHT
            EXIT

        CASE nKey == K_LEFT
            s_nNavKey := K_LEFT
            EXIT

        CASE nKey == K_ESC
            s_nNavKey := 0
            EXIT

        CASE nKey == K_ENTER
            lSub := ::ExecItem()
            _RedrawStack()
            IF !lSub
                EXIT
            ENDIF

        CASE nKey == K_LDBLCLK
             nMR := MRow()
             nML := MCol()
             IF nMR >= ::nTop .AND. nMR <= ::nBottom .AND. ;
                nML >= ::nLeft .AND. nML <= ::nRight
                 nTry := nMR - ::nTop
                 IF nTry >= 1 .AND. nTry <= Len( ::aItems )
                     IF Left( AllTrim( ::aItems[nTry, 1] ), 1 ) != "-"
                         ::nSel := nTry
                         ::Paint()
                         lSub := ::ExecItem()
                         _RedrawStack()
                         IF !lSub
                             EXIT
                         ENDIF
                     ENDIF
                 ENDIF
             ENDIF

        CASE nKey == K_LBUTTONDOWN
             nMR := MRow()
             nML := MCol()
             // Verificar si el click esta dentro del area del popup
             IF nMR >= ::nTop .AND. nMR <= ::nBottom .AND. ;
                nML >= ::nLeft .AND. nML <= ::nRight
                 nTry := nMR - ::nTop
                 IF nTry >= 1 .AND. nTry <= Len( ::aItems )
                     // Saltar separadores
                     IF Left( AllTrim( ::aItems[nTry, 1] ), 1 ) != "-"
                         ::nSel := nTry
                         ::Paint()
                         lSub := ::ExecItem()
                         _RedrawStack()
                         IF !lSub
                             EXIT
                         ENDIF
                     ENDIF
                 ENDIF
             ENDIF

        ENDCASE

    ENDDO

RETURN NIL


METHOD ExecItem() CLASS TMenuPop

    LOCAL bA   := ::aItems[::nSel, 2]
    LOCAL lSub := ::aItems[::nSel, 3]

    IF ValType( bA ) == "B"
        Eval( bA, ::nTop + ::nSel - 1, ::nRight - 1 )
    ENDIF

RETURN lSub


METHOD Close() CLASS TMenuPop

    // Restaurar fondo solo si no fue invalidado por cambio de tema
    IF ::cBack != NIL
        GfxRestore( ;
            Max( 0,           ::nTop    - PADWIN ), ;
            Max( 0,           ::nLeft   - PADWIN ), ;
            Min( GfxMaxRow(), ::nBottom + PADWIN ), ;
            Min( GfxMaxCol(), ::nRight  + PADWIN ), ;
            ::cBack )
        ::cBack := NIL
    ENDIF

    IF !Empty( aPopStack ) .AND. ATail( aPopStack ) == Self
        ASize( aPopStack, Len( aPopStack ) - 1 )
    ENDIF

RETURN NIL


// ============================================================================
// AUXILIARES
// ============================================================================

STATIC FUNCTION _MakePopOpener( oPop )
RETURN {| nR, nC | oPop:Open( nR, nC ) }


STATIC FUNCTION _RedrawStack()

    LOCAL nI

    FOR nI := 1 TO Len( aPopStack )
        aPopStack[nI]:Paint()
    NEXT

RETURN NIL


STATIC FUNCTION _MenuCol( aItems, nPos )

    LOCAL nI
    LOCAL nC := 2

    FOR nI := 1 TO nPos - 1
        nC += Len( aItems[nI, 1] ) + 4
    NEXT

RETURN nC


// ============================================================================
// CERRAR TODOS LOS POPUPS
// (usar antes de cambiar tema para que Close() restaure fondos viejos y
//  luego CLS los pise con el color nuevo)
// ============================================================================
FUNCTION TMenuCloseAll()

    LOCAL nI

    FOR nI := Len( aPopStack ) TO 1 STEP -1
        aPopStack[nI]:Close()
    NEXT

RETURN NIL


// ============================================================================
// INVALIDAR FONDOS DE POPUP (alternativa ligera si no se quiere restaurar)
// ============================================================================
FUNCTION TMenuInvalidateBack()

    LOCAL nI

    FOR nI := 1 TO Len( aPopStack )
        aPopStack[nI]:cBack := NIL
    NEXT

RETURN NIL


// ============================================================================
// FIN DE TMenu.prg
// ============================================================================
