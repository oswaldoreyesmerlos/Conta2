/*
 * ARCHIVO  : Seguridad.prg
 * PROPOSITO: Login de usuario y mantenimiento de roles.
 */

#include "OOp.ch"

MEMVAR cUserID, cUserNom, cUserRol

#define LOGIN_MAX_FAILS     5
#define LOGIN_LOCK_SECONDS  300


// ============================================================================
// SecurityEnsureSchema()
// Migra tablas de seguridad antes del login y garantiza AUDITLOG.
// ============================================================================
FUNCTION SecurityEnsureSchema()

    LOCAL lOK := .T.

    // Mantiene la estructura de seguridad sin borrar usuarios ni claves.
    // La recuperacion de ADMIN queda en AdminRecovery.exe.
    lOK := lOK .AND. _EnsureSecuritySchema()

    IF lOK
        _SeedRoles()
        _EnsureAdminPassword()
    ENDIF

RETURN lOK


STATIC FUNCTION _EnsureSecuritySchema()

    LOCAL lOK := .T.

    dbCloseAll()

    lOK := lOK .AND. _EnsureUsuariosSchema()
    lOK := lOK .AND. _EnsureRolesSchema()
    lOK := lOK .AND. _EnsureRolPermSchema()
    lOK := lOK .AND. _EnsureAuditSchema()

RETURN lOK


STATIC FUNCTION _DropDbf( cDbf )

    IF File( cDbf + ".CDX" )
        FErase( cDbf + ".CDX" )
    ENDIF

    IF File( cDbf + ".FPT" )
        FErase( cDbf + ".FPT" )
    ENDIF

    IF File( cDbf + ".DBF" )
        FErase( cDbf + ".DBF" )
    ENDIF

RETURN .T.


// ============================================================================
// UserPasswordHash()
// SHA-256 iterado con sal individual. No deja la clave en claro en DBF.
// ============================================================================
FUNCTION UserPasswordHash( cPassword, cSalt )

    LOCAL cHash
    LOCAL i

    DEFAULT cPassword TO ""
    DEFAULT cSalt     TO ""

    cHash := HB_SHA256( AllTrim( cSalt ) + ":" + cPassword )
    FOR i := 1 TO 499
        cHash := HB_SHA256( AllTrim( cSalt ) + ":" + cHash )
    NEXT

RETURN cHash


FUNCTION UserNewSalt( cUser )
RETURN Left( HB_SHA256( AllTrim( cUser ) + DToS( Date() ) + Time() + ;
                        AllTrim( Str( Seconds() * 1000 ) ) ), 32 )


FUNCTION UserSetPassword( cUser, cPassword )

    LOCAL cSalt
    LOCAL cHash

    IF Empty( AllTrim( cPassword ) )
        RETURN .F.
    ENDIF

    cSalt := UserNewSalt( cUser )
    cHash := UserPasswordHash( cPassword, cSalt )

    REPLACE SALT    WITH cSalt
    REPLACE CLAVE_H WITH cHash
    REPLACE FEC_CL  WITH Date()
    REPLACE CAMB_CL WITH .F.
    IF FieldPos( "INT_FAL" ) > 0
        REPLACE INT_FAL WITH 0
    ENDIF
    IF FieldPos( "BLOQ_FEC" ) > 0
        REPLACE BLOQ_FEC WITH CToD( "" )
    ENDIF
    IF FieldPos( "BLOQ_HOR" ) > 0
        REPLACE BLOQ_HOR WITH Space( 8 )
    ENDIF

RETURN .T.


FUNCTION UserPasswordValid( cPassword )

    LOCAL cSalt
    LOCAL cHash

    cSalt := AllTrim( USR->SALT )
    cHash := AllTrim( USR->CLAVE_H )

    IF Empty( cSalt ) .OR. Empty( cHash )
        RETURN .F.
    ENDIF

RETURN ( cHash == UserPasswordHash( cPassword, cSalt ) )


