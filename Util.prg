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
 * 6) EvalSafe            - Ejecucion protegida de callbacks de UI
 * 7) Utilidades genericas: DirExiste, MiDefault, IsDbUsed,
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

#define POPUP_NEW "__POPUP_NEW__"

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

    // Activar eventos de raton (GTWVG)
    BEGIN SEQUENCE
        SET EVENTMASK TO ( INKEY_KEYBOARD + INKEY_LDOWN + INKEY_LUP + INKEY_RDOWN + INKEY_RUP )
        wvt_SetMouseMove( .T. )
    RECOVER
    END SEQUENCE

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


FUNCTION ErrorLogError( oErr, cContext )

    DEFAULT cContext TO ""

RETURN ErrorLogAppend( _ErrorLogBuild( oErr, cContext, 3 ) )


STATIC FUNCTION _ErrorLogBuild( oErr, cContext, nStart )

    LOCAL cMsg  := ""
    LOCAL cLog  := ""
    LOCAL cArgs := ""
    LOCAL nI
    LOCAL i

    DEFAULT cContext TO ""
    DEFAULT nStart   TO 2

    cMsg := "ERROR DE EJECUCION" + hb_Eol()
    IF !Empty( cContext )
        cMsg += "Contexto    : " + hb_ValToStr( cContext ) + hb_Eol()
    ENDIF

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
    nI := nStart
    DO WHILE !Empty( ProcName( nI ) )
        cLog += "  " + PadR( ProcFile( nI ), 24 ) + ;
                " -> " + PadR( ProcName( nI ), 30 ) + ;
                " (linea " + AllTrim( Str( ProcLine( nI ) ) ) + ")" + hb_Eol()
        nI++
        IF nI > 50
            EXIT
        ENDIF
    ENDDO

RETURN cLog


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

    IF lProc
        ErrorLevel( 2 )
        QUIT
    ENDIF
    lProc := .T.

    ErrorBlock( { |e| Break( e ) } )

    ErrorLogAppend( _ErrorLogBuild( oErr, "ErrSys", 2 ) )

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
// ABRIR_TABLA( cArchivo, cAlias, cIndice, aCdxAdicionales )
// Abre DBF/CDX y fija tag si se pide. No reposiciona el cursor: el llamador
// decide si necesita DbGoTop(), DbSeek(), etc.
// ----------------------------------------------------------------------------
FUNCTION ABRIR_TABLA( cArchivo, cAlias, cIndice, aCdxAdicionales, lReabierta )

    LOCAL lReintentar := .T.

    DEFAULT cAlias TO cArchivo
    DEFAULT lReabierta TO .F.

    IF IsDbUsed( cAlias )
        DbSelectArea( cAlias )
        IF !Empty( cIndice )
            OrdSetFocus( cIndice )
        ENDIF
        lReabierta := .T.
        RETURN .T.
    ENDIF

    DO WHILE lReintentar
        DbUseArea( .T., "DBFCDX", cArchivo, cAlias, .T., .F. )
        IF NetErr()
            IF MsgYesNo( "Archivo " + cArchivo + " bloqueado. Reintentar?", ;
                         "Error de acceso" )
                LOOP
            ELSE
                lReabierta := .F.
                RETURN .F.
            ENDIF
        ELSE
            lReintentar := .F.
        ENDIF
    ENDDO

    IF HB_ISARRAY( aCdxAdicionales )
        AEval( aCdxAdicionales, { |cCdx| OrdListAdd( cCdx ) } )
    ENDIF

    IF !Empty( cIndice )
        OrdSetFocus( cIndice )
    ENDIF

    lReabierta := .F.

RETURN .T.


// ============================================================================
// 4) BLOQUEOS DE RED
// ============================================================================

FUNCTION NetFLock()

    LOCAL nIntentos := 0

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


// ----------------------------------------------------------------------------
// NetUnLock()
// Libera TODOS los locks del area activa (FLock + record locks).
// Es un wrapper directo de DbUnlock(); el nombre singular es historico.
// ----------------------------------------------------------------------------
FUNCTION NetUnLock()
    DbUnlock()
RETURN NIL


// ============================================================================
// 5) CONTADOR CORRELATIVO DE DOCUMENTOS
// ============================================================================

