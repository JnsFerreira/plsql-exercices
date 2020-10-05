-- ex5
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
