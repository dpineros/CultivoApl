set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

alter PROCEDURE [dbo].[preorden_consultar_orden_pedido_special_order_detalle]

@fecha datetime,
@idc_transportador nvarchar(10),
@idc_cliente_despacho nvarchar(15),
@numero_po nvarchar(50)

as

/*Declaracion de variables globales*/
declare @estado_inventario int,
@estado_prevendido int,
@estado_orden_sin_aprobar_not_sent_to_farm int,
@estado_orden_sin_aprobar_no_farm_confirmed int,
@estado_prevendido_sin_confirmar int,
@nombre_base_datos nvarchar(255),
@id_tapa int,
@idc_tapa nvarchar(3),
@nombre_tapa nvarchar(20),
@fecha_inicial datetime,
@fecha_final datetime

select @fecha_inicial = temporada_cubo.fecha_inicial,
@fecha_final = temporada_cubo.fecha_final
from temporada,
a�o,
temporada_a�o,
temporada_cubo
where temporada.id_temporada = temporada_a�o.id_temporada
and a�o.id_a�o = temporada_a�o.id_a�o
and temporada.id_temporada = temporada_cubo.id_temporada
and a�o.id_a�o = temporada_cubo.id_a�o
and @fecha between
temporada_cubo.fecha_inicial and temporada_cubo.fecha_final

/*adquirir el nombre de la base de datos sobre la cual se trabajar�*/
set @nombre_base_datos = DB_NAME()

/*Si se trabaja sobre Natural, se extraer� la tapa a trav�s del grupo de clientes*/
if(@nombre_base_datos = 'BD_NF')
begin
	select @id_tapa = tapa.id_tapa,
	@idc_tapa = tapa.idc_tapa,
	@nombre_tapa = tapa.nombre_tapa    
	from grupo_cliente_factura,
	cliente_factura,
	cliente_despacho,
	tapa
	where grupo_cliente_factura.id_grupo_cliente_factura = cliente_factura.id_grupo_cliente_factura
	and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
	and tapa.id_tapa = grupo_cliente_factura.id_tapa
	and ltrim(rtrim(cliente_despacho.idc_cliente_despacho)) = ltrim(rtrim(@idc_cliente_despacho))
end

/*Asignar el nombre de los diferentes estados que se manejar�n*/
set @estado_inventario = 1
set @estado_prevendido = 4
set @estado_prevendido_sin_confirmar = 3
set @estado_orden_sin_aprobar_not_sent_to_farm = 5
set @estado_orden_sin_aprobar_no_farm_confirmed = 6

/*Extraer las �ltimas versiones de las ordenes de pedido*/
select max(id_orden_pedido) as id_orden_pedido into #ordenes
from orden_pedido
where exists
(
	select *
	from orden_especial_confirmada
	where orden_especial_confirmada.id_orden_pedido = orden_pedido.id_orden_pedido
)
group by id_orden_pedido_padre

/*Extraer las �ltimas versiones de las ordenes sin aprobar*/
select max(id_item_orden_sin_aprobar) as id_item_orden_sin_aprobar into #orden_sin_confirmar
from item_orden_sin_aprobar
group by id_item_orden_sin_aprobar_padre

/*crear tabla de inventarios sobre la cual se realizar�n la mayor�a de los c�lculos*/
create table #inventario
(
	id int identity (1,1),
	id_farm int, 
	idc_farm nvarchar(10), 
	nombre_farm nvarchar(50), 
	id_tapa int, 
	idc_tapa nvarchar(10), 
	nombre_tapa nvarchar(50), 
	id_tipo_flor int, 
	idc_tipo_flor nvarchar(10), 
	nombre_tipo_flor nvarchar(50), 
	id_variedad_flor int, 
	idc_variedad_flor nvarchar(10), 
	nombre_variedad_flor nvarchar(50), 
	id_grado_flor int, 
	idc_grado_flor nvarchar(10), 
	nombre_grado_flor nvarchar(50), 
	id_tipo_caja int, 
	idc_tipo_caja nvarchar(10), 
	nombre_tipo_caja nvarchar(50), 
	marca nvarchar(10), 
	empaque_principal bit null, 
	unidades_por_pieza int, 
	precio_minimo decimal(20,4) null, 
	estado nvarchar(50), 
	piezas_inventario int null, 
	saldo int null,
	piezas_prevendidas int null, 
	valor_unitario decimal(20,4) null,
	id_orden_especial_confirmada int null,
	medidas_grado_flor nvarchar(50) null,
	idc_color nvarchar(10) null,
	prioridad_color int null,
	nombre_color nvarchar(50) null,
	id_item_inventario_preventa int null,
	id_orden_pedido int null,
	idc_orden_pedido nvarchar(20) null,
	controla_saldos bit null,
	fecha_para_aprobar datetime null,
	idc_transportador nvarchar(10) null,
	idc_cliente_despacho nvarchar(15) null,
	numero_po nvarchar(50) null,
	comentario nvarchar(512) null
)

