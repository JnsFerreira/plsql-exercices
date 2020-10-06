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
/*
8- Elabore uma procedure com cursor FETCH para gerar um extrato completo de uma determinada internação no
formato abaixo:
Internacao : 3006-Paciente MARIA LUCIEIDE - PRE NATAL-Dr. TADASHI KOBAIASH
Período : 07/05/2020 04:58 A 10/05/2020 06:58 – Leito : SIMPLES-ENFERMARIA
Total Diarias: $9800,00
Total Servicos Medicos : $10290,00
---------------------------------------------------------------------------------------------------
Aplicacao-Data Hora Aplicacao - Medicamento - Responsavel Aplicacao- Dose Aplicada - Custo Dose
41 08/05/2020 11:52 NOVALGINA Tiao 7 $10,00
43 09/05/2020 17:12 NOVALGINA Mirtes 5 $10,00
--------------------------------------------------------------------------------------------------
Total Medicamentos : $4,41
---------------------------------------------------------------------------------------------------
Exame-Data Hora Realizacao - Tipo Exame - Laudo - Custo Exame
70 09/05/2020 17:33 RAIO X TORAX Normal $55,00
71 10/05/2020 08:33 URINA Normal $55,00
----------------------------------------------------------------------------------------------------
Total Exames : $110,00
----------------------------------------------------------------------------------------------------
Total Internacao : $20204,41
*/


CREATE OR REPLACE PROCEDURE extrato_completo_internacao(cod_internacao IN internacao.NUM_INTERNACAO%TYPE)
IS
   motivo internacao.MOTIVO%TYPE;
   nome_paciente PACIENTE.NOME_PAC%TYPE;
   nome_medico MEDICO.NOME_MED%TYPE;
   data_hora_entrada internacao.DT_HORA_ENTRADA%TYPE;
   data_hora_saida internacao.DT_HORA_SAIDA%TYPE;
   total_valor_diarias NUMBER(15,0);
   total_valor_serv_medic NUMBER(15,0);
   total_valor_exames NUMBER(15,0);
   total_valor_aplicacoes NUMBER(15,0);
   total_valor NUMBER(15,0);

	
	CURSOR extrato_aplicacao_med is
		SELECT *
		FROM MEDICAMENTO m
			JOIN PRESCRICAO p on (p.COD_MEDICAMENTO =  m.COD_MEDICAMENTO)
			JOIN APLICACAO a on (a.NUM_PRESCRICAO = p.NUM_PRESCRICAO)
		WHERE p.NUM_INTERNACAO = cod_internacao;
	aplicacao_rec extrato_aplicacao_med%ROWTYPE;
		
	   
    CURSOR extrato_exames IS
        SELECT *
        FROM exame_med EM
            JOIN tipo_exame TE on (EM.COD_TIPO_EXAME = TE.COD_TIPO_EXAME)
        WHERE EM.NUM_INTERNACAO = cod_internacao;
	exame_rec extrato_exames%ROWTYPE;
	
