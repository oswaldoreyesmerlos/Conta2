/*
 * ARCHIVO  : Main.prg
 * PROPOSITO: Punto de entrada, inicializacion, login y menu principal.
 */

#include "OOp.ch"

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

    IF !InicioDBF()
        MsgStop( "Error critico en la inicializacion de tablas.", "Inicio" )
        App_Exit()
        RETURN NIL
    ENDIF

    DesktopPaint( "SISTEMA DE GESTION" )

    IF !Login()
        App_Exit()
        RETURN NIL
    ENDIF

    DesktopPaint( cEmpNom )

    IF !CheckEmpresa()
        MsgStop( "Configure los datos de la empresa antes de continuar.", ;
                 "Configuracion requerida" )
    ENDIF

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
// FIN DE Main.prg
// ============================================================================
