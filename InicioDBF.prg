/*
 * ARCHIVO  : InicioDBF.prg
 * PROPOSITO: Crear y verificar las 37 tablas DBF del sistema.
 *
 * LLAMAR DESDE Main() UNA SOLA VEZ al arranque, antes del Login.
 *
 * COMPORTAMIENTO
 * --------------
 * - Si el DBF no existe lo crea con DbCreate().
 * - Siempre regenera el CDX (borra el anterior si existe).
 *   Esto garantiza indices limpios tras cualquier corrupcion.
 * - Al terminar deja SET EXCLUSIVE OFF para el resto de la app.
 * - Siembra datos iniciales solo si la tabla esta vacia.
 *
 * CORRECCIONES RESPECTO A InicioApp.prg ORIGINAL
 * -----------------------------------------------
 * - BAJA se declara ANTES del AAdd(aTablas) en todas las tablas.
 * - Semilla EMPRESA usa NetFLock + DbAppend (tabla vacia).
 * - Semilla USUARIOS usa NetFLock + DbAppend (protocolo correcto).
 * - Campos inapropiados de PROVEED eliminados (TARIFA, TIP_CLI,
 *   LOPD_OK, ENV_MAIL no aplican a proveedores).
 * - NOTADEB y NOTACRED unificadas en NOTASDC con campo TIPO (D/C).
 * - FACTUR_DET enlaza por SERIE+NUMERO para evitar colisiones.
 * - Todos los mensajes de error usan MsgStop() en vez de Alert().
 */

#include "OOp.ch"

