set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

alter PROCEDURE [dbo].[apr_ord_consultar_ordenes_especiales_sin_confirmar]

@idc_vendedor nvarchar(255),
@estado nvarchar(255)

as

/*visualizar ordenes que teniendo valor y siendo aprobadas no han sido enviadas a la finca*/
select item_orden_sin_aprobar.id_item_orden_sin_aprobar,
vendedor.idc_vendedor,
ltrim(rtrim(vendedor.nombre)) as nombre_vendedor,
cliente_factura.idc_cliente_factura,
cliente_despacho.idc_cliente_despacho,
cliente_despacho.nombre_cliente,
tipo_factura.idc_tipo_factura,
tipo_factura.nombre_tipo_factura,
transportador.idc_transportador,
transportador.nombre_transportador,
tipo_flor.idc_tipo_flor,
tipo_flor.nombre_tipo_flor,
variedad_flor.idc_variedad_flor,
variedad_flor.nombre_variedad_flor,
grado_flor.idc_grado_flor,
grado_flor.nombre_grado_flor,
farm.id_farm,
farm.idc_farm,
farm.nombre_farm,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_caja.idc_tipo_caja + caja.idc_caja as idc_caja,
tipo_caja.idc_tipo_caja,
tipo_caja.nombre_tipo_caja,
item_orden_sin_aprobar.code,
item_orden_sin_aprobar.comentario,
item_orden_sin_aprobar.fecha_inicial,
item_orden_sin_aprobar.fecha_final,
item_orden_sin_aprobar.unidades_por_pieza,
item_orden_sin_aprobar.cantidad_piezas,
item_orden_sin_aprobar.valor_unitario,
item_orden_sin_aprobar.fecha_grabacion,
convert(nvarchar, item_orden_sin_aprobar.fecha_grabacion, 108) as hora_grabacion,
item_orden_sin_aprobar.usuario_cobol,
'Not Sent to Farm' as estado,
case
	when item_orden_sin_aprobar.valor_pactado_interno is not null then item_orden_sin_aprobar.valor_pactado_interno
	else 
	case
		when tipo_farm.codigo <> 'C' then 
		((((item_orden_sin_aprobar.valor_unitario - (
		(isnull((
			select sum(valor)
			from tipo_cargo,
			recargo_tipo_cargo
			where tipo_cargo.id_tipo_cargo = recargo_tipo_cargo.id_tipo_cargo
			and cliente_factura.id_cliente_factura = recargo_tipo_cargo.id_cliente_factura
			and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
			), 0)) / item_orden_sin_aprobar.unidades_por_pieza)) - ((item_orden_sin_aprobar.valor_unitario - (
		(isnull((
			select sum(valor)
			from tipo_cargo,
			recargo_tipo_cargo
			where tipo_cargo.id_tipo_cargo = recargo_tipo_cargo.id_tipo_cargo
			and cliente_factura.id_cliente_factura = recargo_tipo_cargo.id_cliente_factura
			and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
			), 0)) / item_orden_sin_aprobar.unidades_por_pieza)) * (convert(decimal(20,4), 35) / 100))) -  ((ciudad.impuesto_por_caja * tipo_caja.factor_a_full) / item_orden_sin_aprobar.unidades_por_pieza)))
		else
