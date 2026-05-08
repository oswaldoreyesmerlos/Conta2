/*
 * ARCHIVO  : SeedTestData.prg
 * PROPOSITO: Inyectar datos de prueba exhaustivos para formularios/listados.
 *
 * COMPILAR : hbmk2 seed_testdata.hbp
 * EJECUTAR : SeedTestData.exe
 *
 * Los registros usan prefijo TST para poder localizarlos facilmente.
 */

#include "OOp.ch"

REQUEST DBFCDX

MEMVAR cUserID, cUserNom, cUserRol, cEmpNom

INIT PROCEDURE SeedBootTrace()
   SeedMain()
   QUIT
RETURN

PROCEDURE SeedMain()

   LOCAL nBefore
   LOCAL nAfter
   LOCAL cDataDir := ".\DATA"

   ErrorBlock( { |e| _SeedError( e ) } )

   SET DATE BRIT
   SET DATE FORMAT TO "DD/MM/YYYY"
   SET EPOCH TO 1950
   SET CENTURY ON
   SET DELETED ON
   SET EXACT ON
   rddSetDefault( "DBFCDX" )

   IF !DirExiste( cDataDir )
      DirMake( cDataDir )
   ENDIF

   IF !File( ".\DATA\CLIENTES.DBF" )
      IF !InicioDBF()
         _SeedLog( "ERROR InicioDBF()" )
         ? "ERROR: no se pudieron preparar las tablas."
         RETURN
      ENDIF
   ENDIF

   DirChange( ".\DATA" )

   hb_MemoWrit( "..\seed_testdata.log", "Inicio seed " + DToC( Date() ) + " " + Time() + Chr(13) + Chr(10) )

   nBefore := _CountTST()

   _SeedEmpresa()
   _SeedAuxiliares()
   _SeedMaestros()
   _SeedContabilidad()
   _SeedVentas()
   _SeedComprasTesoreria()
   _SeedSeguridad()

   nAfter := _CountTST()
   _SeedLog( "Registros TST antes: " + AllTrim( Str( nBefore ) ) )
   _SeedLog( "Registros TST despues: " + AllTrim( Str( nAfter ) ) )

   dbCloseAll()

   ? "Datos de prueba TST inyectados correctamente."
   ? "Se han creado/actualizado al menos dos registros por modulo principal."

RETURN


STATIC FUNCTION _SeedError( e )

   LOCAL cMsg

   cMsg := "ERROR " + DToC( Date() ) + " " + Time() + Chr(13) + Chr(10)
   cMsg += "Subsistema: " + hb_CStr( e:SubSystem ) + Chr(13) + Chr(10)
   cMsg += "Operacion : " + hb_CStr( e:Operation ) + Chr(13) + Chr(10)
   cMsg += "Codigo    : " + hb_CStr( e:GenCode ) + Chr(13) + Chr(10)
   cMsg += "Desc      : " + hb_CStr( e:Description ) + Chr(13) + Chr(10)
   cMsg += ProcName( 1 ) + " linea " + AllTrim( Str( ProcLine( 1 ) ) ) + Chr(13) + Chr(10)
   cMsg += ProcName( 2 ) + " linea " + AllTrim( Str( ProcLine( 2 ) ) ) + Chr(13) + Chr(10)
   cMsg += ProcName( 3 ) + " linea " + AllTrim( Str( ProcLine( 3 ) ) ) + Chr(13) + Chr(10)

   hb_MemoWrit( "..\seed_error.log", cMsg )
   dbCloseAll()
   QUIT

RETURN NIL


STATIC FUNCTION _SeedLog( cText )

   LOCAL cFile := "..\seed_testdata.log"
   LOCAL cOld  := ""

   IF File( cFile )
      cOld := hb_MemoRead( cFile )
   ENDIF

   hb_MemoWrit( cFile, cOld + cText + Chr(13) + Chr(10) )

RETURN NIL


STATIC FUNCTION _CountTST()

   LOCAL nTotal := 0
   LOCAL aTabs  := { "CLIENTES", "PROVEED", "ARTICULOS", "PRESUPUEST", ;
                     "OBRAS", "FACTURA", "USUARIOS" }
   LOCAL i

   FOR i := 1 TO Len( aTabs )
      nTotal += _CountTSTTabla( aTabs[i] )
   NEXT

RETURN nTotal


STATIC FUNCTION _CountTSTTabla( cTabla )

   LOCAL nCount := 0
   LOCAL cAlias := "CNT_" + Left( cTabla, 3 )
   LOCAL i
   LOCAL xVal

   IF !ABRIR_TABLA( cTabla, cAlias, "" )
      RETURN 0
   ENDIF

   DbSelectArea( cAlias )
   DbGoTop()
   DO WHILE !Eof()
      IF !Deleted()
         FOR i := 1 TO FCount()
            xVal := FieldGet( i )
            IF ValType( xVal ) == "C" .AND. "TST" $ Upper( xVal )
               nCount++
               EXIT
            ENDIF
         NEXT
      ENDIF
      DbSkip()
   ENDDO

   (cAlias)->( DbCloseArea() )