// ============================================================================
// InicioDBF()
// Punto de entrada. Devuelve .T. si todo fue bien, .F. si hubo error critico.
// ============================================================================
FUNCTION InicioDBF()

    LOCAL aTablas   := {}
    LOCAL aCampos
    LOCAL aIndices
    LOCAL i
    LOCAL cDbf
    LOCAL aStru
    LOCAL aIdx
    LOCAL oIdx
    LOCAL lOK       := .T.
    LOCAL cDataDir  := ".\DATA"
    LOCAL nErr

    // -- 1. Crear directorio si no existe --
    IF !DirExiste( cDataDir )
        nErr := DirMake( cDataDir )
        IF nErr != 0
            MsgStop( "No se pudo crear la carpeta DATA. Codigo: " + ;
                     AllTrim( Str( nErr ) ), "Error critico" )
            RETURN .F.
        ENDIF
    ENDIF

    SET DEFAULT TO (cDataDir)

    rddSetDefault( "DBFCDX" )

    // =========================================================================
    // DEFINICION DE TABLAS
    // =========================================================================

    // -- 01. EMPRESA --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NIF",      "C", 13, 0 } )
    AAdd( aCampos, { "NOMBRE",   "C", 60, 0 } )
    AAdd( aCampos, { "DIRECCIO", "C", 60, 0 } )
    AAdd( aCampos, { "CIUDAD",   "C", 40, 0 } )
    AAdd( aCampos, { "PROVINCI", "C", 30, 0 } )
    AAdd( aCampos, { "CP",       "C",  5, 0 } )
    AAdd( aCampos, { "PAIS",     "C", 30, 0 } )
    AAdd( aCampos, { "TELEFONO", "C", 15, 0 } )
    AAdd( aCampos, { "MOVIL",    "C", 15, 0 } )
    AAdd( aCampos, { "EMAIL",    "C", 50, 0 } )
    AAdd( aCampos, { "WEB",      "C", 50, 0 } )
    AAdd( aCampos, { "REG_TOMO", "C", 10, 0 } )
    AAdd( aCampos, { "REG_FOL",  "C", 10, 0 } )
    AAdd( aCampos, { "REG_HOJA", "C", 15, 0 } )
    AAdd( aCampos, { "REG_SECC", "C", 10, 0 } )
    AAdd( aCampos, { "IBANPPAL", "C", 34, 0 } )
    AAdd( aCampos, { "FEC_CIER", "D",  8, 0 } )
    AAdd( aCampos, { "PREFIJO",  "C",  3, 0 } )
    AAdd( aCampos, { "LOGO",     "C",120, 0 } )
    AAdd( aCampos, { "PIE_DOC",  "M", 10, 0 } )
    AAdd( aIndices, { "EMP_NIF", "NIF" } )
    AAdd( aTablas, { "EMPRESA", aCampos, aIndices } )

    // -- 02. CLIENTES --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "ID",       "C", 10, 0 } )
    AAdd( aCampos, { "NIF",      "C", 13, 0 } )
    AAdd( aCampos, { "NOMBRE",   "C", 30, 0 } )
    AAdd( aCampos, { "APELLIDO", "C", 30, 0 } )
    AAdd( aCampos, { "DIRECCIO", "C", 50, 0 } )
    AAdd( aCampos, { "CIUDAD",   "C", 40, 0 } )
    AAdd( aCampos, { "PROVINCI", "C", 30, 0 } )
    AAdd( aCampos, { "PAIS",     "C", 40, 0 } )
    AAdd( aCampos, { "CP",       "C",  5, 0 } )
    AAdd( aCampos, { "TELEFONO", "C", 12, 0 } )
    AAdd( aCampos, { "MOVIL",    "C", 12, 0 } )
    AAdd( aCampos, { "EMAIL",    "C", 50, 0 } )
    AAdd( aCampos, { "WEB",      "C", 50, 0 } )
    AAdd( aCampos, { "FECHA_AL", "D",  8, 0 } )
    AAdd( aCampos, { "CTA_BANC", "C", 34, 0 } )
    AAdd( aCampos, { "DIAS_PAG", "N",  3, 0 } )
    AAdd( aCampos, { "FORPAGO",  "C",  3, 0 } )
    AAdd( aCampos, { "LIMITE_C", "N", 12, 2 } )
    AAdd( aCampos, { "TARIFA",   "N",  1, 0 } )
    AAdd( aCampos, { "DESC_COM", "N",  5, 2 } )
    AAdd( aCampos, { "APL_RE",   "L",  1, 0 } )
    AAdd( aCampos, { "APL_IRPF", "L",  1, 0 } )
    AAdd( aCampos, { "TIP_CLI",  "C",  1, 0 } )
    AAdd( aCampos, { "LOPD_OK",  "L",  1, 0 } )
    AAdd( aCampos, { "ENV_MAIL", "L",  1, 0 } )
    AAdd( aCampos, { "CTA_CONT", "C", 10, 0 } )
    AAdd( aCampos, { "CTA_ANTI", "C", 10, 0 } )
    AAdd( aCampos, { "OBSERV",   "M", 10, 0 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "CLI_ID",  "ID" } )
    AAdd( aIndices, { "CLI_NOM", "Upper(NOMBRE+APELLIDO)" } )
    AAdd( aIndices, { "CLI_NIF", "Upper(NIF)" } )
    AAdd( aIndices, { "CLI_CIU", "Upper(CIUDAD)" } )
    AAdd( aTablas, { "CLIENTES", aCampos, aIndices } )

    // -- 03. PROVEED --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "ID",       "C", 10, 0 } )
    AAdd( aCampos, { "NIF",      "C", 13, 0 } )
    AAdd( aCampos, { "NOMBRE",   "C", 30, 0 } )
    AAdd( aCampos, { "APELLIDO", "C", 30, 0 } )
    AAdd( aCampos, { "DIRECCIO", "C", 50, 0 } )
    AAdd( aCampos, { "CIUDAD",   "C", 40, 0 } )
    AAdd( aCampos, { "PROVINCI", "C", 30, 0 } )
    AAdd( aCampos, { "PAIS",     "C", 40, 0 } )
    AAdd( aCampos, { "CP",       "C",  5, 0 } )
    AAdd( aCampos, { "TELEFONO", "C", 12, 0 } )
    AAdd( aCampos, { "MOVIL",    "C", 12, 0 } )
    AAdd( aCampos, { "EMAIL",    "C", 50, 0 } )
    AAdd( aCampos, { "WEB",      "C", 50, 0 } )
    AAdd( aCampos, { "FECHA_AL", "D",  8, 0 } )
    AAdd( aCampos, { "CTA_BANC", "C", 34, 0 } )
    AAdd( aCampos, { "DIAS_PAG", "N",  3, 0 } )
    AAdd( aCampos, { "FORPAGO",  "C",  3, 0 } )
    AAdd( aCampos, { "CTA_CONT", "C", 10, 0 } )
    AAdd( aCampos, { "CTA_ANTI", "C", 10, 0 } )
    AAdd( aCampos, { "OBSERV",   "M", 10, 0 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "PRV_ID",  "ID" } )
    AAdd( aIndices, { "PRV_NOM", "Upper(NOMBRE+APELLIDO)" } )
    AAdd( aIndices, { "PRV_NIF", "Upper(NIF)" } )
    AAdd( aIndices, { "PRV_CIU", "Upper(CIUDAD)" } )
    AAdd( aTablas, { "PROVEED", aCampos, aIndices } )

    // -- 04. ARTICULOS (unificado con campos Drywall) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CODIGO",   "C", 10, 0 } )
    AAdd( aCampos, { "DESCRIP",  "C", 60, 0 } )
    AAdd( aCampos, { "FAMILIA",  "C", 10, 0 } )
    AAdd( aCampos, { "TIPO",     "C", 10, 0 } )
    AAdd( aCampos, { "PROVEEDO", "C", 10, 0 } )
    AAdd( aCampos, { "COD_BARR", "C", 15, 0 } )
    AAdd( aCampos, { "QR_DATA",  "C", 80, 0 } )
    AAdd( aCampos, { "STOCK",    "N", 12, 4 } )
    AAdd( aCampos, { "STO_MIN",  "N", 10, 4 } )
    AAdd( aCampos, { "STO_MAX",  "N", 10, 4 } )
    AAdd( aCampos, { "UNIDAD",   "C",  5, 0 } )
    AAdd( aCampos, { "ES_SERV",  "L",  1, 0 } )
    AAdd( aCampos, { "ESPESOR",  "N",  6, 2 } )
    AAdd( aCampos, { "LARGO",    "N",  6, 2 } )
    AAdd( aCampos, { "ANCHO",    "N",  6, 2 } )
    AAdd( aCampos, { "PESO_UNI", "N", 10, 3 } )
    AAdd( aCampos, { "CTA_VTA",  "C", 10, 0 } )
    AAdd( aCampos, { "CTA_COM",  "C", 10, 0 } )
    AAdd( aCampos, { "COSTO_PR", "N", 12, 4 } )
    AAdd( aCampos, { "PRECIO",   "N", 12, 2 } )
    AAdd( aCampos, { "IVA",      "N",  5, 2 } )
    AAdd( aCampos, { "TIPO_IVA", "C",  1, 0 } )
    AAdd( aCampos, { "DESCUENT", "N",  5, 2 } )
    AAdd( aCampos, { "FECHA_AL", "D",  8, 0 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "ART_COD", "CODIGO" } )
    AAdd( aIndices, { "ART_DES", "Upper(DESCRIP)" } )
    AAdd( aIndices, { "ART_FAM", "FAMILIA" } )
    AAdd( aIndices, { "ART_BAR", "COD_BARR" } )
    AAdd( aTablas, { "ARTICULOS", aCampos, aIndices } )

    // -- 05. MOVIMIENTOS (kardex de stock) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "MOV_NUM",  "C", 10, 0 } )
    AAdd( aCampos, { "FECHA",    "D",  8, 0 } )
    AAdd( aCampos, { "HORA",     "C",  8, 0 } )
    AAdd( aCampos, { "COD_ART",  "C", 10, 0 } )
    AAdd( aCampos, { "TIPO",     "C",  1, 0 } )
    AAdd( aCampos, { "CANTIDAD", "N", 10, 4 } )
    AAdd( aCampos, { "COSTO_UN", "N", 12, 4 } )
    AAdd( aCampos, { "PRECIO_V", "N", 12, 4 } )
    AAdd( aCampos, { "TIP_ORIG", "C",  3, 0 } )
    AAdd( aCampos, { "DOC_ORIG", "C", 10, 0 } )
    AAdd( aCampos, { "USUARIO",  "C", 10, 0 } )
    AAdd( aIndices, { "MOV_ART", "COD_ART" } )
    AAdd( aIndices, { "MOV_FEC", "DtoS(FECHA)" } )
    AAdd( aIndices, { "MOV_DOC", "DOC_ORIG" } )
    AAdd( aTablas, { "MOVIMIEN", aCampos, aIndices } )

    // -- 06. CATALOGO (plan contable) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CUENTA",   "C", 10, 0 } )
    AAdd( aCampos, { "NOMBRE",   "C", 60, 0 } )
    AAdd( aCampos, { "NIVEL",    "N",  1, 0 } )
    AAdd( aCampos, { "TIPO",     "C",  1, 0 } )
    AAdd( aCampos, { "NATURALE", "C",  1, 0 } )
    AAdd( aCampos, { "SUMA_EN",  "C", 10, 0 } )
    AAdd( aCampos, { "SALDO_AN", "N", 16, 2 } )
    AAdd( aCampos, { "DEBE_ANU", "N", 16, 2 } )
    AAdd( aCampos, { "HABER_AN", "N", 16, 2 } )
    AAdd( aCampos, { "SALDO_AC", "N", 16, 2 } )
    AAdd( aCampos, { "PRESUPUE", "N", 16, 2 } )
    AAdd( aCampos, { "BLOQUEAD", "L",  1, 0 } )
    AAdd( aCampos, { "REQ_ANAL", "L",  1, 0 } )
    AAdd( aCampos, { "ES_BANCO", "L",  1, 0 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "CAT_CTA", "CUENTA" } )
    AAdd( aIndices, { "CAT_NOM", "Upper(NOMBRE)" } )
    AAdd( aIndices, { "CAT_MAY", "SUMA_EN" } )
    AAdd( aTablas, { "CATALOGO", aCampos, aIndices } )

    // -- 07. LDIARIO (libro diario contable) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "D_ASIENT", "C", 10, 0 } )
    AAdd( aCampos, { "D_LINEA",  "N",  4, 0 } )
    AAdd( aCampos, { "D_FECHA",  "D",  8, 0 } )
    AAdd( aCampos, { "D_CUENTA", "C", 10, 0 } )
    AAdd( aCampos, { "D_DEBE",   "N", 16, 2 } )
    AAdd( aCampos, { "D_HABER",  "N", 16, 2 } )
    AAdd( aCampos, { "D_DESCRI", "C",100, 0 } )
    AAdd( aCampos, { "D_CCOSTE", "C", 10, 0 } )
    AAdd( aCampos, { "D_DOC_EX", "C", 20, 0 } )
    AAdd( aCampos, { "PUNTEADO", "L",  1, 0 } )
    AAdd( aCampos, { "F_PUNTEO", "D",  8, 0 } )
    AAdd( aCampos, { "DIVISA",   "C",  3, 0 } )
    AAdd( aCampos, { "IMP_DIV",  "N", 16, 2 } )
    AAdd( aCampos, { "CAMBIO",   "N", 10, 6 } )
    AAdd( aCampos, { "USUARIO_", "C", 10, 0 } )
    AAdd( aCampos, { "FECHA_AL", "D",  8, 0 } )
    AAdd( aCampos, { "TIP_ORIG", "C",  3, 0 } )
    AAdd( aCampos, { "DOC_ORIG", "C", 10, 0 } )
    AAdd( aIndices, { "DIA_ASI", "D_ASIENT+Str(D_LINEA,4)" } )
    AAdd( aIndices, { "DIA_FEC", "DtoS(D_FECHA)+D_ASIENT" } )
    AAdd( aIndices, { "DIA_MAY", "D_CUENTA+DtoS(D_FECHA)" } )
    AAdd( aIndices, { "DIA_ANA", "D_CCOSTE+D_CUENTA" } )
    AAdd( aTablas, { "LDIARIO", aCampos, aIndices } )

    // -- 08. BANCOS --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "BAN_COD",  "C", 10, 0 } )
    AAdd( aCampos, { "BAN_NOM",  "C", 40, 0 } )
    AAdd( aCampos, { "BAN_IBAN", "C", 34, 0 } )
    AAdd( aCampos, { "CTA_CONT", "C", 10, 0 } )
    AAdd( aCampos, { "BAN_SALI", "N", 16, 2 } )
    AAdd( aCampos, { "CHEQUERA", "C", 15, 0 } )
    AAdd( aCampos, { "FECHA_AL", "D",  8, 0 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "BAN_COD", "BAN_COD" } )
    AAdd( aIndices, { "BAN_NOM", "Upper(BAN_NOM)" } )
    AAdd( aTablas, { "BANCOS", aCampos, aIndices } )

    // -- 09. VENDEDOR --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "ID",       "C", 10, 0 } )
    AAdd( aCampos, { "NOMBRE",   "C", 40, 0 } )
    AAdd( aCampos, { "DNI",      "C", 15, 0 } )
    AAdd( aCampos, { "TELEFONO", "C", 15, 0 } )
    AAdd( aCampos, { "COMISION", "N",  5, 2 } )
    AAdd( aCampos, { "CTA_CONT", "C", 10, 0 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "VEN_ID",  "ID" } )
    AAdd( aIndices, { "VEN_NOM", "Upper(NOMBRE)" } )
    AAdd( aTablas, { "VENDEDOR", aCampos, aIndices } )

    // -- 10. USUARIOS --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CODIGO",   "C", 10, 0 } )
    AAdd( aCampos, { "NOMBRE",   "C", 40, 0 } )
    AAdd( aCampos, { "ROLID",    "C",  3, 0 } )
    AAdd( aCampos, { "NIVEL",    "N",  1, 0 } )
    AAdd( aCampos, { "FECHA_AL", "D",  8, 0 } )
    AAdd( aCampos, { "ULT_ACCE", "D",  8, 0 } )
    AAdd( aCampos, { "ULT_HORA", "C",  8, 0 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aCampos, { "CLAVE_H",  "C", 64, 0 } )
    AAdd( aCampos, { "SALT",     "C", 32, 0 } )
    AAdd( aCampos, { "CAMB_CL",  "L",  1, 0 } )
    AAdd( aCampos, { "FEC_CL",   "D",  8, 0 } )
    AAdd( aCampos, { "INT_FAL",  "N",  3, 0 } )
    AAdd( aCampos, { "BLOQ_FEC", "D",  8, 0 } )
    AAdd( aCampos, { "BLOQ_HOR", "C",  8, 0 } )
    AAdd( aIndices, { "USR_COD", "CODIGO" } )
    AAdd( aIndices, { "USR_NOM", "Upper(NOMBRE)" } )
    AAdd( aTablas, { "USUARIOS", aCampos, aIndices } )

    // -- 11. ROLES --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "ID",       "C",  3, 0 } )
    AAdd( aCampos, { "DESCRIP",  "C", 30, 0 } )
    AAdd( aCampos, { "NIVEL",    "N",  1, 0 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "ROLID",   "ID" } )
    AAdd( aTablas, { "ROLES", aCampos, aIndices } )

    // -- 12. ROL_PERM --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "ROLID",   "C",  3, 0 } )
    AAdd( aCampos, { "PERMISO", "C", 20, 0 } )
    AAdd( aCampos, { "DESCRIP", "C", 60, 0 } )
    AAdd( aCampos, { "BAJA",    "L",  1, 0 } )
    AAdd( aIndices, { "RPM_ROL", "ROLID+PERMISO" } )
    AAdd( aIndices, { "RPM_PER", "PERMISO+ROLID" } )
    AAdd( aTablas, { "ROL_PERM", aCampos, aIndices } )

    // -- 13. AUDITLOG --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "ID",      "C", 18, 0 } )
    AAdd( aCampos, { "FECHA",   "D",  8, 0 } )
    AAdd( aCampos, { "HORA",    "C",  8, 0 } )
    AAdd( aCampos, { "USUARIO", "C", 10, 0 } )
    AAdd( aCampos, { "ROL",     "C",  3, 0 } )
    AAdd( aCampos, { "ACCION",  "C", 20, 0 } )
    AAdd( aCampos, { "TABLA",   "C", 12, 0 } )
    AAdd( aCampos, { "CLAVE",   "C", 30, 0 } )
    AAdd( aCampos, { "DETALLE", "C",120, 0 } )
    AAdd( aCampos, { "EQUIPO",  "C", 30, 0 } )
    AAdd( aCampos, { "OK",      "L",  1, 0 } )
    AAdd( aIndices, { "AUD_ID",  "ID" } )
    AAdd( aIndices, { "AUD_FEC", "DtoS(FECHA)+HORA" } )
    AAdd( aIndices, { "AUD_USR", "USUARIO+DtoS(FECHA)" } )
    AAdd( aTablas, { "AUDITLOG", aCampos, aIndices } )

    // -- 14. GEOLOC --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CP",       "C",  5, 0 } )
    AAdd( aCampos, { "CIUDAD",   "C", 50, 0 } )
    AAdd( aCampos, { "PROVINCI", "C", 40, 0 } )
    AAdd( aCampos, { "PROV_COD", "C",  2, 0 } )
    AAdd( aIndices, { "GEO_CP",  "CP" } )
    AAdd( aIndices, { "GEO_CIU", "Upper(CIUDAD)" } )
    AAdd( aIndices, { "GEO_PRV", "Upper(PROVINCI)" } )
    AAdd( aTablas, { "GEOLOC", aCampos, aIndices } )

    // -- 13. FACTURA (cabecera facturas emitidas) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "SERIE",    "C",  4, 0 } )
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "CLIENTE_", "C", 10, 0 } )
    AAdd( aCampos, { "VENDEDOR", "C", 10, 0 } )
    AAdd( aCampos, { "FECHA",    "D",  8, 0 } )
    AAdd( aCampos, { "FECHA_OP", "D",  8, 0 } )
    AAdd( aCampos, { "HORA",     "C",  8, 0 } )
    AAdd( aCampos, { "SUBTOTAL", "N", 12, 2 } )
    AAdd( aCampos, { "IVA",      "N", 12, 2 } )
    AAdd( aCampos, { "RE_EQUIP", "N", 12, 2 } )
    AAdd( aCampos, { "RETENCIO", "N", 12, 2 } )
    AAdd( aCampos, { "PORC_RET", "N",  5, 2 } )
    AAdd( aCampos, { "TOTAL",    "N", 12, 2 } )
    AAdd( aCampos, { "FORMA_PA", "C",  3, 0 } )
    AAdd( aCampos, { "FECHA_VT", "D",  8, 0 } )
    AAdd( aCampos, { "ASIENTO",  "C", 10, 0 } )
    AAdd( aCampos, { "COBRADA",  "L",  1, 0 } )
    AAdd( aCampos, { "COBRADO",  "N", 12, 2 } )
    AAdd( aCampos, { "ANULADA",  "L",  1, 0 } )
    AAdd( aCampos, { "TIPO_DOC", "C",  1, 0 } )
    AAdd( aCampos, { "OBSERVA",  "C", 80, 0 } )
    AAdd( aCampos, { "PIE_DOC",  "M", 10, 0 } )
    AAdd( aCampos, { "NUM_PRE",  "C", 10, 0 } )
    AAdd( aCampos, { "ID_OBRA",  "C", 12, 0 } )
    AAdd( aCampos, { "TIPO_FAC", "C",  1, 0 } ) // A=Anticipo C=Certif. F=Final R=Rectif.
    AAdd( aCampos, { "NUM_ABONO","C", 10, 0 } )
    AAdd( aCampos, { "INVERSION","L",  1, 0 } )
    AAdd( aIndices, { "FAC_NUM", "SERIE+NUMERO" } )
    AAdd( aIndices, { "FAC_CLI", "CLIENTE_" } )
    AAdd( aIndices, { "FAC_FEC", "DtoS(FECHA)" } )
    AAdd( aIndices, { "FAC_VTO", "DtoS(FECHA_VT)" } )
    AAdd( aIndices, { "FAC_PTE", "CLIENTE_+DtoS(FECHA)" } )
    AAdd( aIndices, { "FAC_OBR", "ID_OBRA+DtoS(FECHA)" } )
    AAdd( aTablas, { "FACTURA", aCampos, aIndices } )

    // -- 14. FACTUR_DET (lineas de facturas emitidas) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "SERIE",    "C",  4, 0 } )
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "LINEA",    "N",  3, 0 } )
    AAdd( aCampos, { "ARTICULO", "C", 10, 0 } )
    AAdd( aCampos, { "DESCRIPC", "C", 60, 0 } )
    AAdd( aCampos, { "CANTIDAD", "N", 10, 4 } )
    AAdd( aCampos, { "PRECIO",   "N", 12, 2 } )
    AAdd( aCampos, { "DESCUENT", "N",  5, 2 } )
    AAdd( aCampos, { "IMPORTE",  "N", 12, 2 } )
    AAdd( aCampos, { "COSTO",    "N", 12, 4 } )
    AAdd( aCampos, { "CTA_CONT", "C", 10, 0 } )
    AAdd( aCampos, { "TIP_IVA",  "C",  1, 0 } )
    AAdd( aCampos, { "PORC_IVA", "N",  5, 2 } )
    AAdd( aIndices, { "FAC_LIN", "SERIE+NUMERO+Str(LINEA,3)" } )
    AAdd( aTablas, { "FACTUR_DE", aCampos, aIndices } )

    // -- 15. PEDIDOS --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "FECHA",    "D",  8, 0 } )
    AAdd( aCampos, { "CLIENTE_", "C", 10, 0 } )
    AAdd( aCampos, { "VENDEDOR", "C", 10, 0 } )
    AAdd( aCampos, { "SUBTOTAL", "N", 12, 2 } )
    AAdd( aCampos, { "IVA",      "N", 12, 2 } )
    AAdd( aCampos, { "TOTAL",    "N", 12, 2 } )
    AAdd( aCampos, { "ESTADO",   "C",  1, 0 } )
    AAdd( aCampos, { "ALMACEN",  "C",  3, 0 } )
    AAdd( aCampos, { "OBSERVA",  "C", 60, 0 } )
    AAdd( aIndices, { "PED_NUM", "NUMERO" } )
    AAdd( aIndices, { "PED_CLI", "CLIENTE_" } )
    AAdd( aIndices, { "PED_FEC", "DtoS(FECHA)" } )
    AAdd( aIndices, { "PED_EST", "ESTADO" } )
    AAdd( aTablas, { "PEDIDOS", aCampos, aIndices } )

    // -- 16. PED_DET --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "LINEA",    "N",  3, 0 } )
    AAdd( aCampos, { "ARTICULO", "C", 10, 0 } )
    AAdd( aCampos, { "DESCRIPC", "C", 60, 0 } )
    AAdd( aCampos, { "CANTIDAD", "N", 10, 4 } )
    AAdd( aCampos, { "PRECIO",   "N", 12, 2 } )
    AAdd( aCampos, { "DESCUENT", "N",  5, 2 } )
    AAdd( aCampos, { "IMPORTE",  "N", 12, 2 } )
    AAdd( aIndices, { "PED_LIN", "NUMERO+Str(LINEA,3)" } )
    AAdd( aTablas, { "PED_DET", aCampos, aIndices } )

    // -- 17. NOTASDC (notas de debito Y credito unificadas) --
    // TIPO: D=Debito  C=Credito
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "SERIE",    "C",  4, 0 } )
    AAdd( aCampos, { "TIPO",     "C",  1, 0 } )
    AAdd( aCampos, { "CLIENTE_", "C", 10, 0 } )
    AAdd( aCampos, { "FECHA",    "D",  8, 0 } )
    AAdd( aCampos, { "FECHA_OP", "D",  8, 0 } )
    AAdd( aCampos, { "REF_DOC",  "C", 15, 0 } )
    AAdd( aCampos, { "MOTIVO",   "C", 40, 0 } )
    AAdd( aCampos, { "SUBTOTAL", "N", 12, 2 } )
    AAdd( aCampos, { "IVA",      "N", 12, 2 } )
    AAdd( aCampos, { "RETENCIO", "N", 12, 2 } )
    AAdd( aCampos, { "TOTAL",    "N", 12, 2 } )
    AAdd( aCampos, { "ASIENTO",  "C", 10, 0 } )
    AAdd( aCampos, { "ESTADO",   "C",  1, 0 } )
    AAdd( aCampos, { "OBSERVA",  "C", 80, 0 } )
    AAdd( aIndices, { "NDC_NUM", "SERIE+NUMERO" } )
    AAdd( aIndices, { "NDC_CLI", "CLIENTE_" } )
    AAdd( aIndices, { "NDC_FEC", "DtoS(FECHA)" } )
    AAdd( aIndices, { "NDC_TIP", "TIPO+CLIENTE_" } )
    AAdd( aTablas, { "NOTASDC", aCampos, aIndices } )

    // -- 18. NOTASD_DE (detalle notas debito/credito) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "LINEA",    "N",  3, 0 } )
    AAdd( aCampos, { "ARTICULO", "C", 10, 0 } )
    AAdd( aCampos, { "DESCRIPC", "C", 60, 0 } )
    AAdd( aCampos, { "CANTIDAD", "N", 10, 4 } )
    AAdd( aCampos, { "PRECIO",   "N", 12, 2 } )
    AAdd( aCampos, { "DESCUENT", "N",  5, 2 } )
    AAdd( aCampos, { "IMPORTE",  "N", 12, 2 } )
    AAdd( aCampos, { "PORC_IVA", "N",  5, 2 } )
    AAdd( aCampos, { "IMP_IVA",  "N", 12, 2 } )
    AAdd( aCampos, { "CTA_CONT", "C", 10, 0 } )
    AAdd( aCampos, { "CCOSTE",   "C", 10, 0 } )
    AAdd( aCampos, { "REF_LIN",  "N",  3, 0 } )
    AAdd( aCampos, { "OBSERVA",  "C", 80, 0 } )
    AAdd( aIndices, { "NDC_LIN", "NUMERO+Str(LINEA,3)" } )
    AAdd( aTablas, { "NOTASD_DE", aCampos, aIndices } )

    // -- 19. COMPRAS (facturas recibidas de proveedores) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUM_INTE", "C", 10, 0 } )
    AAdd( aCampos, { "NUM_PROV", "C", 20, 0 } )
    AAdd( aCampos, { "PROV_ID",  "C", 10, 0 } )
    AAdd( aCampos, { "FECHA",    "D",  8, 0 } )
    AAdd( aCampos, { "FECHA_RE", "D",  8, 0 } )
    AAdd( aCampos, { "SUBTOTAL", "N", 12, 2 } )
    AAdd( aCampos, { "IVA",      "N", 12, 2 } )
    AAdd( aCampos, { "TOTAL",    "N", 12, 2 } )
    AAdd( aCampos, { "FECHA_VT", "D",  8, 0 } )
    AAdd( aCampos, { "ASIENTO",  "C", 10, 0 } )
    AAdd( aCampos, { "PAGADA",   "L",  1, 0 } )
    AAdd( aCampos, { "METODO_P", "C",  3, 0 } )
    AAdd( aIndices, { "COM_INT", "NUM_INTE" } )
    AAdd( aIndices, { "COM_PRO", "PROV_ID" } )
    AAdd( aIndices, { "COM_FEC", "DtoS(FECHA)" } )
    AAdd( aIndices, { "COM_VTO", "DtoS(FECHA_VT)" } )
    AAdd( aTablas, { "COMPRAS", aCampos, aIndices } )

    // -- 19B. PAGOS (documentos de pago emitidos) --
    // FORMA_PA: EFE=Efectivo TRF=Transferencia CHQ=Cheque TAR=Tarjeta OTR=Otro
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "FECHA",    "D",  8, 0 } )
    AAdd( aCampos, { "PROV_ID",  "C", 10, 0 } )
    AAdd( aCampos, { "BENEFIC",  "C", 60, 0 } )
    AAdd( aCampos, { "CONCEPTO", "C",100, 0 } )
    AAdd( aCampos, { "FORMA_PA", "C",  3, 0 } )
    AAdd( aCampos, { "REFERENC", "C", 20, 0 } )
    AAdd( aCampos, { "BANCO",    "C", 10, 0 } )
    AAdd( aCampos, { "CTA_DEBE", "C", 10, 0 } )
    AAdd( aCampos, { "CTA_HABER","C", 10, 0 } )
    AAdd( aCampos, { "TOTAL",    "N", 12, 2 } )
    AAdd( aCampos, { "ASIENTO",  "C", 10, 0 } )
    AAdd( aCampos, { "DOC_ORIG", "C", 10, 0 } )
    AAdd( aCampos, { "USUARIO_", "C", 10, 0 } )
    AAdd( aIndices, { "PAG_NUM", "NUMERO" } )
    AAdd( aIndices, { "PAG_FEC", "DtoS(FECHA)" } )
    AAdd( aIndices, { "PAG_PRV", "PROV_ID+DtoS(FECHA)" } )
    AAdd( aTablas, { "PAGOS", aCampos, aIndices } )

    // -- 19C. PAGO_DET (imputacion contable del pago) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "LINEA",    "N",  3, 0 } )
    AAdd( aCampos, { "REF_DOC",  "C", 15, 0 } )
    AAdd( aCampos, { "CONCEPTO", "C", 60, 0 } )
    AAdd( aCampos, { "IMPORTE",  "N", 12, 2 } )
    AAdd( aCampos, { "CTA_CONT", "C", 10, 0 } )
    AAdd( aIndices, { "PGD_LIN", "NUMERO+Str(LINEA,3)" } )
    AAdd( aTablas, { "PAGO_DET", aCampos, aIndices } )

    // -- 20. COMP_DET --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "LINEA",    "N",  3, 0 } )
    AAdd( aCampos, { "ARTICULO", "C", 10, 0 } )
    AAdd( aCampos, { "DESCRIPC", "C", 60, 0 } )
    AAdd( aCampos, { "CANTIDAD", "N", 10, 4 } )
    AAdd( aCampos, { "COSTO_UN", "N", 12, 4 } )
    AAdd( aCampos, { "IMPORTE",  "N", 12, 2 } )
    AAdd( aCampos, { "TIP_IVA",  "C",  1, 0 } )
    AAdd( aCampos, { "PORC_IVA", "N",  5, 2 } )
    AAdd( aIndices, { "CPD_LIN", "NUMERO+Str(LINEA,3)" } )
    AAdd( aTablas, { "COMP_DET", aCampos, aIndices } )

    // -- 21. RECIBOS (recibos de caja - ingreso cobrado) --
    // Un recibo existe solo cuando se ha cobrado. No hay estado pendiente.
    // FORMA_PA: EFE=Efectivo TRF=Transferencia TAR=Tarjeta CHQ=Cheque OTR=Otro
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "FECHA",    "D",  8, 0 } )
    AAdd( aCampos, { "CLIENTE_", "C", 10, 0 } )
    AAdd( aCampos, { "CONCEPTO", "C",100, 0 } )
    AAdd( aCampos, { "FORMA_PA", "C",  3, 0 } )
    AAdd( aCampos, { "TOTAL",    "N", 12, 2 } )
    AAdd( aCampos, { "ASIENTO",  "C", 10, 0 } )
    AAdd( aCampos, { "USUARIO_", "C", 10, 0 } )
    AAdd( aIndices, { "REC_NUM", "NUMERO" } )
    AAdd( aIndices, { "REC_CLI", "CLIENTE_" } )
    AAdd( aIndices, { "REC_FEC", "DtoS(FECHA)" } )
    AAdd( aTablas, { "RECIBOS", aCampos, aIndices } )

    // -- 22. RC_DETAL (facturas cobradas por el recibo) --
    // Cada linea referencia una factura cobrada con este recibo.
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "LINEA",    "N",  3, 0 } )
    AAdd( aCampos, { "NUM_FAC",  "C", 10, 0 } )
    AAdd( aCampos, { "IMPORTE",  "N", 12, 2 } )
    AAdd( aIndices, { "RCD_NUM", "NUMERO+Str(LINEA,3)" } )
    AAdd( aIndices, { "RCD_FAC", "NUM_FAC" } )
    AAdd( aTablas, { "RC_DETAL", aCampos, aIndices } )

    // -- 23. VENCIMIEN (vencimientos de cobro/pago) --
    // TIPO: C=Cobro cliente P=Pago proveedor
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "EJERCICIO", "N",  4, 0 } )
    AAdd( aCampos, { "TIPO",      "C",  1, 0 } )
    AAdd( aCampos, { "NUMERO",    "C", 10, 0 } )
    AAdd( aCampos, { "SERIE",     "C",  4, 0 } )
    AAdd( aCampos, { "VENCTO",    "D",  8, 0 } )
    AAdd( aCampos, { "IMPORTE",   "N", 12, 2 } )
    AAdd( aCampos, { "COBRADO",   "L",  1, 0 } )
    AAdd( aCampos, { "CODTERCE",  "C", 10, 0 } )
    AAdd( aCampos, { "NOMBRE",    "C", 60, 0 } )
    AAdd( aCampos, { "ID_OBRA",   "C", 12, 0 } )
    AAdd( aIndices, { "VEN_NUM", "TIPO+NUMERO" } )
    AAdd( aIndices, { "VEN_FEC", "DtoS(VENCTO)" } )
    AAdd( aIndices, { "VEN_TER", "TIPO+CODTERCE+DtoS(VENCTO)" } )
    AAdd( aIndices, { "VEN_OBR", "ID_OBRA+DtoS(VENCTO)" } )
    AAdd( aTablas, { "VENCIMIEN", aCampos, aIndices } )

    // -- 24. OBRAS (gestion economica de obras aceptadas) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "ID",        "C", 12, 0 } ) // OBR20260001
    AAdd( aCampos, { "NUM_PRE",   "C", 10, 0 } )
    AAdd( aCampos, { "CLIENTE_",  "C", 10, 0 } )
    AAdd( aCampos, { "DESCRIP",   "C", 80, 0 } )
    AAdd( aCampos, { "DIRECC_OB", "C", 80, 0 } )
    AAdd( aCampos, { "FECHA_IN",  "D",  8, 0 } )
    AAdd( aCampos, { "FECHA_FIN", "D",  8, 0 } )
    AAdd( aCampos, { "TOTAL",     "N", 12, 2 } )
    AAdd( aCampos, { "INVERSION", "L",  1, 0 } )
    AAdd( aCampos, { "ESTADO",    "C",  1, 0 } ) // A=Abierta E=En curso F=Finalizada C=Cancelada
    AAdd( aCampos, { "USUARIO_",  "C", 10, 0 } )
    AAdd( aCampos, { "FECHA_AL",  "D",  8, 0 } )
    AAdd( aCampos, { "OBSERVA",   "M", 10, 0 } )
    AAdd( aIndices, { "OBR_ID",  "ID" } )
    AAdd( aIndices, { "OBR_PRE", "NUM_PRE" } )
    AAdd( aIndices, { "OBR_CLI", "CLIENTE_" } )
    AAdd( aIndices, { "OBR_EST", "ESTADO" } )
    AAdd( aTablas, { "OBRAS", aCampos, aIndices } )

    // -- 25. PRESUPUEST --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "FECHA",    "D",  8, 0 } )
    AAdd( aCampos, { "VALIDEZ",  "D",  8, 0 } )
    AAdd( aCampos, { "CLIENTE_", "C", 10, 0 } )
    AAdd( aCampos, { "VENDEDOR", "C", 10, 0 } )
    AAdd( aCampos, { "SUBTOTAL", "N", 12, 2 } )
    AAdd( aCampos, { "IVA",      "N", 12, 2 } )
    AAdd( aCampos, { "TOTAL",    "N", 12, 2 } )
    AAdd( aCampos, { "ESTADO",   "C",  1, 0 } )
    AAdd( aCampos, { "OBSERVA",  "C", 60, 0 } )
    AAdd( aCampos, { "PIE_DOC",  "M", 10, 0 } )
    AAdd( aCampos, { "NUM_FAC",  "C", 10, 0 } )
    AAdd( aCampos, { "ID_OBRA",  "C", 12, 0 } )
    AAdd( aCampos, { "TIPO",     "C",  1, 0 } ) // C=Cerrado M=Medicion
    AAdd( aCampos, { "FORMA_PA", "C",  3, 0 } )
    AAdd( aCampos, { "DIAS_PAG", "N",  3, 0 } )
    AAdd( aCampos, { "RETENCIO", "N", 12, 2 } )
    AAdd( aCampos, { "PORC_RET", "N",  5, 2 } )
    AAdd( aCampos, { "INVERSION","L",  1, 0 } )
    AAdd( aCampos, { "FECHA_ACE","D",  8, 0 } )
    AAdd( aCampos, { "ACEPTA_POR","C",30, 0 } )
    AAdd( aIndices, { "PRE_NUM", "NUMERO" } )
    AAdd( aIndices, { "PRE_CLI", "CLIENTE_" } )
    AAdd( aIndices, { "PRE_FEC", "DtoS(FECHA)" } )
    AAdd( aIndices, { "PRE_OBR", "ID_OBRA" } )
    AAdd( aTablas, { "PRESUPUEST", aCampos, aIndices } )

    // -- CLI_DIRES (direcciones de obra por cliente) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CLIENTE",   "C", 10, 0 } )
    AAdd( aCampos, { "DESCRIPC",  "C", 30, 0 } )
    AAdd( aCampos, { "DIRECCION", "C", 50, 0 } )
    AAdd( aCampos, { "CIUDAD",    "C", 40, 0 } )
    AAdd( aCampos, { "PROVINCIA", "C", 30, 0 } )
    AAdd( aCampos, { "PAIS",      "C", 40, 0 } )
    AAdd( aCampos, { "CP",        "C",  5, 0 } )
    AAdd( aIndices, { "CDR_CLI", "CLIENTE" } )
    AAdd( aTablas, { "CLI_DIRES", aCampos, aIndices } )

    // -- CERTIFICA (cabecera certificaciones) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "ID",        "C", 12, 0 } )
    AAdd( aCampos, { "ID_OBRA",   "C", 12, 0 } )
    AAdd( aCampos, { "FECHA",     "D",  8, 0 } )
    AAdd( aCampos, { "PORCENTAJE","N",  5, 2 } )
    AAdd( aCampos, { "IMPORTE",   "N", 12, 2 } )
    AAdd( aCampos, { "BASE",      "N", 12, 2 } )
    AAdd( aCampos, { "IVA",       "N", 12, 2 } )
    AAdd( aCampos, { "PORC_IVA",  "N",  5, 2 } )
    AAdd( aCampos, { "TOTAL",     "N", 12, 2 } )
    AAdd( aCampos, { "ESTADO",    "C",  1, 0 } )
    AAdd( aCampos, { "NUM_FAC",   "C", 10, 0 } )
    AAdd( aCampos, { "ASIENTO",   "C", 10, 0 } )
    AAdd( aCampos, { "OBSERVA",   "C", 80, 0 } )
    AAdd( aIndices, { "CERT_NUM", "ID" } )
    AAdd( aIndices, { "CERT_OBR", "ID_OBRA" } )
    AAdd( aTablas, { "CERTIFICA", aCampos, aIndices } )

    // -- CERTIF_DE (lineas de certificacion) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "ID_CERT",  "C", 12, 0 } )
    AAdd( aCampos, { "LINEA",    "N",  3, 0 } )
    AAdd( aCampos, { "DESCRIPC", "C", 60, 0 } )
    AAdd( aCampos, { "CANTIDAD", "N", 12, 2 } )
    AAdd( aCampos, { "PRECIO",   "N", 12, 2 } )
    AAdd( aCampos, { "IMPORTE",  "N", 12, 2 } )
    AAdd( aIndices, { "CDE_CERT", "ID_CERT+Str(LINEA,3)" } )
    AAdd( aIndices, { "CDE_NUM",  "ID_CERT" } )
    AAdd( aTablas, { "CERTIF_DE", aCampos, aIndices } )

    // -- 24. PRESUP_DE --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "LINEA",    "N",  3, 0 } )
    AAdd( aCampos, { "ARTICULO", "C", 10, 0 } )
    AAdd( aCampos, { "DESCRIPC", "C", 60, 0 } )
    AAdd( aCampos, { "CANTIDAD", "N", 10, 4 } )
    AAdd( aCampos, { "PRECIO",   "N", 12, 2 } )
    AAdd( aCampos, { "DESCUENT", "N",  5, 2 } )
    AAdd( aCampos, { "IMPORTE",  "N", 12, 2 } )
    AAdd( aCampos, { "PORC_IVA", "N",  5, 2 } )
    AAdd( aIndices, { "PRD_LIN", "NUMERO+Str(LINEA,3)" } )
    AAdd( aTablas, { "PRESUP_DE", aCampos, aIndices } )

    // -- 25. CHEQUES --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 15, 0 } )
    AAdd( aCampos, { "FECHA_EM", "D",  8, 0 } )
    AAdd( aCampos, { "FECHA_VT", "D",  8, 0 } )
    AAdd( aCampos, { "BANCO",    "C", 10, 0 } )
    AAdd( aCampos, { "BENEFICIA","C", 40, 0 } )
    AAdd( aCampos, { "PROV_ID",  "C", 10, 0 } )
    AAdd( aCampos, { "CONCEPTO", "C",100, 0 } )
    AAdd( aCampos, { "MONTO",    "N", 12, 2 } )
    AAdd( aCampos, { "ESTADO",   "C",  1, 0 } )
    AAdd( aCampos, { "ASIENTO",  "C", 10, 0 } )
    AAdd( aIndices, { "CHQ_NUM", "NUMERO" } )
    AAdd( aIndices, { "CHQ_FEC", "DtoS(FECHA_EM)" } )
    AAdd( aIndices, { "CHQ_VTO", "DtoS(FECHA_VT)" } )
    AAdd( aTablas, { "CHEQUES", aCampos, aIndices } )

    // -- 26. CHEQUE_DE --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 15, 0 } )
    AAdd( aCampos, { "LINEA",    "N",  3, 0 } )
    AAdd( aCampos, { "REF_DOC",  "C", 15, 0 } )
    AAdd( aCampos, { "CONCEPTO", "C", 60, 0 } )
    AAdd( aCampos, { "IMPORTE",  "N", 12, 2 } )
    AAdd( aCampos, { "CTA_CONT", "C", 10, 0 } )
    AAdd( aIndices, { "CHD_LIN", "NUMERO+Str(LINEA,3)" } )
    AAdd( aTablas, { "CHEQUE_DE", aCampos, aIndices } )

    // -- 27. AJUSTEIN (ajustes de inventario) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "NUMERO",   "C", 10, 0 } )
    AAdd( aCampos, { "FECHA",    "D",  8, 0 } )
    AAdd( aCampos, { "USUARIO_", "C", 10, 0 } )
    AAdd( aCampos, { "TIP_AJUS", "C",  1, 0 } )
    AAdd( aCampos, { "ARTICULO", "C", 10, 0 } )
    AAdd( aCampos, { "CANTIDAD", "N", 10, 4 } )
    AAdd( aCampos, { "COSTO_TO", "N", 12, 4 } )
    AAdd( aIndices, { "AJU_NUM", "NUMERO" } )
    AAdd( aIndices, { "AJU_ART", "ARTICULO" } )
    AAdd( aTablas, { "AJUSTEIN", aCampos, aIndices } )

    // -- 28. CONTADOR --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "COD_DOC",  "C",  3, 0 } )
    AAdd( aCampos, { "DESCRIP",  "C", 40, 0 } )
    AAdd( aCampos, { "PREFIJO",  "C",  3, 0 } )
    AAdd( aCampos, { "ULT_NUM",  "N", 10, 0 } )
    AAdd( aCampos, { "DIGITOS",  "N",  2, 0 } )
    AAdd( aCampos, { "ULT_USR",  "C", 10, 0 } )
    AAdd( aCampos, { "ULT_FEC",  "D",  8, 0 } )
    AAdd( aCampos, { "ULT_HOR",  "C",  8, 0 } )
    AAdd( aIndices, { "COD_DOC", "COD_DOC" } )
    AAdd( aTablas, { "CONTADOR", aCampos, aIndices } )

    // -- 29. BAL_DEF (estados financieros) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CODIGO",   "C", 10, 0 } )
    AAdd( aCampos, { "TIPO_BAL", "C",  1, 0 } )
    AAdd( aCampos, { "DESCRIP",  "C", 60, 0 } )
    AAdd( aCampos, { "NIVEL",    "N",  1, 0 } )
    AAdd( aCampos, { "SIGN_OP",  "C",  1, 0 } )
    AAdd( aCampos, { "CTA_DESD", "C", 10, 0 } )
    AAdd( aCampos, { "CTA_HAST", "C", 10, 0 } )
    AAdd( aCampos, { "NOTAS",    "C", 10, 0 } )
    AAdd( aIndices, { "BAL_ORD", "TIPO_BAL+CODIGO" } )
    AAdd( aTablas, { "BAL_DEF", aCampos, aIndices } )

    // -- 30. TIENDAS --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "ID",       "C",  3, 0 } )
    AAdd( aCampos, { "NOMBRE",   "C", 40, 0 } )
    AAdd( aCampos, { "DIRECCIO", "C", 50, 0 } )
    AAdd( aCampos, { "TELEFONO", "C", 12, 0 } )
    AAdd( aCampos, { "RESPONSA", "C", 40, 0 } )
    AAdd( aIndices, { "TDA_ID",  "ID" } )
    AAdd( aTablas, { "TIENDAS", aCampos, aIndices } )

    // -- 31. CCOSTOS --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CCO_COD",  "C", 10, 0 } )
    AAdd( aCampos, { "CCO_DESC", "C", 40, 0 } )
    AAdd( aCampos, { "CCO_RESP", "C", 30, 0 } )
    AAdd( aCampos, { "CCO_PRES", "N", 12, 2 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "CCO_COD", "CCO_COD" } )
    AAdd( aTablas, { "CCOSTOS", aCampos, aIndices } )

    // -- 32. FORMAPAGO --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CODIGO",   "C",  3, 0 } )
    AAdd( aCampos, { "DESCRIP",  "C", 30, 0 } )
    AAdd( aCampos, { "DIAS",     "N",  3, 0 } )
    AAdd( aCampos, { "NUM_PAGS", "N",  2, 0 } )
    AAdd( aCampos, { "CTA_COB",  "C", 10, 0 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "FP_COD",  "CODIGO" } )
    AAdd( aTablas, { "FORMAPAGO", aCampos, aIndices } )

    // -- 33. TIPOSIVA --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CODIGO",   "C",  1, 0 } )
    AAdd( aCampos, { "DESCRIP",  "C", 20, 0 } )
    AAdd( aCampos, { "PORC_IVA", "N",  5, 2 } )
    AAdd( aCampos, { "PORC_RE",  "N",  5, 2 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "IVA_COD", "CODIGO" } )
    AAdd( aTablas, { "TIPOSIVA", aCampos, aIndices } )

    // -- 34. FAMILIAS --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CODIGO",   "C",  3, 0 } )
    AAdd( aCampos, { "DESCRIP",  "C", 30, 0 } )
    AAdd( aCampos, { "CTA_VTA",  "C", 10, 0 } )
    AAdd( aCampos, { "CTA_COM",  "C", 10, 0 } )
    AAdd( aCampos, { "DEF_IVA",  "C",  1, 0 } )
    AAdd( aCampos, { "MARGEN",   "N",  5, 2 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "FAM_COD", "CODIGO" } )
    AAdd( aIndices, { "FAM_NOM", "Upper(DESCRIP)" } )
    AAdd( aTablas, { "FAMILIAS", aCampos, aIndices } )

    // -- 35. TIPOSIRPF --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CODIGO",   "C",  2, 0 } )
    AAdd( aCampos, { "DESCRIP",  "C", 30, 0 } )
    AAdd( aCampos, { "PORCENTA", "N",  5, 2 } )
    AAdd( aIndices, { "IRF_COD", "CODIGO" } )
    AAdd( aTablas, { "TIPOSIRPF", aCampos, aIndices } )

    // -- 36. PARTIDAS (catalogo de partidas tecnicas reutilizables) --
    aCampos  := {}
    aIndices := {}
    AAdd( aCampos, { "CODIGO",   "C", 10, 0 } )
    AAdd( aCampos, { "DESCRIP",  "C", 60, 0 } )
    AAdd( aCampos, { "PRECIO",   "N", 12, 2 } )
    AAdd( aCampos, { "PORC_IVA", "N",  5, 2 } )
    AAdd( aCampos, { "UNIDAD",   "C",  3, 0 } )
    AAdd( aCampos, { "BAJA",     "L",  1, 0 } )
    AAdd( aIndices, { "PAR_COD", "CODIGO" } )
    AAdd( aIndices, { "PAR_DES", "Upper(DESCRIP)" } )
    AAdd( aTablas, { "PARTIDAS", aCampos, aIndices } )

    // =========================================================================
    // CREACION FISICA DE TABLAS E INDICES
    // =========================================================================
    SET EXCLUSIVE ON

    BEGIN SEQUENCE

        FOR i := 1 TO Len( aTablas )

            cDbf  := aTablas[i, 1]
            aStru := aTablas[i, 2]
            aIdx  := aTablas[i, 3]

            // Si el DBF ya existe no hacer nada — datos y CDX intactos.
            // El reindexado es una operacion de mantenimiento separada
            // que solo ejecuta el ADM previa copia de seguridad.
            IF !File( cDbf + ".DBF" )
                DbCreate( cDbf, aStru )
                IF Len( aIdx ) > 0
                    USE (cDbf) NEW EXCLUSIVE
                    IF !NetErr()
                        FOR EACH oIdx IN aIdx
                            OrdCreate( cDbf + ".CDX", oIdx[1], oIdx[2] )
                        NEXT
                        USE
                    ELSE
                        lOK := .F.
                    ENDIF
                ENDIF
            ENDIF

        NEXT

    RECOVER

        lOK := .F.

    END SEQUENCE

    SET EXCLUSIVE OFF

    IF !lOK
        MsgStop( "Error al crear o reindexar las tablas.", "InicioDBF" )
        RETURN .F.
    ENDIF

    // =========================================================================
    // SIEMBRA DE DATOS INICIALES
    // =========================================================================
    _SiembraIVA()
    _SiembraCatalogo()