// ============================================================================
// HasPerm() / RequirePerm()
// ADM siempre tiene acceso. Otros roles se resuelven contra ROL_PERM.
// ============================================================================
FUNCTION HasPerm( cPerm )

    LOCAL lOK := .F.
    LOCAL nArea := Select()
    LOCAL cRol
    LOCAL lRoleOK := .F.

    MEMVAR cUserRol

    DEFAULT cPerm TO ""

    cRol := Upper( AllTrim( cUserRol ) )

    IF cRol == "ADM"
        RETURN .T.
    ENDIF

    IF Empty( cPerm )
        RETURN .F.
    ENDIF

    IF ABRIR_TABLA( "ROLES", "ROL_CHK", "ROLID" )
        DbSelectArea( "ROL_CHK" )
        OrdSetFocus( "ROLID" )
        IF DbSeek( cRol )
            lRoleOK := !ROL_CHK->BAJA
        ENDIF
        ROL_CHK->( DbCloseArea() )
    ENDIF

    IF lRoleOK .AND. ABRIR_TABLA( "ROL_PERM", "RPM_CHK", "RPM_ROL" )
        DbSelectArea( "RPM_CHK" )
        OrdSetFocus( "RPM_ROL" )
        DbGoTop()
        DO WHILE !Eof()
            IF !Deleted() .AND. AllTrim( RPM_CHK->ROLID ) == cRol .AND. ;
               !RPM_CHK->BAJA .AND. ;
               ( AllTrim( RPM_CHK->PERMISO ) == "*" .OR. ;
                 AllTrim( RPM_CHK->PERMISO ) == Upper( AllTrim( cPerm ) ) )
                lOK := .T.
                EXIT
            ENDIF
            DbSkip()
        ENDDO
        RPM_CHK->( DbCloseArea() )
    ENDIF

    Select( nArea )

RETURN lOK


FUNCTION RequirePerm( cPerm, cAccion )

    DEFAULT cAccion TO cPerm

    IF HasPerm( cPerm )
        RETURN .T.
    ENDIF

    AuditLog( "DENEGADO", "PERMISOS", cPerm, cAccion, .F. )
    MsgStop( "Acceso denegado para: " + cAccion, "Seguridad" )

RETURN .F.


// ============================================================================
// AuditLog()
// Registro central de trazabilidad por usuario, rol, accion y documento.
// ============================================================================
FUNCTION AuditLog( cAccion, cTabla, cClave, cDetalle, lOK )

    LOCAL nArea := Select()
    LOCAL cId

    MEMVAR cUserID, cUserRol

    DEFAULT cAccion  TO ""
    DEFAULT cTabla   TO ""
    DEFAULT cClave   TO ""
    DEFAULT cDetalle TO ""
    DEFAULT lOK      TO .T.

    IF !ABRIR_TABLA( "AUDITLOG", "AUD", "AUD_ID" )
        Select( nArea )
        RETURN .F.
    ENDIF

    cId := DToS( Date() ) + StrTran( Time(), ":", "" ) + ;
           Right( "0000" + AllTrim( Str( RecCount() + 1 ) ), 4 )

    DbSelectArea( "AUD" )
    IF NetFLock()
        DbAppend()
        REPLACE AUD->ID      WITH cId
        REPLACE AUD->FECHA   WITH Date()
        REPLACE AUD->HORA    WITH Time()
        REPLACE AUD->USUARIO WITH PadR( AllTrim( cUserID ), 10 )
        REPLACE AUD->ROL     WITH PadR( AllTrim( cUserRol ), 3 )
        REPLACE AUD->ACCION  WITH PadR( Upper( AllTrim( cAccion ) ), 20 )
        REPLACE AUD->TABLA   WITH PadR( Upper( AllTrim( cTabla ) ), 12 )
        REPLACE AUD->CLAVE   WITH PadR( AllTrim( cClave ), 30 )
        REPLACE AUD->DETALLE WITH PadR( AllTrim( cDetalle ), 120 )
        REPLACE AUD->EQUIPO  WITH PadR( NetName(), 30 )
        REPLACE AUD->OK      WITH lOK
        DbCommit()
        DbUnlock()
    ENDIF

    AUD->( DbCloseArea() )
    Select( nArea )

