/*
 * ARCHIVO  : Main.prg
 * PROPOSITO: Punto de entrada, inicializacion, login y menu principal.
 *
 * FLUJO DE ARRANQUE
 * -----------------
 * 1. InitApp()             configura entorno WVG, fuente, modo pantalla
 * 2. _CrearTablasBoot()    crea SOLO USUARIOS + EMPRESA si no existen
 *                          siembra usuario ADMIN/1234 con cambio obligatorio
 * 3. Login()               autenticacion obligatoria — sin ella nada mas
 * 4. CheckEmpresa()        verifica NIF + Nombre configurados
 *    → si falta → Empresa() formulario obligatorio
 *    → si cancela sin guardar → App_Exit()
 * 5. InicioDBF()           crea las tablas restantes + semillas (IVA, PGC...)
 * 6. DesktopPaint()        barra de titulo con nombre de empresa
 * 7. TMenu():Run()         bucle principal de la aplicacion
 */

#include "OOp.ch"

REQUEST DBFCDX

MEMVAR cUserID, cUserNom, cUserRol, cEmpNom

EXTERNAL Menu_Init
EXTERNAL Login
EXTERNAL SecurityEnsureSchema
EXTERNAL InicioDBF
EXTERNAL InicioDrywall
EXTERNAL Empresa

INIT PROCEDURE IniGlobales()
    PUBLIC cUserID  := Space( 10 )
    PUBLIC cUserNom := Space( 40 )
    PUBLIC cUserRol := Space(  4 )
    PUBLIC cEmpNom  := "SISTEMA"
RETURN


// ============================================================================
// Main()
// ============================================================================
FUNCTION Main()

    LOCAL aMenu

    MEMVAR cUserID, cUserRol, cEmpNom

    InitApp()
    GfxThemeLoad()
    ErrorBlock( { |e| ErrSys( e ) } )

    IF !AppLockAcquire()
        MsgStop( "AppGestion ya esta abierto en este terminal.", "Inicio" )
        App_Exit()
        RETURN NIL
    ENDIF

    SET DATE BRIT
    SET DATE FORMAT TO "DD/MM/YYYY"
    SET EPOCH TO 1950
    SET CENTURY ON
    SET DELETED ON
    SET EXACT ON

    // Directorio de datos: debe establecerse ANTES de cualquier
    // operacion con tablas — incluidas las de arranque (USUARIOS, EMPRESA).
    IF !DirExiste( ".\DATA" )
        IF DirMake( ".\DATA" ) != 0
            MsgStop( "No se pudo crear la carpeta DATA.", "Error critico" )
            App_Exit()
            RETURN NIL
        ENDIF
    ENDIF

    rddSetDefault( "DBFCDX" )
    SET DEFAULT TO ".\DATA"

    // ------------------------------------------------------------------
    // PASO 1: Crear USUARIOS y EMPRESA si no existen (tablas de arranque)
    //         Estas dos tablas son necesarias ANTES del Login.
    //         El resto se crea en InicioDBF() tras verificar la empresa.
    // ------------------------------------------------------------------
    IF !_CrearTablasBoot()
        MsgStop( "Error critico creando tablas de arranque.", "Inicio" )
        App_Exit()
        RETURN NIL
    ENDIF

    IF !SecurityEnsureSchema()
        MsgStop( "Error critico preparando seguridad y auditoria.", "Inicio" )
        App_Exit()
        RETURN NIL
    ENDIF

    DesktopPaint( "SISTEMA DE GESTION" )

    // ------------------------------------------------------------------
    // PASO 2: LOGIN — autenticacion obligatoria
    //         Sin credenciales validas no se puede continuar.
    //         Usuario por defecto: ADMIN / 1234 con cambio obligatorio
    // ------------------------------------------------------------------
    IF !Login()
        App_Exit()
        RETURN NIL
    ENDIF

    // ------------------------------------------------------------------
    // PASO 3: VERIFICAR EMPRESA
    //         Si NIF o Nombre estan vacios, mostrar formulario de alta.
    //         Si el usuario cancela sin guardar datos validos → salir.
    // ------------------------------------------------------------------
    IF !CheckEmpresa()
        Empresa()
        IF !CheckEmpresa()
            MsgStop( "La empresa debe estar configurada para iniciar el sistema.", ;
                     "Configuracion requerida" )
            App_Exit()
            RETURN NIL
        ENDIF
    ENDIF

    // ------------------------------------------------------------------
    // PASO 4: CREAR RESTO DE TABLAS
    //         InicioDBF() crea las 33 tablas restantes y siembra datos
    //         iniciales (tipos IVA, plan contable PGC...).
    // ------------------------------------------------------------------
    IF !InicioDBF()
        MsgStop( "Error critico en la inicializacion de tablas.", "Inicio" )
        App_Exit()
        RETURN NIL
    ENDIF

    // ------------------------------------------------------------------
    // PASO 4b: TABLAS ESPECIFICAS DRYWALL
    // ------------------------------------------------------------------
    IF !InicioDrywall()
        MsgStop( "Error creando tablas del modulo Drywall.", "Inicio" )
        App_Exit()
        RETURN NIL
    ENDIF

    // ------------------------------------------------------------------
    // PASO 5: MENU PRINCIPAL
    // ------------------------------------------------------------------
    DesktopPaint( cEmpNom )

    aMenu := Menu_Init()
    TMenu():New( aMenu, 0 ):Run()

    App_Exit()

