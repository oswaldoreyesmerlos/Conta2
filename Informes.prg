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
// InformeVencimientos()
// Facturas emitidas pendientes de cobro ordenadas por fecha vencimiento
// ============================================================================
FUNCTION InformeVencimientos()

    LOCAL oWin
    LOCAL oBrw
    LOCAL oBtPrn
    LOCAL oBtSal
    LOCAL cTexto
    LOCAL nArea
    LOCAL nDias
    LOCAL cAlerta

    IF !ABRIR_TABLA( "FACTURA", "FAC_IV", "FAC_VTO" )
        RETURN NIL
    ENDIF

    cTexto := ""
    nArea  := Select()

    DbSelectArea( "FAC_IV" )
    OrdSetFocus( "FAC_VTO" )
    DbGoTop()

    cTexto += PadC( "VENCIMIENTOS PENDIENTES DE COBRO", 90 ) + hb_Eol()
    cTexto += Replicate( "-", 90 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()
    cTexto += PadR( "FACTURA",   10 ) + " "
    cTexto += PadR( "F.EMISION", 10 ) + " "
    cTexto += PadR( "F.VENCTO",  10 ) + " "
    cTexto += PadR( "CLIENTE",   30 ) + " "
    cTexto += PadL( "TOTAL",     12 ) + " "
    cTexto += "ESTADO" + hb_Eol()
    cTexto += Replicate( "-", 90 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted() .AND. !FAC_IV->COBRADA .AND. !FAC_IV->ANULADA
            nDias   := Date() - FAC_IV->FECHA_VT
            cAlerta := If( nDias > 0, "VENCIDA +" + AllTrim( Str( nDias ) ) + "d", ;
                       If( nDias > -7, "PROXIMA", "OK" ) )
            cTexto += PadR( AllTrim( FAC_IV->NUMERO   ), 10 ) + " "
            cTexto += PadR( DToC(    FAC_IV->FECHA    ), 10 ) + " "
            cTexto += PadR( DToC(    FAC_IV->FECHA_VT ), 10 ) + " "
            cTexto += PadR( AllTrim( FAC_IV->CLIENTE_ ), 30 ) + " "
            cTexto += PadL( Transform( FAC_IV->TOTAL, "999,999.99" ), 12 ) + " "
            cTexto += cAlerta + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

    FAC_IV->( DbCloseArea() )
    Select( nArea )

    oWin   := TWindow():New( 1, 2, 37, 129, "VENCIMIENTOS PENDIENTES" )
    oBrw   := TLabel():New( 2, 2, cTexto, oWin )
    oBrw:cColor := "W+/N"

    oBtPrn := TButton():New( 33, 40, 34, 59, oWin, "IMPRIMIR", ;
        {|| _ImpTexto( cTexto, "VENCIMIENTOS.TXT" ) } )

    oBtSal := TButton():New( 33, 63, 34, 82, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBrw   )
    oWin:AddCtrl( oBtPrn )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// InformeProveedores()
// ============================================================================
FUNCTION InformeProveedores()

    LOCAL oWin
    LOCAL oBrw
    LOCAL oBtPrn
    LOCAL oBtSal
    LOCAL cTexto
    LOCAL nArea

    IF !ABRIR_TABLA( "PROVEED", "PRV_IP", "PRV_NOM" )
        RETURN NIL
    ENDIF

    cTexto := ""
    nArea  := Select()

    DbSelectArea( "PRV_IP" )
    OrdSetFocus( "PRV_NOM" )
    DbGoTop()

    cTexto += PadC( "INFORME DE PROVEEDORES", 80 ) + hb_Eol()
    cTexto += Replicate( "-", 80 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()
    cTexto += PadR( "CODIGO",   10 ) + " "
    cTexto += PadR( "NOMBRE",   30 ) + " "
    cTexto += PadR( "NIF",      13 ) + " "
    cTexto += PadR( "CIUDAD",   15 ) + " "
    cTexto += PadR( "TELEFONO", 12 ) + " "
    cTexto += "BAJA" + hb_Eol()
    cTexto += Replicate( "-", 80 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted()
            cTexto += PadR( AllTrim( PRV_IP->ID       ), 10 ) + " "
            cTexto += PadR( AllTrim( PRV_IP->NOMBRE + " " + PRV_IP->APELLIDO ), 30 ) + " "
            cTexto += PadR( AllTrim( PRV_IP->NIF      ), 13 ) + " "
            cTexto += PadR( AllTrim( PRV_IP->CIUDAD   ), 15 ) + " "
            cTexto += PadR( AllTrim( PRV_IP->TELEFONO ), 12 ) + " "
            cTexto += If( PRV_IP->BAJA, "SI", "NO" ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

    PRV_IP->( DbCloseArea() )
    Select( nArea )

    oWin   := TWindow():New( 1, 2, 37, 129, "INFORME DE PROVEEDORES" )
    oBrw   := TLabel():New( 2, 2, cTexto, oWin )
    oBrw:cColor := "W+/N"

    oBtPrn := TButton():New( 33, 40, 34, 59, oWin, "IMPRIMIR", ;
        {|| _ImpTexto( cTexto, "PROVEEDORES.TXT" ) } )

    oBtSal := TButton():New( 33, 63, 34, 82, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBrw   )
    oWin:AddCtrl( oBtPrn )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// InformeDiario()
// Libro diario contable del ejercicio actual
// ============================================================================
FUNCTION InformeDiario()

    LOCAL oWin
    LOCAL oBrw
    LOCAL oBtPrn
    LOCAL oBtSal
    LOCAL cTexto
    LOCAL nArea
    LOCAL nEjer
    LOCAL nDebe
    LOCAL nHaber

    IF !ABRIR_TABLA( "LDIARIO", "DIA_IP", "DIA_FEC" )
        RETURN NIL
    ENDIF

    cTexto := ""
    nArea  := Select()
    nEjer  := Year( Date() )
    nDebe  := 0
    nHaber := 0

    DbSelectArea( "DIA_IP" )
    OrdSetFocus( "DIA_FEC" )
    DbGoTop()

    cTexto += PadC( "LIBRO DIARIO - EJERCICIO " + AllTrim( Str( nEjer ) ), 100 ) + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()
    cTexto += PadR( "ASIENTO",  10 ) + " "
    cTexto += PadR( "L",         2 ) + " "
    cTexto += PadR( "FECHA",    10 ) + " "
    cTexto += PadR( "CUENTA",   10 ) + " "
    cTexto += PadL( "DEBE",     12 ) + " "
    cTexto += PadL( "HABER",    12 ) + " "
    cTexto += "DESCRIPCION" + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted() .AND. Year( DIA_IP->D_FECHA ) == nEjer
            nDebe  += DIA_IP->D_DEBE
            nHaber += DIA_IP->D_HABER
            cTexto += PadR( AllTrim( DIA_IP->D_ASIENT ), 10 ) + " "
            cTexto += PadR( AllTrim( Str( DIA_IP->D_LINEA, 2 ) ),  2 ) + " "
            cTexto += PadR( DToC(    DIA_IP->D_FECHA  ), 10 ) + " "
            cTexto += PadR( AllTrim( DIA_IP->D_CUENTA ), 10 ) + " "
            cTexto += PadL( Transform( DIA_IP->D_DEBE,  "999,999.99" ), 12 ) + " "
            cTexto += PadL( Transform( DIA_IP->D_HABER, "999,999.99" ), 12 ) + " "
            cTexto += AllTrim( DIA_IP->D_DESCRI ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

    cTexto += Replicate( "-", 100 ) + hb_Eol()
    cTexto += PadR( "TOTALES", 25 ) + " "
    cTexto += PadL( Transform( nDebe,  "999,999,999.99" ), 14 ) + " "
    cTexto += PadL( Transform( nHaber, "999,999,999.99" ), 14 ) + " "
    cTexto += hb_Eol()

    DIA_IP->( DbCloseArea() )
    Select( nArea )

    oWin   := TWindow():New( 1, 2, 37, 129, "LIBRO DIARIO " + AllTrim( Str( nEjer ) ) )
    oBrw   := TLabel():New( 2, 2, cTexto, oWin )
    oBrw:cColor := "W+/N"

    oBtPrn := TButton():New( 33, 40, 34, 59, oWin, "IMPRIMIR", ;
        {|| _ImpTexto( cTexto, "LDIARIO_" + AllTrim( Str( nEjer ) ) + ".TXT" ) } )

    oBtSal := TButton():New( 33, 63, 34, 82, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBrw   )
    oWin:AddCtrl( oBtPrn )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// InformeStockMinimo()
// Articulos con stock actual por debajo del minimo definido
// ============================================================================
FUNCTION InformeStockMinimo()

    LOCAL oWin
    LOCAL oBrw
    LOCAL oBtPrn
    LOCAL oBtSal
    LOCAL cTexto
    LOCAL nArea
    LOCAL nCont

    IF !ABRIR_TABLA( "ARTICULOS", "ART_SM", "ART_DES" )
        RETURN NIL
    ENDIF

    cTexto := ""
    nArea  := Select()
    nCont  := 0

    DbSelectArea( "ART_SM" )
    OrdSetFocus( "ART_DES" )
    DbGoTop()

    cTexto += PadC( "ARTICULOS POR DEBAJO DE STOCK MINIMO", 85 ) + hb_Eol()
    cTexto += Replicate( "-", 85 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()
    cTexto += PadR( "CODIGO",     10 ) + " "
    cTexto += PadR( "DESCRIPCION",40 ) + " "
    cTexto += PadL( "STOCK ACT.", 10 ) + " "
    cTexto += PadL( "STOCK MIN.", 10 ) + " "
    cTexto += PadL( "DIFERENCIA", 10 ) + " "
    cTexto += "UNIDAD" + hb_Eol()
    cTexto += Replicate( "-", 85 ) + hb_Eol()

    DO WHILE !Eof()
        IF !Deleted() .AND. !ART_SM->BAJA .AND. !ART_SM->ES_SERV
            IF ART_SM->STOCK < ART_SM->STO_MIN
                nCont++
                cTexto += PadR( AllTrim( ART_SM->CODIGO  ), 10 ) + " "
                cTexto += PadR( AllTrim( ART_SM->DESCRIP ), 40 ) + " "
                cTexto += PadL( AllTrim( Str( ART_SM->STOCK,   10, 2 ) ), 10 ) + " "
                cTexto += PadL( AllTrim( Str( ART_SM->STO_MIN, 10, 2 ) ), 10 ) + " "
                cTexto += PadL( AllTrim( Str( ART_SM->STO_MIN - ART_SM->STOCK, 10, 2 ) ), 10 ) + " "
                cTexto += AllTrim( ART_SM->UNIDAD ) + hb_Eol()
            ENDIF
        ENDIF
        DbSkip()
    ENDDO

    cTexto += Replicate( "-", 85 ) + hb_Eol()
    cTexto += "Total articulos bajo minimo: " + AllTrim( Str( nCont ) ) + hb_Eol()

    ART_SM->( DbCloseArea() )
    Select( nArea )

    oWin   := TWindow():New( 1, 2, 37, 129, "ARTICULOS BAJO STOCK MINIMO" )
    oBrw   := TLabel():New( 2, 2, cTexto, oWin )
    oBrw:cColor := "W+/N"

    oBtPrn := TButton():New( 33, 40, 34, 59, oWin, "IMPRIMIR", ;
        {|| _ImpTexto( cTexto, "STOCK_MINIMO.TXT" ) } )

    oBtSal := TButton():New( 33, 63, 34, 82, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oBrw   )
    oWin:AddCtrl( oBtPrn )
    oWin:AddCtrl( oBtSal )

    oWin:Run()

RETURN NIL


// ============================================================================
// FIN DE Informes.prg
// ============================================================================