RETURN .T.


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
    cPass  := Space( 32 )
    lSalir := .F.
    lOK    := .F.
    nArea  := Select()

    IF !ABRIR_TABLA( "USUARIOS", "USR", "USR_COD" )
        MsgStop( "No se puede abrir la tabla de usuarios.", "Login" )
        RETURN .F.
    ENDIF

    DO WHILE !lSalir .AND. !lOK

        cUser := Space( 10 )
        cPass := Space( 32 )

        oWin := TWindow():New( 10, 40, 22, 90, "IDENTIFICACION DE USUARIO" )

        oLblUsr := TLabel():New( 2, 3, "Usuario :", oWin )
        oLblPas := TLabel():New( 4, 3, "Clave   :", oWin )

        oGetUsr := TGet():New( 2, 13, cUser, "@!", oWin )
        oGetUsr:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

        oGetPas := TGet():New( 4, 13, cPass, "@!", oWin )
        oGetPas:lPassword := .T.

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
                    IF FieldPos( "ULT_HORA" ) > 0
                        REPLACE USR->ULT_HORA WITH Time()
                    ENDIF
                    DbUnlock()
                ENDIF

                IF FieldPos( "CAMB_CL" ) > 0 .AND. USR->CAMB_CL
                    MsgInfo( "Debe cambiar la clave inicial antes de continuar.", ;
                             "Seguridad" )
                    IF !_ChangeOwnPassword( cUserID )
                        lOK    := .F.
                        lSalir := .T.
                    ENDIF
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
        IF _MasterPasswordValid( cUser, cPass )
            IF NetRLock()
                _LoginResetFailures()
                IF FieldPos( "CAMB_CL" ) > 0
                    REPLACE USR->CAMB_CL WITH .T.
                ENDIF
                REPLACE USR->BAJA WITH .F.
                DbCommit()
                DbUnlock()
            ENDIF
            AuditLog( "RECUPERA", "USUARIOS", cUser, ;
                      "Clave maestra usada; cambio obligatorio activado", .T. )
            lOK := .T.
            oWin:Close()
            RETURN NIL
        ENDIF

        IF USR->BAJA
            AuditLog( "LOGIN", "USUARIOS", cUser, "Usuario dado de baja", .F. )
            oLblErr:SetText( "  Usuario dado de baja." )
            RETURN NIL
        ENDIF

        IF UserPasswordValid( cPass )
            IF NetRLock()
                _LoginResetFailures()
                DbCommit()
                DbUnlock()
            ENDIF
            AuditLog( "LOGIN", "USUARIOS", cUser, "Acceso correcto", .T. )
            lOK := .T.
            oWin:Close()
            RETURN NIL
        ENDIF

        IF _LoginLockSecondsLeft() > 0
            AuditLog( "LOGIN", "USUARIOS", cUser, "Bloqueo temporal activo", .F. )
            oLblErr:SetText( "  Espere " + ;
                AllTrim( Str( _LoginLockMinutesLeft() ) ) + " min. o use clave correcta." )
            RETURN NIL
        ENDIF

        IF NetRLock()
            _LoginRegisterFailure()
            DbCommit()
            DbUnlock()
        ENDIF
    ENDIF

    AuditLog( "LOGIN", "USUARIOS", cUser, "Credenciales incorrectas", .F. )
    oLblErr:SetText( "  Usuario o clave incorrectos. Reintente." )

RETURN NIL


STATIC FUNCTION _LoginResetFailures()

    IF FieldPos( "INT_FAL" ) > 0
        REPLACE USR->INT_FAL WITH 0
    ENDIF
    IF FieldPos( "BLOQ_FEC" ) > 0
        REPLACE USR->BLOQ_FEC WITH CToD( "" )
    ENDIF
    IF FieldPos( "BLOQ_HOR" ) > 0
        REPLACE USR->BLOQ_HOR WITH Space( 8 )
    ENDIF

RETURN NIL


STATIC FUNCTION _LoginRegisterFailure()

    LOCAL nFails

    IF FieldPos( "INT_FAL" ) == 0
        RETURN NIL
    ENDIF

    nFails := USR->INT_FAL
    IF nFails >= LOGIN_MAX_FAILS .AND. _LoginLockSecondsLeft() <= 0
        nFails := 0
    ENDIF

    nFails++
    REPLACE USR->INT_FAL WITH nFails

    IF nFails >= LOGIN_MAX_FAILS
        IF FieldPos( "BLOQ_FEC" ) > 0
            REPLACE USR->BLOQ_FEC WITH Date()
        ENDIF
        IF FieldPos( "BLOQ_HOR" ) > 0
            REPLACE USR->BLOQ_HOR WITH Time()
        ENDIF
    ENDIF

RETURN NIL


STATIC FUNCTION _LoginLockSecondsLeft()

    LOCAL dBloq
    LOCAL cHor
    LOCAL nElapsed
    LOCAL nLeft

    IF FieldPos( "INT_FAL" ) == 0 .OR. USR->INT_FAL < LOGIN_MAX_FAILS
        RETURN 0
    ENDIF

    IF FieldPos( "BLOQ_FEC" ) == 0 .OR. FieldPos( "BLOQ_HOR" ) == 0
        RETURN 0
    ENDIF

    dBloq := USR->BLOQ_FEC
    cHor  := AllTrim( USR->BLOQ_HOR )
    IF Empty( dBloq ) .OR. Empty( cHor )
        RETURN 0
    ENDIF

    nElapsed := ( Date() - dBloq ) * 86400 + ;
                ( _TimeToSeconds( Time() ) - _TimeToSeconds( cHor ) )
    IF nElapsed < 0
        nElapsed := 0
    ENDIF

    nLeft := LOGIN_LOCK_SECONDS - nElapsed

RETURN Max( 0, nLeft )


STATIC FUNCTION _LoginLockMinutesLeft()
RETURN Max( 1, Int( ( _LoginLockSecondsLeft() + 59 ) / 60 ) )


