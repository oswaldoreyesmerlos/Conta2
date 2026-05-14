#include "OOp.ch"

// ============================================================================
// CLASE: TCombo
// ----------------------------------------------------------------------------
// Lista desplegable de seleccion (no editable libre).
// Soporta dos formatos de array de opciones, autodetectados:
//   1) Simple   : { "Sevilla", "Cordoba", "Malaga" }
//   2) Asociado : { {1,"Activo"}, {2,"Pendiente"}, {3,"Cancelado"} }
//
// En modo asociado, ::xValue guarda el VALOR (1ra col) y la lista
// muestra la ETIQUETA (2da col).  En modo simple, valor == etiqueta.
//
// Teclas:
//   - Cerrado: F4 / SPACE / ALT+DOWN abre la lista. Letra = busqueda incr.
//   - Abierto: flechas, RePag/AvPag, Inicio/Fin, ENTER selecciona, ESC cancela.
//             Letra = busqueda incremental dentro de la lista.
// ============================================================================
CLASS TCombo FROM TControl

    DATA aOptions       // array de opciones
    DATA lAssoc         // .T. si es asociado {valor,etiqueta}
    DATA nSelected      // indice de la opcion actual (1..N), 0 si ninguno
    DATA xValue         // valor real (lo que se guardaria en BD)
    DATA nMaxList       // maximo de filas visibles cuando se despliega
    DATA bChange        // bloque de codigo opcional al cambiar seleccion

    METHOD New()
    METHOD Paint()
    METHOD HandleKey()

    METHOD Open()           // despliega la lista y gestiona seleccion
    METHOD Label()          // texto a mostrar para un indice dado
    METHOD SetIndex()       // cambia el indice y actualiza xValue
    METHOD FindByPrefix()   // busqueda incremental por letra inicial
    METHOD GetValue()
    METHOD SetValue()

ENDCLASS


// ----------------------------------------------------------------------------
// Constructor
// nRow, nCol  : posicion (relativa al parent)
// nWidth      : ancho del control en columnas
// aOpts       : array de opciones (formato simple o asociado)
// nDefault    : indice por defecto seleccionado (1..N), default 1
// oPar        : ventana contenedora
// ----------------------------------------------------------------------------
METHOD New( nRow, nCol, nWidth, aOpts, nDefault, oPar ) CLASS TCombo

    DEFAULT nDefault TO 1

    // Detectar formato del array
    IF Len( aOpts ) > 0 .AND. ValType( aOpts[1] ) == "A"
        ::lAssoc := .T.
    ELSE
        ::lAssoc := .F.
    ENDIF

    ::aOptions := aOpts
    ::nMaxList := 8
    ::bChange  := NIL

    // Anchura minima razonable
    IF nWidth < 6
        nWidth := 6
    ENDIF

    ::TControl:New( nRow, nCol, nRow, nCol + nWidth - 1, oPar )

    ::cColor   := CLR_GET
    ::lTabStop := .T.

    // Establecer indice y valor iniciales
    IF Len( aOpts ) == 0
        ::nSelected := 0
        ::xValue    := NIL
    ELSE
        IF nDefault < 1 .OR. nDefault > Len( aOpts )
            nDefault := 1
        ENDIF
        ::SetIndex( nDefault )
    ENDIF

RETURN Self


// ----------------------------------------------------------------------------
// Devuelve la etiqueta correspondiente a un indice
// ----------------------------------------------------------------------------
METHOD Label( nIdx ) CLASS TCombo

    IF nIdx < 1 .OR. nIdx > Len( ::aOptions )
        RETURN ""
    ENDIF

    IF ::lAssoc
        RETURN hb_CStr( ::aOptions[ nIdx, 2 ] )
    ENDIF

RETURN hb_CStr( ::aOptions[ nIdx ] )


// ----------------------------------------------------------------------------
// Cambia el indice seleccionado y actualiza ::xValue
// ----------------------------------------------------------------------------
METHOD SetIndex( nIdx ) CLASS TCombo

    IF nIdx < 1 .OR. nIdx > Len( ::aOptions )
        RETURN Self
    ENDIF

    ::nSelected := nIdx

    IF ::lAssoc
        ::xValue := ::aOptions[ nIdx, 1 ]
    ELSE
        ::xValue := ::aOptions[ nIdx ]
    ENDIF

    IF ::bChange != NIL
        EvalSafe( ::bChange, "TCombo:bChange", Self )
    ENDIF

RETURN Self


METHOD GetValue() CLASS TCombo
RETURN ::xValue


