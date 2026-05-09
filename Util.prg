/*
 * ARCHIVO  : Util.prg
 * PROPOSITO: Utilidades generales del sistema.
 *
 * CONTENIDO
 * ---------
 * 1) REQUEST / InitApp   - Arranque del entorno WVG
 * 2) ErrSys              - Manejador de errores criticos (log)
 * 3) ABRIR_TABLA         - Apertura segura de DBF con reintento
 * 4) NetFLock / NetRLock / NetUnLock - Bloqueos de red con reintento
 * 5) GetNextNum          - Contador correlativo de documentos
 * 6) Utilidades genericas: DirExiste, MiDefault, IsDbUsed,
 *                          GetDbArea, ASPLIT, CEILING, ArraySkip
 *
 * NOTA: MsgBox, MsgInfo y MsgStop estan en API\MsgBox.prg
 *       MsgYesNo y MsgConfirm estan en API\MsgYesNo.prg
 */

#include "OOp.ch"
#include "inkey.ch"
#include "fileio.ch"

STATIC s_nAppLockHandle := -1
STATIC s_cAppLockFile   := ""

// ============================================================================
// 1) REQUEST / InitApp
// ============================================================================

REQUEST DBFCDX

// ----------------------------------------------------------------------------
// InitApp( nRows, nCols, cFont, nFontH, nFontW )
// Inicializa el entorno grafico WVG. Llamar desde Main() antes de todo.
// ----------------------------------------------------------------------------
FUNCTION InitApp( nRows, nCols, cFont, nFontH, nFontW )

    DEFAULT nRows  TO 40
    DEFAULT nCols  TO 132
    DEFAULT cFont  TO "Lucida Console"
    DEFAULT nFontH TO 16
    DEFAULT nFontW TO 8

    rddSetDefault( "DBFCDX" )

    GfxSetFont( cFont, nFontH, nFontW )

    SetMode( nRows, nCols )

    GfxFixSize( .T. )

    SetColor( CLR_WINDOW )
    CLS

    GfxCursor( SC_NONE )

RETURN NIL


// ----------------------------------------------------------------------------
// AppLockAcquire()
// Evita que AppGestion se ejecute mas de una vez en el mismo terminal.
// Usa un archivo de bloqueo por equipo/usuario y mantiene el handle abierto
// en modo exclusivo hasta AppLockRelease().
// ----------------------------------------------------------------------------
FUNCTION AppLockAcquire()

    LOCAL cDir
    LOCAL cKey
    LOCAL cFile
    LOCAL nTmp

    IF s_nAppLockHandle >= 0
        RETURN .T.
    ENDIF

    cDir := AllTrim( GetEnv( "TEMP" ) )
    IF Empty( cDir )
        cDir := AllTrim( GetEnv( "TMP" ) )
    ENDIF
    IF Empty( cDir )
        cDir := "."
    ENDIF

    cKey  := _AppLockToken( GetEnv( "COMPUTERNAME" ) + "_" + GetEnv( "USERNAME" ) )
    IF Empty( cKey )
        cKey := "TERMINAL"
    ENDIF

    cFile := _AppPathAddSep( cDir ) + "AppGestion_" + cKey + ".lck"

    IF !File( cFile )
        nTmp := FCreate( cFile, FC_NORMAL )
        IF nTmp >= 0
            FClose( nTmp )
        ENDIF
    ENDIF

    s_nAppLockHandle := FOpen( cFile, FO_READWRITE + FO_EXCLUSIVE )
    IF s_nAppLockHandle < 0
        RETURN .F.
    ENDIF

    s_cAppLockFile := cFile
    FSeek( s_nAppLockHandle, 0 )
    FWrite( s_nAppLockHandle, ;
            "AppGestion en ejecucion" + hb_Eol() + ;
            "Equipo : " + GetEnv( "COMPUTERNAME" ) + hb_Eol() + ;
            "Usuario: " + GetEnv( "USERNAME" ) + hb_Eol() + ;
            "Fecha  : " + DToC( Date() ) + " " + Time() + hb_Eol() )

RETURN .T.


