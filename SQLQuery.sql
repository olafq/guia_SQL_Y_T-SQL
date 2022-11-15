use GD2015C1

-- punto 1 
select clie_codigo,clie_razon_social
from Cliente
where clie_codigo >= 1000
order by clie_codigo

--punto2 
select prod_codigo,prod_detalle, sum(item_cantidad) from Producto join Item_Factura on item_producto=prod_codigo
join Factura on item_numero + item_tipo + item_sucursal= fact_numero + fact_tipo + fact_sucursal
where year(fact_fecha) = 2012
group by prod_codigo, prod_detalle
order by sum(item_cantidad)
--punto3

select prod_codigo AS CODIGO, prod_detalle AS NOMBRE,sum(stoc_cantidad) AS 'STOCK TOTAL'
from  STOCK,DEPOSITO,Producto
where stoc_deposito = depo_codigo and stoc_producto=prod_codigo
group by prod_codigo, prod_detalle
order by prod_detalle
-- 2 FORMA CON JOIN  
SELECT 
	prod_codigo AS 'Codigo', 
	prod_detalle AS 'Producto', 
	SUM(stoc_cantidad) AS 'Stock total' 
FROM Producto
JOIN STOCK ON prod_codigo = stoc_producto
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle


-- ejercicio 4 
select prod_codigo,prod_detalle,  count(comp_componente) AS 'componentes'
from Producto
LEFT JOIN Composicion ON prod_codigo = comp_producto
where prod_codigo in( select stoc_producto from STOCK group by stoc_producto having avg(stoc_cantidad)>100)
GROUP BY prod_codigo,prod_detalle

-- ejercicio 5
select 
	prod_codigo,
	prod_detalle,
	sum(item_cantidad) AS 'egresos'
from Producto 
 JOIN Item_Factura  ON prod_codigo = item_producto
 JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
 where YEAR(fact_fecha) = 2012
GROUP BY prod_codigo,prod_detalle
having sum(item_cantidad) > (select sum(item_cantidad)
							 from Item_Factura 
							 join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
							 where YEAR(fact_fecha) = 2011 and item_producto = prod_codigo)


-- EJERCICIO 6 
-- con select dinamico 

	SELECT 
		 rubr_id,
		 rubr_detalle, 
		 COUNT(DISTINCT prod_codigo) AS 'PRODUCTOS',
		 SUM(stoc_cantidad) AS 'STOCK TOTAL'
	FROM Rubro
	Join Producto ON  rubr_id = prod_rubro
	join Stock ON prod_codigo=  stoc_producto  
	WHERE (SELECT sum(stoc_cantidad) FROM STOCK WHERE stoc_producto = prod_codigo)  >
		 -- prod_codigo in (select stoc_producto from stock group by stoc_producto having sum(stoc_cantidad))
		 (SELECT stoc_cantidad from STOCK WHERE (stoc_producto = '00000000') AND (stoc_deposito = '00'))
	GROUP BY rubr_id,rubr_detalle

