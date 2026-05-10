# Informe de Bugs y Mejoras — GfxStack + Util.prg

**Fecha de revisión:** 2026-05-10
**Archivos analizados:** OOp.ch, Gfx.prg, TControl.prg, TWindow.prg, TLabel.prg,
TGet.prg, TButton.prg, TCheck.prg, TCombo.prg, TGrid.prg, TTable.prg, TMenu.prg,
MsgBox.prg, MsgYesNo.prg, OOpMenu4.prg, Util.prg.

---

## Como usar este documento

Cada hallazgo lleva un identificador `B###`, severidad, archivo y línea
aproximada. Donde el arreglo es claro doy código listo para pegar. Donde hay
una decisión de diseño que tomar, expongo las opciones razonables con sus
costes.

**Severidades**

| Nivel    | Significado                                                                   |
|----------|-------------------------------------------------------------------------------|
| CRITICO  | Rompe la corrupción de datos o cuelga la app en uso real. Arreglar ya.        |
| SERIO    | Falla en escenarios concretos previsibles, riesgo de experiencia mala usuario.|
| MEJORA   | Estilo, mantenibilidad o robustez a largo plazo. Sin urgencia.                |
| RESUELTO | Discutido y zanjado durante la revisión.                                      |

Marca con `[x]` cada uno conforme lo trabajes.

---

# CRITICOS

## [ ] B001 — GetNextNum lee del buffer rancio tras RLock

**Archivo:** `Util.prg`, función `GetNextNum`, líneas ~419-430.
**Severidad:** CRITICO. Genera duplicados de número de documento bajo
concurrencia. Es **el** bug clásico del contador en xBase.

### Síntoma

Dos usuarios pidiendo el siguiente número de factura casi a la vez obtienen
**el mismo número**. Aparece de forma errática, suele detectarse en cierre de
mes con varios usuarios facturando, y no hay forma de reproducirlo en local
con un solo usuario.

### Causa

Después de `DbSeek( cCodDoc )`, el buffer de registro carga los valores en
memoria. Cuando llega `RLock()`, este adquiere el lock del SO **pero no
recarga el registro de disco**. Si otro usuario modificó y commiteó entre el
Seek y el RLock, leemos `CON->ULT_NUM` con el valor antiguo.

### Fix

```harbour
IF DbSeek( cCodDoc )

    IF !NetRLock()
        CON->( DbCloseArea() )
        Select( nAreaIni )
        RETURN ""
    ENDIF

    DbSkip( 0 )                         // <-- AÑADIR: recarga registro bajo lock

    cPrefijo := AllTrim( CON->PREFIJO )
    nUltNum  := CON->ULT_NUM
    nDigitos := If( CON->DIGITOS > 0, CON->DIGITOS, 7 )

ELSE
    ...
ENDIF
```

`DbSkip( 0 )` invalida el cache del registro y fuerza relectura. Es el
modismo xBase estándar para "ahora que tengo el lock, dame los datos
frescos".

---

## [ ] B002 — GetNextNum permite duplicados en el primer alta de un cCodDoc

**Archivo:** `Util.prg`, función `GetNextNum`, líneas ~431-447.
**Severidad:** CRITICO. Causa duplicados del **registro de contador**, no
solo del número.

### Síntoma

Dos usuarios pidiendo `GetNextNum("PRO")` cuando aún no existe ese
contador acaban creando dos registros distintos para `COD_DOC = "PRO"`. A
partir de ahí, `DbSeek("PRO")` devuelve uno u otro según el orden del
índice, y los números pueden volver a duplicarse.

### Causa

Patrón clásico de race condition en check-then-act sin lock:

1. A: `DbSeek("PRO")` → no encontrado.
2. B: `DbSeek("PRO")` → no encontrado.
3. A: `NetFLock` ✓, `DbAppend`, escribe registro PRO con `ULT_NUM=1`,
   commit, unlock.
4. B: `NetFLock` ✓ (después del unlock de A), `DbAppend`, escribe **otro**
   registro PRO con `ULT_NUM=1`.

### Fix

Doble verificación bajo lock:

