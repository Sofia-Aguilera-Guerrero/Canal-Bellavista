--
-- PostgreSQL database dump
--

\restrict QhfA8AJQ6tfNvjEAmeCzzg3R3M6S2kmJT690aM1lKwFhfi0hhBUgtpaJKlUCfAQ

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

-- Started on 2025-11-09 22:42:15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 17164)
-- Name: attic; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA attic;


ALTER SCHEMA attic OWNER TO postgres;

--
-- TOC entry 7 (class 2615 OID 17132)
-- Name: clean; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA clean;


ALTER SCHEMA clean OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 17133)
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- TOC entry 5097 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- TOC entry 258 (class 1255 OID 17058)
-- Name: caudales_final_set_id_tiempo(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.caudales_final_set_id_tiempo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.id_tiempo IS NULL THEN
    SELECT dt.id_tiempo
      INTO NEW.id_tiempo
    FROM public.dim_tiempo dt
    WHERE dt.anio = NEW.anio
      AND dt.semana_iso = NEW.semana
      AND dt.fecha = dt.lunes_semana
    LIMIT 1;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.caudales_final_set_id_tiempo() OWNER TO postgres;

--
-- TOC entry 265 (class 1255 OID 17209)
-- Name: fn_calc_valor_esperado_m3(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_calc_valor_esperado_m3() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.acciones IS NOT NULL THEN
    NEW.volumen_m3 := (NEW.acciones / 1000.0) * 604800.0;
  ELSE
    NEW.volumen_m3 := NULL;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_calc_valor_esperado_m3() OWNER TO postgres;

--
-- TOC entry 260 (class 1255 OID 17060)
-- Name: trg_calc_volumen_esperado(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_calc_volumen_esperado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.volumen_esperado_m3 :=
    ROUND((COALESCE(NEW.acciones,0) / 1000.0) * 604800, 3);
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_calc_volumen_esperado() OWNER TO postgres;

--
-- TOC entry 259 (class 1255 OID 17051)
-- Name: trg_caudales_final_set_volumen(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_caudales_final_set_volumen() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- promedio_sem está en L/s
  -- 1 semana = 604800 segundos
  -- L/s * 604800 s = Litros; /1000 = m³
  NEW.volumen_m3 := ROUND((COALESCE(NEW.promedio_sem, 0) / 1000.0) * 604800, 3);
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_caudales_final_set_volumen() OWNER TO postgres;

--
-- TOC entry 266 (class 1255 OID 17286)
-- Name: trg_fact_dm_calc_finanzas(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_fact_dm_calc_finanzas() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.recaudacion_esperada_anual := ROUND(NEW.monto_base * 12, 2);
  NEW.morosidad_pct := ROUND(
    CASE WHEN NEW.monto_base > 0
         THEN (NEW.deuda_total / (NEW.monto_base * 12)) * 100
         ELSE 0 END
  , 2);
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_fact_dm_calc_finanzas() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 239 (class 1259 OID 17069)
-- Name: backup_dim_marco; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.backup_dim_marco (
    id_marco integer,
    marco text,
    submarco text,
    marco_norm text,
    submarco_norm text,
    correo text,
    estado_envio text,
    cuotas_pendientes double precision,
    id_sitio integer
);


ALTER TABLE attic.backup_dim_marco OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 17074)
-- Name: backup_fact_deuda_marcos; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.backup_fact_deuda_marcos (
    id_marco integer,
    anio integer,
    acciones numeric(12,2),
    valor_cuota_mensual numeric(12,2),
    cuotas_pendientes integer,
    monto_base numeric(12,2),
    deuda_total numeric(12,2),
    estado_cobranza text,
    volumen_esperado_m3 numeric(14,3)
);


ALTER TABLE attic.backup_fact_deuda_marcos OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16577)
-- Name: caudales_stage; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.caudales_stage (
    sitio text,
    anio integer,
    semana integer,
    promedio_sem numeric,
    id_sitio integer
);


ALTER TABLE attic.caudales_stage OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16554)
-- Name: correos; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.correos (
    id_marcos character varying(10),
    marcos character varying(50),
    submarcos character varying(50),
    cuotas_pendientes character varying(3),
    correo character varying(100),
    estado character varying(15),
    marco_norm text,
    submarco_norm text
);


ALTER TABLE attic.correos OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16399)
-- Name: deuda_marcoss; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.deuda_marcoss (
    codigo character varying(20),
    marcos character varying(100),
    cuotas_pendientes double precision,
    estado character varying(20),
    acciones numeric(17,2),
    valor_cuota_mensual numeric(17,2),
    monto_base numeric(17,2),
    deuda_total numeric(17,2)
);


ALTER TABLE attic.deuda_marcoss OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 17084)
-- Name: dim_marco; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.dim_marco (
    id_marco bigint,
    marco text,
    submarco text,
    marco_norm text,
    submarco_norm text,
    correo text,
    estado_envio text,
    cuotas_pendientes integer
);