STATIC FUNCTION _TimeToSeconds( cTime )
RETURN Val( SubStr( cTime, 1, 2 ) ) * 3600 + ;
       Val( SubStr( cTime, 4, 2 ) ) * 60 + ;
       Val( SubStr( cTime, 7, 2 ) )


STATIC FUNCTION _MasterPasswordValid( cUser, cPass )

    IF Upper( AllTrim( cUser ) ) != "ADMIN"
        RETURN .F.
    ENDIF

RETURN ( Upper( HB_SHA256( AllTrim( cPass ) ) ) == _MasterPasswordHash() )


STATIC FUNCTION _MasterPasswordHash()
RETURN "9CDD872AC3C6BAEB4863378EE9BCA364A310B3B0F933E12779C8C79F9BB317F3"


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


STATIC FUNCTION _ChangeOwnPassword( cUser )

    LOCAL oWin
    LOCAL oGP1
    LOCAL oGP2
    LOCAL oBtOk
    LOCAL oBtCan
    LOCAL cPass1 := Space( 20 )
    LOCAL cPass2 := Space( 20 )
    LOCAL lOK    := .F.

    oWin := TWindow():New( 10, 32, 24, 98, "CAMBIO OBLIGATORIO DE CLAVE" )

    oWin:AddCtrl( TLabel():New( 2, 3, "Nueva clave :", oWin ) )
    oWin:AddCtrl( TLabel():New( 4, 3, "Repetir     :", oWin ) )

    oGP1 := TGet():New( 2, 18, cPass1, "@!", oWin )
    oGP2 := TGet():New( 4, 18, cPass2, "@!", oWin )
    oGP1:lPassword := .T.
    oGP2:lPassword := .T.

    oGP1:bValid := {| o | Len( AllTrim( o:cBuffer ) ) >= 6 }
    oGP2:bValid := {| o | Len( AllTrim( o:cBuffer ) ) >= 6 }

    oBtOk := TButton():New( 8, 10, 9, 28, oWin, "GUARDAR", ;
        {|| _ChangeOwnPasswordSave( cUser, oGP1, oGP2, @lOK, oWin ) } )

    oBtCan := TButton():New( 8, 32, 9, 50, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGP1    )
    oWin:AddCtrl( oGP2    )
    oWin:AddCtrl( oBtOk   )
    oWin:AddCtrl( oBtCan  )

    oWin:Run()

RETURN lOK


STATIC FUNCTION _ChangeOwnPasswordSave( cUser, oGP1, oGP2, lOK, oWin )

    LOCAL cP1 := AllTrim( oGP1:uVar )
    LOCAL cP2 := AllTrim( oGP2:uVar )

    IF Len( cP1 ) < 6
        MsgStop( "La clave debe tener al menos 6 caracteres.", "Seguridad" )
        RETURN NIL
    ENDIF

    IF cP1 != cP2
        MsgStop( "Las claves no coinciden.", "Seguridad" )
        RETURN NIL
    ENDIF

    DbSelectArea( "USR" )
    OrdSetFocus( "USR_COD" )
    IF DbSeek( cUser )
        IF NetRLock()
            UserSetPassword( cUser, cP1 )
            REPLACE USR->CAMB_CL WITH .F.
            DbCommit()
            DbUnlock()
            AuditLog( "CLAVE", "USUARIOS", cUser, "Cambio obligatorio completado", .T. )
            lOK := .T.
            oWin:Close()
        ENDIF
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

    IF !RequirePerm( "SEG_ROL", "Mantenimiento de roles" )
        RETURN NIL
    ENDIF

    IF !ABRIR_TABLA( "ROLES", "ROLES", "ROLID" )
        RETURN NIL
    ENDIF

    aData := _RolesCargar()

    oWin  := TWindow():New( 5, 20, 32, 118, "MANTENIMIENTO DE ROLES" )
    oGrid := TGrid():New( 2, 2, 22, 94, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 1

    oGrid:AddColumn( "ID Rol",      6, "@!", { |a| a[1] } )
    oGrid:AddColumn( "Descripcion",30, "@!", { |a| a[2] } )
    oGrid:AddColumn( "Permisos",   42, "@!", { |a| a[3] } )
    oGrid:AddColumn( "Nivel",       3, "9",  { |a| a[4] } )
    oGrid:AddColumn( "Baja",        4, "@!", { |a| If( a[5], "SI", "NO" ) } )

    oGrid:bEnter := {| g | ;
        _RolForm( g:CurrentRow()[1] ), ;
        aData := _RolesCargar(), ;
        g:aData := aData, ;
        g:Paint() }

    oBtNvo := TButton():New( 24, 5, 25, 22, oWin, "NUEVO (F5)", ;
        {|| _RolForm( "" ), ;
            aData := _RolesCargar(), ;
            oGrid:aData := aData, ;
            oGrid:Paint() } )

    oBtSal := TButton():New( 24, 75, 25, 92, oWin, "CERRAR", ;
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
                AllTrim( ROLES->ID       ), ;
                AllTrim( ROLES->DESCRIP  ), ;
                _RolePermList( AllTrim( ROLES->ID ) ), ;
                ROLES->NIVEL, ;
                ROLES->BAJA } )
        ENDIF
        DbSkip()
    ENDDO