FUNCTION AppLockRelease()

    IF s_nAppLockHandle >= 0
        FClose( s_nAppLockHandle )
        s_nAppLockHandle := -1
    ENDIF

    IF !Empty( s_cAppLockFile ) .AND. File( s_cAppLockFile )
        BEGIN SEQUENCE
            FErase( s_cAppLockFile )
        RECOVER
        END SEQUENCE
    ENDIF
    s_cAppLockFile := ""

RETURN NIL


FUNCTION ErrorLogAppend( cText )

    LOCAL nH

    DEFAULT cText TO ""

    IF Empty( cText )
        RETURN .F.
    ENDIF

    nH := FOpen( "error.log", FO_READWRITE + FO_DENYNONE )
    IF nH < 0
        nH := FCreate( "error.log", FC_NORMAL )
    ENDIF

    IF nH < 0
        RETURN .F.
    ENDIF

    FSeek( nH, 0, FS_END )
    FWrite( nH, cText )
    IF Right( cText, Len( hb_Eol() ) ) != hb_Eol()
        FWrite( nH, hb_Eol() )
    ENDIF
    FClose( nH )

RETURN .T.


STATIC FUNCTION _AppPathAddSep( cPath )

    cPath := AllTrim( cPath )

    IF Empty( cPath )
        RETURN ".\"
    ENDIF

    IF Right( cPath, 1 ) $ "\/"
        RETURN cPath
    ENDIF

RETURN cPath + "\"


STATIC FUNCTION _AppLockToken( cText )

    LOCAL cOut := ""
    LOCAL i
    LOCAL cCh

    cText := Upper( AllTrim( cText ) )

    FOR i := 1 TO Len( cText )
        cCh := SubStr( cText, i, 1 )
        IF ( cCh >= "A" .AND. cCh <= "Z" ) .OR. ;
           ( cCh >= "0" .AND. cCh <= "9" ) .OR. ;
           cCh == "_" .OR. cCh == "-"
            cOut += cCh
        ELSE
            cOut += "_"
        ENDIF
    NEXT

RETURN cOut


// ============================================================================
// 2) MANEJADOR DE ERRORES CRITICOS
// ============================================================================

// ----------------------------------------------------------------------------
// ErrSys( oErr )
// Solo escribe en error.log y sale. NO pinta en pantalla.
// Uso: ErrorBlock( { |e| ErrSys( e ) } ) desde Main()
// ----------------------------------------------------------------------------
FUNCTION ErrSys( oErr )

    STATIC lProc := .F.
    LOCAL cMsg     := ""
    LOCAL cLog     := ""
    LOCAL cArgs    := ""
    LOCAL nI       := 2
    LOCAL i

    IF lProc
        ErrorLevel( 2 )
        QUIT
    ENDIF
    lProc := .T.

    ErrorBlock( { |e| Break( e ) } )

    cMsg := "ERROR DE EJECUCION" + hb_Eol()
    BEGIN SEQUENCE
        cMsg += "Subsistema  : " + hb_ValToStr( oErr:SubSystem )   + hb_Eol()
        cMsg += "Codigo      : " + hb_ValToStr( oErr:SubCode )     + hb_Eol()
        cMsg += "Operacion   : " + hb_ValToStr( oErr:Operation )   + hb_Eol()
        cMsg += "Descripcion : " + hb_ValToStr( oErr:Description ) + hb_Eol()
        cMsg += "Severidad   : " + hb_ValToStr( oErr:Severity )    + hb_Eol()
        cMsg += "CanRetry    : " + hb_ValToStr( oErr:CanRetry )    + hb_Eol()
        IF !Empty( oErr:FileName )
            cMsg += "Fichero     : " + hb_ValToStr( oErr:FileName ) + hb_Eol()
        ENDIF
        IF !Empty( oErr:OsCode )
            cMsg += "OS code     : " + hb_ValToStr( oErr:OsCode )  + hb_Eol()
        ENDIF
    RECOVER
        cMsg += "(no se pudieron leer todos los campos del error)" + hb_Eol()
    END SEQUENCE

    BEGIN SEQUENCE
        IF HB_ISARRAY( oErr:Args )
            cArgs := "Argumentos:" + hb_Eol()
            FOR i := 1 TO Len( oErr:Args )
                cArgs += "  [" + AllTrim( Str( i ) ) + "] " + ;
                         hb_ValToStr( oErr:Args[ i ] ) + hb_Eol()
            NEXT
        ENDIF
    RECOVER
        cArgs := "(argumentos no accesibles)" + hb_Eol()
    END SEQUENCE

    cLog := Replicate( "=", 70 ) + hb_Eol()
    cLog += "FECHA: " + DToC( Date() ) + " HORA: " + Time() + hb_Eol()
    cLog += cMsg
    IF !Empty( cArgs )
        cLog += cArgs
    ENDIF

    cLog += "Pila de llamadas:" + hb_Eol()
    DO WHILE !Empty( ProcName( nI ) )
        cLog += "  " + PadR( ProcFile( nI ), 24 ) + ;
                " -> " + PadR( ProcName( nI ), 30 ) + ;
                " (linea " + AllTrim( Str( ProcLine( nI ) ) ) + ")" + hb_Eol()
        nI++
        IF nI > 50
            EXIT
        ENDIF
    ENDDO

    ErrorLogAppend( cLog )

    BEGIN SEQUENCE
        dbCloseAll()
        AppLockRelease()
    RECOVER
    END SEQUENCE

    ErrorLevel( 1 )
    QUIT