```harbour
ELSE
    cPrefijo := _PrefijoEmp()

    IF !NetFLock()
        CON->( DbCloseArea() )
        Select( nAreaIni )
        RETURN ""
    ENDIF

    // Re-check bajo lock: alguien pudo haberlo creado entre nuestro Seek y FLock
    IF DbSeek( cCodDoc )
        DbSkip( 0 )                                 // recarga buffer
        cPrefijo := AllTrim( CON->PREFIJO )
        nUltNum  := CON->ULT_NUM
        nDigitos := If( CON->DIGITOS > 0, CON->DIGITOS, 7 )
    ELSE
        DbAppend()
        REPLACE CON->COD_DOC WITH cCodDoc
        REPLACE CON->DESCRIP WITH If( ValType( cDescrip ) == "C", cDescrip, "" )
        REPLACE CON->PREFIJO WITH cPrefijo
        REPLACE CON->DIGITOS WITH nDigitos
    ENDIF
ENDIF
```

Regla general: bajo el lock que vas a usar para escribir, vuelve a
comprobar la condición que te llevó a tomar ese lock.

---

## [ ] B003 — GetNextNum cierra CONTADOR aunque el llamador la tuviera abierta

**Archivo:** `Util.prg`, función `GetNextNum`, líneas ~410 y ~463.
**Severidad:** CRITICO. Rompe silenciosamente módulos que mantengan
CONTADOR abierta entre llamadas.

### Síntoma

Si algún sitio de la app deja CONTADOR abierta (legítimo si la consultas
mucho), tras la primera llamada a `GetNextNum` el alias `CON` queda cerrado.
La siguiente operación que dependa de él falla con error de área no
seleccionable, o peor, opera en otra área activa por confusión.

### Causa

`ABRIR_TABLA` no abre la tabla si ya estaba abierta. Pero `GetNextNum`
hace `CON->( DbCloseArea() )` siempre, como si la hubiera abierto él. Le
falta recordar el estado inicial.

### Fix

```harbour
FUNCTION GetNextNum( cCodDoc, cDescrip )

    LOCAL cProxCod    := ""
    LOCAL nAreaIni    := Select()
    LOCAL lFueAbierta := DBUSED( "CON" )       // <-- AÑADIR
    LOCAL cPrefijo    := ""
    LOCAL nUltNum     := 0
    LOCAL nDigitos    := 7
    LOCAL cUsuario    := "SISTEMA"

    MEMVAR cUserID

    ...

    DbCommit()
    DbUnlock()

    IF !lFueAbierta                            // <-- CAMBIAR
        CON->( DbCloseArea() )
    ENDIF

    Select( nAreaIni )

RETURN cProxCod
```

**Sugerencia adicional (no obligatoria):** si CONTADOR se va a usar
mucho, valora abrirla una vez en `Main()` y dejarla abierta toda la
sesión. Es una tabla pequeña, abrir/cerrar por cada GetNextNum tiene un
coste innecesario.

---

## [ ] B004 — TLabel revienta si cText es NIL

**Archivo:** `TLabel.prg`, método `New`, línea 16.
**Severidad:** CRITICO. Cualquier llamada accidental con NIL produce
runtime error en Paint.

### Causa

```harbour
METHOD New( nRow, nCol, cText, oPar ) CLASS TLabel
    LOCAL nLen
    nLen := Max( Len( cText ), 1 )         // Len(NIL) = 0 en Harbour, OK aquí
    ::TControl:New( nRow, nCol, nRow, nCol + nLen - 1, oPar )
    ::cCaption := cText                    // queda NIL
    ...
```

Luego en Paint llama a `DrawText( 0, 0, ::cCaption, ::cColor )` que
acaba en `DispOutAt( ..., NIL, ... )` → error.

### Fix

Una línea al inicio del constructor:

```harbour
METHOD New( nRow, nCol, cText, oPar ) CLASS TLabel
    LOCAL nLen

    DEFAULT cText TO ""                    // <-- AÑADIR

    nLen := Max( Len( cText ), 1 )
    ...
```

---

# SERIOS

## [ ] B005 — TGet no acepta el separador en pictures de fecha distintas a "99/99/9999"

**Archivo:** `TGet.prg`, método `HandleKey`, línea ~336.
**Severidad:** SERIO. El control rechaza la `/` o `-` en cuanto la
picture de fecha no es exactamente la cadena `"99/99/9999"`.