RETURN nCount


STATIC FUNCTION _SeedEmpresa()

   _Upsert( "EMPRESA", "EMP_TST", "EMP_NIF", "B00000000", {|| ;
      EMP_TST->NIF      := "B00000000", ;
      EMP_TST->NOMBRE   := "Empresa Test Construccion SL", ;
      EMP_TST->DIRECCIO := "Calle Obra 1", ;
      EMP_TST->CIUDAD   := "Barcelona", ;
      EMP_TST->PROVINCI := "Barcelona", ;
      EMP_TST->CP       := "08001", ;
      EMP_TST->PAIS     := "Espana", ;
      EMP_TST->TELEFONO := "900100100", ;
      EMP_TST->EMAIL    := "test@empresa.local", ;
      EMP_TST->PREFIJO  := "TST", ;
      EMP_TST->PIE_DOC  := "Datos inyectados para pruebas funcionales." } )

   _Upsert( "EMPRESA", "EMP_TST", "EMP_NIF", "B00000001", {|| ;
      EMP_TST->NIF      := "B00000001", ;
      EMP_TST->NOMBRE   := "Empresa Test Reformas SL", ;
      EMP_TST->DIRECCIO := "Avenida Demo 2", ;
      EMP_TST->CIUDAD   := "Valencia", ;
      EMP_TST->PROVINCI := "Valencia", ;
      EMP_TST->CP       := "46001", ;
      EMP_TST->PAIS     := "Espana", ;
      EMP_TST->TELEFONO := "900200200", ;
      EMP_TST->EMAIL    := "reformas@test.local", ;
      EMP_TST->PREFIJO  := "TST", ;
      EMP_TST->PIE_DOC  := "Segundo registro de empresa para pruebas." } )

RETURN NIL


STATIC FUNCTION _SeedAuxiliares()

   _Upsert( "FAMILIAS", "FAM_TST", "FAM_COD", "T01", {|| ;
      FAM_TST->CODIGO := "T01", FAM_TST->DESCRIP := "Material test", ;
      FAM_TST->CTA_VTA := "700", FAM_TST->CTA_COM := "600", ;
      FAM_TST->DEF_IVA := "G", FAM_TST->MARGEN := 25, FAM_TST->BAJA := .F. } )
   _Upsert( "FAMILIAS", "FAM_TST", "FAM_COD", "T02", {|| ;
      FAM_TST->CODIGO := "T02", FAM_TST->DESCRIP := "Servicio test", ;
      FAM_TST->CTA_VTA := "705", FAM_TST->CTA_COM := "607", ;
      FAM_TST->DEF_IVA := "G", FAM_TST->MARGEN := 35, FAM_TST->BAJA := .F. } )

   _Upsert( "FORMAPAGO", "FP_TST", "FP_COD", "T01", {|| ;
      FP_TST->CODIGO := "T01", FP_TST->DESCRIP := "Contado test", ;
      FP_TST->DIAS := 0, FP_TST->NUM_PAGS := 1, FP_TST->CTA_COB := "570", ;
      FP_TST->BAJA := .F. } )
   _Upsert( "FORMAPAGO", "FP_TST", "FP_COD", "T30", {|| ;
      FP_TST->CODIGO := "T30", FP_TST->DESCRIP := "30 dias test", ;
      FP_TST->DIAS := 30, FP_TST->NUM_PAGS := 1, FP_TST->CTA_COB := "572", ;
      FP_TST->BAJA := .F. } )

   _Upsert( "TIPOSIVA", "IVA_TST", "IVA_COD", "T", {|| ;
      IVA_TST->CODIGO := "T", IVA_TST->DESCRIP := "Test 21%", ;
      IVA_TST->PORC_IVA := 21, IVA_TST->PORC_RE := 0, IVA_TST->BAJA := .F. } )
   _Upsert( "TIPOSIVA", "IVA_TST", "IVA_COD", "Z", {|| ;
      IVA_TST->CODIGO := "Z", IVA_TST->DESCRIP := "Test ISP 0%", ;
      IVA_TST->PORC_IVA := 0, IVA_TST->PORC_RE := 0, IVA_TST->BAJA := .F. } )

   _Upsert( "CCOSTOS", "CCO_TST", "CCO_COD", "TSTOBR01", {|| ;
      CCO_TST->CCO_COD := "TSTOBR01", CCO_TST->CCO_DESC := "Obra test 1", ;
      CCO_TST->CCO_RESP := "SEED", CCO_TST->CCO_PRES := 12000, CCO_TST->BAJA := .F. } )
   _Upsert( "CCOSTOS", "CCO_TST", "CCO_COD", "TSTOBR02", {|| ;
      CCO_TST->CCO_COD := "TSTOBR02", CCO_TST->CCO_DESC := "Obra test 2", ;
      CCO_TST->CCO_RESP := "SEED", CCO_TST->CCO_PRES := 18000, CCO_TST->BAJA := .F. } )

