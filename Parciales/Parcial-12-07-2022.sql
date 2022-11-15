-- PARCIAL 12/07/2022
select c.clie_razon_social, c.clie_domicilio, (select sum(i.item_cantidad) from factura f2
												join Item_Factura i on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero =
												 i.item_tipo+ i.item_sucursal+ i.item_numero
												 where f2.fact_cliente = f1.fact_cliente)
 from Factura f1 
join Cliente c on c.clie_codigo = f1.fact_cliente
group by f1.fact_cliente ,year(f1.fact_fecha), c.clie_razon_social, c.clie_domicilio
having f1.fact_cliente in (select top 1 f2.fact_cliente from factura f2
							where year(f2.fact_fecha) = year (f1.fact_fecha)
							group by f2.fact_cliente
							order by sum(f2.fact_total)desc)
						and
		f1.fact_cliente in  (select top 1 f2.fact_cliente from factura f2
							where year(f2.fact_fecha) = year (f1.fact_fecha)+1
							group by f2.fact_cliente
							order by sum(f2.fact_total)desc)

-- P U N T O 2 

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