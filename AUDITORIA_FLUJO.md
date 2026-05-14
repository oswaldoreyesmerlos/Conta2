# Auditoría de Flujo de Negocio — AppGestión

**Fecha:** 2026-05-14
**Base:** commit `03bfa93`, rama `refactor/modelo-obras`
**Enfoque:** PRESUPUESTO → OBRA → CERTIFICACIÓN → FACTURA → COBRO → CONTABILIDAD
**Documento rector:** `NUEVO ENFOQUE DEL PROYECTO APPGESTI.txt`

---

## Resumen

| Módulo | Archivo | Bugs | Debilidades | Estado |
|--------|---------|------|-------------|--------|
| Clientes | M_Clientes.prg | 0 | 1 | Fix C001 aplicado |
| Proveedores | M_Proveedo.prg | 0 | 1 | Fix C001 aplicado |
| Vendedores | M_Vendedor.prg | 0 | 1 | Fix C001 aplicado |
| Empresa | M_Empresa.prg | 0 | 1 | Sin revisión detallada |
| Presupuestos | V_Presupuesto.prg | 1 | 2 | Pendiente revisión flujo completo |
| Obras | M_Obras.prg | 0 | 2 | Pendiente revisión certificaciones |
| Certificaciones | *(no existe como módulo)* | — | — | **Carencia crítica** |
| Facturas | V_Facturas.prg | 1 | 2 | Pendiente revisión vencimientos |
| Tesorería | Tesoreria.prg | 0 | 2 | Sin revisión detallada |
| Contabilidad | M_Conta.prg | 0 | 2 | Pendiente revisión asientos automáticos |
| Informes | Informes.prg | 0 | 1 | Sin revisión detallada |
| Reglas de negocio | ReglasNegocio.prg | 1 | 0 | IVA/IRPF |
| Menú | MenuInit.prg | 0 | 1 | Sin acceso a certificaciones |

**Puntuación estimada: 6.0/10** (lastra la carencia de certificaciones)

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

#### D02 — No hay direcciones de obra separadas
El nuevo enfoque pide direcciones de obra adicionales en clientes
(punto 1 del documento rector). Actualmente solo hay una dirección
general. Las reformas suceden en ubicaciones distintas del cliente.

---

## 3. PRESUPUESTOS (V_Presupuesto.prg)

### Bugs

#### B001 — PresupuestoGuardar no usa transacción
Si falla la inserción de líneas de detalle después de insertar la
cabecera, quedan presupuestos huérfanos.
*Severidad:* SERIO.
*Fix:* iniciar `BEGIN TRANSACTION` antes de guardar cabecera y detalle,
`END TRANSACTION` al final. (Los cambios sin commitear ya añadieron
rollback manual.)

### Debilidades

#### D03 — No reutiliza partidas técnicas como plantillas
El nuevo enfoque (punto 4: Plantillas de obra) pide reutilizar
estructuras completas de presupuestos. Actualmente no hay un catálogo
de partidas técnicas reutilizables.

#### D04 — No hay condiciones generales ni firma
El nuevo enfoque (punto 2) pide condiciones generales y firma/aceptación
del presupuesto. No implementado.

---

## 4. OBRAS (M_Obras.prg)

### Estado
Tiene cambios sin commitear que corrigen la generación de número de
obra con año (`OBR2026####`). No se ha revisado el flujo completo.

### Debilidades

#### D05 — Una obra debería vincularse a presupuesto origen
Actualmente no hay certeza de que la obra se cree desde un presupuesto.
El nuevo enfoque exige que el flujo sea PRESUPUESTO → OBRA.

#### D06 — La ficha de obra debería mostrar estado económico
El nuevo enfoque (punto 5) pide: importe presupuestado, facturado,
cobrado y pendiente en la ficha de obra central.

---

## 5. CERTIFICACIONES — Carencia crítica

**No existe como módulo.** No hay archivo ni función que implemente
certificaciones parciales por avance de obra.

Esto bloquea el flujo completo:
```
PRESUPUESTO → OBRA → [CERTIFICACIÓN] → FACTURA → COBRO
                      ↑↑↑
                 NO EXISTE
```

### Lo que debería implementar (según nuevo enfoque punto 6):
- Generar certificaciones parciales desde una obra
- Especificar porcentaje de avance
- Facturar desde certificación
- Histórico de certificaciones por obra
- Reflejo contable

---

## 6. FACTURAS (V_Facturas.prg)

### Bugs

#### B002 — _FacGenVencim ahora retorna lógico pero no se usa
Los cambios sin commitear modifican `_FacGenVencim` para retornar
lógico, pero ningún llamador verifica el retorno.
*Severidad:* BAJO. Consistencia interna.

### Debilidades

#### D07 — Las facturas no se vinculan a certificaciones
Al no existir certificaciones, las facturas se emiten sin relación
con el avance de obra. No hay trazabilidad OBRA → FACTURA.

#### D08 — No hay opción de inversión del sujeto pasivo en facturas
El nuevo enfoque (punto 2) menciona IVA normal o inversión del sujeto
pasivo. Verificar si está soportado.

---

## 7. TESORERÍA (Tesoreria.prg)

### Estado
No revisado en detalle. Módulo clave según nuevo enfoque (punto 8).

### Debilidades

#### D09 — Pendiente de revisión: control de vencimientos
Verificar si el módulo permite:
- Saber qué facturas están pendientes de cobro
- Saber qué obra debe dinero
- Generar recibos

#### D10 — Pendiente de revisión: relación con contabilidad
Verificar si los cobros se reflejan automáticamente en contabilidad
o requieren asiento manual.

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

#### D12 — No se ha verificado la integridad del plan de cuentas
Habría que confirmar que el catálogo de cuentas cubre las necesidades
de reformas (obra en curso, certificaciones, etc.).

---

## 9. INFORMES (Informes.prg)

### Debilidades

#### D13 — Pendiente de revisión
Verificar si los informes actuales cubren:
- Libro diario (debe haberlo)
- Libro mayor
- Balance de sumas y saldos
- Pérdidas y ganancias
- Informe de obra (presupuestado vs facturado vs cobrado)

---

## 10. REGLAS DE NEGOCIO (ReglasNegocio.prg)

### Bugs

#### B003 — IVA/IRPF: Pendiente de revisión
Según el nuevo enfoque, el sistema debe soportar IVA normal e
inversión del sujeto pasivo. Verificar implementación actual.

---

## Resumen de bugs activos

| ID | Archivo | Severidad | Descripción |
|----|---------|-----------|-------------|
| B001 | V_Presupuesto.prg | SERIO | PresupuestoGuardar sin transacción (líneas huérfanas) |
| B002 | V_Facturas.prg | BAJO | _FacGenVencim retorna lógico sin usar |
| B003 | ReglasNegocio.prg | MEDIO | IVA inversión sujeto pasivo — verificar |

## Carencias críticas

| ID | Descripción |
|----|-------------|
| C01 | **No existe módulo de certificaciones** — Bloquea el flujo PRESUPUESTO → OBRA → CERTIFICACIÓN → FACTURA |

## Debilidades (D01-D13)

Ver secciones correspondientes arriba.