RETURN NIL


STATIC FUNCTION _SeedMaestros()

   _SeedCliente( "TSTCLI001", "B11111111", "Francis", "Circuito Test", "T30", 30, .F. )
   _SeedCliente( "TSTCLI002", "B22222222", "Laura",   "Reformas Demo", "T01",  0, .T. )

   _SeedProveedor( "TSTPRO001", "B33333333", "Materiales", "Proveedor Test" )
   _SeedProveedor( "TSTPRO002", "B44444444", "Servicios",  "Industrial Demo" )

   _SeedArticulo( "TSTART001", "Saco cemento test", "T01", "TSTPRO001", 30.00, 48.00, 21 )
   _SeedArticulo( "TSTART002", "Hora oficial test", "T02", "TSTPRO002", 22.00, 38.00, 21 )

   _Upsert( "VENDEDOR", "VEN_TST", "VEN_ID", "TSTVEN001", {|| ;
      VEN_TST->ID := "TSTVEN001", VEN_TST->NOMBRE := "Vendedor Test 1", ;
      VEN_TST->DNI := "00000001T", VEN_TST->TELEFONO := "600000001", ;
      VEN_TST->COMISION := 3, VEN_TST->CTA_CONT := "640", VEN_TST->BAJA := .F. } )
   _Upsert( "VENDEDOR", "VEN_TST", "VEN_ID", "TSTVEN002", {|| ;
      VEN_TST->ID := "TSTVEN002", VEN_TST->NOMBRE := "Vendedor Test 2", ;
      VEN_TST->DNI := "00000002T", VEN_TST->TELEFONO := "600000002", ;
      VEN_TST->COMISION := 5, VEN_TST->CTA_CONT := "640", VEN_TST->BAJA := .F. } )

RETURN NIL


STATIC FUNCTION _SeedContabilidad()

   _SeedCuenta( "430TST001", "Cliente test 1", "A" )
   _SeedCuenta( "430TST002", "Cliente test 2", "A" )
   _SeedCuenta( "700TST001", "Ventas test", "I" )
   _SeedCuenta( "572TST001", "Banco test", "A" )

   _SeedAsiento( "TSTASI001", Date() - 5, "430TST001", 1000, 0, "Asiento test debe" )
   _SeedAsiento( "TSTASI002", Date() - 4, "700TST001", 0, 1000, "Asiento test haber" )

RETURN NIL


STATIC FUNCTION _SeedVentas()

   _SeedPresupuesto( "TSTPRE001", "TSTCLI001", "TSTOBR00001", "A", 12000.00, "Reforma integral test" )
   _SeedPresupuesto( "TSTPRE002", "TSTCLI002", "TSTOBR00002", "P",  6500.00, "Bano test pendiente" )

   _SeedObra( "TSTOBR00001", "TSTPRE001", "TSTCLI001", "Reforma integral test", 12000.00, "E" )
   _SeedObra( "TSTOBR00002", "TSTPRE002", "TSTCLI002", "Bano test pendiente", 6500.00, "A" )

   _SeedFactura( "TSTFAC001", "TSTCLI001", "TSTOBR00001", "TSTPRE001", "A", 3000.00, .F. )
   _SeedFactura( "TSTFAC002", "TSTCLI001", "TSTOBR00001", "TSTPRE001", "C", 4500.00, .F. )

   _SeedNota( "TSTNA0001", "TSTFAC002", "TSTCLI001", 500.00 )
   _SeedNota( "TSTNA0002", "TSTFAC001", "TSTCLI001", 250.00 )

   _SeedPedido( "TSTPED001", "TSTCLI001", 900.00 )
   _SeedPedido( "TSTPED002", "TSTCLI002", 700.00 )

RETURN NIL


