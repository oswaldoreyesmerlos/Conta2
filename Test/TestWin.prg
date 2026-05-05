// ============================================================================
// ARCHIVO : TestWin.prg
// PROPOSITO: Prueba integral del nucleo de la libreria pseudo-grafica.
//
// ESTRUCTURA DEL TEST
// -------------------
// Main()
//   +-- TestBasico()    : TWindow + TLabel + TButton
//   +-- TestFormulario(): TWindow + TLabel + TGet + TButton + TCheck
//   +-- TestCombo()     : TWindow + TLabel + TCombo (simple y asociado)
//   +-- TestGrid()      : TWindow + TGrid  (navegacion, busqueda)
//   +-- TestMsgBox()    : MsgBox / MsgInfo / MsgStop
//   +-- TestMsgYesNo()  : MsgYesNo / MsgConfirm
//   +-- TestAnidado()   : dos TWindow apiladas (modal sobre modal)
//
// COMPILAR
//   hbmk2 test.hbp
//
// EJECUTAR
//   AppGestion.exe
// ============================================================================

#include "OOp.ch"

// ----------------------------------------------------------------------------
// MAIN
// ----------------------------------------------------------------------------
FUNCTION Main()

    LOCAL lSeguir

    // Inicializar entorno grafico WVG
    InitApp()

    GfxSetTitle( "TestWin - Suite de pruebas del framework" )

    // Manejador de errores robusto
    ErrorBlock( { |e| ErrSys( e ) } )

    // Ejecutar cada suite de forma secuencial.
    // Cada una muestra su propio menu o dialogo.
    lSeguir := TestMenu()

    GfxCursor( SC_NONE )
    CLS

RETURN NIL


// ============================================================================
// MENU PRINCIPAL DEL TEST
// ============================================================================
FUNCTION TestMenu()

    LOCAL oWin
    LOCAL oLbl0
    LOCAL oLbl1
    LOCAL oBt1, oBt2, oBt3
    LOCAL oBt4, oBt5, oBt6
    LOCAL oBtSal

    oWin := TWindow():New( 2, 20, 37, 111, "SUITE DE PRUEBAS - Framework Harbour/WVG" )

    // Subtitulo
    oLbl0 := TLabel():New( 2, 5, ;
        "Seleccione la prueba a ejecutar:", oWin )

    // Separador visual
    oLbl1 := TLabel():New( 3, 5, ;
        Replicate( "-", 70 ), oWin )

    // Fila 1 de botones
    oBt1 := TButton():New( 5,  5, 6, 28, oWin, ;
        "1. Ventana Basica", ;
        {|| TestBasico() } )

    oBt2 := TButton():New( 5, 30, 6, 53, oWin, ;
        "2. Formulario Gets", ;
        {|| TestFormulario() } )

    oBt3 := TButton():New( 5, 55, 6, 78, oWin, ;
        "3. Combos", ;
        {|| TestCombo() } )

    // Fila 2 de botones
    oBt4 := TButton():New( 9,  5, 10, 28, oWin, ;
        "4. Grid de datos", ;
        {|| TestGrid() } )

    oBt5 := TButton():New( 9, 30, 10, 53, oWin, ;
        "5. MsgBox / MsgInfo", ;
        {|| TestMsgBox() } )

    oBt6 := TButton():New( 9, 55, 10, 78, oWin, ;
        "6. MsgYesNo", ;
        {|| TestMsgYesNo() } )

    // Fila 3 de botones
    oBtSal := TButton():New( 13, 5, 14, 28, oWin, ;
        "7. Ventanas Anidadas", ;
        {|| TestAnidado() } )

    // Separador
    oLbl1 := TLabel():New( 18, 5, ;
        Replicate( "-", 70 ), oWin )

    // Boton salir
    oBtSal := TButton():New( 20, 38, 21, 51, oWin, ;
        "SALIR", ;
        {|| oWin:Close() } )

    // Registrar controles
    oWin:AddCtrl( oLbl0 )
    oWin:AddCtrl( oLbl1 )
    oWin:AddCtrl( oBt1  )
    oWin:AddCtrl( oBt2  )
    oWin:AddCtrl( oBt3  )
    oWin:AddCtrl( oBt4  )
    oWin:AddCtrl( oBt5  )
    oWin:AddCtrl( oBt6  )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// TEST 1: VENTANA BASICA
