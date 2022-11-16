-- parcial 15-11-2022
-- PUNTO 1

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


-- PUNTO 2
drop trigger punto2
create trigger punto2 on item_factura for insert 
as 
begin 
	declare @producto char(8), @precio decimal(18,2), @fecha smalldatetime, @precioMesAnterior decimal(18,2), 
	@precioAnioAnterior decimal(18,2)
	declare C_VENTAS cursor for 
	select inserted.item_producto, inserted.item_precio, fact_fecha from inserted 
	join factura on inserted.item_tipo+inserted.item_sucursal+inserted.item_numero = fact_tipo+fact_sucursal+fact_numero

	open C_VENTAS 
	fetch next from C_VENTAS into @producto , @precio , @fecha 
	while @@FETCH_STATUS = 0
	begin
		
		set @precioMesAnterior  = (select item_precio from item_factura join factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
									where item_producto = @producto and month(fact_fecha) = (month(@fecha)-1))
		set @precioAnioAnterior = ( select item_precio from item_factura join factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
									where item_producto = @producto and year(fact_fecha) = (year(@fecha)-1))
		if((@precio > @precioMesAnterior) and (@precio < (@precioMesAnterior * 1.05)) and (@precio < @precioAnioAnterior * 1.50))
		begin	
			insert into item_Factura 
			select * from inserted 
			where item_producto = @producto	
		end
		else 
		begin
			RAISERROR('EL PRODUCTO %s NO PUEDE VENDERSE', 48,1, @producto)
		end 
		fetch next from C_VENTAS into @producto , @precio , @fecha 
	end
	close C_VENTAS
	deallocate C_VENTAS	
end
















