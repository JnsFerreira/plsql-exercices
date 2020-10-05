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
