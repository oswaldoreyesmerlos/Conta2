# Auditoría del Módulo Drywall (Junio 2026)

## 1. Resumen Ejecutivo

Drywall es un módulo de cálculo de tabiquería seca (pladur) construido sobre GfxStack API. Gestiona presupuestos técnicos completos: definición de tramos (tabiques, techos, trasdosados, genéricos), cálculo de materiales mediante motor OOP (OOPTRAMO), valoración económica, generación de presupuestos formal y archivo histórico.

**Tamaño total**: ~10,200 líneas de código Harbour en 20 archivos `.prg`.
**Estado funcional**: Operativo, con pruebas de saturación que validan el núcleo.
**Riesgo principal**: Bajo uso de índices (escaneos secuenciales masivos); duplicación de lógica de apertura/cierre de SYS_REND; riesgo de concurrencia en bloqueos largos.

---

## 2. Estructura de Archivos

| Archivo | Líneas | Funciones principales | Propósito |
|---|---|---|---|
| `drywall_main.prg` | 109 | `Main()`, `_DrywallMenu()`, `_DrywallTemaVisual()` | Punto de entrada, menú principal |
| `OOPTRAMO.prg` | 730 | `New()`, `Procesar()`, `Calc_Rendimientos()`, `MatchRendimiento()`, `CodigoRendimiento()`, `Calc_Tabique/Techo/Trasdos/Generico()`, `AddMat()`, `GetRendimientoRol()`, `DesgloseAnclaje()`, `LimpiarLinea()`, `MostrarErrores()` | Motor de cálculo OOP (clase central) |
| `CalcUtils.prg` | 138 | `_OptionalCode()`, `_CantidadCompra()`, `_RoundUp()`, `_SysAncho()`, `_GetAuxTitle()`, `_InformeTextoLineas()` | Utilidades públicas de cálculo |
| `CALC_MOD.prg` | 470 | `Procesa()`, `_GeneraResumen()`, `_LimpiaBD()`, `_ConvierteResumenCompra()`, `_CountAlias()`, `_EnsureCalcTables()` | Controlador del proceso de cálculo |
| `CALC_ADD.prg` | 1279 | `Add_Tabique/Techo/Trasdosado/Generico()`, `Form_Tabique/Techo/Trasdosado/Generico()`, `_CoreSave()`, `_InitData()`, `_PickArt()`, `_TechoSistemaData/PorMaterial/SistemasData/AplicarSistema()` | Altas especializadas con formularios GfxStack |
| `CALC_EDIT.prg` | 220 | `EditTramo()`, `_LoadData()`, `_UpdateData()` | Edición de tramos existentes |
| `VALID_MOD.prg` | 616 | `DrywallValidarTramos()`, `DrywallValidarParaHistorico/Presupuesto()`, `DrywallMarkCalculated/Dirty()`, `DrywallMarkCabDirty()`, `_DvValidaTramoActual/Cabecera/Resumen/Cuenta()` | Validaciones integrales |
| `VAL_MOD.prg` | 467 | `Valorar()`, `ValorarHistorico()`, `ResultadoResumen/Detalle()`, `_ValEditarPrecio/Guardar/Cargar()` | Valoración económica y visualización de resultados |
| `PRES_MOD.prg` | 779 | `GrabaPres()`, `DrywallGuardarCalculado/CerrarHistorico()`, `_MoverCabecera/Tramos/Resumen/Materiales()`, `_LimpiaTemporales()`, `_GetNextDoc()` | Paso a histórico y cierre de proyectos |
| `GenPresupuesto.prg` | 569 | `DrywallGenPresupuesto()`, `_PreGuardarDrywall()`, `_ImpPresupuestoTxt()`, `_CliSeleccionar()` | Generación formal de presupuesto (PDF/TXT) |
| `EDIT_MOD.prg` | 150 | `EditAux()`, `AuxForm()` | Mantenimiento de tablas auxiliares |
| `TARE_MOD.prg` | 706 | `ProyectoActual()`, `VerTareas()`, `_OnAppend/Edit()`, `_CrearProyectoActual()`, `_GuardarCabeceraTrabajo()`, `_SeleccionaProyectoTrabajo()` | Gestión de proyectos (cabecera + grid tramos) |
| `InicioDrywall.prg` | 398 | `InicioDrywall()`, `_TieneCampos()`, `_BorraDbf()` | Creación de tablas DBF e índices |
| `M_Articulos.prg` | 374 | `ArticulosView()`, `ArticulosForm()`, `ArticuloGuardar()` | CRUD de catálogo de artículos |
| `M_Familias.prg` | 238 | `M_Familias()`, `FamiliaGuardar()` | CRUD de familias de artículos |
| `M_Sistemas.prg` | 715 | `SistemasView()`, `_SisCabForm()`, `_SisLineas()`, `_LinForm/Guardar/Borrar()` | CRUD de sistemas constructivos y rendimientos |
| `Informes_Inventario.prg` | 986 | `InformeArticulos/StockMinimo/ClientesDrywall/Proyectos/Historicos()`, `VisorProyectos()`, `DrywallRecuperarHistorico()` | Informes y visor de proyectos |
| `SeedDrywall.prg` | 610 | `SeedDrywall()`, `_SeedAuxiliares/Articulos/Rendimientos/Proyectos()` | Datos de semilla para pruebas |
| `TestOopSaturacion.prg` | 694 | `Main()` (test procedure), `_SeedFixtures()`, mock functions | Test de saturación de OOPTRAMO |
| `DumpCalcData.prg` | 162 | `Main()`, `_DumpTramos/Materiales/Resumen/Rendimientos/Articulos()` | Volcado de depuración |

