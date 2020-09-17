-- 1)
CREATE OR REPLACE TRIGGER validate_date
BEFORE INSERT OR UPDATE ON Funcionario
FOR EACH ROW

BEGIN
IF :NEW.dt_admissao  < CURRENT_DATE THEN
    RAISE_APPLICATION_ERROR( -20050, 'Data de admissão deve ser maior ou igual a data atual');
END IF;
END;

--testing
update funcionario set dt_admissao = TO_DATE('01-01-2021') WHERE cod_func = 10;

-- 2)
CREATE OR REPLACE TRIGGER validate_discount
BEFORE INSERT ON pedido
FOR EACH ROW
BEGIN
    IF :NEW.VL_DESCTO_PED > :NEW.VL_TOTAL_PED * 0.2 THEN 
        RAISE_APPLICATION_ERROR( -20051, 'Valor de desconto acima do permitido (20% do valor do pedido)');
    END IF;
END;

-- 3 - Registrar em log a inclusão e atualização de itens no pedido. Por exemplo, se alterar a quantidade pedida, cancelar o item, etc. Não haverá exclusão de item.

-- TABLE DE LOG
CREATE TABLE AUDITORIA_PEDIDO
(
    NUM_LOG_PEDIDO INTEGER PRIMARY KEY NOT NULL,
    TIPO_LOG VARCHAR2(20) NOT NULL,
    TIMESTAMP_LOG TIMESTAMP(6) NOT NULL,
    DT_HORA_PED_ANTES TIMESTAMP(6) NULL,
    DT_HORA_PED_DEPOIS TIMESTAMP(6) NULL,
    VL_TOTAL_PED_ANTES NUMBER(11,2) NULL,
    VL_TOTAL_PED_DEPOIS NUMBER(11,2) NULL,
    VL_DESCTO_PED_ANTES NUMBER(11,2) NULL,
    VL_DESCTO_PED_DEPOIS NUMBER(11,2) NULL,
    VL_FRETE_PED_ANTES NUMBER(11,2) NULL,
    VL_FRENTE_PED_DEPOIS NUMBER(11,2) NULL,
    END_ENTREGA_ANTES VARCHAR2(80) NULL,
    END_ENTREGA_DEPOIS VARCHAR2(80) NULL,
    SITUACAO_PED_ANTES CHAR(15) NULL,
    SITUACAO_PED_DEPOIS CHAR(15) NULL
);


--triger 
CREATE SEQUENCE log_pedido ; 
-- gatilho para auditar operacoes em produto

CREATE OR REPLACE TRIGGER gera_log_pedido
AFTER INSERT OR UPDATE ON pedido
FOR EACH ROW
BEGIN
-- verificando qual foi a operacao que o usuario acabou de fazer, por meio das variaveis de sessao
IF INSERTING THEN
    INSERT INTO auditoria_pedido VALUES (log_pedido.nextval,
                                         'INSERT',
                                         current_timestamp,
                                         null,
                                         :NEW.DT_HORA_PED,
                                         null,
                                         :NEW.VL_TOTAL_PED,
                                         null,
                                         :NEW.VL_DESCTO_PED,
                                         null,
                                         :NEW.VL_FRETE_PED,
                                         null,
                                         :NEW.END_ENTREGA,
                                         null,
                                         :NEW.SITUACAO_PED);
                        
ELSIF UPDATING THEN
    INSERT INTO auditoria_pedido VALUES (log_pedido.nextval,
                                         'UPDATE',
                                         current_timestamp,
                                         :OLD.DT_HORA_PED,
                                         :NEW.DT_HORA_PED,
                                         :OLD.VL_TOTAL_PED,
                                         :NEW.VL_TOTAL_PED,
                                         :OLD.VL_DESCTO_PED,
                                         :NEW.VL_DESCTO_PED,
                                         :OLD.VL_FRETE_PED,
                                         :NEW.VL_FRETE_PED,
                                         :OLD.END_ENTREGA,
                                         :NEW.END_ENTREGA,
                                         :OLD.SITUACAO_PED,
                                         :NEW.SITUACAO_PED);
END IF ;
END;

--testing
UPDATE pedido SET VL_TOTAL_PED = 1000 WHERE NUM_PED=2020;