RETURN NIL


// ============================================================================
// 3) APERTURA SEGURA DE TABLAS
// ============================================================================

// ----------------------------------------------------------------------------
// ABRIR_TABLA( cArchivo, cAlias, cIndice )
// ----------------------------------------------------------------------------
FUNCTION ABRIR_TABLA( cArchivo, cAlias, cIndice )

    LOCAL lReintentar := .T.

    DEFAULT cAlias TO cArchivo

    IF DBUSED( cAlias )
        DbSelectArea( cAlias )
        IF !Empty( cIndice )
            OrdSetFocus( cIndice )
        ENDIF
        RETURN .T.
    ENDIF

    DO WHILE lReintentar
        DbUseArea( .T., "DBFCDX", cArchivo, cAlias, .T., .F. )
        IF NetErr()
            IF MsgYesNo( "Archivo " + cArchivo + " bloqueado. Reintentar?", ;
                         "Error de acceso" )
                LOOP
            ELSE
                RETURN .F.
            ENDIF
        ELSE
            lReintentar := .F.
        ENDIF
    ENDDO

    IF !Empty( cIndice )
        OrdSetFocus( cIndice )
    ENDIF

    DbGoTop()

RETURN .T.


// ============================================================================
// 4) BLOQUEOS DE RED
// ============================================================================

FUNCTION NetFLock()

    LOCAL nIntentos := 0

    IF FLock()
        RETURN .T.
    ENDIF

    DO WHILE !FLock()
        nIntentos++
        Inkey( 0.5 )
        IF nIntentos > 6
            IF MsgYesNo( "Archivo ocupado. Reintentar?", "Bloqueo" )
                nIntentos := 0
            ELSE
                RETURN .F.
            ENDIF
        ENDIF
    ENDDO

RETURN .T.


FUNCTION NetRLock()

    LOCAL nIntentos := 0

    IF RLock()
        RETURN .T.
    ENDIF

    DO WHILE !RLock()
        nIntentos++
        Inkey( 0.5 )
        IF nIntentos > 6
            IF MsgYesNo( "Registro ocupado. Reintentar?", "Bloqueo" )
                nIntentos := 0
            ELSE
                RETURN .F.
            ENDIF
        ENDIF
    ENDDO

RETURN .T.


FUNCTION NetUnLock()
    DbUnlock()
RETURN NIL


// ============================================================================
// 5) CONTADOR CORRELATIVO DE DOCUMENTOS
// ============================================================================

