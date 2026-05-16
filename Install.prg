/*
------------------------------------------------------------------------------
 ARCHIVO:     INSTALLPYL.PRG
 DESCRIPCION: Instalador del sistema PYL
 EJECUTABLE:  INSTALLPYL.EXE

 FUNCION:
   - Crear carpetas DATA y SOURCE
   - Crear bases de datos e índices
   - Inicializar EMPRESA
   - Copiar todo el código fuente a SOURCE

 NOTAS:
   - Se ejecuta desde pendrive
   - NO se copia a destino
   - Todos los archivos origen están en la raíz
------------------------------------------------------------------------------
*/

#include "fileio.ch"

FUNCTION Main()
    Install()
RETURN NIL


FUNCTION Install()

    LOCAL cBaseDir := ""
    LOCAL cDataDir := ""
    LOCAL cSrcDir := ""
    LOCAL nErr := 0
    LOCAL aFiles := {}
    LOCAL i := 0
    LOCAL cFile := ""

    CLS
    ? "======================================"
    ? "  INSTALADOR SISTEMA PYL"
    ? "======================================"
    ?

    /*
    --------------------------------------------------------------------------
    1. Selección de ruta destino
    --------------------------------------------------------------------------
    */
    ACCEPT "Ruta destino (ej: C:\PYL): " TO cBaseDir

    cBaseDir := AllTrim( cBaseDir )

    IF Empty( cBaseDir )
        Alert( "Ruta destino no valida." )
        RETURN .F.
    ENDIF

    cDataDir := cBaseDir + "\DATA"
    cSrcDir  := cBaseDir + "\SOURCE"

    /*
    --------------------------------------------------------------------------
    2. Creación de carpetas
    --------------------------------------------------------------------------
    */
    IF !DirExiste( cBaseDir )
        nErr := DirMake( cBaseDir )
        IF nErr != 0
            Alert( "ERROR creando carpeta base." )
            RETURN .F.
        ENDIF
    ENDIF

    IF !DirExiste( cDataDir )
        nErr := DirMake( cDataDir )
        IF nErr != 0
            Alert( "ERROR creando carpeta DATA." )
            RETURN .F.
        ENDIF
    ENDIF

    IF !DirExiste( cSrcDir )
        nErr := DirMake( cSrcDir )
        IF nErr != 0
            Alert( "ERROR creando carpeta SOURCE." )
            RETURN .F.
        ENDIF
    ENDIF

    ?
    ? "Carpetas creadas correctamente."

    /*
    --------------------------------------------------------------------------
    3. Creación de bases de datos e índices
    --------------------------------------------------------------------------
    */
    SET DEFAULT TO ( cDataDir )
    SET EXCLUSIVE ON

    ?
    ? "Creando estructuras de bases de datos..."

    Init_Dbs()

    SET EXCLUSIVE OFF

    ?
    ? "Bases de datos creadas."

    /*
    --------------------------------------------------------------------------
    4. Inicialización de EMPRESA
    --------------------------------------------------------------------------
    */
    IF !File( "EMPRESA.DBF" )
        Alert( "ERROR CRITICO: EMPRESA.DBF no existe." )
        RETURN .F.
    ENDIF

    USE EMPRESA EXCLUSIVE NEW

    IF NetErr()
        Alert( "ERROR: No se pudo abrir EMPRESA en exclusivo." )
        CLOSE DATABASES
        RETURN .F.
    ENDIF

    IF LastRec() == 0
        APPEND BLANK
        REPLACE FECHA_ALTA WITH Date()
    ENDIF

    CLOSE EMPRESA

    ?
    ? "Empresa inicializada."

    /*
    --------------------------------------------------------------------------
    5. Copia del código fuente a SOURCE
    --------------------------------------------------------------------------
    */
    ?
    ? "Copiando codigo fuente..."

    aFiles := Directory( "*.*" )

    FOR i := 1 TO Len( aFiles )

        cFile := Upper( aFiles[i][1] )

        IF Right( cFile, 4 ) == ".PRG"
            FileCopy( aFiles[i][1], cSrcDir + "\" + aFiles[i][1] )
        ENDIF

        IF Right( cFile, 3 ) == ".CH"
            FileCopy( aFiles[i][1], cSrcDir + "\" + aFiles[i][1] )
        ENDIF

        IF Right( cFile, 4 ) == ".HBP"
            FileCopy( aFiles[i][1], cSrcDir + "\" + aFiles[i][1] )
        ENDIF

    NEXT

    ?
    ? "Codigo copiado."

    /*
    --------------------------------------------------------------------------
    6. Finalización
    --------------------------------------------------------------------------
    */
    ?
    ? "======================================"
    ? " INSTALACION COMPLETADA CORRECTAMENTE "
    ? "======================================"
    ?
    ? "Estructura creada en:"
    ? cBaseDir
    ?
    ? "Ejecucion normal desde el ejecutable instalado."
    ?

RETURN .T.