### Archivos de proyecto (HBP)

| Archivo | Contenido |
|---|---|
| `drywall.hbp` | Build principal: todos los .prg + dependencias GfxStack + Util + InicioDBF + Seguridad + ReglasNegocio + M_Clientes |
| `seed_drywall.hbp` | Build semilla: solo SeedDrywall.prg |
| `test_oop_saturacion.hbp` | Build test: TestOopSaturacion + CalcUtils + OOPTRAMO |

---

## 3. Análisis por Archivo

### 3.1 drywall_main.prg (109 líneas)

- **Punto de entrada**: `Main()` configura RDD, fecha, fuente, modo pantalla, carga tema visual, inicializa tablas via `InicioDrywall()`, y activa menú jerárquico.
- **Funciones expuestas**: `Main()` (pública).
- **Funciones estáticas**: `_DrywallMenu()`, `_DrywallTemaVisual()`.
- **Dependencias**: InicioDrywall, TMenu, GfxTheme*, PopupSelect, y todas las funciones callback del menú.
- **Debilidades**: Manejo de errores mínimos (BEGIN SEQUENCE solo para SetEventMask). Si `InicioDrywall()` falla, muestra error y termina.

### 3.2 OOPTRAMO.prg (730 líneas) — Clase central

- **DATA**: `nErrores` (num), `aLog` (array).
- **METHOD New**: Inicializa aLog vacío y nErrores=0.
- **METHOD Procesar(lTodo)**: Itera TMP_TRA, para cada tramo llama LimpiarLinea, luego intenta Calc_Rendimientos; si falla, bifurca por tipo (Calc_Tabique/Techo/Trasdos/Generico).
- **METHOD Calc_Rendimientos**: Abre SYS_REND si es necesario, recorre secuencialmente, llama MatchRendimiento + CodigoRendimiento + AddMat.
- **METHOD MatchRendimiento**: Compara SISTEMA_ID, TIPO_OBRA, CARAS, CAPAS, MODUL, ANCHO_PERF.
- **METHOD CodigoRendimiento**: Traduce roles (PLACA_A, MONTANTE, etc.) a códigos reales del tramo o defaults.
- **Métodos Calc_X**: Fórmulas paramétricas con AddMat.
- **METHOD AddMat**: Busca artículo en ARTICULOS, bloquea TMP_MAT, append, REPLACE.
- **Puntos débiles**:
  - `Calc_Rendimientos()` escanea SYS_REND secuencialmente sin usar índice.
  - `Procesar()` usa `DEFAULT lTodo TO .T.` (correcto en Harbour).
  - En `AddMat()`, si `NetFLock()` falla, no restaura `nOrdArt` (IndexOrd) antes de retornar.
  - En `LimpiarLinea()`, `OrdSetFocus("MAT_LIN")` sin verificar que el tag exista.
  - Uso de `FIELD->` sin alias explícito dentro de métodos.

### 3.3 CalcUtils.prg (138 líneas)

- Funciones públicas de apoyo bien encapsuladas.
- `_OptionalCode()`: considera "0" como opcional, lo que fuerza a los artículos a no tener código "0".
- `_CantidadCompra()`: Lógica de conversión a unidades de compra. Correcta pero con defaults hardcodeados (1000 tornillos/caja, 3m perfil, etc.).
- `_RoundUp()`: Redondeo hacia arriba estándar.
- **Sin debilidades significativas**.

### 3.4 CALC_MOD.prg (470 líneas) — Controlador de cálculo

- **Procesa()**: Verifica tablas, confirma, limpia, invoca OOPTRAMO, genera resumen, reporta.
- **Puntos débiles**:
  - Línea 95: Condición `IF oCalc:nErrores == 0 .AND. ( nTramos == 0 .OR. nMat == 0 .OR. nRes == 0 )` — si hay errores Y conteos cero, no se muestra ni el mensaje de incompleto ni los errores (solo MostrarErrores). El flujo es: si errores==0 y vacío → muestra "incompleto"; si errores>0 → muestra errores. Correcto pero confuso.
  - `_GeneraResumen()`: Usa `hb_Hash` para agrupar por línea, luego por artículo. Al final itera TMP_RES con `FOR i := 1 TO Len(aKeys)` pero ya no verifica si otro usuario añadió registros entre el unlock y el next.
  - `_LimpiaBD()`: Mantiene NetFLock() durante todo el borrado (puede ser larga para proyectos grandes).

