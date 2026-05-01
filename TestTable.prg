#include "OOp.ch"
#include "dbstruct.ch"

// ----------------------------------------------------------------------------
// PROCEDIMIENTO: Main
// Banco de pruebas de TTable. Crea clientes.dbf, mete registros, navega.
// Salida via GfxText() de la capa Gfx (no llama directamente a DispOutAt).
// ----------------------------------------------------------------------------
PROCEDURE Main()
    LOCAL bErrOld

    // Activamos el rastreo de errores ANTES de cualquier otra cosa.
    // Si algo peta en InitApp o despues, queda registrado en error.log.
    bErrOld := ErrorBlock( { |oErr| ErrSys( oErr ) } )

    // Inicializacion del entorno WVG (fuente, modo 40x132, colores, CLS)
    InitApp( 40, 132 )

    // Titulo en la primera fila
    GfxText(  0,  0, PadC( " TEST TTABLE - Capa de datos DBF/CDX ", 132 ), "W+/B" )

    TestTabla()

    GfxText( 39,  0, PadR( " Pulse cualquier tecla para salir... ", 132 ), "W+/B" )
    Inkey( 0 )

    SetColor( "W/N" )
    CLS

    ErrorBlock( bErrOld )
RETURN

// ----------------------------------------------------------------------------
// FUNCION: TestTabla
// ----------------------------------------------------------------------------
FUNCTION TestTabla()
    LOCAL oCli
    LOCAL aStruct
    LOCAL aTest
    LOCAL i
    LOCAL nFila

    // 1. Crear el .dbf si no existe
    IF !File( "clientes.dbf" )
        aStruct := { ;
            { "CODIGO", "C",  5, 0 }, ;
            { "NOMBRE", "C", 30, 0 }, ;
            { "POBLAC", "C", 20, 0 }, ;
            { "ALTA",   "D",  8, 0 } }

        // El RDD por defecto ya quedo establecido en InitApp()
        dbCreate( "clientes.dbf", aStruct )
        GfxText( 2, 2, "[ OK ]  clientes.dbf creada", "GR+/N" )
    ELSE
        GfxText( 2, 2, "[INFO]  clientes.dbf ya existe", "W/N" )
    ENDIF

    // 2. Instanciar TTable
    oCli := TTable():New( "CLIENTES", "clientes.dbf", { ;
        { "codigo", "codigo"        }, ;
        { "nombre", "Upper(nombre)" } } )

    // 3. Abrir
    IF !oCli:Open()
        GfxText( 4, 2, "[ERR ]  No se pudo abrir clientes.dbf", "R+/N" )
        Inkey( 0 )
        QUIT
    ENDIF
    GfxText( 3, 2, "[ OK ]  Tabla abierta. Registros: " + ;
                     AllTrim( Str( oCli:LastRec() ) ), "GR+/N" )

    // 4. Si esta vacia, metemos datos de prueba.
    //    NOTA SOBRE CARACTERES ACENTUADOS:
    //    Cuando guardes tus PRGs en tu editor, configurarlo en codificacion
    //    "Windows-1252" / "ANSI" para que los caracteres acentuados queden
    //    en los bytes correctos al compilar. Aqui los datos de prueba
    //    estan sin tildes para que el archivo sea ASCII puro y evitar
    //    problemas de codificacion al transferirlo entre maquinas.
    //    Una alternativa portable es construir caracteres con Chr():
    //       Chr(241) = letra ene minuscula con tilde (ASCII Win-1252)
    //       Chr(209) = letra ene mayuscula con tilde (ASCII Win-1252)
    IF oCli:LastRec() == 0
        aTest := { ;
            { "00001", "ACME S.L.",                          "Sevilla",  CToD( "01/01/2020" ) }, ;
            { "00002", "Talleres Garcia",                    "Cordoba",  CToD( "15/03/2021" ) }, ;
            { "00003", "Distribuciones X",                   "Malaga",   CToD( "20/06/2022" ) }, ;
            { "00004", "Bar Pepe",                           "Sevilla",  CToD( "10/10/2023" ) }, ;
            { "00005", "Suarez Mu" + Chr(241) + "oz S.L.",   "Granada",  CToD( "05/02/2024" ) }, ;
            { "00006", "El Ni" + Chr(241) + "o S.A.",        "Cadiz",    CToD( "12/03/2024" ) } }

        dbSelectArea( "CLIENTES" )
        FOR i := 1 TO Len( aTest )
            dbAppend()
            FieldPut( 1, aTest[ i, 1 ] )
            FieldPut( 2, aTest[ i, 2 ] )
            FieldPut( 3, aTest[ i, 3 ] )
            FieldPut( 4, aTest[ i, 4 ] )
        NEXT
        dbCommit()
        GfxText( 4, 2, "[ OK ]  Insertados " + AllTrim( Str( Len( aTest ) ) ) + ;
                         " registros de prueba", "GR+/N" )
    ENDIF

    // 5. Recorrido por orden CODIGO
    GfxText( 6, 2, "===== Recorrido por CODIGO =====", "W+/N" )
    GfxText( 7, 2, PadR( "Codigo", 8 ) + PadR( "Nombre", 32 ) + ;
                     PadR( "Poblacion", 22 ) + "Alta", "BG+/N" )

    nFila := 8
    oCli:SetOrder( "codigo" )
    oCli:GoTop()
    DO WHILE !oCli:Eof()
        GfxText( nFila, 2, ;
            PadR( oCli:FieldGet( "CODIGO" ),  8 ) + ;
            PadR( oCli:FieldGet( "NOMBRE" ), 32 ) + ;
            PadR( oCli:FieldGet( "POBLAC" ), 22 ) + ;
            DToC( oCli:FieldGet( "ALTA" ) ), "W/N" )
        nFila++
        oCli:Skip()
    ENDDO

    // 6. Recorrido por orden NOMBRE
    GfxText( nFila + 1, 2, "===== Recorrido por NOMBRE (UPPER) =====", "W+/N" )
    nFila += 2

    oCli:SetOrder( "nombre" )
    oCli:GoTop()
    DO WHILE !oCli:Eof()
        GfxText( nFila, 2, ;
            PadR( oCli:FieldGet( "CODIGO" ),  8 ) + ;
            PadR( oCli:FieldGet( "NOMBRE" ), 32 ), "W/N" )
        nFila++
        oCli:Skip()
    ENDDO

    // 7. Busquedas
    nFila++
    GfxText( nFila, 2, "===== Busquedas =====", "W+/N" )
    nFila++

    IF oCli:Seek( "00003", "codigo" )
        GfxText( nFila, 2, "[ OK ]  Codigo 00003 encontrado: " + ;
                             AllTrim( oCli:FieldGet( "NOMBRE" ) ) + ;
                             "  (reg " + AllTrim( Str( oCli:RecNo() ) ) + ")", ;
                             "GR+/N" )
    ELSE
        GfxText( nFila, 2, "[ERR ]  Codigo 00003 NO encontrado", "R+/N" )
    ENDIF
    nFila++

    IF oCli:Seek( "99999", "codigo" )
        GfxText( nFila, 2, "[ERR ]  Encontro 99999 (no deberia)", "R+/N" )
    ELSE
        GfxText( nFila, 2, "[ OK ]  Codigo 99999 NO existe (correcto)", "GR+/N" )
    ENDIF

    // 8. Cerrar
    oCli:Close()
    GfxText( nFila + 2, 2, "[ OK ]  Tabla cerrada correctamente", "GR+/N" )

RETURN NIL
