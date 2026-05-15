# GfxStack / AppGestion

## Estado actual

Proyecto de escritorio en Harbour/xHarbour con datos DBF/CDX e interfaz WVG.
La aplicacion principal es `AppGestion`, con una API grafica propia en `api/`
y un modulo funcional de drywall en `drywall/`.

Entrada principal:

- `Main.prg`
- `MenuInit.prg`
- `Seguridad.prg`
- `InicioDBF.prg`
- `Util.prg`

## Estructura

- Raiz: modulos principales de la aplicacion (`*.prg`) y `test.hbp`.
- `api/`: controles y nucleo grafico reutilizable.
- `drywall/`: modulo de calculo y gestion de tabiqueria seca.
- `DATA/`: datos locales de ejecucion, fuera de Git.
- `experimentos/`: prototipos y pruebas temporales, fuera de Git.
- `logs/`, `INFORME/`, `Test/`, `scripts/`: carpetas locales o generadas.

## Flujo de arranque

1. `Main.prg` inicializa el entorno grafico y de datos.
2. `Util.prg` gestiona bloqueo de instancia, apertura segura de tablas y errores.
3. `Seguridad.prg` prepara esquema de usuarios, login y permisos.
4. `InicioDBF.prg` crea tablas, indices y datos iniciales.
5. `MenuInit.prg` construye el menu principal.

## Compilacion

El proyecto se compila con `hbmk2` usando el archivo raiz `test.hbp`:

```powershell
hbmk2 test.hbp
```

El ejecutable generado es `AppGestion.exe`. Ese binario no debe guardarse en
Git como fuente del proyecto.

## Cambios recientes detectados

- `api/TWindow.prg`: el click de raton sobre botones ya respeta la validacion
  del control con foco. Si `SetFocus()` falla, la accion del boton no se
  ejecuta.
- `api/TButton.prg`: se agrego `lSkipValid` para botones especiales como
  Cancelar, Cerrar o Salir cuando deban cerrar sin forzar validacion.
- `api/TGet.prg`: los campos de texto con picture `@Sxx` usan el ancho visible
  indicado aunque el valor inicial este vacio o sea corto.
- `api/TGet.prg`: `SetValue()` aumenta el buffer si recibe una cadena mas larga
  que la anterior.
- `.gitignore`: `experimentos/` queda excluido como carpeta temporal.

## Politica de repositorio

Debe incluirse:

- Fuentes de la aplicacion en la raiz.
- `test.hbp`.
- `api/`.
- `drywall/`.
- Documentacion de proyecto.
- `PRESUPUESTO.pdf` si se mantiene como referencia de impresion.

No debe incluirse:

- `DATA/`.
- `experimentos/`.
- `scripts/`, `logs/`, `INFORME/`, `Test/`.
- Binarios y artefactos generados: `*.exe`, `*.obj`, `*.o`, `*.c`, `*.map`.
- Archivos DBF/CDX locales salvo que se cree un dataset de prueba explicito.

## Licencia

El proyecto separa claramente dos partes:

- `api/`: libreria grafica reutilizable bajo MPL-2.0. Puede usarse en
  aplicaciones abiertas o propietarias, pero las modificaciones distribuidas de
  los archivos de `api/` deben seguir disponibles como codigo fuente MPL-2.0.
- Resto de la aplicacion: codigo propietario de AppGestion y del modulo
  drywall/pladur. No se publica bajo licencia abierta.
- Las mejoras a la API deben proponerse de vuelta al repositorio original
  cuando sea practico; esto es politica de contribucion del proyecto.

## Pendiente recomendado

- Revisar si `AppGestion.exe` debe eliminarse del arbol de trabajo y generarse
  solo al compilar.
- Disenar control de instalacion/licencia para el ejecutable final:
  clave de activacion, datos de cliente, limite de instalaciones y validacion.
- Implementar los siguientes puntos del informe de API:
  - `TCombo:Open()` sin coordenadas negativas.
  - `TGrid:bDelete` real o ajuste del manual.
  - `TGrid:MouseClick()` para seleccionar fila con raton.
  - `TLabel:SetText()` limpiando texto anterior.
  - `TControl:Enable()/Disable()` con repintado.
