# REFERENCIA DE SINTAXIS DEL FRAMEWORK
## Harbour / GTWVG - Estilo Clipper 5.x

---

## INDICE

1. OOp.ch — Constantes de color y macros
2. Gfx.prg — Capa grafica (servicios de pantalla)
3. TControl — Clase base de todos los controles
4. TWindow — Ventana modal
5. TLabel — Etiqueta de texto estatico
6. TGet — Campo de edicion
7. TButton — Boton de accion
8. TCheck — Casilla de verificacion
9. TCombo — Lista desplegable
10. TGrid — Tabla de datos navegable
11. TTable — Wrapper sobre DBF/CDX
12. MsgBox / MsgInfo / MsgStop — Cuadros de mensaje
13. MsgYesNo / MsgConfirm — Cuadro de confirmacion
14. InitApp / ErrSys — Utilidades de arranque

---

## 1. OOp.ch — Constantes de color y macros

```harbour
// Colores principales
CLR_WINDOW      "N/W"      // fondo normal (negro sobre blanco)
CLR_GET         "N/W*"     // campo de edicion sin foco
CLR_FOCUS       "W+/BG"    // foco universal (blanco brillante/cian)
CLR_GET_FOC     CLR_FOCUS  // alias de foco para Gets
CLR_BUTTON      "N/W"      // boton sin foco
CLR_BUT_FOC     CLR_FOCUS  // boton con foco
CLR_GRID_HDR    "W+/B"     // cabecera de grid (blanco/azul)
CLR_GRID_SEL    CLR_FOCUS  // fila seleccionada con foco
CLR_GRID_INA    "N/BG"     // fila seleccionada sin foco

// Cursor
SC_NONE         0          // cursor invisible
SC_NORMAL       1          // cursor visible

// Indices de columna para TGrid
COL_TITLE       1
COL_WIDTH       2
COL_PICTURE     3
COL_GETVAL      4

// Macro DEFAULT (si variable es NIL, asigna valor)
DEFAULT <var> TO <valor>
```

---

## 2. Gfx.prg — Servicios graficos

### Bloqueo de refresco

```harbour
GfxLock()          // bloquea refresco WVG (evita parpadeo)
GfxUnlock()        // desbloquea y vuelca todo de una vez
```

### Pintado basico

```harbour
GfxClear( nT, nL, nB, nR [, cColor] )     // rellena con espacios
GfxBox(   nT, nL, nB, nR [, cColor] )     // borde ASCII clasico
GfxText(  nRow, nCol, cTxt [, cColor] )   // escribe texto
```

### Relieves WVG

```harbour
GfxRaised(   nT, nL, nB, nR )   // relieve hacia afuera (ventana, boton)
GfxRecessed( nT, nL, nB, nR )   // relieve hacia adentro (Get, lista)
GfxGroup(    nT, nL, nB, nR )   // linea fina de agrupacion
GfxFillSolid( nT, nL, nB, nR [, cColor] ) // rellena capa grafica WVG
```

### Save / Restore

```harbour
xHandle := GfxSave(    nT, nL, nB, nR )            // guarda zona
           GfxRestore( nT, nL, nB, nR, xHandle )   // restaura zona
           GfxInvalidate( nT, nL, nB, nR )          // fuerza repintado
```

NOTA: Las coordenadas de Save y Restore DEBEN ser identicas.

### Cursor y posicion

```harbour
GfxCursor( SC_NONE )           // ocultar cursor
GfxCursor( SC_NORMAL )         // mostrar cursor
GfxSetPos( nFila, nCol )       // posicionar cursor
```

### Inicializacion

```harbour
GfxSetFont( "Lucida Console", 16, 8 )   // fuente monoespaciada
GfxFixSize( .T. )                       // bloquear resize de ventana
nFilas := GfxMaxRow()                   // filas disponibles (base 0)
nCols  := GfxMaxCol()                   // columnas disponibles (base 0)
```