RETURN .T.


// ============================================================================
// _SiembraIVA()
// Carga los 4 tipos de IVA estandar si la tabla esta vacia.
// ============================================================================
STATIC FUNCTION _SiembraIVA()

    IF !ABRIR_TABLA( "TIPOSIVA", "IVA_S", "IVA_COD" )
        RETURN NIL
    ENDIF

    DbSelectArea( "IVA_S" )

    IF LastRec() == 0

        IF NetFLock()

            DbAppend()
            REPLACE IVA_S->CODIGO   WITH "G"
            REPLACE IVA_S->DESCRIP   WITH "General 21%"
            REPLACE IVA_S->PORC_IVA  WITH 21.00
            REPLACE IVA_S->PORC_RE   WITH 5.20

            DbAppend()
            REPLACE IVA_S->CODIGO   WITH "R"
            REPLACE IVA_S->DESCRIP   WITH "Reducido 10%"
            REPLACE IVA_S->PORC_IVA  WITH 10.00
            REPLACE IVA_S->PORC_RE   WITH 1.40

            DbAppend()
            REPLACE IVA_S->CODIGO   WITH "S"
            REPLACE IVA_S->DESCRIP   WITH "Superreducido 4%"
            REPLACE IVA_S->PORC_IVA  WITH 4.00
            REPLACE IVA_S->PORC_RE   WITH 0.50

            DbAppend()
            REPLACE IVA_S->CODIGO   WITH "E"
            REPLACE IVA_S->DESCRIP   WITH "Exento 0%"
            REPLACE IVA_S->PORC_IVA  WITH 0.00
            REPLACE IVA_S->PORC_RE   WITH 0.00

            DbUnlock()

        ENDIF

    ENDIF

    IVA_S->( DbCloseArea() )

