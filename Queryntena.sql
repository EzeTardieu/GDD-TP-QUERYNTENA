use GD1C2020
IF schema_id('QUERYNTENA') IS NOT NULL
    DROP SCHEMA QUERYNTENA

go
CREATE SCHEMA QUERYNTENA AUTHORIZATION dbo
go


/*
drop table QUERYNTENA.pasaje
drop table QUERYNTENA.venta_pasaje
drop table QUERYNTENA.compra_pasaje
drop table QUERYNTENA.Habitacion_Estadia
drop table QUERYNTENA.Compra_Estadia
drop table QUERYNTENA.Butaca_Vuelo
drop table QUERYNTENA.Vuelo
drop table QUERYNTENA.Habitacion
drop table QUERYNTENA.Venta_Estadias
drop table QUERYNTENA.Estadia
drop table QUERYNTENA.Factura
drop table QUERYNTENA.Tipo_Habitacion
drop table QUERYNTENA.Ruta_Aerea
drop table QUERYNTENA.Avion
drop table QUERYNTENA.Cliente
drop table QUERYNTENA.Sucursal
drop table QUERYNTENA.Hotel
drop table QUERYNTENA.Empresa
*/

create table QUERYNTENA.Empresa (
	empr_id int IDENTITY(1,1) PRIMARY KEY,
	empr_razon_social NVARCHAR(255) NOT NULL
)

create table QUERYNTENA.Hotel(
	hote_id int IDENTITY(1,1) PRIMARY KEY,
	hote_calle nvarchar(50),
	hote_nro_calle decimal(18,0),
	hote_cantidad_estrellas decimal(18,0)	
)

create table QUERYNTENA.Sucursal(
	sucu_id int IDENTITY(1,1) PRIMARY KEY,
	sucu_dir nvarchar(255),
	sucu_mail nvarchar(255),
	sucu_telefono decimal(18,0)
)

create table QUERYNTENA.Cliente(
	clie_id int IDENTITY(1,1) PRIMARY KEY,
	clie_apellido nvarchar(255),
	clie_nombre nvarchar(255),
	clie_fecha_nac datetime2(3),
	clie_dni decimal(18,0),
	clie_mail nvarchar(255),
	clie_telefono int
)

create table QUERYNTENA.Avion(
	avio_id nvarchar(50) PRIMARY KEY,
	avio_modelo nvarchar(50)
)

create table QUERYNTENA.Ruta_Aerea(
	ruta_id int IDENTITY(1,1) PRIMARY KEY,
	ruta_codigo decimal(18,0),
	ruta_ciu_orig nvarchar(255),
	ruta_ciu_dest nvarchar(255)
)

create table QUERYNTENA.Tipo_Habitacion(
	tipo_habitacion_codigo decimal(18,0) PRIMARY KEY,
	tipo_habitacion_desc nvarchar(50)
)

create table QUERYNTENA.Factura(
	fact_numero decimal(18,0) PRIMARY KEY,
	fact_cliente int FOREIGN KEY references QUERYNTENA.Cliente(clie_id),
	fact_sucursal int FOREIGN KEY references QUERYNTENA.Sucursal(sucu_id),
	fact_fecha datetime2(3),
	fact_total decimal(18,2)
)

create table QUERYNTENA.Estadia(
	esta_codigo decimal(18,0) PRIMARY KEY,
	esta_hotel int FOREIGN KEY references QUERYNTENA.Hotel(hote_id),
	esta_fecha_ini datetime2(3),
	esta_cantidad_noches decimal(18,0)
)

create table QUERYNTENA.Venta_Estadias(
	vest_id int IDENTITY(1,1) PRIMARY KEY,
	vest_factura decimal(18,0) FOREIGN KEY references QUERYNTENA.Factura(fact_numero),
	vest_precio_final decimal(18,2),
	vest_estadia decimal(18,0) FOREIGN KEY references QUERYNTENA.Estadia(esta_codigo)
)