### Atajos compuestos

```harbour
GfxShadow( nT, nL, nB, nR )                   // sombra negra derecha/abajo
GfxPanel(  nT, nL, nB, nR [, cColor] )        // limpiar + raised
GfxField(  nT, nL, nB, nR [, cColor] )        // limpiar + recessed
```

### Titulo e icono de ventana SO

```harbour
GfxSetTitle( "Mi App v1.0" )
GfxGetTitle()
GfxSetIcon( "app.ico" )          // icono desde archivo externo
GfxSetIconRes( 100 )             // icono compilado en el .exe
```

### Portapapeles

```harbour
cTexto := GfxClipboardGet()
          GfxClipboardSet( "texto a copiar" )
```

### Stack de bloques de pintado (GTWVG)

```harbour
aPrev := GfxPaintPush( [aNuevos] )   // empila nivel nuevo
         GfxPaintPop( aPrev )         // restaura nivel previo
         GfxPaintAdd( cNombre, bBlk [, aRect] )  // agrega bloque
aAct  := GfxPaintGet()               // consulta array activo
         GfxPaintClear()              // vacia nivel actual
```

---

## 3. TControl — Clase base

No se instancia directamente. Todas las clases heredan de ella.

### Propiedades DATA

```harbour
::nTop, ::nLeft, ::nBottom, ::nRight   // coordenadas absolutas
::oParent                              // ventana contenedora
::lVisible                             // .T. = visible
::lEnabled                             // .T. = activo
::lFocused                             // .T. = tiene foco
::lTabStop                             // .T. = recibe foco con TAB
::cColor                               // color por defecto
```

### Metodos heredados (usables en todas las clases)

```harbour
::Paint()                             // repinta el control
::Refresh()                           // alias de Paint()
::SetFocus()                          // activa foco
::KillFocus()                         // desactiva foco
::HandleKey( nKey )                   // despacho de tecla
::Show()                              // hace visible y repinta
::Hide()                              // oculta e invalida zona
::Enable()                            // habilita el control
::Disable()                           // deshabilita el control
::IsHit( nRow, nCol )                 // .T. si coord cae dentro

// Pintado directo
::DrawRaised()                        // relieve hacia afuera
::DrawRecessed()                      // relieve hacia adentro
::DrawGroup()                         // linea fina
::DrawClear()                         // rellena con cColor
::DrawBox()                           // borde ASCII
::Invalidate()                        // marca zona como sucia
::DrawText( nRelRow, nRelCol, cTxt [, cCol] )  // texto relativo

// Lock/Unlock de refresco
::Lock()
::Unlock()
```

### Constructor (uso interno por clases hijas)

```harbour
::TControl:New( nTop, nLeft, nBottom, nRight, oParent )
// Coordenadas relativas al parent (se suman nTop/nLeft del padre)
```

---

## 4. TWindow — Ventana modal

### Constructor

```harbour
oWin := TWindow():New( nTop, nLeft, nBottom, nRight, cTitulo )
```

### Propiedades DATA relevantes

```harbour
::cTitle      // titulo de la ventana
::aCtrls      // array de controles hijos
::lModal      // siempre .T. en esta version
::oOwner      // ventana padre detectada automaticamente en Run()
::xBackup     // snapshot de GfxSave (gestionado por Run/Close)
```

### Metodos publicos

```harbour
oWin:AddCtrl( oControl )      // registra un control hijo
oWin:Run()                    // inicia el bucle modal (bloquea)
oWin:Close()                  // senaliza salida del bucle
oWin:Paint()                  // pinta ventana completa
oWin:Refresh()                // alias de Paint()
oWin:Center()                 // centra la ventana en pantalla
oWin:SetFocus( nPos )         // cambia foco al control nPos
oWin:NextFocus()              // foco al siguiente TabStop
oWin:PrevFocus()              // foco al anterior TabStop
```

### Esquema de uso completo

