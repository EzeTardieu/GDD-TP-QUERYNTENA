use GD1C2020
--Algunas tablas no son necesarias crearlas porque ya están de cuando migramos, por ej: Cliente, Empresa(son los proveedores), tipos de habitaciones, aviones, rutas

create table QUERYNTENA.Dimension_Tiempo (
	tiem_id int IDENTITY(1,1) PRIMARY KEY,
	tiem_anio int,
	tiem_mes int
)

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

insert into QUERYNTENA.Dimension_Tiempo(tiem_anio,tiem_mes) (select year(cest_fecha),month(cest_fecha) from QUERYNTENA.Compra_Estadia
	union select year(cpas_fecha),month(cpas_fecha) from QUERYNTENA.Compra_Pasaje 
	union select year(fact_fecha),month(fact_fecha) from QUERYNTENA.Factura)

--Se crea la tabla de hechos...
--drop table QUERYNTENA.Hechos
create table QUERYNTENA.Hechos (
	hechos_tiempo int Foreign Key references QUERYNTENA.Dimension_Tiempo(tiem_id),
	hechos_ciudad int Foreign Key references QUERYNTENA.Dimension_Ciudad(ciud_id),
	hechos_tipo_pasaje int Foreign Key references QUERYNTENA.Dimension_Tipo_Pasaje(tipo_pasaje_id),
	hechos_cliente int Foreign Key references QUERYNTENA.Cliente(clie_id),
	hechos_proveedor int Foreign Key references QUERYNTENA.Empresa(empr_id),
	hechos_tipo_habitacion decimal(18,0) Foreign Key references QUERYNTENA.Tipo_Habitacion(tipo_habitacion_codigo),
	hechos_avion nvarchar(50) Foreign Key references QUERYNTENA.Avion(avio_id),
	hechos_ruta int Foreign Key references QUERYNTENA.Ruta_Aerea(ruta_id)
	Primary key(hechos_tiempo,hechos_ciudad,hechos_tipo_pasaje,hechos_cliente,hechos_proveedor,hechos_tipo_habitacion,hechos_avion,hechos_ruta),
	hechos_precio_prom_compra_estadias decimal(18,2),
	hechos_precio_prom_venta_estadias decimal(18,2),
	hechos_precio_prom_compra_pasajes decimal(18,2),
	hechos_precio_prom_venta_pasajes decimal(18,2),
	hechos_cantidad_camas int,
	hechos_habitaciones_vendidas int,
	hechos_pasajes_vendidos int,
	hechos_ganancia_pasajes decimal(18,2),
	hechos_ganancia_estadias decimal(18,2)
)

IF OBJECT_ID('QUERYNTENA.getFechaId') is not null
DROP FUNCTION QUERYNTENA.getFechaId 
GO

CREATE FUNCTION QUERYNTENA.getFechaId (@unaFecha datetime2(3))
RETURNS int
AS 
begin
return (select tiem_id from QUERYNTENA.Dimension_Tiempo where tiem_anio = year(@unaFecha) and tiem_mes = month(@unaFecha))
END

IF OBJECT_ID('QUERYNTENA.getCiudadDestinoId') is not null
DROP FUNCTION QUERYNTENA.getCiudadDestinoId 
GO

CREATE FUNCTION QUERYNTENA.getCiudadDestinoId (@unaRuta int)
RETURNS int
AS 
begin
return (select ciud_id from Ruta_Aerea join Dimension_Ciudad on ruta_ciu_dest = ciud_nombre where @unaRuta = ruta_id)
END

--FALTA PODER INSERTARLO, CON NULLS NO SE PUEDE. OPCIONES: PONER 0 a lo que no tienen valor
insert into QUERYNTENA.Hechos(hechos_tiempo,hechos_proveedor,hechos_tipo_habitacion,hechos_precio_prom_compra_estadias)
select QUERYNTENA.getFechaId(cest_fecha),cest_empresa,habi_tipo,avg(cest_costo_total) from QUERYNTENA.Compra_Estadia
join QUERYNTENA.Habitacion_Estadia on cest_estadia = hest_estadia join QUERYNTENA.Habitacion on hest_habitacion_nro = habi_numero and habi_hotel = hest_hotel 
group by QUERYNTENA.getFechaId(cest_fecha),cest_empresa,habi_tipo

insert into QUERYNTENA.Hechos(hechos_tiempo,hechos_cliente,hechos_tipo_habitacion,hechos_precio_prom_compra_estadias)
select QUERYNTENA.getFechaId(fact_fecha),fact_cliente,habi_tipo,avg(vest_precio_final) from QUERYNTENA.Venta_Estadias join queryntena.Factura on vest_factura = fact_numero 
join QUERYNTENA.Habitacion_Estadia on vest_estadia = hest_estadia join QUERYNTENA.Habitacion on hest_habitacion_nro = habi_numero and habi_hotel = hest_hotel 
group by QUERYNTENA.getFechaId(fact_fecha),fact_cliente,habi_tipo

insert into QUERYNTENA.Hechos(hechos_tiempo,hechos_proveedor,hechos_tipo_pasaje,hechos_avion,hechos_ruta,hechos_ciudad,hechos_precio_prom_compra_pasajes)--Tomamos la ciudad destino a la hora de insertar
select QUERYNTENA.getFechaId(cpas_fecha),cpas_empresa,tipo_pasaje_id,vuel_avion,vuel_ruta_aerea,QUERYNTENA.getCiudadDestinoId(vuel_ruta_aerea),avg(cpas_costo_total) from QUERYNTENA.Compra_Pasaje
join QUERYNTENA.Pasaje on pasa_compra_nro = cpas_numero
join QUERYNTENA.Butaca_Vuelo on pasa_butaca = buta_id
join QUERYNTENA.Dimension_Tipo_Pasaje on buta_tipo = tipo_pasaje_nombre--ESTE join deberia ser innecesario, en la tabla butaca_vuelo deberia tener el id del tipo y no el nombre de este
join QUERYNTENA.Vuelo on vuel_codigo = pasa_vuelo
group by QUERYNTENA.getFechaId(cpas_fecha),cpas_empresa,tipo_pasaje_id,vuel_avion,vuel_ruta_aerea,QUERYNTENA.getCiudadDestinoId(vuel_ruta_aerea)

insert into QUERYNTENA.Hechos(hechos_tiempo,hechos_cliente,hechos_tipo_pasaje,hechos_avion,hechos_ruta,hechos_ciudad,hechos_precio_prom_venta_pasajes)--Tomamos la ciudad destino a la hora de insertar
select QUERYNTENA.getFechaId(fact_fecha),fact_cliente,tipo_pasaje_id,vuel_avion,vuel_ruta_aerea,QUERYNTENA.getCiudadDestinoId(vuel_ruta_aerea),avg(vpas_precio_final) from QUERYNTENA.Venta_Pasaje
join QUERYNTENA.Factura on fact_numero = vpas_factura
join QUERYNTENA.Pasaje on pasa_venta_id = vpas_id
join QUERYNTENA.Butaca_Vuelo on pasa_butaca = buta_id
join QUERYNTENA.Dimension_Tipo_Pasaje on buta_tipo = tipo_pasaje_nombre--ESTE join deberia ser innecesario, en la tabla butaca_vuelo deberia tener el id del tipo y no el nombre de este
join QUERYNTENA.Vuelo on vuel_codigo = pasa_vuelo
group by QUERYNTENA.getFechaId(fact_fecha),fact_cliente,tipo_pasaje_id,vuel_avion,vuel_ruta_aerea,QUERYNTENA.getCiudadDestinoId(vuel_ruta_aerea)