/*Extraer las �rdenes de pedido*/
insert into #inventario 
(
	id_farm, 
	idc_farm, 
	nombre_farm, 
	id_tapa, 
	idc_tapa, 
	nombre_tapa, 
	id_tipo_flor, 
	idc_tipo_flor, 
	nombre_tipo_flor, 
	id_variedad_flor, 
	idc_variedad_flor, 
	nombre_variedad_flor, 
	id_grado_flor, 
	idc_grado_flor, 
	nombre_grado_flor, 
	id_tipo_caja, 
	idc_tipo_caja, 
	nombre_tipo_caja, 
	marca, 
	unidades_por_pieza, 
	valor_unitario, 
	estado, 
	piezas_prevendidas, 
	id_orden_especial_confirmada,
	medidas_grado_flor,
	idc_color,
	prioridad_color,
	nombre_color,
	id_orden_pedido,
	idc_orden_pedido,
	fecha_para_aprobar,
	idc_transportador,
	idc_cliente_despacho,
	numero_po,
	comentario
)
select farm.id_farm,
farm.idc_farm,
ltrim(rtrim(farm.nombre_farm)) as nombre_farm,
tapa.id_tapa,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)) as nombre_tipo_flor,
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)) as nombre_variedad_flor,
grado_flor.id_grado_flor,
grado_flor.idc_grado_flor,
ltrim(rtrim(grado_flor.nombre_grado_flor)) as nombre_grado_flor,
tipo_caja.id_tipo_caja,
tipo_caja.idc_tipo_caja,
ltrim(rtrim(tipo_caja.nombre_tipo_caja)) as nombre_tipo_caja,
orden_pedido.marca,
orden_pedido.unidades_por_pieza,
orden_pedido.valor_unitario,
@estado_prevendido as estado,
sum(orden_pedido.cantidad_piezas) as piezas_prevendidas,
null,
grado_flor.medidas,
color.idc_color,
color.prioridad_color,
ltrim(rtrim(color.nombre_color)) as nombre_color,
orden_pedido.id_orden_pedido,
orden_pedido.idc_orden_pedido,
orden_pedido.fecha_para_aprobar,
transportador.idc_transportador,
cliente_despacho.idc_cliente_despacho,
orden_pedido.numero_po,
orden_pedido.comentario
from orden_pedido,
transportador,
tipo_factura,
cliente_despacho,
farm,
tapa,
tipo_flor,
variedad_flor,
grado_flor,
color,
tipo_caja
where color.id_color = variedad_flor.id_color
and orden_pedido.fecha_inicial = @fecha
and farm.id_farm = orden_pedido.id_farm 
and tapa.id_tapa = orden_pedido.id_tapa
and tipo_flor.id_tipo_flor = variedad_flor.id_tipo_flor
and tipo_flor.id_tipo_flor = grado_flor.id_tipo_flor
and variedad_flor.id_variedad_flor = orden_pedido.id_variedad_flor
and grado_flor.id_grado_flor = orden_pedido.id_grado_flor
and tipo_caja.id_tipo_caja = orden_pedido.id_tipo_caja
and tipo_factura.id_tipo_factura = orden_pedido.id_tipo_factura
and tipo_factura.idc_tipo_factura = '4'
and orden_pedido.disponible = 1
and exists
(
	select *
	from #ordenes
	where #ordenes.id_orden_pedido = orden_pedido.id_orden_pedido
)
and transportador.id_transportador = orden_pedido.id_transportador
and cliente_despacho.id_despacho = orden_pedido.id_despacho
group by farm.id_farm,
farm.idc_farm,
ltrim(rtrim(farm.nombre_farm)),
tapa.id_tapa,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)),
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)),
grado_flor.id_grado_flor,
grado_flor.idc_grado_flor,
ltrim(rtrim(grado_flor.nombre_grado_flor)),
tipo_caja.id_tipo_caja,
tipo_caja.idc_tipo_caja,
ltrim(rtrim(tipo_caja.nombre_tipo_caja)),
orden_pedido.marca,
orden_pedido.unidades_por_pieza,
orden_pedido.valor_unitario,
grado_flor.medidas,
color.idc_color,
color.prioridad_color,
ltrim(rtrim(color.nombre_color)),
orden_pedido.id_orden_pedido,
orden_pedido.idc_orden_pedido,
orden_pedido.fecha_para_aprobar,
transportador.idc_transportador,
cliente_despacho.idc_cliente_despacho,
orden_pedido.numero_po,
orden_pedido.comentario

