FUNCTION SigNum( cTipo )
    LOCAL nSig := 0
    
    SELECT Correlat
    LOCATE FOR TIPO_DOC == cTipo
    
    IF Found()
        IF RLock()
            nSig := ULT_NUM + 1
            REPLACE ULT_NUM WITH nSig
            Unlock
        ENDIF
    ENDIF
    
RETURN nSig