create table QUERYNTENA.Habitacion(
	habi_hotel INT NOT NULL,
    habi_numero INT NOT NULL,
	PRIMARY KEY(habi_hotel, habi_numero),
    FOREIGN KEY(habi_hotel) REFERENCES QUERYNTENA.Hotel(hote_id),
	habi_piso decimal(18,0),
	habi_frente nvarchar(50),
	habi_costo decimal(18,2),
	habi_precio decimal(18,2),
	habi_tipo decimal(18,0) FOREIGN KEY references QUERYNTENA.Tipo_Habitacion(tipo_habitacion_codigo)
)

create table QUERYNTENA.Vuelo(
	vuel_codigo decimal(19,0) PRIMARY KEY,
	vuel_ruta_aerea int FOREIGN KEY references QUERYNTENA.Ruta_aerea(ruta_id),
	vuel_avion nvarchar(50) FOREIGN KEY references QUERYNTENA.Avion(avio_id),
	vuel_fecha_salida datetime2(3),
	vuel_fecha_llegada datetime2(3)
)

--agrego un id como PK porque hay vuelos que tienen mismo nro de butaca pero de distinto tipo
create table QUERYNTENA.Butaca_Vuelo(
	buta_id int IDENTITY(1,1) PRIMARY KEY,
	buta_vuelo decimal(19,0) FOREIGN KEY references QUERYNTENA.Vuelo(vuel_codigo),
	buta_numero decimal(18,0),
	buta_tipo nvarchar(255)
)

-- cest = Compra ESTadia
create table QUERYNTENA.Compra_Estadia(
	cest_numero decimal(18,0) PRIMARY KEY,
	cest_empresa int FOREIGN KEY references QUERYNTENA.Empresa(empr_id),
	cest_estadia decimal(18,0) FOREIGN KEY references QUERYNTENA.Estadia(esta_codigo),
	cest_fecha datetime2(3),
	cest_costo_total decimal(18,2)
)

-- hest = Habitacion ESTadia
create table QUERYNTENA.Habitacion_Estadia(
	hest_estadia decimal(18,0) NOT NULL,
	hest_habitacion_nro INT NOT NULL,
	hest_hotel INT NOT NULL,
	PRIMARY KEY(hest_estadia, hest_habitacion_nro, hest_hotel),
	FOREIGN KEY(hest_estadia) REFERENCES QUERYNTENA.Estadia(esta_codigo),
	FOREIGN KEY(hest_hotel,hest_habitacion_nro) REFERENCES QUERYNTENA.Habitacion(habi_hotel,habi_numero),
	hest_fecha_ini datetime2(3),
	hest_cantidad_noches decimal(18,0)
)

-- cpas = Compra PASaje
create table QUERYNTENA.Compra_Pasaje(
	cpas_numero decimal(18,0) PRIMARY KEY,
	cpas_empresa int FOREIGN KEY REFERENCES QUERYNTENA.Empresa(empr_id),
	cpas_fecha datetime2(3),
	cpas_costo_total decimal(18,2)
)

create table QUERYNTENA.Venta_Pasaje(
	vpas_id int IDENTITY(1,1) PRIMARY KEY,
	vpas_factura decimal(18,0) FOREIGN KEY REFERENCES QUERYNTENA.Factura(fact_numero),
	vpas_origen nvarchar(255),
	vpas_destino nvarchar(255),
	vpas_salida datetime2(3),
	vpas_precio_final decimal(18,2)
)

create table QUERYNTENA.Pasaje(
	pasa_codigo decimal(18,0) PRIMARY KEY,
	pasa_vuelo decimal(19,0) FOREIGN KEY REFERENCES QUERYNTENA.Vuelo(vuel_codigo),
	pasa_butaca int FOREIGN KEY REFERENCES QUERYNTENA.Butaca_Vuelo(buta_id),
	pasa_compra_nro decimal(18,0) FOREIGN KEY REFERENCES QUERYNTENA.Compra_Pasaje(cpas_numero),
	pasa_venta_id int FOREIGN KEY REFERENCES QUERYNTENA.Venta_Pasaje(vpas_id),
	pasa_costo decimal(18,2),
	pasa_precio decimal(18,2)
)


insert into QUERYNTENA.Empresa (empr_razon_social)
select distinct EMPRESA_RAZON_SOCIAL from gd_esquema.Maestra