ALTER TABLE attic.dim_marco OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16686)
-- Name: fact_deuda_marcos; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.fact_deuda_marcos (
    id_marco integer NOT NULL,
    anio integer NOT NULL,
    acciones numeric(12,2),
    valor_cuota_mensual numeric(12,2),
    cuotas_pendientes integer,
    monto_base numeric(12,2),
    deuda_total numeric(12,2),
    estado_cobranza text,
    volumen_esperado_m3 numeric(14,3)
);


ALTER TABLE attic.fact_deuda_marcos OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16404)
-- Name: presupuesto_anual; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.presupuesto_anual (
    cuenta character varying(100),
    gasto_anual numeric(17,2),
    gasto_mensual numeric(17,2),
    tipo_pago character varying(50)
);


ALTER TABLE attic.presupuesto_anual OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16561)
-- Name: proyectosfinal; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.proyectosfinal (
    concurso character varying(60),
    proyecto character varying(200),
    construido_por character varying(60),
    costo_total_uf numeric(20,0),
    lugar_ref character varying(60),
    estatus character varying(60),
    concursos text,
    anio integer
);


ALTER TABLE attic.proyectosfinal OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16781)
-- Name: stg_dim_marco; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.stg_dim_marco (
    marco text,
    submarco text,
    marco_norm text NOT NULL,
    submarco_norm text,
    correo text,
    estado_envio text,
    cuotas_pendientes integer
);


ALTER TABLE attic.stg_dim_marco OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 17079)
-- Name: stg_dim_marco_clean; Type: TABLE; Schema: attic; Owner: postgres
--

CREATE TABLE attic.stg_dim_marco_clean (
    marco text,
    submarco text,
    marco_norm text,
    submarco_norm text,
    correo text,
    estado_envio text,
    cuotas_pendientes integer
);


ALTER TABLE attic.stg_dim_marco_clean OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 17140)
-- Name: stg_dim_marco_raw; Type: TABLE; Schema: clean; Owner: postgres
--

CREATE TABLE clean.stg_dim_marco_raw (
    marco text,
    submarco text,
    cuotas_pendientes integer,
    correo text,
    estado_envio text,
    marco_norm text,
    submarco_norm text
);


ALTER TABLE clean.stg_dim_marco_raw OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16585)
-- Name: caudales_final; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.caudales_final (
    id_sitio integer NOT NULL,
    anio integer,
    semana integer,
    promedio_sem numeric,
    sitio text,
    id_tiempo integer NOT NULL,
    volumen_m3 numeric
);


ALTER TABLE public.caudales_final OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 17147)
-- Name: correos_final; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.correos_final (
    id character varying(10),
    marcos character varying(100),
    submarcos character varying(200),
    encargado character varying(200),
    acciones numeric(17,2),
    cuotas_pendientes numeric(17,2),
    correo character varying(200),
    estado character varying(20)
);


ALTER TABLE public.correos_final OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 17160)
-- Name: deudamarcos_final; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.deudamarcos_final (
    marcos character varying(100),
    acciones numeric(17,2),
    cuota_mensual numeric(17,2),
    monto_base numeric(17,2),
    deuda_total numeric(17,2),
    cuotas_pendientes double precision,
    estado_corte character varying(20),
    id character varying(10)
);


ALTER TABLE public.deudamarcos_final OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 17303)
-- Name: dim_anios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_anios (
    id_anio integer NOT NULL,
    anio integer NOT NULL
);


