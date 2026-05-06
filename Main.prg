/*
 * ARCHIVO  : Main.prg
 * PROPOSITO: Punto de entrada, inicializacion, login y menu principal.
 */

#include "OOp.ch"

REQUEST DBFCDX

MEMVAR cUserID, cUserNom, cUserRol, cEmpNom

EXTERNAL Menu_Init
EXTERNAL Login
EXTERNAL InicioDBF

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
    ErrorBlock( { |e| ErrSys( e ) } )

    SET DATE BRIT
    SET DATE FORMAT TO "DD/MM/YYYY"
    SET EPOCH TO 1950
    SET CENTURY ON
    SET DELETED ON
    SET EXACT ON

    // 1. Crear SOLO tabla EMPRESA si no existe
    IF !_CrearEmpresaDBF()
        MsgStop( "Error critico creando tabla EMPRESA.", "Inicio" )
        App_Exit()
        RETURN NIL
    ENDIF

    DesktopPaint( "SISTEMA DE GESTION" )

    // 2. Verificar datos de empresa ANTES de crear el resto
    //    No dejar continuar hasta que se configure
    DO WHILE !CheckEmpresa()
        MsgInfo( "Debe configurar los datos de la empresa antes de continuar.", "Requerido" )
        IF !FirstEmpresa()
            App_Exit()
            RETURN NIL
        ENDIF
    ENDDO

    // 3. Crear el resto de tablas
    IF !InicioDBF()
        MsgStop( "Error critico en la inicializacion de tablas.", "Inicio" )
        App_Exit()
        RETURN NIL
    ENDIF

    IF !Login()
        App_Exit()
        RETURN NIL
    ENDIF

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
    GfxCursor( SC_NORMAL )
    CLS
    QUIT

RETURN NIL


// ============================================================================
// CheckEmpresa()
// ============================================================================
FUNCTION CheckEmpresa()

    LOCAL lOK
    LOCAL nArea

    MEMVAR cEmpNom

    lOK   := .F.
    nArea := Select()

    IF ABRIR_TABLA( "EMPRESA", "EMP_CHK", "" )
        EMP_CHK->( DbGoTop() )
        IF !EMP_CHK->( Eof() ) .AND. !EMP_CHK->( Deleted() )
            IF !Empty( AllTrim( EMP_CHK->NIF    ) ) .AND. ;
               !Empty( AllTrim( EMP_CHK->NOMBRE ) )
                lOK     := .T.
                cEmpNom := AllTrim( EMP_CHK->NOMBRE )
            ENDIF
        ENDIF
        EMP_CHK->( DbCloseArea() )
    ENDIF

    Select( nArea )

RETURN lOK


// ============================================================================
// _CrearEmpresaDBF()
// Crea SOLO la tabla EMPRESA si no existe.
// Devuelve .T. si todo bien.
// ============================================================================
STATIC FUNCTION _CrearEmpresaDBF()

    LOCAL aCampos  := {}
    LOCAL aIndices := {}
    LOCAL cDbf      := ".\DATA\EMPRESA.DBF"

    IF File( cDbf )
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
    AAdd( aIndices, { "EMP_NIF", "NIF" } )

    DbCreate( cDbf, aCampos, "DBFCDX", .T., "EMP_TMP" )

    IF !NetFLock( "EMP_TMP", 0.5 )
        MsgStop( "No se pudo bloquear EMPRESA temporal", "Error" )
        RETURN .F.
    ENDIF

    DbAppend()
    REPLACE EMP_TMP->NIF WITH "0000000000000"
    REPLACE EMP_TMP->NOMBRE WITH "EMPRESA SIN CONFIGURAR"
    DbUnlock()
    DbCloseArea()

    // Crear indices
    IF !ABRIR_TABLA( "EMPRESA", "EMP_INI", "" )
        RETURN .F.
    ENDIF

    EMP_INI->( DbClearIndex() )
    AEval( aIndices, {|oIdx| EMP_INI->( ordCreate( , oIdx[1], oIdx[2], NIL, NIL, NIL, 1 ) ) } )
    EMP_INI->( DbCloseArea() )

RETURN .T.


// ============================================================================
// DesktopPaint()
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

    GfxClear( 0, 0, 0, nMaxC, "W+/B" )
    GfxText( 0, Int( ( nMaxC - Len( cTitulo ) ) / 2 ), cTitulo, "W+/B" )

    cInfo := " Usuario: " + AllTrim( cUserID ) + ;
             "  Rol: "    + AllTrim( cUserRol ) + ;
             "  "         + DToC( Date() ) + ;
             "  "         + Time()

    GfxClear( nMaxR, 0, nMaxR, nMaxC, "W+/B" )
    GfxText( nMaxR, 1, PadR( cInfo, nMaxC ), "W+/B" )

    GfxUnlock()

RETURN NIL


// ============================================================================
// FirstEmpresa()
// Forzar alta de empresa la primera vez.
// Muestra el maestro completo (Empresa()).
// Devuelve .T. si se guardaron datos validos.
// ============================================================================
FUNCTION FirstEmpresa()

    LOCAL lOK := .F.

    DO WHILE !lOK
        // Mostrar maestro completo de empresa
        Empresa()

        lOK := CheckEmpresa()
        IF !lOK
            IF !MsgYesNo( "Debe ingresar los datos de la empresa para continuar." + Chr(13) + ;
                          "NIF valido y Nombre no vacio son obligatorios." + Chr(13) + ;
                          "Desea intentar de nuevo?", "Datos requeridos" )
                EXIT
            ENDIF
        ENDIF
    ENDDO

RETURN lOK


// ============================================================================
// FIN DE Main.prg
// ============================================================================
