/*
 * ARCHIVO  : AdminRecovery.prg
 * PROPOSITO: Recuperar acceso ADMIN sin entrar en la aplicacion.
 *
 * USO:
 *   AdminRecovery.exe
 *
 * Resultado:
 *   ADMIN queda con clave temporal 1234, desbloqueado y con cambio obligatorio.
 */

REQUEST DBFCDX

FUNCTION Main()

    LOCAL cDataDir := ".\DATA"

    SET DATE BRIT
    SET DATE FORMAT TO "DD/MM/YYYY"
    SET EPOCH TO 1950
    SET CENTURY ON
    SET DELETED ON
    SET EXACT ON

    rddSetDefault( "DBFCDX" )

    IF !DirExiste( cDataDir )
        ? "ERROR: No existe la carpeta DATA."
        RETURN NIL
    ENDIF

    SET DEFAULT TO (cDataDir)

    IF !File( "USUARIOS.DBF" )
        ? "ERROR: No existe DATA\USUARIOS.DBF."
        RETURN NIL
    ENDIF

    USE USUARIOS NEW EXCLUSIVE ALIAS USR_REC
    IF NetErr()
        ? "ERROR: No se pudo abrir USUARIOS en exclusivo."
        ? "Cierre AppGestion.exe y vuelva a ejecutar AdminRecovery.exe."
        RETURN NIL
    ENDIF

    IF !_SeekAdmin()
        DbAppend()
        REPLACE USR_REC->CODIGO WITH PadR( "ADMIN", 10 )
        IF FieldPos( "NOMBRE" ) > 0
            REPLACE USR_REC->NOMBRE WITH PadR( "Administrador", 40 )
        ENDIF
        IF FieldPos( "ROLID" ) > 0
            REPLACE USR_REC->ROLID WITH PadR( "ADM", 3 )
        ENDIF
        IF FieldPos( "NIVEL" ) > 0
            REPLACE USR_REC->NIVEL WITH 9
        ENDIF
        IF FieldPos( "FECHA_AL" ) > 0
            REPLACE USR_REC->FECHA_AL WITH Date()
        ENDIF
    ENDIF

    IF RLock()
        _SetAdminPassword( "1234" )
        _ClearAdminLock()
        DbCommit()
        DbUnlock()
        ? "ADMIN recuperado correctamente."
        ? "Clave temporal: 1234"
        ? "Al entrar, el sistema pedira cambiarla."
    ELSE
        ? "ERROR: No se pudo bloquear el registro ADMIN."
    ENDIF

    USE

RETURN NIL


STATIC FUNCTION _SeekAdmin()

    DbGoTop()
    DO WHILE !Eof()
        IF !Deleted() .AND. Upper( AllTrim( USR_REC->CODIGO ) ) == "ADMIN"
            RETURN .T.
        ENDIF
        DbSkip()
    ENDDO

RETURN .F.


STATIC FUNCTION _SetAdminPassword( cPassword )

    LOCAL cSalt
    LOCAL cHash

    cSalt := _UserNewSalt( "ADMIN" )
    cHash := _UserPasswordHash( cPassword, cSalt )

    IF FieldPos( "SALT" ) > 0
        REPLACE USR_REC->SALT WITH cSalt
    ENDIF
    IF FieldPos( "CLAVE_H" ) > 0
        REPLACE USR_REC->CLAVE_H WITH cHash
    ENDIF
    IF FieldPos( "FEC_CL" ) > 0
        REPLACE USR_REC->FEC_CL WITH Date()
    ENDIF
    IF FieldPos( "CAMB_CL" ) > 0
        REPLACE USR_REC->CAMB_CL WITH .T.
    ENDIF

RETURN NIL


STATIC FUNCTION _ClearAdminLock()

    IF FieldPos( "BAJA" ) > 0
        REPLACE USR_REC->BAJA WITH .F.
    ENDIF
    IF FieldPos( "INT_FAL" ) > 0
        REPLACE USR_REC->INT_FAL WITH 0
    ENDIF
    IF FieldPos( "BLOQ_FEC" ) > 0
        REPLACE USR_REC->BLOQ_FEC WITH CToD( "" )
    ENDIF
    IF FieldPos( "BLOQ_HOR" ) > 0
        REPLACE USR_REC->BLOQ_HOR WITH Space( 8 )
    ENDIF
    IF FieldPos( "ULT_ACCE" ) > 0
        REPLACE USR_REC->ULT_ACCE WITH Date()
    ENDIF
    IF FieldPos( "ULT_HORA" ) > 0
        REPLACE USR_REC->ULT_HORA WITH Time()
    ENDIF

RETURN NIL


STATIC FUNCTION _UserPasswordHash( cPassword, cSalt )

    LOCAL cHash
    LOCAL i

    cHash := HB_SHA256( AllTrim( cSalt ) + ":" + cPassword )
    FOR i := 1 TO 499
        cHash := HB_SHA256( AllTrim( cSalt ) + ":" + cHash )
    NEXT

RETURN cHash


STATIC FUNCTION _UserNewSalt( cUser )
RETURN Left( HB_SHA256( AllTrim( cUser ) + DToS( Date() ) + Time() + ;
                        AllTrim( Str( Seconds() * 1000 ) ) ), 32 )


STATIC FUNCTION DirExiste( cDir )
RETURN Directory( cDir, "D" ) != NIL .AND. Len( Directory( cDir, "D" ) ) > 0