ALTER TABLE public.dim_anios OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 17184)
-- Name: dim_marco_contacto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_marco_contacto (
    id character varying(10) NOT NULL,
    marco character varying(100),
    submarco character varying(200),
    encargado character varying(100),
    correo character varying(150),
    estado_envio character varying(20),
    cuotas_ref integer,
    id_sitio integer,
    id_base character varying(10),
    cuotas_impagas integer,
    alerta_deuda text,
    tiene_deuda boolean,
    prioridad_envio integer
);


ALTER TABLE public.dim_marco_contacto OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16961)
-- Name: dim_presupuesto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_presupuesto (
    id_cuenta integer NOT NULL,
    cuenta text NOT NULL,
    tipo_pago text
);


ALTER TABLE public.dim_presupuesto OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16960)
-- Name: dim_presupuesto_id_cuenta_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dim_presupuesto_id_cuenta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dim_presupuesto_id_cuenta_seq OWNER TO postgres;

--
-- TOC entry 5098 (class 0 OID 0)
-- Dependencies: 236
-- Name: dim_presupuesto_id_cuenta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dim_presupuesto_id_cuenta_seq OWNED BY public.dim_presupuesto.id_cuenta;


--
-- TOC entry 233 (class 1259 OID 16918)
-- Name: dim_proyecto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_proyecto (
    id_proyecto integer NOT NULL,
    concursos text NOT NULL,
    anio integer NOT NULL,
    proyecto text,
    construido_por text,
    lugar_ref text,
    estatus text,
    costo_total_uf numeric(14,2)
);


ALTER TABLE public.dim_proyecto OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16917)
-- Name: dim_proyecto_id_proyecto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dim_proyecto_id_proyecto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dim_proyecto_id_proyecto_seq OWNER TO postgres;

--
-- TOC entry 5099 (class 0 OID 0)
-- Dependencies: 232
-- Name: dim_proyecto_id_proyecto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dim_proyecto_id_proyecto_seq OWNED BY public.dim_proyecto.id_proyecto;


--
-- TOC entry 223 (class 1259 OID 16530)
-- Name: dim_sitio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_sitio (
    id_sitio integer NOT NULL,
    sitio text NOT NULL,
    sitio_norm text
);


ALTER TABLE public.dim_sitio OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16529)
-- Name: dim_sitio_id_sitio_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dim_sitio_id_sitio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dim_sitio_id_sitio_seq OWNER TO postgres;

--
-- TOC entry 5100 (class 0 OID 0)
-- Dependencies: 222
-- Name: dim_sitio_id_sitio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dim_sitio_id_sitio_seq OWNED BY public.dim_sitio.id_sitio;


--
-- TOC entry 221 (class 1259 OID 16518)
-- Name: dim_tiempo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_tiempo (
    id_tiempo integer NOT NULL,
    fecha date NOT NULL,
    anio integer NOT NULL,
    mes integer NOT NULL,
    dia integer NOT NULL,
    dia_anio integer NOT NULL,
    semana_iso integer NOT NULL,
    trimestre integer NOT NULL,
    nombre_mes text NOT NULL,
    nombre_dia text NOT NULL,
    es_fin_semana boolean NOT NULL,
    lunes_semana date NOT NULL
);


ALTER TABLE public.dim_tiempo OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16517)
-- Name: dim_tiempo_id_tiempo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dim_tiempo_id_tiempo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dim_tiempo_id_tiempo_seq OWNER TO postgres;

--
-- TOC entry 5101 (class 0 OID 0)
-- Dependencies: 220
-- Name: dim_tiempo_id_tiempo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dim_tiempo_id_tiempo_seq OWNED BY public.dim_tiempo.id_tiempo;


--
-- TOC entry 250 (class 1259 OID 17197)
-- Name: fact_deuda_marco; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fact_deuda_marco (
    id character varying(10) NOT NULL,
    acciones numeric(15,2),
    valor_cuota_mensual numeric(15,0),
    monto_base numeric(15,2),
    deuda_total numeric(15,2),
    cuotas_pendientes integer,
    estado_corte character varying(30),
    volumen_m3 numeric(18,3),
    recaudacion_esperada_anual numeric(18,2),
    morosidad_pct numeric(9,2)
);


ALTER TABLE public.fact_deuda_marco OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 16971)
-- Name: fact_presupuesto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fact_presupuesto (
    id_cuenta integer NOT NULL,
    anio integer NOT NULL,
    gasto_anual numeric(14,2),
    gasto_mensual numeric(14,2)
);


