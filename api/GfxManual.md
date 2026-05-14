# GfxStack API - Manual del Programador

Pseudo-graficos Harbour/GTWVG para aplicaciones de gestion (Contabilidad, Facturacion, etc.)

## Indice
1. [Vision General](#1-vision-general)
2. [Inicializacion](#2-inicializacion)
3. [Clase TWindow - Ventanas](#3-clase-twindow---ventanas)
4. [Clase TLabel - Etiquetas](#4-clase-tlabel---etiquetas)
5. [Clase TGet - Campos de entrada](#5-clase-tget---campos-de-entrada)
6. [Clase TButton - Botones](#6-clase-tbutton---botones)
7. [Clase TCheck - Casillas de verificacion](#7-clase-tcheck---casillas-de-verificacion)
8. [Clase TCombo - Listas desplegables](#8-clase-tcombo---listas-desplegables)
9. [Clase TGrid - Rejillas de datos](#9-clase-tgrid---rejillas-de-datos)
10. [Clase TTable - Acceso a DBF](#10-clase-ttable---acceso-a-dbf)
11. [Clase TMenu - Menus de texto](#11-clase-tmenu---menus-de-texto)
12. [Dialogos modales: MsgBox / MsgYesNo](#12-dialogos-modales-msgbox--msgyesno)
13. [Funciones Gfx - Capa grafica](#13-funciones-gfx---capa-grafica)
14. [Funciones Util - Utilidades](#14-funciones-util---utilidades)
15. [Constantes de color (OOp.ch)](#15-constantes-de-color-oopch)
16. [Patron de diseno: TForm (referencia)](#16-patron-de-diseno-tform-referencia)
17. [Ejemplo completo: Alta de asiento](#17-ejemplo-completo-alta-de-asiento)

---

## 1. Vision General

GfxStack es una capa pseudo-grafica para Harbour que encapsula GTWVG.
**Ventaja clave**: Si manana cambias de GT (GTWVT, GTSLN, GTCGI), solo reescribes `Gfx.prg`.

### Estructura de carpetas
```
GfxStack/
├── api/
│   ├── Gfx.prg           <- Capa grafica (unico archivo que toca GTWVG)
│   ├── TControl.prg      <- Clase base de todos los controles
│   ├── TWindow.prg       <- Ventanas modales
│   ├── TLabel.prg        <- Etiquetas de texto
│   ├── TGet.prg          <- Campos de entrada/edit
│   ├── TButton.prg       <- Botones
│   ├── TCheck.prg        <- Casillas de verificacion
│   ├── TCombo.prg        <- Listas desplegables
│   ├── TGrid.prg         <- Rejillas de datos
│   ├── TTable.prg        <- Wrapper OOP sobre RDD DBFCDX
│   ├── TMenu.prg         <- Menu principal (estilo Clipper, OOP)
│   ├── MsgBox.prg        <- MsgBox / MsgInfo / MsgStop
│   ├── MsgYesNo.prg      <- MsgYesNo / MsgConfirm
│   └── OOp.ch            <- Headers y constantes globales
└── Util.prg              <- InitApp, ErrSys, ABRIR_TABLA, bloqueos, GetNextNum, validacion NIF, popups
```

### Como compilar
```bash
# testform.hbp
gtwvg.hbc
hbct.hbc
hbxpp.hbc
xhb.hbc

-i.
-i.\api
-i.\DATA

.\api\Gfx.prg
.\api\TControl.prg
.\api\TLabel.prg
.\api\TGet.prg
.\api\TButton.prg
.\api\TCheck.prg
.\api\TCombo.prg
.\api\TGrid.prg
.\api\TWindow.prg
.\api\TTable.prg
.\api\TMenu.prg
.\api\MsgBox.prg
.\api\MsgYesNo.prg
.\Util.prg

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
    // Inicializa RDD DBFCDX, fuente, modo 40x132, cursor apagado
    InitApp( 40, 132 )

    // Opcional: titulo de ventana
    GfxSetTitle( "MiApp - Usuario: Admin" )

    // Tu codigo aqui...
    QUIT
RETURN
```

`InitApp()` esta definida en `Util.prg` (raiz del proyecto):

```harbour
FUNCTION InitApp( nRows, nCols, cFont, nFontH, nFontW )
    DEFAULT nRows  TO 40
    DEFAULT nCols  TO 132
    DEFAULT cFont  TO "Lucida Console"
    DEFAULT nFontH TO 16
    DEFAULT nFontW TO 8

    rddSetDefault( "DBFCDX" )
    GfxSetFont( cFont, nFontH, nFontW )
    SetMode( nRows, nCols )
    GfxFixSize( .T. )
    SetColor( CLR_WINDOW )
    CLS
    GfxCursor( SC_NONE )
RETURN NIL
```

---

## 3. Clase TWindow - Ventanas

Ventana modal con relieves WVG, gestion de foco, y stack de pintado.

### Creacion basica
```harbour
LOCAL oWin
oWin := TWindow():New( 05, 10, 20, 70, "Mi Ventana" )
oWin:cBgColor := CLR_PANEL
oWin:AddCtrl( TLabel():New( 07, 12, "Nombre:", oWin ) )
oWin:AddCtrl( TGet():New( 07, 22, "" , "@!", oWin ) )
oWin:Run()
```

### Metodos principales
| Metodo | Descripcion |
|--------|-------------|
| `New( nTop, nLeft, nBottom, nRight, cTitle )` | Constructor |
| `AddCtrl( oControl )` | Anyade un control |
| `Run()` | Bucle modal (TAB, teclas, foco) hasta `Close()` |
| `Close()` | Sale del bucle modal |
| `Paint()` | Pinta ventana (marco raised, titulo, fondo) |
| `Refresh()` | Repinta solo controles |
| `Redraw()` | Repinta ventana completa (incluye marcos) |
| `Center()` | Centra la ventana en pantalla |
| `SetFocus( nPos )` | Pone foco en el control nPos (1-based) |
| `NextFocus()` | Foco al siguiente control con lTabStop |
| `PrevFocus()` | Foco al anterior control con lTabStop |
| `FindFirstFocus()` | Busca el primer control enfocable |
| `HandleKey( nKey )` | Procesa tecla (TAB, ESC, etc.) |
| `Lock()` / `Unlock()` | Bloquea/desbloquea refresco |

### Gestion de foco manual (si no usas `::Run()`)
```harbour
oWin:SetFocus( 1 )
nKey := Inkey( 0 )
oWin:HandleKey( nKey )
```

### Anidar ventanas modales
```harbour
oWin1 := TWindow():New( 05, 10, 20, 60, "Padre" )
oWin1:AddCtrl( TButton():New( 10, 15, 10, 30, oWin1, "Abrir Hijo", ;
    { || oWin2:Run(), oWin1:Refresh() } ) )
oWin1:Run()
```

### Datos internos
| Dato | Descripcion |
|------|-------------|
| `nTop, nLeft, nBottom, nRight` | Coordenadas |
| `cTitle` | Titulo |
| `aCtrls` | Array de controles |
| `nFocPos` | Indice del control con foco |
| `oFocus` | Referencia al control con foco |
| `lExit` | Flag que corta el bucle `Run()` |
| `lVisible` | Visibilidad |
| `xBackup` | Snapshot para restaurar al cerrar |
| `lModal` | .T. si es modal |
| `oOwner` | Ventana padre (si es anidada) |

---

## 4. Clase TLabel - Etiquetas

```harbour
// TLabel():New( nRow, nCol, cTexto, oParent )
oWin:AddCtrl( TLabel():New( 03, 02, "Empresa: MiApp SA", oWin ) )
oWin:AddCtrl( TLabel():New( 04, 02, "Fecha: " + DToC(Date()), oWin ) )
```

| Metodo | Descripcion |
|--------|-------------|
| `New( nRow, nCol, cText, oPar )` | Crea etiqueta |
| `Paint()` | Dibuja el texto |
| `SetText( cNew )` | Cambia el texto y repinta (ajusta ancho) |

**Nota**: `lTabStop := .F.` por defecto (no enfocable).

---

## 5. Clase TGet - Campos de entrada

### Creacion y tipos
```harbour
LOCAL oGet

// Texto (string)
oGet := TGet():New( 05, 10, "" , "@!", oWin )
oGet := TGet():New( 05, 10, "" , "@!" , oWin, 20 )

// Numerico
oGet := TGet():New( 06, 10, 0, "999999.99", oWin )
oGet := TGet():New( 06, 10, 0, "999,999.99", oWin )

// Fecha
oGet := TGet():New( 07, 10, Date(), "99/99/9999", oWin )

// Logico (se muestra Si/No)
oGet := TGet():New( 08, 10, .F., "@!", oWin )
```

### Validacion
```harbour
// bWhen: se ejecuta al intentar entrar (debe devolver .T. para permitir)
oGet:bWhen := { |o| Empty( ::cCabBuffer[ "CLIENTE_" ] ) }

// bValid: se ejecuta al salir (TAB, Enter, flechas)
oGet:bValid := { |o| !Empty( o:GetVal() ) .OR. ( MsgStop("Vacio"), .F. ) }
```

### Leer/escribir valor
```harbour
uVal := oGet:GetVal()     // Devuelve segun tipo
oGet:SetVal( "Nuevo" )    // Escribe y repinta
```

### Metodos disponibles
| Metodo | Descripcion |
|--------|-------------|
| `New( nRow, nCol, uVar, cPicture, oPar, nLen )` | Constructor |
| `Paint()` | Dibuja el campo |
| `SetFocus()` | Activa editor |
| `KillFocus()` | Finaliza edicion, ejecuta bValid |
| `Validate()` | Valida contenido (bValid) |
| `HandleKey( nKey )` | Edicion caracter a caracter |
| `GetValue()` | Devuelve valor |
| `SetValue( uVal )` | Asigna valor |

### Datos internos
| Dato | Descripcion |
|------|-------------|
| `uVar` | Variable vinculada |
| `cBuffer` | Buffer de edicion |
| `cPicture` | Picture Clipper |
| `cType` | "C", "N", "D", "L" |
| `lPassword` | Modo contrasena |
| `bWhen` | Codeblock condicional de entrada |
| `bValid` | Codeblock de validacion al salir |

---

## 6. Clase TButton - Botones

```harbour
// TButton():New( nTop, nLeft, nBottom, nRight, oParent, cCaption, bAction )
oBtn := TButton():New( 25, 05, 25, 20, oWin, "GUARDAR", { || GuardarTodo() } )
oBtn := TButton():New( 25, 25, 25, 40, oWin, "CANCELAR", { || oWin:Close() } )
```

### Comportamiento visual
- **Normal**: Relieve raised, color `CLR_BUTTON`
- **Con foco**: Relieve recessed, color `CLR_BUT_FOC`
- **Click**: Flash de colores invertidos

### Metodos
| Metodo | Descripcion |
|--------|-------------|
| `New( nTop, nLeft, nBottom, nRight, oPar, cCaption, bAction )` | Constructor |
| `Paint()` | Dibuja boton |
| `Click()` | Ejecuta bAction (con flash) |
| `HandleKey( nKey )` | ENTER/ESPACIO disparan Click |

### Datos
| Dato | Descripcion |
|------|-------------|
| `cCaption` | Texto del boton |
| `bAction` | Codeblock a ejecutar |
| `lPressed` | Flag de presionado |

---

## 7. Clase TCheck - Casillas de verificacion

```harbour
oCheck := TCheck():New( 10, 10, "Facturado", .F., oWin )
```

Apariencia: `[X] Facturado` o `[ ] Facturado`. SPACE/ENTER alternan.

### Metodos
| Metodo | Descripcion |
|--------|-------------|
| `New( nRow, nCol, cText, lDefault, oPar )` | Constructor |
| `Paint()` | Dibuja `[X]` o `[ ]` + texto |
| `HandleKey( nKey )` | SPACE/ENTER disparan Toggle |
| `Toggle()` | Alterna estado |
| `GetValue()` | Devuelve `::lValue` (.T./.F.) |
| `SetValue( lVal )` | Asigna valor y repinta |

### Datos
| Dato | Descripcion |
|------|-------------|
| `cCaption` | Texto descriptivo |
| `lValue` | Estado actual |
| `bChange` | Codeblock opcional ejecutado al cambiar |

---

## 8. Clase TCombo - Listas desplegables

Soporta dos formatos de array:
- **Simple**: `{ "Sevilla", "Cordoba", "Malaga" }` -> valor = etiqueta
- **Asociado**: `{ {1,"Activo"}, {2,"Pendiente"} }` -> valor = 1ra col, etiqueta = 2da

```harbour
LOCAL aItems := { "Contado", "Credito 30d", "Credito 60d", "Cheque" }
oCombo := TCombo():New( 10, 10, 20, aItems, 1, oWin )
```

### Metodos
| Metodo | Descripcion |
|--------|-------------|
| `New( nRow, nCol, nWidth, aOpts, nDefault, oPar )` | Constructor |
| `Paint()` | Dibuja el combo cerrado |
| `HandleKey( nKey )` | SPACE/F4/Letra abren lista |
| `Open()` | Despliega lista y gestiona seleccion |
| `Label( nIdx )` | Etiqueta para indice dado |
| `SetIndex( nIdx )` | Cambia indice y actualiza xValue |
| `GetValue()` | Devuelve `::xValue` (valor real) |
| `SetValue( xVal )` | Busca y selecciona por valor |
| `FindByPrefix( cChar, nFromIdx )` | Busqueda incremental |

### Datos
| Dato | Descripcion |
|------|-------------|
| `aOptions` | Array de opciones |
| `lAssoc` | .T. si formato asociado |
| `nSelected` | Indice seleccionado (1..N) |
| `xValue` | Valor real (a guardar en BD) |
| `nMaxList` | Max filas visibles al desplegar (defecto 8) |
| `bChange` | Codeblock al cambiar seleccion |

---

## 9. Clase TGrid - Rejillas de datos

### Creacion
```harbour
LOCAL oGrid
LOCAL aData := { ;
    { "LINEA" => 1, "ARTICULO" => "ART001", "DESCRIPC" => "Producto X", ;
      "CANTIDAD" => 2, "PRECIO" => 150.50, "IMPORTE" => 301.00 } ;
}

oGrid := TGrid():New( 10, 02, 24, 118, oWin )
oGrid:AddColumn( "L",        3,  { |h| Str( h[ "LINEA" ], 3 ) } )
oGrid:AddColumn( "Codigo",  10, { |h| h[ "ARTICULO" ] }, "@!" )
oGrid:AddColumn( "Descripcion", 30, { |h| h[ "DESCRIPC" ] } )
oGrid:AddColumn( "Cant",    8,  { |h| Str( h[ "CANTIDAD" ], 8, 2 ) }, "999999.9" )
oGrid:AddColumn( "Importe", 12, { |h| Str( h[ "IMPORTE" ], 12, 2 ) }, "999,999.99" )
oGrid:aData := aData
```

### Columnas: `AddColumn( cHeader, nWidth, bGetValue, cPicture )`

| Parametro | Descripcion |
|-----------|-------------|
| `cHeader` | Texto del encabezado |
| `nWidth` | Ancho en columnas de caracteres |
| `bGetValue` | Codeblock `{ |h| ... }` que extrae el valor del hash |
| `cPicture` | Picture Clipper opcional para formatear |

### Eventos
```harbour
oGrid:bEnter  := { |g| EditarLinea( g:nCurRow ) }   // F2 / doble click
oGrid:bInsert := { || AgregarLinea() }               // flecha abajo en ultima fila
oGrid:bChange := { |g| ActualizarTotales() }         // al cambiar fila
oGrid:bDelete := { |g| EliminarLinea( g:nCurRow ) }  // DEL
```

**Nota**: `bChange` se ejecuta en cada movimiento de fila (flechas, RePag, AvPag, click).
Usar solo si es imprescindible (ej. formularios que recalculan totales).
Para un visor de datos (solo lectura), dejarlo NIL para maximo rendimiento.

### Navegacion programatica
```harbour
oGrid:GoTop()
oGrid:GoBottom()
oGrid:GoUp()
oGrid:GoDown()
oGrid:PageUp()
oGrid:PageDown()
```

### Metodos
| Metodo | Descripcion |
|--------|-------------|
| `New( nTop, nLeft, nBottom, nRight, oPar )` | Constructor |
| `AddColumn( cHeader, nWidth, bGetVal, cPic )` | Define columna |
| `Paint()` | Dibuja grid completo |
| `PaintHeader()` | Solo encabezados |
| `PaintRow( nRow )` | Fila especifica |
| `HandleKey( nKey )` | Navegacion y eventos |
| `GoTop()` / `GoBottom()` | Ir a primera/ultima fila |
| `GoUp()` / `GoDown()` | Fila anterior/siguiente |
| `PageUp()` / `PageDown()` | Pagina arriba/abajo |
| `CurrentRow()` | Calcula fila en pantalla a partir de nCurRow |
| `IsRowEmpty( nRow )` | Verifica si fila esta vacia |
| `ColPos( nCol )` | Columna visual de una columna |
| `CalcVisibleRows()` | Calcula filas visibles |
| `SeekChar( cChar )` | Busqueda incremental por tecla |
| `RowCount()` | `Len( ::aData )` (INLINE) |
| `ResetSeek()` | Reinicia buffer de busqueda (INLINE) |

### Datos
| Dato | Descripcion |
|------|-------------|
| `aColumns` | Array de columnas |
| `aData` | Array de hashes (datos) |
| `nTopRow` | Primera fila visible |
| `nCurRow` | Fila seleccionada actual |
| `nVisibleRows` | Filas visibles en pantalla |
| `bEnter` | Codeblock al pulsar Enter/F2 |
| `bInsert` | Codeblock al insertar |
| `bChange` | Codeblock al cambiar fila |
| `bDelete` | Codeblock al borrar (DEL) |

---

## 10. Clase TTable - Acceso a DBF

Wrapper OOP sobre RDD DBFCDX. Soporta apertura, navegacion, busqueda y acceso a campos. Sin edicion todavia.

### Creacion y apertura
```harbour
LOCAL oTab

oTab := TTable():New( "CLIENTES", "CLIENTES.DBF", { ;
    { "CODIGO", "CODIGO" }, ;
    { "NOMBRE", "NOMBRE" } ;
} )

IF oTab:Open()
    ? "Tabla abierta correctamente"
ENDIF
```

### Navegacion
```harbour
oTab:GoTop()
oTab:GoBottom()
oTab:Skip( 5 )
oTab:Skip( -1 )
oTab:Goto( 100 )
```

### Estado
```harbour
oTab:Eof()
oTab:Bof()
oTab:RecNo()
oTab:LastRec()
oTab:Used()        // INLINE, devuelve ::lOpen
```

### Busqueda
```harbour
// Por el indice activo
IF oTab:Seek( "CLI001" )
    ? oTab:FieldGet( "NOMBRE" )
ENDIF

// Por un tag concreto
IF oTab:Seek( "Martinez", "NOMBRE" )
    // ...
ENDIF
```

### Acceso a campos
```harbour
cNombre := oTab:FieldGet( "NOMBRE" )
oTab:FieldPut( "NOMBRE", "Nuevo nombre" )
```

### Metodos
| Metodo | Descripcion |
|--------|-------------|
| `New( cAlias, cFile, aIndexes )` | Constructor. `aIndexes := { { cTag, cExpr }, ... }` |
| `Open()` | Abre DBF, crea CDX si no existe, asigna indices |
| `Close()` | Cierra tabla |
| `Select()` | Selecciona el area de la tabla |
| `GoTop()` / `GoBottom()` / `Skip()` / `Goto()` | Navegacion |
| `Eof()` / `Bof()` / `RecNo()` / `LastRec()` | Estado |
| `Seek( uKey, cTag )` | Busqueda por clave |
| `SetOrder( cTag )` | Cambia indice activo |
| `FieldGet( cName )` | Lee valor de campo |
| `FieldPut( cName, uVal )` | Escribe valor de campo |

---

## 11. Clase TMenu - Menus de texto

Menu estilo Clipper para la aplicacion principal. Incluye subclase `TMenuPop` para popups.

```harbour
LOCAL oMenu
LOCAL aItems := { ;
    { "1", "Altas/  Facturas",  .F., .F. }, ;
    { "2", "Altas/  Pedidos",   .F., .F. }, ;
    { "3", "Mestros/Clientes", .F., .F. }, ;
    { "4", "Informes",         .F., .F. }, ;
    { "0", "Salir",             .F., .F. } ;
}

oMenu := TMenu():New( 02, 02, MaxRow() - 2, 30, oWin )
oMenu:aItems := aItems
oMenu:bAction := { |o, n| ProcesarOpcion( o:aItems[ n, 2 ] ) }
oMenu:Paint()
```

### Metodos TMenu
| Metodo | Descripcion |
|--------|-------------|
| `New( nTop, nLeft, nBottom, nRight, oPar, aItems, nSel )` | Constructor |
| `Build()` | Construye estructura interna |
| `Paint()` | Dibuja menu |
| `ShowMsg( cMsg )` | Muestra mensaje en barra |
| `Activate()` | Bucle de teclado del menu |
| `ProcKey( nKey )` | Procesa tecla |
| `OpenPopup( nItem )` | Abre submenu popup |
| `Run()` | INLINE: llama a Activate() |

### Metodos TMenuPop
| Metodo | Descripcion |
|--------|-------------|
| `New()` / `Build()` | Constructor y construccion |
| `Open( nTop, nLeft )` | Abre popup en posicion |
| `CalcSize()` | Calcula dimensiones |
| `Paint()` | Dibuja popup |
| `Run()` | Bucle de seleccion |
| `ExecItem( nSel )` | Ejecuta item seleccionado |
| `Close()` | Cierra popup |

---

## 12. Dialogos modales: MsgBox / MsgYesNo

### MsgBox / MsgInfo / MsgStop
```harbour
MsgBox( "Proceso terminado", "Informacion" )
MsgInfo( "Todo correcto" )
MsgStop( "Error al guardar" )
```

Las tres devuelven `K_ENTER`. `MsgInfo` y `MsgStop` son wrappers que anaden prefijo "INFO:" / "ALERTA:" al titulo.

### MsgYesNo / MsgConfirm
```harbour
IF MsgYesNo( "Desea guardar los cambios?", "Confirmacion" )
    Guardar()
ENDIF
```

Devuelve `.T.` (SI) o `.F.` (NO / ESC). `MsgConfirm` es alias de `MsgYesNo`.

---

## 13. Funciones Gfx - Capa grafica

### Bloqueo de refresco (siempre en pares)
```harbour
GfxLock()       // Inicia bloque
// ... pintado ...
GfxUnlock()     // Ejecuta todas las operaciones
```

### Pintado basico
```harbour
GfxClear( nT, nL, nB, nR, "W/N" )          // Limpiar rectangulo
GfxBox( nT, nL, nB, nR, "B/W" )            // Marco simple ASCII
GfxText( nRow, nCol, "Hola", "W+/B" )      // Texto con color
```

### Relieves WVG
```harbour
GfxRaised( nT, nL, nB, nR )                // Marco levantado
GfxRecessed( nT, nL, nB, nR )              // Marco hundido
GfxGroup( nT, nL, nB, nR )                 // Linea fina (agrupacion)
GfxFillSolid( nT, nL, nB, nR, "W+/B" )     // Relleno opaco
```

### Atajos de pintado
```harbour
GfxPanel( nT, nL, nB, nR, cColor )         // Clear + Raised (ventanas)
GfxField( nT, nL, nB, nR, cColor )         // Clear + Recessed (campos)
GfxShadow( nT, nL, nB, nR )                // Sombra a derecha y abajo
```

### Save/Restore (para ventanas modales)
```harbour
xBackup := GfxSave( nT-2, nL-2, nB+2, nR+2 )
GfxRestore( nT-2, nL-2, nB+2, nR+2, xBackup )
```

### Invalidation
```harbour
GfxInvalidate( nT, nL, nB, nR )            // Forzar redibujado WVG
```

### Stack de pintado (uso interno de TWindow)
```harbour
aPrev := GfxPaintPush()                    // Guardar nivel actual
GfxPaintAdd( "marco", { || GfxRaised(5,5,20,60) } )
GfxPaintPop( aPrev )                       // Restaurar nivel

GfxPaintGet()                              // Obtener stack actual
GfxPaintClear()                            // Limpiar stack
```

### Cursor y posicion
```harbour
GfxCursor( SC_NONE )                       // Ocultar cursor
GfxCursor( SC_NORMAL )                     // Mostrar cursor (subrayado)
GfxSetPos( nRow, nCol )                    // Posicionar cursor
```

### Configuracion de ventana del SO
```harbour
GfxSetFont( "Courier New", 14, 8 )         // Fuente monoespaciada
GfxFixSize( .T. )                          // Ventana tamano fijo
GfxMaxRow() / GfxMaxCol()                  // Dimensiones actuales
GfxSetTitle( "Mi App" )                    // Titulo ventana
GfxGetTitle()                              // Leer titulo actual
GfxSetIcon( "app.ico" )                    // Icono desde archivo
GfxSetIconRes( 101 )                       // Icono desde recurso .exe
GfxSetClosable( .T. )                      // Permitir cerrar con [X]
```

### Portapapeles
```harbour
cText := GfxClipboardGet()                 // Leer portapapeles
GfxClipboardSet( "texto" )                 // Escribir portapapeles
```

---

## 14. Funciones Util - Utilidades

Definidas en `Util.prg` (raiz del proyecto). Ver tambien `MsgBox.prg` y `MsgYesNo.prg` en `api/`.

### InitApp
```harbour
InitApp( 40, 132 )  // nRows, nCols, cFont, nFontH, nFontW
```
Inicializa RDD DBFCDX, fuente, modo pantalla, cursor apagado. Llamar desde `Main()`.

### ErrSys
```harbour
ErrorBlock( { |e| ErrSys( e ) } )
```
Manejador de errores critico. Escribe en `error.log` con pila de llamadas y termina. No muestra UI.

### ABRIR_TABLA
```harbour
IF ABRIR_TABLA( "CLIENTES", "CLI", "CODIGO" )
    // Tabla abierta
ENDIF
```
Apertura segura de DBF con reintento en caso de ocupado. Parametros:
- `cArchivo`: nombre del .dbf (sin extension)
- `cAlias`: alias (opcional, defecto = cArchivo)
- `cIndice`: tag de indice a activar (opcional)
- `aCdxAdicionales`: array de CDX adicionales a asociar (opcional)

### Bloqueos de red
```harbour
NetFLock()          // Bloquear archivo completo (con reintento + MsgYesNo)
NetRLock()          // Bloquear registro actual (con reintento + MsgYesNo)
NetUnLock()         // Liberar todos los bloqueos del area
```
Devuelven `.T.` si se obtuvo el bloqueo, `.F.` si el usuario cancelo.

### GetNextNum
```harbour
cNum := GetNextNum( "FAC", "Factura" )
```
Contador correlativo de documentos. Lee/actualiza contador en tabla `CONTADOR.DBF`. Devuelve string con prefijo + numero zero-filled (ej. `FAC0000001`).

### EvalSafe
```harbour
EvalSafe( bBlock, cContext, xArg1, xArg2, xArg3 )
```
Ejecuta un codeblock con proteccion de errores. Si falla, registra en `error.log` y muestra `MsgStop`. Usado internamente por controles UI.

### AppLockAcquire / AppLockRelease
```harbour
IF !AppLockAcquire()
    MsgStop( "La aplicacion ya esta en ejecucion." )
    QUIT
ENDIF
// ... al salir:
AppLockRelease()
```
Previene ejecucion multiple de la app en el mismo terminal mediante archivo `.lck` en `%TEMP%`.

### Validacion de NIF/CIF
```harbour
ValidNifFormato( cNif, lSilent )      // Valida solo formato (9 chars, letra final)
ValidNifFiscal( cNif, lSilent )       // Valida con digito de control (NIF + CIF)
ValidNif( cNif, lSilent )             // Alias de ValidNifFiscal
ValidNifObligatorio( cNif, lSilent )  // Como Fiscal pero exige no vacio
```

### Popups de seleccion
```harbour
cCod := PopupSelect( "Seleccionar Cliente", aData, aCols, nSeekCol, cNewBtn )
cCod := LookupCliente()                // Popup preconfigurado de clientes
cCod := LookupFormaPago()              // Popup preconfigurado de formas de pago
```
`PopupSelect` muestra una ventana modal con `TGrid` y botones Aceptar/Nuevo/Cancelar. Devuelve el codigo de la fila seleccionada o `""` si cancelo. Si pulsa "Nuevo", devuelve `POPUP_NEW` (constante `"__POPUP_NEW__"`).

### Otras utilidades
```harbour
DirExiste( cRuta )                     // .T. si el directorio existe
MiDefault( xVar, xDefecto )           // Asigna defecto si NIL (funcional)
IsDbUsed( cAlias ) / DBUSED( cAlias ) // Verifica si area DBF esta abierta
DbFieldValue( cField, xDefault )      // Lee campo o devuelve defecto
DbFieldPutIf( cField, xValue )        // Escribe campo si existe
GetDbArea( cAlias )                   // Devuelve numero de area (0 si no)
ASPLIT( cString, cDelim )            // Split de string a array
CEILING( nNum )                       // Redondeo hacia arriba
ArraySkip( nSkip, nRow, nLen )        // Calcula nueva posicion en array con wrap
ErrorLogAppend( cText )               // Anyade texto a error.log

---

## 15. Constantes de color (OOp.ch)

| Constante | Valor | Descripcion |
|-----------|-------|-------------|
| `CLR_WINDOW` | `"N/W"` | Fondo de ventana |
| `CLR_PANEL` | `"N/W*"` | Panel/fondo de formulario |
| `CLR_GET` | `"N/W*"` | Campo GET normal |
| `CLR_GET_FOC` | `"W+/BG"` | GET con foco |
| `CLR_BUTTON` | `"N/W"` | Boton normal |
| `CLR_BUT_FOC` | `"W+/BG"` | Boton con foco |
| `CLR_FOCUS` | `"W+/BG"` | Color de foco universal |
| `CLR_WIN_TITLE_ACT` | `"W+/B"` | Barra titulo activa |
| `CLR_WIN_TITLE_INA` | `"W+/N"` | Barra titulo inactiva |
| `CLR_WIN_BODY` | `CLR_WINDOW` | Cuerpo de ventana |
| `CLR_GRID_HDR` | `"W+/B"` | Encabezado de grid |
| `CLR_GRID_SEL` | `CLR_FOCUS` | Fila seleccionada (con foco) |
| `CLR_GRID_INA` | `"N/BG"` | Fila seleccionada (sin foco) |

### Cursores
| Constante | Valor | Descripcion |
|-----------|-------|-------------|
| `SC_NONE` | `0` | Cursor invisible |
| `SC_NORMAL` | `1` | Cursor subrayado |

### Indices de definicion de columna en TGrid
| Constante | Valor | Descripcion |
|-----------|-------|-------------|
| `COL_TITLE` | `1` | Texto del encabezado |
| `COL_WIDTH` | `2` | Ancho en caracteres |
| `COL_PICTURE` | `3` | Picture Clipper |
| `COL_GETVAL` | `4` | Codeblock de valor |

---

## 16. Patron de diseno: TForm (referencia)

La clase `TForm` no existe como archivo independiente. En su lugar, los formularios comerciales (facturas, pedidos, presupuestos) se construyen directamente combinando `TWindow` + `TGrid` + `TGet` + `TButton` con una estructura estandar.

### Estructura tipica
```harbour
METHOD NuevaFactura() CLASS TFactura
    LOCAL oWin, oGrid, aCabDefs, aDetCols

    oWin := TWindow():New( ROW_TOP, COL_LEFT, ROW_BOT, COL_RIGHT, "FACTURA" )
    oWin:cBgColor := CLR_PANEL

    // Datos empresa (fila 1)
    oWin:AddCtrl( TLabel():New( ROW_EMP, COL_LABEL, "Empresa: " + hEmp[ "NOMBRE" ], oWin ) )
    oWin:AddCtrl( TLabel():New( ROW_EMP, 50, "NIF: " + hEmp[ "NIF" ], oWin ) )

    // Campos cabecera (desde ROW_CAB, incrementando de 2 en 2)
    oWin:AddCtrl( TLabel():New( ROW_CAB, COL_LABEL, "N Factura:", oWin ) )
    oWin:AddCtrl( TGet():New( ROW_CAB, COL_FIELD, "", "@!", oWin, 12 ) )

    oWin:AddCtrl( TLabel():New( ROW_CAB+2, COL_LABEL, "Fecha:", oWin ) )
    oWin:AddCtrl( TGet():New( ROW_CAB+2, COL_FIELD, Date(), "99/99/9999", oWin ) )

    // Grid detalle
    oGrid := TGrid():New( ROW_DET, COL_LEFT+2, ROW_TOT-2, COL_RIGHT-2, oWin )
    oGrid:AddColumn( "L",   3,  { |h| Str( h[ "LINEA" ], 3 ) } )
    oGrid:AddColumn( "Codigo", 10, { |h| h[ "CODIGO" ] }, "@!" )
    oGrid:AddColumn( "Descripcion", 30, { |h| h[ "DESCRIPC" ] } )
    oGrid:AddColumn( "Cant", 6,  { |h| Str( h[ "CANTIDAD" ], 6, 2 ) }, "9999.99" )
    oGrid:AddColumn( "Importe", 10, { |h| Str( h[ "IMPORTE" ], 10, 2 ) }, "999,999.99" )
    oGrid:bInsert := { || AgregarLinea() }
    oGrid:bEnter  := { |g| EditarLinea( g:nCurRow ) }
    oWin:AddCtrl( oGrid )

    // Totales
    oWin:AddCtrl( TLabel():New( ROW_TOT, 70, "Total:", oWin ) )
    oWin:AddCtrl( TGet():New( ROW_TOT, 78, 0, "999,999.99", oWin ) )

    // Botones
    oWin:AddCtrl( TButton():New( ROW_BTN, 05, ROW_BTN, 20, oWin, "GUARDAR", ;
        { || Guardar(), oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( ROW_BTN, 25, ROW_BTN, 42, oWin, "CANCELAR", ;
        { || oWin:Close() } ) )

    oWin:Run()
RETURN Self
```

### Coordenadas tipicas (para 120 columnas)
```harbour
#define ROW_TOP    03
#define ROW_BOT    33
#define COL_LEFT   02
#define COL_RIGHT  122

#define ROW_EMP    01
#define ROW_CAB    03
#define ROW_DET    12
#define ROW_TOT    27
#define ROW_BTN    31
#define COL_LABEL  02
#define COL_FIELD  16
```

---

## 17. Ejemplo completo: Alta de asiento

```harbour
#include "OOp.ch"
#include "inkey.ch"

FUNCTION AsientosForm()
    LOCAL oWin
    LOCAL oGetFec, oGetDesc
    LOCAL oGrid
    LOCAL aPartidas := {}

    oWin := TWindow():New( 03, 02, 35, 122, "ALTA DE ASIENTO CONTABLE" )
    oWin:cBgColor := CLR_PANEL

    // Cabecera
    oWin:AddCtrl( TLabel():New( 03, 02, "Fecha:", oWin ) )
    oGetFec := TGet():New( 03, 10, Date(), "99/99/9999", oWin )
    oWin:AddCtrl( oGetFec )

    oWin:AddCtrl( TLabel():New( 05, 02, "Descripcion:", oWin ) )
    oGetDesc := TGet():New( 05, 16, "" , "@!", oWin, 50 )
    oWin:AddCtrl( oGetDesc )

    // Grid de partidas
    oGrid := TGrid():New( 08, 02, 28, 120, oWin )
    oGrid:AddColumn( "Cuenta",  12, { |h| PadR( h[ "CUENTA" ], 12 ) }, "@!" )
    oGrid:AddColumn( "Descripcion", 30, { |h| PadR( h[ "DESC" ], 30 ) } )
    oGrid:AddColumn( "Debe",   12, { |h| PadL( Str( h[ "DEBE" ], 12, 2 ), 12 ) }, "999,999.99" )
    oGrid:AddColumn( "Haber",  12, { |h| PadL( Str( h[ "HABER" ], 12, 2 ), 12 ) }, "999,999.99" )
    oGrid:aData := aPartidas
    oGrid:bEnter  := { |g| EditarPartida( g:nCurRow, aPartidas, oGrid ) }
    oGrid:bInsert := { || AgregarPartida( aPartidas, oGrid ) }
    oGrid:bDelete := { |g| BorrarPartida( g:nCurRow, aPartidas, oGrid ) }
    oWin:AddCtrl( oGrid )

    // Totales
    oWin:AddCtrl( TLabel():New( 29, 80, "Total Debe:", oWin ) )
    oWin:AddCtrl( TGet():New( 29, 95, 0, "999,999.99", oWin ) )
    oWin:AddCtrl( TLabel():New( 30, 80, "Total Haber:", oWin ) )
    oWin:AddCtrl( TGet():New( 30, 95, 0, "999,999.99", oWin ) )

    // Botones
    oWin:AddCtrl( TButton():New( 32, 05, 32, 20, oWin, "GUARDAR", ;
        { || oWin:Close() } ) )
    oWin:AddCtrl( TButton():New( 32, 25, 32, 42, oWin, "CANCELAR", ;
        { || oWin:Close() } ) )

    oWin:Run()
RETURN NIL
```

---

## Apindice: Errores comunes y soluciones

| Error | Causa | Solucion |
|-------|-------|----------|
| `NETRLOCK not found` | Falta `Util.prg` | Anyadir `Util.prg` al `.hbp` |
| `undefined reference to HB_FUN_WVT_DRAWBOXRAISED` | Falta `gtwvg.hbc` | Anyadir `gtwvg.hbc` al `.hbp` |
| `W0002: Redefinition of SC_NONE` | `OOp.ch` se incluye multiples veces | Normal en Harbour, no afecta |
| `duplicate definition of HB_FUN_MSGINFO` | `MsgBox.prg` y otro MsgBox duplicados | Verificar que solo hay un MsgBox.prg |
| Ventana con artefactos visuales | No se uso `GfxFillSolid` antes de pintar | Usar stack `GfxPaintPush/Pop` |
| `DBFCDX not loaded` | Falta `REQUEST DBFCDX` en `Main()` | Incluir REQUEST o llamar a `InitApp()` que lo hace |

---

**Fin del manual.** Para dudas especificas, revisar los archivos `.prg` en `api/` que contienen comentarios detallados en cada metodo.
