REQUEST DBFCDX
FUNCTION Main()
    LOCAL aT := {"ARTICULO","ARTICULOS"}, i, nJ
    rddSetDefault("DBFCDX")
    FOR i:=1 TO Len(aT)
        DbUseArea(.T.,"DBFCDX","DATA\"+aT[i],aT[i],.T.,.F.)
        IF !NetErr()
            ? aT[i] + ": " + AllTrim(Str(FCount())) + " campos"
            FOR nJ:=1 TO FCount()
                ?? "  " + PadR(FieldName(nJ),10) + FieldType(nJ)+AllTrim(Str(FieldLen(nJ)))
            NEXT
            ?
            (aT[i])->(DbCloseArea())
        ENDIF
    NEXT
RETURN NIL