RETURN NIL


// ============================================================================
// _SiembraCatalogo()
// Siembra grupos, subgrupos y cuentas principales del PGC 2007.
// Solo actua si CATALOGO esta vacio.
// Estructura: { cCuenta, cNombre, nNivel, cTipo, cNaturaleza, cSumaEn }
//   nNivel : 1=Grupo 2=Subgrupo 3=Cuenta 4=Subcuenta
//   cTipo  : A=Activo P=Pasivo G=Gasto I=Ingreso N=Neto
//   cNatur : D=Deudora A=Acreedora
//   cSumaEn: cuenta padre (para consolidar saldos)
// ============================================================================
STATIC FUNCTION _SiembraCatalogo()

    LOCAL aPGC  := {}
    LOCAL i
    LOCAL aFil

    IF !ABRIR_TABLA( "CATALOGO", "CAT_S", "CAT_CTA" )
        RETURN NIL
    ENDIF

    DbSelectArea( "CAT_S" )

    IF LastRec() > 0
        CAT_S->( DbCloseArea() )
        RETURN NIL
    ENDIF

    // -------------------------------------------------------------------------
    // DEFINICION  { cCuenta, cNombre, nNivel, cTipo, cNatur, cSumaEn }
    // -------------------------------------------------------------------------

    // --- GRUPO 1: Financiacion basica ---
    AAdd( aPGC, { "1",   "FINANCIACION BASICA",              1, "P", "A", ""  } )
    AAdd( aPGC, { "10",  "Capital",                          2, "P", "A", "1" } )
    AAdd( aPGC, { "100", "Capital social",                   3, "P", "A", "10"} )
    AAdd( aPGC, { "11",  "Reservas y otros instrumentos",    2, "P", "A", "1" } )
    AAdd( aPGC, { "112", "Reserva legal",                    3, "P", "A", "11"} )
    AAdd( aPGC, { "113", "Reservas voluntarias",             3, "P", "A", "11"} )
    AAdd( aPGC, { "12",  "Resultados pendientes",            2, "P", "A", "1" } )
    AAdd( aPGC, { "120", "Remanente",                        3, "P", "A", "12"} )
    AAdd( aPGC, { "129", "Resultado del ejercicio",          3, "P", "A", "12"} )
    AAdd( aPGC, { "17",  "Deudas a largo plazo",             2, "P", "A", "1" } )
    AAdd( aPGC, { "170", "Deudas a l/p entidades de credito",3, "P", "A", "17"} )

    // --- GRUPO 2: Activo no corriente ---
    AAdd( aPGC, { "2",   "ACTIVO NO CORRIENTE",              1, "A", "D", ""  } )
    AAdd( aPGC, { "20",  "Inmovilizaciones intangibles",     2, "A", "D", "2" } )
    AAdd( aPGC, { "200", "Investigacion",                    3, "A", "D", "20"} )
    AAdd( aPGC, { "206", "Aplicaciones informaticas",        3, "A", "D", "20"} )
    AAdd( aPGC, { "21",  "Inmovilizaciones materiales",      2, "A", "D", "2" } )
    AAdd( aPGC, { "210", "Terrenos y bienes naturales",      3, "A", "D", "21"} )
    AAdd( aPGC, { "211", "Construcciones",                   3, "A", "D", "21"} )
    AAdd( aPGC, { "213", "Maquinaria",                       3, "A", "D", "21"} )
    AAdd( aPGC, { "216", "Mobiliario",                       3, "A", "D", "21"} )
    AAdd( aPGC, { "217", "Equipos proceso informacion",      3, "A", "D", "21"} )
    AAdd( aPGC, { "218", "Elementos de transporte",          3, "A", "D", "21"} )
    AAdd( aPGC, { "28",  "Amortizacion acumulada inmoviliz.", 2, "A", "A", "2" } )
    AAdd( aPGC, { "280", "Amort. acum. inmoviliz. intangib.", 3, "A", "A", "28"} )
    AAdd( aPGC, { "281", "Amort. acum. inmoviliz. material", 3, "A", "A", "28"} )

    // --- GRUPO 3: Existencias ---
    AAdd( aPGC, { "3",   "EXISTENCIAS",                      1, "A", "D", ""  } )
    AAdd( aPGC, { "30",  "Comerciales",                      2, "A", "D", "3" } )
    AAdd( aPGC, { "300", "Mercancias",                       3, "A", "D", "30"} )
    AAdd( aPGC, { "31",  "Materias primas",                  2, "A", "D", "3" } )
    AAdd( aPGC, { "310", "Materias primas",                  3, "A", "D", "31"} )

    // --- GRUPO 4: Acreedores y deudores ---
    AAdd( aPGC, { "4",   "ACREEDORES Y DEUDORES COMERC.",    1, "N", "D", ""  } )
    AAdd( aPGC, { "40",  "Proveedores",                      2, "P", "A", "4" } )
    AAdd( aPGC, { "400", "Proveedores",                      3, "P", "A", "40"} )
    AAdd( aPGC, { "401", "Proveedores, efectos comerciales", 3, "P", "A", "40"} )
    AAdd( aPGC, { "407", "Anticipos a proveedores",          3, "A", "D", "40"} )
    AAdd( aPGC, { "41",  "Acreedores varios",                2, "P", "A", "4" } )
    AAdd( aPGC, { "410", "Acreedores por prest. de servicios",3,"P", "A", "41"} )
    AAdd( aPGC, { "43",  "Clientes",                         2, "A", "D", "4" } )
    AAdd( aPGC, { "430", "Clientes",                         3, "A", "D", "43"} )
    AAdd( aPGC, { "431", "Clientes, efectos comerciales",    3, "A", "D", "43"} )
    AAdd( aPGC, { "438", "Anticipos de clientes",            3, "P", "A", "43"} )
    AAdd( aPGC, { "44",  "Deudores varios",                  2, "A", "D", "4" } )
    AAdd( aPGC, { "440", "Deudores",                         3, "A", "D", "44"} )
    AAdd( aPGC, { "47",  "Administraciones Publicas",        2, "N", "D", "4" } )
    AAdd( aPGC, { "470", "HP deudora por diversos conceptos",3, "A", "D", "47"} )
    AAdd( aPGC, { "471", "Organismos SS deudores",           3, "A", "D", "47"} )
    AAdd( aPGC, { "472", "HP IVA soportado",                 3, "A", "D", "47"} )
    AAdd( aPGC, { "473", "HP retenciones y pagos a cuenta",  3, "A", "D", "47"} )
    AAdd( aPGC, { "474", "Activos por impuesto diferido",    3, "A", "D", "47"} )
    AAdd( aPGC, { "475", "HP acreedora por conceptos fisc.", 3, "P", "A", "47"} )
    AAdd( aPGC, { "476", "Organismos SS acreedores",         3, "P", "A", "47"} )
    AAdd( aPGC, { "477", "HP IVA repercutido",               3, "P", "A", "47"} )
    AAdd( aPGC, { "479", "Pasivos por diferencias temporarias",3,"P","A", "47"} )

    // --- GRUPO 5: Cuentas financieras ---
    AAdd( aPGC, { "5",   "CUENTAS FINANCIERAS",              1, "N", "D", ""  } )
    AAdd( aPGC, { "51",  "Deudas a corto plazo",             2, "P", "A", "5" } )
    AAdd( aPGC, { "520", "Deudas a c/p entidades de credito",3, "P", "A", "51"} )
    AAdd( aPGC, { "52",  "Deudas a c/p por prest. recibidos",2, "P", "A", "5" } )
    AAdd( aPGC, { "55",  "Otras cuentas no bancarias",       2, "N", "D", "5" } )
    AAdd( aPGC, { "550", "Titular de la explotacion",        3, "N", "D", "55"} )
    AAdd( aPGC, { "57",  "Tesoreria",                        2, "A", "D", "5" } )
    AAdd( aPGC, { "570", "Caja, euros",                      3, "A", "D", "57"} )
    AAdd( aPGC, { "572", "Bancos e instituciones de credito", 3, "A", "D", "57"} )
    AAdd( aPGC, { "58",  "Activos no corrientes mantenidos", 2, "A", "D", "5" } )

    // --- GRUPO 6: Compras y gastos ---
    AAdd( aPGC, { "6",   "COMPRAS Y GASTOS",                 1, "G", "D", ""  } )
    AAdd( aPGC, { "60",  "Compras",                          2, "G", "D", "6" } )
    AAdd( aPGC, { "600", "Compras de mercancias",            3, "G", "D", "60"} )
    AAdd( aPGC, { "601", "Compras de materias primas",       3, "G", "D", "60"} )
    AAdd( aPGC, { "608", "Devoluciones de compras",          3, "G", "A", "60"} )
    AAdd( aPGC, { "609", "Rappels por compras",              3, "G", "A", "60"} )
    AAdd( aPGC, { "62",  "Servicios exteriores",             2, "G", "D", "6" } )
    AAdd( aPGC, { "620", "Gastos en I+D del ejercicio",      3, "G", "D", "62"} )
    AAdd( aPGC, { "621", "Arrendamientos y canones",         3, "G", "D", "62"} )
    AAdd( aPGC, { "622", "Reparaciones y conservacion",      3, "G", "D", "62"} )
    AAdd( aPGC, { "623", "Servicios de profesionales indep.", 3,"G", "D", "62"} )
    AAdd( aPGC, { "624", "Transportes",                      3, "G", "D", "62"} )
    AAdd( aPGC, { "625", "Primas de seguros",                3, "G", "D", "62"} )
    AAdd( aPGC, { "626", "Servicios bancarios y similares",  3, "G", "D", "62"} )
    AAdd( aPGC, { "627", "Publicidad, propaganda y RR.PP.",  3, "G", "D", "62"} )
    AAdd( aPGC, { "628", "Suministros",                      3, "G", "D", "62"} )
    AAdd( aPGC, { "629", "Otros servicios",                  3, "G", "D", "62"} )
    AAdd( aPGC, { "63",  "Tributos",                         2, "G", "D", "6" } )
    AAdd( aPGC, { "630", "Impuesto sobre beneficios",        3, "G", "D", "63"} )
    AAdd( aPGC, { "631", "Otros tributos",                   3, "G", "D", "63"} )
    AAdd( aPGC, { "64",  "Gastos de personal",               2, "G", "D", "6" } )
    AAdd( aPGC, { "640", "Sueldos y salarios",               3, "G", "D", "64"} )
    AAdd( aPGC, { "641", "Indemnizaciones",                  3, "G", "D", "64"} )
    AAdd( aPGC, { "642", "Seguridad Social a cargo empresa", 3, "G", "D", "64"} )
    AAdd( aPGC, { "649", "Otros gastos sociales",            3, "G", "D", "64"} )
    AAdd( aPGC, { "65",  "Otros gastos de gestion",          2, "G", "D", "6" } )
    AAdd( aPGC, { "650", "Perdidas de creditos comerc.",      3, "G", "D", "65"} )
    AAdd( aPGC, { "659", "Otros gastos de gestion corriente",3, "G", "D", "65"} )
    AAdd( aPGC, { "66",  "Gastos financieros",               2, "G", "D", "6" } )
    AAdd( aPGC, { "662", "Intereses de deudas",              3, "G", "D", "66"} )
    AAdd( aPGC, { "665", "Descuentos sobre ventas p.p.",     3, "G", "D", "66"} )
    AAdd( aPGC, { "68",  "Dotaciones para amortizaciones",   2, "G", "D", "6" } )
    AAdd( aPGC, { "681", "Amort. inmovilizado intangible",   3, "G", "D", "68"} )
    AAdd( aPGC, { "682", "Amort. inmovilizado material",     3, "G", "D", "68"} )

    // --- GRUPO 7: Ventas e ingresos ---
    AAdd( aPGC, { "7",   "VENTAS E INGRESOS",                1, "I", "A", ""  } )
    AAdd( aPGC, { "70",  "Ventas de mercancias y produccion",2, "I", "A", "7" } )
    AAdd( aPGC, { "700", "Ventas de mercancias",             3, "I", "A", "70"} )
    AAdd( aPGC, { "701", "Ventas de productos terminados",   3, "I", "A", "70"} )
    AAdd( aPGC, { "705", "Prestaciones de servicios",        3, "I", "A", "70"} )
    AAdd( aPGC, { "72",  "Produccion inmovilizada",          2, "I", "A", "7"  } )
    AAdd( aPGC, { "720", "Obra en curso",                    3, "I", "A", "72"} )
    AAdd( aPGC, { "721", "Certificaciones de obra",          3, "I", "A", "72"} )
    AAdd( aPGC, { "708", "Devoluciones de ventas y operac.", 3, "I", "D", "70"} )
    AAdd( aPGC, { "709", "Rappels sobre ventas",             3, "I", "D", "70"} )
    AAdd( aPGC, { "75",  "Otros ingresos de gestion",        2, "I", "A", "7" } )
    AAdd( aPGC, { "751", "Resultados de operaciones en comun",3,"I", "A", "75"} )
    AAdd( aPGC, { "759", "Ingresos por servicios diversos",  3, "I", "A", "75"} )
    AAdd( aPGC, { "76",  "Ingresos financieros",             2, "I", "A", "7" } )
    AAdd( aPGC, { "762", "Ingresos de creditos",             3, "I", "A", "76"} )
    AAdd( aPGC, { "765", "Descuentos sobre compras p.p.",    3, "I", "A", "76"} )
    AAdd( aPGC, { "77",  "Beneficios procedentes de activos",2, "I", "A", "7" } )

    // -------------------------------------------------------------------------
    // GRABACION
    // -------------------------------------------------------------------------
    IF !NetFLock()
        CAT_S->( DbCloseArea() )
        RETURN NIL
    ENDIF

    FOR i := 1 TO Len( aPGC )
        aFil := aPGC[i]
        DbAppend()
        REPLACE CAT_S->CUENTA   WITH PadR( aFil[1], 10 )
        REPLACE CAT_S->NOMBRE   WITH PadR( aFil[2], 60 )
        REPLACE CAT_S->NIVEL    WITH aFil[3]
        REPLACE CAT_S->TIPO     WITH aFil[4]
        REPLACE CAT_S->NATURALE WITH aFil[5]
        REPLACE CAT_S->SUMA_EN  WITH PadR( aFil[6], 10 )
        REPLACE CAT_S->BLOQUEAD WITH .F.
        REPLACE CAT_S->BAJA     WITH .F.
    NEXT

    DbCommit()
    DbUnlock()

    CAT_S->( DbCloseArea() )