-- con select estatico  siempre conviene hacerlo asi ya que el dinamico itera mas veces 
SELECT 
		 rubr_id,
		 rubr_detalle, 
		 COUNT(DISTINCT prod_codigo) AS 'PRODUCTOS',
		 SUM(stoc_cantidad) AS 'STOCK TOTAL'
	FROM Rubro
	Join Producto ON  rubr_id = prod_rubro
	join Stock ON prod_codigo=  stoc_producto  
	WHERE  prod_codigo in (select stoc_producto from STOCK group by stoc_producto having sum(stoc_cantidad) >
		 (SELECT stoc_cantidad from STOCK WHERE (stoc_producto = '00000000') AND (stoc_deposito = '00'))
	GROUP BY rubr_id,rubr_detalle


-- EJERCICIO 7
-- para valores unicos como min o max o avg nos podemos cagar en la atomizidad y usar un where con stoc_cantidad >0 , en cambio si piden sum ahi cambia  se saca el 
-- join stock  y se agregar el where prod_codigo in(select distinct stoc_producto from stock where stoc_cantidad >0
SELECT 
	prod_codigo,
	prod_detalle,
	MAX(item_precio) AS 'PRECIO MAX',
	MIN(item_precio) AS 'PRECIO MIN',
	-- 100 - ((min(item_precio) / max(item_precio))*100)
	CAST(((MAX(item_precio) - MIN(item_precio)) / MIN(item_precio)) * 100 AS DECIMAL(10,2)) AS 'Diferencia'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto 
JOIN STOCK ON prod_codigo = stoc_producto
WHERE  stoc_cantidad > 0
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_codigo




--EJERCICIO 8 DUDA, CONSULTAR BIEN 
SELECT prod_detalle, 
	   MAX(stoc_cantidad) AS 'MAYOR STOCK'
FROM Producto
JOIN STOCK ON  prod_codigo = stoc_producto
where stoc_cantidad > 0
group by prod_codigo,prod_detalle
having count(*) = (select count(*) from DEPOSITO) -- para saber si todos aparecen en todos los depositos que son 33

-- EJERCICIO 9 
--Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
--mismo y la cantidad de depósitos que ambos tienen asignados. 

SELECT empl_jefe, empl_codigo, empl_nombre, count(depo_encargado)
FROM Empleado
JOIN DEPOSITO ON (empl_codigo = depo_encargado or empl_jefe = depo_encargado) -- en el on va cualquier cosa que devuelva true o false 
group by empl_jefe, empl_codigo, empl_nombre



-- EJERCICIO 10 
--Mostrar los 10 productos más vendidos en la historia y también los 10 productos
--menos vendidos en la historia. Además mostrar de esos productos, quien fue el
--cliente que mayor compra realizo. 

SELECT prod_codigo AS 'CODIGO', prod_detalle AS 'PRODUCTO', (SELECT  TOP 1 fact_cliente
															 FROM  item_Factura
															 JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
															 WHERE item_producto = prod_codigo
															 group by fact_cliente
															 order by SUM(item_cantidad) DESC) AS 'MEJOR CLIENTE'

FROM Producto
WHERE prod_codigo IN (SELECT TOP 10 item_producto
					  FROM Item_factura 
					  GROUP BY item_producto
					  ORDER BY SUM(item_cantidad) DESC)
					  OR prod_codigo IN (SELECT TOP 10 item_producto 
										 FROM Item_factura 
										 GROUP BY item_producto
										 ORDER BY SUM(item_cantidad) ASC)
				

--11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
--productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
--ordenar de mayor a menor, por la familia que más productos diferentes vendidos
--tenga, solo se deberán mostrar las familias que tengan una venta superior a 20000
--pesos para el año 2012. 

SELECT fami_detalle, count(DISTINCT prod_codigo) AS 'Cantidad Diferente', SUM(item_precio * item_cantidad) AS 'monto sin impuesto'
FROM Familia
JOIN Producto ON fami_id = prod_familia 
JOIN  Item_Factura ON prod_codigo = item_producto
GROUP BY fami_detalle, fami_id
HAVING (SELECT SUM(Item_precio * item_cantidad) FROM Producto 
JOIN Item_factura ON prod_codigo = item_producto
JOIN Factura ON (item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero)
WHERE YEAR(fact_fecha) = 2012 AND prod_familia = fami_id) > 20000
ORDER BY count(DISTINCT prod_codigo) DESC -- ACA SE PUEDE PONER 2 DESC PARA ORDENARLO SEGUN LA COLUMNA 2

--12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron
--importe promedio pagado por el producto, cantidad de depósitos en lo cuales hay
--stock del producto y stock actual del producto en todos los depósitos. Se deberán
--mostrar aquellos productos que hayan tenido operaciones en el año 2012 y los datos
--deberán ordenarse de mayor a menor por monto vendido del producto
SELECT prod_detalle AS 'PRODUCTO', COUNT(DISTINCT fact_cliente) AS 'CLIENTES', 
						AVG(item_precio) AS 'PRECIO PROMEDIO',ISNULL((SELECT COUNT( DISTINCT stoc_producto)		
																	  FROM STOCK 
																	  WHERE stoc_cantidad >0 and stoc_producto=prod_codigo
																	  GROUP BY stoc_producto), 0) AS 'DEPOSITOS CON STOCK',
																	  ISNULL((SELECT SUM(stoc_cantidad) FROM STOCK 
																										WHERE stoc_producto = prod_codigo
																										GROUP BY stoc_producto),0) AS 'STOCK ACTUAL'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE prod_codigo IN (SELECT item_producto FROM item_Factura JOIN Factura ON item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
						WHERE YEAR(fact_fecha) = 2012 AND item_producto = prod_codigo )
GROUP BY prod_detalle, prod_codigo
ORDER BY SUM( item_cantidad* item_precio)DESC

--13 Realizar una consulta que retorne para cada producto que posea composición
--nombre del producto, precio del producto, precio de la sumatoria de los precios por
--la cantidad de los productos que lo componen. Solo se deberán mostrar los
--productos que estén compuestos por más de 2 productos y deben ser ordenados de
--mayor a menor por cantidad de productos que lo componen. 

SELECT prod_detalle AS 'PRODUCTO' ,prod_precio AS 'PRECIO',SUM(comp_cantidad)* SUM(prod_precio) AS 'PRECIO DE COMPONENTES',COUNT(DISTINCT comp_cantidad)
FROM Composicion 
JOIN Producto ON comp_producto = prod_codigo-- SE VUELA ESTA LINEA 
GROUP BY prod_detalle,prod_precio
HAVING COUNT(DISTINCT comp_cantidad) >2
ORDER BY COUNT(DISTINCT comp_cantidad) DESC	

--14. Escriba una consulta que retorne una estadística de ventas por cliente. Los campos
--que debe retornar son:
--Código del cliente
--Cantidad de veces que compro en el último año
--Promedio por compra en el último año
--Cantidad de productos diferentes que compro en el último año
--Monto de la mayor compra que realizo en el último año
--Se deberán retornar todos los clientes ordenados por la cantidad de veces que
--compro en el último año.
--No se deberán visualizar NULLs en ninguna columna 

SELECT clie_codigo AS 'CODIGO CLIENTE', ISNULL(COUNT(DISTINCT fact_tipo+fact_sucursal+fact_numero),0) AS 'cantidad de veces que se compro'
	   ,ISNULL(AVG(fact_total),0) AS 'PROMEDIO DE COMPRA', ISNULL((SELECT ISNULL(COUNT(DISTINCT item_producto), 0) 
																   FROM Item_Factura
																   JOIN Factura ON item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
																   WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
																   AND fact_cliente = clie_codigo
																   GROUP BY fact_cliente), 0)  AS 'CANTIDAD DE PRODUCTOS',
	    ISNULL(MAX(fact_total),0) AS 'MAX COMPRA'
FROM Cliente 
JOIN Factura ON clie_codigo = fact_cliente
WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha))FROM Factura)
GROUP BY clie_codigo
ORDER BY 2 DESC