ALTER TABLE public.fact_presupuesto OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16546)
-- Name: planilla_marcos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.planilla_marcos (
    id_marco character varying(10),
    marco character varying(100),
    cargo numeric(17,2),
    abono numeric(17,2),
    saldo numeric(17,2)
);


ALTER TABLE public.planilla_marcos OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16928)
-- Name: stg_dim_proyectos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stg_dim_proyectos (
    concursos text,
    anio integer,
    proyecto text,
    construido_por text,
    lugar_ref text,
    estatus text,
    costo_total_uf numeric(14,2)
);


ALTER TABLE public.stg_dim_proyectos OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16955)
-- Name: stg_presupuesto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stg_presupuesto (
    cuenta text,
    gasto_anual text,
    gasto_mensual text,
    tipo_pago text
);


ALTER TABLE public.stg_presupuesto OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 17268)
-- Name: v_caudales_general; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_caudales_general AS
 SELECT max(anio) AS anio,
    round(avg(volumen_m3), 2) AS promedio_volumen_m3_general,
    round(max(volumen_m3), 2) AS caudal_maximo_m3_general,
    round(min(volumen_m3), 2) AS caudal_minimo_m3_general,
    round(stddev_pop(volumen_m3), 2) AS desviacion_volumen_m3_general,
    round(
        CASE
            WHEN (avg(volumen_m3) > (0)::numeric) THEN ((stddev_pop(volumen_m3) / avg(volumen_m3)) * (100)::numeric)
            ELSE (0)::numeric
        END, 2) AS coeficiente_variacion_pct_general
   FROM public.caudales_final;


ALTER VIEW public.v_caudales_general OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 17176)
-- Name: v_correos_norm; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_correos_norm AS
 SELECT id,
    upper(TRIM(BOTH FROM marcos)) AS marco_norm,
    NULLIF(upper(TRIM(BOTH FROM submarcos)), 'SIN SUBMARCO'::text) AS submarco_norm,
    marcos,
    submarcos,
    encargado,
    NULLIF(NULLIF(TRIM(BOTH FROM correo), 'sin contacto'::text), 'sin correo'::text) AS correo,
    estado AS estado_envio
   FROM public.correos_final;


ALTER VIEW public.v_correos_norm OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 17180)
-- Name: v_deuda_marcos_norm; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_deuda_marcos_norm AS
 SELECT id,
    upper(TRIM(BOTH FROM marcos)) AS marco_norm,
    marcos,
    (acciones)::numeric(15,2) AS acciones,
    (cuota_mensual)::numeric(15,0) AS valor_cuota_mensual,
    (monto_base)::numeric(15,2) AS monto_base,
    (deuda_total)::numeric(15,2) AS deuda_total,
    (cuotas_pendientes)::integer AS cuotas_pendientes,
    estado_corte
   FROM public.deudamarcos_final;


ALTER VIEW public.v_deuda_marcos_norm OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 17120)
-- Name: v_dim_marco_sin_sub; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_dim_marco_sin_sub AS
 SELECT id_marco,
    upper(TRIM(BOTH FROM marco_norm)) AS marco_norm
   FROM attic.dim_marco
  WHERE (COALESCE(submarco_norm, ''::text) = ''::text);


ALTER VIEW public.v_dim_marco_sin_sub OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 17277)
-- Name: v_kpi_semana; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_kpi_semana AS
 SELECT id_tiempo,
    round(avg(volumen_m3), 2) AS promedio_semana,
    round(max(volumen_m3), 2) AS caudal_max_semana,
    round(min(volumen_m3), 2) AS caudal_min_semana
   FROM public.caudales_final
  GROUP BY id_tiempo;


ALTER VIEW public.v_kpi_semana OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 17272)
-- Name: v_operativo_caudales; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_operativo_caudales AS
 SELECT id_sitio,
    min(sitio) AS sitio,
    round(avg(volumen_m3), 2) AS promedio_volumen_m3,
    round(max(volumen_m3), 2) AS caudal_maximo,
    round(min(volumen_m3), 2) AS caudal_minimo,
    round(stddev_pop(volumen_m3), 2) AS desviacion_volumen_m3,
    round((stddev_pop(volumen_m3) / NULLIF(avg(volumen_m3), (0)::numeric)), 4) AS coeficiente_variacion_pct
   FROM public.caudales_final
  GROUP BY id_sitio;


