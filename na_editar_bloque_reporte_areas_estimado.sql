/****** Object:  StoredProcedure [dbo].[gc_editar_cuenta_interna_grupo]    Script Date: 10/06/2007 11:25:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter PROCEDURE [dbo].[na_editar_bloque_reporte_areas_estimado]

@id_variedad_flor int,
@fecha datetime

AS

declare @promedio_estimado int,
@cantidad_periodos int

select @promedio_estimado = tallos_estimados_a�o from variedad_flor 
where id_variedad_flor = @id_variedad_flor

set @cantidad_periodos = 52

declare @cantidad_tallos_maxima decimal(20,4)

select bloque.id_bloque,
bloque.idc_bloque,
bloque.area,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)) as nombre_tipo_flor,
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)) as nombre_variedad_flor,
datepart(wk,pieza_postcosecha.fecha_entrada) as semana,
sum(pieza_postcosecha.unidades_por_pieza) as cantidad_tallos,
(
	select count(cama.id_cama)
	from cama,
	cama_bloque,
	construir_cama_bloque,
	sembrar_cama_bloque,
	tipo_flor as tf,
	variedad_flor as vf,
	bloque as b
	where b.id_bloque = cama_bloque.id_bloque
	and cama_bloque.id_bloque = construir_cama_bloque.id_bloque
	and cama_bloque.id_nave = construir_cama_bloque.id_nave
	and cama_bloque.id_cama = construir_cama_bloque.id_cama
	and construir_cama_bloque.id_construir_cama_bloque = sembrar_cama_bloque.id_construir_cama_bloque
	and vf.id_variedad_flor = sembrar_cama_bloque.id_variedad_flor
	and tf.id_tipo_flor = vf.id_tipo_flor
	and vf.id_variedad_flor = @id_variedad_flor
	and cama.id_cama = cama_bloque.id_cama
	and tf.id_tipo_flor = tipo_flor.id_tipo_flor
	and vf.id_variedad_flor = variedad_flor.id_variedad_flor
	and b.id_bloque = bloque.id_bloque
	group by b.id_bloque
) as camas_sembradas,
(
	select count(distinct construir_cama_bloque.id_construir_cama_bloque)
	from bloque as b,
	cama_bloque,
	construir_cama_bloque
	where b.id_bloque = cama_bloque.id_bloque
	and cama_bloque.id_bloque = construir_cama_bloque.id_bloque
	and cama_bloque.id_cama = construir_cama_bloque.id_cama
	and cama_bloque.id_nave = construir_cama_bloque.id_nave
	and bloque.id_bloque = b.id_bloque
	group by b.id_bloque
) as camas_totales,
(
	select max(sembrar_cama_bloque.fecha)
	from cama,
	cama_bloque,
	construir_cama_bloque,
	sembrar_cama_bloque,
	tipo_flor as tf,
	variedad_flor as vf,
	bloque as b
	where b.id_bloque = cama_bloque.id_bloque
	and cama_bloque.id_bloque = construir_cama_bloque.id_bloque
	and cama_bloque.id_nave = construir_cama_bloque.id_nave
	and cama_bloque.id_cama = construir_cama_bloque.id_cama
	and construir_cama_bloque.id_construir_cama_bloque = sembrar_cama_bloque.id_construir_cama_bloque
	and vf.id_variedad_flor = sembrar_cama_bloque.id_variedad_flor
	and tf.id_tipo_flor = vf.id_tipo_flor
	and vf.id_variedad_flor = @id_variedad_flor
	and cama.id_cama = cama_bloque.id_cama
	and tf.id_tipo_flor = tipo_flor.id_tipo_flor
	and vf.id_variedad_flor = variedad_flor.id_variedad_flor
	and b.id_bloque = bloque.id_bloque
	group by b.id_bloque
) as fecha_siembra into #temp
from bloque,
pieza_postcosecha,
tipo_flor,
variedad_flor
where bloque.id_bloque = pieza_postcosecha.id_bloque
and pieza_postcosecha.id_variedad_flor = variedad_flor.id_variedad_flor
and tipo_flor.id_tipo_flor = variedad_flor.id_tipo_flor
and variedad_flor.id_variedad_flor = @id_variedad_flor
and convert(datetime, convert(nvarchar,pieza_postcosecha.fecha_entrada,101)) between
DATEADD(wk, DATEDIFF(wk,0,@fecha), 0) and dateadd(dd, -1, DATEADD(wk, DATEDIFF(wk,0,@fecha)+1, 0))
group by bloque.id_bloque,
bloque.idc_bloque,
bloque.area,
tipo_flor.id_tipo_flor,
tipo_flor.idc_tipo_flor,
ltrim(rtrim(tipo_flor.nombre_tipo_flor)),
variedad_flor.id_variedad_flor,
variedad_flor.idc_variedad_flor,
ltrim(rtrim(variedad_flor.nombre_variedad_flor)),
datepart(wk,pieza_postcosecha.fecha_entrada)
having bloque.area is not null

alter table #temp
add cantidad_tallos_maxima decimal(20,4),
promedio decimal(20,4),
area_por_cama decimal(20,4),
area_por_cama_unitaria decimal(20,4)

/*calcular el �rea que cada cama utiliza del bloque en total*/
update #temp
set area_por_cama = (area/camas_totales) * camas_sembradas,
area_por_cama_unitaria = (area/camas_totales)

/*calcular el promedio de cada bloque en los diferentes periodos de tiempo*/
update #temp
set promedio = cantidad_tallos/area_por_cama

/*colocar el promedio m�ximo para que todas las gr�ficas del reporte vayan hasta el mismo valor en el eje X*/
select @cantidad_tallos_maxima = max(area_por_cama * (@promedio_estimado/convert(decimal(20,4),@cantidad_periodos)))
from #temp

update #temp
set cantidad_tallos_maxima = @cantidad_tallos_maxima

select area_por_cama * (@promedio_estimado/convert(decimal(20,4),@cantidad_periodos)) as cantidad_tallos_estimada_semanal, 
* 
from #temp
order by idc_bloque

drop table #temp