/*15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos
juntos (en la misma factura) más de 500 veces. El resultado debe mostrar el código
y descripción de cada uno de los productos y la cantidad de veces que fueron
vendidos juntos. El resultado debe estar ordenado por la cantidad de veces que se
vendieron juntos dichos productos. Los distintos pares no deben retornarse más de
una vez.
Ejemplo de lo que retornaría la consulta:
PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2 */
SELECT  I1.item_producto AS 'PROD1', (SELECT prod_detalle 
									  FROM  Producto
									  WHERE prod_codigo = I1.Item_Producto) AS 'DETALLE1',
	    I2.item_producto AS 'PROD2', (SELECT prod_detalle 
									  FROM  Producto
									  WHERE prod_codigo = I2.Item_Producto) AS 'DETALLE2',
	   COUNT(*) AS 'VECES'   
 FROM item_factura I1, item_factura I2
 WHERE I1.item_numero+I1.item_tipo+I1.item_sucursal= I2.item_numero+I2.item_tipo+I2.item_sucursal
 AND I1.item_producto != I2.item_producto 
 AND I1.item_producto > I2.item_producto -- CON ESTO SACAMOS QUE SE REPITAN LOS PORDUCTOS 
 GROUP BY I1.item_producto, I2.item_producto
 HAVING COUNT(*) > 500
 ORDER BY 5 


 /* 16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos
compran en la empresa, se pide una consulta SQL que retorne aquellos clientes
cuyas ventas son inferiores a 1/3 del promedio de ventas del/los producto/s que más
se vendieron en el 2012.
Además mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.
Aclaraciones:
La composición es de 2 niveles, es decir, un producto compuesto solo se compone
de productos no compuestos.
Los clientes deben ser ordenados por código de provincia ascendente. */ 