```harbour
LOCAL oWin, oCtrl1, oCtrl2

oWin := TWindow():New( 5, 20, 30, 100, "Mi Formulario" )

// Crear controles con oWin como parent
oCtrl1 := TLabel():New( 2, 3, "Nombre:", oWin )
oCtrl2 := TGet():New( 2, 12, cNombre, "@!", oWin )

// Registrar en la ventana
oWin:AddCtrl( oCtrl1 )
oWin:AddCtrl( oCtrl2 )

// Ejecutar (bloquea hasta Close())
oWin:Run()
```

---

## 5. TLabel — Etiqueta estatica

```harbour
oLbl := TLabel():New( nRow, nCol, cTexto, oParent )

// nRow, nCol : posicion relativa al parent
// cTexto     : texto a mostrar
// oParent    : ventana contenedora

// Cambiar texto despues de crear
oLbl:SetText( "Nuevo texto" )

// lTabStop = .F. (no recibe foco con TAB)
```

---

## 6. TGet — Campo de edicion

### Constructor

```harbour
oGet := TGet():New( nRow, nCol, uValor, cPicture, oParent )

// uValor   : variable local del tipo a editar
// cPicture : formato de edicion (ver ejemplos abajo)
```

### Tipos soportados y pictures tipicos

```harbour
// Caracter
oNom := TGet():New( 2, 14, cNombre, "@!",        oWin )  // mayusculas
oNom := TGet():New( 2, 14, cNombre, "@!",        oWin )  // libre

// Numerico
oNum := TGet():New( 4, 14, nEdad,   "999",       oWin )
oPre := TGet():New( 6, 14, nPrecio, "999,999.99", oWin )

// Fecha
oFch := TGet():New( 8, 14, dAlta,   "99/99/9999", oWin )

// Logico (ESPACIO alterna Si/No)
oAct := TGet():New( 10, 14, lActivo, "L",         oWin )
```

### Codeblocks de validacion

```harbour
// bWhen: si devuelve .F., el campo no recibe foco
oGet:bWhen  := {| o | lCondicion }

// bValid: si devuelve .F., el cursor no abandona el campo
oGet:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
```

### Recuperar el valor tras Run()

```harbour
oWin:Run()
cNombre := AllTrim( oNom:uVar )   // valor editado
nEdad   := oEdad:uVar
dFecha  := oFch:uVar
lActivo := oAct:uVar
```

---

## 7. TButton — Boton de accion

```harbour
oBtn := TButton():New( nTop, nLeft, nBottom, nRight, ;
                       oParent, cCaption, bAction )

// cCaption : texto del boton
// bAction  : { || ... } ejecutado al pulsar

// Ejemplos
oBtAcep := TButton():New( 15, 20, 16, 39, oWin, ;
    "ACEPTAR", ;
    {|| Guardar(), oWin:Close() } )

oBtCanc := TButton():New( 15, 42, 16, 61, oWin, ;
    "CANCELAR", ;
    {|| oWin:Close() } )

// lTabStop = .T. (recibe foco con TAB)
// ENTER o SPACE ejecutan bAction
```

---

## 8. TCheck — Casilla de verificacion

```harbour
oChk := TCheck():New( nRow, nCol, cCaption, lDefault, oParent )

// cCaption : texto a la derecha de la casilla
// lDefault : estado inicial (.T. = marcada)

// Ancho automatico: 4 + Len( cCaption )

// Ejemplo
oChk := TCheck():New( 5, 3, "Acepta condiciones", .F., oWin )

// Codeblock de cambio
oChk:bChange := {| o | ProcesarCambio( o:lValue ) }

// ESPACIO o ENTER alternan el estado
// Leer el valor
lMarcada := oChk:lValue
```

---

## 9. TCombo — Lista desplegable

### Modo simple (valor = etiqueta)

