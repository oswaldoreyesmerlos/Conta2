#include "OOp.ch"

// ============================================================================
// CONSTANTE DE MARGEN PARA SAVE / RESTORE
// ----------------------------------------------------------------------------
// Cuando hacemos GfxSave para guardar el contenido bajo una ventana, y
// despues GfxRestore al cerrarla, las coordenadas deben AMPLIARSE en
// PADWIN filas/columnas por cada lado.
//
// Por que el margen?
//   La capa grafica WVG (Wvt_DrawBoxRaised, Wvt_DrawBoxRecessed, etc.)
//   pinta lineas finas de pixel ENTRE las celdas de caracteres y un poco
//   FUERA del rectangulo de celdas.  Si no ampliamos el area al guardar
//   y restaurar, esas lineas finas quedan FUERA del snapshot y al cerrar
//   permanecen visibles como restos fantasma.
//
// Con PADWIN = 2 cubrimos el caso normal:
//   - 2 filas: la sombra de la ventana ocupa 1 fila debajo + margen.
//   - 2 columnas: la sombra ocupa 2 columnas a la derecha.
//
// Las coordenadas del Save y del Restore deben COINCIDIR EXACTAMENTE.
// ============================================================================
#define PADWIN  2


// ============================================================================
// Variable STATIC del modulo: apunta a la ventana actualmente activa
// (la que esta corriendo Run en este momento).  Sirve para que cuando
// se anida una ventana hija, esta sepa quien es su padre.
// ============================================================================
STATIC s_oCurrentWnd := NIL


// ============================================================================
// CLASE: TWindow
// Ventana principal del framework pseudo grafico
// Version SUPER PRO
// ============================================================================
CLASS TWindow

    DATA nTop
    DATA nLeft
    DATA nBottom
    DATA nRight

    DATA cTitle

    DATA aCtrls
    DATA nFocPos
    DATA oFocus

    DATA lExit
    DATA lVisible

    DATA xBackup                // Snapshot devuelto por GfxSave al inicio
                                // del Run.  Se usa para restaurar la zona
                                // exacta al cerrar la ventana.  Las
                                // coordenadas son las de la ventana ampliadas
                                // en PADWIN filas/cols por cada lado.

    DATA lModal
    DATA nStyle

    DATA lRegistered            // .T. tras la primera llamada a Paint() del
                                // ciclo Run().  Evita que un Refresh()
                                // posterior duplique bloques en el stack.

    DATA oOwner                 // Ventana padre (otro TWindow), si esta
                                // ventana es modal anidada.  Se establece
                                // automaticamente desde Run() detectando si
                                // hay otra ventana ya activa.  Al cerrar,
                                // pedimos al padre que repinte sus
                                // caracteres (los relieves los repinta WVG
                                // solo, gracias al stack).

    METHOD New()

    METHOD AddCtrl()

    METHOD Paint()
    METHOD Refresh()
    METHOD Redraw()

    METHOD Run()
    METHOD Close()

    METHOD HandleKey()

    METHOD SetFocus()
    METHOD NextFocus()
    METHOD PrevFocus()
    METHOD FindFirstFocus()

    METHOD Center()

    METHOD Lock()   INLINE GfxLock()
    METHOD Unlock() INLINE GfxUnlock()

ENDCLASS


// ----------------------------------------------------------------------------
// Constructor
// ----------------------------------------------------------------------------
METHOD New( nT, nL, nB, nR, cTit ) CLASS TWindow

    ::nTop    := nT
    ::nLeft   := nL
    ::nBottom := nB
    ::nRight  := nR

    ::cTitle := cTit

    ::aCtrls := {}

    ::nFocPos := 0
    ::oFocus  := NIL

    ::lExit    := .F.
    ::lVisible := .F.

    ::xBackup := NIL

    ::lModal := .T.
    ::nStyle := 0

    ::lRegistered := .F.

    ::oOwner := NIL

RETURN Self


// ----------------------------------------------------------------------------
// Anyadir control hijo
// ----------------------------------------------------------------------------
METHOD AddCtrl( oCtrl ) CLASS TWindow
    AAdd( ::aCtrls, oCtrl )
RETURN Self


