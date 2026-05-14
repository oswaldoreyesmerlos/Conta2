# Auditoría de API — GfxStack Framework

**Fecha:** 2026-05-14
**Base:** commit `03bfa93`, rama `refactor/modelo-obras`
**Archivos:** `api/Gfx.prg`, `api/TControl.prg`, `api/TWindow.prg`, `api/TLabel.prg`, `api/TGet.prg`, `api/TButton.prg`, `api/TCheck.prg`, `api/TCombo.prg`, `api/TGrid.prg`, `api/TTable.prg`, `api/TMenu.prg`, `api/MsgBox.prg`, `api/MsgYesNo.prg`, `api/OOp.ch`, `Util.prg`

---

## Resumen

| Capa | Archivos | Bugs | Debilidades | Notas |
|------|----------|------|-------------|-------|
| Núcleo gráfico | Gfx.prg | 0 | 2 | Capa fina sobre GTWVG, estable |
| Clase base | TControl.prg | 1 | 1 | GetValue/SetValue genéricos sin implementación real |
| Ventanas | TWindow.prg | 0 | 2 | Anidamiento frágil si no se usa Run() |
| Controles | TLabel,TGet,TButton,TCheck,TCombo | 2 | 4 | Validación, foco, normalización |
| Grid | TGrid.prg | 1 | 2 | bChange ineficiente en lecturas, seek sin timeout |
| Tablas | TTable.prg | 0 | 1 | Sin edición (FieldPut existe pero no Append/Delete) |
| Menús | TMenu.prg | 0 | 1 | Sin teclas rápidas configurables |
| Diálogos | MsgBox, MsgYesNo | 1 | 0 | No retornan qué botón se pulsó en MsgBox |
| Utilidades | Util.prg | 1 | 2 | GetNextNum con race condition, ABRIR_TABLA no informa si reabrió |
| Constantes | OOp.ch | 0 | 0 | Correcto |

**Puntuación estimada: 7.5/10**

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

## 2. TControl.prg — Clase base (1 bug, 1 debilidad)

### B001 — GetValue/SetValue base no están implementados
```harbour
METHOD GetValue() CLASS TControl  // línea 132: RETURN NIL
METHOD SetValue( uVal ) CLASS TControl  // línea 136: RETURN NIL
```
Si un control hijo no sobreescribe estos métodos y alguien los llama
por error polimórfico, recibe NIL silenciosamente.
*Severidad:* MEDIO. No hay crash, pero puede ocultar bugs.
*Fix:* que lancen un error descriptivo o `MsgStop`.

### D03 — No hay método HasFocus() ni IsTabStop()
No hay forma genérica de preguntar si un control tiene el foco o si es
enfocable sin acceder a `::lFocused` o `::lTabStop` directamente.
*Sugerencia:* añadir `METHOD HasFocus() INLINE ::lFocused` y análogo.

---

## 3. TWindow.prg — Ventanas (0 bugs, 2 debilidades)

### D04 — No valida que existan controles antes de SetFocus
Si `aCtrls` está vacío y se llama `SetFocus(1)`, se sale con `NIL`
silenciosamente en `aCtrls[1]`.
*Sugerencia:* chequeo `Empty(::aCtrls)` al inicio.

### D05 — No hay soporte para ventanas no modales
`Run()` siempre es modal. Para pantallas de tipo "toolbox" o
"visor persistente" no hay alternativa.
*Sugerencia:* no necesario ahora, documentar como limitación conocida.

---

## 4. Controles de entrada (2 bugs, 3 debilidades)

### B002 — TCheck no tiene GetValue() documentado como estándar
Aunque `GetValue()` existe y funciona, el método está definido como
`GetValue` en lugar de heredar y sobreescribir limpiamente desde
TControl. Funcionalmente correcto, pero rompe la uniformidad de la API.
*Severidad:* BAJO. No afecta ejecución.
*Sugerencia:* verificar que todos los controles usen la misma firma.

### D06 — TCombo: SetValue no repinta si no encuentra el valor
```harbour
METHOD SetValue( xValue ) CLASS TCombo
    // Si el valor no está en la lista, retorna Self sin repintar
```
El control se queda mostrando el valor anterior sin indicar error.
*Severidad:* BAJO.
*Sugerencia:* o bien `Paint()` siempre, o marcar visualmente.

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

