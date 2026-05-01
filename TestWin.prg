#include "OOp.ch"

// ----------------------------------------------------------------------------
// PROCEDIMIENTO: Main
// ----------------------------------------------------------------------------
PROCEDURE Main()
    LOCAL bErrOld

    bErrOld := ErrorBlock( { |oErr| ErrSys( oErr ) } )

    InitApp( 40, 132 )

    FormMadre()

    ErrorBlock( bErrOld )
RETURN


// ----------------------------------------------------------------------------
// FUNCION: FormMadre
// Ventana principal con un boton que abre una ventana anidada (hija).
// PRUEBA CRITICA del stack de pintado: al cerrar la hija, la madre debe
// quedar intacta (marco, sombra, controles, todo).
// ----------------------------------------------------------------------------
FUNCTION FormMadre()
    LOCAL oWin
    LOCAL oBtnOk, oBtnCan, oBtnDet
    LOCAL oLb1, oLb2, oLb3, oLb4
    LOCAL oGe1, oGe2
    LOCAL oCmb
    LOCAL oChk
    LOCAL cNom    := Space( 20 )
    LOCAL nEdad   := Space( 03 )
    LOCAL aProvs  := { ;
        { 1, "Sevilla"   }, ;
        { 2, "Cordoba"   }, ;
        { 3, "Malaga"    }, ;
        { 4, "Granada"   }, ;
        { 5, "Cadiz"     }, ;
        { 6, "Huelva"    }, ;
        { 7, "Almeria"   }, ;
        { 8, "Jaen"      }, ;
        { 9, "Valencia"  }, ;
        {10, "Madrid"    }, ;
        {11, "Barcelona" }, ;
        {12, "Bilbao"    } }

    // Ventana MADRE - centrada y grande
    oWin := TWindow():New( 08, 30, 30, 100, "Datos del Cliente (MADRE)" )

    // Etiquetas
    oLb1 := TLabel():New( 03, 02, "Nombre....:", oWin )
    oLb2 := TLabel():New( 05, 02, "Edad......:", oWin )
    oLb3 := TLabel():New( 07, 02, "Provincia.:", oWin )
    oLb4 := TLabel():New( 09, 02, "Opciones..:", oWin )

    // Gets
    oGe1 := TGet():New( 03, 14, cNom, "@!", oWin )
    oGe2 := TGet():New( 05, 14, nEdad, "999", oWin )

    // Combo provincias
    oCmb := TCombo():New( 07, 14, 20, aProvs, 1, oWin )

    // Check activo
    oChk := TCheck():New( 09, 14, "Cliente activo", .T., oWin )

    // BOTON QUE ABRE VENTANA HIJA
    oBtnDet := TButton():New( 13, 14, 13, 40, oWin, "DETALLE >>", ;
                              { || FormHija( oWin ) } )

    // Botones aceptar/cancelar
    oBtnOk  := TButton():New( 16, 15, 16, 30, oWin, "ACEPTAR",  ;
                              { || oWin:Close() } )
    oBtnCan := TButton():New( 16, 35, 16, 50, oWin, "CANCELAR", ;
                              { || oWin:Close() } )

    // Registro de controles
    oWin:AddCtrl( oLb1 )
    oWin:AddCtrl( oLb2 )
    oWin:AddCtrl( oLb3 )
    oWin:AddCtrl( oLb4 )
    oWin:AddCtrl( oGe1 )
    oWin:AddCtrl( oGe2 )
    oWin:AddCtrl( oCmb )
    oWin:AddCtrl( oChk )
    oWin:AddCtrl( oBtnDet )
    oWin:AddCtrl( oBtnOk )
    oWin:AddCtrl( oBtnCan )

    oWin:Run()

RETURN NIL


// ----------------------------------------------------------------------------
// FUNCION: FormHija
// Ventana hija que se abre encima de la madre.  Al cerrarse, debe
// dejar la madre INTACTA (con todos sus relieves y controles).
// ----------------------------------------------------------------------------
FUNCTION FormHija( oMadre )
    LOCAL oWin
    LOCAL oLb1
    LOCAL oGe1
    LOCAL oBtnCer
    LOCAL cObs := Space( 30 )

    HB_SYMBOL_UNUSED( oMadre )

    // Ventana HIJA - posicionada para tapar claramente varios controles
    // de la madre (TGets, TCombo, TCheck) y verificar visualmente que
    // la hija es opaca.  Cubre desde col 35 hasta col 90, fila 12 a 22.
    oWin := TWindow():New( 12, 35, 22, 90, "DETALLE (HIJA)" )

    oLb1    := TLabel():New(  03, 02, "Notas:", oWin )
    oGe1    := TGet():New(    03, 09, cObs, "@!S30", oWin )
    oBtnCer := TButton():New( 06, 25, 06, 40, oWin, "CERRAR", ;
                              { || oWin:Close() } )

    oWin:AddCtrl( oLb1 )
    oWin:AddCtrl( oGe1 )
    oWin:AddCtrl( oBtnCer )

    oWin:Run()

RETURN NIL