FUNCTION GetNextNum( cCodDoc, cDescrip )

    LOCAL cProxCod := ""
    LOCAL nAreaIni := Select()
    LOCAL lFueAbierta := IsDbUsed( "CON" )
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
            IF !lFueAbierta
                CON->( DbCloseArea() )
            ENDIF
            Select( nAreaIni )
            RETURN ""
        ENDIF

        DbSkip( 0 )

        cPrefijo := AllTrim( CON->PREFIJO )
        nUltNum  := CON->ULT_NUM
        nDigitos := If( CON->DIGITOS > 0, CON->DIGITOS, 7 )

    ELSE

        cPrefijo := _PrefijoEmp()

        IF !NetFLock()
            IF !lFueAbierta
                CON->( DbCloseArea() )
            ENDIF
            Select( nAreaIni )
            RETURN ""
        ENDIF

        IF DbSeek( cCodDoc )
            DbSkip( 0 )
            cPrefijo := AllTrim( CON->PREFIJO )
            nUltNum  := CON->ULT_NUM
            nDigitos := If( CON->DIGITOS > 0, CON->DIGITOS, 7 )
        ELSE
            DbAppend()
            REPLACE CON->COD_DOC WITH cCodDoc
            REPLACE CON->DESCRIP WITH If( ValType( cDescrip ) == "C", cDescrip, "" )
            REPLACE CON->PREFIJO WITH cPrefijo
            REPLACE CON->DIGITOS WITH nDigitos
        ENDIF

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

    IF !lFueAbierta
        CON->( DbCloseArea() )
    ENDIF

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
// 6) EJECUCION PROTEGIDA DE CALLBACKS
// ============================================================================

FUNCTION EvalSafe( bBlock, cContext, xArg1, xArg2, xArg3 )

    LOCAL xRet := NIL
    LOCAL bOld
    LOCAL oErr

    IF ValType( bBlock ) != "B"
        RETURN NIL
    ENDIF

    bOld := ErrorBlock( {| e | Break( e ) } )

    BEGIN SEQUENCE

        DO CASE
        CASE PCount() <= 2
            xRet := Eval( bBlock )
        CASE PCount() == 3
            xRet := Eval( bBlock, xArg1 )
        CASE PCount() == 4
            xRet := Eval( bBlock, xArg1, xArg2 )
        OTHERWISE
            xRet := Eval( bBlock, xArg1, xArg2, xArg3 )
        ENDCASE

    RECOVER USING oErr

        ErrorLogError( oErr, cContext )
        MsgStop( "Se ha registrado un error en error.log." + hb_Eol() + ;
                 "Contexto: " + hb_ValToStr( cContext ), "Error interno" )
        xRet := NIL

    END SEQUENCE

    ErrorBlock( bOld )

RETURN xRet


