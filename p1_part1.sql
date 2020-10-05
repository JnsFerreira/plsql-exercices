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
drop table remedio_aplicacao_log;
create table remedio_aplicacao_log
(
    id_log number(10) not null,
    id_aplicacao number(10) not null,
    dado_aplicacao varchar(200) not null,
    DT_HORA date not null,
    CONSTRAINT remedio_aplicacao_log_pk Primary Key (id_log)
);


CREATE OR REPLACE TRIGGER remedio_aplicacao_log_seq 
BEFORE INSERT ON remedio_aplicacao_log 
FOR EACH ROW

BEGIN
  SELECT remedio_aplicacao_log_seq.NEXTVAL
  INTO   :new.id_log
  FROM   dual;
END;


CREATE OR REPLACE TRIGGER dar_remedio_log
AFTER INSERT OR UPDATE OR DELETE ON aplicacao 
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO remedio_aplicacao_log VALUES (remedio_aplicacao_log_seq.nextval,:NEW.NUM_APLICACAO,'INSERINDO NA TABELA APLICACAO - NUM_PRESCRICAO: '||TO_CHAR(:NEW.NUM_PRESCRICAO)||' - DT_HORA_APLICACAO: '||TO_CHAR(:NEW.DT_HORA_APLICACAO)||' - APLICADO_POR: '||TO_CHAR(:NEW.APLICADO_POR)||' - DOSE_APLICADA: '||TO_CHAR(:NEW.DOSE_APLICADA), current_timestamp);
    ELSIF UPDATING THEN
        INSERT INTO remedio_aplicacao_log VALUES (remedio_aplicacao_log_seq.nextVal,:OLD.NUM_APLICACAO,'ATUALIZANDO A TABELA APLICACAO - NUM_PRESCRICAO_ANTERIOR: '||TO_CHAR(:OLD.NUM_PRESCRICAO)||' - NUM_PRESCRICAO_NOVO: '||TO_CHAR(:NEW.NUM_PRESCRICAO)||' - DT_HORA_APLICACAO_ANTERIOR: '||TO_CHAR(:OLD.DT_HORA_APLICACAO)||' - DT_HORA_APLICACAO_NOVO: '||TO_CHAR(:NEW.DT_HORA_APLICACAO)||' - APLICADO_POR_ANTERIOR: '||TO_CHAR(:OLD.APLICADO_POR)||' - APLICADO_POR_NOVO: '||TO_CHAR(:NEW.APLICADO_POR)||' - DOSE_APLICADA_ANTERIOR: '||TO_CHAR(:OLD.DOSE_APLICADA)||' - DOSE_APLICADA_NOVO: '||TO_CHAR(:NEW.DOSE_APLICADA),current_timestamp);
    ELSIF DELETING THEN
        INSERT INTO remedio_aplicacao_log VALUES (remedio_aplicacao_log_seq.nextVal,:OLD.NUM_APLICACAO,'DELETANDO LINHA NA TABELA APLICACAO - NUM_PRESCRICAO: '||TO_CHAR(:OLD.NUM_PRESCRICAO)||' - DT_HORA_APLICACAO: '||TO_CHAR(:OLD.DT_HORA_APLICACAO)||' - APLICADO_POR: '||TO_CHAR(:OLD.APLICADO_POR)||' - DOSE_APLICADA: '||TO_CHAR(:OLD.DOSE_APLICADA),current_timestamp);
    END IF;
END;

/*
-- AREA DE TESTE
select * from aplicacao;

insert into aplicacao VALUES
(aplicacao_seq.NextVal, 205, current_timestamp, 'Joninha',10);

select * from remedio_aplicacao_log;
*/


/*4- Implemente uma função que retorne a quantidade de pacientes internados atualmente para um determinado 
motivo de internação, por exemplo, Crise Renal ou Infarto, etc., passando como parâmetro parte do motivo de 
internação. Faça os tratamentos necessário*/

DROP TYPE t_type FORCE ;
CREATE OR REPLACE TYPE t_type AS OBJECT
(quant INTEGER,
motivo VARCHAR2(40));

CREATE OR REPLACE TYPE t_table AS TABLE OF t_type ;


CREATE OR REPLACE FUNCTION count_patients (reason IN internacao.MOTIVO%TYPE)
RETURN t_table IS res t_table := t_table() ;
BEGIN
FOR k IN(SELECT  i.MOTIVO AS motivo, COUNT(i.NUM_INTERNACAO) AS quantidade
        FROM internacao i 
        WHERE UPPER(i.MOTIVO) LIKE ('%'||UPPER(reason)||'%') AND
        i.SITUACAO_INTERNACAO = 'ATIVA'
        GROUP BY i.MOTIVO) LOOP
        
res.EXTEND();
res(res.count) := t_type(k.quantidade, k.motivo) ;
END LOOP ;
RETURN res;
END;


--testing
SELECT * FROM TABLE (count_patients ('fratura'));
