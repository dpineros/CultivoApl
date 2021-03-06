set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

alter PROCEDURE [dbo].[na_consultar_dia_vuelo_finca_preventa]

@idc_farm nvarchar(2),
@fecha datetime

AS

declare @dias_atras_finca int,
@dias_restados_despacho_distribuidora int,
@dias_atras_finca_preventa int,
@id_tipo_despacho int,
@conteo int,
@dia_semana int,
@corrimiento_preventa_activo bit,
@idc_tipo_factura nvarchar(10),
@fecha_inicial datetime,
@id_tipo_venta int

set @fecha_inicial = @fecha
select @corrimiento_preventa_activo = corrimiento_preventa_activo from configuracion_bd
select @dias_atras_finca = cantidad_dias_despacho_finca from configuracion_bd
select @dias_atras_finca_preventa = cantidad_dias_despacho_finca_preventa from configuracion_bd
select @dias_restados_despacho_distribuidora = dias_restados_despacho_distribuidora from farm where idc_farm = @idc_farm

select @id_tipo_venta = tipo_venta.id_tipo_venta
from temporada_a�o,
temporada_cubo,
tipo_venta
where tipo_venta.id_tipo_venta = temporada_a�o.id_tipo_venta
and temporada_a�o.id_temporada = temporada_cubo.id_temporada
and temporada_a�o.id_a�o = temporada_cubo.id_a�o
and @fecha between
temporada_cubo.fecha_inicial and temporada_cubo.fecha_final

if(@id_tipo_venta = 2)
begin
	set @corrimiento_preventa_activo = 0
	set @dias_atras_finca_preventa = 0
end

set @fecha = @fecha - @dias_atras_finca - @dias_restados_despacho_distribuidora - @dias_atras_finca_preventa

select @dia_semana = datepart(dw, @fecha)

if(@corrimiento_preventa_activo = 1)
begin
	set @idc_tipo_factura = '4'
end
else
begin
	set @idc_tipo_factura = 'all'
end

create table #temp 
(
	id_dia_despacho int,
	nombre_dia_despacho nvarchar(255),
	id_tipo_despacho int,
	nombre_tipo_despacho nvarchar(255)
)

select @conteo = count(*) 
from forma_despacho_farm, 
farm,
---------------------------------
tipo_factura
---------------------------------
where farm.id_farm = forma_despacho_farm.id_farm
---------------------------------
and tipo_factura.id_tipo_factura = forma_despacho_farm.id_tipo_factura
and tipo_factura.idc_tipo_factura = @idc_tipo_factura
---------------------------------
and farm.idc_farm = @idc_farm

if(@conteo > = 1)
begin
	insert into #temp (id_dia_despacho,	nombre_dia_despacho, id_tipo_despacho, nombre_tipo_despacho)
	select dia_despacho.id_dia_despacho,
	dia_despacho.nombre_dia_despacho,
	tipo_despacho.id_tipo_despacho,
	tipo_despacho.nombre_tipo_despacho
	from tipo_factura,
	forma_despacho_farm,
	tipo_despacho,
	dia_despacho,
	farm
	where tipo_factura.id_tipo_factura = forma_despacho_farm.id_tipo_factura
	and tipo_despacho.id_tipo_despacho = forma_despacho_farm.id_tipo_despacho
	and dia_despacho.id_dia_despacho = forma_despacho_farm.id_dia_despacho
	and tipo_factura.idc_tipo_factura = @idc_tipo_factura
	and farm.id_farm = forma_despacho_farm.id_farm
	and farm.idc_farm = @idc_farm
end
else
begin
	insert into #temp (id_dia_despacho,	nombre_dia_despacho, id_tipo_despacho, nombre_tipo_despacho)
	select dia_despacho.id_dia_despacho,
	dia_despacho.nombre_dia_despacho,
	tipo_despacho.id_tipo_despacho,
	tipo_despacho.nombre_tipo_despacho
	from tipo_factura,
	forma_despacho_ciudad,
	tipo_despacho,
	dia_despacho,
	farm,
	ciudad
	where tipo_factura.id_tipo_factura = forma_despacho_ciudad.id_tipo_factura
	and tipo_despacho.id_tipo_despacho = forma_despacho_ciudad.id_tipo_despacho
	and dia_despacho.id_dia_despacho = forma_despacho_ciudad.id_dia_despacho
	and tipo_factura.idc_tipo_factura = @idc_tipo_factura
	and ciudad.id_ciudad = forma_despacho_ciudad.id_ciudad
	and farm.id_ciudad = ciudad.id_ciudad
	and farm.idc_farm = @idc_farm
end

select @id_tipo_despacho = id_tipo_despacho 
from #temp
where id_dia_despacho = @dia_semana

if(@id_tipo_despacho = 3 or @id_tipo_despacho = 2)
begin
	select
	case
		when datepart(dw,@fecha_inicial) = id_dia_despacho then @fecha_inicial - 7
		when datepart(dw,@fecha_inicial) > id_dia_despacho then @fecha_inicial-(datepart(dw, @fecha_inicial) - id_dia_despacho)
		when datepart(dw,@fecha_inicial) < id_dia_despacho then @fecha_inicial-(datepart(dw,@fecha_inicial) - id_dia_despacho + 7)
	end as fecha
	from #temp 
	where id_dia_despacho = @dia_semana
end
else
begin
	set @dia_semana = replace(@dia_semana + 1, 8, 1)

	select @id_tipo_despacho = id_tipo_despacho
	from #temp
	where id_dia_despacho = @dia_semana
	
	if(@id_tipo_despacho = 3)
	begin
		select
		case
			when datepart(dw,@fecha_inicial) = id_dia_despacho then @fecha_inicial - 7
			when datepart(dw,@fecha_inicial) > id_dia_despacho then @fecha_inicial-(datepart(dw, @fecha_inicial) - id_dia_despacho)
			when datepart(dw,@fecha_inicial) < id_dia_despacho then @fecha_inicial-(datepart(dw,@fecha_inicial) - id_dia_despacho + 7)
		end as fecha
		from #temp 
		where id_dia_despacho = @dia_semana
	end
	else
	begin
		select @dia_semana = id_dia_despacho,
		@id_tipo_despacho = id_tipo_despacho
		from #temp
		where id_dia_despacho = replace(@dia_semana - 1, 0, 7)

		while(@id_tipo_despacho = 1)
		begin
			select @dia_semana = id_dia_despacho,
			@id_tipo_despacho = id_tipo_despacho
			from #temp
			where id_dia_despacho = replace(@dia_semana - 1, 0, 7)
		end

		select
		case
			when datepart(dw,@fecha_inicial) = id_dia_despacho then @fecha_inicial - 7
			when datepart(dw,@fecha_inicial) > id_dia_despacho then @fecha_inicial-(datepart(dw, @fecha_inicial) - id_dia_despacho)
			when datepart(dw,@fecha_inicial) < id_dia_despacho then @fecha_inicial-(datepart(dw,@fecha_inicial) - id_dia_despacho + 7)
		end as fecha
		from #temp 
		where id_dia_despacho = @dia_semana
	end
end

drop table #temp
