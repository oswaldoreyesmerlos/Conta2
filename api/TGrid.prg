#include "OOp.ch"

// ============================================================================
// CLASE: TGrid
// ----------------------------------------------------------------------------
// Grid de visualizacion y navegacion de datos en formato tabular.
//
// CARACTERISTICAS V0.1
//   - Solo lectura dentro del grid (no edicion inline).
//   - Datos en array (modo TTable se anyadira en V0.2).
//   - Columnas con codeblock bGetVal (permite columnas calculadas).
//   - Navegacion: flechas, PgUp/PgDn, Home/End.
//   - Busqueda incremental por una columna definida (nSeekCol).
//   - ENTER y F2 -> bEnter (editar fila actual).
//   - Flecha abajo en ultima fila NO vacia -> bInsert (anyadir).
//   - TAB -> sale del grid al siguiente control de la ventana.
//   - NO hay tecla DEL (anulacion via formulario de edicion).
//
// USO
//   oGrid := TGrid():New( nT, nL, nB, nR, oWindow )
//   oGrid:aData    := aLineas
//   oGrid:nSeekCol := 1                    // busqueda por col 1 (codigo)
//   oGrid:bEnter   := { |g| EditarLinea( g:CurrentRow() ) }
//   oGrid:bInsert  := { |g| AnyadirLinea( g ) }
//
//   oGrid:AddColumn( "Codigo",   6, "@!",         { |a| a[1] } )
//   oGrid:AddColumn( "Articulo", 25, "@!",        { |a| a[2] } )
//   oGrid:AddColumn( "Cant",     6, "999",        { |a| a[3] } )
//   oGrid:AddColumn( "Precio",   8, "999,999.99", { |a| a[4] } )
//   oGrid:AddColumn( "Subtot",  10, "9,999,999.99", { |a| a[3]*a[4] } )
//
//   oWindow:AddCtrl( oGrid )
// ============================================================================

CLASS TGrid FROM TControl

    DATA aColumns       INIT {}      // Array de definiciones de columna
    DATA aData          INIT {}      // Array con las filas de datos

    DATA nTopRow        INIT 1       // Indice de la primera fila visible
    DATA nCurRow        INIT 1       // Indice de la fila actualmente seleccionada
    DATA nVisibleRows   INIT 0       // Filas visibles dentro del grid (calculado)

    // Busqueda incremental
    DATA nSeekCol       INIT 1       // Columna por la que se busca
    DATA cSeekBuf       INIT ""      // Buffer acumulado de busqueda
    DATA nSeekTime      INIT 0       // Marca de tiempo del ultimo caracter
    DATA nSeekTimeout   INIT 1.5     // Timeout busqueda incremental (segundos)

    // Codeblocks de accion (todos opcionales)
    DATA bEnter                      // ENTER/F2 -> editar fila actual
    DATA bInsert                     // Flecha abajo en ult. fila no vacia
    DATA bChange                     // Notificacion de cambio de fila
    DATA bRowEmpty                   // Detector de fila vacia (override)

    METHOD New( nT, nL, nB, nR, oPar )

    METHOD AddColumn( cTitle, nWidth, cPicture, bGetVal )

    METHOD Paint()
    METHOD HandleKey( nKey )

    // Navegacion
    METHOD GoTop()
    METHOD GoBottom()
    METHOD GoUp()
    METHOD GoDown()
    METHOD PageUp()
    METHOD PageDown()

    // Helpers de acceso a fila/dato
    METHOD CurrentRow()
    METHOD RowCount()    INLINE Len( ::aData )
    METHOD IsRowEmpty( nRow )

    // Helpers de pintado
    METHOD PaintHeader()
    METHOD PaintRow( nRowIdx, lFocused )
    METHOD ColPos( nCol )
    METHOD CalcVisibleRows()

    // Busqueda
    METHOD SeekChar( cChar )
    METHOD ResetSeek() INLINE ( ::cSeekBuf := "", ::nSeekTime := 0 )

ENDCLASS



// ----------------------------------------------------------------------------
METHOD New( nT, nL, nB, nR, oPar ) CLASS TGrid

    ::Super:New( nT, nL, nB, nR, oPar )

    ::lTabStop := .T.                // Recibe foco con TAB

    ::aColumns  := {}
    ::aData     := {}

    ::nTopRow   := 1
    ::nCurRow   := 1
    ::nSeekCol  := 1
    ::cSeekBuf  := ""

RETURN Self