union all
/*Extraer las �rdenes de pedido pendientes de aprobaci�n*/
select farm.id_farm,
farm.idc_farm,
ltrim(rtrim(farm.nombre_farm)) as nombre_farm,
tapa.id_tapa,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)) as nombre_tipo_flor,
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)) as nombre_variedad_flor,
grado_flor.id_grado_flor,
grado_flor.idc_grado_flor,
ltrim(rtrim(grado_flor.nombre_grado_flor)) as nombre_grado_flor,
tipo_caja.id_tipo_caja,
tipo_caja.idc_tipo_caja,
ltrim(rtrim(tipo_caja.nombre_tipo_caja)) as nombre_tipo_caja,
orden_pedido.marca,
orden_pedido.unidades_por_pieza,
orden_pedido.valor_unitario,
@estado_prevendido_sin_confirmar as estado,
sum(orden_pedido.cantidad_piezas) as piezas_prevendidas,
null,
grado_flor.medidas,
color.idc_color,
color.prioridad_color,
ltrim(rtrim(color.nombre_color)) as nombre_color,
orden_pedido.id_orden_pedido,
orden_pedido.idc_orden_pedido,
orden_pedido.fecha_para_aprobar,
transportador.idc_transportador,
cliente_despacho.idc_cliente_despacho,
orden_pedido.numero_po,
orden_pedido.comentario
from orden_pedido,
transportador,
tipo_factura,
cliente_despacho,
farm,
tapa,
tipo_flor,
variedad_flor,
grado_flor,
color,
tipo_caja
where color.id_color = variedad_flor.id_color
and orden_pedido.fecha_para_aprobar between
@fecha_inicial and @fecha_final
and Orden_Pedido.fecha_inicial = convert(datetime, '1999/01/01')
and farm.id_farm = orden_pedido.id_farm 
and tapa.id_tapa = orden_pedido.id_tapa
and tipo_flor.id_tipo_flor = variedad_flor.id_tipo_flor
and tipo_flor.id_tipo_flor = grado_flor.id_tipo_flor
and variedad_flor.id_variedad_flor = orden_pedido.id_variedad_flor
and grado_flor.id_grado_flor = orden_pedido.id_grado_flor
and tipo_caja.id_tipo_caja = orden_pedido.id_tipo_caja
and tipo_factura.id_tipo_factura = orden_pedido.id_tipo_factura
and tipo_factura.idc_tipo_factura = '4'
and orden_pedido.disponible = 1
and exists
(
	select *
	from #ordenes
	where #ordenes.id_orden_pedido = orden_pedido.id_orden_pedido
)
and transportador.id_transportador = orden_pedido.id_transportador
and cliente_despacho.id_despacho = orden_pedido.id_despacho
group by farm.id_farm,
farm.idc_farm,
ltrim(rtrim(farm.nombre_farm)),
tapa.id_tapa,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)),
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)),
grado_flor.id_grado_flor,
grado_flor.idc_grado_flor,
ltrim(rtrim(grado_flor.nombre_grado_flor)),
tipo_caja.id_tipo_caja,
tipo_caja.idc_tipo_caja,
ltrim(rtrim(tipo_caja.nombre_tipo_caja)),
orden_pedido.marca,
orden_pedido.unidades_por_pieza,
orden_pedido.valor_unitario,
grado_flor.medidas,
color.idc_color,
color.prioridad_color,
ltrim(rtrim(color.nombre_color)),
orden_pedido.id_orden_pedido,
orden_pedido.idc_orden_pedido,
orden_pedido.fecha_para_aprobar,
transportador.idc_transportador,
cliente_despacho.idc_cliente_despacho,
orden_pedido.numero_po,
orden_pedido.comentario