(
	(((item_orden_sin_aprobar.valor_unitario - (
	(	item_orden_sin_aprobar.box_charges +
	isnull((
		select sum(valor)
		from tipo_cargo,
		recargo_tipo_cargo
		where tipo_cargo.id_tipo_cargo = recargo_tipo_cargo.id_tipo_cargo
		and cliente_factura.id_cliente_factura = recargo_tipo_cargo.id_cliente_factura
		and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
		), 0)) / item_orden_sin_aprobar.unidades_por_pieza)) - ((item_orden_sin_aprobar.valor_unitario - (
	(	item_orden_sin_aprobar.box_charges +
	isnull((
		select sum(valor)
		from tipo_cargo,
		recargo_tipo_cargo
		where tipo_cargo.id_tipo_cargo = recargo_tipo_cargo.id_tipo_cargo
		and cliente_factura.id_cliente_factura = recargo_tipo_cargo.id_cliente_factura
		and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
		), 0)) / item_orden_sin_aprobar.unidades_por_pieza)) * (farm.comision_farm / 100))) -  ((ciudad.impuesto_por_caja * tipo_caja.factor_a_full) / item_orden_sin_aprobar.unidades_por_pieza))
) end
end as precio_finca,
0 as contiene_mail,
isnull((
	select top 1 orden_pedido.idc_orden_pedido
	from orden_pedido,
	orden_especial_confirmada,
	confirmacion_orden_especial_cultivo,
	solicitud_confirmacion_orden_especial,
	item_orden_sin_aprobar as i
	where orden_pedido.id_orden_pedido = orden_especial_confirmada.id_orden_pedido
	and orden_especial_confirmada.id_confirmacion_orden_especial_cultivo = confirmacion_orden_especial_cultivo.id_confirmacion_orden_especial_cultivo
	and confirmacion_orden_especial_cultivo.id_solicitud_confirmacion_orden_especial = solicitud_confirmacion_orden_especial.id_solicitud_confirmacion_orden_especial
	and solicitud_confirmacion_orden_especial.id_item_orden_sin_aprobar = i.id_item_orden_sin_aprobar
	and i.id_item_orden_sin_aprobar_padre = item_orden_sin_aprobar.id_item_orden_sin_aprobar_padre
	order by orden_especial_confirmada.id_orden_especial_confirmada desc
),0) as idc_orden_pedido,
farm.correo as correo_aprobacion,
0 as numero_consecutivo,
item_orden_sin_aprobar.precio_mercado,
item_orden_sin_aprobar.box_charges,
item_orden_sin_aprobar.observacion as observacion_procurement,
isnull(item_orden_sin_aprobar.numero_po, '') as numero_po,
item_orden_sin_aprobar.valor_pactado_interno into #temp
from cliente_factura,
cliente_despacho,
orden_sin_aprobar,
vendedor,
item_orden_sin_aprobar,
transportador,
variedad_flor,
tipo_flor,
grado_flor,
farm,
tipo_farm,
ciudad,
tapa,
tipo_caja,
caja,
item_orden_sin_aprobar as iosa,
tipo_factura
where tipo_caja.id_tipo_caja = caja.id_tipo_caja
and tipo_farm.id_tipo_farm = farm.id_tipo_farm
and ciudad.id_ciudad = farm.id_ciudad
and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
and vendedor.id_vendedor = cliente_factura.id_vendedor
and cliente_despacho.id_despacho = orden_sin_aprobar.id_despacho
and tipo_factura.id_tipo_factura = orden_sin_aprobar.id_tipo_factura
and orden_sin_aprobar.id_orden_sin_aprobar = item_orden_sin_aprobar.id_orden_sin_aprobar
and item_orden_sin_aprobar.id_transportador = transportador.id_transportador
and item_orden_sin_aprobar.id_variedad_flor = variedad_flor.id_variedad_flor
and item_orden_sin_aprobar.id_grado_flor = grado_flor.id_grado_flor
and tipo_flor.id_tipo_flor = variedad_flor.id_tipo_flor
and tipo_flor.id_tipo_flor = grado_flor.id_tipo_flor
and item_orden_sin_aprobar.id_farm = farm.id_farm
and item_orden_sin_aprobar.id_tapa = tapa.id_tapa
and item_orden_sin_aprobar.id_caja = caja.id_caja
and item_orden_sin_aprobar.id_item_orden_sin_aprobar < = iosa.id_item_orden_sin_aprobar
and item_orden_sin_aprobar.id_item_orden_sin_aprobar_padre = iosa.id_item_orden_sin_aprobar_padre
and not exists
(
	select *
	from solicitud_confirmacion_orden_especial
	where item_orden_sin_aprobar.id_item_orden_sin_aprobar = solicitud_confirmacion_orden_especial.id_item_orden_sin_aprobar
)
and tipo_factura.idc_tipo_factura = '4'
group by
item_orden_sin_aprobar.id_item_orden_sin_aprobar_padre,
item_orden_sin_aprobar.id_item_orden_sin_aprobar,
vendedor.idc_vendedor,
ltrim(rtrim(vendedor.nombre)),
cliente_factura.idc_cliente_factura,
cliente_despacho.idc_cliente_despacho,
cliente_despacho.nombre_cliente,
tipo_factura.idc_tipo_factura,
tipo_factura.nombre_tipo_factura,
transportador.idc_transportador,
transportador.nombre_transportador,
tipo_flor.idc_tipo_flor,
tipo_flor.nombre_tipo_flor,
variedad_flor.idc_variedad_flor,
variedad_flor.nombre_variedad_flor,
grado_flor.idc_grado_flor,
grado_flor.nombre_grado_flor,
farm.id_farm,
farm.idc_farm,
farm.nombre_farm,
tapa.idc_tapa,
tapa.nombre_tapa,
caja.idc_caja,
tipo_caja.idc_tipo_caja,
tipo_caja.nombre_tipo_caja,
item_orden_sin_aprobar.code,
item_orden_sin_aprobar.comentario,
item_orden_sin_aprobar.fecha_inicial,
item_orden_sin_aprobar.fecha_final,
item_orden_sin_aprobar.unidades_por_pieza,
item_orden_sin_aprobar.cantidad_piezas,
item_orden_sin_aprobar.valor_unitario,
case
	when item_orden_sin_aprobar.valor_pactado_interno is not null then item_orden_sin_aprobar.valor_pactado_interno
	else item_orden_sin_aprobar.valor_pactado_cobol
