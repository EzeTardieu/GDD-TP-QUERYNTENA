use GD1C2020
--Algunas tablas no son necesarias crearlas porque ya están de cuando migramos, por ej: Cliente, Empresa(son los proveedores), tipos de habitaciones, aviones, rutas
/*
drop table QUERYNTENA.HechosPasajeCompras
drop table QUERYNTENA.HechosEstadiaCompras
drop table QUERYNTENA.HechosPasajeVentas
drop table QUERYNTENA.HechosEstadiaVentas
drop table QUERYNTENA.Dimension_Ciudad
drop table QUERYNTENA.Dimension_Tipo_Pasaje
*/

create table QUERYNTENA.Dimension_Ciudad (
	ciud_id int IDENTITY(1,1) PRIMARY KEY,
	ciud_nombre nvarchar(255)
)

create table QUERYNTENA.Dimension_Tipo_Pasaje (
	tipo_pasaje_id int IDENTITY(1,1) PRIMARY KEY,
	tipo_pasaje_nombre nvarchar(255)
)

insert into QUERYNTENA.Dimension_Tipo_Pasaje(tipo_pasaje_nombre) (select distinct buta_tipo from QUERYNTENA.Butaca_Vuelo)

insert into QUERYNTENA.Dimension_Ciudad(ciud_nombre) (select ruta_ciu_dest from QUERYNTENA.Ruta_Aerea union select ruta_ciu_orig from QUERYNTENA.Ruta_Aerea)


--Se crea las tablas de hechos...
create table QUERYNTENA.HechosEstadiaCompras (
	hechos_año int,
	hechos_mes int,
	hechos_proveedor int Foreign Key references QUERYNTENA.Empresa(empr_id),
	hechos_tipo_habitacion decimal(18,0) Foreign Key references QUERYNTENA.Tipo_Habitacion(tipo_habitacion_codigo),
	Primary key(hechos_año,hechos_mes,hechos_proveedor,hechos_tipo_habitacion),
	hechos_precio_prom_compra_estadias decimal(18,2),
	hechos_cantidad_camas int
)
create table QUERYNTENA.HechosEstadiaVentas (
	hechos_año int,
	hechos_mes int,
	hechos_cliente_edad int,
	hechos_tipo_habitacion decimal(18,0) Foreign Key references QUERYNTENA.Tipo_Habitacion(tipo_habitacion_codigo),
	Primary key(hechos_año,hechos_mes,hechos_cliente_edad,hechos_tipo_habitacion),
	hechos_precio_prom_venta_estadias decimal(18,2),
	hechos_cantidad_camas int,
	hechos_habitaciones_vendidas int,
	hechos_ganancia_estadias decimal(18,2)
)

create table QUERYNTENA.HechosPasajeCompras (
	hechos_año int,
	hechos_mes int,
	hechos_ciudad int Foreign Key references QUERYNTENA.Dimension_Ciudad(ciud_id),
	hechos_tipo_pasaje int Foreign Key references QUERYNTENA.Dimension_Tipo_Pasaje(tipo_pasaje_id),
	hechos_proveedor int Foreign Key references QUERYNTENA.Empresa(empr_id),
	hechos_avion nvarchar(50) Foreign Key references QUERYNTENA.Avion(avio_id),
	hechos_ruta int Foreign Key references QUERYNTENA.Ruta_Aerea(ruta_id)
	Primary key(hechos_año,hechos_mes,hechos_ciudad,hechos_tipo_pasaje,hechos_proveedor,hechos_avion,hechos_ruta),
	hechos_precio_prom_compra_pasajes decimal(18,2)
)

