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
    ::cN     := "N/W"
    ::cS     := "W+/B"
    ::cM     := "N/W"

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
    GfxClear( ::nTop, ::nLeft, ::nBottom, ::nRight, "N/W" )
    GfxRaised( ::nTop, ::nLeft, ::nBottom, ::nRight )

    FOR nI := 1 TO Len( ::aItems )
        cTit := ::aItems[nI, 1]
        lSep := ( Left( AllTrim( cTit ), 1 ) == "-" )

        IF lSep
            GfxText( ::nTop + nI, ::nLeft + 1, ;
                Replicate( Chr( 196 ), ::nRight - ::nLeft - 1 ), "N/W" )
        ELSE
            cCol := If( nI == ::nSel, "W+/B", "N/W" )
            GfxText( ::nTop + nI, ::nLeft + 1, cTit, cCol )
        ENDIF
    NEXT

    GfxUnlock()

RETURN NIL


METHOD Run() CLASS TMenuPop

    LOCAL nKey
    LOCAL lSub
    LOCAL lSep

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

        ENDCASE

    ENDDO

RETURN NIL


METHOD ExecItem() CLASS TMenuPop

    LOCAL bA   := ::aItems[::nSel, 2]
    LOCAL lSub := ::aItems[::nSel, 3]
    LOCAL oErr
    LOCAL bErr

    IF ValType( bA ) == "B"
        bErr := ErrorBlock( {| e | Break( e ) } )
        BEGIN SEQUENCE
            Eval( bA, ::nTop + ::nSel - 1, ::nRight - 1 )
        RECOVER USING oErr
        END SEQUENCE
        ErrorBlock( bErr )
        IF oErr != NIL
            _MenuError( oErr )
        ENDIF
    ENDIF

RETURN lSub


METHOD Close() CLASS TMenuPop

    GfxRestore( ;
        Max( 0,           ::nTop    - PADWIN ), ;
        Max( 0,           ::nLeft   - PADWIN ), ;
        Min( GfxMaxRow(), ::nBottom + PADWIN ), ;
        Min( GfxMaxCol(), ::nRight  + PADWIN ), ;
        ::cBack )

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


STATIC FUNCTION _MenuError( oErr )

    LOCAL cMsg
    LOCAL cLog
    LOCAL cArgs := ""
    LOCAL nI    := 2
    LOCAL i

    cMsg := "La opcion no pudo ejecutarse."
    cLog := Replicate( "=", 70 ) + hb_Eol() + ;
        "FECHA: " + DToC( Date() ) + " HORA: " + Time() + hb_Eol() + ;
        "ERROR EN OPCION DE MENU" + hb_Eol()

    IF oErr != NIL
        cMsg += Chr( 13 ) + Chr( 10 ) + ;
            AllTrim( hb_CStr( oErr:Operation ) ) + ": " + ;
            AllTrim( hb_CStr( oErr:Description ) )
        BEGIN SEQUENCE
            cLog += "Subsistema  : " + hb_ValToStr( oErr:SubSystem )   + hb_Eol()
            cLog += "Codigo      : " + hb_ValToStr( oErr:SubCode )     + hb_Eol()
            cLog += "Operacion   : " + hb_ValToStr( oErr:Operation )   + hb_Eol()
            cLog += "Descripcion : " + hb_ValToStr( oErr:Description ) + hb_Eol()
            cLog += "Severidad   : " + hb_ValToStr( oErr:Severity )    + hb_Eol()
            cLog += "CanRetry    : " + hb_ValToStr( oErr:CanRetry )    + hb_Eol()
            IF !Empty( oErr:FileName )
                cLog += "Fichero     : " + hb_ValToStr( oErr:FileName ) + hb_Eol()
            ENDIF
            IF !Empty( oErr:OsCode )
                cLog += "OS code     : " + hb_ValToStr( oErr:OsCode )  + hb_Eol()
            ENDIF
        RECOVER
            cLog += "(no se pudieron leer todos los campos del error)" + hb_Eol()
        END SEQUENCE

        BEGIN SEQUENCE
            IF HB_ISARRAY( oErr:Args )
                cArgs := "Argumentos:" + hb_Eol()
                FOR i := 1 TO Len( oErr:Args )
                    cArgs += "  [" + AllTrim( Str( i ) ) + "] " + ;
                             hb_ValToStr( oErr:Args[ i ] ) + hb_Eol()
                NEXT
            ENDIF
        RECOVER
            cArgs := "(argumentos no accesibles)" + hb_Eol()
        END SEQUENCE

        IF !Empty( cArgs )
            cLog += cArgs
        ENDIF

        cLog += "Pila de llamadas:" + hb_Eol()
        DO WHILE !Empty( ProcName( nI ) )
            cLog += "  " + PadR( ProcFile( nI ), 24 ) + ;
                    " -> " + PadR( ProcName( nI ), 30 ) + ;
                    " (linea " + AllTrim( Str( ProcLine( nI ) ) ) + ")" + hb_Eol()
            nI++
            IF nI > 50
                EXIT
            ENDIF
        ENDDO
    ENDIF

    ErrorLogAppend( cLog )

    MsgStop( cMsg, "Menu" )

RETURN NIL


STATIC FUNCTION _MenuCol( aItems, nPos )

    LOCAL nI
    LOCAL nC := 2

    FOR nI := 1 TO nPos - 1
        nC += Len( aItems[nI, 1] ) + 4
    NEXT

RETURN nC


// ============================================================================
// FIN DE TMenu.prg
// ============================================================================
