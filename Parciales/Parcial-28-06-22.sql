--PARCIAL- 28/06/2022
-- P U N T O 1 
select ifc.item_producto, pc.prod_detalle, count(distinct ifc.item_tipo+ifc.item_sucursal+ifc.item_numero),
count(distinct ifp.item_tipo+ifp.item_sucursal+ifp.item_numero),
count(distinct ifp.item_producto) from item_factura ifc
join producto pc on pc.prod_codigo = ifc.item_producto
join composicion cc on ifc.item_producto = cc.comp_componente
join item_factura ifp on ifp.item_producto = cc.comp_producto
group by ifc.item_producto, pc.prod_detalle
order by 3 desc

-- P U N T O 2 
/*
Implementar el/los objetos necesarios para poder registrar cuáles son los productos que requieren reponer su stock. 
Como tarea preventiva, semanalmente se analizará esta información para que la falta de stock no sea una traba 
al momento de realizar una venta.
Esto se calcula teniendo en cuenta el stoc punto_reposicion, es decir, si éste supera en un 10% al stoc_cantidad 
deberá registrarse el producto y la cantidad a reponer.
Considerar que la cantidad a reponer no debe ser mayor a stoc_stock_maximo (cant_reponer es stoc_stock_maximo - stoc_cantidad)
*/

create procedure ejParcial
as 
begin 
	if exists(select * from stock where stoc_punto_reposicion >= 1.10 * stoc_cantidad) 
	begin 
		declare @producto char(8), @depo char(2), @cant_a_reponer decimal(18,2)
		declare C_STOCK cursor for select stoc_producto, stoc_deposito from stock 
																		where stoc_punto_reposicion >= 1.10 * stoc_cantidad
		open C_STOCK
		fetch next from C_STOCK into @producto, @depo 
		while @@FETCH_STATUS = 0
			begin 
				set @cant_a_reponer = (select (stoc_stock_maximo - stoc_cantidad) from stock where stoc_producto = @producto and stoc_deposito = @depo)
				print 'EL PRODUCTO:'+ @producto+ ', necesita reponer: ' + str(@cant_a_reponer) + ', en el deposito:' + @depo
				fetch next from C_STOCK into @producto, @depo 
			end
			close C_STOCK
			deallocate C_STOCK
	end
   
end 
--PRUEBA
EXEC ejParcial 
		






