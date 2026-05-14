/*
 * TWvgCrtWindow — Ventana nativa con GT propio
 *
 * EXPERIMENTAL: Crea un HWND real independiente por ventana
 * usando hb_gtCreate("WVG"). Cada ventana tiene su propio
 * GT, buffer, fuente y cola de teclas.
 *
 * Interface compatible con TWindow para que los mismos
 * controles (TLabel, TGet, TButton, etc.) funcionen sin cambios.
 */

#include "hbclass.ch"
#include "hbgtinfo.ch"
#include "inkey.ch"
#include "OOp.ch"

#define PADWIN  2

CLASS TWvgCrtWindow

    DATA nTop, nLeft, nBottom, nRight
    DATA cTitle
    DATA aCtrls
    DATA nFocPos
    DATA oFocus
    DATA lExit
    DATA lVisible
    DATA pGtParent                     // GT padre al crearse
    DATA pGtSelf                       // GT propio de esta ventana

    METHOD New( nT, nL, nB, nR, cTit )
    METHOD AddCtrl( oCtrl )
    METHOD Paint()
    METHOD Run()
    METHOD Close()
    METHOD HandleKey( nKey )
    METHOD SetFocus( nPos )
    METHOD NextFocus()
    METHOD PrevFocus()
    METHOD FindFirstFocus()
    METHOD Center()

    METHOD Lock()   INLINE GfxLock()
    METHOD Unlock() INLINE GfxUnlock()

ENDCLASS


METHOD New( nT, nL, nB, nR, cTit ) CLASS TWvgCrtWindow

    ::nTop    := nT
    ::nLeft   := nL
    ::nBottom := nB
    ::nRight  := nR
    ::cTitle  := cTit
    ::aCtrls  := {}
    ::nFocPos := 0
    ::oFocus  := NIL
    ::lExit   := .F.
    ::lVisible := .F.
    ::pGtParent := NIL
    ::pGtSelf := NIL

RETURN Self


METHOD AddCtrl( oCtrl ) CLASS TWvgCrtWindow
    AAdd( ::aCtrls, oCtrl )
RETURN Self


METHOD FindFirstFocus() CLASS TWvgCrtWindow

    LOCAL i, oCtrl

    FOR i := 1 TO Len( ::aCtrls )
        oCtrl := ::aCtrls[ i ]
        IF oCtrl:lVisible .AND. oCtrl:lEnabled .AND. oCtrl:lTabStop
            RETURN i
        ENDIF
    NEXT

RETURN 0


METHOD SetFocus( nPos ) CLASS TWvgCrtWindow

    LOCAL oOld, oNew

    IF Empty( ::aCtrls )
        RETURN NIL
    ENDIF
    IF nPos < 1 .OR. nPos > Len( ::aCtrls )
        RETURN NIL
    ENDIF
    IF ::nFocPos == nPos
        RETURN Self
    ENDIF

    oNew := ::aCtrls[ nPos ]

    IF ::nFocPos > 0 .AND. ::nFocPos <= Len( ::aCtrls )
        oOld := ::aCtrls[ ::nFocPos ]
        IF oOld:KillFocus() == NIL
            RETURN NIL
        ENDIF
    ENDIF

    IF oNew:SetFocus() == NIL
        IF oOld != NIL
            oOld:SetFocus()
        ENDIF
        RETURN NIL
    ENDIF

    ::nFocPos := nPos
    ::oFocus  := oNew

RETURN Self


METHOD NextFocus() CLASS TWvgCrtWindow

    LOCAL nTotal, nPos, nTry, oCtrl

    nTotal := Len( ::aCtrls )
    IF nTotal == 0
        RETURN NIL
    ENDIF

    nPos := ::nFocPos
    nTry := 0

    DO WHILE nTry < nTotal
        nPos++
        IF nPos > nTotal
            nPos := 1
        ENDIF
        oCtrl := ::aCtrls[ nPos ]
        IF oCtrl:lVisible .AND. oCtrl:lEnabled .AND. oCtrl:lTabStop
            ::SetFocus( nPos )
            EXIT
        ENDIF
        nTry++
    ENDDO

RETURN Self


METHOD PrevFocus() CLASS TWvgCrtWindow

    LOCAL nTotal, nPos, nTry, oCtrl

    nTotal := Len( ::aCtrls )
    IF nTotal == 0
        RETURN NIL
    ENDIF

    nPos := ::nFocPos
    nTry := 0

    DO WHILE nTry < nTotal
        nPos--
        IF nPos < 1
            nPos := nTotal
        ENDIF
        oCtrl := ::aCtrls[ nPos ]
        IF oCtrl:lVisible .AND. oCtrl:lEnabled .AND. oCtrl:lTabStop
            ::SetFocus( nPos )
            EXIT
        ENDIF
        nTry++
    ENDDO