STATIC FUNCTION _SeedComprasTesoreria()

   _Upsert( "BANCOS", "BAN_TST", "BAN_COD", "TSTBAN001", {|| ;
      BAN_TST->BAN_COD := "TSTBAN001", BAN_TST->BAN_NOM := "Banco Test 1", ;
      BAN_TST->BAN_IBAN := "ES0000000000000000000001", ;
      BAN_TST->CTA_CONT := "572TST001", BAN_TST->BAN_SALI := 15000, BAN_TST->BAJA := .F. } )
   _Upsert( "BANCOS", "BAN_TST", "BAN_COD", "TSTBAN002", {|| ;
      BAN_TST->BAN_COD := "TSTBAN002", BAN_TST->BAN_NOM := "Banco Test 2", ;
      BAN_TST->BAN_IBAN := "ES0000000000000000000002", ;
      BAN_TST->CTA_CONT := "572", BAN_TST->BAN_SALI := 8000, BAN_TST->BAJA := .F. } )

   _SeedCompra( "TSTCOM001", "TSTPRO001", 1210.00 )
   _SeedCompra( "TSTCOM002", "TSTPRO002",  605.00 )

   _SeedRecibo( "TSTREC001", "TSTCLI001", "TSTFAC001", 3000.00 )
   _SeedRecibo( "TSTREC002", "TSTCLI001", "TSTFAC002", 1500.00 )

   _SeedVencimiento( "TSTFAC001", "A", "TSTCLI001", "TSTOBR00001", 3000.00, .F. )
   _SeedVencimiento( "TSTFAC002", "A", "TSTCLI001", "TSTOBR00001", 4500.00, .F. )

   _SeedCheque( "TSTCHQ001", "TSTBAN001", "TSTPRO001", 750.00 )
   _SeedCheque( "TSTCHQ002", "TSTBAN002", "TSTPRO002", 430.00 )

   _SeedAjuste( "TSTAJU001", "TSTART001", 10, 300.00 )
   _SeedAjuste( "TSTAJU002", "TSTART002",  5, 110.00 )

RETURN NIL


STATIC FUNCTION _SeedSeguridad()

   _Upsert( "ROLES", "ROL_TST", "ROLID", "TST", {|| ;
      ROL_TST->ID := "TST", ROL_TST->DESCRIP := "Rol test", ;
      ROL_TST->NIVEL := 1, ROL_TST->BAJA := .F. } )
   _Upsert( "ROLES", "ROL_TST", "ROLID", "AUD", {|| ;
      ROL_TST->ID := "AUD", ROL_TST->DESCRIP := "Auditor test", ;
      ROL_TST->NIVEL := 2, ROL_TST->BAJA := .F. } )

   _Upsert( "USUARIOS", "USR_TST", "USR_COD", "TSTUSER1", {|| ;
      USR_TST->CODIGO := "TSTUSER1", USR_TST->NOMBRE := "Usuario Test 1", ;
      USR_TST->ROLID := "TST", USR_TST->NIVEL := 1, USR_TST->FECHA_AL := Date(), ;
      USR_TST->SALT := "TSTUSER1SEED0001", ;
      USR_TST->CLAVE_H := UserPasswordHash( "123456", "TSTUSER1SEED0001" ), ;
      USR_TST->BAJA := .F., USR_TST->CAMB_CL := .T. } )
   _Upsert( "USUARIOS", "USR_TST", "USR_COD", "TSTUSER2", {|| ;
      USR_TST->CODIGO := "TSTUSER2", USR_TST->NOMBRE := "Usuario Test 2", ;
      USR_TST->ROLID := "AUD", USR_TST->NIVEL := 2, USR_TST->FECHA_AL := Date(), ;
      USR_TST->SALT := "TSTUSER2SEED0002", ;
      USR_TST->CLAVE_H := UserPasswordHash( "123456", "TSTUSER2SEED0002" ), ;
      USR_TST->BAJA := .F., USR_TST->CAMB_CL := .T. } )

RETURN NIL


STATIC FUNCTION _SeedCliente( cId, cNif, cNom, cApe, cFP, nDias, lIrpf )

   _Upsert( "CLIENTES", "CLI_TST", "CLI_ID", cId, {|| ;
      CLI_TST->ID := cId, CLI_TST->NIF := cNif, CLI_TST->NOMBRE := cNom, ;
      CLI_TST->APELLIDO := cApe, CLI_TST->DIRECCIO := "Direccion " + cId, ;
      CLI_TST->CIUDAD := "Barcelona", CLI_TST->PROVINCI := "Barcelona", ;
      CLI_TST->PAIS := "Espana", CLI_TST->CP := "08001", ;
      CLI_TST->TELEFONO := "600" + Right( cId, 6 ), CLI_TST->MOVIL := "610" + Right( cId, 6 ), ;
      CLI_TST->EMAIL := Lower( cId ) + "@test.local", CLI_TST->FECHA_AL := Date(), ;
      CLI_TST->DIAS_PAG := nDias, CLI_TST->FORPAGO := cFP, ;
      CLI_TST->LIMITE_C := 30000, CLI_TST->TARIFA := 1, CLI_TST->DESC_COM := 0, ;
      CLI_TST->APL_RE := .F., CLI_TST->APL_IRPF := lIrpf, CLI_TST->TIP_CLI := "N", ;
      CLI_TST->LOPD_OK := .T., CLI_TST->ENV_MAIL := .T., ;
      CLI_TST->CTA_CONT := "430", CLI_TST->CTA_ANTI := "438", CLI_TST->BAJA := .F. } )

RETURN NIL


