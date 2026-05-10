/*
 * ARCHIVO  : Informes.prg
 * PROPOSITO: Informes básicos del sistema.
 *
 * FUNCIONES PUBLICAS
 * ------------------
 *   InformeClientes()    - listado de clientes
 *   InformeFacturas()     - listado de facturas emitidas
 *   InformePresupuestos() - listado de presupuestos
 */

#include "OOp.ch"

// ============================================================================
// InformeClientes()
// ============================================================================
FUNCTION InformeClientes()

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

RETURN _MostrarInformeTexto( "INFORME DE CLIENTES", cTexto, "INFORME_CLIENTES.TXT" )


// ============================================================================
// InformeFacturas()
// ============================================================================
FUNCTION InformeFacturas()

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
            cTexto += If( DbFieldValue( "COBRADA", .F. ), "SI", "NO" ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

    FAC_I->( DbCloseArea() )
    Select( nArea )

RETURN _MostrarInformeTexto( "INFORME DE FACTURAS", cTexto, "INFORME_FACTURAS.TXT" )


// ============================================================================
// InformePresupuestos()
// ============================================================================
FUNCTION InformePresupuestos()

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

RETURN _MostrarInformeTexto( "INFORME DE PRESUPUESTOS", cTexto, "INFORME_PRESUPUESTOS.TXT" )


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
        IF !Deleted() .AND. !DbFieldValue( "COBRADA", .F. ) .AND. ;
           !DbFieldValue( "ANULADA", .F. )
            nDias   := Date() - DbFieldValue( "FECHA_VT", FAC_IV->FECHA )
            cAlerta := If( nDias > 0, "VENCIDA +" + AllTrim( Str( nDias ) ) + "d", ;
                       If( nDias > -7, "PROXIMA", "OK" ) )
            cTexto += PadR( AllTrim( FAC_IV->NUMERO   ), 10 ) + " "
            cTexto += PadR( DToC(    FAC_IV->FECHA    ), 10 ) + " "
            cTexto += PadR( DToC( DbFieldValue( "FECHA_VT", FAC_IV->FECHA ) ), 10 ) + " "
            cTexto += PadR( AllTrim( FAC_IV->CLIENTE_ ), 30 ) + " "
            cTexto += PadL( Transform( FAC_IV->TOTAL, "999,999.99" ), 12 ) + " "
            cTexto += cAlerta + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

    FAC_IV->( DbCloseArea() )
    Select( nArea )

RETURN _MostrarInformeTexto( "VENCIMIENTOS PENDIENTES", cTexto, "VENCIMIENTOS.TXT" )


// ============================================================================
// InformeProveedores()
// ============================================================================
FUNCTION InformeProveedores()

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

RETURN _MostrarInformeTexto( "INFORME DE PROVEEDORES", cTexto, "PROVEEDORES.TXT" )


// ============================================================================
// InformeDiario()
// Libro diario contable del ejercicio actual
// ============================================================================
FUNCTION InformeDiario()

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

RETURN _MostrarInformeTexto( "LIBRO DIARIO " + AllTrim( Str( nEjer ) ), cTexto, ;
    "LDIARIO_" + AllTrim( Str( nEjer ) ) + ".TXT" )


// ============================================================================
// InformeMayor()
// Mayor contable por cuenta para el ejercicio actual.
// ============================================================================
FUNCTION InformeMayor()

    LOCAL cCuenta

    cCuenta := Space( 10 )

    IF !_PideCuenta( @cCuenta, "MAYOR DE CUENTA" )
        RETURN NIL
    ENDIF

RETURN _InformeMayorCuenta( AllTrim( cCuenta ) )


STATIC FUNCTION _InformeMayorCuenta( cCuenta )

    LOCAL cTexto
    LOCAL nArea
    LOCAL nEjer
    LOCAL nSaldo

    IF Empty( cCuenta )
        RETURN NIL
    ENDIF

    IF !ABRIR_TABLA( "LDIARIO", "DIA_MR", "DIA_MAY" )
        RETURN NIL
    ENDIF

    cTexto := ""
    nArea  := Select()
    nEjer  := Year( Date() )
    nSaldo := 0

    DbSelectArea( "DIA_MR" )
    OrdSetFocus( "DIA_MAY" )
    DbSeek( PadR( cCuenta, 10 ) )

    cTexto += PadC( "LIBRO MAYOR - CUENTA " + cCuenta + " - EJERCICIO " + ;
                    AllTrim( Str( nEjer ) ), 110 ) + hb_Eol()
    cTexto += Replicate( "-", 110 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()
    cTexto += PadR( "FECHA",    10 ) + " "
    cTexto += PadR( "ASIENTO",  10 ) + " "
    cTexto += PadL( "DEBE",     14 ) + " "
    cTexto += PadL( "HABER",    14 ) + " "
    cTexto += PadL( "SALDO",    14 ) + " "
    cTexto += "DESCRIPCION" + hb_Eol()
    cTexto += Replicate( "-", 110 ) + hb_Eol()

    DO WHILE !Eof() .AND. AllTrim( DIA_MR->D_CUENTA ) == cCuenta
        IF !Deleted() .AND. Year( DIA_MR->D_FECHA ) == nEjer
            nSaldo += DIA_MR->D_DEBE - DIA_MR->D_HABER
            cTexto += PadR( DToC( DIA_MR->D_FECHA ), 10 ) + " "
            cTexto += PadR( AllTrim( DIA_MR->D_ASIENT ), 10 ) + " "
            cTexto += PadL( Transform( DIA_MR->D_DEBE,  "999,999.99" ), 14 ) + " "
            cTexto += PadL( Transform( DIA_MR->D_HABER, "999,999.99" ), 14 ) + " "
            cTexto += PadL( Transform( nSaldo, "999,999.99" ), 14 ) + " "
            cTexto += AllTrim( DIA_MR->D_DESCRI ) + hb_Eol()
        ENDIF
        DbSkip()
    ENDDO

    cTexto += Replicate( "-", 110 ) + hb_Eol()
    cTexto += "SALDO FINAL: " + Transform( nSaldo, "999,999,999.99" ) + hb_Eol()

    DIA_MR->( DbCloseArea() )
    Select( nArea )

RETURN _MostrarInformeTexto( "MAYOR " + cCuenta, cTexto, ;
    "MAYOR_" + cCuenta + "_" + AllTrim( Str( nEjer ) ) + ".TXT" )


// ============================================================================
// InformeBalanceSumasSaldos()
// ============================================================================
FUNCTION InformeBalanceSumasSaldos()

    LOCAL aSaldos
    LOCAL cTexto
    LOCAL nEjer
    LOCAL i
    LOCAL nSaldo
    LOCAL nDeudor
    LOCAL nAcreed
    LOCAL nTotDebe
    LOCAL nTotHaber
    LOCAL nTotDeu
    LOCAL nTotAcr

    nEjer     := Year( Date() )
    aSaldos   := _ContSaldosEjercicio( nEjer )
    cTexto    := ""
    nTotDebe  := 0
    nTotHaber := 0
    nTotDeu   := 0
    nTotAcr   := 0

    cTexto += PadC( "BALANCE DE SUMAS Y SALDOS - EJERCICIO " + ;
                    AllTrim( Str( nEjer ) ), 110 ) + hb_Eol()
    cTexto += Replicate( "-", 110 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()
    cTexto += PadR( "CUENTA", 10 ) + " "
    cTexto += PadR( "NOMBRE", 38 ) + " "
    cTexto += PadL( "DEBE", 14 ) + " "
    cTexto += PadL( "HABER", 14 ) + " "
    cTexto += PadL( "DEUDOR", 14 ) + " "
    cTexto += PadL( "ACREEDOR", 14 ) + hb_Eol()
    cTexto += Replicate( "-", 110 ) + hb_Eol()

    FOR i := 1 TO Len( aSaldos )
        nSaldo  := aSaldos[i, 3] - aSaldos[i, 4]
        nDeudor := If( nSaldo > 0, nSaldo, 0 )
        nAcreed := If( nSaldo < 0, Abs( nSaldo ), 0 )
        nTotDebe  += aSaldos[i, 3]
        nTotHaber += aSaldos[i, 4]
        nTotDeu   += nDeudor
        nTotAcr   += nAcreed

        cTexto += PadR( aSaldos[i, 1], 10 ) + " "
        cTexto += PadR( aSaldos[i, 2], 38 ) + " "
        cTexto += PadL( Transform( aSaldos[i, 3], "999,999.99" ), 14 ) + " "
        cTexto += PadL( Transform( aSaldos[i, 4], "999,999.99" ), 14 ) + " "
        cTexto += PadL( Transform( nDeudor, "999,999.99" ), 14 ) + " "
        cTexto += PadL( Transform( nAcreed, "999,999.99" ), 14 ) + hb_Eol()
    NEXT

    cTexto += Replicate( "-", 110 ) + hb_Eol()
    cTexto += PadR( "TOTALES", 49 ) + " "
    cTexto += PadL( Transform( nTotDebe,  "999,999,999.99" ), 14 ) + " "
    cTexto += PadL( Transform( nTotHaber, "999,999,999.99" ), 14 ) + " "
    cTexto += PadL( Transform( nTotDeu,   "999,999,999.99" ), 14 ) + " "
    cTexto += PadL( Transform( nTotAcr,   "999,999,999.99" ), 14 ) + hb_Eol()

RETURN _MostrarInformeTexto( "BALANCE SUMAS Y SALDOS", cTexto, ;
    "BALANCE_SUMAS_SALDOS_" + AllTrim( Str( nEjer ) ) + ".TXT" )


// ============================================================================
// InformeBalanceGeneral()
// ============================================================================
FUNCTION InformeBalanceGeneral()

    LOCAL aSaldos
    LOCAL cTexto
    LOCAL nEjer
    LOCAL i
    LOCAL cTipo
    LOCAL nSaldo
    LOCAL nActivo
    LOCAL nPasivo
    LOCAL nGastos
    LOCAL nIngresos
    LOCAL nResultado

    nEjer   := Year( Date() )
    aSaldos := _ContSaldosEjercicio( nEjer )
    cTexto  := ""
    nActivo := 0
    nPasivo := 0
    nGastos := 0
    nIngresos := 0
    nResultado := 0

    cTexto += PadC( "BALANCE GENERAL - EJERCICIO " + ;
                    AllTrim( Str( nEjer ) ), 100 ) + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()
    cTexto += PadR( "CUENTA", 10 ) + " "
    cTexto += PadR( "NOMBRE", 50 ) + " "
    cTexto += PadL( "ACTIVO", 14 ) + " "
    cTexto += PadL( "PASIVO/PN", 14 ) + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()

    FOR i := 1 TO Len( aSaldos )
        cTipo  := _CuentaTipo( aSaldos[i, 1] )
        nSaldo := aSaldos[i, 3] - aSaldos[i, 4]
        IF cTipo == "A"
            nActivo += nSaldo
            cTexto += PadR( aSaldos[i, 1], 10 ) + " "
            cTexto += PadR( aSaldos[i, 2], 50 ) + " "
            cTexto += PadL( Transform( nSaldo, "999,999.99" ), 14 ) + " "
            cTexto += PadL( "", 14 ) + hb_Eol()
        ELSEIF cTipo == "P"
            nPasivo += -nSaldo
            cTexto += PadR( aSaldos[i, 1], 10 ) + " "
            cTexto += PadR( aSaldos[i, 2], 50 ) + " "
            cTexto += PadL( "", 14 ) + " "
            cTexto += PadL( Transform( -nSaldo, "999,999.99" ), 14 ) + hb_Eol()
        ELSEIF cTipo == "G"
            nGastos += nSaldo
        ELSEIF cTipo == "I"
            nIngresos += -nSaldo
        ENDIF
    NEXT

    nResultado := nIngresos - nGastos
    IF Abs( nResultado ) > 0.01
        nPasivo += nResultado
        cTexto += PadR( "129", 10 ) + " "
        cTexto += PadR( "Resultado del ejercicio", 50 ) + " "
        cTexto += PadL( "", 14 ) + " "
        cTexto += PadL( Transform( nResultado, "999,999.99" ), 14 ) + hb_Eol()
    ENDIF

    cTexto += Replicate( "-", 100 ) + hb_Eol()
    cTexto += PadR( "TOTALES", 61 ) + " "
    cTexto += PadL( Transform( nActivo, "999,999,999.99" ), 14 ) + " "
    cTexto += PadL( Transform( nPasivo, "999,999,999.99" ), 14 ) + hb_Eol()
    cTexto += "DIFERENCIA: " + Transform( nActivo - nPasivo, "999,999,999.99" ) + hb_Eol()

RETURN _MostrarInformeTexto( "BALANCE GENERAL", cTexto, ;
    "BALANCE_GENERAL_" + AllTrim( Str( nEjer ) ) + ".TXT" )


// ============================================================================
// InformePerdidasGanancias()
// ============================================================================
FUNCTION InformePerdidasGanancias()

    LOCAL aSaldos
    LOCAL cTexto
    LOCAL nEjer
    LOCAL i
    LOCAL cTipo
    LOCAL nSaldo
    LOCAL nGastos
    LOCAL nIngresos

    nEjer     := Year( Date() )
    aSaldos   := _ContSaldosEjercicio( nEjer )
    cTexto    := ""
    nGastos   := 0
    nIngresos := 0

    cTexto += PadC( "ESTADO DE PERDIDAS Y GANANCIAS - EJERCICIO " + ;
                    AllTrim( Str( nEjer ) ), 100 ) + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()
    cTexto += "FECHA: " + DToC( Date() ) + "   HORA: " + Time() + hb_Eol()
    cTexto += hb_Eol()
    cTexto += PadR( "CUENTA", 10 ) + " "
    cTexto += PadR( "NOMBRE", 55 ) + " "
    cTexto += PadL( "GASTO", 14 ) + " "
    cTexto += PadL( "INGRESO", 14 ) + hb_Eol()
    cTexto += Replicate( "-", 100 ) + hb_Eol()

    FOR i := 1 TO Len( aSaldos )
        cTipo  := _CuentaTipo( aSaldos[i, 1] )
        nSaldo := aSaldos[i, 3] - aSaldos[i, 4]
        IF cTipo == "G"
            nGastos += nSaldo
            cTexto += PadR( aSaldos[i, 1], 10 ) + " "
            cTexto += PadR( aSaldos[i, 2], 55 ) + " "
            cTexto += PadL( Transform( nSaldo, "999,999.99" ), 14 ) + " "
            cTexto += PadL( "", 14 ) + hb_Eol()
        ELSEIF cTipo == "I"
            nIngresos += -nSaldo
            cTexto += PadR( aSaldos[i, 1], 10 ) + " "
            cTexto += PadR( aSaldos[i, 2], 55 ) + " "
            cTexto += PadL( "", 14 ) + " "
            cTexto += PadL( Transform( -nSaldo, "999,999.99" ), 14 ) + hb_Eol()
        ENDIF
    NEXT

    cTexto += Replicate( "-", 100 ) + hb_Eol()
    cTexto += PadR( "TOTALES", 66 ) + " "
    cTexto += PadL( Transform( nGastos,   "999,999,999.99" ), 14 ) + " "
    cTexto += PadL( Transform( nIngresos, "999,999,999.99" ), 14 ) + hb_Eol()
    cTexto += "RESULTADO: " + Transform( nIngresos - nGastos, "999,999,999.99" ) + hb_Eol()

RETURN _MostrarInformeTexto( "PERDIDAS Y GANANCIAS", cTexto, ;
    "PERDIDAS_GANANCIAS_" + AllTrim( Str( nEjer ) ) + ".TXT" )


STATIC FUNCTION _ContSaldosEjercicio( nEjer )

    LOCAL aSaldos := {}
    LOCAL nPos
    LOCAL cCuenta

    IF !ABRIR_TABLA( "LDIARIO", "DIA_SL", "DIA_MAY" )
        RETURN aSaldos
    ENDIF

    DbSelectArea( "DIA_SL" )
    OrdSetFocus( "DIA_MAY" )
    DbGoTop()

    DO WHILE !DIA_SL->( Eof() )
        IF !DIA_SL->( Deleted() ) .AND. Year( DIA_SL->D_FECHA ) == nEjer
            cCuenta := AllTrim( DIA_SL->D_CUENTA )
            IF !Empty( cCuenta )
                nPos := AScan( aSaldos, {| a | a[1] == cCuenta } )
                IF nPos == 0
                    AAdd( aSaldos, { cCuenta, _CuentaNombre( cCuenta ), 0.00, 0.00 } )
                    nPos := Len( aSaldos )
                ENDIF
                aSaldos[nPos, 3] += DIA_SL->D_DEBE
                aSaldos[nPos, 4] += DIA_SL->D_HABER
            ENDIF
        ENDIF
        DIA_SL->( DbSkip() )
    ENDDO

    DIA_SL->( DbCloseArea() )
    ASort( aSaldos,,, {| x, y | x[1] < y[1] } )

RETURN aSaldos


STATIC FUNCTION _CuentaNombre( cCuenta )

    LOCAL cNombre := cCuenta

    IF ABRIR_TABLA( "CATALOGO", "CAT_NM", "CAT_CTA" )
        IF CAT_NM->( DbSeek( cCuenta ) )
            cNombre := AllTrim( CAT_NM->NOMBRE )
        ENDIF
        CAT_NM->( DbCloseArea() )
    ENDIF

RETURN cNombre


STATIC FUNCTION _CuentaTipo( cCuenta )

    LOCAL cTipo := ""

    IF ABRIR_TABLA( "CATALOGO", "CAT_TP", "CAT_CTA" )
        IF CAT_TP->( DbSeek( cCuenta ) )
            cTipo := AllTrim( CAT_TP->TIPO )
        ENDIF
        CAT_TP->( DbCloseArea() )
    ENDIF

    IF Empty( cTipo )
        DO CASE
        CASE Left( cCuenta, 1 ) $ "12345"
            cTipo := If( Left( cCuenta, 1 ) $ "12", "P", "A" )
        CASE Left( cCuenta, 1 ) == "6"
            cTipo := "G"
        CASE Left( cCuenta, 1 ) == "7"
            cTipo := "I"
        OTHERWISE
            cTipo := "N"
        ENDCASE
    ENDIF

RETURN cTipo


STATIC FUNCTION _PideCuenta( cCuenta, cTitulo )

    LOCAL oWin
    LOCAL oGCta
    LOCAL oBtOk
    LOCAL oBtCan
    LOCAL lOK := .F.

    oWin := TWindow():New( 10, 35, 20, 95, cTitulo )
    oWin:AddCtrl( TLabel():New( 2, 3, "Cuenta:", oWin ) )
    oGCta := TGet():New( 2, 12, cCuenta, "@!", oWin )
    oBtOk := TButton():New( 6, 12, 7, 28, oWin, "ACEPTAR", ;
        {|| lOK := .T., oWin:Close() } )
    oBtCan := TButton():New( 6, 32, 7, 48, oWin, "CANCELAR", ;
        {|| oWin:Close() } )
    oWin:AddCtrl( oGCta )
    oWin:AddCtrl( oBtOk )
    oWin:AddCtrl( oBtCan )
    oWin:Run()

    IF lOK
        cCuenta := AllTrim( oGCta:uVar )
    ENDIF

RETURN lOK


STATIC FUNCTION _MostrarInformeTexto( cTitulo, cTexto, cFile )

    LOCAL oWin
    LOCAL oGrid
    LOCAL oBtPrn
    LOCAL oBtSal
    LOCAL aLineas := _InformeTextoLineas( cTexto )

    oWin   := TWindow():New( 1, 2, 37, 129, cTitulo )
    oGrid  := TGrid():New( 2, 2, 30, 124, oWin )
    oGrid:aData    := aLineas
    oGrid:nSeekCol := 1
    oGrid:AddColumn( "Vista previa TXT", 118, "@!", { |a| a[1] } )

    oWin:AddCtrl( TLabel():New( 32, 2, ;
        "Flechas/PgUp/PgDn: navegar   Letras: buscar texto   GUARDAR TXT: exportar", oWin ) )

    oBtPrn := TButton():New( 33, 40, 34, 59, oWin, "GUARDAR TXT", ;
        {|| _ImpTexto( cTexto, cFile ) } )
    oBtSal := TButton():New( 33, 63, 34, 82, oWin, "CERRAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGrid  )
    oWin:AddCtrl( oBtPrn )
    oWin:AddCtrl( oBtSal )
    oWin:Run()

RETURN NIL


STATIC FUNCTION _InformeTextoLineas( cTexto )

    LOCAL aLineas := {}
    LOCAL nStart  := 1
    LOCAL nPos
    LOCAL cLine

    DEFAULT cTexto TO ""

    cTexto := StrTran( cTexto, Chr( 13 ) + Chr( 10 ), Chr( 10 ) )
    cTexto := StrTran( cTexto, Chr( 13 ), Chr( 10 ) )

    DO WHILE nStart <= Len( cTexto ) + 1
        nPos := At( Chr( 10 ), SubStr( cTexto, nStart ) )
        IF nPos == 0
            cLine := SubStr( cTexto, nStart )
            AAdd( aLineas, { cLine } )
            EXIT
        ENDIF
        cLine := SubStr( cTexto, nStart, nPos - 1 )
        AAdd( aLineas, { cLine } )
        nStart += nPos
    ENDDO

    IF Empty( aLineas )
        AAdd( aLineas, { "" } )
    ENDIF

RETURN aLineas


// ============================================================================
// FIN DE Informes.prg
// ============================================================================