insert into #inventario 
(
	id_farm, 
	idc_farm, 
	nombre_farm, 
	id_tapa, 
	idc_tapa, 
	nombre_tapa, 
	id_tipo_flor, 
	idc_tipo_flor, 
	nombre_tipo_flor, 
	id_variedad_flor, 
	idc_variedad_flor, 
	nombre_variedad_flor, 
	id_grado_flor, 
	idc_grado_flor, 
	nombre_grado_flor, 
	id_tipo_caja, 
	idc_tipo_caja, 
	nombre_tipo_caja, 
	marca, 
	unidades_por_pieza, 
	valor_unitario, 
	estado, 
	piezas_prevendidas, 
	id_orden_especial_confirmada,
	medidas_grado_flor,
	idc_color,
	prioridad_color,
	nombre_color,
	id_orden_pedido,
	idc_orden_pedido,
	fecha_para_aprobar,
	idc_transportador,
	idc_cliente_despacho,
	numero_po,
	comentario
)
select farm.id_farm,
farm.idc_farm,
ltrim(rtrim(farm.nombre_farm)) as nombre_farm,
tapa.id_tapa,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)) as nombre_tipo_flor,
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)) as nombre_variedad_flor,
grado_flor.id_grado_flor,
grado_flor.idc_grado_flor,
ltrim(rtrim(grado_flor.nombre_grado_flor)) as nombre_grado_flor,
tipo_caja.id_tipo_caja,
tipo_caja.idc_tipo_caja,
ltrim(rtrim(tipo_caja.nombre_tipo_caja)) as nombre_tipo_caja,
orden_pedido.marca,
orden_pedido.unidades_por_pieza,
orden_pedido.valor_unitario,
@estado_inventario as estado,
sum(orden_pedido.cantidad_piezas) as piezas_prevendidas,
null,
grado_flor.medidas,
color.idc_color,
color.prioridad_color,
ltrim(rtrim(color.nombre_color)) as nombre_color,
orden_pedido.id_orden_pedido,
orden_pedido.idc_orden_pedido,
orden_pedido.fecha_para_aprobar,
transportador.idc_transportador,
cliente_despacho.idc_cliente_despacho,
orden_pedido.numero_po,
orden_pedido.comentario
from orden_pedido,
transportador,
tipo_factura,
cliente_despacho,
farm,
tapa,
tipo_flor,
variedad_flor,
grado_flor,
color,
tipo_caja
where color.id_color = variedad_flor.id_color
and orden_pedido.fecha_inicial between
@fecha_inicial and @fecha_final
and farm.id_farm = orden_pedido.id_farm 
and tapa.id_tapa = orden_pedido.id_tapa
and tipo_flor.id_tipo_flor = variedad_flor.id_tipo_flor
and tipo_flor.id_tipo_flor = grado_flor.id_tipo_flor
and variedad_flor.id_variedad_flor = orden_pedido.id_variedad_flor
and grado_flor.id_grado_flor = orden_pedido.id_grado_flor
and tipo_caja.id_tipo_caja = orden_pedido.id_tipo_caja
and tipo_factura.id_tipo_factura = orden_pedido.id_tipo_factura
and tipo_factura.idc_tipo_factura = '4'
and orden_pedido.disponible = 1
and exists
(
	select *
	from #ordenes
	where #ordenes.id_orden_pedido = orden_pedido.id_orden_pedido
)
and not exists
(
	select *
	from #inventario
	where #inventario.id_orden_pedido = orden_pedido.id_orden_pedido
)
and transportador.id_transportador = orden_pedido.id_transportador
and cliente_despacho.id_despacho = orden_pedido.id_despacho
group by farm.id_farm,
farm.idc_farm,
ltrim(rtrim(farm.nombre_farm)),
tapa.id_tapa,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)),
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)),
grado_flor.id_grado_flor,
grado_flor.idc_grado_flor,
ltrim(rtrim(grado_flor.nombre_grado_flor)),
tipo_caja.id_tipo_caja,
tipo_caja.idc_tipo_caja,
ltrim(rtrim(tipo_caja.nombre_tipo_caja)),
orden_pedido.marca,
orden_pedido.unidades_por_pieza,
orden_pedido.valor_unitario,
grado_flor.medidas,
color.idc_color,
color.prioridad_color,
ltrim(rtrim(color.nombre_color)),
orden_pedido.id_orden_pedido,
orden_pedido.idc_orden_pedido,
orden_pedido.fecha_para_aprobar,
transportador.idc_transportador,
cliente_despacho.idc_cliente_despacho,
orden_pedido.numero_po,
orden_pedido.comentario

/*Extraer Orden_sin_aprobar - Not sent to farm*/
select farm.id_farm,
farm.idc_farm,
ltrim(rtrim(farm.nombre_farm)) as nombre_farm,
tapa.id_tapa,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)) as nombre_tipo_flor,
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)) as nombre_variedad_flor,
grado_flor.id_grado_flor,
grado_flor.idc_grado_flor,
ltrim(rtrim(grado_flor.nombre_grado_flor)) as nombre_grado_flor,
tipo_caja.id_tipo_caja,
tipo_caja.idc_tipo_caja,
ltrim(rtrim(tipo_caja.nombre_tipo_caja)) as nombre_tipo_caja,
item_orden_sin_aprobar.code as marca,
item_orden_sin_aprobar.unidades_por_pieza,
@estado_orden_sin_aprobar_not_sent_to_farm as estado,
sum(item_orden_sin_aprobar.cantidad_piezas) as piezas_sin_aprobar,
grado_flor.medidas as medidas_grado_flor,
color.idc_color,
color.prioridad_color,
ltrim(rtrim(color.nombre_color)) as nombre_color,
item_orden_sin_aprobar.valor_unitario,
item_orden_sin_aprobar.id_item_orden_sin_aprobar,
item_orden_sin_aprobar.numero_po,
item_orden_sin_aprobar.comentario into #aprobacion_not_sent_to_farm
from orden_sin_aprobar,
item_orden_sin_aprobar,
tipo_factura,
farm,
tapa,
tipo_flor,
variedad_flor,
grado_flor,
color,
caja,
tipo_caja,
transportador,
cliente_despacho
where color.id_color = variedad_flor.id_color
and tipo_factura.id_tipo_factura = orden_sin_aprobar.id_tipo_factura
and orden_sin_aprobar.id_orden_sin_aprobar = item_orden_sin_aprobar.id_orden_sin_aprobar
and tipo_factura.idc_tipo_factura = '4'
and exists
(
	select *
	from #orden_sin_confirmar
	where #orden_sin_confirmar.id_item_orden_sin_aprobar = item_orden_sin_aprobar.id_item_orden_sin_aprobar
)
and farm.id_farm = item_orden_sin_aprobar.id_farm
and tapa.id_tapa = item_orden_sin_aprobar.id_tapa
and tipo_flor.id_tipo_flor = variedad_flor.id_tipo_flor
and tipo_flor.id_tipo_flor = grado_flor.id_tipo_flor
and variedad_flor.id_variedad_flor = item_orden_sin_aprobar.id_variedad_flor
and grado_flor.id_grado_flor = item_orden_sin_aprobar.id_grado_flor
and caja.id_caja = item_orden_sin_aprobar.id_caja
and tipo_caja.id_tipo_caja = caja.id_tipo_caja
and transportador.id_transportador = item_orden_sin_aprobar.id_transportador
and transportador.idc_transportador = @idc_transportador
and cliente_despacho.id_despacho = orden_sin_aprobar.id_despacho
and cliente_despacho.idc_cliente_despacho = @idc_cliente_despacho 
and item_orden_sin_aprobar.fecha_inicial = @fecha
and not exists
(
	select * 
	from solicitud_confirmacion_orden_especial
	where solicitud_confirmacion_orden_especial.id_item_orden_sin_aprobar = item_orden_sin_aprobar.id_item_orden_sin_aprobar
)
group by farm.id_farm,
farm.idc_farm,
ltrim(rtrim(farm.nombre_farm)),
tapa.id_tapa,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)),
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)),
grado_flor.id_grado_flor,
grado_flor.idc_grado_flor,
ltrim(rtrim(grado_flor.nombre_grado_flor)),
tipo_caja.id_tipo_caja,
tipo_caja.idc_tipo_caja,
ltrim(rtrim(tipo_caja.nombre_tipo_caja)),
item_orden_sin_aprobar.code,
item_orden_sin_aprobar.unidades_por_pieza,
grado_flor.medidas,
color.idc_color,
color.prioridad_color,
ltrim(rtrim(color.nombre_color)),
item_orden_sin_aprobar.valor_unitario,
item_orden_sin_aprobar.id_item_orden_sin_aprobar,
item_orden_sin_aprobar.numero_po,
item_orden_sin_aprobar.comentario