create table QUERYNTENA.HechosPasajeVentas (
	hechos_año int,
	hechos_mes int,
	hechos_ciudad int Foreign Key references QUERYNTENA.Dimension_Ciudad(ciud_id),
	hechos_tipo_pasaje int Foreign Key references QUERYNTENA.Dimension_Tipo_Pasaje(tipo_pasaje_id),
	hechos_cliente_edad int,
	hechos_avion nvarchar(50) Foreign Key references QUERYNTENA.Avion(avio_id),
	hechos_ruta int Foreign Key references QUERYNTENA.Ruta_Aerea(ruta_id)
	Primary key(hechos_año,hechos_mes,hechos_ciudad,hechos_tipo_pasaje,hechos_cliente_edad,hechos_avion,hechos_ruta),
	hechos_precio_prom_venta_pasajes decimal(18,2),
	hechos_pasajes_vendidos int,
	hechos_ganancia_pasajes decimal(18,2)
)

IF OBJECT_ID('QUERYNTENA.getCiudadDestinoId') is not null
DROP FUNCTION QUERYNTENA.getCiudadDestinoId 
GO

CREATE FUNCTION QUERYNTENA.getCiudadDestinoId (@unaRuta int)
RETURNS int
AS 
begin
return (select ciud_id from Ruta_Aerea join Dimension_Ciudad on ruta_ciu_dest = ciud_nombre where @unaRuta = ruta_id)
END
go

IF OBJECT_ID('QUERYNTENA.FX_EDAD') IS NOT NULL DROP FUNCTION QUERYNTENA.FX_EDAD
GO
CREATE FUNCTION QUERYNTENA.FX_EDAD (@FECHA_NAC datetime2(3), @FECHA_COMPRA datetime2(3)) RETURNS INT
BEGIN
DECLARE @EDAD INT
IF ((MONTH(@FECHA_COMPRA) > MONTH(@FECHA_NAC) OR (MONTH(@FECHA_COMPRA) = MONTH(@FECHA_NAC) AND DAY(@FECHA_COMPRA)>=DAY(@FECHA_NAC))))
SET @EDAD = datediff(yy, @FECHA_NAC,@FECHA_COMPRA)
ELSE 
SET  @EDAD = datediff(yy, @FECHA_NAC,@FECHA_COMPRA) - 1
RETURN @EDAD
END
GO

/*A la hora de insertar los valores, como no se puede tener nulls en las pks decidimos dividir los hechos en 4 tablas diferentes para solucionar el problema*/
insert into QUERYNTENA.HechosEstadiaCompras(hechos_año,hechos_mes,hechos_proveedor,hechos_tipo_habitacion,hechos_precio_prom_compra_estadias)
select year(cest_fecha),month(cest_fecha),cest_empresa,habi_tipo,avg(cest_costo_total) from QUERYNTENA.Compra_Estadia
join QUERYNTENA.Habitacion_Estadia on cest_estadia = hest_estadia join QUERYNTENA.Habitacion on hest_habitacion_nro = habi_numero and habi_hotel = hest_hotel 
group by cest_empresa,habi_tipo,year(cest_fecha),month(cest_fecha)

insert into QUERYNTENA.HechosEstadiaVentas(hechos_año,hechos_mes,hechos_cliente_edad,hechos_tipo_habitacion,hechos_precio_prom_venta_estadias,hechos_habitaciones_vendidas,hechos_ganancia_estadias)
select year(fact_fecha),month(fact_fecha),QUERYNTENA.FX_EDAD(clie_fecha_nac,fact_fecha),habi_tipo,avg(vest_precio_final),count(*),sum(vest_precio_final -cest_costo_total) from QUERYNTENA.Venta_Estadias join queryntena.Factura on vest_factura = fact_numero 
join QUERYNTENA.Habitacion_Estadia on vest_estadia = hest_estadia join QUERYNTENA.Habitacion on hest_habitacion_nro = habi_numero and habi_hotel = hest_hotel
join QUERYNTENA.Compra_Estadia on cest_estadia = vest_estadia
join QUERYNTENA.Cliente on clie_id = fact_cliente
group by year(fact_fecha),month(fact_fecha),QUERYNTENA.FX_EDAD(clie_fecha_nac,fact_fecha),habi_tipo


