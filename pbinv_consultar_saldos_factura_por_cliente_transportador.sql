/****** Object:  StoredProcedure [dbo].[pbinv_consultar_saldos_factura]    Script Date: 09/04/2008 16:58:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter PROCEDURE [dbo].[pbinv_consultar_saldos_factura_por_cliente_transportador]

@fecha_disponible_distribuidora_inicial datetime,
@fecha_disponible_distribuidora_final datetime,
@idc_cliente_despacho nvarchar(20),
@idc_transportador nvarchar(20)

as

SELECT  
farm.id_farm, 
farm.idc_farm,
farm.nombre_farm,
tapa.id_tapa, 
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor, 
tipo_flor.idc_tipo_flor, 
tipo_flor.nombre_tipo_flor, 
variedad_flor.id_variedad_flor, 
variedad_flor.idc_variedad_flor, 
variedad_flor.nombre_variedad_flor, 
Color.id_color,
color.idc_color,
color.nombre_color,
color.prioridad_color,
grado_flor.id_grado_flor, 
grado_flor.idc_grado_flor, 
grado_flor.nombre_grado_flor, 
grado_flor.medidas, 
tipo_caja.id_tipo_caja, 
tipo_caja.idc_tipo_caja, 
tipo_caja.nombre_tipo_caja, 
Item_Inventario_Preventa.unidades_por_pieza, 
Detalle_Item_Inventario_Preventa.cantidad_piezas AS cantidad_piezas_inventario,
Item_Inventario_Preventa.unidades_por_pieza * Detalle_Item_Inventario_Preventa.cantidad_piezas as cantidad_unidades_inventario_total,
0 as cantidad_unidades_prebook_total,
Detalle_Item_Inventario_Preventa.cantidad_piezas_ofertadas_finca,
0 AS cantidad_piezas_prebook,
Item_Inventario_Preventa.marca, 
Item_Inventario_Preventa.precio_minimo, 
Detalle_Item_Inventario_Preventa.fecha_disponible_distribuidora,
null as id_vendedor, 
null as idc_vendedor, 
null as nombre_vendedor, 
null as id_cliente_factura,
null as idc_cliente_factura,
null as id_despacho, 
null as idc_cliente_despacho, 
null as nombre_cliente, 
null as id_transportador,
null as idc_transportador,
null as nombre_transportador,
'1' as tipo_orden,
null as id_orden_pedido,
null as idc_orden_pedido,
Item_Inventario_Preventa.id_item_inventario_preventa,
null as fecha_para_aprobar,
controla_saldos,
Item_Inventario_Preventa.empaque_principal,
null as comentario,
'' as numero_po into #temp
FROM         
Grado_Flor, 
Inventario_Preventa,
Item_Inventario_Preventa,     
Detalle_Item_Inventario_Preventa,     
Variedad_Flor,      
Tipo_Flor,               
Tipo_Caja,                
Farm,
Tapa,
Color
WHERE Inventario_Preventa.id_farm = Farm.id_farm
and Item_Inventario_Preventa.id_tipo_caja = Tipo_Caja.id_tipo_caja
and Item_Inventario_Preventa.id_tapa = Tapa.id_tapa
and Grado_Flor.id_grado_flor = Item_Inventario_Preventa.id_grado_flor
and Item_Inventario_Preventa.id_variedad_flor = Variedad_Flor.id_variedad_flor
and Grado_Flor.id_tipo_flor = Tipo_Flor.id_tipo_flor
and Variedad_Flor.id_tipo_flor = Tipo_Flor.id_tipo_flor 
and variedad_flor.id_color = color.id_color
and Inventario_Preventa.id_inventario_preventa = Item_Inventario_Preventa.id_inventario_preventa
and Item_Inventario_Preventa.id_item_inventario_preventa = Detalle_Item_Inventario_Preventa.id_item_inventario_preventa
and exists
(
	select * 
	from pantalla_saldo_cobol,
	item_inventario_preventa,
	inventario_preventa
	where pantalla_saldo_cobol.id_item_inventario_preventa = item_inventario_preventa.id_item_inventario_preventa
	and inventario_preventa.id_inventario_preventa = item_inventario_preventa.id_inventario_preventa
	and pantalla_saldo_cobol.idc_cliente_despacho = @idc_cliente_despacho
	and pantalla_saldo_cobol.idc_transportador = @idc_transportador
	and inventario_preventa.id_farm = farm.id_farm
	and item_inventario_preventa.id_tapa = tapa.id_tapa
	and item_inventario_preventa.id_variedad_flor = variedad_flor.id_variedad_flor
	and item_inventario_preventa.id_grado_flor = grado_flor.id_grado_flor
)
and Detalle_Item_Inventario_Preventa.fecha_disponible_distribuidora between
@fecha_disponible_distribuidora_inicial and @fecha_disponible_distribuidora_final
group by
farm.id_farm, 
farm.idc_farm,
farm.nombre_farm,
tapa.id_tapa, 
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor, 
tipo_flor.idc_tipo_flor, 
tipo_flor.nombre_tipo_flor, 
variedad_flor.id_variedad_flor, 
variedad_flor.idc_variedad_flor, 
variedad_flor.nombre_variedad_flor, 
Color.id_color,
color.idc_color,
color.nombre_color,
color.prioridad_color,
grado_flor.id_grado_flor, 
grado_flor.idc_grado_flor, 
grado_flor.nombre_grado_flor, 
grado_flor.medidas, 
tipo_caja.id_tipo_caja, 
tipo_caja.idc_tipo_caja, 
tipo_caja.nombre_tipo_caja, 
Item_Inventario_Preventa.unidades_por_pieza, 
Detalle_Item_Inventario_Preventa.cantidad_piezas,
Item_Inventario_Preventa.marca, 
Item_Inventario_Preventa.precio_minimo, 
Detalle_Item_Inventario_Preventa.fecha_disponible_distribuidora,
Item_Inventario_Preventa.id_item_inventario_preventa,
controla_saldos,
Detalle_Item_Inventario_Preventa.id_detalle_item_inventario_preventa,
Detalle_Item_Inventario_Preventa.cantidad_piezas_ofertadas_finca,
Item_Inventario_Preventa.empaque_principal

UNION

SELECT     
farm.id_farm, 
farm.idc_farm, 
farm.nombre_farm,	
tapa.id_tapa, 
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
tipo_flor.nombre_tipo_flor,
variedad_flor.id_variedad_flor, 
variedad_flor.idc_variedad_flor,
variedad_flor.nombre_variedad_flor,
Color.id_color,
color.idc_color,
color.nombre_color,
color.prioridad_color,
grado_flor.id_grado_flor, 
grado_flor.idc_grado_flor, 
grado_flor.nombre_grado_flor, 
grado_flor.medidas, 
tipo_caja.id_tipo_caja, 
tipo_caja.idc_tipo_caja,
tipo_caja.nombre_tipo_caja,
Orden_Pedido.unidades_por_pieza, 
0 AS cantidad_piezas_inventario,
0 as cantidad_unidades_inventario_total,
Orden_Pedido.unidades_por_pieza * orden_pedido.cantidad_piezas as cantidad_unidades_prebook_total,
0 as cantidad_piezas_ofertadas_finca,
orden_pedido.cantidad_piezas as cantidad_piezas_prebook, 
orden_pedido.marca, 
orden_pedido.valor_unitario,
case
	when Orden_Pedido.fecha_inicial = convert(datetime, '1999/01/01') then orden_pedido.fecha_para_aprobar
	else Orden_Pedido.fecha_inicial
end as fecha_disponible_distribuidora,
vendedor.id_vendedor, 
vendedor.idc_vendedor, 
vendedor.nombre as nombre_vendedor, 
cliente_factura.id_cliente_factura,
cliente_factura.idc_cliente_factura,
cliente_despacho.id_despacho, 
cliente_despacho.idc_cliente_despacho, 
cliente_despacho.nombre_cliente, 
transportador.id_transportador, 
transportador.idc_transportador,
transportador.nombre_transportador,
case
	when Orden_Pedido.fecha_inicial = convert(datetime, '1999/01/01') then '3'
	else '2'
end as tipo_orden,
orden_pedido.id_orden_pedido,
orden_pedido.idc_orden_pedido,
null as id_item_inventario_preventa,
orden_pedido.fecha_para_aprobar,
null as controla_saldos,
null as empaque_principal,
orden_pedido.comentario,
orden_pedido.numero_po
FROM         
Orden_Pedido, 
Variedad_Flor, 
Tipo_Flor, 
Grado_Flor, 
Tipo_Caja, 
Cliente_Despacho, 
Cliente_Factura, 
Vendedor,
Transportador,
Farm,
Tapa,
color,
orden_pedido as op
WHERE
(orden_pedido.fecha_inicial between
@fecha_disponible_distribuidora_inicial and @fecha_disponible_distribuidora_final
or
orden_pedido.fecha_para_aprobar between
@fecha_disponible_distribuidora_inicial and @fecha_disponible_distribuidora_final)
and Orden_Pedido.id_tapa = Tapa.id_tapa
and Orden_Pedido.id_farm = Farm.id_farm
and Orden_Pedido.id_tipo_caja = Tipo_Caja.id_tipo_caja
and Orden_Pedido.id_transportador = Transportador.id_transportador
and Cliente_Factura.id_vendedor = Vendedor.id_vendedor
and Cliente_Despacho.id_cliente_factura = Cliente_Factura.id_cliente_factura
and Orden_Pedido.id_despacho = Cliente_Despacho.id_despacho
and Orden_Pedido.id_tipo_caja = Tipo_Caja.id_tipo_caja
and Orden_Pedido.id_grado_flor = Grado_Flor.id_grado_flor 
and Tipo_Flor.id_tipo_flor = Grado_Flor.id_tipo_flor
and Orden_Pedido.id_variedad_flor = Variedad_Flor.id_variedad_flor
and Variedad_Flor.id_tipo_flor = Tipo_Flor.id_tipo_flor
and variedad_flor.id_color = color.id_color
and Orden_Pedido.id_tipo_factura = 2 
and Orden_Pedido.disponible = 1 
and Orden_Pedido.id_orden_pedido <= op.id_orden_pedido
and orden_pedido.id_orden_pedido_padre = op.id_orden_pedido_padre
and exists
(
	select * 
	from pantalla_saldo_cobol,
	item_inventario_preventa,
	inventario_preventa
	where pantalla_saldo_cobol.id_item_inventario_preventa = item_inventario_preventa.id_item_inventario_preventa
	and inventario_preventa.id_inventario_preventa = item_inventario_preventa.id_inventario_preventa
	and pantalla_saldo_cobol.idc_cliente_despacho = @idc_cliente_despacho
	and pantalla_saldo_cobol.idc_transportador = @idc_transportador
	and inventario_preventa.id_farm = farm.id_farm
	and item_inventario_preventa.id_tapa = tapa.id_tapa
	and item_inventario_preventa.id_variedad_flor = variedad_flor.id_variedad_flor
	and item_inventario_preventa.id_grado_flor = grado_flor.id_grado_flor
)
group by 
farm.id_farm, 
farm.idc_farm, 
farm.nombre_farm,	
tapa.id_tapa, 
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
tipo_flor.nombre_tipo_flor,
variedad_flor.id_variedad_flor, 
variedad_flor.idc_variedad_flor,
variedad_flor.nombre_variedad_flor,
Color.id_color,
color.idc_color,
color.nombre_color,
color.prioridad_color,
grado_flor.id_grado_flor, 
grado_flor.idc_grado_flor, 
grado_flor.nombre_grado_flor, 
grado_flor.medidas, 
tipo_caja.id_tipo_caja, 
tipo_caja.idc_tipo_caja,
tipo_caja.nombre_tipo_caja,
Orden_Pedido.unidades_por_pieza, 
orden_pedido.cantidad_piezas, 
orden_pedido.marca, 
orden_pedido.valor_unitario,
Orden_Pedido.fecha_inicial,
vendedor.id_vendedor, 
vendedor.idc_vendedor, 
vendedor.nombre, 
cliente_factura.id_cliente_factura,
cliente_factura.idc_cliente_factura,
cliente_despacho.id_despacho, 
cliente_despacho.idc_cliente_despacho, 
cliente_despacho.nombre_cliente, 
transportador.id_transportador, 
transportador.idc_transportador,
transportador.nombre_transportador,
orden_pedido.id_orden_pedido,
orden_pedido.idc_orden_pedido,
orden_pedido.fecha_para_aprobar,
orden_pedido.comentario,
orden_pedido.numero_po
having 
orden_pedido.id_orden_pedido = max(op.id_orden_pedido_padre)

alter table #temp
add inventario int,
saldo int

select id_farm,
id_variedad_flor,
id_grado_flor,
id_tapa,
sum(cantidad_unidades_inventario_total) as cantidad_unidades_inventario_total into #inventario
from #temp
where empaque_principal = 1
group by id_farm,
id_variedad_flor,
id_grado_flor,
id_tapa

select id_farm,
id_variedad_flor,
id_grado_flor,
id_tapa,
sum(cantidad_unidades_prebook_total) as cantidad_unidades_prebook_total into #preventa
from #temp
group by id_farm,
id_variedad_flor,
id_grado_flor,
id_tapa

update #temp 
set inventario = #inventario.cantidad_unidades_inventario_total / #temp.unidades_por_pieza
from #inventario
where #temp.id_farm = #inventario.id_farm
and #temp.id_variedad_flor = #inventario.id_variedad_flor
and #temp.id_grado_flor = #inventario.id_grado_flor
and #temp.id_tapa = #inventario.id_tapa

update #temp
set saldo = (#inventario.cantidad_unidades_inventario_total - #preventa.cantidad_unidades_prebook_total) / #temp.unidades_por_pieza
from #inventario,
#preventa
where #inventario.id_farm = #preventa.id_farm
and #inventario.id_variedad_flor = #preventa.id_variedad_flor
and #inventario.id_grado_flor = #preventa.id_grado_flor
and #inventario.id_tapa = #preventa.id_tapa
and #inventario.id_farm = #temp.id_farm
and #inventario.id_variedad_flor = #temp.id_variedad_flor
and #inventario.id_grado_flor = #temp.id_grado_flor
and #inventario.id_tapa = #temp.id_tapa

update #temp
set inventario = 0
where inventario is null

update #temp
set saldo = 0
where saldo is null

select *, 
cantidad_piezas_prebook as prebook 
from #temp
order by
idc_tipo_flor,
prioridad_color,
idc_variedad_flor,
idc_grado_flor,
tipo_orden,
fecha_disponible_distribuidora

delete from pantalla_saldo_cobol
where idc_cliente_despacho = @idc_cliente_despacho
and idc_transportador = @idc_transportador

drop table #temp
drop table #inventario
drop table #preventa

