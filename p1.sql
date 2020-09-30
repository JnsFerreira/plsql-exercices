/*1-Implemente um controle para validar as inclusões/atualizações nas tabelas de Médico Efetivo e Residente 
baseado no tipo de contrato (tabela Médico)*/

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


/*2- Implemente um controle que evite que um paciente seja internado em um leito-quarto que ainda esteja ocupado.*/

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

CREATE OR REPLACE TRIGGER valida_internacao_quarto
BEFORE INSERT OR UPDATE ON INTERNACAO
FOR EACH ROW
DECLARE
status INTERNACAO.SITUACAO_INTERNACAO%TYPE;
BEGIN
   select SITUACAO_INTERNACAO into status
        FROM INTERNACAO
        WHERE NUM_LEITO = :NEW.NUM_LEITO AND NUM_QTO = :NEW.NUM_QTO;
  
IF status is NOT null AND UPPER(status) = 'ATIVA' THEN
    RAISE_APPLICATION_ERROR ( -20005, 'LEITO - QUARTO OCUPADO');
END IF;
END;


/*3- Implemente um controle para registrar em log as aplicações de medicamento (dar o remédio).*/



/*4- Implemente uma função que retorne a quantidade de pacientes internados atualmente para um determinado 
motivo de internação, por exemplo, Crise Renal ou Infarto, etc., passando como parâmetro parte do motivo de 
internação. Faça os tratamentos necessário*/

CREATE OR REPLACE TYPE resultado
AS OBJECT
(
   motivo VARCHAR(6),
   contagem NUMBER
);


CREATE OR REPLACE FUNCTION count_patients (reason IN VARCHAR2)
RETURN resultado
IS res resultado:=;
BEGIN

SELECT  i.MOTIVO, COUNT(DISTINCT i.NUM_INTERNACAO) INTO res.motivo, res.contagem
FROM internacao i 
WHERE UPPER(i.MOTIVO) LIKE ('%'||UPPER(reason)||'%') AND
i.SITUACAO_INTERNACAO = 'ATIVA'
GROUP BY i.MOTIVO;

RETURN res;

EXCEPTION
	WHEN NO_DATA_FOUND THEN 
	RAISE_APPLICATION_ERROR (-20400,'Não foram encontrados pacientes com este motivo de internação');
END;
