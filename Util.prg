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
    LOCAL cLogPrev := ""
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

    BEGIN SEQUENCE
        IF File( "error.log" )
            cLogPrev := hb_MemoRead( "error.log" )
        ENDIF
        hb_MemoWrit( "error.log", cLogPrev + cLog )
    RECOVER
    END SEQUENCE

    BEGIN SEQUENCE
        dbCloseAll()
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

    IF Select( cAlias ) > 0
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
RETURN ( Select( cAlias ) > 0 )


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
// _ValidNif( cNif )
// Valida NIF/NIE/CIF español (validacion basica)
// ============================================================================
FUNCTION _ValidNif( cNif )

    LOCAL cNum
    LOCAL nLen
    LOCAL lValid := .T.

    IF Empty( cNif )
        RETURN .T.
    ENDIF

    cNif := Upper( AllTrim( cNif ) )
    nLen := Len( cNif )

    // NIF personal (8 numeros + 1 letra)
    IF nLen == 9 .AND. SubStr( cNif, 1, 1 ) $ "0123456789"
        cNum := SubStr( cNif, 1, 8 )
        IF !Empty( cNum ) .AND. Val( cNum ) > 0
            RETURN .T.
        ENDIF
    ENDIF

    // NIE (X/Y/Z + 7 numeros + 1 letra)
    IF nLen == 9 .AND. SubStr( cNif, 1, 1 ) $ "XYZ"
        RETURN .T.
    ENDIF

    // CIF (letra + 7 numeros + control)
    IF nLen >= 8 .AND. nLen <= 9 .AND. SubStr( cNif, 1, 1 ) $ "ABCDEFGHJKLMNPQRSUVW"
        RETURN .T.
    ENDIF

RETURN .F.


// ============================================================================
// FIN DE Util.prg
// ============================================================================
