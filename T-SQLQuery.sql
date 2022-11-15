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

/*7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock realizados entre
esas fechas. La tabla se encuentra creada y vacía.*/
create table VENTAS(
	codigo  char(8),
	detalle char(50),
	cant_mov int,
	precio_de_venta  decimal(18,2),
	renglon int,
	ganancia decimal(18,2)
	)
create procedure ej7(@fecha1 smalldatetime, @fecha2 smalldatetime)
as 
begin 
	declare @codigo char(8),@producto char(50),@movimiento int,@precio decimal(18,2), @ganancia decimal(18,2), @renglon int
	declare C_VENTAS cursor for 
		select prod_codigo, prod_detalle, count(item_producto),AVG(item_precio), 
		sum(item_cantidad* item_precio) - sum(item_cantidad* item_precio) from producto 
		JOIN Item_Factura ON prod_codigo = item_producto
		JOIN Factura ON item_numero + item_sucursal + item_tipo =
		fact_numero + fact_sucursal + fact_tipo
		WHERE fact_fecha BETWEEN @FECHA1 AND @FECHA2
		GROUP BY prod_codigo, prod_detalle

		open C_VENTAS
			fetch next from C_VENTAS into @codigo,@producto,@movimiento,@precio, @ganancia 
			SET @renglon = 0
			while @@FETCH_STATUS = 0
				begin
					insert into ventas VALUES (@codigo,@producto,@movimiento,@precio,@renglon,@ganancia)
					set @renglon = @renglon +1
					fetch next from C_VENTAS into @codigo,@producto,@movimiento,@precio, @ganancia 
				end
			close c_ventas 
			deallocate c_ventas
end 

exec ej7 '2012-01-01', '2012-06-01' 

--COMPRUEBO 
SELECT * FROM VENTAS where codigo = '00001415'

/* EJ.8 Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por cantidad
de sus componentes, se aclara que un producto que compone a otro, también puede
estar compuesto por otros y así sucesivamente, la tabla se debe crear y está formada
por las siguientes columnas: 
*/
CREATE TABLE DIFERENCIAS ( 
	dif_codigo char(8),
	dif_detalle char(50),
	dif_cantidad NUMERIC(6,0),
	dif_precio_generado DECIMAL(12,2),
	dif_precio_facturado DECIMAL(12,2),
)
GO

CREATE FUNCTION FX_PRODUCTO_COMPUESTO_PRECIO(@PRODUCTO CHAR(8))
	RETURNS DECIMAL(12,2)
AS
BEGIN
	DECLARE @PRECIO DECIMAL(12,2)
	
	SET @PRECIO =
	(SELECT sum(comp_cantidad* prod_precio) from composicion 
	join producto on comp_componente = prod_codigo
	 where comp_producto = @producto group by comp_producto)

	IF @PRECIO IS NULL
		SET @PRECIO = 
		(SELECT prod_precio 
		FROM Producto 
		WHERE prod_codigo = @PRODUCTO)
	
	RETURN @PRECIO
END
GO


CREATE PROCEDURE ej_8
AS
BEGIN
	INSERT INTO DIFERENCIAS
	SELECT 
	prod_codigo,
	prod_detalle,
	count(distinct comp_componente),
	dbo.FX_PRODUCTO_COMPUESTO_PRECIO(prod_codigo),
	prod_precio
	from producto join composicion on prod_codigo = comp_producto 
	group by prod_codigo, prod_detalle, prod_precio

END
GO

--PRUEBA

-- Elijo un producto compuesto como por ejemplo el 00001707 y veo que tiene
-- un precio facturado de 27.20

SELECT *
FROM Producto
WHERE prod_codigo = '00001707'

-- El producto 00001707 esta compuesto por dos 2 productos, 1 unidad del 00001491 y 
-- 2 unidades del 00014003 

SELECT * 
FROM Composicion
JOIN Producto ON comp_componente = prod_codigo
WHERE comp_producto = '00001707'

-- Como los dos productos que componen al 00001707 no son compuestos solo hay que
-- sumar sus costos para obtener el costo del producto 00001707, haciendo la cuenta
-- me da que el costo de 00001707 es de 27.62 ya que el costo del producto 00001491 es
-- de 15.92 (15.92 * 1) y el costo del producto 00014003 es de 11.7 (5.85 * 2).
-- Ejecuto el SP para completar la tabla de DIFERENCIAS

EXEC ej_8