ALTER VIEW public.v_operativo_caudales OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 17240)
-- Name: v_promedio_volumen_general; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_promedio_volumen_general AS
 SELECT round(avg(volumen_m3), 2) AS promedio_volumen_m3_general
   FROM public.caudales_final;


ALTER VIEW public.v_promedio_volumen_general OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 17244)
-- Name: v_promedio_volumen_por_sitio; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_promedio_volumen_por_sitio AS
 SELECT sitio,
    round(avg(volumen_m3), 2) AS promedio_volumen_m3
   FROM public.caudales_final
  GROUP BY sitio
  ORDER BY (round(avg(volumen_m3), 2)) DESC;


ALTER VIEW public.v_promedio_volumen_por_sitio OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16613)
-- Name: vw_caudales; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_caudales AS
 SELECT f.anio,
    f.semana,
    s.sitio,
    f.promedio_sem,
    f.id_sitio
   FROM (public.caudales_final f
     JOIN public.dim_sitio s USING (id_sitio));


ALTER VIEW public.vw_caudales OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 17281)
-- Name: vw_dim_tiempo_semana; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_dim_tiempo_semana AS
 WITH base AS (
         SELECT dim_tiempo.id_tiempo,
            dim_tiempo.semana_iso,
            dim_tiempo.lunes_semana AS lunes,
            dim_tiempo.anio
           FROM public.dim_tiempo
        ), meses AS (
         SELECT base.id_tiempo,
            base.semana_iso,
            base.lunes,
            base.anio,
                CASE (EXTRACT(month FROM base.lunes))::integer
                    WHEN 1 THEN 'ene'::text
                    WHEN 2 THEN 'feb'::text
                    WHEN 3 THEN 'mar'::text
                    WHEN 4 THEN 'abr'::text
                    WHEN 5 THEN 'may'::text
                    WHEN 6 THEN 'jun'::text
                    WHEN 7 THEN 'jul'::text
                    WHEN 8 THEN 'ago'::text
                    WHEN 9 THEN 'sep'::text
                    WHEN 10 THEN 'oct'::text
                    WHEN 11 THEN 'nov'::text
                    WHEN 12 THEN 'dic'::text
                    ELSE NULL::text
                END AS mes_lunes,
                CASE (EXTRACT(month FROM (base.lunes + 6)))::integer
                    WHEN 1 THEN 'ene'::text
                    WHEN 2 THEN 'feb'::text
                    WHEN 3 THEN 'mar'::text
                    WHEN 4 THEN 'abr'::text
                    WHEN 5 THEN 'may'::text
                    WHEN 6 THEN 'jun'::text
                    WHEN 7 THEN 'jul'::text
                    WHEN 8 THEN 'ago'::text
                    WHEN 9 THEN 'sep'::text
                    WHEN 10 THEN 'oct'::text
                    WHEN 11 THEN 'nov'::text
                    WHEN 12 THEN 'dic'::text
                    ELSE NULL::text
                END AS mes_fin
           FROM base
        )
 SELECT id_tiempo,
    semana_iso,
    lunes AS lunes_semana,
    anio,
    (((((((((((('Semana '::text || semana_iso) || ' ('::text) || lpad((EXTRACT(day FROM lunes))::text, 2, '0'::text)) || ' '::text) || mes_lunes) || ' - '::text) || lpad((EXTRACT(day FROM (lunes + 6)))::text, 2, '0'::text)) || ' '::text) || mes_fin) || ' '::text) || anio) || ')'::text) AS etiqueta_semana
   FROM meses;


ALTER VIEW public.vw_dim_tiempo_semana OWNER TO postgres;

--
-- TOC entry 4895 (class 2604 OID 16964)
-- Name: dim_presupuesto id_cuenta; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_presupuesto ALTER COLUMN id_cuenta SET DEFAULT nextval('public.dim_presupuesto_id_cuenta_seq'::regclass);


--
-- TOC entry 4894 (class 2604 OID 16921)
-- Name: dim_proyecto id_proyecto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_proyecto ALTER COLUMN id_proyecto SET DEFAULT nextval('public.dim_proyecto_id_proyecto_seq'::regclass);


--
-- TOC entry 4893 (class 2604 OID 16533)
-- Name: dim_sitio id_sitio; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_sitio ALTER COLUMN id_sitio SET DEFAULT nextval('public.dim_sitio_id_sitio_seq'::regclass);


