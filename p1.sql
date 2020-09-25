CREATE OR REPLACE TRIGGER valida_medico_efetivo
BEFORE INSERT OR UPDATE ON MEDICO_EFETIVO
FOR EACH ROW
DECLARE
crm  medico.crm%TYPE;
contrato  medico.TIPO_CONTRATO%TYPE;
BEGIN
     SELECT TIPO_CONTRATO into contrato
        FROM MEDICO
        where CRM = :NEW.CRM_EFETIVO;
IF contrato is null THEN
    RAISE_APPLICATION_ERROR ( -20001, 'Médico não encontrado');
ELSIF  LOWER(contrato) = 'residente' THEN
    RAISE_APPLICATION_ERROR ( -20002, 'Médico ainda residente');
END IF;
END;

CREATE OR REPLACE TRIGGER valida_medico_residente
BEFORE INSERT OR UPDATE ON MEDICO_RESIDENTE 
FOR EACH ROW
DECLARE
crm  medico.crm%TYPE;
contrato  medico.TIPO_CONTRATO%TYPE;
BEGIN
     SELECT TIPO_CONTRATO into contrato
        FROM MEDICO 
        where CRM = :NEW.CRM_RESIDENTE;
IF contrato is null THEN
    RAISE_APPLICATION_ERROR ( -20001, 'Médico não encontrado');
ELSIF  LOWER(contrato) = 'residente' THEN
    RAISE_APPLICATION_ERROR ( -20002, 'Médico não ');
END IF;
END;
