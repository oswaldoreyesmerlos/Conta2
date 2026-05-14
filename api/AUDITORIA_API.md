# Auditoría de API — GfxStack Framework

**Fecha:** 2026-05-14
**Base:** commit `03bfa93`, rama `refactor/modelo-obras`
**Archivos:** `api/Gfx.prg`, `api/TControl.prg`, `api/TWindow.prg`, `api/TLabel.prg`, `api/TGet.prg`, `api/TButton.prg`, `api/TCheck.prg`, `api/TCombo.prg`, `api/TGrid.prg`, `api/TTable.prg`, `api/TMenu.prg`, `api/MsgBox.prg`, `api/MsgYesNo.prg`, `api/OOp.ch`, `Util.prg`

---

## Resumen

| Capa | Archivos | Bugs | Debilidades | Notas |
|------|----------|------|-------------|-------|
| Núcleo gráfico | Gfx.prg | 0 | 2 | Capa fina sobre GTWVG, estable |
| Clase base | TControl.prg | 0 | 1 | B001 corregido: GetValue/SetValue lanzan MsgStop |
| Ventanas | TWindow.prg | 0 | 0 | 2 notas de diseño (N01, N02); D04 corregido |
| Controles | TLabel,TGet,TButton,TCheck,TCombo | 0 | 2 | B002 no-era-bug, B003 corregido (SetValue repinta siempre) |
| Grid | TGrid.prg | 0 | 2 | B004 corregido: nSeekTimeout configurable |
| Tablas | TTable.prg | 0 | — | No forma parte de la API activa (N03) |
| Menús | TMenu.prg | 0 | 0 | D12 corregido: añadido SetItems() |
| Diálogos | MsgBox, MsgYesNo | 0 | 0 | B005 corregido: botón asigna nRet |
| Utilidades | Util.prg | 0 | 1 | B006 ya tenía DbSkip(0); D13 corregido (parámetro @lReabierta) |
| Constantes | OOp.ch | 0 | 0 | Correcto |

**Puntuación estimada: 9.0/10**

---

## 1. Gfx.prg — Capa gráfica (0 bugs, 2 debilidades)

Capa de abstracción correcta. Todas las funciones envuelven WVG
adecuadamente. Sin bugs activos.

### D01 — GfxShadow usa colores fijos
`GfxShadow` pinta sombra con `"N/N+"` hardcodeado. Si se cambia el
esquema de colores de la app, la sombra no lo refleja.
*Sugerencia:* añadir parámetro `cColor` con default `"N/N+"`.

### D02 — GfxPaintPush/Pop sin control de desbordamiento
Si se llama `GfxPaintPop` más veces que `GfxPaintPush`, el array global
de stack se vacía y Harbour no lanza error (solo no restaura nada).
*Sugerencia:* documentar que deben ir en pares (ya se hace en TWindow).

---

## 2. TControl.prg — Clase base (0 bugs, 1 debilidad)

### B001 — GetValue/SetValue base no estaban implementados — ***CORREGIDO***
```harbour
METHOD GetValue() CLASS TControl  // ahora llama a MsgStop
METHOD SetValue( uVal ) CLASS TControl  // ahora llama a MsgStop
```
Antes retornaban NIL/Self silenciosamente. Ahora llaman a `MsgStop()`
indicando qué clase no implementó el método.
*Severidad original:* MEDIO.
*Fix aplicado:* `MsgStop( "GetValue() no implementado para " + ::ClassName(), "Error interno" )`.

### D03 — No hay método HasFocus() ni IsTabStop()
No hay forma genérica de preguntar si un control tiene el foco o si es
enfocable sin acceder a `::lFocused` o `::lTabStop` directamente.
*Sugerencia:* añadir `METHOD HasFocus() INLINE ::lFocused` y análogo.

---

## 3. TWindow.prg — Ventanas (0 bugs, 0 debilidades, 2 notas de diseño)

### D04 — No valida que existan controles antes de SetFocus — ***CORREGIDO***
Si `aCtrls` está vacío y se llama `SetFocus(1)`, se sale con `NIL`
silenciosamente en `aCtrls[1]`.
*Sugerencia original:* chequeo `Empty(::aCtrls)` al inicio.
*Fix aplicado:* añadido `IF Empty( ::aCtrls ) RETURN NIL` al inicio de `SetFocus()`.