/*Extraer Orden_sin_aprobar - Not Farm Confirmed*/
select farm.id_farm,
farm.idc_farm,
ltrim(rtrim(farm.nombre_farm)) as nombre_farm,
tapa.id_tapa,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)) as nombre_tipo_flor,
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)) as nombre_variedad_flor,
grado_flor.id_grado_flor,
grado_flor.idc_grado_flor,
ltrim(rtrim(grado_flor.nombre_grado_flor)) as nombre_grado_flor,
tipo_caja.id_tipo_caja,
tipo_caja.idc_tipo_caja,
ltrim(rtrim(tipo_caja.nombre_tipo_caja)) as nombre_tipo_caja,
item_orden_sin_aprobar.code as marca,
item_orden_sin_aprobar.unidades_por_pieza,
@estado_orden_sin_aprobar_no_farm_confirmed as estado,
sum(item_orden_sin_aprobar.cantidad_piezas) as piezas_sin_aprobar,
grado_flor.medidas as medidas_grado_flor,
color.idc_color,
color.prioridad_color,
ltrim(rtrim(color.nombre_color)) as nombre_color ,
item_orden_sin_aprobar.valor_unitario,
item_orden_sin_aprobar.id_item_orden_sin_aprobar,
item_orden_sin_aprobar.numero_po,
item_orden_sin_aprobar.comentario into #aprobacion_no_farm_confirmed
from orden_sin_aprobar,
item_orden_sin_aprobar,
solicitud_confirmacion_orden_especial,
tipo_factura,
farm,
tapa,
tipo_flor,
variedad_flor,
grado_flor,
color,
caja,
tipo_caja,
transportador,
cliente_despacho
where color.id_color = variedad_flor.id_color
and tipo_factura.id_tipo_factura = orden_sin_aprobar.id_tipo_factura
and orden_sin_aprobar.id_orden_sin_aprobar = item_orden_sin_aprobar.id_orden_sin_aprobar
and tipo_factura.idc_tipo_factura = '4'
and exists
(
	select *
	from #orden_sin_confirmar
	where #orden_sin_confirmar.id_item_orden_sin_aprobar = item_orden_sin_aprobar.id_item_orden_sin_aprobar
)
and farm.id_farm = item_orden_sin_aprobar.id_farm
and tapa.id_tapa = item_orden_sin_aprobar.id_tapa
and tipo_flor.id_tipo_flor = variedad_flor.id_tipo_flor
and tipo_flor.id_tipo_flor = grado_flor.id_tipo_flor
and variedad_flor.id_variedad_flor = item_orden_sin_aprobar.id_variedad_flor
and grado_flor.id_grado_flor = item_orden_sin_aprobar.id_grado_flor
and caja.id_caja = item_orden_sin_aprobar.id_caja
and tipo_caja.id_tipo_caja = caja.id_tipo_caja
and transportador.id_transportador = item_orden_sin_aprobar.id_transportador
and transportador.idc_transportador = @idc_transportador
and cliente_despacho.id_despacho = orden_sin_aprobar.id_despacho
and cliente_despacho.idc_cliente_despacho = @idc_cliente_despacho 
and item_orden_sin_aprobar.fecha_inicial = @fecha
and solicitud_confirmacion_orden_especial.id_item_orden_sin_aprobar = item_orden_sin_aprobar.id_item_orden_sin_aprobar
and solicitud_confirmacion_orden_especial.aceptada = 1
and not exists
(
	select * 
	from confirmacion_orden_especial_cultivo
	where confirmacion_orden_especial_cultivo.id_solicitud_confirmacion_orden_especial = solicitud_confirmacion_orden_especial.id_solicitud_confirmacion_orden_especial
)
group by farm.id_farm,
farm.idc_farm,
ltrim(rtrim(farm.nombre_farm)),
tapa.id_tapa,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)),
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)),
grado_flor.id_grado_flor,
grado_flor.idc_grado_flor,
ltrim(rtrim(grado_flor.nombre_grado_flor)),
tipo_caja.id_tipo_caja,
tipo_caja.idc_tipo_caja,
ltrim(rtrim(tipo_caja.nombre_tipo_caja)),
item_orden_sin_aprobar.code,
item_orden_sin_aprobar.unidades_por_pieza,
grado_flor.medidas,
color.idc_color,
color.prioridad_color,
ltrim(rtrim(color.nombre_color)),
item_orden_sin_aprobar.valor_unitario,
item_orden_sin_aprobar.id_item_orden_sin_aprobar,
item_orden_sin_aprobar.numero_po,
item_orden_sin_aprobar.comentario