### Causa

```harbour
IF ::cType == "N" .OR. ( "9" $ ::cPicture .AND. ::cPicture != "99/99/9999" )
    IF ! ( cChr $ "0123456789.-" )
        RETURN .T.   // rechaza
    ENDIF
ENDIF
```

Una picture como `"99-99-9999"`, `"9999/99/99"` o cualquier otro formato
de fecha entra por la rama numérica porque contiene `"9"` y no es el
literal exacto del except. Resultado: el filtro permite solo dígitos,
punto y guión, rechazando `/`. Para fechas en formato europeo con `-` el
guión sí pasa, pero los dígitos del año se confunden.

### Fix

Decidir el filtro por **tipo del valor**, no por la picture:

```harbour
// Caracter imprimible
IF nKey >= 32 .AND. nKey <= 255

    cChr := Chr( nKey )

    IF ::cPicture == "@!"
        cChr := Upper( cChr )
    ENDIF

    DO CASE
    CASE ::cType == "N"
        IF ! ( cChr $ "0123456789.-" )
            RETURN .T.
        ENDIF

    CASE ::cType == "D"
        IF ! ( cChr $ "0123456789/-." )
            RETURN .T.
        ENDIF

    ENDCASE

    ...
ENDIF
```

Y elimina el bloque más abajo `IF ::cPicture == "99/99/9999"` que ya
es redundante con el case anterior.

---

## [ ] B006 — TGet ejecuta Validate() dos veces en una salida normal

**Archivo:** `TGet.prg`, métodos `HandleKey` y `KillFocus`, líneas
~212-244 y ~159-168.
**Severidad:** SERIO. Si `bValid` tiene efectos secundarios (mostrar
mensaje, escribir en BD, contadores, etc.) los verás duplicados.

### Causa

`HandleKey` valida en TAB, SHIFT_TAB, ENTER, UP y DOWN para decidir si
consume la tecla:

```harbour
IF nKey == K_TAB
    IF ! ::Validate()
        RETURN .T.
    ENDIF
    RETURN .F.
ENDIF
```

Después `TWindow` mueve el foco con `NextFocus`, que llama a
`SetFocus(newPos)`, que llama a `KillFocus()` del antiguo, que vuelve a
validar:

```harbour
METHOD KillFocus() CLASS TGet
    IF ! ::Validate()
        RETURN NIL
    ENDIF
    ...
```

### Opciones

Tres alternativas razonables, en orden de menos a más invasivo:

**Opción A (mínima):** documentar que `bValid` debe ser idempotente y sin
efectos secundarios. Sirve si los usuarios respetan la disciplina.

**Opción B:** que `HandleKey` no valide y deje a `KillFocus` hacerlo:

```harbour
IF nKey == K_TAB
    RETURN .F.        // ceder al padre, KillFocus validará
ENDIF
```

Pero entonces si Validate falla en KillFocus, `TWindow:SetFocus` se
queda con el foco en el control nuevo (porque ya lo había puesto). Hay
que mirar bien la coordinación.

**Opción C (recomendada):** flag `lValidated` que se pone a `.T.` cuando
`Validate` tiene éxito y se resetea en `SetFocus` / al modificar el
buffer. `KillFocus` consulta el flag y no vuelve a validar si ya lo está.

```harbour
DATA lValidated INIT .F.

METHOD HandleKey( nKey )
    ...
    IF nKey == K_TAB
        IF ! ::Validate()
            RETURN .T.
        ENDIF
        ::lValidated := .T.
        RETURN .F.
    ENDIF
    ...
    // En cualquier rama de modificación del buffer:
    ::lValidated := .F.

METHOD KillFocus() CLASS TGet
    IF ! ::lValidated
        IF ! ::Validate()
            RETURN NIL
        ENDIF
    ENDIF
    GfxCursor( SC_NONE )
    ::lNumFresh := .F.
RETURN ::TControl:KillFocus()

METHOD SetFocus() CLASS TGet
    ::lValidated := .F.
    ...
```

---

## [ ] B007 — NetFLock/NetRLock muestran MsgYesNo manteniendo otros locks vivos

