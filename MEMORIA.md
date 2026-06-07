# Memoria del proyecto GfxStack

## Estado actual
- Proyecto: **AppGestión** — sistema de gestión empresarial para construcción y drywall (Pladur) en España
- Lenguaje: **Harbour** (xBase/Clipper) con GTWVG (interfaz gráfica en consola)
- Base de datos: DBF/CDX (DBFCDX RDD)
- Build: `hbmk2` via `test.hbp` → genera `AppGestion.exe`
- API gráfica propia: **GfxStack** (`api/`) — framework reutilizable de ventanas, controles y menús para Harbour+GTWVG (licencia MPL-2.0)
- Módulo seco: **Drywall** (`drywall/`) — calculadora técnica de materiales de construcción en seco, integrada en AppGestión
- Tests: 128 tests unitarios verdes en consola pura (`tests/`), sin DBF ni GTWVG
- HEAD en `master`

## Módulos principales
1. **Maestros** — CLIENTES, PROVEED, ARTICULOS, VENDEDORES, FORMAS_PAGO, TIPOS_IVA, PARTIDAS
2. **Ventas** — PRESUPUEST/DE → OBRAS → FACTURA/DET → CERTIFICACIONES
3. **Tesorería** — BANCOS, RC_DETAL, COBROS, PAGOS, CAJA
4. **Contabilidad** — CATALOGO, LDIARIO, LMAYOR, COSTES_CC (Plan General Contable, asientos, IVA, balances)
5. **Seguridad** — USUARIOS, ROLES, PERMISOS, AUDITLOG (SHA-256 con salt, bloqueo por 5 intentos)
6. **Drywall** — TMP_CAB/TRA/MAT/RES, HIS_CAB/TRA/MAT/RES, SYS_REND, ARTICULOS (cálculo de materiales por tramo con OOPTRAMO)
7. **Informes** — listados de clientes, facturas, presupuestos, situación de obra, vencimientos, IVA, balances

## Progreso acumulado
- **P1**: Reorganización interna de CALC_ADD.prg y TARE_MOD.prg en secciones (FORMS/DBF/VALIDACION/UI HELPERS). `DrywallProyectoActualNumero()` y `DrywallActivarProyecto()` movidas a Util.prg.
- **P2**: `::GetRendimientoRol(cRol, nDefault)` híbrido — busca en SYS_REND por SISTEMA_ID+TIPO_OBRA+ROL_MAT, fallback a #define. Migrados todos los #define de rendimiento (CINTA, DESP_PLA, DESP_PER, TORN_M2, TORN_MM, PASTA_M2, GUARDA_M2).
- **P3**: Form_Trasdosado con títulos específicos por sistema (DIRECTO/SEMI DIRECT/AUTOPORTANTE). Checkbox aislante + TGet condicionales. `lPidePerfil := .F.` para Directo.
- **P4**: DesgloseAnclaje con parámetro `nMod`, fórmula corregida a `nArea / (nSepPrim * nMod)`.
- **P5**: `dbSetOrder` → `OrdSetFocus` en OOPTRAMO, CALC_MOD, VALID_MOD, EDIT_MOD.
- **P6**: `BEGIN SEQUENCE...RECOVER` en GrabaPres() y DrywallGuardarCalculado() (Harbour DBFCDX no soporta TRANSACTION).
- **P7**: 22 patrones `IF Select+USE` reemplazados por `ABRIR_TABLA()` en 9 archivos.
- **P8**: ~15 ValType guards en FIELD->* (PLAC_CARA, L_AISLANT, L_BANDA, CARAS) en OOPTRAMO, CALC_EDIT, VALID_MOD.
- **P9**: `_DvShow` sin truncar — eliminado `#define DV_MAX_MSG 8`, se muestran todos los errores.
- **P10**: MARGEN en presupuesto — GenPresupuesto.prg lee TMP_CAB->MARGEN y aplica `nSubtotal *= (1 + nMargen / 100)` antes de IVA.
- **CalcUtils.prg**: 6 funciones públicas puras (_RoundUp, _OptionalCode, _CantidadCompra, _SysAncho, _GetAuxTitle, _InformeTextoLineas). Núcleo testeable sin DBF.
- **TGet Insert mode**: DATA lInsert, K_INS toggle, cursor SC_INSERT/SC_NORMAL.
- **TWindow Status bar**: DATA lStatusBar/cStatusMsg, METHOD SetStatus(cMsg).
- **drywall_main.prg simplificado**: de ~155 a 111 líneas. Sin handlers CLI (seed/migrate).
- **Eliminados .md obsoletos**: AUDITORIA_DRYWALL.md, AUDITORIA_API.md, INFORME_FLUJO_CONTABLE.md, BugReport_GfxStack.md, AUDITORIA_FLUJO.md.
- **Integración Drywall en AppGestion**: menú DRYWALL en MenuInit.prg con 8 opciones.
  `VALID_MOD.prg` y `M_Sistemas.prg` añadidos a build. `Main.prg` llama `InicioDrywall()` y `GfxThemeLoad()`.
  EXTERNALs corregidos (SistemasView, AltaFact). 128 tests verdes.
