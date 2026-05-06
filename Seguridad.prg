/*
 * ARCHIVO  : Seguridad.prg
 * PROPOSITO: Login de usuario y mantenimiento de roles.
 */

#include "OOp.ch"

MEMVAR cUserID, cUserNom, cUserRol


// ============================================================================
// Login()
// ============================================================================
FUNCTION Login()

    LOCAL oWin
    LOCAL oGetUsr
    LOCAL oGetPas
    LOCAL oBtAcep
    LOCAL oBtCanc
    LOCAL oLblUsr
    LOCAL oLblPas
    LOCAL oLblErr
    LOCAL cUser
    LOCAL cPass
    LOCAL lSalir
    LOCAL lOK
    LOCAL nArea

    MEMVAR cUserID, cUserNom, cUserRol

    cUser  := Space( 10 )
    cPass  := Space( 10 )
    lSalir := .F.
    lOK    := .F.
    nArea  := Select()

    IF !ABRIR_TABLA( "USUARIOS", "USR", "USR_COD" )
        MsgStop( "No se puede abrir la tabla de usuarios.", "Login" )
        RETURN .F.
    ENDIF

    DO WHILE !lSalir .AND. !lOK

        cUser := Space( 10 )
        cPass := Space( 10 )

        oWin := TWindow():New( 10, 40, 22, 90, "IDENTIFICACION DE USUARIO" )

        oLblUsr := TLabel():New( 2, 3, "Usuario :", oWin )
        oLblPas := TLabel():New( 4, 3, "Clave   :", oWin )

        oGetUsr := TGet():New( 2, 13, cUser, "@!", oWin )
        oGetUsr:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

        oGetPas := TGet():New( 4, 13, cPass, "@K!", oWin )

        oLblErr := TLabel():New( 7, 3, Space( 38 ), oWin )
        oLblErr:cColor := "R+/W"

        oBtAcep := TButton():New( 9, 8, 10, 21, oWin, "ACEPTAR", ;
            {|| _LoginVerif( oGetUsr, oGetPas, oLblErr, oWin, @lOK ) } )

        oBtCanc := TButton():New( 9, 25, 10, 38, oWin, "CANCELAR", ;
            {|| _LoginCanc( @lSalir, oWin ) } )

        oWin:AddCtrl( oLblUsr  )
        oWin:AddCtrl( oLblPas  )
        oWin:AddCtrl( oGetUsr  )
        oWin:AddCtrl( oGetPas  )
        oWin:AddCtrl( oLblErr  )
        oWin:AddCtrl( oBtAcep  )
        oWin:AddCtrl( oBtCanc  )

        // Ejecutar ventana - ESC o X cerraran la ventana
        oWin:Run()

        // Si la ventana se cerro y no hay login correcto, preguntar salir
        IF !lOK .AND. !lSalir
            IF MsgYesNo( "Desea salir del sistema?", "Salir" )
                lSalir := .T.
            ENDIF
        ENDIF

        IF lOK
            DbSelectArea( "USR" )
            OrdSetFocus( "USR_COD" )
            IF DbSeek( AllTrim( oGetUsr:uVar ) )
                cUserID  := AllTrim( USR->CODIGO )
                cUserNom := AllTrim( USR->NOMBRE )
                cUserRol := AllTrim( USR->ROLID  )
                IF NetRLock()
                    REPLACE USR->ULT_ACCE WITH Date()
                    DbUnlock()
                ENDIF
            ENDIF
        ENDIF

    ENDDO

    USR->( DbCloseArea() )
    Select( nArea )

RETURN lOK


STATIC FUNCTION _LoginVerif( oGU, oGP, oLblErr, oWin, lOK )

    LOCAL cUser
    LOCAL cPass

    cUser := AllTrim( oGU:uVar )
    cPass := AllTrim( oGP:uVar )

    DbSelectArea( "USR" )
    OrdSetFocus( "USR_COD" )

    IF DbSeek( cUser )
        IF AllTrim( USR->CLAVE ) == cPass
            lOK := .T.
            oWin:Close()
            RETURN NIL
        ENDIF
    ENDIF

    oLblErr:SetText( "  Usuario o clave incorrectos. Reintente." )

RETURN NIL


STATIC FUNCTION _LoginCanc( lSalir, oWin )

    IF MsgYesNo( "Desea salir del sistema?", "Salir" )
        lSalir := .T.
        oWin:Close()
    ENDIF

RETURN NIL


STATIC FUNCTION _LoginClose( lSalir, oWin )

    IF MsgYesNo( "Desea salir del sistema?", "Salir" )
        lSalir := .T.
        RETURN .T.  // Permite cerrar
    ENDIF