**Archivo:** `Util.prg`, funciones `NetFLock` y `NetRLock`, líneas
~337-380.
**Severidad:** SERIO. Riesgo de bloqueo en cascada en producción
multipuesto.

### Síntoma

Usuario A está editando una factura, ya tiene bloqueada la cabecera y
una línea de detalle. Para grabar pide `FLock` sobre CLIENTES; falla;
sale el diálogo "Reintentar?". A se va a comer. Mientras tanto, B
intenta editar la misma factura, se queda colgado en `RLock` de la
cabecera. Cuando A vuelve, todo destraba o no según orden.

### Causa

```harbour
DO WHILE !FLock()
    nIntentos++
    Inkey( 0.5 )
    IF nIntentos > 6
        IF MsgYesNo( "Archivo ocupado. Reintentar?", "Bloqueo" )
            ...
```

El `MsgYesNo` es modal y bloqueante, y los demás locks que tuviera la
sesión siguen vivos durante todo el tiempo que el usuario tarde en
responder.

### Opciones

**Opción A (mínima, disciplina):** documentar el contrato: "no se llama
a `NetFLock`/`NetRLock` teniendo otros locks vivos en otras áreas". Es
frágil pero a veces es suficiente si la app es pequeña y la disciplina
del programador es alta.

**Opción B (recomendada):** antes del `MsgYesNo`, soltar todos los locks
de la sesión y forzar al llamador a reintentar la operación entera. La
firma cambia a algo como:

```harbour
FUNCTION NetFLockOrCancel( bOnCancel )
    // Devuelve .T. si bloqueo OK
    // Devuelve .F. tras N intentos sin preguntar al usuario;
    // el llamador decide qué hacer: liberar locks, mostrar MsgStop,
    // volver al menú, etc.
```

Y que el llamador de alto nivel (rutina de grabar factura) sea quien
decide qué hacer con la falla:

```harbour
IF !NetFLockOrCancel()
    DbCommit()                           // soltar lo que tengamos a medio
    DbUnlockAll()                        // (recursivo en todas las areas abiertas)
    MsgStop( "El cliente esta siendo modificado por otro usuario. Reintenta en unos segundos.", "Bloqueo" )
    RETURN .F.
ENDIF
```

**Opción C (más invasiva pero más limpia):** función envoltorio
transaccional `WithTablesLocked( aAlias, bWork )` que toma una lista de
alias, los bloquea todos en orden estable (alfabético, evita
deadlocks), ejecuta el codeblock, y libera al salir. El bloqueo en
cascada queda atómico desde el punto de vista del llamador.

Para tu app, si el grueso de operaciones de escritura son atómicas y no
muy largas, **opción B** suele ser el mejor compromiso entre simplicidad
y robustez.

### Riesgo añadido

Si haces clic en `MsgYesNo` mientras `NetFLock` está esperando, el
diálogo abre **otra TWindow** encima de la pila. Eso funciona porque
`s_oCurrentWnd` y `GfxPaintPush/Pop` lo soportan, pero es un punto donde
si algo se descuadra (foco, cursor, repintado) el bug es difícil de
diagnosticar.

---

# MEJORAS / DECISIONES DE DISEÑO

## [ ] B008 — NetFLock con rama inicial redundante

**Archivo:** `Util.prg`, función `NetFLock`, líneas ~337-357.
**Severidad:** MEJORA. No produce bug, solo es código innecesario.

### Causa

```harbour
FUNCTION NetFLock()
    LOCAL nIntentos := 0
    IF FLock()                             // <-- redundante
        RETURN .T.
    ENDIF
    DO WHILE !FLock()
        ...
```

El `IF FLock()` inicial no aporta: el `DO WHILE !FLock()` ya cubre el
caso de éxito (no entra al cuerpo). Si te preocupa la sleep antes del
primer intento, mira que el sleep está **dentro** del cuerpo del while,
no antes.

### Fix

```harbour
FUNCTION NetFLock()
    LOCAL nIntentos := 0
    DO WHILE !FLock()
        nIntentos++
        Inkey( 0.5 )
        IF nIntentos > 6
            IF MsgYesNo( "Archivo ocupado. Reintentar?", "Bloqueo" )
                nIntentos := 0
            ELSE
                RETURN .F.
            ENDIF
        ENDIF
    ENDDO
RETURN .T.
```