/*Ingresar a la tabla inventario las ordenes especiales que est�n en el proceso - Not Sent to Farm*/
insert into #inventario 
(
	id_farm, 
	idc_farm, 
	nombre_farm, 
	id_tapa, 
	idc_tapa, 
	nombre_tapa, 
	id_tipo_flor, 
	idc_tipo_flor, 
	nombre_tipo_flor, 
	id_variedad_flor, 
	idc_variedad_flor, 
	nombre_variedad_flor, 
	id_grado_flor, 
	idc_grado_flor, 
	nombre_grado_flor, 
	id_tipo_caja, 
	idc_tipo_caja, 
	nombre_tipo_caja, 
	marca, 
	unidades_por_pieza, 
	estado, 
	piezas_prevendidas,
	medidas_grado_flor,
	idc_color,
	prioridad_color,
	nombre_color,
	valor_unitario,
	id_orden_pedido,
	numero_po,
	comentario
)
select id_farm, 
idc_farm, 
nombre_farm, 
id_tapa, 
idc_tapa, 
nombre_tapa, 
id_tipo_flor, 
idc_tipo_flor, 
nombre_tipo_flor, 
id_variedad_flor, 
idc_variedad_flor, 
nombre_variedad_flor, 
id_grado_flor, 
idc_grado_flor, 
nombre_grado_flor, 
id_tipo_caja, 
idc_tipo_caja, 
nombre_tipo_caja, 
marca, 
unidades_por_pieza, 
estado, 
piezas_sin_aprobar,
medidas_grado_flor,
idc_color,
prioridad_color,
nombre_color,
valor_unitario,
id_item_orden_sin_aprobar,
numero_po,
comentario
from #aprobacion_not_sent_to_farm

/*Ingresar a la tabla inventario las ordenes especiales que est�n en el proceso - No Farm Confirmed*/
insert into #inventario 
(
	id_farm, 
	idc_farm, 
	nombre_farm, 
	id_tapa, 
	idc_tapa, 
	nombre_tapa, 
	id_tipo_flor, 
	idc_tipo_flor, 
	nombre_tipo_flor, 
	id_variedad_flor, 
	idc_variedad_flor, 
	nombre_variedad_flor, 
	id_grado_flor, 
	idc_grado_flor, 
	nombre_grado_flor, 
	id_tipo_caja, 
	idc_tipo_caja, 
	nombre_tipo_caja, 
	marca, 
	unidades_por_pieza, 
	estado, 
	piezas_prevendidas,
	medidas_grado_flor,
	idc_color,
	prioridad_color,
	nombre_color,
	valor_unitario,
	id_orden_pedido,
	numero_po,
	comentario
)
select id_farm, 
idc_farm, 
nombre_farm, 
id_tapa, 
idc_tapa, 
nombre_tapa, 
id_tipo_flor, 
idc_tipo_flor, 
nombre_tipo_flor, 
id_variedad_flor, 
idc_variedad_flor, 
nombre_variedad_flor, 
id_grado_flor, 
idc_grado_flor, 
nombre_grado_flor, 
id_tipo_caja, 
idc_tipo_caja, 
nombre_tipo_caja, 
marca, 
unidades_por_pieza, 
estado, 
piezas_sin_aprobar,
medidas_grado_flor,
idc_color,
prioridad_color,
nombre_color,
valor_unitario,
id_item_orden_sin_aprobar,
numero_po,
comentario
from #aprobacion_no_farm_confirmed

/*creaci�n de tablas para extraer los datos de las unidades agrupadas por finca, tapa y flor*/
create table #inventario_agrupado
(
	id_farm int, 
	id_tapa int null, 
	id_variedad_flor int, 
	id_grado_flor int, 
	unidades_agrupadas_inventario int
)

create table #orden_pedido_agrupado
(
	id_farm int, 
	id_tapa int null, 
	id_variedad_flor int, 
	id_grado_flor int, 
	unidades_agrupadas_prevendidas int
)

create table #empaque_principal
(
	id_farm int, 
	id_tapa int null, 
	id_variedad_flor int, 
	id_grado_flor int, 
	precio_minimo decimal(20,4)
)