RETURN NIL


// ============================================================================
// App_Exit()
// ============================================================================
FUNCTION App_Exit()

    dbCloseAll()
    AppLockRelease()
    GfxCursor( SC_NORMAL )
    CLS
    QUIT

RETURN NIL


// ============================================================================
// CheckEmpresa()
// Devuelve .T. si la tabla EMPRESA tiene un registro con NIF y Nombre
// validos (no vacios y NIF distinto del placeholder de arranque).
// Como efecto secundario actualiza la variable publica cEmpNom.
// ============================================================================
FUNCTION CheckEmpresa()

    LOCAL lOK
    LOCAL nArea
    LOCAL cNif
    LOCAL cNom

    MEMVAR cEmpNom

    lOK   := .F.
    nArea := Select()

    IF ABRIR_TABLA( "EMPRESA", "EMP_CHK", "" )
        EMP_CHK->( DbGoTop() )
        IF !EMP_CHK->( Eof() ) .AND. !EMP_CHK->( Deleted() )
            cNif := AllTrim( EMP_CHK->NIF    )
            cNom := AllTrim( EMP_CHK->NOMBRE )
            IF !Empty( cNif ) .AND. !Empty( cNom )
                lOK     := .T.
                cEmpNom := cNom
            ENDIF
        ENDIF
        EMP_CHK->( DbCloseArea() )
    ENDIF

    Select( nArea )

RETURN lOK


// ============================================================================
// DesktopPaint( cTitulo )
// Pinta el fondo de escritorio con barra de titulo y barra de estado.
// ============================================================================
FUNCTION DesktopPaint( cTitulo )

    LOCAL nMaxC
    LOCAL nMaxR
    LOCAL cInfo

    MEMVAR cUserID, cUserRol

    DEFAULT cTitulo TO "SISTEMA"

    nMaxC := GfxMaxCol()
    nMaxR := GfxMaxRow()

    GfxLock()

    GfxClear( 0, 0, nMaxR, nMaxC, CLR_WINDOW )

    // Barra superior — titulo centrado
    GfxClear( 0, 0, 0, nMaxC, "W+/B" )
    GfxText( 0, Int( ( nMaxC - Len( cTitulo ) ) / 2 ), cTitulo, "W+/B" )

    // Barra inferior — usuario, rol, fecha, hora
    cInfo := " Usuario: " + AllTrim( cUserID ) + ;
             "  Rol: "    + AllTrim( cUserRol ) + ;
             "  "         + DToC( Date() ) + ;
             "  "         + Time()

    GfxClear( nMaxR, 0, nMaxR, nMaxC, "W+/B" )
    GfxText( nMaxR, 1, PadR( cInfo, nMaxC ), "W+/B" )

    GfxUnlock()

RETURN NIL


// ============================================================================
// _CrearTablasBoot()
// ----------------------------------------------------------------------------
// Crea las dos tablas necesarias ANTES del Login:
//   - USUARIOS : para poder autenticar
//   - EMPRESA  : para poder verificar configuracion
//
// Si USUARIOS esta vacia siembra el usuario ADMIN/1234 con rol ADM.
// Si EMPRESA no existe crea la tabla con un registro placeholder.
//
// Devuelve .T. si todo fue bien, .F. si hubo error critico.
// ============================================================================
STATIC FUNCTION _CrearTablasBoot()

    LOCAL lOK

    lOK := .T.

    // El directorio DATA y rddSetDefault ya fueron establecidos en Main().
    // Esta funcion solo crea las tablas si no existen.

    IF !_BootUsuarios()
        lOK := .F.
    ENDIF

    IF !_BootEmpresa()
        lOK := .F.
    ENDIF

RETURN lOK