RETURN .F.  // Evita cerrar


STATIC FUNCTION _LoginEsc( lSalir, oWin )

    IF MsgYesNo( "Desea salir del sistema?", "Salir" )
        lSalir := .T.
        oWin:Close()
    ENDIF

RETURN NIL


// ============================================================================
// RolesEdit()
// ============================================================================
FUNCTION RolesEdit()

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtNvo
    LOCAL oBtSal
    LOCAL aData

    MEMVAR cUserRol

    IF AllTrim( cUserRol ) != "ADM"
        MsgStop( "Acceso restringido a Administrador.", "Roles" )
        RETURN NIL
    ENDIF

    IF !ABRIR_TABLA( "ROLES", "ROLES", "ROLID" )
        RETURN NIL
    ENDIF

    aData := _RolesCargar()

    oWin  := TWindow():New( 5, 30, 30, 100, "MANTENIMIENTO DE ROLES" )
    oGrid := TGrid():New( 2, 2, 20, 67, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 1

    oGrid:AddColumn( "ID Rol",      6, "@!", { |a| a[1] } )
    oGrid:AddColumn( "Descripcion",40, "@!", { |a| a[2] } )

    oGrid:bEnter := {| g | ;
        _RolForm( g:CurrentRow()[1], g:CurrentRow()[2] ), ;
        aData := _RolesCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oBtNvo := TButton():New( 22, 5, 23, 22, oWin, "NUEVO (F5)", ;
        {|| _RolForm( "", "" ), ;
            aData := _RolesCargar(), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 22, 45, 23, 62, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oBtNvo )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

    ROLES->( DbCloseArea() )

RETURN NIL


STATIC FUNCTION _RolesCargar()

    LOCAL aData

    aData := {}

    DbSelectArea( "ROLES" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted()
            AAdd( aData, { ;
                AllTrim( ROLES->ID     ), ;
                AllTrim( ROLES->DESCRIP ) } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _RolForm( cId, cDesc )

    LOCAL oWin
    LOCAL oGetId
    LOCAL oGetDesc
    LOCAL oBtAcep
    LOCAL oBtCanc
    LOCAL lNuevo
    LOCAL cTit
    LOCAL lOK
    LOCAL cIdEd
    LOCAL cDescEd

    lNuevo := Empty( AllTrim( cId ) )
    cTit   := If( lNuevo, "NUEVO ROL", "EDITAR ROL" )
    lOK    := .F.
    cIdEd  := PadR( cId,   3  )
    cDescEd:= PadR( cDesc, 30 )

    oWin := TWindow():New( 10, 35, 22, 85, cTit )

    oWin:AddCtrl( TLabel():New( 2, 3, "ID Rol      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 4, 3, "Descripcion :", oWin ) )

    oGetId := TGet():New( 2, 17, cIdEd, "@!", oWin )
    oGetId:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    IF !lNuevo
        oGetId:lEnabled := .F.
    ENDIF

    oGetDesc := TGet():New( 4, 17, cDescEd, "@!", oWin )
    oGetDesc:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oBtAcep := TButton():New( 8, 8, 9, 21, oWin, "GUARDAR", ;
        {|| _RolGuardar( oGetId, oGetDesc, lNuevo, @lOK, oWin ) } )

    oBtCanc := TButton():New( 8, 25, 9, 38, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGetId   )
    oWin:AddCtrl( oGetDesc )
    oWin:AddCtrl( oBtAcep  )
    oWin:AddCtrl( oBtCanc  )

    oWin:Run()

RETURN lOK


STATIC FUNCTION _RolGuardar( oGId, oGDesc, lNuevo, lOK, oWin )

    LOCAL cId
    LOCAL cDesc

    cId   := AllTrim( oGId:uVar   )
    cDesc := AllTrim( oGDesc:uVar )

    DbSelectArea( "ROLES" )
    OrdSetFocus( "ROLID" )

    IF lNuevo
        IF DbSeek( cId )
            MsgStop( "El rol " + cId + " ya existe.", "Alta" )
            RETURN NIL
        ENDIF
        IF NetFLock()
            DbAppend()
            REPLACE ROLES->ID     WITH cId
            REPLACE ROLES->DESCRIP WITH cDesc
            DbUnlock()
            lOK := .T.
            oWin:Close()
        ENDIF
    ELSE
        IF DbSeek( cId )
            IF NetRLock()
                REPLACE ROLES->DESCRIP WITH cDesc
                DbUnlock()
                lOK := .T.
                oWin:Close()
            ENDIF
        ENDIF
    ENDIF

RETURN NIL


// ============================================================================
// FIN DE Seguridad.prg
// ============================================================================
