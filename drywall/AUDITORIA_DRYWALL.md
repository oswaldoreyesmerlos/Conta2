# Auditoría Drywall — GfxStack

**Fecha:** 2026-05-22
**Total:** ~9.650 líneas, 20 PRG, 16 tablas DBF

---

## Puntos fuertes

| # | Fortaleza | Dónde |
|---|-----------|-------|
| S1 | Modularización por responsabilidad | 20 archivos con propósito único |
| S2 | OOPTRAMO como clase de cálculo | New/Procesar/MostrarErrores/AddMat |
| S3 | SYS_REND extensible | Rendimientos configurables sin recompilar |
| S4 | Boy Scout pattern (save/restore área) | PRES_MOD, TARE_MOD, VAL_MOD |
| S5 | Validación centralizada | VALID_MOD.prg: 15+ funciones `_Dv*` |
| S6 | Hash-based data passing | CALC_ADD/CALC_EDIT con hb_Hash() |
| S7 | Test de saturación | TestOopSaturacion.prg: 320 tramos, 8 patrones |
| S8 | Transacción en guardado presupuesto | GenPresupuesto.prg usa BEGIN/END TRANSACTION |

---

## Debilidades (orden prioritario)

### P1 — Lógica de negocio mezclada con UI
`CALC_ADD.prg` (914 ln) mezcla forms, validación, DBF y reglas de negocio.
`TARE_MOD.prg` (779 ln) combina grid, CRUD, DBF y lógica de proyecto.
- **Impacto:** Dificulta testear, mantener y reutilizar.
- **Propuesta:** Extraer `_CoreSave()` y toda escritura DBF a `DrywallData.prg`.

### P2 — Constantes hardcodeadas en OOPTRAMO
```harbour
#define K_DESP_PLA   1.05   // Pladur: 1.10
#define K_DESP_PER   1.10   // correcto
#define K_TORN_M2    15     // correcto
#define K_TORN_MM    4      // correcto
#define K_PASTA_M2   0.40   // correcto
#define K_CINTA_M2   1.45   // Pladur: 3.15 (tabique), 1.89 (techo)
```
- **Impacto:** Cinta infravalorada ~50% frente al manual técnico.
- **Propuesta:** Eliminar `#define` y poblar SYS_REND para todos los casos.

### P3 — Calc_Trasdosado() no añade materiales
- **Cinta de juntas:** 1.30 ml/m² (autoportante) — no se añade nunca
- **Tornillos MM:** 3 ud/m² — no se añaden nunca
- **Guardavivos:** 0.15 ml/m² — no se añaden nunca
- **Impacto:** Presupuestos de trasdosado incompletos.

### P4 — DesgloseAnclaje() calcula mal
```
nPuntos := nArea / (nSepPrim * 1.00)  // debería ser nArea / (nSepPrim * nMod)
```
- `nPuntos` termina siendo metros lineales de primario, no número de puntos de anclaje.
- Varilla: `0.50` m/punto hardcodeado.

### P5 — dbSetOrder(n) por número en vez de OrdSetFocus("TAG")
Ocurre en OOPTRAMO:AddMat (línea 554), LimpiarLinea (línea 142), etc.
- **Impacto:** Rompe si cambia el orden de creación de índices.

### P6 — Sin transacciones en GrabaPres() / DrywallGuardarCalculado()
Múltiples tablas (TMP_CAB/TRA/MAT/RES → HIS_CAB/TRA/MAT/RES) sin protección.
- **Impacto:** Crash deja estado inconsistente (datos a medio copiar).

### P7 — Patrón duplicado de apertura de tablas
```harbour
IF Select("TMP_TRA") == 0
    USE TMP_TRA NEW SHARED VIA "DBFCDX"
ENDIF
```
Repetido ~15 veces en CALC_ADD, CALC_EDIT, OOPTRAMO, etc.
- **Propuesta:** Helper `_OpenIfNeeded(cAlias)` con flag `lWeOpened`.

