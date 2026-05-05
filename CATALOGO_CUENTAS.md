# SISTEMA DE CUENTAS CONTABLES
## Plan General Contable PGC 2007 — Guía de uso

---

## 1. ESTRUCTURA DEL CATALOGO

El catálogo sigue la estructura jerárquica del PGC español en 4 niveles:

```
GRUPO        1 dígito     Ej: 4
SUBGRUPO     2 dígitos    Ej: 43
CUENTA       3 dígitos    Ej: 430
SUBCUENTA    4-10 dígitos Ej: 4300001  (cliente específico)
```

El sistema siembra automáticamente **grupos y subgrupos** (niveles 1 y 2)
y las **cuentas principales** más usadas en pymes (nivel 3).
Las **subcuentas** (nivel 4) las crea el usuario o el propio sistema
al dar de alta clientes, proveedores y bancos.

---

## 2. GRUPOS DEL PGC SEMBRADOS

| Grupo | Nombre |
|---|---|
| 1 | Financiación básica |
| 2 | Activo no corriente |
| 3 | Existencias |
| 4 | Acreedores y deudores por operaciones comerciales |
| 5 | Cuentas financieras |
| 6 | Compras y gastos |
| 7 | Ventas e ingresos |

---

## 3. CUENTAS CLAVE PARA PYME/AUTONOMO

### Grupo 4 — El más usado en el día a día

| Cuenta | Nombre | Uso |
|---|---|---|
| 400 | Proveedores | Subcuentas por proveedor |
| 407 | Anticipos a proveedores | Pagos a cuenta |
| 410 | Acreedores por prestaciones de servicios | Gastos pendientes |
| 430 | Clientes | Subcuentas por cliente |
| 438 | Anticipos de clientes | Cobros a cuenta |
| 470 | Hacienda Pública deudora | IVA a recuperar |
| 472 | HP IVA soportado | IVA de compras |
| 473 | HP retenciones y pagos a cuenta | IRPF soportado |
| 475 | HP acreedora | IVA repercutido a pagar |
| 477 | HP IVA repercutido | IVA de ventas |

### Grupo 5 — Tesorería

| Cuenta | Nombre | Uso |
|---|---|---|
| 570 | Caja | Efectivo |
| 572 | Bancos c/c | Una subcuenta por banco |

### Grupo 6 — Gastos

| Cuenta | Nombre | Uso |
|---|---|---|
| 600 | Compras de mercaderías | Compras con stock |
| 621 | Arrendamientos y cánones | Alquiler local |
| 626 | Servicios bancarios | Comisiones banco |
| 628 | Suministros | Luz, agua, teléfono |
| 629 | Otros servicios | Gastos varios |
| 640 | Sueldos y salarios | Nóminas |
| 642 | Seguridad Social | Cuota autónomo/empresa |

### Grupo 7 — Ingresos

| Cuenta | Nombre | Uso |
|---|---|---|
| 700 | Ventas de mercaderías | Venta de productos |
| 705 | Prestaciones de servicios | Facturación servicios |
| 708 | Devoluciones de ventas | Notas de crédito |
| 759 | Ingresos por servicios diversos | Otros ingresos |

---

## 4. COMO AÑADIR UNA SUBCUENTA

### 4.1 Subcuenta de cliente (automática)
Cuando se da de alta un cliente, el sistema puede generar
automáticamente su subcuenta contable en el campo CTA_CONT:

```
Cliente código: CLI00001
Subcuenta generada: 4300001
                    ^^^----  cuenta padre 430
                       ^^^^  código interno del cliente (4 dígitos)
```

Si prefieres asignarla manualmente, déjala en blanco al crear
el cliente y escríbela directamente en el campo CTA_CONT
de la ficha del cliente.

### 4.2 Subcuenta de proveedor (automática)
Igual que clientes pero usando la cuenta 400:

```
Proveedor código: PRV00001
Subcuenta generada: 4000001
                    ^^^----  cuenta padre 400
                       ^^^^  código interno del proveedor
```

### 4.3 Subcuenta de banco (manual)
En la ficha de banco, campo CTA_CONT, escribir la subcuenta
de la cuenta 572:

```
Banco: BBVA cuenta corriente
CTA_CONT: 5720001
```

### 4.4 Subcuenta manual desde el modulo de Contabilidad
En CONTABILIDAD → Plan Cuentas → NUEVO:

| Campo | Valor de ejemplo |
|---|---|
| Cuenta | 6210001 |
| Nombre | Alquiler local nave industrial |
| Nivel | 4 (subcuenta) |
| Tipo | A (activo) / P (pasivo) / G (gasto) / I (ingreso) |
| Naturaleza | D (deudora) / A (acreedora) |
| Suma en | 621 (cuenta padre) |

---

## 5. NATURALEZA DE LAS CUENTAS

| Naturaleza | Aumenta por | Disminuye por | Ejemplos |
|---|---|---|---|
| D (Deudora) | DEBE | HABER | Clientes, Bancos, Gastos |
| A (Acreedora) | HABER | DEBE | Proveedores, IVA repercutido, Ingresos |

---

## 6. ASIENTOS AUTOMATICOS QUE GENERA EL SISTEMA

### Factura emitida (venta)
```
DEBE    430.CLIENTE   Total factura
HABER   477           IVA repercutido
HABER   700/705       Base imponible
```

### Factura recibida (compra)
```
DEBE    600/62x       Base imponible
DEBE    472           IVA soportado
HABER   400.PROVEEDOR Total factura
```

### Cobro de cliente
```
DEBE    572.BANCO     Importe cobrado
HABER   430.CLIENTE   Importe cobrado
```

### Pago a proveedor
```
DEBE    400.PROVEEDOR Importe pagado
HABER   572.BANCO     Importe pagado
```

---

## 7. CONSEJOS PRACTICOS

- **No borres grupos ni subgrupos** del catálogo sembrado.
  Son la estructura sobre la que se consolidan los saldos.

- **Las subcuentas de clientes y proveedores** se crean solas
  al dar de alta el tercero si activas la opción automática.
  Si las creas a mano, usa siempre el mismo criterio:
  `cuenta_padre` + `codigo_interno` sin separadores.

- **Cuenta 472 vs 477**: 472 es el IVA que pagas (soportado,
  va al DEBE). 477 es el IVA que cobras (repercutido, va al
  HABER). La liquidación trimestral es la diferencia entre ambas.

- **Antes de cerrar el ejercicio** ejecuta el informe de
  Libro Diario y verifica que todos los asientos están cuadrados
  (suma DEBE == suma HABER para cada asiento).

---

*Documento generado para el Sistema de Gestion de Pyme/Autonomo*