/*Si se trabaja sobre Natural, no se tendr� en cuenta la tapa*/
if(@nombre_base_datos = 'BD_NF')
begin
	insert into #inventario_agrupado (id_farm, id_variedad_flor, id_grado_flor, unidades_agrupadas_inventario)
	select id_farm, id_variedad_flor, id_grado_flor, sum(unidades_por_pieza * piezas_inventario) as unidades_agrupadas_inventario
	from #inventario
	group by id_farm, id_variedad_flor, id_grado_flor

	insert into #orden_pedido_agrupado (id_farm, id_variedad_flor, id_grado_flor, unidades_agrupadas_prevendidas)
	select id_farm, id_variedad_flor, id_grado_flor, sum(unidades_por_pieza * piezas_prevendidas) as unidades_agrupadas_prevendidas
	from #inventario
	group by id_farm, id_variedad_flor, id_grado_flor

	update #inventario
	set saldo = isnull(unidades_agrupadas_inventario, 0) - isnull(unidades_agrupadas_prevendidas, 0)
	from #orden_pedido_agrupado,
	#inventario_agrupado
	where #orden_pedido_agrupado.id_farm = #inventario_agrupado.id_farm
	and #orden_pedido_agrupado.id_variedad_flor = #inventario_agrupado.id_variedad_flor
	and #orden_pedido_agrupado.id_grado_flor = #inventario_agrupado.id_grado_flor
	and #inventario.id_farm = #inventario_agrupado.id_farm
	and #inventario.id_variedad_flor = #inventario_agrupado.id_variedad_flor
	and #inventario.id_grado_flor = #inventario_agrupado.id_grado_flor 

	/*Colocar el saldo con el valor del inventario cuando despu�s del proceso anterior �ste es nulo*/
	update #inventario
	set saldo = isnull(unidades_agrupadas_inventario, 0)
	from #inventario_agrupado
	where #inventario.id_farm = #inventario_agrupado.id_farm
	and #inventario.id_variedad_flor = #inventario_agrupado.id_variedad_flor
	and #inventario.id_grado_flor = #inventario_agrupado.id_grado_flor 
	and #inventario.saldo is null
end
else
/*Si NO se trabaja sobre Natural, se tendr� en cuenta la tapa*/
begin
	insert into #inventario_agrupado (id_farm, id_tapa, id_variedad_flor, id_grado_flor, unidades_agrupadas_inventario)
	select id_farm, id_tapa, id_variedad_flor, id_grado_flor, sum(unidades_por_pieza * piezas_inventario) as unidades_agrupadas_inventario
	from #inventario
	group by id_farm, id_tapa, id_variedad_flor, id_grado_flor

	insert into #orden_pedido_agrupado (id_farm, id_tapa, id_variedad_flor, id_grado_flor, unidades_agrupadas_prevendidas)
	select id_farm, id_tapa, id_variedad_flor, id_grado_flor, sum(unidades_por_pieza * piezas_prevendidas) as unidades_agrupadas_prevendidas
	from #inventario
	group by id_farm, id_tapa, id_variedad_flor, id_grado_flor

	update #inventario
	set saldo = isnull(unidades_agrupadas_inventario, 0) - isnull(unidades_agrupadas_prevendidas, 0)
	from #orden_pedido_agrupado,
	#inventario_agrupado
	where #orden_pedido_agrupado.id_farm = #inventario_agrupado.id_farm
	and #orden_pedido_agrupado.id_tapa = #inventario_agrupado.id_tapa
	and #orden_pedido_agrupado.id_variedad_flor = #inventario_agrupado.id_variedad_flor
	and #orden_pedido_agrupado.id_grado_flor = #inventario_agrupado.id_grado_flor
	and #inventario.id_farm = #inventario_agrupado.id_farm
	and #inventario.id_tapa = #inventario_agrupado.id_tapa
	and #inventario.id_variedad_flor = #inventario_agrupado.id_variedad_flor
	and #inventario.id_grado_flor = #inventario_agrupado.id_grado_flor 

	/*Colocar el saldo con el valor del inventario cuando despu�s del proceso anterior �ste es nulo*/
	update #inventario
	set saldo = isnull(unidades_agrupadas_inventario, 0)
	from #inventario_agrupado
	where #inventario.id_farm = #inventario_agrupado.id_farm
	and #inventario.id_tapa = #inventario_agrupado.id_tapa
	and #inventario.id_variedad_flor = #inventario_agrupado.id_variedad_flor
	and #inventario.id_grado_flor = #inventario_agrupado.id_grado_flor 
	and #inventario.saldo is null
end

insert into #empaque_principal (id_farm, id_tapa, id_variedad_flor, id_grado_flor, precio_minimo)
select id_farm, 
id_tapa, 
id_variedad_flor, 
id_grado_flor, 
precio_minimo
from #inventario
WHERE empaque_principal = 1
group by id_farm, 
id_tapa, 
id_variedad_flor, 
id_grado_flor,
precio_minimo

update #inventario
set precio_minimo = #empaque_principal.precio_minimo
from #empaque_principal
where #inventario.id_farm = #empaque_principal.id_farm
and #inventario.id_tapa = #empaque_principal.id_tapa
and #inventario.id_variedad_flor = #empaque_principal.id_variedad_flor
and #inventario.id_grado_flor = #empaque_principal.id_grado_flor 
and #inventario.empaque_principal = 0