BEGIN
    total_valor_aplicacoes := 0;
	total_valor_exames := 0;
	total_valor := 0;
	
    SELECT p.NOME_PAC, i.MOTIVO, m.NOME_MED, i.DT_HORA_ENTRADA, i.DT_HORA_SAIDA into nome_paciente, motivo, nome_medico, data_hora_entrada, data_hora_saida
    FROM INTERNACAO i
        JOIN PACIENTE p on (i.COD_PACIENTE = p.COD_PACIENTE)
        JOIN MEDICO m on (i.CRM_RESPONSAVEL = m.CRM)
    WHERE i.NUM_INTERNACAO = cod_internacao;
    
    DBMS_OUTPUT.PUT_LINE('Internação: '||TO_CHAR(cod_internacao)||' - '||TO_CHAR(nome_paciente)||' - '||TO_CHAR(motivo)||' - Dr.'||TO_CHAR(nome_medico));
    DBMS_OUTPUT.PUT_LINE('Período: '||TO_CHAR(data_hora_entrada, 'DD-MM-YYYY')||' A '||TO_CHAR(data_hora_saida, 'DD-MM-YYYY'));
	
	
	
	/*calculo diarias*/
	
	SELECT DISTINCT (extract(day from (i.DT_HORA_SAIDA-i.DT_HORA_ENTRADA)) * l.CUSTO_DIARIA) INTO total_valor_diarias
				FROM INTERNACAO i
					JOIN LEITO l on (l.NUM_QTO = i.NUM_QTO)
				WHERE i.NUM_INTERNACAO = cod_internacao
				AND l.NUM_LEITO = i.NUM_LEITO
				AND DT_HORA_SAIDA IS NOT NULL;
				
	IF total_valor_diarias >= 0 AND total_valor_diarias < 1 THEN 
	        SELECT DISTINCT l.CUSTO_DIARIA INTO total_valor_diarias
			FROM INTERNACAO i
				JOIN LEITO l on (l.NUM_QTO = i.NUM_QTO)
			WHERE i.NUM_INTERNACAO = cod_internacao
			AND l.NUM_LEITO = i.NUM_LEITO
			AND DT_HORA_SAIDA IS NOT NULL;
	END IF;
	
	IF 	total_valor_diarias is not null THEN
		DBMS_OUTPUT.PUT_LINE('Total Diarias: $'||TO_CHAR(TO_NUMBER(total_valor_diarias))||',00');
	END IF;				
    
	
	
	/*calculo valor serviço medico*/
	
	
	SELECT DISTINCT (extract(day from (i.DT_HORA_ALTA-i.DT_HORA_ENTRADA)) * e.CUSTO_SERVICO) INTO total_valor_serv_medic
				FROM INTERNACAO i
					JOIN MEDICO_EFETIVO me on (me.CRM_EFETIVO = i.CRM_RESPONSAVEL)
					JOIN ESPECIALIDADE e on (e.COD_ESP = me.COD_ESPEC)
				WHERE i.NUM_INTERNACAO = cod_internacao 
				AND DT_HORA_ALTA IS NOT NULL;

    IF 	total_valor_serv_medic is not null THEN
		DBMS_OUTPUT.PUT_LINE('Total Serviço Médico: $'||TO_CHAR(total_valor_serv_medic)||',00');
	END IF;
  
  /*APLICACAO EXTRATO*/
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Aplicacao - Data Hora Aplicacao - Medicamento - Responsavel Aplicacao - Dose Aplica - Custo Dose');


    OPEN extrato_aplicacao_med;
    LOOP
		FETCH extrato_aplicacao_med INTO aplicacao_rec;
		EXIT WHEN extrato_aplicacao_med%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(aplicacao_rec.NUM_APLICACAO)||'  -  '||TO_CHAR(aplicacao_rec.DT_HORA_APLICACAO, 'DD-MM-YYYY hh:mm')||'  -  '||TO_CHAR(aplicacao_rec.NOME_MEDICAMENTO)||'  -  '||TO_CHAR(aplicacao_rec.DOSE_APLICADA)||'  -  R$ '||TO_CHAR(aplicacao_rec.CUSTO_DOSE)||',00');
		total_valor_aplicacoes := total_valor_aplicacoes + ((aplicacao_rec.CUSTO_DOSE / aplicacao_rec.DOSAGEM) * aplicacao_rec.DOSE_APLICADA);
    END LOOP;
	CLOSE extrato_aplicacao_med;

    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total em aplicacoes: $'||TO_CHAR(total_valor_aplicacoes)||',00');
	
  /*EXAMES EXTRATO*/
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Exame - Data Hora Exame - Tipo - Laudo - Valor Exame - Total');

	OPEN extrato_exames;
    LOOP
		FETCH extrato_exames INTO exame_rec;
		EXIT WHEN extrato_exames%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(TO_CHAR(exame_rec.NUM_EXAME)||'  -  '||TO_CHAR(exame_rec.DT_HORA_EXAME	, 'DD-MM-YYYY hh:mm')||'  -  '||TO_CHAR(exame_rec.TIPO_EXAME)||'  -  '||TO_CHAR(exame_rec.LAUDO_EXAME)||'  -  R$ '||TO_CHAR(exame_rec.CUSTO_EXAME)||',00');
        total_valor_exames := total_valor_exames + exame_rec.CUSTO_EXAME;
    END LOOP;
	CLOSE extrato_exames;

	DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total em exames: $'||TO_CHAR(total_valor_exames)||',00');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------');
	
	total_valor := total_valor_aplicacoes + total_valor_exames + total_valor_diarias + total_valor_serv_medic;
	
    DBMS_OUTPUT.PUT_LINE('Total Internação: $'||TO_CHAR(total_valor)||',00');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------------------------------------------');
EXCEPTION
  WHEN NO_DATA_FOUND THEN 
	RAISE_APPLICATION_ERROR (-20035,'Não encontramos dados suficientes desta internação para emissão de extrato');
END;

/*
TESTE
EXECUTE extrato_completo_internacao(3003)
*/
