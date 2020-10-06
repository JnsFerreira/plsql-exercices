/*
5-Implemente uma função que retorne o total de dias que um paciente ficou internado para um determinado
período de tempo.
Parâmetros de entrada : código do paciente, data inicial e data final.
Retorno : soma dos intervalos (duração) entre a data hora entrada e data hora de alta de cada internação
*/

CREATE OR REPLACE FUNCTION retorna_total_dias_internado (cod_paciente_busca IN INTERNACAO.COD_PACIENTE%TYPE, 
dtini IN INTERNACAO.DT_HORA_ENTRADA%TYPE, dtfim IN INTERNACAO.DT_HORA_ALTA%TYPE)
RETURN NUMBER
is total_dias Number;
BEGIN
    total_dias := 0;
    FOR k IN(SELECT extract(day from (DT_HORA_ALTA-DT_HORA_ENTRADA)) DIFF
        FROM INTERNACAO
        WHERE COD_PACIENTE = cod_paciente_busca 
            AND DT_HORA_ENTRADA >= dtini
            AND DT_HORA_ALTA <= dtfim
            AND DT_HORA_ALTA IS NOT NULL)
    LOOP
        total_dias := total_dias + k.DIFF;
    END LOOP;
RETURN total_dias;
EXCEPTION
	WHEN NO_DATA_FOUND THEN 
	RAISE_APPLICATION_ERROR (-20015,'Não foram encontrados dados de internação no período informado');
END;

/*
testes
SELECT retorna_total_dias_internado(5003,CURRENT_TIMESTAMP - 730 , CURRENT_TIMESTAMP) from dual
*/
			    
/*
6-Implemente uma função que retorne todos os motivos e a quantidade de internações para cada motivo em um
certo intervalo de tempo. Considere a data final como a data da alta. Por exemplo, de 10/06/2020 a 20/09/2020 :
Dores no Peito 4
Pressão Alta 12
Febre e Manchas na pele 2 ... etc.
*/
			    
DROP TYPE t_type FORCE ;
CREATE OR REPLACE TYPE t_type AS OBJECT
(motivo VARCHAR2(40),
quant INTEGER);

CREATE OR REPLACE TYPE t_table AS TABLE OF t_type ;

CREATE OR REPLACE FUNCTION retorna_motivos_quantidade_internacoes (dtini IN INTERNACAO.DT_HORA_ENTRADA%TYPE,
dtfim IN INTERNACAO.DT_HORA_ALTA%TYPE)
RETURN t_table IS res t_table:=t_table();
BEGIN

    FOR k IN(SELECT  i.MOTIVO AS motivo, COUNT(i.NUM_INTERNACAO) AS quantidade
        FROM internacao i 
        WHERE i.DT_HORA_ENTRADA >= dtini
            AND i.DT_HORA_ALTA <= dtfim
        GROUP BY i.MOTIVO)
    LOOP
        res.EXTEND();
        res(res.count) := t_type(k.motivo, k.quantidade);
    END LOOP;
RETURN res;
EXCEPTION
	WHEN NO_DATA_FOUND THEN 
	RAISE_APPLICATION_ERROR (-20020,'Não foram encontrados dados de motivos de internação no período informado');
END;
/*
validação
select * FROM TABLE (retorna_motivos_quantidade_internacoes(current_timestamp - 1000, current_timestamp))
*/
	
			    
/*
7 – Elabore uma procedure com cursor para gerar um extrato dos exames médicos de uma determinada internação
no formato abaixo:
Internação : 3029 WAGNER DINIZ - DORES FORTES NO PEITO- Dr. ANTONIO SOUZA
Período: 24/04/2020 18:58 A 10/09/2020 18:58
----------------------------------------------------------------------------------------------------
Exame Data Hora Exame Tipo Laudo Valor Exame Total
50 25/04/2020 18:58 SANGUE Normal $55,00 $55,00
52 06/06/2020 14:18 - GLICEMIA Normal $55,00 $110,00
51 09/09/2020 11:22 GLICEMIA Normal $55,00 $165,00
*/


CREATE OR REPLACE PROCEDURE extrato_exames_medicos(cod_internacao IN internacao.NUM_INTERNACAO%TYPE)
IS
   motivo internacao.MOTIVO%TYPE;
   nome_paciente PACIENTE.NOME_PAC%TYPE;
   nome_medico MEDICO.NOME_MED%TYPE;
   data_hora_entrada internacao.DT_HORA_ENTRADA%TYPE;
   data_hora_saida internacao.DT_HORA_SAIDA%TYPE;
   total_valor NUMBER;
   total_linhas NUMBER;
   
   CURSOR extrato_exames IS
           Select EM.NUM_EXAME as EXAME,  EM.DT_HORA_EXAME as DATA_HORA, TE.TIPO_EXAME as TIPO, EM.LAUDO_EXAME as LAUDO, TE.CUSTO_EXAME AS VALOR
        FROM exame_med EM
            JOIN tipo_exame TE on (EM.COD_TIPO_EXAME = TE.COD_TIPO_EXAME)
        WHERE EM.NUM_INTERNACAO = cod_internacao ;
BEGIN
    total_valor := 0;
    SELECT p.NOME_PAC, i.MOTIVO, m.NOME_MED, i.DT_HORA_ENTRADA, i.DT_HORA_SAIDA into nome_paciente, motivo, nome_medico, data_hora_entrada, data_hora_saida
    FROM INTERNACAO i
        JOIN PACIENTE p on (i.COD_PACIENTE = p.COD_PACIENTE)
        JOIN MEDICO m on (i.CRM_RESPONSAVEL = m.CRM)
    WHERE i.NUM_INTERNACAO = cod_internacao;
    
    DBMS_OUTPUT.PUT_LINE('Internação: '||TO_CHAR(cod_internacao)||' - '||TO_CHAR(nome_paciente)||' - '||TO_CHAR(motivo)||' - Dr.'||TO_CHAR(nome_medico));
    DBMS_OUTPUT.PUT_LINE('Período: '||TO_CHAR(data_hora_entrada, 'DD-MM-YYYY')||' A '||TO_CHAR(data_hora_saida, 'DD-MM-YYYY'));
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Exame - Data Hora Exame - Tipo - Laudo - Valor Exame - Total');


    FOR record IN extrato_exames
    LOOP
        total_valor := total_valor + record.VALOR;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(record.EXAME)||'  -  '||TO_CHAR(record.DATA_HORA, 'DD-MM-YYYY')||'  -  '||TO_CHAR(record.TIPO)||'  -  '||TO_CHAR(record.LAUDO)||'  -  R$ '||TO_CHAR(record.VALOR)||',00 -  R$'
        ||TO_CHAR(total_valor)||',00');
    END LOOP;
    
    
EXCEPTION
  WHEN NO_DATA_FOUND THEN 
	RAISE_APPLICATION_ERROR (-20035,'não há registro de exames para esta internação');
END;

/*
TESTE
execute extrato_exames_medicos(3003)
*/