// ----------------------------------------------------------------------------
// AddColumn
// ----------------------------------------------------------------------------
// Anyade una definicion de columna al grid.
//
// PARAMETROS
//   cTitle   : texto de cabecera (string)
//   nWidth   : ancho en columnas/caracteres (numero)
//   cPicture : picture de visualizacion (string).  Si NIL o "", se usa
//              representacion por defecto segun el tipo del valor.
//   bGetVal  : codeblock { |aRow| ... } que recibe la fila y devuelve
//              el valor a mostrar.  Permite columnas calculadas.
// ----------------------------------------------------------------------------
METHOD AddColumn( cTitle, nWidth, cPicture, bGetVal ) CLASS TGrid

    DEFAULT cTitle   TO ""
    DEFAULT nWidth   TO 10
    DEFAULT cPicture TO ""

    AAdd( ::aColumns, { cTitle, nWidth, cPicture, bGetVal } )

RETURN Self



// ----------------------------------------------------------------------------
// CalcVisibleRows
// ----------------------------------------------------------------------------
// Calcula cuantas filas de datos caben en el area del grid:
//   - Linea de cabecera: 1 fila (nTop)
//   - Linea separadora bajo cabecera: 1 fila (nTop+1)
//   - Filas de datos: desde nTop+2 hasta nBottom-1
//   - Linea inferior: nBottom (borde)
// ----------------------------------------------------------------------------
METHOD CalcVisibleRows() CLASS TGrid
    ::nVisibleRows := Max( 0, ::nBottom - ::nTop - 2 )
RETURN ::nVisibleRows



// ----------------------------------------------------------------------------
// ColPos
// ----------------------------------------------------------------------------
// Devuelve la columna absoluta de pantalla donde empieza la columna nCol
// del grid.  Suma los anchos de las columnas anteriores + 1 (borde izq).
// ----------------------------------------------------------------------------
METHOD ColPos( nCol ) CLASS TGrid

    LOCAL nPos := ::nLeft + 1        // empieza tras el borde izquierdo
    LOCAL i

    FOR i := 1 TO nCol - 1
        nPos += ::aColumns[ i, COL_WIDTH ] + 1     // +1 separador
    NEXT

RETURN nPos



// ----------------------------------------------------------------------------
// CurrentRow - devuelve la fila actual (array, objeto, lo que sea aData[i])
// ----------------------------------------------------------------------------
METHOD CurrentRow() CLASS TGrid

    IF ::nCurRow >= 1 .AND. ::nCurRow <= Len( ::aData )
        RETURN ::aData[ ::nCurRow ]
    ENDIF

RETURN NIL



// ----------------------------------------------------------------------------
// IsRowEmpty - decide si una fila esta vacia
// ----------------------------------------------------------------------------
// Si el usuario definio bRowEmpty, lo usa.  Si no, asume que la primera
// columna vacia/cero/falsa indica fila vacia.
//
// En grids editables de detalle suele convenir definir bRowEmpty propio.
// La heuristica por defecto esta pensada para listados simples, no para
// lineas con numero/autocodigo en la primera columna.
// ----------------------------------------------------------------------------
METHOD IsRowEmpty( nRow ) CLASS TGrid

    LOCAL aRow
    LOCAL xVal

    IF nRow < 1 .OR. nRow > Len( ::aData )
        RETURN .T.
    ENDIF

    aRow := ::aData[ nRow ]

    IF ::bRowEmpty != NIL
        RETURN EvalSafe( ::bRowEmpty, "TGrid:bRowEmpty", aRow ) == .T.
    ENDIF

    // Heuristica por defecto: primera columna vacia/cero/false
    IF Len( ::aColumns ) > 0
        xVal := EvalSafe( ::aColumns[ 1, COL_GETVAL ], "TGrid:COL_GETVAL", aRow )
        DO CASE
        CASE ValType( xVal ) == "C"
             RETURN Empty( xVal )
        CASE ValType( xVal ) == "N"
             RETURN xVal == 0
        CASE ValType( xVal ) == "L"
             RETURN ! xVal
        CASE ValType( xVal ) == "D"
             RETURN Empty( xVal )
        ENDCASE
    ENDIF

RETURN .F.



