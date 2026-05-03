#include "OOp.ch"

// ============================================================================
// REQUEST de modulos del runtime que el linker debe incluir si o si.
// ----------------------------------------------------------------------------
// IMPORTANTE: rddSetDefault() solo selecciona un modulo, pero NO obliga al
// linker a enlazarlo en el ejecutable. Si el modulo no esta enlazado, la
// llamada puede fallar silenciosamente o dar "Argument error".
//
// REQUEST fuerza al linker a incluir el codigo, independientemente de la
// optimizacion. Es la forma canonica desde Clipper 5.x de garantizar que
// un modulo esta disponible en runtime.
// ============================================================================

// RDD para tablas DBF + indices CDX (formato Clipper)
REQUEST DBFCDX

// ----------------------------------------------------------------------------
// FUNCION: InitApp
// Inicializa el entorno pseudo-grafico WVG de la aplicacion.
// Se llama desde Main(), antes de cualquier ventana o salida a pantalla.
// Parametros (todos opcionales):
//   nRows  : filas    (default 40)
//   nCols  : columnas (default 132)
//   cFont  : fuente   (default "Lucida Console")
//   nFontH : alto px  (default 16)
//   nFontW : ancho px (default 8)
// ----------------------------------------------------------------------------
FUNCTION InitApp( nRows, nCols, cFont, nFontH, nFontW )

    DEFAULT nRows  TO 40
    DEFAULT nCols  TO 132
    DEFAULT cFont  TO "Lucida Console"
    DEFAULT nFontH TO 16
    DEFAULT nFontW TO 8

    // 1. RDD por defecto: DBFCDX
    rddSetDefault( "DBFCDX" )

    // 2. Fuente fija de ancho constante
    GfxSetFont( cFont, nFontH, nFontW )

    // 3. Modo de pantalla (filas x columnas)
    SetMode( nRows, nCols )

    // 4. Bloqueo de redimensionamiento (evita fantasmas en Save/Restore)
    GfxFixSize( .T. )

    // 5. Color por defecto y limpieza de pantalla
    SetColor( CLR_WINDOW )
    CLS

    // 6. Cursor oculto por defecto
    GfxCursor( SC_NONE )

RETURN NIL

// ----------------------------------------------------------------------------
// FUNCION: MsgBox  (Caja de mensaje robusta)
// ----------------------------------------------------------------------------
FUNCTION MsgBox( cMsg, cTit )
    LOCAL xSave
    LOCAL nT, nL, nB, nR
    LOCAL nAncho, nAlto
    LOCAL nKey

    hb_Default( @cTit, "Mensaje" )
    hb_Default( @cMsg, "" )

    // Calculamos un cuadro centrado segun el tamano de pantalla actual
    nAncho  := Min( Max( Len( cMsg ) + 6, Len( cTit ) + 8 ), GfxMaxCol() - 4 )
    nAlto   := 6

    nT := Int( ( GfxMaxRow() - nAlto  ) / 2 )
    nL := Int( ( GfxMaxCol() - nAncho ) / 2 )
    nB := nT + nAlto
    nR := nL + nAncho

    // Guardamos lo que haya debajo (incluyendo capa grafica)
    xSave := GfxSave( nT, nL, nB, nR )

    // Cursor apagado: el MsgBox no es editable, no hay donde poner cursor.
    // Si veniamos de un TGet con foco, el cursor estaba visible debajo;
    // al apagarlo aqui evitamos que se vea bajo el cuadro de mensaje.
    GfxCursor( SC_NONE )

    GfxLock()
    GfxClear( nT, nL, nB, nR, CLR_WINDOW )
    GfxBox(   nT, nL, nB, nR, CLR_WINDOW )
    GfxText(  nT,     nL + 2, " " + cTit + " ", "W+/B" )
    GfxText(  nT + 2, nL + 3, PadR( cMsg, nAncho - 5 ), CLR_WINDOW )
    GfxText(  nB - 1, nL + Int( ( nAncho - 13 ) / 2 ), " [ ACEPTAR ] ", "W+/B" )
    GfxUnlock()

    // Esperamos cualquier tecla
    DO WHILE .T.
        nKey := Inkey( 0 )
        IF nKey == K_ENTER .OR. nKey == K_ESC .OR. nKey == K_SPACE
            EXIT
        ENDIF
    ENDDO

    // Restauramos pantalla.  El cursor lo dejamos apagado: si volvemos
    // a un TGet, su Paint lo encendera de nuevo en su Paint().
    GfxRestore( nT, nL, nB, nR, xSave )
    GfxCursor( SC_NONE )
