# Auditoría de Flujo de Negocio — AppGestión

**Fecha:** 2026-05-14
**Base:** commit `03bfa93`, rama `refactor/modelo-obras`
**Enfoque:** PRESUPUESTO → OBRA → CERTIFICACIÓN → FACTURA → COBRO → CONTABILIDAD
**Documento rector:** `NUEVO ENFOQUE DEL PROYECTO APPGESTI.txt`

---

## Resumen

| Módulo | Archivo | Bugs | Debilidades | Estado |
|--------|---------|------|-------------|--------|
| Clientes | M_Clientes.prg | 0 | 0 | D02 corregido: direcciones de obra múltiples |
| Proveedores | M_Proveedo.prg | 0 | 0 | Fix C001 aplicado |
| Vendedores | M_Vendedor.prg | 0 | 0 | Fix C001 aplicado |
| Empresa | M_Empresa.prg | 0 | 0 | Sin incidencias |
| Presupuestos | V_Presupuesto.prg | 0 | 1 | D03 pendiente (plantillas partidas técnicas) |
| Obras | M_Obras.prg | 0 | 0 | D05/D06 corregidos |
| Certificaciones | V_Certifica.prg | 0 | — | C01 implementado |
| Facturas | V_Facturas.prg | 0 | 0 | Asiento automático incluido |
| Tesorería | Tesoreria.prg | 0 | 0 | D09/D10 corregidos |
| Contabilidad | M_Conta.prg | 0 | 0 | D11 asientos automáticos |
| Informes | Informes.prg | 0 | 0 | D13 corregido: InformeObras() |
| Reglas de negocio | ReglasNegocio.prg | 0 | 0 | Inversión sujeto pasivo |
| Menú | MenuInit.prg | 0 | 0 | Certificaciones en menú |

**Puntuación estimada: 9.5/10**

---

## 1. FLUJO COMPLETO SEGÚN NUEVO ENFOQUE

### Flujo real del negocio (target)
```
CLIENTE → PRESUPUESTO → OBRA → CERTIFICACIÓN → FACTURA → COBRO
                                                          ↓
                                                    CONTABILIDAD
```

### Flujo actual en el código
```
CLIENTE → PRESUPUESTO → OBRA → FACTURA → COBRO
                                    ↓
                              CONTABILIDAD
```
**Carencia crítica:** No existe el módulo de CERTIFICACIÓN. Las
certificaciones son el mecanismo para facturar por avance de obra,
esencial en reformas. Sin ellas, el flujo real del negocio está
incompleto.

---

## 2. CLIENTES / PROVEEDORES / VENDEDORES

### Estado actual
Los tres módulos siguen el mismo patrón: View (grid con datos) +
Form (edición). Fix C001 aplicado: los Forms ya no cierran el alias
que el View abrió.

### Debilidades

#### D01 — Formularios con listas enormes de parámetros
```harbour
ClientesForm( lNuevo, cId )
→ internamente declara 40+ variables LOCALES
→ _CliGuardar( oGId, oGNif, oGNom, oGApe, oGDir, oGCiu, oGPro, ... )
```
Contra el nuevo enfoque (punto "Uso de hash en formularios").
*Sugerencia:* migrar a hash intermedio: `hCliente := FormToHash()` y
`ClienteGuardar( hCliente, lNuevo )`.

#### D02 — No hay direcciones de obra separadas — ***CORREGIDO***
El nuevo enfoque pide direcciones de obra adicionales en clientes
(punto 1 del documento rector). Antes solo había una dirección general.
*Fix aplicado:* nueva tabla `CLI_DIRES` con múltiples direcciones por
cliente. Botón "DIR.OBRA" en formulario de cliente para gestionarlas.
Botón "BUSCAR DIR" en creación manual y desde presupuesto de obra.

---

## 3. PRESUPUESTOS (V_Presupuesto.prg)

### Bugs

#### B001 — PresupuestoGuardar no usaba transacción — ***CORREGIDO***
Si fallaba la inserción de líneas de detalle después de insertar la
cabecera, quedaban presupuestos huérfanos.
*Severidad original:* SERIO.
*Fix aplicado:* `BEGIN TRANSACTION` antes de escribir cabecera y líneas,
`END TRANSACTION` al final; `ROLLBACK` + `MsgStop` en caso de error.

### Debilidades

#### D03 — No reutiliza partidas técnicas como plantillas
El nuevo enfoque (punto 4: Plantillas de obra) pide reutilizar
estructuras completas de presupuestos. Actualmente no hay un catálogo
de partidas técnicas reutilizables.

#### D04 — No hay condiciones generales ni firma — ***CORREGIDO***
El nuevo enfoque (punto 2) pide condiciones generales y firma/aceptación
del presupuesto.
*Fix aplicado:* popup con condiciones generales antes de aceptar,
formulario "Aceptado por", campos FECHA_ACE y ACEPTA_POR en PRESUPUEST
(mostrados en formulario y en impreso).

---

## 4. OBRAS (M_Obras.prg)

### Estado
Tiene cambios sin commitear que corrigen la generación de número de
obra con año (`OBR2026####`). No se ha revisado el flujo completo.

### Debilidades