RETURN NIL



// ============================================================================
// ReindexarTodo()
// ----------------------------------------------------------------------------
// Operacion de mantenimiento — solo disponible para ADM.
// Recrea todos los indices CDX de todas las tablas del sistema.
//
// IMPORTANTE: ejecutar SIEMPRE con copia de seguridad previa y con
// todos los usuarios desconectados (modo exclusivo).
//
// Flujo recomendado:
//   1. Cerrar sesion de todos los usuarios
//   2. Hacer copia de seguridad de .\DATA//   3. Entrar como ADM
//   4. Sistema → Reindexar
// ============================================================================
FUNCTION ReindexarTodo()

    LOCAL aTablas
    LOCAL aIndices
    LOCAL i
    LOCAL cDbf
    LOCAL oIdx
    LOCAL nTotal
    LOCAL nOK
    LOCAL cMsg

    IF !RequirePerm( "SEG_REINDEX", "Reindexar tablas" )
        RETURN .F.
    ENDIF

    IF !MsgYesNo( "Esta operacion requiere copia de seguridad previa." + Chr(13) + ;
                  "Todos los usuarios deben estar desconectados." + Chr(13) + ;
                  "Desea continuar?", "Reindexar tablas" )
        RETURN .F.
    ENDIF

    // Construir lista de tablas e indices (igual que InicioDBF pero solo indices)
    aTablas := _GetTablasList()

    nTotal := Len( aTablas )
    nOK    := 0

    SET EXCLUSIVE ON

    BEGIN SEQUENCE

        FOR i := 1 TO nTotal

            cDbf    := aTablas[i, 1]
            aIndices := aTablas[i, 2]

            IF !File( cDbf + ".DBF" ) .OR. Len( aIndices ) == 0
                nOK++
                LOOP
            ENDIF

            // Borrar CDX existente
            IF File( cDbf + ".CDX" )
                FErase( cDbf + ".CDX" )
            ENDIF

            // Recrear indices
            USE (cDbf) NEW EXCLUSIVE
            IF !NetErr()
                FOR EACH oIdx IN aIndices
                    OrdCreate( cDbf + ".CDX", oIdx[1], oIdx[2] )
                NEXT
                USE
                nOK++
            ENDIF

        NEXT

    RECOVER

        SET EXCLUSIVE OFF
        MsgStop( "Error durante el reindexado. Restaure la copia de seguridad.", ;
                 "Error critico" )
        RETURN .F.

    END SEQUENCE

    SET EXCLUSIVE OFF

    cMsg := "Reindexado completado." + Chr(13) + ;
            AllTrim( Str( nOK ) ) + " de " + AllTrim( Str( nTotal ) ) + ;
            " tablas procesadas correctamente."

    MsgInfo( cMsg, "Reindexar" )