STATIC FUNCTION _SeedProveedor( cId, cNif, cNom, cApe )

   _Upsert( "PROVEED", "PRV_TST", "PRV_ID", cId, {|| ;
      PRV_TST->ID := cId, PRV_TST->NIF := cNif, PRV_TST->NOMBRE := cNom, ;
      PRV_TST->APELLIDO := cApe, PRV_TST->DIRECCIO := "Direccion " + cId, ;
      PRV_TST->CIUDAD := "Madrid", PRV_TST->PROVINCI := "Madrid", ;
      PRV_TST->PAIS := "Espana", PRV_TST->CP := "28001", ;
      PRV_TST->TELEFONO := "910" + Right( cId, 6 ), ;
      PRV_TST->EMAIL := Lower( cId ) + "@proveedor.local", ;
      PRV_TST->FECHA_AL := Date(), PRV_TST->DIAS_PAG := 30, PRV_TST->FORPAGO := "T30", ;
      PRV_TST->CTA_CONT := "400", PRV_TST->CTA_ANTI := "407", PRV_TST->BAJA := .F. } )

RETURN NIL


STATIC FUNCTION _SeedArticulo( cCod, cDesc, cFam, cProv, nCosto, nPrecio, nIva )

   _Upsert( "ARTICULOS", "ART_TST", "ART_COD", cCod, {|| ;
      ART_TST->CODIGO := cCod, ART_TST->DESCRIP := cDesc, ART_TST->FAMILIA := cFam, ;
      ART_TST->PROVEEDO := cProv, ART_TST->COD_BARR := cCod, ART_TST->QR_DATA := cCod, ;
      ART_TST->STOCK := 25, ART_TST->STO_MIN := 2, ART_TST->STO_MAX := 100, ;
      ART_TST->UNIDAD := "UD", ART_TST->ES_SERV := ( cFam == "T02" ), ;
      ART_TST->CTA_VTA := "700", ART_TST->CTA_COM := "600", ;
      ART_TST->COSTO_PR := nCosto, ART_TST->PRECIO := nPrecio, ;
      ART_TST->IVA := nIva, ART_TST->TIPO_IVA := "T", ART_TST->DESCUENT := 0, ;
      ART_TST->FECHA_AL := Date(), ART_TST->BAJA := .F. } )

RETURN NIL


STATIC FUNCTION _SeedCuenta( cCuenta, cNombre, cTipo )

   _Upsert( "CATALOGO", "CAT_TST", "CAT_CTA", cCuenta, {|| ;
      CAT_TST->CUENTA := cCuenta, CAT_TST->NOMBRE := cNombre, ;
      CAT_TST->NIVEL := 9, CAT_TST->TIPO := cTipo, CAT_TST->NATURALE := "D", ;
      CAT_TST->SUMA_EN := "", CAT_TST->SALDO_AN := 0, CAT_TST->DEBE_ANU := 0, ;
      CAT_TST->HABER_AN := 0, CAT_TST->SALDO_AC := 0, CAT_TST->PRESUPUE := 0, ;
      CAT_TST->BLOQUEAD := .F., CAT_TST->REQ_ANAL := .F., CAT_TST->ES_BANCO := .F., ;
      CAT_TST->BAJA := .F. } )

RETURN NIL


STATIC FUNCTION _SeedAsiento( cAsi, dFec, cCuenta, nDebe, nHaber, cDesc )

   _Upsert( "LDIARIO", "DIA_TST", "DIA_ASI", cAsi + Str( 1, 4 ), {|| ;
      DIA_TST->D_ASIENT := cAsi, DIA_TST->D_LINEA := 1, DIA_TST->D_FECHA := dFec, ;
      DIA_TST->D_CUENTA := cCuenta, DIA_TST->D_DEBE := nDebe, DIA_TST->D_HABER := nHaber, ;
      DIA_TST->D_DESCRI := cDesc, DIA_TST->USUARIO_ := "SEED", DIA_TST->FECHA_AL := Date(), ;
      DIA_TST->TIP_ORIG := "TST", DIA_TST->DOC_ORIG := cAsi } )

RETURN NIL


STATIC FUNCTION _SeedPresupuesto( cNum, cCli, cObra, cEstado, nTotal, cDesc )

   LOCAL nBase := Round( nTotal / 1.21, 2 )
   LOCAL nIva  := Round( nTotal - nBase, 2 )

   _Upsert( "PRESUPUEST", "PRE_TST", "PRE_NUM", cNum, {|| ;
      PRE_TST->NUMERO := cNum, PRE_TST->FECHA := Date() - 20, PRE_TST->VALIDEZ := Date() + 10, ;
      PRE_TST->CLIENTE_ := cCli, PRE_TST->VENDEDOR := "TSTVEN001", ;
      PRE_TST->SUBTOTAL := nBase, PRE_TST->IVA := nIva, PRE_TST->TOTAL := nTotal, ;
      PRE_TST->ESTADO := cEstado, PRE_TST->OBSERVA := cDesc, ;
      PRE_TST->PIE_DOC := "Condiciones test", PRE_TST->NUM_FAC := "", ;
      PRE_TST->ID_OBRA := cObra, PRE_TST->TIPO := "C", PRE_TST->RETENCIO := 0, ;
      PRE_TST->PORC_RET := 0 } )

   _SeedLinea( "PRESUP_DE", "PRD_TST", "PRD_LIN", cNum, 1, cDesc + " fase 1", 1, nBase * 0.60, 21 )
   _SeedLinea( "PRESUP_DE", "PRD_TST", "PRD_LIN", cNum, 2, cDesc + " fase 2", 1, nBase * 0.40, 21 )