// ----------------------------------------------------------------------------
// Prueba: TWindow + TLabel + TButton
// Verifica:
//   - Apertura y cierre de ventana
//   - Pintado de sombra y marco raised
//   - TLabel muestra texto estatico
//   - TButton recibe foco, responde a ENTER/SPACE
//   - ESC cierra la ventana
// ============================================================================
FUNCTION TestBasico()

    LOCAL oWin
    LOCAL oL1, oL2, oL3
    LOCAL oBt

    oWin := TWindow():New( 8, 30, 30, 100, "TEST 1: Ventana Basica" )

    oL1 := TLabel():New( 2, 3, ;
        "Ventana creada con TWindow():New( nT, nL, nB, nR, cTitulo )", ;
        oWin )

    oL2 := TLabel():New( 4, 3, ;
        "TLabel muestra texto estatico. No recibe foco (lTabStop=.F.)", ;
        oWin )

    oL3 := TLabel():New( 6, 3, ;
        "TButton recibe foco con TAB. ENTER/SPACE ejecuta bAction.", ;
        oWin )

    oBt := TButton():New( 14, 35, 15, 54, oWin, ;
        "CERRAR (ENTER)", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oL1 )
    oWin:AddCtrl( oL2 )
    oWin:AddCtrl( oL3 )
    oWin:AddCtrl( oBt )

    oWin:Run()

RETURN NIL