// ----------------------------------------------------------------------------
// Buscar primer control enfocable
// ----------------------------------------------------------------------------
METHOD FindFirstFocus() CLASS TWindow

    LOCAL i
    LOCAL oCtrl

    FOR i := 1 TO Len( ::aCtrls )

        oCtrl := ::aCtrls[ i ]

        IF oCtrl:lVisible .AND. ;
           oCtrl:lEnabled .AND. ;
           oCtrl:lTabStop

            RETURN i

        ENDIF

    NEXT

RETURN 0


// ----------------------------------------------------------------------------
// Cambiar foco seguro
// ----------------------------------------------------------------------------
METHOD SetFocus( nPos ) CLASS TWindow

    LOCAL oOld
    LOCAL oNew

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


// ----------------------------------------------------------------------------
// Siguiente foco
// ----------------------------------------------------------------------------
METHOD NextFocus() CLASS TWindow

    LOCAL nTotal
    LOCAL nPos
    LOCAL nTry
    LOCAL oCtrl

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

        IF oCtrl:lVisible .AND. ;
           oCtrl:lEnabled .AND. ;
           oCtrl:lTabStop

            ::SetFocus( nPos )
            EXIT

        ENDIF

        nTry++

    ENDDO

RETURN Self


// ----------------------------------------------------------------------------
// Foco anterior
// ----------------------------------------------------------------------------
METHOD PrevFocus() CLASS TWindow

    LOCAL nTotal
    LOCAL nPos
    LOCAL nTry
    LOCAL oCtrl

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

        IF oCtrl:lVisible .AND. ;
           oCtrl:lEnabled .AND. ;
           oCtrl:lTabStop

            ::SetFocus( nPos )
            EXIT

        ENDIF

        nTry++

    ENDDO

RETURN Self


// ----------------------------------------------------------------------------
// Centrar ventana
// ----------------------------------------------------------------------------
METHOD Center() CLASS TWindow

    LOCAL nH
    LOCAL nW

    nH := ::nBottom - ::nTop
    nW := ::nRight  - ::nLeft

    ::nTop  := Int( ( GfxMaxRow() - nH ) / 2 )
    ::nLeft := Int( ( GfxMaxCol() - nW ) / 2 )

    ::nBottom := ::nTop + nH
    ::nRight  := ::nLeft + nW

RETURN Self


// ----------------------------------------------------------------------------
// Pintado principal
// ----------------------------------------------------------------------------
// Esta version usa el "stack de bloques de pintado" oficial GTWVG (ver
// Gfx.prg seccion 8).  Los RELIEVES (sombra, marco raised) se registran
// como CODEBLOCKS via GfxPaintAdd, de forma que GTWVG los re-pinta
// automaticamente cuando lo necesita y, sobre todo, los puede HACER
// DESAPARECER en el cierre de la ventana mediante GfxPaintPop.
//
// El contenido CAMBIANTE (color de fondo del interior, barra de titulo
// con texto, hijos con su estado actual) se pinta directamente: no hace
// falta meterlo en el stack porque cuando cambia su estado (foco, valor),
// el propio control se llama de nuevo a Paint() y se actualiza solo.
// ----------------------------------------------------------------------------
METHOD Paint() CLASS TWindow

    LOCAL nTitCol
    LOCAL Self_ := Self          // referencia explicita para los codeblocks

    ::Lock()

    // -- Bloques persistentes (capa grafica WVG): se registran en el stack
    //    SOLO la primera vez del ciclo Run() para evitar duplicados.

    IF ! ::lRegistered

        // [1] Sombra a la derecha y debajo
        GfxPaintAdd( "tw_shadow", ;
            {|| GfxShadow( Self_:nTop, Self_:nLeft, ;
                           Self_:nBottom, Self_:nRight ) } )

        // [2] Marco raised
        GfxPaintAdd( "tw_frame", ;
            {|| GfxRaised( Self_:nTop, Self_:nLeft, ;
                           Self_:nBottom, Self_:nRight ) } )

        ::lRegistered := .T.

    ENDIF

    // -- Pintado directo (capa de caracteres): se ejecuta SIEMPRE.
    //
    //    NOTA: probamos GfxFillSolid (wvg_ShadedRect) como "escudo
    //    opaco" antes del pintado, pero la capa grafica WVG SIEMPRE
    //    queda por encima de los caracteres en GTWVG, asi que tapaba
    //    nuestros propios textos y controles.  La transparencia de
    //    relieves WVG de la ventana padre queda como limitacion
    //    visual conocida.

    // [3] LIMPIEZA AGRESIVA del area completa de la ventana (incluyendo
    //     el marco) para borrar cualquier caracter previo de ventanas
    //     inferiores que pudiera quedar.  Los relieves WVG no se afectan
    //     (estan en otra capa), pero los caracteres si.
    GfxClear( ::nTop, ::nLeft, ::nBottom, ::nRight, CLR_WINDOW )

    // [4] Barra de titulo (fondo azul) - solo la franja del titulo
    GfxClear( ::nTop, ::nLeft + 1, ::nTop, ::nRight - 1, "W+/B" )

    // [5] Texto del titulo centrado
    IF ! Empty( ::cTitle )
        nTitCol := ::nLeft + ;
                   Int( ( ::nRight - ::nLeft - Len( ::cTitle ) ) / 2 )

        GfxText( ::nTop, nTitCol, ::cTitle, "W+/B" )
    ENDIF

    // [6] Interior (color de fondo) - innecesario ya por el [3] pero
    //     lo dejamos por claridad de codigo
    GfxClear( ::nTop + 1, ::nLeft + 1, ;
              ::nBottom - 1, ::nRight - 1, ;
              CLR_WINDOW )

    // [7] Hijos (cada uno se pinta con su estado actual)
    AEval( ::aCtrls, ;
           { |o| If( o:lVisible, o:Paint(), NIL ) } )

    ::Unlock()