insert into QUERYNTENA.Hotel (hote_calle,hote_nro_calle,hote_cantidad_estrellas)
select distinct HOTEL_CALLE, HOTEL_NRO_CALLE, HOTEL_CANTIDAD_ESTRELLAS from gd_esquema.Maestra
where HOTEL_CALLE is not null

insert into QUERYNTENA.Sucursal (sucu_dir,sucu_mail,sucu_telefono)
select distinct SUCURSAL_DIR, SUCURSAL_MAIL, SUCURSAL_TELEFONO from gd_esquema.Maestra
where SUCURSAL_DIR is not null

insert into QUERYNTENA.Cliente (clie_apellido,clie_nombre,clie_fecha_nac,clie_dni,clie_mail,clie_telefono)
select distinct CLIENTE_APELLIDO,CLIENTE_NOMBRE,CLIENTE_FECHA_NAC,CLIENTE_DNI,CLIENTE_MAIL,CLIENTE_TELEFONO from gd_esquema.Maestra
where CLIENTE_APELLIDO is not null

insert into QUERYNTENA.Avion
select distinct AVION_IDENTIFICADOR, AVION_MODELO from gd_esquema.Maestra
where AVION_MODELO is not null

insert into QUERYNTENA.Ruta_Aerea(ruta_codigo,ruta_ciu_orig,ruta_ciu_dest)
select distinct RUTA_AEREA_CODIGO,RUTA_AEREA_CIU_ORIG,RUTA_AEREA_CIU_DEST from gd_esquema.Maestra
where RUTA_AEREA_CODIGO is not null

insert into QUERYNTENA.Tipo_Habitacion
select distinct TIPO_HABITACION_CODIGO, TIPO_HABITACION_DESC from gd_esquema.Maestra
where TIPO_HABITACION_CODIGO is not null

insert into QUERYNTENA.Factura(fact_numero,fact_cliente,fact_sucursal,fact_fecha,fact_total)
select distinct FACTURA_NRO,clie_id,sucu_id,FACTURA_FECHA,
case when PASAJE_PRECIO is not null then PASAJE_PRECIO else sum(HABITACION_PRECIO*ESTADIA_CANTIDAD_NOCHES) end
from gd_esquema.Maestra
join QUERYNTENA.Cliente on gd_esquema.Maestra.CLIENTE_APELLIDO = QUERYNTENA.Cliente.clie_apellido 
	and gd_esquema.Maestra.CLIENTE_NOMBRE= QUERYNTENA.Cliente.clie_nombre 
	and gd_esquema.Maestra.CLIENTE_DNI = QUERYNTENA.Cliente.clie_dni
join QUERYNTENA.Sucursal on gd_esquema.Maestra.SUCURSAL_DIR = sucu_dir
group by FACTURA_NRO,clie_id,sucu_id,FACTURA_FECHA,PASAJE_PRECIO


insert into QUERYNTENA.Estadia
select distinct ESTADIA_CODIGO,hote_id,ESTADIA_FECHA_INI,ESTADIA_CANTIDAD_NOCHES from gd_esquema.Maestra
join QUERYNTENA.Hotel on gd_esquema.Maestra.HOTEL_CALLE = hote_calle and HOTEL_NRO_CALLE = hote_nro_calle

insert into QUERYNTENA.Venta_Estadias(vest_factura,vest_precio_final,vest_estadia)
select distinct FACTURA_NRO,sum(HABITACION_PRECIO*ESTADIA_CANTIDAD_NOCHES),ESTADIA_CODIGO from gd_esquema.Maestra
where ESTADIA_CODIGO is not null and FACTURA_NRO is not null
group by FACTURA_NRO,ESTADIA_CODIGO


insert into QUERYNTENA.Habitacion
select distinct hote_id,HABITACION_NUMERO,HABITACION_PISO,HABITACION_FRENTE,HABITACION_COSTO,HABITACION_PRECIO,TIPO_HABITACION_CODIGO 
from gd_esquema.Maestra 
join QUERYNTENA.Hotel on HOTEL_CALLE = hote_calle and HOTEL_NRO_CALLE = hote_nro_calle