RETURN .T.


// ----------------------------------------------------------------------------
// _GetTablasList() — devuelve array { cNombreDBF, aIndices } de todas las tablas
// Se mantiene sincronizado con InicioDBF() manualmente.
// ----------------------------------------------------------------------------
STATIC FUNCTION _GetTablasList()

    LOCAL aTablas

    aTablas := {}

    AAdd( aTablas, { "EMPRESA",    { { "EMP_NIF",  "NIF"                        } } } )
    AAdd( aTablas, { "CLIENTES",   { { "CLI_ID",   "ID"                         }, ;
                                     { "CLI_NOM",  "Upper(NOMBRE+APELLIDO)"     }, ;
                                     { "CLI_NIF",  "Upper(NIF)"                 }, ;
                                     { "CLI_CIU",  "Upper(CIUDAD)"              } } } )
    AAdd( aTablas, { "PROVEED",    { { "PRV_ID",   "ID"                         }, ;
                                     { "PRV_NOM",  "Upper(NOMBRE+APELLIDO)"     }, ;
                                     { "PRV_NIF",  "Upper(NIF)"                 }, ;
                                     { "PRV_CIU",  "Upper(CIUDAD)"              } } } )
    AAdd( aTablas, { "ARTICULOS",  { { "ART_COD",  "CODIGO"                     }, ;
                                     { "ART_DES",  "Upper(DESCRIP)"             }, ;
                                     { "ART_FAM",  "FAMILIA"                    }, ;
                                     { "ART_BAR",  "COD_BARR"                   } } } )
    AAdd( aTablas, { "MOVIMIEN",   { { "MOV_ART",  "COD_ART"                    }, ;
                                     { "MOV_FEC",  "DtoS(FECHA)"                }, ;
                                     { "MOV_DOC",  "DOC_ORIG"                   } } } )
    AAdd( aTablas, { "CATALOGO",   { { "CAT_CTA",  "CUENTA"                     }, ;
                                     { "CAT_NOM",  "Upper(NOMBRE)"              }, ;
                                     { "CAT_MAY",  "SUMA_EN"                    } } } )
    AAdd( aTablas, { "LDIARIO",    { { "DIA_ASI",  "D_ASIENT+Str(D_LINEA,4)"   }, ;
                                     { "DIA_FEC",  "DtoS(D_FECHA)+D_ASIENT"    }, ;
                                     { "DIA_MAY",  "D_CUENTA+DtoS(D_FECHA)"    }, ;
                                     { "DIA_ANA",  "D_CCOSTE+D_CUENTA"         } } } )
    AAdd( aTablas, { "BANCOS",     { { "BAN_COD",  "BAN_COD"                    }, ;
                                     { "BAN_NOM",  "Upper(BAN_NOM)"             } } } )
    AAdd( aTablas, { "VENDEDOR",   { { "VEN_ID",   "ID"                         }, ;
                                     { "VEN_NOM",  "Upper(NOMBRE)"              } } } )
    AAdd( aTablas, { "USUARIOS",   { { "USR_COD",  "CODIGO"                     }, ;
                                     { "USR_NOM",  "Upper(NOMBRE)"              } } } )
    AAdd( aTablas, { "ROLES",      { { "ROLID",    "ID"                         } } } )
    AAdd( aTablas, { "ROL_PERM",   { { "RPM_ROL",  "ROLID+PERMISO"              }, ;
                                     { "RPM_PER",  "PERMISO+ROLID"              } } } )
    AAdd( aTablas, { "AUDITLOG",   { { "AUD_ID",   "ID"                         }, ;
                                     { "AUD_FEC",  "DtoS(FECHA)+HORA"           }, ;
                                     { "AUD_USR",  "USUARIO+DtoS(FECHA)"        } } } )
    AAdd( aTablas, { "GEOLOC",     { { "GEO_CP",   "CP"                         }, ;
                                     { "GEO_CIU",  "Upper(CIUDAD)"              }, ;
                                     { "GEO_PRV",  "Upper(PROVINCI)"            } } } )
    AAdd( aTablas, { "FACTURA",    { { "FAC_NUM",  "SERIE+NUMERO"               }, ;
                                     { "FAC_CLI",  "CLIENTE_"                   }, ;
                                     { "FAC_FEC",  "DtoS(FECHA)"                }, ;
                                     { "FAC_VTO",  "DtoS(FECHA_VT)"             }, ;
                                     { "FAC_PTE",  "CLIENTE_+DtoS(FECHA)"       }, ;
                                     { "FAC_OBR",  "ID_OBRA+DtoS(FECHA)"        } } } )
    AAdd( aTablas, { "FACTUR_DE",  { { "FAC_LIN",  "SERIE+NUMERO+Str(LINEA,3)" } } } )
    AAdd( aTablas, { "PEDIDOS",    { { "PED_NUM",  "NUMERO"                     }, ;
                                     { "PED_CLI",  "CLIENTE_"                   }, ;
                                     { "PED_FEC",  "DtoS(FECHA)"                }, ;
                                     { "PED_EST",  "ESTADO"                     } } } )
    AAdd( aTablas, { "PED_DET",    { { "PED_LIN",  "NUMERO+Str(LINEA,3)"       } } } )
    AAdd( aTablas, { "NOTASDC",    { { "NDC_NUM",  "SERIE+NUMERO"               }, ;
                                     { "NDC_CLI",  "CLIENTE_"                   }, ;
                                     { "NDC_FEC",  "DtoS(FECHA)"                }, ;
                                     { "NDC_TIP",  "TIPO+CLIENTE_"              } } } )
    AAdd( aTablas, { "NOTASD_DE",  { { "NDC_LIN",  "NUMERO+Str(LINEA,3)"       } } } )
    AAdd( aTablas, { "COMPRAS",    { { "COM_INT",  "NUM_INTE"                   }, ;
                                     { "COM_PRO",  "PROV_ID"                    }, ;
                                     { "COM_FEC",  "DtoS(FECHA)"                }, ;
                                     { "COM_VTO",  "DtoS(FECHA_VT)"             } } } )
    AAdd( aTablas, { "PAGOS",      { { "PAG_NUM",  "NUMERO"                     }, ;
                                     { "PAG_FEC",  "DtoS(FECHA)"                }, ;
                                     { "PAG_PRV",  "PROV_ID+DtoS(FECHA)"        } } } )
    AAdd( aTablas, { "PAGO_DET",   { { "PGD_LIN",  "NUMERO+Str(LINEA,3)"       } } } )
    AAdd( aTablas, { "COMP_DET",   { { "CPD_LIN",  "NUMERO+Str(LINEA,3)"       } } } )
    AAdd( aTablas, { "RECIBOS",    { { "REC_NUM",  "NUMERO"                     }, ;
                                     { "REC_CLI",  "CLIENTE_"                   }, ;
                                     { "REC_FEC",  "DtoS(FECHA)"                } } } )
    AAdd( aTablas, { "RC_DETAL",   { { "RCD_NUM",  "NUMERO+Str(LINEA,3)"       }, ;
                                     { "RCD_FAC",  "NUM_FAC"                    } } } )
    AAdd( aTablas, { "VENCIMIEN",  { { "VEN_NUM",  "TIPO+NUMERO"                }, ;
                                     { "VEN_FEC",  "DtoS(VENCTO)"               }, ;
                                     { "VEN_TER",  "TIPO+CODTERCE+DtoS(VENCTO)" }, ;
                                     { "VEN_OBR",  "ID_OBRA+DtoS(VENCTO)"       } } } )
    AAdd( aTablas, { "OBRAS",      { { "OBR_ID",   "ID"                         }, ;
                                     { "OBR_PRE",  "NUM_PRE"                    }, ;
                                     { "OBR_CLI",  "CLIENTE_"                   }, ;
                                     { "OBR_EST",  "ESTADO"                     } } } )
    AAdd( aTablas, { "PRESUPUEST", { { "PRE_NUM",  "NUMERO"                     }, ;
                                     { "PRE_CLI",  "CLIENTE_"                   }, ;
                                     { "PRE_FEC",  "DtoS(FECHA)"                }, ;
                                     { "PRE_OBR",  "ID_OBRA"                    } } } )
    AAdd( aTablas, { "PRESUP_DE",  { { "PRD_LIN",  "NUMERO+Str(LINEA,3)"       } } } )
    AAdd( aTablas, { "CHEQUES",    { { "CHQ_NUM",  "NUMERO"                     }, ;
                                     { "CHQ_FEC",  "DtoS(FECHA_EM)"             }, ;
                                     { "CHQ_VTO",  "DtoS(FECHA_VT)"             } } } )
    AAdd( aTablas, { "CHEQUE_DE",  { { "CHD_LIN",  "NUMERO+Str(LINEA,3)"       } } } )
    AAdd( aTablas, { "AJUSTEIN",   { { "AJU_NUM",  "NUMERO"                     }, ;
                                     { "AJU_ART",  "ARTICULO"                   } } } )
    AAdd( aTablas, { "CONTADOR",   { { "COD_DOC",  "COD_DOC"                    } } } )
    AAdd( aTablas, { "BAL_DEF",    { { "BAL_ORD",  "TIPO_BAL+CODIGO"            } } } )
    AAdd( aTablas, { "TIENDAS",    { { "TDA_ID",   "ID"                         } } } )
    AAdd( aTablas, { "CCOSTOS",    { { "CCO_COD",  "CCO_COD"                    } } } )
    AAdd( aTablas, { "FORMAPAGO",  { { "FP_COD",   "CODIGO"                     } } } )
    AAdd( aTablas, { "TIPOSIVA",   { { "IVA_COD",  "CODIGO"                     } } } )
    AAdd( aTablas, { "FAMILIAS",   { { "FAM_COD",  "CODIGO"                     }, ;
                                     { "FAM_NOM",  "Upper(DESCRIP)"             } } } )
    AAdd( aTablas, { "TIPOSIRPF",  { { "IRF_COD",  "CODIGO"                     } } } )
    AAdd( aTablas, { "PARTIDAS",   { { "PAR_COD",  "CODIGO"                     }, ;
                                      { "PAR_DES",  "Upper(DESCRIP)"             } } } )

RETURN aTablas


// ============================================================================
// FIN DE InicioDBF.prg
// ============================================================================