### P8 — Potenciales NIL en FIELD->*
- `PLAC_CARA`, `L_AISLANT`, `CARAS`, `L_BANDA` como `FIELD->*` sin verificación de tipo.
- **Impacto:** Runtime error si el campo es NIL (migraciones, datos incompletos).
- **Propuesta:** `If(ValType(FIELD->X) == "N", FIELD->X, 0)`.

### P9 — _DvShow() trunca errores a 8
`DV_MAX_MSG := 8` oculta errores en validaciones masivas.
- **Propuesta:** Reemplazar con lista scrollable o log completo.

### P10 — Margen de presupuesto no se aplica
`TMP_CAB->MARGEN` existe pero `GenPresupuesto.prg` no lo aplica al subtotal.
- **Propuesta:** `nSubtotal *= (1 + MARGEN / 100)` antes de IVA.

---

## Flujo de ejecución

```
drywall_main:Main()
  ├── InicioDrywall()   → crea tablas TMP_*/HIS_*/ARTICULOS/SYS_REND/PRESUPUEST
  ├── SeedDrywall()      → datos semilla (artículos, rendimientos, proyectos demo)
  └── _DrywallMenu()    → TMenu:Activate()

ProyectoActual() / VerTareas()
  ├── _OnAppend()  → Add_Tabique/Techo/Trasdosado/Generico → Form_* → _CoreSave()
  ├── _OnEdit()    → EditTramo() → Form_* (mismos forms, flag lNuevo=.F.)
  └── Procesa()    → CALC_MOD:_ProcesaTramo()
       └── OOPTRAMO:New():Procesar()
            ├── LimpiarLinea()     → borra TMP_MAT automático del tramo
            ├── Calc_Rendimientos()→ busca en SYS_REND; fallback a constantes #define
            └── Calc_Tabique/Techo/Trasdos/Generico → AddMat()

Valorar() → VAL_MOD:Valorar()
  ├── Carga TMP_RES, permite editar precios
  ├── Botón RESUMEN → ResultadoResumen() (cabecera + totales)
  ├── Botón DESPIECE → ResultadoDetalle() (grid TMP_RES)
  └── Botón GUARDAR Y GENERAR PRESUPUESTO → DrywallGuardarGenerar()
       └── GenPresupuesto:DrywallGenPresupuesto()
            └── Crea PRESUPUEST/PRESUP_DE + Archiva en HIS_*
```

---

## Tablas DBF (16)

| Tabla | Uso | Creada por |
|-------|-----|------------|
| TMP_CAB | Proyecto activo (cabecera) | InicioDrywall |
| TMP_TRA | Tramos del proyecto activo | InicioDrywall |
| TMP_MAT | Materiales calculados del proyecto activo | InicioDrywall |
| TMP_RES | Resumen de materiales (agrupado por código) | InicioDrywall |
| HIS_CAB | Proyecto histórico (cabecera) | InicioDrywall |
| HIS_TRA | Tramos históricos | InicioDrywall |
| HIS_MAT | Materiales históricos | InicioDrywall |
| HIS_RES | Resumen histórico | InicioDrywall |
| ARTICULOS | Catálogo de artículos | InicioDrywall |
| TABLAS_AUX | Tablas auxiliares (perfiles, placas, etc.) | InicioDrywall |
| SYS_REND | Rendimientos por sistema constructivo | InicioDrywall |
| PRESUPUEST | Presupuestos generados (cabecera) | InicioDrywall |
| PRESUP_DE | Presupuestos generados (detalle) | InicioDrywall |
| FAMILIAS | Familias de artículos (compartida) | InicioDBF |
| CLIENTES | Clientes (compartida) | InicioDBF |
| CONTADOR | Contadores (compartida) | InicioDBF |

---

## Pendientes de la auditoría anterior (API)
- GfxShadow() colores fijos (D01)
- GfxPaintPush/Pop sin control desbordamiento (D02)
- TControl sin HasFocus() ni IsTabStop() (D03)
- TGet sin placeholder (D07)
- TGet ancho mínimo documentar (D08)
- TGrid bChange en cada movimiento (D09)
- TGrid sin columna de ordenamiento (D10)
- ErrSys no restaura cursor (D14)