```harbour
aOpts := { "Opcion A", "Opcion B", "Opcion C" }

oCmb := TCombo():New( nRow, nCol, nAncho, aOpts, nDefecto, oParent )
// nDefecto : indice inicial (1..N)

// Leer valor
cSelec := oCmb:xValue      // = la cadena seleccionada
nIdx   := oCmb:nSelected   // indice en el array
```

### Modo asociado (codigo + etiqueta)

```harbour
aOpts := { {1,"Activo"}, {2,"Pendiente"}, {3,"Baja"} }

oCmb := TCombo():New( nRow, nCol, 20, aOpts, 1, oParent )

// Leer valor
nCod  := oCmb:xValue      // = elemento [1] de la fila (el codigo)
cLbl  := oCmb:Label( oCmb:nSelected )  // etiqueta actual
```

### Codeblock de cambio

```harbour
oCmb:bChange := {| o | Actualizar( o:xValue ) }
```

### Teclas en estado cerrado

```harbour
F4 / SPACE / ALT+DOWN   // abre la lista
Letras/digitos          // busqueda incremental por primera letra
TAB / SH_TAB / ENTER    // navegan al siguiente control
```

### Teclas dentro de la lista abierta

```harbour
Arriba / Abajo          // navega una fila
RePag / AvPag           // navega una pagina
Inicio / Fin            // primera / ultima opcion
ENTER                   // selecciona y cierra
ESC / F4                // cierra sin cambiar
Letras                  // busqueda incremental
```

---

## 10. TGrid — Tabla de datos navegable

### Constructor y configuracion

```harbour
oGrid := TGrid():New( nTop, nLeft, nBottom, nRight, oParent )

// Datos (array de arrays, objetos o lo que sea)
oGrid:aData := aLineas

// Columna para busqueda incremental (1..N)
oGrid:nSeekCol := 1

// Maximo visible de filas (calculado automatico)
oGrid:nVisibleRows    // solo lectura (lo calcula CalcVisibleRows)
```

### Definicion de columnas

```harbour
oGrid:AddColumn( cTitulo, nAncho, cPicture, bGetVal )

// bGetVal es un codeblock { |aFila| ... } que devuelve el valor

oGrid:AddColumn( "Codigo",  6, "@!",         { |a| a[1] } )
oGrid:AddColumn( "Nombre", 30, "@!",         { |a| a[2] } )
oGrid:AddColumn( "Edad",    4, "999",        { |a| a[3] } )
oGrid:AddColumn( "Saldo",  12, "999,999.99", { |a| a[3]*a[4] } )
// La ultima es CALCULADA (no existe directamente en el array)
```

### Codeblocks de accion

```harbour
// Al pulsar ENTER o F2 sobre una fila no vacia
oGrid:bEnter := {| g | EditarFila( g:CurrentRow() ) }

// Al pulsar flecha abajo en la ultima fila no vacia
oGrid:bInsert := {| g | NuevaFila( g ) }

// Notificacion de cambio de fila (navegacion)
oGrid:bChange := {| g | ActualizarPanel( g:CurrentRow() ) }

// Override del detector de fila vacia
oGrid:bRowEmpty := {| aFila | Empty( aFila[1] ) }
```

### Metodos publicos

```harbour
aFila  := oGrid:CurrentRow()    // devuelve la fila actual (o NIL)
nTotal := oGrid:RowCount()      // Len( aData )
lVacia := oGrid:IsRowEmpty( n ) // .T. si fila n esta vacia
oGrid:GoTop()
oGrid:GoBottom()
oGrid:GoUp()
oGrid:GoDown()
oGrid:PageUp()
oGrid:PageDown()
oGrid:ResetSeek()               // limpia buffer de busqueda
```

### Teclas del grid

```harbour
Arriba / Abajo           // fila anterior / siguiente
RePag / AvPag            // pagina anterior / siguiente
Inicio / CTRL+RePag      // primera fila
Fin   / CTRL+AvPag       // ultima fila
ENTER / F2               // ejecuta bEnter
Letras / digitos         // busqueda incremental (nSeekCol)
TAB                      // sale del grid al siguiente control
```