RETURN NIL


// ----------------------------------------------------------------------------
// Refresh
// ----------------------------------------------------------------------------
METHOD Refresh() CLASS TWindow
    ::Paint()
RETURN Self


METHOD Redraw() CLASS TWindow
    ::Paint()
RETURN Self


// ----------------------------------------------------------------------------
// Teclado principal
// ----------------------------------------------------------------------------
METHOD HandleKey( nKey ) CLASS TWindow

    LOCAL lUsed := .F.

    DO CASE

    CASE nKey == K_ESC
        ::Close()

    CASE nKey == K_TAB
        ::NextFocus()

    CASE nKey == K_SH_TAB
        ::PrevFocus()

    CASE nKey == K_UP .OR. nKey == K_DOWN

        // Las flechas verticales tienen DOBLE comportamiento:
        //   - Si el control con foco las consume (TGrid, TCombo abierto,
        //     TGet multilinea, etc.) -> el control hace su navegacion
        //     interna y la ventana no toca el foco.
        //   - Si el control NO las consume (TGet simple, TButton, TLabel,
        //     TCheck...) -> la ventana las usa para mover el foco al
        //     control siguiente/anterior, como hace TAB / SH_TAB.
        //
        // Esto permite navegar formularios completos con flechas y al
        // mismo tiempo deja que controles complejos (grids, combos)
        // usen las flechas para su propia navegacion.
        IF ::oFocus != NIL
            lUsed := ::oFocus:HandleKey( nKey )
        ENDIF

        IF ! lUsed
            IF nKey == K_DOWN
                ::NextFocus()
            ELSE
                ::PrevFocus()
            ENDIF
        ENDIF

    OTHERWISE

        IF ::oFocus != NIL

            lUsed := ::oFocus:HandleKey( nKey )

            IF ! lUsed .AND. nKey == K_ENTER
                ::NextFocus()
            ENDIF

        ENDIF

    ENDCASE

RETURN NIL


