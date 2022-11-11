USE GD2015C1 
/*1. Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es menor
al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el % de
ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”. */
CREATE FUNCTION ej1 (@producto char(8), @deposito char(2))
RETURNS varchar(30)
AS
BEGIN 
	DECLARE @cantidad decimal(12,2)
	DECLARE @cant_max decimal(12,2)
	SELECT @cantidad =  stoc_cantidad, @cant_max = stoc_stock_maximo FROM Stock WHERE stoc_producto = @producto AND  stoc_deposito = @deposito
	IF(@cantidad < @cant_max)
		RETURN'OCUPACION DEL DEPOSITO'+LTRIM(RTRIM(STR(@cantidad/@cant_max*100)))+ ' %'
	ELSE 
		BEGIN 
		IF(@cant_max>0)
			RETURN 'DEPOSITO COMPLETO'
		END
RETURN NULL
END
DROP FUNCTION EJ1

-- OTRA FORMA DE EJ1 SIN UTILIZAR RECURSOS DE NINGUN TIPO, NO CRE VARIABLES NO HACE NADA, EJECUTA UN SELECT 
CREATE FUNCTION ej1PRO(@producto char(8), @deposito char(2))
RETURNS varchar(30)
AS 
BEGIN 
RETURN (SELECT CASE WHEN stoc_cantidad >= stoc_stock_maximo  THEN 'DEPOSITO COMPLETO'
ELSE 'OCUPACION DEL DEPOSITO'+LTRIM(RTRIM(STR(stoc_cantidad/stoc_stock_maximo*100)))+ ' %' END
FROM stock
WHERE stoc_producto=  @producto AND  stoc_deposito = @deposito)
END
--EJEMPLO DE USO DE LA FUNCION EJ1
SELECT stoc_producto, DBO.ej1(stoc_producto,stoc_deposito) FROM STOCK
SELECT stoc_producto, DBO.ej1PRO(stoc_producto,stoc_deposito) FROM STOCK
SELECT * FROM STOCK order by stoc_producto

--EJ2 HACERLO 
/*2. Realizar una función que dado un artículo y una fecha, retorne el stock que existía a
esa fecha  */
-- preguntar si esta bien.....
CREATE FUNCTION ej2(@producto char(8), @fecha date)
RETURNS int
AS
BEGIN 
RETURN (SELECT isnull(sum(stoc_cantidad),0) FROM STOCK join Item_Factura ON stoc_producto=item_producto
join Factura ON item_tipo+ item_sucursal+ item_numero = fact_tipo+fact_sucursal+fact_numero
where stoc_producto = @producto AND fact_fecha = @fecha)
END

-- EJEMPLO DE USO DE LA FUNCION EJ2
select item_producto,fact_fecha,DBO.ej2(item_producto,fact_fecha) from Factura 
join item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+ item_sucursal+ item_numero 
group by item_producto,fact_fecha
order by item_producto,fact_fecha



/*3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado en
caso que sea necesario. Se sabe que debería existir un único gerente general (debería
ser el único empleado sin jefe). Si detecta que hay más de un empleado sin jefe
deberá elegir entre ellos el gerente general, el cual será seleccionado por mayor
salario. Si hay más de uno se seleccionara el de mayor antigüedad en la empresa.
Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla de un único
empleado sin jefe (el gerente general) y deberá retornar la cantidad de empleados
que había sin jefe antes de la ejecución. */
/* Usamos un procedimineto y no un trigger porque lo voy a ejecutar 
en un momento determinado, no depende de la ejecucion de un evento
y no usamos una funcion porque vamos a modificar los estados de la tabla*/
ALTER PROCEDURE ej3 @cantidad int OUTPUT -- OUTPUT porque es parametro de salida y retorna sobre una variable 
AS 
BEGIN
	SELECT @cantidad = COUNT(*) FROM EMPLEADO WHERE empl_jefe is null
	UPDATE empleado set empl_jefe = (SELECT TOP 1 empl_codigo FROM Empleado WHERE empl_jefe IS NULL order by empl_salario DESC, empl_ingreso/*ordena de mas antiguo a mas actual*/)
	WHERE empl_jefe is null and empl_codigo not in (SELECT TOP 1 empl_codigo FROM Empleado WHERE empl_jefe IS NULL order by empl_salario DESC, empl_ingreso)
	RETURN
END 
GO
-- LO QUE DEVUELVE EL OUTPUT ( 1 )
declare @cantidad int
set @cantidad = 0
exec ej3 @cantidad OUTPUT 

/*4. Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese empleado
a lo largo del último año. Se deberá retornar el código del vendedor que más vendió
(en monto) a lo largo del último año.*/

create procedure ej4_Pr_Actualizar_Comisiones(@empleado_mas_vendedor numeric(6,0) OUTPUT)
as 
begin 
	declare @ultimo_Anio int
	select  @ultimo_Anio =  max(year(fact_fecha)) from Factura 
	update Empleado set empl_comision = (select sum(fact_total- fact_total_impuestos) from factura where fact_vendedor = empl_codigo AND year(fact_fecha) = @ultimo_Anio)
	select  TOP 1 @empleado_mas_vendedor =  fact_vendedor from factura where year(fact_fecha) = @ultimo_Anio group by fact_vendedor order by sum(fact_total) desc