### N01 — Run() es siempre modal por diseño
`Run()` ejecuta un bucle bloqueante `DO WHILE !::lExit` / `Inkey(0)`.
No hay soporte para ventanas no modales (toolbox, visor persistente).
Esto es intencionado: reproduce el flujo Clipper 5.x donde cada
pantalla es una transacción modal que bloquea hasta cerrarse.
Consistente con el punto 10 del nuevo enfoque (interfaz clásica de
escritorio, ventanas modales, teclado). No es una carencia.

### N02 — GTWVG soporta multi-ventana SO vía WvgCrt — ***CORREGIDA LA NOTA***
La auditoría original asumía que GTWVG limitaba a una sola ventana SO.
**Esto es incorrecto.** GTWVG incluye `crt.prg` (contrib/gtwvg/crt.prg)
que provee la clase `WvgCrt`, compatible con Xbase++, que crea ventanas
HWND reales con su propia instancia GT por ventana (`hb_gtCreate("WVG")`).
Métodos: `setFrameState()`, `toFront()`, `toBack()`, `show()`, `hide()`,
`getHWND()`. Soporta minimizar/maximizar/restore via `WM_SYSCOMMAND` y
callbacks (paint, keyboard, close, move, resize).

TWindow actual NO usa `WvgCrt` — dibuja pseudo-ventanas con Gfx* sobre
una sola superficie GT, por simplicidad, no por limitación del GT.
Usar `WvgCrt` permitiría ventanas SO reales sin salir de Harbour + GTWVG
y sin migrar a GTWVW. Queda como decisión de diseño pendiente.

---

## 4. Controles de entrada (0 bugs, 2 debilidades)

### B002 — TCheck: GetValue sí sobreescribe correctamente — ***NO ES BUG***
El código tiene `METHOD GetValue() CLASS TCheck` que sobreescribe
correctamente el método de TControl. Funciona y sigue el patrón OOP
estándar de Harbour. La descripción original de la auditoría era
incorrecta. No requiere acción.

### D06 — TCombo: SetValue no repinta si no encuentra el valor — ***CORREGIDO***
```harbour
METHOD SetValue( xValue ) CLASS TCombo
    // Ahora llama a ::Paint() SIEMPRE al final
```
El control se quedaba mostrando el valor anterior sin indicar error.
*Severidad original:* BAJO.
*Fix aplicado:* `::Paint()` al final del método, incluso si no encontró el valor.

### D07 — TGet: no hay soporte nativo para Placeholder
No hay forma de mostrar un texto de ayuda ("Escriba nombre...") gris
cuando el campo está vacío sin implementación manual.
*Sugerencia:* añadir `cPlaceholder` como mejora futura.

### D08 — TGet: Ancho mínimo de 10 sin picture
Si no se pasa `nLen` ni `cPicture`, el ancho por defecto es 10.
Es adecuado pero conviene documentarlo explícitamente.

### B003 — TCombo: si aOpts está vacío, GetValue() devuelve NIL
No es un bug real si el llamador controla, pero `GetValue()` puede
devolver NIL sin previo aviso si no hay opciones.
*Severidad:* BAJO.

---

## 5. TGrid.prg — Rejilla (0 bugs, 2 debilidades)

### B004 — SeekChar no tenía timeout configurable — ***CORREGIDO***
La búsqueda incremental por teclado tenía un timeout fijo interno
(`nSeekTime`). No se podía ajustar desde fuera.
*Severidad original:* BAJO.
*Fix aplicado:* añadida `DATA nSeekTimeout INIT 1.5` configurable desde fuera.

### D09 — bChange se ejecuta en cada movimiento de fila
Ya documentado en el manual. Para visores de solo lectura sin
necesidad de recálculo, conviene dejarlo NIL.

### D10 — No resalta columna de ordenamiento
TGrid no indica visualmente qué columna es la que ordena (no hay
soporte de ordenación real actualmente).
*Sugerencia:* mejora futura.

---

## 6. TTable.prg — Acceso a DBF (0 bugs, 1 nota)

### N03 — No forma parte de la API activa
TTable es un wrapper OOP sobre RDD DBFCDX que no se usa en la
aplicación. El proyecto prefiere el acceso directo a DBF con funciones
nativas de Harbour (`DbSelectArea`, `DbGoTop`, `DbSeek`, `DbAppend`,
`FieldGet`, `REPLACE`, etc.). Se mantiene en el repositorio como
referencia pero no se considera parte de la API oficial ni se
desarrollará activamente.

---

## 7. TMenu.prg — Menús (0 bugs, 0 debilidades)