### 3.5 CALC_ADD.prg (1279 líneas) — Formularios de alta

- Contiene Form_Tabique (173 líneas), Form_Techo (379 líneas), Form_Trasdosado (273 líneas), Form_Generico (94 líneas).
- `_CoreSave()`: Validación + REPLACE en TMP_TRA con NetFLock().
- `_PickArt()`: Abre ARTICULOS con índice ART_FAM, recorre por familia.
- **Puntos débiles**:
  - Enorme duplicación: `_TechoSistemaData()`, `_TechoSistemaPorMaterial()`, `_TechoSistemasData()` repiten el patrón de abrir SYS_REND, recorrer secuencialmente, cerrar.
  - `_TechoSistemaData()` busca sistema por escaneo secuencial (SYS_REND no usa índice SR_SIS para seek).
  - `_TechoSeleccionarMaterial()`: Si cRol no es PLACA_A, cFamilia siempre "PERFIL". No considera otros roles como AISLAN, PASTA, etc.
  - `_BtnPick()` llama a `_PickArt(cFam)` que escanea ARTICULOS por familia sin índice si no existe ART_FAM.

### 3.6 VALID_MOD.prg (616 líneas) — Validaciones

- Funciones de marcado de estado (dirty/calculated) y validación estructural.
- `DrywallValidarTramos()`: Recorre TMP_TRA, para cada tramo llama `_DvValidaTramoActual()`.
- `_DvArticuloExiste()`: Busca con seek + fallback a escaneo secuencial.
- **Puntos débiles**:
  - `DrywallMarkCalcDirty()`, `DrywallMarkCabDirty()`, `DrywallMarkCalculated()` tienen lógica casi idéntica (abrir TMP_CAB, buscar proyecto, REPLACE estado). Refactorizable.
  - `_DvOpen()` llama `OrdSetFocus()` dentro de BEGIN SEQUENCE pero no verifica que el tag exista.

### 3.7 VAL_MOD.prg (467 líneas) — Valoración

- `Valorar()`: Grid con TMP_RES, permite editar precios, guarda.
- `ResultadoResumen()` / `ResultadoDetalle()`: Visualización en TGrid.
- **Puntos débiles**:
  - `_ValGuardarEn()`: Para cada línea del array, escanea TMP_RES secuencialmente buscando NUMERO+CODIGO. Ineficiente: TMP_RES tiene índice RES_PK (NUMERO+CODIGO) pero no se usa.
  - `_ValCargarDesde()`: similar, escaneo secuencial. Podría usar seek por RES_PK.
  - `_ValEditarPrecio()`: Ventana modal bien construida.

### 3.8 PRES_MOD.prg (779 líneas) — Paso a histórico

- `GrabaPres()`: Valida, asigna número correlativo, mueve TMP_* → HIS_*.
- `DrywallGuardarCalculado()`: Guarda como calculado (mantiene mismo número).
- `DrywallCerrarHistorico()`: Cierra proyecto histórico (estado "F").
- **Puntos débiles**:
  - `_MoverCabecera()` busca TMP_CAB con escaneo secuencial (TMP_CAB no tiene índices).
  - `_MoverTramos()`: Bloquea HIS_TRA con NetFLock() al inicio, luego itera TMP_TRA y hace append a HIS_TRA manteniendo el bloqueo. Bloqueo largo.
  - `_BorraTemporalProyecto()`: Si falla el bloqueo de una tabla, retorna .F. pero las tablas previas quedan bloqueadas.
  - `_GetNextDoc()`: Usa CONTADOR, correcto con NetRLock().
  - `_BorradoTotalObsoleto()` (línea 242): Código muerto comentado como obsoleto.

### 3.9 GenPresupuesto.prg (569 líneas) — Presupuesto formal

- `DrywallGenPresupuesto()`: Obtiene datos de cabecera + resumen, abre diálogo con TGrid, guarda en PRESUPUEST/PRESUP_DE con transacción.
- **Puntos débiles**:
  - `_PreGuardarDrywall()` abre PRESUPUEST alias PRE_DRY y PRESUP_DE alias PRD_DRY. Si PRESUP_DE falla, cierra PRE_DRY correctamente.
  - `_PreSiguienteDry()`: Escanea PRESUPUEST secuencialmente para calcular el próximo número. Ineficiente para muchos presupuestos.
  - `DrywallGenPresupuesto()`: Las variables `nFila` se incrementan manualmente — frágil ante cambios de layout.

### 3.10 TARE_MOD.prg (706 líneas) — Gestión de proyectos