// ----------------------------------------------------------------------------
// _BootUsuarios()
// Crea tabla USUARIOS si no existe y siembra ADMIN si esta vacia.
// ----------------------------------------------------------------------------
STATIC FUNCTION _BootUsuarios()

    LOCAL aCampos
    LOCAL aIdx
    LOCAL cDbf

    aCampos := {}
    aIdx    := {}
    cDbf    := "USUARIOS"

    IF !File( cDbf + ".DBF" )

        AAdd( aCampos, { "CODIGO",   "C", 10, 0 } )
        AAdd( aCampos, { "NOMBRE",   "C", 40, 0 } )
        AAdd( aCampos, { "ROLID",    "C",  3, 0 } )
        AAdd( aCampos, { "NIVEL",    "N",  1, 0 } )
        AAdd( aCampos, { "FECHA_AL", "D",  8, 0 } )
        AAdd( aCampos, { "ULT_ACCE", "D",  8, 0 } )
        AAdd( aCampos, { "ULT_HORA", "C",  8, 0 } )
        AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
        AAdd( aCampos, { "CLAVE_H",  "C", 64, 0 } )
        AAdd( aCampos, { "SALT",     "C", 32, 0 } )
        AAdd( aCampos, { "CAMB_CL",  "L",  1, 0 } )
        AAdd( aCampos, { "FEC_CL",   "D",  8, 0 } )
        AAdd( aCampos, { "INT_FAL",  "N",  3, 0 } )
        AAdd( aCampos, { "BLOQ_FEC", "D",  8, 0 } )
        AAdd( aCampos, { "BLOQ_HOR", "C",  8, 0 } )

        DbCreate( cDbf, aCampos )

    ENDIF

    IF !ABRIR_TABLA( cDbf, "USR_B", "USR_COD" )

        // Intentar sin indice si falla (primera vez sin CDX)
        IF !ABRIR_TABLA( cDbf, "USR_B", "" )
            RETURN .F.
        ENDIF

    ENDIF

    // Regenerar indice si no existe
    IF File( cDbf + ".CDX" )
        // ya existe
    ELSE
        USR_B->( OrdCreate( cDbf + ".CDX", "USR_COD", "CODIGO" ) )
        USR_B->( OrdCreate( cDbf + ".CDX", "USR_NOM", "Upper(NOMBRE)" ) )
    ENDIF

    // Sembrar ADMIN si tabla vacia
    IF USR_B->( LastRec() ) == 0
        IF NetFLock()
            USR_B->( DbAppend() )
            REPLACE USR_B->CODIGO   WITH "ADMIN"
            REPLACE USR_B->NOMBRE   WITH "Administrador"
            REPLACE USR_B->ROLID    WITH "ADM"
            REPLACE USR_B->NIVEL    WITH 9
            REPLACE USR_B->FECHA_AL WITH Date()
            REPLACE USR_B->ULT_ACCE WITH Date()
            REPLACE USR_B->ULT_HORA WITH Time()
            REPLACE USR_B->BAJA     WITH .F.
            UserSetPassword( "ADMIN", "1234" )
            REPLACE USR_B->CAMB_CL  WITH .T.
            DbCommit()
            DbUnlock()
        ENDIF
    ENDIF

    USR_B->( DbCloseArea() )

RETURN .T.


// ----------------------------------------------------------------------------
// _BootEmpresa()
// Crea tabla EMPRESA si no existe con un registro placeholder.
// ----------------------------------------------------------------------------
STATIC FUNCTION _BootEmpresa()

    LOCAL aCampos
    LOCAL cDbf

    aCampos := {}
    cDbf    := "EMPRESA"

    IF File( cDbf + ".DBF" )
        RETURN .T.
    ENDIF

    AAdd( aCampos, { "NIF",      "C", 13, 0 } )
    AAdd( aCampos, { "NOMBRE",   "C", 60, 0 } )
    AAdd( aCampos, { "DIRECCIO", "C", 60, 0 } )
    AAdd( aCampos, { "CIUDAD",   "C", 40, 0 } )
    AAdd( aCampos, { "PROVINCI", "C", 30, 0 } )
    AAdd( aCampos, { "CP",       "C",  5, 0 } )
    AAdd( aCampos, { "PAIS",     "C", 30, 0 } )
    AAdd( aCampos, { "TELEFONO", "C", 15, 0 } )
    AAdd( aCampos, { "MOVIL",    "C", 15, 0 } )
    AAdd( aCampos, { "EMAIL",    "C", 50, 0 } )
    AAdd( aCampos, { "WEB",      "C", 50, 0 } )
    AAdd( aCampos, { "REG_TOMO", "C", 10, 0 } )
    AAdd( aCampos, { "REG_FOL",  "C", 10, 0 } )
    AAdd( aCampos, { "REG_HOJA", "C", 15, 0 } )
    AAdd( aCampos, { "REG_SECC", "C", 10, 0 } )
    AAdd( aCampos, { "IBANPPAL", "C", 34, 0 } )
    AAdd( aCampos, { "FEC_CIER", "D",  8, 0 } )
    AAdd( aCampos, { "PREFIJO",  "C",  3, 0 } )
    AAdd( aCampos, { "LOGO",     "C",120, 0 } )
    AAdd( aCampos, { "PIE_DOC",  "M", 10, 0 } )

    DbCreate( cDbf, aCampos )

    IF !ABRIR_TABLA( cDbf, "EMP_B", "" )
        RETURN .F.
    ENDIF

    // Crear indice
    EMP_B->( OrdCreate( cDbf + ".CDX", "EMP_NIF", "NIF" ) )

    // Tabla vacia intencionalmente — CheckEmpresa() detecta Eof()
    // y fuerza el alta antes de continuar

    EMP_B->( DbCloseArea() )
RETURN .T.


// ============================================================================
// FIN DE Main.prg
// ============================================================================