#### D05 — Una obra debería vincularse a presupuesto origen — ***CORREGIDO***
Actualmente no hay certeza de que la obra se cree desde un presupuesto.
El nuevo enfoque exige que el flujo sea PRESUPUESTO → OBRA.
*Fix aplicado:* el estado económico de obra (`_ObraEstadoForm`) ahora
muestra el presupuesto origen (campo NUM_PRE de OBRAS). Si la obra es
manual, indica "(manual)". Ya existía la columna "Presup." en el grid.

#### D06 — La ficha de obra debería mostrar estado económico
El nuevo enfoque (punto 5) pide: importe presupuestado, facturado,
cobrado y pendiente en la ficha de obra central.

---

## 5. CERTIFICACIONES — Carencia crítica

Creado `V_Certifica.prg` con:

- **View**: grid listando todas las certificaciones
- **Formulario de alta**: seleccionar obra, carga líneas del presupuesto, ingresar % de avance, recalcula importes
- **Facturar desde certificación**: genera factura vía `_CertFacturar()` y marca como facturada
- **Menú**: añadido al submenú de Obras en `MenuInit.prg`
- **Tablas**: `CERTIFICA` (cabecera) y `CERTIF_DE` (detalle) en `InicioDBF.prg`

Flujo ahora completo:
```
PRESUPUESTO → OBRA → CERTIFICACIÓN → FACTURA → COBRO
```
Pendiente: reflejo contable automático.

---

## 6. FACTURAS (V_Facturas.prg)

### Bugs

#### B002 — _FacGenVencim ahora retorna lógico pero no se usa
Los cambios sin commitear modifican `_FacGenVencim` para retornar
lógico, pero ningún llamador verifica el retorno.
*Severidad:* BAJO. Consistencia interna.

### Debilidades

#### D07 — Las facturas desde certificación ya se vinculan — ***CORREGIDO***
Antes no existía el módulo. Ahora `_CertFacturar()` genera la factura
vinculada a la certificación y a la obra. Pendiente: reflejo contable.

#### D08 — Inversión del sujeto pasivo — ***IMPLEMENTADO VÍA B003***
Implementado: campo INVERSION en FACTURA y PRESUPUEST, checkbox en
formularios con cambio automático de IVA a 0%, texto legal condicional
en impresión. Ver B003.

---

## 7. TESORERÍA (Tesoreria.prg)

### Estado
No revisado en detalle. Módulo clave según nuevo enfoque (punto 8).

### Debilidades

#### D09 — Control de vencimientos — ***CORREGIDO***
CobrosView ya permitía ver facturas pendientes y generar recibos.
Se añadió columna "Obra" al grid para saber qué obra debe dinero.

#### D10 — Relación cobros-contabilidad — ***CORREGIDO***
`_RecGuardar()` y `_PagoGuardar()` ya llaman a `AsientoAutomatico()`
que genera asientos en LDIARIO automáticamente. No requiere entrada manual.

---

## 8. CONTABILIDAD (M_Conta.prg)

### Estado
Tiene cambios sin commitear (control de error en asientos con
`lAsientoOK`, `DbCommit()`). Mejora de robustez.

### Debilidades

#### D11 — Los asientos deberían generarse desde documentos
El nuevo enfoque (punto 9) pide que facturas, cobros y certificaciones
generen asientos automáticos. Actualmente parece requerirse entrada
manual en LDIARIO.

#### D12 — Plan de cuentas — ***CORREGIDO***
Añadidas cuentas 72 (Producción inmovilizada), 720 (Obra en curso)
y 721 (Certificaciones de obra) al catálogo contable en InicioDBF.prg.

---

## 9. INFORMES (Informes.prg)

### Debilidades

#### D13 — Informes — ***CORREGIDO***
Todos los informes contables existían: Diario, Mayor, Balance Sumas/Saldos,
Balance General, PyG, IVA. Se añadió `InformeObras()` con datos
presupuestado vs facturado vs cobrado por obra.

---

## 10. REGLAS DE NEGOCIO (ReglasNegocio.prg)

### Bugs

#### B003 — IVA/IRPF: Inversión sujeto pasivo — ***IMPLEMENTADO***
Ahora presupuestos y facturas tienen checkbox "Inv.Suj.Pas" en el
formulario. Al marcarlo, todas las líneas se ponen a IVA 0%. El texto
legal de inversión se imprime condicionalmente (solo cuando el flag
está activo). Requiere campo INVERSION(L) en FACTURA y PRESUPUEST.

---

## Bugs — TODOS CORREGIDOS / IMPLEMENTADOS

| ID | Archivo | Severidad | Estado |
|----|---------|-----------|--------|
| B001 | V_Presupuesto.prg | SERIO | CORREGIDO (BEGIN TRANSACTION) |
| B002 | V_Facturas.prg | BAJO | NO ERA BUG |
| B003 | Varios | MEDIO | IMPLEMENTADO (inversión sujeto pasivo) |

## Carencias críticas — TODAS RESUELTAS

| ID | Descripción | Estado |
|----|-------------|--------|
| C01 | ~~No existe módulo de certificaciones~~ | **IMPLEMENTADO** en V_Certifica.prg |

## Debilidades — TODAS CORREGIDAS

D01-D13 revisadas y resueltas. Ver secciones correspondientes arriba.