Mismo cambio aplicable a `NetRLock`.

---

## [ ] B009 — NetUnLock libera todos los locks, no solo el último

**Archivo:** `Util.prg`, función `NetUnLock`, línea ~383.
**Severidad:** MEJORA. Comportamiento correcto pero nombre engañoso.

### Causa

`DbUnlock()` libera tanto el FLock como **todos** los record-locks del
área activa. El nombre singular sugiere que libera un único lock.

### Opciones

A. Renombrar a `NetUnLockAll()` y dejar comentario en cabecera.

B. Mantener nombre y añadir comentario claro en cabecera:

```harbour
// ----------------------------------------------------------------------------
// NetUnLock()
// Libera TODOS los locks del area activa (FLock + record locks).
// Es un wrapper directo de DbUnlock(); el nombre singular es historico.
// Para liberar locks de una tabla concreta:
//    cAlias->( DbUnlock() )
// ----------------------------------------------------------------------------
```

Si elijes A, recuerda actualizar todas las llamadas en la app.

---

## [ ] B010 — ABRIR_TABLA solo abre el .cdx de producción

**Archivo:** `Util.prg`, función `ABRIR_TABLA`, líneas ~310-322.
**Severidad:** MEJORA. No es bug actual, es limitación a futuro.

### Causa

```harbour
DbUseArea( .T., "DBFCDX", cArchivo, cAlias, .T., .F. )
```

DBFCDX abre automáticamente el `.cdx` de producción (mismo nombre que
el `.dbf`). Si en el futuro necesitas índices secundarios en otros
`.cdx`, no se abrirán y `OrdSetFocus` con esos tags fallará.

### Fix

Si lo necesitas, añade un parámetro opcional:

```harbour
FUNCTION ABRIR_TABLA( cArchivo, cAlias, cIndice, aCdxAdicionales )
    ...
    DbUseArea( .T., "DBFCDX", cArchivo, cAlias, .T., .F. )

    IF NetErr()
        ...
    ELSE
        IF HB_ISARRAY( aCdxAdicionales )
            AEval( aCdxAdicionales, { |c| OrdListAdd( c ) } )
        ENDIF
    ENDIF
    ...
```

Por ahora seguramente no lo necesitas, pero queda preparado.

---

## [ ] B011 — ABRIR_TABLA hace DbGoTop solo si abre la tabla

**Archivo:** `Util.prg`, función `ABRIR_TABLA`, líneas ~302-330.
**Severidad:** MEJORA. Comportamiento condicional sutil.

### Causa

Si la tabla ya está abierta, `ABRIR_TABLA` selecciona, fija orden y
**no** mueve el cursor. Si no estaba abierta, abre y va al primer
registro. El cursor de la tabla queda en sitios distintos según el
estado previo.

### Opciones

A. Quitar el `DbGoTop()` final. Que cada llamador decida si quiere
   posicionar al inicio.

B. Hacer siempre `DbGoTop()` al final (también si ya estaba abierta).
   Más predecible pero menos eficiente cuando se reabre mucho.

C. Documentar el comportamiento condicional en cabecera y dejarlo así.

A es lo más limpio para una librería.

---

## [ ] B012 — TGrid IsRowEmpty por defecto solo mira la primera columna

**Archivo:** `TGrid.prg`, método `IsRowEmpty`, líneas ~186-216.
**Severidad:** MEJORA. Para apps de gestión casi siempre vas a querer
sobrescribir.

### Causa

La heurística por defecto considera "fila vacía" si la primera columna
es vacía/cero. En grid de partidas contables o líneas de factura, la
primera columna suele ser un número de línea autogenerado (siempre
distinto de cero) o un código de cuenta (siempre presente), por lo que
nunca cuenta como vacía y `bInsert` no dispara con flecha abajo en la
última fila.

### Recomendación

En la cabecera de `TGrid.prg`, anyadir una nota: *"En la práctica casi
siempre conviene asignar `bRowEmpty` propio en grids de detalle. La
heurística por defecto está pensada para listados de consulta, no para
grids editables."*

Ejemplo de bRowEmpty para una línea de factura:

```harbour
oGrid:bRowEmpty := { |aRow| Empty( aRow[ "ARTICULO" ] ) }
```

---

## [ ] B013 — Manejo de errores no uniforme entre clases

**Archivo:** Todos los `T*.prg`.
**Severidad:** MEJORA. Riesgo de UX errática.

### Causa

`TMenu` envuelve la ejecución de items en `BEGIN SEQUENCE` con un
handler `_MenuError` que loguea y muestra `MsgStop`. El resto de
controles (`TButton:Click`, `TGet:Validate`, `TCombo:bChange`,
`TGrid:bEnter` / `bInsert`...) evalúan codeblocks "a pelo". Si uno
falla, te llevas la ventana entera por delante (cae al `ErrSys` global
y la app cierra).

### Fix

Centralizar la evaluación de codeblocks de usuario en una función
helper:

```harbour
// En Util.prg
FUNCTION EvalSafe( bBlock, cContext, ... )

    LOCAL aArgs := hb_AParams()
    LOCAL xRet
    LOCAL oErr
    LOCAL bOld

    aArgs := ASize( aArgs, Max( 2, Len( aArgs ) ) )
    ASize( aArgs, Len( aArgs ) - 2 )         // quitar bBlock y cContext

    bOld := ErrorBlock( {| e | Break( e ) } )
    BEGIN SEQUENCE
        xRet := hb_ExecFromArray( bBlock, aArgs )
    RECOVER USING oErr
        ErrorLogAppend( "Error en " + cContext + ": " + ;
                        hb_ValToStr( oErr:Description ) )
        MsgStop( "Error en " + cContext + ":" + hb_Eol() + ;
                 oErr:Description, "Error" )
        xRet := NIL
    END SEQUENCE
    ErrorBlock( bOld )

RETURN xRet
```

Y usarlo en todas las clases:

```harbour
// TButton:Click
IF ::bAction != NIL
    EvalSafe( ::bAction, "TButton:" + ::cCaption, Self )
ENDIF

// TGrid:HandleKey rama K_ENTER
IF ::bEnter != NIL .AND. ::nCurRow >= 1 .AND. ::nCurRow <= Len( ::aData )
    EvalSafe( ::bEnter, "TGrid:bEnter", Self )
    ::Paint()
ENDIF

// TGet:Validate
IF ::bValid != NIL
    lOk := EvalSafe( ::bValid, "TGet:bValid", Self )
ENDIF
```

No es trivial introducirlo a posteriori, pero pega un cambio de
robustez serio. Si lo dejas para v2, al menos protege ya las llamadas
en `TButton:Click` y `TGrid:bEnter`/`bInsert`/`bDelete`, que son las
más expuestas a errores de programación de la app cliente.

---

## [ ] B014 — Política de cursor inconsistente entre controles

**Archivo:** Varios `T*.prg`.
**Severidad:** MEJORA. Cosmética.

### Causa

`Gfx.prg` documenta que el cursor solo se muestra en TGet con foco. El
cumplimiento por control:

- `TGet:Paint`: enciende cursor si focused, apaga si no. ✓
- `TButton:Paint`: apaga cursor si focused, no toca si no focused.
  Dependes de quién pintó antes.
- `TCheck:Paint`: apaga siempre. ✓
- `TCombo:Paint`: apaga siempre. ✓
- `TLabel:Paint`: no toca cursor.
- `TGrid:Paint`: no toca cursor.

### Fix

Política única: cualquier `Paint` que **no** sea TGet apaga el cursor
al final, dentro del `Lock/Unlock`:

```harbour
// Al final de cada Paint excepto TGet
GfxCursor( SC_NONE )
```

Así no dependes del orden de pintado. Si el último que pintó fue un
TGet con foco, el cursor está encendido; cualquier otro repintado lo
apaga.

---

## [ ] B015 — TGet detecta password con "@K", que en Clipper no significa eso

**Archivo:** `TGet.prg`, método `New`, línea ~44.
**Severidad:** MEJORA. Riesgo de confusión.

### Causa

```harbour
::lPassword := ( "@K" $ Upper( cPic ) )
```

En Clipper estándar, `@K` en una picture significa "no auto-clear",
es decir, no borrar el contenido al primer carácter tecleado. Nada que
ver con password.