---

## 11. TTable — Wrapper DBF/CDX

### Constructor

```harbour
oTab := TTable():New( cAlias, cFichero, aIndexes )

// aIndexes : { { "TAG1", "Campo1" }, { "TAG2", "Campo1+Campo2" } }
// Si NIL, sin indices (solo lectura secuencial)

oCltes := TTable():New( "CLTES", "datos\clientes.dbf", ;
    { { "COD", "CodClte" }, { "NIF", "NifClte" } } )
```

### Apertura y cierre

```harbour
IF oCltes:Open()
    // tabla abierta y lista
    ...
    oCltes:Close()
ENDIF

lAbierta := oCltes:Used()    // .T. si esta abierta
```

### Navegacion

```harbour
oCltes:GoTop()
oCltes:GoBottom()
oCltes:Skip( [nVeces] )    // default 1
oCltes:Goto( nRec )

lFin    := oCltes:Eof()
lPrinci := oCltes:Bof()
nActual := oCltes:RecNo()
nTotal  := oCltes:LastRec()
```

### Busqueda e indice

```harbour
oCltes:SetOrder( "NIF" )              // cambia indice activo
lEnc := oCltes:Seek( cNif )           // busca con indice activo
lEnc := oCltes:Seek( cNif, "NIF" )    // busca con indice especifico
```

### Lectura y escritura de campos

```harbour
cNombre := oCltes:FieldGet( "NOMBRE" )
           oCltes:FieldPut( "NOMBRE", "Nuevo nombre" )

// IMPORTANTE: FieldPut no gestiona bloqueo de red.
// Antes de modificar hacer NetRLock / NetFLock segun el protocolo.
```

---

## 12. MsgBox / MsgInfo / MsgStop

```harbour
// Cuadro informativo generico
MsgBox( cMensaje [, cTitulo] )

// Wrapper de informacion (prefija "INFO:")
MsgInfo( cMensaje [, cTitulo] )

// Wrapper de error/alerta (prefija "ALERTA:")
MsgStop( cMensaje [, cTitulo] )

// Todos devuelven K_ENTER al cerrar.
// Se cierran con ENTER, ESC o SPACE.
// Construidos con TWindow + TLabel + TButton (controles reales).
```

---

## 13. MsgYesNo / MsgConfirm

```harbour
lRespuesta := MsgYesNo( cMensaje [, cTitulo] )
// .T. = SI    .F. = NO / ESC

lRespuesta := MsgConfirm( cMensaje [, cTitulo] )
// alias amigable de MsgYesNo

// Uso tipico
IF MsgYesNo( "Desea guardar los cambios?", "Confirmar" )
    Guardar()
ENDIF

// Teclas
// Flechas / TAB     : cambia boton activo (SI <-> NO)
// ENTER             : confirma boton actual
// ESC               : equivale a NO
// "S" / "s"         : selecciona SI directamente
// "N" / "n"         : selecciona NO directamente
```

---

## 14. InitApp / ErrSys

```harbour
// Inicializacion completa del entorno (llamar desde Main antes que nada)
InitApp( [nFilas], [nCols], [cFuente], [nAltoPx], [nAnchoPx] )

// Valores por defecto:
//   nFilas  = 40
//   nCols   = 132
//   cFuente = "Lucida Console"
//   nAltoPx = 16
//   nAnchoPx = 8

// Ejemplo basico
FUNCTION Main()
    InitApp()
    ErrorBlock( { |e| ErrSys( e ) } )
    // ... codigo de la aplicacion ...
RETURN NIL

// Ejemplo personalizado
FUNCTION Main()
    InitApp( 35, 120, "Courier New", 14, 7 )
    ErrorBlock( { |e| ErrSys( e ) } )
    // ...
RETURN NIL

// Manejador de errores robusto (escribe error.log y sale limpiamente)
// No llamar directamente: se pasa como codeblock a ErrorBlock()
ErrSys( oErr )
```

