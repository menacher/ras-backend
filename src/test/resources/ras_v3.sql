--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4 (Debian 13.4-1.pgdg100+1)
-- Dumped by pg_dump version 13.4 (Debian 13.4-1.pgdg100+1)

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
-- Name: notifications; Type: TYPE; Schema: public; Owner: ras
--

CREATE TYPE public.notifications AS ENUM (
    'INFO',
    'ALERT'
);


ALTER TYPE public.notifications OWNER TO ras;

--
-- Name: flow_item_history_insert(); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.flow_item_history_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
        IF (
          TG_OP = 'UPDATE'
          AND (
            OLD.flow_status <> NEW.flow_status
            OR OLD.item_type <> NEW.item_type
            OR OLD.step_name <> NEW.step_name
            OR OLD.step_status <> NEW.step_status
          )
        ) OR (
          TG_OP = 'INSERT'
        )
	    THEN
            INSERT INTO flow_item_history (flow_item_id, flow_status, item_type, step_name, step_status, additional_info, other_obj_id, other_rel_name, future1, step_config, step_context)
            VALUES (NEW.id, NEW.flow_status, NEW.item_type, NEW.step_name, NEW.step_status, NEW.additional_info, NEW.other_obj_id, NEW.other_rel_name, NEW.future1, NEW.step_config, NEW.step_context);
        END IF;
        RETURN NULL;
    END;
$$;


ALTER FUNCTION public.flow_item_history_insert() OWNER TO ras;

--
-- Name: get_linked_source_file_of(bigint); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.get_linked_source_file_of(startid bigint) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare tempId int8 := startId;
declare resultId int8 := 0;
declare x text := '';
declare ctr int := 0;
begin
	while tempId is not null and ctr < 5 loop
	resultId := tempId;
	select xf.linked_orig_file into tempId from x12file xf where xf.id = resultId limit 1;
	ctr := ctr + 1;
end loop;
select xf.source_file_name into x from x12file xf where xf.id = resultId;
return x;
end;
$$;


ALTER FUNCTION public.get_linked_source_file_of(startid bigint) OWNER TO ras;

--
-- Name: inst_update_duplicate_claim_line(); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.inst_update_duplicate_claim_line() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE
    inst_2400
SET
    line_hash = sub.hash_key
FROM
  (
    SELECT
      i24.id,
      ras_md5(
        UPPER(
          concat(
            COALESCE(claim.plan_id,''),
            COALESCE(i201ba.beneficiary_member_identifier,''),
            COALESCE(i23dtp.dtp_03, ''),
            COALESCE(i23.facility_type_code, ''),
            COALESCE(i24.service_line_revenue_code, ''),
            COALESCE(i201aa.billing_provider_npi_identifier,''),
            COALESCE(claim.payer_amount_paid::TEXT, '0'),
            COALESCE(i24.line_item_charge_amount::TEXT, '0'),
            COALESCE(i24.procedure_code, ''),
            COALESCE(i24.procedure_modifier1, ''),
            COALESCE(i24.procedure_modifier2, ''),
            COALESCE(i24.procedure_modifier3, ''),
            COALESCE(i24.procedure_modifier4, ''),
            COALESCE(i2410.national_drug_code, '')
          )
        )
      ) as hash_key
    FROM
      inst_2400 i24
      JOIN inst_claim_identifier claim ON claim.id = i24.claim_id
      JOIN inst_2300 i23 ON i24.claim_id = i23.claim_id
      JOIN child_inst_2300_dtp i23dtp ON i24.claim_id = i23dtp.claim_id
      AND i23.id = i23dtp.parent_id
      AND i23dtp.date_time_qualifier = '434'
      LEFT JOIN inst_2010ba i201ba ON i24.claim_id = i201ba.claim_id
      LEFT JOIN inst_2010aa i201aa ON i24.claim_id = i201aa.claim_id
      LEFT JOIN inst_2410 i2410 ON i24.claim_id = i2410.claim_id AND i24.claim_line_number = i2410.claim_line_number
    WHERE
      i24.id = NEW.id
      AND claim.source = 'ENCOUNTER'
      AND claim.encounter_or_chart_review = 'EN'
      AND claim.claim_frequency_code IN ('1', '2', '3', '4', '5')
      AND (i24.procedure_modifier1 IS NULL OR i24.procedure_modifier1 NOT IN('59', '62', '66', '76', '77', '91'))
      AND (i24.procedure_modifier2 IS NULL OR i24.procedure_modifier2 NOT IN('59', '62', '66', '76', '77', '91'))
      AND (i24.procedure_modifier3 IS NULL OR i24.procedure_modifier3 NOT IN('59', '62', '66', '76', '77', '91'))
      AND (i24.procedure_modifier4 IS NULL OR i24.procedure_modifier4 NOT IN('59', '62', '66', '76', '77', '91'))
  ) AS sub
WHERE
    inst_2400.id = sub.id;
RETURN NULL;
END;
$$;


ALTER FUNCTION public.inst_update_duplicate_claim_line() OWNER TO ras;

--
-- Name: inst_update_duplicate_claim_line_other(); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.inst_update_duplicate_claim_line_other() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE
    inst_2400
SET
    line_hash = sub.hash_key
FROM
  (
    SELECT
      i24.id,
      ras_md5(
        UPPER(
          concat(
            COALESCE(claim.plan_id,''),
            COALESCE(i201ba.beneficiary_member_identifier,''),
            COALESCE(i23dtp.dtp_03, ''),
            COALESCE(i23.facility_type_code, ''),
            COALESCE(i24.service_line_revenue_code, ''),
            COALESCE(i201aa.billing_provider_npi_identifier,''),
            COALESCE(claim.payer_amount_paid::TEXT, '0'),
            COALESCE(i24.line_item_charge_amount::TEXT, '0'),
            COALESCE(i24.procedure_code, ''),
            COALESCE(i24.procedure_modifier1, ''),
            COALESCE(i24.procedure_modifier2, ''),
            COALESCE(i24.procedure_modifier3, ''),
            COALESCE(i24.procedure_modifier4, ''),
            COALESCE(i2410.national_drug_code, '')
          )
        )
      ) as hash_key
    FROM
      inst_2400 i24
      JOIN inst_claim_identifier claim ON claim.id = i24.claim_id
      JOIN inst_2300 i23 ON i24.claim_id = i23.claim_id
      JOIN child_inst_2300_dtp i23dtp ON i24.claim_id = i23dtp.claim_id
      AND i23.id = i23dtp.parent_id
      AND i23dtp.date_time_qualifier = '434'
      LEFT JOIN inst_2010ba i201ba ON i24.claim_id = i201ba.claim_id
      LEFT JOIN inst_2010aa i201aa ON i24.claim_id = i201aa.claim_id
      LEFT JOIN inst_2410 i2410 ON i24.claim_id = i2410.claim_id AND i24.claim_line_number = i2410.claim_line_number
    WHERE
      i24.claim_id = NEW.claim_id
      AND claim.source = 'ENCOUNTER'
      AND claim.encounter_or_chart_review = 'EN'
      AND claim.claim_frequency_code IN ('1', '2', '3', '4', '5')
      AND (i24.procedure_modifier1 IS NULL OR i24.procedure_modifier1 NOT IN('59', '62', '66', '76', '77', '91'))
      AND (i24.procedure_modifier2 IS NULL OR i24.procedure_modifier2 NOT IN('59', '62', '66', '76', '77', '91'))
      AND (i24.procedure_modifier3 IS NULL OR i24.procedure_modifier3 NOT IN('59', '62', '66', '76', '77', '91'))
      AND (i24.procedure_modifier4 IS NULL OR i24.procedure_modifier4 NOT IN('59', '62', '66', '76', '77', '91'))
  ) AS sub
WHERE
    inst_2400.id = sub.id;
RETURN NULL;
END;
$$;


ALTER FUNCTION public.inst_update_duplicate_claim_line_other() OWNER TO ras;

--
-- Name: inst_update_duplicate_line_flag(); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.inst_update_duplicate_line_flag() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE current_rec RECORD;
BEGIN current_rec = NEW;

UPDATE
    inst_2400
SET
    dup_line = false
WHERE
    inst_2400.id = current_rec.id;
UPDATE
    inst_2400
SET
    dup_line = flag.status
FROM
  (
    SELECT
      true AS status
    FROM
      inst_2400 i24
      JOIN inst_claim_identifier ici ON ici.id = i24.claim_id
      AND ici.encounter_status IN ('ACCEPTED', 'NEW', 'SUBMITTED')
      AND ici.source = 'ENCOUNTER'
    WHERE
      current_rec.line_hash = i24.line_hash
      AND i24.id <> current_rec.id
      AND ici.id IS NOT NULL
    LIMIT
      1
  ) AS flag
WHERE
    inst_2400.id = current_rec.id;
RETURN NULL;
END;
$$;


ALTER FUNCTION public.inst_update_duplicate_line_flag() OWNER TO ras;

--
-- Name: inst_update_revision(); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.inst_update_revision() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      current_rec RECORD;
	BEGIN
	    IF TG_OP = 'DELETE' THEN
          current_rec = OLD;
        ELSE
          current_rec = NEW;
	    END IF;
        IF (
          TG_OP = 'DELETE'
          AND OLD.source = 'ENCOUNTER'
          AND OLD.encounter_status NOT LIKE('%LINKED%')
        ) OR (
          TG_OP = 'INSERT'
          AND NEW.source = 'ENCOUNTER'
          AND NEW.encounter_status NOT LIKE('%LINKED%')
        ) OR (
          NEW.source = 'ENCOUNTER'
          AND NEW.encounter_status NOT LIKE('%LINKED%')
          AND (
            OLD.submission_date <> NEW.submission_date
            OR OLD.last_updated <> NEW.last_updated
            OR OLD.patient_control_number <> NEW.patient_control_number
            OR OLD.encounter_or_chart_review <> NEW.encounter_or_chart_review
            OR OLD.id <> NEW.id
          )
        )
	    THEN
            UPDATE inst_claim_identifier SET encounter_revision = sub.rank
            FROM
        	(
			  SELECT
			    id,
			    rank() OVER (
			      PARTITION BY patient_control_number, encounter_or_chart_review
			      ORDER BY
			        submission_date DESC,
			        last_updated DESC,
			        id DESC
			    )
			  FROM
			    inst_claim_identifier claim
			  WHERE
			    patient_control_number = current_rec.patient_control_number
			    AND source = 'ENCOUNTER'
			    AND encounter_status NOT LIKE('%LINKED%')
			    AND (encounter_status_type IS NULL OR encounter_status_type <> 'DUPLICATE')
			) AS sub
			WHERE inst_claim_identifier.id = sub.id;
        END IF;
        RETURN NULL;
    END;
$$;


ALTER FUNCTION public.inst_update_revision() OWNER TO ras;

--
-- Name: next_ras_ticker_val(); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.next_ras_ticker_val() RETURNS bigint
    LANGUAGE sql
    AS $$
  UPDATE global_ticker
    SET ticker=ticker+1
    WHERE name='ras'
  RETURNING ticker;
$$;


ALTER FUNCTION public.next_ras_ticker_val() OWNER TO ras;

--
-- Name: prof_update_duplicate_claim_line(); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.prof_update_duplicate_claim_line() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
check_id bigint;
BEGIN
check_id = NEW.id;
IF (TG_TABLE_NAME = 'child_prof_2400_dtp') THEN
    check_id = NEW.parent_id;
END IF;
UPDATE
    prof_2400
SET
    line_hash = sub.hash_key
FROM
  (
    SELECT
      p24.id,
      ras_md5(
        UPPER(
          concat(
            COALESCE(claim.plan_id,''),
            COALESCE(p201ba.beneficiary_member_identifier,''),
            COALESCE(p24dtp.begin_date_of_service, ''),
            COALESCE(
              p24dtp.end_date_of_service,
              p24dtp.begin_date_of_service,
              ''
            ),
            COALESCE(p23.place_of_service_code, ''),
            COALESCE(p24.procedure_code, ''),
            COALESCE(p24.procedure_modifier1, ''),
            COALESCE(p24.procedure_modifier2, ''),
            COALESCE(p24.procedure_modifier3, ''),
            COALESCE(p24.procedure_modifier4, ''),
            COALESCE(
              p231b.rendering_provider_identifier,
              p201aa.billing_provider_npi_identifier,
              ''
            ),
            COALESCE(claim.payer_amount_paid::TEXT, '0'),
            COALESCE(p24.line_item_charge_amount::TEXT, '0'),
            COALESCE(p2410.national_drug_code, '')
          )
        )
      ) as hash_key
    FROM
      prof_2400 p24
      JOIN prof_claim_identifier claim ON claim.id = p24.claim_id
      JOIN child_prof_2400_dtp p24dtp ON p24.claim_id = p24dtp.claim_id
      AND p24.id = p24dtp.parent_id
      AND p24dtp.date_time_qualifier = '472'
      JOIN prof_2300 p23 ON p24.claim_id = p23.claim_id
      LEFT JOIN prof_2010ba p201ba ON p24.claim_id = p201ba.claim_id
      LEFT JOIN prof_2310b p231b ON p24.claim_id = p231b.claim_id
      LEFT JOIN prof_2010aa p201aa ON p24.claim_id = p201aa.claim_id
      LEFT JOIN prof_2410 p2410 ON p24.claim_id = p2410.claim_id AND p24.claim_line_number = p2410.claim_line_number
    WHERE
      p24.id = check_id
      AND claim.source = 'ENCOUNTER'
      AND claim.encounter_or_chart_review = 'EN'
      AND claim.claim_frequency_code = '1'
      AND (p24.procedure_modifier1 IS NULL OR p24.procedure_modifier1 NOT IN('59', '76', '77', '91'))
      AND (p24.procedure_modifier2 IS NULL OR p24.procedure_modifier2 NOT IN('59', '76', '77', '91'))
      AND (p24.procedure_modifier3 IS NULL OR p24.procedure_modifier3 NOT IN('59', '76', '77', '91'))
      AND (p24.procedure_modifier4 IS NULL OR p24.procedure_modifier4 NOT IN('59', '76', '77', '91'))
  ) AS sub
WHERE
    prof_2400.id = sub.id;
RETURN NULL;
END;
$$;


ALTER FUNCTION public.prof_update_duplicate_claim_line() OWNER TO ras;

--
-- Name: prof_update_duplicate_claim_line_other(); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.prof_update_duplicate_claim_line_other() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
UPDATE
    prof_2400
SET
    line_hash = sub.hash_key
FROM
  (
    SELECT
      p24.id,
      ras_md5(
        UPPER(
          concat(
            COALESCE(claim.plan_id,''),
            COALESCE(p201ba.beneficiary_member_identifier,''),
            COALESCE(p24dtp.begin_date_of_service, ''),
            COALESCE(
              p24dtp.end_date_of_service,
              p24dtp.begin_date_of_service,
              ''
            ),
            COALESCE(p23.place_of_service_code, ''),
            COALESCE(p24.procedure_code, ''),
            COALESCE(p24.procedure_modifier1, ''),
            COALESCE(p24.procedure_modifier2, ''),
            COALESCE(p24.procedure_modifier3, ''),
            COALESCE(p24.procedure_modifier4, ''),
            COALESCE(
              p231b.rendering_provider_identifier,
              p201aa.billing_provider_npi_identifier,
              ''
            ),
            COALESCE(claim.payer_amount_paid::TEXT, '0'),
            COALESCE(p24.line_item_charge_amount::TEXT, '0'),
            COALESCE(p2410.national_drug_code, '')
          )
        )
      ) as hash_key
    FROM
      prof_2400 p24
      JOIN prof_claim_identifier claim ON claim.id = p24.claim_id
      JOIN child_prof_2400_dtp p24dtp ON p24.claim_id = p24dtp.claim_id
      AND p24.id = p24dtp.parent_id
      AND p24dtp.date_time_qualifier = '472'
      JOIN prof_2300 p23 ON p24.claim_id = p23.claim_id
      LEFT JOIN prof_2010ba p201ba ON p24.claim_id = p201ba.claim_id
      LEFT JOIN prof_2310b p231b ON p24.claim_id = p231b.claim_id
      LEFT JOIN prof_2010aa p201aa ON p24.claim_id = p201aa.claim_id
      LEFT JOIN prof_2410 p2410 ON p24.claim_id = p2410.claim_id AND p24.claim_line_number = p2410.claim_line_number
    WHERE
      p24.claim_id = NEW.claim_id
      AND claim.source ='ENCOUNTER'
      AND claim.encounter_or_chart_review = 'EN'
      AND claim.claim_frequency_code = '1'
      AND (p24.procedure_modifier1 IS NULL OR p24.procedure_modifier1 NOT IN('59', '76', '77', '91'))
      AND (p24.procedure_modifier2 IS NULL OR p24.procedure_modifier2 NOT IN('59', '76', '77', '91'))
      AND (p24.procedure_modifier3 IS NULL OR p24.procedure_modifier3 NOT IN('59', '76', '77', '91'))
      AND (p24.procedure_modifier4 IS NULL OR p24.procedure_modifier4 NOT IN('59', '76', '77', '91'))
  ) AS sub
WHERE
    prof_2400.id = sub.id;
RETURN NULL;
END;
$$;


ALTER FUNCTION public.prof_update_duplicate_claim_line_other() OWNER TO ras;

--
-- Name: prof_update_duplicate_line_flag(); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.prof_update_duplicate_line_flag() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE current_rec RECORD;
BEGIN current_rec = NEW;

UPDATE
    prof_2400
SET
    dup_line = false
WHERE
    prof_2400.id = current_rec.id;
UPDATE
    prof_2400
SET
    dup_line = flag.status
FROM
  (
    SELECT
      true AS status
    FROM
      prof_2400 p24
      JOIN prof_claim_identifier pci ON pci.id = p24.claim_id
      AND pci.encounter_status IN ('ACCEPTED', 'NEW', 'SUBMITTED')
      AND pci.source = 'ENCOUNTER'
    WHERE
      current_rec.line_hash = p24.line_hash
      AND p24.id <> current_rec.id
      AND pci.id IS NOT NULL
    LIMIT
      1
  ) AS flag
WHERE
    prof_2400.id = current_rec.id;
RETURN NULL;
END;
$$;


ALTER FUNCTION public.prof_update_duplicate_line_flag() OWNER TO ras;

--
-- Name: prof_update_revision(); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.prof_update_revision() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
      current_rec RECORD;
	BEGIN
	    IF TG_OP = 'DELETE' THEN
          current_rec = OLD;
        ELSE
          current_rec = NEW;
	    END IF;
        IF (
          TG_OP = 'DELETE'
          AND OLD.source = 'ENCOUNTER'
          AND OLD.encounter_status NOT LIKE('%LINKED%')
        ) OR (
          TG_OP = 'INSERT'
          AND NEW.source = 'ENCOUNTER'
          AND NEW.encounter_status NOT LIKE('%LINKED%')
        ) OR (
          NEW.source = 'ENCOUNTER'
          AND NEW.encounter_status NOT LIKE('%LINKED%')
          AND (
            OLD.submission_date <> NEW.submission_date
            OR OLD.last_updated <> NEW.last_updated
            OR OLD.patient_control_number <> NEW.patient_control_number
            OR OLD.encounter_or_chart_review <> NEW.encounter_or_chart_review
            OR OLD.id <> NEW.id
          )
        )
	    THEN
            UPDATE prof_claim_identifier SET encounter_revision = sub.rank
            FROM
        	(
			  SELECT
			    id,
			    rank() OVER (
			      PARTITION BY patient_control_number, encounter_or_chart_review
			      ORDER BY
			        submission_date DESC,
			        last_updated DESC,
			        id DESC
			    )
			  FROM
			    prof_claim_identifier claim
			  WHERE
			    patient_control_number = current_rec.patient_control_number
			    AND source = 'ENCOUNTER'
			    AND encounter_status NOT LIKE('%LINKED%')
			    AND (encounter_status_type IS NULL OR encounter_status_type <> 'DUPLICATE')
			) AS sub
			WHERE prof_claim_identifier.id = sub.id;
        END IF;
        RETURN NULL;
    END;
$$;


ALTER FUNCTION public.prof_update_revision() OWNER TO ras;

--
-- Name: ras_concat(text, text[]); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.ras_concat(text, VARIADIC text[]) RETURNS text
    LANGUAGE internal IMMUTABLE PARALLEL SAFE
    AS $$text_concat_ws$$;


ALTER FUNCTION public.ras_concat(text, VARIADIC text[]) OWNER TO ras;

--
-- Name: ras_md5(text); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE FUNCTION public.ras_md5(arow text) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
SELECT md5(aRow);
$$;


ALTER FUNCTION public.ras_md5(arow text) OWNER TO ras;

--
-- Name: get_enrollment_months_in_year(date, date, integer); Type: FUNCTION; Schema: public; Owner: ras
--

CREATE OR REPLACE FUNCTION public.get_enrollment_months_in_year(
    p_enrollment_date DATE,
    p_disenrollment_date DATE,
    target_year INTEGER
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    year_start DATE;
    year_end DATE;
    effective_disenrollment_date DATE;
    overlap_start DATE;
    overlap_end DATE;
    months_enrolled NUMERIC;
BEGIN
    IF p_enrollment_date IS NULL THEN
        RETURN NULL;
    END IF;

    year_start := DATE(target_year || '-01-01');
    year_end := DATE(target_year || '-12-31');

    effective_disenrollment_date := COALESCE(p_disenrollment_date, year_end);

    IF effective_disenrollment_date < year_start OR p_enrollment_date > year_end THEN
        RETURN 0;
    END IF;

    overlap_start := GREATEST(p_enrollment_date, year_start);
    overlap_end := LEAST(effective_disenrollment_date, year_end);

    months_enrolled := (
        (DATE_PART('year', overlap_end) - DATE_PART('year', overlap_start)) * 12
        + (DATE_PART('month', overlap_end) - DATE_PART('month', overlap_start))
    );

    RETURN months_enrolled;
END;
$$;


ALTER FUNCTION public.get_enrollment_months_in_year(date, date, integer) OWNER TO ras;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.audit_log (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    orig_claim_id bigint NOT NULL,
    patient_control_number text,
    beneficiary_member_identifier text,
    begin_date_of_service text,
    end_date_of_service text,
    orig_key_hash text,
    modification_type text NOT NULL,
    modified_by text NOT NULL,
    modified_on timestamp without time zone,
    modified_data jsonb NOT NULL,
    CONSTRAINT audit_log_modification_type_check CHECK ((modification_type = ANY (ARRAY['UPDATE'::text, 'INSERT'::text, 'DELETE'::text])))
);


ALTER TABLE public.audit_log OWNER TO ras;

--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.audit_log_id_seq OWNER TO ras;

--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: batch_data; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.batch_data (
    id bigint NOT NULL,
    batch_file_id bigint NOT NULL,
    lob text NOT NULL,
    submitter_id text NOT NULL,
    mbi text NOT NULL,
    patient_control_number text NOT NULL,
    begin_date_of_service text NOT NULL,
    end_date_of_service text NOT NULL,
    source_type text NOT NULL,
    submission_date text,
    status text DEFAULT 'NEW'::text,
    status_code text,
    data jsonb
);


ALTER TABLE public.batch_data OWNER TO ras;

--
-- Name: batch_data_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.batch_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.batch_data_id_seq OWNER TO ras;

--
-- Name: batch_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.batch_data_id_seq OWNED BY public.batch_data.id;


--
-- Name: batch_file; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.batch_file (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    type text NOT NULL,
    name text NOT NULL,
    url text NOT NULL,
    status text,
    processed_status text,
    db_load_timestamp timestamp without time zone,
    last_updated timestamp without time zone,
    modified_by text,
    hash text
);


ALTER TABLE public.batch_file OWNER TO ras;

--
-- Name: batch_file_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.batch_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.batch_file_id_seq OWNER TO ras;

--
-- Name: batch_file_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.batch_file_id_seq OWNED BY public.batch_file.id;


--
-- Name: child_inst_2010aa_per; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2010aa_per (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    billing_provider_contact_function_code text,
    billing_provider_contact_name text,
    billing_provider_communication_number_qualifier1 text,
    billing_provider_communication_number1 text,
    billing_provider_communication_number_qualifier2 text,
    billing_provider_communication_number2 text,
    billing_provider_communication_number_qualifier3 text,
    billing_provider_communication_number3 text
);


ALTER TABLE public.child_inst_2010aa_per OWNER TO ras;

--
-- Name: child_inst_2010aa_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2010aa_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    billing_provider_ref_identification_qualifier text,
    billing_provider_employers_identification_number text
);


ALTER TABLE public.child_inst_2010aa_ref OWNER TO ras;

--
-- Name: child_inst_2010ac_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2010ac_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    pay_to_plan_ref_identification_qual text,
    payer_identification_number text
);


ALTER TABLE public.child_inst_2010ac_ref OWNER TO ras;

--
-- Name: child_inst_2010ba_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2010ba_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    subscriber_secondary_identification_code_qual text,
    subscriber_supplemental_identifier text
);


ALTER TABLE public.child_inst_2010ba_ref OWNER TO ras;

--
-- Name: child_inst_2010bb_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2010bb_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    payer_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2010bb_ref OWNER TO ras;

--
-- Name: child_inst_2300_dtp; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2300_dtp (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    date_time_qualifier text,
    date_time_period_format_qualifier text,
    dtp_03 text
);


ALTER TABLE public.child_inst_2300_dtp OWNER TO ras;

--
-- Name: child_inst_2300_hi; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2300_hi (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    primary_claim_code_type text,
    primary_claim_code text,
    primary_date_qual text,
    primary_date text,
    primary_monetary_amount text,
    primary_quantity text,
    primary_version text,
    primary_industry_code text,
    primary_response_code text,
    secondary_claim_code_type1 text,
    secondary_claim_code1 text,
    secondary_date_qual1 text,
    secondary_date1 text,
    secondarymonetary_amount1 text,
    secondary_quantity1 text,
    secondary_version1 text,
    secondary_industry_code1 text,
    secondary_response_code1 text,
    secondary_claim_code_type2 text,
    secondary_claim_code2 text,
    secondary_date_qual2 text,
    secondary_date2 text,
    secondarymonetary_amount2 text,
    secondary_quantity2 text,
    secondary_version2 text,
    secondary_industry_code2 text,
    secondary_response_code2 text,
    secondary_claim_code_type3 text,
    secondary_claim_code3 text,
    secondary_date_qual3 text,
    secondary_date3 text,
    secondarymonetary_amount3 text,
    secondary_quantity3 text,
    secondary_version3 text,
    secondary_industry_code3 text,
    secondary_response_code3 text,
    secondary_claim_code_type4 text,
    secondary_claim_code4 text,
    secondary_date_qual4 text,
    secondary_date4 text,
    secondarymonetary_amount4 text,
    secondary_quantity4 text,
    secondary_version4 text,
    secondary_industry_code4 text,
    secondary_response_code4 text,
    secondary_claim_code_type5 text,
    secondary_claim_code5 text,
    secondary_date_qual5 text,
    secondary_date5 text,
    secondarymonetary_amount5 text,
    secondary_quantity5 text,
    secondary_version5 text,
    secondary_industry_code5 text,
    secondary_response_code5 text,
    secondary_claim_code_type6 text,
    secondary_claim_code6 text,
    secondary_date_qual6 text,
    secondary_date6 text,
    secondarymonetary_amount6 text,
    secondary_quantity6 text,
    secondary_version6 text,
    secondary_industry_code6 text,
    secondary_response_code6 text,
    secondary_claim_code_type7 text,
    secondary_claim_code7 text,
    secondary_date_qual7 text,
    secondary_date7 text,
    secondarymonetary_amount7 text,
    secondary_quantity7 text,
    secondary_version7 text,
    secondary_industry_code7 text,
    secondary_response_code7 text,
    secondary_claim_code_type8 text,
    secondary_claim_code8 text,
    secondary_date_qual8 text,
    secondary_date8 text,
    secondarymonetary_amount8 text,
    secondary_quantity8 text,
    secondary_version8 text,
    secondary_industry_code8 text,
    secondary_response_code8 text,
    secondary_claim_code_type9 text,
    secondary_claim_code9 text,
    secondary_date_qual9 text,
    secondary_date9 text,
    secondarymonetary_amount9 text,
    secondary_quantity9 text,
    secondary_version9 text,
    secondary_industry_code9 text,
    secondary_response_code9 text,
    secondary_claim_code_type10 text,
    secondary_claim_code10 text,
    secondary_date_qual10 text,
    secondary_date10 text,
    secondarymonetary_amount10 text,
    secondary_quantity10 text,
    secondary_version10 text,
    secondary_industry_code10 text,
    secondary_response_code10 text,
    secondary_claim_code_type11 text,
    secondary_claim_code11 text,
    secondary_date_qual11 text,
    secondary_date11 text,
    secondarymonetary_amount11 text,
    secondary_quantity11 text,
    secondary_version11 text,
    secondary_industry_code11 text,
    secondary_response_code11 text,
    secondary_claim_code_type12 text,
    secondary_claim_code12 text,
    secondary_date_qual12 text,
    secondary_date12 text,
    secondarymonetary_amount12 text,
    secondary_quantity12 text,
    secondary_version12 text,
    secondary_industry_code12 text,
    secondary_response_code12 text,
    secondary_claim_code_type13 text,
    secondary_claim_code13 text,
    secondary_date_qual13 text,
    secondary_date13 text,
    secondarymonetary_amount13 text,
    secondary_quantity13 text,
    secondary_version13 text,
    secondary_industry_code13 text,
    secondary_response_code13 text,
    secondary_claim_code_type14 text,
    secondary_claim_code14 text,
    secondary_date_qual14 text,
    secondary_date14 text,
    secondarymonetary_amount14 text,
    secondary_quantity14 text,
    secondary_version14 text,
    secondary_industry_code14 text,
    secondary_response_code14 text,
    secondary_claim_code_type15 text,
    secondary_claim_code15 text,
    secondary_date_qual15 text,
    secondary_date15 text,
    secondarymonetary_amount15 text,
    secondary_quantity15 text,
    secondary_version15 text,
    secondary_industry_code15 text,
    secondary_response_code15 text,
    secondary_claim_code_type16 text,
    secondary_claim_code16 text,
    secondary_date_qual16 text,
    secondary_date16 text,
    secondarymonetary_amount16 text,
    secondary_quantity16 text,
    secondary_version16 text,
    secondary_industry_code16 text,
    secondary_response_code16 text,
    secondary_claim_code_type17 text,
    secondary_claim_code17 text,
    secondary_date_qual17 text,
    secondary_date17 text,
    secondarymonetary_amount17 text,
    secondary_quantity17 text,
    secondary_version17 text,
    secondary_industry_code17 text,
    secondary_response_code17 text,
    secondary_claim_code_type18 text,
    secondary_claim_code18 text,
    secondary_date_qual18 text,
    secondary_date18 text,
    secondarymonetary_amount18 text,
    secondary_quantity18 text,
    secondary_version18 text,
    secondary_industry_code18 text,
    secondary_response_code18 text,
    secondary_claim_code_type19 text,
    secondary_claim_code19 text,
    secondary_date_qual19 text,
    secondary_date19 text,
    secondarymonetary_amount19 text,
    secondary_quantity19 text,
    secondary_version19 text,
    secondary_industry_code19 text,
    secondary_response_code19 text,
    secondary_claim_code_type20 text,
    secondary_claim_code20 text,
    secondary_date_qual20 text,
    secondary_date20 text,
    secondarymonetary_amount20 text,
    secondary_quantity20 text,
    secondary_version20 text,
    secondary_industry_code20 text,
    secondary_response_code20 text,
    secondary_claim_code_type21 text,
    secondary_claim_code21 text,
    secondary_date_qual21 text,
    secondary_date21 text,
    secondarymonetary_amount21 text,
    secondary_quantity21 text,
    secondary_version21 text,
    secondary_industry_code21 text,
    secondary_response_code21 text,
    secondary_claim_code_type22 text,
    secondary_claim_code22 text,
    secondary_date_qual22 text,
    secondary_date22 text,
    secondarymonetary_amount22 text,
    secondary_quantity22 text,
    secondary_version22 text,
    secondary_industry_code22 text,
    secondary_response_code22 text,
    secondary_claim_code_type23 text,
    secondary_claim_code23 text,
    secondary_date_qual23 text,
    secondary_date23 text,
    secondarymonetary_amount23 text,
    secondary_quantity23 text,
    secondary_version23 text,
    secondary_industry_code23 text,
    secondary_response_code23 text,
    secondary_claim_code_type24 text,
    secondary_claim_code24 text,
    secondary_date_qual24 text,
    secondary_date24 text,
    secondarymonetary_amount24 text,
    secondary_quantity24 text,
    secondary_version24 text,
    secondary_industry_code24 text,
    secondary_response_code24 text,
    secondary_claim_code_type25 text,
    secondary_claim_code25 text,
    secondary_date_qual25 text,
    secondary_date25 text,
    secondarymonetary_amount25 text,
    secondary_quantity25 text,
    secondary_version25 text,
    secondary_industry_code25 text,
    secondary_response_code25 text,
    secondary_claim_code_type26 text,
    secondary_claim_code26 text,
    secondary_date_qual26 text,
    secondary_date26 text,
    secondarymonetary_amount26 text,
    secondary_quantity26 text,
    secondary_version26 text,
    secondary_industry_code26 text,
    secondary_response_code26 text,
    secondary_claim_code_type27 text,
    secondary_claim_code27 text,
    secondary_date_qual27 text,
    secondary_date27 text,
    secondarymonetary_amount27 text,
    secondary_quantity27 text,
    secondary_version27 text,
    secondary_industry_code27 text,
    secondary_response_code27 text,
    secondary_claim_code_type28 text,
    secondary_claim_code28 text,
    secondary_date_qual28 text,
    secondary_date28 text,
    secondarymonetary_amount28 text,
    secondary_quantity28 text,
    secondary_version28 text,
    secondary_industry_code28 text,
    secondary_response_code28 text,
    secondary_claim_code_type29 text,
    secondary_claim_code29 text,
    secondary_date_qual29 text,
    secondary_date29 text,
    secondarymonetary_amount29 text,
    secondary_quantity29 text,
    secondary_version29 text,
    secondary_industry_code29 text,
    secondary_response_code29 text,
    secondary_claim_code_type30 text,
    secondary_claim_code30 text,
    secondary_date_qual30 text,
    secondary_date30 text,
    secondarymonetary_amount30 text,
    secondary_quantity30 text,
    secondary_version30 text,
    secondary_industry_code30 text,
    secondary_response_code30 text,
    secondary_claim_code_type31 text,
    secondary_claim_code31 text,
    secondary_date_qual31 text,
    secondary_date31 text,
    secondarymonetary_amount31 text,
    secondary_quantity31 text,
    secondary_version31 text,
    secondary_industry_code31 text,
    secondary_response_code31 text,
    secondary_claim_code_type32 text,
    secondary_claim_code32 text,
    secondary_date_qual32 text,
    secondary_date32 text,
    secondarymonetary_amount32 text,
    secondary_quantity32 text,
    secondary_version32 text,
    secondary_industry_code32 text,
    secondary_response_code32 text,
    secondary_claim_code_type33 text,
    secondary_claim_code33 text,
    secondary_date_qual33 text,
    secondary_date33 text,
    secondarymonetary_amount33 text,
    secondary_quantity33 text,
    secondary_version33 text,
    secondary_industry_code33 text,
    secondary_response_code33 text,
    secondary_claim_code_type34 text,
    secondary_claim_code34 text,
    secondary_date_qual34 text,
    secondary_date34 text,
    secondarymonetary_amount34 text,
    secondary_quantity34 text,
    secondary_version34 text,
    secondary_industry_code34 text,
    secondary_response_code34 text,
    secondary_claim_code_type35 text,
    secondary_claim_code35 text,
    secondary_date_qual35 text,
    secondary_date35 text,
    secondarymonetary_amount35 text,
    secondary_quantity35 text,
    secondary_version35 text,
    secondary_industry_code35 text,
    secondary_response_code35 text,
    secondary_claim_code_type36 text,
    secondary_claim_code36 text,
    secondary_date_qual36 text,
    secondary_date36 text,
    secondarymonetary_amount36 text,
    secondary_quantity36 text,
    secondary_version36 text,
    secondary_industry_code36 text,
    secondary_response_code36 text,
    secondary_claim_code_type37 text,
    secondary_claim_code37 text,
    secondary_date_qual37 text,
    secondary_date37 text,
    secondarymonetary_amount37 text,
    secondary_quantity37 text,
    secondary_version37 text,
    secondary_industry_code37 text,
    secondary_response_code37 text,
    secondary_claim_code_type38 text,
    secondary_claim_code38 text,
    secondary_date_qual38 text,
    secondary_date38 text,
    secondarymonetary_amount38 text,
    secondary_quantity38 text,
    secondary_version38 text,
    secondary_industry_code38 text,
    secondary_response_code38 text,
    secondary_claim_code_type39 text,
    secondary_claim_code39 text,
    secondary_date_qual39 text,
    secondary_date39 text,
    secondarymonetary_amount39 text,
    secondary_quantity39 text,
    secondary_version39 text,
    secondary_industry_code39 text,
    secondary_response_code39 text
);


ALTER TABLE public.child_inst_2300_hi OWNER TO ras;

--
-- Name: child_inst_2300_nte; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2300_nte (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    note_reference_code text,
    claim_note_text text
);


ALTER TABLE public.child_inst_2300_nte OWNER TO ras;

--
-- Name: child_inst_2300_pwk; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2300_pwk (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    attachment_report_type_code text,
    attachment_transmission_code text,
    attachment_control_number1 text,
    attachment_control_number2 text
);


ALTER TABLE public.child_inst_2300_pwk OWNER TO ras;

--
-- Name: child_inst_2300_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2300_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    reference_identification_qualifier text,
    ref_02_code text
);


ALTER TABLE public.child_inst_2300_ref OWNER TO ras;

--
-- Name: child_inst_2310a_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2310a_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    attending_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2310a_ref OWNER TO ras;

--
-- Name: child_inst_2310b_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2310b_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    operating_physician_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2310b_ref OWNER TO ras;

--
-- Name: child_inst_2310c_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2310c_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_operating_physician_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2310c_ref OWNER TO ras;

--
-- Name: child_inst_2310d_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2310d_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    rendering_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2310d_ref OWNER TO ras;

--
-- Name: child_inst_2310e_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2310e_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    service_facility_identification_qualifier text,
    ref_02 text
);


ALTER TABLE public.child_inst_2310e_ref OWNER TO ras;

--
-- Name: child_inst_2310f_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2310f_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    referring_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2310f_ref OWNER TO ras;

--
-- Name: child_inst_2320_amt; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2320_amt (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    amt_1 text,
    amt_2 numeric(10,2)
);


ALTER TABLE public.child_inst_2320_amt OWNER TO ras;

--
-- Name: child_inst_2320_cas; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2320_cas (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_adjustment_group_code1 text,
    claim_adjustment_reason_code1 text,
    claim_adjustment_amount1 text,
    claim_adjustment_quantity1 text,
    claim_adjustment_reason_code2 text,
    claim_adjustment_amount2 text,
    claim_adjustment_quantity2 text,
    claim_adjustment_reason_code3 text,
    claim_adjustment_amount3 text,
    claim_adjustment_quantity3 text,
    claim_adjustment_reason_code4 text,
    claim_adjustment_amount4 text,
    claim_adjustment_quantity4 text,
    claim_adjustment_reason_code5 text,
    claim_adjustment_amount5 text,
    claim_adjustment_quantity5 text,
    claim_adjustment_reason_code6 text,
    claim_adjustment_amount6 text,
    claim_adjustment_quantity6 text
);


ALTER TABLE public.child_inst_2320_cas OWNER TO ras;

--
-- Name: child_inst_2330b_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2330b_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2330b_ref OWNER TO ras;

--
-- Name: child_inst_2330c_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2330c_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_attending_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2330c_ref OWNER TO ras;

--
-- Name: child_inst_2330d_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2330d_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_operating_physician_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2330d_ref OWNER TO ras;

--
-- Name: child_inst_2330e_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2330e_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_other_operating_physician_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2330e_ref OWNER TO ras;

--
-- Name: child_inst_2330f_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2330f_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_service_location_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2330f_ref OWNER TO ras;

--
-- Name: child_inst_2330g_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2330g_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_render_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2330g_ref OWNER TO ras;

--
-- Name: child_inst_2330h_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2330h_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_refer_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2330h_ref OWNER TO ras;

--
-- Name: child_inst_2330i_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2330i_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_billing_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_inst_2330i_ref OWNER TO ras;

--
-- Name: child_inst_2400_amt; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2400_amt (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    amount_qualifier_code text,
    amt_02 text
);


ALTER TABLE public.child_inst_2400_amt OWNER TO ras;

--
-- Name: child_inst_2400_dtp; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2400_dtp (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    date_time_qualifier text,
    date_time_period_format_qualifier text,
    begin_date_of_service text,
    end_date_of_service text
);


ALTER TABLE public.child_inst_2400_dtp OWNER TO ras;

--
-- Name: child_inst_2400_pwk; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2400_pwk (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    line_attachment_report_type_code1 text,
    line_attachment_transmission_code1 text,
    line_attachment_control_number_qual text,
    line_attachment_control_number text
);


ALTER TABLE public.child_inst_2400_pwk OWNER TO ras;

--
-- Name: child_inst_2400_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2400_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    reference_identification_qualifier text,
    ref_02 text
);


ALTER TABLE public.child_inst_2400_ref OWNER TO ras;

--
-- Name: child_inst_2410_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2410_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    prescription_drug_identification_qualifier text,
    ref_02 text
);


ALTER TABLE public.child_inst_2410_ref OWNER TO ras;

--
-- Name: child_inst_2420a_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2420a_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    operating_physician_secondary_identification_qual text,
    ref_02 text,
    ref_04_01 text,
    ref_04_02 text
);


ALTER TABLE public.child_inst_2420a_ref OWNER TO ras;

--
-- Name: child_inst_2420b_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2420b_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_operating_physician_secondary_identification_qual text,
    ref_02 text,
    ref_04_01 text,
    ref_04_02 text
);


ALTER TABLE public.child_inst_2420b_ref OWNER TO ras;

--
-- Name: child_inst_2420c_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2420c_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    rendering_provider_secondary_identification_qual text,
    ref_02 text,
    ref_04_01 text,
    ref_04_02 text
);


ALTER TABLE public.child_inst_2420c_ref OWNER TO ras;

--
-- Name: child_inst_2420d_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2420d_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    referring_provider_secondary_identification_qual text,
    ref_02 text,
    ref_04_01 text,
    ref_04_02 text
);


ALTER TABLE public.child_inst_2420d_ref OWNER TO ras;

--
-- Name: child_inst_2430_cas; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_2430_cas (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    adjustment_group_code text,
    adjustment_reason_code1 text,
    adjustment_amount1 text,
    adjustment_quantity1 text,
    adjustment_reason_code2 text,
    adjustment_amount2 text,
    adjustment_quantity2 text,
    adjustment_reason_code3 text,
    adjustment_amount3 text,
    adjustment_quantity3 text,
    adjustment_reason_code4 text,
    adjustment_amount4 text,
    adjustment_quantity4 text,
    adjustment_reason_code5 text,
    adjustment_amount5 text,
    adjustment_quantity5 text,
    adjustment_reason_code6 text,
    adjustment_amount6 text,
    adjustment_quantity6 text
);


ALTER TABLE public.child_inst_2430_cas OWNER TO ras;

--
-- Name: child_inst_claim_identifier_amt; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_claim_identifier_amt (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    amt_1 text,
    amt_2 text
);


ALTER TABLE public.child_inst_claim_identifier_amt OWNER TO ras;

--
-- Name: child_inst_claim_identifier_dtp; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_inst_claim_identifier_dtp (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    date_time_qualifier text,
    date_field_type text,
    begin_date_of_service text,
    end_date_of_service text
);


ALTER TABLE public.child_inst_claim_identifier_dtp OWNER TO ras;

--
-- Name: child_prof_2010aa_per; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2010aa_per (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    billing_provider_contact_function_code text,
    billing_provider_contact_name text,
    billing_provider_communication_number_qualifier1 text,
    billing_provider_communication_number1 text,
    billing_provider_communication_number_qualifier2 text,
    billing_provider_communication_number2 text,
    billing_provider_communication_number_qualifier3 text,
    billing_provider_communication_number3 text
);


ALTER TABLE public.child_prof_2010aa_per OWNER TO ras;

--
-- Name: child_prof_2010aa_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2010aa_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    billing_provider_ref_identification_qualifier text,
    billing_provider_employers_identification_number text
);


ALTER TABLE public.child_prof_2010aa_ref OWNER TO ras;

--
-- Name: child_prof_2010ac_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2010ac_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    pay_to_plan_ref_identification_qual text,
    payer_identification_number text
);


ALTER TABLE public.child_prof_2010ac_ref OWNER TO ras;

--
-- Name: child_prof_2010ba_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2010ba_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    subscriber_secondary_identification_code_qual text,
    subscriber_supplemental_identifier text
);


ALTER TABLE public.child_prof_2010ba_ref OWNER TO ras;

--
-- Name: child_prof_2010bb_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2010bb_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    payer_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_prof_2010bb_ref OWNER TO ras;

--
-- Name: child_prof_2300_crc; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2300_crc (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    ambulance_certification_code text,
    crc_02 text,
    crc_03 text,
    crc_04 text,
    crc_05 text,
    crc_06 text,
    crc_07 text
);


ALTER TABLE public.child_prof_2300_crc OWNER TO ras;

--
-- Name: child_prof_2300_dtp; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2300_dtp (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    date_time_qualifier text,
    date_time_period_format_qualifier text,
    dtp_03 text
);


ALTER TABLE public.child_prof_2300_dtp OWNER TO ras;

--
-- Name: child_prof_2300_hi; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2300_hi (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    primary_claim_code_type text,
    primary_claim_code text,
    secondary_claim_code_type1 text,
    secondary_claim_code1 text,
    secondary_claim_code_type2 text,
    secondary_claim_code2 text,
    secondary_claim_code_type3 text,
    secondary_claim_code3 text,
    secondary_claim_code_type4 text,
    secondary_claim_code4 text,
    secondary_claim_code_type5 text,
    secondary_claim_code5 text,
    secondary_claim_code_type6 text,
    secondary_claim_code6 text,
    secondary_claim_code_type7 text,
    secondary_claim_code7 text,
    secondary_claim_code_type8 text,
    secondary_claim_code8 text,
    secondary_claim_code_type9 text,
    secondary_claim_code9 text,
    secondary_claim_code_type10 text,
    secondary_claim_code10 text,
    secondary_claim_code_type11 text,
    secondary_claim_code11 text,
    secondary_claim_code_type12 text,
    secondary_claim_code12 text,
    secondary_claim_code_type13 text,
    secondary_claim_code13 text,
    secondary_claim_code_type14 text,
    secondary_claim_code14 text,
    secondary_claim_code_type15 text,
    secondary_claim_code15 text,
    secondary_claim_code_type16 text,
    secondary_claim_code16 text,
    secondary_claim_code_type17 text,
    secondary_claim_code17 text,
    secondary_claim_code_type18 text,
    secondary_claim_code18 text,
    secondary_claim_code_type19 text,
    secondary_claim_code19 text,
    secondary_claim_code_type20 text,
    secondary_claim_code20 text,
    secondary_claim_code_type21 text,
    secondary_claim_code21 text,
    secondary_claim_code_type22 text,
    secondary_claim_code22 text,
    secondary_claim_code_type23 text,
    secondary_claim_code23 text,
    secondary_claim_code_type24 text,
    secondary_claim_code24 text,
    secondary_claim_code_type25 text,
    secondary_claim_code25 text,
    secondary_claim_code_type26 text,
    secondary_claim_code26 text,
    secondary_claim_code_type27 text,
    secondary_claim_code27 text,
    secondary_claim_code_type28 text,
    secondary_claim_code28 text,
    secondary_claim_code_type29 text,
    secondary_claim_code29 text,
    secondary_claim_code_type30 text,
    secondary_claim_code30 text,
    secondary_claim_code_type31 text,
    secondary_claim_code31 text,
    secondary_claim_code_type32 text,
    secondary_claim_code32 text,
    secondary_claim_code_type33 text,
    secondary_claim_code33 text,
    secondary_claim_code_type34 text,
    secondary_claim_code34 text,
    secondary_claim_code_type35 text,
    secondary_claim_code35 text,
    secondary_claim_code_type36 text,
    secondary_claim_code36 text,
    secondary_claim_code_type37 text,
    secondary_claim_code37 text,
    secondary_claim_code_type38 text,
    secondary_claim_code38 text,
    secondary_claim_code_type39 text,
    secondary_claim_code39 text
);


ALTER TABLE public.child_prof_2300_hi OWNER TO ras;

--
-- Name: child_prof_2300_pwk; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2300_pwk (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    attachment_report_type_code text,
    attachment_transmission_code text,
    attachment_control_number1 text,
    attachment_control_number2 text
);


ALTER TABLE public.child_prof_2300_pwk OWNER TO ras;

--
-- Name: child_prof_2300_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2300_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    reference_identification_qualifier text,
    ref_02_code text
);


ALTER TABLE public.child_prof_2300_ref OWNER TO ras;

--
-- Name: child_prof_2310a_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2310a_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    referring_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_prof_2310a_ref OWNER TO ras;

--
-- Name: child_prof_2310b_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2310b_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    rendering_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_prof_2310b_ref OWNER TO ras;

--
-- Name: child_prof_2310c_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2310c_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    service_facility_identification_qualifier text,
    ref_02 text
);


ALTER TABLE public.child_prof_2310c_ref OWNER TO ras;

--
-- Name: child_prof_2310d_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2310d_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    supervising_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_prof_2310d_ref OWNER TO ras;

--
-- Name: child_prof_2320_amt; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2320_amt (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    amt_1 text,
    amt_2 numeric(10,2)
);


ALTER TABLE public.child_prof_2320_amt OWNER TO ras;

--
-- Name: child_prof_2320_cas; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2320_cas (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_adjustment_group_code1 text,
    claim_adjustment_reason_code1 text,
    claim_adjustment_amount1 text,
    claim_adjustment_quantity1 text,
    claim_adjustment_reason_code2 text,
    claim_adjustment_amount2 text,
    claim_adjustment_quantity2 text,
    claim_adjustment_reason_code3 text,
    claim_adjustment_amount3 text,
    claim_adjustment_quantity3 text,
    claim_adjustment_reason_code4 text,
    claim_adjustment_amount4 text,
    claim_adjustment_quantity4 text,
    claim_adjustment_reason_code5 text,
    claim_adjustment_amount5 text,
    claim_adjustment_quantity5 text,
    claim_adjustment_reason_code6 text,
    claim_adjustment_amount6 text,
    claim_adjustment_quantity6 text
);


ALTER TABLE public.child_prof_2320_cas OWNER TO ras;

--
-- Name: child_prof_2330b_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2330b_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_prof_2330b_ref OWNER TO ras;

--
-- Name: child_prof_2330c_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2330c_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_refer_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_prof_2330c_ref OWNER TO ras;

--
-- Name: child_prof_2330d_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2330d_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_render_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_prof_2330d_ref OWNER TO ras;

--
-- Name: child_prof_2330e_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2330e_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_svc_location_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_prof_2330e_ref OWNER TO ras;

--
-- Name: child_prof_2330f_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2330f_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_spvc_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_prof_2330f_ref OWNER TO ras;

--
-- Name: child_prof_2330g_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2330g_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_billing_provider_secondary_identification_qual text,
    ref_02 text
);


ALTER TABLE public.child_prof_2330g_ref OWNER TO ras;

--
-- Name: child_prof_2400_amt; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2400_amt (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    amount_qualifier_code text,
    amt_02 text
);


ALTER TABLE public.child_prof_2400_amt OWNER TO ras;

--
-- Name: child_prof_2400_crc; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2400_crc (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    certification_code text,
    crc_02 text,
    crc_03 text,
    crc_04 text,
    crc_05 text,
    crc_06 text,
    crc_07 text
);


ALTER TABLE public.child_prof_2400_crc OWNER TO ras;

--
-- Name: child_prof_2400_dtp; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2400_dtp (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    date_time_qualifier text,
    date_field_type text,
    begin_date_of_service text,
    end_date_of_service text
);


ALTER TABLE public.child_prof_2400_dtp OWNER TO ras;

--
-- Name: child_prof_2400_k3; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2400_k3 (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    fixed_format_information text
);


ALTER TABLE public.child_prof_2400_k3 OWNER TO ras;

--
-- Name: child_prof_2400_mea; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2400_mea (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    test_measurement_reference_id_code text,
    test_measurement_qualifier text,
    test_results text
);


ALTER TABLE public.child_prof_2400_mea OWNER TO ras;

--
-- Name: child_prof_2400_nte; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2400_nte (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    note_reference_code text,
    nte_02 text
);


ALTER TABLE public.child_prof_2400_nte OWNER TO ras;

--
-- Name: child_prof_2400_pwk; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2400_pwk (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    line_attachment_report_type_code1 text,
    line_attachment_transmission_code1 text,
    line_attachment_control_number_qual text,
    line_attachment_control_number text
);


ALTER TABLE public.child_prof_2400_pwk OWNER TO ras;

--
-- Name: child_prof_2400_qty; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2400_qty (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    ambulance_patients_quantity_qualifier text,
    qty_02 text
);


ALTER TABLE public.child_prof_2400_qty OWNER TO ras;

--
-- Name: child_prof_2400_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2400_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    reference_identification_qualifier text,
    ref_02 text,
    payer_identification_number text,
    other_payer_primary_identifier text
);


ALTER TABLE public.child_prof_2400_ref OWNER TO ras;

--
-- Name: child_prof_2410_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2410_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    prescription_drug_identification_qualifier text,
    ref_02 text
);


ALTER TABLE public.child_prof_2410_ref OWNER TO ras;

--
-- Name: child_prof_2420a_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2420a_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    rendering_provider_secondary_identification_qual text,
    ref_02 text,
    ref_04_01 text,
    ref_04_02 text
);


ALTER TABLE public.child_prof_2420a_ref OWNER TO ras;

--
-- Name: child_prof_2420b_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2420b_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    purchased_svc_provider_secondary_identification_qual text,
    ref_02 text,
    ref_04_01 text,
    ref_04_02 text
);


ALTER TABLE public.child_prof_2420b_ref OWNER TO ras;

--
-- Name: child_prof_2420c_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2420c_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    service_facility_identification_qualifier text,
    ref_02 text,
    ref_04_01 text,
    ref_04_02 text
);


ALTER TABLE public.child_prof_2420c_ref OWNER TO ras;

--
-- Name: child_prof_2420d_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2420d_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    supervising_provider_secondary_identification_qual text,
    ref_02 text,
    ref_04_01 text,
    ref_04_02 text
);


ALTER TABLE public.child_prof_2420d_ref OWNER TO ras;

--
-- Name: child_prof_2420e_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2420e_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    ordering_provider_secondary_identification_qual text,
    ref_02 text,
    ref_04_01 text,
    ref_04_02 text
);


ALTER TABLE public.child_prof_2420e_ref OWNER TO ras;

--
-- Name: child_prof_2420f_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2420f_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    referring_provider_secondary_identification_qual text,
    ref_02 text,
    ref_04_01 text,
    ref_04_02 text
);


ALTER TABLE public.child_prof_2420f_ref OWNER TO ras;

--
-- Name: child_prof_2430_cas; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_2430_cas (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    adjustment_group_code text,
    adjustment_reason_code1 text,
    adjustment_amount1 text,
    adjustment_quantity1 text,
    adjustment_reason_code2 text,
    adjustment_amount2 text,
    adjustment_quantity2 text,
    adjustment_reason_code3 text,
    adjustment_amount3 text,
    adjustment_quantity3 text,
    adjustment_reason_code4 text,
    adjustment_amount4 text,
    adjustment_quantity4 text,
    adjustment_reason_code5 text,
    adjustment_amount5 text,
    adjustment_quantity5 text,
    adjustment_reason_code6 text,
    adjustment_amount6 text,
    adjustment_quantity6 text
);


ALTER TABLE public.child_prof_2430_cas OWNER TO ras;

--
-- Name: child_prof_claim_identifier_amt; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_claim_identifier_amt (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    amt_1 text,
    amt_2 text
);


ALTER TABLE public.child_prof_claim_identifier_amt OWNER TO ras;

--
-- Name: child_prof_claim_identifier_dtp; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_prof_claim_identifier_dtp (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    date_time_qualifier text,
    date_field_type text,
    begin_date_of_service text,
    end_date_of_service text
);


ALTER TABLE public.child_prof_claim_identifier_dtp OWNER TO ras;

--
-- Name: child_raps_cms_tracking_raps_resp; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_raps_cms_tracking_raps_resp (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    file_status text,
    file_processed_status text,
    file_url text,
    response_type text,
    manual_update_comment text,
    retry_count integer,
    last_updated timestamp without time zone,
    db_load_timestamp timestamp without time zone
);


ALTER TABLE public.child_raps_cms_tracking_raps_resp OWNER TO ras;

--
-- Name: child_raps_feras_error_raps_resp; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_raps_feras_error_raps_resp (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    feras_error_record text,
    feras_error_sequence text,
    feras_error_code text,
    feras_error_description text
);


ALTER TABLE public.child_raps_feras_error_raps_resp OWNER TO ras;

--
-- Name: child_remit_1000a_per; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_1000a_per (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    contact_function_code text,
    payer_contact_name text,
    communication_number_qualifier text,
    payer_contact_communication_number text,
    communication_number_qualifier_5 text,
    payer_contact_communication_number_6 text,
    communication_number_qualifier_7 text,
    payer_contact_communication_number_8 text,
    contact_inquiry_reference text
);


ALTER TABLE public.child_remit_1000a_per OWNER TO ras;

--
-- Name: child_remit_1000a_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_1000a_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    reference_identification_qualifier text,
    additional_payer_identifier text,
    description text,
    reference_identifier text
);


ALTER TABLE public.child_remit_1000a_ref OWNER TO ras;

--
-- Name: child_remit_2100_amt; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2100_amt (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    amount_qualifier_code text,
    claim_supplemental_information_amount text,
    credit_debit_flag_code text
);


ALTER TABLE public.child_remit_2100_amt OWNER TO ras;

--
-- Name: child_remit_2100_cas; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2100_cas (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    claim_adjustment_group_code1 text,
    adjustment_reason_code1 text,
    adjustment_amount1 text,
    adjustment_quantity1 text,
    adjustment_reason_code2 text,
    adjustment_amount2 text,
    adjustment_quantity2 text,
    adjustment_reason_code3 text,
    adjustment_amount3 text,
    adjustment_quantity3 text,
    adjustment_reason_code4 text,
    adjustment_amount4 text,
    adjustment_quantity4 text,
    adjustment_reason_code5 text,
    adjustment_amount5 text,
    adjustment_quantity5 text,
    adjustment_reason_code6 text,
    adjustment_amount6 text,
    adjustment_quantity6 text
);


ALTER TABLE public.child_remit_2100_cas OWNER TO ras;

--
-- Name: child_remit_2100_dtm; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2100_dtm (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    date_time_qualifier text,
    claim_date text,
    "time" text,
    time_code text,
    date_time_period_format_qualifier text,
    date_time_period text
);


ALTER TABLE public.child_remit_2100_dtm OWNER TO ras;

--
-- Name: child_remit_2100_nm1; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2100_nm1 (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    entity_identifier_code text,
    entity_type_qualifier text,
    patient_last_name text,
    patient_first_name text,
    patient_middle_name_or_initial text,
    name_prefix text,
    patient_name_suffix text,
    identification_code_qualifier text,
    patient_identifier text,
    entity_relationship_code text,
    entity_identifier_code_11 text,
    name_last_org_name text
);


ALTER TABLE public.child_remit_2100_nm1 OWNER TO ras;

--
-- Name: child_remit_2100_per; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2100_per (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    contact_function_code text,
    claim_contact_name text,
    communication_number_qualifier text,
    claim_contact_communications_number text,
    communication_number_qualifier_5 text,
    claim_contact_communications_number_6 text,
    communication_number_qualifier_7 text,
    communication_number_extension text,
    contact_inquiry_reference text
);


ALTER TABLE public.child_remit_2100_per OWNER TO ras;

--
-- Name: child_remit_2100_qty; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2100_qty (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    quantity_qualifier text,
    claim_supplemental_information_quantity text,
    composite_unit_of_measure text,
    free_form_information text
);


ALTER TABLE public.child_remit_2100_qty OWNER TO ras;

--
-- Name: child_remit_2100_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2100_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    reference_identification_qualifier text,
    other_claim_related_identifier text,
    description text,
    reference_identifier text,
    reference_identification_qualifier_1 text,
    rendering_provider_secondary_identifier text,
    description_3 text,
    reference_identifier_4 text
);


ALTER TABLE public.child_remit_2100_ref OWNER TO ras;

--
-- Name: child_remit_2110_amt; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2110_amt (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    amount_qualifier_code text,
    service_supplemental_amount text,
    credit_debit_flag_code text
);


ALTER TABLE public.child_remit_2110_amt OWNER TO ras;

--
-- Name: child_remit_2110_cas; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2110_cas (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    claim_adjustment_group_code text,
    adjustment_reason_code1 text,
    adjustment_amount1 text,
    adjustment_quantity1 text,
    adjustment_reason_code2 text,
    adjustment_amount2 text,
    adjustment_quantity2 text,
    adjustment_reason_code3 text,
    adjustment_amount3 text,
    adjustment_quantity3 text,
    adjustment_reason_code4 text,
    adjustment_amount4 text,
    adjustment_quantity4 text,
    adjustment_reason_code5 text,
    adjustment_amount5 text,
    adjustment_quantity5 text,
    adjustment_reason_code6 text,
    adjustment_amount6 text,
    adjustment_quantity6 text
);


ALTER TABLE public.child_remit_2110_cas OWNER TO ras;

--
-- Name: child_remit_2110_dtm; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2110_dtm (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    date_time_qualifier text,
    service_date text,
    "time" text,
    time_code text,
    date_time_period_format_qualifier text,
    date_time_period text
);


ALTER TABLE public.child_remit_2110_dtm OWNER TO ras;

--
-- Name: child_remit_2110_lq; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2110_lq (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    code_list_qualifier_code text,
    remark_code text
);


ALTER TABLE public.child_remit_2110_lq OWNER TO ras;

--
-- Name: child_remit_2110_qty; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2110_qty (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    quantity_qualifier text,
    service_supplemental_quantity_count text,
    composite_unit_of_measure text,
    free_form_information text
);


ALTER TABLE public.child_remit_2110_qty OWNER TO ras;

--
-- Name: child_remit_2110_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_2110_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    reference_identification_qualifier text,
    provider_identifier text,
    description_3 text,
    reference_identifier text
);


ALTER TABLE public.child_remit_2110_ref OWNER TO ras;

--
-- Name: child_remit_bht_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_bht_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    reference_identification_qualifier text,
    receiver_identifier text,
    description text,
    reference_identifier text
);


ALTER TABLE public.child_remit_bht_ref OWNER TO ras;

--
-- Name: child_remit_identifier_nm1; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_remit_identifier_nm1 (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    entity_identifier_code text,
    patient_identifier text
);


ALTER TABLE public.child_remit_identifier_nm1 OWNER TO ras;

--
-- Name: child_resp_277_2000b_amt; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_resp_277_2000b_amt (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    total_accepted_amount text
);


ALTER TABLE public.child_resp_277_2000b_amt OWNER TO ras;

--
-- Name: child_resp_277_2000b_qty; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_resp_277_2000b_qty (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    accepted_claim_quantity text
);


ALTER TABLE public.child_resp_277_2000b_qty OWNER TO ras;

--
-- Name: child_resp_277_2000d_dtp; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_resp_277_2000d_dtp (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    date_time_qualifier text,
    date_field_type text,
    begin_date_of_service text,
    end_date_of_service text
);


ALTER TABLE public.child_resp_277_2000d_dtp OWNER TO ras;

--
-- Name: child_resp_277_2000d_ref; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_resp_277_2000d_ref (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    qual text,
    ref_02 text
);


ALTER TABLE public.child_resp_277_2000d_ref OWNER TO ras;

--
-- Name: child_resp_277_2000d_stc; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_resp_277_2000d_stc (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    billing_provider_status text,
    full_status_code text,
    status_code text,
    secondary_status_code text,
    tertiary_status_code text
);


ALTER TABLE public.child_resp_277_2000d_stc OWNER TO ras;

--
-- Name: child_resp_277_2220d_stc; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_resp_277_2220d_stc (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    full_status_code text,
    status_reject_code text,
    secondary_status_code text,
    tertiary_status_code text
);


ALTER TABLE public.child_resp_277_2220d_stc OWNER TO ras;

--
-- Name: child_resp_999_2100_ik4; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_resp_999_2100_ik4 (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    element_position_in_segment text,
    component_data_element_position text,
    element_error_code text
);


ALTER TABLE public.child_resp_999_2100_ik4 OWNER TO ras;

--
-- Name: child_x12file_resp_file; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_x12file_resp_file (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    file_name text,
    file_url text,
    response_file_type text,
    total_encounters text,
    error_code text,
    duplicate_st_se_submission text,
    duplicate_file_id_submission text,
    response_date text,
    applied_status text,
    file_processed_status text,
    manual_update_comment text,
    retry_count integer,
    last_updated timestamp without time zone,
    db_load_timestamp timestamp without time zone,
    file_hash text
);


ALTER TABLE public.child_x12file_resp_file OWNER TO ras;

--
-- Name: child_x12file_x12shards; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.child_x12file_x12shards (
    id bigint NOT NULL,
    parent_id bigint NOT NULL,
    shard_file_name text,
    shard_file_input_location text,
    shard_file_st_index text,
    shard_file_processed_status text
);


ALTER TABLE public.child_x12file_x12shards OWNER TO ras;

--
-- Name: claim_error; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.claim_error (
    id bigint NOT NULL,
    resp_file_id bigint,
    plan_id text,
    claim_id bigint,
    claim_line_id bigint,
    error_ref_id bigint,
    error_internal_relation_name text,
    error_code text
);


ALTER TABLE public.claim_error OWNER TO ras;

--
-- Name: cms_submitter_info; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.cms_submitter_info (
    id bigint NOT NULL,
    a_id bigint NOT NULL,
    cms_provided_id text,
    x12_file_number integer,
    product_name text,
    date_created timestamp without time zone,
    last_updated timestamp without time zone,
    active boolean DEFAULT false
);


ALTER TABLE public.cms_submitter_info OWNER TO ras;

--
-- Name: customer; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.customer (
    id bigint NOT NULL,
    date_created timestamp without time zone,
    last_updated timestamp without time zone,
    name text,
    description text
);


ALTER TABLE public.customer OWNER TO ras;

--
-- Name: customer_account; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.customer_account (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    parent_account_id bigint,
    date_created timestamp without time zone,
    last_updated timestamp without time zone,
    modified_by text,
    name text NOT NULL,
    description text,
    status text
);


ALTER TABLE public.customer_account OWNER TO ras;

--
-- Name: databasechangelog; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.databasechangelog (
    id character varying(255) NOT NULL,
    author character varying(255) NOT NULL,
    filename character varying(255) NOT NULL,
    dateexecuted timestamp without time zone NOT NULL,
    orderexecuted integer NOT NULL,
    exectype character varying(10) NOT NULL,
    md5sum character varying(35),
    description character varying(255),
    comments character varying(255),
    tag character varying(255),
    liquibase character varying(20),
    contexts character varying(255),
    labels character varying(255),
    deployment_id character varying(10)
);


ALTER TABLE public.databasechangelog OWNER TO ras;

--
-- Name: databasechangeloglock; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.databasechangeloglock (
    id integer NOT NULL,
    locked boolean NOT NULL,
    lockgranted timestamp without time zone,
    lockedby character varying(255)
);


ALTER TABLE public.databasechangeloglock OWNER TO ras;

--
-- Name: flow; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.flow (
    id bigint NOT NULL,
    name text NOT NULL,
    status text,
    created_by text,
    linked_orig_flow bigint,
    additional_info text,
    date_created timestamp with time zone DEFAULT now() NOT NULL,
    last_updated timestamp with time zone
);


ALTER TABLE public.flow OWNER TO ras;

--
-- Name: flow_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.flow_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.flow_id_seq OWNER TO ras;

--
-- Name: flow_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.flow_id_seq OWNED BY public.flow.id;


--
-- Name: flow_item; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.flow_item (
    id bigint NOT NULL,
    flow_id bigint NOT NULL,
    flow_status text NOT NULL,
    item_type text NOT NULL,
    step_name text NOT NULL,
    step_status text,
    next_run_time timestamp with time zone DEFAULT now(),
    date_created timestamp with time zone DEFAULT now() NOT NULL,
    additional_info text,
    other_obj_id bigint,
    other_rel_name text,
    future1 text,
    step_config jsonb NOT NULL,
    step_context jsonb NOT NULL
);


ALTER TABLE public.flow_item OWNER TO ras;

--
-- Name: flow_item_history; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.flow_item_history (
    id bigint NOT NULL,
    flow_item_id bigint NOT NULL,
    flow_status text NOT NULL,
    item_type text NOT NULL,
    step_name text NOT NULL,
    step_status text,
    processed_at timestamp with time zone DEFAULT now(),
    additional_info text,
    other_obj_id bigint,
    other_rel_name text,
    future1 text,
    step_config jsonb NOT NULL,
    step_context jsonb NOT NULL
);


ALTER TABLE public.flow_item_history OWNER TO ras;

--
-- Name: flow_item_history_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.flow_item_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.flow_item_history_id_seq OWNER TO ras;

--
-- Name: flow_item_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.flow_item_history_id_seq OWNED BY public.flow_item_history.id;


--
-- Name: flow_item_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.flow_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.flow_item_id_seq OWNER TO ras;

--
-- Name: flow_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.flow_item_id_seq OWNED BY public.flow_item.id;


--
-- Name: global_ticker; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.global_ticker (
    id bigint NOT NULL,
    name text,
    ticker bigint
);


ALTER TABLE public.global_ticker OWNER TO ras;

--
-- Name: h_plan_config; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.h_plan_config (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    key text,
    value text
);


ALTER TABLE public.h_plan_config OWNER TO ras;

--
-- Name: h_plan_report; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.h_plan_report (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    plan_id text,
    user_name text,
    report_name text,
    report_url text,
    file_status text,
    product_name text,
    date_created timestamp without time zone
);


ALTER TABLE public.h_plan_report OWNER TO ras;

--
-- Name: h_plan_submitter; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.h_plan_submitter (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    cms_submitter_id bigint NOT NULL,
    description text,
    additional_notes text,
    created_by text,
    delete_status text,
    date_created timestamp without time zone,
    last_updated timestamp without time zone
);


ALTER TABLE public.h_plan_submitter OWNER TO ras;

--
-- Name: hcc_diag; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.hcc_diag (
    id bigint NOT NULL,
    plan_id text,
    pcp_id text,
    pcp_last_name text,
    pcp_first_name text,
    plan_member_id text,
    beneficiary_member_identifier text,
    beneficiary_last_name text,
    beneficiary_first_name text,
    subscriber_birth_date text,
    subscriber_gender_code text,
    patient_control_number text,
    place_of_service text,
    claim_frequency_code text,
    submission_date text,
    begin_date_of_service text,
    end_date_of_service text,
    cmsicn text,
    payer_claim_control_number text,
    encounter_or_chartreview text,
    billing_provider_last_organisation_name text,
    billing_provider_npi_identifier text,
    billing_provider_taxonomy text,
    rendering_provider_last_name text,
    rendering_provider_first_name text,
    rendering_provider_identifier text,
    rendering_provider_taxonomy text,
    attending_provider_last_name text,
    attending_provider_first_name text,
    attending_provider_identifier text,
    attending_provider_taxonomy text,
    claim_code text,
    hcc_value text,
    encounter_type_switch text,
    allowed_disallowed text,
    allowed_disallowed_reason_code text,
    add_delete_ind text,
    encounter_status text,
    duplicate_plan_icn text,
    duplicate_encounter_icn text,
    encounter_reject_code text,
    reject_reason text,
    revenue_codes text,
    procedure_codes text,
    procedure_modifier1 text,
    procedure_modifier2 text,
    procedure_modifier3 text,
    procedure_modifier4 text,
    model_category text,
    payment_year text,
    model_run text,
    source_file_id bigint,
    file_name text,
    claim_id bigint,
    source text,
    is_hcc_deleted boolean DEFAULT false NOT NULL,
    key_hash text,
    is_cpt_eligible boolean,
    last_updated timestamp without time zone DEFAULT now(),
    tx_type text,
    prelim_ra_flag text
);


ALTER TABLE public.hcc_diag OWNER TO ras;

--
-- Name: hcc_diag_filtered; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.hcc_diag_filtered (
    id bigint NOT NULL,
    plan_id text,
    pcp_id text,
    pcp_last_name text,
    pcp_first_name text,
    plan_member_id text,
    beneficiary_member_identifier text,
    beneficiary_last_name text,
    beneficiary_first_name text,
    subscriber_birth_date text,
    subscriber_gender_code text,
    patient_control_number text,
    place_of_service text,
    claim_frequency_code text,
    submission_date text,
    begin_date_of_service text,
    end_date_of_service text,
    cmsicn text,
    payer_claim_control_number text,
    encounter_or_chartreview text,
    billing_provider_last_organisation_name text,
    billing_provider_npi_identifier text,
    billing_provider_taxonomy text,
    rendering_provider_last_name text,
    rendering_provider_first_name text,
    rendering_provider_identifier text,
    rendering_provider_taxonomy text,
    attending_provider_last_name text,
    attending_provider_first_name text,
    attending_provider_identifier text,
    attending_provider_taxonomy text,
    claim_code text,
    hcc_value text,
    encounter_type_switch text,
    allowed_disallowed text,
    allowed_disallowed_reason_code text,
    add_delete_ind text,
    encounter_status text,
    duplicate_plan_icn text,
    duplicate_encounter_icn text,
    encounter_reject_code text,
    reject_reason text,
    revenue_codes text,
    procedure_codes text,
    procedure_modifier1 text,
    procedure_modifier2 text,
    procedure_modifier3 text,
    procedure_modifier4 text,
    model_category text,
    payment_year text,
    model_run text,
    source_file_id bigint,
    file_name text,
    claim_id bigint,
    source text,
    is_cpt_eligible boolean DEFAULT false NOT NULL,
    is_removed_in_hierarchy boolean DEFAULT false NOT NULL,
    key_hash text,
    prelim_ra_flag text
);


ALTER TABLE public.hcc_diag_filtered OWNER TO ras;

--
-- Name: hcc_diag_filtered_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.hcc_diag_filtered_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hcc_diag_filtered_id_seq OWNER TO ras;

--
-- Name: hcc_diag_filtered_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.hcc_diag_filtered_id_seq OWNED BY public.hcc_diag_filtered.id;


--
-- Name: hcc_diag_hierarchy_applied; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.hcc_diag_hierarchy_applied (
    id bigint NOT NULL,
    plan_id text,
    pcp_id text,
    pcp_last_name text,
    pcp_first_name text,
    plan_member_id text,
    beneficiary_member_identifier text,
    beneficiary_last_name text,
    beneficiary_first_name text,
    subscriber_birth_date text,
    subscriber_gender_code text,
    patient_control_number text,
    place_of_service text,
    claim_frequency_code text,
    submission_date text,
    begin_date_of_service text,
    end_date_of_service text,
    cmsicn text,
    payer_claim_control_number text,
    encounter_or_chartreview text,
    billing_provider_last_organisation_name text,
    billing_provider_npi_identifier text,
    billing_provider_taxonomy text,
    rendering_provider_last_name text,
    rendering_provider_first_name text,
    rendering_provider_identifier text,
    rendering_provider_taxonomy text,
    attending_provider_last_name text,
    attending_provider_first_name text,
    attending_provider_identifier text,
    attending_provider_taxonomy text,
    claim_code text,
    hcc_value text,
    encounter_type_switch text,
    allowed_disallowed text,
    allowed_disallowed_reason_code text,
    add_delete_ind text,
    encounter_status text,
    duplicate_plan_icn text,
    duplicate_encounter_icn text,
    encounter_reject_code text,
    reject_reason text,
    revenue_codes text,
    procedure_codes text,
    procedure_modifier1 text,
    procedure_modifier2 text,
    procedure_modifier3 text,
    procedure_modifier4 text,
    model_category text,
    payment_year text,
    model_run text,
    source_file_id bigint,
    file_name text,
    claim_id bigint,
    source text,
    is_cpt_eligible boolean DEFAULT false NOT NULL,
    key_hash text,
    hierarchy_present_in_edps boolean DEFAULT false,
    hierarchy_present_in_raps boolean DEFAULT false,
    prelim_ra_flag text
);


ALTER TABLE public.hcc_diag_hierarchy_applied OWNER TO ras;

--
-- Name: hcc_diag_hierarchy_applied_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.hcc_diag_hierarchy_applied_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hcc_diag_hierarchy_applied_id_seq OWNER TO ras;

--
-- Name: hcc_diag_hierarchy_applied_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.hcc_diag_hierarchy_applied_id_seq OWNED BY public.hcc_diag_hierarchy_applied.id;


--
-- Name: hcc_diag_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.hcc_diag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hcc_diag_id_seq OWNER TO ras;

--
-- Name: hcc_diag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.hcc_diag_id_seq OWNED BY public.hcc_diag.id;


--
-- Name: hcc_diag_payment_year_modelcategory; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.hcc_diag_payment_year_modelcategory (
    id bigint NOT NULL,
    service_year text,
    payment_year text,
    model_category text,
    product_name text
);


ALTER TABLE public.hcc_diag_payment_year_modelcategory OWNER TO ras;

--
-- Name: health_plan; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.health_plan (
    id smallint NOT NULL,
    a_id bigint NOT NULL,
    plan_name text,
    description text,
    created_by text,
    date_created timestamp without time zone,
    last_updated timestamp without time zone,
    schema character varying(8) DEFAULT 'public'::character varying NOT NULL,
    geo text DEFAULT 'CMS'::text NOT NULL,
    CONSTRAINT health_plan_geo_check CHECK ((upper(geo) = geo)),
    CONSTRAINT health_plan_schema_check CHECK ((lower((schema)::text) = (schema)::text))
);


ALTER TABLE public.health_plan OWNER TO ras;

--
-- Name: health_plan_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.health_plan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.health_plan_id_seq OWNER TO ras;

--
-- Name: health_plan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.health_plan_id_seq OWNED BY public.health_plan.id;


--
-- Name: hibernate_sequence; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.hibernate_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hibernate_sequence OWNER TO ras;

--
-- Name: in_process_flows; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.in_process_flows (
    flow_item_id bigint NOT NULL,
    date_created timestamp with time zone DEFAULT now() NOT NULL,
    locked_at timestamp with time zone,
    locked_by text
);


ALTER TABLE public.in_process_flows OWNER TO ras;

--
-- Name: inst_1000a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_1000a (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    batch_control_number text,
    entity_identifier_code text,
    entity_type_qualifier text,
    submitter_last_or_organization_name text,
    name_first text,
    name_middle text,
    identification_code_qualifier text,
    submitter_identifier text,
    contact_function_code text,
    name text,
    communication_number_qualifier1 text,
    communication_number1 text,
    communication_number_qualifier2 text,
    communication_number2 text,
    communication_number_qualifier3 text,
    communication_number3 text
);


ALTER TABLE public.inst_1000a OWNER TO ras;

--
-- Name: inst_1000b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_1000b (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    batch_control_number text,
    entity_identifier_code text,
    entity_type_qualifier text,
    receiver_name text,
    electronic_transmitter_identification_number text,
    receiver_primary_identifier text
);


ALTER TABLE public.inst_1000b OWNER TO ras;

--
-- Name: inst_2000a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2000a (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    billing_provider_hierarchical_id_number text,
    billing_provider_hierarchical_level_code text,
    billing_provider_hierarchical_child_code text,
    billing_provider_code text,
    billing_provider_taxonomy_code_qual text,
    billing_provider_taxonomy_code text,
    currency_identifier_code_qual text,
    currency_code text
);


ALTER TABLE public.inst_2000a OWNER TO ras;

--
-- Name: inst_2000b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2000b (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    subscriber_hierarchical_id_number text,
    subscriber_hierarchical_parent_id_number text,
    subscriber_hierarchical_level_code text,
    subscriber_hierarchical_child_code text,
    payer_responsibility text,
    subscriber_individual_relationship_code text,
    subscriber_group text,
    subscriber_group_name text,
    subscriber_insurance_type_code text,
    claim_filing_indicator_code text,
    date_format text,
    patient_death_date text,
    measurement_code text,
    patient_weight text,
    pregnancy_indicator text
);


ALTER TABLE public.inst_2000b OWNER TO ras;

--
-- Name: inst_2000c; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2000c (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    patient_hierarchical_id_number text,
    patient_hierarchical_parent_id_number text,
    patient_hierarchical_level_code text,
    patient_hierarchical_child_code text,
    patient_relationship_code text,
    patient_death_date_format text,
    patient_death_date text,
    basis_for_dme_patient_measurement_code text,
    dme_patient_weight text,
    patient_pregnancy_indicator text
);


ALTER TABLE public.inst_2000c OWNER TO ras;

--
-- Name: inst_2010aa; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2010aa (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    billing_provider_entity_identifier_code_qual text,
    billing_provider_entity_type_qualifier text,
    billing_provider_last_organization_name text,
    billing_provider_first_name text,
    billing_provider_middle_name_or_initial text,
    billing_provider_name_suffix text,
    billing_provider_primary_identification_qual text,
    billing_provider_npi_identifier text,
    billing_provider_address_line1 text,
    billing_provider_address_line2 text,
    billing_provider_city_name text,
    billing_provider_state_or_province_code text,
    billing_provider_postal_zone_or_zip_code text,
    country_code text,
    country_subdivision_code text
);


ALTER TABLE public.inst_2010aa OWNER TO ras;

--
-- Name: inst_2010ab; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2010ab (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    pay_to_provider_identifier_code text,
    pay_to_provider_identifier_type_qualifier text,
    pay_to_address1 text,
    pay_to_address2 text,
    pay_to_address_city_name text,
    pay_to_address_state_code text,
    pay_to_address_postal_zone_or_zip_code text,
    pay_to_address_country_code text,
    pay_to_address_country_sub_code text
);


ALTER TABLE public.inst_2010ab OWNER TO ras;

--
-- Name: inst_2010ac; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2010ac (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    pay_to_plan_identifier_code text,
    pay_to_plan_identifier_type_qualifier text,
    pay_to_plan_organization_name text,
    pay_to_plan_primary_identification_code_qual text,
    pay_to_plan_name_hplan text,
    pay_to_plan_address1 text,
    pay_to_plan_address2 text,
    pay_to_plan_address_city_name text,
    pay_to_plan_address_state_code text,
    pay_to_plan_address_postal_zone_or_zip_code text,
    pay_to_plan_address_country_code text,
    pay_to_plan_address_country_sub_code text
);


ALTER TABLE public.inst_2010ac OWNER TO ras;

--
-- Name: inst_2010ba; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2010ba (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    subscriber_entity_identifier_code text,
    subscriber_entity_type_qual text,
    subscriber_last_name text,
    subscriber_first_name text,
    subscriber_middle_name text,
    subscriber_name_suffix text,
    subscriber_primary_identification_code_qual text,
    beneficiary_member_identifier text,
    subscriber_address1 text,
    subscriber_address2 text,
    subscriber_city_name text,
    subscriber_state_or_province_code text,
    subscriber_postal_zone_or_zip_code text,
    subscriber_country_code text,
    subscriber_country_sub_code text,
    subscriber_birth_date_qual text,
    subscriber_birth_date text,
    subscriber_gender_code text,
    subscriber_contact_function_code text,
    subscriber_contact_name text,
    subscriber_communication_number_qualifier text,
    subscriber_communication_number text,
    subscriber_communication_number_qualifier2 text,
    subscriber_communication_number2 text
);


ALTER TABLE public.inst_2010ba OWNER TO ras;

--
-- Name: inst_2010bb; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2010bb (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    beneficiary_member_identifier text,
    payer_entity_identifier_code text,
    payer_entity_type_qual text,
    payer_last_name text,
    payer_primary_identification_code_qual text,
    payer_identifier text,
    payer_address1 text,
    payer_address2 text,
    payer_city_name text,
    payer_state_or_province_code text,
    payer_postal_zone_or_zip_code text,
    payer_country_code text,
    payer_country_sub_code text
);


ALTER TABLE public.inst_2010bb OWNER TO ras;

--
-- Name: inst_2010ca; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2010ca (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    patient_entity_identifier_code text,
    patient_entity_type_qual text,
    patient_last_name text,
    patient_first_name text,
    patient_middle_name text,
    patient_name_suffix text,
    patient_address1 text,
    patient_address2 text,
    patient_city_name text,
    patient_state_or_province_code text,
    patient_postal_zone_or_zip_code text,
    patient_country_code text,
    patient_country_sub_code text,
    patient_birth_date_qual text,
    patient_birth_date text,
    patient_gender_code text,
    patient_secondary_identification_code_qual text,
    patient_property_casualty_claim_number text,
    patient_contact_function_code text,
    patient_contact_name text,
    patient_communication_number_qualifier text,
    patient_communication_number text,
    patient_communication_number_qualifier2 text,
    patient_communication_number2 text
);


ALTER TABLE public.inst_2010ca OWNER TO ras;

--
-- Name: inst_2300; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2300 (
    id bigint NOT NULL,
    record_type text,
    claim_id bigint NOT NULL,
    interchange_sender_id text,
    interchange_control_number text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    batch_control_number text,
    billing_provider_hierarchical_id_number text,
    billing_provider_npi_identifier text,
    payer_identifier text,
    subscriber_hierarchical_id_number text,
    beneficiary_member_identifier text,
    patient_hierarchical_id_number text,
    patient_control_number text,
    total_claim_charge_amount text,
    facility_type_code text,
    facility_type_code_qual text,
    claim_frequency_code text,
    assignment_or_plan_participation_code text,
    benefits_assignment_certification_indicator text,
    release_of_information_code text,
    delay_reason_code text,
    admission_type_code text,
    admission_source_code text,
    patient_status_code text,
    contract_type_code text,
    contract_amount text,
    contract_percentage text,
    contract_code text,
    terms_discount_percentage text,
    contract_version_identifier text,
    patient_responsibility_estimated_qualifier_code text,
    patient_responsibility_amount text,
    fixed_format_information text,
    epsdt_screening_referral_information_code_qualifier text,
    epsdt_referral_certification_condition_indicator text,
    epsdt_referral_condition_code1 text,
    epsdt_referral_condition_code2 text,
    epsdt_referral_condition_code3 text,
    claim_pricing_methodology text,
    repriced_allowed_amount text,
    repriced_saving_amount text,
    repricing_organization_identifier text,
    repricing_per_diem_or_flat_rate_amount text,
    repriced_approved_ambulatory_patient_group_code text,
    repriced_approved_ambulatory_patient_group_amount text,
    repriced_approved_revenue_code text,
    measurement_code text,
    repriced_approved_service_unit_count text,
    repriced_reject_reason_code text,
    repriced_policy_compliance_code text,
    repriced_exception_code text
);


ALTER TABLE public.inst_2300 OWNER TO ras;

--
-- Name: inst_2310a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2310a (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    attending_provider_entity_identifier_code text,
    attending_provider_entity_qualifier text,
    attending_provider_last_name text,
    attending_provider_first_name text,
    attending_provider_middle_name_or_initial text,
    attending_provider_name_suffix text,
    attending_provider_identification_code_qualifier text,
    attending_provider_identifier text,
    attending_provider_code text,
    attending_provider_code_qual text,
    attending_provider_taxonomy_code text
);


ALTER TABLE public.inst_2310a OWNER TO ras;

--
-- Name: inst_2310b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2310b (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    operating_physician_entity_identifier_code text,
    operating_physician_entity_qualifier text,
    operating_physician_last_name text,
    operating_physician_first_name text,
    operating_physician_middle_name_or_initial text,
    operating_physician_name_suffix text,
    operating_physician_identification_code_qualifier text,
    operating_physician_identifier text
);


ALTER TABLE public.inst_2310b OWNER TO ras;

--
-- Name: inst_2310c; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2310c (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_operating_physician_entity_identifier_code text,
    other_operating_physician_entity_qualifier text,
    other_operating_physician_last_name text,
    other_operating_physician_first_name text,
    other_operating_physician_middle_name_or_initial text,
    other_operating_physician_name_suffix text,
    other_operating_physician_identification_code_qualifier text,
    other_operating_physician_identifier text
);


ALTER TABLE public.inst_2310c OWNER TO ras;

--
-- Name: inst_2310d; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2310d (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    rendering_provider_entity_identifier_code text,
    rendering_provider_entity_qualifier text,
    rendering_provider_last_name text,
    rendering_provider_first_name text,
    rendering_provider_middle_name_or_initial text,
    rendering_provider_name_suffix text,
    rendering_provider_identification_code_qualifier text,
    rendering_provider_identifier text
);


ALTER TABLE public.inst_2310d OWNER TO ras;

--
-- Name: inst_2310e; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2310e (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    service_facility_entity_identifier_code text,
    service_facility_entity_type_qualifier text,
    service_facility_last_organization_name text,
    service_facility_identifier_qual text,
    service_facility_primary_identifier text,
    service_facility_address_line1 text,
    service_facility_address_line2 text,
    service_facility_city_name text,
    service_facility_state_or_province_code text,
    service_facility_postal_zone_or_zip_code text,
    country_code text,
    country_subdivision_code text,
    service_facility_provider_code text,
    service_facility_provider_code_qual text,
    service_facility_provider_taxonomy_code text
);


ALTER TABLE public.inst_2310e OWNER TO ras;

--
-- Name: inst_2310f; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2310f (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    referring_provider_entity_identifier_code text,
    referring_provider_entity_type_qual text,
    referring_provider_last_name text,
    referring_provider_first_name text,
    referring_provider_middle_name_or_initial text,
    referring_provider_name_suffix text,
    referring_provider_identification_code_qualifier text,
    referring_provider_identifier text
);


ALTER TABLE public.inst_2310f OWNER TO ras;

--
-- Name: inst_2320; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2320 (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    payer_responsibility text,
    subscriber_individual_relationship_code text,
    subscriber_group text,
    subscriber_group_name text,
    subscriber_insurance_type_code text,
    claim_filing_indicator_code text,
    benefits_assignment_certification_indicator text,
    patient_signature_source_code text,
    release_of_information_code text,
    inpatient_covered_days_or_visits_count text,
    inpatient_amount text,
    lifetime_psychiatric_days_count text,
    claim_drg_amount text,
    claim_payment_remark_code1 text,
    claim_disproportionate_share_amount text,
    claim_msp_passthrough_amount text,
    claim_pps_capital_amount text,
    ppscapital_fsp_drg_amount text,
    ppscapital_hsp_drg_amount text,
    ppscapital_dsh_drg_amount text,
    old_capital_amount text,
    ppscapital_ime_amount text,
    ppsoperating_hospital_specific_drg_amount text,
    cost_report_day_count text,
    ppsoperating_federal_specific_drg_amount text,
    claim_pps_capital_outlier_amount text,
    claim_indirect_teaching_amount text,
    nonpayable_professional_component_billed_amount text,
    claim_payment_remark_code2 text,
    claim_payment_remark_code3 text,
    claim_payment_remark_code4 text,
    claim_payment_remark_code5 text,
    ppscapital_exception_amount text,
    reimbursement_rate text,
    hcpcs_payable_amount text,
    esrd_payment_amount text
);


ALTER TABLE public.inst_2320 OWNER TO ras;

--
-- Name: inst_2330a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2330a (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_subscriber_entity_identifier_code text,
    other_subscriber_entity_identifier_qual text,
    other_subscriber_last_name text,
    other_subscriber_first_name text,
    other_subscriber_middle_name text,
    other_subscriber_name_suffix text,
    other_subscriber_identification_code_qualifier text,
    other_subscriber_primary_identifier text,
    other_subscriber_address1 text,
    other_subscriber_address2 text,
    other_subscriber_city_name text,
    other_subscriber_state_or_province_code text,
    other_subscriber_postal_zone_or_zip_code text,
    other_subscriber_country_code text,
    other_subscriber_country_sub_code text,
    other_subscriber_secondary_identification_qual text,
    other_subscriber_social_security_number text
);


ALTER TABLE public.inst_2330a OWNER TO ras;

--
-- Name: inst_2330b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2330b (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_entity_identifier_code text,
    other_payer_entity_identifier_qual text,
    other_payer_last_name text,
    other_payer_identification_code_qualifier text,
    other_payer_primary_identifier text,
    other_payer_address1 text,
    other_payer_address2 text,
    other_payer_city_name text,
    other_payer_state_or_province_code text,
    other_payer_postal_zone_or_zip_code text,
    other_payer_country_code text,
    other_payer_country_sub_code text,
    date_claim_paid_qual text,
    date_claim_paid_format text,
    adjudication_date text
);


ALTER TABLE public.inst_2330b OWNER TO ras;

--
-- Name: inst_2330c; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2330c (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_attending_provider_entity_identifier_code text,
    other_payer_attending_provider_entity_identifier_qual text
);


ALTER TABLE public.inst_2330c OWNER TO ras;

--
-- Name: inst_2330d; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2330d (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_operating_physician_entity_identifier_code text,
    other_payer_operating_physician_entity_identifier_qual text
);


ALTER TABLE public.inst_2330d OWNER TO ras;

--
-- Name: inst_2330e; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2330e (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_other_operating_physician_entity_identifier_code text,
    other_payer_other_operating_physician_entity_identifier_qual text
);


ALTER TABLE public.inst_2330e OWNER TO ras;

--
-- Name: inst_2330f; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2330f (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_service_location_entity_identifier_code text,
    other_payer_service_location_entity_identifier_qual text
);


ALTER TABLE public.inst_2330f OWNER TO ras;

--
-- Name: inst_2330g; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2330g (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_render_provider_entity_identifier_code text,
    other_payer_render_provider_entity_identifier_qual text
);


ALTER TABLE public.inst_2330g OWNER TO ras;

--
-- Name: inst_2330h; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2330h (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_refer_provider_entity_identifier_code text,
    other_payer_refer_provider_entity_identifier_qual text
);


ALTER TABLE public.inst_2330h OWNER TO ras;

--
-- Name: inst_2330i; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2330i (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_billing_provider_entity_identifier_code text,
    other_payer_billing_provider_entity_identifier_qual text
);


ALTER TABLE public.inst_2330i OWNER TO ras;

--
-- Name: inst_2400; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2400 (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    segment_number integer,
    claim_line_number integer,
    service_line_revenue_code text,
    procedure_code_qualifier text,
    procedure_code text,
    procedure_modifier1 text,
    procedure_modifier2 text,
    procedure_modifier3 text,
    procedure_modifier4 text,
    procedure_code_description text,
    line_item_charge_amount numeric(10,2),
    unit_or_basis_for_measurement text,
    service_unit_count text,
    line_item_denied_charge_or_noncovered_charge_amount text,
    note_reference_code text,
    third_party_organization_notes text,
    pricing_methodology text,
    repriced_allowed_amount text,
    repriced_saving_amount text,
    repricing_organization_identifier text,
    repricing_per_diem_or_flat_rate_amount text,
    repriced_approved_ambulatory_patient_group_code text,
    repriced_approved_ambulatory_patient_group_amount text,
    repricing_service_id text,
    repricing_service_id_qualifier text,
    repriced_approved_hcpcs_code text,
    basis_for_measurement_code text,
    repriced_approved_service_unit_count text,
    reject_reason_code text,
    policy_compliance_code text,
    exception_code text,
    line_hash text,
    dup_line boolean DEFAULT false,
    remit_line_match_status text
);


ALTER TABLE public.inst_2400 OWNER TO ras;

--
-- Name: inst_2410; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2410 (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    national_drug_code_qual text,
    national_drug_code text,
    national_drug_unit_count text,
    code_qualifier text
);


ALTER TABLE public.inst_2410 OWNER TO ras;

--
-- Name: inst_2420a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2420a (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    operating_physician_entity_identifier_code text,
    operating_physician_entity_qualifier text,
    operating_physician_last_name text,
    operating_physician_first_name text,
    operating_physician_middle_name_or_initial text,
    operating_physician_name_suffix text,
    operating_physician_identification_code_qualifier text,
    operating_physician_identifier text
);


ALTER TABLE public.inst_2420a OWNER TO ras;

--
-- Name: inst_2420b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2420b (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    other_operating_physician_entity_identifier_code text,
    other_operating_physician_entity_qualifier text,
    other_operating_physician_last_name text,
    other_operating_physician_first_name text,
    other_operating_physician_middle_name_or_initial text,
    other_operating_physician_name_suffix text,
    other_operating_physician_identification_code_qualifier text,
    other_operating_physician_identifier text
);


ALTER TABLE public.inst_2420b OWNER TO ras;

--
-- Name: inst_2420c; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2420c (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    rendering_provider_entity_identifier_code text,
    rendering_provider_entity_qualifier text,
    rendering_provider_last_name text,
    rendering_provider_first_name text,
    rendering_provider_middle_name_or_initial text,
    rendering_provider_name_suffix text,
    rendering_provider_identification_code_qualifier text,
    rendering_provider_identifier text
);


ALTER TABLE public.inst_2420c OWNER TO ras;

--
-- Name: inst_2420d; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2420d (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    referring_provider_entity_identifier_code text,
    referring_provider_entity_qualifier text,
    referring_provider_last_name text,
    referring_provider_first_name text,
    referring_provider_middle_name_or_initial text,
    referring_provider_name_suffix text,
    referring_provider_identification_code_qualifier text,
    referring_provider_identifier text
);


ALTER TABLE public.inst_2420d OWNER TO ras;

--
-- Name: inst_2430; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2430 (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    other_payer_primary_identifier text,
    service_line_paid_amount text,
    product_or_service_id_qualifier text,
    procedure_code text,
    procedure_modifier1 text,
    procedure_modifier2 text,
    procedure_modifier3 text,
    procedure_modifier4 text,
    procedure_code_description text,
    product_service_id text,
    paid_service_unit_count text,
    bundled_or_unbundled_line_number text,
    date_claim_paid text,
    date_time_period_format_qualifier text,
    adjudication_or_payment_date text,
    amount_qualifier_code text,
    remaining_patient_liability text
);


ALTER TABLE public.inst_2430 OWNER TO ras;

--
-- Name: inst_2440; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_2440 (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    form_identifier_qual text,
    form_identifier text,
    question_number_or_letter text,
    question_response text,
    question_response_desc text,
    question_response_date text,
    question_response_percentage text
);


ALTER TABLE public.inst_2440 OWNER TO ras;

--
-- Name: inst_bht; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_bht (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    hierarchical_structure_code text,
    transaction_set_purpose_code text,
    batch_control_number text,
    date text,
    "time" text,
    claim_identifier text
);


ALTER TABLE public.inst_bht OWNER TO ras;

--
-- Name: inst_claim_data; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_claim_data (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    data jsonb NOT NULL
);


ALTER TABLE public.inst_claim_data OWNER TO ras;

--
-- Name: inst_claim_identifier; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_claim_identifier (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    plan_id text,
    patient_control_number text,
    linked_patient_control_number text,
    beneficiary_first_name text,
    beneficiary_last_name text,
    type_of_bill text,
    begin_date_of_service text,
    end_date_of_service text,
    submission_date text,
    claim_frequency_code text,
    encounter_or_chart_review text,
    beneficiary_member_identifier text,
    total_claim_charge_amount text,
    payer_amount_paid numeric(10,2),
    cmsicn text,
    payer_claim_control_number text,
    source text,
    encounter_status text,
    encounter_status_type text,
    encounter_status_code text,
    encounter_reject_category text,
    file_id bigint NOT NULL,
    linked_provider_clm_id bigint,
    h_plan_submitter_id bigint,
    last_updated timestamp without time zone,
    date_created timestamp without time zone,
    modified_by text,
    segment_number integer,
    interchange_sender_id text,
    interchange_receiver_id text,
    billing_provider_npi text,
    attending_provider_npi text,
    interchange_control_number text,
    group_control_number text NOT NULL,
    batch_control_number text,
    transaction_set_control_number text NOT NULL,
    st_index integer,
    billing_provider_hierarchical_id_number text,
    raps_extract_status text,
    encounter_revision numeric,
    key_hash text GENERATED ALWAYS AS (public.ras_md5(public.ras_concat(interchange_sender_id, VARIADIC ARRAY[interchange_receiver_id, plan_id, beneficiary_member_identifier, beneficiary_last_name, type_of_bill, COALESCE(attending_provider_npi, billing_provider_npi), total_claim_charge_amount, encounter_or_chart_review, begin_date_of_service, end_date_of_service, (payer_amount_paid)::text]))) STORED
);


ALTER TABLE public.inst_claim_identifier OWNER TO ras;

--
-- Name: inst_claim_line_data; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_claim_line_data (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer NOT NULL,
    data jsonb NOT NULL
);


ALTER TABLE public.inst_claim_line_data OWNER TO ras;

--
-- Name: inst_header_trailer; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_header_trailer (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    authorization_information_qualifier text,
    authorization_information text,
    security_information_qualifier text,
    security_information text,
    interchange_sender_id_qualifier text,
    interchange_sender_id text,
    interchange_receiver_id_qualifier text,
    interchange_receiver_id text,
    interchange_date text,
    interchange_time text,
    repetition_separator text,
    interchange_control_version_number text,
    interchange_control_number text,
    acknowledgment_requested text,
    interchange_usage_indicator text,
    component_element_separator text,
    functional_identifier_code text,
    application_senders_code text,
    application_receivers_code text,
    group_header_date text,
    group_header_time text,
    group_control_number text,
    responsible_agency_code text,
    industry_identifier_code text,
    number_of_transaction_sets_included text,
    trailer_group_control_number text,
    number_of_included_functional_groups text
);


ALTER TABLE public.inst_header_trailer OWNER TO ras;

--
-- Name: inst_se; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_se (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_segment_count text,
    transaction_set_control_number text
);


ALTER TABLE public.inst_se OWNER TO ras;

--
-- Name: inst_st; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inst_st (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    st_index integer,
    transaction_set_identifier_code text,
    transaction_set_control_number text,
    implementation_convention_reference text
);


ALTER TABLE public.inst_st OWNER TO ras;

--
-- Name: inter_process_queue; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.inter_process_queue (
    id text NOT NULL,
    date_created timestamp without time zone DEFAULT now(),
    locked_at timestamp without time zone,
    locked_by text,
    source text NOT NULL,
    channel text NOT NULL,
    type text,
    message jsonb NOT NULL
);


ALTER TABLE public.inter_process_queue OWNER TO ras;

--
-- Name: linked_cr_batch; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.linked_cr_batch (
    id bigint NOT NULL,
    batch_file_id bigint NOT NULL,
    submitter_id text NOT NULL,
    plan_id text,
    mbi text NOT NULL,
    patient_control_number text NOT NULL,
    begin_date_of_service text NOT NULL,
    end_date_of_service text NOT NULL,
    lob text NOT NULL,
    add_delete_indicator text NOT NULL,
    primary_diag_code text NOT NULL,
    secondary_diag_code1 text,
    secondary_diag_code2 text,
    secondary_diag_code3 text,
    secondary_diag_code4 text,
    secondary_diag_code5 text,
    secondary_diag_code6 text,
    secondary_diag_code7 text,
    secondary_diag_code8 text,
    secondary_diag_code9 text,
    secondary_diag_code10 text,
    secondary_diag_code11 text,
    default_procedure_code text,
    status text DEFAULT 'NEW'::text,
    status_code text
);


ALTER TABLE public.linked_cr_batch OWNER TO ras;

--
-- Name: linked_cr_batch_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.linked_cr_batch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.linked_cr_batch_id_seq OWNER TO ras;

--
-- Name: linked_cr_batch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.linked_cr_batch_id_seq OWNED BY public.linked_cr_batch.id;


--
-- Name: member_raf; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.member_raf (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    plan_id text,
    beneficiary_id text,
    ma_type text DEFAULT 'PART-C'::text,
    year smallint,
    month smallint,
    age smallint,
    sex text,
    raft text,
    orec text,
    medicaid_flag boolean DEFAULT false,
    extract_type text,
    raw_risk_score numeric(5,3),
    total_demography_score numeric(5,3),
    total_hcc_score numeric(5,3),
    calc_blended_risk_score numeric(5,3),
    bid_amount numeric,
    ma_payment numeric,
    hcc_map jsonb,
    hcc_engine_output jsonb,
    plan_member_id text
);


ALTER TABLE public.member_raf OWNER TO ras;

--
-- Name: member_raf_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.member_raf_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.member_raf_id_seq OWNER TO ras;

--
-- Name: member_raf_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.member_raf_id_seq OWNED BY public.member_raf.id;


--
-- Name: mmr_data; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.mmr_data (
    id bigint NOT NULL,
    contract_number text,
    run_date text,
    payment_date text,
    beneficiary_id text,
    surname text,
    first_initial text,
    gender_code text,
    date_of_birth text,
    filler1 text,
    state_and_county_code text,
    out_of_area_ind text,
    part_a_entitlement text,
    part_b_entitlement text,
    hospice text,
    esrd text,
    aged_disabled_msp text,
    filler2 text,
    filler3 text,
    new_beneficiary_status text,
    lti_flag text,
    medicaid_ind text,
    filler4 text,
    def_risk_factor_code text,
    risk_adjustment_factor_a text,
    rick_adjustment_factor_b text,
    payment_adjustment_months_part_a text,
    payment_adjustment_months_part_b text,
    adjustment text,
    payment_adjustment_start_date text,
    payment_adjustment_end_date text,
    filler5 text,
    filler6 text,
    monthly_payment_adjustment_amount_rate_a text,
    monthly_payment_adjustment_amount_rate_b text,
    lis_premium_subsidy text,
    esrd_msp_flag text,
    medication_therapy_management_addon text,
    filler7 text,
    medicaid_status text,
    risk_adjustment_age_group text,
    filler8 text,
    filler9 text,
    filler10 text,
    plan_benefit_package_id text,
    filler11 text,
    risk_adjustment_factor_type_code text,
    frailty_ind text,
    original_reason_for_entitlement_code text,
    filler12 text,
    segment_number1 text,
    filler13 text,
    eghp_flag text,
    part_c_basic_premium_part_a_amt text,
    part_c_basic_premium_part_b_amt text,
    rebate_for_part_a_cost_sharing_reduction text,
    rebate_for_part_b_cost_sharing_reduction text,
    rebate_for_other_part_a_mandatory_supplemental_benefits text,
    rebate_for_other_part_b_mandatory_supplemental_benefits text,
    rebate_for_part_b_premium_reduction_part_a_amt text,
    rebate_for_part_b_premium_reduction_part_b_amt text,
    rebate_for_part_d_supplemental_benefits_part_a_amt text,
    rebate_for_part_d_supplemental_benefits_part_b_amt text,
    total_part_a_ma_payment text,
    total_part_b_ma_payment text,
    total_ma_payment_amt text,
    part_d_ra_factor text,
    part_d_low_income_ind text,
    part_d_low_income_multiplier text,
    part_d_long_term_inst_ind text,
    part_d_long_term_inst_multiplier text,
    rebate_for_part_d_basic_premium_reduction text,
    part_d_basic_premium_amt text,
    part_d_direct_subsidy_monthly_payment_amt text,
    reinsurance_subsidy_amt text,
    low_income_subsidy_cost_sharing_amt text,
    total_part_d_payment text,
    number_of_payment_adjustment_months_part_d text,
    pace_premium_addon text,
    pace_cost_sharing_addon text,
    part_c_frailty_score_factor text,
    msp_factor text,
    msp_reduction_adjustment_amt_part_a text,
    msp_reduction_adjustment_amt_part_b text,
    medicaid_dual_status_code text,
    part_d_coverage_gap_discount_amt text,
    part_d_risk_adjustment_factor_type text,
    def_part_d_risk_adjustment_factor_code text,
    part_a_risk_adjusted_monthly_amt_for_payment_adjustment text,
    part_b_risk_adjusted_monthly_amt_for_payment_adjustment text,
    part_d_direct_subsidy_monthly_amt_for_payment_adjustment text,
    cleanup_id text,
    plan_member_id text,
    member_active boolean
);


ALTER TABLE public.mmr_data OWNER TO ras;

--
-- Name: mmr_data_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.mmr_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mmr_data_id_seq OWNER TO ras;

--
-- Name: mmr_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.mmr_data_id_seq OWNED BY public.mmr_data.id;


--
-- Name: model_run_config; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.model_run_config (
    id bigint NOT NULL,
    payment_year text,
    model_run text,
    from_date_of_service text,
    to_date_of_service text,
    submission_cut_off_date text
);


ALTER TABLE public.model_run_config OWNER TO ras;

--
-- Name: prof_1000a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_1000a (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    batch_control_number text,
    entity_identifier_code text,
    entity_type_qualifier text,
    submitter_last_or_organization_name text,
    name_first text,
    name_middle text,
    identification_code_qualifier text,
    submitter_identifier text,
    contact_function_code text,
    name text,
    communication_number_qualifier1 text,
    communication_number1 text,
    communication_number_qualifier2 text,
    communication_number2 text,
    communication_number_qualifier3 text,
    communication_number3 text
);


ALTER TABLE public.prof_1000a OWNER TO ras;

--
-- Name: prof_1000b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_1000b (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    batch_control_number text,
    entity_identifier_code text,
    entity_type_qualifier text,
    receiver_name text,
    electronic_transmitter_identification_number text,
    receiver_primary_identifier text
);


ALTER TABLE public.prof_1000b OWNER TO ras;

--
-- Name: prof_2000a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2000a (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    billing_provider_hierarchical_id_number text,
    billing_provider_hierarchical_level_code text,
    billing_provider_hierarchical_child_code text,
    billing_provider_code text,
    billing_provider_taxonomy_code_qual text,
    billing_provider_taxonomy_code text,
    currency_identifier_code_qual text,
    currency_code text
);


ALTER TABLE public.prof_2000a OWNER TO ras;

--
-- Name: prof_2000b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2000b (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    subscriber_hierarchical_id_number text,
    subscriber_hierarchical_parent_id_number text,
    subscriber_hierarchical_level_code text,
    subscriber_hierarchical_child_code text,
    payer_responsibility text,
    subscriber_individual_relationship_code text,
    subscriber_group text,
    subscriber_group_name text,
    subscriber_insurance_type_code text,
    claim_filing_indicator_code text,
    date_format text,
    patient_death_date text,
    measurement_code text,
    patient_weight text,
    pregnancy_indicator text
);


ALTER TABLE public.prof_2000b OWNER TO ras;

--
-- Name: prof_2000c; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2000c (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    patient_hierarchical_id_number text,
    patient_hierarchical_parent_id_number text,
    patient_hierarchical_level_code text,
    patient_hierarchical_child_code text,
    patient_relationship_code text,
    patient_death_date_format text,
    patient_death_date text,
    basis_for_dme_patient_measurement_code text,
    dme_patient_weight text,
    patient_pregnancy_indicator text
);


ALTER TABLE public.prof_2000c OWNER TO ras;

--
-- Name: prof_2010aa; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2010aa (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    billing_provider_entity_identifier_code_qual text,
    billing_provider_entity_type_qualifier text,
    billing_provider_last_organization_name text,
    billing_provider_first_name text,
    billing_provider_middle_name_or_initial text,
    billing_provider_name_suffix text,
    billing_provider_primary_identification_qual text,
    billing_provider_npi_identifier text,
    billing_provider_address_line1 text,
    billing_provider_address_line2 text,
    billing_provider_city_name text,
    billing_provider_state_or_province_code text,
    billing_provider_postal_zone_or_zip_code text,
    country_code text,
    country_subdivision_code text
);


ALTER TABLE public.prof_2010aa OWNER TO ras;

--
-- Name: prof_2010ab; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2010ab (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    pay_to_provider_identifier_code text,
    pay_to_provider_identifier_type_qualifier text,
    pay_to_address1 text,
    pay_to_address2 text,
    pay_to_address_city_name text,
    pay_to_address_state_code text,
    pay_to_address_postal_zone_or_zip_code text,
    pay_to_address_country_code text,
    pay_to_address_country_sub_code text
);


ALTER TABLE public.prof_2010ab OWNER TO ras;

--
-- Name: prof_2010ac; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2010ac (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    pay_to_plan_identifier_code text,
    pay_to_plan_identifier_type_qualifier text,
    pay_to_plan_organization_name text,
    pay_to_plan_primary_identification_code_qual text,
    pay_to_plan_name_h_plan text,
    pay_to_plan_address1 text,
    pay_to_plan_address2 text,
    pay_to_plan_address_city_name text,
    pay_to_plan_address_state_code text,
    pay_to_plan_address_postal_zone_or_zip_code text,
    pay_to_plan_address_country_code text,
    pay_to_plan_address_country_sub_code text
);


ALTER TABLE public.prof_2010ac OWNER TO ras;

--
-- Name: prof_2010ba; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2010ba (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    subscriber_entity_identifier_code text,
    subscriber_entity_type_qual text,
    subscriber_last_name text,
    subscriber_first_name text,
    subscriber_middle_name text,
    subscriber_name_suffix text,
    subscriber_primary_identification_code_qual text,
    beneficiary_member_identifier text,
    subscriber_address1 text,
    subscriber_address2 text,
    subscriber_city_name text,
    subscriber_state_or_province_code text,
    subscriber_postal_zone_or_zip_code text,
    subscriber_country_code text,
    subscriber_country_sub_code text,
    subscriber_birth_date_qual text,
    subscriber_birth_date text,
    subscriber_gender_code text,
    subscriber_contact_function_code text,
    subscriber_contact_name text,
    subscriber_communication_number_qualifier text,
    subscriber_communication_number text,
    subscriber_communication_number_qualifier2 text,
    subscriber_communication_number2 text
);


ALTER TABLE public.prof_2010ba OWNER TO ras;

--
-- Name: prof_2010bb; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2010bb (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    beneficiary_member_identifier text,
    payer_entity_identifier_code text,
    payer_entity_type_qual text,
    payer_last_name text,
    payer_primary_identification_code_qual text,
    payer_identifier text,
    payer_address1 text,
    payer_address2 text,
    payer_city_name text,
    payer_state_or_province_code text,
    payer_postal_zone_or_zip_code text,
    payer_country_code text,
    payer_country_sub_code text
);


ALTER TABLE public.prof_2010bb OWNER TO ras;

--
-- Name: prof_2010ca; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2010ca (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    patient_entity_identifier_code text,
    patient_entity_type_qual text,
    patient_last_name text,
    patient_first_name text,
    patient_middle_name text,
    patient_name_suffix text,
    patient_address1 text,
    patient_address2 text,
    patient_city_name text,
    patient_state_or_province_code text,
    patient_postal_zone_or_zip_code text,
    patient_country_code text,
    patient_country_sub_code text,
    patient_birth_date_qual text,
    patient_birth_date text,
    patient_gender_code text,
    patient_secondary_identification_code_qual text,
    patient_property_casualty_claim_number text,
    patient_contact_function_code text,
    patient_contact_name text,
    patient_communication_number_qualifier text,
    patient_communication_number text,
    patient_communication_number_qualifier2 text,
    patient_communication_number2 text
);


ALTER TABLE public.prof_2010ca OWNER TO ras;

--
-- Name: prof_2300; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2300 (
    id bigint NOT NULL,
    record_type text,
    claim_id bigint NOT NULL,
    interchange_sender_id text,
    interchange_control_number text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    batch_control_number text,
    billing_provider_hierarchical_id_number text,
    billing_provider_npi_identifier text,
    payer_identifier text,
    subscriber_hierarchical_id_number text,
    beneficiary_member_identifier text,
    patient_hierarchical_id_number text,
    patient_control_number text,
    total_claim_charge_amount text,
    place_of_service_code text,
    place_of_service_code_qual text,
    claim_frequency_code text,
    provider_or_supplier_signature_indicator text,
    assignment_or_plan_participation_code text,
    benefits_assignment_certification_indicator text,
    release_of_information_code text,
    patient_signature_source_code text,
    related_causes_code1 text,
    related_causes_code2 text,
    auto_accident_state_or_province_code text,
    country_code text,
    special_program_indicator text,
    delay_reason_code text,
    contract_type_code text,
    contract_amount text,
    contract_percentage text,
    contract_code text,
    terms_discount_percentage text,
    contract_version_identifier text,
    patient_amount_qualifier_code text,
    patient_amount_paid text,
    fixed_format_information text,
    note_reference_code text,
    claim_note_text text,
    ambulance_patient_measurement_code text,
    ambulance_patient_weight text,
    ambulance_transportation_reason_code text,
    ambulance_transportation_measurement_code text,
    transport_distance text,
    round_trip_purpose_description text,
    stretcher_purpose_description text,
    nature_of_condition_code text,
    patient_condition_description1 text,
    patient_condition_description2 text,
    claim_pricing_methodology text,
    repriced_allowed_amount text,
    repriced_saving_amount text,
    repricing_organization_identifier text,
    repricing_per_diem_or_flat_rate_amount text,
    repriced_approved_ambulatory_patient_group_code text,
    repriced_approved_ambulatory_patient_group_amount text,
    repriced_reject_reason_code text,
    repriced_policy_compliance_code text,
    repriced_exception_code text
);


ALTER TABLE public.prof_2300 OWNER TO ras;

--
-- Name: prof_2310a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2310a (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    referring_provider_entity_identifier_code text,
    referring_provider_entity_type_qual text,
    referring_provider_last_name text,
    referring_provider_first_name text,
    referring_provider_middle_name_or_initial text,
    referring_provider_name_suffix text,
    referring_provider_identification_code_qualifier text,
    referring_provider_identifier text
);


ALTER TABLE public.prof_2310a OWNER TO ras;

--
-- Name: prof_2310b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2310b (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    rendering_provider_entity_identifier_code text,
    rendering_provider_entity_qualifier text,
    rendering_provider_last_name text,
    rendering_provider_first_name text,
    rendering_provider_middle_name_or_initial text,
    rendering_provider_name_suffix text,
    rendering_provider_identification_code_qualifier text,
    rendering_provider_identifier text,
    rendering_provider_code text,
    rendering_provider_code_qual text,
    rendering_provider_taxonomy_code text
);


ALTER TABLE public.prof_2310b OWNER TO ras;

--
-- Name: prof_2310c; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2310c (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    service_facility_entity_identifier_code text,
    service_facility_entity_type_qualifier text,
    service_facility_last_organization_name text,
    service_facility_identifier_qual text,
    service_facility_primary_identifier text,
    service_facility_address_line1 text,
    service_facility_address_line2 text,
    service_facility_city_name text,
    service_facility_state_or_province_code text,
    service_facility_postal_zone_or_zip_code text,
    country_code text,
    country_subdivision_code text,
    service_facility_contact_function_code text,
    service_facility_contact_name text,
    service_facility_communication_number_qualifier text,
    service_facility_communication_number text,
    service_facility_communication_number_qualifier2 text,
    service_facility_communication_number2 text
);


ALTER TABLE public.prof_2310c OWNER TO ras;

--
-- Name: prof_2310d; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2310d (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    supervising_provider_entity_identifier_code text,
    supervising_provider_entity_qualifier text,
    supervising_provider_last_name text,
    supervising_provider_first_name text,
    supervising_provider_middle_name_or_initial text,
    supervising_provider_name_suffix text,
    supervising_provider_identification_code_qualifier text,
    supervising_provider_identifier text,
    supervising_provider_code text,
    supervising_provider_code_qual text,
    supervising_provider_taxonomy_code text
);


ALTER TABLE public.prof_2310d OWNER TO ras;

--
-- Name: prof_2310e; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2310e (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    ambulance_pickup_entity_identifier_code text,
    ambulance_pickup_entity_type_qualifier text,
    ambulance_pickup_address_line1 text,
    ambulance_pickup_address_line2 text,
    ambulance_pickup_city_name text,
    ambulance_pickup_state_or_province_code text,
    ambulance_pickup_postal_zone_or_zip_code text,
    country_code text,
    country_subdivision_code text
);


ALTER TABLE public.prof_2310e OWNER TO ras;

--
-- Name: prof_2310f; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2310f (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    ambulance_drop_off_entity_identifier_code text,
    ambulance_drop_off_entity_type_qualifier text,
    ambulance_drop_off_location text,
    ambulance_drop_off_address_line1 text,
    ambulance_drop_off_address_line2 text,
    ambulance_drop_off_city_name text,
    ambulance_drop_off_state_or_province_code text,
    ambulance_drop_off_postal_zone_or_zip_code text,
    country_code text,
    country_subdivision_code text
);


ALTER TABLE public.prof_2310f OWNER TO ras;

--
-- Name: prof_2320; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2320 (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    payer_responsibility text,
    subscriber_individual_relationship_code text,
    subscriber_group text,
    subscriber_group_name text,
    subscriber_insurance_type_code text,
    claim_filing_indicator_code text,
    benefits_assignment_certification_indicator text,
    patient_signature_source_code text,
    release_of_information_code text,
    reimbursement_rate text,
    hcpcs_payable_amount text,
    claim_payment_remark_code1 text,
    claim_payment_remark_code2 text,
    claim_payment_remark_code3 text,
    claim_payment_remark_code4 text,
    claim_payment_remark_code5 text,
    esrd_payment_amount text,
    non_payable_professional_component_billed_amount text
);


ALTER TABLE public.prof_2320 OWNER TO ras;

--
-- Name: prof_2330a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2330a (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_subscriber_entity_identifier_code text,
    other_subscriber_entity_identifier_qual text,
    other_subscriber_last_name text,
    other_subscriber_first_name text,
    other_subscriber_middle_name text,
    other_subscriber_name_suffix text,
    other_subscriber_identification_code_qualifier text,
    other_subscriber_primary_identifier text,
    other_subscriber_address1 text,
    other_subscriber_address2 text,
    other_subscriber_city_name text,
    other_subscriber_state_or_province_code text,
    other_subscriber_postal_zone_or_zip_code text,
    other_subscriber_country_code text,
    other_subscriber_country_sub_code text,
    other_subscriber_secondary_identification_qual text,
    other_subscriber_social_security_number text
);


ALTER TABLE public.prof_2330a OWNER TO ras;

--
-- Name: prof_2330b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2330b (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_entity_identifier_code text,
    other_payer_entity_identifier_qual text,
    other_payer_last_name text,
    other_payer_identification_code_qualifier text,
    other_payer_primary_identifier text,
    other_payer_address1 text,
    other_payer_address2 text,
    other_payer_city_name text,
    other_payer_state_or_province_code text,
    other_payer_postal_zone_or_zip_code text,
    other_payer_country_code text,
    other_payer_country_sub_code text,
    date_claim_paid_qual text,
    date_claim_paid_format text,
    adjudication_date text
);


ALTER TABLE public.prof_2330b OWNER TO ras;

--
-- Name: prof_2330c; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2330c (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_refer_provider_entity_identifier_code text,
    other_payer_refer_provider_entity_identifier_qual text
);


ALTER TABLE public.prof_2330c OWNER TO ras;

--
-- Name: prof_2330d; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2330d (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_render_provider_entity_identifier_code text,
    other_payer_render_provider_entity_identifier_qual text
);


ALTER TABLE public.prof_2330d OWNER TO ras;

--
-- Name: prof_2330e; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2330e (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_svc_location_entity_identifier_code text,
    other_payer_svc_location_entity_identifier_qual text
);


ALTER TABLE public.prof_2330e OWNER TO ras;

--
-- Name: prof_2330f; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2330f (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_spvc_provider_entity_identifier_code text,
    other_payer_spvc_provider_entity_identifier_qual text
);


ALTER TABLE public.prof_2330f OWNER TO ras;

--
-- Name: prof_2330g; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2330g (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    other_payer_billing_provider_entity_identifier_code text,
    other_payer_billing_provider_entity_identifier_qual text
);


ALTER TABLE public.prof_2330g OWNER TO ras;

--
-- Name: prof_2400; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2400 (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    segment_number integer,
    claim_line_number integer,
    procedure_code_qualifier text,
    procedure_code text,
    procedure_modifier1 text,
    procedure_modifier2 text,
    procedure_modifier3 text,
    procedure_modifier4 text,
    procedure_code_description text,
    line_item_charge_amount numeric(10,2),
    unit_or_basis_for_measurement text,
    service_unit_count text,
    place_of_service_code text,
    diagnosis_code_pointer1 text,
    diagnosis_code_pointer2 text,
    diagnosis_code_pointer3 text,
    diagnosis_code_pointer4 text,
    emergency_indicator text,
    epsdt_indicator text,
    family_planning_indicator text,
    copay_status_code text,
    dme_procedure_identifier text,
    dme_procedure_code text,
    dme_unit_or_basis_for_measurement text,
    length_of_medical_necessity text,
    dme_rental_price text,
    dme_purchase_price text,
    rental_unit_price_indicator text,
    ambulance_patient_measurement text,
    ambulance_patient_weight text,
    ambulance_transport_reason_code text,
    ambulance_transportation_measurement text,
    ambulance_transport_distance text,
    ambulance_round_trip_purpose_description text,
    ambulance_stretcher_purpose_description text,
    dme_certification_type_code text,
    dme_duration_measurement_unit text,
    durable_medical_equipment_duration text,
    contract_type_code text,
    contract_amount text,
    contract_percentage text,
    contract_code text,
    terms_discount_percentage text,
    contract_version_identifier text,
    purchased_service_provider_identifier text,
    purchased_service_charge_amount text,
    pricing_methodology text,
    repriced_allowed_amount text,
    repriced_saving_amount text,
    repricing_organization_identifier text,
    repricing_per_diem_or_flat_rate_amount text,
    repriced_approved_ambulatory_patient_group_code text,
    repriced_approved_ambulatory_patient_group_amount text,
    product_or_service_id_qualifier text,
    repriced_approved_hcpcs_code text,
    basis_for_measurement_code text,
    repriced_approved_service_unit_count text,
    reject_reason_code text,
    policy_compliance_code text,
    exception_code text,
    line_hash text,
    dup_line boolean DEFAULT false,
    remit_line_match_status text
);


ALTER TABLE public.prof_2400 OWNER TO ras;

--
-- Name: prof_2410; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2410 (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    national_drug_code_qual text,
    national_drug_code text,
    national_drug_unit_count text,
    code_qualifier text
);


ALTER TABLE public.prof_2410 OWNER TO ras;

--
-- Name: prof_2420a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2420a (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    rendering_provider_entity_identifier_code text,
    rendering_provider_entity_qualifier text,
    rendering_provider_last_name text,
    rendering_provider_first_name text,
    rendering_provider_middle_name_or_initial text,
    rendering_provider_name_suffix text,
    rendering_provider_identification_code_qualifier text,
    rendering_provider_identifier text,
    rendering_provider_code text,
    rendering_provider_code_qual text,
    rendering_provider_taxonomy_code text
);


ALTER TABLE public.prof_2420a OWNER TO ras;

--
-- Name: prof_2420b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2420b (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    purchased_svc_provider_entity_identifier_code text,
    purchased_svc_provider_entity_qualifier text,
    purchased_svc_provider_identification_code_qualifier text,
    purchased_svc_provider_identifier text
);


ALTER TABLE public.prof_2420b OWNER TO ras;

--
-- Name: prof_2420c; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2420c (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    service_facility_entity_identifier_code text,
    service_facility_entity_type_qualifier text,
    service_facility_last_organization_name text,
    service_facility_identifier_qual text,
    service_facility_primary_identifier text,
    service_facility_address_line1 text,
    service_facility_address_line2 text,
    service_facility_city_name text,
    service_facility_state_or_province_code text,
    service_facility_postal_zone_or_zip_code text,
    country_code text,
    country_subdivision_code text
);


ALTER TABLE public.prof_2420c OWNER TO ras;

--
-- Name: prof_2420d; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2420d (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    supervising_provider_entity_identifier_code text,
    supervising_provider_entity_qualifier text,
    supervising_provider_last_name text,
    supervising_provider_first_name text,
    supervising_provider_middle_name_or_initial text,
    supervising_provider_name_suffix text,
    supervising_provider_identification_code_qualifier text,
    supervising_provider_identifier text
);


ALTER TABLE public.prof_2420d OWNER TO ras;

--
-- Name: prof_2420e; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2420e (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    ordering_provider_entity_identifier_code text,
    ordering_provider_entity_qualifier text,
    ordering_provider_last_name text,
    ordering_provider_first_name text,
    ordering_provider_middle_name_or_initial text,
    ordering_provider_name_suffix text,
    ordering_provider_identification_code_qualifier text,
    ordering_provider_identifier text,
    ordering_address_line1 text,
    ordering_address_line2 text,
    ordering_city_name text,
    ordering_state_or_province_code text,
    ordering_postal_zone_or_zip_code text,
    country_code text,
    country_subdivision_code text,
    ordering_provider_contact_function_code text,
    ordering_provider_contact_name text,
    ordering_provider_communication_number_qualifier1 text,
    ordering_provider_communication_number1 text,
    ordering_provider_communication_number_qualifier2 text,
    ordering_provider_communication_number2 text,
    ordering_provider_communication_number_qualifier3 text,
    ordering_provider_communication_number3 text
);


ALTER TABLE public.prof_2420e OWNER TO ras;

--
-- Name: prof_2420f; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2420f (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    referring_provider_entity_identifier_code text,
    referring_provider_entity_qualifier text,
    referring_provider_last_name text,
    referring_provider_first_name text,
    referring_provider_middle_name_or_initial text,
    referring_provider_name_suffix text,
    referring_provider_identification_code_qualifier text,
    referring_provider_identifier text
);


ALTER TABLE public.prof_2420f OWNER TO ras;

--
-- Name: prof_2420g; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2420g (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    ambulance_pickup_entity_identifier_code text,
    ambulance_pickup_entity_type_qualifier text,
    ambulance_pickup_address_line1 text,
    ambulance_pickup_address_line2 text,
    ambulance_pickup_city_name text,
    ambulance_pickup_state_or_province_code text,
    ambulance_pickup_postal_zone_or_zip_code text,
    country_code text,
    country_subdivision_code text
);


ALTER TABLE public.prof_2420g OWNER TO ras;

--
-- Name: prof_2420h; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2420h (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    ambulance_drop_off_entity_identifier_code text,
    ambulance_drop_off_entity_type_qualifier text,
    ambulance_drop_off_location text,
    ambulance_drop_off_address_line1 text,
    ambulance_drop_off_address_line2 text,
    ambulance_drop_off_city_name text,
    ambulance_drop_off_state_or_province_code text,
    ambulance_drop_off_postal_zone_or_zip_code text,
    country_code text,
    country_subdivision_code text
);


ALTER TABLE public.prof_2420h OWNER TO ras;

--
-- Name: prof_2430; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2430 (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    other_payer_primary_identifier text,
    service_line_paid_amount text,
    product_or_service_id_qualifier text,
    procedure_code text,
    procedure_modifier1 text,
    procedure_modifier2 text,
    procedure_modifier3 text,
    procedure_modifier4 text,
    procedure_code_description text,
    paid_service_unit_count text,
    bundled_or_unbundled_line_number text,
    date_claim_paid text,
    date_time_period_format_qualifier text,
    adjudication_or_payment_date text,
    amount_qualifier_code text,
    remaining_patient_liability text
);


ALTER TABLE public.prof_2430 OWNER TO ras;

--
-- Name: prof_2440; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_2440 (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer,
    form_identifier_qual text,
    form_identifier text,
    question_number text,
    question_response text,
    question_response_desc text,
    question_response_date text,
    question_response_percentage text
);


ALTER TABLE public.prof_2440 OWNER TO ras;

--
-- Name: prof_bht; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_bht (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    hierarchical_structure_code text,
    transaction_set_purpose_code text,
    batch_control_number text,
    date text,
    "time" text,
    claim_identifier text
);


ALTER TABLE public.prof_bht OWNER TO ras;

--
-- Name: prof_claim_data; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_claim_data (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    data jsonb NOT NULL
);


ALTER TABLE public.prof_claim_data OWNER TO ras;

--
-- Name: prof_claim_identifier; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_claim_identifier (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    plan_id text,
    patient_control_number text,
    linked_patient_control_number text,
    beneficiary_first_name text,
    beneficiary_last_name text,
    place_of_service text,
    begin_date_of_service text,
    end_date_of_service text,
    submission_date text,
    claim_frequency_code text,
    encounter_or_chart_review text,
    beneficiary_member_identifier text,
    rendering_provider_npi text,
    total_claim_charge_amount text,
    payer_amount_paid numeric(10,2),
    cmsicn text,
    payer_claim_control_number text,
    source text,
    encounter_status text,
    encounter_status_type text,
    encounter_status_code text,
    encounter_reject_category text,
    file_id bigint NOT NULL,
    linked_provider_clm_id bigint,
    h_plan_submitter_id bigint,
    last_updated timestamp without time zone,
    date_created timestamp without time zone,
    modified_by text,
    segment_number integer,
    interchange_sender_id text,
    interchange_receiver_id text,
    interchange_control_number text,
    group_control_number text NOT NULL,
    batch_control_number text,
    transaction_set_control_number text NOT NULL,
    st_index integer,
    billing_provider_hierarchical_id_number text,
    billing_provider_npi text,
    raps_extract_status text,
    encounter_revision numeric,
    key_hash text GENERATED ALWAYS AS (public.ras_md5(public.ras_concat(interchange_sender_id, VARIADIC ARRAY[interchange_receiver_id, plan_id, beneficiary_member_identifier, beneficiary_last_name, place_of_service, rendering_provider_npi, total_claim_charge_amount, encounter_or_chart_review, begin_date_of_service, end_date_of_service, (payer_amount_paid)::text]))) STORED
);


ALTER TABLE public.prof_claim_identifier OWNER TO ras;

--
-- Name: prof_claim_line_data; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_claim_line_data (
    id bigint NOT NULL,
    claim_id bigint NOT NULL,
    claim_line_number integer NOT NULL,
    data jsonb NOT NULL
);


ALTER TABLE public.prof_claim_line_data OWNER TO ras;

--
-- Name: prof_header_trailer; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_header_trailer (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    authorization_information_qualifier text,
    authorization_information text,
    security_information_qualifier text,
    security_information text,
    interchange_sender_id_qualifier text,
    interchange_sender_id text,
    interchange_receiver_id_qualifier text,
    interchange_receiver_id text,
    interchange_date text,
    interchange_time text,
    repetition_separator text,
    interchange_control_version_number text,
    interchange_control_number text,
    acknowledgment_requested text,
    interchange_usage_indicator text,
    component_element_separator text,
    functional_identifier_code text,
    application_senders_code text,
    application_receivers_code text,
    group_header_date text,
    group_header_time text,
    group_control_number text,
    responsible_agency_code text,
    industry_identifier_code text,
    number_of_transaction_sets_included text,
    trailer_group_control_number text,
    number_of_included_functional_groups text
);


ALTER TABLE public.prof_header_trailer OWNER TO ras;

--
-- Name: prof_se; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_se (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_segment_count text,
    transaction_set_control_number text
);


ALTER TABLE public.prof_se OWNER TO ras;

--
-- Name: prof_st; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.prof_st (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    st_index integer,
    transaction_set_identifier_code text,
    transaction_set_control_number text,
    implementation_convention_reference text
);


ALTER TABLE public.prof_st OWNER TO ras;

--
-- Name: provider_837_remit_mapping; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.provider_837_remit_mapping (
    id bigint NOT NULL,
    ref_provider_claim_id bigint,
    ref_remit_id bigint
);


ALTER TABLE public.provider_837_remit_mapping OWNER TO ras;

--
-- Name: provider_837_remit_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.provider_837_remit_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.provider_837_remit_mapping_id_seq OWNER TO ras;

--
-- Name: provider_837_remit_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.provider_837_remit_mapping_id_seq OWNED BY public.provider_837_remit_mapping.id;


--
-- Name: raps_cluster; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.raps_cluster (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    plan_id text,
    sender_id text,
    raps_file_id bigint NOT NULL,
    transaction_date text,
    diag_type text,
    member_id text,
    file_type text,
    bbb_seq_number text,
    ccc_seq_number text,
    seq_error_code text,
    patient_control_number text,
    member_id_error_code text,
    patient_dob text,
    dob_error_code text,
    provider_type text,
    from_date text,
    thru_date text,
    delete_ind text,
    diagnosis_code text,
    diag_cluster_error1 text,
    diag_cluster_error2 text,
    corrected_medicare_id text,
    risk_assessment_code text,
    risk_assessment_code_error text,
    hicn text,
    cluster_status text,
    feras_error_code text,
    internal_claim_id text,
    submission_file_id text,
    key_hash text GENERATED ALWAYS AS (public.ras_md5(public.ras_concat(hicn, VARIADIC ARRAY[provider_type, from_date, thru_date, plan_id, diagnosis_code, delete_ind]))) STORED,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE public.raps_cluster OWNER TO ras;

--
-- Name: raps_cluster_history; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.raps_cluster_history (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    plan_id text,
    sender_id text,
    raps_file_id bigint NOT NULL,
    transaction_date text,
    diag_type text,
    member_id text,
    file_type text,
    bbb_seq_number text,
    ccc_seq_number text,
    seq_error_code text,
    patient_control_number text,
    member_id_error_code text,
    patient_dob text,
    dob_error_code text,
    provider_type text,
    from_date text,
    thru_date text,
    delete_ind text,
    diagnosis_code text,
    diag_cluster_error1 text,
    diag_cluster_error2 text,
    corrected_medicare_id text,
    risk_assessment_code text,
    risk_assessment_code_error text,
    hicn text,
    cluster_status text,
    feras_error_code text,
    internal_claim_id text,
    submission_file_id text,
    key_hash text GENERATED ALWAYS AS (public.ras_md5(public.ras_concat(hicn, VARIADIC ARRAY[provider_type, from_date, thru_date, plan_id, diagnosis_code, delete_ind]))) STORED
);


ALTER TABLE public.raps_cluster_history OWNER TO ras;

--
-- Name: raps_cluster_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.raps_cluster_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.raps_cluster_id_seq OWNER TO ras;

--
-- Name: raps_cluster_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.raps_cluster_id_seq OWNED BY public.raps_cluster.id;


--
-- Name: raps_cms_tracking; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.raps_cms_tracking (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    raps_file_id bigint NOT NULL,
    sender_id text,
    plan_id text,
    submission_file_id text,
    submission_date text,
    return_file_id text,
    feras_file_id text,
    dupx_file_id text,
    error_report_file_id text,
    summary_report_file_id text,
    file_status text,
    feras_error_code text
);


ALTER TABLE public.raps_cms_tracking OWNER TO ras;

--
-- Name: raps_eef; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.raps_eef (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    raps_file_id bigint NOT NULL,
    sender_id text,
    plan_id text,
    interchange_control_number text,
    interchange_date text,
    member_id text,
    file_type text,
    encounter_type text,
    plan_claim_number text,
    internal_claim_id text,
    patient_control_number text,
    patient_dob text,
    from_date text,
    thru_date text,
    delete_indicator text,
    replace_indicator text,
    duplicate_indicator text,
    diagnosis_type text,
    diagnosis_code_type text,
    diagnosis_code text,
    member_first_name text,
    member_last_name text,
    member_middle_name text,
    member_gender text,
    hicn text,
    billing_provider_taxonomy_code text,
    rendering_provider_taxonomy_code text,
    attending_provider_taxonomy_code text,
    facility_type_code text,
    place_of_service_code text,
    frequency_code text,
    provider_type text,
    eef_source_file_name text,
    source text,
    pcp_id text,
    pcp_name text,
    bill_type text,
    ineligible_reason text,
    encounter_timestamp text,
    "timestamp" text,
    current_extract_timestamp text,
    raps_extract_status text
);


ALTER TABLE public.raps_eef OWNER TO ras;

--
-- Name: raps_feras_error; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.raps_feras_error (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    submission_file_id text,
    feras_file_id text
);


ALTER TABLE public.raps_feras_error OWNER TO ras;

--
-- Name: raps_file; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.raps_file (
    id bigint NOT NULL,
    a_id bigint NOT NULL,
    source_file_name text NOT NULL,
    file_status text,
    file_processed_status text,
    file_url text,
    raps_eef_type text,
    manual_update_comment text,
    retry_count integer,
    last_updated timestamp without time zone,
    db_load_timestamp timestamp without time zone,
    feras_error_code text
);


ALTER TABLE public.raps_file OWNER TO ras;

--
-- Name: remit_1000a; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.remit_1000a (
    id bigint NOT NULL,
    file_id bigint NOT NULL,
    entity_identifier_code text,
    payer_name text,
    identification_code_qualifier text,
    payer_identifier text,
    entity_relationship_code text,
    entity_identifier_code_6 text,
    payer_address_line text,
    payer_address_line_2 text,
    payer_city_name text,
    payer_state_code text,
    payer_postal_zone_or_zip_code text,
    country_code text,
    location_qualifier text,
    location_identifier text,
    country_subdivision_code text
);


ALTER TABLE public.remit_1000a OWNER TO ras;

--
-- Name: remit_1000b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.remit_1000b (
    id bigint NOT NULL,
    file_id bigint NOT NULL,
    entity_identifier_code text,
    payee_name text,
    identification_code_qualifier text,
    payee_identification_code text,
    entity_relationship_code text,
    entity_identifier_code_6 text,
    payee_address_line text,
    payee_address_line_2 text,
    payee_city_name text,
    payee_state_code text,
    payee_postal_zone_or_zip_code text,
    country_code text,
    location_qualifier text,
    location_identifier text,
    country_subdivision_code text,
    reference_identification_qualifier text,
    additional_payee_identifier text,
    description text,
    reference_identifier text,
    report_transmission_code text,
    name text,
    communication_number text,
    reference_identifier_4 text,
    reference_identifier_5 text
);


ALTER TABLE public.remit_1000b OWNER TO ras;

--
-- Name: remit_2000; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.remit_2000 (
    id bigint NOT NULL,
    file_id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    assigned_number text,
    provider_identifier text,
    facility_type_code text,
    fiscal_period_date text,
    total_claim_count text,
    total_claim_charge_amount text,
    monetary_amount text,
    monetary_amount_7 text,
    monetary_amount_8 text,
    monetary_amount_9 text,
    monetary_amount_10 text,
    monetary_amount_11 text,
    monetary_amount_12 text,
    total_msp_payer_amount text,
    monetary_amount_14 text,
    total_non_lab_charge_amount text,
    monetary_amount_16 text,
    total_hcpcs_reported_charge_amount text,
    total_hcpcs_payable_amount text,
    monetary_amount_19 text,
    total_professional_component_amount text,
    total_msp_patient_liability_met_amount text,
    total_patient_reimbursement_amount text,
    total_pip_claim_count text,
    total_pip_adjustment_amount text,
    total_drg_amount text,
    total_federal_specific_amount text,
    total_hospital_specific_amount text,
    total_disproportionate_share_amount text,
    total_capital_amount text,
    total_indirect_medical_education_amount text,
    total_outlier_day_count text,
    total_day_outlier_amount text,
    total_cost_outlier_amount text,
    average_drg_length_of_stay text,
    total_discharge_count text,
    total_cost_report_day_count text,
    total_covered_day_count text,
    total_non_covered_day_count text,
    total_msp_pass_through_amount text,
    average_drg_weight text,
    total_pps_capital_fsp_drg_amount text,
    total_pps_capital_hsp_drg_amount text,
    total_pps_dsh_drg_amount text
);


ALTER TABLE public.remit_2000 OWNER TO ras;

--
-- Name: remit_2100; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.remit_2100 (
    id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    patient_control_number text,
    claim_status_code text,
    total_claim_charge_amount text,
    claim_payment_amount numeric(10,2),
    patient_responsibility_amount text,
    claim_filing_indicator_code text,
    payer_claim_control_number text,
    facility_type_code text,
    claim_frequency_code text,
    patient_status_code text,
    diagnosis_related_group_drg_code text,
    diagnosis_related_group_drg_weight text,
    discharge_fraction text,
    yes_no_condition_response_code text,
    covered_days_or_visits_count text,
    pps_operating_outlier_amount text,
    lifetime_psychiatric_days_count text,
    claim_drg_amount text,
    claim_payment_remark_code text,
    claim_disproportionate_share_amount text,
    claim_msp_pass_through_amount text,
    claim_pps_capital_amount text,
    pps_capital_fsp_drg_amount text,
    pps_capital_hsp_drg_amount text,
    pps_capital_dsh_drg_amount text,
    old_capital_amount text,
    pps_capital_ime_amount text,
    pps_operating_hospital_specific_drg_amount text,
    cost_report_day_count text,
    pps_operating_federal_specific_drg_amount text,
    claim_pps_capital_outlier_amount text,
    claim_indirect_teaching_amount text,
    non_payable_professional_component_amount text,
    claim_payment_remark_code_20 text,
    claim_payment_remark_code_21 text,
    claim_payment_remark_code_22 text,
    claim_payment_remark_code_23 text,
    pps_capital_exception_amount text,
    reimbursement_rate text,
    claim_hcpcs_payable_amount text,
    claim_payment_remark_code_3 text,
    claim_payment_remark_code_4 text,
    claim_payment_remark_code_5 text,
    claim_payment_remark_code_6 text,
    claim_payment_remark_code_7 text,
    claim_esrd_payment_amount text,
    non_payable_professional_component_amount_9 text
);


ALTER TABLE public.remit_2100 OWNER TO ras;

--
-- Name: remit_2110; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.remit_2110 (
    id bigint NOT NULL,
    remittance_id bigint NOT NULL,
    remit_line_number integer,
    product_or_service_id_qualifier text,
    adjudicated_procedure_code text,
    procedure_modifier text,
    procedure_modifier_1_3 text,
    procedure_modifier_1_4 text,
    procedure_modifier_1_5 text,
    description text,
    product_service_id text,
    line_item_charge_amount numeric(10,2),
    line_item_provider_payment_amount text,
    national_uniform_billing_committee_revenue_code text,
    units_of_service_paid_count text,
    product_or_service_id_qualifier_6_0 text,
    procedure_code text,
    procedure_modifier_6_2 text,
    procedure_modifier_6_3 text,
    procedure_modifier_6_4 text,
    procedure_modifier_6_5 text,
    procedure_code_description text,
    product_service_id_6_7 text,
    original_units_of_service_count text
);


ALTER TABLE public.remit_2110 OWNER TO ras;

--
-- Name: remit_bht; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.remit_bht (
    id bigint NOT NULL,
    file_id bigint NOT NULL,
    transaction_handling_code text,
    total_actual_provider_payment_amount text,
    credit_or_debit_flag_code text,
    payment_method_code text,
    payment_format_code text,
    dfi_qualifier text,
    sender_dfi_identifier text,
    account_number_qualifier text,
    sender_bank_account_number text,
    payer_identifier text,
    originating_company_supplemental_code text,
    dfi_qualifier_12 text,
    receiver_or_provider_bank_id_number text,
    account_number_qualifier_14 text,
    receiver_or_provider_account_number text,
    check_issue_or_eft_effective_date text,
    business_function_code text,
    dfi_id_number_qualifier text,
    dfi_identification_number text,
    account_number_qualifier_20 text,
    account_number text,
    trace_type_code text,
    check_or_eft_trace_number text,
    payer_identifier_3 text,
    originating_company_supplemental_code_4 text,
    entity_identifier_code text,
    currency_code text,
    exchange_rate text,
    entity_identifier_code_4 text,
    currency_code_5 text,
    currency_market_exchange_code text,
    date_time_qualifier text,
    date text,
    "time" text,
    date_time_qualifier_10 text,
    date_11 text,
    time_12 text,
    date_time_qualifier_13 text,
    date_14 text,
    time_15 text,
    date_time_qualifier_16 text,
    date_17 text,
    time_18 text,
    date_time_qualifier_19 text,
    date_20 text,
    time_21 text,
    date_time_qualifier_1 text,
    production_date text,
    time_3 text,
    time_code text,
    date_time_period_format_qualifier text,
    date_time_period text
);


ALTER TABLE public.remit_bht OWNER TO ras;

--
-- Name: remit_footer; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.remit_footer (
    id bigint NOT NULL,
    file_id bigint NOT NULL,
    provider_identifier text,
    fiscal_period_date text,
    adjustment_reason_code text,
    provider_adjustment_identifier text,
    provider_adjustment_amount text,
    adjustment_reason_code_5_0 text,
    provider_adjustment_identifier_5_1 text,
    provider_adjustment_amount_6 text,
    adjustment_reason_code_7_0 text,
    provider_adjustment_identifier_7_1 text,
    provider_adjustment_amount_8 text,
    adjustment_reason_code_9_0 text,
    provider_adjustment_identifier_9_1 text,
    provider_adjustment_amount_10 text,
    adjustment_reason_code_11_0 text,
    provider_adjustment_identifier_11_1 text,
    provider_adjustment_amount_12 text,
    adjustment_reason_code_13_0 text,
    provider_adjustment_identifier_13_1 text,
    provider_adjustment_amount_14 text
);


ALTER TABLE public.remit_footer OWNER TO ras;

--
-- Name: remit_header_trailer; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.remit_header_trailer (
    id bigint NOT NULL,
    record_type text,
    file_id bigint NOT NULL,
    authorization_information_qualifier text,
    authorization_information text,
    security_information_qualifier text,
    security_information text,
    interchange_sender_id_qualifier text,
    interchange_sender_id text,
    interchange_receiver_id_qualifier text,
    interchange_receiver_id text,
    interchange_date text,
    interchange_time text,
    repetition_separator text,
    interchange_control_version_number text,
    interchange_control_number text,
    acknowledgment_requested text,
    interchange_usage_indicator text,
    component_element_separator text,
    functional_identifier_code text,
    application_senders_code text,
    application_receivers_code text,
    group_header_date text,
    group_header_time text,
    group_control_number text,
    responsible_agency_code text,
    industry_identifier_code text,
    number_of_transaction_sets_included text,
    trailer_group_control_number text,
    number_of_included_functional_groups text
);


ALTER TABLE public.remit_header_trailer OWNER TO ras;

--
-- Name: remit_identifier; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.remit_identifier (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    plan_id text,
    file_id bigint NOT NULL,
    last_updated timestamp without time zone,
    date_created timestamp without time zone,
    modified_by text,
    file_submission_date text,
    patient_control_number text,
    beneficiary_member_identifier text,
    begin_date_of_service text,
    end_date_of_service text,
    total_claim_charge_amount text,
    claim_payment_amount numeric(10,2),
    payer_claim_control_number text,
    facility_type_code text,
    claim_frequency_code text,
    st_index integer,
    remit_status text
);


ALTER TABLE public.remit_identifier OWNER TO ras;

--
-- Name: remit_st; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.remit_st (
    id bigint NOT NULL,
    file_id bigint NOT NULL,
    st_index integer,
    transaction_set_identifier_code text,
    transaction_set_control_number text,
    implementation_convention_reference text
);


ALTER TABLE public.remit_st OWNER TO ras;

--
-- Name: report_category; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.report_category (
    id bigint NOT NULL,
    report_name text NOT NULL,
    category text NOT NULL,
    default_email text
);


ALTER TABLE public.report_category OWNER TO ras;

--
-- Name: report_category_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.report_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.report_category_id_seq OWNER TO ras;

--
-- Name: report_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.report_category_id_seq OWNED BY public.report_category.id;


--
-- Name: report_details; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.report_details (
    id bigint NOT NULL,
    report_category_id bigint NOT NULL,
    authority text,
    default_email_cc text,
    user_name text
);


ALTER TABLE public.report_details OWNER TO ras;

--
-- Name: report_details_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.report_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.report_details_id_seq OWNER TO ras;

--
-- Name: report_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.report_details_id_seq OWNED BY public.report_details.id;


--
-- Name: report_subscription; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.report_subscription (
    id bigint NOT NULL,
    report_details_id bigint NOT NULL,
    email text
);


ALTER TABLE public.report_subscription OWNER TO ras;

--
-- Name: report_subscription_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.report_subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.report_subscription_id_seq OWNER TO ras;

--
-- Name: report_subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.report_subscription_id_seq OWNED BY public.report_subscription.id;


--
-- Name: report_type; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.report_type (
    name text NOT NULL,
    notification_type public.notifications NOT NULL,
    phi_data boolean DEFAULT false NOT NULL
);


ALTER TABLE public.report_type OWNER TO ras;

--
-- Name: resp_277_2000b; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_277_2000b (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    transaction_set_control_number text,
    information_receiver_name text,
    claim_transaction_batch_number text,
    information_receiver_status text
);


ALTER TABLE public.resp_277_2000b OWNER TO ras;

--
-- Name: resp_277_2000c; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_277_2000c (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    transaction_set_control_number text,
    st_index integer,
    segment_number integer,
    claim_transaction_batch_number text,
    billing_provider_name text,
    provider_of_service_information_trace_id text,
    billing_provider_status text,
    full_status_code text,
    status_code text,
    secondary_status_code text,
    tertiary_status_code text,
    accepted_claim_quantity text,
    total_accepted_amount text
);


ALTER TABLE public.resp_277_2000c OWNER TO ras;

--
-- Name: resp_277_2000d; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_277_2000d (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    transaction_set_control_number text,
    st_index integer,
    segment_number integer,
    claim_transaction_batch_number text,
    patient_first_name text,
    patient_last_name text,
    patient_control_number text,
    billing_provider_status text,
    full_status_code text,
    status_code text,
    secondary_status_code text,
    tertiary_status_code text
);


ALTER TABLE public.resp_277_2000d OWNER TO ras;

--
-- Name: resp_277_2220d; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_277_2220d (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    transaction_set_control_number text,
    st_index integer,
    segment_number integer,
    claim_transaction_batch_number text,
    patient_control_number text,
    ref_reject_code text,
    line_item_control_number integer,
    ref_6r_value text
);


ALTER TABLE public.resp_277_2220d OWNER TO ras;

--
-- Name: resp_277_bht; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_277_bht (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    transaction_set_control_number text,
    batch_control_number text,
    date_of_response text,
    time_of_response text
);


ALTER TABLE public.resp_277_bht OWNER TO ras;

--
-- Name: resp_277_header_trailer; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_277_header_trailer (
    id bigint NOT NULL,
    record_type text,
    resp_file_id bigint NOT NULL,
    authorization_information_qualifier text,
    authorization_information text,
    security_information_qualifier text,
    security_information text,
    interchange_sender_id_qualifier text,
    interchange_sender_id text,
    interchange_receiver_id_qualifier text,
    interchange_receiver_id text,
    interchange_date text,
    interchange_time text,
    repetition_separator text,
    interchange_control_version_number text,
    interchange_control_number text,
    acknowledgment_requested text,
    interchange_usage_indicator text,
    component_element_separator text,
    functional_identifier_code text,
    application_senders_code text,
    application_receivers_code text,
    group_header_date text,
    group_header_time text,
    group_control_number text,
    responsible_agency_code text,
    industry_identifier_code text,
    number_of_transaction_sets_included text,
    trailer_group_control_number text,
    number_of_included_functional_groups text
);


ALTER TABLE public.resp_277_header_trailer OWNER TO ras;

--
-- Name: resp_277_st; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_277_st (
    id bigint NOT NULL,
    record_type text,
    resp_file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_sender_id text,
    interchange_receiver_id text,
    group_control_number text,
    st_index integer,
    transaction_set_identifier_code text,
    transaction_set_control_number text,
    implementation_convention_reference text
);


ALTER TABLE public.resp_277_st OWNER TO ras;

--
-- Name: resp_999_2000; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_999_2000 (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    record_type text,
    interchange_sender_id text,
    interchange_control_number text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    batch_control_number text,
    ak_transaction_set_control_number text,
    transaction_set_status text
);


ALTER TABLE public.resp_999_2000 OWNER TO ras;

--
-- Name: resp_999_2100; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_999_2100 (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    record_type text,
    interchange_sender_id text,
    interchange_control_number text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    batch_control_number text,
    ak_transaction_set_control_number text,
    transaction_set_error_code text,
    error_segment_id_code text,
    error_segment_position integer,
    loop_identifier_code text,
    segment_syntax_error_code text
);


ALTER TABLE public.resp_999_2100 OWNER TO ras;

--
-- Name: resp_999_2110; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_999_2110 (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    record_type text,
    interchange_sender_id text,
    interchange_control_number text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    batch_control_number text,
    ak_transaction_set_control_number text,
    element_position_in_segment text,
    component_data_element_position text,
    element_error_code text
);


ALTER TABLE public.resp_999_2110 OWNER TO ras;

--
-- Name: resp_999_bht; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_999_bht (
    id bigint NOT NULL,
    record_type text,
    interchange_sender_id text,
    interchange_control_number text,
    interchange_receiver_id text,
    group_control_number text,
    transaction_set_control_number text,
    functional_identifier_code text,
    batch_control_number text,
    industry_identifier_code text,
    functional_group_acknowledge_code text,
    number_of_transaction_sets text,
    functional_group_syntax_error_code text,
    resp_file_id bigint NOT NULL,
    is_response_applied_status text,
    retry_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.resp_999_bht OWNER TO ras;

--
-- Name: resp_999_header_trailer; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_999_header_trailer (
    id bigint NOT NULL,
    record_type text,
    resp_file_id bigint NOT NULL,
    authorization_information_qualifier text,
    authorization_information text,
    security_information_qualifier text,
    security_information text,
    interchange_sender_id_qualifier text,
    interchange_sender_id text,
    interchange_receiver_id_qualifier text,
    interchange_receiver_id text,
    interchange_date text,
    interchange_time text,
    repetition_separator text,
    interchange_control_version_number text,
    interchange_control_number text,
    acknowledgment_requested text,
    interchange_usage_indicator text,
    component_element_separator text,
    functional_identifier_code text,
    application_senders_code text,
    application_receivers_code text,
    group_header_date text,
    group_header_time text,
    group_control_number text,
    responsible_agency_code text,
    industry_identifier_code text,
    number_of_transaction_sets_included text,
    trailer_group_control_number text,
    number_of_included_functional_groups text
);


ALTER TABLE public.resp_999_header_trailer OWNER TO ras;

--
-- Name: resp_mao_1; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_mao_1 (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    interchange_sender_id text,
    interchange_control_number text,
    interchange_date text,
    medicare_contract_id text,
    plan_icn text,
    encounter_icn text,
    encounter_line_number text,
    duplicate_plan_icn text,
    duplicate_encounter_icn text,
    duplicate_encounter_line_number text,
    beneficiary_hicn text,
    date_of_service text,
    error_code text
);


ALTER TABLE public.resp_mao_1 OWNER TO ras;

--
-- Name: resp_mao_2; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_mao_2 (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    interchange_control_number text,
    medicare_contract_id text,
    plan_icn text,
    encounter_icn text,
    encounter_line_number text,
    encounter_status text,
    error_code text,
    error_description text
);


ALTER TABLE public.resp_mao_2 OWNER TO ras;

--
-- Name: resp_mao_4; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_mao_4 (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    plan_id text,
    report_date text,
    beneficiary_id text,
    encounter_icn text,
    encounter_type_switch text,
    linked_encounter_icn text,
    linked_encounter_allowed_disallowed text,
    encounter_submission_date text,
    from_date text,
    through_date text,
    service_type text,
    allowed_disallowed text,
    allowed_disallowed_reason_code text,
    diagnoses_icd text,
    diagnosis_code text,
    add_delete_ind text
);


ALTER TABLE public.resp_mao_4 OWNER TO ras;

--
-- Name: resp_ta1_data; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_ta1_data (
    id bigint NOT NULL,
    resp_file_id bigint NOT NULL,
    interchange_control_number text,
    interchange_date text,
    interchange_time text,
    interchange_ack_code text,
    interchange_note_code text
);


ALTER TABLE public.resp_ta1_data OWNER TO ras;

--
-- Name: resp_ta1_header_trailer; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.resp_ta1_header_trailer (
    id bigint NOT NULL,
    record_type text,
    resp_file_id bigint NOT NULL,
    authorization_information_qualifier text,
    authorization_information text,
    security_information_qualifier text,
    security_information text,
    interchange_sender_id_qualifier text,
    interchange_sender_id text,
    interchange_receiver_id_qualifier text,
    interchange_receiver_id text,
    interchange_date text,
    interchange_time text,
    repetition_separator text,
    interchange_control_version_number text,
    interchange_control_number text,
    acknowledgment_requested text,
    interchange_usage_indicator text,
    component_element_separator text,
    functional_identifier_code text,
    application_senders_code text,
    application_receivers_code text,
    group_header_date text,
    group_header_time text,
    group_control_number text,
    responsible_agency_code text,
    industry_identifier_code text,
    number_of_transaction_sets_included text,
    trailer_group_control_number text,
    number_of_included_functional_groups text
);


ALTER TABLE public.resp_ta1_header_trailer OWNER TO ras;

--
-- Name: segment_data; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
)
PARTITION BY HASH (claim_id);


ALTER TABLE public.segment_data OWNER TO ras;

--
-- Name: segment_data_00; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_00 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_00 FOR VALUES WITH (modulus 20, remainder 0);


ALTER TABLE public.segment_data_00 OWNER TO ras;

--
-- Name: segment_data_01; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_01 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_01 FOR VALUES WITH (modulus 20, remainder 1);


ALTER TABLE public.segment_data_01 OWNER TO ras;

--
-- Name: segment_data_02; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_02 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_02 FOR VALUES WITH (modulus 20, remainder 2);


ALTER TABLE public.segment_data_02 OWNER TO ras;

--
-- Name: segment_data_03; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_03 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_03 FOR VALUES WITH (modulus 20, remainder 3);


ALTER TABLE public.segment_data_03 OWNER TO ras;

--
-- Name: segment_data_04; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_04 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_04 FOR VALUES WITH (modulus 20, remainder 4);


ALTER TABLE public.segment_data_04 OWNER TO ras;

--
-- Name: segment_data_05; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_05 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_05 FOR VALUES WITH (modulus 20, remainder 5);


ALTER TABLE public.segment_data_05 OWNER TO ras;

--
-- Name: segment_data_06; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_06 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_06 FOR VALUES WITH (modulus 20, remainder 6);


ALTER TABLE public.segment_data_06 OWNER TO ras;

--
-- Name: segment_data_07; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_07 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_07 FOR VALUES WITH (modulus 20, remainder 7);


ALTER TABLE public.segment_data_07 OWNER TO ras;

--
-- Name: segment_data_08; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_08 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_08 FOR VALUES WITH (modulus 20, remainder 8);


ALTER TABLE public.segment_data_08 OWNER TO ras;

--
-- Name: segment_data_09; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_09 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_09 FOR VALUES WITH (modulus 20, remainder 9);


ALTER TABLE public.segment_data_09 OWNER TO ras;

--
-- Name: segment_data_10; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_10 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_10 FOR VALUES WITH (modulus 20, remainder 10);


ALTER TABLE public.segment_data_10 OWNER TO ras;

--
-- Name: segment_data_11; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_11 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_11 FOR VALUES WITH (modulus 20, remainder 11);


ALTER TABLE public.segment_data_11 OWNER TO ras;

--
-- Name: segment_data_12; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_12 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_12 FOR VALUES WITH (modulus 20, remainder 12);


ALTER TABLE public.segment_data_12 OWNER TO ras;

--
-- Name: segment_data_13; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_13 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_13 FOR VALUES WITH (modulus 20, remainder 13);


ALTER TABLE public.segment_data_13 OWNER TO ras;

--
-- Name: segment_data_14; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_14 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_14 FOR VALUES WITH (modulus 20, remainder 14);


ALTER TABLE public.segment_data_14 OWNER TO ras;

--
-- Name: segment_data_15; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_15 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_15 FOR VALUES WITH (modulus 20, remainder 15);


ALTER TABLE public.segment_data_15 OWNER TO ras;

--
-- Name: segment_data_16; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_16 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_16 FOR VALUES WITH (modulus 20, remainder 16);


ALTER TABLE public.segment_data_16 OWNER TO ras;

--
-- Name: segment_data_17; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_17 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_17 FOR VALUES WITH (modulus 20, remainder 17);


ALTER TABLE public.segment_data_17 OWNER TO ras;

--
-- Name: segment_data_18; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_18 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_18 FOR VALUES WITH (modulus 20, remainder 18);


ALTER TABLE public.segment_data_18 OWNER TO ras;

--
-- Name: segment_data_19; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.segment_data_19 (
    loop_id text,
    segment_number integer,
    segment_name text,
    claim_id bigint,
    claim_line_id bigint,
    file_id bigint
);
ALTER TABLE ONLY public.segment_data ATTACH PARTITION public.segment_data_19 FOR VALUES WITH (modulus 20, remainder 19);


ALTER TABLE public.segment_data_19 OWNER TO ras;

--
-- Name: shedlock; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.shedlock (
    name character varying(255) NOT NULL,
    lock_until timestamp without time zone,
    locked_at timestamp without time zone,
    locked_by character varying(255)
);


ALTER TABLE public.shedlock OWNER TO ras;

--
-- Name: submitter_info_config; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.submitter_info_config (
    id bigint NOT NULL,
    cms_submitter_id bigint NOT NULL,
    key text,
    value text
);


ALTER TABLE public.submitter_info_config OWNER TO ras;

--
-- Name: tenant_schema; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.tenant_schema (
    tenant_id text NOT NULL,
    schema text NOT NULL,
    modified_by text,
    date_created timestamp without time zone DEFAULT now(),
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE public.tenant_schema OWNER TO ras;

--
-- Name: x12_duplicate_file; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.x12_duplicate_file (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    file_id bigint NOT NULL,
    encounter_type text,
    duplicate_file_name text,
    file_url text,
    file_type text,
    db_load_timestamp timestamp without time zone
);


ALTER TABLE public.x12_duplicate_file OWNER TO ras;

--
-- Name: x12_resp_duplicate_file; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.x12_resp_duplicate_file (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    duplicate_file_name text,
    file_url text,
    resp_file_id bigint NOT NULL,
    response_file_type text,
    db_load_timestamp timestamp without time zone
);


ALTER TABLE public.x12_resp_duplicate_file OWNER TO ras;

--
-- Name: x12file; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.x12file (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    encounter_type text,
    submission_file_type text,
    encounter_or_chart_review text,
    source_file_name text NOT NULL,
    file_name text,
    file_url text,
    file_type text,
    initial_source text,
    file_status text,
    file_processed_status text,
    total_st_se_segments text,
    manual_update_comment text,
    retry_count integer,
    last_updated timestamp without time zone,
    db_load_timestamp timestamp without time zone,
    linked_orig_file bigint,
    modified_by text,
    file_hash text
);


ALTER TABLE public.x12file OWNER TO ras;

--
-- Name: x12file_struct_validation; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.x12file_struct_validation (
    id bigint NOT NULL,
    file_id bigint NOT NULL,
    message text
);


ALTER TABLE public.x12file_struct_validation OWNER TO ras;

--
-- Name: x12file_struct_validation_id_seq; Type: SEQUENCE; Schema: public; Owner: ras
--

CREATE SEQUENCE public.x12file_struct_validation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.x12file_struct_validation_id_seq OWNER TO ras;

--
-- Name: x12file_struct_validation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ras
--

ALTER SEQUENCE public.x12file_struct_validation_id_seq OWNED BY public.x12file_struct_validation.id;


--
-- Name: xref_billtype_ipop; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_billtype_ipop (
    id bigint NOT NULL,
    bill_type text,
    start_date text,
    end_date text,
    ipop_ind text,
    taxonomy_req_ind text
);


ALTER TABLE public.xref_billtype_ipop OWNER TO ras;

--
-- Name: xref_claim_error_277; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_claim_error_277 (
    id bigint NOT NULL,
    claim_status_category_code text,
    claim_status_code1 text,
    claim_status_code2 text,
    claim_status_code3 text,
    eic text,
    encounter_type text,
    internal_error_number integer,
    error_description text,
    error_category text
);


ALTER TABLE public.xref_claim_error_277 OWNER TO ras;

--
-- Name: xref_claim_error_999; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_claim_error_999 (
    id bigint NOT NULL,
    loop_id text,
    segment_id_code text,
    element_position_in_segment text,
    element_sub_position text,
    segment_syntax_error_code text,
    element_syntax_error_code text,
    functional_group_syntax_error_code text,
    transaction_set_syntax_error_code text,
    encounter_type text,
    internal_error_number integer,
    error_description text,
    error_category text
);


ALTER TABLE public.xref_claim_error_999 OWNER TO ras;

--
-- Name: xref_claim_error_mao2; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_claim_error_mao2 (
    id bigint NOT NULL,
    code text,
    category text,
    disposition text,
    description text
);


ALTER TABLE public.xref_claim_error_mao2 OWNER TO ras;

--
-- Name: xref_claim_npi_mapping; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_claim_npi_mapping (
    h_plan_id smallint,
    claim_ref text,
    name text,
    billing_npi text,
    attending_npi text
);


ALTER TABLE public.xref_claim_npi_mapping OWNER TO ras;

--
-- Name: xref_dme_pos; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_dme_pos (
    id bigint NOT NULL,
    dme_pos text,
    year text
);


ALTER TABLE public.xref_dme_pos OWNER TO ras;

--
-- Name: xref_edit_error; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_edit_error (
    internal_error_number integer NOT NULL,
    encounter_type text NOT NULL,
    error_category text,
    error_description text
);


ALTER TABLE public.xref_edit_error OWNER TO ras;

--
-- Name: xref_hcc_description; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_hcc_description (
    id bigint NOT NULL,
    description text
);


ALTER TABLE public.xref_hcc_description OWNER TO ras;

--
-- Name: xref_hcc_drop; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_hcc_drop (
    id bigint NOT NULL,
    model_run text,
    hierarchy_hcc text,
    hcc_to_drop text,
    payment_year text
);


ALTER TABLE public.xref_hcc_drop OWNER TO ras;

--
-- Name: xref_hcpcs_cpt; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_hcpcs_cpt (
    id bigint NOT NULL,
    cpt_code text,
    code_description text,
    payment_year text,
    service_year text
);


ALTER TABLE public.xref_hcpcs_cpt OWNER TO ras;

--
-- Name: xref_hicn_mbi; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_hicn_mbi (
    id bigint NOT NULL,
    h_plan_id smallint NOT NULL,
    submitter_id text,
    plan_number text,
    plan_member_id text,
    hicn text,
    mbi text,
    pcp_effective_start_date text,
    pcp_effective_end_date text,
    member_enrollment_date text,
    member_disenrolled_date text,
    subscriber_last_name text,
    subscriber_first_name text,
    subscriber_middle_name text,
    subscriber_gender text,
    subscriber_dob text,
    pcp_id text,
    pcp_last_name text,
    pcp_first_name text,
    pcp_middle_name text,
    permanent_street_address_1 text,
    permanent_street_address_2 text,
    permanent_street_address_3 text,
    permanent_city text,
    permanent_state text,
    permanent_zip_code text,
    permanent_county text,
    mailing_street_address_1 text,
    mailing_street_address_2 text,
    mailing_street_address_3 text,
    mailing_city text,
    mailing_state text,
    mailing_zip_code text,
    mailing_county text,
    enrollment_year smallint GENERATED ALWAYS AS (("substring"(member_enrollment_date, 1, 4))::smallint) STORED,
    enrollment_month smallint GENERATED ALWAYS AS (("substring"(member_enrollment_date, 5, 2))::smallint) STORED,
    disenrollment_year smallint GENERATED ALWAYS AS (("substring"(member_disenrolled_date, 1, 4))::smallint) STORED,
    disenrollment_month smallint GENERATED ALWAYS AS (("substring"(member_disenrolled_date, 5, 2))::smallint) STORED,
    enrollment_date date GENERATED ALWAYS AS (make_date(("substring"(member_enrollment_date, 1, 4))::integer, ("substring"(member_enrollment_date, 5, 2))::integer, ("substring"(member_enrollment_date, 7, 2))::integer)) STORED,
    disenrollment_date date GENERATED ALWAYS AS (make_date(("substring"(member_disenrolled_date, 1, 4))::integer, ("substring"(member_disenrolled_date, 5, 2))::integer, ("substring"(member_disenrolled_date, 7, 2))::integer)) STORED
);


ALTER TABLE public.xref_hicn_mbi OWNER TO ras;

--
-- Name: xref_icd_hcc; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_icd_hcc (
    id bigint NOT NULL,
    icd_code text,
    icd_description text,
    hcc_model text,
    model_category text,
    hcc text,
    payment_year text
);


ALTER TABLE public.xref_icd_hcc OWNER TO ras;

--
-- Name: xref_raf_codes; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_raf_codes (
    id bigint NOT NULL,
    payment_year smallint,
    product text,
    normalization_factor numeric,
    coding_intensity numeric,
    blend_percent numeric
);


ALTER TABLE public.xref_raf_codes OWNER TO ras;

--
-- Name: xref_raps_error; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_raps_error (
    id bigint NOT NULL,
    error_code text,
    error_description text,
    error_record text,
    error_category text
);


ALTER TABLE public.xref_raps_error OWNER TO ras;

--
-- Name: xref_specialty_codes; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_specialty_codes (
    id bigint NOT NULL,
    specialty_code text,
    specialty text,
    payment_year text
);


ALTER TABLE public.xref_specialty_codes OWNER TO ras;

--
-- Name: xref_specialty_taxonomy; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_specialty_taxonomy (
    id bigint NOT NULL,
    specialty_code text,
    provider_type_desc text,
    provider_taxonomy_code text,
    provider_taxonomy_desc text,
    payment_year text
);


ALTER TABLE public.xref_specialty_taxonomy OWNER TO ras;

--
-- Name: xref_ta1_error; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.xref_ta1_error (
    id bigint NOT NULL,
    error_type text,
    error_code text,
    error_description text,
    error_category text
);


ALTER TABLE public.xref_ta1_error OWNER TO ras;

--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: batch_data id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.batch_data ALTER COLUMN id SET DEFAULT nextval('public.batch_data_id_seq'::regclass);


--
-- Name: batch_file id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.batch_file ALTER COLUMN id SET DEFAULT nextval('public.batch_file_id_seq'::regclass);


--
-- Name: flow id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.flow ALTER COLUMN id SET DEFAULT nextval('public.flow_id_seq'::regclass);


--
-- Name: flow_item id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.flow_item ALTER COLUMN id SET DEFAULT nextval('public.flow_item_id_seq'::regclass);


--
-- Name: flow_item_history id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.flow_item_history ALTER COLUMN id SET DEFAULT nextval('public.flow_item_history_id_seq'::regclass);


--
-- Name: hcc_diag id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.hcc_diag ALTER COLUMN id SET DEFAULT nextval('public.hcc_diag_id_seq'::regclass);


--
-- Name: hcc_diag_filtered id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.hcc_diag_filtered ALTER COLUMN id SET DEFAULT nextval('public.hcc_diag_filtered_id_seq'::regclass);


--
-- Name: hcc_diag_hierarchy_applied id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.hcc_diag_hierarchy_applied ALTER COLUMN id SET DEFAULT nextval('public.hcc_diag_hierarchy_applied_id_seq'::regclass);


--
-- Name: health_plan id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.health_plan ALTER COLUMN id SET DEFAULT nextval('public.health_plan_id_seq'::regclass);


--
-- Name: linked_cr_batch id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.linked_cr_batch ALTER COLUMN id SET DEFAULT nextval('public.linked_cr_batch_id_seq'::regclass);


--
-- Name: member_raf id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.member_raf ALTER COLUMN id SET DEFAULT nextval('public.member_raf_id_seq'::regclass);


--
-- Name: mmr_data id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.mmr_data ALTER COLUMN id SET DEFAULT nextval('public.mmr_data_id_seq'::regclass);


--
-- Name: provider_837_remit_mapping id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.provider_837_remit_mapping ALTER COLUMN id SET DEFAULT nextval('public.provider_837_remit_mapping_id_seq'::regclass);


--
-- Name: raps_cluster id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_cluster ALTER COLUMN id SET DEFAULT nextval('public.raps_cluster_id_seq'::regclass);


--
-- Name: report_category id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_category ALTER COLUMN id SET DEFAULT nextval('public.report_category_id_seq'::regclass);


--
-- Name: report_details id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_details ALTER COLUMN id SET DEFAULT nextval('public.report_details_id_seq'::regclass);


--
-- Name: report_subscription id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_subscription ALTER COLUMN id SET DEFAULT nextval('public.report_subscription_id_seq'::regclass);


--
-- Name: x12file_struct_validation id; Type: DEFAULT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12file_struct_validation ALTER COLUMN id SET DEFAULT nextval('public.x12file_struct_validation_id_seq'::regclass);


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.audit_log (id, h_plan_id, orig_claim_id, patient_control_number, beneficiary_member_identifier, begin_date_of_service, end_date_of_service, orig_key_hash, modification_type, modified_by, modified_on, modified_data) FROM stdin;
\.


--
-- Data for Name: batch_data; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.batch_data (id, batch_file_id, lob, submitter_id, mbi, patient_control_number, begin_date_of_service, end_date_of_service, source_type, submission_date, status, status_code, data) FROM stdin;
\.


--
-- Data for Name: batch_file; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.batch_file (id, h_plan_id, type, name, url, status, processed_status, db_load_timestamp, last_updated, modified_by, hash) FROM stdin;
\.


--
-- Data for Name: child_inst_2010aa_per; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2010aa_per (id, parent_id, claim_id, billing_provider_contact_function_code, billing_provider_contact_name, billing_provider_communication_number_qualifier1, billing_provider_communication_number1, billing_provider_communication_number_qualifier2, billing_provider_communication_number2, billing_provider_communication_number_qualifier3, billing_provider_communication_number3) FROM stdin;
\.


--
-- Data for Name: child_inst_2010aa_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2010aa_ref (id, parent_id, claim_id, billing_provider_ref_identification_qualifier, billing_provider_employers_identification_number) FROM stdin;
\.


--
-- Data for Name: child_inst_2010ac_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2010ac_ref (id, parent_id, claim_id, pay_to_plan_ref_identification_qual, payer_identification_number) FROM stdin;
\.


--
-- Data for Name: child_inst_2010ba_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2010ba_ref (id, parent_id, claim_id, subscriber_secondary_identification_code_qual, subscriber_supplemental_identifier) FROM stdin;
\.


--
-- Data for Name: child_inst_2010bb_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2010bb_ref (id, parent_id, claim_id, payer_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2300_dtp; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2300_dtp (id, parent_id, claim_id, date_time_qualifier, date_time_period_format_qualifier, dtp_03) FROM stdin;
\.


--
-- Data for Name: child_inst_2300_hi; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2300_hi (id, parent_id, claim_id, primary_claim_code_type, primary_claim_code, primary_date_qual, primary_date, primary_monetary_amount, primary_quantity, primary_version, primary_industry_code, primary_response_code, secondary_claim_code_type1, secondary_claim_code1, secondary_date_qual1, secondary_date1, secondarymonetary_amount1, secondary_quantity1, secondary_version1, secondary_industry_code1, secondary_response_code1, secondary_claim_code_type2, secondary_claim_code2, secondary_date_qual2, secondary_date2, secondarymonetary_amount2, secondary_quantity2, secondary_version2, secondary_industry_code2, secondary_response_code2, secondary_claim_code_type3, secondary_claim_code3, secondary_date_qual3, secondary_date3, secondarymonetary_amount3, secondary_quantity3, secondary_version3, secondary_industry_code3, secondary_response_code3, secondary_claim_code_type4, secondary_claim_code4, secondary_date_qual4, secondary_date4, secondarymonetary_amount4, secondary_quantity4, secondary_version4, secondary_industry_code4, secondary_response_code4, secondary_claim_code_type5, secondary_claim_code5, secondary_date_qual5, secondary_date5, secondarymonetary_amount5, secondary_quantity5, secondary_version5, secondary_industry_code5, secondary_response_code5, secondary_claim_code_type6, secondary_claim_code6, secondary_date_qual6, secondary_date6, secondarymonetary_amount6, secondary_quantity6, secondary_version6, secondary_industry_code6, secondary_response_code6, secondary_claim_code_type7, secondary_claim_code7, secondary_date_qual7, secondary_date7, secondarymonetary_amount7, secondary_quantity7, secondary_version7, secondary_industry_code7, secondary_response_code7, secondary_claim_code_type8, secondary_claim_code8, secondary_date_qual8, secondary_date8, secondarymonetary_amount8, secondary_quantity8, secondary_version8, secondary_industry_code8, secondary_response_code8, secondary_claim_code_type9, secondary_claim_code9, secondary_date_qual9, secondary_date9, secondarymonetary_amount9, secondary_quantity9, secondary_version9, secondary_industry_code9, secondary_response_code9, secondary_claim_code_type10, secondary_claim_code10, secondary_date_qual10, secondary_date10, secondarymonetary_amount10, secondary_quantity10, secondary_version10, secondary_industry_code10, secondary_response_code10, secondary_claim_code_type11, secondary_claim_code11, secondary_date_qual11, secondary_date11, secondarymonetary_amount11, secondary_quantity11, secondary_version11, secondary_industry_code11, secondary_response_code11, secondary_claim_code_type12, secondary_claim_code12, secondary_date_qual12, secondary_date12, secondarymonetary_amount12, secondary_quantity12, secondary_version12, secondary_industry_code12, secondary_response_code12, secondary_claim_code_type13, secondary_claim_code13, secondary_date_qual13, secondary_date13, secondarymonetary_amount13, secondary_quantity13, secondary_version13, secondary_industry_code13, secondary_response_code13, secondary_claim_code_type14, secondary_claim_code14, secondary_date_qual14, secondary_date14, secondarymonetary_amount14, secondary_quantity14, secondary_version14, secondary_industry_code14, secondary_response_code14, secondary_claim_code_type15, secondary_claim_code15, secondary_date_qual15, secondary_date15, secondarymonetary_amount15, secondary_quantity15, secondary_version15, secondary_industry_code15, secondary_response_code15, secondary_claim_code_type16, secondary_claim_code16, secondary_date_qual16, secondary_date16, secondarymonetary_amount16, secondary_quantity16, secondary_version16, secondary_industry_code16, secondary_response_code16, secondary_claim_code_type17, secondary_claim_code17, secondary_date_qual17, secondary_date17, secondarymonetary_amount17, secondary_quantity17, secondary_version17, secondary_industry_code17, secondary_response_code17, secondary_claim_code_type18, secondary_claim_code18, secondary_date_qual18, secondary_date18, secondarymonetary_amount18, secondary_quantity18, secondary_version18, secondary_industry_code18, secondary_response_code18, secondary_claim_code_type19, secondary_claim_code19, secondary_date_qual19, secondary_date19, secondarymonetary_amount19, secondary_quantity19, secondary_version19, secondary_industry_code19, secondary_response_code19, secondary_claim_code_type20, secondary_claim_code20, secondary_date_qual20, secondary_date20, secondarymonetary_amount20, secondary_quantity20, secondary_version20, secondary_industry_code20, secondary_response_code20, secondary_claim_code_type21, secondary_claim_code21, secondary_date_qual21, secondary_date21, secondarymonetary_amount21, secondary_quantity21, secondary_version21, secondary_industry_code21, secondary_response_code21, secondary_claim_code_type22, secondary_claim_code22, secondary_date_qual22, secondary_date22, secondarymonetary_amount22, secondary_quantity22, secondary_version22, secondary_industry_code22, secondary_response_code22, secondary_claim_code_type23, secondary_claim_code23, secondary_date_qual23, secondary_date23, secondarymonetary_amount23, secondary_quantity23, secondary_version23, secondary_industry_code23, secondary_response_code23, secondary_claim_code_type24, secondary_claim_code24, secondary_date_qual24, secondary_date24, secondarymonetary_amount24, secondary_quantity24, secondary_version24, secondary_industry_code24, secondary_response_code24, secondary_claim_code_type25, secondary_claim_code25, secondary_date_qual25, secondary_date25, secondarymonetary_amount25, secondary_quantity25, secondary_version25, secondary_industry_code25, secondary_response_code25, secondary_claim_code_type26, secondary_claim_code26, secondary_date_qual26, secondary_date26, secondarymonetary_amount26, secondary_quantity26, secondary_version26, secondary_industry_code26, secondary_response_code26, secondary_claim_code_type27, secondary_claim_code27, secondary_date_qual27, secondary_date27, secondarymonetary_amount27, secondary_quantity27, secondary_version27, secondary_industry_code27, secondary_response_code27, secondary_claim_code_type28, secondary_claim_code28, secondary_date_qual28, secondary_date28, secondarymonetary_amount28, secondary_quantity28, secondary_version28, secondary_industry_code28, secondary_response_code28, secondary_claim_code_type29, secondary_claim_code29, secondary_date_qual29, secondary_date29, secondarymonetary_amount29, secondary_quantity29, secondary_version29, secondary_industry_code29, secondary_response_code29, secondary_claim_code_type30, secondary_claim_code30, secondary_date_qual30, secondary_date30, secondarymonetary_amount30, secondary_quantity30, secondary_version30, secondary_industry_code30, secondary_response_code30, secondary_claim_code_type31, secondary_claim_code31, secondary_date_qual31, secondary_date31, secondarymonetary_amount31, secondary_quantity31, secondary_version31, secondary_industry_code31, secondary_response_code31, secondary_claim_code_type32, secondary_claim_code32, secondary_date_qual32, secondary_date32, secondarymonetary_amount32, secondary_quantity32, secondary_version32, secondary_industry_code32, secondary_response_code32, secondary_claim_code_type33, secondary_claim_code33, secondary_date_qual33, secondary_date33, secondarymonetary_amount33, secondary_quantity33, secondary_version33, secondary_industry_code33, secondary_response_code33, secondary_claim_code_type34, secondary_claim_code34, secondary_date_qual34, secondary_date34, secondarymonetary_amount34, secondary_quantity34, secondary_version34, secondary_industry_code34, secondary_response_code34, secondary_claim_code_type35, secondary_claim_code35, secondary_date_qual35, secondary_date35, secondarymonetary_amount35, secondary_quantity35, secondary_version35, secondary_industry_code35, secondary_response_code35, secondary_claim_code_type36, secondary_claim_code36, secondary_date_qual36, secondary_date36, secondarymonetary_amount36, secondary_quantity36, secondary_version36, secondary_industry_code36, secondary_response_code36, secondary_claim_code_type37, secondary_claim_code37, secondary_date_qual37, secondary_date37, secondarymonetary_amount37, secondary_quantity37, secondary_version37, secondary_industry_code37, secondary_response_code37, secondary_claim_code_type38, secondary_claim_code38, secondary_date_qual38, secondary_date38, secondarymonetary_amount38, secondary_quantity38, secondary_version38, secondary_industry_code38, secondary_response_code38, secondary_claim_code_type39, secondary_claim_code39, secondary_date_qual39, secondary_date39, secondarymonetary_amount39, secondary_quantity39, secondary_version39, secondary_industry_code39, secondary_response_code39) FROM stdin;
\.


--
-- Data for Name: child_inst_2300_nte; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2300_nte (id, parent_id, claim_id, note_reference_code, claim_note_text) FROM stdin;
\.


--
-- Data for Name: child_inst_2300_pwk; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2300_pwk (id, parent_id, claim_id, attachment_report_type_code, attachment_transmission_code, attachment_control_number1, attachment_control_number2) FROM stdin;
\.


--
-- Data for Name: child_inst_2300_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2300_ref (id, parent_id, claim_id, reference_identification_qualifier, ref_02_code) FROM stdin;
\.


--
-- Data for Name: child_inst_2310a_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2310a_ref (id, parent_id, claim_id, attending_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2310b_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2310b_ref (id, parent_id, claim_id, operating_physician_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2310c_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2310c_ref (id, parent_id, claim_id, other_operating_physician_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2310d_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2310d_ref (id, parent_id, claim_id, rendering_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2310e_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2310e_ref (id, parent_id, claim_id, service_facility_identification_qualifier, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2310f_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2310f_ref (id, parent_id, claim_id, referring_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2320_amt; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2320_amt (id, parent_id, claim_id, amt_1, amt_2) FROM stdin;
\.


--
-- Data for Name: child_inst_2320_cas; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2320_cas (id, parent_id, claim_id, claim_adjustment_group_code1, claim_adjustment_reason_code1, claim_adjustment_amount1, claim_adjustment_quantity1, claim_adjustment_reason_code2, claim_adjustment_amount2, claim_adjustment_quantity2, claim_adjustment_reason_code3, claim_adjustment_amount3, claim_adjustment_quantity3, claim_adjustment_reason_code4, claim_adjustment_amount4, claim_adjustment_quantity4, claim_adjustment_reason_code5, claim_adjustment_amount5, claim_adjustment_quantity5, claim_adjustment_reason_code6, claim_adjustment_amount6, claim_adjustment_quantity6) FROM stdin;
\.


--
-- Data for Name: child_inst_2330b_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2330b_ref (id, parent_id, claim_id, other_payer_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2330c_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2330c_ref (id, parent_id, claim_id, other_payer_attending_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2330d_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2330d_ref (id, parent_id, claim_id, other_payer_operating_physician_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2330e_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2330e_ref (id, parent_id, claim_id, other_payer_other_operating_physician_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2330f_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2330f_ref (id, parent_id, claim_id, other_payer_service_location_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2330g_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2330g_ref (id, parent_id, claim_id, other_payer_render_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2330h_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2330h_ref (id, parent_id, claim_id, other_payer_refer_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2330i_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2330i_ref (id, parent_id, claim_id, other_payer_billing_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2400_amt; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2400_amt (id, parent_id, claim_id, amount_qualifier_code, amt_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2400_dtp; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2400_dtp (id, parent_id, claim_id, date_time_qualifier, date_time_period_format_qualifier, begin_date_of_service, end_date_of_service) FROM stdin;
\.


--
-- Data for Name: child_inst_2400_pwk; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2400_pwk (id, parent_id, claim_id, line_attachment_report_type_code1, line_attachment_transmission_code1, line_attachment_control_number_qual, line_attachment_control_number) FROM stdin;
\.


--
-- Data for Name: child_inst_2400_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2400_ref (id, parent_id, claim_id, reference_identification_qualifier, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2410_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2410_ref (id, parent_id, claim_id, prescription_drug_identification_qualifier, ref_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2420a_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2420a_ref (id, parent_id, claim_id, operating_physician_secondary_identification_qual, ref_02, ref_04_01, ref_04_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2420b_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2420b_ref (id, parent_id, claim_id, other_operating_physician_secondary_identification_qual, ref_02, ref_04_01, ref_04_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2420c_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2420c_ref (id, parent_id, claim_id, rendering_provider_secondary_identification_qual, ref_02, ref_04_01, ref_04_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2420d_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2420d_ref (id, parent_id, claim_id, referring_provider_secondary_identification_qual, ref_02, ref_04_01, ref_04_02) FROM stdin;
\.


--
-- Data for Name: child_inst_2430_cas; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_2430_cas (id, parent_id, claim_id, adjustment_group_code, adjustment_reason_code1, adjustment_amount1, adjustment_quantity1, adjustment_reason_code2, adjustment_amount2, adjustment_quantity2, adjustment_reason_code3, adjustment_amount3, adjustment_quantity3, adjustment_reason_code4, adjustment_amount4, adjustment_quantity4, adjustment_reason_code5, adjustment_amount5, adjustment_quantity5, adjustment_reason_code6, adjustment_amount6, adjustment_quantity6) FROM stdin;
\.


--
-- Data for Name: child_inst_claim_identifier_amt; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_claim_identifier_amt (id, parent_id, claim_id, amt_1, amt_2) FROM stdin;
\.


--
-- Data for Name: child_inst_claim_identifier_dtp; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_inst_claim_identifier_dtp (id, parent_id, claim_id, date_time_qualifier, date_field_type, begin_date_of_service, end_date_of_service) FROM stdin;
\.


--
-- Data for Name: child_prof_2010aa_per; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2010aa_per (id, parent_id, claim_id, billing_provider_contact_function_code, billing_provider_contact_name, billing_provider_communication_number_qualifier1, billing_provider_communication_number1, billing_provider_communication_number_qualifier2, billing_provider_communication_number2, billing_provider_communication_number_qualifier3, billing_provider_communication_number3) FROM stdin;
\.


--
-- Data for Name: child_prof_2010aa_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2010aa_ref (id, parent_id, claim_id, billing_provider_ref_identification_qualifier, billing_provider_employers_identification_number) FROM stdin;
100002267	100002266	100002259	EI	555599900
100002306	100002305	100002302	EI	650173173
100002376	100002375	100002372	EI	555555555
100002415	100002414	100002411	EI	897643616
100002452	100002451	100002448	EI	432167891
100002489	100002488	100002485	EI	555599900
100002528	100002527	100002524	EI	121313313
100002565	100002564	100002561	EI	123467891
100002603	100002602	100002599	EI	222222222
100002641	100002640	100002637	EI	555599900
100002680	100002679	100002676	EI	222222222
100002718	100002717	100002714	EI	222222222
100002756	100002755	100002752	EI	987646678
100002794	100002793	100002790	EI	987646678
100002832	100002831	100002828	EI	987646678
100002870	100002869	100002866	EI	123467890
100002908	100002907	100002904	EI	555599900
\.


--
-- Data for Name: child_prof_2010ac_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2010ac_ref (id, parent_id, claim_id, pay_to_plan_ref_identification_qual, payer_identification_number) FROM stdin;
\.


--
-- Data for Name: child_prof_2010ba_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2010ba_ref (id, parent_id, claim_id, subscriber_secondary_identification_code_qual, subscriber_supplemental_identifier) FROM stdin;
\.


--
-- Data for Name: child_prof_2010bb_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2010bb_ref (id, parent_id, claim_id, payer_secondary_identification_qual, ref_02) FROM stdin;
100002271	100002270	100002259	2U	HX96X
100002311	100002310	100002302	2U	H9999
100002380	100002379	100002372	2U	H9999
100002419	100002418	100002411	2U	H9999
100002456	100002455	100002448	2U	H9999
100002493	100002492	100002485	2U	H9999
100002532	100002531	100002524	2U	H9999
100002569	100002568	100002561	2U	H9999
100002607	100002606	100002599	2U	H9999
100002645	100002644	100002637	2U	H9999
100002684	100002683	100002676	2U	H9999
100002722	100002721	100002714	2U	H9999
100002761	100002760	100002752	2U	H9999
100002799	100002798	100002790	2U	H9999
100002837	100002836	100002828	2U	H9999
100002874	100002873	100002866	2U	H9999
100002912	100002911	100002904	2U	H9999
\.


--
-- Data for Name: child_prof_2300_crc; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2300_crc (id, parent_id, claim_id, ambulance_certification_code, crc_02, crc_03, crc_04, crc_05, crc_06, crc_07) FROM stdin;
\.


--
-- Data for Name: child_prof_2300_dtp; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2300_dtp (id, parent_id, claim_id, date_time_qualifier, date_time_period_format_qualifier, dtp_03) FROM stdin;
100002272	100002263	100002259	435	D8	20210228
100002273	100002263	100002259	096	D8	20810228
100002312	100002304	100002302	435	D8	20210811
100002381	100002374	100002372	435	D8	20210627
100002382	100002374	100002372	096	D8	20210828
100002420	100002413	100002411	435	D8	20480611
100002457	100002450	100002448	435	D8	21080822
100002458	100002450	100002448	096	D8	20210822
100002494	100002487	100002485	435	D8	20210816
100002495	100002487	100002485	096	D8	20480816
100002533	100002526	100002524	435	D8	21080818
100002570	100002563	100002561	435	D8	20780709
100002608	100002601	100002599	435	D8	21080731
100002646	100002639	100002637	435	D8	20190919
100002647	100002639	100002637	096	D8	20190919
100002685	100002678	100002676	435	D8	21080907
100002723	100002716	100002714	435	D8	21081007
100002762	100002754	100002752	435	D8	20191230
100002800	100002792	100002790	435	D8	20191230
100002838	100002830	100002828	435	D8	20191230
100002875	100002868	100002866	435	D8	20190204
100002876	100002868	100002866	096	D8	20490204
100002913	100002906	100002904	435	D8	20190919
100002914	100002906	100002904	096	D8	20190319
\.


--
-- Data for Name: child_prof_2300_hi; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2300_hi (id, parent_id, claim_id, primary_claim_code_type, primary_claim_code, secondary_claim_code_type1, secondary_claim_code1, secondary_claim_code_type2, secondary_claim_code2, secondary_claim_code_type3, secondary_claim_code3, secondary_claim_code_type4, secondary_claim_code4, secondary_claim_code_type5, secondary_claim_code5, secondary_claim_code_type6, secondary_claim_code6, secondary_claim_code_type7, secondary_claim_code7, secondary_claim_code_type8, secondary_claim_code8, secondary_claim_code_type9, secondary_claim_code9, secondary_claim_code_type10, secondary_claim_code10, secondary_claim_code_type11, secondary_claim_code11, secondary_claim_code_type12, secondary_claim_code12, secondary_claim_code_type13, secondary_claim_code13, secondary_claim_code_type14, secondary_claim_code14, secondary_claim_code_type15, secondary_claim_code15, secondary_claim_code_type16, secondary_claim_code16, secondary_claim_code_type17, secondary_claim_code17, secondary_claim_code_type18, secondary_claim_code18, secondary_claim_code_type19, secondary_claim_code19, secondary_claim_code_type20, secondary_claim_code20, secondary_claim_code_type21, secondary_claim_code21, secondary_claim_code_type22, secondary_claim_code22, secondary_claim_code_type23, secondary_claim_code23, secondary_claim_code_type24, secondary_claim_code24, secondary_claim_code_type25, secondary_claim_code25, secondary_claim_code_type26, secondary_claim_code26, secondary_claim_code_type27, secondary_claim_code27, secondary_claim_code_type28, secondary_claim_code28, secondary_claim_code_type29, secondary_claim_code29, secondary_claim_code_type30, secondary_claim_code30, secondary_claim_code_type31, secondary_claim_code31, secondary_claim_code_type32, secondary_claim_code32, secondary_claim_code_type33, secondary_claim_code33, secondary_claim_code_type34, secondary_claim_code34, secondary_claim_code_type35, secondary_claim_code35, secondary_claim_code_type36, secondary_claim_code36, secondary_claim_code_type37, secondary_claim_code37, secondary_claim_code_type38, secondary_claim_code38, secondary_claim_code_type39, secondary_claim_code39) FROM stdin;
100002277	100002263	100002259	ABK	K222	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002316	100002304	100002302	ABK	P9601	ABF	P189	ABF	I2699	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002386	100002374	100002372	ABK	R0600	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002423	100002413	100002411	ABK	I509	ABF	I2510	ABF	R079	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002462	100002450	100002448	ABK	C44229	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002499	100002487	100002485	ABK	R1310	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002537	100002526	100002524	ABK	I63432	ABF	Z9282	ABF	I480	ABF	H53461	ABF	R4701	ABF	G8191	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002574	100002563	100002561	ABK	I350	ABF	I340	ABF	I5043	ABF	I4891	ABF	N184	ABF	I10	ABF	R0602	ABF	P90	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002612	100002601	100002599	ABK	G8918	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002651	100002639	100002637	ABK	R1310	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002689	100002678	100002676	ABK	I4891	ABF	E785	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002727	100002716	100002714	ABK	S72001A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002765	100002754	100002752	ABK	S72142A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002803	100002792	100002790	ABK	S72142A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002841	100002830	100002828	ABK	S72142A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002879	100002868	100002866	ABK	I2720	ABF	R0609	ABF	G4733	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002918	100002906	100002904	ABK	K210	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: child_prof_2300_pwk; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2300_pwk (id, parent_id, claim_id, attachment_report_type_code, attachment_transmission_code, attachment_control_number1, attachment_control_number2) FROM stdin;
100002274	100002263	100002259	OZ	AA	\N	\N
100002313	100002304	100002302	OZ	AA	\N	\N
100002383	100002374	100002372	OZ	AA	\N	\N
100002421	100002413	100002411	OZ	AA	\N	\N
100002459	100002450	100002448	OZ	AA	\N	\N
100002496	100002487	100002485	OZ	AA	\N	\N
100002534	100002526	100002524	OZ	AA	\N	\N
100002571	100002563	100002561	OZ	AA	\N	\N
100002609	100002601	100002599	OZ	AA	\N	\N
100002648	100002639	100002637	OZ	AA	\N	\N
100002686	100002678	100002676	OZ	AA	\N	\N
100002724	100002716	100002714	OZ	AA	\N	\N
100002877	100002868	100002866	OZ	AA	\N	\N
100002915	100002906	100002904	OZ	AA	\N	\N
\.


--
-- Data for Name: child_prof_2300_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2300_ref (id, parent_id, claim_id, reference_identification_qualifier, ref_02_code) FROM stdin;
100002275	100002263	100002259	G1	180540042
100002276	100002263	100002259	D9	180746130000258ARS
100002314	100002304	100002302	G1	HOSP AUTHH
100002315	100002304	100002302	D9	181976190000108ARM
100002384	100002374	100002372	G1	1806080070
100002385	100002374	100002372	D9	181996130000308ARS
100002422	100002413	100002411	D9	1820861R0000648ARS
100002460	100002450	100002448	G1	182320064
100002461	100002450	100002448	D9	1823961R0001578ARS
100002497	100002487	100002485	G1	182250009
100002498	100002487	100002485	D9	182476130001488ARS
100002535	100002526	100002524	G1	182320059
100002536	100002526	100002524	D9	182536130000058ARS
100002572	100002563	100002561	G1	181920010
100002573	100002563	100002561	D9	182556190000118ARM
100002610	100002601	100002599	G1	L81940005S
100002611	100002601	100002599	D9	182646130000938ARS
100002649	100002639	100002637	G1	182600053
100002650	100002639	100002637	D9	182716190000388ARM
100002687	100002678	100002676	G1	182530012I
100002688	100002678	100002676	D9	182836130000688ARS
100002725	100002716	100002714	G1	170020016I
100002726	100002716	100002714	D9	183136130000208ARS
100002763	100002754	100002752	G1	183650032
100002764	100002754	100002752	D9	010419762949571
100002801	100002792	100002790	G1	183650032
100002802	100002792	100002790	D9	010419762949575
100002839	100002830	100002828	G1	183650032
100002840	100002830	100002828	D9	010419762949568
100002878	100002868	100002866	D9	190506130001218ARS
100002916	100002906	100002904	G1	190600007
100002917	100002906	100002904	D9	1909261R0000278ARS
\.


--
-- Data for Name: child_prof_2310a_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2310a_ref (id, parent_id, claim_id, referring_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2310b_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2310b_ref (id, parent_id, claim_id, rendering_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2310c_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2310c_ref (id, parent_id, claim_id, service_facility_identification_qualifier, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2310d_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2310d_ref (id, parent_id, claim_id, supervising_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2320_amt; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2320_amt (id, parent_id, claim_id, amt_1, amt_2) FROM stdin;
100002283	100002281	100002259	D	86.51
100002321	100002319	100002302	D	370.60
100002392	100002390	100002372	D	9.17
100002429	100002427	100002411	D	104.47
100002466	100002464	100002448	D	778.72
100002505	100002503	100002485	D	110.30
100002542	100002540	100002524	D	85.50
100002580	100002578	100002561	D	39.43
100002618	100002616	100002599	D	68.40
100002657	100002655	100002637	D	110.30
100002695	100002693	100002676	D	132.36
100002733	100002731	100002714	D	330.90
100002771	100002769	100002752	D	1275.06
100002809	100002807	100002790	D	116.80
100002847	100002845	100002828	D	173.41
100002884	100002882	100002866	D	87.26
100002924	100002922	100002904	D	110.69
\.


--
-- Data for Name: child_prof_2320_cas; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2320_cas (id, parent_id, claim_id, claim_adjustment_group_code1, claim_adjustment_reason_code1, claim_adjustment_amount1, claim_adjustment_quantity1, claim_adjustment_reason_code2, claim_adjustment_amount2, claim_adjustment_quantity2, claim_adjustment_reason_code3, claim_adjustment_amount3, claim_adjustment_quantity3, claim_adjustment_reason_code4, claim_adjustment_amount4, claim_adjustment_quantity4, claim_adjustment_reason_code5, claim_adjustment_amount5, claim_adjustment_quantity5, claim_adjustment_reason_code6, claim_adjustment_amount6, claim_adjustment_quantity6) FROM stdin;
\.


--
-- Data for Name: child_prof_2330b_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2330b_ref (id, parent_id, claim_id, other_payer_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2330c_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2330c_ref (id, parent_id, claim_id, other_payer_refer_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2330d_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2330d_ref (id, parent_id, claim_id, other_payer_render_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2330e_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2330e_ref (id, parent_id, claim_id, other_payer_svc_location_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2330f_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2330f_ref (id, parent_id, claim_id, other_payer_spvc_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2330g_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2330g_ref (id, parent_id, claim_id, other_payer_billing_provider_secondary_identification_qual, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2400_amt; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2400_amt (id, parent_id, claim_id, amount_qualifier_code, amt_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2400_crc; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2400_crc (id, parent_id, claim_id, certification_code, crc_02, crc_03, crc_04, crc_05, crc_06, crc_07) FROM stdin;
\.


--
-- Data for Name: child_prof_2400_dtp; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2400_dtp (id, parent_id, claim_id, date_time_qualifier, date_field_type, begin_date_of_service, end_date_of_service) FROM stdin;
100002300	100002289	100002259	472	RD8	20210228	20180228
100002338	100002327	100002302	472	RD8	20210613	20180613
100002354	100002343	100002302	472	RD8	20210611	20180611
100002370	100002359	100002302	472	RD8	20210612	20180612
100002409	100002398	100002372	472	RD8	20210628	20180628
100002446	100002435	100002411	472	RD8	20210613	20180613
100002483	100002472	100002448	472	RD8	20210822	20180822
100002522	100002511	100002485	472	RD8	20210816	20180816
100002559	100002548	100002524	472	RD8	20210820	20180820
100002597	100002586	100002561	472	RD8	20210729	20180729
100002635	100002624	100002599	472	RD8	20210731	20180731
100002674	100002663	100002637	472	RD8	20210919	20180919
100002712	100002701	100002676	472	RD8	20210911	20180911
100002750	100002739	100002714	472	RD8	20211008	20181008
100002788	100002777	100002752	472	RD8	20211230	20181230
100002826	100002815	100002790	472	RD8	20211230	20181230
100002864	100002853	100002828	472	RD8	20211230	20181230
100002901	100002890	100002866	472	RD8	20190204	20190204
100002941	100002930	100002904	472	RD8	20190319	20190319
\.


--
-- Data for Name: child_prof_2400_k3; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2400_k3 (id, parent_id, claim_id, fixed_format_information) FROM stdin;
\.


--
-- Data for Name: child_prof_2400_mea; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2400_mea (id, parent_id, claim_id, test_measurement_reference_id_code, test_measurement_qualifier, test_results) FROM stdin;
\.


--
-- Data for Name: child_prof_2400_nte; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2400_nte (id, parent_id, claim_id, note_reference_code, nte_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2400_pwk; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2400_pwk (id, parent_id, claim_id, line_attachment_report_type_code1, line_attachment_transmission_code1, line_attachment_control_number_qual, line_attachment_control_number) FROM stdin;
\.


--
-- Data for Name: child_prof_2400_qty; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2400_qty (id, parent_id, claim_id, ambulance_patients_quantity_qualifier, qty_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2400_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2400_ref (id, parent_id, claim_id, reference_identification_qualifier, ref_02, payer_identification_number, other_payer_primary_identifier) FROM stdin;
\.


--
-- Data for Name: child_prof_2410_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2410_ref (id, parent_id, claim_id, prescription_drug_identification_qualifier, ref_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2420a_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2420a_ref (id, parent_id, claim_id, rendering_provider_secondary_identification_qual, ref_02, ref_04_01, ref_04_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2420b_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2420b_ref (id, parent_id, claim_id, purchased_svc_provider_secondary_identification_qual, ref_02, ref_04_01, ref_04_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2420c_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2420c_ref (id, parent_id, claim_id, service_facility_identification_qualifier, ref_02, ref_04_01, ref_04_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2420d_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2420d_ref (id, parent_id, claim_id, supervising_provider_secondary_identification_qual, ref_02, ref_04_01, ref_04_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2420e_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2420e_ref (id, parent_id, claim_id, ordering_provider_secondary_identification_qual, ref_02, ref_04_01, ref_04_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2420f_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2420f_ref (id, parent_id, claim_id, referring_provider_secondary_identification_qual, ref_02, ref_04_01, ref_04_02) FROM stdin;
\.


--
-- Data for Name: child_prof_2430_cas; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_2430_cas (id, parent_id, claim_id, adjustment_group_code, adjustment_reason_code1, adjustment_amount1, adjustment_quantity1, adjustment_reason_code2, adjustment_amount2, adjustment_quantity2, adjustment_reason_code3, adjustment_amount3, adjustment_quantity3, adjustment_reason_code4, adjustment_amount4, adjustment_quantity4, adjustment_reason_code5, adjustment_amount5, adjustment_quantity5, adjustment_reason_code6, adjustment_amount6, adjustment_quantity6) FROM stdin;
100002301	100002297	100002259	CO	45	363.49	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002339	100002335	100002302	CO	45	175.34	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002355	100002351	100002302	CO	45	77.03	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002371	100002367	100002302	CO	45	77.03	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002410	100002406	100002372	CO	45	15.83	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002447	100002443	100002411	CO	45	75.53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002484	100002480	100002448	CO	45	901.28	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002523	100002519	100002485	CO	45	339.7	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002560	100002556	100002524	CO	45	64.5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002598	100002594	100002561	CO	45	50.57	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002636	100002632	100002599	CO	45	135.6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002675	100002671	100002637	CO	45	414.7	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002713	100002709	100002676	CO	45	680.14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002751	100002747	100002714	CO	45	1256.6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002789	100002785	100002752	CO	45	5192.94	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002827	100002823	100002790	CO	45	571.2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002865	100002861	100002828	CO	45	426.59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002902	100002898	100002866	PR	3	20	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002903	100002898	100002866	CO	45	36.74	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002942	100002938	100002904	CO	45	414.31	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: child_prof_claim_identifier_amt; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_claim_identifier_amt (id, parent_id, claim_id, amt_1, amt_2) FROM stdin;
100002282	100002259	100002259	D	86.51
100002320	100002302	100002302	D	370.6
100002391	100002372	100002372	D	9.17
100002428	100002411	100002411	D	104.47
100002465	100002448	100002448	D	778.72
100002504	100002485	100002485	D	110.3
100002541	100002524	100002524	D	85.5
100002579	100002561	100002561	D	39.43
100002617	100002599	100002599	D	68.4
100002656	100002637	100002637	D	110.3
100002694	100002676	100002676	D	132.36
100002732	100002714	100002714	D	330.9
100002770	100002752	100002752	D	1275.06
100002808	100002790	100002790	D	116.8
100002846	100002828	100002828	D	173.41
100002883	100002866	100002866	D	87.26
100002923	100002904	100002904	D	110.69
\.


--
-- Data for Name: child_prof_claim_identifier_dtp; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_prof_claim_identifier_dtp (id, parent_id, claim_id, date_time_qualifier, date_field_type, begin_date_of_service, end_date_of_service) FROM stdin;
100002299	100002259	100002259	472	RD8	20210228	20180228
100002337	100002302	100002302	472	RD8	20210613	20180613
100002353	100002302	100002302	472	RD8	20210611	20180611
100002369	100002302	100002302	472	RD8	20210612	20180612
100002408	100002372	100002372	472	RD8	20210628	20180628
100002445	100002411	100002411	472	RD8	20210613	20180613
100002482	100002448	100002448	472	RD8	20210822	20180822
100002521	100002485	100002485	472	RD8	20210816	20180816
100002558	100002524	100002524	472	RD8	20210820	20180820
100002596	100002561	100002561	472	RD8	20210729	20180729
100002634	100002599	100002599	472	RD8	20210731	20180731
100002673	100002637	100002637	472	RD8	20210919	20180919
100002711	100002676	100002676	472	RD8	20210911	20180911
100002749	100002714	100002714	472	RD8	20211008	20181008
100002787	100002752	100002752	472	RD8	20211230	20181230
100002825	100002790	100002790	472	RD8	20211230	20181230
100002863	100002828	100002828	472	RD8	20211230	20181230
100002900	100002866	100002866	472	RD8	20190204	20190204
100002940	100002904	100002904	472	RD8	20190319	20190319
\.


--
-- Data for Name: child_raps_cms_tracking_raps_resp; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_raps_cms_tracking_raps_resp (id, parent_id, file_status, file_processed_status, file_url, response_type, manual_update_comment, retry_count, last_updated, db_load_timestamp) FROM stdin;
\.


--
-- Data for Name: child_raps_feras_error_raps_resp; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_raps_feras_error_raps_resp (id, parent_id, feras_error_record, feras_error_sequence, feras_error_code, feras_error_description) FROM stdin;
\.


--
-- Data for Name: child_remit_1000a_per; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_1000a_per (id, parent_id, contact_function_code, payer_contact_name, communication_number_qualifier, payer_contact_communication_number, communication_number_qualifier_5, payer_contact_communication_number_6, communication_number_qualifier_7, payer_contact_communication_number_8, contact_inquiry_reference) FROM stdin;
\.


--
-- Data for Name: child_remit_1000a_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_1000a_ref (id, parent_id, reference_identification_qualifier, additional_payer_identifier, description, reference_identifier) FROM stdin;
\.


--
-- Data for Name: child_remit_2100_amt; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2100_amt (id, parent_id, remittance_id, amount_qualifier_code, claim_supplemental_information_amount, credit_debit_flag_code) FROM stdin;
\.


--
-- Data for Name: child_remit_2100_cas; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2100_cas (id, parent_id, remittance_id, claim_adjustment_group_code1, adjustment_reason_code1, adjustment_amount1, adjustment_quantity1, adjustment_reason_code2, adjustment_amount2, adjustment_quantity2, adjustment_reason_code3, adjustment_amount3, adjustment_quantity3, adjustment_reason_code4, adjustment_amount4, adjustment_quantity4, adjustment_reason_code5, adjustment_amount5, adjustment_quantity5, adjustment_reason_code6, adjustment_amount6, adjustment_quantity6) FROM stdin;
\.


--
-- Data for Name: child_remit_2100_dtm; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2100_dtm (id, parent_id, remittance_id, date_time_qualifier, claim_date, "time", time_code, date_time_period_format_qualifier, date_time_period) FROM stdin;
\.


--
-- Data for Name: child_remit_2100_nm1; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2100_nm1 (id, parent_id, remittance_id, entity_identifier_code, entity_type_qualifier, patient_last_name, patient_first_name, patient_middle_name_or_initial, name_prefix, patient_name_suffix, identification_code_qualifier, patient_identifier, entity_relationship_code, entity_identifier_code_11, name_last_org_name) FROM stdin;
\.


--
-- Data for Name: child_remit_2100_per; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2100_per (id, parent_id, remittance_id, contact_function_code, claim_contact_name, communication_number_qualifier, claim_contact_communications_number, communication_number_qualifier_5, claim_contact_communications_number_6, communication_number_qualifier_7, communication_number_extension, contact_inquiry_reference) FROM stdin;
\.


--
-- Data for Name: child_remit_2100_qty; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2100_qty (id, parent_id, remittance_id, quantity_qualifier, claim_supplemental_information_quantity, composite_unit_of_measure, free_form_information) FROM stdin;
\.


--
-- Data for Name: child_remit_2100_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2100_ref (id, parent_id, remittance_id, reference_identification_qualifier, other_claim_related_identifier, description, reference_identifier, reference_identification_qualifier_1, rendering_provider_secondary_identifier, description_3, reference_identifier_4) FROM stdin;
\.


--
-- Data for Name: child_remit_2110_amt; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2110_amt (id, parent_id, remittance_id, amount_qualifier_code, service_supplemental_amount, credit_debit_flag_code) FROM stdin;
\.


--
-- Data for Name: child_remit_2110_cas; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2110_cas (id, parent_id, remittance_id, claim_adjustment_group_code, adjustment_reason_code1, adjustment_amount1, adjustment_quantity1, adjustment_reason_code2, adjustment_amount2, adjustment_quantity2, adjustment_reason_code3, adjustment_amount3, adjustment_quantity3, adjustment_reason_code4, adjustment_amount4, adjustment_quantity4, adjustment_reason_code5, adjustment_amount5, adjustment_quantity5, adjustment_reason_code6, adjustment_amount6, adjustment_quantity6) FROM stdin;
\.


--
-- Data for Name: child_remit_2110_dtm; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2110_dtm (id, parent_id, remittance_id, date_time_qualifier, service_date, "time", time_code, date_time_period_format_qualifier, date_time_period) FROM stdin;
\.


--
-- Data for Name: child_remit_2110_lq; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2110_lq (id, parent_id, remittance_id, code_list_qualifier_code, remark_code) FROM stdin;
\.


--
-- Data for Name: child_remit_2110_qty; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2110_qty (id, parent_id, remittance_id, quantity_qualifier, service_supplemental_quantity_count, composite_unit_of_measure, free_form_information) FROM stdin;
\.


--
-- Data for Name: child_remit_2110_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_2110_ref (id, parent_id, remittance_id, reference_identification_qualifier, provider_identifier, description_3, reference_identifier) FROM stdin;
\.


--
-- Data for Name: child_remit_bht_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_bht_ref (id, parent_id, reference_identification_qualifier, receiver_identifier, description, reference_identifier) FROM stdin;
\.


--
-- Data for Name: child_remit_identifier_nm1; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_remit_identifier_nm1 (id, parent_id, remittance_id, entity_identifier_code, patient_identifier) FROM stdin;
\.


--
-- Data for Name: child_resp_277_2000b_amt; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_resp_277_2000b_amt (id, parent_id, total_accepted_amount) FROM stdin;
100000018	100000014	725
100000019	100000014	14554
\.


--
-- Data for Name: child_resp_277_2000b_qty; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_resp_277_2000b_qty (id, parent_id, accepted_claim_quantity) FROM stdin;
100000016	100000014	2
100000017	100000014	15
\.


--
-- Data for Name: child_resp_277_2000d_dtp; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_resp_277_2000d_dtp (id, parent_id, date_time_qualifier, date_field_type, begin_date_of_service, end_date_of_service) FROM stdin;
100000022	100000015	472	D8	20180228	\N
100000029	100000024	472	RD8	20180611	20180613
100000036	100000031	472	D8	20180628	\N
100000042	100000038	472	D8	20180613	\N
100000048	100000044	472	D8	20180822	\N
100000054	100000050	472	D8	20180816	\N
100000060	100000056	472	D8	20180820	\N
100000066	100000062	472	D8	20180729	\N
100000072	100000068	472	D8	20180731	\N
100000079	100000074	472	D8	20180919	\N
100000085	100000081	472	D8	20180911	\N
100000091	100000087	472	D8	20181008	\N
100000097	100000093	472	D8	20181230	\N
100000103	100000099	472	D8	20181230	\N
100000109	100000105	472	D8	20181230	\N
100000115	100000111	472	D8	20190204	\N
100000121	100000117	472	D8	20190319	\N
\.


--
-- Data for Name: child_resp_277_2000d_ref; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_resp_277_2000d_ref (id, parent_id, qual, ref_02) FROM stdin;
100000021	100000015	D9	180746130000258ARS
100000027	100000024	1K	1925541686087
100000028	100000024	D9	181976190000108ARM
100000034	100000031	1K	1925541686091
100000035	100000031	D9	181996130000308ARS
100000041	100000038	D9	1820861R0000648ARS
100000047	100000044	D9	1823961R0001578ARS
100000053	100000050	D9	182476130001488ARS
100000059	100000056	D9	182536130000058ARS
100000065	100000062	D9	182556190000118ARM
100000071	100000068	D9	182646130000938ARS
100000078	100000074	D9	182716190000388ARM
100000084	100000081	D9	182836130000688ARS
100000090	100000087	D9	183136130000208ARS
100000096	100000093	D9	010419762949571
100000102	100000099	D9	010419762949575
100000108	100000105	D9	010419762949568
100000114	100000111	D9	190506130001218ARS
100000120	100000117	D9	1909261R0000278ARS
\.


--
-- Data for Name: child_resp_277_2000d_stc; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_resp_277_2000d_stc (id, parent_id, billing_provider_status, full_status_code, status_code, secondary_status_code, tertiary_status_code) FROM stdin;
100000020	100000015	U	A7:510	A7	A7:190	\N
100000026	100000024	WQ	A2:20:PR	A2	\N	\N
100000033	100000031	WQ	A2:20:PR	A2	\N	\N
100000040	100000038	U	A7:510	A7	A7:189	\N
100000046	100000044	U	A7:510	A7	A7:189	\N
100000052	100000050	U	A7:510	A7	A7:190	\N
100000058	100000056	U	A7:510	A7	A7:189	\N
100000064	100000062	U	A7:510	A7	A7:189	\N
100000070	100000068	U	A7:510	A7	A7:189	\N
100000076	100000074	U	A7:510	A7	A7:189	\N
100000077	100000074	U	A7:510	A7	A7:190	\N
100000083	100000081	U	A7:510	A7	A7:189	\N
100000089	100000087	U	A7:510	A7	A7:189	\N
100000095	100000093	U	A7:510	A7	A7:189	\N
100000101	100000099	U	A7:510	A7	A7:189	\N
100000107	100000105	U	A7:510	A7	A7:189	\N
100000113	100000111	U	A7:510	A7	A7:190	\N
100000119	100000117	U	A7:510	A7	A7:189	\N
\.


--
-- Data for Name: child_resp_277_2220d_stc; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_resp_277_2220d_stc (id, parent_id, full_status_code, status_reject_code, secondary_status_code, tertiary_status_code) FROM stdin;
\.


--
-- Data for Name: child_resp_999_2100_ik4; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_resp_999_2100_ik4 (id, parent_id, element_position_in_segment, component_data_element_position, element_error_code) FROM stdin;
\.


--
-- Data for Name: child_x12file_resp_file; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_x12file_resp_file (id, parent_id, h_plan_id, file_name, file_url, response_file_type, total_encounters, error_code, duplicate_st_se_submission, duplicate_file_id_submission, response_date, applied_status, file_processed_status, manual_update_comment, retry_count, last_updated, db_load_timestamp, file_hash) FROM stdin;
100000003	1	1	TA1	/Users/menacher/dev/ras-data/EDPS/DEFAULT_ACCOUNT/HX96X/history/TO_BE_PROCESSED/TA1	TA1	\N	\N	\N	\N	\N	\N	PROCESSED	\N	0	\N	2022-11-14 02:05:38.29459	395e3c4a1e9ee4d200b9fe5e8cff9469
100000001	100000002	2	999R.ENC0001.LEA01.TXT.D1190912.T153304.U330431	/Users/menacher/dev/ras-data/EDPS/DEFAULT_ACCOUNT/HX96X/history/TO_BE_PROCESSED/999R.ENC0001.LEA01.TXT.D1190912.T153304.U330431	999	\N	\N	\N	\N	\N	APPLIED_999	PROCESSED	\N	1	2022-11-13 21:06:11.634895	2022-11-14 02:05:36.47995	d3c8c7d49876e081ad283c5f4ef322c7
100000000	100000002	2	277CA.ENC0001.LEA01.TXT.D1190912.T153258.U325807	/Users/menacher/dev/ras-data/EDPS/DEFAULT_ACCOUNT/HX96X/history/TO_BE_PROCESSED/277CA.ENC0001.LEA01.TXT.D1190912.T153258.U325807	277	\N	\N	\N	\N	\N	APPLIED_277	PROCESSED	\N	1	\N	2022-11-14 02:05:35.455417	abd0e211fb36a14366f77f4ceac4f490
100001243	100000002	2	DATA.PROC.STAT.RP.ENC0001.D1190912.T234748.U474865	/Users/menacher/dev/ras-data/EDPS/DEFAULT_ACCOUNT/HX96X/history/TO_BE_PROCESSED/DATA.PROC.STAT.RP.ENC0001.D1190912.T234748.U474865	MAO-002	\N	\N	\N	\N	\N	APPLIED_MAO2	PROCESSED	\N	1	2022-11-13 21:06:11.984906	2022-11-14 02:05:36.324733	5247e47bb17d68fd201670575c215d05
100000243	100000002	2	DATA.DUPE.RP.ENC0001.D1180213.T223113.U311329	/Users/menacher/dev/ras-data/EDPS/DEFAULT_ACCOUNT/HX96X/history/TO_BE_PROCESSED/DATA.DUPE.RP.ENC0001.D1180213.T223113.U311329	MAO-001	\N	\N	\N	\N	\N	APPLIED_MAO1	PROCESSED	\N	1	2022-11-13 21:06:12.047412	2022-11-14 02:05:36.152014	94bdad35c0fd78e5482bd415a27d18e4
\.


--
-- Data for Name: child_x12file_x12shards; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.child_x12file_x12shards (id, parent_id, shard_file_name, shard_file_input_location, shard_file_st_index, shard_file_processed_status) FROM stdin;
\.


--
-- Data for Name: claim_error; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.claim_error (id, resp_file_id, plan_id, claim_id, claim_line_id, error_ref_id, error_internal_relation_name, error_code) FROM stdin;
100006645	100000000	HX96X	100002259	0	5194	XREF_CLAIM_ERROR_277	5194
100006646	100000000	H9999	100002411	0	5193	XREF_CLAIM_ERROR_277	5193
100006647	100000000	H9999	100002448	0	5193	XREF_CLAIM_ERROR_277	5193
100006648	100000000	H9999	100002485	0	5194	XREF_CLAIM_ERROR_277	5194
100006649	100000000	H9999	100002524	0	5193	XREF_CLAIM_ERROR_277	5193
100006650	100000000	H9999	100002561	0	5193	XREF_CLAIM_ERROR_277	5193
100006651	100000000	H9999	100002599	0	5193	XREF_CLAIM_ERROR_277	5193
100006652	100000000	H9999	100002637	0	5193	XREF_CLAIM_ERROR_277	5193
100006653	100000000	H9999	100002637	0	5194	XREF_CLAIM_ERROR_277	5194
100006654	100000000	H9999	100002676	0	5193	XREF_CLAIM_ERROR_277	5193
100006655	100000000	H9999	100002714	0	5193	XREF_CLAIM_ERROR_277	5193
100006656	100000000	H9999	100002752	0	5193	XREF_CLAIM_ERROR_277	5193
100006657	100000000	H9999	100002790	0	5193	XREF_CLAIM_ERROR_277	5193
100006658	100000000	H9999	100002828	0	5193	XREF_CLAIM_ERROR_277	5193
100006659	100000000	H9999	100002866	0	5194	XREF_CLAIM_ERROR_277	5194
100006660	100000000	H9999	100002904	0	5193	XREF_CLAIM_ERROR_277	5193
100006661	100001243	H9999	100002302	0	100001244	RESP_MAO_2	\N
100006665	100001243	H9999	100002372	0	100001248	RESP_MAO_2	02110
100006662	100001243	H9999	100002302	100002327	100001245	RESP_MAO_2	98325
100006667	100000243	H9999	100002302	100002327	100000244	RESP_MAO_1	98325
100006663	100001243	H9999	100002302	100002343	100001246	RESP_MAO_2	98325
100006668	100000243	H9999	100002302	100002343	100000245	RESP_MAO_1	98325
100006664	100001243	H9999	100002302	100002359	100001247	RESP_MAO_2	98325
100006669	100000243	H9999	100002302	100002359	100000246	RESP_MAO_1	98325
100006666	100001243	H9999	100002372	100002398	100001249	RESP_MAO_2	\N
\.


--
-- Data for Name: cms_submitter_info; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.cms_submitter_info (id, a_id, cms_provided_id, x12_file_number, product_name, date_created, last_updated, active) FROM stdin;
1	2	ENC0001	10000	EDPS	2022-11-14 01:29:31.331038	2022-11-14 01:29:31.331038	t
3	2	ENC1234	10000	EDPS	2022-11-14 01:29:31.341296	2022-11-14 01:29:31.341296	f
2	2	SHXXXX	50000	RAPS	2022-11-14 01:29:31.350338	2022-11-14 01:29:31.350338	t
\.


--
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.customer (id, date_created, last_updated, name, description) FROM stdin;
1	2022-11-14 01:29:14.887634	2022-11-14 01:29:14.887634	SYSTEM	\N
100000000	2022-11-14 01:29:31.292659	2022-11-14 01:29:31.292659	DEFAULT_CUSTOMER	\N
\.


--
-- Data for Name: customer_account; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.customer_account (id, customer_id, parent_account_id, date_created, last_updated, modified_by, name, description, status) FROM stdin;
1	1	\N	2022-11-14 01:29:14.901178	2022-11-14 01:29:14.901178	\N	SYSTEM_ACCOUNT	\N	\N
2	100000000	\N	2022-11-14 01:29:31.304145	2022-11-14 01:29:31.304145	\N	DEFAULT_ACCOUNT	\N	\N
\.


--
-- Data for Name: databasechangelog; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.databasechangelog (id, author, filename, dateexecuted, orderexecuted, exectype, md5sum, description, comments, tag, liquibase, contexts, labels, deployment_id) FROM stdin;
\.


--
-- Data for Name: databasechangeloglock; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.databasechangeloglock (id, locked, lockgranted, lockedby) FROM stdin;
1	f	\N	\N
\.


--
-- Data for Name: flow; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.flow (id, name, status, created_by, linked_orig_flow, additional_info, date_created, last_updated) FROM stdin;
\.


--
-- Data for Name: flow_item; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.flow_item (id, flow_id, flow_status, item_type, step_name, step_status, next_run_time, date_created, additional_info, other_obj_id, other_rel_name, future1, step_config, step_context) FROM stdin;
\.


--
-- Data for Name: flow_item_history; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.flow_item_history (id, flow_item_id, flow_status, item_type, step_name, step_status, processed_at, additional_info, other_obj_id, other_rel_name, future1, step_config, step_context) FROM stdin;
\.


--
-- Data for Name: global_ticker; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.global_ticker (id, name, ticker) FROM stdin;
1	ras	100006669
\.


--
-- Data for Name: h_plan_config; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.h_plan_config (id, h_plan_id, key, value) FROM stdin;
4	2	PLAN_FILE_SOURCE	/Users/menacher/dev/ras-data/edps/DEFAULT_ACCOUNT/HX96X/history/to_be_processed
5	2	PLAN_NEW_FILE_SOURCE	/Users/menacher/dev/ras-data/edps/DEFAULT_ACCOUNT/HX96X/regular/to_be_processed
6	2	GENERATED_FILE_SOURCE	/Users/menacher/dev/ras-data/edps/DEFAULT_ACCOUNT/HX96X/regular/generated
7	2	PROVIDER_FILE_SOURCE	/Users/menacher/dev/ras-data/edps/DEFAULT_ACCOUNT/HX96X/provider/to_be_processed
8	2	PROVIDER_HISTORY_FILE_SOURCE	/Users/menacher/dev/ras-data/edps/DEFAULT_ACCOUNT/HX96X/provider/history/to_be_processed
9	2	SUBMISSION_FILE_DEPOSIT	/Users/menacher/dev/ras-data/edps/DEFAULT_ACCOUNT/HX96X/cms/to_be_submitted
10	2	PATIENT_CONTROL_NUMBER_PREFIX	ABC
11	2	L_2320_SBR_3	ABC0001
12	2	L_2330A_NM1_8	MI
13	2	L_2330B_NM1_3	Internal Plans
14	2	L_2330B_NM1_8	XV
15	2	L_2330B_NM1_9	HX96X
16	2	L_2330B_N3_1	Master bld
17	2	L_2330B_N3_2	Apt 20
18	2	L_2330B_N4_1	Wesley
19	2	L_2330B_N4_2	WI
20	2	L_2330B_N4_3	123459998
22	2	RAPS_REGULAR_FILE_SOURCE	/Users/menacher/dev/ras-data/raps/DEFAULT_ACCOUNT/HX96X/regular/to_be_processed
23	2	RAPS_HISTORY_FILE_SOURCE	/Users/menacher/dev/ras-data/raps/DEFAULT_ACCOUNT/HX96X/history/to_be_processed
24	2	RAPS_RESPONSE_FILE_SOURCE	/Users/menacher/dev/ras-data/raps/DEFAULT_ACCOUNT/HX96X/responses/to_be_processed
25	2	RAPS_SUBMISSION_FILE_DEPOSIT	/Users/menacher/dev/ras-data/raps/DEFAULT_ACCOUNT/HX96X/cms/to_be_submitted
26	2	EDPS_FILENAME_GRAMMAR	MAB.PROD.NDM.{environment}.EDST.{edps_submitter}_DEF_837({encounter_type})_{timestamp}
27	2	RAPS_FILENAME_GRAMMAR	MAB.PROD.NDM.RAPS.{environment}.{raps_submitter}_DEF_{timestamp}
38	2	ADJUDICATED_FILE_SOURCE	/Users/menacher/dev/ras-data/edps/DEFAULT_ACCOUNT/HX96X/adjudicated/to_be_processed
40	2	SET_CMSICN_FROM_ORIG_CLAIM_FLAG	false
41	2	CMSICN_CLAIM_SUFFIX_CHAR	0
42	2	CMSICN_CLAIM_SUFFIX_LENGTH	2
36	2	X12_NEW_IS_ADJUDICATED_FLAG	true
37	2	X12_ADJUDICATED_POST_PROCESS_FLAG	true
39	2	DUPLICATE_CLAIM_CHECK_FLAG	true
21	2	RULE_ENGINE_ENABLED	true
\.


--
-- Data for Name: h_plan_report; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.h_plan_report (id, h_plan_id, plan_id, user_name, report_name, report_url, file_status, product_name, date_created) FROM stdin;
\.


--
-- Data for Name: h_plan_submitter; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.h_plan_submitter (id, h_plan_id, cms_submitter_id, description, additional_notes, created_by, delete_status, date_created, last_updated) FROM stdin;
1	2	1	Linking HX96X plan to ENC0001 submitter	\N	confianza	\N	2022-11-14 01:29:31.359613	2022-11-14 01:29:31.359613
2	2	3	Linking HX96X plan to ENC1234 submitter	\N	confianza	\N	2022-11-14 01:29:31.369884	2022-11-14 01:29:31.369884
3	2	2	Linking HX96X plan to SHXXXX submitter	\N	confianza	\N	2022-11-14 01:29:31.379969	2022-11-14 01:29:31.379969
\.


--
-- Data for Name: hcc_diag; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.hcc_diag (id, plan_id, pcp_id, pcp_last_name, pcp_first_name, plan_member_id, beneficiary_member_identifier, beneficiary_last_name, beneficiary_first_name, subscriber_birth_date, subscriber_gender_code, patient_control_number, place_of_service, claim_frequency_code, submission_date, begin_date_of_service, end_date_of_service, cmsicn, payer_claim_control_number, encounter_or_chartreview, billing_provider_last_organisation_name, billing_provider_npi_identifier, billing_provider_taxonomy, rendering_provider_last_name, rendering_provider_first_name, rendering_provider_identifier, rendering_provider_taxonomy, attending_provider_last_name, attending_provider_first_name, attending_provider_identifier, attending_provider_taxonomy, claim_code, hcc_value, encounter_type_switch, allowed_disallowed, allowed_disallowed_reason_code, add_delete_ind, encounter_status, duplicate_plan_icn, duplicate_encounter_icn, encounter_reject_code, reject_reason, revenue_codes, procedure_codes, procedure_modifier1, procedure_modifier2, procedure_modifier3, procedure_modifier4, model_category, payment_year, model_run, source_file_id, file_name, claim_id, source, is_hcc_deleted, key_hash, is_cpt_eligible, last_updated, tx_type) FROM stdin;
\.


--
-- Data for Name: hcc_diag_filtered; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.hcc_diag_filtered (id, plan_id, pcp_id, pcp_last_name, pcp_first_name, plan_member_id, beneficiary_member_identifier, beneficiary_last_name, beneficiary_first_name, subscriber_birth_date, subscriber_gender_code, patient_control_number, place_of_service, claim_frequency_code, submission_date, begin_date_of_service, end_date_of_service, cmsicn, payer_claim_control_number, encounter_or_chartreview, billing_provider_last_organisation_name, billing_provider_npi_identifier, billing_provider_taxonomy, rendering_provider_last_name, rendering_provider_first_name, rendering_provider_identifier, rendering_provider_taxonomy, attending_provider_last_name, attending_provider_first_name, attending_provider_identifier, attending_provider_taxonomy, claim_code, hcc_value, encounter_type_switch, allowed_disallowed, allowed_disallowed_reason_code, add_delete_ind, encounter_status, duplicate_plan_icn, duplicate_encounter_icn, encounter_reject_code, reject_reason, revenue_codes, procedure_codes, procedure_modifier1, procedure_modifier2, procedure_modifier3, procedure_modifier4, model_category, payment_year, model_run, source_file_id, file_name, claim_id, source, is_cpt_eligible, is_removed_in_hierarchy, key_hash) FROM stdin;
\.


--
-- Data for Name: hcc_diag_hierarchy_applied; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.hcc_diag_hierarchy_applied (id, plan_id, pcp_id, pcp_last_name, pcp_first_name, plan_member_id, beneficiary_member_identifier, beneficiary_last_name, beneficiary_first_name, subscriber_birth_date, subscriber_gender_code, patient_control_number, place_of_service, claim_frequency_code, submission_date, begin_date_of_service, end_date_of_service, cmsicn, payer_claim_control_number, encounter_or_chartreview, billing_provider_last_organisation_name, billing_provider_npi_identifier, billing_provider_taxonomy, rendering_provider_last_name, rendering_provider_first_name, rendering_provider_identifier, rendering_provider_taxonomy, attending_provider_last_name, attending_provider_first_name, attending_provider_identifier, attending_provider_taxonomy, claim_code, hcc_value, encounter_type_switch, allowed_disallowed, allowed_disallowed_reason_code, add_delete_ind, encounter_status, duplicate_plan_icn, duplicate_encounter_icn, encounter_reject_code, reject_reason, revenue_codes, procedure_codes, procedure_modifier1, procedure_modifier2, procedure_modifier3, procedure_modifier4, model_category, payment_year, model_run, source_file_id, file_name, claim_id, source, is_cpt_eligible, key_hash, hierarchy_present_in_edps, hierarchy_present_in_raps) FROM stdin;
\.


--
-- Data for Name: hcc_diag_payment_year_modelcategory; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.hcc_diag_payment_year_modelcategory (id, service_year, payment_year, model_category, product_name) FROM stdin;
1	2018	2019	V23	EDPS
2	2019	2020	V24	EDPS
3	2020	2021	V24	EDPS
4	2018	2019	V22	RAPS
5	2019	2020	V22	RAPS
6	2020	2021	V22	RAPS
7	2016	2017	V21	EDPS
8	2017	2018	V22	EDPS
9	2017	2018	V22	RAPS
10	2016	2017	V22	RAPS
11	2021	2022	V24	EDPS
12	2021	2022	V22	RAPS
13	2022	2023	V24	EDPS
14	2022	2023	V22	RAPS
\.


--
-- Data for Name: health_plan; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.health_plan (id, a_id, plan_name, description, created_by, date_created, last_updated, schema, geo) FROM stdin;
1	1	DEFAULT_PLAN	System place holder plan.	confianza	2022-11-14 01:29:14.914883	2022-11-14 01:29:14.914883	public	CMS
2	2	HX96X	Health Plan - HX96X	confianza	2022-11-14 01:29:31.321176	2022-11-14 01:29:31.321176	public	CMS
\.


--
-- Data for Name: in_process_flows; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.in_process_flows (flow_item_id, date_created, locked_at) FROM stdin;
\.


--
-- Data for Name: inst_1000a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_1000a (id, record_type, file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, transaction_set_control_number, batch_control_number, entity_identifier_code, entity_type_qualifier, submitter_last_or_organization_name, name_first, name_middle, identification_code_qualifier, submitter_identifier, contact_function_code, name, communication_number_qualifier1, communication_number1, communication_number_qualifier2, communication_number2, communication_number_qualifier3, communication_number3) FROM stdin;
\.


--
-- Data for Name: inst_1000b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_1000b (id, record_type, file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, transaction_set_control_number, batch_control_number, entity_identifier_code, entity_type_qualifier, receiver_name, electronic_transmitter_identification_number, receiver_primary_identifier) FROM stdin;
\.


--
-- Data for Name: inst_2000a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2000a (id, claim_id, billing_provider_hierarchical_id_number, billing_provider_hierarchical_level_code, billing_provider_hierarchical_child_code, billing_provider_code, billing_provider_taxonomy_code_qual, billing_provider_taxonomy_code, currency_identifier_code_qual, currency_code) FROM stdin;
\.


--
-- Data for Name: inst_2000b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2000b (id, claim_id, subscriber_hierarchical_id_number, subscriber_hierarchical_parent_id_number, subscriber_hierarchical_level_code, subscriber_hierarchical_child_code, payer_responsibility, subscriber_individual_relationship_code, subscriber_group, subscriber_group_name, subscriber_insurance_type_code, claim_filing_indicator_code, date_format, patient_death_date, measurement_code, patient_weight, pregnancy_indicator) FROM stdin;
\.


--
-- Data for Name: inst_2000c; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2000c (id, claim_id, patient_hierarchical_id_number, patient_hierarchical_parent_id_number, patient_hierarchical_level_code, patient_hierarchical_child_code, patient_relationship_code, patient_death_date_format, patient_death_date, basis_for_dme_patient_measurement_code, dme_patient_weight, patient_pregnancy_indicator) FROM stdin;
\.


--
-- Data for Name: inst_2010aa; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2010aa (id, claim_id, billing_provider_entity_identifier_code_qual, billing_provider_entity_type_qualifier, billing_provider_last_organization_name, billing_provider_first_name, billing_provider_middle_name_or_initial, billing_provider_name_suffix, billing_provider_primary_identification_qual, billing_provider_npi_identifier, billing_provider_address_line1, billing_provider_address_line2, billing_provider_city_name, billing_provider_state_or_province_code, billing_provider_postal_zone_or_zip_code, country_code, country_subdivision_code) FROM stdin;
\.


--
-- Data for Name: inst_2010ab; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2010ab (id, claim_id, pay_to_provider_identifier_code, pay_to_provider_identifier_type_qualifier, pay_to_address1, pay_to_address2, pay_to_address_city_name, pay_to_address_state_code, pay_to_address_postal_zone_or_zip_code, pay_to_address_country_code, pay_to_address_country_sub_code) FROM stdin;
\.


--
-- Data for Name: inst_2010ac; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2010ac (id, claim_id, pay_to_plan_identifier_code, pay_to_plan_identifier_type_qualifier, pay_to_plan_organization_name, pay_to_plan_primary_identification_code_qual, pay_to_plan_name_hplan, pay_to_plan_address1, pay_to_plan_address2, pay_to_plan_address_city_name, pay_to_plan_address_state_code, pay_to_plan_address_postal_zone_or_zip_code, pay_to_plan_address_country_code, pay_to_plan_address_country_sub_code) FROM stdin;
\.


--
-- Data for Name: inst_2010ba; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2010ba (id, claim_id, subscriber_entity_identifier_code, subscriber_entity_type_qual, subscriber_last_name, subscriber_first_name, subscriber_middle_name, subscriber_name_suffix, subscriber_primary_identification_code_qual, beneficiary_member_identifier, subscriber_address1, subscriber_address2, subscriber_city_name, subscriber_state_or_province_code, subscriber_postal_zone_or_zip_code, subscriber_country_code, subscriber_country_sub_code, subscriber_birth_date_qual, subscriber_birth_date, subscriber_gender_code, subscriber_contact_function_code, subscriber_contact_name, subscriber_communication_number_qualifier, subscriber_communication_number, subscriber_communication_number_qualifier2, subscriber_communication_number2) FROM stdin;
\.


--
-- Data for Name: inst_2010bb; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2010bb (id, claim_id, beneficiary_member_identifier, payer_entity_identifier_code, payer_entity_type_qual, payer_last_name, payer_primary_identification_code_qual, payer_identifier, payer_address1, payer_address2, payer_city_name, payer_state_or_province_code, payer_postal_zone_or_zip_code, payer_country_code, payer_country_sub_code) FROM stdin;
\.


--
-- Data for Name: inst_2010ca; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2010ca (id, claim_id, patient_entity_identifier_code, patient_entity_type_qual, patient_last_name, patient_first_name, patient_middle_name, patient_name_suffix, patient_address1, patient_address2, patient_city_name, patient_state_or_province_code, patient_postal_zone_or_zip_code, patient_country_code, patient_country_sub_code, patient_birth_date_qual, patient_birth_date, patient_gender_code, patient_secondary_identification_code_qual, patient_property_casualty_claim_number, patient_contact_function_code, patient_contact_name, patient_communication_number_qualifier, patient_communication_number, patient_communication_number_qualifier2, patient_communication_number2) FROM stdin;
\.


--
-- Data for Name: inst_2300; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2300 (id, record_type, claim_id, interchange_sender_id, interchange_control_number, interchange_receiver_id, group_control_number, transaction_set_control_number, batch_control_number, billing_provider_hierarchical_id_number, billing_provider_npi_identifier, payer_identifier, subscriber_hierarchical_id_number, beneficiary_member_identifier, patient_hierarchical_id_number, patient_control_number, total_claim_charge_amount, facility_type_code, facility_type_code_qual, claim_frequency_code, assignment_or_plan_participation_code, benefits_assignment_certification_indicator, release_of_information_code, delay_reason_code, admission_type_code, admission_source_code, patient_status_code, contract_type_code, contract_amount, contract_percentage, contract_code, terms_discount_percentage, contract_version_identifier, patient_responsibility_estimated_qualifier_code, patient_responsibility_amount, fixed_format_information, epsdt_screening_referral_information_code_qualifier, epsdt_referral_certification_condition_indicator, epsdt_referral_condition_code1, epsdt_referral_condition_code2, epsdt_referral_condition_code3, claim_pricing_methodology, repriced_allowed_amount, repriced_saving_amount, repricing_organization_identifier, repricing_per_diem_or_flat_rate_amount, repriced_approved_ambulatory_patient_group_code, repriced_approved_ambulatory_patient_group_amount, repriced_approved_revenue_code, measurement_code, repriced_approved_service_unit_count, repriced_reject_reason_code, repriced_policy_compliance_code, repriced_exception_code) FROM stdin;
\.


--
-- Data for Name: inst_2310a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2310a (id, claim_id, attending_provider_entity_identifier_code, attending_provider_entity_qualifier, attending_provider_last_name, attending_provider_first_name, attending_provider_middle_name_or_initial, attending_provider_name_suffix, attending_provider_identification_code_qualifier, attending_provider_identifier, attending_provider_code, attending_provider_code_qual, attending_provider_taxonomy_code) FROM stdin;
\.


--
-- Data for Name: inst_2310b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2310b (id, claim_id, operating_physician_entity_identifier_code, operating_physician_entity_qualifier, operating_physician_last_name, operating_physician_first_name, operating_physician_middle_name_or_initial, operating_physician_name_suffix, operating_physician_identification_code_qualifier, operating_physician_identifier) FROM stdin;
\.


--
-- Data for Name: inst_2310c; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2310c (id, claim_id, other_operating_physician_entity_identifier_code, other_operating_physician_entity_qualifier, other_operating_physician_last_name, other_operating_physician_first_name, other_operating_physician_middle_name_or_initial, other_operating_physician_name_suffix, other_operating_physician_identification_code_qualifier, other_operating_physician_identifier) FROM stdin;
\.


--
-- Data for Name: inst_2310d; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2310d (id, claim_id, rendering_provider_entity_identifier_code, rendering_provider_entity_qualifier, rendering_provider_last_name, rendering_provider_first_name, rendering_provider_middle_name_or_initial, rendering_provider_name_suffix, rendering_provider_identification_code_qualifier, rendering_provider_identifier) FROM stdin;
\.


--
-- Data for Name: inst_2310e; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2310e (id, claim_id, service_facility_entity_identifier_code, service_facility_entity_type_qualifier, service_facility_last_organization_name, service_facility_identifier_qual, service_facility_primary_identifier, service_facility_address_line1, service_facility_address_line2, service_facility_city_name, service_facility_state_or_province_code, service_facility_postal_zone_or_zip_code, country_code, country_subdivision_code, service_facility_provider_code, service_facility_provider_code_qual, service_facility_provider_taxonomy_code) FROM stdin;
\.


--
-- Data for Name: inst_2310f; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2310f (id, claim_id, referring_provider_entity_identifier_code, referring_provider_entity_type_qual, referring_provider_last_name, referring_provider_first_name, referring_provider_middle_name_or_initial, referring_provider_name_suffix, referring_provider_identification_code_qualifier, referring_provider_identifier) FROM stdin;
\.


--
-- Data for Name: inst_2320; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2320 (id, claim_id, payer_responsibility, subscriber_individual_relationship_code, subscriber_group, subscriber_group_name, subscriber_insurance_type_code, claim_filing_indicator_code, benefits_assignment_certification_indicator, patient_signature_source_code, release_of_information_code, inpatient_covered_days_or_visits_count, inpatient_amount, lifetime_psychiatric_days_count, claim_drg_amount, claim_payment_remark_code1, claim_disproportionate_share_amount, claim_msp_passthrough_amount, claim_pps_capital_amount, ppscapital_fsp_drg_amount, ppscapital_hsp_drg_amount, ppscapital_dsh_drg_amount, old_capital_amount, ppscapital_ime_amount, ppsoperating_hospital_specific_drg_amount, cost_report_day_count, ppsoperating_federal_specific_drg_amount, claim_pps_capital_outlier_amount, claim_indirect_teaching_amount, nonpayable_professional_component_billed_amount, claim_payment_remark_code2, claim_payment_remark_code3, claim_payment_remark_code4, claim_payment_remark_code5, ppscapital_exception_amount, reimbursement_rate, hcpcs_payable_amount, esrd_payment_amount) FROM stdin;
\.


--
-- Data for Name: inst_2330a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2330a (id, claim_id, other_subscriber_entity_identifier_code, other_subscriber_entity_identifier_qual, other_subscriber_last_name, other_subscriber_first_name, other_subscriber_middle_name, other_subscriber_name_suffix, other_subscriber_identification_code_qualifier, other_subscriber_primary_identifier, other_subscriber_address1, other_subscriber_address2, other_subscriber_city_name, other_subscriber_state_or_province_code, other_subscriber_postal_zone_or_zip_code, other_subscriber_country_code, other_subscriber_country_sub_code, other_subscriber_secondary_identification_qual, other_subscriber_social_security_number) FROM stdin;
\.


--
-- Data for Name: inst_2330b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2330b (id, claim_id, other_payer_entity_identifier_code, other_payer_entity_identifier_qual, other_payer_last_name, other_payer_identification_code_qualifier, other_payer_primary_identifier, other_payer_address1, other_payer_address2, other_payer_city_name, other_payer_state_or_province_code, other_payer_postal_zone_or_zip_code, other_payer_country_code, other_payer_country_sub_code, date_claim_paid_qual, date_claim_paid_format, adjudication_date) FROM stdin;
\.


--
-- Data for Name: inst_2330c; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2330c (id, claim_id, other_payer_attending_provider_entity_identifier_code, other_payer_attending_provider_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: inst_2330d; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2330d (id, claim_id, other_payer_operating_physician_entity_identifier_code, other_payer_operating_physician_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: inst_2330e; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2330e (id, claim_id, other_payer_other_operating_physician_entity_identifier_code, other_payer_other_operating_physician_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: inst_2330f; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2330f (id, claim_id, other_payer_service_location_entity_identifier_code, other_payer_service_location_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: inst_2330g; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2330g (id, claim_id, other_payer_render_provider_entity_identifier_code, other_payer_render_provider_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: inst_2330h; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2330h (id, claim_id, other_payer_refer_provider_entity_identifier_code, other_payer_refer_provider_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: inst_2330i; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2330i (id, claim_id, other_payer_billing_provider_entity_identifier_code, other_payer_billing_provider_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: inst_2400; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2400 (id, claim_id, segment_number, claim_line_number, service_line_revenue_code, procedure_code_qualifier, procedure_code, procedure_modifier1, procedure_modifier2, procedure_modifier3, procedure_modifier4, procedure_code_description, line_item_charge_amount, unit_or_basis_for_measurement, service_unit_count, line_item_denied_charge_or_noncovered_charge_amount, note_reference_code, third_party_organization_notes, pricing_methodology, repriced_allowed_amount, repriced_saving_amount, repricing_organization_identifier, repricing_per_diem_or_flat_rate_amount, repriced_approved_ambulatory_patient_group_code, repriced_approved_ambulatory_patient_group_amount, repricing_service_id, repricing_service_id_qualifier, repriced_approved_hcpcs_code, basis_for_measurement_code, repriced_approved_service_unit_count, reject_reason_code, policy_compliance_code, exception_code, line_hash, dup_line, remit_line_match_status) FROM stdin;
\.


--
-- Data for Name: inst_2410; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2410 (id, claim_id, claim_line_number, national_drug_code_qual, national_drug_code, national_drug_unit_count, code_qualifier) FROM stdin;
\.


--
-- Data for Name: inst_2420a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2420a (id, claim_id, claim_line_number, operating_physician_entity_identifier_code, operating_physician_entity_qualifier, operating_physician_last_name, operating_physician_first_name, operating_physician_middle_name_or_initial, operating_physician_name_suffix, operating_physician_identification_code_qualifier, operating_physician_identifier) FROM stdin;
\.


--
-- Data for Name: inst_2420b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2420b (id, claim_id, claim_line_number, other_operating_physician_entity_identifier_code, other_operating_physician_entity_qualifier, other_operating_physician_last_name, other_operating_physician_first_name, other_operating_physician_middle_name_or_initial, other_operating_physician_name_suffix, other_operating_physician_identification_code_qualifier, other_operating_physician_identifier) FROM stdin;
\.


--
-- Data for Name: inst_2420c; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2420c (id, claim_id, claim_line_number, rendering_provider_entity_identifier_code, rendering_provider_entity_qualifier, rendering_provider_last_name, rendering_provider_first_name, rendering_provider_middle_name_or_initial, rendering_provider_name_suffix, rendering_provider_identification_code_qualifier, rendering_provider_identifier) FROM stdin;
\.


--
-- Data for Name: inst_2420d; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2420d (id, claim_id, claim_line_number, referring_provider_entity_identifier_code, referring_provider_entity_qualifier, referring_provider_last_name, referring_provider_first_name, referring_provider_middle_name_or_initial, referring_provider_name_suffix, referring_provider_identification_code_qualifier, referring_provider_identifier) FROM stdin;
\.


--
-- Data for Name: inst_2430; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2430 (id, claim_id, claim_line_number, other_payer_primary_identifier, service_line_paid_amount, product_or_service_id_qualifier, procedure_code, procedure_modifier1, procedure_modifier2, procedure_modifier3, procedure_modifier4, procedure_code_description, product_service_id, paid_service_unit_count, bundled_or_unbundled_line_number, date_claim_paid, date_time_period_format_qualifier, adjudication_or_payment_date, amount_qualifier_code, remaining_patient_liability) FROM stdin;
\.


--
-- Data for Name: inst_2440; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_2440 (id, claim_id, claim_line_number, form_identifier_qual, form_identifier, question_number_or_letter, question_response, question_response_desc, question_response_date, question_response_percentage) FROM stdin;
\.


--
-- Data for Name: inst_bht; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_bht (id, record_type, file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, transaction_set_control_number, hierarchical_structure_code, transaction_set_purpose_code, batch_control_number, date, "time", claim_identifier) FROM stdin;
\.


--
-- Data for Name: inst_claim_data; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_claim_data (id, claim_id, data) FROM stdin;
\.


--
-- Data for Name: inst_claim_identifier; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_claim_identifier (id, h_plan_id, plan_id, patient_control_number, linked_patient_control_number, beneficiary_first_name, beneficiary_last_name, type_of_bill, begin_date_of_service, end_date_of_service, submission_date, claim_frequency_code, encounter_or_chart_review, beneficiary_member_identifier, total_claim_charge_amount, payer_amount_paid, cmsicn, payer_claim_control_number, source, encounter_status, encounter_status_type, encounter_status_code, encounter_reject_category, file_id, linked_provider_clm_id, h_plan_submitter_id, last_updated, date_created, modified_by, segment_number, interchange_sender_id, interchange_receiver_id, billing_provider_npi, attending_provider_npi, interchange_control_number, group_control_number, batch_control_number, transaction_set_control_number, st_index, billing_provider_hierarchical_id_number, raps_extract_status, encounter_revision) FROM stdin;
\.


--
-- Data for Name: inst_claim_line_data; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_claim_line_data (id, claim_id, claim_line_number, data) FROM stdin;
\.


--
-- Data for Name: inst_header_trailer; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_header_trailer (id, record_type, file_id, authorization_information_qualifier, authorization_information, security_information_qualifier, security_information, interchange_sender_id_qualifier, interchange_sender_id, interchange_receiver_id_qualifier, interchange_receiver_id, interchange_date, interchange_time, repetition_separator, interchange_control_version_number, interchange_control_number, acknowledgment_requested, interchange_usage_indicator, component_element_separator, functional_identifier_code, application_senders_code, application_receivers_code, group_header_date, group_header_time, group_control_number, responsible_agency_code, industry_identifier_code, number_of_transaction_sets_included, trailer_group_control_number, number_of_included_functional_groups) FROM stdin;
\.


--
-- Data for Name: inst_se; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_se (id, record_type, file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, transaction_segment_count, transaction_set_control_number) FROM stdin;
\.


--
-- Data for Name: inst_st; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inst_st (id, record_type, file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, st_index, transaction_set_identifier_code, transaction_set_control_number, implementation_convention_reference) FROM stdin;
\.


--
-- Data for Name: inter_process_queue; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.inter_process_queue (id, date_created, locked_at, locked_by, source, channel, type, message) FROM stdin;
\.


--
-- Data for Name: linked_cr_batch; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.linked_cr_batch (id, batch_file_id, submitter_id, plan_id, mbi, patient_control_number, begin_date_of_service, end_date_of_service, lob, add_delete_indicator, primary_diag_code, secondary_diag_code1, secondary_diag_code2, secondary_diag_code3, secondary_diag_code4, secondary_diag_code5, secondary_diag_code6, secondary_diag_code7, secondary_diag_code8, secondary_diag_code9, secondary_diag_code10, secondary_diag_code11, default_procedure_code, status, status_code) FROM stdin;
\.


--
-- Data for Name: member_raf; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.member_raf (id, h_plan_id, plan_id, beneficiary_id, ma_type, year, month, age, sex, raft, orec, medicaid_flag, extract_type, raw_risk_score, total_demography_score, total_hcc_score, calc_blended_risk_score, bid_amount, ma_payment, hcc_map, hcc_engine_output, plan_member_id) FROM stdin;
\.


--
-- Data for Name: mmr_data; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.mmr_data (id, contract_number, run_date, payment_date, beneficiary_id, surname, first_initial, gender_code, date_of_birth, filler1, state_and_county_code, out_of_area_ind, part_a_entitlement, part_b_entitlement, hospice, esrd, aged_disabled_msp, filler2, filler3, new_beneficiary_status, lti_flag, medicaid_ind, filler4, def_risk_factor_code, risk_adjustment_factor_a, rick_adjustment_factor_b, payment_adjustment_months_part_a, payment_adjustment_months_part_b, adjustment, payment_adjustment_start_date, payment_adjustment_end_date, filler5, filler6, monthly_payment_adjustment_amount_rate_a, monthly_payment_adjustment_amount_rate_b, lis_premium_subsidy, esrd_msp_flag, medication_therapy_management_addon, filler7, medicaid_status, risk_adjustment_age_group, filler8, filler9, filler10, plan_benefit_package_id, filler11, risk_adjustment_factor_type_code, frailty_ind, original_reason_for_entitlement_code, filler12, segment_number1, filler13, eghp_flag, part_c_basic_premium_part_a_amt, part_c_basic_premium_part_b_amt, rebate_for_part_a_cost_sharing_reduction, rebate_for_part_b_cost_sharing_reduction, rebate_for_other_part_a_mandatory_supplemental_benefits, rebate_for_other_part_b_mandatory_supplemental_benefits, rebate_for_part_b_premium_reduction_part_a_amt, rebate_for_part_b_premium_reduction_part_b_amt, rebate_for_part_d_supplemental_benefits_part_a_amt, rebate_for_part_d_supplemental_benefits_part_b_amt, total_part_a_ma_payment, total_part_b_ma_payment, total_ma_payment_amt, part_d_ra_factor, part_d_low_income_ind, part_d_low_income_multiplier, part_d_long_term_inst_ind, part_d_long_term_inst_multiplier, rebate_for_part_d_basic_premium_reduction, part_d_basic_premium_amt, part_d_direct_subsidy_monthly_payment_amt, reinsurance_subsidy_amt, low_income_subsidy_cost_sharing_amt, total_part_d_payment, number_of_payment_adjustment_months_part_d, pace_premium_addon, pace_cost_sharing_addon, part_c_frailty_score_factor, msp_factor, msp_reduction_adjustment_amt_part_a, msp_reduction_adjustment_amt_part_b, medicaid_dual_status_code, part_d_coverage_gap_discount_amt, part_d_risk_adjustment_factor_type, def_part_d_risk_adjustment_factor_code, part_a_risk_adjusted_monthly_amt_for_payment_adjustment, part_b_risk_adjusted_monthly_amt_for_payment_adjustment, part_d_direct_subsidy_monthly_amt_for_payment_adjustment, cleanup_id, plan_member_id, member_active) FROM stdin;
\.


--
-- Data for Name: model_run_config; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.model_run_config (id, payment_year, model_run, from_date_of_service, to_date_of_service, submission_cut_off_date) FROM stdin;
1	2019	INITIAL	20170701	20180630	20180904
2	2019	MID	20180101	20181231	20190306
3	2019	FINAL	20180101	20181231	20200131
4	2020	INITIAL	20180701	20190630	20190904
5	2020	MID	20190101	20191231	20200306
6	2020	FINAL	20190101	20191231	20210131
7	2021	INITIAL	20190701	20200630	20200904
8	2021	MID	20200101	20201231	20210305
9	2021	FINAL	20200101	20201231	20220131
10	2022	INITIAL	20200701	20210630	20210903
11	2022	MID	20210101	20211231	20220304
12	2022	FINAL	20210101	20211231	20230131
13	2023	INITIAL	20210701	20220630	20220903
14	2023	MID	20220101	20221231	20230304
15	2023	FINAL	20220101	20221231	20240131
\.


--
-- Data for Name: prof_1000a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_1000a (id, record_type, file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, transaction_set_control_number, batch_control_number, entity_identifier_code, entity_type_qualifier, submitter_last_or_organization_name, name_first, name_middle, identification_code_qualifier, submitter_identifier, contact_function_code, name, communication_number_qualifier1, communication_number1, communication_number_qualifier2, communication_number2, communication_number_qualifier3, communication_number3) FROM stdin;
100002262	\N	100000002	000108258	ENC0001	80882	108258	0001	20190912000522.1650+0000	41	2	MIRRA HEALTH	\N	\N	46	ENC0001	IC	MIRRA HELPDESK	TE	5703449237	\N	\N	\N	\N
\.


--
-- Data for Name: prof_1000b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_1000b (id, record_type, file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, transaction_set_control_number, batch_control_number, entity_identifier_code, entity_type_qualifier, receiver_name, electronic_transmitter_identification_number, receiver_primary_identifier) FROM stdin;
100002264	\N	100000002	000108258	ENC0001	80882	108258	0001	20190912000522.1650+0000	40	2	EDSCMS	46	80882
\.


--
-- Data for Name: prof_2000a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2000a (id, claim_id, billing_provider_hierarchical_id_number, billing_provider_hierarchical_level_code, billing_provider_hierarchical_child_code, billing_provider_code, billing_provider_taxonomy_code_qual, billing_provider_taxonomy_code, currency_identifier_code_qual, currency_code) FROM stdin;
100002265	100002259	1	20	1	\N	\N	\N	\N	\N
100002303	100002302	3	20	1	\N	\N	\N	\N	\N
100002373	100002372	5	20	1	\N	\N	\N	\N	\N
100002412	100002411	7	20	1	\N	\N	\N	\N	\N
100002449	100002448	9	20	1	\N	\N	\N	\N	\N
100002486	100002485	11	20	1	\N	\N	\N	\N	\N
100002525	100002524	13	20	1	\N	\N	\N	\N	\N
100002562	100002561	15	20	1	BI	PXC	193200000X	\N	\N
100002600	100002599	17	20	1	\N	\N	\N	\N	\N
100002638	100002637	19	20	1	\N	\N	\N	\N	\N
100002677	100002676	21	20	1	\N	\N	\N	\N	\N
100002715	100002714	23	20	1	\N	\N	\N	\N	\N
100002753	100002752	25	20	1	\N	\N	\N	\N	\N
100002791	100002790	27	20	1	\N	\N	\N	\N	\N
100002829	100002828	29	20	1	\N	\N	\N	\N	\N
100002867	100002866	31	20	1	\N	\N	\N	\N	\N
100002905	100002904	33	20	1	\N	\N	\N	\N	\N
\.


--
-- Data for Name: prof_2000b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2000b (id, claim_id, subscriber_hierarchical_id_number, subscriber_hierarchical_parent_id_number, subscriber_hierarchical_level_code, subscriber_hierarchical_child_code, payer_responsibility, subscriber_individual_relationship_code, subscriber_group, subscriber_group_name, subscriber_insurance_type_code, claim_filing_indicator_code, date_format, patient_death_date, measurement_code, patient_weight, pregnancy_indicator) FROM stdin;
100002268	100002259	2	1	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002308	100002302	4	3	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002377	100002372	6	5	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002416	100002411	8	7	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002453	100002448	10	9	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002490	100002485	12	11	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002529	100002524	14	13	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002566	100002561	16	15	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002604	100002599	18	17	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002642	100002637	20	19	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002681	100002676	22	21	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002719	100002714	24	23	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002758	100002752	26	25	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002796	100002790	28	27	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002834	100002828	30	29	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002871	100002866	32	31	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
100002909	100002904	34	33	22	0	S	18	\N	\N	47	MB	\N	\N	\N	\N	\N
\.


--
-- Data for Name: prof_2000c; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2000c (id, claim_id, patient_hierarchical_id_number, patient_hierarchical_parent_id_number, patient_hierarchical_level_code, patient_hierarchical_child_code, patient_relationship_code, patient_death_date_format, patient_death_date, basis_for_dme_patient_measurement_code, dme_patient_weight, patient_pregnancy_indicator) FROM stdin;
\.


--
-- Data for Name: prof_2010aa; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2010aa (id, claim_id, billing_provider_entity_identifier_code_qual, billing_provider_entity_type_qualifier, billing_provider_last_organization_name, billing_provider_first_name, billing_provider_middle_name_or_initial, billing_provider_name_suffix, billing_provider_primary_identification_qual, billing_provider_npi_identifier, billing_provider_address_line1, billing_provider_address_line2, billing_provider_city_name, billing_provider_state_or_province_code, billing_provider_postal_zone_or_zip_code, country_code, country_subdivision_code) FROM stdin;
100002266	100002259	85	2	AMRITA INSTITUTE OF MEDICAL RESEARCH	\N	\N	\N	XX	9999999999	PONEKKARA, P. O	\N	KOCHI	KL	682041999	\N	\N
100002305	100002302	85	2	AMRITA PULMONARY	\N	\N	\N	XX	4444444444	2320 W MARINE DR	\N	KOCHI	KL	336141853	\N	\N
100002375	100002372	85	2	RADIOLOGY OF KOCHI KL	\N	\N	\N	XX	2222222222	PO BOX 31265	\N	KOCHI	KL	336313265	\N	\N
100002414	100002411	85	2	ST POHNS HOSPITAL	\N	\N	\N	XX	1528196847	14533 MARINE DR	\N	KOCHI	KL	346139998	\N	\N
100002451	100002448	85	2	KRISHNAN KUTTI MD	\N	\N	\N	XX	9876432100	5433 COMMERCIAL DR	\N	KOCHI	KL	346061110	\N	\N
100002488	100002485	85	2	AMRITA INSTITUTE OF MEDICAL RESEARCH	\N	\N	\N	XX	9999999999	PONEKKARA, P. O	\N	KOCHI	KL	682041999	\N	\N
100002527	100002524	85	2	KIMS NEUROLOGY	\N	\N	\N	XX	1234432111	PO BOX 602373	\N	KOCHI	KL	346069998	\N	\N
100002564	100002561	85	2	KOCHIN MEDICAL GROUP	\N	\N	\N	XX	1213131313	PO BOX 743409	\N	ALAPPEY	KL	336029998	\N	\N
100002602	100002599	85	2	ANESTHESIOLOGIST ASSOC KOCHIN	\N	\N	\N	XX	1678901010	PO BOX 15689	\N	KOCHI	KL	346040122	\N	\N
100002640	100002637	85	2	AMRITA INSTITUTE OF MEDICAL RESEARCH	\N	\N	\N	XX	9999999999	1222 MG ROAD ST102	\N	KOCHI	KL	682041999	\N	\N
100002679	100002676	85	2	ANESTHESIOLOGIST ASSOC KOCHIN	\N	\N	\N	XX	1678901010	PO BOX 15689	\N	KOCHI	KL	346040122	\N	\N
100002717	100002714	85	2	ANESTHESIOLOGISTS ASSOC KOCHIN	\N	\N	\N	XX	1678901010	PO BOX 1589	\N	KOCHI	KL	346040122	\N	\N
100002755	100002752	85	2	THE CENTER FOR BONE DISEASE	\N	\N	\N	XX	1234678901	7544 ANAYARA DR	\N	KOCHIN	KL	346677162	\N	\N
100002793	100002790	85	2	THE CENTER FOR BONE DISEASE	\N	\N	\N	XX	1234678901	7544 ANAYARA DR	\N	KOCHIN	KL	346677162	\N	\N
100002831	100002828	85	2	THE CENTER FOR BONE DISEASE	\N	\N	\N	XX	1234678901	7544 ANAYARA DR	\N	KOCHIN	KL	346677162	\N	\N
100002869	100002866	85	2	ALI AKBAR	\N	\N	\N	XX	1962699959	11373 MARINE DR STE 303	\N	KOCHI	KL	346135411	\N	\N
100002907	100002904	85	2	AMRITA INSTITUTE OF MEDICAL RESEARCH	\N	\N	\N	XX	9999999999	PONEKKARA, P. O	\N	KOCHI	KL	682041999	\N	\N
\.


--
-- Data for Name: prof_2010ab; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2010ab (id, claim_id, pay_to_provider_identifier_code, pay_to_provider_identifier_type_qualifier, pay_to_address1, pay_to_address2, pay_to_address_city_name, pay_to_address_state_code, pay_to_address_postal_zone_or_zip_code, pay_to_address_country_code, pay_to_address_country_sub_code) FROM stdin;
100002307	100002302	87	2	2810 W MARINE DR	\N	KOCHI	KL	336149998	\N	\N
100002757	100002752	87	2	PO BOX 628213	\N	THRISUR	KL	328629998	\N	\N
100002795	100002790	87	2	PO BOX 628213	\N	THRISUR	KL	328629998	\N	\N
100002833	100002828	87	2	PO BOX 628213	\N	THRISUR	KL	328629998	\N	\N
\.


--
-- Data for Name: prof_2010ac; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2010ac (id, claim_id, pay_to_plan_identifier_code, pay_to_plan_identifier_type_qualifier, pay_to_plan_organization_name, pay_to_plan_primary_identification_code_qual, pay_to_plan_name_h_plan, pay_to_plan_address1, pay_to_plan_address2, pay_to_plan_address_city_name, pay_to_plan_address_state_code, pay_to_plan_address_postal_zone_or_zip_code, pay_to_plan_address_country_code, pay_to_plan_address_country_sub_code) FROM stdin;
\.


--
-- Data for Name: prof_2010ba; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2010ba (id, claim_id, subscriber_entity_identifier_code, subscriber_entity_type_qual, subscriber_last_name, subscriber_first_name, subscriber_middle_name, subscriber_name_suffix, subscriber_primary_identification_code_qual, beneficiary_member_identifier, subscriber_address1, subscriber_address2, subscriber_city_name, subscriber_state_or_province_code, subscriber_postal_zone_or_zip_code, subscriber_country_code, subscriber_country_sub_code, subscriber_birth_date_qual, subscriber_birth_date, subscriber_gender_code, subscriber_contact_function_code, subscriber_contact_name, subscriber_communication_number_qualifier, subscriber_communication_number, subscriber_communication_number_qualifier2, subscriber_communication_number2) FROM stdin;
100002269	100002259	IL	1	OOMMAN	CHAANDI	P	\N	MI	X68X83X73X7	1236 FEDERAL BANK BUILD	\N	KOCHI	KL	346139998	\N	\N	D8	19440718	F	\N	\N	\N	\N	\N	\N
100002309	100002302	IL	1	SHAPI	ADOOR	A	\N	MI	XKRXYTXMEX5	2646 MARINE DR	\N	HOLIDAY	KL	346919998	\N	\N	D8	19470905	M	\N	\N	\N	\N	\N	\N
100002378	100002372	IL	1	SHAPI	ADOOR	A	\N	MI	XKRXYTXMEX5	2646 MARINE DR	\N	HOLIDAY	KL	346919998	\N	\N	D8	19470905	M	\N	\N	\N	\N	\N	\N
100002417	100002411	IL	1	SHAHRUKH	KHAN	E	\N	MI	XTPXEEXFQX8	14948 MARINE AVE	\N	KOCHI	KL	346139998	\N	\N	D8	19281114	M	\N	\N	\N	\N	\N	\N
100002454	100002448	IL	1	IDAVELA	BABU	D	\N	MI	XDPXFCXPFX4	7424 POYES KLRDEN	\N	KOCHI	KL	346069998	\N	\N	D8	19340124	M	\N	\N	\N	\N	\N	\N
100002491	100002485	IL	1	SALIM	KUMAR	P	\N	MI	XP1XFFXYRX3	7360 MARINE MEADOW DR	\N	KOCHI	KL	346069998	\N	\N	D8	19300521	F	\N	\N	\N	\N	\N	\N
100002530	100002524	IL	1	PAGDISH	KUMAR	F	\N	MI	XUGXGWXCEX7	13002 TITLEIST DR	\N	KOCHIN	KL	346699998	\N	\N	D8	19440519	F	\N	\N	\N	\N	\N	\N
100002567	100002561	IL	1	ARUN	POHN	P	\N	MI	XV4XV3XCGX8	8023 MARINE AVE	\N	KOCHI	KL	346139998	\N	\N	D8	19430121	M	\N	\N	\N	\N	\N	\N
100002605	100002599	IL	1	LAURENCE	MICHAEL	N	\N	MI	XHDXVX2TX06	41 NESAMANI CIR	\N	HAILESA	KL	344469998	\N	\N	D8	19480614	M	\N	\N	\N	\N	\N	\N
100002643	100002637	IL	1	DASAMOOLAM	DAMU	A	\N	MI	XC0XP6XXTX3	7151 MARINE AVE	\N	KOCHI	KL	346139998	\N	\N	D8	19580929	F	\N	\N	\N	\N	\N	\N
100002682	100002676	IL	1	SRANK	HARBOR	M	\N	MI	XNQXXKXEX41	PO BOX 1907	\N	HAILESA HAILESA	KL	344479998	\N	\N	D8	19440909	F	\N	\N	\N	\N	\N	\N
100002720	100002714	IL	1	APPUKKUTTAN	L	P	\N	MI	XN2XPUXTCX2	18736 HARIHAR NAGAR ST	APT 106	KOCHIN	KL	346679998	\N	\N	D8	19490710	F	\N	\N	\N	\N	\N	\N
100002759	100002752	IL	1	ANJALI	AMIR	A	\N	MI	XRFXA9XNGX0	13725 ANAYARA DR	APT 106	KOCHIN	KL	346699998	\N	\N	D8	19360209	F	\N	\N	\N	\N	\N	\N
100002797	100002790	IL	1	ANJALI	AMIR	A	\N	MI	XRFXA9XNGX0	13725 ANAYARA DR	APT 106	KOCHIN	KL	346699998	\N	\N	D8	19360209	F	\N	\N	\N	\N	\N	\N
100002835	100002828	IL	1	ANJALI	AMIR	A	\N	MI	XRFXA9XNGX0	13725 ANAYARA DR	APT 106	KOCHIN	KL	346699998	\N	\N	D8	19360209	F	\N	\N	\N	\N	\N	\N
100002872	100002866	IL	1	AJAY	MACKAN	A	\N	MI	2HX5UX6TX6X	12332 ZEPHYER COCHIN	APT 106	KOCHI	KL	346149998	\N	\N	D8	19541028	M	\N	\N	\N	\N	\N	\N
100002910	100002904	IL	1	HARIZ	JAYRAJ	K	\N	MI	XK2XTQXQWX8	9479 PALARIVATTAM ROAD	APT 106	KOCHI	KL	346089998	\N	\N	D8	19560426	F	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: prof_2010bb; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2010bb (id, claim_id, beneficiary_member_identifier, payer_entity_identifier_code, payer_entity_type_qual, payer_last_name, payer_primary_identification_code_qual, payer_identifier, payer_address1, payer_address2, payer_city_name, payer_state_or_province_code, payer_postal_zone_or_zip_code, payer_country_code, payer_country_sub_code) FROM stdin;
100002270	100002259	X68X83X73X7	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002310	100002302	XKRXYTXMEX5	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002379	100002372	XKRXYTXMEX5	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002418	100002411	XTPXEEXFQX8	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002455	100002448	XDPXFCXPFX4	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002492	100002485	XP1XFFXYRX3	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002531	100002524	XUGXGWXCEX7	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002568	100002561	XV4XV3XCGX8	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002606	100002599	XHDXVX2TX06	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002644	100002637	XC0XP6XXTX3	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002683	100002676	XNQXXKXEX41	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002721	100002714	XN2XPUXTCX2	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002760	100002752	XRFXA9XNGX0	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002798	100002790	XRFXA9XNGX0	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002836	100002828	XRFXA9XNGX0	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002873	100002866	2HX5UX6TX6X	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
100002911	100002904	XK2XTQXQWX8	PR	2	EDSCMS	PI	80882	7500 SECURITY BLVD	\N	BALTIMORE	MD	212441850	\N	\N
\.


--
-- Data for Name: prof_2010ca; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2010ca (id, claim_id, patient_entity_identifier_code, patient_entity_type_qual, patient_last_name, patient_first_name, patient_middle_name, patient_name_suffix, patient_address1, patient_address2, patient_city_name, patient_state_or_province_code, patient_postal_zone_or_zip_code, patient_country_code, patient_country_sub_code, patient_birth_date_qual, patient_birth_date, patient_gender_code, patient_secondary_identification_code_qual, patient_property_casualty_claim_number, patient_contact_function_code, patient_contact_name, patient_communication_number_qualifier, patient_communication_number, patient_communication_number_qualifier2, patient_communication_number2) FROM stdin;
\.


--
-- Data for Name: prof_2300; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2300 (id, record_type, claim_id, interchange_sender_id, interchange_control_number, interchange_receiver_id, group_control_number, transaction_set_control_number, batch_control_number, billing_provider_hierarchical_id_number, billing_provider_npi_identifier, payer_identifier, subscriber_hierarchical_id_number, beneficiary_member_identifier, patient_hierarchical_id_number, patient_control_number, total_claim_charge_amount, place_of_service_code, place_of_service_code_qual, claim_frequency_code, provider_or_supplier_signature_indicator, assignment_or_plan_participation_code, benefits_assignment_certification_indicator, release_of_information_code, patient_signature_source_code, related_causes_code1, related_causes_code2, auto_accident_state_or_province_code, country_code, special_program_indicator, delay_reason_code, contract_type_code, contract_amount, contract_percentage, contract_code, terms_discount_percentage, contract_version_identifier, patient_amount_qualifier_code, patient_amount_paid, fixed_format_information, note_reference_code, claim_note_text, ambulance_patient_measurement_code, ambulance_patient_weight, ambulance_transportation_reason_code, ambulance_transportation_measurement_code, transport_distance, round_trip_purpose_description, stretcher_purpose_description, nature_of_condition_code, patient_condition_description1, patient_condition_description2, claim_pricing_methodology, repriced_allowed_amount, repriced_saving_amount, repricing_organization_identifier, repricing_per_diem_or_flat_rate_amount, repriced_approved_ambulatory_patient_group_code, repriced_approved_ambulatory_patient_group_amount, repriced_reject_reason_code, repriced_policy_compliance_code, repriced_exception_code) FROM stdin;
100002263	\N	100002259	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	1	9999999999	80882	2	X68X83X73X7	\N	CLM180750002500	450	22	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002304	\N	100002302	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	3	4444444444	80882	4	XKRXYTXMEX5	\N	CLM182000000400	700	21	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002374	\N	100002372	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	5	2222222222	80882	6	XKRXYTXMEX5	\N	CLM182000045100	25	21	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002413	\N	100002411	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	7	1528196847	80882	8	XTPXEEXFQX8	\N	CLM182110013300	180	21	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002450	\N	100002448	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	9	9876432100	80882	10	XDPXFCXPFX4	\N	CLM182410026100	1680	11	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002487	\N	100002485	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	11	9999999999	80882	12	XP1XFFXYRX3	\N	CLM182480018000	450	22	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002526	\N	100002524	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	13	1234432111	80882	14	XUGXGWXCEX7	\N	CLM182550003600	150	21	B	1	Y	C	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002563	\N	100002561	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	15	1213131313	80882	16	XV4XV3XCGX8	\N	CLM182570001300	90	21	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002601	\N	100002599	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	17	1678901010	80882	18	XHDXVX2TX06	\N	CLM182680019600	204	21	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	ADD	036	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002639	\N	100002637	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	19	9999999999	80882	20	XC0XP6XXTX3	\N	CLM182760006800	525	22	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002678	\N	100002676	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	21	1678901010	80882	22	XNQXXKXEX41	\N	CLM182880007200	812.5	21	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002716	\N	100002714	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	23	1678901010	80882	24	XN2XPUXTCX2	\N	CLM183180006300	1587.5	21	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002754	\N	100002752	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	25	1234678901	80882	26	XRFXA9XNGX0	\N	CLM190050062200	6468	21	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002792	\N	100002790	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	27	1234678901	80882	28	XRFXA9XNGX0	\N	CLM190050062300	688	21	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002830	\N	100002828	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	29	1234678901	80882	30	XRFXA9XNGX0	\N	CLM190050062400	600	21	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002868	\N	100002866	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	31	1962699959	80882	32	2HX5UX6TX6X	\N	CLM190520022900	144	11	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002906	\N	100002904	ENC0001	000108258	80882	108258	0001	20190912000522.1650+0000	33	9999999999	80882	34	XK2XTQXQWX8	\N	CLM190950005300	525	22	B	1	Y	A	Y	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: prof_2310a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2310a (id, claim_id, referring_provider_entity_identifier_code, referring_provider_entity_type_qual, referring_provider_last_name, referring_provider_first_name, referring_provider_middle_name_or_initial, referring_provider_name_suffix, referring_provider_identification_code_qualifier, referring_provider_identifier) FROM stdin;
100002278	100002259	DN	1	AAMIR	KHAN	\N	\N	XX	8888888888
100002317	100002302	DN	1	CARLOS	CARLOS	K	\N	XX	3333333333
100002387	100002372	DN	1	PRASHANT	D	H	\N	XX	1111111111
100002424	100002411	DN	1	APAY	THOMAS	\N	\N	XX	1234678910
100002463	100002448	DN	1	BABU	ANTHONY	\N	\N	XX	4321678901
100002500	100002485	DN	1	AAMIR	KHAN	\N	\N	XX	8888888888
100002575	100002561	DN	1	VONTAAFFE	WILLIAM	P	\N	XX	1508870817
100002613	100002599	DN	1	TARABISHY	IMAD	\N	\N	XX	1306959903
100002652	100002637	DN	1	AAMIR	KHAN	\N	\N	XX	8888888888
100002690	100002676	DN	1	SALMAN	KHAN	\N	\N	XX	8888888888
100002728	100002714	DN	1	SALINSKY	PARED	\N	\N	XX	1295762433
100002766	100002752	DN	1	SHARUKH	KHAN	\N	\N	XX	1234678901
100002804	100002790	DN	1	SHARUKH	KHAN	\N	\N	XX	1234678901
100002842	100002828	DN	1	SHARUKH	KHAN	\N	\N	XX	1234678901
100002880	100002866	DN	1	DIANA	HYDEN	\N	\N	XX	1234678901
100002919	100002904	DN	1	HERRAKA	IHAB	\N	\N	XX	1174610018
\.


--
-- Data for Name: prof_2310b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2310b (id, claim_id, rendering_provider_entity_identifier_code, rendering_provider_entity_qualifier, rendering_provider_last_name, rendering_provider_first_name, rendering_provider_middle_name_or_initial, rendering_provider_name_suffix, rendering_provider_identification_code_qualifier, rendering_provider_identifier, rendering_provider_code, rendering_provider_code_qual, rendering_provider_taxonomy_code) FROM stdin;
100002279	100002259	82	1	POHN	ABRAHAM	M	\N	XX	6666666666	\N	\N	\N
100002388	100002372	82	1	PAVIT	PAUL	B	\N	XX	7777777777	\N	\N	\N
100002425	100002411	82	1	APAY	THOMAS	\N	\N	XX	1234678910	\N	\N	\N
100002501	100002485	82	1	MANOP	BAPPAI	\N	\N	XX	1123467641	\N	\N	\N
100002538	100002524	82	1	SHERMAN	POHN	P	\N	XX	1295089910	\N	\N	\N
100002576	100002561	82	1	RANVEER	SINGH	D	\N	XX	7777788999	PE	PXC	208G00000X
100002614	100002599	82	1	SHAHOUT	MOHAMED	\N	\N	XX	1073573598	\N	\N	\N
100002653	100002637	82	1	SALMAN	KHAN	\N	\N	XX	8888888888	\N	\N	\N
100002691	100002676	82	1	AAMIR	KHAN	C	\N	XX	8888888888	\N	\N	\N
100002729	100002714	82	1	URBANOWSKI	PAUL	\N	\N	XX	1841390796	\N	\N	\N
100002767	100002752	82	1	AJAY	THARAYIL	S	\N	XX	9999988888	PE	PXC	207XS0106X
100002805	100002790	82	1	SALMAN	KHAN	P	\N	XX	8888888888	PE	PXC	363L00000X
100002843	100002828	82	1	ARUN	JACOB	\N	\N	XX	1234678901	PE	PXC	363A00000X
100002881	100002866	82	1	ANDREW	YOUSSEF	S	\N	XX	1234678901	\N	\N	\N
100002920	100002904	82	1	SALMANR	AMONA	\N	\N	XX	8888888888	\N	\N	\N
\.


--
-- Data for Name: prof_2310c; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2310c (id, claim_id, service_facility_entity_identifier_code, service_facility_entity_type_qualifier, service_facility_last_organization_name, service_facility_identifier_qual, service_facility_primary_identifier, service_facility_address_line1, service_facility_address_line2, service_facility_city_name, service_facility_state_or_province_code, service_facility_postal_zone_or_zip_code, country_code, country_subdivision_code, service_facility_contact_function_code, service_facility_contact_name, service_facility_communication_number_qualifier, service_facility_communication_number, service_facility_communication_number_qualifier2, service_facility_communication_number2) FROM stdin;
100002280	100002259	77	2	AMRITA ENDOSCOPY AND SURGERY CENTER	XX	5555555555	1222 MG ROAD	\N	KOCHI	KL	346134898	\N	\N	\N	\N	\N	\N	\N	\N
100002318	100002302	77	2	KERALA HOSPITAL	\N	\N	3100 E  MARINE AVE	\N	KOCHI	KL	336134613	\N	\N	\N	\N	\N	\N	\N	\N
100002389	100002372	77	2	KOCHI GENERAL HOSPITAL	XX	1234677890	1 KOCHI GENERAL CIRCLE	\N	KOCHI	KL	336063508	\N	\N	\N	\N	\N	\N	\N	\N
100002426	100002411	77	2	KOCHINL HOSPITAL	XX	1234678911	11375 MARINE DR	\N	KOCHI	KL	346135409	\N	\N	\N	\N	\N	\N	\N	\N
100002502	100002485	77	2	AMRITA ENDOSCOPY AND SURGERY CENTER	XX	5555555555	1222 MG ROAD	\N	KOCHI	KL	346134898	\N	\N	\N	\N	\N	\N	\N	\N
100002539	100002524	77	2	MISSION HOSPITAL INPATIENT	XX	1881626075	509 BILTMORE AVE	\N	ASHEVILLE	KL	288014601	\N	\N	\N	\N	\N	\N	\N	\N
100002577	100002561	77	2	RAMANAN PLANT HOSP	XX	1376529743	300 PABAPABA STREET	\N	SEAWATER	KL	337563804	\N	\N	\N	\N	\N	\N	\N	\N
100002615	100002599	77	2	KOCHINL HOSPITAL	XX	1234678911	11375 MARINE DR	\N	KOCHI	KL	346135409	\N	\N	\N	\N	\N	\N	\N	\N
100002654	100002637	77	2	AMRITA ENDOSCOPY AND SURGERY CENTER	XX	5555555555	1222 MG ROAD	\N	KOCHI	KL	346134898	\N	\N	\N	\N	\N	\N	\N	\N
100002692	100002676	77	2	KOCHINL HOSPITAL	XX	1234678911	11375 MARINE DR	\N	KOCHI	KL	346135409	\N	\N	\N	\N	\N	\N	\N	\N
100002730	100002714	77	2	KOCHINL HOSPITAL	XX	1234678911	11375 MARINE DR	\N	BROOKSVLLIE	KL	346135409	\N	\N	\N	\N	\N	\N	\N	\N
100002768	100002752	77	2	KOCHIN REGIONAL MEDICAL CENTER	XX	9088880000	14000 FIVAY RD	\N	KOCHIN	KL	346677103	\N	\N	\N	\N	\N	\N	\N	\N
100002806	100002790	77	2	KOCHIN REGIONAL MEDICAL CENTER	XX	9088880000	14000 FIVAY RD	\N	KOCHIN	KL	346677103	\N	\N	\N	\N	\N	\N	\N	\N
100002844	100002828	77	2	KOCHIN REGIONAL MEDICAL CENTER	XX	9088880000	14000 FIVAY RD	\N	KOCHIN	KL	346677103	\N	\N	\N	\N	\N	\N	\N	\N
100002921	100002904	77	2	AMRITA ENDOSCOPY AND SURGERY CENTER	XX	5555555555	1222 MG ROAD	\N	KOCHI	KL	346134898	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: prof_2310d; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2310d (id, claim_id, supervising_provider_entity_identifier_code, supervising_provider_entity_qualifier, supervising_provider_last_name, supervising_provider_first_name, supervising_provider_middle_name_or_initial, supervising_provider_name_suffix, supervising_provider_identification_code_qualifier, supervising_provider_identifier, supervising_provider_code, supervising_provider_code_qual, supervising_provider_taxonomy_code) FROM stdin;
\.


--
-- Data for Name: prof_2310e; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2310e (id, claim_id, ambulance_pickup_entity_identifier_code, ambulance_pickup_entity_type_qualifier, ambulance_pickup_address_line1, ambulance_pickup_address_line2, ambulance_pickup_city_name, ambulance_pickup_state_or_province_code, ambulance_pickup_postal_zone_or_zip_code, country_code, country_subdivision_code) FROM stdin;
\.


--
-- Data for Name: prof_2310f; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2310f (id, claim_id, ambulance_drop_off_entity_identifier_code, ambulance_drop_off_entity_type_qualifier, ambulance_drop_off_location, ambulance_drop_off_address_line1, ambulance_drop_off_address_line2, ambulance_drop_off_city_name, ambulance_drop_off_state_or_province_code, ambulance_drop_off_postal_zone_or_zip_code, country_code, country_subdivision_code) FROM stdin;
\.


--
-- Data for Name: prof_2320; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2320 (id, claim_id, payer_responsibility, subscriber_individual_relationship_code, subscriber_group, subscriber_group_name, subscriber_insurance_type_code, claim_filing_indicator_code, benefits_assignment_certification_indicator, patient_signature_source_code, release_of_information_code, reimbursement_rate, hcpcs_payable_amount, claim_payment_remark_code1, claim_payment_remark_code2, claim_payment_remark_code3, claim_payment_remark_code4, claim_payment_remark_code5, esrd_payment_amount, non_payable_professional_component_billed_amount) FROM stdin;
100002281	100002259	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002319	100002302	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002390	100002372	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002427	100002411	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002464	100002448	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002503	100002485	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002540	100002524	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002578	100002561	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002616	100002599	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002655	100002637	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002693	100002676	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002731	100002714	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002769	100002752	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002807	100002790	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002845	100002828	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002882	100002866	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
100002922	100002904	P	18	CLM00001	\N	\N	16	Y	\N	Y	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: prof_2330a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2330a (id, claim_id, other_subscriber_entity_identifier_code, other_subscriber_entity_identifier_qual, other_subscriber_last_name, other_subscriber_first_name, other_subscriber_middle_name, other_subscriber_name_suffix, other_subscriber_identification_code_qualifier, other_subscriber_primary_identifier, other_subscriber_address1, other_subscriber_address2, other_subscriber_city_name, other_subscriber_state_or_province_code, other_subscriber_postal_zone_or_zip_code, other_subscriber_country_code, other_subscriber_country_sub_code, other_subscriber_secondary_identification_qual, other_subscriber_social_security_number) FROM stdin;
100002284	100002259	IL	1	OOMMAN	CHAANDI	P	\N	MI	X68X83X73X7	1236 FEDERAL BANK BUILD	\N	KOCHI	KL	346139998	\N	\N	\N	\N
100002322	100002302	IL	1	SHAPI	ADOOR	A	\N	MI	XKRXYTXMEX5	2646 MARINE DR	\N	HOLIDAY	KL	346919998	\N	\N	\N	\N
100002393	100002372	IL	1	SHAPI	ADOOR	A	\N	MI	XKRXYTXMEX5	2646 MARINE DR	\N	HOLIDAY	KL	346919998	\N	\N	\N	\N
100002430	100002411	IL	1	SHAHRUKH	KHAN	E	\N	MI	XTPXEEXFQX8	14948 MARINE AVE	\N	KOCHI	KL	346139998	\N	\N	\N	\N
100002467	100002448	IL	1	IDAVELA	BABU	D	\N	MI	XDPXFCXPFX4	7424 POYES KLRDEN	\N	KOCHI	KL	346069998	\N	\N	\N	\N
100002506	100002485	IL	1	SALIM	KUMAR	P	\N	MI	XP1XFFXYRX3	7360 MARINE MEADOW DR	\N	KOCHI	KL	346069998	\N	\N	\N	\N
100002543	100002524	IL	1	PAGDISH	KUMAR	F	\N	MI	XUGXGWXCEX7	13002 TITLEIST DR	\N	KOCHIN	KL	346699998	\N	\N	\N	\N
100002581	100002561	IL	1	ARUN	POHN	P	\N	MI	XV4XV3XCGX8	8023 MARINE AVE	\N	KOCHI	KL	346139998	\N	\N	\N	\N
100002619	100002599	IL	1	LAURENCE	MICHAEL	N	\N	MI	XHDXVX2TX06	41 NESAMANI CIR	\N	HAILESA	KL	344469998	\N	\N	\N	\N
100002658	100002637	IL	1	DASAMOOLAM	DAMU	A	\N	MI	XC0XP6XXTX3	7151 MARINE AVE	\N	KOCHI	KL	346139998	\N	\N	\N	\N
100002696	100002676	IL	1	SRANK	HARBOR	M	\N	MI	XNQXXKXEX41	PO BOX 1907	\N	HAILESA HAILESA	KL	344479998	\N	\N	\N	\N
100002734	100002714	IL	1	APPUKKUTTAN	L	P	\N	MI	XN2XPUXTCX2	18736 HARIHAR NAGAR ST	APT 106	KOCHIN	KL	346679998	\N	\N	\N	\N
100002772	100002752	IL	1	ANJALI	AMIR	A	\N	MI	XRFXA9XNGX0	13725 ANAYARA DR	APT 106	KOCHIN	KL	346699998	\N	\N	\N	\N
100002810	100002790	IL	1	ANJALI	AMIR	A	\N	MI	XRFXA9XNGX0	13725 ANAYARA DR	APT 106	KOCHIN	KL	346699998	\N	\N	\N	\N
100002848	100002828	IL	1	ANJALI	AMIR	A	\N	MI	XRFXA9XNGX0	13725 ANAYARA DR	APT 106	KOCHIN	KL	346699998	\N	\N	\N	\N
100002885	100002866	IL	1	AJAY	MACKAN	A	\N	MI	2HX5UX6TX6X	12332 ZEPHYER COCHIN	APT 106	KOCHI	KL	346149998	\N	\N	\N	\N
100002925	100002904	IL	1	HARIZ	JAYRAJ	K	\N	MI	XK2XTQXQWX8	9479 PALARIVATTAM ROAD	APT 106	KOCHI	KL	346089998	\N	\N	\N	\N
\.


--
-- Data for Name: prof_2330b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2330b (id, claim_id, other_payer_entity_identifier_code, other_payer_entity_identifier_qual, other_payer_last_name, other_payer_identification_code_qualifier, other_payer_primary_identifier, other_payer_address1, other_payer_address2, other_payer_city_name, other_payer_state_or_province_code, other_payer_postal_zone_or_zip_code, other_payer_country_code, other_payer_country_sub_code, date_claim_paid_qual, date_claim_paid_format, adjudication_date) FROM stdin;
100002285	100002259	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002323	100002302	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002394	100002372	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002431	100002411	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002468	100002448	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002507	100002485	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002544	100002524	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002582	100002561	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002620	100002599	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002659	100002637	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002697	100002676	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002735	100002714	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002773	100002752	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002811	100002790	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002849	100002828	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002886	100002866	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
100002926	100002904	PR	2	UNITED INDIA HEALTH PLANS, KL	XV	H9999	201 DESADANAM BUILD	SUITE 1800	KOCHI	KL	336029998	\N	\N	\N	\N	\N
\.


--
-- Data for Name: prof_2330c; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2330c (id, claim_id, other_payer_refer_provider_entity_identifier_code, other_payer_refer_provider_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: prof_2330d; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2330d (id, claim_id, other_payer_render_provider_entity_identifier_code, other_payer_render_provider_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: prof_2330e; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2330e (id, claim_id, other_payer_svc_location_entity_identifier_code, other_payer_svc_location_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: prof_2330f; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2330f (id, claim_id, other_payer_spvc_provider_entity_identifier_code, other_payer_spvc_provider_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: prof_2330g; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2330g (id, claim_id, other_payer_billing_provider_entity_identifier_code, other_payer_billing_provider_entity_identifier_qual) FROM stdin;
\.


--
-- Data for Name: prof_2400; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2400 (id, claim_id, segment_number, claim_line_number, procedure_code_qualifier, procedure_code, procedure_modifier1, procedure_modifier2, procedure_modifier3, procedure_modifier4, procedure_code_description, line_item_charge_amount, unit_or_basis_for_measurement, service_unit_count, place_of_service_code, diagnosis_code_pointer1, diagnosis_code_pointer2, diagnosis_code_pointer3, diagnosis_code_pointer4, emergency_indicator, epsdt_indicator, family_planning_indicator, copay_status_code, dme_procedure_identifier, dme_procedure_code, dme_unit_or_basis_for_measurement, length_of_medical_necessity, dme_rental_price, dme_purchase_price, rental_unit_price_indicator, ambulance_patient_measurement, ambulance_patient_weight, ambulance_transport_reason_code, ambulance_transportation_measurement, ambulance_transport_distance, ambulance_round_trip_purpose_description, ambulance_stretcher_purpose_description, dme_certification_type_code, dme_duration_measurement_unit, durable_medical_equipment_duration, contract_type_code, contract_amount, contract_percentage, contract_code, terms_discount_percentage, contract_version_identifier, purchased_service_provider_identifier, purchased_service_charge_amount, pricing_methodology, repriced_allowed_amount, repriced_saving_amount, repricing_organization_identifier, repricing_per_diem_or_flat_rate_amount, repriced_approved_ambulatory_patient_group_code, repriced_approved_ambulatory_patient_group_amount, product_or_service_id_qualifier, repriced_approved_hcpcs_code, basis_for_measurement_code, repriced_approved_service_unit_count, reject_reason_code, policy_compliance_code, exception_code, line_hash, dup_line, remit_line_match_status) FROM stdin;
100002289	100002259	47	1	HC	00811	QZ	\N	\N	\N	\N	450.00	MP	6	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	702630d7789a6145fa3220191ada2d4d	f	\N
100002327	100002302	90	1	HC	99291	\N	\N	\N	\N	\N	400.00	UN	1	\N	1	2	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	8462f27349ed2de1f46513bd6561194a	f	\N
100002343	100002302	96	2	HC	99232	\N	\N	\N	\N	\N	150.00	UN	1	\N	1	2	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	76e1e0ae3fbc7c7800dbb76fc5a49942	f	\N
100002359	100002302	102	3	HC	99232	\N	\N	\N	\N	\N	150.00	UN	1	\N	1	2	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	8f3d31bbae1e47d6837f9e0004afd243	f	\N
100002398	100002372	144	1	HC	71045	26	\N	\N	\N	\N	25.00	UN	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	77ac396611bc8ceed9b6143dad1364a1	f	\N
100002435	100002411	184	1	HC	99233	\N	\N	\N	\N	\N	180.00	UN	1	\N	1	2	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	470c0137da1a3804bafe01b7946af7eb	f	\N
100002472	100002448	222	1	HC	14060	79	\N	\N	\N	\N	1680.00	UN	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	da77e8015b6310c7b437836f7620325e	f	\N
100002511	100002485	264	1	HC	00731	QZ	\N	\N	\N	\N	450.00	MP	6	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	5408dbf9b78556e7aa18c6d955cef9a8	f	\N
100002548	100002524	304	1	HC	99233	\N	\N	\N	\N	\N	150.00	UN	1	\N	1	2	3	4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0f5bbd01d254dbbea24d87ac617210de	f	\N
100002586	100002561	347	1	HC	99231	\N	\N	\N	\N	\N	90.00	UN	1	\N	1	2	3	4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3a14f6f954680f952b44dab856d57621	f	\N
100002624	100002599	389	1	HC	64447	XU	\N	\N	\N	\N	204.00	UN	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	e1c8b4f0757845a82ffdcde7a939fe3a	f	\N
100002663	100002637	431	1	HC	00731	QZ	\N	\N	\N	\N	525.00	MP	7	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	53ff8db6b3871f416a201ae68869acf8	f	\N
100002701	100002676	472	1	HC	00811	QZ	QS	P3	\N	\N	812.50	MP	23	\N	1	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	67ae1c8b7b481e02b4cfc8e36e23f324	f	\N
100002739	100002714	513	1	HC	01214	AA	CC	P3	\N	\N	1587.50	MP	101	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	678ee2c98918fda4caf68e826f55dfae	f	\N
100002777	100002752	557	1	HC	27245	LT	\N	\N	\N	\N	6468.00	UN	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	a9fa54efbdd6f5adcaa46cd873d7e12f	f	\N
100002815	100002790	601	1	HC	99222	57	\N	\N	\N	\N	688.00	UN	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3f81c15e17a2a58091bd55e6badf40f1	f	\N
100002853	100002828	645	1	HC	27245	AS	LT	\N	\N	\N	600.00	UN	1	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	ba40970f8e5b54e477f35d84dc3c8d2e	f	\N
100002890	100002866	684	1	HC	99214	\N	\N	\N	\N	\N	144.00	UN	1	\N	1	2	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	cbfa7760ae61b1b03a6b8ab2260560a5	f	\N
100002930	100002904	726	1	HC	00731	QZ	\N	\N	\N	\N	525.00	MP	7	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	dd9854b00a145b599c0523e09cd13ad9	f	\N
\.


--
-- Data for Name: prof_2410; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2410 (id, claim_id, claim_line_number, national_drug_code_qual, national_drug_code, national_drug_unit_count, code_qualifier) FROM stdin;
\.


--
-- Data for Name: prof_2420a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2420a (id, claim_id, claim_line_number, rendering_provider_entity_identifier_code, rendering_provider_entity_qualifier, rendering_provider_last_name, rendering_provider_first_name, rendering_provider_middle_name_or_initial, rendering_provider_name_suffix, rendering_provider_identification_code_qualifier, rendering_provider_identifier, rendering_provider_code, rendering_provider_code_qual, rendering_provider_taxonomy_code) FROM stdin;
\.


--
-- Data for Name: prof_2420b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2420b (id, claim_id, claim_line_number, purchased_svc_provider_entity_identifier_code, purchased_svc_provider_entity_qualifier, purchased_svc_provider_identification_code_qualifier, purchased_svc_provider_identifier) FROM stdin;
\.


--
-- Data for Name: prof_2420c; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2420c (id, claim_id, claim_line_number, service_facility_entity_identifier_code, service_facility_entity_type_qualifier, service_facility_last_organization_name, service_facility_identifier_qual, service_facility_primary_identifier, service_facility_address_line1, service_facility_address_line2, service_facility_city_name, service_facility_state_or_province_code, service_facility_postal_zone_or_zip_code, country_code, country_subdivision_code) FROM stdin;
\.


--
-- Data for Name: prof_2420d; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2420d (id, claim_id, claim_line_number, supervising_provider_entity_identifier_code, supervising_provider_entity_qualifier, supervising_provider_last_name, supervising_provider_first_name, supervising_provider_middle_name_or_initial, supervising_provider_name_suffix, supervising_provider_identification_code_qualifier, supervising_provider_identifier) FROM stdin;
\.


--
-- Data for Name: prof_2420e; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2420e (id, claim_id, claim_line_number, ordering_provider_entity_identifier_code, ordering_provider_entity_qualifier, ordering_provider_last_name, ordering_provider_first_name, ordering_provider_middle_name_or_initial, ordering_provider_name_suffix, ordering_provider_identification_code_qualifier, ordering_provider_identifier, ordering_address_line1, ordering_address_line2, ordering_city_name, ordering_state_or_province_code, ordering_postal_zone_or_zip_code, country_code, country_subdivision_code, ordering_provider_contact_function_code, ordering_provider_contact_name, ordering_provider_communication_number_qualifier1, ordering_provider_communication_number1, ordering_provider_communication_number_qualifier2, ordering_provider_communication_number2, ordering_provider_communication_number_qualifier3, ordering_provider_communication_number3) FROM stdin;
\.


--
-- Data for Name: prof_2420f; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2420f (id, claim_id, claim_line_number, referring_provider_entity_identifier_code, referring_provider_entity_qualifier, referring_provider_last_name, referring_provider_first_name, referring_provider_middle_name_or_initial, referring_provider_name_suffix, referring_provider_identification_code_qualifier, referring_provider_identifier) FROM stdin;
\.


--
-- Data for Name: prof_2420g; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2420g (id, claim_id, claim_line_number, ambulance_pickup_entity_identifier_code, ambulance_pickup_entity_type_qualifier, ambulance_pickup_address_line1, ambulance_pickup_address_line2, ambulance_pickup_city_name, ambulance_pickup_state_or_province_code, ambulance_pickup_postal_zone_or_zip_code, country_code, country_subdivision_code) FROM stdin;
\.


--
-- Data for Name: prof_2420h; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2420h (id, claim_id, claim_line_number, ambulance_drop_off_entity_identifier_code, ambulance_drop_off_entity_type_qualifier, ambulance_drop_off_location, ambulance_drop_off_address_line1, ambulance_drop_off_address_line2, ambulance_drop_off_city_name, ambulance_drop_off_state_or_province_code, ambulance_drop_off_postal_zone_or_zip_code, country_code, country_subdivision_code) FROM stdin;
\.


--
-- Data for Name: prof_2430; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2430 (id, claim_id, claim_line_number, other_payer_primary_identifier, service_line_paid_amount, product_or_service_id_qualifier, procedure_code, procedure_modifier1, procedure_modifier2, procedure_modifier3, procedure_modifier4, procedure_code_description, paid_service_unit_count, bundled_or_unbundled_line_number, date_claim_paid, date_time_period_format_qualifier, adjudication_or_payment_date, amount_qualifier_code, remaining_patient_liability) FROM stdin;
100002297	100002259	1	H9999	86.51	HC	00811	QZ	\N	\N	\N	\N	6	\N	573	D8	20210321	\N	\N
100002335	100002302	1	H9999	224.66	HC	99291	\N	\N	\N	\N	\N	1	\N	573	D8	20210803	\N	\N
100002351	100002302	2	H9999	72.97	HC	99232	\N	\N	\N	\N	\N	1	\N	573	D8	20210803	\N	\N
100002367	100002302	3	H9999	72.97	HC	99232	\N	\N	\N	\N	\N	1	\N	573	D8	20210803	\N	\N
100002406	100002372	1	H9999	9.17	HC	71045	26	\N	\N	\N	\N	1	\N	573	D8	20210808	\N	\N
100002443	100002411	1	H9999	104.47	HC	99233	\N	\N	\N	\N	\N	1	\N	573	D8	20210803	\N	\N
100002480	100002448	1	H9999	778.72	HC	14060	79	\N	\N	\N	\N	1	\N	573	D8	20210831	\N	\N
100002519	100002485	1	H9999	110.3	HC	00731	QZ	\N	\N	\N	\N	6	\N	573	D8	20210907	\N	\N
100002556	100002524	1	H9999	85.5	HC	99233	\N	\N	\N	\N	\N	1	\N	573	D8	20210921	\N	\N
100002594	100002561	1	H9999	39.43	HC	99231	\N	\N	\N	\N	\N	1	\N	573	D8	20210919	\N	\N
100002632	100002599	1	H9999	68.4	HC	64447	XU	\N	\N	\N	\N	1	\N	573	D8	20211003	\N	\N
100002671	100002637	1	H9999	110.3	HC	00731	QZ	\N	\N	\N	\N	7	\N	573	D8	20211005	\N	\N
100002709	100002676	1	H9999	132.36	HC	00811	QZ	QS	P3	\N	\N	23	\N	573	D8	20211026	\N	\N
100002747	100002714	1	H9999	330.9	HC	01214	AA	CC	P3	\N	\N	101	\N	573	D8	20211121	\N	\N
100002785	100002752	1	H9999	1275.06	HC	27245	LT	\N	\N	\N	\N	1	\N	573	D8	20190109	\N	\N
100002823	100002790	1	H9999	116.8	HC	99222	57	\N	\N	\N	\N	1	\N	573	D8	20190109	\N	\N
100002861	100002828	1	H9999	173.41	HC	27245	AS	LT	\N	\N	\N	1	\N	573	D8	20190109	\N	\N
100002898	100002866	1	H9999	87.26	HC	99214	\N	\N	\N	\N	\N	1	\N	573	D8	20190222	\N	\N
100002938	100002904	1	H9999	110.69	HC	00731	QZ	\N	\N	\N	\N	7	\N	573	D8	20190410	\N	\N
\.


--
-- Data for Name: prof_2440; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_2440 (id, claim_id, claim_line_number, form_identifier_qual, form_identifier, question_number, question_response, question_response_desc, question_response_date, question_response_percentage) FROM stdin;
\.


--
-- Data for Name: prof_bht; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_bht (id, record_type, file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, transaction_set_control_number, hierarchical_structure_code, transaction_set_purpose_code, batch_control_number, date, "time", claim_identifier) FROM stdin;
100002260	\N	100000002	000108258	ENC0001	80882	108258	0001	0019	00	20190912000522.1650+0000	20190912	0005	CH
\.


--
-- Data for Name: prof_claim_data; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_claim_data (id, claim_id, data) FROM stdin;
\.


--
-- Data for Name: prof_claim_identifier; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_claim_identifier (id, h_plan_id, plan_id, patient_control_number, linked_patient_control_number, beneficiary_first_name, beneficiary_last_name, place_of_service, begin_date_of_service, end_date_of_service, submission_date, claim_frequency_code, encounter_or_chart_review, beneficiary_member_identifier, rendering_provider_npi, total_claim_charge_amount, payer_amount_paid, cmsicn, payer_claim_control_number, source, encounter_status, encounter_status_type, encounter_status_code, encounter_reject_category, file_id, linked_provider_clm_id, h_plan_submitter_id, last_updated, date_created, modified_by, segment_number, interchange_sender_id, interchange_receiver_id, interchange_control_number, group_control_number, batch_control_number, transaction_set_control_number, st_index, billing_provider_hierarchical_id_number, billing_provider_npi, raps_extract_status, encounter_revision) FROM stdin;
100002259	2	HX96X	CLM180750002500	\N	CHAANDI	OOMMAN	22	20210228	20180228	190912	1	EN	X68X83X73X7	6666666666	450	86.51	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	47	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	1	9999999999	\N	1
100002411	2	H9999	CLM182110013300	\N	KHAN	SHAHRUKH	21	20210613	20180613	190912	1	EN	XTPXEEXFQX8	1234678910	180	104.47	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	184	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	7	1528196847	\N	1
100002448	2	H9999	CLM182410026100	\N	BABU	IDAVELA	11	20210822	20180822	190912	1	EN	XDPXFCXPFX4	9876432100	1680	778.72	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	222	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	9	9876432100	\N	1
100002485	2	H9999	CLM182480018000	\N	KUMAR	SALIM	22	20210816	20180816	190912	1	EN	XP1XFFXYRX3	1123467641	450	110.30	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	264	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	11	9999999999	\N	1
100002524	2	H9999	CLM182550003600	\N	KUMAR	PAGDISH	21	20210820	20180820	190912	1	EN	XUGXGWXCEX7	1295089910	150	85.50	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	304	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	13	1234432111	\N	1
100002561	2	H9999	CLM182570001300	\N	POHN	ARUN	21	20210729	20180729	190912	1	EN	XV4XV3XCGX8	7777788999	90	39.43	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	347	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	15	1213131313	\N	1
100002302	2	H9999	CLM182000000400	\N	ADOOR	SHAPI	21	20210611	20180613	190912	1	EN	XKRXYTXMEX5	4444444444	700	370.60	1925541686087	\N	ENCOUNTER	REJECTED	MAO-002	\N	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	102	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	3	4444444444	\N	1
100002372	2	H9999	CLM182000045100	\N	ADOOR	SHAPI	21	20210628	20180628	190912	1	EN	XKRXYTXMEX5	7777777777	25	9.17	1925541686091	\N	ENCOUNTER	REJECTED	MAO-002	02110	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	144	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	5	2222222222	\N	1
100002599	2	H9999	CLM182680019600	\N	MICHAEL	LAURENCE	21	20210731	20180731	190912	1	EN	XHDXVX2TX06	1073573598	204	68.40	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	389	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	17	1678901010	\N	1
100002637	2	H9999	CLM182760006800	\N	DAMU	DASAMOOLAM	22	20210919	20180919	190912	1	EN	XC0XP6XXTX3	8888888888	525	110.30	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	431	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	19	9999999999	\N	1
100002676	2	H9999	CLM182880007200	\N	HARBOR	SRANK	21	20210911	20180911	190912	1	EN	XNQXXKXEX41	8888888888	812.5	132.36	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	472	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	21	1678901010	\N	1
100002714	2	H9999	CLM183180006300	\N	L	APPUKKUTTAN	21	20211008	20181008	190912	1	EN	XN2XPUXTCX2	1841390796	1587.5	330.90	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	513	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	23	1678901010	\N	1
100002752	2	H9999	CLM190050062200	\N	AMIR	ANJALI	21	20211230	20181230	190912	1	EN	XRFXA9XNGX0	9999988888	6468	1275.06	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	557	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	25	1234678901	\N	1
100002790	2	H9999	CLM190050062300	\N	AMIR	ANJALI	21	20211230	20181230	190912	1	EN	XRFXA9XNGX0	8888888888	688	116.80	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	601	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	27	1234678901	\N	1
100002828	2	H9999	CLM190050062400	\N	AMIR	ANJALI	21	20211230	20181230	190912	1	EN	XRFXA9XNGX0	1234678901	600	173.41	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	645	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	29	1234678901	\N	1
100002866	2	H9999	CLM190520022900	\N	MACKAN	AJAY	11	20190204	20190204	190912	1	EN	2HX5UX6TX6X	1234678901	144	87.26	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	684	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	31	1962699959	\N	1
100002904	2	H9999	CLM190950005300	\N	JAYRAJ	HARIZ	22	20190319	20190319	190912	1	EN	XK2XTQXQWX8	8888888888	525	110.69	\N	\N	ENCOUNTER	REJECTED	277	A7	\N	100000002	\N	1	2022-11-14 02:05:37.118184	2022-11-14 02:05:37.118184	\N	726	ENC0001	80882	000108258	108258	20190912000522.1650+0000	0001	1	33	9999999999	\N	1
\.


--
-- Data for Name: prof_claim_line_data; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_claim_line_data (id, claim_id, claim_line_number, data) FROM stdin;
\.


--
-- Data for Name: prof_header_trailer; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_header_trailer (id, record_type, file_id, authorization_information_qualifier, authorization_information, security_information_qualifier, security_information, interchange_sender_id_qualifier, interchange_sender_id, interchange_receiver_id_qualifier, interchange_receiver_id, interchange_date, interchange_time, repetition_separator, interchange_control_version_number, interchange_control_number, acknowledgment_requested, interchange_usage_indicator, component_element_separator, functional_identifier_code, application_senders_code, application_receivers_code, group_header_date, group_header_time, group_control_number, responsible_agency_code, industry_identifier_code, number_of_transaction_sets_included, trailer_group_control_number, number_of_included_functional_groups) FROM stdin;
100006621	HEADER_TRAILER	100000002	00	\N	00	\N	ZZ	ENC0001	ZZ	80882	190912	0005	<	00501	000108258	0	P	:	HC	ENC0001	80882	20190912	0005	108258	X	005010X222A1	1	108258	\N
\.


--
-- Data for Name: prof_se; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_se (id, record_type, file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, transaction_segment_count, transaction_set_control_number) FROM stdin;
100002943	\N	100000002	000108258	ENC0001	80882	108258	727	0001
\.


--
-- Data for Name: prof_st; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.prof_st (id, record_type, file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, st_index, transaction_set_identifier_code, transaction_set_control_number, implementation_convention_reference) FROM stdin;
100002261	\N	100000002	000108258	ENC0001	80882	108258	1	837	0001	005010X222A1
\.


--
-- Data for Name: provider_837_remit_mapping; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.provider_837_remit_mapping (id, ref_provider_claim_id, ref_remit_id) FROM stdin;
\.


--
-- Data for Name: raps_cluster; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.raps_cluster (id, h_plan_id, plan_id, sender_id, raps_file_id, transaction_date, diag_type, member_id, file_type, bbb_seq_number, ccc_seq_number, seq_error_code, patient_control_number, member_id_error_code, patient_dob, dob_error_code, provider_type, from_date, thru_date, delete_ind, diagnosis_code, diag_cluster_error1, diag_cluster_error2, corrected_medicare_id, risk_assessment_code, risk_assessment_code_error, hicn, cluster_status, feras_error_code, internal_claim_id, submission_file_id, last_updated) FROM stdin;
\.


--
-- Data for Name: raps_cluster_history; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.raps_cluster_history (id, h_plan_id, plan_id, sender_id, raps_file_id, transaction_date, diag_type, member_id, file_type, bbb_seq_number, ccc_seq_number, seq_error_code, patient_control_number, member_id_error_code, patient_dob, dob_error_code, provider_type, from_date, thru_date, delete_ind, diagnosis_code, diag_cluster_error1, diag_cluster_error2, corrected_medicare_id, risk_assessment_code, risk_assessment_code_error, hicn, cluster_status, feras_error_code, internal_claim_id, submission_file_id) FROM stdin;
\.


--
-- Data for Name: raps_cms_tracking; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.raps_cms_tracking (id, h_plan_id, raps_file_id, sender_id, plan_id, submission_file_id, submission_date, return_file_id, feras_file_id, dupx_file_id, error_report_file_id, summary_report_file_id, file_status, feras_error_code) FROM stdin;
\.


--
-- Data for Name: raps_eef; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.raps_eef (id, h_plan_id, raps_file_id, sender_id, plan_id, interchange_control_number, interchange_date, member_id, file_type, encounter_type, plan_claim_number, internal_claim_id, patient_control_number, patient_dob, from_date, thru_date, delete_indicator, replace_indicator, duplicate_indicator, diagnosis_type, diagnosis_code_type, diagnosis_code, member_first_name, member_last_name, member_middle_name, member_gender, hicn, billing_provider_taxonomy_code, rendering_provider_taxonomy_code, attending_provider_taxonomy_code, facility_type_code, place_of_service_code, frequency_code, provider_type, eef_source_file_name, source, pcp_id, pcp_name, bill_type, ineligible_reason, encounter_timestamp, "timestamp", current_extract_timestamp, raps_extract_status) FROM stdin;
\.


--
-- Data for Name: raps_feras_error; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.raps_feras_error (id, h_plan_id, submission_file_id, feras_file_id) FROM stdin;
\.


--
-- Data for Name: raps_file; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.raps_file (id, a_id, source_file_name, file_status, file_processed_status, file_url, raps_eef_type, manual_update_comment, retry_count, last_updated, db_load_timestamp, feras_error_code) FROM stdin;
\.


--
-- Data for Name: remit_1000a; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.remit_1000a (id, file_id, entity_identifier_code, payer_name, identification_code_qualifier, payer_identifier, entity_relationship_code, entity_identifier_code_6, payer_address_line, payer_address_line_2, payer_city_name, payer_state_code, payer_postal_zone_or_zip_code, country_code, location_qualifier, location_identifier, country_subdivision_code) FROM stdin;
\.


--
-- Data for Name: remit_1000b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.remit_1000b (id, file_id, entity_identifier_code, payee_name, identification_code_qualifier, payee_identification_code, entity_relationship_code, entity_identifier_code_6, payee_address_line, payee_address_line_2, payee_city_name, payee_state_code, payee_postal_zone_or_zip_code, country_code, location_qualifier, location_identifier, country_subdivision_code, reference_identification_qualifier, additional_payee_identifier, description, reference_identifier, report_transmission_code, name, communication_number, reference_identifier_4, reference_identifier_5) FROM stdin;
\.


--
-- Data for Name: remit_2000; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.remit_2000 (id, file_id, remittance_id, assigned_number, provider_identifier, facility_type_code, fiscal_period_date, total_claim_count, total_claim_charge_amount, monetary_amount, monetary_amount_7, monetary_amount_8, monetary_amount_9, monetary_amount_10, monetary_amount_11, monetary_amount_12, total_msp_payer_amount, monetary_amount_14, total_non_lab_charge_amount, monetary_amount_16, total_hcpcs_reported_charge_amount, total_hcpcs_payable_amount, monetary_amount_19, total_professional_component_amount, total_msp_patient_liability_met_amount, total_patient_reimbursement_amount, total_pip_claim_count, total_pip_adjustment_amount, total_drg_amount, total_federal_specific_amount, total_hospital_specific_amount, total_disproportionate_share_amount, total_capital_amount, total_indirect_medical_education_amount, total_outlier_day_count, total_day_outlier_amount, total_cost_outlier_amount, average_drg_length_of_stay, total_discharge_count, total_cost_report_day_count, total_covered_day_count, total_non_covered_day_count, total_msp_pass_through_amount, average_drg_weight, total_pps_capital_fsp_drg_amount, total_pps_capital_hsp_drg_amount, total_pps_dsh_drg_amount) FROM stdin;
\.


--
-- Data for Name: remit_2100; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.remit_2100 (id, remittance_id, patient_control_number, claim_status_code, total_claim_charge_amount, claim_payment_amount, patient_responsibility_amount, claim_filing_indicator_code, payer_claim_control_number, facility_type_code, claim_frequency_code, patient_status_code, diagnosis_related_group_drg_code, diagnosis_related_group_drg_weight, discharge_fraction, yes_no_condition_response_code, covered_days_or_visits_count, pps_operating_outlier_amount, lifetime_psychiatric_days_count, claim_drg_amount, claim_payment_remark_code, claim_disproportionate_share_amount, claim_msp_pass_through_amount, claim_pps_capital_amount, pps_capital_fsp_drg_amount, pps_capital_hsp_drg_amount, pps_capital_dsh_drg_amount, old_capital_amount, pps_capital_ime_amount, pps_operating_hospital_specific_drg_amount, cost_report_day_count, pps_operating_federal_specific_drg_amount, claim_pps_capital_outlier_amount, claim_indirect_teaching_amount, non_payable_professional_component_amount, claim_payment_remark_code_20, claim_payment_remark_code_21, claim_payment_remark_code_22, claim_payment_remark_code_23, pps_capital_exception_amount, reimbursement_rate, claim_hcpcs_payable_amount, claim_payment_remark_code_3, claim_payment_remark_code_4, claim_payment_remark_code_5, claim_payment_remark_code_6, claim_payment_remark_code_7, claim_esrd_payment_amount, non_payable_professional_component_amount_9) FROM stdin;
\.


--
-- Data for Name: remit_2110; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.remit_2110 (id, remittance_id, remit_line_number, product_or_service_id_qualifier, adjudicated_procedure_code, procedure_modifier, procedure_modifier_1_3, procedure_modifier_1_4, procedure_modifier_1_5, description, product_service_id, line_item_charge_amount, line_item_provider_payment_amount, national_uniform_billing_committee_revenue_code, units_of_service_paid_count, product_or_service_id_qualifier_6_0, procedure_code, procedure_modifier_6_2, procedure_modifier_6_3, procedure_modifier_6_4, procedure_modifier_6_5, procedure_code_description, product_service_id_6_7, original_units_of_service_count) FROM stdin;
\.


--
-- Data for Name: remit_bht; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.remit_bht (id, file_id, transaction_handling_code, total_actual_provider_payment_amount, credit_or_debit_flag_code, payment_method_code, payment_format_code, dfi_qualifier, sender_dfi_identifier, account_number_qualifier, sender_bank_account_number, payer_identifier, originating_company_supplemental_code, dfi_qualifier_12, receiver_or_provider_bank_id_number, account_number_qualifier_14, receiver_or_provider_account_number, check_issue_or_eft_effective_date, business_function_code, dfi_id_number_qualifier, dfi_identification_number, account_number_qualifier_20, account_number, trace_type_code, check_or_eft_trace_number, payer_identifier_3, originating_company_supplemental_code_4, entity_identifier_code, currency_code, exchange_rate, entity_identifier_code_4, currency_code_5, currency_market_exchange_code, date_time_qualifier, date, "time", date_time_qualifier_10, date_11, time_12, date_time_qualifier_13, date_14, time_15, date_time_qualifier_16, date_17, time_18, date_time_qualifier_19, date_20, time_21, date_time_qualifier_1, production_date, time_3, time_code, date_time_period_format_qualifier, date_time_period) FROM stdin;
\.


--
-- Data for Name: remit_footer; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.remit_footer (id, file_id, provider_identifier, fiscal_period_date, adjustment_reason_code, provider_adjustment_identifier, provider_adjustment_amount, adjustment_reason_code_5_0, provider_adjustment_identifier_5_1, provider_adjustment_amount_6, adjustment_reason_code_7_0, provider_adjustment_identifier_7_1, provider_adjustment_amount_8, adjustment_reason_code_9_0, provider_adjustment_identifier_9_1, provider_adjustment_amount_10, adjustment_reason_code_11_0, provider_adjustment_identifier_11_1, provider_adjustment_amount_12, adjustment_reason_code_13_0, provider_adjustment_identifier_13_1, provider_adjustment_amount_14) FROM stdin;
\.


--
-- Data for Name: remit_header_trailer; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.remit_header_trailer (id, record_type, file_id, authorization_information_qualifier, authorization_information, security_information_qualifier, security_information, interchange_sender_id_qualifier, interchange_sender_id, interchange_receiver_id_qualifier, interchange_receiver_id, interchange_date, interchange_time, repetition_separator, interchange_control_version_number, interchange_control_number, acknowledgment_requested, interchange_usage_indicator, component_element_separator, functional_identifier_code, application_senders_code, application_receivers_code, group_header_date, group_header_time, group_control_number, responsible_agency_code, industry_identifier_code, number_of_transaction_sets_included, trailer_group_control_number, number_of_included_functional_groups) FROM stdin;
\.


--
-- Data for Name: remit_identifier; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.remit_identifier (id, h_plan_id, plan_id, file_id, last_updated, date_created, modified_by, file_submission_date, patient_control_number, beneficiary_member_identifier, begin_date_of_service, end_date_of_service, total_claim_charge_amount, claim_payment_amount, payer_claim_control_number, facility_type_code, claim_frequency_code, st_index, remit_status) FROM stdin;
\.


--
-- Data for Name: remit_st; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.remit_st (id, file_id, st_index, transaction_set_identifier_code, transaction_set_control_number, implementation_convention_reference) FROM stdin;
\.


--
-- Data for Name: report_category; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.report_category (id, report_name, category, default_email) FROM stdin;
1	INVALID_X12_FILE	edps-op	
\.


--
-- Data for Name: report_details; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.report_details (id, report_category_id, authority, default_email_cc, user_name) FROM stdin;
1	1			
\.


--
-- Data for Name: report_subscription; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.report_subscription (id, report_details_id, email) FROM stdin;
\.


--
-- Data for Name: report_type; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.report_type (name, notification_type, phi_data) FROM stdin;
INVALID_X12_FILE	INFO	f
\.


--
-- Data for Name: resp_277_2000b; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_277_2000b (id, resp_file_id, transaction_set_control_number, information_receiver_name, claim_transaction_batch_number, information_receiver_status) FROM stdin;
100000014	100000000	000000001	MIRRA HEALTH	20190912000522.1650+0000	WQ
\.


--
-- Data for Name: resp_277_2000c; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_277_2000c (id, resp_file_id, transaction_set_control_number, st_index, segment_number, claim_transaction_batch_number, billing_provider_name, provider_of_service_information_trace_id, billing_provider_status, full_status_code, status_code, secondary_status_code, tertiary_status_code, accepted_claim_quantity, total_accepted_amount) FROM stdin;
100000011	100000000	000000001	1	21	20190912000522.1650+0000	AMRITA INSTITUTE OF MEDICAL RESEARCH	CLM180750002500	WQ	A1:19:PR	A1	\N	\N	1	450
100000023	100000000	000000001	1	33	20190912000522.1650+0000	AMRITA PULMONARY	CLM182000000400	WQ	A1:19:PR	A1	\N	\N	1	700
100000030	100000000	000000001	1	46	20190912000522.1650+0000	RADIOLOGY OF KOCHI KL	CLM182000045100	WQ	A1:19:PR	A1	\N	\N	1	25
100000037	100000000	000000001	1	59	20190912000522.1650+0000	ST POHNS HOSPITAL	CLM182110013300	WQ	A1:19:PR	A1	\N	\N	1	180
100000043	100000000	000000001	1	71	20190912000522.1650+0000	KRISHNAN KUTTI MD	CLM182410026100	WQ	A1:19:PR	A1	\N	\N	1	1680
100000049	100000000	000000001	1	83	20190912000522.1650+0000	AMRITA INSTITUTE OF MEDICAL RESEARCH	CLM182480018000	WQ	A1:19:PR	A1	\N	\N	1	450
100000055	100000000	000000001	1	95	20190912000522.1650+0000	KIMS NEUROLOGY	CLM182550003600	WQ	A1:19:PR	A1	\N	\N	1	150
100000061	100000000	000000001	1	107	20190912000522.1650+0000	KOCHIN MEDICAL GROUP	CLM182570001300	WQ	A1:19:PR	A1	\N	\N	1	90
100000067	100000000	000000001	1	119	20190912000522.1650+0000	ANESTHESIOLOGIST ASSOC KOCHIN	CLM182680019600	WQ	A1:19:PR	A1	\N	\N	1	204
100000073	100000000	000000001	1	131	20190912000522.1650+0000	AMRITA INSTITUTE OF MEDICAL RESEARCH	CLM182760006800	WQ	A1:19:PR	A1	\N	\N	1	525
100000080	100000000	000000001	1	144	20190912000522.1650+0000	ANESTHESIOLOGIST ASSOC KOCHIN	CLM182880007200	WQ	A1:19:PR	A1	\N	\N	1	812.5
100000086	100000000	000000001	1	156	20190912000522.1650+0000	ANESTHESIOLOGISTS ASSOC KOCHIN	CLM183180006300	WQ	A1:19:PR	A1	\N	\N	1	1587.5
100000092	100000000	000000001	1	168	20190912000522.1650+0000	THE CENTER FOR BONE DISEASE	CLM190050062200	WQ	A1:19:PR	A1	\N	\N	1	6468
100000098	100000000	000000001	1	180	20190912000522.1650+0000	THE CENTER FOR BONE DISEASE	CLM190050062300	WQ	A1:19:PR	A1	\N	\N	1	688
100000104	100000000	000000001	1	192	20190912000522.1650+0000	THE CENTER FOR BONE DISEASE	CLM190050062400	WQ	A1:19:PR	A1	\N	\N	1	600
100000110	100000000	000000001	1	204	20190912000522.1650+0000	ALI AKBAR	CLM190520022900	WQ	A1:19:PR	A1	\N	\N	1	144
100000116	100000000	000000001	1	216	20190912000522.1650+0000	AMRITA INSTITUTE OF MEDICAL RESEARCH	CLM190950005300	WQ	A1:19:PR	A1	\N	\N	1	525
\.


--
-- Data for Name: resp_277_2000d; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_277_2000d (id, resp_file_id, transaction_set_control_number, st_index, segment_number, claim_transaction_batch_number, patient_first_name, patient_last_name, patient_control_number, billing_provider_status, full_status_code, status_code, secondary_status_code, tertiary_status_code) FROM stdin;
100000015	100000000	000000001	1	24	20190912000522.1650+0000	OOMMAN	CHAANDI	CLM180750002500	\N	\N	\N	\N	\N
100000024	100000000	000000001	1	36	20190912000522.1650+0000	SHAPI	ADOOR	CLM182000000400	\N	\N	\N	\N	\N
100000031	100000000	000000001	1	49	20190912000522.1650+0000	SHAPI	ADOOR	CLM182000045100	\N	\N	\N	\N	\N
100000038	100000000	000000001	1	62	20190912000522.1650+0000	SHAHRUKH	KHAN	CLM182110013300	\N	\N	\N	\N	\N
100000044	100000000	000000001	1	74	20190912000522.1650+0000	IDAVELA	BABU	CLM182410026100	\N	\N	\N	\N	\N
100000050	100000000	000000001	1	86	20190912000522.1650+0000	SALIM	KUMAR	CLM182480018000	\N	\N	\N	\N	\N
100000056	100000000	000000001	1	98	20190912000522.1650+0000	PAGDISH	KUMAR	CLM182550003600	\N	\N	\N	\N	\N
100000062	100000000	000000001	1	110	20190912000522.1650+0000	ARUN	POHN	CLM182570001300	\N	\N	\N	\N	\N
100000068	100000000	000000001	1	122	20190912000522.1650+0000	LAURENCE	MICHAEL	CLM182680019600	\N	\N	\N	\N	\N
100000074	100000000	000000001	1	134	20190912000522.1650+0000	DASAMOOLAM	DAMU	CLM182760006800	\N	\N	\N	\N	\N
100000081	100000000	000000001	1	147	20190912000522.1650+0000	SRANK	HARBOR	CLM182880007200	\N	\N	\N	\N	\N
100000087	100000000	000000001	1	159	20190912000522.1650+0000	APPUKKUTTAN	L	CLM183180006300	\N	\N	\N	\N	\N
100000093	100000000	000000001	1	171	20190912000522.1650+0000	ANJALI	AMIR	CLM190050062200	\N	\N	\N	\N	\N
100000099	100000000	000000001	1	183	20190912000522.1650+0000	ANJALI	AMIR	CLM190050062300	\N	\N	\N	\N	\N
100000105	100000000	000000001	1	195	20190912000522.1650+0000	ANJALI	AMIR	CLM190050062400	\N	\N	\N	\N	\N
100000111	100000000	000000001	1	207	20190912000522.1650+0000	AJAY	MACKAN	CLM190520022900	\N	\N	\N	\N	\N
100000117	100000000	000000001	1	219	20190912000522.1650+0000	HARIZ	JAYRAJ	CLM190950005300	\N	\N	\N	\N	\N
\.


--
-- Data for Name: resp_277_2220d; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_277_2220d (id, resp_file_id, transaction_set_control_number, st_index, segment_number, claim_transaction_batch_number, patient_control_number, ref_reject_code, line_item_control_number, ref_6r_value) FROM stdin;
\.


--
-- Data for Name: resp_277_bht; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_277_bht (id, resp_file_id, transaction_set_control_number, batch_control_number, date_of_response, time_of_response) FROM stdin;
100000010	100000000	000000001	19255	20190912	142620
\.


--
-- Data for Name: resp_277_header_trailer; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_277_header_trailer (id, record_type, resp_file_id, authorization_information_qualifier, authorization_information, security_information_qualifier, security_information, interchange_sender_id_qualifier, interchange_sender_id, interchange_receiver_id_qualifier, interchange_receiver_id, interchange_date, interchange_time, repetition_separator, interchange_control_version_number, interchange_control_number, acknowledgment_requested, interchange_usage_indicator, component_element_separator, functional_identifier_code, application_senders_code, application_receivers_code, group_header_date, group_header_time, group_control_number, responsible_agency_code, industry_identifier_code, number_of_transaction_sets_included, trailer_group_control_number, number_of_included_functional_groups) FROM stdin;
100000233	HEADER_TRAILER	100000000	00	\N	00	\N	ZZ	80882	ZZ	ENC0001	190912	1426	^	00501	000108258	0	P	:	HN	80882	ENC0001	20190912	142620	1	X	005010X214	1	1	\N
\.


--
-- Data for Name: resp_277_st; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_277_st (id, record_type, resp_file_id, interchange_control_number, interchange_sender_id, interchange_receiver_id, group_control_number, st_index, transaction_set_identifier_code, transaction_set_control_number, implementation_convention_reference) FROM stdin;
100000012	\N	100000000	000108258	80882	ENC0001	1	1	277	000000001	005010X214
\.


--
-- Data for Name: resp_999_2000; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_999_2000 (id, resp_file_id, record_type, interchange_sender_id, interchange_control_number, interchange_receiver_id, group_control_number, transaction_set_control_number, batch_control_number, ak_transaction_set_control_number, transaction_set_status) FROM stdin;
100002244	100000001	\N	80882	000407664	ENC0001	1	0001	108258	0001	A
\.


--
-- Data for Name: resp_999_2100; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_999_2100 (id, resp_file_id, record_type, interchange_sender_id, interchange_control_number, interchange_receiver_id, group_control_number, transaction_set_control_number, batch_control_number, ak_transaction_set_control_number, transaction_set_error_code, error_segment_id_code, error_segment_position, loop_identifier_code, segment_syntax_error_code) FROM stdin;
\.


--
-- Data for Name: resp_999_2110; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_999_2110 (id, resp_file_id, record_type, interchange_sender_id, interchange_control_number, interchange_receiver_id, group_control_number, transaction_set_control_number, batch_control_number, ak_transaction_set_control_number, element_position_in_segment, component_data_element_position, element_error_code) FROM stdin;
\.


--
-- Data for Name: resp_999_bht; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_999_bht (id, record_type, interchange_sender_id, interchange_control_number, interchange_receiver_id, group_control_number, transaction_set_control_number, functional_identifier_code, batch_control_number, industry_identifier_code, functional_group_acknowledge_code, number_of_transaction_sets, functional_group_syntax_error_code, resp_file_id, is_response_applied_status, retry_count) FROM stdin;
100002243	\N	80882	000407664	ENC0001	1	0001	HC	108258	005010X222A1	A	1	\N	100000001	APPLIED_999	0
\.


--
-- Data for Name: resp_999_header_trailer; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_999_header_trailer (id, record_type, resp_file_id, authorization_information_qualifier, authorization_information, security_information_qualifier, security_information, interchange_sender_id_qualifier, interchange_sender_id, interchange_receiver_id_qualifier, interchange_receiver_id, interchange_date, interchange_time, repetition_separator, interchange_control_version_number, interchange_control_number, acknowledgment_requested, interchange_usage_indicator, component_element_separator, functional_identifier_code, application_senders_code, application_receivers_code, group_header_date, group_header_time, group_control_number, responsible_agency_code, industry_identifier_code, number_of_transaction_sets_included, trailer_group_control_number, number_of_included_functional_groups) FROM stdin;
100002249	HEADER_TRAILER	100000001	00	\N	00	\N	ZZ	80882	ZZ	ENC0001	190912	1422	^	00501	000407664	0	P	:	FA	80882	ENC0001	20190912	142233	1	X	005010X231A1	1	1	\N
\.


--
-- Data for Name: resp_mao_1; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_mao_1 (id, resp_file_id, interchange_sender_id, interchange_control_number, interchange_date, medicare_contract_id, plan_icn, encounter_icn, encounter_line_number, duplicate_plan_icn, duplicate_encounter_icn, duplicate_encounter_line_number, beneficiary_hicn, date_of_service, error_code) FROM stdin;
100000244	100000243	ENC0001	000108258	20190912	H9999	CLM182000000400	1804380098981	001	CLM173620003400	1802680030191	001	3X3X97X33X	20171227	98325
100000245	100000243	ENC0001	000108258	20190912	H9999	CLM182000000400	1804380098981	002	CLM173620003400	1802680030191	002	3X3X97X33X	20171227	98325
100000246	100000243	ENC0001	000108258	20190912	H9999	CLM182000000400	1804380098981	003	CLM173620003400	1802680030191	003	3X3X97X33X	20171227	98325
\.


--
-- Data for Name: resp_mao_2; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_mao_2 (id, resp_file_id, interchange_control_number, medicare_contract_id, plan_icn, encounter_icn, encounter_line_number, encounter_status, error_code, error_description) FROM stdin;
100001244	100001243	000108258	H9999	CLM182000000400	1925541686087	000	REJECTED	\N	\N
100001245	100001243	000108258	H9999	CLM182000000400	1925541686087	001	REJECTED	98325	SERVICE LINE DUPLICATE
100001246	100001243	000108258	H9999	CLM182000000400	1925541686087	002	REJECTED	98325	SERVICE LINE DUPLICATE
100001247	100001243	000108258	H9999	CLM182000000400	1925541686087	003	REJECTED	98325	SERVICE LINE DUPLICATE
100001248	100001243	000108258	H9999	CLM182000045100	1925541686091	000	REJECTED	02110	BENEFICIARY HICN NOT ON FILE
100001249	100001243	000108258	H9999	CLM182000045100	1925541686091	001	REJECTED	\N	\N
\.


--
-- Data for Name: resp_mao_4; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_mao_4 (id, resp_file_id, plan_id, report_date, beneficiary_id, encounter_icn, encounter_type_switch, linked_encounter_icn, linked_encounter_allowed_disallowed, encounter_submission_date, from_date, through_date, service_type, allowed_disallowed, allowed_disallowed_reason_code, diagnoses_icd, diagnosis_code, add_delete_ind) FROM stdin;
\.


--
-- Data for Name: resp_ta1_data; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_ta1_data (id, resp_file_id, interchange_control_number, interchange_date, interchange_time, interchange_ack_code, interchange_note_code) FROM stdin;
100006631	100000003	700086007	200102	0902	R	014
\.


--
-- Data for Name: resp_ta1_header_trailer; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.resp_ta1_header_trailer (id, record_type, resp_file_id, authorization_information_qualifier, authorization_information, security_information_qualifier, security_information, interchange_sender_id_qualifier, interchange_sender_id, interchange_receiver_id_qualifier, interchange_receiver_id, interchange_date, interchange_time, repetition_separator, interchange_control_version_number, interchange_control_number, acknowledgment_requested, interchange_usage_indicator, component_element_separator, functional_identifier_code, application_senders_code, application_receivers_code, group_header_date, group_header_time, group_control_number, responsible_agency_code, industry_identifier_code, number_of_transaction_sets_included, trailer_group_control_number, number_of_included_functional_groups) FROM stdin;
100006634	HEADER_TRAILER	100000003	00	\N	00	\N	ZZ	80882	ZZ	ENC0001	200102	0902	^	00501	700086007	0	P	:	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0
\.


--
-- Data for Name: segment_data_00; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_00 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: segment_data_01; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_01 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
2000A	432	HL	100002676	\N	100000002
2010AA	433	NM1	100002676	\N	100000002
2010AA	434	N3	100002676	\N	100000002
2010AA	435	N4	100002676	\N	100000002
2010AA	436	REF	100002676	\N	100000002
2000B	437	HL	100002676	\N	100000002
2000B	438	SBR	100002676	\N	100000002
2010BA	439	NM1	100002676	\N	100000002
2010BA	440	N3	100002676	\N	100000002
2010BA	441	N4	100002676	\N	100000002
2010BA	442	DMG	100002676	\N	100000002
2010BB	443	NM1	100002676	\N	100000002
2010BB	444	N3	100002676	\N	100000002
2010BB	445	N4	100002676	\N	100000002
2010BB	446	REF	100002676	\N	100000002
2300	447	CLM	100002676	\N	100000002
2300	448	DTP	100002676	\N	100000002
2300	449	PWK	100002676	\N	100000002
2300	450	REF	100002676	\N	100000002
2300	451	REF	100002676	\N	100000002
2300	452	HI	100002676	\N	100000002
2310A	453	NM1	100002676	\N	100000002
2310B	454	NM1	100002676	\N	100000002
2310C	455	NM1	100002676	\N	100000002
2310C	456	N3	100002676	\N	100000002
2310C	457	N4	100002676	\N	100000002
2320	458	SBR	100002676	\N	100000002
2320	459	AMT	100002676	\N	100000002
2320	460	OI	100002676	\N	100000002
2330A	461	NM1	100002676	\N	100000002
2330A	462	N3	100002676	\N	100000002
2330A	463	N4	100002676	\N	100000002
2330B	464	NM1	100002676	\N	100000002
2330B	465	N3	100002676	\N	100000002
2330B	466	N4	100002676	\N	100000002
2400	467	LX	100002676	100002701	100000002
2400	468	SV1	100002676	100002701	100000002
2400	469	DTP	100002676	100002701	100000002
2430	470	SVD	100002676	100002701	100000002
2430	471	CAS	100002676	100002701	100000002
2430	472	DTP	100002676	100002701	100000002
\.


--
-- Data for Name: segment_data_02; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_02 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
2000A	185	HL	100002448	\N	100000002
2010AA	186	NM1	100002448	\N	100000002
2010AA	187	N3	100002448	\N	100000002
2010AA	188	N4	100002448	\N	100000002
2010AA	189	REF	100002448	\N	100000002
2000B	190	HL	100002448	\N	100000002
2000B	191	SBR	100002448	\N	100000002
2010BA	192	NM1	100002448	\N	100000002
2010BA	193	N3	100002448	\N	100000002
2010BA	194	N4	100002448	\N	100000002
2010BA	195	DMG	100002448	\N	100000002
2010BB	196	NM1	100002448	\N	100000002
2010BB	197	N3	100002448	\N	100000002
2010BB	198	N4	100002448	\N	100000002
2010BB	199	REF	100002448	\N	100000002
2300	200	CLM	100002448	\N	100000002
2300	201	DTP	100002448	\N	100000002
2300	202	DTP	100002448	\N	100000002
2300	203	PWK	100002448	\N	100000002
2300	204	REF	100002448	\N	100000002
2300	205	REF	100002448	\N	100000002
2300	206	HI	100002448	\N	100000002
2310A	207	NM1	100002448	\N	100000002
2320	208	SBR	100002448	\N	100000002
2320	209	AMT	100002448	\N	100000002
2320	210	OI	100002448	\N	100000002
2330A	211	NM1	100002448	\N	100000002
2330A	212	N3	100002448	\N	100000002
2330A	213	N4	100002448	\N	100000002
2330B	214	NM1	100002448	\N	100000002
2330B	215	N3	100002448	\N	100000002
2330B	216	N4	100002448	\N	100000002
2400	217	LX	100002448	100002472	100000002
2400	218	SV1	100002448	100002472	100000002
2400	219	DTP	100002448	100002472	100000002
2430	220	SVD	100002448	100002472	100000002
2430	221	CAS	100002448	100002472	100000002
2430	222	DTP	100002448	100002472	100000002
2000A	646	HL	100002866	\N	100000002
2010AA	647	NM1	100002866	\N	100000002
2010AA	648	N3	100002866	\N	100000002
2010AA	649	N4	100002866	\N	100000002
2010AA	650	REF	100002866	\N	100000002
2000B	651	HL	100002866	\N	100000002
2000B	652	SBR	100002866	\N	100000002
2010BA	653	NM1	100002866	\N	100000002
2010BA	654	N3	100002866	\N	100000002
2010BA	655	N4	100002866	\N	100000002
2010BA	656	DMG	100002866	\N	100000002
2010BB	657	NM1	100002866	\N	100000002
2010BB	658	N3	100002866	\N	100000002
2010BB	659	N4	100002866	\N	100000002
2010BB	660	REF	100002866	\N	100000002
2300	661	CLM	100002866	\N	100000002
2300	662	DTP	100002866	\N	100000002
2300	663	DTP	100002866	\N	100000002
2300	664	PWK	100002866	\N	100000002
2300	665	REF	100002866	\N	100000002
2300	666	HI	100002866	\N	100000002
2310A	667	NM1	100002866	\N	100000002
2310B	668	NM1	100002866	\N	100000002
2320	669	SBR	100002866	\N	100000002
2320	670	AMT	100002866	\N	100000002
2320	671	OI	100002866	\N	100000002
2330A	672	NM1	100002866	\N	100000002
2330A	673	N3	100002866	\N	100000002
2330A	674	N4	100002866	\N	100000002
2330B	675	NM1	100002866	\N	100000002
2330B	676	N3	100002866	\N	100000002
2330B	677	N4	100002866	\N	100000002
2400	678	LX	100002866	100002890	100000002
2400	679	SV1	100002866	100002890	100000002
2400	680	DTP	100002866	100002890	100000002
2430	681	SVD	100002866	100002890	100000002
2430	682	CAS	100002866	100002890	100000002
2430	683	CAS	100002866	100002890	100000002
2430	684	DTP	100002866	100002890	100000002
\.


--
-- Data for Name: segment_data_03; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_03 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: segment_data_04; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_04 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: segment_data_05; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_05 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
2000A	145	HL	100002411	\N	100000002
2010AA	146	NM1	100002411	\N	100000002
2010AA	147	N3	100002411	\N	100000002
2010AA	148	N4	100002411	\N	100000002
2010AA	149	REF	100002411	\N	100000002
2000B	150	HL	100002411	\N	100000002
2000B	151	SBR	100002411	\N	100000002
2010BA	152	NM1	100002411	\N	100000002
2010BA	153	N3	100002411	\N	100000002
2010BA	154	N4	100002411	\N	100000002
2010BA	155	DMG	100002411	\N	100000002
2010BB	156	NM1	100002411	\N	100000002
2010BB	157	N3	100002411	\N	100000002
2010BB	158	N4	100002411	\N	100000002
2010BB	159	REF	100002411	\N	100000002
2300	160	CLM	100002411	\N	100000002
2300	161	DTP	100002411	\N	100000002
2300	162	PWK	100002411	\N	100000002
2300	163	REF	100002411	\N	100000002
2300	164	HI	100002411	\N	100000002
2310A	165	NM1	100002411	\N	100000002
2310B	166	NM1	100002411	\N	100000002
2310C	167	NM1	100002411	\N	100000002
2310C	168	N3	100002411	\N	100000002
2310C	169	N4	100002411	\N	100000002
2320	170	SBR	100002411	\N	100000002
2320	171	AMT	100002411	\N	100000002
2320	172	OI	100002411	\N	100000002
2330A	173	NM1	100002411	\N	100000002
2330A	174	N3	100002411	\N	100000002
2330A	175	N4	100002411	\N	100000002
2330B	176	NM1	100002411	\N	100000002
2330B	177	N3	100002411	\N	100000002
2330B	178	N4	100002411	\N	100000002
2400	179	LX	100002411	100002435	100000002
2400	180	SV1	100002411	100002435	100000002
2400	181	DTP	100002411	100002435	100000002
2430	182	SVD	100002411	100002435	100000002
2430	183	CAS	100002411	100002435	100000002
2430	184	DTP	100002411	100002435	100000002
\.


--
-- Data for Name: segment_data_06; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_06 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
2000A	265	HL	100002524	\N	100000002
2010AA	266	NM1	100002524	\N	100000002
2010AA	267	N3	100002524	\N	100000002
2010AA	268	N4	100002524	\N	100000002
2010AA	269	REF	100002524	\N	100000002
2000B	270	HL	100002524	\N	100000002
2000B	271	SBR	100002524	\N	100000002
2010BA	272	NM1	100002524	\N	100000002
2010BA	273	N3	100002524	\N	100000002
2010BA	274	N4	100002524	\N	100000002
2010BA	275	DMG	100002524	\N	100000002
2010BB	276	NM1	100002524	\N	100000002
2010BB	277	N3	100002524	\N	100000002
2010BB	278	N4	100002524	\N	100000002
2010BB	279	REF	100002524	\N	100000002
2300	280	CLM	100002524	\N	100000002
2300	281	DTP	100002524	\N	100000002
2300	282	PWK	100002524	\N	100000002
2300	283	REF	100002524	\N	100000002
2300	284	REF	100002524	\N	100000002
2300	285	HI	100002524	\N	100000002
2310B	286	NM1	100002524	\N	100000002
2310C	287	NM1	100002524	\N	100000002
2310C	288	N3	100002524	\N	100000002
2310C	289	N4	100002524	\N	100000002
2320	290	SBR	100002524	\N	100000002
2320	291	AMT	100002524	\N	100000002
2320	292	OI	100002524	\N	100000002
2330A	293	NM1	100002524	\N	100000002
2330A	294	N3	100002524	\N	100000002
2330A	295	N4	100002524	\N	100000002
2330B	296	NM1	100002524	\N	100000002
2330B	297	N3	100002524	\N	100000002
2330B	298	N4	100002524	\N	100000002
2400	299	LX	100002524	100002548	100000002
2400	300	SV1	100002524	100002548	100000002
2400	301	DTP	100002524	100002548	100000002
2430	302	SVD	100002524	100002548	100000002
2430	303	CAS	100002524	100002548	100000002
2430	304	DTP	100002524	100002548	100000002
\.


--
-- Data for Name: segment_data_07; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_07 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: segment_data_08; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_08 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: segment_data_09; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_09 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: segment_data_10; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_10 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
2000A	685	HL	100002904	\N	100000002
2010AA	686	NM1	100002904	\N	100000002
2010AA	687	N3	100002904	\N	100000002
2010AA	688	N4	100002904	\N	100000002
2010AA	689	REF	100002904	\N	100000002
2000B	690	HL	100002904	\N	100000002
2000B	691	SBR	100002904	\N	100000002
2010BA	692	NM1	100002904	\N	100000002
2010BA	693	N3	100002904	\N	100000002
2010BA	694	N4	100002904	\N	100000002
2010BA	695	DMG	100002904	\N	100000002
2010BB	696	NM1	100002904	\N	100000002
2010BB	697	N3	100002904	\N	100000002
2010BB	698	N4	100002904	\N	100000002
2010BB	699	REF	100002904	\N	100000002
2300	700	CLM	100002904	\N	100000002
2300	701	DTP	100002904	\N	100000002
2300	702	DTP	100002904	\N	100000002
2300	703	PWK	100002904	\N	100000002
2300	704	REF	100002904	\N	100000002
2300	705	REF	100002904	\N	100000002
2300	706	HI	100002904	\N	100000002
2310A	707	NM1	100002904	\N	100000002
2310B	708	NM1	100002904	\N	100000002
2310C	709	NM1	100002904	\N	100000002
2310C	710	N3	100002904	\N	100000002
2310C	711	N4	100002904	\N	100000002
2320	712	SBR	100002904	\N	100000002
2320	713	AMT	100002904	\N	100000002
2320	714	OI	100002904	\N	100000002
2330A	715	NM1	100002904	\N	100000002
2330A	716	N3	100002904	\N	100000002
2330A	717	N4	100002904	\N	100000002
2330B	718	NM1	100002904	\N	100000002
2330B	719	N3	100002904	\N	100000002
2330B	720	N4	100002904	\N	100000002
2400	721	LX	100002904	100002930	100000002
2400	722	SV1	100002904	100002930	100000002
2400	723	DTP	100002904	100002930	100000002
2430	724	SVD	100002904	100002930	100000002
2430	725	CAS	100002904	100002930	100000002
2430	726	DTP	100002904	100002930	100000002
SE	727	SE	100002904	\N	100000002
\.


--
-- Data for Name: segment_data_11; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_11 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
2000A	348	HL	100002599	\N	100000002
2010AA	349	NM1	100002599	\N	100000002
2010AA	350	N3	100002599	\N	100000002
2010AA	351	N4	100002599	\N	100000002
2010AA	352	REF	100002599	\N	100000002
2000B	353	HL	100002599	\N	100000002
2000B	354	SBR	100002599	\N	100000002
2010BA	355	NM1	100002599	\N	100000002
2010BA	356	N3	100002599	\N	100000002
2010BA	357	N4	100002599	\N	100000002
2010BA	358	DMG	100002599	\N	100000002
2010BB	359	NM1	100002599	\N	100000002
2010BB	360	N3	100002599	\N	100000002
2010BB	361	N4	100002599	\N	100000002
2010BB	362	REF	100002599	\N	100000002
2300	363	CLM	100002599	\N	100000002
2300	364	DTP	100002599	\N	100000002
2300	365	PWK	100002599	\N	100000002
2300	366	REF	100002599	\N	100000002
2300	367	REF	100002599	\N	100000002
2300	368	NTE	100002599	\N	100000002
2300	369	HI	100002599	\N	100000002
2310A	370	NM1	100002599	\N	100000002
2310B	371	NM1	100002599	\N	100000002
2310C	372	NM1	100002599	\N	100000002
2310C	373	N3	100002599	\N	100000002
2310C	374	N4	100002599	\N	100000002
2320	375	SBR	100002599	\N	100000002
2320	376	AMT	100002599	\N	100000002
2320	377	OI	100002599	\N	100000002
2330A	378	NM1	100002599	\N	100000002
2330A	379	N3	100002599	\N	100000002
2330A	380	N4	100002599	\N	100000002
2330B	381	NM1	100002599	\N	100000002
2330B	382	N3	100002599	\N	100000002
2330B	383	N4	100002599	\N	100000002
2400	384	LX	100002599	100002624	100000002
2400	385	SV1	100002599	100002624	100000002
2400	386	DTP	100002599	100002624	100000002
2430	387	SVD	100002599	100002624	100000002
2430	388	CAS	100002599	100002624	100000002
2430	389	DTP	100002599	100002624	100000002
2000A	473	HL	100002714	\N	100000002
2010AA	474	NM1	100002714	\N	100000002
2010AA	475	N3	100002714	\N	100000002
2010AA	476	N4	100002714	\N	100000002
2010AA	477	REF	100002714	\N	100000002
2000B	478	HL	100002714	\N	100000002
2000B	479	SBR	100002714	\N	100000002
2010BA	480	NM1	100002714	\N	100000002
2010BA	481	N3	100002714	\N	100000002
2010BA	482	N4	100002714	\N	100000002
2010BA	483	DMG	100002714	\N	100000002
2010BB	484	NM1	100002714	\N	100000002
2010BB	485	N3	100002714	\N	100000002
2010BB	486	N4	100002714	\N	100000002
2010BB	487	REF	100002714	\N	100000002
2300	488	CLM	100002714	\N	100000002
2300	489	DTP	100002714	\N	100000002
2300	490	PWK	100002714	\N	100000002
2300	491	REF	100002714	\N	100000002
2300	492	REF	100002714	\N	100000002
2300	493	HI	100002714	\N	100000002
2310A	494	NM1	100002714	\N	100000002
2310B	495	NM1	100002714	\N	100000002
2310C	496	NM1	100002714	\N	100000002
2310C	497	N3	100002714	\N	100000002
2310C	498	N4	100002714	\N	100000002
2320	499	SBR	100002714	\N	100000002
2320	500	AMT	100002714	\N	100000002
2320	501	OI	100002714	\N	100000002
2330A	502	NM1	100002714	\N	100000002
2330A	503	N3	100002714	\N	100000002
2330A	504	N4	100002714	\N	100000002
2330B	505	NM1	100002714	\N	100000002
2330B	506	N3	100002714	\N	100000002
2330B	507	N4	100002714	\N	100000002
2400	508	LX	100002714	100002739	100000002
2400	509	SV1	100002714	100002739	100000002
2400	510	DTP	100002714	100002739	100000002
2430	511	SVD	100002714	100002739	100000002
2430	512	CAS	100002714	100002739	100000002
2430	513	DTP	100002714	100002739	100000002
2000A	514	HL	100002752	\N	100000002
2010AA	515	NM1	100002752	\N	100000002
2010AA	516	N3	100002752	\N	100000002
2010AA	517	N4	100002752	\N	100000002
2010AA	518	REF	100002752	\N	100000002
2010AB	519	NM1	100002752	\N	100000002
2010AB	520	N3	100002752	\N	100000002
2010AB	521	N4	100002752	\N	100000002
2000B	522	HL	100002752	\N	100000002
2000B	523	SBR	100002752	\N	100000002
2010BA	524	NM1	100002752	\N	100000002
2010BA	525	N3	100002752	\N	100000002
2010BA	526	N4	100002752	\N	100000002
2010BA	527	DMG	100002752	\N	100000002
2010BB	528	NM1	100002752	\N	100000002
2010BB	529	N3	100002752	\N	100000002
2010BB	530	N4	100002752	\N	100000002
2010BB	531	REF	100002752	\N	100000002
2300	532	CLM	100002752	\N	100000002
2300	533	DTP	100002752	\N	100000002
2300	534	REF	100002752	\N	100000002
2300	535	REF	100002752	\N	100000002
2300	536	HI	100002752	\N	100000002
2310A	537	NM1	100002752	\N	100000002
2310B	538	NM1	100002752	\N	100000002
2310B	539	PRV	100002752	\N	100000002
2310C	540	NM1	100002752	\N	100000002
2310C	541	N3	100002752	\N	100000002
2310C	542	N4	100002752	\N	100000002
2320	543	SBR	100002752	\N	100000002
2320	544	AMT	100002752	\N	100000002
2320	545	OI	100002752	\N	100000002
2330A	546	NM1	100002752	\N	100000002
2330A	547	N3	100002752	\N	100000002
2330A	548	N4	100002752	\N	100000002
2330B	549	NM1	100002752	\N	100000002
2330B	550	N3	100002752	\N	100000002
2330B	551	N4	100002752	\N	100000002
2400	552	LX	100002752	100002777	100000002
2400	553	SV1	100002752	100002777	100000002
2400	554	DTP	100002752	100002777	100000002
2430	555	SVD	100002752	100002777	100000002
2430	556	CAS	100002752	100002777	100000002
2430	557	DTP	100002752	100002777	100000002
\.


--
-- Data for Name: segment_data_12; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_12 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: segment_data_13; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_13 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
2000A	602	HL	100002828	\N	100000002
2010AA	603	NM1	100002828	\N	100000002
2010AA	604	N3	100002828	\N	100000002
2010AA	605	N4	100002828	\N	100000002
2010AA	606	REF	100002828	\N	100000002
2010AB	607	NM1	100002828	\N	100000002
2010AB	608	N3	100002828	\N	100000002
2010AB	609	N4	100002828	\N	100000002
2000B	610	HL	100002828	\N	100000002
2000B	611	SBR	100002828	\N	100000002
2010BA	612	NM1	100002828	\N	100000002
2010BA	613	N3	100002828	\N	100000002
2010BA	614	N4	100002828	\N	100000002
2010BA	615	DMG	100002828	\N	100000002
2010BB	616	NM1	100002828	\N	100000002
2010BB	617	N3	100002828	\N	100000002
2010BB	618	N4	100002828	\N	100000002
2010BB	619	REF	100002828	\N	100000002
2300	620	CLM	100002828	\N	100000002
2300	621	DTP	100002828	\N	100000002
2300	622	REF	100002828	\N	100000002
2300	623	REF	100002828	\N	100000002
2300	624	HI	100002828	\N	100000002
2310A	625	NM1	100002828	\N	100000002
2310B	626	NM1	100002828	\N	100000002
2310B	627	PRV	100002828	\N	100000002
2310C	628	NM1	100002828	\N	100000002
2310C	629	N3	100002828	\N	100000002
2310C	630	N4	100002828	\N	100000002
2320	631	SBR	100002828	\N	100000002
2320	632	AMT	100002828	\N	100000002
2320	633	OI	100002828	\N	100000002
2330A	634	NM1	100002828	\N	100000002
2330A	635	N3	100002828	\N	100000002
2330A	636	N4	100002828	\N	100000002
2330B	637	NM1	100002828	\N	100000002
2330B	638	N3	100002828	\N	100000002
2330B	639	N4	100002828	\N	100000002
2400	640	LX	100002828	100002853	100000002
2400	641	SV1	100002828	100002853	100000002
2400	642	DTP	100002828	100002853	100000002
2430	643	SVD	100002828	100002853	100000002
2430	644	CAS	100002828	100002853	100000002
2430	645	DTP	100002828	100002853	100000002
\.


--
-- Data for Name: segment_data_14; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_14 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
ST	1	ST	100002259	\N	100000002
BHT	2	BHT	100002259	\N	100000002
1000A	3	NM1	100002259	\N	100000002
1000A	4	PER	100002259	\N	100000002
1000B	5	NM1	100002259	\N	100000002
2000A	6	HL	100002259	\N	100000002
2010AA	7	NM1	100002259	\N	100000002
2010AA	8	N3	100002259	\N	100000002
2010AA	9	N4	100002259	\N	100000002
2010AA	10	REF	100002259	\N	100000002
2000B	11	HL	100002259	\N	100000002
2000B	12	SBR	100002259	\N	100000002
2010BA	13	NM1	100002259	\N	100000002
2010BA	14	N3	100002259	\N	100000002
2010BA	15	N4	100002259	\N	100000002
2010BA	16	DMG	100002259	\N	100000002
2010BB	17	NM1	100002259	\N	100000002
2010BB	18	N3	100002259	\N	100000002
2010BB	19	N4	100002259	\N	100000002
2010BB	20	REF	100002259	\N	100000002
2300	21	CLM	100002259	\N	100000002
2300	22	DTP	100002259	\N	100000002
2300	23	DTP	100002259	\N	100000002
2300	24	PWK	100002259	\N	100000002
2300	25	REF	100002259	\N	100000002
2300	26	REF	100002259	\N	100000002
2300	27	HI	100002259	\N	100000002
2310A	28	NM1	100002259	\N	100000002
2310B	29	NM1	100002259	\N	100000002
2310C	30	NM1	100002259	\N	100000002
2310C	31	N3	100002259	\N	100000002
2310C	32	N4	100002259	\N	100000002
2320	33	SBR	100002259	\N	100000002
2320	34	AMT	100002259	\N	100000002
2320	35	OI	100002259	\N	100000002
2330A	36	NM1	100002259	\N	100000002
2330A	37	N3	100002259	\N	100000002
2330A	38	N4	100002259	\N	100000002
2330B	39	NM1	100002259	\N	100000002
2330B	40	N3	100002259	\N	100000002
2330B	41	N4	100002259	\N	100000002
2400	42	LX	100002259	100002289	100000002
2400	43	SV1	100002259	100002289	100000002
2400	44	DTP	100002259	100002289	100000002
2430	45	SVD	100002259	100002289	100000002
2430	46	CAS	100002259	100002289	100000002
2430	47	DTP	100002259	100002289	100000002
2000A	103	HL	100002372	\N	100000002
2010AA	104	NM1	100002372	\N	100000002
2010AA	105	N3	100002372	\N	100000002
2010AA	106	N4	100002372	\N	100000002
2010AA	107	REF	100002372	\N	100000002
2000B	108	HL	100002372	\N	100000002
2000B	109	SBR	100002372	\N	100000002
2010BA	110	NM1	100002372	\N	100000002
2010BA	111	N3	100002372	\N	100000002
2010BA	112	N4	100002372	\N	100000002
2010BA	113	DMG	100002372	\N	100000002
2010BB	114	NM1	100002372	\N	100000002
2010BB	115	N3	100002372	\N	100000002
2010BB	116	N4	100002372	\N	100000002
2010BB	117	REF	100002372	\N	100000002
2300	118	CLM	100002372	\N	100000002
2300	119	DTP	100002372	\N	100000002
2300	120	DTP	100002372	\N	100000002
2300	121	PWK	100002372	\N	100000002
2300	122	REF	100002372	\N	100000002
2300	123	REF	100002372	\N	100000002
2300	124	HI	100002372	\N	100000002
2310A	125	NM1	100002372	\N	100000002
2310B	126	NM1	100002372	\N	100000002
2310C	127	NM1	100002372	\N	100000002
2310C	128	N3	100002372	\N	100000002
2310C	129	N4	100002372	\N	100000002
2320	130	SBR	100002372	\N	100000002
2320	131	AMT	100002372	\N	100000002
2320	132	OI	100002372	\N	100000002
2330A	133	NM1	100002372	\N	100000002
2330A	134	N3	100002372	\N	100000002
2330A	135	N4	100002372	\N	100000002
2330B	136	NM1	100002372	\N	100000002
2330B	137	N3	100002372	\N	100000002
2330B	138	N4	100002372	\N	100000002
2400	139	LX	100002372	100002398	100000002
2400	140	SV1	100002372	100002398	100000002
2400	141	DTP	100002372	100002398	100000002
2430	142	SVD	100002372	100002398	100000002
2430	143	CAS	100002372	100002398	100000002
2430	144	DTP	100002372	100002398	100000002
2000A	558	HL	100002790	\N	100000002
2010AA	559	NM1	100002790	\N	100000002
2010AA	560	N3	100002790	\N	100000002
2010AA	561	N4	100002790	\N	100000002
2010AA	562	REF	100002790	\N	100000002
2010AB	563	NM1	100002790	\N	100000002
2010AB	564	N3	100002790	\N	100000002
2010AB	565	N4	100002790	\N	100000002
2000B	566	HL	100002790	\N	100000002
2000B	567	SBR	100002790	\N	100000002
2010BA	568	NM1	100002790	\N	100000002
2010BA	569	N3	100002790	\N	100000002
2010BA	570	N4	100002790	\N	100000002
2010BA	571	DMG	100002790	\N	100000002
2010BB	572	NM1	100002790	\N	100000002
2010BB	573	N3	100002790	\N	100000002
2010BB	574	N4	100002790	\N	100000002
2010BB	575	REF	100002790	\N	100000002
2300	576	CLM	100002790	\N	100000002
2300	577	DTP	100002790	\N	100000002
2300	578	REF	100002790	\N	100000002
2300	579	REF	100002790	\N	100000002
2300	580	HI	100002790	\N	100000002
2310A	581	NM1	100002790	\N	100000002
2310B	582	NM1	100002790	\N	100000002
2310B	583	PRV	100002790	\N	100000002
2310C	584	NM1	100002790	\N	100000002
2310C	585	N3	100002790	\N	100000002
2310C	586	N4	100002790	\N	100000002
2320	587	SBR	100002790	\N	100000002
2320	588	AMT	100002790	\N	100000002
2320	589	OI	100002790	\N	100000002
2330A	590	NM1	100002790	\N	100000002
2330A	591	N3	100002790	\N	100000002
2330A	592	N4	100002790	\N	100000002
2330B	593	NM1	100002790	\N	100000002
2330B	594	N3	100002790	\N	100000002
2330B	595	N4	100002790	\N	100000002
2400	596	LX	100002790	100002815	100000002
2400	597	SV1	100002790	100002815	100000002
2400	598	DTP	100002790	100002815	100000002
2430	599	SVD	100002790	100002815	100000002
2430	600	CAS	100002790	100002815	100000002
2430	601	DTP	100002790	100002815	100000002
\.


--
-- Data for Name: segment_data_15; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_15 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: segment_data_16; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_16 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: segment_data_17; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_17 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
2000A	48	HL	100002302	\N	100000002
2010AA	49	NM1	100002302	\N	100000002
2010AA	50	N3	100002302	\N	100000002
2010AA	51	N4	100002302	\N	100000002
2010AA	52	REF	100002302	\N	100000002
2010AB	53	NM1	100002302	\N	100000002
2010AB	54	N3	100002302	\N	100000002
2010AB	55	N4	100002302	\N	100000002
2000B	56	HL	100002302	\N	100000002
2000B	57	SBR	100002302	\N	100000002
2010BA	58	NM1	100002302	\N	100000002
2010BA	59	N3	100002302	\N	100000002
2010BA	60	N4	100002302	\N	100000002
2010BA	61	DMG	100002302	\N	100000002
2010BB	62	NM1	100002302	\N	100000002
2010BB	63	N3	100002302	\N	100000002
2010BB	64	N4	100002302	\N	100000002
2010BB	65	REF	100002302	\N	100000002
2300	66	CLM	100002302	\N	100000002
2300	67	DTP	100002302	\N	100000002
2300	68	PWK	100002302	\N	100000002
2300	69	REF	100002302	\N	100000002
2300	70	REF	100002302	\N	100000002
2300	71	HI	100002302	\N	100000002
2310A	72	NM1	100002302	\N	100000002
2310C	73	NM1	100002302	\N	100000002
2310C	74	N3	100002302	\N	100000002
2310C	75	N4	100002302	\N	100000002
2320	76	SBR	100002302	\N	100000002
2320	77	AMT	100002302	\N	100000002
2320	78	OI	100002302	\N	100000002
2330A	79	NM1	100002302	\N	100000002
2330A	80	N3	100002302	\N	100000002
2330A	81	N4	100002302	\N	100000002
2330B	82	NM1	100002302	\N	100000002
2330B	83	N3	100002302	\N	100000002
2330B	84	N4	100002302	\N	100000002
2400	85	LX	100002302	100002327	100000002
2400	86	SV1	100002302	100002327	100000002
2400	87	DTP	100002302	100002327	100000002
2430	88	SVD	100002302	100002327	100000002
2430	89	CAS	100002302	100002327	100000002
2430	90	DTP	100002302	100002327	100000002
2400	91	LX	100002302	100002343	100000002
2400	92	SV1	100002302	100002343	100000002
2400	93	DTP	100002302	100002343	100000002
2430	94	SVD	100002302	100002343	100000002
2430	95	CAS	100002302	100002343	100000002
2430	96	DTP	100002302	100002343	100000002
2400	97	LX	100002302	100002359	100000002
2400	98	SV1	100002302	100002359	100000002
2400	99	DTP	100002302	100002359	100000002
2430	100	SVD	100002302	100002359	100000002
2430	101	CAS	100002302	100002359	100000002
2430	102	DTP	100002302	100002359	100000002
2000A	223	HL	100002485	\N	100000002
2010AA	224	NM1	100002485	\N	100000002
2010AA	225	N3	100002485	\N	100000002
2010AA	226	N4	100002485	\N	100000002
2010AA	227	REF	100002485	\N	100000002
2000B	228	HL	100002485	\N	100000002
2000B	229	SBR	100002485	\N	100000002
2010BA	230	NM1	100002485	\N	100000002
2010BA	231	N3	100002485	\N	100000002
2010BA	232	N4	100002485	\N	100000002
2010BA	233	DMG	100002485	\N	100000002
2010BB	234	NM1	100002485	\N	100000002
2010BB	235	N3	100002485	\N	100000002
2010BB	236	N4	100002485	\N	100000002
2010BB	237	REF	100002485	\N	100000002
2300	238	CLM	100002485	\N	100000002
2300	239	DTP	100002485	\N	100000002
2300	240	DTP	100002485	\N	100000002
2300	241	PWK	100002485	\N	100000002
2300	242	REF	100002485	\N	100000002
2300	243	REF	100002485	\N	100000002
2300	244	HI	100002485	\N	100000002
2310A	245	NM1	100002485	\N	100000002
2310B	246	NM1	100002485	\N	100000002
2310C	247	NM1	100002485	\N	100000002
2310C	248	N3	100002485	\N	100000002
2310C	249	N4	100002485	\N	100000002
2320	250	SBR	100002485	\N	100000002
2320	251	AMT	100002485	\N	100000002
2320	252	OI	100002485	\N	100000002
2330A	253	NM1	100002485	\N	100000002
2330A	254	N3	100002485	\N	100000002
2330A	255	N4	100002485	\N	100000002
2330B	256	NM1	100002485	\N	100000002
2330B	257	N3	100002485	\N	100000002
2330B	258	N4	100002485	\N	100000002
2400	259	LX	100002485	100002511	100000002
2400	260	SV1	100002485	100002511	100000002
2400	261	DTP	100002485	100002511	100000002
2430	262	SVD	100002485	100002511	100000002
2430	263	CAS	100002485	100002511	100000002
2430	264	DTP	100002485	100002511	100000002
2000A	305	HL	100002561	\N	100000002
2000A	306	PRV	100002561	\N	100000002
2010AA	307	NM1	100002561	\N	100000002
2010AA	308	N3	100002561	\N	100000002
2010AA	309	N4	100002561	\N	100000002
2010AA	310	REF	100002561	\N	100000002
2000B	311	HL	100002561	\N	100000002
2000B	312	SBR	100002561	\N	100000002
2010BA	313	NM1	100002561	\N	100000002
2010BA	314	N3	100002561	\N	100000002
2010BA	315	N4	100002561	\N	100000002
2010BA	316	DMG	100002561	\N	100000002
2010BB	317	NM1	100002561	\N	100000002
2010BB	318	N3	100002561	\N	100000002
2010BB	319	N4	100002561	\N	100000002
2010BB	320	REF	100002561	\N	100000002
2300	321	CLM	100002561	\N	100000002
2300	322	DTP	100002561	\N	100000002
2300	323	PWK	100002561	\N	100000002
2300	324	REF	100002561	\N	100000002
2300	325	REF	100002561	\N	100000002
2300	326	HI	100002561	\N	100000002
2310A	327	NM1	100002561	\N	100000002
2310B	328	NM1	100002561	\N	100000002
2310B	329	PRV	100002561	\N	100000002
2310C	330	NM1	100002561	\N	100000002
2310C	331	N3	100002561	\N	100000002
2310C	332	N4	100002561	\N	100000002
2320	333	SBR	100002561	\N	100000002
2320	334	AMT	100002561	\N	100000002
2320	335	OI	100002561	\N	100000002
2330A	336	NM1	100002561	\N	100000002
2330A	337	N3	100002561	\N	100000002
2330A	338	N4	100002561	\N	100000002
2330B	339	NM1	100002561	\N	100000002
2330B	340	N3	100002561	\N	100000002
2330B	341	N4	100002561	\N	100000002
2400	342	LX	100002561	100002586	100000002
2400	343	SV1	100002561	100002586	100000002
2400	344	DTP	100002561	100002586	100000002
2430	345	SVD	100002561	100002586	100000002
2430	346	CAS	100002561	100002586	100000002
2430	347	DTP	100002561	100002586	100000002
2000A	390	HL	100002637	\N	100000002
2010AA	391	NM1	100002637	\N	100000002
2010AA	392	N3	100002637	\N	100000002
2010AA	393	N4	100002637	\N	100000002
2010AA	394	REF	100002637	\N	100000002
2000B	395	HL	100002637	\N	100000002
2000B	396	SBR	100002637	\N	100000002
2010BA	397	NM1	100002637	\N	100000002
2010BA	398	N3	100002637	\N	100000002
2010BA	399	N4	100002637	\N	100000002
2010BA	400	DMG	100002637	\N	100000002
2010BB	401	NM1	100002637	\N	100000002
2010BB	402	N3	100002637	\N	100000002
2010BB	403	N4	100002637	\N	100000002
2010BB	404	REF	100002637	\N	100000002
2300	405	CLM	100002637	\N	100000002
2300	406	DTP	100002637	\N	100000002
2300	407	DTP	100002637	\N	100000002
2300	408	PWK	100002637	\N	100000002
2300	409	REF	100002637	\N	100000002
2300	410	REF	100002637	\N	100000002
2300	411	HI	100002637	\N	100000002
2310A	412	NM1	100002637	\N	100000002
2310B	413	NM1	100002637	\N	100000002
2310C	414	NM1	100002637	\N	100000002
2310C	415	N3	100002637	\N	100000002
2310C	416	N4	100002637	\N	100000002
2320	417	SBR	100002637	\N	100000002
2320	418	AMT	100002637	\N	100000002
2320	419	OI	100002637	\N	100000002
2330A	420	NM1	100002637	\N	100000002
2330A	421	N3	100002637	\N	100000002
2330A	422	N4	100002637	\N	100000002
2330B	423	NM1	100002637	\N	100000002
2330B	424	N3	100002637	\N	100000002
2330B	425	N4	100002637	\N	100000002
2400	426	LX	100002637	100002663	100000002
2400	427	SV1	100002637	100002663	100000002
2400	428	DTP	100002637	100002663	100000002
2430	429	SVD	100002637	100002663	100000002
2430	430	CAS	100002637	100002663	100000002
2430	431	DTP	100002637	100002663	100000002
\.


--
-- Data for Name: segment_data_18; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_18 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: segment_data_19; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.segment_data_19 (loop_id, segment_number, segment_name, claim_id, claim_line_id, file_id) FROM stdin;
\.


--
-- Data for Name: shedlock; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.shedlock (name, lock_until, locked_at, locked_by) FROM stdin;
\.


--
-- Data for Name: submitter_info_config; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.submitter_info_config (id, cms_submitter_id, key, value) FROM stdin;
1	1	SUBMISSION_INDICATOR	PROD
2	2	SUBMISSION_INDICATOR	PROD
28	3	ORG_NAME	CONFIANZA SOFTWARE PVT LTD
29	3	IDENTIFIER	ENC1234
30	3	CONTACT_NAME	Abraham Menacherry
31	3	TELEPHONE_NUMBER	1234568888
32	1	ORG_NAME	CONFIANZA SOFTWARE PVT LTD
33	1	IDENTIFIER	ENC0001
34	1	CONTACT_NAME	Abraham Menacherry
35	1	TELEPHONE_NUMBER	1234568888
\.


--
-- Data for Name: tenant_schema; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.tenant_schema (tenant_id, schema, modified_by, date_created, last_updated) FROM stdin;
public	public	\N	2022-11-14 01:29:24.964135	2022-11-14 01:29:24.964135
\.


--
-- Data for Name: x12_duplicate_file; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.x12_duplicate_file (id, h_plan_id, file_id, encounter_type, duplicate_file_name, file_url, file_type, db_load_timestamp) FROM stdin;
\.


--
-- Data for Name: x12_resp_duplicate_file; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.x12_resp_duplicate_file (id, h_plan_id, duplicate_file_name, file_url, resp_file_id, response_file_type, db_load_timestamp) FROM stdin;
\.


--
-- Data for Name: x12file; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.x12file (id, h_plan_id, encounter_type, submission_file_type, encounter_or_chart_review, source_file_name, file_name, file_url, file_type, initial_source, file_status, file_processed_status, total_st_se_segments, manual_update_comment, retry_count, last_updated, db_load_timestamp, linked_orig_file, modified_by, file_hash) FROM stdin;
1	1	\N	\N	\N	default_file_not_a_file	default_file_not_a_file	\N	\N	\N	\N	NA	\N	\N	\N	2022-11-14 01:29:14.926706	2022-11-14 01:29:14.926706	\N	SYSTEM_PY-RAS	\N
100000002	2	PROFESSIONAL	HISTORY_837	\N	FIANZA.PROD.NDM.PROD.EDST.ENC0001_837(P)_1_20191121_061443	FIANZA.PROD.NDM.PROD.EDST.ENC0001_837(P)_1_20191121_061443	/Users/menacher/dev/ras-data/EDPS/DEFAULT_ACCOUNT/HX96X/history/TO_BE_PROCESSED/FIANZA.PROD.NDM.PROD.EDST.ENC0001_837(P)_1_20191121_061443	837	\N	COMPLETED	PROCESSED	\N	\N	0	\N	2022-11-14 02:05:36.820461	\N	SYSTEM_PY-RAS	0ea96a72dd689813043978558d519e6e
\.


--
-- Data for Name: x12file_struct_validation; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.x12file_struct_validation (id, file_id, message) FROM stdin;
\.


--
-- Data for Name: xref_billtype_ipop; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_billtype_ipop (id, bill_type, start_date, end_date, ipop_ind, taxonomy_req_ind) FROM stdin;
1	111	20080101	99999999	IP	N
2	114	20080101	99999999	IP	N
3	116	20080101	99999999	IP	N
4	117	20080101	99999999	IP	N
5	131	20080101	99999999	OP	N
6	134	20080101	99999999	OP	N
7	136	20080101	99999999	OP	N
8	137	20080101	99999999	OP	N
9	411	20080101	99999999	IP	Y
10	414	20080101	99999999	IP	Y
11	416	20080101	99999999	IP	Y
12	417	20080101	99999999	IP	Y
13	421	20080101	99999999	OP	Y
14	424	20080101	99999999	OP	Y
15	426	20080101	99999999	OP	Y
16	427	20080101	99999999	OP	Y
17	431	20080101	99999999	OP	Y
18	434	20080101	99999999	OP	Y
19	436	20080101	99999999	OP	Y
20	437	20080101	99999999	OP	Y
21	511	20080101	99999999	IP	N
22	514	20080101	99999999	IP	N
23	516	20080101	99999999	IP	N
24	517	20080101	99999999	IP	N
25	711	20080101	99999999	OP	N
26	714	20080101	99999999	OP	N
27	716	20080101	99999999	OP	N
28	717	20080101	99999999	OP	N
29	731	20080101	99999999	OP	N
30	734	20080101	99999999	OP	N
31	736	20080101	99999999	OP	N
32	737	20080101	99999999	OP	N
33	761	20080101	99999999	OP	N
34	764	20080101	99999999	OP	N
35	766	20080101	99999999	OP	N
36	767	20080101	99999999	OP	N
37	851	20080101	99999999	IP	N
38	854	20080101	99999999	IP	N
39	856	20080101	99999999	IP	N
40	857	20080101	99999999	IP	N
41	02	20080101	99999999	PHY	N
42	87X	20210101	99999999	OP	N
\.


--
-- Data for Name: xref_claim_error_277; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_claim_error_277 (id, claim_status_category_code, claim_status_code1, claim_status_code2, claim_status_code3, eic, encounter_type, internal_error_number, error_description, error_category) FROM stdin;
\.


--
-- Data for Name: xref_claim_error_999; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_claim_error_999 (id, loop_id, segment_id_code, element_position_in_segment, element_sub_position, segment_syntax_error_code, element_syntax_error_code, functional_group_syntax_error_code, transaction_set_syntax_error_code, encounter_type, internal_error_number, error_description, error_category) FROM stdin;
\.


--
-- Data for Name: xref_claim_error_mao2; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_claim_error_mao2 (id, code, category, disposition, description) FROM stdin;
\.


--
-- Data for Name: xref_claim_npi_mapping; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_claim_npi_mapping (h_plan_id, claim_ref, name, billing_npi, attending_npi) FROM stdin;
\.


--
-- Data for Name: xref_dme_pos; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_dme_pos (id, dme_pos, year) FROM stdin;
\.


--
-- Data for Name: xref_edit_error; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_edit_error (internal_error_number, encounter_type, error_category, error_description) FROM stdin;
\.


--
-- Data for Name: xref_hcc_description; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_hcc_description (id, description) FROM stdin;
1	HIV/AIDS 
2	Septicemia, Sepsis, Systemic Inflammatory Response Syndrome/Shock 
6	Opportunistic Infections 
8	Metastatic Cancer and Acute Leukemia 
9	Lung and Other Severe Cancers 
10	Lymphoma and Other Cancers 
11	Colorectal, Bladder, and Other Cancers 
12	Breast, Prostate, and Other Cancers and Tumors 
17	Diabetes with Acute Complications 
18	Diabetes with Chronic Complications 
19	Diabetes without Complication 
21	Protein-Calorie Malnutrition 
22	Morbid Obesity 
23	Other Significant Endocrine and Metabolic Disorders 
27	End-Stage Liver Disease 
28	Cirrhosis of Liver 
29	Chronic Hepatitis 
33	Intestinal Obstruction/Perforation 
34	Chronic Pancreatitis 
35	Inflammatory Bowel Disease 
39	Bone/Joint/Muscle Infections/Necrosis 
40	Rheumatoid Arthritis and Inflammatory Connective Tissue Disease 
46	Severe Hematological Disorders 
47	Disorders of Immunity 
48	Coagulation Defects and Other Specified Hematological Disorders 
51	Dementia With Complications 
52	Dementia Without Complication 
54	Substance Use with Psychotic Complications 
55	Substance Use Disorder, Moderate/Severe, or Substance Use with Complications 
56	Substance Use Disorder, Mild, Except Alcohol and Cannabis 
57	Schizophrenia 
58	Reactive and Unspecified Psychosis 
59	Major Depressive, Bipolar, and Paranoid Disorders 
60	Personality Disorders 
70	Quadriplegia 
71	Paraplegia 
72	Spinal Cord Disorders/Injuries 
73	Amyotrophic Lateral Sclerosis and Other Motor Neuron Disease 
74	Cerebral Palsy 
75	Myasthenia Gravis/Myoneural Disorders and Guillain-Barre Syndrome/Inflammatory and Toxic Neuropathy 
76	Muscular Dystrophy 
77	Multiple Sclerosis 
78	Parkinson's and Huntington's Diseases 
79	Seizure Disorders and Convulsions 
80	Coma, Brain Compression/Anoxic Damage 
82	Respirator Dependence/Tracheostomy Status 
83	Respiratory Arrest 
84	Cardio-Respiratory Failure and Shock 
85	Congestive Heart Failure 
86	Acute Myocardial Infarction 
87	Unstable Angina and Other Acute Ischemic Heart Disease 
88	Angina Pectoris 
96	Specified Heart Arrhythmias 
99	Intracranial Hemorrhage 
100	Ischemic or Unspecified Stroke 
103	Hemiplegia/Hemiparesis 
104	Monoplegia, Other Paralytic Syndromes 
106	Atherosclerosis of the Extremities with Ulceration or Gangrene 
107	Vascular Disease with Complications 
108	Vascular Disease 
110	Cystic Fibrosis 
111	Chronic Obstructive Pulmonary Disease 
112	Fibrosis of Lung and Other Chronic Lung Disorders 
114	Aspiration and Specified Bacterial Pneumonias 
115	Pneumococcal Pneumonia, Empyema, Lung Abscess 
122	Proliferative Diabetic Retinopathy and Vitreous Hemorrhage 
124	Exudative Macular Degeneration 
134	Dialysis Status 
135	Acute Renal Failure 
136	Chronic Kidney Disease, Stage 5 
137	Chronic Kidney Disease, Severe (Stage 4) 
138	Chronic Kidney Disease, Moderate (Stage 3) 
157	Pressure Ulcer of Skin with Necrosis Through to Muscle, Tendon, or Bone 
158	Pressure Ulcer of Skin with Full Thickness Skin Loss 
159	Pressure Ulcer of Skin with Partial Thickness Skin Loss 
161	Chronic Ulcer of Skin, Except Pressure 
162	Severe Skin Burn or Condition 
166	Severe Head Injury 
167	Major Head Injury 
169	Vertebral Fractures without Spinal Cord Injury 
170	Hip Fracture/Dislocation 
173	Traumatic Amputations and Complications 
176	Complications of Specified Implanted Device or Graft 
186	Major Organ Transplant or Replacement Status 
188	Artificial Openings for Feeding or Elimination 
189	Amputation Status, Lower Limb/Amputation Complications 
\.


--
-- Data for Name: xref_hcc_drop; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_hcc_drop (id, model_run, hierarchy_hcc, hcc_to_drop, payment_year) FROM stdin;
1	V24	8	9	2023
2	V24	8	10	2023
3	V24	8	11	2023
4	V24	8	12	2023
5	V24	9	10	2023
6	V24	9	11	2023
7	V24	9	12	2023
8	V24	10	11	2023
9	V24	10	12	2023
10	V24	11	12	2023
11	V24	17	18	2023
12	V24	17	19	2023
13	V24	18	19	2023
14	V24	27	28	2023
15	V24	27	29	2023
16	V24	27	80	2023
17	V24	28	29	2023
18	V24	46	48	2023
19	V24	51	52	2023
20	V24	54	55	2023
21	V24	54	56	2023
22	V24	55	56	2023
23	V24	57	58	2023
24	V24	57	59	2023
25	V24	57	60	2023
26	V24	58	59	2023
27	V24	58	60	2023
28	V24	59	60	2023
29	V24	70	71	2023
30	V24	70	72	2023
31	V24	70	103	2023
32	V24	70	104	2023
33	V24	70	169	2023
34	V24	71	72	2023
35	V24	71	104	2023
36	V24	71	169	2023
37	V24	72	169	2023
38	V24	82	83	2023
39	V24	82	84	2023
40	V24	83	84	2023
41	V24	86	87	2023
42	V24	86	88	2023
43	V24	87	88	2023
44	V24	99	100	2023
45	V24	103	104	2023
46	V24	106	107	2023
47	V24	106	108	2023
48	V24	106	161	2023
49	V24	106	189	2023
50	V24	107	108	2023
51	V24	110	111	2023
52	V24	110	112	2023
53	V24	111	112	2023
54	V24	114	115	2023
55	V24	134	135	2023
56	V24	134	136	2023
57	V24	134	137	2023
58	V24	134	138	2023
59	V24	135	136	2023
60	V24	135	137	2023
61	V24	135	138	2023
62	V24	136	137	2023
63	V24	136	138	2023
64	V24	137	138	2023
65	V24	157	158	2023
66	V24	157	159	2023
67	V24	157	161	2023
68	V24	158	159	2023
69	V24	158	161	2023
70	V24	159	161	2023
71	V24	166	80	2023
72	V24	166	167	2023
73	V22	8	9	2018
74	V22	8	10	2018
75	V22	8	11	2018
76	V22	8	12	2018
77	V22	9	10	2018
78	V22	9	11	2018
79	V22	9	12	2018
80	V22	10	11	2018
81	V22	10	12	2018
82	V22	11	12	2018
83	V22	17	18	2018
84	V22	17	19	2018
85	V22	18	19	2018
86	V22	27	28	2018
87	V22	27	29	2018
88	V22	27	80	2018
89	V22	28	29	2018
90	V22	46	48	2018
91	V22	54	55	2018
92	V22	57	58	2018
93	V22	70	71	2018
94	V22	70	72	2018
95	V22	70	103	2018
96	V22	70	104	2018
97	V22	70	169	2018
98	V22	71	72	2018
99	V22	71	104	2018
100	V22	71	169	2018
101	V22	72	169	2018
102	V22	82	83	2018
103	V22	82	84	2018
104	V22	83	84	2018
105	V22	86	87	2018
106	V22	86	88	2018
107	V22	87	88	2018
108	V22	99	100	2018
109	V22	103	104	2018
110	V22	106	107	2018
111	V22	106	108	2018
112	V22	106	161	2018
113	V22	106	189	2018
114	V22	107	108	2018
115	V22	110	111	2018
116	V22	110	112	2018
117	V22	111	112	2018
118	V22	114	115	2018
119	V22	134	135	2018
120	V22	134	136	2018
121	V22	134	137	2018
122	V22	135	136	2018
123	V22	135	137	2018
124	V22	136	137	2018
125	V22	157	158	2018
126	V22	157	161	2018
127	V22	158	161	2018
128	V22	166	80	2018
129	V22	166	167	2018
130	V23	8	9	2019
131	V23	8	10	2019
132	V23	8	11	2019
133	V23	8	12	2019
134	V23	9	10	2019
135	V23	9	11	2019
136	V23	9	12	2019
137	V23	10	11	2019
138	V23	10	12	2019
139	V23	11	12	2019
140	V23	17	18	2019
141	V23	17	19	2019
142	V23	18	19	2019
143	V23	27	28	2019
144	V23	27	29	2019
145	V23	27	80	2019
146	V23	28	29	2019
147	V23	46	48	2019
148	V23	51	52	2019
149	V23	54	55	2019
150	V23	54	56	2019
151	V23	55	56	2019
152	V23	57	58	2019
153	V23	57	59	2019
154	V23	57	60	2019
155	V23	58	59	2019
156	V23	58	60	2019
157	V23	59	60	2019
158	V23	70	71	2019
159	V23	70	72	2019
160	V23	70	103	2019
161	V23	70	104	2019
162	V23	70	169	2019
163	V23	71	72	2019
164	V23	71	104	2019
165	V23	71	169	2019
166	V23	72	169	2019
167	V23	82	83	2019
168	V23	82	84	2019
169	V23	83	84	2019
170	V23	86	87	2019
171	V23	86	88	2019
172	V23	87	88	2019
173	V23	99	100	2019
174	V23	103	104	2019
175	V23	106	107	2019
176	V23	106	108	2019
177	V23	106	161	2019
178	V23	106	189	2019
179	V23	107	108	2019
180	V23	110	111	2019
181	V23	110	112	2019
182	V23	111	112	2019
183	V23	114	115	2019
184	V23	134	135	2019
185	V23	134	136	2019
186	V23	134	137	2019
187	V23	134	138	2019
188	V23	135	136	2019
189	V23	135	137	2019
190	V23	135	138	2019
191	V23	136	137	2019
192	V23	136	138	2019
193	V23	137	138	2019
194	V23	157	158	2019
195	V23	157	159	2019
196	V23	157	161	2019
197	V23	158	159	2019
198	V23	158	161	2019
199	V23	159	161	2019
200	V23	166	80	2019
201	V23	166	167	2019
\.


--
-- Data for Name: xref_hcpcs_cpt; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_hcpcs_cpt (id, cpt_code, code_description, payment_year, service_year) FROM stdin;
\.


--
-- Data for Name: xref_hicn_mbi; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_hicn_mbi (id, h_plan_id, submitter_id, plan_number, plan_member_id, hicn, mbi, pcp_effective_start_date, pcp_effective_end_date, member_enrollment_date, member_disenrolled_date, subscriber_last_name, subscriber_first_name, subscriber_middle_name, subscriber_gender, subscriber_dob, pcp_id, pcp_last_name, pcp_first_name, pcp_middle_name, permanent_street_address_1, permanent_street_address_2, permanent_street_address_3, permanent_city, permanent_state, permanent_zip_code, permanent_county, mailing_street_address_1, mailing_street_address_2, mailing_street_address_3, mailing_city, mailing_state, mailing_zip_code, mailing_county) FROM stdin;
\.


--
-- Data for Name: xref_icd_hcc; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_icd_hcc (id, icd_code, icd_description, hcc_model, model_category, hcc, payment_year) FROM stdin;
\.


--
-- Data for Name: xref_raf_codes; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_raf_codes (id, payment_year, product, normalization_factor, coding_intensity, blend_percent) FROM stdin;
1	2019	EDPS	1.038	0.059	0.25
2	2019	RAPS	1.041	0.059	0.75
3	2020	EDPS	1.069	0.059	0.5
4	2020	RAPS	1.075	0.059	0.5
5	2021	EDPS	1.097	0.059	0.75
6	2021	RAPS	1.106	0.059	0.25
7	2022	EDPS	1.118	0.059	1
8	2022	RAPS	0	0	0
9	2023	EDPS	1.127	0.059	1
10	2023	RAPS	0	0	0
\.


--
-- Data for Name: xref_raps_error; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_raps_error (id, error_code, error_description, error_record, error_category) FROM stdin;
1	100	INVALID RECORD TYPE	AAA	FILE_LEVEL
2	101	AAA RECORD MISSING FROM TRANSACTION	AAA	FILE_LEVEL
3	102	MISSING / INVALID SUBMITTER-ID ON AAA RECORD	AAA	FILE_LEVEL
4	103	MISSING FILE-ID ON AAA RECORD	AAA	FILE_LEVEL
5	104	MISSING / INVALID TRANSACTION DATE ON AAA RECORD	AAA	FILE_LEVEL
6	105	MISSING / INVALID PROD-TEST-OPMT-INDICATOR ON AAA RECORD	AAA	FILE_LEVEL
7	106	MISSING / INVALID FILE-DIAG-INDICATOR ON AAA RECORD	AAA	FILE_LEVEL
8	107	SUBMITTER ID IS NOT VALIDATED TO SEND PRODUCTION DATA	AAA	FILE_LEVEL
9	109	ICD10 FILES NOT ACCEPTED AT THIS TIME	AAA	FILE_LEVEL
10	112	SUBMITTER ID NOT ON FILE	AAA	FILE_LEVEL
11	113	FILE NAME DUPLICATES ANOTHER FILE ACCEPTED WITHIN LAST 12 MONTHS	AAA	FILE_LEVEL
12	114	TRANSACTION DATE IS GREATER THAN CURRENT DATE	AAA	FILE_LEVEL
13	151	ZZZ RECORD MISSING FROM TRANSACTION	ZZZ	FILE_LEVEL
14	152	MISSING / INVALID SUBMITTER-ID ON ZZZ RECORD	ZZZ	FILE_LEVEL
15	153	MISSING / INVALID FILE-ID ON ZZZ RECORD	ZZZ	FILE_LEVEL
16	154	MISSING / INVALID BBB-RECORD-TOTAL	ZZZ	FILE_LEVEL
17	162	ZZZ SUBMITTER-ID DOES NOT MATCH SUBMITTER-ID ON AAA RECORD	ZZZ	FILE_LEVEL
18	163	FILE ID DOES NOT MATCH FILE ID ON AAA RECORD	ZZZ	FILE_LEVEL
19	164	ZZZ VALUE IS NOT EQUAL TO THE NUMBER OF BBB RECORDS	ZZZ	FILE_LEVEL
20	165	FERAS/RAPS EDI AGREEMENT NOT ON FILE	NA	FILE_LEVEL
21	166	TEST FILES CANNOT EXCEED 3,000 CCC RECORDS	ZZZ	FILE_LEVEL
22	177	PROD FILE CANNOT EXCEED 1,000,000 RECORDS	ZZZ	FILE_LEVEL
23	201	BBB RECORD MISSING FROM TRANSACTION	BBB	BATCH_LEVEL
24	202	MISSING / INVALID SEQUENCE NUMBER ON BBB RECORD	BBB	BATCH_LEVEL
25	203	MISSING / INVALID PLAN NUMBER ON BBB RECORD	BBB	BATCH_LEVEL
26	212	SEQUENCE NUMBER ON BBB RECORD IS OUT OF SEQUENCE	BBB	BATCH_LEVEL
27	213	SUBMITTER ID NOT AUTHORIZED TO SUBMIT FOR THIS PLAN ID	BBB	BATCH_LEVEL
28	214	CONTRACT ENROLLMENT DATE NOT ON FILE	BBB	BATCH_LEVEL
29	215	OVERPAYMENT-ID IS NOT GREATER THAN SPACES FOR OPMT FILE	BBB	BATCH_LEVEL
30	216	PAYMENT-YEAR IS NOT GREATER THAN SPACES FOR OPMT FILE	BBB	BATCH_LEVEL
31	217	OVERPAYMENT-ID MUST BE SPACES FOR NON OPMT FILE	BBB	BATCH_LEVEL
32	218	PAYMENT-YEAR MUST BE SPACES FOR NON OPMT FILE	BBB	BATCH_LEVEL
33	227	ICD9/ICD10 FILE TYPE IN HEADER DOES NOT MATCH TYPE DIAGNOSIS CODE\nENTERED IN DETAIL RECORD	AAA	FILE_LEVEL
34	251	YYY RECORD MISSING FROM TRANSACTION	YYY	BATCH_LEVEL
35	252	MISSING / INVALID SEQUENCE NUMBER ON YYY RECORD	YYY	BATCH_LEVEL
36	253	MISSING / INVALID PLAN NUMBER ON YYY RECORD	YYY	BATCH_LEVEL
37	254	MISSING / INVALID DETAIL-RECORD-TOTAL	YYY	BATCH_LEVEL
38	262	LAST YYY SEQUENCE NUMBER IS NOT EQUAL TO NUMBER OF YYY RECORDS	YYY	BATCH_LEVEL
39	263	PLAN NUMBER DOES NOT MATCH PLAN NUMBER IN BBB RECORD	YYY	BATCH_LEVEL
40	264	YYY VALUE IS NOT EQUAL TO THE NUMBER OF DETAIL RECORDS	YYY	BATCH_LEVEL
41	272	SEQUENCE NUMBER ON YYY RECORD IS OUT OF SEQUENCE	YYY	BATCH_LEVEL
42	301	DETAIL RECORD MISSING FROM TRANSACTION	CCC	RECORD_LEVEL
43	302	MISSING / INVALID SEQUENCE NUMBER ON DETAIL RECORD	CCC	RECORD_LEVEL
44	303	SEQUENCE-ERROR-CODE FILLER NOT EQUAL TO SPACES	CCC	RECORD_LEVEL
45	304	HIC-ERROR-CODE FILLER NOT EQUAL TO SPACES	CCC	RECORD_LEVEL
46	305	DOB-ERROR-CODE FILLER NOT EQUAL TO SPACES	CCC	RECORD_LEVEL
47	306	DIAGNOSIS CODE FILLER NOT EQUAL TO SPACES	CCC	RECORD_LEVEL
48	307	DIAGNOSIS-CLUSTER-ERROR-1 NOT EQUAL TO SPACES	CCC	RECORD_LEVEL
49	308	DIAGNOSIS-CLUSTER-ERROR-2 NOT EQUAL TO SPACES	CCC	RECORD_LEVEL
50	309	SEQUENCE-NUMBER ON DETAIL RECORD IS OUT OF SEQUENCE	CCC	RECORD_LEVEL
51	310	MISSING / INVALID HIC-NO ON DETAIL RECORD	CCC	RECORD_LEVEL
52	311	AT LEAST ONE DIAGNOSIS CLUSTER REQUIRED ON TRANSACTION	CCC	RECORD_LEVEL
53	313	DELETE-INDICATOR MUST BE EQUAL TO A SPACE OR "D" FOR DELETE	CCC	RECORD_LEVEL
54	314	INVALID DIAGNOSIS CODE FORMAT ON DETAIL RECORD	CCC	RECORD_LEVEL
55	315	CORRECTED HIC NOT EQUAL TO SPACES	CCC	RECORD_LEVEL
56	316	RISK ASSESSMENT CODE ERROR NOT EQUAL TO SPACES	CCC	RECORD_LEVEL
57	317	INVALID OVERPAYMENT-ID ON BBB RECORD	BBB	BATCH_LEVEL
58	318	INVALID PAYMENT-YEAR ON BBB RECORD	BBB	BATCH_LEVEL
59	319	INPUT PLAN NO ON BBB RECORD DOES NOT MATCH PLAN NO ON REMEDY TICKET	BBB	BATCH_LEVEL
60	350	INVALID PATIENT-DOB ON CCC RECORD	CCC	RECORD_LEVEL
61	353	HIC NUMBER DOES NOT EXIST ON CME	CCC	RECORD_LEVEL
62	354	PATIENT DOB SUBMITTED DOES NOT MATCH DOB ON MBD	CCC	RECORD_LEVEL
63	360	BENEFICIARY MBI NUMBER MAY NOT BE USED BEFORE THE MBI TRANSITION DATE	CCC	RECORD_LEVEL
64	400	MISSING / INVALID PROVIDER-TYPE ON DETAIL RECORD	CCC	DIAGNOSIS_CLUSTER
65	401	INVALID SERVICE FROM-DATE ON DETAIL RECORD	CCC	DIAGNOSIS_CLUSTER
66	402	INVALID SERVICE THRU-DATE ON DETAIL RECORD	CCC	DIAGNOSIS_CLUSTER
67	403	SERVICE THRU-DATE IS OUTSIDE THE RISK ADJUSTMENT PROCESSING RANGE	CCC	DIAGNOSIS_CLUSTER
68	404	SERVICE FROM-DATE MUST BE LESS THAN OR EQUAL TO THRU-DATE	CCC	DIAGNOSIS_CLUSTER
69	405	DOB IS GREATER THAN SERVICE FROM-DATE	CCC	DIAGNOSIS_CLUSTER
70	406	SERVICE FROM-DATE IS NOT WITHIN MEDICARE ENTITLEMENT PERIOD	CCC	DIAGNOSIS_CLUSTER
71	407	SERVICE THRU-DATE IS NOT WITHIN MEDICARE ENTITLEMENT PERIOD	CCC	DIAGNOSIS_CLUSTER
72	408	SERVICE FROM-DATE IS NOT WITHIN MA ORG ENROLLMENT PERIOD	CCC	DIAGNOSIS_CLUSTER
73	409	SERVICE THRU-DATE IS NOT WITHIN MA ORG ENROLLMENT PERIOD	CCC	DIAGNOSIS_CLUSTER
74	410	SERVICE FROM-DATE IS AFTER THE BENEFICIARY’S DISENROLLMENT FROM\nSUBMITTING PLAN	CCC	DIAGNOSIS_CLUSTER
75	411	SERVICE THRU-DATE IS GREATER THAN DATE OF DEATH	CCC	DIAGNOSIS_CLUSTER
76	412	SERVICE FROM-DATE GREATER THAN TRANSACTION DATE	CCC	DIAGNOSIS_CLUSTER
77	413	SERVICE THRU-DATE GREATER THAN TRANSACTION DATE	CCC	DIAGNOSIS_CLUSTER
78	414	SERVICE THRU-DATE GREATER THAN 09/30/2015 FOR ICD-9 DIAGNOSIS	CCC	DIAGNOSIS_CLUSTER
79	415	SERVICE THRU-DATE BEFORE 10/01/2015 FOR ICD-10 DIAGNOSIS	CCC	DIAGNOSIS_CLUSTER
80	416	RISK ASSESSMENT CODE MUST BE EQUAL TO A VALID CODE	CCC	DIAGNOSIS_CLUSTER
81	417	DIAGNOSIS CODE IS REQUIRED IF RISK ASSESSMENT CODE PRESENT	CCC	DIAGNOSIS_CLUSTER
82	418	SERVICE YEAR IS CLOSED FOR DIAGNOSIS SUBMISSIONS	CCC	DIAGNOSIS_CLUSTER
83	419	DIAGNOSIS CODE PRESENT IN THE CLUSTER, RISK ASSESSMENT CODE IS MISSING	CCC	DIAGNOSIS_CLUSTER
84	420	DIAGNOSIS CLUSTER SUBMITTED FOR RESTRICTED SERVICE YEAR	CCC	DIAGNOSIS_CLUSTER
85	421	DELETE-IND MUST BE EQUAL TO D FOR DELETE ON OPMT FILE	CCC	DIAGNOSIS_CLUSTER
86	422	SERVICE THRU-DATE IS NOT WITHIN THE REPORTED PAYMENT YEAR	CCC	DIAGNOSIS_CLUSTER
87	423	DELETE IS NOT ALLOWED WITHOUT AN OPMT FILE AFTER FINAL SWEEP DATE	CCC	DIAGNOSIS_CLUSTER
88	424	SERVICE YEAR IS CLOSED FOR DIAGNOSIS DELETE SUBMISSIONS	CCC	DIAGNOSIS_CLUSTER
89	425	DIAGNOSIS DELETE CLUSTER SUBMITTED FOR RESTRICTED SERVICE YEAR	CCC	DIAGNOSIS_CLUSTER
90	450	DIAGNOSIS DOES NOT EXIST FOR THIS SERVICE THRU DATE	CCC	DIAGNOSIS_CLUSTER
91	451	SERVICE THRU-DATE IS GREATER THAN DIAGNOSIS END DATE	CCC	DIAGNOSIS_CLUSTER
92	453	DIAGNOSIS CODE IS NOT APPROPRIATE FOR PATIENT SEX	CCC	DIAGNOSIS_CLUSTER
93	454	DIAGNOSIS IS VALID, BUT IS NOT SUFFICIENTLY SPECIFIC FOR RISK ADJUSTMENT\nGROUPING	CCC	DIAGNOSIS_CLUSTER
94	455	DIAGNOSIS CLUSTER NOT EDITED DUE TO RECORD FORMAT ERROR	CCC	DIAGNOSIS_CLUSTER
95	460	SERVICE FROM- AND THRU-DATE SPAN IS GREATER THAN 31 DAYS	CCC	DIAGNOSIS_CLUSTER
96	490	COULD NOT DELETE; DIAGNOSIS CLUSTER NOT IN RAPS DATABASE BENEFICIARY\nRECORD	CCC	DIAGNOSIS_DELETE
97	491	DELETE ERROR, DIAGNOSIS CLUSTER PREVIOUSLY DELETED	CCC	DIAGNOSIS_DELETE
98	492	DIAGNOSIS CLUSTER WAS NOT SUCCESSFULLY DELETED. A DIAGNOSIS CLUSTER\nWITH THE SAME ATTRIBUTES WAS ALREADY DELETED FROM THE RAPS DATABASE ON THIS DATE	CCC	DIAGNOSIS_DELETE
99	500	BENEFICIARY HIC NUMBER HAS CHANGED ACCORDING TO CMS RECORDS; USE CORRECT HIC NUMBER FOR THE FUTURE SUBMISSIONS	CCC	INFORMATIONAL
100	502	DIAGNOSIS CLUSTER WAS ACCEPTED BUT NOT STORED. A DIAGNOSIS CLUSTER WITH THE SAME ATTRIBUTES IS ALREADY STORED IN THE RAPS DATABASE.	CCC	DUPLICATE
\.


--
-- Data for Name: xref_specialty_codes; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_specialty_codes (id, specialty_code, specialty, payment_year) FROM stdin;
\.


--
-- Data for Name: xref_specialty_taxonomy; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_specialty_taxonomy (id, specialty_code, provider_type_desc, provider_taxonomy_code, provider_taxonomy_desc, payment_year) FROM stdin;
\.


--
-- Data for Name: xref_ta1_error; Type: TABLE DATA; Schema: public; Owner: ras
--

COPY public.xref_ta1_error (id, error_type, error_code, error_description, error_category) FROM stdin;
1	TA105	24	Invalid Interchange Content	FILE_LEVEL
2	TA105	22	Invalid Control Structure	FILE_LEVEL
3	TA105	23	Improper (Premature) End-of-File (Transmission)	FILE_LEVEL
4	TA105	10	Invalid Authorization Information Qualifier Value	FILE_LEVEL
5	TA105	11	Invalid Authorization Information Value	FILE_LEVEL
6	TA105	12	Security Information Qualifier Value	FILE_LEVEL
7	TA105	13	Security Information Value	FILE_LEVEL
8	TA105	5	Invalid Interchange ID Qualifier for Sender	FILE_LEVEL
9	TA105	6	Invalid Interchange Sender ID	FILE_LEVEL
10	TA105	7	Invalid Interchange ID Qualifier for Receiver	FILE_LEVEL
11	TA105	8	Invalid Interchange Receiver ID	FILE_LEVEL
12	TA105	14	Invalid Interchange Date Value	FILE_LEVEL
13	TA105	15	Invalid Interchange Time Value	FILE_LEVEL
14	TA105	17	Invalid Interchange Version ID Value	FILE_LEVEL
15	TA105	18	Invalid Interchange Control Number Value	FILE_LEVEL
16	TA105	19	Invalid Acknowledgment Requested Value	FILE_LEVEL
17	TA105	20	Invalid Test Indicator Value	FILE_LEVEL
18	TA105	27	Invalid Component Element Separator	FILE_LEVEL
\.


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 1, false);


--
-- Name: batch_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.batch_data_id_seq', 1, false);


--
-- Name: batch_file_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.batch_file_id_seq', 1, false);


--
-- Name: flow_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.flow_id_seq', 1, false);


--
-- Name: flow_item_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.flow_item_history_id_seq', 1, false);


--
-- Name: flow_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.flow_item_id_seq', 1, false);


--
-- Name: hcc_diag_filtered_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.hcc_diag_filtered_id_seq', 1, false);


--
-- Name: hcc_diag_hierarchy_applied_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.hcc_diag_hierarchy_applied_id_seq', 1, false);


--
-- Name: hcc_diag_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.hcc_diag_id_seq', 1, false);


--
-- Name: health_plan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.health_plan_id_seq', 1, false);


--
-- Name: hibernate_sequence; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.hibernate_sequence', 42, true);


--
-- Name: linked_cr_batch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.linked_cr_batch_id_seq', 1, false);


--
-- Name: member_raf_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.member_raf_id_seq', 1, false);


--
-- Name: mmr_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.mmr_data_id_seq', 1, false);


--
-- Name: provider_837_remit_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.provider_837_remit_mapping_id_seq', 1, false);


--
-- Name: raps_cluster_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.raps_cluster_id_seq', 1, false);


--
-- Name: report_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.report_category_id_seq', 1, false);


--
-- Name: report_details_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.report_details_id_seq', 1, false);


--
-- Name: report_subscription_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.report_subscription_id_seq', 1, false);


--
-- Name: x12file_struct_validation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ras
--

SELECT pg_catalog.setval('public.x12file_struct_validation_id_seq', 1, false);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: batch_data batch_data_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.batch_data
    ADD CONSTRAINT batch_data_pkey PRIMARY KEY (id);


--
-- Name: batch_file batch_file_name_key; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.batch_file
    ADD CONSTRAINT batch_file_name_key UNIQUE (name);


--
-- Name: batch_file batch_file_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.batch_file
    ADD CONSTRAINT batch_file_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2010aa_per child_inst_2010aa_per_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010aa_per
    ADD CONSTRAINT child_inst_2010aa_per_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2010aa_ref child_inst_2010aa_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010aa_ref
    ADD CONSTRAINT child_inst_2010aa_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2010ac_ref child_inst_2010ac_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010ac_ref
    ADD CONSTRAINT child_inst_2010ac_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2010ba_ref child_inst_2010ba_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010ba_ref
    ADD CONSTRAINT child_inst_2010ba_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2010bb_ref child_inst_2010bb_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010bb_ref
    ADD CONSTRAINT child_inst_2010bb_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2300_dtp child_inst_2300_dtp_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_dtp
    ADD CONSTRAINT child_inst_2300_dtp_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2300_hi child_inst_2300_hi_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_hi
    ADD CONSTRAINT child_inst_2300_hi_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2300_nte child_inst_2300_nte_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_nte
    ADD CONSTRAINT child_inst_2300_nte_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2300_pwk child_inst_2300_pwk_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_pwk
    ADD CONSTRAINT child_inst_2300_pwk_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2300_ref child_inst_2300_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_ref
    ADD CONSTRAINT child_inst_2300_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2310a_ref child_inst_2310a_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310a_ref
    ADD CONSTRAINT child_inst_2310a_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2310b_ref child_inst_2310b_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310b_ref
    ADD CONSTRAINT child_inst_2310b_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2310c_ref child_inst_2310c_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310c_ref
    ADD CONSTRAINT child_inst_2310c_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2310d_ref child_inst_2310d_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310d_ref
    ADD CONSTRAINT child_inst_2310d_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2310e_ref child_inst_2310e_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310e_ref
    ADD CONSTRAINT child_inst_2310e_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2310f_ref child_inst_2310f_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310f_ref
    ADD CONSTRAINT child_inst_2310f_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2320_amt child_inst_2320_amt_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2320_amt
    ADD CONSTRAINT child_inst_2320_amt_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2320_cas child_inst_2320_cas_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2320_cas
    ADD CONSTRAINT child_inst_2320_cas_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2330b_ref child_inst_2330b_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330b_ref
    ADD CONSTRAINT child_inst_2330b_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2330c_ref child_inst_2330c_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330c_ref
    ADD CONSTRAINT child_inst_2330c_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2330d_ref child_inst_2330d_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330d_ref
    ADD CONSTRAINT child_inst_2330d_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2330e_ref child_inst_2330e_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330e_ref
    ADD CONSTRAINT child_inst_2330e_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2330f_ref child_inst_2330f_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330f_ref
    ADD CONSTRAINT child_inst_2330f_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2330g_ref child_inst_2330g_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330g_ref
    ADD CONSTRAINT child_inst_2330g_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2330h_ref child_inst_2330h_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330h_ref
    ADD CONSTRAINT child_inst_2330h_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2330i_ref child_inst_2330i_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330i_ref
    ADD CONSTRAINT child_inst_2330i_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2400_amt child_inst_2400_amt_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_amt
    ADD CONSTRAINT child_inst_2400_amt_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2400_dtp child_inst_2400_dtp_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_dtp
    ADD CONSTRAINT child_inst_2400_dtp_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2400_pwk child_inst_2400_pwk_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_pwk
    ADD CONSTRAINT child_inst_2400_pwk_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2400_ref child_inst_2400_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_ref
    ADD CONSTRAINT child_inst_2400_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2410_ref child_inst_2410_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2410_ref
    ADD CONSTRAINT child_inst_2410_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2420a_ref child_inst_2420a_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420a_ref
    ADD CONSTRAINT child_inst_2420a_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2420b_ref child_inst_2420b_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420b_ref
    ADD CONSTRAINT child_inst_2420b_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2420c_ref child_inst_2420c_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420c_ref
    ADD CONSTRAINT child_inst_2420c_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2420d_ref child_inst_2420d_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420d_ref
    ADD CONSTRAINT child_inst_2420d_ref_pkey PRIMARY KEY (id);


--
-- Name: child_inst_2430_cas child_inst_2430_cas_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2430_cas
    ADD CONSTRAINT child_inst_2430_cas_pkey PRIMARY KEY (id);


--
-- Name: child_inst_claim_identifier_amt child_inst_claim_identifier_amt_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_claim_identifier_amt
    ADD CONSTRAINT child_inst_claim_identifier_amt_pkey PRIMARY KEY (id);


--
-- Name: child_inst_claim_identifier_dtp child_inst_claim_identifier_dtp_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_claim_identifier_dtp
    ADD CONSTRAINT child_inst_claim_identifier_dtp_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2010aa_per child_prof_2010aa_per_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010aa_per
    ADD CONSTRAINT child_prof_2010aa_per_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2010aa_ref child_prof_2010aa_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010aa_ref
    ADD CONSTRAINT child_prof_2010aa_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2010ac_ref child_prof_2010ac_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010ac_ref
    ADD CONSTRAINT child_prof_2010ac_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2010ba_ref child_prof_2010ba_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010ba_ref
    ADD CONSTRAINT child_prof_2010ba_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2010bb_ref child_prof_2010bb_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010bb_ref
    ADD CONSTRAINT child_prof_2010bb_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2300_crc child_prof_2300_crc_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_crc
    ADD CONSTRAINT child_prof_2300_crc_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2300_dtp child_prof_2300_dtp_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_dtp
    ADD CONSTRAINT child_prof_2300_dtp_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2300_hi child_prof_2300_hi_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_hi
    ADD CONSTRAINT child_prof_2300_hi_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2300_pwk child_prof_2300_pwk_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_pwk
    ADD CONSTRAINT child_prof_2300_pwk_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2300_ref child_prof_2300_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_ref
    ADD CONSTRAINT child_prof_2300_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2310a_ref child_prof_2310a_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310a_ref
    ADD CONSTRAINT child_prof_2310a_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2310b_ref child_prof_2310b_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310b_ref
    ADD CONSTRAINT child_prof_2310b_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2310c_ref child_prof_2310c_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310c_ref
    ADD CONSTRAINT child_prof_2310c_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2310d_ref child_prof_2310d_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310d_ref
    ADD CONSTRAINT child_prof_2310d_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2320_amt child_prof_2320_amt_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2320_amt
    ADD CONSTRAINT child_prof_2320_amt_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2320_cas child_prof_2320_cas_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2320_cas
    ADD CONSTRAINT child_prof_2320_cas_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2330b_ref child_prof_2330b_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330b_ref
    ADD CONSTRAINT child_prof_2330b_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2330c_ref child_prof_2330c_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330c_ref
    ADD CONSTRAINT child_prof_2330c_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2330d_ref child_prof_2330d_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330d_ref
    ADD CONSTRAINT child_prof_2330d_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2330e_ref child_prof_2330e_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330e_ref
    ADD CONSTRAINT child_prof_2330e_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2330f_ref child_prof_2330f_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330f_ref
    ADD CONSTRAINT child_prof_2330f_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2330g_ref child_prof_2330g_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330g_ref
    ADD CONSTRAINT child_prof_2330g_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2400_amt child_prof_2400_amt_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_amt
    ADD CONSTRAINT child_prof_2400_amt_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2400_crc child_prof_2400_crc_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_crc
    ADD CONSTRAINT child_prof_2400_crc_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2400_dtp child_prof_2400_dtp_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_dtp
    ADD CONSTRAINT child_prof_2400_dtp_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2400_k3 child_prof_2400_k3_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_k3
    ADD CONSTRAINT child_prof_2400_k3_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2400_mea child_prof_2400_mea_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_mea
    ADD CONSTRAINT child_prof_2400_mea_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2400_nte child_prof_2400_nte_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_nte
    ADD CONSTRAINT child_prof_2400_nte_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2400_pwk child_prof_2400_pwk_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_pwk
    ADD CONSTRAINT child_prof_2400_pwk_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2400_qty child_prof_2400_qty_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_qty
    ADD CONSTRAINT child_prof_2400_qty_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2400_ref child_prof_2400_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_ref
    ADD CONSTRAINT child_prof_2400_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2410_ref child_prof_2410_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2410_ref
    ADD CONSTRAINT child_prof_2410_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2420a_ref child_prof_2420a_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420a_ref
    ADD CONSTRAINT child_prof_2420a_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2420b_ref child_prof_2420b_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420b_ref
    ADD CONSTRAINT child_prof_2420b_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2420c_ref child_prof_2420c_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420c_ref
    ADD CONSTRAINT child_prof_2420c_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2420d_ref child_prof_2420d_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420d_ref
    ADD CONSTRAINT child_prof_2420d_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2420e_ref child_prof_2420e_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420e_ref
    ADD CONSTRAINT child_prof_2420e_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2420f_ref child_prof_2420f_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420f_ref
    ADD CONSTRAINT child_prof_2420f_ref_pkey PRIMARY KEY (id);


--
-- Name: child_prof_2430_cas child_prof_2430_cas_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2430_cas
    ADD CONSTRAINT child_prof_2430_cas_pkey PRIMARY KEY (id);


--
-- Name: child_prof_claim_identifier_amt child_prof_claim_identifier_amt_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_claim_identifier_amt
    ADD CONSTRAINT child_prof_claim_identifier_amt_pkey PRIMARY KEY (id);


--
-- Name: child_prof_claim_identifier_dtp child_prof_claim_identifier_dtp_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_claim_identifier_dtp
    ADD CONSTRAINT child_prof_claim_identifier_dtp_pkey PRIMARY KEY (id);


--
-- Name: child_raps_cms_tracking_raps_resp child_raps_cms_tracking_raps_resp_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_raps_cms_tracking_raps_resp
    ADD CONSTRAINT child_raps_cms_tracking_raps_resp_pkey PRIMARY KEY (id);


--
-- Name: child_raps_feras_error_raps_resp child_raps_feras_error_raps_resp_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_raps_feras_error_raps_resp
    ADD CONSTRAINT child_raps_feras_error_raps_resp_pkey PRIMARY KEY (id);


--
-- Name: child_remit_1000a_per child_remit_1000a_per_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_1000a_per
    ADD CONSTRAINT child_remit_1000a_per_pkey PRIMARY KEY (id);


--
-- Name: child_remit_1000a_ref child_remit_1000a_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_1000a_ref
    ADD CONSTRAINT child_remit_1000a_ref_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2100_amt child_remit_2100_amt_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_amt
    ADD CONSTRAINT child_remit_2100_amt_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2100_cas child_remit_2100_cas_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_cas
    ADD CONSTRAINT child_remit_2100_cas_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2100_dtm child_remit_2100_dtm_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_dtm
    ADD CONSTRAINT child_remit_2100_dtm_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2100_nm1 child_remit_2100_nm1_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_nm1
    ADD CONSTRAINT child_remit_2100_nm1_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2100_per child_remit_2100_per_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_per
    ADD CONSTRAINT child_remit_2100_per_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2100_qty child_remit_2100_qty_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_qty
    ADD CONSTRAINT child_remit_2100_qty_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2100_ref child_remit_2100_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_ref
    ADD CONSTRAINT child_remit_2100_ref_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2110_amt child_remit_2110_amt_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_amt
    ADD CONSTRAINT child_remit_2110_amt_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2110_cas child_remit_2110_cas_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_cas
    ADD CONSTRAINT child_remit_2110_cas_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2110_dtm child_remit_2110_dtm_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_dtm
    ADD CONSTRAINT child_remit_2110_dtm_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2110_lq child_remit_2110_lq_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_lq
    ADD CONSTRAINT child_remit_2110_lq_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2110_qty child_remit_2110_qty_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_qty
    ADD CONSTRAINT child_remit_2110_qty_pkey PRIMARY KEY (id);


--
-- Name: child_remit_2110_ref child_remit_2110_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_ref
    ADD CONSTRAINT child_remit_2110_ref_pkey PRIMARY KEY (id);


--
-- Name: child_remit_bht_ref child_remit_bht_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_bht_ref
    ADD CONSTRAINT child_remit_bht_ref_pkey PRIMARY KEY (id);


--
-- Name: child_remit_identifier_nm1 child_remit_identifier_nm1_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_identifier_nm1
    ADD CONSTRAINT child_remit_identifier_nm1_pkey PRIMARY KEY (id);


--
-- Name: child_resp_277_2000b_amt child_resp_277_2000b_amt_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2000b_amt
    ADD CONSTRAINT child_resp_277_2000b_amt_pkey PRIMARY KEY (id);


--
-- Name: child_resp_277_2000b_qty child_resp_277_2000b_qty_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2000b_qty
    ADD CONSTRAINT child_resp_277_2000b_qty_pkey PRIMARY KEY (id);


--
-- Name: child_resp_277_2000d_dtp child_resp_277_2000d_dtp_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2000d_dtp
    ADD CONSTRAINT child_resp_277_2000d_dtp_pkey PRIMARY KEY (id);


--
-- Name: child_resp_277_2000d_ref child_resp_277_2000d_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2000d_ref
    ADD CONSTRAINT child_resp_277_2000d_ref_pkey PRIMARY KEY (id);


--
-- Name: child_resp_277_2000d_stc child_resp_277_2000d_stc_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2000d_stc
    ADD CONSTRAINT child_resp_277_2000d_stc_pkey PRIMARY KEY (id);


--
-- Name: child_resp_277_2220d_stc child_resp_277_2220d_stc_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2220d_stc
    ADD CONSTRAINT child_resp_277_2220d_stc_pkey PRIMARY KEY (id);


--
-- Name: child_resp_999_2100_ik4 child_resp_999_2100_ik4_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_999_2100_ik4
    ADD CONSTRAINT child_resp_999_2100_ik4_pkey PRIMARY KEY (id);


--
-- Name: child_x12file_resp_file child_x12file_resp_file_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_x12file_resp_file
    ADD CONSTRAINT child_x12file_resp_file_pkey PRIMARY KEY (id);


--
-- Name: child_x12file_x12shards child_x12file_x12shards_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_x12file_x12shards
    ADD CONSTRAINT child_x12file_x12shards_pkey PRIMARY KEY (id);


--
-- Name: claim_error claim_error_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.claim_error
    ADD CONSTRAINT claim_error_pkey PRIMARY KEY (id);


--
-- Name: cms_submitter_info cms_submitter_info_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.cms_submitter_info
    ADD CONSTRAINT cms_submitter_info_pkey PRIMARY KEY (id);


--
-- Name: customer_account customer_account_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.customer_account
    ADD CONSTRAINT customer_account_pkey PRIMARY KEY (id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- Name: databasechangeloglock databasechangeloglock_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.databasechangeloglock
    ADD CONSTRAINT databasechangeloglock_pkey PRIMARY KEY (id);


--
-- Name: flow_item_history flow_item_history_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.flow_item_history
    ADD CONSTRAINT flow_item_history_pkey PRIMARY KEY (id);


--
-- Name: flow_item flow_item_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.flow_item
    ADD CONSTRAINT flow_item_pkey PRIMARY KEY (id);


--
-- Name: flow flow_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.flow
    ADD CONSTRAINT flow_pkey PRIMARY KEY (id);


--
-- Name: global_ticker global_ticker_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.global_ticker
    ADD CONSTRAINT global_ticker_pkey PRIMARY KEY (id);


--
-- Name: h_plan_config h_plan_config_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.h_plan_config
    ADD CONSTRAINT h_plan_config_pkey PRIMARY KEY (id);


--
-- Name: h_plan_report h_plan_report_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.h_plan_report
    ADD CONSTRAINT h_plan_report_pkey PRIMARY KEY (id);


--
-- Name: h_plan_submitter h_plan_submitter_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.h_plan_submitter
    ADD CONSTRAINT h_plan_submitter_pkey PRIMARY KEY (id);


--
-- Name: hcc_diag_filtered hcc_diag_filtered_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.hcc_diag_filtered
    ADD CONSTRAINT hcc_diag_filtered_pkey PRIMARY KEY (id);


--
-- Name: hcc_diag_hierarchy_applied hcc_diag_hierarchy_applied_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.hcc_diag_hierarchy_applied
    ADD CONSTRAINT hcc_diag_hierarchy_applied_pkey PRIMARY KEY (id);


--
-- Name: hcc_diag_payment_year_modelcategory hcc_diag_payment_year_modelcategory_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.hcc_diag_payment_year_modelcategory
    ADD CONSTRAINT hcc_diag_payment_year_modelcategory_pkey PRIMARY KEY (id);


--
-- Name: hcc_diag hcc_diag_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.hcc_diag
    ADD CONSTRAINT hcc_diag_pkey PRIMARY KEY (id);


--
-- Name: health_plan health_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.health_plan
    ADD CONSTRAINT health_plan_pkey PRIMARY KEY (id);


--
-- Name: in_process_flows in_process_flows_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.in_process_flows
    ADD CONSTRAINT in_process_flows_pkey PRIMARY KEY (flow_item_id);


--
-- Name: inst_1000a inst_1000a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_1000a
    ADD CONSTRAINT inst_1000a_pkey PRIMARY KEY (id);


--
-- Name: inst_1000b inst_1000b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_1000b
    ADD CONSTRAINT inst_1000b_pkey PRIMARY KEY (id);


--
-- Name: inst_2000a inst_2000a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2000a
    ADD CONSTRAINT inst_2000a_pkey PRIMARY KEY (id);


--
-- Name: inst_2000b inst_2000b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2000b
    ADD CONSTRAINT inst_2000b_pkey PRIMARY KEY (id);


--
-- Name: inst_2000c inst_2000c_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2000c
    ADD CONSTRAINT inst_2000c_pkey PRIMARY KEY (id);


--
-- Name: inst_2010aa inst_2010aa_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010aa
    ADD CONSTRAINT inst_2010aa_pkey PRIMARY KEY (id);


--
-- Name: inst_2010ab inst_2010ab_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ab
    ADD CONSTRAINT inst_2010ab_pkey PRIMARY KEY (id);


--
-- Name: inst_2010ac inst_2010ac_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ac
    ADD CONSTRAINT inst_2010ac_pkey PRIMARY KEY (id);


--
-- Name: inst_2010ba inst_2010ba_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ba
    ADD CONSTRAINT inst_2010ba_pkey PRIMARY KEY (id);


--
-- Name: inst_2010bb inst_2010bb_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010bb
    ADD CONSTRAINT inst_2010bb_pkey PRIMARY KEY (id);


--
-- Name: inst_2010ca inst_2010ca_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ca
    ADD CONSTRAINT inst_2010ca_pkey PRIMARY KEY (id);


--
-- Name: inst_2300 inst_2300_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2300
    ADD CONSTRAINT inst_2300_pkey PRIMARY KEY (id);


--
-- Name: inst_2310a inst_2310a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310a
    ADD CONSTRAINT inst_2310a_pkey PRIMARY KEY (id);


--
-- Name: inst_2310b inst_2310b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310b
    ADD CONSTRAINT inst_2310b_pkey PRIMARY KEY (id);


--
-- Name: inst_2310c inst_2310c_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310c
    ADD CONSTRAINT inst_2310c_pkey PRIMARY KEY (id);


--
-- Name: inst_2310d inst_2310d_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310d
    ADD CONSTRAINT inst_2310d_pkey PRIMARY KEY (id);


--
-- Name: inst_2310e inst_2310e_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310e
    ADD CONSTRAINT inst_2310e_pkey PRIMARY KEY (id);


--
-- Name: inst_2310f inst_2310f_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310f
    ADD CONSTRAINT inst_2310f_pkey PRIMARY KEY (id);


--
-- Name: inst_2320 inst_2320_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2320
    ADD CONSTRAINT inst_2320_pkey PRIMARY KEY (id);


--
-- Name: inst_2330a inst_2330a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330a
    ADD CONSTRAINT inst_2330a_pkey PRIMARY KEY (id);


--
-- Name: inst_2330b inst_2330b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330b
    ADD CONSTRAINT inst_2330b_pkey PRIMARY KEY (id);


--
-- Name: inst_2330c inst_2330c_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330c
    ADD CONSTRAINT inst_2330c_pkey PRIMARY KEY (id);


--
-- Name: inst_2330d inst_2330d_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330d
    ADD CONSTRAINT inst_2330d_pkey PRIMARY KEY (id);


--
-- Name: inst_2330e inst_2330e_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330e
    ADD CONSTRAINT inst_2330e_pkey PRIMARY KEY (id);


--
-- Name: inst_2330f inst_2330f_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330f
    ADD CONSTRAINT inst_2330f_pkey PRIMARY KEY (id);


--
-- Name: inst_2330g inst_2330g_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330g
    ADD CONSTRAINT inst_2330g_pkey PRIMARY KEY (id);


--
-- Name: inst_2330h inst_2330h_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330h
    ADD CONSTRAINT inst_2330h_pkey PRIMARY KEY (id);


--
-- Name: inst_2330i inst_2330i_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330i
    ADD CONSTRAINT inst_2330i_pkey PRIMARY KEY (id);


--
-- Name: inst_2400 inst_2400_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2400
    ADD CONSTRAINT inst_2400_pkey PRIMARY KEY (id);


--
-- Name: inst_2410 inst_2410_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2410
    ADD CONSTRAINT inst_2410_pkey PRIMARY KEY (id);


--
-- Name: inst_2420a inst_2420a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2420a
    ADD CONSTRAINT inst_2420a_pkey PRIMARY KEY (id);


--
-- Name: inst_2420b inst_2420b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2420b
    ADD CONSTRAINT inst_2420b_pkey PRIMARY KEY (id);


--
-- Name: inst_2420c inst_2420c_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2420c
    ADD CONSTRAINT inst_2420c_pkey PRIMARY KEY (id);


--
-- Name: inst_2420d inst_2420d_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2420d
    ADD CONSTRAINT inst_2420d_pkey PRIMARY KEY (id);


--
-- Name: inst_2430 inst_2430_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2430
    ADD CONSTRAINT inst_2430_pkey PRIMARY KEY (id);


--
-- Name: inst_2440 inst_2440_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2440
    ADD CONSTRAINT inst_2440_pkey PRIMARY KEY (id);


--
-- Name: inst_bht inst_bht_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_bht
    ADD CONSTRAINT inst_bht_pkey PRIMARY KEY (id);


--
-- Name: inst_claim_data inst_claim_data_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_claim_data
    ADD CONSTRAINT inst_claim_data_pkey PRIMARY KEY (id);


--
-- Name: inst_claim_identifier inst_claim_identifier_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_claim_identifier
    ADD CONSTRAINT inst_claim_identifier_pkey PRIMARY KEY (id);


--
-- Name: inst_claim_line_data inst_claim_line_data_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_claim_line_data
    ADD CONSTRAINT inst_claim_line_data_pkey PRIMARY KEY (id);


--
-- Name: inst_header_trailer inst_header_trailer_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_header_trailer
    ADD CONSTRAINT inst_header_trailer_pkey PRIMARY KEY (id);


--
-- Name: inst_se inst_se_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_se
    ADD CONSTRAINT inst_se_pkey PRIMARY KEY (id);


--
-- Name: inst_st inst_st_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_st
    ADD CONSTRAINT inst_st_pkey PRIMARY KEY (id);


--
-- Name: inter_process_queue inter_process_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inter_process_queue
    ADD CONSTRAINT inter_process_queue_pkey PRIMARY KEY (id);


--
-- Name: linked_cr_batch linked_cr_batch_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.linked_cr_batch
    ADD CONSTRAINT linked_cr_batch_pkey PRIMARY KEY (id);


--
-- Name: member_raf member_raf_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.member_raf
    ADD CONSTRAINT member_raf_mapping_pkey PRIMARY KEY (id);


--
-- Name: mmr_data mmr_data_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.mmr_data
    ADD CONSTRAINT mmr_data_pkey PRIMARY KEY (id);


--
-- Name: model_run_config model_run_config_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.model_run_config
    ADD CONSTRAINT model_run_config_pkey PRIMARY KEY (id);


--
-- Name: prof_1000a prof_1000a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_1000a
    ADD CONSTRAINT prof_1000a_pkey PRIMARY KEY (id);


--
-- Name: prof_1000b prof_1000b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_1000b
    ADD CONSTRAINT prof_1000b_pkey PRIMARY KEY (id);


--
-- Name: prof_2000a prof_2000a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2000a
    ADD CONSTRAINT prof_2000a_pkey PRIMARY KEY (id);


--
-- Name: prof_2000b prof_2000b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2000b
    ADD CONSTRAINT prof_2000b_pkey PRIMARY KEY (id);


--
-- Name: prof_2000c prof_2000c_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2000c
    ADD CONSTRAINT prof_2000c_pkey PRIMARY KEY (id);


--
-- Name: prof_2010aa prof_2010aa_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010aa
    ADD CONSTRAINT prof_2010aa_pkey PRIMARY KEY (id);


--
-- Name: prof_2010ab prof_2010ab_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ab
    ADD CONSTRAINT prof_2010ab_pkey PRIMARY KEY (id);


--
-- Name: prof_2010ac prof_2010ac_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ac
    ADD CONSTRAINT prof_2010ac_pkey PRIMARY KEY (id);


--
-- Name: prof_2010ba prof_2010ba_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ba
    ADD CONSTRAINT prof_2010ba_pkey PRIMARY KEY (id);


--
-- Name: prof_2010bb prof_2010bb_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010bb
    ADD CONSTRAINT prof_2010bb_pkey PRIMARY KEY (id);


--
-- Name: prof_2010ca prof_2010ca_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ca
    ADD CONSTRAINT prof_2010ca_pkey PRIMARY KEY (id);


--
-- Name: prof_2300 prof_2300_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2300
    ADD CONSTRAINT prof_2300_pkey PRIMARY KEY (id);


--
-- Name: prof_2310a prof_2310a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310a
    ADD CONSTRAINT prof_2310a_pkey PRIMARY KEY (id);


--
-- Name: prof_2310b prof_2310b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310b
    ADD CONSTRAINT prof_2310b_pkey PRIMARY KEY (id);


--
-- Name: prof_2310c prof_2310c_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310c
    ADD CONSTRAINT prof_2310c_pkey PRIMARY KEY (id);


--
-- Name: prof_2310d prof_2310d_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310d
    ADD CONSTRAINT prof_2310d_pkey PRIMARY KEY (id);


--
-- Name: prof_2310e prof_2310e_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310e
    ADD CONSTRAINT prof_2310e_pkey PRIMARY KEY (id);


--
-- Name: prof_2310f prof_2310f_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310f
    ADD CONSTRAINT prof_2310f_pkey PRIMARY KEY (id);


--
-- Name: prof_2320 prof_2320_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2320
    ADD CONSTRAINT prof_2320_pkey PRIMARY KEY (id);


--
-- Name: prof_2330a prof_2330a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330a
    ADD CONSTRAINT prof_2330a_pkey PRIMARY KEY (id);


--
-- Name: prof_2330b prof_2330b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330b
    ADD CONSTRAINT prof_2330b_pkey PRIMARY KEY (id);


--
-- Name: prof_2330c prof_2330c_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330c
    ADD CONSTRAINT prof_2330c_pkey PRIMARY KEY (id);


--
-- Name: prof_2330d prof_2330d_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330d
    ADD CONSTRAINT prof_2330d_pkey PRIMARY KEY (id);


--
-- Name: prof_2330e prof_2330e_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330e
    ADD CONSTRAINT prof_2330e_pkey PRIMARY KEY (id);


--
-- Name: prof_2330f prof_2330f_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330f
    ADD CONSTRAINT prof_2330f_pkey PRIMARY KEY (id);


--
-- Name: prof_2330g prof_2330g_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330g
    ADD CONSTRAINT prof_2330g_pkey PRIMARY KEY (id);


--
-- Name: prof_2400 prof_2400_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2400
    ADD CONSTRAINT prof_2400_pkey PRIMARY KEY (id);


--
-- Name: prof_2410 prof_2410_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2410
    ADD CONSTRAINT prof_2410_pkey PRIMARY KEY (id);


--
-- Name: prof_2420a prof_2420a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420a
    ADD CONSTRAINT prof_2420a_pkey PRIMARY KEY (id);


--
-- Name: prof_2420b prof_2420b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420b
    ADD CONSTRAINT prof_2420b_pkey PRIMARY KEY (id);


--
-- Name: prof_2420c prof_2420c_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420c
    ADD CONSTRAINT prof_2420c_pkey PRIMARY KEY (id);


--
-- Name: prof_2420d prof_2420d_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420d
    ADD CONSTRAINT prof_2420d_pkey PRIMARY KEY (id);


--
-- Name: prof_2420e prof_2420e_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420e
    ADD CONSTRAINT prof_2420e_pkey PRIMARY KEY (id);


--
-- Name: prof_2420f prof_2420f_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420f
    ADD CONSTRAINT prof_2420f_pkey PRIMARY KEY (id);


--
-- Name: prof_2420g prof_2420g_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420g
    ADD CONSTRAINT prof_2420g_pkey PRIMARY KEY (id);


--
-- Name: prof_2420h prof_2420h_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420h
    ADD CONSTRAINT prof_2420h_pkey PRIMARY KEY (id);


--
-- Name: prof_2430 prof_2430_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2430
    ADD CONSTRAINT prof_2430_pkey PRIMARY KEY (id);


--
-- Name: prof_2440 prof_2440_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2440
    ADD CONSTRAINT prof_2440_pkey PRIMARY KEY (id);


--
-- Name: prof_bht prof_bht_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_bht
    ADD CONSTRAINT prof_bht_pkey PRIMARY KEY (id);


--
-- Name: prof_claim_data prof_claim_data_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_claim_data
    ADD CONSTRAINT prof_claim_data_pkey PRIMARY KEY (id);


--
-- Name: prof_claim_identifier prof_claim_identifier_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_claim_identifier
    ADD CONSTRAINT prof_claim_identifier_pkey PRIMARY KEY (id);


--
-- Name: prof_claim_line_data prof_claim_line_data_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_claim_line_data
    ADD CONSTRAINT prof_claim_line_data_pkey PRIMARY KEY (id);


--
-- Name: prof_header_trailer prof_header_trailer_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_header_trailer
    ADD CONSTRAINT prof_header_trailer_pkey PRIMARY KEY (id);


--
-- Name: prof_se prof_se_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_se
    ADD CONSTRAINT prof_se_pkey PRIMARY KEY (id);


--
-- Name: prof_st prof_st_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_st
    ADD CONSTRAINT prof_st_pkey PRIMARY KEY (id);


--
-- Name: provider_837_remit_mapping provider_837_remit_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.provider_837_remit_mapping
    ADD CONSTRAINT provider_837_remit_mapping_pkey PRIMARY KEY (id);


--
-- Name: raps_cluster_history raps_cluster_history_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_cluster_history
    ADD CONSTRAINT raps_cluster_history_pkey PRIMARY KEY (id);


--
-- Name: raps_cluster raps_cluster_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_cluster
    ADD CONSTRAINT raps_cluster_pkey PRIMARY KEY (id);


--
-- Name: raps_cms_tracking raps_cms_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_cms_tracking
    ADD CONSTRAINT raps_cms_tracking_pkey PRIMARY KEY (id);


--
-- Name: raps_eef raps_eef_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_eef
    ADD CONSTRAINT raps_eef_pkey PRIMARY KEY (id);


--
-- Name: raps_feras_error raps_feras_error_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_feras_error
    ADD CONSTRAINT raps_feras_error_pkey PRIMARY KEY (id);


--
-- Name: raps_file raps_file_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_file
    ADD CONSTRAINT raps_file_pkey PRIMARY KEY (id);


--
-- Name: remit_1000a remit_1000a_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_1000a
    ADD CONSTRAINT remit_1000a_pkey PRIMARY KEY (id);


--
-- Name: remit_1000b remit_1000b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_1000b
    ADD CONSTRAINT remit_1000b_pkey PRIMARY KEY (id);


--
-- Name: remit_2000 remit_2000_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_2000
    ADD CONSTRAINT remit_2000_pkey PRIMARY KEY (id);


--
-- Name: remit_2100 remit_2100_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_2100
    ADD CONSTRAINT remit_2100_pkey PRIMARY KEY (id);


--
-- Name: remit_2110 remit_2110_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_2110
    ADD CONSTRAINT remit_2110_pkey PRIMARY KEY (id);


--
-- Name: remit_bht remit_bht_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_bht
    ADD CONSTRAINT remit_bht_pkey PRIMARY KEY (id);


--
-- Name: remit_footer remit_footer_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_footer
    ADD CONSTRAINT remit_footer_pkey PRIMARY KEY (id);


--
-- Name: remit_header_trailer remit_header_trailer_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_header_trailer
    ADD CONSTRAINT remit_header_trailer_pkey PRIMARY KEY (id);


--
-- Name: remit_identifier remit_identifier_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_identifier
    ADD CONSTRAINT remit_identifier_pkey PRIMARY KEY (id);


--
-- Name: remit_st remit_st_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_st
    ADD CONSTRAINT remit_st_pkey PRIMARY KEY (id);


--
-- Name: report_category report_category_pk; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_category
    ADD CONSTRAINT report_category_pk PRIMARY KEY (id);


--
-- Name: report_details report_details_pk; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_details
    ADD CONSTRAINT report_details_pk PRIMARY KEY (id);


--
-- Name: report_category report_name_category_idx; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_category
    ADD CONSTRAINT report_name_category_idx UNIQUE (report_name, category);


--
-- Name: report_subscription report_subscription_pk; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_subscription
    ADD CONSTRAINT report_subscription_pk PRIMARY KEY (id);


--
-- Name: report_type report_type_pk; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_type
    ADD CONSTRAINT report_type_pk PRIMARY KEY (name);


--
-- Name: resp_277_2000b resp_277_2000b_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_2000b
    ADD CONSTRAINT resp_277_2000b_pkey PRIMARY KEY (id);


--
-- Name: resp_277_2000c resp_277_2000c_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_2000c
    ADD CONSTRAINT resp_277_2000c_pkey PRIMARY KEY (id);


--
-- Name: resp_277_2000d resp_277_2000d_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_2000d
    ADD CONSTRAINT resp_277_2000d_pkey PRIMARY KEY (id);


--
-- Name: resp_277_2220d resp_277_2220d_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_2220d
    ADD CONSTRAINT resp_277_2220d_pkey PRIMARY KEY (id);


--
-- Name: resp_277_bht resp_277_bht_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_bht
    ADD CONSTRAINT resp_277_bht_pkey PRIMARY KEY (id);


--
-- Name: resp_277_header_trailer resp_277_header_trailer_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_header_trailer
    ADD CONSTRAINT resp_277_header_trailer_pkey PRIMARY KEY (id);


--
-- Name: resp_277_st resp_277_st_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_st
    ADD CONSTRAINT resp_277_st_pkey PRIMARY KEY (id);


--
-- Name: resp_999_2000 resp_999_2000_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_999_2000
    ADD CONSTRAINT resp_999_2000_pkey PRIMARY KEY (id);


--
-- Name: resp_999_2100 resp_999_2100_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_999_2100
    ADD CONSTRAINT resp_999_2100_pkey PRIMARY KEY (id);


--
-- Name: resp_999_2110 resp_999_2110_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_999_2110
    ADD CONSTRAINT resp_999_2110_pkey PRIMARY KEY (id);


--
-- Name: resp_999_bht resp_999_bht_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_999_bht
    ADD CONSTRAINT resp_999_bht_pkey PRIMARY KEY (id);


--
-- Name: resp_999_header_trailer resp_999_header_trailer_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_999_header_trailer
    ADD CONSTRAINT resp_999_header_trailer_pkey PRIMARY KEY (id);


--
-- Name: resp_mao_1 resp_mao_1_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_mao_1
    ADD CONSTRAINT resp_mao_1_pkey PRIMARY KEY (id);


--
-- Name: resp_mao_2 resp_mao_2_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_mao_2
    ADD CONSTRAINT resp_mao_2_pkey PRIMARY KEY (id);


--
-- Name: resp_mao_4 resp_mao_4_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_mao_4
    ADD CONSTRAINT resp_mao_4_pkey PRIMARY KEY (id);


--
-- Name: resp_ta1_data resp_ta1_data_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_ta1_data
    ADD CONSTRAINT resp_ta1_data_pkey PRIMARY KEY (id);


--
-- Name: resp_ta1_header_trailer resp_ta1_header_trailer_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_ta1_header_trailer
    ADD CONSTRAINT resp_ta1_header_trailer_pkey PRIMARY KEY (id);


--
-- Name: shedlock shedlock_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.shedlock
    ADD CONSTRAINT shedlock_pkey PRIMARY KEY (name);


--
-- Name: submitter_info_config submitter_info_config_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.submitter_info_config
    ADD CONSTRAINT submitter_info_config_pkey PRIMARY KEY (id);


--
-- Name: tenant_schema tenant_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.tenant_schema
    ADD CONSTRAINT tenant_pkey PRIMARY KEY (tenant_id);


--
-- Name: inst_2300 uk_3lrgdmf6uq42go0bcpr1p6jdt; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2300
    ADD CONSTRAINT uk_3lrgdmf6uq42go0bcpr1p6jdt UNIQUE (claim_id);


--
-- Name: prof_2310e uk_421tc55qcbdw9kaloj68vc6y3; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310e
    ADD CONSTRAINT uk_421tc55qcbdw9kaloj68vc6y3 UNIQUE (claim_id);


--
-- Name: prof_2010aa uk_43o022kykedt4ehbi5e5hymel; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010aa
    ADD CONSTRAINT uk_43o022kykedt4ehbi5e5hymel UNIQUE (claim_id);


--
-- Name: inst_2310e uk_44gehh6p06jrmnuyrnrd6rwb8; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310e
    ADD CONSTRAINT uk_44gehh6p06jrmnuyrnrd6rwb8 UNIQUE (claim_id);


--
-- Name: inst_2010bb uk_5ig955dli1kbg4gv240tpxauv; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010bb
    ADD CONSTRAINT uk_5ig955dli1kbg4gv240tpxauv UNIQUE (claim_id);


--
-- Name: prof_2010bb uk_5r1t8hs7degfqnapcspkq7n6d; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010bb
    ADD CONSTRAINT uk_5r1t8hs7degfqnapcspkq7n6d UNIQUE (claim_id);


--
-- Name: inst_2010aa uk_7mngogivuli7ss4qw9p3vb2ap; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010aa
    ADD CONSTRAINT uk_7mngogivuli7ss4qw9p3vb2ap UNIQUE (claim_id);


--
-- Name: prof_2300 uk_7rx0cqyqcc1nb81soah8bt18; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2300
    ADD CONSTRAINT uk_7rx0cqyqcc1nb81soah8bt18 UNIQUE (claim_id);


--
-- Name: inst_2310d uk_85lbng5ydy0754fjfqj3yo83a; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310d
    ADD CONSTRAINT uk_85lbng5ydy0754fjfqj3yo83a UNIQUE (claim_id);


--
-- Name: inst_2310c uk_8dnxndtnm4m0cbsfoltjra87e; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310c
    ADD CONSTRAINT uk_8dnxndtnm4m0cbsfoltjra87e UNIQUE (claim_id);


--
-- Name: prof_2310f uk_8i74lt2d9ns566d0sw27rrkfs; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310f
    ADD CONSTRAINT uk_8i74lt2d9ns566d0sw27rrkfs UNIQUE (claim_id);


--
-- Name: inst_2310b uk_9fotmd4mekbjmcl3i18piagmh; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310b
    ADD CONSTRAINT uk_9fotmd4mekbjmcl3i18piagmh UNIQUE (claim_id);


--
-- Name: inst_2010ba uk_b0yd4ca7g018mjnhjckgcsei; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ba
    ADD CONSTRAINT uk_b0yd4ca7g018mjnhjckgcsei UNIQUE (claim_id);


--
-- Name: prof_2010ab uk_bjgf01j9cjddxniienfjmp3kl; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ab
    ADD CONSTRAINT uk_bjgf01j9cjddxniienfjmp3kl UNIQUE (claim_id);


--
-- Name: x12file uk_bo4r7mbclvdkfwr8scwr4mp31; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12file
    ADD CONSTRAINT uk_bo4r7mbclvdkfwr8scwr4mp31 UNIQUE (source_file_name);


--
-- Name: prof_2000b uk_dbjnocdab5rkhqge5639wh97i; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2000b
    ADD CONSTRAINT uk_dbjnocdab5rkhqge5639wh97i UNIQUE (claim_id);


--
-- Name: prof_2010ac uk_df0tf4306pw6a63r2sal9x08; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ac
    ADD CONSTRAINT uk_df0tf4306pw6a63r2sal9x08 UNIQUE (claim_id);


--
-- Name: inst_2010ab uk_du0o5hv0u1bepd8sxfrwguh9y; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ab
    ADD CONSTRAINT uk_du0o5hv0u1bepd8sxfrwguh9y UNIQUE (claim_id);


--
-- Name: prof_2000a uk_ekx2vgbqtreem5d1bikg6oyo3; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2000a
    ADD CONSTRAINT uk_ekx2vgbqtreem5d1bikg6oyo3 UNIQUE (claim_id);


--
-- Name: inst_2310a uk_fgqgefvtf3y5nguxuhlx3qmva; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310a
    ADD CONSTRAINT uk_fgqgefvtf3y5nguxuhlx3qmva UNIQUE (claim_id);


--
-- Name: raps_file uk_fss73n6sbt3cvpkpsd0xjxb4v; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_file
    ADD CONSTRAINT uk_fss73n6sbt3cvpkpsd0xjxb4v UNIQUE (source_file_name);


--
-- Name: inst_2010ca uk_gq2hrdx3vmrdo2pr7y0qrl7hw; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ca
    ADD CONSTRAINT uk_gq2hrdx3vmrdo2pr7y0qrl7hw UNIQUE (claim_id);


--
-- Name: remit_2100 uk_grm2n4mo3hjishj6otpf4sk77; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_2100
    ADD CONSTRAINT uk_grm2n4mo3hjishj6otpf4sk77 UNIQUE (remittance_id);


--
-- Name: inst_2000b uk_ijnq79xqxd0ahe5owq4ocm0ti; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2000b
    ADD CONSTRAINT uk_ijnq79xqxd0ahe5owq4ocm0ti UNIQUE (claim_id);


--
-- Name: prof_2310c uk_jog2p94uq716gfcmi438451h; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310c
    ADD CONSTRAINT uk_jog2p94uq716gfcmi438451h UNIQUE (claim_id);


--
-- Name: customer_account uk_mja6rs2vpev73f0qctrkjrjrn; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.customer_account
    ADD CONSTRAINT uk_mja6rs2vpev73f0qctrkjrjrn UNIQUE (name);


--
-- Name: inst_2010ac uk_nlyi446d0ak00gs9ydfe1emu3; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ac
    ADD CONSTRAINT uk_nlyi446d0ak00gs9ydfe1emu3 UNIQUE (claim_id);


--
-- Name: prof_2010ca uk_ny5f7i7ehmhatgnn26gha66nt; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ca
    ADD CONSTRAINT uk_ny5f7i7ehmhatgnn26gha66nt UNIQUE (claim_id);


--
-- Name: inst_2000c uk_p8htosi87d7hscvi1q6y8b9v2; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2000c
    ADD CONSTRAINT uk_p8htosi87d7hscvi1q6y8b9v2 UNIQUE (claim_id);


--
-- Name: prof_2310d uk_popyt2tdv30ksk50d1bb55wh; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310d
    ADD CONSTRAINT uk_popyt2tdv30ksk50d1bb55wh UNIQUE (claim_id);


--
-- Name: inst_2000a uk_prkuwtxjt7559i76jf78b8aw3; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2000a
    ADD CONSTRAINT uk_prkuwtxjt7559i76jf78b8aw3 UNIQUE (claim_id);


--
-- Name: prof_2010ba uk_rd9sb3ho56bq6hdcyxmn69y9d; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ba
    ADD CONSTRAINT uk_rd9sb3ho56bq6hdcyxmn69y9d UNIQUE (claim_id);


--
-- Name: prof_2310b uk_ris9ua5lq4mmt4omwiyfik37j; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310b
    ADD CONSTRAINT uk_ris9ua5lq4mmt4omwiyfik37j UNIQUE (claim_id);


--
-- Name: prof_2000c uk_rlrl560h4ec3fvnng7cau8b61; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2000c
    ADD CONSTRAINT uk_rlrl560h4ec3fvnng7cau8b61 UNIQUE (claim_id);


--
-- Name: inst_2310f uk_t6fmq3jf6acx51wnk8ce6p95t; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310f
    ADD CONSTRAINT uk_t6fmq3jf6acx51wnk8ce6p95t UNIQUE (claim_id);


--
-- Name: x12_duplicate_file x12_duplicate_file_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12_duplicate_file
    ADD CONSTRAINT x12_duplicate_file_pkey PRIMARY KEY (id);


--
-- Name: x12_resp_duplicate_file x12_resp_duplicate_file_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12_resp_duplicate_file
    ADD CONSTRAINT x12_resp_duplicate_file_pkey PRIMARY KEY (id);


--
-- Name: x12file x12file_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12file
    ADD CONSTRAINT x12file_pkey PRIMARY KEY (id);


--
-- Name: x12file_struct_validation x12file_struct_validation_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12file_struct_validation
    ADD CONSTRAINT x12file_struct_validation_pkey PRIMARY KEY (id);


--
-- Name: xref_billtype_ipop xref_billtype_ipop_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_billtype_ipop
    ADD CONSTRAINT xref_billtype_ipop_pkey PRIMARY KEY (id);


--
-- Name: xref_claim_error_277 xref_claim_error_277_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_claim_error_277
    ADD CONSTRAINT xref_claim_error_277_pkey PRIMARY KEY (id);


--
-- Name: xref_claim_error_999 xref_claim_error_999_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_claim_error_999
    ADD CONSTRAINT xref_claim_error_999_pkey PRIMARY KEY (id);


--
-- Name: xref_claim_error_mao2 xref_claim_error_mao2_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_claim_error_mao2
    ADD CONSTRAINT xref_claim_error_mao2_pkey PRIMARY KEY (id);


--
-- Name: xref_dme_pos xref_dme_pos_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_dme_pos
    ADD CONSTRAINT xref_dme_pos_pkey PRIMARY KEY (id);


--
-- Name: xref_edit_error xref_edit_error_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_edit_error
    ADD CONSTRAINT xref_edit_error_pkey PRIMARY KEY (internal_error_number);


--
-- Name: xref_hcc_description xref_hcc_description_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_hcc_description
    ADD CONSTRAINT xref_hcc_description_pkey PRIMARY KEY (id);


--
-- Name: xref_hcc_drop xref_hcc_drop_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_hcc_drop
    ADD CONSTRAINT xref_hcc_drop_pkey PRIMARY KEY (id);


--
-- Name: xref_hcpcs_cpt xref_hcpcs_cpt_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_hcpcs_cpt
    ADD CONSTRAINT xref_hcpcs_cpt_pkey PRIMARY KEY (id);


--
-- Name: xref_hicn_mbi xref_hicn_mbi_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_hicn_mbi
    ADD CONSTRAINT xref_hicn_mbi_pkey PRIMARY KEY (id);


--
-- Name: xref_icd_hcc xref_icd_hcc_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_icd_hcc
    ADD CONSTRAINT xref_icd_hcc_pkey PRIMARY KEY (id);


--
-- Name: xref_raf_codes xref_raf_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_raf_codes
    ADD CONSTRAINT xref_raf_codes_pkey PRIMARY KEY (id);


--
-- Name: xref_raps_error xref_raps_error_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_raps_error
    ADD CONSTRAINT xref_raps_error_pkey PRIMARY KEY (id);


--
-- Name: xref_specialty_codes xref_specialty_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_specialty_codes
    ADD CONSTRAINT xref_specialty_codes_pkey PRIMARY KEY (id);


--
-- Name: xref_specialty_taxonomy xref_specialty_taxonomy_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_specialty_taxonomy
    ADD CONSTRAINT xref_specialty_taxonomy_pkey PRIMARY KEY (id);


--
-- Name: xref_ta1_error xref_ta1_error_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_ta1_error
    ADD CONSTRAINT xref_ta1_error_pkey PRIMARY KEY (id);


--
-- Name: batch_data_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX batch_data_file_idx ON public.batch_data USING btree (batch_file_id);


--
-- Name: batch_data_status_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX batch_data_status_idx ON public.batch_data USING btree (status) WHERE (status = 'NEW'::text);


--
-- Name: child_inst_2010aa_per_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2010aa_per_claim_idx ON public.child_inst_2010aa_per USING btree (claim_id);


--
-- Name: child_inst_2010aa_per_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2010aa_per_parent_idx ON public.child_inst_2010aa_per USING btree (parent_id);


--
-- Name: child_inst_2010aa_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2010aa_ref_claim_idx ON public.child_inst_2010aa_ref USING btree (claim_id);


--
-- Name: child_inst_2010aa_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2010aa_ref_parent_idx ON public.child_inst_2010aa_ref USING btree (parent_id);


--
-- Name: child_inst_2010ac_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2010ac_ref_claim_idx ON public.child_inst_2010ac_ref USING btree (claim_id);


--
-- Name: child_inst_2010ac_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2010ac_ref_parent_idx ON public.child_inst_2010ac_ref USING btree (parent_id);


--
-- Name: child_inst_2010ba_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2010ba_ref_claim_idx ON public.child_inst_2010ba_ref USING btree (claim_id);


--
-- Name: child_inst_2010ba_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2010ba_ref_parent_idx ON public.child_inst_2010ba_ref USING btree (parent_id);


--
-- Name: child_inst_2010bb_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2010bb_ref_claim_idx ON public.child_inst_2010bb_ref USING btree (claim_id);


--
-- Name: child_inst_2010bb_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2010bb_ref_parent_idx ON public.child_inst_2010bb_ref USING btree (parent_id);


--
-- Name: child_inst_2300_dtp_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2300_dtp_claim_idx ON public.child_inst_2300_dtp USING btree (claim_id);


--
-- Name: child_inst_2300_dtp_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2300_dtp_parent_idx ON public.child_inst_2300_dtp USING btree (parent_id);


--
-- Name: child_inst_2300_hi_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2300_hi_claim_idx ON public.child_inst_2300_hi USING btree (claim_id);


--
-- Name: child_inst_2300_hi_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2300_hi_parent_idx ON public.child_inst_2300_hi USING btree (parent_id);


--
-- Name: child_inst_2300_nte_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2300_nte_claim_idx ON public.child_inst_2300_nte USING btree (claim_id);


--
-- Name: child_inst_2300_nte_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2300_nte_parent_idx ON public.child_inst_2300_nte USING btree (parent_id);


--
-- Name: child_inst_2300_pwk_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2300_pwk_claim_idx ON public.child_inst_2300_pwk USING btree (claim_id);


--
-- Name: child_inst_2300_pwk_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2300_pwk_parent_idx ON public.child_inst_2300_pwk USING btree (parent_id);


--
-- Name: child_inst_2300_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2300_ref_claim_idx ON public.child_inst_2300_ref USING btree (claim_id);


--
-- Name: child_inst_2300_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2300_ref_parent_idx ON public.child_inst_2300_ref USING btree (parent_id);


--
-- Name: child_inst_2310a_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310a_ref_claim_idx ON public.child_inst_2310a_ref USING btree (claim_id);


--
-- Name: child_inst_2310a_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310a_ref_parent_idx ON public.child_inst_2310a_ref USING btree (parent_id);


--
-- Name: child_inst_2310b_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310b_ref_claim_idx ON public.child_inst_2310b_ref USING btree (claim_id);


--
-- Name: child_inst_2310b_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310b_ref_parent_idx ON public.child_inst_2310b_ref USING btree (parent_id);


--
-- Name: child_inst_2310c_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310c_ref_claim_idx ON public.child_inst_2310c_ref USING btree (claim_id);


--
-- Name: child_inst_2310c_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310c_ref_parent_idx ON public.child_inst_2310c_ref USING btree (parent_id);


--
-- Name: child_inst_2310d_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310d_ref_claim_idx ON public.child_inst_2310d_ref USING btree (claim_id);


--
-- Name: child_inst_2310d_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310d_ref_parent_idx ON public.child_inst_2310d_ref USING btree (parent_id);


--
-- Name: child_inst_2310e_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310e_ref_claim_idx ON public.child_inst_2310e_ref USING btree (claim_id);


--
-- Name: child_inst_2310e_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310e_ref_parent_idx ON public.child_inst_2310e_ref USING btree (parent_id);


--
-- Name: child_inst_2310f_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310f_ref_claim_idx ON public.child_inst_2310f_ref USING btree (claim_id);


--
-- Name: child_inst_2310f_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2310f_ref_parent_idx ON public.child_inst_2310f_ref USING btree (parent_id);


--
-- Name: child_inst_2320_amt_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2320_amt_claim_idx ON public.child_inst_2320_amt USING btree (claim_id);


--
-- Name: child_inst_2320_amt_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2320_amt_parent_idx ON public.child_inst_2320_amt USING btree (parent_id);


--
-- Name: child_inst_2320_cas_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2320_cas_claim_idx ON public.child_inst_2320_cas USING btree (claim_id);


--
-- Name: child_inst_2320_cas_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2320_cas_parent_idx ON public.child_inst_2320_cas USING btree (parent_id);


--
-- Name: child_inst_2330b_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330b_ref_claim_idx ON public.child_inst_2330b_ref USING btree (claim_id);


--
-- Name: child_inst_2330b_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330b_ref_parent_idx ON public.child_inst_2330b_ref USING btree (parent_id);


--
-- Name: child_inst_2330c_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330c_ref_claim_idx ON public.child_inst_2330c_ref USING btree (claim_id);


--
-- Name: child_inst_2330c_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330c_ref_parent_idx ON public.child_inst_2330c_ref USING btree (parent_id);


--
-- Name: child_inst_2330d_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330d_ref_claim_idx ON public.child_inst_2330d_ref USING btree (claim_id);


--
-- Name: child_inst_2330d_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330d_ref_parent_idx ON public.child_inst_2330d_ref USING btree (parent_id);


--
-- Name: child_inst_2330e_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330e_ref_claim_idx ON public.child_inst_2330e_ref USING btree (claim_id);


--
-- Name: child_inst_2330e_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330e_ref_parent_idx ON public.child_inst_2330e_ref USING btree (parent_id);


--
-- Name: child_inst_2330f_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330f_ref_claim_idx ON public.child_inst_2330f_ref USING btree (claim_id);


--
-- Name: child_inst_2330f_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330f_ref_parent_idx ON public.child_inst_2330f_ref USING btree (parent_id);


--
-- Name: child_inst_2330g_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330g_ref_claim_idx ON public.child_inst_2330g_ref USING btree (claim_id);


--
-- Name: child_inst_2330g_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330g_ref_parent_idx ON public.child_inst_2330g_ref USING btree (parent_id);


--
-- Name: child_inst_2330h_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330h_ref_claim_idx ON public.child_inst_2330h_ref USING btree (claim_id);


--
-- Name: child_inst_2330h_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330h_ref_parent_idx ON public.child_inst_2330h_ref USING btree (parent_id);


--
-- Name: child_inst_2330i_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330i_ref_claim_idx ON public.child_inst_2330i_ref USING btree (claim_id);


--
-- Name: child_inst_2330i_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2330i_ref_parent_idx ON public.child_inst_2330i_ref USING btree (parent_id);


--
-- Name: child_inst_2400_amt_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2400_amt_claim_idx ON public.child_inst_2400_amt USING btree (claim_id);


--
-- Name: child_inst_2400_amt_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2400_amt_parent_idx ON public.child_inst_2400_amt USING btree (parent_id);


--
-- Name: child_inst_2400_dtp_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2400_dtp_claim_idx ON public.child_inst_2400_dtp USING btree (claim_id);


--
-- Name: child_inst_2400_dtp_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2400_dtp_parent_idx ON public.child_inst_2400_dtp USING btree (parent_id);


--
-- Name: child_inst_2400_pwk_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2400_pwk_claim_idx ON public.child_inst_2400_pwk USING btree (claim_id);


--
-- Name: child_inst_2400_pwk_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2400_pwk_parent_idx ON public.child_inst_2400_pwk USING btree (parent_id);


--
-- Name: child_inst_2400_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2400_ref_claim_idx ON public.child_inst_2400_ref USING btree (claim_id);


--
-- Name: child_inst_2400_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2400_ref_parent_idx ON public.child_inst_2400_ref USING btree (parent_id);


--
-- Name: child_inst_2410_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2410_ref_claim_idx ON public.child_inst_2410_ref USING btree (claim_id);


--
-- Name: child_inst_2410_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2410_ref_parent_idx ON public.child_inst_2410_ref USING btree (parent_id);


--
-- Name: child_inst_2420a_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2420a_ref_claim_idx ON public.child_inst_2420a_ref USING btree (claim_id);


--
-- Name: child_inst_2420a_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2420a_ref_parent_idx ON public.child_inst_2420a_ref USING btree (parent_id);


--
-- Name: child_inst_2420b_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2420b_ref_claim_idx ON public.child_inst_2420b_ref USING btree (claim_id);


--
-- Name: child_inst_2420b_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2420b_ref_parent_idx ON public.child_inst_2420b_ref USING btree (parent_id);


--
-- Name: child_inst_2420c_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2420c_ref_claim_idx ON public.child_inst_2420c_ref USING btree (claim_id);


--
-- Name: child_inst_2420c_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2420c_ref_parent_idx ON public.child_inst_2420c_ref USING btree (parent_id);


--
-- Name: child_inst_2420d_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2420d_ref_claim_idx ON public.child_inst_2420d_ref USING btree (claim_id);


--
-- Name: child_inst_2420d_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2420d_ref_parent_idx ON public.child_inst_2420d_ref USING btree (parent_id);


--
-- Name: child_inst_2430_cas_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2430_cas_claim_idx ON public.child_inst_2430_cas USING btree (claim_id);


--
-- Name: child_inst_2430_cas_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_2430_cas_parent_idx ON public.child_inst_2430_cas USING btree (parent_id);


--
-- Name: child_inst_claim_identifier_amt_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_claim_identifier_amt_claim_idx ON public.child_inst_claim_identifier_amt USING btree (claim_id);


--
-- Name: child_inst_claim_identifier_amt_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_claim_identifier_amt_parent_idx ON public.child_inst_claim_identifier_amt USING btree (parent_id);


--
-- Name: child_inst_claim_identifier_dtp_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_claim_identifier_dtp_claim_idx ON public.child_inst_claim_identifier_dtp USING btree (claim_id);


--
-- Name: child_inst_claim_identifier_dtp_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_inst_claim_identifier_dtp_parent_idx ON public.child_inst_claim_identifier_dtp USING btree (parent_id);


--
-- Name: child_prof_2010aa_per_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2010aa_per_claim_idx ON public.child_prof_2010aa_per USING btree (claim_id);


--
-- Name: child_prof_2010aa_per_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2010aa_per_parent_idx ON public.child_prof_2010aa_per USING btree (parent_id);


--
-- Name: child_prof_2010aa_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2010aa_ref_claim_idx ON public.child_prof_2010aa_ref USING btree (claim_id);


--
-- Name: child_prof_2010aa_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2010aa_ref_parent_idx ON public.child_prof_2010aa_ref USING btree (parent_id);


--
-- Name: child_prof_2010ac_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2010ac_ref_claim_idx ON public.child_prof_2010ac_ref USING btree (claim_id);


--
-- Name: child_prof_2010ac_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2010ac_ref_parent_idx ON public.child_prof_2010ac_ref USING btree (parent_id);


--
-- Name: child_prof_2010ba_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2010ba_ref_claim_idx ON public.child_prof_2010ba_ref USING btree (claim_id);


--
-- Name: child_prof_2010ba_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2010ba_ref_parent_idx ON public.child_prof_2010ba_ref USING btree (parent_id);


--
-- Name: child_prof_2010bb_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2010bb_ref_claim_idx ON public.child_prof_2010bb_ref USING btree (claim_id);


--
-- Name: child_prof_2010bb_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2010bb_ref_parent_idx ON public.child_prof_2010bb_ref USING btree (parent_id);


--
-- Name: child_prof_2300_crc_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2300_crc_claim_idx ON public.child_prof_2300_crc USING btree (claim_id);


--
-- Name: child_prof_2300_crc_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2300_crc_parent_idx ON public.child_prof_2300_crc USING btree (parent_id);


--
-- Name: child_prof_2300_dtp_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2300_dtp_claim_idx ON public.child_prof_2300_dtp USING btree (claim_id);


--
-- Name: child_prof_2300_dtp_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2300_dtp_parent_idx ON public.child_prof_2300_dtp USING btree (parent_id);


--
-- Name: child_prof_2300_hi_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2300_hi_claim_idx ON public.child_prof_2300_hi USING btree (claim_id);


--
-- Name: child_prof_2300_hi_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2300_hi_parent_idx ON public.child_prof_2300_hi USING btree (parent_id);


--
-- Name: child_prof_2300_pwk_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2300_pwk_claim_idx ON public.child_prof_2300_pwk USING btree (claim_id);


--
-- Name: child_prof_2300_pwk_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2300_pwk_parent_idx ON public.child_prof_2300_pwk USING btree (parent_id);


--
-- Name: child_prof_2300_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2300_ref_claim_idx ON public.child_prof_2300_ref USING btree (claim_id);


--
-- Name: child_prof_2300_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2300_ref_parent_idx ON public.child_prof_2300_ref USING btree (parent_id);


--
-- Name: child_prof_2310a_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2310a_ref_claim_idx ON public.child_prof_2310a_ref USING btree (claim_id);


--
-- Name: child_prof_2310a_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2310a_ref_parent_idx ON public.child_prof_2310a_ref USING btree (parent_id);


--
-- Name: child_prof_2310b_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2310b_ref_claim_idx ON public.child_prof_2310b_ref USING btree (claim_id);


--
-- Name: child_prof_2310b_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2310b_ref_parent_idx ON public.child_prof_2310b_ref USING btree (parent_id);


--
-- Name: child_prof_2310c_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2310c_ref_claim_idx ON public.child_prof_2310c_ref USING btree (claim_id);


--
-- Name: child_prof_2310c_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2310c_ref_parent_idx ON public.child_prof_2310c_ref USING btree (parent_id);


--
-- Name: child_prof_2310d_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2310d_ref_claim_idx ON public.child_prof_2310d_ref USING btree (claim_id);


--
-- Name: child_prof_2310d_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2310d_ref_parent_idx ON public.child_prof_2310d_ref USING btree (parent_id);


--
-- Name: child_prof_2320_amt_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2320_amt_claim_idx ON public.child_prof_2320_amt USING btree (claim_id);


--
-- Name: child_prof_2320_amt_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2320_amt_parent_idx ON public.child_prof_2320_amt USING btree (parent_id);


--
-- Name: child_prof_2320_cas_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2320_cas_claim_idx ON public.child_prof_2320_cas USING btree (claim_id);


--
-- Name: child_prof_2320_cas_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2320_cas_parent_idx ON public.child_prof_2320_cas USING btree (parent_id);


--
-- Name: child_prof_2330b_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330b_ref_claim_idx ON public.child_prof_2330b_ref USING btree (claim_id);


--
-- Name: child_prof_2330b_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330b_ref_parent_idx ON public.child_prof_2330b_ref USING btree (parent_id);


--
-- Name: child_prof_2330c_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330c_ref_claim_idx ON public.child_prof_2330c_ref USING btree (claim_id);


--
-- Name: child_prof_2330c_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330c_ref_parent_idx ON public.child_prof_2330c_ref USING btree (parent_id);


--
-- Name: child_prof_2330d_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330d_ref_claim_idx ON public.child_prof_2330d_ref USING btree (claim_id);


--
-- Name: child_prof_2330d_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330d_ref_parent_idx ON public.child_prof_2330d_ref USING btree (parent_id);


--
-- Name: child_prof_2330e_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330e_ref_claim_idx ON public.child_prof_2330e_ref USING btree (claim_id);


--
-- Name: child_prof_2330e_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330e_ref_parent_idx ON public.child_prof_2330e_ref USING btree (parent_id);


--
-- Name: child_prof_2330f_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330f_ref_claim_idx ON public.child_prof_2330f_ref USING btree (claim_id);


--
-- Name: child_prof_2330f_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330f_ref_parent_idx ON public.child_prof_2330f_ref USING btree (parent_id);


--
-- Name: child_prof_2330g_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330g_ref_claim_idx ON public.child_prof_2330g_ref USING btree (claim_id);


--
-- Name: child_prof_2330g_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2330g_ref_parent_idx ON public.child_prof_2330g_ref USING btree (parent_id);


--
-- Name: child_prof_2400_amt_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_amt_claim_idx ON public.child_prof_2400_amt USING btree (claim_id);


--
-- Name: child_prof_2400_amt_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_amt_parent_idx ON public.child_prof_2400_amt USING btree (parent_id);


--
-- Name: child_prof_2400_crc_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_crc_claim_idx ON public.child_prof_2400_crc USING btree (claim_id);


--
-- Name: child_prof_2400_crc_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_crc_parent_idx ON public.child_prof_2400_crc USING btree (parent_id);


--
-- Name: child_prof_2400_dtp_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_dtp_claim_idx ON public.child_prof_2400_dtp USING btree (claim_id);


--
-- Name: child_prof_2400_dtp_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_dtp_parent_idx ON public.child_prof_2400_dtp USING btree (parent_id);


--
-- Name: child_prof_2400_k3_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_k3_claim_idx ON public.child_prof_2400_k3 USING btree (claim_id);


--
-- Name: child_prof_2400_k3_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_k3_parent_idx ON public.child_prof_2400_k3 USING btree (parent_id);


--
-- Name: child_prof_2400_mea_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_mea_claim_idx ON public.child_prof_2400_mea USING btree (claim_id);


--
-- Name: child_prof_2400_mea_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_mea_parent_idx ON public.child_prof_2400_mea USING btree (parent_id);


--
-- Name: child_prof_2400_nte_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_nte_claim_idx ON public.child_prof_2400_nte USING btree (claim_id);


--
-- Name: child_prof_2400_nte_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_nte_parent_idx ON public.child_prof_2400_nte USING btree (parent_id);


--
-- Name: child_prof_2400_pwk_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_pwk_claim_idx ON public.child_prof_2400_pwk USING btree (claim_id);


--
-- Name: child_prof_2400_pwk_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_pwk_parent_idx ON public.child_prof_2400_pwk USING btree (parent_id);


--
-- Name: child_prof_2400_qty_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_qty_claim_idx ON public.child_prof_2400_qty USING btree (claim_id);


--
-- Name: child_prof_2400_qty_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_qty_parent_idx ON public.child_prof_2400_qty USING btree (parent_id);


--
-- Name: child_prof_2400_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_ref_claim_idx ON public.child_prof_2400_ref USING btree (claim_id);


--
-- Name: child_prof_2400_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2400_ref_parent_idx ON public.child_prof_2400_ref USING btree (parent_id);


--
-- Name: child_prof_2410_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2410_ref_claim_idx ON public.child_prof_2410_ref USING btree (claim_id);


--
-- Name: child_prof_2410_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2410_ref_parent_idx ON public.child_prof_2410_ref USING btree (parent_id);


--
-- Name: child_prof_2420a_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420a_ref_claim_idx ON public.child_prof_2420a_ref USING btree (claim_id);


--
-- Name: child_prof_2420a_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420a_ref_parent_idx ON public.child_prof_2420a_ref USING btree (parent_id);


--
-- Name: child_prof_2420b_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420b_ref_claim_idx ON public.child_prof_2420b_ref USING btree (claim_id);


--
-- Name: child_prof_2420b_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420b_ref_parent_idx ON public.child_prof_2420b_ref USING btree (parent_id);


--
-- Name: child_prof_2420c_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420c_ref_claim_idx ON public.child_prof_2420c_ref USING btree (claim_id);


--
-- Name: child_prof_2420c_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420c_ref_parent_idx ON public.child_prof_2420c_ref USING btree (parent_id);


--
-- Name: child_prof_2420d_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420d_ref_claim_idx ON public.child_prof_2420d_ref USING btree (claim_id);


--
-- Name: child_prof_2420d_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420d_ref_parent_idx ON public.child_prof_2420d_ref USING btree (parent_id);


--
-- Name: child_prof_2420e_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420e_ref_claim_idx ON public.child_prof_2420e_ref USING btree (claim_id);


--
-- Name: child_prof_2420e_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420e_ref_parent_idx ON public.child_prof_2420e_ref USING btree (parent_id);


--
-- Name: child_prof_2420f_ref_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420f_ref_claim_idx ON public.child_prof_2420f_ref USING btree (claim_id);


--
-- Name: child_prof_2420f_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2420f_ref_parent_idx ON public.child_prof_2420f_ref USING btree (parent_id);


--
-- Name: child_prof_2430_cas_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2430_cas_claim_idx ON public.child_prof_2430_cas USING btree (claim_id);


--
-- Name: child_prof_2430_cas_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_2430_cas_parent_idx ON public.child_prof_2430_cas USING btree (parent_id);


--
-- Name: child_prof_claim_identifier_amt_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_claim_identifier_amt_claim_idx ON public.child_prof_claim_identifier_amt USING btree (claim_id);


--
-- Name: child_prof_claim_identifier_amt_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_claim_identifier_amt_parent_idx ON public.child_prof_claim_identifier_amt USING btree (parent_id);


--
-- Name: child_prof_claim_identifier_dtp_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_claim_identifier_dtp_claim_idx ON public.child_prof_claim_identifier_dtp USING btree (claim_id);


--
-- Name: child_prof_claim_identifier_dtp_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_prof_claim_identifier_dtp_parent_idx ON public.child_prof_claim_identifier_dtp USING btree (parent_id);


--
-- Name: child_raps_cms_tracking_raps_resp_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_raps_cms_tracking_raps_resp_parent_idx ON public.child_raps_cms_tracking_raps_resp USING btree (parent_id);


--
-- Name: child_raps_feras_error_raps_resp_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_raps_feras_error_raps_resp_parent_idx ON public.child_raps_feras_error_raps_resp USING btree (parent_id);


--
-- Name: child_remit_1000a_per_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_1000a_per_parent_idx ON public.child_remit_1000a_per USING btree (parent_id);


--
-- Name: child_remit_1000a_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_1000a_ref_parent_idx ON public.child_remit_1000a_ref USING btree (parent_id);


--
-- Name: child_remit_2100_amt_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_amt_parent_idx ON public.child_remit_2100_amt USING btree (parent_id);


--
-- Name: child_remit_2100_amt_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_amt_remittance_idx ON public.child_remit_2100_amt USING btree (remittance_id);


--
-- Name: child_remit_2100_cas_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_cas_parent_idx ON public.child_remit_2100_cas USING btree (parent_id);


--
-- Name: child_remit_2100_cas_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_cas_remittance_idx ON public.child_remit_2100_cas USING btree (remittance_id);


--
-- Name: child_remit_2100_dtm_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_dtm_parent_idx ON public.child_remit_2100_dtm USING btree (parent_id);


--
-- Name: child_remit_2100_dtm_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_dtm_remittance_idx ON public.child_remit_2100_dtm USING btree (remittance_id);


--
-- Name: child_remit_2100_nm1_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_nm1_parent_idx ON public.child_remit_2100_nm1 USING btree (parent_id);


--
-- Name: child_remit_2100_nm1_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_nm1_remittance_idx ON public.child_remit_2100_nm1 USING btree (remittance_id);


--
-- Name: child_remit_2100_per_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_per_parent_idx ON public.child_remit_2100_per USING btree (parent_id);


--
-- Name: child_remit_2100_per_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_per_remittance_idx ON public.child_remit_2100_per USING btree (remittance_id);


--
-- Name: child_remit_2100_qty_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_qty_parent_idx ON public.child_remit_2100_qty USING btree (parent_id);


--
-- Name: child_remit_2100_qty_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_qty_remittance_idx ON public.child_remit_2100_qty USING btree (remittance_id);


--
-- Name: child_remit_2100_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_ref_parent_idx ON public.child_remit_2100_ref USING btree (parent_id);


--
-- Name: child_remit_2100_ref_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2100_ref_remittance_idx ON public.child_remit_2100_ref USING btree (remittance_id);


--
-- Name: child_remit_2110_amt_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_amt_parent_idx ON public.child_remit_2110_amt USING btree (parent_id);


--
-- Name: child_remit_2110_amt_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_amt_remittance_idx ON public.child_remit_2110_amt USING btree (remittance_id);


--
-- Name: child_remit_2110_cas_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_cas_parent_idx ON public.child_remit_2110_cas USING btree (parent_id);


--
-- Name: child_remit_2110_cas_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_cas_remittance_idx ON public.child_remit_2110_cas USING btree (remittance_id);


--
-- Name: child_remit_2110_dtm_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_dtm_parent_idx ON public.child_remit_2110_dtm USING btree (parent_id);


--
-- Name: child_remit_2110_dtm_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_dtm_remittance_idx ON public.child_remit_2110_dtm USING btree (remittance_id);


--
-- Name: child_remit_2110_lq_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_lq_parent_idx ON public.child_remit_2110_lq USING btree (parent_id);


--
-- Name: child_remit_2110_lq_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_lq_remittance_idx ON public.child_remit_2110_lq USING btree (remittance_id);


--
-- Name: child_remit_2110_qty_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_qty_parent_idx ON public.child_remit_2110_qty USING btree (parent_id);


--
-- Name: child_remit_2110_qty_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_qty_remittance_idx ON public.child_remit_2110_qty USING btree (remittance_id);


--
-- Name: child_remit_2110_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_ref_parent_idx ON public.child_remit_2110_ref USING btree (parent_id);


--
-- Name: child_remit_2110_ref_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_2110_ref_remittance_idx ON public.child_remit_2110_ref USING btree (remittance_id);


--
-- Name: child_remit_bht_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_bht_ref_parent_idx ON public.child_remit_bht_ref USING btree (parent_id);


--
-- Name: child_remit_identifier_nm1_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_identifier_nm1_parent_idx ON public.child_remit_identifier_nm1 USING btree (parent_id);


--
-- Name: child_remit_identifier_nm1_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_remit_identifier_nm1_remittance_idx ON public.child_remit_identifier_nm1 USING btree (remittance_id);


--
-- Name: child_resp_277_2000b_amt_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_resp_277_2000b_amt_parent_idx ON public.child_resp_277_2000b_amt USING btree (parent_id);


--
-- Name: child_resp_277_2000b_qty_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_resp_277_2000b_qty_parent_idx ON public.child_resp_277_2000b_qty USING btree (parent_id);


--
-- Name: child_resp_277_2000d_dtp_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_resp_277_2000d_dtp_parent_idx ON public.child_resp_277_2000d_dtp USING btree (parent_id);


--
-- Name: child_resp_277_2000d_ref_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_resp_277_2000d_ref_parent_idx ON public.child_resp_277_2000d_ref USING btree (parent_id);


--
-- Name: child_resp_277_2000d_stc_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_resp_277_2000d_stc_parent_idx ON public.child_resp_277_2000d_stc USING btree (parent_id);


--
-- Name: child_resp_277_2220d_stc_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_resp_277_2220d_stc_parent_idx ON public.child_resp_277_2220d_stc USING btree (parent_id);


--
-- Name: child_resp_999_2100_ik4_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_resp_999_2100_ik4_parent_idx ON public.child_resp_999_2100_ik4 USING btree (parent_id);


--
-- Name: child_x12file_resp_file_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_x12file_resp_file_parent_idx ON public.child_x12file_resp_file USING btree (parent_id);


--
-- Name: child_x12file_x12shards_parent_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX child_x12file_x12shards_parent_idx ON public.child_x12file_x12shards USING btree (parent_id);


--
-- Name: claim_error_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX claim_error_claim_id_idx ON public.claim_error USING btree (claim_id);


--
-- Name: claim_error_claim_line_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX claim_error_claim_line_id_idx ON public.claim_error USING btree (claim_line_id);


--
-- Name: claim_error_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX claim_error_respfile_idx ON public.claim_error USING btree (resp_file_id);


--
-- Name: flow_item_flow_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX flow_item_flow_idx ON public.flow_item USING btree (flow_id);


--
-- Name: flow_item_history_item_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX flow_item_history_item_idx ON public.flow_item_history USING btree (flow_item_id);


--
-- Name: flow_item_next_run_time_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX flow_item_next_run_time_idx ON public.flow_item USING btree (next_run_time);


--
-- Name: flow_item_other_obj_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX flow_item_other_obj_idx ON public.flow_item USING btree (other_obj_id);


--
-- Name: hcc_diag_beneficiary_member_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_diag_beneficiary_member_id_idx ON public.hcc_diag USING btree (beneficiary_member_identifier);


--
-- Name: hcc_diag_cpteligible_pos_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_diag_cpteligible_pos_idx ON public.hcc_diag USING btree (is_cpt_eligible, place_of_service) WHERE (is_cpt_eligible IS NULL);


--
-- Name: hcc_diag_filtered_mbi_planid_hcc_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_diag_filtered_mbi_planid_hcc_idx ON public.hcc_diag_filtered USING btree (plan_id, hcc_value, beneficiary_member_identifier);


--
-- Name: hcc_diag_filtered_member_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_diag_filtered_member_id_idx ON public.hcc_diag_filtered USING btree (beneficiary_member_identifier);


--
-- Name: hcc_diag_filtered_paymtyear_modelrun_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_diag_filtered_paymtyear_modelrun_idx ON public.hcc_diag_filtered USING btree (payment_year, model_run);


--
-- Name: hcc_diag_hierarchy_paymtyear_modelrun_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_diag_hierarchy_paymtyear_modelrun_idx ON public.hcc_diag_hierarchy_applied USING btree (payment_year, model_run);


--
-- Name: hcc_diag_hierarchy_planid_mbi_hcc_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_diag_hierarchy_planid_mbi_hcc_idx ON public.hcc_diag_hierarchy_applied USING btree (plan_id, beneficiary_member_identifier, hcc_value);


--
-- Name: hcc_diag_idx_time_tx_type; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_diag_idx_time_tx_type ON public.hcc_diag USING btree (tx_type, last_updated);


--
-- Name: hcc_diag_key_hash_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_diag_key_hash_idx ON public.hcc_diag USING btree (key_hash);


--
-- Name: hcc_diag_source_status_freq_code_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_diag_source_status_freq_code_idx ON public.hcc_diag USING btree (source, encounter_status, claim_frequency_code);


--
-- Name: hcc_drop_model_run_hierarchy_hcc_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX hcc_drop_model_run_hierarchy_hcc_idx ON public.xref_hcc_drop USING btree (model_run, hierarchy_hcc);


--
-- Name: in_process_flows_date_created_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX in_process_flows_date_created_idx ON public.in_process_flows USING btree (date_created);


--
-- Name: inst_1000a_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_1000a_file_idx ON public.inst_1000a USING btree (file_id);


--
-- Name: inst_1000b_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_1000b_file_idx ON public.inst_1000b USING btree (file_id);


--
-- Name: inst_2320_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2320_claim_idx ON public.inst_2320 USING btree (claim_id);


--
-- Name: inst_2330a_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2330a_claim_idx ON public.inst_2330a USING btree (claim_id);


--
-- Name: inst_2330b_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2330b_claim_idx ON public.inst_2330b USING btree (claim_id);


--
-- Name: inst_2330c_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2330c_claim_idx ON public.inst_2330c USING btree (claim_id);


--
-- Name: inst_2330d_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2330d_claim_idx ON public.inst_2330d USING btree (claim_id);


--
-- Name: inst_2330e_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2330e_claim_idx ON public.inst_2330e USING btree (claim_id);


--
-- Name: inst_2330f_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2330f_claim_idx ON public.inst_2330f USING btree (claim_id);


--
-- Name: inst_2330g_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2330g_claim_idx ON public.inst_2330g USING btree (claim_id);


--
-- Name: inst_2330h_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2330h_claim_idx ON public.inst_2330h USING btree (claim_id);


--
-- Name: inst_2330i_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2330i_claim_idx ON public.inst_2330i USING btree (claim_id);


--
-- Name: inst_2400_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2400_claim_idx ON public.inst_2400 USING btree (claim_id);


--
-- Name: inst_2400_line_hash_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2400_line_hash_idx ON public.inst_2400 USING btree (line_hash) WHERE (line_hash IS NOT NULL);


--
-- Name: inst_2400_segment_number_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2400_segment_number_idx ON public.inst_2400 USING btree (segment_number);


--
-- Name: inst_2410_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2410_claim_idx ON public.inst_2410 USING btree (claim_id);


--
-- Name: inst_2420a_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2420a_claim_idx ON public.inst_2420a USING btree (claim_id);


--
-- Name: inst_2420b_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2420b_claim_idx ON public.inst_2420b USING btree (claim_id);


--
-- Name: inst_2420c_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2420c_claim_idx ON public.inst_2420c USING btree (claim_id);


--
-- Name: inst_2420d_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2420d_claim_idx ON public.inst_2420d USING btree (claim_id);


--
-- Name: inst_2430_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2430_claim_idx ON public.inst_2430 USING btree (claim_id);


--
-- Name: inst_2440_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_2440_claim_idx ON public.inst_2440 USING btree (claim_id);


--
-- Name: inst_bht_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_bht_file_idx ON public.inst_bht USING btree (file_id);


--
-- Name: inst_claim_data_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_claim_data_claim_idx ON public.inst_claim_data USING btree (claim_id);


--
-- Name: inst_claim_identifier_cmsicn_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_claim_identifier_cmsicn_idx ON public.inst_claim_identifier USING btree (cmsicn) WHERE (source = 'ENCOUNTER'::text);


--
-- Name: inst_claim_identifier_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_claim_identifier_file_idx ON public.inst_claim_identifier USING btree (file_id);


--
-- Name: inst_claim_identifier_gcn_tscn; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_claim_identifier_gcn_tscn ON public.inst_claim_identifier USING btree (group_control_number, transaction_set_control_number);


--
-- Name: inst_claim_identifier_hplansubmitter_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_claim_identifier_hplansubmitter_idx ON public.inst_claim_identifier USING btree (h_plan_submitter_id);


--
-- Name: inst_claim_identifier_patient_control_number_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_claim_identifier_patient_control_number_idx ON public.inst_claim_identifier USING btree (patient_control_number);


--
-- Name: inst_claim_identifier_segment_number_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_claim_identifier_segment_number_idx ON public.inst_claim_identifier USING btree (segment_number);


--
-- Name: inst_claim_identifier_source_status_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_claim_identifier_source_status_idx ON public.inst_claim_identifier USING btree (source, encounter_status);


--
-- Name: inst_claim_line_data_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_claim_line_data_claim_idx ON public.inst_claim_line_data USING btree (claim_id);


--
-- Name: inst_header_trailer_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_header_trailer_file_idx ON public.inst_header_trailer USING btree (file_id);


--
-- Name: inst_se_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_se_file_idx ON public.inst_se USING btree (file_id);


--
-- Name: inst_st_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inst_st_file_idx ON public.inst_st USING btree (file_id);


--
-- Name: inter_process_queue_date_created_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX inter_process_queue_date_created_idx ON public.inter_process_queue USING btree (date_created, locked_at) WHERE (locked_at IS NULL);


--
-- Name: linked_cr_batch_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX linked_cr_batch_file_idx ON public.linked_cr_batch USING btree (batch_file_id);


--
-- Name: member_raf_beneficiary_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX member_raf_beneficiary_id_idx ON public.member_raf USING btree (beneficiary_id);


--
-- Name: prof_1000a_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_1000a_file_idx ON public.prof_1000a USING btree (file_id);


--
-- Name: prof_1000b_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_1000b_file_idx ON public.prof_1000b USING btree (file_id);


--
-- Name: prof_2310a_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2310a_claim_idx ON public.prof_2310a USING btree (claim_id);


--
-- Name: prof_2320_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2320_claim_idx ON public.prof_2320 USING btree (claim_id);


--
-- Name: prof_2330a_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2330a_claim_idx ON public.prof_2330a USING btree (claim_id);


--
-- Name: prof_2330b_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2330b_claim_idx ON public.prof_2330b USING btree (claim_id);


--
-- Name: prof_2330c_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2330c_claim_idx ON public.prof_2330c USING btree (claim_id);


--
-- Name: prof_2330d_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2330d_claim_idx ON public.prof_2330d USING btree (claim_id);


--
-- Name: prof_2330e_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2330e_claim_idx ON public.prof_2330e USING btree (claim_id);


--
-- Name: prof_2330f_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2330f_claim_idx ON public.prof_2330f USING btree (claim_id);


--
-- Name: prof_2330g_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2330g_claim_idx ON public.prof_2330g USING btree (claim_id);


--
-- Name: prof_2400_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2400_claim_idx ON public.prof_2400 USING btree (claim_id);


--
-- Name: prof_2400_line_hash_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2400_line_hash_idx ON public.prof_2400 USING btree (line_hash) WHERE (line_hash IS NOT NULL);


--
-- Name: prof_2400_segment_number_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2400_segment_number_idx ON public.prof_2400 USING btree (segment_number);


--
-- Name: prof_2410_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2410_claim_idx ON public.prof_2410 USING btree (claim_id);


--
-- Name: prof_2420a_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2420a_claim_idx ON public.prof_2420a USING btree (claim_id);


--
-- Name: prof_2420b_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2420b_claim_idx ON public.prof_2420b USING btree (claim_id);


--
-- Name: prof_2420c_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2420c_claim_idx ON public.prof_2420c USING btree (claim_id);


--
-- Name: prof_2420d_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2420d_claim_idx ON public.prof_2420d USING btree (claim_id);


--
-- Name: prof_2420e_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2420e_claim_idx ON public.prof_2420e USING btree (claim_id);


--
-- Name: prof_2420f_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2420f_claim_idx ON public.prof_2420f USING btree (claim_id);


--
-- Name: prof_2420g_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2420g_claim_idx ON public.prof_2420g USING btree (claim_id);


--
-- Name: prof_2420h_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2420h_claim_idx ON public.prof_2420h USING btree (claim_id);


--
-- Name: prof_2430_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2430_claim_idx ON public.prof_2430 USING btree (claim_id);


--
-- Name: prof_2440_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_2440_claim_idx ON public.prof_2440 USING btree (claim_id);


--
-- Name: prof_bht_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_bht_file_idx ON public.prof_bht USING btree (file_id);


--
-- Name: prof_claim_data_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_claim_data_claim_idx ON public.prof_claim_data USING btree (claim_id);


--
-- Name: prof_claim_identifier_cmsicn_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_claim_identifier_cmsicn_idx ON public.prof_claim_identifier USING btree (cmsicn) WHERE (source = 'ENCOUNTER'::text);


--
-- Name: prof_claim_identifier_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_claim_identifier_file_idx ON public.prof_claim_identifier USING btree (file_id);


--
-- Name: prof_claim_identifier_gcn_tscn; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_claim_identifier_gcn_tscn ON public.prof_claim_identifier USING btree (group_control_number, transaction_set_control_number);


--
-- Name: prof_claim_identifier_hplansubmitter_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_claim_identifier_hplansubmitter_idx ON public.prof_claim_identifier USING btree (h_plan_submitter_id);


--
-- Name: prof_claim_identifier_patient_control_number_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_claim_identifier_patient_control_number_idx ON public.prof_claim_identifier USING btree (patient_control_number);


--
-- Name: prof_claim_identifier_segment_number_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_claim_identifier_segment_number_idx ON public.prof_claim_identifier USING btree (segment_number);


--
-- Name: prof_claim_identifier_source_status_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_claim_identifier_source_status_idx ON public.prof_claim_identifier USING btree (source, encounter_status);


--
-- Name: prof_claim_line_data_claim_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_claim_line_data_claim_idx ON public.prof_claim_line_data USING btree (claim_id);


--
-- Name: prof_header_trailer_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_header_trailer_file_idx ON public.prof_header_trailer USING btree (file_id);


--
-- Name: prof_se_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_se_file_idx ON public.prof_se USING btree (file_id);


--
-- Name: prof_st_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX prof_st_file_idx ON public.prof_st USING btree (file_id);


--
-- Name: provider_837_remit_mapping_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX provider_837_remit_mapping_claim_id_idx ON public.provider_837_remit_mapping USING btree (ref_provider_claim_id);


--
-- Name: provider_837_remit_mapping_remit_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX provider_837_remit_mapping_remit_id_idx ON public.provider_837_remit_mapping USING btree (ref_remit_id);


--
-- Name: raps_cluster_hicn_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX raps_cluster_hicn_idx ON public.raps_cluster USING btree (hicn);


--
-- Name: raps_cluster_history_hicn_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX raps_cluster_history_hicn_idx ON public.raps_cluster_history USING btree (hicn);


--
-- Name: raps_cluster_history_key_hash_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX raps_cluster_history_key_hash_idx ON public.raps_cluster_history USING btree (key_hash);


--
-- Name: raps_cluster_history_status_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX raps_cluster_history_status_idx ON public.raps_cluster_history USING btree (cluster_status) WHERE (cluster_status = ANY (ARRAY['NEW'::text, 'CORRECTED'::text]));


--
-- Name: raps_cluster_key_hash_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX raps_cluster_key_hash_idx ON public.raps_cluster USING btree (key_hash);


--
-- Name: remit_1000a_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_1000a_file_idx ON public.remit_1000a USING btree (file_id);


--
-- Name: remit_1000b_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_1000b_file_idx ON public.remit_1000b USING btree (file_id);


--
-- Name: remit_2000_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_2000_file_idx ON public.remit_2000 USING btree (file_id);


--
-- Name: remit_2000_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_2000_remittance_idx ON public.remit_2000 USING btree (remittance_id);


--
-- Name: remit_2110_remittance_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_2110_remittance_idx ON public.remit_2110 USING btree (remittance_id);


--
-- Name: remit_bht_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_bht_file_idx ON public.remit_bht USING btree (file_id);


--
-- Name: remit_footer_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_footer_file_idx ON public.remit_footer USING btree (file_id);


--
-- Name: remit_header_trailer_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_header_trailer_file_idx ON public.remit_header_trailer USING btree (file_id);


--
-- Name: remit_identifier_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_identifier_file_idx ON public.remit_identifier USING btree (file_id);


--
-- Name: remit_identifier_patient_control_number_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_identifier_patient_control_number_idx ON public.remit_identifier USING btree (patient_control_number);


--
-- Name: remit_st_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX remit_st_file_idx ON public.remit_st USING btree (file_id);


--
-- Name: resp_277_2000b_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_277_2000b_respfile_idx ON public.resp_277_2000b USING btree (resp_file_id);


--
-- Name: resp_277_2000c_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_277_2000c_respfile_idx ON public.resp_277_2000c USING btree (resp_file_id);


--
-- Name: resp_277_2000c_segment_number_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_277_2000c_segment_number_idx ON public.resp_277_2000c USING btree (segment_number);


--
-- Name: resp_277_2000d_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_277_2000d_respfile_idx ON public.resp_277_2000d USING btree (resp_file_id);


--
-- Name: resp_277_2000d_segment_number_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_277_2000d_segment_number_idx ON public.resp_277_2000d USING btree (segment_number);


--
-- Name: resp_277_2220d_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_277_2220d_respfile_idx ON public.resp_277_2220d USING btree (resp_file_id);


--
-- Name: resp_277_2220d_segment_number_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_277_2220d_segment_number_idx ON public.resp_277_2220d USING btree (segment_number);


--
-- Name: resp_277_bht_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_277_bht_respfile_idx ON public.resp_277_bht USING btree (resp_file_id);


--
-- Name: resp_277_header_trailer_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_277_header_trailer_respfile_idx ON public.resp_277_header_trailer USING btree (resp_file_id);


--
-- Name: resp_277_st_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_277_st_respfile_idx ON public.resp_277_st USING btree (resp_file_id);


--
-- Name: resp_999_2000_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_999_2000_respfile_idx ON public.resp_999_2000 USING btree (resp_file_id);


--
-- Name: resp_999_2100_error_segment_position_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_999_2100_error_segment_position_idx ON public.resp_999_2100 USING btree (error_segment_position);


--
-- Name: resp_999_2100_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_999_2100_respfile_idx ON public.resp_999_2100 USING btree (resp_file_id);


--
-- Name: resp_999_2110_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_999_2110_respfile_idx ON public.resp_999_2110 USING btree (resp_file_id);


--
-- Name: resp_999_bht_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_999_bht_respfile_idx ON public.resp_999_bht USING btree (resp_file_id);


--
-- Name: resp_999_header_trailer_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_999_header_trailer_respfile_idx ON public.resp_999_header_trailer USING btree (resp_file_id);


--
-- Name: resp_mao_1_enc_icn_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_mao_1_enc_icn_idx ON public.resp_mao_1 USING btree (encounter_icn);


--
-- Name: resp_mao_1_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_mao_1_respfile_idx ON public.resp_mao_1 USING btree (resp_file_id);


--
-- Name: resp_mao_2_control_number_status_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_mao_2_control_number_status_idx ON public.resp_mao_2 USING btree (interchange_control_number, encounter_status);


--
-- Name: resp_mao_2_plan_icn_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_mao_2_plan_icn_idx ON public.resp_mao_2 USING btree (plan_icn);


--
-- Name: resp_mao_2_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_mao_2_respfile_idx ON public.resp_mao_2 USING btree (resp_file_id);


--
-- Name: resp_mao_4_enc_icn_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_mao_4_enc_icn_idx ON public.resp_mao_4 USING btree (encounter_icn);


--
-- Name: resp_mao_4_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_mao_4_respfile_idx ON public.resp_mao_4 USING btree (resp_file_id);


--
-- Name: resp_ta1_data_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_ta1_data_respfile_idx ON public.resp_ta1_data USING btree (resp_file_id);


--
-- Name: resp_ta1_header_trailer_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX resp_ta1_header_trailer_respfile_idx ON public.resp_ta1_header_trailer USING btree (resp_file_id);


--
-- Name: segment_data_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_claim_id_idx ON ONLY public.segment_data USING btree (claim_id);


--
-- Name: segment_data_00_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_00_claim_id_idx ON public.segment_data_00 USING btree (claim_id);


--
-- Name: segment_data_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_file_idx ON ONLY public.segment_data USING btree (file_id);


--
-- Name: segment_data_00_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_00_file_id_idx ON public.segment_data_00 USING btree (file_id);


--
-- Name: segment_data_01_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_01_claim_id_idx ON public.segment_data_01 USING btree (claim_id);


--
-- Name: segment_data_01_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_01_file_id_idx ON public.segment_data_01 USING btree (file_id);


--
-- Name: segment_data_02_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_02_claim_id_idx ON public.segment_data_02 USING btree (claim_id);


--
-- Name: segment_data_02_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_02_file_id_idx ON public.segment_data_02 USING btree (file_id);


--
-- Name: segment_data_03_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_03_claim_id_idx ON public.segment_data_03 USING btree (claim_id);


--
-- Name: segment_data_03_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_03_file_id_idx ON public.segment_data_03 USING btree (file_id);


--
-- Name: segment_data_04_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_04_claim_id_idx ON public.segment_data_04 USING btree (claim_id);


--
-- Name: segment_data_04_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_04_file_id_idx ON public.segment_data_04 USING btree (file_id);


--
-- Name: segment_data_05_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_05_claim_id_idx ON public.segment_data_05 USING btree (claim_id);


--
-- Name: segment_data_05_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_05_file_id_idx ON public.segment_data_05 USING btree (file_id);


--
-- Name: segment_data_06_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_06_claim_id_idx ON public.segment_data_06 USING btree (claim_id);


--
-- Name: segment_data_06_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_06_file_id_idx ON public.segment_data_06 USING btree (file_id);


--
-- Name: segment_data_07_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_07_claim_id_idx ON public.segment_data_07 USING btree (claim_id);


--
-- Name: segment_data_07_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_07_file_id_idx ON public.segment_data_07 USING btree (file_id);


--
-- Name: segment_data_08_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_08_claim_id_idx ON public.segment_data_08 USING btree (claim_id);


--
-- Name: segment_data_08_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_08_file_id_idx ON public.segment_data_08 USING btree (file_id);


--
-- Name: segment_data_09_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_09_claim_id_idx ON public.segment_data_09 USING btree (claim_id);


--
-- Name: segment_data_09_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_09_file_id_idx ON public.segment_data_09 USING btree (file_id);


--
-- Name: segment_data_10_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_10_claim_id_idx ON public.segment_data_10 USING btree (claim_id);


--
-- Name: segment_data_10_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_10_file_id_idx ON public.segment_data_10 USING btree (file_id);


--
-- Name: segment_data_11_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_11_claim_id_idx ON public.segment_data_11 USING btree (claim_id);


--
-- Name: segment_data_11_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_11_file_id_idx ON public.segment_data_11 USING btree (file_id);


--
-- Name: segment_data_12_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_12_claim_id_idx ON public.segment_data_12 USING btree (claim_id);


--
-- Name: segment_data_12_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_12_file_id_idx ON public.segment_data_12 USING btree (file_id);


--
-- Name: segment_data_13_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_13_claim_id_idx ON public.segment_data_13 USING btree (claim_id);


--
-- Name: segment_data_13_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_13_file_id_idx ON public.segment_data_13 USING btree (file_id);


--
-- Name: segment_data_14_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_14_claim_id_idx ON public.segment_data_14 USING btree (claim_id);


--
-- Name: segment_data_14_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_14_file_id_idx ON public.segment_data_14 USING btree (file_id);


--
-- Name: segment_data_15_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_15_claim_id_idx ON public.segment_data_15 USING btree (claim_id);


--
-- Name: segment_data_15_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_15_file_id_idx ON public.segment_data_15 USING btree (file_id);


--
-- Name: segment_data_16_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_16_claim_id_idx ON public.segment_data_16 USING btree (claim_id);


--
-- Name: segment_data_16_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_16_file_id_idx ON public.segment_data_16 USING btree (file_id);


--
-- Name: segment_data_17_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_17_claim_id_idx ON public.segment_data_17 USING btree (claim_id);


--
-- Name: segment_data_17_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_17_file_id_idx ON public.segment_data_17 USING btree (file_id);


--
-- Name: segment_data_18_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_18_claim_id_idx ON public.segment_data_18 USING btree (claim_id);


--
-- Name: segment_data_18_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_18_file_id_idx ON public.segment_data_18 USING btree (file_id);


--
-- Name: segment_data_19_claim_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_19_claim_id_idx ON public.segment_data_19 USING btree (claim_id);


--
-- Name: segment_data_19_file_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX segment_data_19_file_id_idx ON public.segment_data_19 USING btree (file_id);


--
-- Name: x12_duplicate_file_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX x12_duplicate_file_file_idx ON public.x12_duplicate_file USING btree (file_id);


--
-- Name: x12_resp_duplicate_file_respfile_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX x12_resp_duplicate_file_respfile_idx ON public.x12_resp_duplicate_file USING btree (resp_file_id);


--
-- Name: x12file_struct_validation_file_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX x12file_struct_validation_file_idx ON public.x12file_struct_validation USING btree (file_id);


--
-- Name: xref_claim_error_277_comp_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_claim_error_277_comp_idx ON public.xref_claim_error_277 USING btree (claim_status_category_code, claim_status_code1, claim_status_code2);


--
-- Name: xref_claim_npi_mapping_claim_ref_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_claim_npi_mapping_claim_ref_idx ON public.xref_claim_npi_mapping USING btree (claim_ref);


--
-- Name: xref_dme_pos_procedure_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_dme_pos_procedure_idx ON public.xref_dme_pos USING btree (dme_pos);


--
-- Name: xref_hcpcs_cpt_cpt_code_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_hcpcs_cpt_cpt_code_idx ON public.xref_hcpcs_cpt USING btree (cpt_code);


--
-- Name: xref_hcpcs_cpt_payyear_cptcode_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_hcpcs_cpt_payyear_cptcode_idx ON public.xref_hcpcs_cpt USING btree (payment_year, cpt_code);


--
-- Name: xref_hicn_mbi_hicn_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_hicn_mbi_hicn_idx ON public.xref_hicn_mbi USING btree (hicn);


--
-- Name: xref_hicn_mbi_last_name_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_hicn_mbi_last_name_idx ON public.xref_hicn_mbi USING btree (upper(subscriber_last_name));


--
-- Name: xref_hicn_mbi_mbi_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_hicn_mbi_mbi_idx ON public.xref_hicn_mbi USING btree (mbi);


--
-- Name: xref_hicn_mbi_plan_and_member_id_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_hicn_mbi_plan_and_member_id_idx ON public.xref_hicn_mbi USING btree (h_plan_id, plan_member_id);


--
-- Name: xref_hicn_mbi_plan_number_member_mbi_hicn_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_hicn_mbi_plan_number_member_mbi_hicn_idx ON public.xref_hicn_mbi USING btree (plan_number, plan_member_id, mbi, hicn);


--
-- Name: xref_hicn_mbi_enrollment_year_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_hicn_mbi_enrollment_year_idx ON public.xref_hicn_mbi USING btree (enrollment_year);


--
-- Name: xref_hicn_mbi_disenrollment_year_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_hicn_mbi_disenrollment_year_idx ON public.xref_hicn_mbi USING btree (disenrollment_year);


--
-- Name: xref_icd_hcc_icd_category_year_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_icd_hcc_icd_category_year_idx ON public.xref_icd_hcc USING btree (icd_code, model_category, payment_year);


--
-- Name: xref_icd_hcc_icdcode_modelcategory_hccmodel_idx; Type: INDEX; Schema: public; Owner: ras
--

CREATE INDEX xref_icd_hcc_icdcode_modelcategory_hccmodel_idx ON public.xref_icd_hcc USING btree (icd_code, model_category, hcc_model);


--
-- Name: segment_data_00_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_00_claim_id_idx;


--
-- Name: segment_data_00_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_00_file_id_idx;


--
-- Name: segment_data_01_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_01_claim_id_idx;


--
-- Name: segment_data_01_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_01_file_id_idx;


--
-- Name: segment_data_02_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_02_claim_id_idx;


--
-- Name: segment_data_02_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_02_file_id_idx;


--
-- Name: segment_data_03_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_03_claim_id_idx;


--
-- Name: segment_data_03_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_03_file_id_idx;


--
-- Name: segment_data_04_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_04_claim_id_idx;


--
-- Name: segment_data_04_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_04_file_id_idx;


--
-- Name: segment_data_05_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_05_claim_id_idx;


--
-- Name: segment_data_05_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_05_file_id_idx;


--
-- Name: segment_data_06_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_06_claim_id_idx;


--
-- Name: segment_data_06_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_06_file_id_idx;


--
-- Name: segment_data_07_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_07_claim_id_idx;


--
-- Name: segment_data_07_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_07_file_id_idx;


--
-- Name: segment_data_08_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_08_claim_id_idx;


--
-- Name: segment_data_08_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_08_file_id_idx;


--
-- Name: segment_data_09_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_09_claim_id_idx;


--
-- Name: segment_data_09_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_09_file_id_idx;


--
-- Name: segment_data_10_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_10_claim_id_idx;


--
-- Name: segment_data_10_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_10_file_id_idx;


--
-- Name: segment_data_11_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_11_claim_id_idx;


--
-- Name: segment_data_11_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_11_file_id_idx;


--
-- Name: segment_data_12_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_12_claim_id_idx;


--
-- Name: segment_data_12_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_12_file_id_idx;


--
-- Name: segment_data_13_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_13_claim_id_idx;


--
-- Name: segment_data_13_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_13_file_id_idx;


--
-- Name: segment_data_14_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_14_claim_id_idx;


--
-- Name: segment_data_14_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_14_file_id_idx;


--
-- Name: segment_data_15_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_15_claim_id_idx;


--
-- Name: segment_data_15_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_15_file_id_idx;


--
-- Name: segment_data_16_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_16_claim_id_idx;


--
-- Name: segment_data_16_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_16_file_id_idx;


--
-- Name: segment_data_17_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_17_claim_id_idx;


--
-- Name: segment_data_17_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_17_file_id_idx;


--
-- Name: segment_data_18_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_18_claim_id_idx;


--
-- Name: segment_data_18_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_18_file_id_idx;


--
-- Name: segment_data_19_claim_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_claim_id_idx ATTACH PARTITION public.segment_data_19_claim_id_idx;


--
-- Name: segment_data_19_file_id_idx; Type: INDEX ATTACH; Schema: public; Owner: ras
--

ALTER INDEX public.segment_data_file_idx ATTACH PARTITION public.segment_data_19_file_id_idx;


--
-- Name: flow_item flow_item_insert_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER flow_item_insert_trig AFTER INSERT ON public.flow_item FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.flow_item_history_insert();


--
-- Name: flow_item flow_item_update_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER flow_item_update_trig AFTER UPDATE OF flow_status, item_type, step_name, step_status ON public.flow_item FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.flow_item_history_insert();


--
-- Name: inst_claim_identifier inst_insert_delete_revision_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER inst_insert_delete_revision_trig AFTER INSERT OR DELETE ON public.inst_claim_identifier FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.inst_update_revision();


--
-- Name: inst_2010ba inst_update_duplicate_line_2010ba_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER inst_update_duplicate_line_2010ba_trig AFTER UPDATE OF beneficiary_member_identifier ON public.inst_2010ba FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.inst_update_duplicate_claim_line_other();


--
-- Name: child_inst_2300_dtp inst_update_duplicate_line_2300_dtp_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER inst_update_duplicate_line_2300_dtp_trig AFTER UPDATE OF dtp_03, date_time_qualifier ON public.child_inst_2300_dtp FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.inst_update_duplicate_claim_line_other();


--
-- Name: child_inst_2320_amt inst_update_duplicate_line_amt_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER inst_update_duplicate_line_amt_trig AFTER UPDATE OF amt_2 ON public.child_inst_2320_amt FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.inst_update_duplicate_claim_line_other();


--
-- Name: inst_2400 inst_update_duplicate_line_flag_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER inst_update_duplicate_line_flag_trig AFTER UPDATE OF line_hash ON public.inst_2400 FOR EACH ROW WHEN ((pg_trigger_depth() <= 1)) EXECUTE FUNCTION public.inst_update_duplicate_line_flag();


--
-- Name: inst_2300 inst_update_duplicate_line_i2300_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER inst_update_duplicate_line_i2300_trig AFTER UPDATE OF facility_type_code ON public.inst_2300 FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.inst_update_duplicate_claim_line_other();


--
-- Name: inst_2400 inst_update_duplicate_line_i2400_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER inst_update_duplicate_line_i2400_trig AFTER UPDATE OF service_line_revenue_code, procedure_code, procedure_modifier1, procedure_modifier2, procedure_modifier3, procedure_modifier4, line_item_charge_amount ON public.inst_2400 FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.inst_update_duplicate_claim_line();


--
-- Name: inst_2010aa inst_update_duplicate_line_inst_2010aa_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER inst_update_duplicate_line_inst_2010aa_trig AFTER UPDATE OF billing_provider_npi_identifier ON public.inst_2010aa FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.inst_update_duplicate_claim_line_other();


--
-- Name: inst_claim_identifier inst_update_revision_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER inst_update_revision_trig AFTER UPDATE OF plan_id, patient_control_number, encounter_or_chart_review, submission_date, last_updated, id, source, encounter_status, encounter_status_type ON public.inst_claim_identifier FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.inst_update_revision();


--
-- Name: prof_claim_identifier prof_insert_delete_revision_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER prof_insert_delete_revision_trig AFTER INSERT OR DELETE ON public.prof_claim_identifier FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.prof_update_revision();


--
-- Name: prof_2010aa prof_update_duplicate_line_2010aa_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER prof_update_duplicate_line_2010aa_trig AFTER UPDATE OF billing_provider_npi_identifier ON public.prof_2010aa FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.prof_update_duplicate_claim_line_other();


--
-- Name: prof_2010ba prof_update_duplicate_line_2010ba_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER prof_update_duplicate_line_2010ba_trig AFTER UPDATE OF beneficiary_member_identifier ON public.prof_2010ba FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.prof_update_duplicate_claim_line_other();


--
-- Name: prof_2310b prof_update_duplicate_line_2310b_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER prof_update_duplicate_line_2310b_trig AFTER UPDATE OF rendering_provider_identifier ON public.prof_2310b FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.prof_update_duplicate_claim_line_other();


--
-- Name: child_prof_2400_dtp prof_update_duplicate_line_2400_dtp_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER prof_update_duplicate_line_2400_dtp_trig AFTER UPDATE OF begin_date_of_service, end_date_of_service, date_time_qualifier ON public.child_prof_2400_dtp FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.prof_update_duplicate_claim_line();


--
-- Name: child_prof_2320_amt prof_update_duplicate_line_amt_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER prof_update_duplicate_line_amt_trig AFTER UPDATE OF amt_2 ON public.child_prof_2320_amt FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.prof_update_duplicate_claim_line_other();


--
-- Name: prof_2400 prof_update_duplicate_line_flag_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER prof_update_duplicate_line_flag_trig AFTER UPDATE OF line_hash ON public.prof_2400 FOR EACH ROW WHEN ((pg_trigger_depth() <= 1)) EXECUTE FUNCTION public.prof_update_duplicate_line_flag();


--
-- Name: prof_2300 prof_update_duplicate_line_p2300_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER prof_update_duplicate_line_p2300_trig AFTER UPDATE OF place_of_service_code ON public.prof_2300 FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.prof_update_duplicate_claim_line_other();


--
-- Name: prof_2400 prof_update_duplicate_line_p2400_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER prof_update_duplicate_line_p2400_trig AFTER UPDATE OF procedure_code, procedure_modifier1, procedure_modifier2, procedure_modifier3, procedure_modifier4, line_item_charge_amount ON public.prof_2400 FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.prof_update_duplicate_claim_line();


--
-- Name: prof_claim_identifier prof_update_revision_trig; Type: TRIGGER; Schema: public; Owner: ras
--

CREATE TRIGGER prof_update_revision_trig AFTER UPDATE OF plan_id, patient_control_number, encounter_or_chart_review, submission_date, last_updated, id, source, encounter_status, encounter_status_type ON public.prof_claim_identifier FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION public.prof_update_revision();


--
-- Name: batch_data batch_data_file_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.batch_data
    ADD CONSTRAINT batch_data_file_id_fk FOREIGN KEY (batch_file_id) REFERENCES public.batch_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: batch_file batchfilehealthplanfk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.batch_file
    ADD CONSTRAINT batchfilehealthplanfk FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2420a_ref fk17rmd7uc4jfaonjedjlcrwdd7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420a_ref
    ADD CONSTRAINT fk17rmd7uc4jfaonjedjlcrwdd7 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2010ac fk1a2wlx7g3a5q0g1hrfyrc1mvp; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ac
    ADD CONSTRAINT fk1a2wlx7g3a5q0g1hrfyrc1mvp FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2010aa fk1cjep5nmt3lawfaogcc77vlk0; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010aa
    ADD CONSTRAINT fk1cjep5nmt3lawfaogcc77vlk0 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310b_ref fk1dbc763poce6bxferfrahe20k; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310b_ref
    ADD CONSTRAINT fk1dbc763poce6bxferfrahe20k FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_resp_277_2000b_amt fk1f38nj17nn83dsywc39k4flxi; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2000b_amt
    ADD CONSTRAINT fk1f38nj17nn83dsywc39k4flxi FOREIGN KEY (parent_id) REFERENCES public.resp_277_2000b(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_crc fk1gembqc6y8hj4hjao07tbt9gn; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_crc
    ADD CONSTRAINT fk1gembqc6y8hj4hjao07tbt9gn FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2320_cas fk1ghya6tcf3h5u4ldcb658mvhw; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2320_cas
    ADD CONSTRAINT fk1ghya6tcf3h5u4ldcb658mvhw FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_nte fk1k59wjxe26prvn54dw4awouu2; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_nte
    ADD CONSTRAINT fk1k59wjxe26prvn54dw4awouu2 FOREIGN KEY (parent_id) REFERENCES public.prof_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2330a fk1m20ki0y3wiuo6dno2e22r9io; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330a
    ADD CONSTRAINT fk1m20ki0y3wiuo6dno2e22r9io FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_claim_identifier_dtp fk1nv4mhtww2f7q27q1tdgigtb6; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_claim_identifier_dtp
    ADD CONSTRAINT fk1nv4mhtww2f7q27q1tdgigtb6 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_claim_identifier fk1vj2epoa2iwjqat1ehld38wrp; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_claim_identifier
    ADD CONSTRAINT fk1vj2epoa2iwjqat1ehld38wrp FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2310c fk22uu0s47nsqpixm87fxp4ehyl; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310c
    ADD CONSTRAINT fk22uu0s47nsqpixm87fxp4ehyl FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: raps_cms_tracking fk24o1c2n6i37oyixob8g12dmoc; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_cms_tracking
    ADD CONSTRAINT fk24o1c2n6i37oyixob8g12dmoc FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_raps_cms_tracking_raps_resp fk27jk3l5ecv26i6jdl1lputd1s; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_raps_cms_tracking_raps_resp
    ADD CONSTRAINT fk27jk3l5ecv26i6jdl1lputd1s FOREIGN KEY (parent_id) REFERENCES public.raps_cms_tracking(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2000b fk28egqidukljuy5rr0do6asbae; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2000b
    ADD CONSTRAINT fk28egqidukljuy5rr0do6asbae FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420e_ref fk2dakmx5eqhmfu6ec2bqnwur07; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420e_ref
    ADD CONSTRAINT fk2dakmx5eqhmfu6ec2bqnwur07 FOREIGN KEY (parent_id) REFERENCES public.prof_2420e(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2320 fk2r3squ68d1hrd2qovwt98myi7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2320
    ADD CONSTRAINT fk2r3squ68d1hrd2qovwt98myi7 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2010ba fk2r84s2yhc1ggqdre91m891nw9; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ba
    ADD CONSTRAINT fk2r84s2yhc1ggqdre91m891nw9 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310e_ref fk2ruk1ikijk3x1tt51rui118vr; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310e_ref
    ADD CONSTRAINT fk2ruk1ikijk3x1tt51rui118vr FOREIGN KEY (parent_id) REFERENCES public.inst_2310e(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_header_trailer fk2yr3mtku4qkpf43hlbyp5ygyd; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_header_trailer
    ADD CONSTRAINT fk2yr3mtku4qkpf43hlbyp5ygyd FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2010aa fk320pq4t768n0q6kw3qib9708f; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010aa
    ADD CONSTRAINT fk320pq4t768n0q6kw3qib9708f FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2420d fk33peb3a5rkg5xbckch8spyqq6; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420d
    ADD CONSTRAINT fk33peb3a5rkg5xbckch8spyqq6 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2010ac_ref fk33v660xil60b1t9a11oqfxp3p; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010ac_ref
    ADD CONSTRAINT fk33v660xil60b1t9a11oqfxp3p FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cms_submitter_info fk3641yrvnm8k6qlvir503i09nv; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.cms_submitter_info
    ADD CONSTRAINT fk3641yrvnm8k6qlvir503i09nv FOREIGN KEY (a_id) REFERENCES public.customer_account(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2010aa_per fk38l9hf34uje91kc6h6rbqe1by; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010aa_per
    ADD CONSTRAINT fk38l9hf34uje91kc6h6rbqe1by FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_claim_identifier fk38njesaryvhj7e3p4thqkq7pb; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_claim_identifier
    ADD CONSTRAINT fk38njesaryvhj7e3p4thqkq7pb FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2320_amt fk3dnf5eweckaetmv5cdimswetp; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2320_amt
    ADD CONSTRAINT fk3dnf5eweckaetmv5cdimswetp FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2010ac fk3rppgil34edn7x60uxfj9wnpr; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ac
    ADD CONSTRAINT fk3rppgil34edn7x60uxfj9wnpr FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310a_ref fk3yggm4e1k8v7ywxs0sio9ldac; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310a_ref
    ADD CONSTRAINT fk3yggm4e1k8v7ywxs0sio9ldac FOREIGN KEY (parent_id) REFERENCES public.inst_2310a(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_1000a_ref fk41dldhcw6a1d7we45v094dcfb; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_1000a_ref
    ADD CONSTRAINT fk41dldhcw6a1d7we45v094dcfb FOREIGN KEY (parent_id) REFERENCES public.remit_1000a(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: raps_cluster_history fk41fjev816o2pfjmmjq4rkdp81; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_cluster_history
    ADD CONSTRAINT fk41fjev816o2pfjmmjq4rkdp81 FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330f_ref fk420vy09ug8jvjcql2mo1csxa9; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330f_ref
    ADD CONSTRAINT fk420vy09ug8jvjcql2mo1csxa9 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: h_plan_config fk47rguupsfyxjafe5jfrpicjaf; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.h_plan_config
    ADD CONSTRAINT fk47rguupsfyxjafe5jfrpicjaf FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_277_header_trailer fk4d5ho5rpjs3shjpracep1c9ch; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_header_trailer
    ADD CONSTRAINT fk4d5ho5rpjs3shjpracep1c9ch FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330f_ref fk4po1wjot218jkpsdjrv9abxql; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330f_ref
    ADD CONSTRAINT fk4po1wjot218jkpsdjrv9abxql FOREIGN KEY (parent_id) REFERENCES public.inst_2330f(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_claim_identifier_dtp fk4ps8ls0ndhxg1yai5s9q5da82; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_claim_identifier_dtp
    ADD CONSTRAINT fk4ps8ls0ndhxg1yai5s9q5da82 FOREIGN KEY (parent_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2430 fk4tw5x9t5q3kcglo6jehlmjbuc; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2430
    ADD CONSTRAINT fk4tw5x9t5q3kcglo6jehlmjbuc FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2400 fk51bu0d2mr8wjf6onj0prq5atv; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2400
    ADD CONSTRAINT fk51bu0d2mr8wjf6onj0prq5atv FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_ref fk52642s3p57wjx349o1o00ghb9; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_ref
    ADD CONSTRAINT fk52642s3p57wjx349o1o00ghb9 FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2430_cas fk529gu8x9fes2sd2fipum6uco7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2430_cas
    ADD CONSTRAINT fk529gu8x9fes2sd2fipum6uco7 FOREIGN KEY (parent_id) REFERENCES public.inst_2430(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2320_cas fk531t1cug623gf5pl1ylb8l0ri; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2320_cas
    ADD CONSTRAINT fk531t1cug623gf5pl1ylb8l0ri FOREIGN KEY (parent_id) REFERENCES public.prof_2320(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: claim_error fk53g0ep44nov1kgmqj9aflswqw; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.claim_error
    ADD CONSTRAINT fk53g0ep44nov1kgmqj9aflswqw FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_dtm fk53svd32953iatxu77l5o9a6ob; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_dtm
    ADD CONSTRAINT fk53svd32953iatxu77l5o9a6ob FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: x12_resp_duplicate_file fk57fymdqj7m0736xqwy6g252l7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12_resp_duplicate_file
    ADD CONSTRAINT fk57fymdqj7m0736xqwy6g252l7 FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330g_ref fk5c33kofcyk69s3sfrvjt2vcrc; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330g_ref
    ADD CONSTRAINT fk5c33kofcyk69s3sfrvjt2vcrc FOREIGN KEY (parent_id) REFERENCES public.inst_2330g(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2310d fk5cg710193dwiibexk9h66qcfb; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310d
    ADD CONSTRAINT fk5cg710193dwiibexk9h66qcfb FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2330h fk5d115xkket14qr07qkieqtdku; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330h
    ADD CONSTRAINT fk5d115xkket14qr07qkieqtdku FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330b_ref fk5p6qfh72f4mxw4kq2wq0u2btw; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330b_ref
    ADD CONSTRAINT fk5p6qfh72f4mxw4kq2wq0u2btw FOREIGN KEY (parent_id) REFERENCES public.prof_2330b(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_nm1 fk5rvpy1b5d71gffnhctpxt41iq; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_nm1
    ADD CONSTRAINT fk5rvpy1b5d71gffnhctpxt41iq FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2420b fk5tcvmfk2yn64m4ydj0j203fjc; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420b
    ADD CONSTRAINT fk5tcvmfk2yn64m4ydj0j203fjc FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420f_ref fk621kyw3yhy60oxqpcv0kk14yi; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420f_ref
    ADD CONSTRAINT fk621kyw3yhy60oxqpcv0kk14yi FOREIGN KEY (parent_id) REFERENCES public.prof_2420f(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2420d_ref fk62g95g4s1lfg9sxy0opkh6aos; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420d_ref
    ADD CONSTRAINT fk62g95g4s1lfg9sxy0opkh6aos FOREIGN KEY (parent_id) REFERENCES public.inst_2420d(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2310d_ref fk63ev0r2yemsfcs49lipa0rj62; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310d_ref
    ADD CONSTRAINT fk63ev0r2yemsfcs49lipa0rj62 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_amt fk6599iktokmqt5cf6inpql4tbg; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_amt
    ADD CONSTRAINT fk6599iktokmqt5cf6inpql4tbg FOREIGN KEY (parent_id) REFERENCES public.remit_2110(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_claim_identifier fk6by9668sowmdob7433mi3rpsu; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_claim_identifier
    ADD CONSTRAINT fk6by9668sowmdob7433mi3rpsu FOREIGN KEY (h_plan_submitter_id) REFERENCES public.h_plan_submitter(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: customer_account fk6c5oqutth35p5vmw0svg56msa; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.customer_account
    ADD CONSTRAINT fk6c5oqutth35p5vmw0svg56msa FOREIGN KEY (customer_id) REFERENCES public.customer(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2300_pwk fk6hdh7mkpkvcug0jisaxh7poir; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_pwk
    ADD CONSTRAINT fk6hdh7mkpkvcug0jisaxh7poir FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330b_ref fk6jdj95769vvkwnu7kxk5hj1v0; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330b_ref
    ADD CONSTRAINT fk6jdj95769vvkwnu7kxk5hj1v0 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_identifier_nm1 fk6na4jbtxowo3sc8xhsosw9ujg; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_identifier_nm1
    ADD CONSTRAINT fk6na4jbtxowo3sc8xhsosw9ujg FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: x12file_struct_validation fk6naed9m2owruc84ls8i6c1x1d; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12file_struct_validation
    ADD CONSTRAINT fk6naed9m2owruc84ls8i6c1x1d FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330b_ref fk6rrlxvwsyp39a7y6ptxyhojxl; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330b_ref
    ADD CONSTRAINT fk6rrlxvwsyp39a7y6ptxyhojxl FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2010ac_ref fk6ukedp39ivpwr44isnw5ght6r; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010ac_ref
    ADD CONSTRAINT fk6ukedp39ivpwr44isnw5ght6r FOREIGN KEY (parent_id) REFERENCES public.prof_2010ac(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: raps_feras_error fk6w55cqp5r4dd92gjhlo91hln6; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_feras_error
    ADD CONSTRAINT fk6w55cqp5r4dd92gjhlo91hln6 FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_qty fk6y5t8ww8c0jq2s6kpoi128yd5; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_qty
    ADD CONSTRAINT fk6y5t8ww8c0jq2s6kpoi128yd5 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330e_ref fk6yd4tn4r2a1jukmnsty37h14o; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330e_ref
    ADD CONSTRAINT fk6yd4tn4r2a1jukmnsty37h14o FOREIGN KEY (parent_id) REFERENCES public.prof_2330e(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2010ba fk70b627j8w6k1sj9o4hn5r9719; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ba
    ADD CONSTRAINT fk70b627j8w6k1sj9o4hn5r9719 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_ref fk70hb2hl2j56ar7nd97y2pg0ju; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_ref
    ADD CONSTRAINT fk70hb2hl2j56ar7nd97y2pg0ju FOREIGN KEY (parent_id) REFERENCES public.remit_2100(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330d_ref fk73yqu8kbm8usyxm2fetlmvvl; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330d_ref
    ADD CONSTRAINT fk73yqu8kbm8usyxm2fetlmvvl FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_amt fk75g9i93obajjj96v96516we54; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_amt
    ADD CONSTRAINT fk75g9i93obajjj96v96516we54 FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_ta1_header_trailer fk795dxvvjgdgiom268sluy1pe9; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_ta1_header_trailer
    ADD CONSTRAINT fk795dxvvjgdgiom268sluy1pe9 FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2430_cas fk7fmlobhasoio42nu2ip7vthby; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2430_cas
    ADD CONSTRAINT fk7fmlobhasoio42nu2ip7vthby FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330e_ref fk7ggoaek7eheubxqi6axaimtkh; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330e_ref
    ADD CONSTRAINT fk7ggoaek7eheubxqi6axaimtkh FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2010aa_ref fk7k1k9gwohj56eg24w44pq7j9n; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010aa_ref
    ADD CONSTRAINT fk7k1k9gwohj56eg24w44pq7j9n FOREIGN KEY (parent_id) REFERENCES public.prof_2010aa(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_resp_277_2220d_stc fk7k58db6userhyo0revjw2vxwa; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2220d_stc
    ADD CONSTRAINT fk7k58db6userhyo0revjw2vxwa FOREIGN KEY (parent_id) REFERENCES public.resp_277_2220d(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2430 fk7kb06ic8oar88intl9b0nq3p2; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2430
    ADD CONSTRAINT fk7kb06ic8oar88intl9b0nq3p2 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_bht fk7x5b4nacr76kvltq9bqixodlb; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_bht
    ADD CONSTRAINT fk7x5b4nacr76kvltq9bqixodlb FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330c_ref fk82qpa7mawutvgmlj2n57goppm; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330c_ref
    ADD CONSTRAINT fk82qpa7mawutvgmlj2n57goppm FOREIGN KEY (parent_id) REFERENCES public.prof_2330c(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2010bb_ref fk83m87cvxy55osgadoecxq3i5a; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010bb_ref
    ADD CONSTRAINT fk83m87cvxy55osgadoecxq3i5a FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2400_ref fk84p9lmcfe97oumjjjd34d3wd7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_ref
    ADD CONSTRAINT fk84p9lmcfe97oumjjjd34d3wd7 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_ref fk85jkp80oinuxrq3nrjvsf6hbj; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_ref
    ADD CONSTRAINT fk85jkp80oinuxrq3nrjvsf6hbj FOREIGN KEY (parent_id) REFERENCES public.prof_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2010aa_per fk89m763v6nb1lcabkmt7r425s6; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010aa_per
    ADD CONSTRAINT fk89m763v6nb1lcabkmt7r425s6 FOREIGN KEY (parent_id) REFERENCES public.inst_2010aa(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2420c fk8aqo4s901d8lfoiywe9opbcsn; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2420c
    ADD CONSTRAINT fk8aqo4s901d8lfoiywe9opbcsn FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2420a_ref fk8c6yxajmhuyhw3ho8bklb497d; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420a_ref
    ADD CONSTRAINT fk8c6yxajmhuyhw3ho8bklb497d FOREIGN KEY (parent_id) REFERENCES public.inst_2420a(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_cas fk8cke87lodqpkbh8sl8q6gjl61; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_cas
    ADD CONSTRAINT fk8cke87lodqpkbh8sl8q6gjl61 FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2400_amt fk8d0lbgttgso2id8jl72c5nbk5; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_amt
    ADD CONSTRAINT fk8d0lbgttgso2id8jl72c5nbk5 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_cas fk8dt2p0dqlkyw98bexdte9lrl7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_cas
    ADD CONSTRAINT fk8dt2p0dqlkyw98bexdte9lrl7 FOREIGN KEY (parent_id) REFERENCES public.remit_2100(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_qty fk8e3x0f0spwtp5xspcmyno2j2o; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_qty
    ADD CONSTRAINT fk8e3x0f0spwtp5xspcmyno2j2o FOREIGN KEY (parent_id) REFERENCES public.remit_2100(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2310b fk8e8qd1kqoah40h1qh6xku5ddu; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310b
    ADD CONSTRAINT fk8e8qd1kqoah40h1qh6xku5ddu FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2000b fk8h6mp8xwcvrmpavk2jhh17qim; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2000b
    ADD CONSTRAINT fk8h6mp8xwcvrmpavk2jhh17qim FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2310b fk8h6uti4jn1gys8h07bebn2l6o; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310b
    ADD CONSTRAINT fk8h6uti4jn1gys8h07bebn2l6o FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330c_ref fk8idftnntj1du0s52w5vmbbyf; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330c_ref
    ADD CONSTRAINT fk8idftnntj1du0s52w5vmbbyf FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_277_2000b fk8lpkgke6curucoqjsmykp21uq; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_2000b
    ADD CONSTRAINT fk8lpkgke6curucoqjsmykp21uq FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2010ba_ref fk8nt3ffudkdmkhkw7j04491g7u; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010ba_ref
    ADD CONSTRAINT fk8nt3ffudkdmkhkw7j04491g7u FOREIGN KEY (parent_id) REFERENCES public.prof_2010ba(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: submitter_info_config fk8o9322exwox9oplk6cioj641y; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.submitter_info_config
    ADD CONSTRAINT fk8o9322exwox9oplk6cioj641y FOREIGN KEY (cms_submitter_id) REFERENCES public.cms_submitter_info(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_2110 fk8ogc8whn9rchbpun2lo31kv98; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_2110
    ADD CONSTRAINT fk8ogc8whn9rchbpun2lo31kv98 FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_1000b fk8s0mwir8ximy50mo2sakk0sr6; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_1000b
    ADD CONSTRAINT fk8s0mwir8ximy50mo2sakk0sr6 FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2010ba_ref fk8tmvpijphify9623h9w3o4vc8; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010ba_ref
    ADD CONSTRAINT fk8tmvpijphify9623h9w3o4vc8 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2300_hi fk8x0qp96r4o99niqkfbvilcle8; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_hi
    ADD CONSTRAINT fk8x0qp96r4o99niqkfbvilcle8 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2300_dtp fk8x18cp24cthonijfa2yfokejd; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_dtp
    ADD CONSTRAINT fk8x18cp24cthonijfa2yfokejd FOREIGN KEY (parent_id) REFERENCES public.inst_2300(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2410 fk91g5ym7wiya93rhy7i6xp6xr7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2410
    ADD CONSTRAINT fk91g5ym7wiya93rhy7i6xp6xr7 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2300_ref fk91iewji93ei6vp58r2psuqpk5; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_ref
    ADD CONSTRAINT fk91iewji93ei6vp58r2psuqpk5 FOREIGN KEY (parent_id) REFERENCES public.inst_2300(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_1000a_per fk93j5sjy8e5w3en7ldejda2ttv; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_1000a_per
    ADD CONSTRAINT fk93j5sjy8e5w3en7ldejda2ttv FOREIGN KEY (parent_id) REFERENCES public.remit_1000a(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_mao_2 fk94epernrno17jcf8m045fr8vk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_mao_2
    ADD CONSTRAINT fk94epernrno17jcf8m045fr8vk FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2420g fk95pek0qtkjjbi9hmjwhh9ojpp; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420g
    ADD CONSTRAINT fk95pek0qtkjjbi9hmjwhh9ojpp FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330f_ref fk96w50d3g714aiikyi5uw3c23h; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330f_ref
    ADD CONSTRAINT fk96w50d3g714aiikyi5uw3c23h FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_amt fk9751qqghaprxoqds7wqowsgo8; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_amt
    ADD CONSTRAINT fk9751qqghaprxoqds7wqowsgo8 FOREIGN KEY (parent_id) REFERENCES public.prof_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_qty fk98cx48mk0e49s0feen9ybupc0; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_qty
    ADD CONSTRAINT fk98cx48mk0e49s0feen9ybupc0 FOREIGN KEY (parent_id) REFERENCES public.prof_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2010ac_ref fk9b9b50tcjp2c33b14nxapksld; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010ac_ref
    ADD CONSTRAINT fk9b9b50tcjp2c33b14nxapksld FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2010ca fk9e5j5t9wg0tnc9jc0urnyb2lt; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ca
    ADD CONSTRAINT fk9e5j5t9wg0tnc9jc0urnyb2lt FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2410_ref fk9fopcpuvyxc24y68gr1xsscvb; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2410_ref
    ADD CONSTRAINT fk9fopcpuvyxc24y68gr1xsscvb FOREIGN KEY (parent_id) REFERENCES public.inst_2410(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_x12file_resp_file fk9ogtwtcev62iha38nyo28jyl6; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_x12file_resp_file
    ADD CONSTRAINT fk9ogtwtcev62iha38nyo28jyl6 FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_per fk9rkcguq6g0xq4x1xb56vgxavg; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_per
    ADD CONSTRAINT fk9rkcguq6g0xq4x1xb56vgxavg FOREIGN KEY (parent_id) REFERENCES public.remit_2100(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2310f fk9u2ydvs39o3vcmmaf69o26jom; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310f
    ADD CONSTRAINT fk9u2ydvs39o3vcmmaf69o26jom FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_claim_identifier_amt fk9umbfhs1qsr2lklaa7ahon76m; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_claim_identifier_amt
    ADD CONSTRAINT fk9umbfhs1qsr2lklaa7ahon76m FOREIGN KEY (parent_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2420h fk9v1b07q8jnb7dp2f0efkv5n6p; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420h
    ADD CONSTRAINT fk9v1b07q8jnb7dp2f0efkv5n6p FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2310f fk9v3371lw791ay1qqkjgn37jqw; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310f
    ADD CONSTRAINT fk9v3371lw791ay1qqkjgn37jqw FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2300_ref fk9v3jl34u12fl429ltts9v0ycs; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_ref
    ADD CONSTRAINT fk9v3jl34u12fl429ltts9v0ycs FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2300_hi fk9wbjh4vwb9i6n7p8pl7otcra; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_hi
    ADD CONSTRAINT fk9wbjh4vwb9i6n7p8pl7otcra FOREIGN KEY (parent_id) REFERENCES public.inst_2300(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2330g fk9wkc4yfowoetsxi6xsajsqtve; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330g
    ADD CONSTRAINT fk9wkc4yfowoetsxi6xsajsqtve FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2310a fk9xe3vw9vf2qear4qymot25fjd; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310a
    ADD CONSTRAINT fk9xe3vw9vf2qear4qymot25fjd FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_ta1_data fk9yl2636loxxklvk8hpcjbasai; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_ta1_data
    ADD CONSTRAINT fk9yl2636loxxklvk8hpcjbasai FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: audit_log fk_audit_log_plan_id; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT fk_audit_log_plan_id FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: flow_item fk_flow_item_flow_id; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.flow_item
    ADD CONSTRAINT fk_flow_item_flow_id FOREIGN KEY (flow_id) REFERENCES public.flow(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: flow_item_history fk_flow_item_history_item_id; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.flow_item_history
    ADD CONSTRAINT fk_flow_item_history_item_id FOREIGN KEY (flow_item_id) REFERENCES public.flow_item(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: in_process_flows fk_in_proc_flows_item_id; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.in_process_flows
    ADD CONSTRAINT fk_in_proc_flows_item_id FOREIGN KEY (flow_item_id) REFERENCES public.flow_item(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_claim_data fk_inst_claim_data_claim_id; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_claim_data
    ADD CONSTRAINT fk_inst_claim_data_claim_id FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_claim_line_data fk_inst_claim_line_data_claim_id; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_claim_line_data
    ADD CONSTRAINT fk_inst_claim_line_data_claim_id FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_claim_data fk_prof_claim_data_claim_id; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_claim_data
    ADD CONSTRAINT fk_prof_claim_data_claim_id FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_claim_line_data fk_prof_claim_line_data_claim_id; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_claim_line_data
    ADD CONSTRAINT fk_prof_claim_line_data_claim_id FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_nte fka11st2pnkqcqec3t14wxohltw; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_nte
    ADD CONSTRAINT fka11st2pnkqcqec3t14wxohltw FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2330f fka4dmnhrokrjgrcs2f1egvv3ww; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330f
    ADD CONSTRAINT fka4dmnhrokrjgrcs2f1egvv3ww FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_dtm fkacn37c3o25snf7v3arx0lgiep; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_dtm
    ADD CONSTRAINT fkacn37c3o25snf7v3arx0lgiep FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310a_ref fkadcxct76cj31f30pf42ii1y9o; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310a_ref
    ADD CONSTRAINT fkadcxct76cj31f30pf42ii1y9o FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2440 fkagri8xc7r1ls3acbn802p1oxk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2440
    ADD CONSTRAINT fkagri8xc7r1ls3acbn802p1oxk FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_se fkah76my5ohel5gvpwbptcferib; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_se
    ADD CONSTRAINT fkah76my5ohel5gvpwbptcferib FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: x12_resp_duplicate_file fkammtrem2bkmcvqcc789avaj4p; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12_resp_duplicate_file
    ADD CONSTRAINT fkammtrem2bkmcvqcc789avaj4p FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330h_ref fkan54nvsnmh02cklwkfoxkshff; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330h_ref
    ADD CONSTRAINT fkan54nvsnmh02cklwkfoxkshff FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310c_ref fkancwhck5e7m7t0ymxu69gd71y; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310c_ref
    ADD CONSTRAINT fkancwhck5e7m7t0ymxu69gd71y FOREIGN KEY (parent_id) REFERENCES public.inst_2310c(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_277_2000d fkanxrh6tacnn41g1l7aktd5x82; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_2000d
    ADD CONSTRAINT fkanxrh6tacnn41g1l7aktd5x82 FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2010ba_ref fkao16w4hx8j2l4ew1fqxilm4q; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010ba_ref
    ADD CONSTRAINT fkao16w4hx8j2l4ew1fqxilm4q FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_identifier fkaovoyhqiakgi5geeduqsp3n0y; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_identifier
    ADD CONSTRAINT fkaovoyhqiakgi5geeduqsp3n0y FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_claim_identifier fkb06gpo9ng6eujkhnes0eco7bj; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_claim_identifier
    ADD CONSTRAINT fkb06gpo9ng6eujkhnes0eco7bj FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2420a fkb6qho8ss6ee0pco2jp3kh1rjq; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420a
    ADD CONSTRAINT fkb6qho8ss6ee0pco2jp3kh1rjq FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420d_ref fkb6s4vpenbhfyms2naiyts7bbu; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420d_ref
    ADD CONSTRAINT fkb6s4vpenbhfyms2naiyts7bbu FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_mea fkb8irwnvcye5ecsuclt01pik3h; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_mea
    ADD CONSTRAINT fkb8irwnvcye5ecsuclt01pik3h FOREIGN KEY (parent_id) REFERENCES public.prof_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_resp_999_2100_ik4 fkbaqa5pl3lrrvwri1q154bjped; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_999_2100_ik4
    ADD CONSTRAINT fkbaqa5pl3lrrvwri1q154bjped FOREIGN KEY (parent_id) REFERENCES public.resp_999_2100(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420b_ref fkbe0cffeaxuv67aad7egjtsl3v; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420b_ref
    ADD CONSTRAINT fkbe0cffeaxuv67aad7egjtsl3v FOREIGN KEY (parent_id) REFERENCES public.prof_2420b(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: raps_eef fkbes6dqbo5xqfr5dps7jw5yfuf; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_eef
    ADD CONSTRAINT fkbes6dqbo5xqfr5dps7jw5yfuf FOREIGN KEY (raps_file_id) REFERENCES public.raps_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_1000a fkbftslunkt74iu277hdrbi3gkx; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_1000a
    ADD CONSTRAINT fkbftslunkt74iu277hdrbi3gkx FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310c_ref fkblxd3wvoo8u6ix5i9cvvlunpe; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310c_ref
    ADD CONSTRAINT fkblxd3wvoo8u6ix5i9cvvlunpe FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_claim_identifier_amt fkbvhmw7t3phot91btgjsqu6p0l; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_claim_identifier_amt
    ADD CONSTRAINT fkbvhmw7t3phot91btgjsqu6p0l FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2300_pwk fkbygnx4idlgydbbdea7udkssn4; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_pwk
    ADD CONSTRAINT fkbygnx4idlgydbbdea7udkssn4 FOREIGN KEY (parent_id) REFERENCES public.prof_2300(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2300_crc fkbyif7wjc13syy1lpmrhmanpup; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_crc
    ADD CONSTRAINT fkbyif7wjc13syy1lpmrhmanpup FOREIGN KEY (parent_id) REFERENCES public.prof_2300(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2300_dtp fkbyopn6g21g4mbefwpip9ldwgd; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_dtp
    ADD CONSTRAINT fkbyopn6g21g4mbefwpip9ldwgd FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2420d_ref fkc0j0ycviqqom3m3pk1ttmighx; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420d_ref
    ADD CONSTRAINT fkc0j0ycviqqom3m3pk1ttmighx FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2330g fkc3b5i071dp7s25tfs9i8tf8xi; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330g
    ADD CONSTRAINT fkc3b5i071dp7s25tfs9i8tf8xi FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2300_ref fkc4300wbgo4t3c0agg4961lgpe; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_ref
    ADD CONSTRAINT fkc4300wbgo4t3c0agg4961lgpe FOREIGN KEY (parent_id) REFERENCES public.prof_2300(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2310b_ref fkcgb6pdpr32h4klomvlv63rnpp; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310b_ref
    ADD CONSTRAINT fkcgb6pdpr32h4klomvlv63rnpp FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2410_ref fkcsx5eqqr7v5hfnt6r03c35k5w; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2410_ref
    ADD CONSTRAINT fkcsx5eqqr7v5hfnt6r03c35k5w FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_999_bht fkctlrx28orddolljr5prtid22v; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_999_bht
    ADD CONSTRAINT fkctlrx28orddolljr5prtid22v FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2330c fkctytnwnr6ycdkb5og0cbb8q68; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330c
    ADD CONSTRAINT fkctytnwnr6ycdkb5og0cbb8q68 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2300_hi fkcwxsyetauc1nd2jk7veetpe27; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_hi
    ADD CONSTRAINT fkcwxsyetauc1nd2jk7veetpe27 FOREIGN KEY (parent_id) REFERENCES public.prof_2300(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2320_amt fkd2s5s2hpdmm1sw4hwbelpnyoj; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2320_amt
    ADD CONSTRAINT fkd2s5s2hpdmm1sw4hwbelpnyoj FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_277_st fkd80tnjgagwndol3018l49m840; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_st
    ADD CONSTRAINT fkd80tnjgagwndol3018l49m840 FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_pwk fkd8mqfjt9wjguic3iam5i8o6cx; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_pwk
    ADD CONSTRAINT fkd8mqfjt9wjguic3iam5i8o6cx FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_cas fkdj66ehce4s91eretmo7lsx0ed; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_cas
    ADD CONSTRAINT fkdj66ehce4s91eretmo7lsx0ed FOREIGN KEY (parent_id) REFERENCES public.remit_2110(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330d_ref fkdo8cusabipjib3ceb3iwbufyn; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330d_ref
    ADD CONSTRAINT fkdo8cusabipjib3ceb3iwbufyn FOREIGN KEY (parent_id) REFERENCES public.prof_2330d(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_dtm fkdp4bay9drfgin3xfsdnk14cbs; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_dtm
    ADD CONSTRAINT fkdp4bay9drfgin3xfsdnk14cbs FOREIGN KEY (parent_id) REFERENCES public.remit_2110(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_dtp fkdw26y2q8jonjhue7fahh4wiuu; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_dtp
    ADD CONSTRAINT fkdw26y2q8jonjhue7fahh4wiuu FOREIGN KEY (parent_id) REFERENCES public.prof_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420b_ref fkdykl1soi2s5lwkhg0cjwblxin; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420b_ref
    ADD CONSTRAINT fkdykl1soi2s5lwkhg0cjwblxin FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2420c fke114nxf837mwqh1tt5ub3tohv; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420c
    ADD CONSTRAINT fke114nxf837mwqh1tt5ub3tohv FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420a_ref fke19g3no2x66snm4hm12k2wbfn; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420a_ref
    ADD CONSTRAINT fke19g3no2x66snm4hm12k2wbfn FOREIGN KEY (parent_id) REFERENCES public.prof_2420a(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_crc fke72vup8wg7qtwa5i6idjen4ys; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_crc
    ADD CONSTRAINT fke72vup8wg7qtwa5i6idjen4ys FOREIGN KEY (parent_id) REFERENCES public.prof_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2330d fkepplmd87hsnwe3lt2jdbgqlck; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330d
    ADD CONSTRAINT fkepplmd87hsnwe3lt2jdbgqlck FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_ref fkeri5l59x8xtutxjamxtnjsbo2; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_ref
    ADD CONSTRAINT fkeri5l59x8xtutxjamxtnjsbo2 FOREIGN KEY (parent_id) REFERENCES public.remit_2110(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_amt fkertfh5kls1eoqefqwmqpw1ed1; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_amt
    ADD CONSTRAINT fkertfh5kls1eoqefqwmqpw1ed1 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2420c_ref fkerwg91qfp25laouvsbgkx14ty; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420c_ref
    ADD CONSTRAINT fkerwg91qfp25laouvsbgkx14ty FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: x12_duplicate_file fketb1hha08s7h85qykhkj5y8ef; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12_duplicate_file
    ADD CONSTRAINT fketb1hha08s7h85qykhkj5y8ef FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420c_ref fkeuotx4yrhxpo5yxtkigx2wetd; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420c_ref
    ADD CONSTRAINT fkeuotx4yrhxpo5yxtkigx2wetd FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_per fkexakxltwju9v49rf879va23hy; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_per
    ADD CONSTRAINT fkexakxltwju9v49rf879va23hy FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2300_pwk fkf1fvpq83riwkdhxodttxdclg0; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_pwk
    ADD CONSTRAINT fkf1fvpq83riwkdhxodttxdclg0 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2310e fkf406ono8itvup7on5b9ssh4nw; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310e
    ADD CONSTRAINT fkf406ono8itvup7on5b9ssh4nw FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420a_ref fkf7s45oijk36w17hud2llk3v0p; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420a_ref
    ADD CONSTRAINT fkf7s45oijk36w17hud2llk3v0p FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2310a_ref fkfbqmu3xuwbm8eehigobq0uu3l; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310a_ref
    ADD CONSTRAINT fkfbqmu3xuwbm8eehigobq0uu3l FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2330f fkfc5ch98opa7tfn4mu3h9lxqnx; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330f
    ADD CONSTRAINT fkfc5ch98opa7tfn4mu3h9lxqnx FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330b_ref fkfdi66duehpasspipfjmk130ib; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330b_ref
    ADD CONSTRAINT fkfdi66duehpasspipfjmk130ib FOREIGN KEY (parent_id) REFERENCES public.inst_2330b(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2000c fkfe6j9hdg9ekjaa08p70nxxras; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2000c
    ADD CONSTRAINT fkfe6j9hdg9ekjaa08p70nxxras FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2410_ref fkfi2nlb08d1u7adlvjs67k5yml; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2410_ref
    ADD CONSTRAINT fkfi2nlb08d1u7adlvjs67k5yml FOREIGN KEY (parent_id) REFERENCES public.prof_2410(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_resp_277_2000b_qty fkfjyy2snjnqxp50xa2yf651ify; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2000b_qty
    ADD CONSTRAINT fkfjyy2snjnqxp50xa2yf651ify FOREIGN KEY (parent_id) REFERENCES public.resp_277_2000b(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_999_header_trailer fkflw4w49de0u3yljuxpu49mh9b; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_999_header_trailer
    ADD CONSTRAINT fkflw4w49de0u3yljuxpu49mh9b FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330g_ref fkfnipbvmxk37fqvydye0qr05w; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330g_ref
    ADD CONSTRAINT fkfnipbvmxk37fqvydye0qr05w FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2310a fkfoagl528k0i4bmtwdv6ucprg8; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310a
    ADD CONSTRAINT fkfoagl528k0i4bmtwdv6ucprg8 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330c_ref fkfobpfat55t26vkuxs2tapr7y3; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330c_ref
    ADD CONSTRAINT fkfobpfat55t26vkuxs2tapr7y3 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2420b_ref fkfowmyohv5cqlx1ancvcg3ek0y; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420b_ref
    ADD CONSTRAINT fkfowmyohv5cqlx1ancvcg3ek0y FOREIGN KEY (parent_id) REFERENCES public.inst_2420b(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_dtm fkfuaircjy1h1601li427i5xund; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_dtm
    ADD CONSTRAINT fkfuaircjy1h1601li427i5xund FOREIGN KEY (parent_id) REFERENCES public.remit_2100(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2400_amt fkfwibi0nxb9np97bpaecaibwb7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_amt
    ADD CONSTRAINT fkfwibi0nxb9np97bpaecaibwb7 FOREIGN KEY (parent_id) REFERENCES public.inst_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310b_ref fkfxhn6jfkn8yvq5ljqibsxle81; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310b_ref
    ADD CONSTRAINT fkfxhn6jfkn8yvq5ljqibsxle81 FOREIGN KEY (parent_id) REFERENCES public.inst_2310b(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2300 fkg1xj4d6xu13m341afbuw8w7ew; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2300
    ADD CONSTRAINT fkg1xj4d6xu13m341afbuw8w7ew FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2300_dtp fkg4gu15eopbffmj4u7f85gdxlt; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_dtp
    ADD CONSTRAINT fkg4gu15eopbffmj4u7f85gdxlt FOREIGN KEY (parent_id) REFERENCES public.prof_2300(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2330b fkg549kkj7tehvsjhj24x287j67; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330b
    ADD CONSTRAINT fkg549kkj7tehvsjhj24x287j67 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: health_plan fkg61lcukyk4o1mcxfqx7ceb7uy; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.health_plan
    ADD CONSTRAINT fkg61lcukyk4o1mcxfqx7ceb7uy FOREIGN KEY (a_id) REFERENCES public.customer_account(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2300 fkg7h0ww29r6tyhx7lqia5vuvpr; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2300
    ADD CONSTRAINT fkg7h0ww29r6tyhx7lqia5vuvpr FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2330d fkg7ugh5fs45g6wx2ftes2of4gs; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330d
    ADD CONSTRAINT fkg7ugh5fs45g6wx2ftes2of4gs FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_mea fkg8iu8fy5eqx2578iu0aqxo2uo; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_mea
    ADD CONSTRAINT fkg8iu8fy5eqx2578iu0aqxo2uo FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_2100 fkgexb5iujw6t511wv50d88wbf6; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_2100
    ADD CONSTRAINT fkgexb5iujw6t511wv50d88wbf6 FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_claim_identifier fkghg06eb3syulj5toy506clngt; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_claim_identifier
    ADD CONSTRAINT fkghg06eb3syulj5toy506clngt FOREIGN KEY (h_plan_submitter_id) REFERENCES public.h_plan_submitter(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2310d_ref fkgiytm2ki3m10n8ija8n8rcnel; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310d_ref
    ADD CONSTRAINT fkgiytm2ki3m10n8ija8n8rcnel FOREIGN KEY (parent_id) REFERENCES public.prof_2310d(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_claim_identifier_amt fkgm72kyjo7xeebj2ifmxh1p35b; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_claim_identifier_amt
    ADD CONSTRAINT fkgm72kyjo7xeebj2ifmxh1p35b FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2400_ref fkgognv4q4exxg2drtb13pj4p4q; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_ref
    ADD CONSTRAINT fkgognv4q4exxg2drtb13pj4p4q FOREIGN KEY (parent_id) REFERENCES public.inst_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_pwk fkgv615s4c21mi5uo1e42hcy56i; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_pwk
    ADD CONSTRAINT fkgv615s4c21mi5uo1e42hcy56i FOREIGN KEY (parent_id) REFERENCES public.prof_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_bht_ref fkgvmk5io5bew2td5oq4y8orjh1; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_bht_ref
    ADD CONSTRAINT fkgvmk5io5bew2td5oq4y8orjh1 FOREIGN KEY (parent_id) REFERENCES public.remit_bht(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_mao_4 fkgyy7maxnswiw0y2cuc78rgyr5; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_mao_4
    ADD CONSTRAINT fkgyy7maxnswiw0y2cuc78rgyr5 FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2320_amt fkh0lmmu56gv4k4tiaixjyx0yed; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2320_amt
    ADD CONSTRAINT fkh0lmmu56gv4k4tiaixjyx0yed FOREIGN KEY (parent_id) REFERENCES public.inst_2320(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_k3 fkh2erco1r3qkl0far1i2phensn; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_k3
    ADD CONSTRAINT fkh2erco1r3qkl0far1i2phensn FOREIGN KEY (parent_id) REFERENCES public.prof_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_ref fkh4c3isyyowb5j1tfcgyk51htd; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_ref
    ADD CONSTRAINT fkh4c3isyyowb5j1tfcgyk51htd FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_qty fkh5crliapbt6ijbc2q7wb9i16w; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_qty
    ADD CONSTRAINT fkh5crliapbt6ijbc2q7wb9i16w FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2400_pwk fkh7t5w9cw71l0j8wbrtebes9gf; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_pwk
    ADD CONSTRAINT fkh7t5w9cw71l0j8wbrtebes9gf FOREIGN KEY (parent_id) REFERENCES public.inst_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_277_bht fkh7wlpfks2bqoqenwjuchyhf48; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_bht
    ADD CONSTRAINT fkh7wlpfks2bqoqenwjuchyhf48 FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_bht fkh8c1a7d4yll04k0ytfhn68u1d; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_bht
    ADD CONSTRAINT fkh8c1a7d4yll04k0ytfhn68u1d FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_x12file_x12shards fkhbsy3rpcyjyxdm9kandtmwax1; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_x12file_x12shards
    ADD CONSTRAINT fkhbsy3rpcyjyxdm9kandtmwax1 FOREIGN KEY (parent_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310f_ref fkhcn3fggsifvcu8wedoxv7e6qx; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310f_ref
    ADD CONSTRAINT fkhcn3fggsifvcu8wedoxv7e6qx FOREIGN KEY (parent_id) REFERENCES public.inst_2310f(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_claim_identifier_amt fkhdroicr18xx4unyvr2isgj20k; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_claim_identifier_amt
    ADD CONSTRAINT fkhdroicr18xx4unyvr2isgj20k FOREIGN KEY (parent_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2310c_ref fkhds6gn9jge2ngru3xjdlne0ba; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310c_ref
    ADD CONSTRAINT fkhds6gn9jge2ngru3xjdlne0ba FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2010ab fkhdyvn0ka61chfw6h46lxqlj2r; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ab
    ADD CONSTRAINT fkhdyvn0ka61chfw6h46lxqlj2r FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_277_2220d fkhfxh7dbdqme4u7326cu5oaxr9; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_2220d
    ADD CONSTRAINT fkhfxh7dbdqme4u7326cu5oaxr9 FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_claim_identifier_dtp fkhlvyunbj21ecgjuhcub8vmb6u; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_claim_identifier_dtp
    ADD CONSTRAINT fkhlvyunbj21ecgjuhcub8vmb6u FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_st fkho323420o2snuvputhusjw8ou; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_st
    ADD CONSTRAINT fkho323420o2snuvputhusjw8ou FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330c_ref fkhoxcdu6iqgq9cxvcu4ldv96i2; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330c_ref
    ADD CONSTRAINT fkhoxcdu6iqgq9cxvcu4ldv96i2 FOREIGN KEY (parent_id) REFERENCES public.inst_2330c(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: x12file fkhrvgqtdisfxyewkswhi96kcxw; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12file
    ADD CONSTRAINT fkhrvgqtdisfxyewkswhi96kcxw FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2010bb fkhv2bv0vo4ps8ts3vfdw06gh9m; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010bb
    ADD CONSTRAINT fkhv2bv0vo4ps8ts3vfdw06gh9m FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_se fkhvxtc6efo7xqiy745yxt4po6l; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_se
    ADD CONSTRAINT fkhvxtc6efo7xqiy745yxt4po6l FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2300_dtp fki69aa9v37rm9wq0s5jo8xm1r; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_dtp
    ADD CONSTRAINT fki69aa9v37rm9wq0s5jo8xm1r FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2310c fkidhfm5amnwcbvmjb7nrksnr02; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2310c
    ADD CONSTRAINT fkidhfm5amnwcbvmjb7nrksnr02 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2300_nte fkikd2f6jlgibkul07vi6i8p2w4; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_nte
    ADD CONSTRAINT fkikd2f6jlgibkul07vi6i8p2w4 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2300_pwk fkipa4crgnvk992hn0obxvbqdmn; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_pwk
    ADD CONSTRAINT fkipa4crgnvk992hn0obxvbqdmn FOREIGN KEY (parent_id) REFERENCES public.inst_2300(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_footer fkipboe84wamq3che2xe5vfddd1; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_footer
    ADD CONSTRAINT fkipboe84wamq3che2xe5vfddd1 FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2400_dtp fkiridqgis0wjtrchkae6jblael; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_dtp
    ADD CONSTRAINT fkiridqgis0wjtrchkae6jblael FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2420a fkivys9g0euerxeccd5uyv78gwc; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2420a
    ADD CONSTRAINT fkivys9g0euerxeccd5uyv78gwc FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: raps_cms_tracking fkixlk6wy9lgp6063kxgag3jmyb; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_cms_tracking
    ADD CONSTRAINT fkixlk6wy9lgp6063kxgag3jmyb FOREIGN KEY (raps_file_id) REFERENCES public.raps_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2010aa_ref fkiym6pqhc5b8bb357n4kybh807; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010aa_ref
    ADD CONSTRAINT fkiym6pqhc5b8bb357n4kybh807 FOREIGN KEY (parent_id) REFERENCES public.inst_2010aa(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2440 fkj4e25g0fp8v06874v263l2l9f; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2440
    ADD CONSTRAINT fkj4e25g0fp8v06874v263l2l9f FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: raps_file fkjiyk9fb38e57cyut2t0wc8yr4; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_file
    ADD CONSTRAINT fkjiyk9fb38e57cyut2t0wc8yr4 FOREIGN KEY (a_id) REFERENCES public.customer_account(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: x12_duplicate_file fkjs7dr944939ke8ijr3i113ehj; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.x12_duplicate_file
    ADD CONSTRAINT fkjs7dr944939ke8ijr3i113ehj FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2000c fkjtcq6lfg1f9143o25ps3wbtl5; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2000c
    ADD CONSTRAINT fkjtcq6lfg1f9143o25ps3wbtl5 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: raps_cluster fkjxc01ad6hrxd3vy3t1m5xmtwo; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_cluster
    ADD CONSTRAINT fkjxc01ad6hrxd3vy3t1m5xmtwo FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_lq fkjylbcurunrl713ixh2ys8y39b; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_lq
    ADD CONSTRAINT fkjylbcurunrl713ixh2ys8y39b FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_dtp fkk0gk2upfwq5kf5rvhjr66aeh4; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_dtp
    ADD CONSTRAINT fkk0gk2upfwq5kf5rvhjr66aeh4 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2330c fkk1xrx8v8s7scbtig7y5cx73u4; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330c
    ADD CONSTRAINT fkk1xrx8v8s7scbtig7y5cx73u4 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_st fkk78udpa4yv9ahw4m7b2ni0cbi; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_st
    ADD CONSTRAINT fkk78udpa4yv9ahw4m7b2ni0cbi FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2330e fkk8du59tpv32l60equijdgu1nk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330e
    ADD CONSTRAINT fkk8du59tpv32l60equijdgu1nk FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2010bb fkkg31mdp8l5uul9la0fcaiq3xa; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010bb
    ADD CONSTRAINT fkkg31mdp8l5uul9la0fcaiq3xa FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2310c_ref fkkhyk1h3jjfpqa6j3gupll31ki; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310c_ref
    ADD CONSTRAINT fkkhyk1h3jjfpqa6j3gupll31ki FOREIGN KEY (parent_id) REFERENCES public.prof_2310c(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2430_cas fkki7u5c6hmrh61ur8agx2mn7i5; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2430_cas
    ADD CONSTRAINT fkki7u5c6hmrh61ur8agx2mn7i5 FOREIGN KEY (parent_id) REFERENCES public.prof_2430(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330g_ref fkkj9ibwiqt9130pyl25cf77bso; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330g_ref
    ADD CONSTRAINT fkkj9ibwiqt9130pyl25cf77bso FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_2000 fkkkri96410elty6ielo97dnggp; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_2000
    ADD CONSTRAINT fkkkri96410elty6ielo97dnggp FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2420b fkkpb2h7721tx16pcpxal65a6ug; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2420b
    ADD CONSTRAINT fkkpb2h7721tx16pcpxal65a6ug FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2400_dtp fkkse6299f7c5ugxrrkm90uq81v; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_dtp
    ADD CONSTRAINT fkkse6299f7c5ugxrrkm90uq81v FOREIGN KEY (parent_id) REFERENCES public.inst_2400(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330f_ref fkl4751002e6scav712y8olqru; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330f_ref
    ADD CONSTRAINT fkl4751002e6scav712y8olqru FOREIGN KEY (parent_id) REFERENCES public.prof_2330f(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_ref fkl70fui5g4q7cy0x1a7xd8uiq8; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_ref
    ADD CONSTRAINT fkl70fui5g4q7cy0x1a7xd8uiq8 FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2300_nte fkldh4rh8dt2lxvqrnmogimbtdk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2300_nte
    ADD CONSTRAINT fkldh4rh8dt2lxvqrnmogimbtdk FOREIGN KEY (parent_id) REFERENCES public.inst_2300(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: h_plan_submitter fkleqq7je69sl1oqii09mogd5bi; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.h_plan_submitter
    ADD CONSTRAINT fkleqq7je69sl1oqii09mogd5bi FOREIGN KEY (cms_submitter_id) REFERENCES public.cms_submitter_info(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_claim_identifier_dtp fklom5ticp8fpnbt9ap1cem2sjr; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_claim_identifier_dtp
    ADD CONSTRAINT fklom5ticp8fpnbt9ap1cem2sjr FOREIGN KEY (parent_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: raps_cluster fklwec9mroxvl37sw99ohspvd69; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_cluster
    ADD CONSTRAINT fklwec9mroxvl37sw99ohspvd69 FOREIGN KEY (raps_file_id) REFERENCES public.raps_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: h_plan_submitter fkm0ktk9wsb98qhgjb5w1ponrpx; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.h_plan_submitter
    ADD CONSTRAINT fkm0ktk9wsb98qhgjb5w1ponrpx FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330i_ref fkma0kgaxsd3r4pkquyosuy2mr1; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330i_ref
    ADD CONSTRAINT fkma0kgaxsd3r4pkquyosuy2mr1 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2310a_ref fkme9p8in1gld1u77wuv2tg1fff; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310a_ref
    ADD CONSTRAINT fkme9p8in1gld1u77wuv2tg1fff FOREIGN KEY (parent_id) REFERENCES public.prof_2310a(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2400_pwk fkmgwep1lw0s968wncjm6pese83; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2400_pwk
    ADD CONSTRAINT fkmgwep1lw0s968wncjm6pese83 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_amt fkmjx50a2tmva4eg8rm971isjv1; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_amt
    ADD CONSTRAINT fkmjx50a2tmva4eg8rm971isjv1 FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310e_ref fkmr2ekmklkfn4lw5vwkmjcu6yc; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310e_ref
    ADD CONSTRAINT fkmr2ekmklkfn4lw5vwkmjcu6yc FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_nm1 fkmw8jx2lwq3w7f9sph8daudb9x; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_nm1
    ADD CONSTRAINT fkmw8jx2lwq3w7f9sph8daudb9x FOREIGN KEY (parent_id) REFERENCES public.remit_2100(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2010ab fkmxp16vuslmb2g5hbysurr6yuy; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2010ab
    ADD CONSTRAINT fkmxp16vuslmb2g5hbysurr6yuy FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_identifier_nm1 fkn0s5x39skqn3d0es2esip7awu; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_identifier_nm1
    ADD CONSTRAINT fkn0s5x39skqn3d0es2esip7awu FOREIGN KEY (parent_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_277_2000c fkn14b782k4vb59p23w2xcufywr; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_277_2000c
    ADD CONSTRAINT fkn14b782k4vb59p23w2xcufywr FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2010aa_ref fkn5a4yfprooj7weipcl8kffo7n; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010aa_ref
    ADD CONSTRAINT fkn5a4yfprooj7weipcl8kffo7n FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2000a fkna0jm4amc1j70uwddpqmrwchl; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2000a
    ADD CONSTRAINT fkna0jm4amc1j70uwddpqmrwchl FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_1000a fknpyd6fsdppapo57k0xq4uhfh7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_1000a
    ADD CONSTRAINT fknpyd6fsdppapo57k0xq4uhfh7 FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2410 fknsh301j7bt0yo99r2ch4yj3lj; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2410
    ADD CONSTRAINT fknsh301j7bt0yo99r2ch4yj3lj FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2010ba_ref fko9ywrkn4kr0oljn2dut7gtb1g; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010ba_ref
    ADD CONSTRAINT fko9ywrkn4kr0oljn2dut7gtb1g FOREIGN KEY (parent_id) REFERENCES public.inst_2010ba(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_1000a fkoco66o6ohqv1ovhwr0dre63ur; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_1000a
    ADD CONSTRAINT fkoco66o6ohqv1ovhwr0dre63ur FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2300_crc fkogu0gt99ekvw6che99fi0w007; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_crc
    ADD CONSTRAINT fkogu0gt99ekvw6che99fi0w007 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2000a fkohprbprygy95umwd7dn4cmbga; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2000a
    ADD CONSTRAINT fkohprbprygy95umwd7dn4cmbga FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_lq fkoq4vc7bawr235fy9ccyjqtyfq; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_lq
    ADD CONSTRAINT fkoq4vc7bawr235fy9ccyjqtyfq FOREIGN KEY (parent_id) REFERENCES public.remit_2110(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_999_2100 fkornxsxx3wybmf4esa4iione9l; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_999_2100
    ADD CONSTRAINT fkornxsxx3wybmf4esa4iione9l FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2010ca fkotqui7we9h38nq99nynplbwur; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2010ca
    ADD CONSTRAINT fkotqui7we9h38nq99nynplbwur FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_1000b fkou565jwwa299jsylh3tb1mc40; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_1000b
    ADD CONSTRAINT fkou565jwwa299jsylh3tb1mc40 FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_cas fkoycligsyxm31vqt665bo84gwc; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_cas
    ADD CONSTRAINT fkoycligsyxm31vqt665bo84gwc FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2330b fkp37nykww0vafwje0vcgg1o2vh; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330b
    ADD CONSTRAINT fkp37nykww0vafwje0vcgg1o2vh FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420e_ref fkp3jl1ufvo68irk20rwe0sja9c; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420e_ref
    ADD CONSTRAINT fkp3jl1ufvo68irk20rwe0sja9c FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2310d fkpbtmb3qdsqlj6yrsqcg55twqc; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310d
    ADD CONSTRAINT fkpbtmb3qdsqlj6yrsqcg55twqc FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2400_k3 fkpc0wivct5xssvk51u0mtb5ufp; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2400_k3
    ADD CONSTRAINT fkpc0wivct5xssvk51u0mtb5ufp FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_bht fkpm4n7al4jw6uw4twu06olll47; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_bht
    ADD CONSTRAINT fkpm4n7al4jw6uw4twu06olll47 FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_st fkpnm0oyktydbhe2s3cpwmf0345; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_st
    ADD CONSTRAINT fkpnm0oyktydbhe2s3cpwmf0345 FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330d_ref fkppavqa0234tm9e1dpge240xw; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330d_ref
    ADD CONSTRAINT fkppavqa0234tm9e1dpge240xw FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_amt fkprgh9odk9bt46pe8gcec87rg3; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_amt
    ADD CONSTRAINT fkprgh9odk9bt46pe8gcec87rg3 FOREIGN KEY (parent_id) REFERENCES public.remit_2100(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2320_cas fkprm7nvn57vgfw4nq63icenyv; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2320_cas
    ADD CONSTRAINT fkprm7nvn57vgfw4nq63icenyv FOREIGN KEY (parent_id) REFERENCES public.inst_2320(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2420f fkpsa6jehwp2ufsvjgw9cr3awse; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420f
    ADD CONSTRAINT fkpsa6jehwp2ufsvjgw9cr3awse FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2420d fkq03nvtynxpx6nd97ofk9m9x59; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2420d
    ADD CONSTRAINT fkq03nvtynxpx6nd97ofk9m9x59 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330e_ref fkq0kld44xrki9i29dams9bv2mb; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330e_ref
    ADD CONSTRAINT fkq0kld44xrki9i29dams9bv2mb FOREIGN KEY (parent_id) REFERENCES public.inst_2330e(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_header_trailer fkq6p41k6n13mknhs9yv4p63jy8; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_header_trailer
    ADD CONSTRAINT fkq6p41k6n13mknhs9yv4p63jy8 FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310d_ref fkqa61t6nl9kl24pgjavanmh86p; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310d_ref
    ADD CONSTRAINT fkqa61t6nl9kl24pgjavanmh86p FOREIGN KEY (parent_id) REFERENCES public.inst_2310d(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420c_ref fkqh4tyyelnir5qml7foh0ijbo9; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420c_ref
    ADD CONSTRAINT fkqh4tyyelnir5qml7foh0ijbo9 FOREIGN KEY (parent_id) REFERENCES public.prof_2420c(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2320 fkqi5e3joypghjlwqai30khokvl; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2320
    ADD CONSTRAINT fkqi5e3joypghjlwqai30khokvl FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2110_qty fkqn31wgfmjxodhdx6apl03l03x; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2110_qty
    ADD CONSTRAINT fkqn31wgfmjxodhdx6apl03l03x FOREIGN KEY (parent_id) REFERENCES public.remit_2110(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2330g_ref fkqq9o5gdbjjnrfh2nvdk01542m; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2330g_ref
    ADD CONSTRAINT fkqq9o5gdbjjnrfh2nvdk01542m FOREIGN KEY (parent_id) REFERENCES public.prof_2330g(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_identifier fkqqntipvxg2u8rkemup3ur2v36; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_identifier
    ADD CONSTRAINT fkqqntipvxg2u8rkemup3ur2v36 FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2010bb_ref fkqtb1xb7o1isa5agbhyc653n01; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010bb_ref
    ADD CONSTRAINT fkqtb1xb7o1isa5agbhyc653n01 FOREIGN KEY (parent_id) REFERENCES public.prof_2010bb(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2010aa_ref fkqtrgx22lsgctjlp8laf5yyjs5; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010aa_ref
    ADD CONSTRAINT fkqtrgx22lsgctjlp8laf5yyjs5 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_claim_identifier fkquhdclhnjm96ptawdc66cvoug; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_claim_identifier
    ADD CONSTRAINT fkquhdclhnjm96ptawdc66cvoug FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2300_hi fkqx8dpguv5d55bdh8vx6j6e0b6; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_hi
    ADD CONSTRAINT fkqx8dpguv5d55bdh8vx6j6e0b6 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2310e fkqy51l4yf7gkltox332rt2q95; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2310e
    ADD CONSTRAINT fkqy51l4yf7gkltox332rt2q95 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_x12file_resp_file fkqycxdeb6s7ardf7klk6miuqfd; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_x12file_resp_file
    ADD CONSTRAINT fkqycxdeb6s7ardf7klk6miuqfd FOREIGN KEY (parent_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2400 fkqyx8ieagkamf4ycumdvnliws3; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2400
    ADD CONSTRAINT fkqyx8ieagkamf4ycumdvnliws3 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: remit_2000 fkr2u9b4r1rrbssm4jdljugd68d; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.remit_2000
    ADD CONSTRAINT fkr2u9b4r1rrbssm4jdljugd68d FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inst_2330i fkr3qpclrnnt8pa162ru4v2y5jj; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.inst_2330i
    ADD CONSTRAINT fkr3qpclrnnt8pa162ru4v2y5jj FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2420e fkr850cyrjuipugs2p3bnpwt6np; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2420e
    ADD CONSTRAINT fkr850cyrjuipugs2p3bnpwt6np FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_mao_1 fkr96fdtq28e4ps80l0ug7nnq7d; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_mao_1
    ADD CONSTRAINT fkr96fdtq28e4ps80l0ug7nnq7d FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: raps_eef fkr9wn8mtiqgg621pfdllp3dbmb; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_eef
    ADD CONSTRAINT fkr9wn8mtiqgg621pfdllp3dbmb FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_1000b fkrayvk4ln73kahyv9qwrfv5sql; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_1000b
    ADD CONSTRAINT fkrayvk4ln73kahyv9qwrfv5sql FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_header_trailer fkrb70rh6dxqi23lkitevmeb056; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_header_trailer
    ADD CONSTRAINT fkrb70rh6dxqi23lkitevmeb056 FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330d_ref fkrfu9qku4pr2xbbvvvjibubsxo; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330d_ref
    ADD CONSTRAINT fkrfu9qku4pr2xbbvvvjibubsxo FOREIGN KEY (parent_id) REFERENCES public.inst_2330d(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2320_cas fkrgxxp1sigb71g30p6cxtf04i7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2320_cas
    ADD CONSTRAINT fkrgxxp1sigb71g30p6cxtf04i7 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: xref_hicn_mbi fkrig66yio4wn6otre1yriedcck; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_hicn_mbi
    ADD CONSTRAINT fkrig66yio4wn6otre1yriedcck FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2330a fkro5avebllat2ujlb3opvdlu45; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330a
    ADD CONSTRAINT fkro5avebllat2ujlb3opvdlu45 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310d_ref fkrpwcluuj1lxq2eosancgimglp; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310d_ref
    ADD CONSTRAINT fkrpwcluuj1lxq2eosancgimglp FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2410_ref fkrtg4dcns2wc1xeakhkdixhd3d; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2410_ref
    ADD CONSTRAINT fkrtg4dcns2wc1xeakhkdixhd3d FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420d_ref fkru9opacoskbow1s5l98qjwjp1; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420d_ref
    ADD CONSTRAINT fkru9opacoskbow1s5l98qjwjp1 FOREIGN KEY (parent_id) REFERENCES public.prof_2420d(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_remit_2100_qty fks1swd09lhcovcson9y3nd3t1b; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_remit_2100_qty
    ADD CONSTRAINT fks1swd09lhcovcson9y3nd3t1b FOREIGN KEY (remittance_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2420c_ref fks369u8eoda380ma1vw4a10c93; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420c_ref
    ADD CONSTRAINT fks369u8eoda380ma1vw4a10c93 FOREIGN KEY (parent_id) REFERENCES public.inst_2420c(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_999_2000 fks5ikurhs7g1iyml83s35cgfg2; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_999_2000
    ADD CONSTRAINT fks5ikurhs7g1iyml83s35cgfg2 FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2010aa_per fks7iw9c4wbjgrpecqtfsxxbwhc; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010aa_per
    ADD CONSTRAINT fks7iw9c4wbjgrpecqtfsxxbwhc FOREIGN KEY (parent_id) REFERENCES public.prof_2010aa(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2430_cas fksbs7f54lftcq0fxmm2n22enjh; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2430_cas
    ADD CONSTRAINT fksbs7f54lftcq0fxmm2n22enjh FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2300_ref fkscxk19399wcfecotoscv60su9; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2300_ref
    ADD CONSTRAINT fkscxk19399wcfecotoscv60su9 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_raps_feras_error_raps_resp fksdkjvdkvynmfh9m514wj8vwq9; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_raps_feras_error_raps_resp
    ADD CONSTRAINT fksdkjvdkvynmfh9m514wj8vwq9 FOREIGN KEY (parent_id) REFERENCES public.raps_feras_error(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2010bb_ref fksoisuf2ymyvpt95lj94c8w42c; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2010bb_ref
    ADD CONSTRAINT fksoisuf2ymyvpt95lj94c8w42c FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330i_ref fkspe8btoktd2tmy7y9wxv5orno; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330i_ref
    ADD CONSTRAINT fkspe8btoktd2tmy7y9wxv5orno FOREIGN KEY (parent_id) REFERENCES public.inst_2330i(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2420b_ref fksq5pfpno3rgl07iancgqo72fj; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2420b_ref
    ADD CONSTRAINT fksq5pfpno3rgl07iancgqo72fj FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prof_2330e fkstmonnb7tmtnms3a7sj85r551; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.prof_2330e
    ADD CONSTRAINT fkstmonnb7tmtnms3a7sj85r551 FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2420f_ref fksxustghud4qpwq4qq89diho5y; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2420f_ref
    ADD CONSTRAINT fksxustghud4qpwq4qq89diho5y FOREIGN KEY (claim_id) REFERENCES public.prof_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2310f_ref fkt01qt4hwpkmkpitmimethjgl7; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2310f_ref
    ADD CONSTRAINT fkt01qt4hwpkmkpitmimethjgl7 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2010bb_ref fkt5joy3ma9gj466flg51tus8kd; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010bb_ref
    ADD CONSTRAINT fkt5joy3ma9gj466flg51tus8kd FOREIGN KEY (parent_id) REFERENCES public.inst_2010bb(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2010ac_ref fkt5xlnbnp6ssk1gqwhuvdyum5n; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010ac_ref
    ADD CONSTRAINT fkt5xlnbnp6ssk1gqwhuvdyum5n FOREIGN KEY (parent_id) REFERENCES public.inst_2010ac(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2310b_ref fktcv79pvj5geje34s4ethsavys; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2310b_ref
    ADD CONSTRAINT fktcv79pvj5geje34s4ethsavys FOREIGN KEY (parent_id) REFERENCES public.prof_2310b(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2010aa_per fkteln7qbcjtul4l6g67soxrgf4; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2010aa_per
    ADD CONSTRAINT fkteln7qbcjtul4l6g67soxrgf4 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_resp_277_2000d_dtp fktlw499y5gns7imwtyg75ydtp0; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2000d_dtp
    ADD CONSTRAINT fktlw499y5gns7imwtyg75ydtp0 FOREIGN KEY (parent_id) REFERENCES public.resp_277_2000d(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_resp_277_2000d_stc fktlw499y5gns7imwtyg75yrgt0; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2000d_stc
    ADD CONSTRAINT fktlw499y5gns7imwtyg75yrgt0 FOREIGN KEY (parent_id) REFERENCES public.resp_277_2000d(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_resp_277_2000d_ref fktlw499y5gns7imwtyg75yrmt0; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_resp_277_2000d_ref
    ADD CONSTRAINT fktlw499y5gns7imwtyg75yrmt0 FOREIGN KEY (parent_id) REFERENCES public.resp_277_2000d(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: raps_cluster_history fktnk97wunqygj1nnox83haison; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.raps_cluster_history
    ADD CONSTRAINT fktnk97wunqygj1nnox83haison FOREIGN KEY (raps_file_id) REFERENCES public.raps_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_prof_2320_amt fktp6jsnx5hk9mi3cottqfu24jn; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_prof_2320_amt
    ADD CONSTRAINT fktp6jsnx5hk9mi3cottqfu24jn FOREIGN KEY (parent_id) REFERENCES public.prof_2320(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: h_plan_report fktpfedljkpci23uh8l9uebtso4; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.h_plan_report
    ADD CONSTRAINT fktpfedljkpci23uh8l9uebtso4 FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330e_ref fktpvwy3sgdg558d4cuujeq5lt3; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330e_ref
    ADD CONSTRAINT fktpvwy3sgdg558d4cuujeq5lt3 FOREIGN KEY (claim_id) REFERENCES public.inst_claim_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: child_inst_2330h_ref fkwdjgua5cjh334xa9qp8w4h50; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.child_inst_2330h_ref
    ADD CONSTRAINT fkwdjgua5cjh334xa9qp8w4h50 FOREIGN KEY (parent_id) REFERENCES public.inst_2330h(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: resp_999_2110 fkwr8jyv7ejfg9ix4d2bwgmy6h; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.resp_999_2110
    ADD CONSTRAINT fkwr8jyv7ejfg9ix4d2bwgmy6h FOREIGN KEY (resp_file_id) REFERENCES public.child_x12file_resp_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: linked_cr_batch linkedcrbatchfileidfk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.linked_cr_batch
    ADD CONSTRAINT linkedcrbatchfileidfk FOREIGN KEY (batch_file_id) REFERENCES public.batch_file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: member_raf memberrafhealthplanfk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.member_raf
    ADD CONSTRAINT memberrafhealthplanfk FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: provider_837_remit_mapping remit_identifier_to_mapping_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.provider_837_remit_mapping
    ADD CONSTRAINT remit_identifier_to_mapping_fkey FOREIGN KEY (ref_remit_id) REFERENCES public.remit_identifier(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_category report_category_fk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_category
    ADD CONSTRAINT report_category_fk FOREIGN KEY (report_name) REFERENCES public.report_type(name) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_details report_details_fk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_details
    ADD CONSTRAINT report_details_fk FOREIGN KEY (report_category_id) REFERENCES public.report_category(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_subscription report_subscription_fk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.report_subscription
    ADD CONSTRAINT report_subscription_fk FOREIGN KEY (report_details_id) REFERENCES public.report_details(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: segment_data segment_data_x12file_fk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE public.segment_data
    ADD CONSTRAINT segment_data_x12file_fk FOREIGN KEY (file_id) REFERENCES public.x12file(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: xref_claim_npi_mapping xref_claim_npi_mapping_plan_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.xref_claim_npi_mapping
    ADD CONSTRAINT xref_claim_npi_mapping_plan_id_fk FOREIGN KEY (h_plan_id) REFERENCES public.health_plan(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

--
-- Email-notification outbox (EMAIL_NOTIFICATIONS_AWS_SES_PLAN_V2, Phase 1).
-- Added to the baseline init script so every TestContainers context that boots from ras_v3.sql
-- and touches NotificationService has the table. Mirrors ras-db-config
-- liquibase/version2/notification_outbox.sql (and member_hcc_year_test_setup.sql).
--
CREATE TABLE IF NOT EXISTS public.notification_outbox (
    id                   BIGSERIAL PRIMARY KEY,
    template_key         TEXT     NOT NULL,
    tenant_schema        TEXT     NOT NULL DEFAULT '',
    h_plan_id            SMALLINT NOT NULL DEFAULT 0,
    dedupe_key           TEXT     NOT NULL,
    to_emails            TEXT     NOT NULL,
    cc_emails            TEXT,
    subject              TEXT     NOT NULL,
    body_html            TEXT,
    body_text            TEXT,
    attachment_paths     TEXT,
    phi_data             BOOLEAN  NOT NULL DEFAULT FALSE,
    status               TEXT     NOT NULL DEFAULT 'PENDING',
    attempts             INT      NOT NULL DEFAULT 0,
    last_error           TEXT,
    provider_message_id  TEXT,
    payload_json         JSONB,
    scheduled_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    sent_at              TIMESTAMP WITH TIME ZONE,
    created_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT notification_outbox_dedupe_uk UNIQUE (template_key, h_plan_id, dedupe_key)
);
CREATE INDEX IF NOT EXISTS notification_outbox_pending_idx
    ON public.notification_outbox (scheduled_at)
    WHERE status = 'PENDING';

CREATE TABLE IF NOT EXISTS public.notification_recipient (
    id                  BIGSERIAL PRIMARY KEY,
    email               TEXT NOT NULL UNIQUE,
    recipient_kind      TEXT NOT NULL DEFAULT 'EXTERNAL',
    identity_subject    TEXT,
    verified_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    disabled_at         TIMESTAMP WITH TIME ZONE,
    last_bounce_at      TIMESTAMP WITH TIME ZONE,
    created_by          TEXT NOT NULL,
    updated_by          TEXT NOT NULL,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT notification_recipient_email_normalized_ck CHECK (email = lower(btrim(email))),
    CONSTRAINT notification_recipient_kind_ck CHECK (recipient_kind IN ('EXTERNAL', 'IDENTITY')),
    CONSTRAINT notification_recipient_identity_ck
        CHECK (recipient_kind <> 'IDENTITY' OR identity_subject IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS public.notification_subscription (
    id                  BIGSERIAL PRIMARY KEY,
    recipient_id        BIGINT NOT NULL REFERENCES public.notification_recipient(id) ON DELETE CASCADE,
    h_plan_id           SMALLINT NOT NULL REFERENCES public.health_plan(id) ON DELETE CASCADE,
    template_key        TEXT NOT NULL,
    display_name        TEXT,
    persona             TEXT NOT NULL,
    source              TEXT NOT NULL DEFAULT 'ADMIN',
    enabled             BOOLEAN NOT NULL DEFAULT TRUE,
    created_by          TEXT NOT NULL,
    updated_by          TEXT NOT NULL,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT notification_subscription_persona_ck
        CHECK (persona IN ('FINANCE', 'RECAPTURE', 'OPERATIONAL', 'ALERT')),
    CONSTRAINT notification_subscription_source_ck
        CHECK (source IN ('ADMIN', 'SELF_SERVICE', 'MIGRATION')),
    CONSTRAINT notification_subscription_audience_uk
        UNIQUE (h_plan_id, template_key, recipient_id)
);

ALTER TABLE public.notification_outbox
    ADD COLUMN IF NOT EXISTS subscription_ids BIGINT[] NOT NULL DEFAULT '{}'::BIGINT[];

CREATE TABLE IF NOT EXISTS public.notification_allowed_domain (
    id                  BIGSERIAL PRIMARY KEY,
    h_plan_id           SMALLINT NOT NULL REFERENCES public.health_plan(id) ON DELETE CASCADE,
    domain              TEXT NOT NULL,
    created_by          TEXT NOT NULL,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT notification_allowed_domain_normalized_ck CHECK (domain = lower(btrim(domain))),
    CONSTRAINT notification_allowed_domain_format_ck
        CHECK (domain ~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$'),
    CONSTRAINT notification_allowed_domain_uk UNIQUE (h_plan_id, domain)
);

CREATE TABLE IF NOT EXISTS public.flow_file_rejection (
    id                      BIGSERIAL PRIMARY KEY,
    flow_id                 BIGINT REFERENCES public.flow(id) ON DELETE SET NULL,
    flow_name               TEXT NOT NULL,
    source_file_name        TEXT NOT NULL,
    item_type               TEXT NOT NULL,
    validation_rules        TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    validation_error_count  INTEGER NOT NULL CHECK (validation_error_count > 0),
    occurred_at             TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS flow_file_rejection_occurred_idx
    ON public.flow_file_rejection (occurred_at DESC);
CREATE INDEX IF NOT EXISTS flow_file_rejection_flow_idx
    ON public.flow_file_rejection (flow_id);