update QUERYNTENA.HechosEstadiaCompras set hechos_cantidad_camas = (case hechos_tipo_habitacion when 1001 then 1 when 1002 then 2 when 1003 then 3 when 1004 then 4 when 1005 then 5 end)
update QUERYNTENA.HechosEstadiaVentas set hechos_cantidad_camas = (case hechos_tipo_habitacion when 1001 then 1 when 1002 then 2 when 1003 then 3 when 1004 then 4 when 1005 then 5 end)

insert into QUERYNTENA.HechosPasajeCompras(hechos_año,hechos_mes,hechos_proveedor,hechos_tipo_pasaje,hechos_avion,hechos_ruta,hechos_ciudad,hechos_precio_prom_compra_pasajes)--Tomamos la ciudad destino a la hora de insertar
select year(cpas_fecha),month(cpas_fecha),cpas_empresa,tipo_pasaje_id,vuel_avion,vuel_ruta_aerea,QUERYNTENA.getCiudadDestinoId(vuel_ruta_aerea),avg(pasa_costo) from QUERYNTENA.Compra_Pasaje
join QUERYNTENA.Pasaje on pasa_compra_nro = cpas_numero
join QUERYNTENA.Butaca_Vuelo on pasa_butaca = buta_id
join QUERYNTENA.Dimension_Tipo_Pasaje on buta_tipo = tipo_pasaje_nombre
join QUERYNTENA.Vuelo on vuel_codigo = pasa_vuelo
group by year(cpas_fecha),month(cpas_fecha),cpas_empresa,tipo_pasaje_id,vuel_avion,vuel_ruta_aerea,QUERYNTENA.getCiudadDestinoId(vuel_ruta_aerea)


insert into QUERYNTENA.HechosPasajeVentas(hechos_año,hechos_mes,hechos_cliente_edad,hechos_tipo_pasaje,hechos_avion,hechos_ruta,hechos_ciudad,hechos_precio_prom_venta_pasajes,hechos_pasajes_vendidos,hechos_ganancia_pasajes)--Tomamos la ciudad destino a la hora de insertar
select year(fact_fecha),month(fact_fecha),QUERYNTENA.FX_EDAD(clie_fecha_nac,fact_fecha),tipo_pasaje_id,vuel_avion,vuel_ruta_aerea,QUERYNTENA.getCiudadDestinoId(vuel_ruta_aerea),avg(pasa_precio),count(*),sum(pasa_precio-pasa_costo) from QUERYNTENA.Venta_Pasaje
join QUERYNTENA.Factura on fact_numero = vpas_factura
join QUERYNTENA.Pasaje on pasa_venta_id = vpas_id
join QUERYNTENA.Butaca_Vuelo on pasa_butaca = buta_id
join QUERYNTENA.Dimension_Tipo_Pasaje on buta_tipo = tipo_pasaje_nombre
join QUERYNTENA.Vuelo on vuel_codigo = pasa_vuelo
join QUERYNTENA.Cliente on clie_id = fact_cliente
group by year(fact_fecha),month(fact_fecha),QUERYNTENA.FX_EDAD(clie_fecha_nac,fact_fecha),tipo_pasaje_id,vuel_avion,vuel_ruta_aerea,QUERYNTENA.getCiudadDestinoId(vuel_ruta_aerea)


--Ejemplos...
/*
--Ganancia obtenida de pasajes de la fecha de julio 2018
select sum(isnull(hechos_ganancia_pasajes,0)) from QUERYNTENA.HechosPasajeVentas 
where hechos_año = 2018 and hechos_mes = 7

--cantidad de pasajes con destino a luanda que hubo en enero de 2018
select sum(hechos_pasajes_vendidos) from QUERYNTENA.HechosPasajeVentas join QUERYNTENA.Dimension_Ciudad on ciud_id = hechos_ciudad
where ciud_nombre = 'LUANDA' and hechos_año= 2018 and hechos_mes = 1

--dinero gastado en promedio en compras de estadias en 2018 al proveedor Hilton
select avg(hechos_precio_prom_compra_estadias) from QUERYNTENA.HechosEstadiaCompras join QUERYNTENA.Empresa on hechos_proveedor = empr_id
where hechos_año = 2018 and empr_razon_social = 'HILTON'

*/