/*
 * ARCHIVO  : Informes.prg
 * PROPOSITO: Informes básicos del sistema.
 *
 * FUNCIONES PUBLICAS
 * ------------------
 *   InformeClientes()    - listado de clientes
 *   InformeFacturas()     - listado de facturas emitidas
 *   InformeArticulos()   - listado de artículos
 *   InformePresupuestos() - listado de presupuestos
 */

#include "OOp.ch"

// ============================================================================
// InformeClientes()
// ============================================================================
FUNCTION InformeClientes()

    LOCAL oWin
    LOCAL oBrw
    LOCAL oBtPrn
    LOCAL oBtSal
    LOCAL cTexto
    LOCAL nArea

    IF !ABRIR_TABLA( "CLIENTES", "CLI_I", "CLI_NOM" )
        RETURN NIL
    ENDIF

    cTexto := ""
    nArea  := Select()

    DbSelectArea( "CLI_I" )
    OrdSetFocus( "CLI_NOM" )
    DbGoTop()

    cTexto += PadC( "INFORME DE CLIENTES", 80 ) + hb_Eol()
    cTexto += Replicate( "-", 80 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()

    cTexto += PadR( "CODIGO", 10 ) + " "
    cTexto += PadR( "NOMBRE", 30 ) + " "
    cTexto += PadR( "NIF", 13 ) + " "
    cTexto += PadR( "CIUDAD", 20 ) + " "
    cTexto += PadR( "TELEFONO", 12 ) + " "
    cTexto += "BAJA" + hb_Eol()

    cTexto += Replicate( "-", 80 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted()
            cTexto += PadR( AllTrim( CLI_I->ID ), 10 ) + " "
            cTexto += PadR( AllTrim( CLI_I->NOMBRE + " " + CLI_I->APELLIDO ), 30 ) + " "
            cTexto += PadR( AllTrim( CLI_I->NIF ), 13 ) + " "
            cTexto += PadR( AllTrim( CLI_I->CIUDAD ), 20 ) + " "
            cTexto += PadR( AllTrim( CLI_I->TELEFONO ), 12 ) + " "
            cTexto += If( CLI_I->BAJA, "SI", "NO" ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

    CLI_I->( DbCloseArea() )
    Select( nArea )

    oWin := TWindow():New( 1, 2, 37, 129, "INFORME DE CLIENTES" )

    oBrw := TLabel():New( 2, 2, cTexto, oWin )
    oBrw:cColor := "W+/N"

    oBtPrn := TButton():New( 33, 40, 34, 59, oWin, "IMPRIMIR", ;
        {|| _ImpTexto( cTexto, "INFORME_CLIENTES.TXT" ) } )

    oBtSal := TButton():New( 33, 63, 34, 82, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBrw   )
    oWin:AddCtrl( oBtPrn )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// InformeFacturas()
// ============================================================================
FUNCTION InformeFacturas()

    LOCAL oWin
    LOCAL oBrw
    LOCAL oBtPrn
    LOCAL oBtSal
    LOCAL cTexto
    LOCAL nArea

    IF !ABRIR_TABLA( "FACTURA", "FAC_I", "FAC_FEC" )
        RETURN NIL
    ENDIF

    cTexto := ""
    nArea  := Select()

    DbSelectArea( "FAC_I" )
    OrdSetFocus( "FAC_FEC" )
    DbGoTop()

    cTexto += PadC( "INFORME DE FACTURAS EMITIDAS", 80 ) + hb_Eol()
    cTexto += Replicate( "-", 80 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()

    cTexto += PadR( "NUMERO", 10 ) + " "
    cTexto += PadR( "FECHA", 10 ) + " "
    cTexto += PadR( "CLIENTE", 30 ) + " "
    cTexto += PadL( "BASE", 12 ) + " "
    cTexto += PadL( "IVA", 10 ) + " "
    cTexto += PadL( "TOTAL", 12 ) + " "
    cTexto += "COBRADA" + hb_Eol()

    cTexto += Replicate( "-", 80 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted()
            cTexto += PadR( AllTrim( FAC_I->NUMERO ), 10 ) + " "
            cTexto += PadR( DToC( FAC_I->FECHA ), 10 ) + " "
            cTexto += PadR( AllTrim( FAC_I->CLIENTE_ ), 30 ) + " "
            cTexto += PadL( Transform( FAC_I->SUBTOTAL, "999,999.99" ), 12 ) + " "
            cTexto += PadL( Transform( FAC_I->IVA, "999,999.99" ), 10 ) + " "
            cTexto += PadL( Transform( FAC_I->TOTAL, "999,999.99" ), 12 ) + " "
            cTexto += If( FAC_I->COBRADA, "SI", "NO" ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

    FAC_I->( DbCloseArea() )
    Select( nArea )

    oWin := TWindow():New( 1, 2, 37, 129, "INFORME DE FACTURAS" )

    oBrw := TLabel():New( 2, 2, cTexto, oWin )
    oBrw:cColor := "W+/N"

    oBtPrn := TButton():New( 33, 40, 34, 59, oWin, "IMPRIMIR", ;
        {|| _ImpTexto( cTexto, "INFORME_FACTURAS.TXT" ) } )

    oBtSal := TButton():New( 33, 63, 34, 82, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBrw   )
    oWin:AddCtrl( oBtPrn )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// InformeArticulos()
// ============================================================================
FUNCTION InformeArticulos()

    LOCAL oWin
    LOCAL oBrw
    LOCAL oBtPrn
    LOCAL oBtSal
    LOCAL cTexto
    LOCAL nArea

    IF !ABRIR_TABLA( "ARTICULOS", "ART_I", "ART_DES" )
        RETURN NIL
    ENDIF

    cTexto := ""
    nArea  := Select()

    DbSelectArea( "ART_I" )
    OrdSetFocus( "ART_DES" )
    DbGoTop()

    cTexto += PadC( "INFORME DE ARTICULOS", 80 ) + hb_Eol()
    cTexto += Replicate( "-", 80 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()

    cTexto += PadR( "CODIGO", 10 ) + " "
    cTexto += PadR( "DESCRIPCION", 40 ) + " "
    cTexto += PadL( "STOCK", 12 ) + " "
    cTexto += PadL( "PRECIO", 12 ) + " "
    cTexto += PadR( "FAMILIA", 3 ) + " "
    cTexto += "BAJA" + hb_Eol()

    cTexto += Replicate( "-", 80 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted()
            cTexto += PadR( AllTrim( ART_I->CODIGO ), 10 ) + " "
            cTexto += PadR( AllTrim( ART_I->DESCRIP ), 40 ) + " "
            cTexto += PadL( Transform( ART_I->STOCK, "999,999.99" ), 12 ) + " "
            cTexto += PadL( Transform( ART_I->PRECIO, "999,999.99" ), 12 ) + " "
            cTexto += PadR( AllTrim( ART_I->FAMILIA ), 3 ) + " "
            cTexto += If( ART_I->BAJA, "SI", "NO" ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

    ART_I->( DbCloseArea() )
    Select( nArea )

    oWin := TWindow():New( 1, 2, 37, 129, "INFORME DE ARTICULOS" )

    oBrw := TLabel():New( 2, 2, cTexto, oWin )
    oBrw:cColor := "W+/N"

    oBtPrn := TButton():New( 33, 40, 34, 59, oWin, "IMPRIMIR", ;
        {|| _ImpTexto( cTexto, "INFORME_ARTICULOS.TXT" ) } )

    oBtSal := TButton():New( 33, 63, 34, 82, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBrw   )
    oWin:AddCtrl( oBtPrn )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// InformePresupuestos()
// ============================================================================
FUNCTION InformePresupuestos()

    LOCAL oWin
    LOCAL oBrw
    LOCAL oBtPrn
    LOCAL oBtSal
    LOCAL cTexto
    LOCAL nArea

    IF !ABRIR_TABLA( "PRESUPUEST", "PRE_I", "PRE_FEC" )
        RETURN NIL
    ENDIF

    cTexto := ""
    nArea  := Select()

    DbSelectArea( "PRE_I" )
    OrdSetFocus( "PRE_FEC" )
    DbGoTop()

    cTexto += PadC( "INFORME DE PRESUPUESTOS", 80 ) + hb_Eol()
    cTexto += Replicate( "-", 80 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()

    cTexto += PadR( "NUMERO", 10 ) + " "
    cTexto += PadR( "FECHA", 10 ) + " "
    cTexto += PadR( "CLIENTE", 30 ) + " "
    cTexto += PadL( "TOTAL", 12 ) + " "
    cTexto += PadR( "ESTADO", 8 ) + " "
    cTexto += "FACTURA" + hb_Eol()

    cTexto += Replicate( "-", 80 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted()
            cTexto += PadR( AllTrim( PRE_I->NUMERO ), 10 ) + " "
            cTexto += PadR( DToC( PRE_I->FECHA ), 10 ) + " "
            cTexto += PadR( AllTrim( PRE_I->CLIENTE_ ), 30 ) + " "
            cTexto += PadL( Transform( PRE_I->TOTAL, "999,999.99" ), 12 ) + " "
            cTexto += PadR( If( PRE_I->ESTADO == "F", "FACTURADO", If( PRE_I->ESTADO == "A", "ACEPTADO", "PENDIENTE" ) ), 8 ) + " "
            cTexto += PadR( AllTrim( PRE_I->NUM_FAC ), 10 ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

    PRE_I->( DbCloseArea() )
    Select( nArea )

    oWin := TWindow():New( 1, 2, 37, 129, "INFORME DE PRESUPUESTOS" )

    oBrw := TLabel():New( 2, 2, cTexto, oWin )
    oBrw:cColor := "W+/N"

    oBtPrn := TButton():New( 33, 40, 34, 59, oWin, "IMPRIMIR", ;
        {|| _ImpTexto( cTexto, "INFORME_PRESUPUESTOS.TXT" ) } )

    oBtSal := TButton():New( 33, 63, 34, 82, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBrw   )
    oWin:AddCtrl( oBtPrn )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// _ImpTexto()
// ============================================================================
STATIC FUNCTION _ImpTexto( cTexto, cFile )

    LOCAL cPath

    cPath := ".\INFORME\" 
    IF !DirExiste( cPath )
        DirMake( cPath )
    ENDIF

    hb_MemoWrit( cPath + cFile, cTexto )

    MsgInfo( "Informe guardado en: " + cPath + cFile, "Impresión" )

RETURN NIL


// ============================================================================
// FIN DE Informes.prg
// ============================================================================
