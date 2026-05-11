# Auditoría de Flujo de Usuario — GfxStack

**Rama auditada:** `refactor/modelo-obras` (commit `277a31d`)
**Fecha:** 11/05/2026
**Tipo:** Simulación de flujo completo de usuario final
**Base de código:** 19 PRG principales + 8 API auxiliares + 3 aislados (~12.000 líneas)

---

## Resumen

| Métrica | Valor |
|---|---|
| Bugs funcionales identificados | 16 |
| Debilidades de flujo/usabilidad | 22 |
| Problemas de código/arquitectura | 10 |
| **Calificación estimada** | **6.8/10** (consistente con AUDITORIA.txt) |

---

## Simulación de Flujo de Usuario Final

### 1. Login (`MenuInit.prg` → `Seguridad.prg`)

**Flujo simulado:**
1. Ejecuta `Main.prg` → llama a `MenuInit.prg` → `InicioDBF.prg`
2. `InicioDBF.prg` abre `_gfx.dbf` y verifica que existan los archivos DBF
3. Se invoca `MenuInit.prg:163` que llama a `LogIn()` en `Seguridad.prg:67`
4. `LogIn()` pide usuario y contraseña. Verifica en `Usuarios.dbf` con `SEEK`
5. Si OK → escribe `_gfx.dbf` con usuario actual (`cNomUsua`) y escribe `Audit.dbf`
6. Si no existe `Menu.dbf` → llena `_MenuTmp` con `_GenMenu()`

**Hallazgos:**
- `Seguridad.prg:215` — `AES_Descifrar()`: Si la contraseña está en texto plano (primer login o migración), el `SEEK` falla y no da mensaje claro al usuario ("Usuario o contraseña inválidos" sería incorrecto; debería distinguir "Usuario no existe" vs "Contraseña incorrecta")
- `InicioDBF.prg:112` — `llave` aleatoria de 4 dígitos tiene rango limitado (1000-9999), no hay verificación de integridad de `_gfx.dbf`
- **No hay límite de intentos de login** — permite fuerza bruta ilimitada
- **No hay protección contra inyección** por macros (&) en las consultas DBF

---

### 2. Menú Principal (`MenuInit.prg`)

**Flujo simulado:**
1. Tras login, se ejecuta el bucle principal de menú
2. `cCadMens` contiene tips emergentes que cambian según se navegan las opciones
3. `_SelMenu()` en `MenuInit.prg:199` asigna `nTarea` y luego se bifurca con un `DO CASE`

**Hallazgos:**
- `MenuInit.prg:152` — El menú es procedural, enorme y monolítico (~400 líneas)
- Los tips (`cCadMens`) están hardcodeados en arrays paralelos en lugar de leerse desde la DBF de menú
- **No hay tecla de acceso rápido** (Ctrl+Q, etc.) para acciones comunes — todo es navegación por cursor + Enter

---

### 3. Maestro de Obras (`M_Obras.prg`)

**Flujo simulado:**
1. Alta de obra nueva → `M_Obras.prg:140` (nTarea=1)
2. Se presenta formulario con campos: CODIGO (disabled), NOMBRE, DIRECCION, LOCALIDAD, CPROV, CLIENTE, etc.
3. Se guarda en `Obras.dbf`
4. Modificación → `M_Obras.prg:140` (nTarea=4), misma pantalla modo edición

**Hallazgos:**
- `M_Obras.prg:96` — `nFreeObra = _ObtenerNuevoCodigo("Obras")` podría devolver un código ya existente si no hay transaccionalidad real (DBF no tiene transacciones)
- `M_Obras.prg:204` — La validación de `CLIENTE` existente solo verifica contra `Clientes.dbf` al guardar, no mientras se escribe
- **No controla duplicados por nombre** — se pueden dar de alta dos obras con el mismo nombre
- `M_Obras.prg:311` — El borrado lógico (`DELETED`) nunca se compacta (`PACK`), los registros marcados como eliminados se acumulan indefinidamente

---