- `ProyectoActual()`: Crea/edita proyecto actual.
- `VerTareas()`: Grid principal de tramos con botones de calcular/valorar.
- **Puntos débiles**:
  - `_AbrirTablas()` (línea 307): Abre TMP_TRA, TMP_MAT, TMP_RES, TMP_CAB, TABLAS_AUX. No abre ARTICULOS, CLIENTES, SYS_REND, etc. (se abren bajo demanda).
  - `_AdoptaTramosSinProyecto()`: Recupera tramos huérfanos (NUMERO vacío). Buena feature.

### 3.11 InicioDrywall.prg (398 líneas) — Creación de tablas

- Define estructuras de TMP_CAB, TMP_TRA/HIS_TRA, TMP_MAT/HIS_MAT, TMP_RES/HIS_RES, HIS_CAB, TABLAS_AUX, SYS_REND, PRESUPUEST, PRESUP_DE.
- **Puntos débiles**:
  - `TMP_CAB` definido SIN índices (aInds := {}). Esto fuerza escaneos secuenciales en todas las búsquedas por número de proyecto.
  - `DbCreate()` con último parámetro `.T.` (modo compartido) y alias "DRYWALL" para el RDD. Correcto.
  - Reconstrucción de CDX: Abre en exclusivo, revisa LastRec, regenera índices. Correcto.
  - `_TieneCampos()`: Compara estructura actual con esperada; si difiere, borra y recrea la tabla. Esto puede causar pérdida de datos si se añaden campos en versiones futuras.

### 3.12 M_Articulos.prg (374 líneas) — CRUD artículos

- Estándar. `ArticuloGuardar()`: seek, bloquea, REPLACE. Correcto.
- Sin debilidades significativas.

### 3.13 M_Familias.prg (238 líneas) — CRUD familias

- Estándar. `FamiliaGuardar()` no hace `dbCommit()` después de REPLACE (a diferencia de ArticuloGuardar). Inconsistencia.
- `_FamForm()`: falta `oGCod:nMaxLen` o similar para limitar a 3 caracteres.

### 3.14 M_Sistemas.prg (715 líneas) — CRUD sistemas

- **Puntos débiles**:
  - `_SisGuardarCab()` (para editar): Escanea SYS_REND secuencialmente (sin usar SR_SIS) para encontrar el sistema a actualizar.
  - `_SisHeader()`: Escaneo secuencial para buscar cabecera del sistema.
  - `_LinSeek()`: Escaneo secuencial para encontrar línea por orden.
  - El índice SR_SIS existe pero no se usa para seek en ningún lugar de este módulo.

### 3.15 Informes_Inventario.prg (986 líneas) — Informes y visor

- Funciones de informe bien estructuradas.
- `VisorProyectos()`: Grid unificado TMP+HIS con acciones contextuales.
- `DrywallRecuperarHistorico()`: Copia HIS_* a TMP_* para reabrir.
- **Puntos débiles**:
  - `_VisorCargarDatos()`: Abre TMP_RES para verificar estado, pero lo abre y cierra sin usar en algunos casos. Pequeña fuga de recursos.
  - `_VisorMostrarResultado()`: Usa `OrdSetFocus(1)` — asume que el primer índice es el correcto para buscar por NUMERO. Para TMP_RES es "RES_PK" (NUMERO+CODIGO). Si se busca por NUMERO exacto con seek, "RES_PK" sirve parcialmente (solo primer registro del proyecto).
  - `_RecCopiarTramos()`: Bloquea TMP_TRA al inicio, luego itera HIS_TRA y hace appends. Bloqueo largo.

### 3.16 SeedDrywall.prg (610 líneas) — Datos semilla

- Inserta datos maestros con `FLock()` en lugar de `NetFLock()`. En modo exclusivo no hay problema, pero en modo compartido FLock es bloqueo de archivo completo (no de registro).
- **Debilidad**: `_Aux()` y `_Art()` usan `FLock()` para inserción, que en modo compartido podría ser demasiado restrictivo, pero como es seed (uso exclusivo) es aceptable.

### 3.17 TestOopSaturacion.prg (694 líneas) — Test

- Crea 320 tramos de 8 patrones distintos, ejecuta OOPTRAMO, verifica resultados.
- Mock de `DrywallProyectoActualNumero()` y `NetFLock()`, `NetRLock()`, `Ceiling()`.
- **Notable**: Mock de DrywallProyectoActualNumero significa que las funciones drywall_main.dll no se linkean con el test.

### 3.18 DumpCalcData.prg (162 líneas) — Utilidad de depuración

- Usa DBFNTX. Solo para diagnóstico.
- Sin debilidades.

---

## 4. Flujo de Datos y Procesos Clave

### 4.1 Ciclo de vida de un proyecto