SELECT clie_razon_social AS 'CLIENTE', SUM(item_cantidad) AS 'unidades vendidad 2012',
(SELECT  TOP 1 item_producto 
FROM item_Factura 
JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero  
WHERE clie_codigo = fact_cliente and YEAR(fact_fecha) = 2012  GROUP BY item_producto ORDER BY SUM(item_cantidad) DESC) AS 'PRODUCTO MAS COMPRADO EN 2012'
FROM Cliente
JOIN Factura ON clie_codigo = fact_cliente 
JOIN item_factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero  
WHERE YEAR(fact_fecha) = 2012 
GROUP BY clie_razon_social, clie_codigo,clie_domicilio
HAVING SUM(Item_cantidad) < (1.00/3) * (SELECT  TOP 1 SUM(item_cantidad) 
FROM item_Factura 
JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero  
JOIN CLIENTE ON clie_codigo = fact_cliente
WHERE clie_codigo = fact_cliente and YEAR(fact_fecha) = 2012  GROUP BY item_producto ORDER BY SUM(item_cantidad) DESC)

/*17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto.
La consulta debe retornar:
PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del
periodo pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar
ordenada por periodo y código de producto. 
*/ 
SELECT CONCAT(YEAR(F1.fact_fecha),RIGHT('0'+RTRIM(MONTH(F1.fact_fecha)),2)) AS 'PERIODO',
	   prod_codigo AS 'CODIGO',
	   ISNULL(prod_detalle,'SIN DESCRIPCION') AS 'PRODUCTO',
	   ISNULL(SUM(item_cantidad),0) AS 'CANTIDAD VENDIDA', 
	   ISNULL((SELECT SUM(Item_cantidad) 
			FROM item_Factura 
			JOIN Factura F2 ON item_tipo+item_sucursal+item_numero = F2.fact_tipo+F2.fact_sucursal+F2.fact_numero 
			WHERE item_producto = prod_codigo 
					AND YEAR(F2.fact_fecha) = YEAR(F1.fact_fecha) -1
					AND MONTH(F2.fact_fecha) = MONTH(F1.fact_fecha)),0) AS 'CANT. VENIDAD AÑO ANTEORIOR',
		ISNULL(COUNT(*),0) AS 'CANTIDAD DE FACTURAS'	
FROM Producto 
JOIN item_Factura ON prod_codigo = item_producto
JOIN Factura F1 ON Item_tipo+item_sucursal+item_numero = F1.fact_tipo+F1.fact_sucursal+F1.fact_numero 
GROUP BY prod_codigo,prod_detalle,YEAR(F1.fact_fecha),MONTH(F1.fact_fecha)
ORDER BY 1,2 


SELECT 
	CONCAT(YEAR(F1.fact_fecha), RIGHT('0' + RTRIM(MONTH(F1.fact_fecha)), 2)) AS 'Periodo',
	prod_codigo AS 'Codigo',
	ISNULL(prod_detalle, 'SIN DESCRIPCION') AS 'Producto',
	ISNULL(SUM(item_cantidad), 0) AS 'Cantidad vendida',
	ISNULL((SELECT SUM(item_cantidad) FROM Item_Factura
	JOIN Factura F2 ON item_numero + item_sucursal + item_tipo = F2.fact_numero + F2.fact_sucursal + F2.fact_tipo  
	WHERE item_producto = prod_codigo 
	AND YEAR(F2.fact_fecha) = YEAR(F1.fact_fecha) - 1
	AND MONTH(F2.fact_fecha) = MONTH(F1.fact_fecha)), 0) AS 'Cantidad vendida anterior',
	ISNULL(COUNT(*) , 0) AS 'Cantidad de facturas'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura F1 ON item_numero + item_sucursal + item_tipo =