### 4. Maestro de Clientes (`M_Clientes.prg`)

**Flujo simulado:**
1. ABM de clientes con campos: CIF/NIF, RAZON, DIRECCION, etc.
2. Búsqueda por código o por nombre parcial

**Hallazgos:**
- `M_Clientes.prg:88` — `SEEK` sobre CIF/NIF sin índice activo puede devolver resultados incorrectos (depende de qué índice esté activo, no se fuerza orden)
- **No validación de CIF/NIF** según algoritmo oficial español
- **No control de duplicados de CIF/NIF**
- **No historial de modificaciones** (quién cambió qué y cuándo) — el `Audit.dbf` solo registra acceso, no cambios en maestros

---

### 5. Maestro de Presupuestos (`V_Presupuesto.prg`)

**Flujo simulado:**
1. Emisión de presupuesto: cabecera + líneas de detalle
2. `nTarea=1` (nuevo) → captura CLIENTE, OBRA, condiciones de pago, etc.
3. En líneas se añaden artículos con cantidad, precio, descuento, IVA
4. Cálculo de totales

**Hallazgos:**
- `V_Presupuesto.prg:415` — `CalcularTotales()` redondea cada línea individualmente, luego suma. Puede diferir de `TotalBase*(1+IVA)` a nivel de total general (diferencia de céntimos)
- `V_Presupuesto.prg:301` — El precio del artículo se obtiene de `Articulos.dbf` al momento de añadir la línea, pero **no guarda histórico** — si después se cambia el precio en el maestro, el presupuesto mostrará el precio nuevo (inconsistencia)
- `V_Presupuesto.prg:78` — No hay control de presupuestos duplicados (mismo cliente+obra+fecha)
- **No hay conversión a pedido** — un presupuesto aceptado debe re-escribirse manualmente en otra pantalla
- **No hay numeración automática por serie/año** — el código es autoincremental global

---

### 6. Facturación (`V_Facturas.prg`)

**Flujo simulado:**
1. Generación de factura desde presupuesto (o desde cero)
2. Líneas de detalle similares a presupuesto
3. Cálculo de IVA, retenciones, bases
4. Grabación en `Facturas.dbf` + `Factuline.dbf`

**Hallazgos:**
- `V_Facturas.prg:201` — La búsqueda de siguiente numeración `_ObtenerNuevoCodigo("Facturas")` no discrimina por serie fiscal — en España las facturas deben numerarse por serie y año
- `V_Facturas.prg:512` — Al facturar desde presupuesto, NO se marca el presupuesto como "facturado" en `Presupuestos.dbf`, permitiendo doble facturación del mismo presupuesto
- **No hay control de libro de IVA** — facturas emitidas no se reflejan automáticamente en registro fiscal
- **No hay factura rectificativa** — no se puede emitir factura negativa para anular una anterior
- `V_Facturas.prg:88` — Validación de cliente solo verifica que exista, no que tenga datos fiscales completos (CIF, dirección, etc.)

---

### 7. Tesorería (`Tesoreria.prg`)

**Flujo simulado:**
1. Gestión de cobros y pagos
2. Asociación a facturas
3. Estado de cuentas corrientes

**Hallazgos:**
- `Tesoreria.prg:177` — Al registrar un cobro, actualiza `Facturas.dbf` en `TOTAL_COB` pero **no verifica que el importe cobrado no exceda el total de la factura** (sobrecobro permitido)
- **No hay conciliación bancaria** — el saldo contable es un campo manual en `CtaCtte.dbf`, no se compara con extractos bancarios
- `Tesoreria.prg:245` — Los cobros pueden registrarse sin factura asociada (campo `CODFACT` vacío), lo que genera descuadres en libro de IVA
- **No hay control de morosidad** — plazos de pago vencidos no generan alertas

---

### 8. Contabilidad (`M_Conta.prg`)

**Flujo simulado:**
1. Gestión del plan contable
2. Asientos manuales
3. Balance y PYG

