/*
 * ARCHIVO  : M_Empresa.prg
 * PROPOSITO: Mantenimiento de los datos de la empresa.
 */

#include "OOp.ch"

FUNCTION Empresa()

    LOCAL oWin
    LOCAL nArea
    LOCAL cNif
    LOCAL cNombre
    LOCAL cDirecc
    LOCAL cCiudad
    LOCAL cProvin
    LOCAL cCP
    LOCAL cPais
    LOCAL cTelef
    LOCAL cMovil
    LOCAL cEmail
    LOCAL cWeb
    LOCAL cIban
    LOCAL cPrefijo
    LOCAL cTomo
    LOCAL cFolio
    LOCAL cHoja
    LOCAL cSeccion
    LOCAL lNuevo
    LOCAL oGNif
    LOCAL oGNom
    LOCAL oGDir
    LOCAL oGCiu
    LOCAL oGPro
    LOCAL oGCP
    LOCAL oGPais
    LOCAL oGTel
    LOCAL oGMov
    LOCAL oGMail
    LOCAL oGWeb
    LOCAL oGIban
    LOCAL oGPref
    LOCAL oGTomo
    LOCAL oGFol
    LOCAL oGHoja
    LOCAL oGSec
    LOCAL oBtGua
    LOCAL oBtCan

    nArea    := Select()
    cNif     := Space( 13 )
    cNombre  := Space( 60 )
    cDirecc  := Space( 60 )
    cCiudad  := Space( 40 )
    cProvin  := Space( 30 )
    cCP      := Space(  5 )
    cPais    := Space( 30 )
    cTelef   := Space( 15 )
    cMovil   := Space( 15 )
    cEmail   := Space( 50 )
    cWeb     := Space( 50 )
    cIban    := Space( 34 )
    cPrefijo := Space(  3 )
    cTomo    := Space( 10 )
    cFolio   := Space( 10 )
    cHoja    := Space( 15 )
    cSeccion := Space( 10 )
    lNuevo   := .F.

    IF !ABRIR_TABLA( "EMPRESA", "EMP", "" )
        RETURN NIL
    ENDIF

    DbSelectArea( "EMP" )
    DbGoTop()

    IF !Eof() .AND. !Deleted()
        cNif     := PadR( AllTrim( EMP->NIF      ), 13 )
        cNombre  := PadR( AllTrim( EMP->NOMBRE   ), 60 )
        cDirecc  := PadR( AllTrim( EMP->DIRECCIO ), 60 )
        cCiudad  := PadR( AllTrim( EMP->CIUDAD   ), 40 )
        cProvin  := PadR( AllTrim( EMP->PROVINCI ), 30 )
        cCP      := PadR( AllTrim( EMP->CP       ),  5 )
        cPais    := PadR( AllTrim( EMP->PAIS     ), 30 )
        cTelef   := PadR( AllTrim( EMP->TELEFONO ), 15 )
        cMovil   := PadR( AllTrim( EMP->MOVIL    ), 15 )
        cEmail   := PadR( AllTrim( EMP->EMAIL    ), 50 )
        cWeb     := PadR( AllTrim( EMP->WEB      ), 50 )
        cIban    := PadR( AllTrim( EMP->IBANPPAL ), 34 )
        cPrefijo := PadR( AllTrim( EMP->PREFIJO  ),  3 )
        cTomo    := PadR( AllTrim( EMP->REG_TOMO ), 10 )
        cFolio   := PadR( AllTrim( EMP->REG_FOL  ), 10 )
        cHoja    := PadR( AllTrim( EMP->REG_HOJA ), 15 )
        cSeccion := PadR( AllTrim( EMP->REG_SECC ), 10 )
    ELSE
        lNuevo := .T.
    ENDIF

    oWin := TWindow():New( 1, 5, 38, 125, "DATOS DE LA EMPRESA" )

    oWin:AddCtrl( TLabel():New(  2,  2, "NIF / CIF        :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4,  2, "Razon Social     :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6,  2, "Direccion        :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8,  2, "Ciudad           :", oWin ) )
    oWin:AddCtrl( TLabel():New( 10,  2, "Provincia        :", oWin ) )
    oWin:AddCtrl( TLabel():New( 12,  2, "C.P.             :", oWin ) )
    oWin:AddCtrl( TLabel():New( 14,  2, "Pais             :", oWin ) )
    oWin:AddCtrl( TLabel():New( 16,  2, "Telefono         :", oWin ) )
    oWin:AddCtrl( TLabel():New( 18,  2, "Movil            :", oWin ) )
    oWin:AddCtrl( TLabel():New( 20,  2, "Email            :", oWin ) )
    oWin:AddCtrl( TLabel():New( 22,  2, "Web              :", oWin ) )
    oWin:AddCtrl( TLabel():New( 24,  2, "IBAN Principal   :", oWin ) )
    oWin:AddCtrl( TLabel():New( 26,  2, "Prefijo docs     :", oWin ) )

    oWin:AddCtrl( TLabel():New(  2, 84, "Tomo   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  4, 84, "Folio  :", oWin ) )
    oWin:AddCtrl( TLabel():New(  6, 84, "Hoja   :", oWin ) )
    oWin:AddCtrl( TLabel():New(  8, 84, "Seccion:", oWin ) )

    oGNif  := TGet():New(  2, 21, cNif,    "@!",    oWin )
    oGNif:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGNom  := TGet():New(  4, 21, cNombre, "@!",    oWin )
    oGNom:bValid := {| o | !Empty( AllTrim( o:cBuffer ) ) }

    oGDir  := TGet():New(  6, 21, cDirecc,  "@!",    oWin )
    oGCiu  := TGet():New(  8, 21, cCiudad,  "@!",    oWin )
    oGPro  := TGet():New( 10, 21, cProvin,  "@!",    oWin )
    oGCP   := TGet():New( 12, 21, cCP,      "99999", oWin )
    oGPais := TGet():New( 14, 21, cPais,    "@!",    oWin )
    oGTel  := TGet():New( 16, 21, cTelef,   "@!",    oWin )
    oGMov  := TGet():New( 18, 21, cMovil,   "@!",    oWin )
    oGMail := TGet():New( 20, 21, cEmail,   "@!",    oWin )
    oGWeb  := TGet():New( 22, 21, cWeb,     "@!",    oWin )
    oGIban := TGet():New( 24, 21, cIban,    "@!",    oWin )
    oGPref := TGet():New( 26, 21, cPrefijo, "@!",    oWin )

    oGTomo := TGet():New(  2, 93, cTomo,    "@!", oWin )
    oGFol  := TGet():New(  4, 93, cFolio,   "@!", oWin )
    oGHoja := TGet():New(  6, 93, cHoja,    "@!", oWin )
    oGSec  := TGet():New(  8, 93, cSeccion, "@!", oWin )

    oBtGua := TButton():New( 30, 35, 31, 54, oWin, "GUARDAR", ;
        {|| If( EmpresaGuardar( _EmpFormHash( oGNif, oGNom, oGDir, oGCiu, oGPro, ;
                                              oGCP,  oGPais, oGTel, oGMov, oGMail, ;
                                              oGWeb, oGIban, oGPref, ;
                                              oGTomo, oGFol, oGHoja, oGSec ), ;
                                lNuevo ), ;
                 oWin:Close(), NIL ) } )

    oBtCan := TButton():New( 30, 58, 31, 77, oWin, "CANCELAR", ;
        {|| oWin:Close() } )

    oWin:AddCtrl( oGNif  )
    oWin:AddCtrl( oGNom  )
    oWin:AddCtrl( oGDir  )
    oWin:AddCtrl( oGCiu  )
    oWin:AddCtrl( oGPro  )
    oWin:AddCtrl( oGCP   )
    oWin:AddCtrl( oGPais )
    oWin:AddCtrl( oGTel  )
    oWin:AddCtrl( oGMov  )
    oWin:AddCtrl( oGMail )
    oWin:AddCtrl( oGWeb  )
    oWin:AddCtrl( oGIban )
    oWin:AddCtrl( oGPref )
    oWin:AddCtrl( oGTomo )
    oWin:AddCtrl( oGFol  )
    oWin:AddCtrl( oGHoja )
    oWin:AddCtrl( oGSec  )
    oWin:AddCtrl( oBtGua )
    oWin:AddCtrl( oBtCan )

    oWin:Run()

    EMP->( DbCloseArea() )
    Select( nArea )

RETURN NIL


STATIC FUNCTION _EmpFormHash( oGNif, oGNom, oGDir, oGCiu, oGPro, ;
                               oGCP,  oGPais, oGTel, oGMov, oGMail, ;
                               oGWeb, oGIban, oGPref, ;
                               oGTomo, oGFol, oGHoja, oGSec )

    LOCAL hEmpresa := {=>}

    hEmpresa[ "NIF"      ] := AllTrim( oGNif:GetValue() )
    hEmpresa[ "NOMBRE"   ] := AllTrim( oGNom:GetValue() )
    hEmpresa[ "DIRECCIO" ] := AllTrim( oGDir:GetValue() )
    hEmpresa[ "CIUDAD"   ] := AllTrim( oGCiu:GetValue() )
    hEmpresa[ "PROVINCI" ] := AllTrim( oGPro:GetValue() )
    hEmpresa[ "CP"       ] := AllTrim( oGCP:GetValue() )
    hEmpresa[ "PAIS"     ] := AllTrim( oGPais:GetValue() )
    hEmpresa[ "TELEFONO" ] := AllTrim( oGTel:GetValue() )
    hEmpresa[ "MOVIL"    ] := AllTrim( oGMov:GetValue() )
    hEmpresa[ "EMAIL"    ] := AllTrim( oGMail:GetValue() )
    hEmpresa[ "WEB"      ] := AllTrim( oGWeb:GetValue() )
    hEmpresa[ "IBANPPAL" ] := AllTrim( oGIban:GetValue() )
    hEmpresa[ "PREFIJO"  ] := AllTrim( oGPref:GetValue() )
    hEmpresa[ "REG_TOMO" ] := AllTrim( oGTomo:GetValue() )
    hEmpresa[ "REG_FOL"  ] := AllTrim( oGFol:GetValue() )
    hEmpresa[ "REG_HOJA" ] := AllTrim( oGHoja:GetValue() )
    hEmpresa[ "REG_SECC" ] := AllTrim( oGSec:GetValue() )

RETURN hEmpresa


FUNCTION EmpresaGuardar( hEmpresa, lNuevo )

    DEFAULT lNuevo TO .F.

    DbSelectArea( "EMP" )

    IF lNuevo
        IF !NetFLock()
            RETURN .F.
        ENDIF
        DbAppend()
    ELSE
        DbGoTop()
        IF !NetRLock()
            RETURN .F.
        ENDIF
    ENDIF

    REPLACE EMP->NIF      WITH hEmpresa[ "NIF"      ]
    REPLACE EMP->NOMBRE   WITH hEmpresa[ "NOMBRE"   ]
    REPLACE EMP->DIRECCIO WITH hEmpresa[ "DIRECCIO" ]
    REPLACE EMP->CIUDAD   WITH hEmpresa[ "CIUDAD"   ]
    REPLACE EMP->PROVINCI WITH hEmpresa[ "PROVINCI" ]
    REPLACE EMP->CP       WITH hEmpresa[ "CP"       ]
    REPLACE EMP->PAIS     WITH hEmpresa[ "PAIS"     ]
    REPLACE EMP->TELEFONO WITH hEmpresa[ "TELEFONO" ]
    REPLACE EMP->MOVIL    WITH hEmpresa[ "MOVIL"    ]
    REPLACE EMP->EMAIL    WITH hEmpresa[ "EMAIL"    ]
    REPLACE EMP->WEB      WITH hEmpresa[ "WEB"      ]
    REPLACE EMP->IBANPPAL WITH hEmpresa[ "IBANPPAL" ]
    REPLACE EMP->PREFIJO  WITH hEmpresa[ "PREFIJO"  ]
    REPLACE EMP->REG_TOMO WITH hEmpresa[ "REG_TOMO" ]
    REPLACE EMP->REG_FOL  WITH hEmpresa[ "REG_FOL"  ]
    REPLACE EMP->REG_HOJA WITH hEmpresa[ "REG_HOJA" ]
    REPLACE EMP->REG_SECC WITH hEmpresa[ "REG_SECC" ]

    DbCommit()
    DbUnlock()

    MsgInfo( "Datos de empresa guardados correctamente.", "Empresa" )

RETURN .T.

// ============================================================================
// FIN DE M_Empresa.prg
// ============================================================================