```
1. Crear proyecto (TARE_MOD: _CrearProyectoActual)
   → TMP_CAB (cabecera con NUMERO, fecha, cliente, estado)
   
2. Añadir tramos (CALC_ADD: Add_Tabique/Techo/Trasdosado/Generico)
   → TMP_TRA (cada línea: geometría, materiales, sistema)
   
3. Calcular (CALC_MOD: Procesa → OOPTRAMO:Procesar)
   → Limpia TMP_MAT, TMP_RES
   → Por cada tramo en TMP_TRA:
     a. Calc_Rendimientos (busca SYS_REND)
     b. Si no hay rendimientos: Calc_Tabique/Techo/Trasdos/Generico
   → AddMat escribe en TMP_MAT
   → _GeneraResumen agrupa TMP_MAT en TMP_RES
   → _ConvierteResumenCompra normaliza unidades
   
4. Valorar (VAL_MOD: Valorar)
   → Edita precios en TMP_RES
   
5. Guardar en firme (PRES_MOD: DrywallGuardarCalculado)
   → TMP_* → HIS_* (mismo número)
   → Limpia temporales
   
6. Cerrar (PRES_MOD: DrywallCerrarHistorico / GenPresupuesto: DrywallGenPresupuesto)
   → Genera presupuesto formal (PRESUPUEST + PRESUP_DE)
   → Estado = "F" (cerrado)
   
7. Recuperar (Informes_Inventario: DrywallRecuperarHistorico)
   → Copia HIS_* → TMP_*
```

### 4.2 Flujo del motor OOPTRAMO

```
Procesar(lTodo)
  ├── Por cada TMP_TRA no borrado del proyecto:
  │   ├── LimpiarLinea (borra materiales auto en TMP_MAT)
  │   ├── Calc_Rendimientos
  │   │   ├── Abre SYS_REND (si no abierta)
  │   │   ├── Escanea secuencial SYS_REND
  │   │   ├── MatchRendimiento (filtra por parámetros)
  │   │   ├── CodigoRendimiento (traduce rol a código real)
  │   │   └── AddMat (escribe TMP_MAT)
  │   └── Si no hay rendimientos:
  │       ├── Calc_Tabique (fórmulas fijas)
  │       ├── Calc_Techo (fórmulas fijas)
  │       ├── Calc_Trasdos (fórmulas fijas)
  │       └── Calc_Generico (fórmulas fijas)
  └── MostrarErrores (si nErrores > 0)
```

### 4.3 Flujo de generación de presupuesto

```
DrywallGenPresupuesto(cNumProyecto, cOrigen)
  ├── Lee cabecera (TMP_CAB o HIS_CAB)
  ├── Valida con DrywallValidarParaPresupuesto
  ├── Verifica que no exista presupuesto previo (_PreExisteOrigen)
  ├── Carga líneas de TMP_RES o HIS_RES
  ├── Diálogo con TGrid (editar cliente, fechas, IVA, etc.)
  ├── _PreGuardarDrywall
  │   ├── _PreSiguienteDry (calcula número: P20260001)
  │   ├── BEGIN TRANSACTION
  │   │   ├── Append a PRESUPUEST
  │   │   ├── Appends a PRESUP_DE (una por línea)
  │   │   └── END TRANSACTION / ROLLBACK
  │   └── _ImpPresupuestoTxt (exporta a .\INFORME\)
```

---

## 5. Tablas DBF

### 5.1 Tablas temporales (TMP_*)

| Tabla | Campos clave | Índices | Uso |
|---|---|---|---|
| **TMP_CAB** | NUMERO(C6), FECHA(D), TITULO(C60), ID_CLIENTE(C15), ESTADO(C1), MARGEN(N5,2), OBSERV(C200), L_ACTIVO(L), L_SUCIO(L), L_CALC_DIR(L), L_CAB_DIR(L) | **NINGUNO** | Cabecera de proyecto activo |
| **TMP_TRA** | NUMERO(C6), ID_LINEA(N4), TIPO_OBRA(C15), SISTEMA_ID(C20), CONCEPTO(C40), LARGO(N6,2), ALTO(N6,2), MODUL(N5,2), ANCHO_PERF(N3), SEP_PRIM(N5,2), CARAS(N1), PLAC_CARA(N1), ID_PER_VER/HOR/PER(C15), ID_PLACA_A/B(C15), L_AISLANT(L), ID_AISLANT(C15), ID_ANCLAJE(C15), L_BANDA(L), METROS(N10,2) | TTRA_ORD: NUMERO+Str(ID_LINEA,4) | Tramos del proyecto activo |
| **TMP_MAT** | NUMERO(C6), ID_LINEA(N4), L_MANUAL(L), ORIGEN(C4), FAMILIA(C10), CODIGO(C15), DESCRIP(C40), UNIDAD(C5), PESO_TOT(N12,3), RENDIM(N12,3), CANTIDAD(N12,3), PRECIO(N10,2), IMPORTE(N12,2), DETALLE(C30) | MAT_NUM: NUMERO, MAT_LIN: NUMERO+Str(ID_LINEA,4), MAT_COD: CODIGO | Materiales calculados |
| **TMP_RES** | NUMERO(C6), FAMILIA(C10), CODIGO(C15), DESCRIP(C40), UNIDAD(C5), CANT_TOT(N12,3), PESO_TOT(N12,3), PRECIO(N10,2), IMP_TOT(N12,2) | RES_PK: NUMERO+CODIGO | Resumen agrupado |

