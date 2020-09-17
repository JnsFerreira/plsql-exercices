-- Validar a região do vendedor que atende o pedido para a mesma região do cliente, ou seja, não permitir que um vendedor de outra região atenda o cliente;

CREATE OR REPLACE TRIGGER valida_regiao
BEFORE INSERT OR UPDATE ON pedido
FOR EACH ROW
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
v_cod_reg_func NUMBER;
v_cod_reg_cli NUMBER;

BEGIN

    SELECT f.COD_REGIAO INTO v_cod_reg_func
    FROM funcionario f 
    WHERE f.COD_FUNC = :NEW.COD_FUNC_VENDEDOR; 
    
    SELECT c.COD_REGIAO INTO v_cod_reg_cli
    FROM cliente c INNER JOIN pedido p ON (p.COD_CLI = c.COD_CLI)
    WHERE c.COD_CLI = (SELECT COD_CLI FROM pedido WHERE NUM_PED = :OLD.NUM_PED) AND 
    ROWNUM =1;
    
    IF v_cod_reg_func != v_cod_reg_cli THEN
        RAISE_APPLICATION_ERROR( -20100, 'O vendedor deve ser da mesma região do cliente');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Vendedor alterado com sucesso');
    END IF;
END;

--testando
UPDATE pedido SET COD_FUNC_VENDEDOR = 4 WHERE NUM_PED = 2025


/*===========================================================================================*/

CREATE OR REPLACE TRIGGER valida_salario
BEFORE INSERT OR UPDATE ON FUNCIONARIO  -- momento do disparo ANTES para evitar o erro
FOR EACH ROW
DECLARE
  Pragma Autonomous_Transaction;

vCOD_FUNC FUNCIONARIO.COD_FUNC%TYPE ;
vvalor_salario FUNCIONARIO.SALARIO%TYPE  ;  -- tipo de dado ancorado no tipo de dado da coluna
teste number;
BEGIN
SELECT f.COD_FUNC, f.SALARIO INTO vCOD_FUNC, vvalor_salario
FROM FUNCIONARIO f
WHERE f.COD_FUNC = :NEW.COD_FUNC ;
-- testando
SELECT COUNT(COD_CARGO) into teste
FROM FUNCIONARIO
WHERE SALARIO > vvalor_salario ;


/*===========================================================================================*/

/*- Elabore um controle para evitar que um funcionário que não tenha o cargo de gerente seja cadastrado como gerente de outro funcionário,
ou seja, somente funcionários com cargo de Gerente podem gerenciar outros funcionários, e além disso os gerentes devem ser da mesma
região que o funcionário.*/

CREATE OR REPLACE TRIGGER valida_gerencia
BEFORE UPDATE OR INSERT ON funcionario
FOR EACH ROW
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
vcargo number;
vgerencia VARCHAR2(25);
v_reg_func number;
v_reg_gerente number;

BEGIN

SELECT f.COD_CARGO INTO vcargo
FROM funcionario f 
WHERE f.COD_FUNC = :NEW.COD_FUNC_GERENTE;

SELECT f.COD_REGIAO INTO v_reg_gerente
FROM funcionario f 
WHERE f.COD_FUNC = :NEW.COD_FUNC_GERENTE;

SELECT f.COD_REGIAO INTO v_reg_func
FROM funcionario f 
WHERE f.COD_FUNC = :OLD.COD_FUNC;

SELECT c.NOME_CARGO INTO vgerencia
from CARGO c
WHERE c.COD_CARGO = (SELECT f.COD_CARGO FROM funcionario f WHERE f.COD_FUNC = :NEW.COD_FUNC_GERENTE);

    IF (vgerencia not like '%Gerente%')  OR (v_reg_func != v_reg_gerente) THEN
        RAISE_APPLICATION_ERROR( -20103, 'Não pode ser alterado, verifique o código e região do gerente' );
    ELSE
        DBMS_OUTPUT.PUT_LINE('Gerente alterado com sucesso');
END IF;
END;
 