// ----------------------------------------------------------------------------
// Paint
// ----------------------------------------------------------------------------
// Pinta el grid completo: marco recessed, cabecera, filas, scroll si hace
// falta.
// ----------------------------------------------------------------------------
METHOD Paint() CLASS TGrid

    LOCAL i, nRowIdx
    LOCAL nMaxRows

    IF !::lVisible
        RETURN NIL
    ENDIF

    ::Lock()

    ::CalcVisibleRows()

    // [1] Limpieza del area completa - fondo gris claro
    GfxClear( ::nTop, ::nLeft, ::nBottom, ::nRight, CLR_WINDOW )

    // [2] Cabecera con titulos de columna (fondo azul)
    ::PaintHeader()

    // [3] Linea separadora bajo cabecera (caracteres horizontales)
    GfxText( ::nTop + 1, ::nLeft, Replicate( "-", ::nRight - ::nLeft + 1 ), ;
             CLR_WINDOW )

    // [4] Filas visibles
    //
    //     Cada fila se pinta en uno de tres estados:
    //       0 -> normal (no es la fila seleccionada)
    //       1 -> seleccionada PERO el grid no tiene foco (color tenue)
    //       2 -> seleccionada Y el grid tiene foco (color de foco)
    //
    //     Esto da feedback visual claro al usuario:
    //       - Cuando navega por el grid: fila cian fuerte.
    //       - Cuando sale del grid con TAB: fila sigue marcada en tono
    //         suave para que se vea cual sera el registro afectado si
    //         pulsa botones como [F2] EDITAR o [F5] NUEVO.
    nMaxRows := Min( ::nVisibleRows, Len( ::aData ) - ::nTopRow + 1 )

    FOR i := 1 TO ::nVisibleRows
        nRowIdx := ::nTopRow + i - 1

        IF nRowIdx <= Len( ::aData )

            DO CASE
            CASE nRowIdx != ::nCurRow
                ::PaintRow( nRowIdx, 0 )            // normal
            CASE ::lFocused
                ::PaintRow( nRowIdx, 2 )            // seleccionada con foco
            OTHERWISE
                ::PaintRow( nRowIdx, 1 )            // seleccionada sin foco
            ENDCASE

        ELSE
            // Fila inexistente -> linea vacia con fondo de ventana
            GfxClear( ::nTop + 1 + i, ::nLeft + 1, ;
                      ::nTop + 1 + i, ::nRight - 1, ;
                      CLR_WINDOW )
        ENDIF
    NEXT

    // [5] Marco recessed alrededor de todo el area (encima de los caracteres)
    IF ::lFocused
        GfxRaised( ::nTop, ::nLeft, ::nBottom, ::nRight )
    ELSE
        GfxRecessed( ::nTop, ::nLeft, ::nBottom, ::nRight )
    ENDIF

    GfxCursor( SC_NONE )

    ::Unlock()

RETURN NIL



// ----------------------------------------------------------------------------
// PaintHeader - pinta la fila de cabecera con los titulos de columna
// ----------------------------------------------------------------------------
METHOD PaintHeader() CLASS TGrid

    LOCAL i, nCol, nWid, cTit

    // Fondo azul de toda la fila de cabecera
    GfxClear( ::nTop, ::nLeft, ::nTop, ::nRight, CLR_GRID_HDR )

    // Pintar cada titulo en su posicion
    FOR i := 1 TO Len( ::aColumns )
        nCol := ::ColPos( i )
        nWid := ::aColumns[ i, COL_WIDTH ]
        cTit := ::aColumns[ i, COL_TITLE ]

        // Recortar/ajustar al ancho de la columna
        cTit := PadR( cTit, nWid )

        GfxText( ::nTop, nCol, cTit, CLR_GRID_HDR )
    NEXT

RETURN NIL



// ----------------------------------------------------------------------------
// PaintRow - pinta una fila de datos del grid
// ----------------------------------------------------------------------------
// PARAMETROS
//   nRowIdx : indice de la fila en aData
//   nState  : estado visual:
//               0 = normal (no seleccionada)
//               1 = seleccionada PERO el grid no tiene foco (tono suave)
//               2 = seleccionada Y el grid tiene foco (color de foco fuerte)
// ----------------------------------------------------------------------------
METHOD PaintRow( nRowIdx, nState ) CLASS TGrid

    LOCAL nScrRow                    // fila de pantalla
    LOCAL aRow                       // fila de datos
    LOCAL i, nCol, nWid, cPic, bGet
    LOCAL xVal, cTxt
    LOCAL cClr

    DEFAULT nState TO 0

    // Calcular fila de pantalla: cabecera (nTop) + separador (nTop+1) +
    // offset de la fila visible (nRowIdx - nTopRow)
    nScrRow := ::nTop + 2 + ( nRowIdx - ::nTopRow )

    // Color segun estado
    DO CASE
    CASE nState == 2
         cClr := CLR_GRID_SEL                       // seleccionada + foco
    CASE nState == 1
         cClr := CLR_GRID_INA                       // seleccionada sin foco
    OTHERWISE
         cClr := CLR_WINDOW                         // normal
    ENDCASE

    // Limpiar la fila completa con el color
    GfxClear( nScrRow, ::nLeft + 1, nScrRow, ::nRight - 1, cClr )

    aRow := ::aData[ nRowIdx ]

    // Pintar cada celda
    FOR i := 1 TO Len( ::aColumns )
        nCol := ::ColPos( i )
        nWid := ::aColumns[ i, COL_WIDTH ]
        cPic := ::aColumns[ i, COL_PICTURE ]
        bGet := ::aColumns[ i, COL_GETVAL ]

        // Obtener valor via codeblock
        IF bGet != NIL
            xVal := EvalSafe( bGet, "TGrid:COL_GETVAL", aRow )
        ELSE
            xVal := ""
        ENDIF

        // Formatear segun picture o tipo
        IF !Empty( cPic )
            cTxt := Transform( xVal, cPic )
        ELSE
            cTxt := AllTrim( hb_CStr( xVal ) )
        ENDIF

        // Recortar/ajustar al ancho
        cTxt := PadR( Left( cTxt, nWid ), nWid )

        GfxText( nScrRow, nCol, cTxt, cClr )
    NEXT