RETURN Self


METHOD Center() CLASS TWvgCrtWindow

    LOCAL nH := ::nBottom - ::nTop
    LOCAL nW := ::nRight - ::nLeft

    ::nTop  := Int( ( GfxMaxRow() - nH ) / 2 )
    ::nLeft := Int( ( GfxMaxCol() - nW ) / 2 )
    ::nBottom := ::nTop + nH
    ::nRight  := ::nLeft + nW

RETURN Self


METHOD Paint() CLASS TWvgCrtWindow

    LOCAL Self_ := Self
    LOCAL i

    ::Lock()

    GfxClear( ::nTop, ::nLeft, ::nBottom, ::nRight, CLR_WIN_BODY )
    GfxClear( ::nTop, ::nLeft, ::nTop, ::nRight, CLR_WIN_TITLE_ACT )

    IF !Empty( ::cTitle )
        GfxText( ::nTop, ::nLeft, ;
            PadR( " " + AllTrim( ::cTitle ) + " ", ::nRight - ::nLeft + 1 ), ;
            CLR_WIN_TITLE_ACT )
    ENDIF

    GfxRaised( ::nTop, ::nLeft, ::nBottom, ::nRight )
    GfxClear( ::nTop + 1, ::nLeft + 1, ::nBottom - 1, ::nRight - 1, CLR_WIN_BODY )

    AEval( ::aCtrls, { |o| If( o:lVisible, o:Paint(), NIL ) } )

    ::Unlock()

RETURN NIL


METHOD HandleKey( nKey ) CLASS TWvgCrtWindow

    LOCAL lUsed := .F.

    DO CASE
    CASE nKey == K_ESC
        ::Close()

    CASE nKey == K_TAB
        ::NextFocus()

    CASE nKey == K_SH_TAB
        ::PrevFocus()

    CASE nKey == K_UP .OR. nKey == K_DOWN
        IF ::oFocus != NIL
            lUsed := ::oFocus:HandleKey( nKey )
        ENDIF
        IF !lUsed
            IF nKey == K_DOWN
                ::NextFocus()
            ELSE
                ::PrevFocus()
            ENDIF
        ENDIF

    OTHERWISE
        IF ::oFocus != NIL
            lUsed := ::oFocus:HandleKey( nKey )
            IF !lUsed .AND. nKey == K_ENTER
                ::NextFocus()
            ENDIF
        ENDIF
    ENDCASE

RETURN NIL


METHOD Run() CLASS TWvgCrtWindow

    LOCAL nKey, nFirst

    ::lVisible := .T.
    ::lExit    := .F.

    // --- 1. Guardar GT padre ---
    ::pGtParent := hb_gtSelect()

    // --- 2. Crear GT propio (nuevo HWND) ---
    ::pGtSelf := hb_gtCreate( "WVG" )
    hb_gtSelect( ::pGtSelf )

    // --- 3. Configurar GT hijo ---
    hb_gtInfo( HB_GTI_WINTITLE, If( Empty( ::cTitle ), "TWvgCrtWindow", ::cTitle ) )
    hb_gtInfo( HB_GTI_FONTNAME, "Lucida Console" )
    hb_gtInfo( HB_GTI_FONTWIDTH, 8 )
    hb_gtInfo( HB_GTI_FONTHEIGHT, 16 )
    hb_gtInfo( HB_GTI_ISGRAPHIC, .T. )

    SetMode( ::nBottom - ::nTop + 3, ::nRight - ::nLeft + 3 )
    SetColor( CLR_WINDOW )
    CLS

    // --- 4. Fijar tamaño (opcional) ---
    GfxFixSize( .T. )

    // --- 5. Pintar ---
    ::Paint()

    // --- 6. Foco inicial ---
    nFirst := ::FindFirstFocus()
    IF nFirst > 0
        ::SetFocus( nFirst )
    ENDIF

    // --- 7. Bucle de teclas (Inkey sobre este GT) ---
    DO WHILE !::lExit
        nKey := Inkey( 0 )
        ::HandleKey( nKey )
    ENDDO

    // --- 8. Limpiar foco ---
    IF ::oFocus != NIL
        ::oFocus:lFocused := .F.
        ::oFocus := NIL
        ::nFocPos := 0
    ENDIF
    GfxCursor( SC_NONE )

    // --- 9. Volver al GT padre ---
    hb_gtSelect( ::pGtParent )
    // El GT hijo se destruye al perder referencia (::pGtSelf := NIL)
    ::pGtSelf := NIL

    ::lVisible := .F.

RETURN NIL


METHOD Close() CLASS TWvgCrtWindow
    ::lExit := .T.
RETURN Self
