set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

-- =============================================
-- Author:		Diego Pi�eros
-- Create date: 2010/08/02
-- Description:	Inserta nuevas versiones de �rdenes canceladas
-- =============================================

alter PROCEDURE [dbo].[apr_ord_crear_version_item_orden_especial_sin_aprobar_version2] 

@id_item_orden_sin_aprobar int,
@idc_cliente_despacho nvarchar(255),
@idc_tipo_factura nvarchar(255),
@idc_transportador nvarchar(255),
@idc_tipo_flor nvarchar(255),
@idc_variedad_flor nvarchar(255),
@idc_grado_flor nvarchar(255),
@idc_farm nvarchar(255),
@idc_tapa nvarchar(255),
@idc_caja nvarchar(255),
@code nvarchar(255),
@comentario nvarchar(1024),
@fecha_inicial datetime, 
@fecha_final datetime,
@unidades_por_pieza int, 
@cantidad_piezas int, 
@valor_unitario decimal(20,4), 
@valor_pactado_orden_especial decimal(20,4), 
@usuario_cobol nvarchar(255),
@box_charges decimal(20,4), 
@precio_mercado decimal(20,4),
@observacion nvarchar(1024)

as

declare @id_item_orden_sin_aprobar_padre int,
@id_orden_sin_aprobar int,
@id_orden_sin_aprobar_aux int,
@conteo int

select @id_item_orden_sin_aprobar_padre = item_orden_sin_aprobar.id_item_orden_sin_aprobar_padre,
@id_orden_sin_aprobar_aux = orden_sin_aprobar.id_orden_sin_aprobar
from item_orden_sin_aprobar,
orden_sin_aprobar
where orden_sin_aprobar.id_orden_sin_aprobar = item_orden_sin_aprobar.id_orden_sin_aprobar
and item_orden_sin_aprobar.id_item_orden_sin_aprobar = @id_item_orden_sin_aprobar

select @conteo = count(*)
from orden_sin_aprobar,
tipo_factura,
cliente_despacho
where cliente_despacho.id_despacho = orden_sin_aprobar.id_despacho
and tipo_factura.id_tipo_factura = orden_sin_aprobar.id_tipo_factura
and orden_sin_aprobar.id_orden_sin_aprobar = @id_orden_sin_aprobar_aux
and cliente_despacho.idc_cliente_despacho = @idc_cliente_despacho
and tipo_factura.idc_tipo_factura = @idc_tipo_factura

if(@conteo = 0)
begin
	insert into orden_sin_aprobar (id_despacho, id_tipo_factura)
	select cliente_despacho.id_despacho,
	tipo_factura.id_tipo_factura
	from cliente_despacho,
	tipo_factura
	where cliente_despacho.idc_cliente_despacho = @idc_cliente_despacho
	and tipo_factura.idc_tipo_factura = @idc_tipo_factura

	set @id_orden_sin_aprobar = scope_identity()
end
else
begin
	set @id_orden_sin_aprobar = @id_orden_sin_aprobar_aux
end

insert into item_orden_sin_aprobar 
(
	id_item_orden_sin_aprobar_padre,
	id_transportador, 
	id_orden_sin_aprobar, 
	id_variedad_flor, 
	id_grado_flor, 
	id_farm, 
	id_tapa, 
	id_caja, 
	code, 
	comentario, 
	fecha_inicial, 
	fecha_final, 
	unidades_por_pieza, 
	cantidad_piezas, 
	valor_unitario, 
	valor_pactado_cobol,
	usuario_cobol,
	box_charges, 
	precio_mercado,
	observacion
)
select @id_item_orden_sin_aprobar_padre,
transportador.id_transportador,
@id_orden_sin_aprobar,
variedad_flor.id_variedad_flor,
grado_flor.id_grado_flor,
farm.id_farm,
tapa.id_tapa,
caja.id_caja,
@code,
@comentario,
@fecha_inicial, 
@fecha_final,
@unidades_por_pieza, 
@cantidad_piezas, 
@valor_unitario, 
@valor_pactado_orden_especial,
@usuario_cobol,
@box_charges, 
@precio_mercado,
@observacion
from transportador,
variedad_flor,
tipo_flor,
grado_flor,
farm,
tapa,
tipo_caja,
caja
where tipo_caja.id_tipo_caja = caja.id_tipo_caja
and transportador.idc_transportador = @idc_transportador
and tipo_flor.id_tipo_flor = variedad_flor.id_tipo_flor
and variedad_flor.idc_variedad_flor = @idc_variedad_flor
and tipo_flor.idc_tipo_flor = @idc_tipo_flor
and tipo_flor.id_tipo_flor = grado_flor.id_tipo_flor
and grado_flor.idc_grado_flor = @idc_grado_flor
and farm.idc_farm = @idc_farm
and tapa.idc_tapa = @idc_tapa
and tipo_caja.idc_tipo_caja + caja.idc_caja = @idc_caja

set @id_item_orden_sin_aprobar = scope_identity()

select @id_item_orden_sin_aprobar as id_item_orden_sin_aprobar