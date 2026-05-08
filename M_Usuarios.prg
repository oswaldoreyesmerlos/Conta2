/*
 * ARCHIVO  : M_Usuarios.prg
 * PROPOSITO: Mantenimiento completo de usuarios del sistema.
 */

#include "OOp.ch"

MEMVAR cUserID, cUserNom, cUserRol


// ============================================================================
// UsuariosView()
// ============================================================================
FUNCTION UsuariosView()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL oLbl
    LOCAL aData

    MEMVAR cUserRol

    IF !RequirePerm( "SEG_USR", "Mantenimiento de usuarios" )
        RETURN NIL
    ENDIF

    IF !ABRIR_TABLA( "USUARIOS", "USR", "USR_NOM" )
        RETURN NIL
    ENDIF

    aData := _UsrCargar()

    oWin  := TWindow():New( 1, 2, 37, 129, "MANTENIMIENTO DE USUARIOS" )
    oGrid := TGrid():New( 2, 2, 30, 124, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2

    oGrid:AddColumn( "Codigo",      10, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Nombre",      35, "@!",         { |a| a[2] } )
    oGrid:AddColumn( "Rol",         4, "@!",         { |a| a[3] } )
    oGrid:AddColumn( "Nivel",       3, "9",          { |a| a[4] } )
    oGrid:AddColumn( "Ult.Acceso",  10, "@!",         { |a| a[5] } )
    oGrid:AddColumn( "Baja",        4, "@!",         { |a| If( a[6], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        UsuariosForm( g:CurrentRow()[1] ), ;
        aData := _UsrCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oLbl := TLabel():New( 32, 2, ;
        "Letras: busqueda por nombre. ENTER: editar. F5: nuevo.", oWin )

    oBtNvo := TButton():New( 33, 2, 34, 18, oWin, "NUEVO (F5)", ;
        {|| UsuariosForm( "" ), ;
            aData := _UsrCargar(), ;
            oGrid:aData := aData, ;
            oGrid:nCurRow := Len( aData ), ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 33, 108, 34, 124, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLbl   )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    USR->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _UsrCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "USR" )
    OrdSetFocus( "USR_NOM" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( USR->CODIGO   ), ;
                AllTrim( USR->NOMBRE   ), ;
                AllTrim( USR->ROLID    ), ;
                USR->NIVEL, ;
                DToC(    USR->ULT_ACCE ), ;
                USR->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


// ============================================================================
// UsuariosForm()
// ============================================================================
FUNCTION UsuariosForm( cCodigo )

    LOCAL oWin
    LOCAL nArea
    LOCAL cCod_
    LOCAL cNombre
    LOCAL cClave
    LOCAL cRolID
    LOCAL nNivel
    LOCAL dUltAcc
    LOCAL lBaja
    LOCAL oGCod
    LOCAL oGNom
    LOCAL oGPas
    LOCAL oGRol
    LOCAL oGNiv
    LOCAL oChkBaj
    LOCAL oBtGua
    LOCAL oBtCan
    LOCAL lNuevo

    DEFAULT cCodigo TO ""

    lNuevo   := Empty( AllTrim( cCodigo ) )
    nArea    := Select()
    cCod_    := Space( 10 )
    cNombre  := Space( 40 )
    cClave   := Space( 20 )
    cRolID   := Space(  3 )
    nNivel   := 1
    dUltAcc  := CToD( "" )
    lBaja    := .F.

    IF !ABRIR_TABLA( "USUARIOS", "USR", "USR_COD" )
        RETURN NIL
    ENDIF

    IF !lNuevo .AND. !Empty( AllTrim( cCodigo ) )
        DbSelectArea( "USR" )
        OrdSetFocus( "USR_COD" )
        IF DbSeek( AllTrim( cCodigo ) )
            cCod_    := PadR( AllTrim( USR->CODIGO   ), 10 )
            cNombre  := PadR( AllTrim( USR->NOMBRE   ), 40 )
            cClave   := Space( 20 )
            cRolID   := PadR( AllTrim( USR->ROLID    ),  3 )
            nNivel   := USR->NIVEL
            dUltAcc  := USR->ULT_ACCE
            lBaja    := USR->BAJA
        ENDIF
    ENDIF

    oWin := TWindow():New( 10, 30, 28, 100, ;
        If( lNuevo, "NUEVO USUARIO", "EDITAR USUARIO: " + AllTrim( cCod_ ) ) )

    oWin:AddCtrl( TLabel():New(  2, 3, "Codigo      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 3, "Nombre      :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 3, "Clave       :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 3, "Rol (ADM/CONT/CAJA):", oWin ) )
    oWin:AddCtrl( TLabel():New( 10, 3, "Nivel (1-9):", oWin ) )

    oGCod := TGet():New(  2, 17, cCod_, "@!", oWin )
    oGCod:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }
    IF !lNuevo
        oGCod:lEnabled := .F.
    ENDIF

    oGNom := TGet():New(  4, 17, cNombre, "@!", oWin )
    oGNom:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGPas := TGet():New(  6, 17, cClave, "@K!", oWin )
    oGPas:bValid := {| o | !lNuevo .OR. !Empty( AllTrim( o:cBuffer ) ) }

    oGRol := TGet():New(  8, 17, cRolID, "@!", oWin )
    oGRol:bValid := {| o | AllTrim( o:cBuffer ) $ "ADM,CONT,CAJA" }

    oGNiv := TGet():New( 10, 17, nNivel, "9", oWin )

    oChkBaj := TCheck():New( 12, 17, "Baja", lBaja, oWin )

    oBtGua := TButton():New( 14, 8, 15, 24, oWin, "GUARDAR", ;
        {|| _UsrGuardar( oGCod, oGNom, oGPas, oGRol, oGNiv, oChkBaj, lNuevo, oWin ) } )

    oBtCan := TButton():New( 14, 28, 15, 44, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGCod   )
    oWin:AddCtrl( oGNom   )
    oWin:AddCtrl( oGPas   )
    oWin:AddCtrl( oGRol   )
    oWin:AddCtrl( oGNiv   )
    oWin:AddCtrl( oChkBaj )
    oWin:AddCtrl( oBtGua  )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

    USR->( DbCloseArea() )
    Select( nArea )

RETURN NIL


STATIC FUNCTION _UsrGuardar( oGC, oGN, oGP, oGR, oGNv, oChk, lNuevo, oWin )

    LOCAL cCodigo
    LOCAL cClave

    cCodigo := AllTrim( oGC:uVar )
    cClave  := AllTrim( oGP:uVar )

    DbSelectArea( "USR" )
    OrdSetFocus( "USR_COD" )

    IF lNuevo
        IF DbSeek( cCodigo )
            MsgStop( "El codigo " + cCodigo + " ya existe.", "Alta usuario" )
            RETURN NIL
        ENDIF
        IF !NetFLock()
            RETURN NIL
        ENDIF
        DbAppend()
    ELSE
        IF !DbSeek( cCodigo )
            RETURN NIL
        ENDIF
        IF !NetRLock()
            RETURN NIL
        ENDIF
    ENDIF

    REPLACE USR->CODIGO   WITH cCodigo
    REPLACE USR->NOMBRE   WITH AllTrim( oGN:uVar )
    REPLACE USR->ROLID    WITH AllTrim( oGR:uVar )
    REPLACE USR->NIVEL    WITH oGNv:uVar

    IF lNuevo .OR. !Empty( cClave )
        IF !UserSetPassword( cCodigo, cClave )
            DbUnlock()
            MsgStop( "Debe indicar una clave valida.", "Usuario" )
            RETURN NIL
        ENDIF
    ENDIF

    IF lNuevo
        REPLACE USR->FECHA_AL WITH Date()
        REPLACE USR->ULT_ACCE WITH Date()
    ENDIF

    REPLACE USR->BAJA     WITH oChk:lValue
    IF FieldPos( "INT_FAL" ) > 0 .AND. !oChk:lValue
        REPLACE USR->INT_FAL WITH 0
    ENDIF

    DbCommit()
    DbUnlock()

    AuditLog( If( lNuevo, "ALTA", "MODIF" ), "USUARIOS", cCodigo, ;
              "Usuario/rol actualizado", .T. )

    oWin:Close()

RETURN NIL


// ============================================================================
// FIN DE M_Usuarios.prg
// ============================================================================
