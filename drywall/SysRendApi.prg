#include "OOp.ch"
// SysRendApi.prg — API compartida para tabla SYS_REND

FUNCTION _SysRendAbrir()

    LOCAL lAbierta := .F.

    IF Select( "SYS_REND" ) == 0
        IF ABRIR_TABLA( "SYS_REND", "SYS_REND", "SR_SIS" )
            lAbierta := .T.
        ELSE
            RETURN .F.
        ENDIF
    ENDIF

    dbSelectArea( "SYS_REND" )

RETURN lAbierta

FUNCTION _SysRendCerrar( lAbierta, nAreaAnt )

    IF lAbierta
        dbSelectArea( "SYS_REND" )
        dbCloseArea()
    ENDIF

    IF HB_ISNUMERIC( nAreaAnt ) .AND. nAreaAnt > 0
        dbSelectArea( nAreaAnt )
    ENDIF

RETURN NIL