F1.fact_numero + F1.fact_sucursal + F1.fact_tipo
GROUP BY prod_codigo, prod_detalle, YEAR(F1.fact_fecha), MONTH(F1.fact_fecha)
ORDER BY 1, 2

select * from item_factura order by item_producto

select * from Producto order by prod_codigo
 
/*30. Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean
jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la
consulta que retorne las siguientes columnas:
 Nombre del Jefe
 Cantidad de empleados a cargo
 Monto total vendido de los empleados a cargo
 Cantidad de facturas realizadas por los empleados a cargo
 Nombre del empleado con mejor ventas de ese jefe
Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese
necesario.
Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se
deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas.*/select ej.empl_nombre as 'jefe',count(distinct ee.empl_codigo) as 'empleados a cargo' ,sum(fact_total) as 'total vendido' ,count(*) 'total de facturas' ,(select  top 1 e1.empl_nombre from empleado e1 join Factura on e1.empl_codigo = fact_vendedorwhere   ee.empl_jefe = e1.empl_jefe and year(fact_fecha) = 2012group by  e1.empl_nombreOrder by sum(fact_total) desc) as 'empleado con mejor ventas' from empleado ee join empleado ej on ee.empl_jefe = ej.empl_codigo		join factura on ee.empl_codigo = fact_vendedorwhere year(fact_fecha) = 2012  group by ej.empl_nombre, ee.empl_jefe   having count(*) >10  order by 3 desc/* ejercicio practica sql La empresa necesita recuperar ventas perdidas. Con el fin de lanzar una nueva campaña comercial, se pide una consulta SQL que retorne aquellos clientes cuyas ventas(considerar fact_total) del año 2012 fueron inferiores al 25% del promedio de ventas de los productos vendidos entre los años 2011 y 2010. En base a lo solicitado, se requiere un listado con la siguiente informacion: 1.Razon social del cliente  2. Mostrar la leyenda "cliente recurente" si dicho cliente realizo mas de una compra en el 2012. En caso de que haya realizado solo 1 compra, entonces mostrar la leyenda "Unica vez" 3. Cantidad de productos totales vendidad en el 2012 para ese cliente. 4. Codigo de producto que mayor venta tuvo en el 2012(en caso de exisitir mas de 1, mostrar solamente el menor codigo) para ese cliente*/select clie_razon_social, case when count(distinct fact_numero + fact_sucursal + fact_tipo) >1  then 'CLIENTE RECURENTE'															    else 'Unica Vez' end, 															    sum(item_cantidad), 																(select top 1 item_producto from factura join Item_Factura on 																 fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo 																 where year(fact_fecha) = 2012 and clie_codigo = fact_cliente 																 group by item_producto 																 order by sum(item_cantidad)desc, item_producto)  from factura  join Cliente on fact_cliente = clie_codigojoin item_factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo where year(fact_fecha) = 2012group by clie_razon_social, clie_codigohaving sum(item_cantidad* item_precio) < (0.25* (select avg(fact_total) from factura where year(fact_fecha) between 2010 and 2011)) order by 1-- otra forma contemplando el fact_total select clie_razon_social, case when count(*) >1  then 'CLIENTE RECURENTE'							else 'Unica Vez' end, 							(select sum(item_cantidad) from item_factura join Factura on  fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo 							where clie_codigo = fact_cliente) , 							(select top 1 item_producto from factura join Item_Factura on 							fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo 							where year(fact_fecha) = 2012 and clie_codigo = fact_cliente 							group by item_producto 							order by sum(item_cantidad)desc, item_producto)  from factura  join Cliente on fact_cliente = clie_codigowhere year(fact_fecha) = 2012group by clie_razon_social, clie_codigohaving sum(fact_total) < (0.25* (select avg(fact_total) from factura where year(fact_fecha) between 2010 and 2011)) order by 1