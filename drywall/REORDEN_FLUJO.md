# Reorden del flujo Drywall

## Idea principal

Drywall debe girar alrededor de una accion fundamental: crear un proyecto temporal, definir sus tramos, calcular el despiece y guardarlo en firme.

El usuario no deberia tener que conocer tablas temporales, resumenes internos ni pasos tecnicos separados. La app debe guiar el flujo natural del trabajo.

## Flujo objetivo

1. Proyecto actual
2. Definir tramos
3. Calcular despiece
4. Pasar a historico

Al pasar a historico, el proyecto temporal queda cerrado, se generan los resultados finales y se limpia el temporal para empezar un proyecto nuevo.

## Menu Proyecto

Opciones propuestas:

- Proyecto actual
- Definir tramos
- Historico de proyectos
- Eliminar proyecto actual

### Proyecto actual

Pantalla para crear o editar la cabecera del proyecto temporal:

- Cliente
- Titulo/obra
- Fecha
- Observaciones
- Margen u otros datos generales si procede

Esta opcion no debe sonar a "nuevo proyecto" solamente, porque tambien sirve para revisar o modificar la cabecera actual.

### Definir tramos

Pantalla principal de trabajo tecnico.

Debe permitir:

- Crear tramos
- Editar tramos
- Borrar tramos
- Calcular despiece
- Pasar a historico

Dentro de esta pantalla no deberia haber demasiadas acciones sueltas. El objetivo es que el usuario trabaje con tramos y cierre el proyecto cuando este conforme.

### Historico de proyectos

Consulta de proyectos ya cerrados.

Desde aqui deberian poder consultarse los documentos generados:

- Presupuesto
- Resumen de material
- Detalle por despiece

### Eliminar proyecto actual

Accion para descartar el proyecto temporal y empezar limpio.

Debe pedir confirmacion clara, porque borra el trabajo temporal.

## Resultados esperados

Al final del flujo cada proyecto debe tener tres salidas claras:

- Presupuesto: responde a "cuanto cuesta".
- Resumen de material: responde a "que tengo que comprar".
- Detalle por despiece: responde a "de donde sale cada cantidad".

## Reglas de interfaz

- El menu debe abrir areas de trabajo.
- Los botones deben ejecutar acciones del area actual.
- Calcular, resumen, detalle, valorar, guardar y generar presupuesto no deberian aparecer como opciones sueltas de menu si pertenecen al flujo de tramos/proyecto.
- Evitar opciones duplicadas que den la sensacion de no saber que paso ejecutar.
- Mantener una interfaz minimalista: pocas decisiones visibles, pero muy claras.

## Validaciones de flujo

- No deberia permitirse definir tramos sin una cabecera minima de proyecto.
- Si el usuario entra en Definir tramos sin proyecto actual valido, la app debe abrir o solicitar primero Proyecto actual.
- Antes de pasar a historico debe existir:
  - Cabecera valida.
  - Al menos un tramo.
  - Calculo de despiece generado.
  - Resumen/informe economico coherente.
- Al pasar a historico debe evitarse duplicar proyectos ya cerrados.
- Despues de guardar en historico, se limpia el temporal.

## Criterio de producto

Primero debe funcionar como herramienta personal fiable. Si el flujo aguanta el uso real, puede evolucionar hacia una beta cerrada para profesionales de confianza.

La prioridad antes de beta es que el calculo sea predecible, revisable y coherente con piezas comerciales reales.