// ----------------------------------------------------------------------------
// Loop modal - MODELO HIBRIDO
// ----------------------------------------------------------------------------
// Combinamos dos estrategias para la mejor robustez visual:
//
// 1) PUSH/POP del stack de bloques (modelo oficial GTWVG, Pritpal Bedi):
//    - Al abrir la ventana, hacemos GfxPaintPush para empilar los bloques
//      activos.
//    - Cada bloque que registramos con GfxPaintAdd queda vivo mientras
//      esta ventana este activa.  GTWVG re-ejecutara esos bloques cada
//      vez que el SO mande un evento WM_PAINT (resize, restore desde
//      minimizado, etc.).
//    - Al cerrar, GfxPaintPop desempila: los bloques de esta ventana
//      dejan de pintarse en futuros eventos del SO.
//
// 2) SAVE/RESTORE de pantalla con margen amplio (modelo Clipper clasico):
//    - Al abrir, GfxSave guarda el contenido EXACTO de la zona que vamos
//      a tapar, AMPLIADA en PADWIN filas/cols por cada lado.
//    - Al cerrar, GfxRestore con LAS MISMAS COORDENADAS devuelve la zona
//      a su estado anterior, borrando todo lo que pintamos (caracteres
//      Y relieves WVG residuales).
//    - Las coordenadas del Save y del Restore deben COINCIDIR EXACTAMENTE.
//
// Por que combinar las dos?
//   - El POP solo NO basta: aunque saquemos los bloques del array, los
//     pixeles ya pintados siguen visibles hasta que algo los borre.
//   - El RESTORE solo NO basta: si el SO manda WM_PAINT mientras la
//     ventana esta abierta, GTWVG no sabe re-pintarla porque no tiene
//     bloques registrados.
//
// Orden critico:
//   Open : Push -> Save -> Paint -> Loop
//   Close: Restore -> Pop -> ajustes
// ----------------------------------------------------------------------------
METHOD Run() CLASS TWindow

    LOCAL nKey
    LOCAL nFirst
    LOCAL aPrev                  // bloques del nivel previo (para POP)
    LOCAL nT, nL, nB, nR         // coordenadas ampliadas (Save y Restore)

    ::lVisible := .T.
    ::lExit    := .F.

    // Coordenadas ampliadas para el snapshot.  DEBEN ser identicas en
    // el Save y en el Restore para que el handle no se descuadre.
    nT := Max( ::nTop    - PADWIN, 0           )
    nL := Max( ::nLeft   - PADWIN, 0           )
    nB := Min( ::nBottom + PADWIN, GfxMaxRow() )
    nR := Min( ::nRight  + PADWIN, GfxMaxCol() )

    // [1] Detectar ventana padre.  Si ya hay una ventana activa, ESA es
    //     nuestra padre.  Pasamos a ser nosotros la activa.
    ::oOwner      := s_oCurrentWnd
    s_oCurrentWnd := Self

    // [2] PUSH del stack de bloques.  A partir de aqui, los GfxPaintAdd
    //     se registraran en NUESTRO array (vacio inicialmente).  Los
    //     bloques de niveles superiores quedan guardados en aPrev.
    aPrev := GfxPaintPush()

    // [3] SAVE clasico ampliado.  Capturamos el estado EXACTO de la zona
    //     antes de pintar nada nuestro.  Incluye caracteres + capa
    //     grafica WVG.  El margen PADWIN garantiza que cubrimos las
    //     lineas finas que se pintan fuera del rectangulo de celdas.
    ::xBackup := GfxSave( nT, nL, nB, nR )

    // [4] Pintar nuestro contenido (registra bloques + pinta caracteres)
    ::Paint()

    // [5] Establecer foco inicial
    nFirst := ::FindFirstFocus()

    IF nFirst > 0
        ::SetFocus( nFirst )
    ENDIF

    // [6] Bucle de teclas
    DO WHILE ! ::lExit

        nKey := Inkey( 0 )

        ::HandleKey( nKey )

    ENDDO

    // [7] RESTORE clasico ampliado.  Las coordenadas DEBEN ser las
    //     mismas que el Save.  Esto borra todo lo que pintamos
    //     (caracteres + capa grafica WVG residual) de una sola
    //     operacion.
    GfxRestore( nT, nL, nB, nR, ::xBackup )

    ::xBackup := NIL

    // [8] POP del stack: nuestros bloques salen del array activo de WVG.
    //     A partir de aqui, futuros WM_PAINT del SO ejecutaran solo los
    //     bloques del nivel padre (si los hay).
    GfxPaintPop( aPrev )

    // [9] Restaurar la ventana activa al padre
    s_oCurrentWnd := ::oOwner

    // [10] Cursor apagado: politica unificada de la libreria.
    GfxCursor( SC_NONE )

    ::lVisible    := .F.
    ::lRegistered := .F.        // Reseteamos para que un futuro Run() vuelva
                                // a registrar los bloques desde cero.

RETURN NIL


// ----------------------------------------------------------------------------
// Cerrar
// ----------------------------------------------------------------------------
METHOD Close() CLASS TWindow
    ::lExit := .T.
RETURN Self