RETURN NIL



// ----------------------------------------------------------------------------
// HandleKey - despacho de teclas
// ----------------------------------------------------------------------------
METHOD HandleKey( nKey ) CLASS TGrid

    LOCAL lHandled := .T.
    LOCAL cChar

    DO CASE

    CASE nKey == K_UP
         ::GoUp()

    CASE nKey == K_DOWN
         ::GoDown()

    CASE nKey == K_PGUP
         ::PageUp()

    CASE nKey == K_PGDN
         ::PageDown()

    CASE nKey == K_HOME .OR. nKey == K_CTRL_PGUP
         ::GoTop()

    CASE nKey == K_END  .OR. nKey == K_CTRL_PGDN
         ::GoBottom()

    CASE nKey == K_ENTER .OR. nKey == K_F2
         IF ::bEnter != NIL .AND. ::nCurRow >= 1 .AND. ;
            ::nCurRow <= Len( ::aData )
            EvalSafe( ::bEnter, "TGrid:bEnter", Self )
            ::Paint()
         ENDIF

    CASE nKey >= 32 .AND. nKey <= 255
         // Caracter imprimible -> busqueda incremental
         cChar := Chr( nKey )
         ::SeekChar( cChar )

    OTHERWISE
         lHandled := .F.

    ENDCASE

RETURN lHandled



// ----------------------------------------------------------------------------
// GoUp - mueve a la fila anterior
// ----------------------------------------------------------------------------
METHOD GoUp() CLASS TGrid

    ::ResetSeek()

    IF ::nCurRow > 1
        ::nCurRow--

        // Si salio del area visible, ajustar nTopRow
        IF ::nCurRow < ::nTopRow
            ::nTopRow := ::nCurRow
        ENDIF

        ::Paint()

        IF ::bChange != NIL
            EvalSafe( ::bChange, "TGrid:bChange", Self )
        ENDIF
    ENDIF

RETURN Self



// ----------------------------------------------------------------------------
// GoDown - mueve a la fila siguiente.  Si esta en la ultima y no esta
// vacia, llama a bInsert para que el usuario anyada nueva fila.
// ----------------------------------------------------------------------------
METHOD GoDown() CLASS TGrid

    ::ResetSeek()

    IF ::nCurRow < Len( ::aData )

        ::nCurRow++

        // Si salio del area visible, ajustar nTopRow
        IF ::nCurRow > ::nTopRow + ::nVisibleRows - 1
            ::nTopRow := ::nCurRow - ::nVisibleRows + 1
        ENDIF

        ::Paint()

        IF ::bChange != NIL
            EvalSafe( ::bChange, "TGrid:bChange", Self )
        ENDIF

    ELSEIF ::nCurRow == Len( ::aData ) .AND. Len( ::aData ) > 0

        // Estamos en la ultima fila.  Si NO esta vacia y hay bInsert,
        // llamar al codeblock que anyade nueva fila.
        IF !::IsRowEmpty( ::nCurRow ) .AND. ::bInsert != NIL
            EvalSafe( ::bInsert, "TGrid:bInsert", Self )

            // Tras anyadir, posicionarse en la nueva ultima fila
            ::nCurRow := Len( ::aData )

            IF ::nCurRow > ::nTopRow + ::nVisibleRows - 1
                ::nTopRow := ::nCurRow - ::nVisibleRows + 1
            ENDIF

            ::Paint()
        ENDIF

    ELSEIF Len( ::aData ) == 0 .AND. ::bInsert != NIL

        // Grid completamente vacio: pulsar abajo anyade primera fila
        EvalSafe( ::bInsert, "TGrid:bInsert", Self )

        IF Len( ::aData ) > 0
            ::nCurRow := 1
            ::nTopRow := 1
            ::Paint()
        ENDIF

    ENDIF

