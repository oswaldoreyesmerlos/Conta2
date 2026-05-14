#include "OOp.ch"

FUNCTION Main()

    LOCAL nArea := Select()

    rddSetDefault( "DBFCDX" )
    hb_gtReload( "WVG" )
    SetMode( 40, 132 )
    SetColor( "N/W" )
    CLS

    GfxSetFont( "Lucida Console", 16, 8 )
    GfxFixSize( .T. )

    IF !InicioDrywall()
        ? "Error creando tablas Drywall"
        WAIT
        RETURN 1
    ENDIF

    ? "Drywall module ready. Testing Add_Tabique..."
    Add_Tabique( "Tabique prueba" )

RETURN 0