--
-- TOC entry 4892 (class 2604 OID 16521)
-- Name: dim_tiempo id_tiempo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_tiempo ALTER COLUMN id_tiempo SET DEFAULT nextval('public.dim_tiempo_id_tiempo_seq'::regclass);


--
-- TOC entry 4905 (class 2606 OID 16692)
-- Name: fact_deuda_marcos fact_deuda_marcos_pkey; Type: CONSTRAINT; Schema: attic; Owner: postgres
--

ALTER TABLE ONLY attic.fact_deuda_marcos
    ADD CONSTRAINT fact_deuda_marcos_pkey PRIMARY KEY (id_marco, anio);


--
-- TOC entry 4925 (class 2606 OID 17309)
-- Name: dim_anios dim_anios_anio_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_anios
    ADD CONSTRAINT dim_anios_anio_key UNIQUE (anio);


--
-- TOC entry 4927 (class 2606 OID 17307)
-- Name: dim_anios dim_anios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_anios
    ADD CONSTRAINT dim_anios_pkey PRIMARY KEY (id_anio);


--
-- TOC entry 4917 (class 2606 OID 17190)
-- Name: dim_marco_contacto dim_marco_contacto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_marco_contacto
    ADD CONSTRAINT dim_marco_contacto_pkey PRIMARY KEY (id);


--
-- TOC entry 4911 (class 2606 OID 16968)
-- Name: dim_presupuesto dim_presupuesto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_presupuesto
    ADD CONSTRAINT dim_presupuesto_pkey PRIMARY KEY (id_cuenta);


--
-- TOC entry 4907 (class 2606 OID 16927)
-- Name: dim_proyecto dim_proyecto_concursos_anio_proyecto_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_proyecto
    ADD CONSTRAINT dim_proyecto_concursos_anio_proyecto_key UNIQUE (concursos, anio, proyecto);


--
-- TOC entry 4909 (class 2606 OID 16925)
-- Name: dim_proyecto dim_proyecto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_proyecto
    ADD CONSTRAINT dim_proyecto_pkey PRIMARY KEY (id_proyecto);


--
-- TOC entry 4901 (class 2606 OID 16537)
-- Name: dim_sitio dim_sitio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_sitio
    ADD CONSTRAINT dim_sitio_pkey PRIMARY KEY (id_sitio);


--
-- TOC entry 4903 (class 2606 OID 16539)
-- Name: dim_sitio dim_sitio_sitio_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_sitio
    ADD CONSTRAINT dim_sitio_sitio_key UNIQUE (sitio);


--
-- TOC entry 4897 (class 2606 OID 16527)
-- Name: dim_tiempo dim_tiempo_fecha_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_tiempo
    ADD CONSTRAINT dim_tiempo_fecha_key UNIQUE (fecha);


--
-- TOC entry 4899 (class 2606 OID 16525)
-- Name: dim_tiempo dim_tiempo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_tiempo
    ADD CONSTRAINT dim_tiempo_pkey PRIMARY KEY (id_tiempo);


--
-- TOC entry 4923 (class 2606 OID 17215)
-- Name: fact_deuda_marco fact_deuda_marco_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_deuda_marco
    ADD CONSTRAINT fact_deuda_marco_pkey PRIMARY KEY (id);


--
-- TOC entry 4915 (class 2606 OID 16975)
-- Name: fact_presupuesto fact_presupuesto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_presupuesto
    ADD CONSTRAINT fact_presupuesto_pkey PRIMARY KEY (id_cuenta, anio);


--
-- TOC entry 4913 (class 2606 OID 16970)
-- Name: dim_presupuesto uq_dim_presupuesto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_presupuesto
    ADD CONSTRAINT uq_dim_presupuesto UNIQUE (cuenta);


--
-- TOC entry 4918 (class 1259 OID 17216)
-- Name: idx_dim_mc_id_base; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dim_mc_id_base ON public.dim_marco_contacto USING btree (id_base);


--
-- TOC entry 4919 (class 1259 OID 17196)
-- Name: idx_dim_mc_marco_norm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dim_mc_marco_norm ON public.dim_marco_contacto USING btree (upper(TRIM(BOTH FROM marco)));


