--1-Elabore uma função que retorne a quantidade e a soma do valor total dos pedidos feitos por um cliente passando como parâmetro o nome ou parte do nome, em um intervalo de tempo. 

CREATE OR REPLACE TYPE resultado IS TABLE OF NUMBER;

CREATE OR REPLACE FUNCTION orders_info (user_name IN cliente.NOME_FANTASIA%TYPE, vini IN pedido.dt_hora_ped%TYPE, vfim IN pedido.dt_hora_ped%TYPE)
RETURN resultado
IS vtotal resultado:= resultado(null, null);
BEGIN
SELECT SUM(p.Vl_TOTAL_PED), COUNT(p.NUM_PED) INTO vtotal(1), vtotal(2)
FROM cliente c INNER JOIN pedido p ON(c.COD_CLI = p.COD_CLI)
WHERE (p.DT_HORA_PED BETWEEN vini AND vfim) AND (UPPER(NOME_FANTASIA) LIKE '%'||UPPER(user_name)||'%')
GROUP BY NOME_FANTASIA;
RETURN vtotal;
EXCEPTION
	WHEN NO_DATA_FOUND THEN 
	RAISE_APPLICATION_ERROR (-20400,'Pedido nao encontrado! Tente novamente');
END;

/*

*/

CREATE OR REPLACE FUNCTION pedidos_gerente (vcodgerente IN funcionario.cod_func%TYPE, 
dtIni IN pedido.dt_hora_ped%TYPE, dtVim IN pedido.dt_hora_ped%TYPE)
RETURN NUMBER
IS
vtotal pedido.vl_total_ped%TYPE;

BEGIN 
SELECT SUM (ped.vl_total_ped) INTO vtotal
FROM pedido ped JOIN funcionario fun ON (ped.cod_func_vendedor = fun.cod_func)
WHERE fun.cod_func_gerente = vcodgerente
AND ped.dt_hora_ped BETWEEN dtIni AND dtVim
AND ped.situacao_ped <> 'CANCELADO';
RETURN vtotal;
EXCEPTION
	WHEN NO_DATA_FOUND THEN 
	RAISE_APPLICATION_ERROR (-20020,'Gerente nao encontrado! Refaca a busca!');
END;