METHOD SetValue( xValue ) CLASS TCombo

    LOCAL i

    FOR i := 1 TO Len( ::aOptions )
        IF ::lAssoc
            IF ::aOptions[ i, 1 ] == xValue
                ::SetIndex( i )
                ::Paint()
                RETURN Self
            ENDIF
        ELSEIF ::aOptions[ i ] == xValue
            ::SetIndex( i )
            ::Paint()
            RETURN Self
        ENDIF
    NEXT

    ::Paint()

RETURN Self


// ----------------------------------------------------------------------------
// Busqueda incremental por primera letra desde una posicion dada
// Devuelve el indice encontrado o 0 si no
// ----------------------------------------------------------------------------
METHOD FindByPrefix( cChar, nFromIdx ) CLASS TCombo

    LOCAL nLen := Len( ::aOptions )
    LOCAL i
    LOCAL nIdx

    DEFAULT nFromIdx TO 1

    cChar := Upper( cChar )

    // Empezar la busqueda desde nFromIdx (incluyendo este) hasta el final,
    // y luego dar la vuelta hasta nFromIdx-1
    FOR i := 0 TO nLen - 1

        nIdx := nFromIdx + i
        IF nIdx > nLen
            nIdx -= nLen
        ENDIF

        IF Left( Upper( ::Label( nIdx ) ), 1 ) == cChar
            RETURN nIdx
        ENDIF

    NEXT

RETURN 0


// ----------------------------------------------------------------------------
// Pintado del control (estado cerrado)
// ----------------------------------------------------------------------------
METHOD Paint() CLASS TCombo

    LOCAL cCol
    LOCAL nWidth
    LOCAL cText
    LOCAL cShow

    IF ! ::lVisible
        RETURN NIL
    ENDIF

    cCol   := If( ::lFocused, CLR_GET_FOC, CLR_GET )
    nWidth := ::nRight - ::nLeft + 1

    // Texto: la etiqueta de la opcion actual, recortada al ancho - 2
    // (los 2 ultimos caracteres son el indicador desplegable)
    cText := ::Label( ::nSelected )
    cShow := PadR( cText, nWidth - 2 ) + Chr(31) + " "
    // Chr(31) es la flecha hacia abajo en la pagina ASCII clasica.
    // Nota: si tu codepage no la representa bien, puedes usar "v"

    ::Lock()

    ::DrawRecessed()
    ::DrawText( 0, 0, cShow, cCol )

    // Cursor apagado: el combo no es editable carnacter a caracter
    GfxCursor( SC_NONE )

    ::Unlock()

RETURN NIL


// ----------------------------------------------------------------------------
// Teclas en estado cerrado
// ----------------------------------------------------------------------------
METHOD HandleKey( nKey ) CLASS TCombo

    LOCAL nFound
    LOCAL cChr

    // Apertura de lista
    IF nKey == K_F4 .OR. nKey == K_SPACE .OR. nKey == K_ALT_DOWN
        ::Open()
        RETURN .T.
    ENDIF

    // Navegacion entre controles -> no consumir
    IF nKey == K_TAB    .OR. nKey == K_SH_TAB .OR. ;
       nKey == K_ENTER .OR. nKey == K_UP     .OR. nKey == K_DOWN
        RETURN .F.
    ENDIF

    // Busqueda incremental: cualquier letra/digito imprimible
    IF nKey >= 32 .AND. nKey <= 255

        cChr := Chr( nKey )

        nFound := ::FindByPrefix( cChr, ::nSelected + 1 )

        IF nFound > 0
            ::SetIndex( nFound )
            ::Paint()
        ENDIF

        RETURN .T.
    ENDIF

RETURN .F.