-- Por lo tanto en la tabla DIFERENCIAS en la columna de productos que lo componen 
-- deberia figurar un 2 para el producto 00001707, un precio generado de 27.62 y un
-- precio facturado de 27.20

SELECT *
FROM DIFERENCIAS


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


/*12. Cree el/los objetos de base de datos necesarios para que nunca un producto pueda
ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se cumple y
que la base de datos es accedida por n aplicaciones de diferentes tipos y tecnologías.
No se conoce la cantidad de niveles de composición existentes.*/

create trigger ej12 on composicion  instead of insert, update
as
begin
	declare @prod_nuevo char(8), @comp_Nuevo char(8)

	declare C_COMPOSICION cursor for 
	select inserted.comp_producto, inserted.comp_componente from inserted 

	open C_COMPOSICION
	fetch next from C_COMPOSICION INTO  @prod_nuevo,@comp_Nuevo
	WHILE @@FETCH_STATUS = 0 
	BEGIN 
		IF @prod_nuevo<>@comp_Nuevo
		BEGIN
			insert into composicion 
			select * from inserted 
			where comp_producto = @prod_nuevo and comp_componente = @comp_Nuevo
		end
		ELSE
			RAISERROR('EL PRODUCTO %s NO PUEDE ESTAR COMPUESTO POR SI MISMO', 16, 1, @prod_nuevo)
			fetch next from C_COMPOSICION INTO  @prod_nuevo,@comp_Nuevo
	end
	close C_COMPOSICION
	deallocate C_COMPOSICION
end	
--PRUEBA

-- Elijo un producto compuesto como por ejemplo el producto 00001707 esta compuesto 
-- por dos 2 productos, el producto 00001491 y el 00014003 

SELECT * 
FROM Composicion
WHERE comp_producto = '00001707'

-- Primero pruebo con intentar insertar el producto 00001707 como componente
-- de si mismo, no me deberia dejar ya que no puede estar compuesto por si mismo 

INSERT INTO Composicion VALUES (2, '00001707', '00001707')

-- Compruebo que no se haya insertado el componente

SELECT * FROM Composicion WHERE comp_producto = '00001707'

-- Ahora pruebo con intentar insertar un componente distinto a si mismo 
-- para el producto 00001707 lo cual me deberia dejar hacer 

INSERT INTO Composicion VALUES (2, '00001707', '00001708')

-- Compruebo que se haya insertado el componente

SELECT * FROM Composicion WHERE comp_producto = '00001707'

-- Borro el componente de prueba

DELETE FROM Composicion 
WHERE comp_producto = '00001707' 
AND comp_componente = '00001708'

/*14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes que
imprima la fecha, que cliente, que productos y a qué precio se realizó la compra.
No se deberá permitir que dicho precio sea menor a la mitad de la suma de los
componentes.*/ 
create trigger ej14 on item_factura instead of insert
as 
begin 
	declare C_VENTA cursor for 

	select fact_fecha,fact_cliente,inserted.item_producto, inserted.item_precio/inserted.item_cantidad, dbo.FX_PRODUCTO_COMPUESTO_PRECIO(inserted.item_producto) from inserted 
	join factura on inserted.item_tipo+inserted.item_sucursal+inserted.item_numero = fact_tipo+fact_sucursal+fact_numero
	declare @producto char(8), @precio_vendido decimal(18,2), @precio_Compuesto decimal(18,2), @fecha smalldatetime, @cliente char(6)
	
	open C_VENTA 
	fetch next from C_VENTA into @fecha, @cliente, @producto, @precio_vendido, @precio_Compuesto 
	while @@FETCH_STATUS = 0
	begin 
		if(@precio_vendido < (@precio_Compuesto/2))
			RAISERROR('EL PRODUCTO %s NO PUEDE VENDERSE', 16, 11, @producto)
		else 
			begin 
				insert into item_Factura 
				select * from inserted 
				where item_producto = @producto
				if(@precio_vendido < @precio_compuesto)
					print 'fecha'+@fecha+'cliente'+@cliente+'producto'+@producto+'precio'+@precio_vendido
			end 
	fetch next from C_VENTA into @producto, @precio_vendido, @precio_Compuesto 
	end
	close C_VENTA 
	deallocate C_VENTA 
end

/*16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran del
deposito que mas producto poseea y se supone que el stock se almacena tanto de
productos simples como compuestos (si se acaba el stock de los compuestos no se
arman combos)
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo en
el ultimo deposito que se desconto. */