RETURN NIL


STATIC FUNCTION _SeedObra( cId, cPre, cCli, cDesc, nTotal, cEstado )

   _Upsert( "OBRAS", "OBR_TST", "OBR_ID", cId, {|| ;
      OBR_TST->ID := cId, OBR_TST->NUM_PRE := cPre, OBR_TST->CLIENTE_ := cCli, ;
      OBR_TST->DESCRIP := cDesc, OBR_TST->DIRECC_OB := "Direccion obra " + cId, ;
      OBR_TST->FECHA_IN := Date() - 15, OBR_TST->FECHA_FIN := CToD( "" ), ;
      OBR_TST->TOTAL := nTotal, OBR_TST->ESTADO := cEstado, ;
      OBR_TST->USUARIO_ := "SEED", OBR_TST->FECHA_AL := Date(), ;
      OBR_TST->OBSERVA := "Obra de prueba inyectada" } )

RETURN NIL


STATIC FUNCTION _SeedFactura( cNum, cCli, cObra, cPre, cTipo, nTotal, lCobrada )

   LOCAL nBase := Round( nTotal / 1.21, 2 )
   LOCAL nIva  := Round( nTotal - nBase, 2 )

   _Upsert( "FACTURA", "FAC_TST", "FAC_NUM", PadR( "A", 4 ) + PadR( cNum, 10 ), {|| ;
      FAC_TST->SERIE := "A", FAC_TST->NUMERO := cNum, FAC_TST->CLIENTE_ := cCli, ;
      FAC_TST->VENDEDOR := "TSTVEN001", FAC_TST->FECHA := Date() - 7, ;
      FAC_TST->FECHA_OP := Date(), FAC_TST->HORA := Time(), ;
      FAC_TST->SUBTOTAL := nBase, FAC_TST->IVA := nIva, FAC_TST->RE_EQUIP := 0, ;
      FAC_TST->RETENCIO := 0, FAC_TST->PORC_RET := 0, FAC_TST->TOTAL := nTotal, ;
      FAC_TST->FORMA_PA := "T30", FAC_TST->FECHA_VT := Date() + 30, ;
      FAC_TST->ASIENTO := "", FAC_TST->COBRADA := lCobrada, ;
      FAC_TST->COBRADO := If( lCobrada, nTotal, 0 ), FAC_TST->ANULADA := .F., ;
      FAC_TST->TIPO_DOC := "F", FAC_TST->OBSERVA := "Factura test", ;
      FAC_TST->PIE_DOC := "Pie factura test", FAC_TST->NUM_PRE := cPre, ;
      FAC_TST->ID_OBRA := cObra, FAC_TST->TIPO_FAC := cTipo, FAC_TST->NUM_ABONO := "" } )

   _SeedFacLinea( cNum, 1, "Factura test " + cNum, nBase, 21 )

RETURN NIL


STATIC FUNCTION _SeedFacLinea( cNum, nLin, cDesc, nBase, nIva )

   _Upsert( "FACTUR_DE", "FD_TST", "FAC_LIN", PadR( "A", 4 ) + PadR( cNum, 10 ) + Str( nLin, 3 ), {|| ;
      FD_TST->SERIE := "A", FD_TST->NUMERO := cNum, FD_TST->LINEA := nLin, ;
      FD_TST->ARTICULO := "", FD_TST->DESCRIPC := cDesc, FD_TST->CANTIDAD := 1, ;
      FD_TST->PRECIO := nBase, FD_TST->DESCUENT := 0, FD_TST->IMPORTE := nBase, ;
      FD_TST->COSTO := 0, FD_TST->CTA_CONT := "700", FD_TST->TIP_IVA := "T", ;
      FD_TST->PORC_IVA := nIva } )

RETURN NIL


STATIC FUNCTION _SeedLinea( cTabla, cAlias, cIndex, cNum, nLin, cDesc, nCant, nPrecio, nIva )

   _Upsert( cTabla, cAlias, cIndex, cNum + Str( nLin, 3 ), {|| ;
      _Put( "NUMERO", cNum ), _Put( "LINEA", nLin ), ;
      _Put( "ARTICULO", "" ), _Put( "DESCRIPC", cDesc ), ;
      _Put( "CANTIDAD", nCant ), _Put( "PRECIO", nPrecio ), ;
      _Put( "DESCUENT", 0 ), _Put( "IMPORTE", nCant * nPrecio ), ;
      _Put( "PORC_IVA", nIva ) } )

