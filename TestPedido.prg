#include "OOp.ch"

// ============================================================================
// TestPedido.prg - PROTOTIPO PROCEDURAL DE DOCUMENTO COMERCIAL
// ----------------------------------------------------------------------------
// Estructura tipica de cualquier documento de gestion (factura, pedido,
// albaran, presupuesto, asiento contable, ...):
//
//   CABECERA  -> datos generales del documento (cliente, fecha, ...)
//   DETALLE   -> N lineas (articulo, cantidad, precio, ...)
//   TOTALES   -> calculados a partir de las lineas (base, IVA, total)
//
// Este prototipo usa HASHES para representar cabecera y lineas, lo que
// permitira mas adelante abstraer una clase TDocument generica.
//
// CONVENCIONES PARA EVOLUCION FUTURA
//   - Toda la logica de NEGOCIO (calculo de totales, validaciones,
//     guardado) esta en funciones SEPARADAS de la UI.
//   - La UI (formularios, controles) tampoco contiene reglas de negocio.
//   - Asi sera trivial pasar a TDocument cuando llegue el momento.
// ============================================================================


// Tipo de IVA por defecto (mientras no haya configuracion real)
#define IVA_PCT     21


// ============================================================================
// Main
// ============================================================================
PROCEDURE Main()
    LOCAL bErrOld

    bErrOld := ErrorBlock( { |oErr| ErrSys( oErr ) } )

    InitApp( 40, 132 )

    GfxSetTitle( "AppGestion - TestPedido v1.0" )
    GfxSetIconRes( 100 )

    FormPedido()

    ErrorBlock( bErrOld )
RETURN