create function esProducto_Compuesto(@producto char(8))
	returns int
as 
begin 
declare @retorno int
if((select comp_producto from Composicion where comp_producto = @producto group by comp_producto) is not null)
	set @retorno = 0 -- es compuesto
else 
	set @retorno = 1 -- no es compuesto
return @retorno
end
go

create trigger ej16 on item_factura for insert 
as 
begin 
	declare @Producto char(8), @Cantidad decimal(12,2),@Comp char(8), @Cantidad_comp decimal(12,2)
	declare C_VENTA cursor for 
	select i.item_Producto, i.Item_Cantidad from inserted i 

	open C_VENTA 
		fetch next from C_VENTA into @Producto, @Cantidad
		while @@FETCH_STATUS = 0
		begin
			if(dbo.esProducto_Compuesto(@producto))= 0
			begin
				declare C_COMPOSICION cursor for 
				select comp_componente, comp_cantidad from composicion where comp_producto= @Producto
				open C_COMPOSICION 
				fetch next from C_COMPOSICION into @Comp, @Cantidad_comp
				while @@FETCH_STATUS = 0
					begin 
						declare @depo decimal(12,2), @Canti_deposito decimal(12,2)
						declare @cantidad_A_Descontar decimal(12,2) = @Cantidad * @Cantidad_comp
						declare C_STOCK cursor for select stoc_deposito, stoc_cantidad
														from stock 
														where stoc_producto = @Comp 
														order by stoc_cantidad desc
						open C_STOCK 
						fetch next from C_STOCK into @depo, @Canti_deposito 
						while @@FETCH_STATUS = 0 and @cantidad_A_Descontar<>0 
						begin 
							if @Canti_deposito>= @cantidad_A_Descontar 
							begin 
								update STOCK set stoc_cantidad = stoc_cantidad - @cantidad_A_Descontar
								where stoc_deposito = @depo and stoc_producto = @comp
								set @cantidad_A_Descontar = 0
							end 	
							if @Canti_deposito < @cantidad_A_Descontar
							begin 
								set @cantidad_A_Descontar -= @Canti_deposito
								update STOCK set stoc_cantidad = 0
								where stoc_deposito = @depo and stoc_producto = @comp
							end 
							declare @depoant decimal(12,2) = @depo
						fetch next from C_STOCK into @depo, @Canti_deposito 
						end
						close C_STOCK
						deallocate C_STOCK
						if @cantidad_A_Descontar <>0 
							begin
							update STOCK set stoc_cantidad = stoc_cantidad - @cantidad_A_Descontar
							where stoc_deposito = @depoant and stoc_producto = @comp
							end
					fetch next from C_COMPOSICION into @Comp, @Cantidad_comp			 
					end
					close C_COMPOSICION
					deallocate C_COMPOSICION
			end 
			else 
			begin 
				declare @cant_a_descontar_simple  decimal(12,2) = @Cantidad 
					declare C_STOCK cursor for select stoc_deposito, stoc_cantidad
														from stock 
														where stoc_producto = @producto 
														order by stoc_cantidad desc
						open C_STOCK 
						fetch next from C_STOCK into @depo, @Canti_deposito 
						while @@FETCH_STATUS = 0 and @cant_a_descontar_simple<>0 
						begin 
							if  @Canti_deposito >= @cant_a_descontar_simple
							begin 
								update STOCK set stoc_cantidad = stoc_cantidad - @cant_a_descontar_simple
								where stoc_deposito = @depo and stoc_producto = @Producto
								set @cant_a_descontar_simple = 0
							end 	
							if @Canti_deposito < @cant_a_descontar_simple
							begin 
								set @cant_a_descontar_simple -= @Canti_deposito
								update STOCK set stoc_cantidad = 0
								where stoc_deposito = @depo and stoc_producto = @Producto
							end 
							declare @depoant2 decimal(12,2) = @depo
						fetch next from C_STOCK into @depo, @Canti_deposito 
						end
						close C_STOCK
						deallocate C_STOCK
						if @cant_a_descontar_simple <>0 
							begin
							update STOCK set stoc_cantidad = stoc_cantidad - @cant_a_descontar_simple
							where stoc_deposito = @depoant2 and stoc_producto = @Producto
							end
			end
		close C_VENTA
		deallocate C_VENTA
		end
end
-- PRUEBA 

select * from item_factura WHERE item_producto = '00001707'
insert into item_factura values ('A','003','00093121','00001707','2.00','0.57')