/*Retornar los datos al usuario*/
select idc_farm, 
nombre_farm, 
/*Si se trabaja en Natural, se encontr� tapa asignada al cliente ingresado y la finca es N4, se colocar� la tapa que est� asignada al cliente*/
/*en caso contrario, la que venga con el inventario*/
case
	when @id_tapa is not null and idc_farm = 'N4' then @idc_tapa
	else idc_tapa
end as idc_tapa,
case
	when @id_tapa is not null and idc_farm = 'N4' then @nombre_tapa
	else nombre_tapa
end as nombre_tapa,
idc_tipo_flor, 
nombre_tipo_flor, 
idc_variedad_flor, 
nombre_variedad_flor, 
idc_grado_flor, 
nombre_grado_flor, 
idc_tipo_caja, 
nombre_tipo_caja, 
marca, 
empaque_principal, 
unidades_por_pieza, 
precio_minimo, 
estado, 
piezas_prevendidas as piezas_inventario, 
null as saldo,
piezas_prevendidas, 
valor_unitario as precio_venta,
medidas_grado_flor,
idc_color,
prioridad_color,
nombre_color,
id_item_inventario_preventa,
id_orden_pedido,
idc_orden_pedido,
controla_saldos,
fecha_para_aprobar,
comentario
from #inventario
WHERE estado NOT IN (@estado_prevendido, @estado_prevendido_sin_confirmar, @estado_inventario)
and isnull(numero_po, '') = @numero_po
UNION ALL
select idc_farm, 
nombre_farm, 
/*Si se trabaja en Natural, se encontr� tapa asignada al cliente ingresado y la finca es N4, se colocar� la tapa que est� asignada al cliente*/
/*en caso contrario, la que venga con el inventario*/
case
	when @id_tapa is not null and idc_farm = 'N4' then @idc_tapa
	else idc_tapa
end as idc_tapa,
case
	when @id_tapa is not null and idc_farm = 'N4' then @nombre_tapa
	else nombre_tapa
end as nombre_tapa,
idc_tipo_flor, 
nombre_tipo_flor, 
idc_variedad_flor, 
nombre_variedad_flor, 
idc_grado_flor, 
nombre_grado_flor, 
idc_tipo_caja, 
nombre_tipo_caja, 
'' as marca, 
0, 
unidades_por_pieza, 
99.99 as precio_minimo, 
estado, 
sum(piezas_prevendidas) as piezas_inventario, 
0 as saldo,
sum(piezas_prevendidas) as piezas_prevendidas, 
0 as precio_venta,
medidas_grado_flor,
idc_color,
prioridad_color,
nombre_color,
0,
0,
'',
0 as controla_saldos,
null,
comentario
from #inventario
WHERE estado IN (@estado_inventario)
group by idc_farm, 
nombre_farm, 
idc_tapa,
nombre_tapa,
idc_tipo_flor, 
nombre_tipo_flor, 
idc_variedad_flor, 
nombre_variedad_flor, 
idc_grado_flor, 
nombre_grado_flor, 
idc_tipo_caja, 
nombre_tipo_caja, 
unidades_por_pieza, 
estado, 
medidas_grado_flor,
idc_color,
prioridad_color,
nombre_color,
comentario
union all
select idc_farm, 
nombre_farm, 
/*Si se trabaja en Natural, se encontr� tapa asignada al cliente ingresado y la finca es N4, se colocar� la tapa que est� asignada al cliente*/
/*en caso contrario, la que venga con el inventario*/
case
	when @id_tapa is not null and idc_farm = 'N4' then @idc_tapa
	else idc_tapa
end as idc_tapa,
case
	when @id_tapa is not null and idc_farm = 'N4' then @nombre_tapa
	else nombre_tapa
end as nombre_tapa,
idc_tipo_flor, 
nombre_tipo_flor, 
idc_variedad_flor, 
nombre_variedad_flor, 
idc_grado_flor, 
nombre_grado_flor, 
idc_tipo_caja, 
nombre_tipo_caja, 
marca, 
empaque_principal, 
unidades_por_pieza, 
precio_minimo, 
estado, 
piezas_prevendidas as piezas_inventario, 
null as saldo,
piezas_prevendidas, 
valor_unitario as precio_venta,
medidas_grado_flor,
idc_color,
prioridad_color,
nombre_color,
id_item_inventario_preventa,
id_orden_pedido,
idc_orden_pedido,
controla_saldos,
fecha_para_aprobar,
comentario
from #inventario
where estado in (@estado_prevendido, @estado_prevendido_sin_confirmar)
and idc_transportador = @idc_transportador
and idc_cliente_despacho = @idc_cliente_despacho
and isnull(numero_po, '') = @numero_po
order by estado

/*eliminaci�n de tablas temporales*/
drop table #ordenes
drop table #inventario
drop table #inventario_agrupado
drop table #orden_pedido_agrupado
drop table #aprobacion_not_sent_to_farm
drop table #aprobacion_no_farm_confirmed
drop table #orden_sin_confirmar