end,
item_orden_sin_aprobar.fecha_grabacion,
convert(nvarchar, item_orden_sin_aprobar.fecha_grabacion, 108),
item_orden_sin_aprobar.usuario_cobol,
farm.correo,
item_orden_sin_aprobar.precio_mercado,
item_orden_sin_aprobar.box_charges,
item_orden_sin_aprobar.observacion,
cliente_factura.id_cliente_factura,
cliente_despacho.id_cliente_factura,
ciudad.impuesto_por_caja,
item_orden_sin_aprobar.valor_pactado_interno,
tipo_caja.factor_a_full,
farm.comision_farm,
tipo_farm.codigo,
isnull(item_orden_sin_aprobar.numero_po, '')
having
item_orden_sin_aprobar.id_item_orden_sin_aprobar = max(iosa.id_item_orden_sin_aprobar)

union all
/*visualizar ordenes que teniendo valor, siendo aprobadas y teniendo confirmacion de la finca no han sido confirmadas*/
select item_orden_sin_aprobar.id_item_orden_sin_aprobar,
vendedor.idc_vendedor,
ltrim(rtrim(vendedor.nombre)) as nombre_vendedor,
cliente_factura.idc_cliente_factura,
cliente_despacho.idc_cliente_despacho,
cliente_despacho.nombre_cliente,
tipo_factura.idc_tipo_factura,
tipo_factura.nombre_tipo_factura,
transportador.idc_transportador,
transportador.nombre_transportador,
tipo_flor.idc_tipo_flor,
tipo_flor.nombre_tipo_flor,
variedad_flor.idc_variedad_flor,
variedad_flor.nombre_variedad_flor,
grado_flor.idc_grado_flor,
grado_flor.nombre_grado_flor,
farm.id_farm,
farm.idc_farm,
farm.nombre_farm,
tapa.idc_tapa,
tapa.nombre_tapa,
tipo_caja.idc_tipo_caja + caja.idc_caja as idc_caja,
tipo_caja.idc_tipo_caja,
tipo_caja.nombre_tipo_caja,
item_orden_sin_aprobar.code,
item_orden_sin_aprobar.comentario,
item_orden_sin_aprobar.fecha_inicial,
item_orden_sin_aprobar.fecha_final,
item_orden_sin_aprobar.unidades_por_pieza,
item_orden_sin_aprobar.cantidad_piezas,
item_orden_sin_aprobar.valor_unitario,
solicitud_confirmacion_orden_especial.fecha_grabacion,
convert(nvarchar, solicitud_confirmacion_orden_especial.fecha_grabacion, 108),
cuenta_interna.nombre,
'No Farm Confirmed' as estado,
case
	when item_orden_sin_aprobar.valor_pactado_interno is not null then item_orden_sin_aprobar.valor_pactado_interno
	else 
	case
		when tipo_farm.codigo <> 'C' then 
		((((item_orden_sin_aprobar.valor_unitario - (
		(isnull((
			select sum(valor)
			from tipo_cargo,
			recargo_tipo_cargo
			where tipo_cargo.id_tipo_cargo = recargo_tipo_cargo.id_tipo_cargo
			and cliente_factura.id_cliente_factura = recargo_tipo_cargo.id_cliente_factura
			and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
			), 0)) / item_orden_sin_aprobar.unidades_por_pieza)) - ((item_orden_sin_aprobar.valor_unitario - (
		(isnull((
			select sum(valor)
			from tipo_cargo,
			recargo_tipo_cargo
			where tipo_cargo.id_tipo_cargo = recargo_tipo_cargo.id_tipo_cargo
			and cliente_factura.id_cliente_factura = recargo_tipo_cargo.id_cliente_factura
			and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
			), 0)) / item_orden_sin_aprobar.unidades_por_pieza)) * (convert(decimal(20,4), 35) / 100))) -  ((ciudad.impuesto_por_caja * tipo_caja.factor_a_full) / item_orden_sin_aprobar.unidades_por_pieza)))
		else