### D12 — Sin método para cambiar items en caliente — ***CORREGIDO***
`aItems` se podía modificar externamente, pero no había un método
`SetItems()` que refresque la estructura interna.
*Sugerencia original:* añadir `SetItems( aNew )` que rehaga `Build()`.
*Fix aplicado:* añadido `METHOD SetItems( aDef )` que llama a `::Build()`
y `::Paint()`.

---

## 8. MsgBox / MsgYesNo (0 bugs, 0 debilidades)

### B005 — MsgBox no distinguía qué botón se pulsó — ***CORREGIDO***
```harbour
FUNCTION MsgBox( cMsg, cTit )
    // Ahora el botón asigna nRet := K_ENTER en su callback
```
Antes devolvía `K_ENTER` fijo sin importar el botón. Ahora el callback
del botón ACEPTAR asigna `nRet := K_ENTER` antes de cerrar, preparado
para futuros botones múltiples.
*Severidad original:* BAJO. Mejora preventiva.
*Fix aplicado:* callback `{ || nRet := K_ENTER, oWin:Close() }`.

---

## 9. Util.prg — Utilidades (0 bugs, 1 debilidad)

### B006 — GetNextNum: lee buffer rancio tras RLock — ***NO ERA BUG***
**Ya no crítico.** La auditoría original afirmaba que faltaba `DbSkip(0)`
tras `NetRLock()`. Sin embargo, revisando el código en el commit base
(`03bfa93`), `DbSkip(0)` YA estaba presente en la línea 432 de `Util.prg`.
El fix descrito ya estaba implementado. No se requirió acción adicional.

### D13 — ABRIR_TABLA no informaba si reutilizó alias — ***CORREGIDO***
No había forma de saber si `ABRIR_TABLA` abrió una nueva área o
reutilizó una existente. Esto obligaba a los formularios a añadir
`lFueAbierta` manualmente (como en el fix C001).
*Sugerencia original:* que devuelva `nArea` o añadir parámetro de salida.
*Fix aplicado:* añadido 5º parámetro de salida `@lReabierta`. El que lo
pase recibe `.T.` si reutilizó alias, `.F.` si abrió nuevo.
Compatible hacia atrás (callers existentes no lo notan).

### D14 — ErrSys no restaura el cursor al salir
Si ocurre un error en mitad de una operación gráfica, el cursor
puede quedar apagado (`SC_NONE`) al terminar la app.
*Sugerencia:* en ErrSys, antes de `QUIT`, llamar `GfxCursor(SC_NORMAL)`.

---

## 10. OOp.ch — Constantes (0 bugs, 0 debilidades)

Correcto. Constantes bien definidas, guardas de inclusión, sin errores.

---

## Bugs — TODOS CORREGIDOS

| ID | Archivo | Severidad | Estado | Fix |
|----|---------|-----------|--------|-----|
| B001 | TControl.prg | MEDIO | CORREGIDO | GetValue/SetValue lanzan MsgStop |
| B002 | TCheck.prg | BAJO | NO ERA BUG | Código ya sobreescribía correctamente |
| B003 | TCombo.prg | BAJO | CORREGIDO | SetValue llama a Paint() siempre |
| B004 | TGrid.prg | BAJO | CORREGIDO | nSeekTimeout configurable (DATA) |
| B005 | MsgBox.prg | BAJO | CORREGIDO | Botón asigna nRet en callback |
| B006 | Util.prg | CRÍTICO | NO ERA BUG | DbSkip(0) ya estaba presente |

## Debilidades activas (D01-D03, D06-D10, D14)

| ID | Archivo | Descripción |
|----|---------|-------------|
| D01 | Gfx.prg | GfxShadow usa colores fijos "N/N+" |
| D02 | Gfx.prg | GfxPaintPush/Pop sin control de desbordamiento |
| D03 | TControl.prg | No hay HasFocus() ni IsTabStop() genéricos |
| D07 | TGet.prg | Sin soporte nativo para Placeholder |
| D08 | TGet.prg | Ancho mínimo 10 sin picture, conviene documentarlo |
| D09 | TGrid.prg | bChange se ejecuta en cada movimiento de fila |
| D10 | TGrid.prg | No resalta columna de ordenamiento |
| D14 | Util.prg | ErrSys no restaura el cursor al salir |

D04, D12, D13 corregidos. D05 y D11 reemplazados por notas N01/N02 y N03 respectivamente.

## Notas de diseño (N01-N03)

Ver secciones 3, 6 y 3 arriba. N02 actualizada: GTWVG SÍ soporta multi-ventana vía `WvgCrt` en `crt.prg`.