// ============================================================================
// TEST 2: FORMULARIO CON GETS
// ----------------------------------------------------------------------------
// Prueba: TGet con tipos C, N, D, L + TCheck + TButton
// Verifica:
//   - TGet tipo caracter: edicion libre, cursor visible
//   - TGet tipo numerico: filtrado de teclas
//   - TGet tipo fecha: formato DD/MM/AAAA
//   - TGet tipo logico: ESPACIO alterna Si/No
//   - TCheck: ESPACIO alterna estado marcado/desmarcado
//   - Navegacion TAB / SH_TAB / flechas entre todos los controles
//   - bValid: bloquea salida si campo obligatorio vacio
// ============================================================================
FUNCTION TestFormulario()

    LOCAL oWin
    LOCAL oNom, oEdad, oFecha, oActiv
    LOCAL oChk
    LOCAL oLN, oLE, oLF, oLA, oLC
    LOCAL oBtAcep, oBtCanc

    // Variables a editar
    LOCAL cNombre := Space( 20 )
    LOCAL nEdad   := 0
    LOCAL dAlta   := Date()
    LOCAL lActivo := .T.

    oWin := TWindow():New( 5, 15, 33, 115, "TEST 2: Formulario de Gets" )

    // Etiquetas
    oLN := TLabel():New(  2, 3, "Nombre   :", oWin )
    oLE := TLabel():New(  4, 3, "Edad     :", oWin )
    oLF := TLabel():New(  6, 3, "Alta     :", oWin )
    oLA := TLabel():New(  8, 3, "Activo   :", oWin )
    oLC := TLabel():New( 10, 3, "Acepta   :", oWin )

    // Gets
    oNom := TGet():New(  2, 14, cNombre, "@!", oWin )
    oNom:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oEdad := TGet():New(  4, 14, nEdad, "999", oWin )

    oFecha := TGet():New(  6, 14, dAlta, "99/99/9999", oWin )

    oActiv := TGet():New(  8, 14, lActivo, "L", oWin )

    // Check
    oChk := TCheck():New( 10, 14, "Acepta condiciones de prueba", .F., oWin )

    // Instrucciones
    TLabel():New( 15, 3, ;
        "TAB / SH_TAB / flechas navegan entre campos.", oWin ):Paint()
    TLabel():New( 16, 3, ;
        "Nombre es obligatorio (bValid). ESPACIO en Activo alterna.", oWin ):Paint()

    // Botones
    oBtAcep := TButton():New( 19, 20, 20, 39, oWin, ;
        "ACEPTAR", ;
        {|| MsgInfo( "Formulario aceptado", "Test 2" ), oWin:Close() } )

    oBtCanc := TButton():New( 19, 45, 20, 64, oWin, ;
        "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oLN    )
    oWin:AddCtrl( oLE    )
    oWin:AddCtrl( oLF    )
    oWin:AddCtrl( oLA    )
    oWin:AddCtrl( oLC    )
    oWin:AddCtrl( oNom   )
    oWin:AddCtrl( oEdad  )
    oWin:AddCtrl( oFecha )
    oWin:AddCtrl( oActiv )
    oWin:AddCtrl( oChk   )
    oWin:AddCtrl( oBtAcep )
    oWin:AddCtrl( oBtCanc )

    oWin:Run()

    // Recuperar valores tras cerrar
    cNombre := AllTrim( oNom:uVar )
    nEdad   := oEdad:uVar
    dAlta   := oFecha:uVar
    lActivo := oActiv:uVar

RETURN NIL


// ============================================================================
// TEST 3: COMBOS
// ----------------------------------------------------------------------------
// Prueba: TCombo modo simple y modo asociado
// Verifica:
//   - Combo simple: valor == etiqueta
//   - Combo asociado: xValue = elemento [1], label = elemento [2]
//   - F4 / SPACE abre la lista
//   - Flechas y letras navegan dentro de la lista
//   - ENTER selecciona, ESC cancela
//   - Cierre limpio (sin residuo de relieves WVG)
// ============================================================================
FUNCTION TestCombo()

    LOCAL oWin
    LOCAL oCmb1, oCmb2
    LOCAL aProvincias, aEstados
    LOCAL oBtAcep
    LOCAL oLbl

    // Combo simple
    aProvincias := { ;
        "Almeria", "Cadiz", "Cordoba", ;
        "Granada", "Huelva", "Jaen", ;
        "Malaga",  "Sevilla" }

    // Combo asociado { valor, etiqueta }
    aEstados := { ;
        { 1, "Activo"    }, ;
        { 2, "Pendiente" }, ;
        { 3, "Baja"      }, ;
        { 4, "Bloqueado" } }

    oWin := TWindow():New( 5, 25, 32, 105, "TEST 3: Combos" )

    oLbl := TLabel():New( 2, 3, ;
        "Combo simple (valor = etiqueta):", oWin )

    oCmb1 := TCombo():New( 3, 3, 20, aProvincias, 8, oWin )
    // posicion 8 = Sevilla por defecto

    TLabel():New( 8, 3, ;
        "Combo asociado (xValue = codigo interno):", oWin ):Paint()

    oCmb2 := TCombo():New( 9, 3, 20, aEstados, 1, oWin )

    TLabel():New( 14, 3, ;
        "F4 o ESPACIO abre la lista. Letras buscan. ENTER selecciona.", oWin ):Paint()

    TLabel():New( 15, 3, ;
        "ESC cierra sin cambio. Cierre limpio sin artefactos graficos.", oWin ):Paint()

    oBtAcep := TButton():New( 19, 28, 20, 47, oWin, ;
        "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oLbl  )
    oWin:AddCtrl( oCmb1 )
    oWin:AddCtrl( oCmb2 )
    oWin:AddCtrl( oBtAcep )

    oWin:Run()

RETURN NIL


// ============================================================================
// TEST 4: GRID DE DATOS
// ----------------------------------------------------------------------------
// Prueba: TGrid con aData en memoria
// Verifica:
//   - Cabecera pintada con CLR_GRID_HDR
//   - Navegacion: flechas, PgUp/PgDn, Home/End
//   - Busqueda incremental por letra (nSeekCol = 1)
//   - Fila seleccionada: CLR_GRID_SEL con foco, CLR_GRID_INA sin foco
//   - bEnter: dialogo al pulsar ENTER/F2 sobre una fila
//   - bInsert: mensaje al llegar al final del array
// ============================================================================
FUNCTION TestGrid()

    LOCAL oWin
    LOCAL oGrid
    LOCAL aData
    LOCAL oBtCerrar
    LOCAL oLbl

    // Array de datos de prueba: { Codigo, Nombre, Edad, Saldo }
    aData := { ;
        { "A001", "Almagro Ruiz, Carlos",    42,  1250.50 }, ;
        { "A002", "Benitez Mora, Ana",        35,  3800.00 }, ;
        { "A003", "Carrasco Vidal, Luis",     28,   975.25 }, ;
        { "A004", "Dominguez Pena, Maria",    51,  6100.75 }, ;
        { "A005", "Espinosa Reyes, Jose",     39,  2200.00 }, ;
        { "A006", "Fernandez Alba, Rosa",     45,   430.80 }, ;
        { "A007", "Garcia Soto, Antonio",     60,  9500.00 }, ;
        { "A008", "Herrera Leal, Pilar",      33,  1100.10 }, ;
        { "A009", "Iglesias Mora, Rafael",    47,  3300.50 }, ;
        { "A010", "Jimenez Cruz, Carmen",     29,   780.00 }, ;
        { "A011", "Lopez Rueda, Francisco",   55,  4400.25 }, ;
        { "A012", "Martin Vega, Dolores",     38,  2050.00 }, ;
        { "A013", "Navarro Rios, Miguel",     44,  1600.90 }, ;
        { "A014", "Ortega Sanz, Isabel",      31,   900.00 }, ;
        { "A015", "Perez Blanco, Eduardo",    63, 12000.00 }  }

    oWin := TWindow():New( 2, 5, 37, 125, "TEST 4: Grid de Datos" )

    oGrid := TGrid():New( 2, 1, 29, 117, oWin )

    oGrid:aData    := aData
    oGrid:nSeekCol := 2    // busqueda incremental por Nombre

    oGrid:AddColumn( "Codigo", 6, "@!",         { |a| a[1] } )
    oGrid:AddColumn( "Nombre y Apellidos", 30, "@!",  { |a| a[2] } )
    oGrid:AddColumn( "Edad",   4, "999",        { |a| a[3] } )
    oGrid:AddColumn( "Saldo",  12, "999,999.99", { |a| a[4] } )

    oGrid:bEnter := {| g | ;
        MsgInfo( ;
            "Fila seleccionada: " + g:CurrentRow()[1] + ;
            " - " + AllTrim( g:CurrentRow()[2] ), ;
            "Editar registro" ) }

    oGrid:bInsert := {| g | ;
        MsgInfo( "Aqui se abriria el formulario de alta.", "Nuevo registro" ) }

    oLbl := TLabel():New( 31, 1, ;
        "Flechas/PgUp/PgDn navegan. Letras buscan por Nombre. F2/ENTER abre detalle.", ;
        oWin )

    oBtCerrar := TButton():New( 33, 50, 34, 66, oWin, ;
        "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid     )
    oWin:AddCtrl( oLbl      )
    oWin:AddCtrl( oBtCerrar )

    oWin:Run()

RETURN NIL


// ============================================================================
// TEST 5: MSGBOX / MSGINFO / MSGSTOP
// ----------------------------------------------------------------------------
// Prueba las tres variantes del cuadro de mensaje.
// Verifica:
//   - Apertura centrada en pantalla
//   - Cierre con ENTER / ESC / SPACE
//   - Restauracion limpia de pantalla (sin residuos WVG)
// ============================================================================
FUNCTION TestMsgBox()

    LOCAL oWin
    LOCAL oBt1, oBt2, oBt3, oBtSal

    oWin := TWindow():New( 10, 30, 28, 100, "TEST 5: Cuadros de Mensaje" )

    TLabel():New( 2, 3, ;
        "Cada boton abre un cuadro modal sobre esta ventana.", oWin ):Paint()

    TLabel():New( 3, 3, ;
        "Verificar que al cerrar el cuadro no quedan residuos graficos.", oWin ):Paint()

    oBt1 := TButton():New( 6, 5, 7, 30, oWin, ;
        "MsgBox basico", ;
        {|| MsgBox( "Mensaje de prueba sin wrapper.", "Titulo" ) } )

    oBt2 := TButton():New( 6, 33, 7, 58, oWin, ;
        "MsgInfo", ;
        {|| MsgInfo( "Operacion completada con exito.", "Resultado" ) } )

    oBt3 := TButton():New( 6, 61, 7, 86, oWin, ;
        "MsgStop (error)", ;
        {|| MsgStop( "No se pudo conectar a la BD.", "Conexion" ) } )

    oBtSal := TButton():New( 12, 28, 13, 44, oWin, ;
        "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBt1   )
    oWin:AddCtrl( oBt2   )
    oWin:AddCtrl( oBt3   )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// TEST 6: MSGYESNO
// ----------------------------------------------------------------------------
// Prueba la caja de confirmacion Si/No.
// Verifica:
//   - Flechas izquierda/derecha cambian boton activo (raised/recessed)
//   - ENTER confirma el boton actual
//   - ESC equivale a No
//   - Teclas "S"/"N" seleccion directa
//   - Resultado mostrado en MsgInfo posterior
// ============================================================================
FUNCTION TestMsgYesNo()

    LOCAL oWin
    LOCAL oBt1, oBt2, oBtSal
    LOCAL lRes

    oWin := TWindow():New( 10, 30, 26, 100, "TEST 6: MsgYesNo" )

    TLabel():New( 2, 3, ;
        "MsgYesNo devuelve .T. (SI) o .F. (NO/ESC).", oWin ):Paint()

    TLabel():New( 3, 3, ;
        "Flechas cambian seleccion. S/N seleccion directa.", oWin ):Paint()

    oBt1 := TButton():New( 6, 8, 7, 35, oWin, ;
        "Probar MsgYesNo", ;
        {|| lRes := MsgYesNo( "Desea continuar con la prueba?", "Confirmacion" ), ;
            MsgInfo( If( lRes, "Respondio SI", "Respondio NO" ), "Resultado" ) } )

    oBt2 := TButton():New( 6, 38, 7, 65, oWin, ;
        "Probar MsgConfirm", ;
        {|| lRes := MsgConfirm( "Seguro que desea borrar el registro?", "Atencion" ), ;
            MsgInfo( If( lRes, "Confirmado: SI", "Cancelado: NO" ), "Resultado" ) } )

    oBtSal := TButton():New( 11, 28, 12, 44, oWin, ;
        "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBt1   )
    oWin:AddCtrl( oBt2   )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// TEST 7: VENTANAS ANIDADAS (modal sobre modal)
// ----------------------------------------------------------------------------
// Prueba el apilamiento de ventanas.
// Verifica:
//   - GfxPaintPush/Pop correcto a cada nivel
//   - GfxSave/GfxRestore con coordenadas identicas
//   - Al cerrar la hija, la madre queda intacta (sin fantasmas WVG)
//   - Al cerrar la madre, la pantalla vuelve al menu principal limpia
// ============================================================================
FUNCTION TestAnidado()

    LOCAL oWin1
    LOCAL oBtHija, oBtCerrar

    oWin1 := TWindow():New( 4, 20, 24, 90, "TEST 7: Ventana Nivel 1" )

    TLabel():New( 2, 3, "Esta es la ventana madre (nivel 1).", oWin1 ):Paint()
    TLabel():New( 3, 3, "El boton abre una segunda ventana anidada (nivel 2).", oWin1 ):Paint()
    TLabel():New( 4, 3, "Al cerrar la hija, la madre debe quedar intacta.", oWin1 ):Paint()

    oBtHija := TButton():New( 8, 10, 9, 38, oWin1, ;
        "Abrir ventana hija", ;
        {|| TestAnidadoHija() } )

    oBtCerrar := TButton():New( 14, 26, 15, 42, oWin1, ;
        "CERRAR", ;
        {|| oWin1:Close() } )

    oWin1:AddCtrl( oBtHija   )
    oWin1:AddCtrl( oBtCerrar )

    oWin1:Run()

RETURN NIL


FUNCTION TestAnidadoHija()

    LOCAL oWin2
    LOCAL oBtNieta, oBtCerrar

    oWin2 := TWindow():New( 10, 30, 26, 88, "Ventana Nivel 2 (hija)" )

    TLabel():New( 2, 3, "Ventana hija (nivel 2) sobre la madre.", oWin2 ):Paint()
    TLabel():New( 3, 3, "Al cerrar, los relieves WVG de la madre deben volver.", oWin2 ):Paint()

    oBtNieta := TButton():New( 6, 8, 7, 32, oWin2, ;
        "Abrir nivel 3", ;
        {|| TestAnidadoNieta() } )

    oBtCerrar := TButton():New( 11, 16, 12, 30, oWin2, ;
        "CERRAR", ;
        {|| oWin2:Close() } )

    oWin2:AddCtrl( oBtNieta  )
    oWin2:AddCtrl( oBtCerrar )

    oWin2:Run()

RETURN NIL


FUNCTION TestAnidadoNieta()

    LOCAL oWin3
    LOCAL oBt

    oWin3 := TWindow():New( 14, 35, 26, 90, "Ventana Nivel 3 (nieta)" )

    TLabel():New( 2, 3, "Nivel 3. Al cerrar:", oWin3 ):Paint()
    TLabel():New( 3, 3, " - La hija (nivel 2) debe recuperarse intacta.", oWin3 ):Paint()
    TLabel():New( 4, 3, " - La madre (nivel 1) queda bajo la hija.", oWin3 ):Paint()

    oBt := TButton():New( 7, 13, 8, 29, oWin3, ;
        "CERRAR", ;
        {|| oWin3:Close() } )

    oWin3:AddCtrl( oBt )

    oWin3:Run()

RETURN NIL