RETURN Self



// ----------------------------------------------------------------------------
METHOD GoTop() CLASS TGrid

    ::ResetSeek()

    IF Len( ::aData ) > 0
        ::nCurRow := 1
        ::nTopRow := 1
        ::Paint()

        IF ::bChange != NIL
            EvalSafe( ::bChange, "TGrid:bChange", Self )
        ENDIF
    ENDIF

RETURN Self



// ----------------------------------------------------------------------------
METHOD GoBottom() CLASS TGrid

    ::ResetSeek()

    IF Len( ::aData ) > 0
        ::nCurRow := Len( ::aData )
        ::nTopRow := Max( 1, ::nCurRow - ::nVisibleRows + 1 )
        ::Paint()

        IF ::bChange != NIL
            EvalSafe( ::bChange, "TGrid:bChange", Self )
        ENDIF
    ENDIF

RETURN Self



// ----------------------------------------------------------------------------
METHOD PageUp() CLASS TGrid

    ::ResetSeek()

    IF Len( ::aData ) == 0
        RETURN Self
    ENDIF

    ::nCurRow := Max( 1, ::nCurRow - ::nVisibleRows )
    ::nTopRow := Max( 1, ::nTopRow - ::nVisibleRows )
    ::Paint()

    IF ::bChange != NIL
        EvalSafe( ::bChange, "TGrid:bChange", Self )
    ENDIF

RETURN Self



// ----------------------------------------------------------------------------
METHOD PageDown() CLASS TGrid

    ::ResetSeek()

    IF Len( ::aData ) == 0
        RETURN Self
    ENDIF

    ::nCurRow := Min( Len( ::aData ), ::nCurRow + ::nVisibleRows )
    ::nTopRow := Min( Max( 1, Len( ::aData ) - ::nVisibleRows + 1 ), ;
                      ::nTopRow + ::nVisibleRows )
    ::Paint()

    IF ::bChange != NIL
        EvalSafe( ::bChange, "TGrid:bChange", Self )
    ENDIF

RETURN Self



// ----------------------------------------------------------------------------
// SeekChar - acumula un caracter en el buffer de busqueda y posiciona
// ----------------------------------------------------------------------------
// Funcionamiento: cada tecla imprimible se anyade a cSeekBuf.  Despues
// recorre aData buscando una fila cuyo valor de la columna nSeekCol
// EMPIECE por cSeekBuf (case-insensitive).  Si encuentra, posiciona alli.
//
// Si pasan mas de 1.5 segundos sin teclear, el buffer se resetea (la
// proxima tecla empieza nueva busqueda).
// ----------------------------------------------------------------------------
METHOD SeekChar( cChar ) CLASS TGrid

    LOCAL nNow := Seconds()
    LOCAL bGet
    LOCAL i, xVal, cVal
    LOCAL nFound := 0

    // Reset si paso el timeout desde la ultima tecla
    IF nNow - ::nSeekTime > ::nSeekTimeout
        ::cSeekBuf := ""
    ENDIF

    ::cSeekBuf  += Upper( cChar )
    ::nSeekTime := nNow

    // Validar que la columna de busqueda existe
    IF ::nSeekCol < 1 .OR. ::nSeekCol > Len( ::aColumns )
        RETURN Self
    ENDIF

    bGet := ::aColumns[ ::nSeekCol, COL_GETVAL ]

    IF bGet == NIL
        RETURN Self
    ENDIF

    // Recorrer aData buscando coincidencia
    FOR i := 1 TO Len( ::aData )
        xVal := EvalSafe( bGet, "TGrid:COL_GETVAL", ::aData[ i ] )
        cVal := Upper( AllTrim( hb_CStr( xVal ) ) )

        IF Left( cVal, Len( ::cSeekBuf ) ) == ::cSeekBuf
            nFound := i
            EXIT
        ENDIF
    NEXT

    IF nFound > 0
        ::nCurRow := nFound

        // Ajustar nTopRow si quedo fuera de vista
        IF ::nCurRow < ::nTopRow
            ::nTopRow := ::nCurRow
        ELSEIF ::nCurRow > ::nTopRow + ::nVisibleRows - 1
            ::nTopRow := ::nCurRow - ::nVisibleRows + 1
        ENDIF

        ::Paint()

        IF ::bChange != NIL
            EvalSafe( ::bChange, "TGrid:bChange", Self )
        ENDIF
    ENDIF

RETURN Self