RETURN aData


STATIC FUNCTION _RolForm( cId )

    LOCAL oWin
    LOCAL oGetId
    LOCAL oGetDesc
    LOCAL oGetPerm
    LOCAL oGetNivel
    LOCAL oChkBaja
    LOCAL oBtAcep
    LOCAL oBtCanc
    LOCAL lNuevo
    LOCAL cTit
    LOCAL lOK
    LOCAL cIdEd
    LOCAL cDescEd
    LOCAL cPermEd
    LOCAL nNivel
    LOCAL lBaja

    lNuevo := Empty( AllTrim( cId ) )
    cTit   := If( lNuevo, "NUEVO ROL", "EDITAR ROL" )
    lOK    := .F.
    cIdEd  := PadR( cId, 3 )
    cDescEd:= Space( 30 )
    cPermEd:= Space( 120 )
    nNivel := 1
    lBaja  := .F.

    IF !lNuevo
        DbSelectArea( "ROLES" )
        OrdSetFocus( "ROLID" )
        IF DbSeek( AllTrim( cId ) )
            cDescEd := PadR( AllTrim( ROLES->DESCRIP ), 30 )
            cPermEd := PadR( _RolePermList( AllTrim( cId ) ), 120 )
            nNivel  := ROLES->NIVEL
            lBaja   := ROLES->BAJA
        ENDIF
    ENDIF

    oWin := TWindow():New( 8, 20, 26, 118, cTit )

    oWin:AddCtrl( TLabel():New( 2, 3, "ID Rol      :", oWin ) )
    oWin:AddCtrl( TLabel():New( 4, 3, "Descripcion :", oWin ) )
    oWin:AddCtrl( TLabel():New( 6, 3, "Permisos    :", oWin ) )
    oWin:AddCtrl( TLabel():New( 8, 3, "Nivel       :", oWin ) )

    oGetId := TGet():New( 2, 17, cIdEd, "@!", oWin )
    oGetId:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    IF !lNuevo
        oGetId:lEnabled := .F.
    ENDIF

    oGetDesc := TGet():New( 4, 17, cDescEd, "@!", oWin )
    oGetDesc:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGetPerm := TGet():New( 6, 17, cPermEd, "@!", oWin )
    oGetPerm:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGetNivel := TGet():New( 8, 17, nNivel, "9", oWin )
    oChkBaja  := TCheck():New( 10, 17, "Baja", lBaja, oWin )

    oBtAcep := TButton():New( 13, 8, 14, 24, oWin, "GUARDAR", ;
        {|| _RolGuardar( oGetId, oGetDesc, oGetPerm, oGetNivel, ;
                         oChkBaja, lNuevo, @lOK, oWin ) } )

    oBtCanc := TButton():New( 13, 28, 14, 44, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGetId   )
    oWin:AddCtrl( oGetDesc )
    oWin:AddCtrl( oGetPerm )
    oWin:AddCtrl( oGetNivel )
    oWin:AddCtrl( oChkBaja  )
    oWin:AddCtrl( oBtAcep  )
    oWin:AddCtrl( oBtCanc  )

    oWin:Run()

RETURN lOK


STATIC FUNCTION _RolGuardar( oGId, oGDesc, oGPerm, oGNivel, oChkBaja, lNuevo, lOK, oWin )

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
            REPLACE ROLES->ID       WITH cId
            REPLACE ROLES->DESCRIP  WITH cDesc
            REPLACE ROLES->NIVEL    WITH oGNivel:uVar
            REPLACE ROLES->BAJA     WITH oChkBaja:lValue
            DbCommit()
            DbUnlock()
            _RolePermSave( cId, AllTrim( oGPerm:uVar ) )
            AuditLog( "ALTA", "ROLES", cId, "Rol creado", .T. )
            lOK := .T.
            oWin:Close()
        ENDIF
    ELSE
        IF DbSeek( cId )
            IF NetRLock()
                REPLACE ROLES->DESCRIP  WITH cDesc
                REPLACE ROLES->NIVEL    WITH oGNivel:uVar
                REPLACE ROLES->BAJA     WITH oChkBaja:lValue
                DbCommit()
                DbUnlock()
                _RolePermSave( cId, AllTrim( oGPerm:uVar ) )
                AuditLog( "MODIF", "ROLES", cId, "Rol actualizado", .T. )
                lOK := .T.
                oWin:Close()
            ENDIF
        ENDIF
    ENDIF

