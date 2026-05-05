#include "OOp.ch"

// ============================================================================
// TestGrid.prg - Ejemplo de uso de TGrid V0.1
// ----------------------------------------------------------------------------
// Simula un formulario de PEDIDO con:
//   - Cabecera: cliente, fecha, observaciones (TGets).
//   - Detalle: lineas del pedido en un TGrid.
//
// El usuario navega por las lineas con las flechas.  Pulsa ENTER (o F2)
// para editar una linea -> abre formulario modal con TGets.  Pulsa flecha
// abajo en la ultima linea no vacia -> abre formulario para anyadir.
//
// Las columnas del grid incluyen una calculada (Subtotal = Cant * Precio).
// ============================================================================

PROCEDURE Main()
    LOCAL bErrOld

    bErrOld := ErrorBlock( { |oErr| ErrSys( oErr ) } )

    InitApp( 40, 132 )

    FormPedido()

    ErrorBlock( bErrOld )
RETURN



// ============================================================================
// FormPedido - formulario principal con cabecera y detalle
// ============================================================================
FUNCTION FormPedido()

    LOCAL oWin
    LOCAL oLbCli, oLbFec, oLbObs, oLbLin
    LOCAL oGetCli, oGetFec, oGetObs
    LOCAL oGrid
    LOCAL oBtnNew, oBtnEdt, oBtnOk, oBtnCan

    // Datos de cabecera
    LOCAL cCliente := PadR( "12345 - INFORMATICA NORTE SL", 35 )
    LOCAL dFecha   := Date()
    LOCAL cObserv  := Space( 50 )

    // Datos de detalle (lineas del pedido)
    // Cada fila: { cCodigo, cArticulo, nCant, nPrecio }
    LOCAL aLineas := { ;
        { "0001", PadR( "Disco SSD 1TB Samsung 870 EVO",      30 ), 2, 89.50  }, ;
        { "0002", PadR( "RAM DDR4 16GB Kingston 3200MHz",     30 ), 4, 45.00  }, ;
        { "0003", PadR( "CPU Intel Core i5 12400 6-core",     30 ), 1, 199.99 }, ;
        { "0004", PadR( "Placa base ASRock B660M Pro RS",     30 ), 1, 129.00 }, ;
        { "0005", PadR( "Tarjeta grafica RTX 3060 12GB",      30 ), 1, 379.00 }, ;
        { "0006", PadR( "Fuente Corsair RM750x 750W",         30 ), 1, 119.50 }, ;
        { "0007", PadR( "Caja ATX NZXT H510 Negra",           30 ), 1,  85.00 }, ;
        { "0008", PadR( "Cooler Noctua NH-D15",               30 ), 1, 105.00 }  }

    // -- Ventana principal
    oWin := TWindow():New( 04, 10, 35, 120, "PEDIDO 2026/000123" )

    // === CABECERA: TGets de cliente, fecha, observaciones ===
    oLbCli  := TLabel():New( 02, 02, "Cliente.....:", oWin )
    oLbFec  := TLabel():New( 04, 02, "Fecha.......:", oWin )
    oLbObs  := TLabel():New( 06, 02, "Observac....:", oWin )

    oGetCli := TGet():New( 02, 16, cCliente, "@!", oWin )
    oGetFec := TGet():New( 04, 16, dFecha,   "",   oWin )
    oGetObs := TGet():New( 06, 16, cObserv,  "@!", oWin )

    // === SEPARADOR VISUAL ===
    oLbLin  := TLabel():New( 08, 02, ;
        "Lineas del pedido (ENTER/F2 editar, flecha abajo en ult. fila anyade):", ;
        oWin )

    // === DETALLE: TGrid con las lineas ===
    oGrid := TGrid():New( 09, 02, 26, 108, oWin )

    oGrid:aData    := aLineas
    oGrid:nSeekCol := 1                                  // busqueda por codigo

    oGrid:AddColumn( "Codigo",   6, "@!",            { |a| a[ 1 ] } )
    oGrid:AddColumn( "Articulo", 30, "@!",           { |a| a[ 2 ] } )
    oGrid:AddColumn( "Cant",      6, "9,999",        { |a| a[ 3 ] } )
    oGrid:AddColumn( "Precio",   12, "999,999.99",   { |a| a[ 4 ] } )
    oGrid:AddColumn( "Subtotal", 13, "9,999,999.99", { |a| a[ 3 ] * a[ 4 ] } )

    // ENTER/F2 -> editar fila actual
    oGrid:bEnter := { |g| EditLine( g:CurrentRow() ) }

    // Flecha abajo en ultima fila no vacia -> anyadir nueva fila
    oGrid:bInsert := { |g| InsertLine( g ) }

    // Detector de fila vacia: codigo vacio = fila vacia
    oGrid:bRowEmpty := { |a| Empty( a[ 1 ] ) }

    // === BOTONES INFERIORES ===
    oBtnNew := TButton():New( 28, 03, 28, 18, oWin, "[F5] NUEVO",   ;
                              { || InsertLine( oGrid ), oGrid:Paint() } )

    oBtnEdt := TButton():New( 28, 21, 28, 36, oWin, "[F2] EDITAR",  ;
                              { || EditLine( oGrid:CurrentRow() ), oGrid:Paint() } )

    oBtnOk  := TButton():New( 28, 70, 28, 90, oWin, "ACEPTAR PEDIDO", ;
                              { || oWin:Close() } )

    oBtnCan := TButton():New( 28, 93, 28, 108, oWin, "CANCELAR",   ;
                              { || oWin:Close() } )

    // -- Registro de controles
    oWin:AddCtrl( oLbCli  )
    oWin:AddCtrl( oLbFec  )
    oWin:AddCtrl( oLbObs  )
    oWin:AddCtrl( oLbLin  )
    oWin:AddCtrl( oGetCli )
    oWin:AddCtrl( oGetFec )
    oWin:AddCtrl( oGetObs )
    oWin:AddCtrl( oGrid   )
    oWin:AddCtrl( oBtnNew )
    oWin:AddCtrl( oBtnEdt )
    oWin:AddCtrl( oBtnOk  )
    oWin:AddCtrl( oBtnCan )

    oWin:Run()

