# Bug report GfxStack

Fecha: 2026-05-15

## Corregido en el arbol de trabajo

- Click de raton en `TButton`: ya no ejecuta la accion si la validacion del
  control anterior falla durante el cambio de foco.
- Botones especiales: `TButton` incorpora `lSkipValid` para permitir cerrar o
  cancelar sin validar cuando el formulario lo configure expresamente.
- `TGet` con `@Sxx`: respeta el ancho visible declarado aunque el valor inicial
  este vacio o sea corto.
- `TGet:SetValue()`: amplia `nBufLen` si recibe una cadena mas larga.

## Pendiente

- Probar en formularios reales que solo los botones Cancelar/Cerrar/Salir usan
  `lSkipValid := .T.`.
- Corregir `TCombo:Open()` para evitar coordenadas negativas al abrir hacia
  arriba.
- Decidir si `TGrid:bDelete` se implementa o se retira del manual.
- Agregar seleccion de fila por raton en `TGrid`.
- Revisar artefactos locales: `AppGestion.exe`, `DATA/`, `logs/` y carpetas de
  pruebas no deben versionarse.