RETURN NIL


STATIC FUNCTION _Put( cField, xValue )

   LOCAL nPos := FieldPos( cField )

   IF nPos > 0
      FieldPut( nPos, xValue )
   ENDIF

RETURN NIL


STATIC FUNCTION _SeedNota( cNum, cFac, cCli, nTotal )

   LOCAL nBase := Round( nTotal / 1.21, 2 )
   LOCAL nIva  := Round( nTotal - nBase, 2 )

   _Upsert( "NOTASDC", "NDC_TST", "NDC_NUM", PadR( "NA", 4 ) + PadR( cNum, 10 ), {|| ;
      NDC_TST->NUMERO := cNum, NDC_TST->SERIE := "NA", NDC_TST->TIPO := "C", ;
      NDC_TST->CLIENTE_ := cCli, NDC_TST->FECHA := Date() - 2, NDC_TST->FECHA_OP := Date(), ;
      NDC_TST->REF_DOC := cFac, NDC_TST->MOTIVO := "Abono test", ;
      NDC_TST->SUBTOTAL := nBase, NDC_TST->IVA := nIva, NDC_TST->RETENCIO := 0, ;
      NDC_TST->TOTAL := nTotal, NDC_TST->ASIENTO := "", NDC_TST->ESTADO := "E", ;
      NDC_TST->OBSERVA := "Nota credito test" } )

   _Upsert( "NOTASD_DE", "NDD_TST", "NDC_LIN", cNum + Str( 1, 3 ), {|| ;
      NDD_TST->NUMERO := cNum, NDD_TST->LINEA := 1, NDD_TST->ARTICULO := "", ;
      NDD_TST->DESCRIPC := "Abono parcial test", NDD_TST->CANTIDAD := 1, ;
      NDD_TST->PRECIO := nBase, NDD_TST->DESCUENT := 0, NDD_TST->IMPORTE := -nBase, ;
      NDD_TST->PORC_IVA := 21, NDD_TST->IMP_IVA := -nIva, ;
      NDD_TST->CTA_CONT := "700", NDD_TST->CCOSTE := "", NDD_TST->REF_LIN := 1, ;
      NDD_TST->OBSERVA := "Linea abono test" } )

RETURN NIL


STATIC FUNCTION _SeedPedido( cNum, cCli, nTotal )

   LOCAL nBase := Round( nTotal / 1.21, 2 )
   LOCAL nIva  := Round( nTotal - nBase, 2 )

   _Upsert( "PEDIDOS", "PED_TST", "PED_NUM", cNum, {|| ;
      PED_TST->NUMERO := cNum, PED_TST->FECHA := Date(), PED_TST->CLIENTE_ := cCli, ;
      PED_TST->VENDEDOR := "TSTVEN001", PED_TST->SUBTOTAL := nBase, ;
      PED_TST->IVA := nIva, PED_TST->TOTAL := nTotal, PED_TST->ESTADO := "P", ;
      PED_TST->ALMACEN := "001", PED_TST->OBSERVA := "Pedido test" } )

   _SeedLinea( "PED_DET", "PDD_TST", "PED_LIN", cNum, 1, "Linea pedido test", 1, nBase, 21 )

RETURN NIL


STATIC FUNCTION _SeedCompra( cNum, cProv, nTotal )

   LOCAL nBase := Round( nTotal / 1.21, 2 )
   LOCAL nIva  := Round( nTotal - nBase, 2 )

   _Upsert( "COMPRAS", "COM_TST", "COM_INT", cNum, {|| ;
      COM_TST->NUM_INTE := cNum, COM_TST->NUM_PROV := "PROV-" + cNum, ;
      COM_TST->PROV_ID := cProv, COM_TST->FECHA := Date() - 3, COM_TST->FECHA_RE := Date(), ;
      COM_TST->SUBTOTAL := nBase, COM_TST->IVA := nIva, COM_TST->TOTAL := nTotal, ;
      COM_TST->FECHA_VT := Date() + 30, COM_TST->ASIENTO := "", ;
      COM_TST->PAGADA := .F., COM_TST->METODO_P := "T30" } )

   _Upsert( "COMP_DET", "CPD_TST", "CPD_LIN", cNum + Str( 1, 3 ), {|| ;
      CPD_TST->NUMERO := cNum, CPD_TST->LINEA := 1, CPD_TST->ARTICULO := "TSTART001", ;
      CPD_TST->DESCRIPC := "Compra test", CPD_TST->CANTIDAD := 1, ;
      CPD_TST->COSTO_UN := nBase, CPD_TST->IMPORTE := nBase, ;
      CPD_TST->TIP_IVA := "T", CPD_TST->PORC_IVA := 21 } )