- **Ejecución durante desarrollo**: AppGestion es el destino principal y ya integra Drywall.
  El ejecutable standalone de Drywall se mantiene como banco de pruebas para compilar,
  sembrar datos temporales y validar cálculos con mayor rapidez.
- **Tema Visual migrado** de `drywall_main.prg` a `MenuInit.prg` (`_AppTemaVisual()` estática).
  Carga automática al arranque vía `GfxThemeLoad()` en `Main.prg`.
- **SeedDrywall eliminado** permanentemente (ya no se usará).
- **Numeración CONTADOR**: `_PreSiguiente()` reemplazada por `GetNextNum("PRE", "Presupuestos")`
  en `V_Presupuesto.prg` — O(1), lock atómico, sin duplicados ni huecos.
- **Seed CONTADOR en InicioDBF.prg**: `_SiembraContador()` crea registros iniciales para
  PRE, PAG, REC, NA, ASI, CER, OBR y PRY. La siembra es idempotente: completa los
  registros ausentes sin depender de que la tabla esté vacía.
- **Series anuales corregidas en CONTADOR**:
  - `COD_DOC` y `PREFIJO` ampliados de 3 a 10 caracteres.
  - `GetNextNum()` conserva claves como FAC2026, ASI2026, REC2026 y NA2026.
  - Las series anuales se generan con longitud compatible con los campos de documento.
  - Certificaciones recuperan el formato CER + año + cuatro dígitos.
  - `DATA/CONTADOR` reconstruida conservando sus 3 registros existentes.
- **BEGIN SEQUENCE en Tesorería**: `_PagoGuardar()` y `_RecGuardar()` envueltos en
  `BEGIN SEQUENCE...RECOVER`; solo devuelven éxito cuando cabecera, detalle, asiento y
  marcado terminan correctamente. Ante fallo limpian detalle, asiento, marcas y cabecera.
- **Refino de cálculo Drywall contra Excel**:
  - Placas y perfiles se consolidan y convierten a unidades de compra por tramo.
  - Pastas, cintas, tornillos y complementarios se acumulan en unidad técnica y se
    convierten al final del proyecto.
  - El aislamiento usa superficie física: rendimiento `1.000` por defecto, separado de
    la merma de placa `DESP_PLA`.
  - Corregida la búsqueda `SR_TIPO`: clave con `TIPO_OBRA` rellenado, búsqueda suave y
    comparación sin espacios finales. Antes los techos con sistema podían no encontrar
    su receta y quedar sin materiales.
  - `SYS_REND` reconstruida con `SEP_PRIM`; se conservaron 31 registros y se ajustaron
    dos líneas `AISLANTE` a `1.000`.
  - Saturación validada con 320 tramos, 2.080 líneas de material y cero errores.

## Pendientes
- **Refinar cálculo Drywall contra Control appGestion.xlsm**:
  - Revisar que tamaños de placa y composición del sistema seleccionado coincidan con
    los usados en la hoja antes de comparar resultados.
  - Recalcular el proyecto comparativo desde la interfaz y contrastar el resumen final
    con la hoja usando exactamente los mismos artículos y sistemas.
- Unificar `_TareNextLinea()` / `_NextTramoLinea()` para evitar lógica duplicada.
- Corregir críticos de auditoría: CTA_CONT faltante en CLIENTES

## Decisiones tomadas
- Numeración de documentos mediante GetNextNum() (CONTADOR) al momento de guardar,
  no al abrir formulario. Patrón a extender a todos los formularios de captura.
- Los cambios y hallazgos de auditoría se priorizan: críticos primero, después altos.
- Enfoque especializado en construcción/drywall (no ERP genérico, no TPV, no ecommerce)
- Interfaz clásica por teclado, rápida y estable, en consola 132x40
- DBF como base de datos (sin SQL) por simplicidad y velocidad
- API gráfica separada del negocio (licencia MPL-2.0)
- Drywall integrado en AppGestión (no ejecutable separado)
- Tests en consola pura (`-std` + `hbct.hbc`), sin DBF ni GTWVG
- `::GetRendimientoRol()` híbrido: SYS_REND + #define fallback
- Harbour DBFCDX no soporta `BEGIN TRANSACTION` → `BEGIN SEQUENCE...RECOVER`
- AppGestion es la aplicación principal; Drywall standalone continúa disponible para
  desarrollo y pruebas.
- Convenciones de código: `LOCAL` al inicio, sangría de 4 espacios, arrays `[x, y]` y
  evitar instrucciones anidadas con `;`. Se permiten nombres de más de 10 caracteres
  cuando mejoran claramente la legibilidad.
- Actualizar este archivo al completar etapas relevantes, decisiones de arquitectura o
  cambios importantes de flujo; no es necesario hacerlo por cada corrección menor.

## Notas
- `CalcUtils.prg` (138 líneas) compila en drywall y tests. Sin dependencias DBF/GUI.
- SYS_REND busca con `OrdSetFocus("SR_SIS")` + `dbSeek(cSis)`, itera por SISTEMA_ID hasta coincidir TIPO_OBRA + ROL_MAT.
- Git: solo `master` (origin). No hay rama `mouse`/`implementacion-mouse`.
- `ReglasNegocio.prg` centraliza validaciones críticas (cobros, facturación, cierre de obras).
- Git ignora DATA/, *.exe, logs/.