**Hallazgos:**
- `M_Conta.prg:389` — Los asientos contables se crean manualmente uno a uno, **no hay integración automática** con facturación ni tesorería
- `M_Conta.prg:104` — `nFreeAsiento = _UltimoAsiento()+1` no considera ejercicios cerrados — se puede crear un asiento con fecha de ejercicio anterior después del cierre
- **No hay libro diario ni libro mayor formateado para impresión fiscal**
- `M_Conta.prg:456` — El cierre contable solo marca `FECHA_CIE` en `Ejercicios.dbf` pero **no bloquea realmente** la creación de nuevos asientos en ese ejercicio

---

### 9. Informes (`Informes.prg`)

**Flujo simulado:**
1. Listados de clientes, proveedores, obras, etc.
2. Informes de facturación por período

**Hallazgos:**
- `Informes.prg:93` — Los informes se generan con `@ ... SAY` a impresora, **sin vista previa en pantalla** — el usuario no sabe lo que va a imprimir hasta que sale en papel
- **No hay exportación a PDF, Excel ni CSV**
- `Informes.prg:201` — Fechas en filtros no tienen validación de rango (`FECHA_DESDE > FECHA_HASTA` permite invertir el filtro)
- **No hay informes predefinidos** para IVA (303, 349), Balance de Sumas y Saldos ni Libro Mayor
- `Informes.prg:55` — Usa `SET PRINTER TO ...` para generar TXT, pero no hay control de errores si la ruta de salida no existe

---

### 10. Impresión (`V_Imprimir.prg`)

**Flujo simulado:**
1. Previsualización y envío a impresora de documentos (presupuestos, facturas, etc.)

**Hallazgos:**
- `V_Imprimir.prg:134` — La vista previa (`Preview()`) carga todo el documento en memoria como array de líneas de texto; documentos muy largos pueden saturar la memoria del menú
- **No hay templates de impresión personalizables** por tipo de documento — el formato está hardcodeado

---

## Bugs Funcionales (16)

| # | Archivo | Línea | Bug | Gravedad |
|---|---|---|---|---|
| 1 | `Seguridad.prg` | 215 | Contraseña en texto plano vs cifrada no se distingue → mensaje engañoso | Media |
| 2 | `M_Obras.prg` | 204 | No valida existencia de cliente en tiempo real | Baja |
| 3 | `M_Obras.prg` | 311 | Borrado lógico sin `PACK` → registros huérfanos acumulados | Media |
| 4 | `M_Clientes.prg` | 88 | `SEEK` sin índice explícito → resultado indeterminado | Alta |
| 5 | `M_Clientes.prg` | — | Sin validación de CIF/NIF según estándar español | Media |
| 6 | `V_Presupuesto.prg` | 415 | Error de redondeo acumulado en totales | Baja |
| 7 | `V_Presupuesto.prg` | 301 | Precio no histórico → cambia si se modifica el maestro | Alta |
| 8 | `V_Facturas.prg` | 201 | Numeración sin serie/año → no cumple requisitos fiscales | Alta |
| 9 | `V_Facturas.prg` | 512 | Presupuesto no se marca como facturado → doble facturación | **Crítica** |
| 10 | `V_Facturas.prg` | — | No existen facturas rectificativas | Alta |
| 11 | `Tesoreria.prg` | 177 | No controla sobrecobro (cobrar más del total factura) | Alta |
| 12 | `Tesoreria.prg` | 245 | Cobro sin factura asociada → descuadre IVA | Media |
| 13 | `M_Conta.prg` | 104 | Asientos pueden crearse en ejercicio cerrado | Media |
| 14 | `M_Conta.prg` | 456 | Cierre contable no bloquea realmente | Alta |
| 15 | `Informes.prg` | 201 | Fechas de filtro sin validación de rango | Baja |
| 16 | `V_Imprimir.prg` | — | Documentos extensos pueden saturar memoria | Media |

---

## Debilidades de Flujo y Usabilidad (22)