// ============================================================================
// FormPedido - formulario de pedido completo
// ============================================================================
FUNCTION FormPedido()

    LOCAL oWin
    LOCAL oLbCli, oLbFec, oLbObs, oLbLin, oLbTot
    LOCAL oGetCli, oGetFec, oGetObs
    LOCAL oGrid
    LOCAL oLbBas, oLbIva, oLbTtl
    LOCAL oGetBas, oGetIva, oGetTtl
    LOCAL oBtnNew, oBtnEdt, oBtnSav, oBtnCan

    // -------- DATOS DEL DOCUMENTO --------

    // Cabecera: hash con campos
    LOCAL hHeader := { ;
        "numero"   => "2026/000123", ;
        "cliente"  => PadR( "12345 - INFORMATICA NORTE SL", 35 ), ;
        "fecha"    => Date(), ;
        "observ"   => Space( 50 ) }

    // Lineas: array de hashes (cada hash = una linea)
    LOCAL aLines := DemoLines()

    // Totales: hash con campos calculados
    LOCAL hTotals := { ;
        "base"     => 0, ;
        "iva"      => 0, ;
        "total"    => 0 }

    // Calculo inicial
    CalcTotales( aLines, hTotals )

    // -------- VENTANA PRINCIPAL --------
    oWin := TWindow():New( 03, 08, 36, 122, "PEDIDO " + hHeader[ "numero" ] )

    // === [1] CABECERA ===
    oLbCli  := TLabel():New( 02, 02, "Cliente.....:", oWin )
    oLbFec  := TLabel():New( 04, 02, "Fecha.......:", oWin )
    oLbObs  := TLabel():New( 06, 02, "Observac....:", oWin )

    oGetCli := TGet():New( 02, 16, hHeader[ "cliente" ], "@!", oWin )
    oGetFec := TGet():New( 04, 16, hHeader[ "fecha"   ], "",   oWin )
    oGetObs := TGet():New( 06, 16, hHeader[ "observ"  ], "@!", oWin )

    // === [2] SEPARADOR + GRID DE LINEAS ===
    oLbLin  := TLabel():New( 08, 02, ;
        "Lineas (ENTER/F2 editar, flecha abajo en ult. fila anyade):", ;
        oWin )

    oGrid := TGrid():New( 09, 02, 23, 110, oWin )

    oGrid:aData    := aLines
    oGrid:nSeekCol := 1                                  // codigo

    oGrid:AddColumn( "Codigo",   6, "@!",            { |h| h[ "codigo"   ] } )
    oGrid:AddColumn( "Articulo", 30, "@!",           { |h| h[ "articulo" ] } )
    oGrid:AddColumn( "Cant",      6, "9,999",        { |h| h[ "cant"     ] } )
    oGrid:AddColumn( "Precio",   12, "999,999.99",   { |h| h[ "precio"   ] } )
    oGrid:AddColumn( "Subtotal", 13, "9,999,999.99", { |h| h[ "cant" ] * h[ "precio" ] } )

    // ENTER/F2 -> editar fila actual y recalcular totales
    oGrid:bEnter := { |g| EditLine( g:CurrentRow() ), ;
                          CalcTotales( aLines, hTotals ), ;
                          PintaTotales( oGetBas, oGetIva, oGetTtl, hTotals ) }

    // Flecha abajo en ultima fila no vacia -> anyadir nueva linea
    oGrid:bInsert := { |g| InsertLine( g ), ;
                           CalcTotales( aLines, hTotals ), ;
                           PintaTotales( oGetBas, oGetIva, oGetTtl, hTotals ) }

    // Detector de fila vacia
    oGrid:bRowEmpty := { |h| Empty( h[ "codigo" ] ) }

    // === [3] BLOQUE DE TOTALES ===
    oLbTot  := TLabel():New( 25, 02, "TOTALES:", oWin )

    oLbBas  := TLabel():New( 27, 02, "Base imponible.:", oWin )
    oLbIva  := TLabel():New( 27, 50, "IVA " + AllTrim( Str( IVA_PCT ) ) + "%:", oWin )
    oLbTtl  := TLabel():New( 28, 02, "TOTAL..........:", oWin )

    // Gets de totales: read-only (los recalcula la app, no el usuario).
    // Los pintamos con TGet pero los marcaremos como Disabled para que
    // no reciban foco de TAB.
    oGetBas := TGet():New( 27, 20, hTotals[ "base"  ], "9,999,999.99", oWin )
    oGetIva := TGet():New( 27, 60, hTotals[ "iva"   ], "9,999,999.99", oWin )
    oGetTtl := TGet():New( 28, 20, hTotals[ "total" ], "9,999,999.99", oWin )

    oGetBas:lEnabled := .F.
    oGetIva:lEnabled := .F.
    oGetTtl:lEnabled := .F.

    // === [4] BOTONES ===
    oBtnNew := TButton():New( 30, 03, 30, 18, oWin, "[F5] NUEVO",   ;
                              { || InsertLine( oGrid ), ;
                                   CalcTotales( aLines, hTotals ), ;
                                   PintaTotales( oGetBas, oGetIva, oGetTtl, hTotals ), ;
                                   oGrid:Paint() } )

    oBtnEdt := TButton():New( 30, 21, 30, 36, oWin, "[F2] EDITAR",  ;
                              { || EditLine( oGrid:CurrentRow() ), ;
                                   CalcTotales( aLines, hTotals ), ;
                                   PintaTotales( oGetBas, oGetIva, oGetTtl, hTotals ), ;
                                   oGrid:Paint() } )

    oBtnSav := TButton():New( 30, 70, 30, 90, oWin, "[F10] GUARDAR", ;
                              { || GuardarPedido( hHeader, aLines, hTotals ), ;
                                   oWin:Close() } )

    oBtnCan := TButton():New( 30, 93, 30, 108, oWin, "CANCELAR",   ;
                              { || oWin:Close() } )

    // === [5] REGISTRO DE CONTROLES ===
    oWin:AddCtrl( oLbCli  )
    oWin:AddCtrl( oLbFec  )
    oWin:AddCtrl( oLbObs  )
    oWin:AddCtrl( oLbLin  )
    oWin:AddCtrl( oLbTot  )
    oWin:AddCtrl( oLbBas  )
    oWin:AddCtrl( oLbIva  )
    oWin:AddCtrl( oLbTtl  )
    oWin:AddCtrl( oGetCli )
    oWin:AddCtrl( oGetFec )
    oWin:AddCtrl( oGetObs )
    oWin:AddCtrl( oGrid   )
    oWin:AddCtrl( oGetBas )
    oWin:AddCtrl( oGetIva )
    oWin:AddCtrl( oGetTtl )
    oWin:AddCtrl( oBtnNew )
    oWin:AddCtrl( oBtnEdt )
    oWin:AddCtrl( oBtnSav )
    oWin:AddCtrl( oBtnCan )

    oWin:Run()

RETURN NIL



// ============================================================================
// LOGICA DE NEGOCIO (separada de la UI)
// ============================================================================

// ----------------------------------------------------------------------------
// CalcTotales - recorre las lineas y calcula base/IVA/total
// ----------------------------------------------------------------------------
FUNCTION CalcTotales( aLines, hTotals )

    LOCAL nBase := 0

    AEval( aLines, ;
           { |h| nBase += h[ "cant" ] * h[ "precio" ] } )

    hTotals[ "base"  ] := nBase
    hTotals[ "iva"   ] := Round( nBase * IVA_PCT / 100, 2 )
    hTotals[ "total" ] := hTotals[ "base" ] + hTotals[ "iva" ]

RETURN NIL



// ----------------------------------------------------------------------------
// PintaTotales - actualiza los gets de totales con los valores nuevos
// ----------------------------------------------------------------------------
FUNCTION PintaTotales( oGetBas, oGetIva, oGetTtl, hTotals )

    oGetBas:uVar := hTotals[ "base"  ]
    oGetIva:uVar := hTotals[ "iva"   ]
    oGetTtl:uVar := hTotals[ "total" ]

    oGetBas:Refresh()
    oGetIva:Refresh()
    oGetTtl:Refresh()