### 5.2 Tablas históricas (HIS_*)

| Tabla | Índices | Notas |
|---|---|---|
| HIS_CAB | HIS_NUM, HIS_CLI | Campos extra: PRES_NUM, FEC_CALC, FEC_CIERRE |
| HIS_TRA | HTRA_NUM: NUMERO+Str(ID_LINEA,4) | Misma estructura que TMP_TRA |
| HIS_MAT | HMAT_NUM, HMAT_LIN | Misma estructura que TMP_MAT |
| HIS_RES | HRES_PK: NUMERO+CODIGO | Misma estructura que TMP_RES |

### 5.3 Tablas maestras

| Tabla | Índices | Notas |
|---|---|---|
| **ARTICULOS** | ART_COD, ART_FAM, ART_DES (definidos externamente en InicioDBF) | Catálogo de materiales |
| **SYS_REND** | SR_SIS: Upper(SISTEMA_ID)+Str(ORDEN,4), SR_TIPO: Upper(TIPO_OBRA)+Str(MODUL)+Str(CARAS)+Str(CAPAS)+Str(ANCHO_PERF)+Str(ORDEN,4) | Rendimientos técnicos |
| **TABLAS_AUX** | AUX_PK: Upper(TIPO)+Upper(CODIGO) | Listas auxiliares (PERFIL, PLACA, etc.) |
| **FAMILIAS** | FAM_COD (externo) | Familias de artículos |
| **CLIENTES** | CLI_ID, CLI_NOM (externo) | Clientes |
| **CONTADOR** | (externo) | Contadores |

### 5.4 Tablas de presupuesto formal

| Tabla | Índices | Notas |
|---|---|---|
| **PRESUPUEST** | PRE_NUM, PRE_CLI, PRE_FEC, PRE_OBR | Cabecera compartida con AppGestion |
| **PRESUP_DE** | PRD_LIN: NUMERO+Str(LINEA,3) | Líneas compartidas con AppGestion |

---

## 6. Puntos Débiles Encontrados

### 6.1 Críticos

| ID | Archivo | Problema |
|---|---|---|
| **C1** | `InicioDrywall.prg:59` | **TMP_CAB sin índices**. Obliga a escaneo secuencial en cada operación con cabeceras (marcar dirty/calculated, buscar proyecto, mover a histórico). |
| **C2** | `OOPTRAMO.prg:237-255` | **Calc_Rendimientos escanea SYS_REND secuencialmente** en lugar de usar SR_TIPO (que está diseñado exactamente para este filtro: TIPO_OBRA+MODUL+CARAS+CAPAS+ANCHO_PERF+ORDEN). En proyectos grandes (>1000 tramos) y SYS_REND con muchos registros, esto es O(n*m) en lugar de O(log n + m). |
| **C3** | `Múltiples archivos` | **Duplicación masiva del patrón "abrir/cerrar SYS_REND + escaneo secuencial"** en: `Calc_Rendimientos`, `GetRendimientoRol`, `_TechoSistemaData`, `_TechoSistemaPorMaterial`, `_TechoSistemasData`, `_SisGuardarCab`, `_SisHeader`, `_LinSeek`. |
| **C4** | `PRES_MOD.prg:282-318` | **_BorraTemporalProyecto** no libera bloqueos previos si falla el bloqueo de una tabla intermedia. |

### 6.2 Altos

| ID | Archivo | Problema |
|---|---|---|
| **A1** | `CALC_MOD.prg:206-229` | `_LimpiaBD()` mantiene NetFLock() durante todo el borrado. Riesgo de contención. |
| **A2** | `PRES_MOD.prg:110-169` | `_MoverTramos()` mantiene NetFLock() en HIS_TRA durante toda la transferencia. |
| **A3** | `VAL_MOD.prg:407-433` | `_ValGuardarEn()` escanea TMP_RES secuencialmente en vez de usar índice RES_PK. |
| **A4** | `CALC_ADD.prg:540-597` | `_TechoSistemaData()` escanea SYS_REND secuencialmente. Podría usar `SR_SIS` para seek y luego filtrar por TIPO_OBRA="TECHO". |
| **A5** | `GenPresupuesto.prg:446-477` | `_PreSiguienteDry()` escanea PRESUPUEST completo para calcular próximo número. En tablas grandes (>1000 presupuestos), esto es lento. |
| **A6** | `M_Sistemas.prg:291-342` | `_SisGuardarCab()` escanea SYS_REND secuencialmente para actualizar cabecera. |
| **A7** | `OOPTRAMO.prg:607-730` | `AddMat()` no restaura `nOrdArt` (del índice original) si `NetFLock()` falla (retorna antes de `dbSetOrder(nOrdArt)`). |

