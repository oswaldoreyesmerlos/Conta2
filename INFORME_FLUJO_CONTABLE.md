# Informe de flujo de ejecucion y revision contable

Fecha: 08/05/2026

## 1. Flujo de ejecucion de la aplicacion

### 1.1 Arranque principal

El punto de entrada es `Main()` en `Main.prg`.

Flujo observado:

1. `InitApp()` configura entorno grafico WVG.
2. Se configura entorno DBF:
   - `SET DATE BRIT`
   - `SET CENTURY ON`
   - `SET DELETED ON`
   - `SET EXACT ON`
   - `rddSetDefault( "DBFCDX" )`
   - `SET DEFAULT TO ".\DATA"`
3. `_CrearTablasBoot()` crea tablas minimas de arranque:
   - `USUARIOS`
   - `EMPRESA`
4. `SecurityEnsureSchema()` prepara seguridad:
   - `USUARIOS`
   - `ROLES`
   - `ROL_PERM`
   - `AUDITLOG`
   - siembra roles base
   - garantiza usuario `ADMIN` si falta clave
5. `Login()` autentica.
6. `CheckEmpresa()` valida datos de empresa.
7. `InicioDBF()` crea/verifica tablas de negocio.
8. `Menu_Init()` arma el menu segun permisos.
9. `TMenu():Run()` deja la aplicacion en bucle principal.

### 1.2 Seguridad y recuperacion

Estado actual:

- Existe bloqueo temporal por intentos fallidos.
- La clave correcta desbloquea al usuario.
- Existe `AdminRecovery.exe` para recuperar `ADMIN` sin entrar al sistema.
- El recuperador deja:
  - usuario `ADMIN`
  - clave temporal `1234`
  - desbloqueado
  - cambio obligatorio activado

Riesgo corregido:

- `SecurityEnsureSchema()` ya no debe borrar usuarios ni claves en cada arranque.

### 1.3 Menus principales

Menus activos:

- `MAESTROS`
- `VENTAS`
- `TESORERIA`
- `CONTABILIDAD`
- `INFORMES`
- `SISTEMA`

Permisos:

- `ADM` accede a sistema y configuracion.
- `CONT` accede a contabilidad e informes.
- `CAJA` accede a tesoreria e informes.

## 2. Flujo contable actual

### 2.1 Tablas contables relevantes

`CATALOGO`

- Plan contable.
- Campos clave:
  - `CUENTA`
  - `NOMBRE`
  - `NIVEL`
  - `TIPO`
  - `NATURALE`
  - `SUMA_EN`
  - `SALDO_AN`
  - `DEBE_ANU`
  - `HABER_AN`
  - `SALDO_AC`

`LDIARIO`

- Libro diario.
- Campos clave:
  - `D_ASIENT`
  - `D_LINEA`
  - `D_FECHA`
  - `D_CUENTA`
  - `D_DEBE`
  - `D_HABER`
  - `D_DESCRI`
  - `D_CCOSTE`
  - `TIP_ORIG`
  - `DOC_ORIG`

`BAL_DEF`

- Definicion de estados financieros.
- Existe estructura, pero no se observa uso funcional completo en menus o informes.

### 2.2 Funciones contables existentes

En `M_Conta.prg`:

- `PlanCuentasView()`
- `PlanCuentasForm()`
- `LibroDiarioView()`
- asiento manual con multiples lineas
- validacion de cuadre Debe/Haber
- `AsientoAutomatico()`
- `_AsiFactura()`
- `_AsiCompra()`
- `_AsiRecibo()`
- `CierreEjercicio()`

En `Informes.prg`:

- `InformeDiario()`
- `InformeMayor()`
- `InformeBalanceSumasSaldos()`
- `InformeBalanceGeneral()`
- `InformePerdidasGanancias()`

### 2.3 Asientos automaticos existentes

Factura emitida:

- Debe: `430` o cuenta cliente
- Haber: `700`
- Haber: `477`
- Marca `FACTURA->ASIENTO`

Compra:

- Debe: `600`
- Debe: `472`
- Haber: `400` o cuenta proveedor
- Marca `COMPRAS->ASIENTO`