RETURN NIL


// ============================================================================
// Migracion fisica de tablas de seguridad
// ============================================================================
STATIC FUNCTION _EnsureUsuariosSchema()

    LOCAL aStru := {}
    LOCAL aIdx  := {}

    AAdd( aStru, { "CODIGO",   "C", 10, 0 } )
    AAdd( aStru, { "NOMBRE",   "C", 40, 0 } )
    AAdd( aStru, { "ROLID",    "C",  3, 0 } )
    AAdd( aStru, { "NIVEL",    "N",  1, 0 } )
    AAdd( aStru, { "FECHA_AL", "D",  8, 0 } )
    AAdd( aStru, { "ULT_ACCE", "D",  8, 0 } )
    AAdd( aStru, { "ULT_HORA", "C",  8, 0 } )
    AAdd( aStru, { "BAJA",     "L",  1, 0 } )
    AAdd( aStru, { "CLAVE_H",  "C", 64, 0 } )
    AAdd( aStru, { "SALT",     "C", 32, 0 } )
    AAdd( aStru, { "CAMB_CL",  "L",  1, 0 } )
    AAdd( aStru, { "FEC_CL",   "D",  8, 0 } )
    AAdd( aStru, { "INT_FAL",  "N",  3, 0 } )
    AAdd( aStru, { "BLOQ_FEC", "D",  8, 0 } )
    AAdd( aStru, { "BLOQ_HOR", "C",  8, 0 } )

    AAdd( aIdx, { "USR_COD", "CODIGO" } )
    AAdd( aIdx, { "USR_NOM", "Upper(NOMBRE)" } )

RETURN _EnsureDbfSchema( "USUARIOS", aStru, aIdx )


STATIC FUNCTION _EnsureRolesSchema()

    LOCAL aStru := {}
    LOCAL aIdx  := {}

    AAdd( aStru, { "ID",       "C",   3, 0 } )
    AAdd( aStru, { "DESCRIP",  "C",  30, 0 } )
    AAdd( aStru, { "NIVEL",    "N",   1, 0 } )
    AAdd( aStru, { "BAJA",     "L",   1, 0 } )

    AAdd( aIdx, { "ROLID", "ID" } )

RETURN _EnsureDbfSchema( "ROLES", aStru, aIdx )


STATIC FUNCTION _EnsureRolPermSchema()

    LOCAL aStru := {}
    LOCAL aIdx  := {}

    AAdd( aStru, { "ROLID",    "C",  3, 0 } )
    AAdd( aStru, { "PERMISO",  "C", 20, 0 } )
    AAdd( aStru, { "DESCRIP",  "C", 60, 0 } )
    AAdd( aStru, { "BAJA",     "L",  1, 0 } )

    AAdd( aIdx, { "RPM_ROL", "ROLID+PERMISO" } )
    AAdd( aIdx, { "RPM_PER", "PERMISO+ROLID" } )

RETURN _EnsureDbfSchema( "ROL_PERM", aStru, aIdx )


STATIC FUNCTION _EnsureAuditSchema()

    LOCAL aStru := {}
    LOCAL aIdx  := {}

    AAdd( aStru, { "ID",      "C", 18, 0 } )
    AAdd( aStru, { "FECHA",   "D",  8, 0 } )
    AAdd( aStru, { "HORA",    "C",  8, 0 } )
    AAdd( aStru, { "USUARIO", "C", 10, 0 } )
    AAdd( aStru, { "ROL",     "C",  3, 0 } )
    AAdd( aStru, { "ACCION",  "C", 20, 0 } )
    AAdd( aStru, { "TABLA",   "C", 12, 0 } )
    AAdd( aStru, { "CLAVE",   "C", 30, 0 } )
    AAdd( aStru, { "DETALLE", "C",120, 0 } )
    AAdd( aStru, { "EQUIPO",  "C", 30, 0 } )
    AAdd( aStru, { "OK",      "L",  1, 0 } )

    AAdd( aIdx, { "AUD_ID",  "ID" } )
    AAdd( aIdx, { "AUD_FEC", "DtoS(FECHA)+HORA" } )
    AAdd( aIdx, { "AUD_USR", "USUARIO+DtoS(FECHA)" } )

RETURN _EnsureDbfSchema( "AUDITLOG", aStru, aIdx )


