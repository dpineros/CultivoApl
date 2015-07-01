alter PROCEDURE [dbo].[pbinv_consultar_inventario_pantalla_inventario_cobol]

@fecha_disponible_distribuidora_inicial datetime,
@fecha_disponible_distribuidora_final datetime,
@usuario_cobol nvarchar(255)

AS

declare @nombre_base_datos nvarchar(255)
set @nombre_base_datos = DB_NAME()

select item_inventario_preventa.id_item_inventario_preventa,
Tapa.id_tapa,
Tapa.idc_tapa,
Tapa.nombre_tapa,
Tipo_Caja.id_tipo_caja,
Tipo_Caja.idc_tipo_caja,
Tipo_Caja.nombre_tipo_caja,
Tipo_Flor.id_tipo_flor,
Tipo_Flor.idc_tipo_flor,
Tipo_FLor.nombre_tipo_flor,
Variedad_Flor.id_variedad_flor,
Variedad_Flor.idc_variedad_flor,
Variedad_Flor.nombre_variedad_flor,
Color.idc_color,
Color.nombre_color,
Color.prioridad_color,
Grado_Flor.id_grado_flor,
Grado_Flor.idc_grado_flor,
Grado_Flor.nombre_grado_flor,
Grado_Flor.medidas,
Farm.id_farm,
Farm.idc_farm,
Farm.nombre_farm,
item_inventario_preventa.unidades_por_pieza, 
marca,
item_inventario_preventa.precio_minimo, 
item_inventario_preventa.precio_finca, 
detalle_item_inventario_preventa.fecha_disponible_distribuidora,
item_inventario_preventa.controla_saldos, 
item_inventario_preventa.empaque_principal,
sum(detalle_item_inventario_preventa.cantidad_piezas) as cantidad_piezas,
sum(detalle_item_inventario_preventa.cantidad_piezas_adicionales_finca) as cantidad_piezas_adicionales_finca,
sum(detalle_item_inventario_preventa.cantidad_piezas_ofertadas_finca) as cantidad_piezas_ofertadas_finca into #temp_preventas
from detalle_item_inventario_preventa, 
item_inventario_preventa, 
Inventario_Preventa, 
Tapa, 
Variedad_Flor, 
Grado_Flor, 
Tipo_Flor, 
Farm, 
Tipo_Caja,
Color
where detalle_item_inventario_preventa.id_item_inventario_preventa = item_inventario_preventa.id_item_inventario_preventa
and Inventario_Preventa.id_inventario_preventa = Item_Inventario_Preventa.id_inventario_preventa
and detalle_item_inventario_preventa.fecha_disponible_distribuidora between
@fecha_disponible_distribuidora_inicial and @fecha_disponible_distribuidora_final
and Inventario_Preventa.id_farm = farm.id_farm
and Item_Inventario_Preventa.id_tapa = Tapa.id_tapa
and Item_Inventario_Preventa.id_tipo_caja = Tipo_Caja.id_tipo_caja
and Item_Inventario_Preventa.id_variedad_flor = Variedad_Flor.id_variedad_flor
and Item_Inventario_Preventa.id_grado_flor = Grado_Flor.id_grado_flor
and Variedad_Flor.id_tipo_flor = Tipo_Flor.id_tipo_flor
and variedad_flor.id_color = color.id_color
and Grado_Flor.id_tipo_flor = Tipo_Flor.id_tipo_flor
and exists
(
	select *
	from Pantalla_Inventario_Cobol
	where Pantalla_Inventario_Cobol.id_item_inventario_preventa = item_inventario_preventa.id_item_inventario_preventa
	and detalle_item_inventario_preventa.fecha_disponible_distribuidora = Pantalla_Inventario_Cobol.fecha
	and Pantalla_Inventario_Cobol.usuario_cobol = @usuario_cobol
	and Pantalla_Inventario_Cobol.fecha = @fecha_disponible_distribuidora_inicial
)
group by item_inventario_preventa.id_item_inventario_preventa,
Tapa.id_tapa,
Tapa.idc_tapa,
Tapa.nombre_tapa,
Tipo_Caja.id_tipo_caja,
Tipo_Caja.idc_tipo_caja,
Tipo_Caja.nombre_tipo_caja,
Tipo_Flor.id_tipo_flor,
Tipo_Flor.idc_tipo_flor,
Tipo_FLor.nombre_tipo_flor,
Variedad_Flor.id_variedad_flor,
Variedad_Flor.idc_variedad_flor,
Variedad_Flor.nombre_variedad_flor,
Color.idc_color,
Color.nombre_color,
Color.prioridad_color,
Grado_Flor.id_grado_flor,
Grado_Flor.idc_grado_flor,
Grado_Flor.nombre_grado_flor,
Grado_Flor.medidas,
Farm.id_farm,
Farm.idc_farm,
Farm.nombre_farm,
item_inventario_preventa.unidades_por_pieza, 
marca,
item_inventario_preventa.precio_minimo, 
item_inventario_preventa.precio_finca, 
detalle_item_inventario_preventa.fecha_disponible_distribuidora,
item_inventario_preventa.controla_saldos, 
item_inventario_preventa.empaque_principal

