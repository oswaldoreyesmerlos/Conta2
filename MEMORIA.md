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
- **Tema Visual migrado** de `drywall_main.prg` a `MenuInit.prg` (`_AppTemaVisual()` estática).
  Carga automática al arranque vía `GfxThemeLoad()` en `Main.prg`.
- **SeedDrywall eliminado** permanentemente (ya no se usará).
- **Numeración CONTADOR**: `_PreSiguiente()` reemplazada por `GetNextNum("PRE", "Presupuestos")`
  en `V_Presupuesto.prg` — O(1), lock atómico, sin duplicados ni huecos.
- **Auditoría completa AppGestion**: 46 hallazgos (18 críticos, 16 altos, 5 medios, 7 bajos)
  documentados por módulo. Pendiente corregir progresivamente.

## Pendientes
- **Extender patrón CONTADOR** a FACTURA, COMPRAS, RECIBOS, PAGOS, CERTIFICACIONES y demás documentos
- Corregir críticos de auditoría: CierreEjercicio stub, CTA_CONT faltante en CLIENTES,
  alias duplicado DIA_C, fugas PRE_C/FAC, nArea en informes, NetFLock→NetRLock
- Añadir seed de CONTADOR para todos los tipos de documento en InicioDBF

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

## Notas
- `CalcUtils.prg` (138 líneas) compila en drywall y tests. Sin dependencias DBF/GUI.
- SYS_REND busca con `OrdSetFocus("SR_SIS")` + `dbSeek(cSis)`, itera por SISTEMA_ID hasta coincidir TIPO_OBRA + ROL_MAT.
- Git: solo `master` (origin). No hay rama `mouse`/`implementacion-mouse`.
- `ReglasNegocio.prg` centraliza validaciones críticas (cobros, facturación, cierre de obras).
- Git ignora DATA/, *.exe, logs/.