STATIC FUNCTION _EnsureDbfSchema( cDbf, aRequired, aIdx )

    LOCAL aOld
    LOCAL lMismatch := .F.
    LOCAL i
    LOCAL cTmp
    LOCAL cFld
    LOCAL nNewPos
    LOCAL nOldPos

    IF !File( cDbf + ".DBF" )
        DbCreate( cDbf, aRequired )
        _CreateIndexes( cDbf, aIdx )
        RETURN .T.
    ENDIF

    USE (cDbf) NEW EXCLUSIVE ALIAS OLD_SEC
    IF NetErr()
        RETURN .F.
    ENDIF

    aOld := DbStruct()

    IF Len( aOld ) != Len( aRequired )
        lMismatch := .T.
    ELSE
        FOR i := 1 TO Len( aRequired )
            IF aOld[i, 1] != aRequired[i, 1] .OR. ;
               aOld[i, 2] != aRequired[i, 2] .OR. ;
               aOld[i, 3] != aRequired[i, 3] .OR. ;
               aOld[i, 4] != aRequired[i, 4]
                lMismatch := .T.
                EXIT
            ENDIF
        NEXT
    ENDIF

    IF !lMismatch
        OLD_SEC->( DbCloseArea() )
        _CreateIndexes( cDbf, aIdx )
        RETURN .T.
    ENDIF

    cTmp := cDbf + "_NEW"
    IF File( cTmp + ".DBF" )
        FErase( cTmp + ".DBF" )
    ENDIF
    IF File( cTmp + ".CDX" )
        FErase( cTmp + ".CDX" )
    ENDIF

    DbCreate( cTmp, aRequired )
    USE (cTmp) NEW EXCLUSIVE ALIAS NEW_SEC
    IF NetErr()
        OLD_SEC->( DbCloseArea() )
        RETURN .F.
    ENDIF

    OLD_SEC->( DbGoTop() )
    DO WHILE !OLD_SEC->( Eof() )
        NEW_SEC->( DbAppend() )
        FOR i := 1 TO Len( aRequired )
            cFld    := aRequired[i, 1]
            nOldPos := OLD_SEC->( FieldPos( cFld ) )
            nNewPos := NEW_SEC->( FieldPos( cFld ) )
            IF nOldPos > 0 .AND. nNewPos > 0
                NEW_SEC->( FieldPut( nNewPos, OLD_SEC->( FieldGet( nOldPos ) ) ) )
            ENDIF
        NEXT
        OLD_SEC->( DbSkip() )
    ENDDO

    NEW_SEC->( DbCloseArea() )
    OLD_SEC->( DbCloseArea() )

    IF File( cDbf + ".BAK" )
        FErase( cDbf + ".BAK" )
    ENDIF
    IF File( cDbf + ".CDX" )
        FErase( cDbf + ".CDX" )
    ENDIF

    FRename( cDbf + ".DBF", cDbf + ".BAK" )
    FRename( cTmp + ".DBF", cDbf + ".DBF" )

    _CreateIndexes( cDbf, aIdx )

RETURN .T.


STATIC FUNCTION _CreateIndexes( cDbf, aIdx )

    LOCAL oIdx

    IF Len( aIdx ) == 0
        RETURN NIL
    ENDIF

    IF File( cDbf + ".CDX" )
        FErase( cDbf + ".CDX" )
    ENDIF

    USE (cDbf) NEW EXCLUSIVE ALIAS IDX_SEC
    IF !NetErr()
        FOR EACH oIdx IN aIdx
            OrdCreate( cDbf + ".CDX", oIdx[1], oIdx[2] )
        NEXT
        IDX_SEC->( DbCloseArea() )
    ENDIF

RETURN NIL


STATIC FUNCTION _SeedRoles()

    IF !ABRIR_TABLA( "ROLES", "ROL_SEED", "ROLID" )
        RETURN NIL
    ENDIF

    _UpsertRol( "ADM",  "Administrador", 9 )
    _UpsertRol( "CONT", "Contabilidad",  5 )
    _UpsertRol( "CAJA", "Caja",          4 )

    ROL_SEED->( DbCloseArea() )

    _RolePermSave( "ADM",  "*" )
    _RolePermSave( "CONT", "CONT,INFO" )
    _RolePermSave( "CAJA", "TESO,INFO" )

RETURN NIL


STATIC FUNCTION _UpsertRol( cId, cDesc, nNivel )

    DbSelectArea( "ROL_SEED" )
    OrdSetFocus( "ROLID" )

    IF DbSeek( cId )
        IF NetRLock()
            IF ROL_SEED->NIVEL == 0
                REPLACE ROL_SEED->NIVEL WITH nNivel
            ENDIF
            DbCommit()
            DbUnlock()
        ENDIF
    ELSE
        IF NetFLock()
            DbAppend()
            REPLACE ROL_SEED->ID       WITH cId
            REPLACE ROL_SEED->DESCRIP  WITH cDesc
            REPLACE ROL_SEED->NIVEL    WITH nNivel
            REPLACE ROL_SEED->BAJA     WITH .F.
            DbCommit()
            DbUnlock()
        ENDIF
    ENDIF

RETURN NIL