end
go

-- lo que devuelve el OUTPUT 
DECLARE @empleado INT
set @empleado = 0
EXEC ej4_Pr_Actualizar_Comisiones @empleado OUTPUT
SELECT @empleado
GO
-- Finalmente compruebo si se actualizaron las comisiones
SELECT empl_codigo, empl_comision FROM Empleado

/*5 5. Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
Create table Fact_table
( anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto) */
Create table Fact_table
( anio char(4) not null,
mes char(2)not null,
familia char(3)not null,
rubro char(4)not null,
zona char(3)not null,
cliente char(6)not null,
producto char(8)not null,
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint PK_FACT_TABLE primary key(anio,mes,familia,rubro,zona,cliente,producto)

create procedure ej5_completar_Fac_table
as
begin 
INSERT INTO fact_table 
select year(fact_fecha), month(fact_fecha),prod_familia,prod_rubro,depa_zona, fact_cliente,Prod_Codigo,
sum(ISNULL(item_cantidad,0)),sum(ISNULL(item_precio * item_cantidad,0))
From Factura join item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
join Empleado on fact_vendedor = empl_codigo  
join Producto on item_Producto = prod_Codigo
join Departamento on empl_departamento = depa_codigo
group by year(fact_fecha), month(fact_fecha),prod_familia,prod_rubro,depa_zona, fact_cliente,Prod_Codigo
end 
go 

-- PRUEBA

-- Primero veo que productos se vendieron y tomo uno para probar el SP como por ejemplo
-- par el producto 00001415 del rubro 0010 y familia 101 durante el mes de junio en el 
-- a�o 2012 al cliente 00656 correspondiente a la zona 004

SELECT
SUM(item_cantidad) AS 'Cantidad vendida',
SUM (item_cantidad * item_precio) AS 'Monto'
FROM Item_Factura
JOIN Factura ON item_numero + item_sucursal + item_tipo =
fact_numero + item_sucursal + item_tipo
JOIN Producto ON item_producto = prod_codigo 
JOIN Empleado ON fact_vendedor = empl_codigo
JOIN Departamento ON empl_departamento = depa_codigo
WHERE item_producto = '00001415' AND
YEAR(fact_fecha) = 2012 AND
MONTH(fact_fecha) = 6 AND
fact_cliente = '00656' AND
depa_zona = '004' AND
prod_familia = '101' AND
prod_rubro = '0010'

-- Segun la consulta anterior se vendieron en junio de 2012 unas 10 unidades del 
-- producto 00001415 por un monto de 13.30, por lo tanto estos dos valores
-- deberian aparecer en la tabla FACT_TABLE junto con los otros campos cuando
-- ejecute el SP

EXEC ej5_completar_Fac_table

-- Compruebo si aparecen esos valores en la tabla FACT_TABLE

SELECT * FROM FACT_TABLE
WHERE producto = '00001415' AND
mes = 6 AND
anio = 2012 AND
cliente = '00656' AND
zona = '004' AND
familia = '101' AND
rubro = '0010'

/*9. Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes*/
/* cuando tenemos que traajar con un update se trabaja asi, es separar en inserted y deleted*/
create trigger ej9 on item_factura for update 
AS
BEGIN 
	declare @producto char(8), @cantidad decimal(12,2), @componente char(8), @cantidad_componente decimal(12,2)

	declare c1 cursor for select i.item_producto, i.item_cantidad   from inserted i
	where i.item_producto in (select comp_producto from Composicion) 

	declare c3 cursor for select i.item_producto, i.item_cantidad   from deleted i 
	 where i.item_producto in (select comp_producto from Composicion) 

	open c1
	fetch next into @producto, @cantidad 
	declare c2 cursor for select comp_componente, comp_cantidad from composicion 
		where comp_producto = @producto 
	while @@FETCH_STATUS = 0
	BEGIN 
		open c2
		fetch next into @componente, @cantidad_componente
		while @@FETCH_STATUS = 0
		BEGIN 
			update stock set stoc_cantidad = stoc_cantidad - (@cantidad * @cantidad_componente)
			where stoc_producto = @componente and stoc_deposito = (select top 1 stoc_deposito from STOCK where stoc_producto = @componente)	
			fetch next into @componente, @cantidad_componente
		END 
		close c2
		fetch next into @producto, @cantidad 
	END

	open c3
	fetch next into @producto, @cantidad 
	while @@FETCH_STATUS = 0
	BEGIN 
		open c2
		fetch next into @componente, @cantidad_componente
		while @@FETCH_STATUS = 0
		BEGIN 
			update stock set stoc_cantidad = stoc_cantidad + (@cantidad * @cantidad_componente)
			where stoc_producto = @componente and stoc_deposito = (select top 1 stoc_deposito from STOCK where stoc_producto = @componente)	
			fetch next into @componente, @cantidad_componente
		END 
		close c2
		fetch next into @producto, @cantidad 
	END
	deallocate c2  
	close c3
	deallocate c3
	close c1 
	deallocate c1

END 