### Fix

Eliminar la detección por picture y añadir un DATA explícito o un
parámetro:

```harbour
DATA lPassword INIT .F.

// En el constructor, eliminar la línea ::lPassword := ( "@K" $ ... )

// El usuario lo activa explícitamente:
oGet := TGet():New( 10, 5, "", "@!", oWin )
oGet:lPassword := .T.
```

O bien añade un parámetro al constructor:

```harbour
METHOD New( nRow, nCol, uValue, cPic, oPar, lPwd ) CLASS TGet
    DEFAULT lPwd TO .F.
    ...
    ::lPassword := lPwd
```

---

## [ ] B016 — ValidNif acepta cadena vacía como válida

**Archivo:** `Util.prg`, funciones `ValidNif*`, líneas ~804 y ~846.
**Severidad:** MEJORA. Decisión de diseño que conviene documentar.

### Causa

```harbour
IF Empty( cNif )
    RETURN .T.
ENDIF
```

Útil para campos opcionales, pero peligroso si lo usas en una
validación obligatoria — pasa silenciosamente.

### Fix

Documentar el comportamiento en cabecera y, opcionalmente, ofrecer un
wrapper:

```harbour
// ----------------------------------------------------------------------------
// ValidNifFiscal( cNif, lSilent )
// NIF/CIF/NIE vacio se considera VALIDO (campo opcional).
// Para validacion obligatoria usar ValidNifObligatorio().
// ----------------------------------------------------------------------------

FUNCTION ValidNifObligatorio( cNif, lSilent )
    IF Empty( AllTrim( cNif ) )
        IF !lSilent
            MsgStop( "El NIF/CIF es obligatorio.", "Validacion NIF" )
        ENDIF
        RETURN .F.
    ENDIF
RETURN ValidNifFiscal( cNif, lSilent )
```

---

# RESUELTOS DURANTE LA REVISIÓN

## [x] B017 — TWindow:Paint barra de título

Confirmaste que el diseño de pintar el título de `nLeft` a `nRight`
inclusive es **intencional** para conseguir la franja azul tipo Win95
de borde a borde. No tocar.

Mejora opcional ya planteada en chat: cubrir también el caso de título
vacío con un `GfxClear` previo de la fila completa, para que la franja
azul aparezca siempre. No es bug, es mejora cosmética.

## [x] B018 — Colisión TMenu vs OOpMenu4

Confirmaste que `OOpMenu4.prg` queda fuera del build (carpeta
`_legacy/` o eliminado). No volver a meter al `.hbp`.

## [x] B019 — TButton ignora silenciosamente nBottom

Resuelto: añadiste cabecera explicativa con el contrato del
constructor (altura fija = 1 fila, ancho mínimo = 10 columnas). El
contrato queda claro para futuros lectores.

## [x] B020 — Discrepancias entre GfxManual.md y código

Confirmaste que el manual está desactualizado y la fuente de verdad
son los `.prg`. Recomendación general: cuando la API se estabilice,
regenerar el manual a partir de las cabeceras de los archivos en lugar
de mantenerlo a mano.

## [x] B021 — TTable.prg no se usa

Confirmaste que prefieres acceso directo xBase. Sacar `TTable.prg` del
`.hbp`. Si quieres conservarlo como referencia, a `_legacy/`.

---

# ORDEN SUGERIDO DE TRABAJO

Si vas a abordar esto por fases, propongo:

1. **Sesión 1 — Críticos de datos (1-2 horas):**
   B001, B002, B003. Son tres cambios localizados en `GetNextNum` y
   evitan corrupción de numeración de documentos. Imprescindible
   antes de producción.

2. **Sesión 2 — Críticos de estabilidad (30 min):**
   B004 (TLabel NIL).

3. **Sesión 3 — Serios de UX (2-3 horas):**
   B005, B006, B007. El B007 es el que más cambios estructurales
   pide; tómate tiempo para decidir entre las opciones B y C.

4. **Sesión 4 — Mejoras (cuando quieras):**
   B008-B016. Sin urgencia. B013 (manejo de errores uniforme) es la
   que más vale la pena de las "no críticas" porque te va a ahorrar
   horas de soporte.

---

**Fin del informe.**