// ----------------------------------------------------------------------------
// Despliega la lista y gestiona el bucle interno de seleccion
// ----------------------------------------------------------------------------
METHOD Open() CLASS TCombo

    LOCAL nTotal
    LOCAL nVisible
    LOCAL nT, nL, nB, nR
    LOCAL nWidth
    LOCAL nCur            // posicion actual seleccionada (durante navegacion)
    LOCAL nTop            // primer indice visible (para scroll)
    LOCAL lExit
    LOCAL lAccept
    LOCAL nKey
    LOCAL i, nFila
    LOCAL cTxt
    LOCAL cCol
    LOCAL nFound
    LOCAL cChr

    nTotal := Len( ::aOptions )

    IF nTotal == 0
        RETURN Self
    ENDIF

    nVisible := Min( nTotal, ::nMaxList )
    nWidth   := ::nRight - ::nLeft + 1

    // Posicion de la lista: justo debajo del control
    nT := ::nBottom + 1
    nL := ::nLeft
    nB := nT + nVisible - 1
    nR := ::nRight

    // Si la lista no cabe abajo, la mostramos arriba
    IF nB >= GfxMaxRow() - 1
        nB := ::nTop - 1
        nT := nB - nVisible + 1
    ENDIF

    // Estado inicial: cursor sobre la opcion seleccionada actual
    nCur := Max( ::nSelected, 1 )

    // Calcular nTop para que nCur quede visible
    IF nCur <= nVisible
        nTop := 1
    ELSEIF nCur > nTotal - nVisible
        nTop := nTotal - nVisible + 1
    ELSE
        nTop := nCur - Int( nVisible / 2 )
    ENDIF

    lExit   := .F.
    lAccept := .F.

    DO WHILE !lExit

        // ---- Repintado de la lista ----
        ::Lock()

        GfxClear( nT, nL, nB, nR, CLR_GET )
        GfxRecessed( nT, nL, nB, nR )

        FOR i := 0 TO nVisible - 1

            nFila := nTop + i

            IF nFila > nTotal
                EXIT
            ENDIF

            cTxt := PadR( ::Label( nFila ), nWidth )

            cCol := If( nFila == nCur, CLR_GET_FOC, CLR_GET )

            GfxText( nT + i, nL, cTxt, cCol )

        NEXT

        ::Unlock()

        // ---- Espera de tecla ----
        nKey := Inkey( 0 )

        DO CASE

        CASE nKey == K_ESC .OR. nKey == 27
            lExit := .T.

        CASE nKey == K_ENTER .OR. nKey == 13
            lAccept := .T.
            lExit   := .T.

        CASE nKey == K_UP
            IF nCur > 1
                nCur--
                IF nCur < nTop
                    nTop := nCur
                ENDIF
            ENDIF

        CASE nKey == K_DOWN
            IF nCur < nTotal
                nCur++
                IF nCur >= nTop + nVisible
                    nTop := nCur - nVisible + 1
                ENDIF
            ENDIF

        CASE nKey == K_PGUP
            nCur := Max( 1, nCur - nVisible )
            nTop := Max( 1, nTop - nVisible )

        CASE nKey == K_PGDN
            nCur := Min( nTotal, nCur + nVisible )
            IF nCur >= nTop + nVisible
                nTop := Min( nTotal - nVisible + 1, nTop + nVisible )
            ENDIF

        CASE nKey == K_HOME
            nCur := 1
            nTop := 1

        CASE nKey == K_END
            nCur := nTotal
            nTop := Max( 1, nTotal - nVisible + 1 )

        CASE nKey == K_F4 .OR. nKey == K_ALT_DOWN
            // F4 vuelve a cerrar la lista (toggle)
            lExit := .T.

        CASE nKey >= 32 .AND. nKey <= 255
            // Busqueda incremental
            cChr := Chr( nKey )
            nFound := ::FindByPrefix( cChr, nCur + 1 )

            IF nFound > 0
                nCur := nFound
                IF nCur < nTop
                    nTop := nCur
                ELSEIF nCur >= nTop + nVisible
                    nTop := nCur - nVisible + 1
                ENDIF
            ENDIF

        ENDCASE

    ENDDO

    // ---- Aplicar seleccion si fue ENTER ----
    IF lAccept
        ::SetIndex( nCur )
    ENDIF

    // ---- Cierre de la lista ----
    //
    // En esta version de GTWVG, Wvt_SaveScreen / Wvt_RestScreen NO
    // restauran la capa grafica WVG (los relieves Recessed/Raised),
    // solo los caracteres.  Por eso si confiabamos en Restore solo,
    // el rectangulo cian de la lista quedaba pintado en pantalla.
    //
    // Solucion robusta: invalidamos el area (limpia capa grafica)
    // y pedimos al TWindow padre que se repinte por completo.  El
    // TWindow tiene su propio xBackScr y sabe redibujarse incluyendo
    // marco, sombra, fondo y todos los hijos -> el efecto neto es que
    // la lista desaparece y la ventana queda intacta.

    GfxInvalidate( nT - 1, nL - 1, nB + 2, nR + 3 )

    IF ::oParent != NIL
        BEGIN SEQUENCE
            ::oParent:Refresh()
        RECOVER
            // Si el padre no es un TWindow, al menos repintamos este combo
            ::Paint()
        END SEQUENCE
    ELSE
        ::Paint()
    ENDIF

RETURN Self