(
	(((item_orden_sin_aprobar.valor_unitario - (
	(	item_orden_sin_aprobar.box_charges +
	isnull((
		select sum(valor)
		from tipo_cargo,
		recargo_tipo_cargo
		where tipo_cargo.id_tipo_cargo = recargo_tipo_cargo.id_tipo_cargo
		and cliente_factura.id_cliente_factura = recargo_tipo_cargo.id_cliente_factura
		and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
		), 0)) / item_orden_sin_aprobar.unidades_por_pieza)) - ((item_orden_sin_aprobar.valor_unitario - (
	(	item_orden_sin_aprobar.box_charges +
	isnull((
		select sum(valor)
		from tipo_cargo,
		recargo_tipo_cargo
		where tipo_cargo.id_tipo_cargo = recargo_tipo_cargo.id_tipo_cargo
		and cliente_factura.id_cliente_factura = recargo_tipo_cargo.id_cliente_factura
		and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
		), 0)) / item_orden_sin_aprobar.unidades_por_pieza)) * (farm.comision_farm / 100))) -  ((ciudad.impuesto_por_caja * tipo_caja.factor_a_full) / item_orden_sin_aprobar.unidades_por_pieza))
) end
end as precio_finca,
0 as contiene_mail,
isnull((
	select top 1 orden_pedido.idc_orden_pedido
	from orden_pedido,
	orden_especial_confirmada,
	confirmacion_orden_especial_cultivo,
	solicitud_confirmacion_orden_especial,
	item_orden_sin_aprobar as i
	where orden_pedido.id_orden_pedido = orden_especial_confirmada.id_orden_pedido
	and orden_especial_confirmada.id_confirmacion_orden_especial_cultivo = confirmacion_orden_especial_cultivo.id_confirmacion_orden_especial_cultivo
	and confirmacion_orden_especial_cultivo.id_solicitud_confirmacion_orden_especial = solicitud_confirmacion_orden_especial.id_solicitud_confirmacion_orden_especial
	and solicitud_confirmacion_orden_especial.id_item_orden_sin_aprobar = i.id_item_orden_sin_aprobar
	and i.id_item_orden_sin_aprobar_padre = item_orden_sin_aprobar.id_item_orden_sin_aprobar_padre
	order by orden_especial_confirmada.id_orden_especial_confirmada desc
),0) as idc_orden_pedido,
farm.correo as correo_aprobacion,
solicitud_confirmacion_orden_especial.numero_solicitud as numero_consecutivo,
item_orden_sin_aprobar.precio_mercado,
item_orden_sin_aprobar.box_charges,
item_orden_sin_aprobar.observacion as observacion_procurement,
isnull(item_orden_sin_aprobar.numero_po, '') as numero_po,
item_orden_sin_aprobar.valor_pactado_interno
from cliente_factura,
cliente_despacho,
cuenta_interna,
orden_sin_aprobar,
vendedor,
item_orden_sin_aprobar,
transportador,
variedad_flor,
tipo_flor,
grado_flor,
farm,
tipo_farm,
ciudad,
tapa,
tipo_caja,
caja,
item_orden_sin_aprobar as iosa,
tipo_factura,
solicitud_confirmacion_orden_especial,
solicitud_confirmacion_orden_especial as sco
where tipo_caja.id_tipo_caja = caja.id_tipo_caja
and tipo_farm.id_tipo_farm = farm.id_tipo_farm
and ciudad.id_ciudad = farm.id_ciudad
and cliente_factura.id_cliente_factura = cliente_despacho.id_cliente_factura
and vendedor.id_vendedor = cliente_factura.id_vendedor
and cliente_despacho.id_despacho = orden_sin_aprobar.id_despacho
and tipo_factura.id_tipo_factura = orden_sin_aprobar.id_tipo_factura
and orden_sin_aprobar.id_orden_sin_aprobar = item_orden_sin_aprobar.id_orden_sin_aprobar
and item_orden_sin_aprobar.id_transportador = transportador.id_transportador
and item_orden_sin_aprobar.id_variedad_flor = variedad_flor.id_variedad_flor
and item_orden_sin_aprobar.id_grado_flor = grado_flor.id_grado_flor
and tipo_flor.id_tipo_flor = variedad_flor.id_tipo_flor
and tipo_flor.id_tipo_flor = grado_flor.id_tipo_flor
and item_orden_sin_aprobar.id_farm = farm.id_farm
and item_orden_sin_aprobar.id_tapa = tapa.id_tapa
and item_orden_sin_aprobar.id_caja = caja.id_caja
and item_orden_sin_aprobar.id_item_orden_sin_aprobar < = iosa.id_item_orden_sin_aprobar
and item_orden_sin_aprobar.id_item_orden_sin_aprobar_padre = iosa.id_item_orden_sin_aprobar_padre
and item_orden_sin_aprobar.id_item_orden_sin_aprobar = solicitud_confirmacion_orden_especial.id_item_orden_sin_aprobar
and solicitud_confirmacion_orden_especial.id_solicitud_confirmacion_orden_especial < = sco.id_solicitud_confirmacion_orden_especial
and solicitud_confirmacion_orden_especial.id_solicitud_confirmacion_orden_especial_padre = sco.id_solicitud_confirmacion_orden_especial_padre
and solicitud_confirmacion_orden_especial.aceptada = 1
and solicitud_confirmacion_orden_especial.id_cuenta_interna = cuenta_interna.id_cuenta_interna
and not exists
(
	select *
	from confirmacion_orden_especial_cultivo
	where solicitud_confirmacion_orden_especial.id_solicitud_confirmacion_orden_especial = confirmacion_orden_especial_cultivo.id_solicitud_confirmacion_orden_especial
)
and tipo_factura.idc_tipo_factura = '4'
group by
item_orden_sin_aprobar.id_item_orden_sin_aprobar_padre,
item_orden_sin_aprobar.id_item_orden_sin_aprobar,
vendedor.idc_vendedor,
ltrim(rtrim(vendedor.nombre)),
cliente_factura.idc_cliente_factura,
cliente_despacho.idc_cliente_despacho,
cliente_despacho.nombre_cliente,
tipo_factura.idc_tipo_factura,
tipo_factura.nombre_tipo_factura,
transportador.idc_transportador,
transportador.nombre_transportador,
tipo_flor.idc_tipo_flor,
tipo_flor.nombre_tipo_flor,
variedad_flor.idc_variedad_flor,
variedad_flor.nombre_variedad_flor,
grado_flor.idc_grado_flor,
grado_flor.nombre_grado_flor,
farm.id_farm,
farm.idc_farm,
farm.nombre_farm,
tapa.idc_tapa,
tapa.nombre_tapa,
caja.idc_caja,
tipo_caja.idc_tipo_caja,
tipo_caja.nombre_tipo_caja,
item_orden_sin_aprobar.code,
item_orden_sin_aprobar.comentario,
item_orden_sin_aprobar.fecha_inicial,
item_orden_sin_aprobar.fecha_final,
item_orden_sin_aprobar.unidades_por_pieza,
item_orden_sin_aprobar.cantidad_piezas,
item_orden_sin_aprobar.valor_unitario,
case
	when item_orden_sin_aprobar.valor_pactado_interno is not null then item_orden_sin_aprobar.valor_pactado_interno
	else item_orden_sin_aprobar.valor_pactado_cobol