Recibo/cobro:

- Debe: `570`
- Haber: `430` o cuenta cliente
- Marca `RECIBOS->ASIENTO`

Pago a proveedor:

- En `Tesoreria.prg`, al registrar pago se llama:
  - `AsientoAutomatico( "PAG", cNumCom )`
- Genera asiento especifico de pago:
  - Debe: `400` proveedor
  - Haber: `572` banco

## 3. Informes contables existentes y faltantes

### 3.1 Existe

- Libro Diario del ejercicio actual.
- Totales Debe/Haber del diario.
- Libro Mayor por cuenta.
- Balance de sumas y saldos.
- Balance general basico.
- Estado de perdidas y ganancias basico.

### 3.2 Falta implementar

Prioridad alta:

1. Informe de IVA repercutido/soportado.
2. Extracto de cuenta cliente/proveedor.
3. Comprobacion de asientos descuadrados por asiento.

Prioridad media:

4. Listado de asientos por origen (`FAC`, `COM`, `REC`, `PAG`, `CIE`).
5. Informe de centros de coste.

Prioridad baja:

6. Presupuesto vs real por cuenta.
7. Comparativo mensual.
8. Cierre/apertura formal con arrastre de saldos.

## 4. Hallazgos contables importantes

### 4.1 Los saldos del plan no parecen recalcularse desde diario

`CATALOGO` tiene `DEBE_ANU`, `HABER_AN` y `SALDO_AC`, pero los asientos en `LDIARIO` no parecen actualizar esos acumulados.

Recomendacion:

- Crear una rutina `RecalcularSaldosContables( nEjercicio )`.
- Recorrer `LDIARIO`.
- Acumular por `D_CUENTA`.
- Actualizar `CATALOGO`.
- Propagar a cuentas padre mediante `SUMA_EN`.

Mientras no exista esa rutina, los informes fiables deben calcularse directamente desde `LDIARIO`, no desde `CATALOGO->SALDO_AC`.

### 4.2 Libro Mayor

La tabla `LDIARIO` ya tiene indice `DIA_MAY` por cuenta y fecha, por tanto el mayor es viable sin cambiar estructura.

Implementado:

- movimientos debe/haber
- saldo acumulado
- salida TXT

Pendiente:

- cuenta desde/hasta
- fecha desde/hasta
- saldo inicial antes del periodo

### 4.3 Balance de sumas y saldos

Implementado desde `LDIARIO`, agrupando por cuenta:

- debe periodo
- haber periodo
- saldo deudor
- saldo acreedor

Este informe es la base para detectar errores antes de balance general y perdidas/ganancias.

Pendiente:

- saldo inicial
- filtro fecha desde/hasta
- opcion de cuentas auxiliares o grupos

### 4.4 Balance General

El catalogo distingue `TIPO`:

- `A`: activo
- `P`: pasivo/patrimonio
- `G`: gasto
- `I`: ingreso
- `N`: neutro

Implementado informe basico usando cuentas de tipo `A` y `P`, calculado desde `LDIARIO`.

Pendiente:

- definir formato de presentacion
- usar `SUMA_EN` para agrupar
- decidir signo segun `NATURALE`

### 4.5 Estado de perdidas y ganancias

Implementado informe basico usando cuentas:

- gastos: grupos 6 / tipo `G`
- ingresos: grupos 7 / tipo `I`

Resultado:

- ingresos - gastos

Pendiente:

- agrupacion por epigrafes.
- cuadre con cuenta `129` tras regularizacion/cierre.

### 4.6 Cierre de ejercicio todavia es simbolico

`CierreEjercicio()` valida que el diario cuadre, pero el asiento generado es simbolico con importes cero en `129`.

Falta:

- regularizar grupos 6 y 7 contra `129`
- cerrar cuentas patrimoniales
- crear asiento de apertura del ejercicio siguiente
- bloquear o advertir sobre movimientos en ejercicio cerrado

### 4.7 Riesgo de alias en contabilidad

Se detecto un patron parecido al bug de usuarios.

Corregido:

- `PlanCuentasView()` usa `CAT`.
- `PlanCuentasForm()` usa `CATF`.

Recomendacion:

- listado: alias `CAT`
- formulario: alias `CATF`

Tambien revisar `BancosView()` / `TesoreriaForm()` porque usa alias `BAN` compartido.

Nota tecnica:

- `ABRIR_TABLA()` ya comprueba si el alias esta abierto.
- Se agrego `DBUSED( cAlias )` como wrapper claro sobre `Select( cAlias ) > 0`.
- Esto evita abrir dos veces el mismo alias.
- Pero si una ventana hija reutiliza el alias de la ventana padre, al cerrar la hija puede cerrar tambien el area que la padre necesita.
- Regla recomendada:
  - cada ventana/formulario con ciclo de vida propio debe usar alias propio
  - ejemplo: listado `USR`, formulario `USRF`
  - ejemplo: listado `CAT`, formulario `CATF`
  - ejemplo: listado `BAN`, formulario `BANF`

## 5. Flujo contable recomendado

### 5.1 Ventas

1. Crear factura.
2. Generar asiento de factura:
   - D cliente `430`
   - H ventas `700`
   - H IVA `477`
3. Cobro:
   - D banco/caja `570/572`
   - H cliente `430`
4. Marcar factura cobrada.

### 5.2 Compras

1. Crear compra/factura proveedor.
2. Generar asiento de compra:
   - D compras/gasto `600/62x`
   - D IVA `472`
   - H proveedor `400`
3. Pago:
   - D proveedor `400`
   - H banco/caja `570/572`
4. Marcar compra pagada.

### 5.3 Cierre

1. Validar asientos descuadrados.
2. Emitir balance de sumas y saldos.
3. Emitir mayor de cuentas sensibles.
4. Regularizar gastos e ingresos contra `129`.
5. Emitir perdidas y ganancias.
6. Emitir balance general.
7. Cerrar ejercicio.
8. Crear apertura del ejercicio siguiente.

## 6. Plan de implementacion propuesto

### Fase 1 - Solidez minima

1. Corregir alias de `PlanCuentasForm()` (`CATF`). IMPLEMENTADO.
2. Corregir alias de `TesoreriaForm()` (`BANF`) si aplica.
3. Hacer que `_AsiCompra()` marque `COMPRAS->ASIENTO`. IMPLEMENTADO.
4. Crear `AsientoAutomatico( "PAG", cNumCom )` para pagos de proveedor. IMPLEMENTADO.
5. Cambiar `PagosView()` para usar `"PAG"` en vez de `"COM"` al registrar pago. IMPLEMENTADO.

### Fase 2 - Informes contables basicos

1. `InformeMayor()`. IMPLEMENTADO.
2. `InformeBalanceSumasSaldos()`. IMPLEMENTADO.
3. Menu `INFORMES -> Mayor`. IMPLEMENTADO.
4. Menu `INFORMES -> Balance Sumas/Saldos`. IMPLEMENTADO.

### Fase 3 - Estados financieros

1. `InformeBalanceGeneral()`. IMPLEMENTADO basico.
2. `InformePerdidasGanancias()`. IMPLEMENTADO basico.
3. Uso real de `BAL_DEF` o agrupacion por `CATALOGO->TIPO` y `SUMA_EN`.

### Fase 4 - Cierre real

1. Regularizacion de grupos 6 y 7.
2. Cierre patrimonial.
3. Apertura siguiente ejercicio.
4. Bloqueo/alerta por fecha de cierre.

## 7. Conclusion

La base contable existe y es aprovechable:

- plan contable
- diario
- asientos manuales
- asientos automaticos parciales
- informe de diario
- estructura para estados financieros

Pero para considerar la contabilidad completa faltan tres piezas clave:

1. Informes contables de control: mayor y balance de sumas/saldos.
2. Estados financieros: balance general y perdidas/ganancias.
3. Contabilizacion completa de pagos y cierre real.

La siguiente mejora recomendada es implementar primero `Libro Mayor` y `Balance de Sumas y Saldos`, porque sirven como prueba de integridad antes de construir balance general y perdidas/ganancias.