RETURN NIL



// ============================================================================
// EditLine - abre formulario modal para editar la linea pasada
// La linea se modifica POR REFERENCIA (es un array).
// ============================================================================
FUNCTION EditLine( aLine )

    LOCAL oWin
    LOCAL oLbCod, oLbArt, oLbCnt, oLbPrc
    LOCAL oGetCod, oGetArt, oGetCnt, oGetPrc
    LOCAL oBtnOk, oBtnCan
    LOCAL lAccept := .F.

    // Variables temporales para el formulario (copia)
    LOCAL cCod := aLine[ 1 ]
    LOCAL cArt := aLine[ 2 ]
    LOCAL nCnt := aLine[ 3 ]
    LOCAL nPrc := aLine[ 4 ]

    oWin := TWindow():New( 12, 35, 26, 95, "EDITAR LINEA" )

    oLbCod  := TLabel():New( 02, 02, "Codigo....:",   oWin )
    oLbArt  := TLabel():New( 04, 02, "Articulo..:",   oWin )
    oLbCnt  := TLabel():New( 06, 02, "Cantidad..:",   oWin )
    oLbPrc  := TLabel():New( 08, 02, "Precio....:",   oWin )

    oGetCod := TGet():New( 02, 14, cCod, "@!",         oWin )
    oGetArt := TGet():New( 04, 14, cArt, "@!",         oWin )
    oGetCnt := TGet():New( 06, 14, nCnt, "9,999",      oWin )
    oGetPrc := TGet():New( 08, 14, nPrc, "999,999.99", oWin )

    oBtnOk  := TButton():New( 11, 12, 11, 26, oWin, "ACEPTAR",  ;
                              { || lAccept := .T., oWin:Close() } )

    oBtnCan := TButton():New( 11, 30, 11, 44, oWin, "CANCELAR", ;
                              { || oWin:Close() } )

    oWin:AddCtrl( oLbCod  )
    oWin:AddCtrl( oLbArt  )
    oWin:AddCtrl( oLbCnt  )
    oWin:AddCtrl( oLbPrc  )
    oWin:AddCtrl( oGetCod )
    oWin:AddCtrl( oGetArt )
    oWin:AddCtrl( oGetCnt )
    oWin:AddCtrl( oGetPrc )
    oWin:AddCtrl( oBtnOk  )
    oWin:AddCtrl( oBtnCan )

    oWin:Run()

    // Si acepto, escribir cambios de vuelta al array original
    IF lAccept
        aLine[ 1 ] := oGetCod:uVar
        aLine[ 2 ] := oGetArt:uVar
        aLine[ 3 ] := oGetCnt:uVar
        aLine[ 4 ] := oGetPrc:uVar
    ENDIF

RETURN lAccept



// ============================================================================
// InsertLine - anyade una nueva linea vacia al grid y la abre para edicion
// ============================================================================
FUNCTION InsertLine( oGrid )

    LOCAL aNueva
    LOCAL cNuevoCod
    LOCAL nMax := 0
    LOCAL i

    // Calcular siguiente codigo: maximo actual + 1, formato "9999"
    FOR i := 1 TO Len( oGrid:aData )
        nMax := Max( nMax, Val( oGrid:aData[ i, 1 ] ) )
    NEXT

    cNuevoCod := PadL( AllTrim( Str( nMax + 1 ) ), 4, "0" )

    aNueva := { cNuevoCod, PadR( "", 30 ), 0, 0 }

    AAdd( oGrid:aData, aNueva )

    // Abrir formulario para que el usuario rellene
    IF EditLine( aNueva )
        // Usuario acepto: la linea queda anyadida con sus datos
    ELSE
        // Usuario cancelo: quitar la linea recien anyadida
        ASize( oGrid:aData, Len( oGrid:aData ) - 1 )
    ENDIF

RETURN NIL