select id_tapa,
id_variedad_flor,
id_grado_flor,
id_farm,
sum(cantidad_piezas) as cantidad_piezas into #temp_orden_pedido
from orden_pedido
where id_tipo_factura = 2
and fecha_inicial between
@fecha_disponible_distribuidora_inicial and @fecha_disponible_distribuidora_final
and disponible = 1
group by id_tapa,
id_variedad_flor,
id_grado_flor,
id_farm

select id_variedad_flor,
id_grado_flor,
id_farm,
sum(cantidad_piezas) as cantidad_piezas into #temp_orden_pedido_sin_tapa
from orden_pedido
where id_tipo_factura = 2
and fecha_inicial between
@fecha_disponible_distribuidora_inicial and @fecha_disponible_distribuidora_final
and disponible = 1
group by id_variedad_flor,
id_grado_flor,
id_farm

alter table #temp_preventas
add saldo int,
inventario int,
facturado int

select #temp_preventas.id_variedad_flor,
#temp_preventas.id_grado_flor,
#temp_preventas.id_farm,
sum(#temp_preventas.cantidad_piezas) as cantidad_piezas into #preventas_sin_tapa
from #temp_preventas


select #temp_preventas.id_variedad_flor,
#temp_preventas.id_grado_flor,
#temp_preventas.id_farm,
#temp_preventas.id_tapa,
sum(#temp_preventas.cantidad_piezas) as cantidad_piezas into #preventas_con_tapa
from #temp_preventas

if(@nombre_base_datos = 'BD_NF')
begin
	update #temp_preventas
	set inventario = #preventas_sin_tapa.cantidad_piezas
	from #preventas_sin_tapa
	where  #temp_preventas.id_variedad_flor = #preventas_sin_tapa.id_variedad_flor
	and #temp_preventas.id_grado_flor = #preventas_sin_tapa.id_grado_flor
	and #temp_preventas.id_farm = #preventas_sin_tapa.id_farm
	and #temp_preventas.idc_farm = 'N4'

	update #temp_preventas
	set saldo = #temp_preventas.inventario - isnull(#temp_orden_pedido_sin_tapa.cantidad_piezas, 0),
	inventario = #temp_preventas.inventario,
	facturado = isnull(#temp_orden_pedido_sin_tapa.cantidad_piezas, 0)
	from #temp_orden_pedido_sin_tapa
	where  #temp_preventas.id_variedad_flor = #temp_orden_pedido_sin_tapa.id_variedad_flor
	and #temp_preventas.id_grado_flor = #temp_orden_pedido_sin_tapa.id_grado_flor
	and #temp_preventas.id_farm = #temp_orden_pedido_sin_tapa.id_farm
	and #temp_preventas.idc_farm = 'N4'
end

update #temp_preventas
set inventario = #preventas_con_tapa.cantidad_piezas
from #preventas_con_tapa
where  #temp_preventas.id_variedad_flor = #preventas_con_tapa.id_variedad_flor
and #temp_preventas.id_grado_flor = #preventas_con_tapa.id_grado_flor
and #temp_preventas.id_farm = #preventas_con_tapa.id_farm
and #temp_preventas.id_tapa = #preventas_con_tapa.id_tapa
and #temp_preventas.idc_farm <> 'N4'

update #temp_preventas
set saldo = #temp_preventas.inventario - isnull(#temp_orden_pedido.cantidad_piezas, 0),
inventario = #temp_preventas.inventario,
facturado = isnull(#temp_orden_pedido.cantidad_piezas, 0)
from #temp_orden_pedido
where #temp_preventas.id_tapa = #temp_orden_pedido.id_tapa
and #temp_preventas.id_variedad_flor = #temp_orden_pedido.id_variedad_flor
and #temp_preventas.id_grado_flor = #temp_orden_pedido.id_grado_flor
and #temp_preventas.id_farm = #temp_orden_pedido.id_farm
and #temp_preventas.idc_farm <> 'N4'

select id_item_inventario_preventa,
id_tapa,
idc_tapa,
nombre_tapa,
id_tipo_caja,
idc_tipo_caja,
nombre_tipo_caja,
id_tipo_flor,
idc_tipo_flor,
nombre_tipo_flor,
id_variedad_flor,
idc_variedad_flor,
nombre_variedad_flor,
idc_color,
nombre_color,
prioridad_color,
id_grado_flor,
idc_grado_flor,
nombre_grado_flor,
medidas,
id_farm,
idc_farm,
nombre_farm,
unidades_por_pieza, 
marca,
isnull(precio_minimo, 0) as precio_minimo, 
fecha_disponible_distribuidora,
controla_saldos, 
cantidad_piezas,
cantidad_piezas_ofertadas_finca,
cantidad_piezas_adicionales_finca,
isnull(precio_finca, 0) as precio_finca,
empaque_principal,
case
	when saldo is null then cantidad_piezas
	else saldo
end as saldo,
case
	when facturado is null then 0
	else facturado
end as facturado,
case
	when inventario is null then cantidad_piezas
	else inventario
end as inventario
from #temp_preventas
order by idc_farm,
nombre_tipo_flor,
nombre_variedad_flor,
idc_grado_flor

drop table #temp_preventas
drop table #temp_orden_pedido
drop table #temp_orden_pedido_sin_tapa
drop table #preventas_con_tapa
drop table #preventas_sin_tapa

delete from Pantalla_Inventario_Cobol
where fecha = @fecha_disponible_distribuidora_inicial
and usuario_cobol = @usuario_cobol