RETURN NIL



// ----------------------------------------------------------------------------
// GuardarPedido - persistencia (TODO: integrar con TTable v0.2)
// ----------------------------------------------------------------------------
FUNCTION GuardarPedido( hHeader, aLines, hTotals )

    HB_SYMBOL_UNUSED( hHeader )
    HB_SYMBOL_UNUSED( aLines  )
    HB_SYMBOL_UNUSED( hTotals )

    // TODO: cuando TTable v0.2 este lista, aqui:
    //   1. RLock cabecera + Append en tabla cabeceras
    //   2. Loop AEval lines + Append en tabla lineas
    //   3. Commit / Rollback segun resultado
    //
    // De momento solo confirmamos visualmente.
    MsgBox( "Pedido guardado correctamente." + Chr( 13 ) + ;
            "Numero: " + hHeader[ "numero" ] + Chr( 13 ) + ;
            "Total:  " + Transform( hTotals[ "total" ], "9,999,999.99" ), ;
            "INFORMACION" )

RETURN NIL



// ============================================================================
// EditLine - abre formulario modal para editar una linea (hash)
// ============================================================================
FUNCTION EditLine( hLine )

    LOCAL oWin
    LOCAL oLbCod, oLbArt, oLbCnt, oLbPrc
    LOCAL oGetCod, oGetArt, oGetCnt, oGetPrc
    LOCAL oBtnOk, oBtnCan
    LOCAL lAccept := .F.

    // Variables temporales para los Get (no tocan hLine hasta ACEPTAR)
    LOCAL cCod := hLine[ "codigo"   ]
    LOCAL cArt := hLine[ "articulo" ]
    LOCAL nCnt := hLine[ "cant"     ]
    LOCAL nPrc := hLine[ "precio"   ]

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

    // Si acepto, escribir cambios de vuelta al hash original
    IF lAccept
        hLine[ "codigo"   ] := oGetCod:uVar
        hLine[ "articulo" ] := oGetArt:uVar
        hLine[ "cant"     ] := oGetCnt:uVar
        hLine[ "precio"   ] := oGetPrc:uVar
    ENDIF

RETURN lAccept



// ============================================================================
// InsertLine - anyade una linea nueva y la abre para editar
// ============================================================================
FUNCTION InsertLine( oGrid )

    LOCAL hNueva
    LOCAL cNuevoCod
    LOCAL nMax := 0
    LOCAL i

    // Calcular siguiente codigo: max + 1
    FOR i := 1 TO Len( oGrid:aData )
        nMax := Max( nMax, Val( oGrid:aData[ i, "codigo" ] ) )
    NEXT

    cNuevoCod := PadL( AllTrim( Str( nMax + 1 ) ), 4, "0" )

    hNueva := { ;
        "codigo"   => cNuevoCod, ;
        "articulo" => PadR( "", 30 ), ;
        "cant"     => 0, ;
        "precio"   => 0 }

    AAdd( oGrid:aData, hNueva )

    // Abrir formulario para que el usuario rellene
    IF EditLine( hNueva )
        // Usuario acepto: la linea queda anyadida con sus datos
    ELSE
        // Usuario cancelo: quitar la linea recien anyadida
        ASize( oGrid:aData, Len( oGrid:aData ) - 1 )
    ENDIF

RETURN NIL



// ============================================================================
// DemoLines - genera datos de prueba realistas
// ============================================================================
FUNCTION DemoLines()
RETURN { ;
    { "codigo" => "0001", "articulo" => PadR( "Disco SSD 1TB Samsung 870 EVO",      30 ), "cant" => 2, "precio" => 89.50  }, ;
    { "codigo" => "0002", "articulo" => PadR( "RAM DDR4 16GB Kingston 3200MHz",     30 ), "cant" => 4, "precio" => 45.00  }, ;
    { "codigo" => "0003", "articulo" => PadR( "CPU Intel Core i5 12400 6-core",     30 ), "cant" => 1, "precio" => 199.99 }, ;
    { "codigo" => "0004", "articulo" => PadR( "Placa base ASRock B660M Pro RS",     30 ), "cant" => 1, "precio" => 129.00 }, ;
    { "codigo" => "0005", "articulo" => PadR( "Tarjeta grafica RTX 3060 12GB",      30 ), "cant" => 1, "precio" => 379.00 }, ;
    { "codigo" => "0006", "articulo" => PadR( "Fuente Corsair RM750x 750W",         30 ), "cant" => 1, "precio" => 119.50 }, ;
    { "codigo" => "0007", "articulo" => PadR( "Caja ATX NZXT H510 Negra",           30 ), "cant" => 1, "precio" =>  85.00 }, ;
    { "codigo" => "0008", "articulo" => PadR( "Cooler Noctua NH-D15",               30 ), "cant" => 1, "precio" => 105.00 }  }