RETURN NIL


STATIC FUNCTION _SeedRecibo( cNum, cCli, cFac, nImporte )

   _Upsert( "RECIBOS", "REC_TST", "REC_NUM", cNum, {|| ;
      REC_TST->NUMERO := cNum, REC_TST->FECHA := Date(), REC_TST->CLIENTE_ := cCli, ;
      REC_TST->CONCEPTO := "Cobro test " + cFac, REC_TST->FORMA_PA := "T01", ;
      REC_TST->TOTAL := nImporte, REC_TST->ASIENTO := "", REC_TST->USUARIO_ := "SEED" } )

   _Upsert( "RC_DETAL", "RCD_TST", "RCD_NUM", cNum + Str( 1, 3 ), {|| ;
      RCD_TST->NUMERO := cNum, RCD_TST->LINEA := 1, RCD_TST->NUM_FAC := cFac, ;
      RCD_TST->IMPORTE := nImporte } )

RETURN NIL


STATIC FUNCTION _SeedVencimiento( cNumFac, cSerie, cCli, cObra, nImporte, lCobrado )

   _Upsert( "VENCIMIEN", "VEN_TST", "VEN_NUM", "C" + PadR( cNumFac, 10 ), {|| ;
      VEN_TST->EJERCICIO := Year( Date() ), VEN_TST->TIPO := "C", ;
      VEN_TST->NUMERO := cNumFac, VEN_TST->SERIE := cSerie, VEN_TST->VENCTO := Date() + 30, ;
      VEN_TST->IMPORTE := nImporte, VEN_TST->COBRADO := lCobrado, ;
      VEN_TST->CODTERCE := cCli, VEN_TST->NOMBRE := "Cliente vencimiento test", ;
      VEN_TST->ID_OBRA := cObra } )

RETURN NIL


STATIC FUNCTION _SeedCheque( cNum, cBanco, cProv, nMonto )

   _Upsert( "CHEQUES", "CHQ_TST", "CHQ_NUM", cNum, {|| ;
      CHQ_TST->NUMERO := cNum, CHQ_TST->FECHA_EM := Date(), CHQ_TST->FECHA_VT := Date() + 15, ;
      CHQ_TST->BANCO := cBanco, CHQ_TST->BENEFICIA := "Beneficiario " + cProv, ;
      CHQ_TST->PROV_ID := cProv, CHQ_TST->CONCEPTO := "Cheque test", ;
      CHQ_TST->MONTO := nMonto, CHQ_TST->ESTADO := "P", CHQ_TST->ASIENTO := "" } )

   _Upsert( "CHEQUE_DE", "CHD_TST", "CHD_LIN", cNum + Str( 1, 3 ), {|| ;
      CHD_TST->NUMERO := cNum, CHD_TST->LINEA := 1, CHD_TST->REF_DOC := cProv, ;
      CHD_TST->CONCEPTO := "Detalle cheque test", CHD_TST->IMPORTE := nMonto, ;
      CHD_TST->CTA_CONT := "400" } )

RETURN NIL


STATIC FUNCTION _SeedAjuste( cNum, cArt, nCant, nCosto )

   _Upsert( "AJUSTEIN", "AJU_TST", "AJU_NUM", cNum, {|| ;
      AJU_TST->NUMERO := cNum, AJU_TST->FECHA := Date(), AJU_TST->USUARIO_ := "SEED", ;
      AJU_TST->TIP_AJUS := "E", AJU_TST->ARTICULO := cArt, ;
      AJU_TST->CANTIDAD := nCant, AJU_TST->COSTO_TO := nCosto } )

RETURN NIL


STATIC FUNCTION _Upsert( cTabla, cAlias, cIndex, cKey, bFill )

   LOCAL lFound

   IF !ABRIR_TABLA( cTabla, cAlias, cIndex )
      _SeedLog( "No se pudo abrir " + cTabla )
      RETURN .F.
   ENDIF

   DbSelectArea( cAlias )
   IF !Empty( cIndex )
      OrdSetFocus( cIndex )
   ENDIF

   lFound := DbSeek( cKey )

   IF lFound
      IF !NetRLock()
         _SeedLog( "No se pudo bloquear registro " + cTabla + " " + cKey )
         (cAlias)->( DbCloseArea() )
         RETURN .F.
      ENDIF
   ELSE
      IF !NetFLock()
         _SeedLog( "No se pudo bloquear tabla " + cTabla + " " + cKey )
         (cAlias)->( DbCloseArea() )
         RETURN .F.
      ENDIF
      DbAppend()
   ENDIF

   Eval( bFill )
   DbCommit()
   DbUnlock()
   _SeedLog( If( lFound, "Actualizado ", "Creado " ) + cTabla + " " + cKey )
   (cAlias)->( DbCloseArea() )

RETURN .T.