FUNCTION GetNextNum( cCodDoc, cDescrip )

    LOCAL cProxCod := ""
    LOCAL nAreaIni := Select()
    LOCAL cPrefijo := ""
    LOCAL nUltNum  := 0
    LOCAL nDigitos := 7
    LOCAL cUsuario := "SISTEMA"

    MEMVAR cUserID

    IF ValType( cCodDoc ) != "C" .OR. Empty( cCodDoc )
        MsgStop( "GetNextNum: falta el codigo de documento.", "Contador" )
        RETURN ""
    ENDIF

    cCodDoc := PadR( AllTrim( Upper( cCodDoc ) ), 3 )

    IF !ABRIR_TABLA( "CONTADOR", "CON", "COD_DOC" )
        MsgStop( "No se puede acceder al contador.", "Error critico" )
        Select( nAreaIni )
        RETURN ""
    ENDIF

    DbSelectArea( "CON" )
    OrdSetFocus( "COD_DOC" )

    IF DbSeek( cCodDoc )

        IF !NetRLock()
            CON->( DbCloseArea() )
            Select( nAreaIni )
            RETURN ""
        ENDIF

        cPrefijo := AllTrim( CON->PREFIJO )
        nUltNum  := CON->ULT_NUM
        nDigitos := If( CON->DIGITOS > 0, CON->DIGITOS, 7 )

    ELSE

        cPrefijo := _PrefijoEmp()

        IF !NetFLock()
            CON->( DbCloseArea() )
            Select( nAreaIni )
            RETURN ""
        ENDIF

        DbAppend()
        REPLACE CON->COD_DOC WITH cCodDoc
        REPLACE CON->DESCRIP WITH If( ValType( cDescrip ) == "C", cDescrip, "" )
        REPLACE CON->PREFIJO WITH cPrefijo
        REPLACE CON->DIGITOS WITH nDigitos

    ENDIF

    nUltNum++
    cProxCod := cPrefijo + StrZero( nUltNum, nDigitos )

    IF Type( "cUserID" ) == "C" .AND. !Empty( cUserID )
        cUsuario := PadR( AllTrim( cUserID ), 10 )
    ENDIF

    REPLACE CON->ULT_NUM WITH nUltNum
    REPLACE CON->ULT_USR WITH cUsuario
    REPLACE CON->ULT_FEC WITH Date()
    REPLACE CON->ULT_HOR WITH Time()

    DbCommit()
    DbUnlock()
    CON->( DbCloseArea() )

    Select( nAreaIni )

RETURN cProxCod


STATIC FUNCTION _PrefijoEmp()

    LOCAL cPref  := ""
    LOCAL nArea  := Select()

    IF Select( "EMPRESA" ) > 0
        cPref := AllTrim( EMPRESA->PREFIJO )
    ELSE
        IF ABRIR_TABLA( "EMPRESA", "TMP_EMP", "" )
            cPref := AllTrim( TMP_EMP->PREFIJO )
            TMP_EMP->( DbCloseArea() )
        ENDIF
    ENDIF

    Select( nArea )

RETURN cPref


// ============================================================================
// 6) UTILIDADES GENERICAS
// ============================================================================

FUNCTION DirExiste( cRuta )

    LOCAL cMask
    LOCAL aDir

    IF Right( cRuta, 1 ) $ "\/"
        cRuta := Left( cRuta, Len( cRuta ) - 1 )
    ENDIF

    cMask := cRuta + "\*.*"
    aDir  := Directory( cMask, "D" )

RETURN ( Len( aDir ) > 0 )


FUNCTION MiDefault( xVar, xDefecto )
RETURN If( xVar == NIL, xDefecto, xVar )


FUNCTION IsDbUsed( cAlias )
RETURN DBUSED( cAlias )


FUNCTION DBUSED( cAlias )

    IF ValType( cAlias ) != "C" .OR. Empty( AllTrim( cAlias ) )
        RETURN .F.
    ENDIF

RETURN ( Select( AllTrim( cAlias ) ) > 0 )


FUNCTION DbFieldValue( cField, xDefault )

    LOCAL nPos

    DEFAULT xDefault TO NIL

    IF ValType( cField ) != "C" .OR. Empty( AllTrim( cField ) )
        RETURN xDefault
    ENDIF

    nPos := FieldPos( AllTrim( cField ) )
    IF nPos == 0
        RETURN xDefault
    ENDIF