STATIC FUNCTION _RolePermList( cRol )

    LOCAL cPerms := ""
    LOCAL nArea  := Select()

    IF ABRIR_TABLA( "ROL_PERM", "RPM_LST", "RPM_ROL" )
        DbSelectArea( "RPM_LST" )
        DbGoTop()
        DO WHILE !Eof()
            IF !Deleted() .AND. !RPM_LST->BAJA .AND. ;
               AllTrim( RPM_LST->ROLID ) == AllTrim( cRol )
                IF !Empty( cPerms )
                    cPerms += ","
                ENDIF
                cPerms += AllTrim( RPM_LST->PERMISO )
            ENDIF
            DbSkip()
        ENDDO
        RPM_LST->( DbCloseArea() )
    ENDIF

    Select( nArea )

RETURN cPerms


STATIC FUNCTION _RolePermSave( cRol, cPerms )

    LOCAL aPerms
    LOCAL cPerm
    LOCAL i
    LOCAL nArea := Select()

    DEFAULT cPerms TO ""

    IF !ABRIR_TABLA( "ROL_PERM", "RPM_SAV", "RPM_ROL" )
        Select( nArea )
        RETURN .F.
    ENDIF

    DbSelectArea( "RPM_SAV" )
    DbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. AllTrim( RPM_SAV->ROLID ) == AllTrim( cRol )
            IF NetRLock()
                REPLACE RPM_SAV->BAJA WITH .T.
                DbCommit()
                DbUnlock()
            ENDIF
        ENDIF
        DbSkip()
    ENDDO

    aPerms := ASPLIT( Upper( AllTrim( cPerms ) ), "," )

    FOR i := 1 TO Len( aPerms )
        cPerm := AllTrim( aPerms[i] )
        IF Empty( cPerm )
            LOOP
        ENDIF

        IF NetFLock()
            DbAppend()
            REPLACE RPM_SAV->ROLID   WITH PadR( AllTrim( cRol ), 3 )
            REPLACE RPM_SAV->PERMISO WITH PadR( cPerm, 20 )
            REPLACE RPM_SAV->DESCRIP WITH PadR( _PermDesc( cPerm ), 60 )
            REPLACE RPM_SAV->BAJA    WITH .F.
            DbCommit()
            DbUnlock()
        ENDIF
    NEXT

    RPM_SAV->( DbCloseArea() )
    Select( nArea )

RETURN .T.


STATIC FUNCTION _PermDesc( cPerm )

    LOCAL cDesc := cPerm

    DO CASE
    CASE cPerm == "*"
        cDesc := "Acceso total"
    CASE cPerm == "SEG_USR"
        cDesc := "Mantenimiento de usuarios"
    CASE cPerm == "SEG_ROL"
        cDesc := "Mantenimiento de roles"
    CASE cPerm == "SEG_REINDEX"
        cDesc := "Reindexar tablas"
    CASE cPerm == "CONT"
        cDesc := "Contabilidad"
    CASE cPerm == "TESO"
        cDesc := "Tesoreria"
    CASE cPerm == "INFO"
        cDesc := "Informes"
    ENDCASE

RETURN cDesc


STATIC FUNCTION _EnsureAdminPassword()

    IF !ABRIR_TABLA( "USUARIOS", "USR_BOOT", "USR_COD" )
        RETURN NIL
    ENDIF

    DbSelectArea( "USR_BOOT" )
    OrdSetFocus( "USR_COD" )

    IF LastRec() == 0
        IF NetFLock()
            DbAppend()
            REPLACE USR_BOOT->CODIGO   WITH "ADMIN"
            REPLACE USR_BOOT->NOMBRE   WITH "Administrador"
            REPLACE USR_BOOT->ROLID    WITH "ADM"
            REPLACE USR_BOOT->NIVEL    WITH 9
            REPLACE USR_BOOT->FECHA_AL WITH Date()
            REPLACE USR_BOOT->ULT_ACCE WITH Date()
            REPLACE USR_BOOT->ULT_HORA WITH Time()
            REPLACE USR_BOOT->BAJA     WITH .F.
            UserSetPassword( "ADMIN", "1234" )
            REPLACE USR_BOOT->CAMB_CL WITH .T.
            DbCommit()
            DbUnlock()
        ENDIF
    ELSEIF DbSeek( "ADMIN" ) .AND. Empty( USR_BOOT->CLAVE_H )
        IF NetRLock()
            UserSetPassword( "ADMIN", "1234" )
            REPLACE USR_BOOT->CAMB_CL WITH .T.
            DbCommit()
            DbUnlock()
        ENDIF
    ENDIF

    USR_BOOT->( DbCloseArea() )

RETURN NIL


// ============================================================================
// FIN DE Seguridad.prg
// ============================================================================