--
-- TOC entry 4920 (class 1259 OID 17258)
-- Name: idx_dmc_prioridad_envio; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dmc_prioridad_envio ON public.dim_marco_contacto USING btree (prioridad_envio);


--
-- TOC entry 4921 (class 1259 OID 17257)
-- Name: idx_dmc_tiene_deuda; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dmc_tiene_deuda ON public.dim_marco_contacto USING btree (tiene_deuda);


--
-- TOC entry 4936 (class 2620 OID 17061)
-- Name: fact_deuda_marcos trg_calc_volumen_esperado; Type: TRIGGER; Schema: attic; Owner: postgres
--

CREATE TRIGGER trg_calc_volumen_esperado BEFORE INSERT OR UPDATE OF acciones ON attic.fact_deuda_marcos FOR EACH ROW EXECUTE FUNCTION public.trg_calc_volumen_esperado();


--
-- TOC entry 4937 (class 2620 OID 17287)
-- Name: fact_deuda_marco fact_dm_calc_finanzas; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER fact_dm_calc_finanzas BEFORE INSERT OR UPDATE OF monto_base, deuda_total ON public.fact_deuda_marco FOR EACH ROW EXECUTE FUNCTION public.trg_fact_dm_calc_finanzas();


--
-- TOC entry 4934 (class 2620 OID 17054)
-- Name: caudales_final set_volumen_caudales_final; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_volumen_caudales_final BEFORE INSERT OR UPDATE OF promedio_sem ON public.caudales_final FOR EACH ROW EXECUTE FUNCTION public.trg_caudales_final_set_volumen();


--
-- TOC entry 4935 (class 2620 OID 17059)
-- Name: caudales_final trg_cf_set_id_tiempo; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_cf_set_id_tiempo BEFORE INSERT OR UPDATE OF anio, semana ON public.caudales_final FOR EACH ROW EXECUTE FUNCTION public.caudales_final_set_id_tiempo();


--
-- TOC entry 4938 (class 2620 OID 17210)
-- Name: fact_deuda_marco trg_fact_deuda_marco_calc_m3; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_fact_deuda_marco_calc_m3 BEFORE INSERT OR UPDATE ON public.fact_deuda_marco FOR EACH ROW EXECUTE FUNCTION public.fn_calc_valor_esperado_m3();


--
-- TOC entry 4929 (class 2606 OID 16590)
-- Name: caudales_final caudales_final_id_sitio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caudales_final
    ADD CONSTRAINT caudales_final_id_sitio_fkey FOREIGN KEY (id_sitio) REFERENCES public.dim_sitio(id_sitio);


--
-- TOC entry 4933 (class 2606 OID 17191)
-- Name: dim_marco_contacto dim_marco_contacto_id_sitio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_marco_contacto
    ADD CONSTRAINT dim_marco_contacto_id_sitio_fkey FOREIGN KEY (id_sitio) REFERENCES public.dim_sitio(id_sitio);


--
-- TOC entry 4931 (class 2606 OID 16976)
-- Name: fact_presupuesto fact_presupuesto_id_cuenta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_presupuesto
    ADD CONSTRAINT fact_presupuesto_id_cuenta_fkey FOREIGN KEY (id_cuenta) REFERENCES public.dim_presupuesto(id_cuenta);


--
-- TOC entry 4930 (class 2606 OID 17320)
-- Name: dim_proyecto fk_dim_proyecto_anio; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_proyecto
    ADD CONSTRAINT fk_dim_proyecto_anio FOREIGN KEY (anio) REFERENCES public.dim_anios(id_anio);


--
-- TOC entry 4928 (class 2606 OID 17315)
-- Name: dim_tiempo fk_dim_tiempo_anio; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_tiempo
    ADD CONSTRAINT fk_dim_tiempo_anio FOREIGN KEY (anio) REFERENCES public.dim_anios(id_anio);


--
-- TOC entry 4932 (class 2606 OID 17325)
-- Name: fact_presupuesto fk_fact_presupuesto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_presupuesto
    ADD CONSTRAINT fk_fact_presupuesto FOREIGN KEY (anio) REFERENCES public.dim_anios(id_anio);


-- Completed on 2025-11-09 22:42:16

--
-- PostgreSQL database dump complete
--

\unrestrict QhfA8AJQ6tfNvjEAmeCzzg3R3M6S2kmJT690aM1lKwFhfi0hhBUgtpaJKlUCfAQ