| # | Área | Debilidad |
|---|---|---|
| 1 | Login | Sin límite de intentos ni protección anti-fuerza bruta |
| 2 | Login | Sin bloqueo por inactividad (timeout de sesión) |
| 3 | Menú | Interfaz textual sin aceleradores de teclado |
| 4 | Menú | Tips hardcodeados, no configurables desde DBF |
| 5 | Obras | No hay control de duplicados por nombre |
| 6 | Obras | Campos de dirección sin validación de formato |
| 7 | Clientes | No hay historial de modificaciones |
| 8 | Presupuesto | Presupuesto aceptado no genera pedido automáticamente |
| 9 | Presupuesto | No hay numeración por serie fiscal |
| 10 | Presupuesto | No se puede duplicar presupuesto existente para agilizar |
| 11 | Facturas | No hay libro de IVA integrado |
| 12 | Facturas | No se validan datos fiscales completos del cliente |
| 13 | Facturas | No hay enlace a asiento contable automático |
| 14 | Tesorería | No hay conciliación bancaria |
| 15 | Tesorería | No hay alertas de morosidad/vencimientos |
| 16 | Tesorería | Remesas no contempladas |
| 17 | Contabilidad | Sin integración automática con facturación/tesorería |
| 18 | Contabilidad | No hay libro diario/mayor para impresión fiscal |
| 19 | Informes | Sin vista previa en pantalla — solo salida a papel |
| 20 | Informes | Sin exportación a PDF/Excel/CSV |
| 21 | Informes | Sin informes predefinidos de IVA (303, 349) |
| 22 | General | No hay backups automáticos ni planes de recuperación |

---

## Problemas de Código y Arquitectura (10)

| # | Archivo | Problema |
|---|---|---|
| 1 | General | Ausencia total de manejo de errores (`ERROR`, `ON ERROR`, `TRY...CATCH`) |
| 2 | General | No hay sistema de logging centralizado — mensajes a pantalla solamente |
| 3 | General | Sin capa de abstracción de datos — SQL y DBF mezclados con lógica de UI |
| 4 | General | Variables globales excesivas (`PUBLIC`) sin control de ámbito |
| 5 | General | Sin pruebas automatizadas ni framework de testing |
| 6 | General | Macros (`&`) para evaluación dinámica — riesgo de inyección |
| 7 | `MenuInit.prg` | Menú monolítico de ~400 líneas — difícil mantenimiento |
| 8 | TODOS | Mezcla de español/inglés en nombres de variables y comentarios |
| 9 | `Seguridad.prg` | Cifrado AES con clave estática (seguridad por oscuridad) |
| 10 | `InicioDBF.prg` | Inicialización sin validación de integridad de DBF |

---

## Recomendaciones Prioritarias

### Críticas (acción inmediata)
1. Marcar presupuesto como facturado al emitir factura (`V_Facturas.prg:512`)
2. Implementar factura rectificativa
3. Validar CIF/NIF con algoritmo oficial
4. Bloquear ejercicio contable cerrado (`M_Conta.prg:456`)
5. Numeración de facturas por serie y año

### Altas (próximo ciclo)
6. Precio histórico en líneas de presupuesto/factura
7. Control de sobrecobro en tesorería
8. No permitir cobros sin factura asociada
9. Vista previa en informes
10. Integración contabilidad-facturación

### Medias (corto plazo)
11. PACK de registros eliminados periódicamente
12. Límite de intentos de login
13. Exportación a PDF/CSV
14. Caché de precio de artículo al crear línea
15. Informes predefinidos de IVA

---

## Nota Final

Este documento refleja la simulación completa del flujo de usuario final sobre el código actual en la rama `refactor/modelo-obras`. No se ha modificado ningún archivo del proyecto ni del repositorio git. La calificación estimada de **6.8/10** es consistente con la auditoría previa (`AUDITORIA.txt`).

Para alcanzar un **9.0/10** (según `AUDITORIA2.txt`), se recomienda abordar primero los bugs críticos y altos, seguido de las debilidades de usabilidad y finalmente los problemas arquitectónicos.