insert into QUERYNTENA.Vuelo
select distinct VUELO_CODIGO, ruta_id, AVION_IDENTIFICADOR, VUELO_FECHA_SALUDA, VUELO_FECHA_LLEGADA from gd_esquema.Maestra
join QUERYNTENA.Ruta_Aerea on RUTA_AEREA_CIU_DEST = Ruta_Aerea.ruta_ciu_dest AND RUTA_AEREA_CIU_ORIG = Ruta_Aerea.ruta_ciu_orig 
	AND RUTA_AEREA_CODIGO = Ruta_Aerea.ruta_codigo 

insert into QUERYNTENA.Butaca_Vuelo(buta_vuelo, buta_numero, buta_tipo)
select distinct VUELO_CODIGO, BUTACA_NUMERO, BUTACA_TIPO
from gd_esquema.Maestra
WHERE VUELO_CODIGO IS NOT NULL

insert into QUERYNTENA.Compra_Estadia
select distinct COMPRA_NUMERO, empr_id, ESTADIA_CODIGO, COMPRA_FECHA,(select sum(ESTADIA_CANTIDAD_NOCHES*HABITACION_COSTO) from gd_esquema.Maestra where ESTADIA_CODIGO = ma.ESTADIA_CODIGO and FACTURA_NRO is not null ) from gd_esquema.Maestra ma
join QUERYNTENA.Empresa on Empresa.empr_razon_social = EMPRESA_RAZON_SOCIAL
where ESTADIA_CODIGO IS NOT NULL



insert into QUERYNTENA.Compra_Pasaje
select distinct COMPRA_NUMERO, empr_id, COMPRA_FECHA,sum(PASAJE_COSTO) from gd_esquema.Maestra
join QUERYNTENA.Empresa on Empresa.empr_razon_social = EMPRESA_RAZON_SOCIAL
where PASAJE_CODIGO IS NOT NULL
group by COMPRA_NUMERO,empr_id,COMPRA_FECHA


insert into QUERYNTENA.Venta_Pasaje(vpas_factura, vpas_origen, vpas_destino, vpas_salida,vpas_precio_final)
select distinct FACTURA_NRO, RUTA_AEREA_CIU_ORIG, RUTA_AEREA_CIU_DEST, VUELO_FECHA_SALUDA,sum(PASAJE_PRECIO) from gd_esquema.Maestra
where FACTURA_NRO is not null
group by FACTURA_NRO, RUTA_AEREA_CIU_ORIG, RUTA_AEREA_CIU_DEST, VUELO_FECHA_SALUDA

insert into QUERYNTENA.Pasaje
select distinct PASAJE_CODIGO, VUELO_CODIGO, buta_id,COMPRA_NUMERO, vpas_id , PASAJE_COSTO, PASAJE_PRECIO from gd_esquema.Maestra
join QUERYNTENA.Butaca_Vuelo on buta_numero = BUTACA_NUMERO and buta_tipo = BUTACA_TIPO and buta_vuelo = VUELO_CODIGO
join QUERYNTENA.Venta_Pasaje on FACTURA_NRO = vpas_factura
union (select distinct PASAJE_CODIGO, VUELO_CODIGO, buta_id,COMPRA_NUMERO, vpas_id , PASAJE_COSTO, PASAJE_PRECIO from gd_esquema.Maestra m
join QUERYNTENA.Butaca_Vuelo on buta_numero = BUTACA_NUMERO and buta_tipo = BUTACA_TIPO and buta_vuelo = VUELO_CODIGO
left join QUERYNTENA.Venta_Pasaje on FACTURA_NRO = vpas_factura
where (select count(*) from gd_esquema.Maestra
join QUERYNTENA.Butaca_Vuelo on buta_numero = BUTACA_NUMERO and buta_tipo = BUTACA_TIPO and buta_vuelo = VUELO_CODIGO
left join QUERYNTENA.Venta_Pasaje on FACTURA_NRO = vpas_factura
where PASAJE_CODIGO = m.PASAJE_CODIGO
group by PASAJE_CODIGO) = 1)

