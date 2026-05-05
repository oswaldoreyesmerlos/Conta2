# GfxStack API - Manual del Programador

Pseudo-graficos Harbour/GTWVG para aplicaciones de gestion (Contabilidad, Facturacion, etc.)

## Indice
1. [Visión General](#1-visión-general)
2. [Inicializacion](#2-inicializacion)
3. [Clase TWindow - Ventanas](#3-clase-twindow---ventanas)
4. [Clase TLabel - Etiquetas](#4-clase-tlabel---etiquetas)
5. [Clase TGet - Campos de entrada](#5-clase-tget---campos-de-entrada)
6. [Clase TButton - Botones](#6-clase-tbutton---botones)
7. [Clase TCheck - Casillas de verificacion](#7-clase-tcheck---casillas-de-verificacion)
8. [Clase TCombo - Listas desplegables](#8-clase-tcombo---listas-desplegables)
9. [Clase TGrid - Rejillas de datos](#9-clase-tgrid---rejillas-de-datos)
10. [Clase TForm - Formularios comerciales](#10-clase-tform---formularios-comerciales)
11. [Clase TMenu - Menus de texto](#11-clase-tmenu---menus-de-texto)
12. [Funciones Gfx - Capa grafica](#12-funciones-gfx---capa-grafica)
13. [Patrones de diseno para Contabilidad](#13-patrones-de-diseno-para-contabilidad)
14. [Ejemplo completo: Alta de asiento](#14-ejemplo-completo-alta-de-asiento)

---

## 1. Visión General

GfxStack es una capa pseudo-grafica para Harbour que encapsula GTWVG. 
**Ventaja clave**: Si manana cambias de GT (GTWVT, GTSLN, GTCGI), solo reescribes `Gfx.prg`.

### Estructura de carpetas (post-reorganizacion)
```
GfxStack/
├── api/
│   ├── Gfx.prg          <- Capa grafica (unico archivo que toca GTWVG)
│   ├── TControl.prg     <- Clase base
│   ├── TLabel.prg
│   ├── TGet.prg
│   ├── TButton.prg
│   ├── TCheck.prg
│   ├── TCombo.prg
│   ├── TGrid.prg
│   ├── TWindow.prg
│   ├── TForm.prg         <- Formularios comerciales
│   ├── TTable.prg
│   ├── TMenu.prg
│   ├── Util.prg         <- Utilidades (NetFLock, NetRLock, ErrSys)
│   ├── MsgBox.prg
│   ├── MsgYesNo.prg
│   ├── OOp.ch           <- Headers (hbclass.ch, inkey.ch, setcurs.ch)
│   └── GfxApi.md       <- Referencia rapida API
└── .gitignore
```

### Como compilar un test
```bash
# testform.hbp
gtwvg.hbc
hbct.hbc
hbxpp.hbc
xhb.hbc

-i.
-iConta2/api

Conta2/api/Gfx.prg
Conta2/api/TControl.prg
Conta2/api/TLabel.prg
Conta2/api/TGet.prg
Conta2/api/TButton.prg
Conta2/api/TCheck.prg
Conta2/api/TCombo.prg
Conta2/api/TGrid.prg
Conta2/api/TWindow.prg
Conta2/api/TForm.prg
Conta2/api/Util.prg

TestForm.prg

-oTestForm
-w0
-gui
```

---

## 2. Inicializacion

Siempre debe hacerse al inicio de la aplicacion (`Main.prg`):

```harbour
#include "OOp.ch"

PROCEDURE Main()
    // 1. Inicializar entorno pseudo-grafico (ventana 40x132, fuente monoespaciada)
    InitApp( 40, 132 )
    
    // 2. Opcional: poner titulo, icono, etc.
    GfxSetTitle( "MiApp Contabilidad - User: Admin" )
    
    // 3. Tu codigo aqui...
    // Ejecutar TWindow, TForm, etc.
    
    QUIT
RETURN

// ----------------------------------------------------------------------------
// Inicializacion (va en Util.prg / api/Util.prg)
// ----------------------------------------------------------------------------
FUNCTION InitApp( nRows, nCols )
    DEFAULT nRows  TO 40
    DEFAULT nCols  TO 132
    
    // Fuente monoespaciada (obligatorio para alineacion)
    GfxSetFont( "Courier New", 14, 8 )
    
    // Tamano fijo (el usuario no puede redimensionar)
    GfxFixSize( .T. )
    
    // Limpiar pantalla y ocultar cursor
    SetMode( nRows, nCols )
    SetColor( CLR_WINDOW )
    CLS
    GfxCursor( SC_NONE )
RETURN NIL
```

### Colores disponibles (notacion Clipper)
| Codigo | Color | RGB (0-65535) |
|--------|-------|----------------|
| `"N/W"` | Negro sobre blanco | `{0,0,0}` |
| `"B/W"` | Azul sobre blanco | `{0,0,32768}` |
| `"W+/B"` | Blanco sobre azul (titulos) | `{49152,49152,49152}` sobre `{0,0,32768}` |
| `"N/W+"` | Gris sobre blanco | `{32768,32768,32768}` |
| `"W+/N+"` | Blanco sobre gris | `{49152,49152,49152}` sobre `{32768,32768,32768}` |
| `"GR+/N"` | Amarillo sobre negro | `{65535,65535,0}` sobre `{0,0,0}` |

Constantes utiles: `CLR_WINDOW`, `CLR_PANEL`, `CLR_GET`, `CLR_GET_FOC`, `CLR_BUTTON`, `CLR_BUT_FOC`

---

## 3. Clase TWindow - Ventanas

Ventana modal con relieves WVG, gestion de foco, y stack de pintado.

### Creacion basica
```harbour
LOCAL oWin

// Crear ventana: fila_top, col_left, fila_bottom, col_right, titulo
oWin := TWindow():New( 05, 10, 20, 70, "Mi Ventana" )
oWin:cBgColor := CLR_PANEL  // Color de fondo (defecto CLR_WINDOW)

// Anyadir controles
oWin:AddCtrl( TLabel():New( 07, 12, "Nombre:", oWin ) )
oWin:AddCtrl( TGet():New( 07, 22, "" , "@!", oWin ) )

// Ejecutar modal (bucle interno hasta ESC o ::Close())
oWin:Run()
```

### Coordenadas recomendadas para Contabilidad
```harbour
// Ventana estandar: 38 filas x 120 columnas, centrada
#define ROW_TOP    03
#define ROW_BOT    33
#define COL_LEFT   02
#define COL_RIGHT  122

oWin := TWindow():New( ROW_TOP, COL_LEFT, ROW_BOT, COL_RIGHT, "Alta de Asiento" )
```

### Gestion de foco
```harbour
// Ciclo manual (si no usas ::Run())
oWin:SetFocus( 1 )       // Primer control enfocable
nKey := Inkey( 0 )
oWin:HandleKey( nKey )  // TAB, Shift+TAB, flechas, ESC

// Cerrar ventana programaticamente
oWin:Close()              // Equivale a lExit := .T.
```

### Anidar ventanas modales
```harbour
// TWindow detecta automaticamente si hay otra ventana activa y la pone como ::oOwner
// Al cerrar, restaura el padre.

oWin1 := TWindow():New( 05, 10, 20, 60, "Padre" )
oWin1:AddCtrl( TButton():New( 10, 15, 10, 30, oWin1, "Abrir Hijo", ;
    { || oWin2:Run(), oWin1:Refresh() } ) )
oWin1:Run()
```

---

## 4. Clase TLabel - Etiquetas

```harbour
// TLabel():New( nRow, nCol, cTexto, oParent )
oWin:AddCtrl( TLabel():New( 03, 02, "Empresa: Conta2 SA", oWin ) )
oWin:AddCtrl( TLabel():New( 04, 02, "Fecha: " + DToC(Date()), oWin ) )
```

**Nota**: Para etiquetas multilinea, usar `GfxText()` directamente en el Paint de una ventana personalizada.

---

## 5. Clase TGet - Campos de entrada

### Creacion y tipos
```harbour
LOCAL oGet

// 1. Texto (string)
oGet := TGet():New( 05, 10, "" , "@!", oWin )        // Sin picture: ancho minimo 10
oGet := TGet():New( 05, 10, "" , "@!" , oWin, 20 ) // Ancho fijo 20 caracteres

// 2. Numerico
oGet := TGet():New( 06, 10, 0, "999999.99", oWin )    // Picture determina ancho
oGet := TGet():New( 06, 10, 0, "999,999.99", oWin ) // Con separadores

// 3. Fecha
oGet := TGet():New( 07, 10, Date(), "99/99/9999", oWin )

// 4. Logico (Si/No)
oGet := TGet():New( 08, 10, .F., "@!", oWin )
```

### Validacion
```harbour
// bWhen: se ejecuta al intentar entrar (debe devolver .T. para permitir)
oGet:bWhen := { |o| Empty( ::cCabBuffer[ "CLIENTE_" ] ) }

// bValid: se ejecuta al salir (TAB, Enter, flechas)
// Devuelve .T. para aceptar, .F. para quedarse
oGet:bValid := { |o| !Empty( o:GetVal() ) .OR. ( MsgStop("Vacio"), .F. ) }
```

### Leer/escribir valor
```harbour
// Leer valor actual
uVal := oGet:GetVal()    // Devuelve segun tipo: string, number, date, logical

// Escribir valor (y repintar)
oGet:SetVal( "Nuevo texto" )
```

### Uso tipico en formularios de contabilidad
```harbour
// Header fields con definicion centralizada (ver TForm mas abajo)
aCabDefs := { ;
    { "NUMERO",   "N Pedido:",  "@!",        10, .F. }, ;
    { "FECHA",    "Fecha:",     "99/99/9999", 10, .F. }, ;
    { "CLIENTE_", "Cliente:",   "@!",        10, .F. }  ;
}

// En TForm se usa asi:
oForm:SetCabFields( aCabDefs )
// TForm crea automaticamente los TGet respetando el ancho (nLen)
```

---

## 6. Clase TButton - Botones

```harbour
// TButton():New( nTop, nLeft, nBottom, nRight, oParent, cCaption, bAction )
oBtn := TButton():New( 25, 05, 25, 20, oWin, "GUARDAR", { || GuardarTodo() } )
oBtn := TButton():New( 25, 25, 25, 40, oWin, "CANCELAR", { || oWin:Close() } )
```

### Comportamiento visual
- **Normal**: Relieve raised, color `CLR_BUTTON`
- **Con foco** (TAB): Relieve recessed, color `CLR_BUT_FOC`
- **Al hacer click**: Flash de colores invertidos (`__SwapColor`)

### Uso en Contabilidad
```harbour
// Botones estandar para formularios comerciales
oWin:AddCtrl( TButton():New( ROW_BTN, 05, ROW_BTN, 20, oWin, ;
    "GUARDAR", { || ::Save(), ::oWin:Close() } ) )
oWin:AddCtrl( TButton():New( ROW_BTN, 25, ROW_BTN, 42, oWin, ;
    "CANCELAR", { || ::oWin:Close() } ) )
oWin:AddCtrl( TButton():New( ROW_BTN, 47, ROW_BTN, 62, oWin, ;
    "AGREGAR", { || ::AddLinea() } ) )
```

---

## 7. Clase TCheck - Casillas de verificacion

```harbour
oCheck := TCheck():New( 10, 10, oWin, "Facturado", .F. )
oCheck:bSetGet := { |l| If( l == NIL, ::uVar, ::uVar := l ) }

// Leer valor
IF oCheck:GetVal()
    // Esta facturado
ENDIF
```

**Teclado**: SPACE para cambiar estado, se pinta "Si " / "No " automaticamente.

---

## 8. Clase TCombo - Listas desplegables

```harbour
LOCAL oCombo
LOCAL aItems := { "Contado", "Credito 30 dias", "Credito 60 dias", "Cheque" }

// Crear combo con array de items
oCombo := TCombo():New( 10, 10, oWin, aItems, 1 )  // 1 = indice inicial

// Leer/escribir
nSel := oCombo:GetVal()         // Devuelve indice (1-based)
cText := aItems[ nSel ]      // Texto seleccionado
oCombo:SetVal( 3 )            // Seleccionar "Credito 60 dias"
```

### Uso en Contabilidad (forma de pago)
```harbour
aFormasPago := { "Contado", "Tarjeta", "Transferencia", "Cheque" }
oWin:AddCtrl( TLabel():New( 10, 02, "Forma pago:", oWin ) )
oWin:AddCtrl( TCombo():New( 10, 15, oWin, aFormasPago, 1 ) )
```

---

## 9. Clase TGrid - Rejillas de datos

### Creacion
```harbour
LOCAL oGrid
LOCAL aData := { ;
    { "LINEA" => 1, "ARTICULO" => "ART001", "DESCRIPC" => "Producto X", ;
      "CANTIDAD" => 2, "PRECIO" => 150.50, "IMPORTE" => 301.00 }, ;
    { "LINEA" => 2, "ARTICULO" => "ART002", "DESCRIPC" => "Producto Y", ;
      "CANTIDAD" => 1, "PRECIO" => 89.90, "IMPORTE" => 89.90 } ;
}

// TGrid():New( nTop, nLeft, nBottom, nRight, oParent )
oGrid := TGrid():New( 10, 02, 24, 118, oWin )

// Anyadir columnas: AddColumn( cHeader, nWidth, bData, cPicture )
oGrid:AddColumn( "L",        3,  { |h| Str( h[ "LINEA" ], 3 ) } )
oGrid:AddColumn( "Codigo",  10, { |h| h[ "ARTICULO" ] }, "@!" )
oGrid:AddColumn( "Descripcion", 30, { |h| h[ "DESCRIPC" ] } )
oGrid:AddColumn( "Cant",    8,  { |h| Str( h[ "CANTIDAD" ], 8, 2 ) }, "999999.9" )
oGrid:AddColumn( "Precio",  10, { |h| Str( h[ "PRECIO" ], 10, 2 ) }, "999999.99" )
oGrid:AddColumn( "Importe", 12, { |h| Str( h[ "IMPORTE" ], 12, 2 ) }, "999,999.99" )

// Asignar datos (array de hashes)
oGrid:aData := aData
```

### Navegacion y eventos
```harbour
// bEnter: doble click o F2 (editar linea)
oGrid:bEnter := { |g| EditarLinea( g:nCurRow ) }

// bInsert: flecha abajo en ultima linea (agregar nueva)
oGrid:bInsert := { || AgregarLinea() }

// bDelete: DEL (eliminar linea)
oGrid:bDelete := { |g| EliminarLinea( g:nCurRow ) }

// Leer fila actual
nRow := oGrid:nCurRow
IF nRow >= 1 .AND. nRow <= Len( oGrid:aData )
    hRow := oGrid:aData[ nRow ]
    // hRow[ "ARTICULO" ], etc.
ENDIF
```

### Uso en Contabilidad (grid de detalle de factura)
```harbour
METHOD EditLinea( nRow ) CLASS TForm
    LOCAL hRow := ::aDetalle[ nRow ]
    LOCAL oW := TWindow():New( 12, 10, 22, 62, "Linea " + Str( nRow, 3 ) )
    
    oW:AddCtrl( TLabel():New( 02, 02, "Articulo:", oW ) )
    oW:AddCtrl( TGet():New( 02, 12, hRow[ "ARTICULO" ], "@!", oW, 10 ) )
    // ... mas campos ...
    
    oW:AddCtrl( TButton():New( 08, 42, 08, 55, oW, "OK", ;
        { || GuardarLinea( hRow ), oW:Close() } ) )
    oW:Run()
RETURN Self
```

---

## 10. Clase TForm - Formularios comerciales

**Clase estandarizada para pedidos, facturas, presupuestos, etc.**

### Uso basico
```harbour
LOCAL oForm
LOCAL hEmp := { "NOMBRE" => "Conta2 SA", "NIF" => "B12345678" }

oForm := TForm():New( "PEDIDOS", "PED_DET", "NUMERO" )
oForm:SetDocInfo( "PED", "PEDIDO" )
oForm:SetEmpresa( hEmp )
oForm:SetMode( .T. )  // .T. = Nuevo, .F. = Edicion

// Definir campos cabecera: { cVar, cLabel, cPic, nLen, lReadOnly, bWhen, bValid }
oForm:SetCabFields( { ;
    { "NUMERO",   "N Pedido:",  "@!",        10, .F. }, ;
    { "FECHA",    "Fecha:",     "99/99/9999", 10, .F. }, ;
    { "CLIENTE_", "Cliente:",   "@!",        10, .F. }  ;
} )

// Definir columnas del grid (opcional, tiene default)
oForm:SetDetCols( { ;
    { "L",        3,  { |h| Str( h[ "LINEA" ], 3 ) }, NIL }, ;
    { "Codigo",  10, { |h| h[ "ARTICULO" ] }, "@!" }, ;
    { "Descripcion", 30, { |h| h[ "DESCRIPC" ] }, NIL }, ;
    { "Cant",    8,  { |h| Str( h[ "CANTIDAD" ], 8, 2 ) }, "999999.9" }, ;
    { "Precio",  10, { |h| Str( h[ "PRECIO" ], 10, 2 ) }, "999999.99" }, ;
    { "Dto%",     6,  { |h| Str( h[ "DESCUENT" ], 6, 2 ) }, "99.9" }, ;
    { "Importe", 12,  { |h| Str( h[ "IMPORTE" ], 12, 2 ) }, "999,999.99" }  ;
} )

// Ejecutar
oForm:Run()
```

### Cargar documento existente
```harbour
oForm := TForm():New( "PEDIDOS", "PED_DET", "NUMERO" )
oForm:SetMode( .F. )              // Modo edicion
oForm:Load( "000123" )          // Carga cabecera y detalle
oForm:Run()
```

### Metodos utiles
```harbour
// Leer valor de cabecera
cNumero := oForm:GetCabVal( "NUMERO" )

// Escribir valor de cabecera (y refrescar GET)
oForm:SetCabVal( "FECHA", Date() )

// Recalcular totales (se llama automaticamente al editar lineas)
oForm:RecalcTotals()
// Accede a ::nSubtotal, ::nIva (21%), ::nTotal
```

### Coordenadas de formulario (ajustadas para 98 columnas)
```harbour
#define ROW_EMP    01     // Datos empresa
#define ROW_CAB    03     // Campos cabecera (incrementa de 2 en 2)
#define ROW_DET    13     // Inicio del grid
#define ROW_TOT    28     // Inicio de totales (bajado 1 fila)
#define ROW_BTN    32     // Botones
#define COL_LABEL  02     // Columna de etiquetas
#define COL_FIELD  18     // Columna de campos GET
#define COL_TOT    50     // Totales movidos a la izquierda 5 colummnas
```

---

## 11. Clase TMenu - Menus de texto

**Menu estilo Clipper (no WVG) para la aplicacion principal.

```harbour
LOCAL oMenu
LOCAL aItems := { ;
    { "1", "Altas/  Facturas",  .F., .F. }, ;
    { "2", "Altas/  Pedidos",   .F., .F. }, ;
    { "3", "Mestros/Clientes", .F., .F. }, ;
    { "4", "Informes/  Contabilidad", .F., .F. }, ;
    { "0", "Salir",             .F., .F. } ;
}

oMenu := TMenu():New( 02, 02, MaxRow() - 2, 30, oWin )
oMenu:aItems := aItems
oMenu:bAction := { |o, n| ProcesarOpcion( o:aItems[ n, 2 ] ) }
oMenu:Paint()
```

---

## 12. Funciones Gfx - Capa grafica

### Bloqueo de refresco (siempre en pares)
```harbour
GfxLock()    // Iniciar bloque (acumula cambios)
// ... operaciones de pintado ...
GfxUnlock()  // Ejecutar todas las operaciones de una vez
```

### Pintado basico
```harbour
GfxClear( nT, nL, nB, nR, "W/N" )       // Limpiar rectangulo
GfxBox( nT, nL, nB, nR, "B/W" )       // Marco simple ASCII
GfxText( nRow, nCol, "Hola", "W+/B" )      // Texto con color
```

### Relieves WVG (capa grafica)
```harbour
GfxRaised( nT, nL, nB, nR )           // Marco levantado (ventanas, botones)
GfxRecessed( nT, nL, nB, nR )         // Marco hundido (campos GET)
GfxGroup( nT, nL, nB, nR )           // Linea fina (agrupacion)
GfxFillSolid( nT, nL, nB, nR, "W+/B" )  // Rellenar opaco (escudo)
```

### Save/Restore (para ventanas modales)
```harbour
// Guardar zona (incluye relieves WVG gracias a PADWIN=2 en TWindow)
xBackup := GfxSave( nT-2, nL-2, nB+2, nR+2 )

// Restaurar exactamente
GfxRestore( nT-2, nL-2, nB+2, nR+2, xBackup )
```

### Stack de pintado (uso interno de TWindow)
```harbour
aPrev := GfxPaintPush()                      // Guardar nivel actual
GfxPaintAdd( "marco", { || GfxRaised( 5,5,20,60 ) } )  // Registrar bloque
// ... pintar ...
GfxPaintPop( aPrev )                      // Restaurar nivel anterior
```

### Utilidades
```harbour
GfxSetFont( "Courier New", 14, 8 )       // Fuente monoespaciada
GfxFixSize( .T. )                         // Ventana tamano fijo
GfxMaxRow() / GfxMaxCol()                // Dimensiones actuales
GfxCursor( SC_NONE )                      // Ocultar cursor
GfxCursor( SC_NORMAL )                    // Mostrar cursor (subrayado)
GfxSetTitle( "Mi App" )                   // Titulo ventana
```

---

## 13. Patrones de diseno para Contabilidad

### Estructura recomendada de archivos
```
Conta2/
├── api/               <- Copia de GfxStack/api/ (o symlink)
├── DATA/              <- DBF/CDX files
├── sources/           <- Tu codigo de contabilidad
│   ├── Main.prg             <- Inicia con InitApp()
│   ├── MenuInit.prg        <- Menu principal TMenu
│   ├── Asientos.prg        <- Alta de asientos
│   ├── Fact_Alta.prg       <- Facturacion (usa TForm)
│   ├── Pedidos.prg         <- Pedidos (usa TForm)
│   └── Utilidades.prg      <- NetFLock, NetRLock, ABRIR_TABLA
└── Contab.Hbp          <- Build file
```

### Como abrir tablas con bloqueo
```harbour
#include "OOp.ch"

FUNCTION ABRIR_TABLA( cArchivo, cAlias, cIndice )
    LOCAL lReintentar := .T.
    
    IF cAlias == NIL; cAlias := cArchivo; ENDIF
    
    // Verificar si ya esta abierto
    IF Select( cAlias ) > 0
        DbSelectArea( cAlias )
        IF cIndice != NIL; ORDSETFOCUS( cIndice ); ENDIF
        RETURN .T.
    ENDIF
    
    DO WHILE lReintentar
        DbUseArea( .T., "DBFCDX", cArchivo, cAlias, .T., .F. )
        IF NetErr()
            IF Alert( "Archivo " + cArchivo + " ocupado. Reintentar?", ;
                      { "Si", "No" } ) == 2
                RETURN .F.
            ENDIF
        ELSE
            lReintentar := .F.
        ENDIF
    ENDDO
    
    IF cIndice != NIL; ORDSETFOCUS( cIndice ); ENDIF
    DbGoTop()
RETURN .T.
```

### Formulario de alta de asiento contable (ejemplo)
```harbour
FUNCTION AltaAsiento()
    LOCAL oWin
    LOCAL oGetFecha, oGetDesc, oGetDebe, oGetHaber
    LOCAL aPartidas := {}
    LOCAL nTotalDebe := 0, nTotalHaber := 0
    
    oWin := TWindow():New( 05, 05, 30, 115, "Alta de Asiento Contable" )
    oWin:cBgColor := CLR_PANEL
    
    // Cabecera
    oWin:AddCtrl( TLabel():New( 03, 02, "Fecha:", oWin ) )
    oGetFecha := TGet():New( 03, 10, Date(), "99/99/9999", oWin )
    oWin:AddCtrl( oGetFecha )
    
    oWin:AddCtrl( TLabel():New( 05, 02, "Descripcion:", oWin ) )
    oGetDesc := TGet():New( 05, 16, "" , "@!", oWin, 40 )
    oWin:AddCtrl( oGetDesc )
    
    // Grid de partidas (simplificado, usar TGrid en produccion)
    oWin:AddCtrl( TLabel():New( 08, 02, "Partidas:", oWin ) )
    
    // Botones
    oWin:AddCtrl( TButton():New( 26, 05, 26, 20, oWin, "AGREGAR", ;
        { || AgregarPartida( aPartidas ), oWin:Refresh() } ) )
    oWin:AddCtrl( TButton():New( 26, 25, 26, 42, oWin, "GUARDAR", ;
        { || GuardarAsiento(), oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 26, 45, 26, 62, oWin, "CANCELAR", ;
        { || oWin:Close() } ) )
    
    oWin:Run()
RETURN NIL
```

### Uso de TForm para Facturacion (modelo Conta2)
```harbour
FUNCTION NuevaFactura()
    LOCAL oForm
    LOCAL hEmp
    
    // Cargar datos empresa
    ABRIR_TABLA( "EMPRESA", "EMP", "" )
    hEmp := { "NOMBRE" => EMP->NOMBRE, "NIF" => EMP->NIF }
    EMP->( DbCloseArea() )
    
    // Crear formulario
    oForm := TForm():New( "FACTURA", "FACTUR_DET", "NUMERO" )
    oForm:SetDocInfo( "FAC", "FACTURA" )
    oForm:SetEmpresa( hEmp )
    oForm:SetMode( .T. )  // Nuevo
    
    // Campos cabecera
    oForm:SetCabFields( { ;
        { "NUMERO",   "N Factura:",  "@!",        12, .F. }, ;
        { "FECHA",    "Fecha:",     "99/99/9999", 10, .F. }, ;
        { "CLIENTE_", "Cliente:",   "@!",        10, .F. }, ;
        { "OBSERVA",  "Notas:",     "@S50",      60, .F. }  ;
    } )
    
    // Ejecutar
    oForm:Run()
RETURN NIL
```

---

## 14. Ejemplo completo: Alta de asiento

Archivo: `Conta2/sources/Asientos.prg`

```harbour
#include "OOp.ch"
#include "inkey.ch"
#include "box.ch"
#include "styles.ch"

FUNCTION AsientosForm()
    LOCAL oWin
    LOCAL oGetFec, oGetDesc
    LOCAL aPartidas := {}
    LOCAL nRow := 08
    
    // Crear ventana principal
    oWin := TWindow():New( 03, 02, 35, 122, "ALTA DE ASIENTO CONTABLE" )
    oWin:cBgColor := CLR_PANEL
    
    // ---- Cabecera ----
    oWin:AddCtrl( TLabel():New( 03, 02, "Fecha:", oWin ) )
    oGetFec := TGet():New( 03, 10, Date(), "99/99/9999", oWin )
    oWin:AddCtrl( oGetFec )
    
    oWin:AddCtrl( TLabel():New( 05, 02, "Descripcion:", oWin ) )
    oGetDesc := TGet():New( 05, 16, "" , "@!", oWin, 50 )
    oWin:AddCtrl( oGetDesc )
    
    // ---- Grid de partidas (usando TGrid) ----
    oGrid := TGrid():New( 08, 02, 28, 120, oWin )
    oGrid:AddColumn( "Cuenta",  12, { |h| PadR( h[ "CUENTA" ], 12 ) }, "@!" )
    oGrid:AddColumn( "Descripcion", 30, { |h| PadR( h[ "DESC" ], 30 ) } )
    oGrid:AddColumn( "Debe",   12, { |h| PadL( Str( h[ "DEBE" ], 12, 2 ), 12, 2 ) }, "999,999.99" )
    oGrid:AddColumn( "Haber",  12, { |h| PadL( Str( h[ "HABER" ], 12, 2 ), 12, 2 ) }, "999,999.99" )
    oGrid:aData := aPartidas
    
    oGrid:bEnter := { |g| EditarPartida( g:nCurRow, aPartidas, oGrid ) }
    oGrid:bInsert := { || AgregarPartida( aPartidas, oGrid ) }
    oGrid:bDelete := { |g| BorrarPartida( g:nCurRow, aPartidas, oGrid ) }
    
    oWin:AddCtrl( oGrid )
    
    // ---- Totales ----
    oWin:AddCtrl( TLabel():New( 29, 80, "Total Debe:", oWin ) )
    oWin:AddCtrl( TGet():New( 29, 95, 0.00, "999,999.99", oWin ) )
    
    oWin:AddCtrl( TLabel():New( 30, 80, "Total Haber:", oWin ) )
    oWin:AddCtrl( TGet():New( 30, 95, 0.00, "999,999.99", oWin ) )
    
    // ---- Botones ----
    oWin:AddCtrl( TButton():New( 32, 05, 32, 20, oWin, "GUARDAR", ;
        { || GuardarAsiento( oGetFec:GetVal(), oGetDesc:GetVal(), aPartidas ), ;
           oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 32, 25, 32, 42, oWin, "CANCELAR", ;
        { || oWin:Close() } ) )
    
    // Ejecutar
    oWin:Run()
RETURN NIL


// ----------------------------------------------------------------------------
// Editar partida (ventana modal pequeña)
// ----------------------------------------------------------------------------
STATIC FUNCTION EditarPartida( nRow, aPartidas, oGrid )
    LOCAL hRow
    LOCAL oW, oGetCta, oGetDesc, oGetDeb, oGetHab
    
    IF nRow < 1 .OR. nRow > Len( aPartidas )
        RETURN NIL
    ENDIF
    
    hRow := aPartidas[ nRow ]
    oW := TWindow():New( 12, 30, 20, 90, "Editar Partida" )
    oW:cBgColor := CLR_PANEL
    
    oW:AddCtrl( TLabel():New( 02, 02, "Cuenta:", oW ) )
    oGetCta := TGet():New( 02, 12, hRow[ "CUENTA" ], "@!", oW, 12 )
    oW:AddCtrl( oGetCta )
    
    oW:AddCtrl( TLabel():New( 04, 02, "Descripcion:", oW ) )
    oGetDesc := TGet():New( 04, 16, hRow[ "DESC" ], "@!", oW, 30 )
    oW:AddCtrl( oGetDesc )
    
    oW:AddCtrl( TLabel():New( 06, 02, "Debe:", oW ) )
    oGetDeb := TGet():New( 06, 08, hRow[ "DEBE" ], "999999.99", oW )
    oW:AddCtrl( oGetDeb )
    
    oW:AddCtrl( TLabel():New( 06, 25, "Haber:", oW ) )
    oGetHab := TGet():New( 06, 33, hRow[ "HABER" ], "999999.99", oW )
    oW:AddCtrl( oGetHab )
    
    oW:AddCtrl( TButton():New( 08, 25, 08, 40, oW, "OK", ;
        { || hRow[ "CUENTA" ] := oGetCta:GetVal(), ;
            hRow[ "DESC" ] := oGetDesc:GetVal(), ;
            hRow[ "DEBE" ]  := oGetDeb:GetVal(), ;
            hRow[ "HABER" ] := oGetHab:GetVal(), ;
            oGrid:aData := aPartidas, ;
            oGrid:Paint(), ;
            oW:Close() } ) )
    
    oW:Run()
RETURN NIL


// ----------------------------------------------------------------------------
// Agregar partida nueva
// ----------------------------------------------------------------------------
STATIC FUNCTION AgregarPartida( aPartidas, oGrid )
    AAdd( aPartidas, { "CUENTA" => "", "DESC" => "", "DEBE" => 0, "HABER" => 0 } )
    oGrid:aData := aPartidas
    oGrid:nCurRow := Len( aPartidas )
    EditarPartida( Len( aPartidas ), aPartidas, oGrid )
RETURN NIL


// ----------------------------------------------------------------------------
// Borrar partida
// ----------------------------------------------------------------------------
STATIC FUNCTION BorrarPartida( nRow, aPartidas, oGrid )
    IF nRow < 1 .OR. nRow > Len( aPartidas )
        RETURN NIL
    ENDIF
    ADel( aPartidas, nRow )
    ASize( aPartidas, Len( aPartidas ) - 1 )
    oGrid:aData := aPartidas
    oGrid:Paint()
RETURN NIL


// ----------------------------------------------------------------------------
// Guardar asiento en tabla ASIENTOS (simplificado)
// ----------------------------------------------------------------------------
STATIC FUNCTION GuardarAsiento( dFecha, cDesc, aPartidas )
    LOCAL nAsiento := 1  // En produccion usar GetNextNum( "ASI", "Asiento" )
    
    IF !ABRIR_TABLA( "LDIARIO", "ASI", "NUMERO" )
        MsgStop( "No se puede abrir el diario" )
        RETURN .F.
    ENDIF
    
    // Cabecera (en produccion usar TTable o acceso directo)
    // ... omitido por brevedad ...
    
    ASI->( DbCloseArea() )
    MsgInfo( "Asiento " + Str( nAsiento, 6 ) + " guardado correctamente" )
RETURN .T.
```

---

## Apindice: Errores comunes y soluciones

| Error | Causa | Solucion |
|-------|-------|----------|
| `NETRLOCK not found` | Falta `Util.prg` o `Utilidades.prg` | Anyadir `api/Util.prg` al `.hbp` |
| `undefined reference to HB_FUN_WVT_DRAWBOXRAISED` | Falta `gtwvg.hbc` | Anyadir `gtwvg.hbc` al `.hbp` |
| `W0002: Redefinition of SC_NONE` | `OOp.ch` se incluye multiples veces | Normal en Harbour, no afecta funcionamiento |
| `duplicate definition of HB_FUN_MSGINFO` | `MsgBox.prg` y `Util.prg` duplicados | Eliminar uno, o usar `#ifndef HAS_UTILIDADES` |
| Ventana con artefactos visuales | No se uso `GfxFillSolid` antes de pintar | Usar stack `GfxPaintPush/Pop` correctamente |

---

**Fin del manual.** Para dudas especificas, revisar los archivos `.prg` en `api/` que tienen comentarios detallados en cada metodo.