// ============================================================================
// 7) UTILIDADES GENERICAS
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
// PopupSelect()
// Muestra una lista modal y devuelve el codigo de la fila seleccionada.
// aCols: { { cTitulo, nAncho, cPicture, nCampo }, ... }
// ============================================================================
FUNCTION PopupSelect( cTitle, aData, aCols, nSeekCol, cNewCaption )

    LOCAL oWin
    LOCAL oGrid
    LOCAL oLbl
    LOCAL oBtOk
    LOCAL oBtNew
    LOCAL oBtCan
    LOCAL cRet := ""
    LOCAL i

    DEFAULT cTitle   TO "SELECCION"
    DEFAULT aData    TO {}
    DEFAULT aCols    TO {}
    DEFAULT nSeekCol TO 1
    DEFAULT cNewCaption TO ""

    IF Len( aData ) == 0 .AND. Empty( cNewCaption )
        MsgInfo( "No hay datos para seleccionar.", cTitle )
        RETURN ""
    ENDIF

    oWin  := TWindow():New( 5, 18, 27, 114, cTitle )
    oGrid := TGrid():New( 2, 2, 17, 92, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := nSeekCol

    FOR i := 1 TO Len( aCols )
        oGrid:AddColumn( aCols[i, 1], aCols[i, 2], aCols[i, 3], ;
                         _PopupColBlock( aCols[i, 4] ) )
    NEXT

    oGrid:bEnter := {| g | If( g:CurrentRow() != NIL, ;
                               ( cRet := AllTrim( g:CurrentRow()[1] ), ;
                                 oWin:Close() ), NIL ) }

    oLbl := TLabel():New( 18, 2, ;
        "ENTER: seleccionar   Letras: buscar   ESC: cancelar" + ;
        If( !Empty( cNewCaption ), "   TAB: " + AllTrim( cNewCaption ), "" ), oWin )

    oBtOk := TButton():New( 20, 18, 20, 35, oWin, "ACEPTAR", ;
        {|| If( oGrid:CurrentRow() != NIL, ;
                ( cRet := AllTrim( oGrid:CurrentRow()[1] ), ;
                  oWin:Close() ), NIL ) } )

    oBtNew := TButton():New( 20, 39, 20, 56, oWin, cNewCaption, ;
        {|| cRet := POPUP_NEW, oWin:Close() } )

    IF Empty( cNewCaption )
        oBtNew:Hide()
    ENDIF

    oBtCan := TButton():New( 20, 60, 20, 77, oWin, "CANCELAR", ;
        {|| cRet := "", oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oLbl   )
    oWin:AddCtrl( oBtOk  )
    oWin:AddCtrl( oBtNew )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

RETURN cRet


FUNCTION LookupCliente()

    LOCAL aData
    LOCAL cRet

    DO WHILE .T.
        aData := _LookupClientesData()

        cRet := PopupSelect( "SELECCIONAR CLIENTE", aData, ;
            { { "Codigo", 10, "@!", 1 }, ;
              { "Nombre", 42, "@!", 2 }, ;
              { "NIF",    14, "@!", 3 }, ;
              { "Ciudad", 20, "@!", 4 } }, 2, "NUEVO" )

        IF cRet == POPUP_NEW
            ClientesForm( .T., "" )
        ELSE
            EXIT
        ENDIF
    ENDDO

RETURN cRet


STATIC FUNCTION _LookupClientesData()

    LOCAL nArea := Select()
    LOCAL aData := {}

    IF !ABRIR_TABLA( "CLIENTES", "CLI_LKP", "CLI_NOM" )
        RETURN aData
    ENDIF

    DbSelectArea( "CLI_LKP" )
    OrdSetFocus( "CLI_NOM" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. !DbFieldValue( "BAJA", .F. )
            AAdd( aData, { ;
                AllTrim( CLI_LKP->ID ), ;
                AllTrim( CLI_LKP->NOMBRE + " " + CLI_LKP->APELLIDO ), ;
                AllTrim( CLI_LKP->NIF ), ;
                AllTrim( CLI_LKP->CIUDAD ) } )
        ENDIF
        DbSkip()
    ENDDO

    CLI_LKP->( DbCloseArea() )
    Select( nArea )

RETURN aData


FUNCTION LookupFormaPago()

    LOCAL nArea := Select()
    LOCAL aData := {}
    LOCAL cRet

    IF !ABRIR_TABLA( "FORMAPAGO", "FP_LKP", "FP_COD" )
        RETURN ""
    ENDIF

    DbSelectArea( "FP_LKP" )
    OrdSetFocus( "FP_COD" )
    DbGoTop()

    DO WHILE !Eof()
        IF !Deleted() .AND. !DbFieldValue( "BAJA", .F. )
            AAdd( aData, { ;
                AllTrim( FP_LKP->CODIGO ), ;
                AllTrim( FP_LKP->DESCRIP ), ;
                FP_LKP->DIAS, ;
                FP_LKP->NUM_PAGS } )
        ENDIF
        DbSkip()
    ENDDO

    FP_LKP->( DbCloseArea() )
    Select( nArea )

    cRet := PopupSelect( "SELECCIONAR FORMA DE PAGO", aData, ;
        { { "Cod",         5, "@!",  1 }, ;
          { "Descripcion", 40, "@!", 2 }, ;
          { "Dias",        6, "999", 3 }, ;
          { "Pagos",       6, "99",  4 } }, 2 )

RETURN cRet


STATIC FUNCTION _PopupColBlock( nIndex )

RETURN {| aRow | If( nIndex >= 1 .AND. nIndex <= Len( aRow ), aRow[nIndex], "" ) }


// ============================================================================
// ValidNifFormato( cNif, lSilent )
// Valida solo formato general NIF/NIE/CIF. Util para datos provisionales.
// ============================================================================
FUNCTION ValidNifFormato( cNif, lSilent )

    LOCAL cTipo

    DEFAULT lSilent TO .F.

    cNif := Upper( AllTrim( cNif ) )

    IF Empty( cNif )
        RETURN .T.
    ENDIF

    cTipo := Left( cNif, 1 )

    IF Len( cNif ) == 9 .AND. ;
       ( ( cTipo >= "0" .AND. cTipo <= "9" ) .OR. cTipo $ "XYZ" ) .AND. ;
       _IsAllDigits( SubStr( cNif, 2, 7 ) ) .AND. ;
       Right( cNif, 1 ) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        RETURN .T.
    ENDIF

    IF Len( cNif ) >= 8 .AND. Len( cNif ) <= 9 .AND. ;
       cTipo $ "ABCDEFGHJKLMNPQRSUVW" .AND. ;
       _IsAllDigits( SubStr( cNif, 2, Min( 7, Len( cNif ) - 1 ) ) )
        RETURN .T.
    ENDIF

    IF !lSilent
        MsgStop( "Formato de NIF/CIF no reconocido.", "Validacion NIF" )
    ENDIF

RETURN .F.


// ============================================================================
// ValidNifFiscal( cNif, lSilent )
// Valida NIF/NIE/CIF con digito/letra de control.
// ============================================================================
FUNCTION ValidNifFiscal( cNif, lSilent )

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

    IF Len( cNif ) != 9
        IF !lSilent
            MsgStop( "El NIF/CIF debe tener 9 caracteres.", "Validacion NIF" )
        ENDIF
        RETURN .F.
    ENDIF

    cTipo := Left( cNif, 1 )

    IF cTipo $ "XYZ"
        cNif  := If( cTipo == "X", "0", If( cTipo == "Y", "1", "2" ) ) + SubStr( cNif, 2 )
        cTipo := "0"
    ENDIF

    IF IsDigit( cTipo )
        IF !_IsAllDigits( Left( cNif, 8 ) )
            IF !lSilent
                MsgStop( "Los primeros 8 caracteres del NIF deben ser numericos.", "Validacion NIF" )
            ENDIF
            RETURN .F.
        ENDIF

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
        IF _ValidCifFiscal( cNif )
            RETURN .T.
        ENDIF
        IF !lSilent
            MsgStop( "El control del CIF no es correcto.", "Validacion NIF" )
        ENDIF
        RETURN .F.
    ENDIF

    IF !lSilent
        MsgStop( "Formato de NIF/CIF no reconocido.", "Validacion NIF" )
    ENDIF

RETURN .F.


FUNCTION ValidNif( cNif, lSilent )

RETURN ValidNifFiscal( cNif, lSilent )


FUNCTION ValidNifObligatorio( cNif, lSilent )

    DEFAULT lSilent TO .F.

    IF ValType( cNif ) != "C" .OR. Empty( AllTrim( cNif ) )
        IF !lSilent
            MsgStop( "El NIF/CIF es obligatorio.", "Validacion NIF" )
        ENDIF
        RETURN .F.
    ENDIF

RETURN ValidNifFiscal( cNif, lSilent )


FUNCTION _ValidNif( cNif, lSilent )

RETURN ValidNif( cNif, lSilent )


STATIC FUNCTION _IsAllDigits( cValue )

    LOCAL nPos
    LOCAL cChar

    cValue := AllTrim( cValue )

    IF Empty( cValue )
        RETURN .F.
    ENDIF

    FOR nPos := 1 TO Len( cValue )
        cChar := SubStr( cValue, nPos, 1 )
        IF cChar < "0" .OR. cChar > "9"
            RETURN .F.
        ENDIF
    NEXT

RETURN .T.


STATIC FUNCTION _ValidCifFiscal( cCif )

    LOCAL cTipo
    LOCAL cNum
    LOCAL cCtrl
    LOCAL cCtrlLetra
    LOCAL nSuma := 0
    LOCAL nPos
    LOCAL nDig
    LOCAL nDoble
    LOCAL nCtrl

    cCif  := Upper( AllTrim( cCif ) )
    cTipo := Left( cCif, 1 )
    cNum  := SubStr( cCif, 2, 7 )
    cCtrl := Right( cCif, 1 )

    IF Len( cCif ) != 9 .OR. !_IsAllDigits( cNum )
        RETURN .F.
    ENDIF

    FOR nPos := 1 TO 7
        nDig := Val( SubStr( cNum, nPos, 1 ) )
        IF nPos % 2 == 1
            nDoble := nDig * 2
            nSuma  += Int( nDoble / 10 ) + ( nDoble % 10 )
        ELSE
            nSuma += nDig
        ENDIF
    NEXT

    nCtrl      := ( 10 - ( nSuma % 10 ) ) % 10
    cCtrlLetra := SubStr( "JABCDEFGHI", nCtrl + 1, 1 )

    IF cTipo $ "PQRSNW"
        RETURN cCtrl == cCtrlLetra
    ENDIF

    IF cTipo $ "ABEH"
        RETURN cCtrl == Str( nCtrl, 1 )
    ENDIF

RETURN cCtrl == Str( nCtrl, 1 ) .OR. cCtrl == cCtrlLetra


// ============================================================================
// FIN DE Util.prg
// ============================================================================