### 6.3 Medios

| ID | Archivo | Problema |
|---|---|---|
| **M1** | `OOPTRAMO.prg:178` | `OrdSetFocus("MAT_LIN")` sin verificar que el tag exista. Si el CDX está corrupto o falta, Harbour lanza runtime error. |
| **M2** | `VALID_MOD.prg:1-49` | `DrywallMarkCalcDirty`, `DrywallMarkCabDirty`, `DrywallMarkCalculated` son casi idénticas y podrían refactorizarse en una sola función parametrizada. |
| **M3** | `PRES_MOD.prg:242-279` | `_BorradoTotalObsoleto` es código muerto (comentado como obsoleto). |
| **M4** | `M_Familias.prg:201-238` | `FamiliaGuardar()` no ejecuta `dbCommit()` después de REPLACE (inconsistente con `ArticuloGuardar`). |
| **M5** | `CALC_ADD.prg:1231-1234` | `_PickArt()` abre ARTICULOS con `OrdSetFocus("ART_FAM")`. Si el tag ART_FAM no existe, falla. |
| **M6** | `GenPresupuesto.prg:113-116` | `OrdSetFocus(cResIndex)` seguido de `dbSeek(PadR(...))` dentro de BEGIN SEQUENCE. El seek por NUMERO en índice "NUMERO+CODIGO" solo encuentra el primer registro del proyecto, pero luego itera con WHILE, lo cual es correcto. |
| **M7** | `SeedDrywall.prg` | Uso de `FLock()` en lugar de `NetFLock()` para inserciones. Funcional en seed (exclusivo), pero inconsistente con el estilo del resto del módulo. |

### 6.4 Bajos / Cosmética

| ID | Archivo | Problema |
|---|---|---|
| **L1** | `CALC_MOD.prg:95` | Condición confusa en `Procesa()`: `IF oCalc:nErrores == 0 .AND. (nTramos==0 .OR. nMat==0 .OR. nRes==0)`. Lógica correcta pero legibilidad baja. |
| **L2** | `VAL_MOD.prg:22` | `LastRec() == 0` no considera registros borrados. Si todos los registros están borrados pero hay alguno, LastRec() > 0 pero no hay datos visibles. |
| **L3** | `Informes_Inventario.prg:838` | `OrdSetFocus(1)` asume el orden del primer índice sin verificar. |
| **L4** | `CALC_ADD.prg:471` | `_TechoSeleccionarMaterial` solo soporta `cFamilia := "PERFIL"` o `cRol == "PLACA_A" → "PLACA"`. No considera otros roles. |
| **L5** | `OOPTRAMO.prg:206-210` | Default de `nMod` hardcodeado (0.50 para techo, 0.60 para otros). Debería venir de SYS_REND siempre que sea posible. |
| **L6** | `M_Sistemas.prg:536-540` | `lNuevo .AND. nOrden == 0` deshabilita campos en edición de línea 0 (cabecera). La condición es correcta: si es edición de la línea 0, no se permite cambiar orden/familia/rol. |

---

## 7. Dependencias Externas

### 7.1 Archivos externos necesarios (listados en drywall.hbp)