end,
solicitud_confirmacion_orden_especial.fecha_grabacion,
convert(nvarchar, solicitud_confirmacion_orden_especial.fecha_grabacion, 108),
farm.correo,
solicitud_confirmacion_orden_especial.numero_solicitud,
cuenta_interna.nombre,
solicitud_confirmacion_orden_especial.id_solicitud_confirmacion_orden_especial,
item_orden_sin_aprobar.precio_mercado,
item_orden_sin_aprobar.box_charges,
item_orden_sin_aprobar.observacion,
cliente_factura.id_cliente_factura,
cliente_despacho.id_cliente_factura,
ciudad.impuesto_por_caja,
item_orden_sin_aprobar.valor_pactado_interno,
tipo_caja.factor_a_full,
farm.comision_farm,
tipo_farm.codigo,
isnull(item_orden_sin_aprobar.numero_po, '')
having
item_orden_sin_aprobar.id_item_orden_sin_aprobar = max(iosa.id_item_orden_sin_aprobar)
and solicitud_confirmacion_orden_especial.id_solicitud_confirmacion_orden_especial = max(sco.id_solicitud_confirmacion_orden_especial)

update #temp
set contiene_mail = 1
from farm
where #temp.id_farm = farm.id_farm
and farm.correo is not null
and len(farm.correo) > 7

select * 
from #temp
where idc_vendedor like
case
	when @idc_vendedor = '' THEN '%%'
	else @idc_vendedor
end
and estado like
case
	when @estado = '' then '%%'
	else @estado
end
order by fecha_grabacion desc

drop table #temp