## 5. TGrid.prg — Rejilla (1 bug, 2 debilidades)

### B004 — SeekChar no tiene timeout configurable
La búsqueda incremental por teclado tiene un timeout fijo interno
(`nSeekTime`). No se puede ajustar desde fuera.
*Severidad:* BAJO.
*Sugerencia:* añadir DATA `nSeekTimeout`.

### D09 — bChange se ejecuta en cada movimiento de fila
Ya documentado en el manual. Para visores de solo lectura sin
necesidad de recálculo, conviene dejarlo NIL.

### D10 — No resalta columna de ordenamiento
TGrid no indica visualmente qué columna es la que ordena (no hay
soporte de ordenación real actualmente).
*Sugerencia:* mejora futura.

---

## 6. TTable.prg — Acceso a DBF (0 bugs, 1 debilidad)

### D11 — Sin Append() ni Delete()
TTable permite lectura, navegación y búsqueda, pero no tiene métodos
para añadir o borrar registros. `FieldPut` existe pero no hay
`Append`/`Delete`/`Recall`.
*Sugerencia:* añadir cuando se necesite edición desde la clase.

---

## 7. TMenu.prg — Menús (0 bugs, 1 debilidad)

### D12 — Sin método para cambiar items en caliente
`aItems` se puede modificar externamente, pero no hay un método
`SetItems()` que refresque la estructura interna.
*Sugerencia:* añadir `SetItems( aNew )` que rehaga `Build()`.

---

## 8. MsgBox / MsgYesNo (1 bug, 0 debilidades)

### B005 — MsgBox no distingue qué botón se pulsó
```harbour
FUNCTION MsgBox( cMsg, cTit )
    // Siempre devuelve K_ENTER
```
Si en el futuro se añaden botones Sí/No/Cancelar a MsgBox, el retorno
fijo no servirá. MsgYesNo sí distingue (.T./.F.).
*Severidad:* BAJO. Mejora preventiva.

---

## 9. Util.prg — Utilidades (1 bug, 2 debilidades)

### B006 — GetNextNum: lee buffer rancio tras RLock
**CRÍTICO.** Descrito en bug B001 de informes anteriores.
Después de `DbSeek()` y antes de `NetRLock()`, otro usuario puede
modificar el registro. Falta `DbSkip(0)` tras el lock para refrescar.
*Fix:*
```harbour
IF DbSeek( cCodDoc )
    IF !NetRLock()
        ...
    ENDIF
    DbSkip( 0 )   // <-- recargar registro bajo lock
    // ... leer valores
```

### D13 — ABRIR_TABLA no informa si reutilizó un alias existente
No hay forma de saber si `ABRIR_TABLA` abrió una nueva área o
reutilizó una existente. Esto obliga a los formularios a añadir
`lFueAbierta` manualmente (como en el fix C001).
*Sugerencia:* que devuelva `nArea` (número de área) o añadir
parámetro de salida `@lReabierta`.

### D14 — ErrSys no restaura el cursor al salir
Si ocurre un error en mitad de una operación gráfica, el cursor
puede quedar apagado (`SC_NONE`) al terminar la app.
*Sugerencia:* en ErrSys, antes de `QUIT`, llamar `GfxCursor(SC_NORMAL)`.

---

## 10. OOp.ch — Constantes (0 bugs, 0 debilidades)

Correcto. Constantes bien definidas, guardas de inclusión, sin errores.

---

## Resumen de bugs activos

| ID | Archivo | Severidad | Descripción |
|----|---------|-----------|-------------|
| B001 | TControl.prg | MEDIO | GetValue/SetValue base retornan NIL |
| B002 | TCheck.prg | BAJO | GetValue no sigue el patrón estándar limpiamente |
| B003 | TCombo.prg | BAJO | SetValue no repinta si no encuentra valor |
| B004 | TGrid.prg | BAJO | SeekChar timeout no configurable |
| B005 | MsgBox.prg | BAJO | Retorno fijo K_ENTER |
| B006 | Util.prg | CRÍTICO | GetNextNum race condition (buffer rancio) |

## Debilidades (D01-D14)

Ver secciones correspondientes arriba.
