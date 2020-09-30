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
Elabore uma função que retorne o valor total vendido, calculado em reais, para um determinado Gerente de uma equipe de vendas em um 
período de tempo, tendo como parâmetros de entrada o código do gerente e as datas de início e término do período, ou seja, quanto foi vendido 
pelos vendedores que são gerenciados por este gerente. Considere que na tabela de cargo existe o cargo “Gerente Vendas”. Faça as validações 
necessárias.
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

/*
Elabore uma função que retorne o valor calculado, em reais, da comissão de um vendedor para um determinado período de tempo, tendo 
como parâmetros de entrada o código do vendedor, as datas de início e término do período, e o percentual de comissão (esse dado não tem o 
banco), ou seja, o total das comissões baseado nos pedidos de um período de tempo. Faça as seguintes validações : i) comissão não pode ser 
negativa nem passar de 100% ; ii) data final maior ou igual à data inicial do período e não podem ser nulas (se forem nulas considere a data 
final como a data atual e a data inicial 1 mês atrás – comissão dos últimos 30 dias) ; iii) se o código do vendedor é de um vendedor mesmo.
*/

CREATE OR REPLACE FUNCTION comissao (vcodvendedor IN funcionario.cod_func%TYPE, 
vini IN pedido.dt_hora_ped%TYPE, vfim IN pedido.dt_hora_ped%TYPE, percentual IN itens_pedido.descto_item%TYPE)
RETURN NUMBER
IS vtotal pedido.vl_total_ped%TYPE;
vini_new pedido.dt_hora_ped%TYPE;
vfim_new pedido.dt_hora_ped%TYPE;
BEGIN 
IF (vfim is null) OR (vini is null) THEN vini_new := current_date - 30; vfim_new := current_date; ELSE vini_new := vini; vfim_new := vfim;
END IF;
SELECT SUM (ped.vl_total_ped) * ((100 - percentual)/100) INTO vtotal
FROM pedido ped JOIN funcionario fun ON (ped.cod_func_vendedor = fun.cod_func)
WHERE ped.cod_func_vendedor = vcodvendedor
AND fun.cod_cargo = 2
AND ped.dt_hora_ped BETWEEN vini_new AND vfim_new
AND ped.situacao_ped <> 'CANCELADO';
IF percentual < 0 OR percentual > 100 THEN
	RAISE_APPLICATION_ERROR(-20025, 'Percentual Invalido! Valor não permitido');
ELSIF (vfim_new < vini_new) THEN 
	RAISE_APPLICATION_ERROR(-20030, 'Periodo de data invalido! Data final deve ser maior ou igual que a data incial');
END IF;
RETURN vtotal;
EXCEPTION
	WHEN NO_DATA_FOUND THEN 
	RAISE_APPLICATION_ERROR (-20035,'Vendedor não possui comissao!');
END;