RETURN NIL

// ----------------------------------------------------------------------------
// FUNCIONES WRAPPERS
// ----------------------------------------------------------------------------
FUNCTION MsgInfo( cMsg, cTit )
    hb_Default( @cTit, "Informacion" )
    MsgBox( cMsg, "INFO: " + cTit )
RETURN NIL

FUNCTION MsgStop( cMsg, cTit )
    hb_Default( @cTit, "Error" )
    MsgBox( cMsg, "ALERTA: " + cTit )
RETURN NIL

// ----------------------------------------------------------------------------
// FUNCION: ErrSys
// PROPOSITO UNICO: registrar el error en error.log y salir.
// NO pinta nada en pantalla, NO llama a MsgBox, NO depende del entorno
// grafico (que puede ser precisamente lo que esta roto).
// ----------------------------------------------------------------------------
FUNCTION ErrSys( oErr )
    STATIC lProc := .F.
    LOCAL cMsg     := ""
    LOCAL cLog     := ""
    LOCAL cArgs    := ""
    LOCAL cLogPrev := ""
    LOCAL nI       := 2
    LOCAL i

    // 1. Blindaje anti-recursividad
    IF lProc
        ErrorLevel( 2 )
        QUIT
    ENDIF
    lProc := .T.

    // 2. Desactivar el manejador para evitar bucles dentro de la propia
    //    construccion del mensaje (acceso a oErr puede disparar errores).
    ErrorBlock( { |e| Break( e ) } )

    // 3. Construccion del mensaje
    cMsg := "ERROR DE EJECUCION" + hb_Eol()
    BEGIN SEQUENCE
        cMsg += "Subsistema  : " + hb_ValToStr( oErr:SubSystem )    + hb_Eol()
        cMsg += "Codigo      : " + hb_ValToStr( oErr:SubCode )      + hb_Eol()
        cMsg += "Operacion   : " + hb_ValToStr( oErr:Operation )    + hb_Eol()
        cMsg += "Descripcion : " + hb_ValToStr( oErr:Description )  + hb_Eol()
        cMsg += "Severidad   : " + hb_ValToStr( oErr:Severity )     + hb_Eol()
        cMsg += "CanRetry    : " + hb_ValToStr( oErr:CanRetry )     + hb_Eol()

        IF !Empty( oErr:FileName )
            cMsg += "Fichero     : " + hb_ValToStr( oErr:FileName ) + hb_Eol()
        ENDIF
        IF !Empty( oErr:OsCode )
            cMsg += "OS code     : " + hb_ValToStr( oErr:OsCode )   + hb_Eol()
        ENDIF
    RECOVER
        cMsg += "(no se pudieron leer todos los campos del error)" + hb_Eol()
    END SEQUENCE

    // 4. Argumentos del operador que fallo
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

    // 5. Cabecera del log
    cLog := Replicate( "=", 70 ) + hb_Eol()
    cLog += "FECHA: " + DToC( Date() ) + " HORA: " + Time() + hb_Eol()
    cLog += cMsg
    IF !Empty( cArgs )
        cLog += cArgs
    ENDIF

    // 6. Pila de llamadas
    cLog += "Pila de llamadas:" + hb_Eol()
    DO WHILE !Empty( ProcName( nI ) )
        cLog += "  " + PadR( ProcFile( nI ), 24 ) + ;
                " -> " + PadR( ProcName( nI ), 30 ) + ;
                " (linea " + AllTrim( Str( ProcLine( nI ) ) ) + ")" + hb_Eol()
        nI++
        IF nI > 50      // Limite de seguridad
            EXIT
        ENDIF
    ENDDO

    // 7. Persistencia: append al error.log
    BEGIN SEQUENCE
        IF File( "error.log" )
            cLogPrev := hb_MemoRead( "error.log" )
        ENDIF
        hb_MemoWrit( "error.log", cLogPrev + cLog )
    RECOVER
        // Si ni siquiera podemos escribir el log, no hay nada mas que hacer
    END SEQUENCE

    // 8. Cierre limpio de tablas y salida.
    //    NO se notifica al usuario aqui: ese es trabajo de quien llama
    //    (el modulo que detecta una operacion fallida puede usar MsgStop).
    BEGIN SEQUENCE
        dbCloseAll()
    RECOVER
        // Ignoramos
    END SEQUENCE

    ErrorLevel( 1 )
    QUIT

RETURN NIL
