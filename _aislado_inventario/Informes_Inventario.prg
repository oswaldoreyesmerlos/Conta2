/*
 * ARCHIVO  : Informes_Inventario.prg
 * PROPOSITO: Informes de articulos/stock aislados del build principal.
 *
 * NOTA
 * ----
 * Este archivo conserva trabajo reutilizable para una app con inventario.
 * Si se reactiva, hay que compilarlo junto con un modulo que aporte
 * _MostrarInformeTexto() o adaptar estas funciones al sistema de informes
 * de la nueva aplicacion.
 */

#include "OOp.ch"


// ============================================================================
// InformeArticulos()
// ============================================================================
FUNCTION InformeArticulos()

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

RETURN _MostrarInformeTexto( "INFORME DE ARTICULOS", cTexto, "INFORME_ARTICULOS.TXT" )


// ============================================================================
// InformeStockMinimo()
// Articulos con stock actual por debajo del minimo definido
// ============================================================================
FUNCTION InformeStockMinimo()

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

RETURN _MostrarInformeTexto( "ARTICULOS BAJO STOCK MINIMO", cTexto, "STOCK_MINIMO.TXT" )