RETURN FieldGet( nPos )


FUNCTION DbFieldPutIf( cField, xValue )

    LOCAL nPos

    IF ValType( cField ) != "C" .OR. Empty( AllTrim( cField ) )
        RETURN .F.
    ENDIF

    nPos := FieldPos( AllTrim( cField ) )
    IF nPos == 0
        RETURN .F.
    ENDIF

    FieldPut( nPos, xValue )

RETURN .T.


FUNCTION GetDbArea( cAlias )

    IF ValType( cAlias ) != "C" .OR. Empty( cAlias )
        RETURN 0
    ENDIF

RETURN Select( AllTrim( cAlias ) )


FUNCTION ASPLIT( cString, cDelim )

    LOCAL aResult  := {}
    LOCAL nResult
    LOCAL nPos
    LOCAL nStart   := 1

    DEFAULT cDelim TO " "

    cString := AllTrim( cString )

    DO WHILE .T.
        nResult := At( cDelim, SubStr( cString, nStart ) )
        IF nResult == 0
            AAdd( aResult, SubStr( cString, nStart ) )
            EXIT
        ENDIF
        nPos := nResult + nStart - 1
        AAdd( aResult, SubStr( cString, nStart, nPos - nStart ) )
        nStart := nPos + Len( cDelim )
        DO WHILE SubStr( cString, nStart, 1 ) == cDelim
            nStart++
        ENDDO
    ENDDO

RETURN aResult


FUNCTION CEILING( nNum )

    IF ValType( nNum ) != "N"
        RETURN 0
    ENDIF

RETURN Int( nNum ) + If( nNum > Int( nNum ), 1, 0 )


FUNCTION ArraySkip( nSkip, nRow, nLen )

    LOCAL nSkipped := 0

    IF nRow + nSkip < 1
        nSkipped := 1 - nRow
    ELSEIF nRow + nSkip > nLen
        nSkipped := nLen - nRow
    ELSE
        nSkipped := nSkip
    ENDIF

    nRow += nSkipped

RETURN nSkipped


// ============================================================================
// ValidNif( cNif, lSilent )
// Valida NIF/NIE/CIF espanol. Para CIF mantiene validacion basica.
// ============================================================================
FUNCTION ValidNif( cNif, lSilent )

    LOCAL cLetra
    LOCAL nNum
    LOCAL cLetraCalc
    LOCAL cTipo

    DEFAULT lSilent TO .F.

    cLetra := "TRWAGMYFPDXBNJZSQVHLCKE"
    cNif   := Upper( AllTrim( cNif ) )

    IF Empty( cNif )
        RETURN .T.
    ENDIF

    IF Len( cNif ) < 7
        IF !lSilent
            MsgStop( "NIF demasiado corto.", "Validacion NIF" )
        ENDIF
        RETURN .F.
    ENDIF

    cTipo := Left( cNif, 1 )

    IF cTipo $ "XYZ"
        cNif  := If( cTipo == "X", "0", If( cTipo == "Y", "1", "2" ) ) + SubStr( cNif, 2 )
        cTipo := "0"
    ENDIF

    IF IsDigit( cTipo ) .AND. Len( cNif ) == 9
        nNum       := Val( Left( cNif, 8 ) )
        cLetraCalc := SubStr( cLetra, ( nNum % 23 ) + 1, 1 )
        IF Right( cNif, 1 ) != cLetraCalc
            IF !lSilent
                MsgStop( "La letra del NIF no es correcta.", "Validacion NIF" )
            ENDIF
            RETURN .F.
        ENDIF
        RETURN .T.
    ENDIF

    IF cTipo $ "ABCDEFGHJKLMNPQRSUVW"
        RETURN .T.
    ENDIF

    IF !lSilent
        MsgStop( "Formato de NIF/CIF no reconocido.", "Validacion NIF" )
    ENDIF

RETURN .F.


FUNCTION _ValidNif( cNif, lSilent )

RETURN ValidNif( cNif, lSilent )


// ============================================================================
// FIN DE Util.prg
// ============================================================================