---

## PATRON TIPICO: FORMULARIO COMPLETO

```harbour
FUNCTION FormCliente( cCodigo )

    LOCAL oWin
    LOCAL cNom  := Space( 30 )
    LOCAL cNif  := Space( 9  )
    LOCAL nDias := 0
    LOCAL lAct  := .T.
    LOCAL lOk   := .F.

    oWin := TWindow():New( 5, 10, 32, 120, "Ficha de Cliente" )

    // Etiquetas (lTabStop = .F., no reciben foco)
    oWin:AddCtrl( TLabel():New( 2, 2, "Nombre  :", oWin ) )
    oWin:AddCtrl( TLabel():New( 4, 2, "NIF     :", oWin ) )
    oWin:AddCtrl( TLabel():New( 6, 2, "Dias    :", oWin ) )
    oWin:AddCtrl( TLabel():New( 8, 2, "Activo  :", oWin ) )

    // Gets (lTabStop = .T., reciben foco con TAB)
    LOCAL oNom  := TGet():New( 2, 12, cNom,  "@!",  oWin )
    LOCAL oNif  := TGet():New( 4, 12, cNif,  "@!",  oWin )
    LOCAL oDias := TGet():New( 6, 12, nDias, "999", oWin )
    LOCAL oAct  := TGet():New( 8, 12, lAct,  "L",   oWin )

    oNom:bValid  := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oWin:AddCtrl( oNom  )
    oWin:AddCtrl( oNif  )
    oWin:AddCtrl( oDias )
    oWin:AddCtrl( oAct  )

    // Botones
    LOCAL oBtAcep := TButton():New( 15, 15, 16, 34, oWin, ;
        "ACEPTAR", ;
        {|| lOk := .T., oWin:Close() } )

    LOCAL oBtCanc := TButton():New( 15, 38, 16, 57, oWin, ;
        "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBtAcep )
    oWin:AddCtrl( oBtCanc )

    oWin:Run()

    IF lOk
        cNom  := AllTrim( oNom:uVar  )
        cNif  := AllTrim( oNif:uVar  )
        nDias := oDias:uVar
        lAct  := oAct:uVar
        // ... guardar en DBF ...
    ENDIF

RETURN lOk
```

---

## PATRON TIPICO: GRID + FORMULARIO DE EDICION

```harbour
FUNCTION ListadoClientes()

    LOCAL oWin, oGrid, aData
    LOCAL oBtNuevo, oBtSal

    // Cargar datos en memoria desde TTable o array manual
    aData := CargarClientes()

    oWin  := TWindow():New( 2, 5, 37, 125, "Clientes" )
    oGrid := TGrid():New( 2, 1, 29, 117, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Codigo", 8, "@!", { |a| a[1] } )
    oGrid:AddColumn( "Nombre", 35, "@!", { |a| a[2] } )
    oGrid:AddColumn( "NIF",    10, "@!", { |a| a[3] } )

    oGrid:bEnter  := {| g | FormCliente( g:CurrentRow()[1] ), ;
                            aData := CargarClientes(), ;
                            g:aData := aData, ;
                            g:Paint() }

    oGrid:bInsert := {| g | FormCliente( "" ), ;
                            aData := CargarClientes(), ;
                            g:aData := aData, ;
                            g:nCurRow := Len( aData ), ;
                            g:Paint() }

    oBtNuevo := TButton():New( 31, 2, 32, 18, oWin, ;
        "NUEVO (F5)", ;
        {|| FormCliente( "" ), ;
            aData := CargarClientes(), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 31, 100, 32, 114, oWin, ;
        "SALIR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid   )
    oWin:AddCtrl( oBtNuevo )
    oWin:AddCtrl( oBtSal  )

    oWin:Run()

RETURN NIL
```

---

*Fin del documento de referencia*