| Archivo | Ruta | Propósito |
|---|---|---|
| `Gfx.prg` | `..\api\` | Funciones gráficas base |
| `TControl.prg` | `..\api\` | Clase base de controles |
| `TLabel.prg` | `..\api\` | Etiqueta visual |
| `TGet.prg` | `..\api\` | Campo de entrada |
| `TButton.prg` | `..\api\` | Botón |
| `TCheck.prg` | `..\api\` | Checkbox |
| `TCombo.prg` | `..\api\` | Combo/listbox |
| `TGrid.prg` | `..\api\` | Grid de datos |
| `TWindow.prg` | `..\api\` | Ventana |
| `TMenu.prg` | `..\api\` | Menú jerárquico |
| `MsgBox.prg` | `..\api\` | MessageBox |
| `MsgYesNo.prg` | `..\api\` | Confirmación Yes/No |
| `Util.prg` | `..\` | ABRIR_TABLA, IsDbUsed, DbFieldPutIf, PopupSelect, DrywallProyectoActualNumero, DrywallActivarProyecto |
| `InicioDBF.prg` | `..\` | Creación de tablas base (ARTICULOS, CLIENTES, etc.) |
| `Seguridad.prg` | `..\` | Seguridad y accesos |
| `ReglasNegocio.prg` | `..\` | Reglas de negocio globales |
| `M_Clientes.prg` | `..\` | Mantenimiento de clientes |

### 7.2 Funciones externas más utilizadas

| Función | Origen | Usos en drywall |
|---|---|---|
| `ABRIR_TABLA()` | `Util.prg:354` | ~45 llamadas |
| `DrywallProyectoActualNumero()` | `Util.prg:1109` | ~15 llamadas |
| `DrywallActivarProyecto()` | `Util.prg:1150` | ~5 llamadas |
| `DbFieldPutIf()` | `Util.prg:658` | ~6 llamadas |
| `IsDbUsed()` | `Util.prg:632` | 1 llamada |
| `PopupSelect()` | `Util.prg:744` | ~6 llamadas |
| `MsgStop/Info/YesNo()` | `MsgBox.prg`/`MsgYesNo.prg` | Uso extensivo |
| `GfxMaxRow/MaxCol()` | `api/Gfx.prg` | ~15 llamadas |
| `TWindow/TGrid/TGet/TButton/TCheck/TLabel/TMenu` | API GfxStack | ~40 instancias |

---

## 8. Recomendaciones Priorizadas

### P1 — Inmediatas (rendimiento y estabilidad)

1. **Añadir índice a TMP_CAB**: Crear índice `TMP_NUM` sobre campo NUMERO. Esto optimiza todas las búsquedas de cabecera (mark dirty/calculated, mover a histórico, activar proyecto).

2. **Usar SR_TIPO en Calc_Rendimientos**: Cambiar el escaneo secuencial de SYS_REND por `OrdSetFocus("SR_TIPO") + dbSeek(cTipo + Str(nMod,5,2) + ...)`. El índice SR_TIPO está diseñado exactamente para este propósito (ver `InicioDrywall.prg:235`).

3. **Refactorizar apertura de SYS_REND**: Extraer el patrón "abrir SYS_REND si no está abierta + restaurar área" en una función auxiliar `_AbrirSysRend()` para eliminar la duplicación en 6 archivos.

4. **Liberar bloqueos en _BorraTemporalProyecto**: Si falla el bloqueo de una tabla, desbloquear las tablas previas antes de retornar.

5. **Corregir AddMat()**: Asegurar que `nOrdArt` se restaure siempre (usando BEGIN SEQUENCE o reordenando retornos tempranos).

### P2 — Corto plazo

6. **Reemplazar escaneos secuenciales por seek con índices existentes**:
   - `_ValGuardarEn()`: Usar `OrdSetFocus("RES_PK") + dbSeek(cProyecto + cCodigo)`.
   - `_MoverCabecera()`: Usar índice nuevo de TMP_CAB.
   - `_PreSiguienteDry()`: Usar `OrdSetFocus("PRE_NUM")` + dbSeek + dbSkip para navegar solo registros del año actual.

7. **Reducir ventana de bloqueo**: En `_MoverTramos()` y `_LimpiaBD()`, bloquear/desbloquear por lote o registro en lugar de mantener NetFLock durante toda la operación.

8. **Refactorizar DrywallMarkXxx**: Unificar `DrywallMarkCalcDirty`, `DrywallMarkCabDirty`, `DrywallMarkCalculated` en una función `_MarkEstado(cProyecto, cEstado, lCalcDirty, lCabDirty, lSucio)`.

### P3 — Medio plazo

9. **Extraer lógica de techo a funciones reutilizables**: `_TechoSistemaData`, `_TechoAplicarSistema`, `_TechoSistemaPorMaterial` están en CALC_ADD.prg pero podrían moverse a un módulo compartido (ej. `SYS_REND_API.prg`).

10. **Validar existencia de tags de índice antes de OrdSetFocus**: Envolver todas las llamadas a OrdSetFocus con verificación de existencia (`IndexKey(0)` para listar tags, o `IndexOrd( cTag )` para verificar existencia).

11. **Agregar dbCommit() en FamiliaGuardar()** para consistencia con ArticuloGuardar.

12. **Revisar uso de FLock vs NetFLock en SeedDrywall**: Cambiar a NetFLock para consistencia.

### P4 — Largo plazo

13. **Migrar a consultas DBFCDX con filtros**: En lugar de `dbGoTop()` + WHILE con `IF !Deleted()`, usar `OrdScope` (orden por rango) cuando sea posible.

14. **Agregar transacciones reales en operaciones críticas**: `_MoverTramos/Resumen/Materiales` podrían agruparse en una transacción. Actualmente solo _PreGuardarDrywall usa BEGIN/END TRANSACTION.

15. **Sistema de logs centralizado**: En lugar de `AAdd(::aLog, ...)` en OOPTRAMO, usar un logger compartido.

16. **Pruebas unitarias automatizadas**: El test de saturación es un buen comienzo. Extender con tests para Validación, Presupuesto, y Recuperación de histórico.

---

*Auditoría generada el 07/06/2026 basada en el código real del directorio `drywall/`.*
