#include "OOp.ch"
#include "dbstruct.ch"

// ============================================================================
// CLASE: TTable    (Wrapper sobre RDD DBFCDX)
// Version: 0.1     Lectura, navegacion y busqueda. Sin edicion todavia.
// ============================================================================
CLASS TTable
    DATA cAlias        // alias logico (tambien identifica el area)
    DATA cFile         // ruta y nombre del .dbf
    DATA aIndexes      // { { cTag, cExpr }, ... }
    DATA lOpen         // .T. si la tabla esta abierta

    METHOD New()
    METHOD Open()
    METHOD Close()
    METHOD Used()        INLINE ::lOpen

    METHOD GoTop()
    METHOD GoBottom()
    METHOD Skip()
    METHOD Goto()

    METHOD Eof()
    METHOD Bof()
    METHOD RecNo()
    METHOD LastRec()

    METHOD Seek()
    METHOD SetOrder()

    METHOD FieldGet()
    METHOD FieldPut()

    METHOD Select()       // metodo interno: selecciona el area de esta tabla
ENDCLASS

// ----------------------------------------------------------------------------
// METODO: New
// aIndexes : array de pares { cTag, cExpresion }
// ----------------------------------------------------------------------------
METHOD New( cAlias, cFile, aIndexes ) CLASS TTable
    ::cAlias   := cAlias
    ::cFile    := cFile
    ::aIndexes := If( aIndexes == NIL, {}, aIndexes )
    ::lOpen    := .F.
RETURN Self

// ----------------------------------------------------------------------------
// METODO: Select  (uso interno; deja el area de esta tabla como activa)
// ----------------------------------------------------------------------------
METHOD Select() CLASS TTable
    IF ::lOpen
        dbSelectArea( ::cAlias )
    ENDIF
RETURN NIL

// ----------------------------------------------------------------------------
// METODO: Open
// Abre el .dbf en su propia area.  Si el .cdx no existe, lo crea con los
// indices declarados en aIndexes.  Si existe, simplemente lo asocia.
// ----------------------------------------------------------------------------
METHOD Open() CLASS TTable
    LOCAL cCdx
    LOCAL i
    LOCAL cTag, cExpr
    LOCAL lExisteCdx

    IF ::lOpen
        RETURN .T.
    ENDIF

    // El RDD por defecto (DBFCDX) ya quedo establecido en InitApp().
    // Si esta clase se usa fuera del contexto de la app, conviene asegurarlo
    // llamando a rddSetDefault("DBFCDX") en el Main correspondiente.

    IF !File( ::cFile )
        // Si el .dbf no existe, no podemos abrirlo. Quien llame a Open()
        // debe haber comprobado o creado el fichero antes.
        RETURN .F.
    ENDIF

    // Construimos el nombre del .cdx asociado (mismo nombre, distinta extension)
    cCdx := hb_FNameExtSet( ::cFile, ".cdx" )
    lExisteCdx := File( cCdx )

    // Abrimos en modo compartido para multipuesto
    dbUseArea( .T., "DBFCDX", ::cFile, ::cAlias, .T., .F. )

    IF !Used()
        RETURN .F.
    ENDIF

    // Si el .cdx no existia y hay indices declarados, los creamos
    IF !lExisteCdx .AND. !Empty( ::aIndexes )
        FOR i := 1 TO Len( ::aIndexes )
            cTag  := ::aIndexes[ i, 1 ]
            cExpr := ::aIndexes[ i, 2 ]
            // OrdCreate( cBag, cTag, cExpr, bExpr, lUnique )
            OrdCreate( cCdx, cTag, cExpr, &( "{||" + cExpr + "}" ), .F. )
        NEXT
    ELSE
        // El .cdx ya existe, lo asociamos al area
        IF File( cCdx )
            OrdListAdd( cCdx )
        ENDIF
    ENDIF

    // Por defecto activamos el primer indice si hay alguno
    IF !Empty( ::aIndexes )
        OrdSetFocus( ::aIndexes[ 1, 1 ] )
    ENDIF

    ::lOpen := .T.
RETURN .T.

// ----------------------------------------------------------------------------
// METODO: Close
// ----------------------------------------------------------------------------
METHOD Close() CLASS TTable
    IF ::lOpen
        ::Select()
        dbCloseArea()
        ::lOpen := .F.
    ENDIF
RETURN NIL

// ----------------------------------------------------------------------------
// NAVEGACION
// ----------------------------------------------------------------------------
METHOD GoTop() CLASS TTable
    ::Select()
    dbGoTop()
RETURN NIL

METHOD GoBottom() CLASS TTable
    ::Select()
    dbGoBottom()
RETURN NIL

METHOD Skip( nVeces ) CLASS TTable
    DEFAULT nVeces TO 1
    ::Select()
    dbSkip( nVeces )
RETURN NIL

METHOD Goto( nRec ) CLASS TTable
    ::Select()
    dbGoto( nRec )
RETURN NIL

// ----------------------------------------------------------------------------
// ESTADO
// ----------------------------------------------------------------------------
METHOD Eof() CLASS TTable
    ::Select()
RETURN Eof()

METHOD Bof() CLASS TTable
    ::Select()
RETURN Bof()

METHOD RecNo() CLASS TTable
    ::Select()
RETURN RecNo()

METHOD LastRec() CLASS TTable
    ::Select()
RETURN LastRec()

// ----------------------------------------------------------------------------
// METODO: SetOrder  (cambia el indice activo por su tag)
// ----------------------------------------------------------------------------
METHOD SetOrder( cTag ) CLASS TTable
    ::Select()
    OrdSetFocus( cTag )
RETURN NIL

// ----------------------------------------------------------------------------
// METODO: Seek
// uKey  : clave a buscar
// cTag  : tag del indice (opcional, si NIL usa el indice activo)
// Devuelve .T. si encontro, .F. si no.
// ----------------------------------------------------------------------------
METHOD Seek( uKey, cTag ) CLASS TTable
    ::Select()
    IF cTag != NIL
        OrdSetFocus( cTag )
    ENDIF
RETURN dbSeek( uKey )

// ----------------------------------------------------------------------------
// CAMPOS
// ----------------------------------------------------------------------------
METHOD FieldGet( cName ) CLASS TTable
    LOCAL nPos
    ::Select()
    nPos := FieldPos( cName )
    IF nPos == 0
        RETURN NIL
    ENDIF
RETURN FieldGet( nPos )

METHOD FieldPut( cName, uValue ) CLASS TTable
    LOCAL nPos
    ::Select()
    nPos := FieldPos( cName )
    IF nPos == 0
        RETURN NIL
    ENDIF
    FieldPut( nPos, uValue )
RETURN uValue
