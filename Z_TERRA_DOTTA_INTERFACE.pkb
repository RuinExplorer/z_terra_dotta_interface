/* Formatted on 5/31/2019 11:39:43 AM (QP5 v5.336) */
CREATE OR REPLACE PACKAGE BODY BANINST1.z_terra_dotta_interface
AS
    /***************************************************************************

    REVISIONS:
    Date       Author           Description
    ---------  ---------------  ------------------------------------
    20160617   Carl Ellsworth   created this package from z_student_etl
    20160620   Carl Ellsworth   added p_extract_sis_user_info_custom
    20160622   Carl Ellsworth   split out individual address fields
    20160623   Carl Ellsworth   updated file names to match vendor spec
    20170103   Carl Ellsworth   added error handling to track down issues
    20170406   Carl Ellsworth   removed unessesary SQLERRM causing APPMANAGER GRIEF
    20170511   Carl Ellsworth   Option1 field now populated with residency
    20170908   Carl Ellsworth   updated term function calls
    20180524   Carl Ellsworth   added custom call for majority campus
    20180926   Carl Ellsworth   updated major2 field with college as requested
    20190520   Carl Ellsworth   added ISS extract functionality
    20190521   Carl Ellsworth   added some SEVIS specifics to ISSS extract
    20190522   Carl Ellsworth   added extended academics to ISSS extract
    20190523   Carl Ellsworth   added Admissions, Advisors, and more data elements
    20190524   Carl Ellsworth   added sevis translations for degree codes
    20190531   Carl Ellsworth   added logic for a term code override for calculations

    ***************************************************************************/

    gv_directory_name   VARCHAR2 (30) := 'TERRADOTTA';

    FUNCTION f_enclose (p_string IN OUT VARCHAR2)
        RETURN VARCHAR2
    IS
        quot   CHAR := CHR (34);               --ASCII character double quotes
    BEGIN
        IF p_string IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN (quot || p_string || quot);
        END IF;
    END;

    FUNCTION f_parse (p_string    VARCHAR2,
                      p_col_num   VARCHAR2,
                      p_delim     VARCHAR2)
        RETURN VARCHAR2
    /***************************************************************************
       This process will receive a column number as an input parameter and return
        the value in that column.  If nothing is found will return null.
    ***************************************************************************/
    IS
        --v_delim         VARCHAR2 (1) := CHR (9);                           --tab
        v_parse_first   VARCHAR2 (32767);
        v_parse_last    VARCHAR2 (32767);
        v_parse_quote   VARCHAR2 (32767);
        v_value         VARCHAR2 (32767);
        v_string        VARCHAR2 (32767);
    BEGIN
        -- Add comma to end of the string to allow function to parse out possible last value
        v_string := p_string || p_delim;

        -- get characters up to the desired delim (row)
        v_parse_first :=
            SUBSTR (v_string,
                    1,
                      INSTR (v_string,
                             p_delim,
                             1,
                             p_col_num)
                    - 1);

        -- reverse search keeping everything from the end of the string until the first comma
        v_parse_last :=
            SUBSTR (v_parse_first,
                      INSTR (v_parse_first,
                             p_delim,
                             -1,
                             1)
                    + 1);

        --trim any quotes from characters
        v_parse_quote := TRIM ('"' FROM v_parse_last);

        -- trim any leading or trailing spaces in data.
        v_value := TRIM (v_parse_quote);

        RETURN v_value;
    END;

    PROCEDURE p_student_address (p_pidm                 VARCHAR2,
                                 p_addr_type            VARCHAR2,
                                 p_addr_date            DATE DEFAULT NULL,
                                 out_street_line1   OUT VARCHAR2,
                                 out_street_line2   OUT VARCHAR2,
                                 out_street_line3   OUT VARCHAR2,
                                 out_city           OUT VARCHAR2,
                                 out_stat_code      OUT VARCHAR2,
                                 out_zip            OUT VARCHAR2,
                                 out_natn_code      OUT VARCHAR2)
    AS
    BEGIN
        SELECT spraddr_street_line1,
               spraddr_street_line2,
               spraddr_street_line3,
               spraddr_city,
               spraddr_stat_code,
               spraddr_zip,
               spraddr_natn_code
          INTO out_street_line1,
               out_street_line2,
               out_street_line3,
               out_city,
               out_stat_code,
               out_zip,
               out_natn_code
          FROM spraddr
         WHERE     spraddr_pidm = p_pidm
               AND spraddr_atyp_code = p_addr_type
               AND (spraddr_status_ind IS NULL OR spraddr_status_ind = 'A')
               AND TRUNC (NVL (p_addr_date, SYSDATE)) BETWEEN TRUNC (
                                                                  NVL (
                                                                      spraddr_from_date,
                                                                      NVL (
                                                                          p_addr_date,
                                                                          SYSDATE)))
                                                          AND TRUNC (
                                                                  NVL (
                                                                      spraddr_to_date,
                                                                      NVL (
                                                                          p_addr_date,
                                                                          SYSDATE)));
    --RETURN v_address;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            out_street_line1 := NULL;
            out_street_line2 := NULL;
            out_street_line3 := NULL;
            out_city := NULL;
            out_stat_code := NULL;
            out_zip := NULL;
            out_natn_code := NULL;
        --return null;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Address: '
                || 'PIDM: '
                || p_pidm
                || ' ADDR_TYPE: '
                || p_addr_type
                || ' ADDR_DATE: '
                || p_addr_date
                || SQLERRM);
            RAISE;
    END;


    FUNCTION f_student_level (p_pidm VARCHAR2, p_term VARCHAR2)
        RETURN VARCHAR2
    IS
        v_level_code   VARCHAR2 (8);
    BEGIN
        SELECT sgbstdn_levl_code
          INTO v_level_code
          FROM sgbstdn
         WHERE     sgbstdn_term_code_eff =
                   (SELECT MAX (bravo.sgbstdn_term_code_eff)
                      FROM sgbstdn bravo
                     WHERE     bravo.sgbstdn_pidm = sgbstdn.sgbstdn_pidm
                           AND bravo.sgbstdn_term_code_eff <= p_term)
               AND sgbstdn_pidm = p_pidm;

        RETURN v_level_code;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Level: '
                || SQLERRM);
            RAISE;
    END;

    FUNCTION f_student_visa (p_pidm gorvisa.gorvisa_pidm%TYPE)
        RETURN VARCHAR2
    IS
        --
        rtn_visa   VARCHAR2 (16);
    BEGIN
        SELECT MAX (gorvisa_vtyp_code)
          INTO rtn_visa
          FROM gorvisa
         WHERE     gorvisa_pidm = p_pidm
               AND gorvisa_seq_no = (SELECT MAX (bravo.gorvisa_seq_no)
                                       FROM gorvisa bravo
                                      WHERE bravo.gorvisa_pidm = p_pidm);

        RETURN rtn_visa;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Visa: '
                || SQLERRM);
            RAISE;
    END f_student_visa;

    FUNCTION f_student_natn (p_pidm gobintl.gobintl_pidm%TYPE)
        RETURN VARCHAR2
    IS
        --
        rtn_natn   VARCHAR2 (16);
    BEGIN
        SELECT MAX (gobintl_natn_code_legal)
          INTO rtn_natn
          FROM gobintl
         WHERE gobintl_pidm = p_pidm;

        RETURN rtn_natn;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Nation: '
                || SQLERRM);
            RAISE;
    END f_student_natn;

    FUNCTION f_student_record (
        p_pidm            sgbstdn.sgbstdn_pidm%TYPE,
        p_term_code       sgbstdn.sgbstdn_term_code_eff%TYPE,
        out_major_1   OUT VARCHAR2,
        out_college   OUT VARCHAR2)
        RETURN DATE
    IS
        --this procedure served as a shortcut to major_1 and major_2
        -- Monika Galvydis requested that major_2 be populated with college instead
        -- the change was made on 20180926 and is noted here due to the field name
        rtn_exp_grad_date   DATE;
    BEGIN
        SELECT sgbstdn_exp_grad_date, alpha.stvmajr_desc, stvcoll_desc --bravo.stvmajr_desc
          INTO rtn_exp_grad_date, out_major_1, out_college       --out_major_2
          FROM sgbstdn  alpha
               LEFT JOIN stvmajr alpha
                   ON alpha.stvmajr_code = sgbstdn_majr_code_1
               LEFT JOIN stvmajr bravo
                   ON bravo.stvmajr_code = sgbstdn_majr_code_2
               LEFT JOIN stvcoll ON stvcoll_code = alpha.sgbstdn_coll_code_1
         WHERE     sgbstdn_pidm = p_pidm
               AND sgbstdn_term_code_eff =
                   (SELECT MAX (bravo.sgbstdn_term_code_eff)
                      FROM sgbstdn bravo
                     WHERE     bravo.sgbstdn_pidm = alpha.sgbstdn_pidm
                           AND bravo.sgbstdn_term_code_eff <= p_term_code);

        RETURN rtn_exp_grad_date;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            rtn_exp_grad_date := NULL;
            out_major_1 := NULL;
            out_college := NULL;
            --out_major_2 := NULL;
            RETURN rtn_exp_grad_date;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Record: '
                || SQLERRM);
            RAISE;
    END f_student_record;

    FUNCTION f_student_emergency (p_pidm spremrg.spremrg_pidm%TYPE)
        RETURN VARCHAR2
    IS
        --
        rtn_emergency_contact   VARCHAR2 (512);
    BEGIN
        SELECT TRIM (
                      'NAME: '
                   || spremrg_first_name
                   || ' '
                   || spremrg_last_name
                   || ' PHONE: '
                   || spremrg_phone_area
                   || spremrg_phone_number
                   || ' ADDRESS: '
                   || CASE
                          WHEN spremrg_street_line1 IS NULL THEN ''
                          ELSE spremrg_street_line1 || ', '
                      END
                   || CASE
                          WHEN spremrg_street_line2 IS NULL THEN ''
                          ELSE spremrg_street_line2 || ', '
                      END
                   || CASE
                          WHEN spremrg_street_line3 IS NULL THEN ''
                          ELSE spremrg_street_line3 || ', '
                      END
                   || spremrg_city
                   || ' '
                   || spremrg_stat_code
                   || ' '
                   || spremrg_zip
                   || CASE
                          WHEN spremrg_natn_code = 'US' THEN ''
                          WHEN spremrg_natn_code IS NULL THEN ''
                          ELSE ', ' || spremrg_natn_code
                      END)    AS CONTACT_STRING
          INTO rtn_emergency_contact
          FROM spremrg alpha
         WHERE     spremrg_pidm = p_pidm
               AND spremrg_priority =
                   (SELECT MIN (bravo.spremrg_priority)
                      FROM spremrg bravo
                     WHERE bravo.spremrg_pidm = alpha.spremrg_pidm);

        RETURN rtn_emergency_contact;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Emergency Contact: '
                || SQLERRM);
            RAISE;
    END f_student_emergency;

    FUNCTION f_student_phone (
        p_pidm        IN sprtele.sprtele_pidm%TYPE,
        p_tele_code   IN sprtele.sprtele_tele_code%TYPE)
        RETURN VARCHAR2
    AS
        rtn_phone_number   VARCHAR2 (64);
    BEGIN
        SELECT phone_number
          INTO rtn_phone_number
          FROM (  SELECT SUBSTR (
                             REGEXP_REPLACE (
                                    sprtele_phone_area
                                 || sprtele_phone_number
                                 || sprtele_phone_ext,
                                 '[^0-9]+',
                                 ''),
                             1,
                             10)    AS phone_number
                    FROM sprtele
                   WHERE     (   sprtele_atyp_code = NULL
                              OR (sprtele_atyp_code, sprtele_addr_seqno) =
                                 (SELECT spraddr_atyp_code, spraddr_seqno
                                    FROM spraddr
                                   WHERE     spraddr.ROWID = baninst1.F_GET_ADDRESS_ROWID (
                                                                 spraddr_pidm,
                                                                 'ADMSADDR',
                                                                 'A',
                                                                 SYSDATE,
                                                                 NULL,
                                                                 'S',
                                                                 NULL)
                                         AND spraddr_pidm = sprtele_pidm))
                         AND sprtele_tele_code = p_tele_code
                         AND sprtele_pidm = p_pidm
                         AND sprtele_status_ind IS NULL
                ORDER BY sprtele_seqno DESC) numbers
         WHERE ROWNUM = 1;

        RETURN rtn_phone_number;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Phone Number: '
                || SQLERRM);
            RAISE;
    END f_student_phone;

    FUNCTION f_holds_academic (p_pidm sprhold.sprhold_pidm%TYPE)
        RETURN VARCHAR2
    IS
        rtn_boolean   VARCHAR2 (3) := NULL;
    BEGIN
        --academic holds
        SELECT DISTINCT MAX ('Yes')
          INTO rtn_boolean
          FROM sprhold
         WHERE     sprhold_hldd_code IN ('AA',
                                         'AD',
                                         'AT',
                                         'CT',
                                         'CW',
                                         'DH',
                                         'HO',
                                         'IN',
                                         'IS',
                                         'JD',
                                         'J1',
                                         'MS',
                                         'RG',
                                         'SH',
                                         'TR',
                                         'UA',
                                         'VT')
               AND SYSDATE BETWEEN sprhold_from_date
                               AND NVL (sprhold_to_date, SYSDATE)
               AND sprhold_pidm = p_pidm;

        IF rtn_boolean IS NULL
        THEN
            rtn_boolean := 'No';
        END IF;

        RETURN rtn_boolean;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Academic Holds: '
                || SQLERRM);
            RAISE;
    END;

    FUNCTION f_holds_financial (p_pidm sprhold.sprhold_pidm%TYPE)
        RETURN VARCHAR2
    IS
        rtn_boolean   VARCHAR2 (3) := NULL;
    BEGIN
        --financial holds
        SELECT DISTINCT MAX ('Yes')
          INTO rtn_boolean
          FROM sprhold
         WHERE     sprhold_hldd_code IN ('A1',
                                         'AR',
                                         'BI',
                                         'BK',
                                         'CB',
                                         'CP',
                                         'JM',
                                         'LF',
                                         'P1',
                                         'P3',
                                         'PF',
                                         'PR',
                                         'R1',
                                         'RT',
                                         'T1',
                                         'WO')
               AND SYSDATE BETWEEN sprhold_from_date
                               AND NVL (sprhold_to_date, SYSDATE)
               AND sprhold_pidm = p_pidm;

        IF rtn_boolean IS NULL
        THEN
            rtn_boolean := 'No';
        END IF;

        RETURN rtn_boolean;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Financial Holds: '
                || SQLERRM);
            RAISE;
    END;

    FUNCTION f_holds_conduct (p_pidm sprhold.sprhold_pidm%TYPE)
        RETURN VARCHAR2
    IS
        rtn_boolean   VARCHAR2 (3) := NULL;
    BEGIN
        --financial holds
        SELECT DISTINCT MAX ('Yes')
          INTO rtn_boolean
          FROM sprhold
         WHERE     sprhold_hldd_code IN ('J1', 'JD')
               AND SYSDATE BETWEEN sprhold_from_date
                               AND NVL (sprhold_to_date, SYSDATE)
               AND sprhold_pidm = p_pidm;

        IF rtn_boolean IS NULL
        THEN
            rtn_boolean := 'No';
        END IF;

        RETURN rtn_boolean;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Conduct Holds: '
                || SQLERRM);
            RAISE;
    END f_holds_conduct;

    FUNCTION f_student_resd (p_pidm VARCHAR2, p_term VARCHAR2)
        RETURN VARCHAR2
    IS
        v_resd_desc   VARCHAR2 (30);
    BEGIN
        SELECT stvresd_desc
          INTO v_resd_desc
          FROM sgbstdn JOIN stvresd ON sgbstdn_resd_code = stvresd_code
         WHERE     sgbstdn_term_code_eff =
                   (SELECT MAX (bravo.sgbstdn_term_code_eff)
                      FROM sgbstdn bravo
                     WHERE     bravo.sgbstdn_pidm = sgbstdn.sgbstdn_pidm
                           AND bravo.sgbstdn_term_code_eff <= p_term)
               AND sgbstdn_pidm = p_pidm;

        RETURN v_resd_desc;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Student Residency: '
                || SQLERRM);
            RAISE;
    END;

    PROCEDURE p_extract_hr_user_info_core
    IS
        v_delim       VARCHAR2 (1) := CHR (9); --ASCII Character horizonal tab

        --PROCESSING VARIABLES
        id            UTL_FILE.file_type;
        filedata      VARCHAR2 (20000);

        CURSOR hr_cur IS
            (SELECT SUBSTR (spriden_first_name, 1, 50)         user_first_name,
                    SUBSTR (spriden_last_name, 1, 50)          user_last_name,
                    SUBSTR (spriden_mi, 1, 50)                 user_middle_name,
                    spriden_id                                 user_name,
                    SUBSTR (goremal_email_address, 1, 250)     user_email
               FROM (SELECT DISTINCT spriden_pidm     pidm
                       FROM ts_hr.hrd_emplposnjobs@EDW
                      WHERE     nbbposn_posn LIKE '9%'
                            AND nbrjobs_effective_date < SYSDATE
                            AND nbrjobs_nchg_date >= SYSDATE) population
                    JOIN spriden
                        ON spriden_pidm = pidm AND spriden_change_ind IS NULL
                    --LEFT JOIN spbpers ON spbpers_pidm = pidm
                    LEFT OUTER JOIN goremal
                        ON     goremal_pidm = pidm
                           AND goremal_status_ind = 'A'
                           AND goremal_preferred_ind = 'Y');

        cur           INTEGER;
        ret           INTEGER;

        --FILE PROCESSING VARIABLES
        v_directory   VARCHAR2 (30) := gv_directory_name;
        v_file_name   VARCHAR2 (30) := 'hr_user_info_core.txt';
    BEGIN
        id :=
            UTL_FILE.fopen (v_directory,
                            v_file_name,
                            'w',
                            20000);

        --  HEADER RECORD
        filedata :=
               'UUUID'
            || v_delim
            || 'First_Name'
            || v_delim
            || 'Last_Name'
            || v_delim
            || 'Middle_Name'
            || v_delim
            || 'Email';

        --output header record
        UTL_FILE.put_line (id, filedata);

        FOR hr_rec IN hr_cur
        LOOP
            BEGIN
                filedata :=
                       hr_rec.user_name
                    || v_delim
                    || hr_rec.user_first_name
                    || v_delim
                    || hr_rec.user_last_name
                    || v_delim
                    || hr_rec.user_middle_name
                    || v_delim
                    || hr_rec.user_email;

                UTL_FILE.put_line (id, filedata);
            EXCEPTION
                WHEN OTHERS
                THEN
                    DBMS_OUTPUT.put_line (
                        'TDEXPORT - Bad row creation in file: ' || SQLERRM);
            END;
        END LOOP;

        UTL_FILE.fclose (id);
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line ('TDEXPORT - UNKNOWN ERROR: ' || SQLERRM);
    END;

    PROCEDURE p_extract_sis_user_info_core
    IS
        v_delim       VARCHAR2 (1) := CHR (9); --ASCII Character horizonal tab

        --PROCESSING VARIABLES
        id            UTL_FILE.file_type;
        filedata      VARCHAR2 (20000);

        CURSOR student_cur IS
            (SELECT SUBSTR (spriden_first_name, 1, 50)        user_first_name,
                    SUBSTR (spriden_last_name, 1, 50)         user_last_name,
                    SUBSTR (spriden_mi, 1, 50)                user_middle_name,
                    spriden_id                                user_name,
                    SUBSTR (goremal_email_address, 1, 250)    user_email,
                    spbpers_birth_date                        user_dob,
                    spbpers_sex                               user_sex,
                    COALESCE (spbpers_confid_ind, 'N')        user_confidentiality
               FROM (SELECT DISTINCT saradap_pidm     pidm
                       FROM saradap                       --admissions records
                      WHERE saradap_term_code_entry IN
                                (SELECT term_code
                                   FROM TABLE (F_LIST_ACTIVETERMS))
                     UNION
                     SELECT DISTINCT sfrstcr_pidm     pidm
                       FROM sfrstcr                     --registration records
                      WHERE sfrstcr_term_code IN
                                (SELECT term_code
                                   FROM TABLE (F_LIST_ACTIVETERMS)))
                    population
                    JOIN spriden
                        ON spriden_pidm = pidm AND spriden_change_ind IS NULL
                    LEFT JOIN spbpers ON spbpers_pidm = pidm
                    LEFT OUTER JOIN goremal
                        ON     goremal_pidm = pidm
                           AND goremal_status_ind = 'A'
                           AND goremal_preferred_ind = 'Y');

        cur           INTEGER;
        ret           INTEGER;

        --FILE PROCESSING VARIABLES
        v_directory   VARCHAR2 (30) := gv_directory_name;
        v_file_name   VARCHAR2 (30) := 'sis_user_info_core.txt';
    BEGIN
        id :=
            UTL_FILE.fopen (v_directory,
                            v_file_name,
                            'w',
                            20000);

        --  HEADER RECORD
        filedata :=
               'UUUID'
            || v_delim
            || 'First_Name'
            || v_delim
            || 'Last_Name'
            || v_delim
            || 'Middle_Name'
            || v_delim
            || 'Email'
            || v_delim
            || 'DOB'
            || v_delim
            || 'Gender'
            || v_delim
            || 'Confidentiality_Indicator';

        --output header record
        UTL_FILE.put_line (id, filedata);

        FOR student_rec IN student_cur
        LOOP
            BEGIN
                filedata :=
                       student_rec.user_name
                    || v_delim
                    || student_rec.user_first_name
                    || v_delim
                    || student_rec.user_last_name
                    || v_delim
                    || student_rec.user_middle_name
                    || v_delim
                    || student_rec.user_email
                    || v_delim
                    || student_rec.user_dob
                    || v_delim
                    || student_rec.user_sex
                    || v_delim
                    || student_rec.user_confidentiality;

                UTL_FILE.put_line (id, filedata);
            EXCEPTION
                WHEN OTHERS
                THEN
                    DBMS_OUTPUT.put_line (
                        'TDEXPORT - Bad row creation in file: ' || SQLERRM);
            END;
        END LOOP;

        UTL_FILE.fclose (id);
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line ('TDEXPORT - UNKNOWN ERROR: ' || SQLERRM);
    END;



    PROCEDURE p_extract_sis_user_info_custom
    IS
        v_delim                      VARCHAR2 (1) := CHR (9); --ASCII Character horizonal tab

        --PROCESSING VARIABLES
        IN_DATA                      UTL_FILE.FILE_TYPE;
        OUT_DATA                     UTL_FILE.FILE_TYPE;

        v_header                     VARCHAR2 (4096)
            :=    'UUUID'
               || v_delim
               || 'Class_Level'
               || v_delim
               || 'Academic_Level'
               || v_delim
               || 'Country_of_Citizenship'
               || v_delim
               || 'Visa_Status'
               || v_delim
               || 'Cell_Number'
               || v_delim
               || 'Cumulative_GPA'
               || v_delim
               || 'Financial_Hold'
               || v_delim
               || 'Academic_Hold'
               || v_delim
               || 'Major_1'
               || v_delim
               || 'Major_2'
               || v_delim
               || 'Option_1'
               || v_delim
               || 'Option_2'
               || v_delim
               || 'Expected_Graduation_Date'
               || v_delim
               || 'Preferred_Name'
               || v_delim
               || 'Emergency_Contact'
               -- || v_delim
               -- || 'Campus Address'
               -- || v_delim
               -- || 'Permanent Address'
               || v_delim
               || 'Campus_Address_Line_1'
               || v_delim
               || 'Campus_Address_Line_2'
               || v_delim
               || 'Campus_Address_Line_3'
               || v_delim
               || 'Campus_City'
               || v_delim
               || 'Campus_State'
               || v_delim
               || 'Campus_Zip'
               || v_delim
               || 'Campus_Country'
               || v_delim
               || 'Perm_Address_Line_1'
               || v_delim
               || 'Perm_Address_Line_2'
               || v_delim
               || 'Perm_Address_Line_3'
               || v_delim
               || 'Perm_City'
               || v_delim
               || 'Perm_State'
               || v_delim
               || 'Perm_Zip'
               || v_delim
               || 'Perm_Country';


        v_in_file_name               VARCHAR2 (30) := 'studyabroad_usu_edu_pool.txt';
        --getting specifc filename from chelsey
        v_out_file_name              VARCHAR2 (30) := 'sis_user_info_custom.txt';

        v_filedata                   VARCHAR2 (32767);
        v_newline                    VARCHAR2 (256);
        v_rec_count                  NUMBER (6) := 0;
        --v_update_count               NUMBER (6) := 0;

        --EXTRACT VARIABLES
        v_term_code                  VARCHAR2 (6) := CASANDRA.F_FETCH_TERM;
        v_pidm                       spriden.spriden_pidm%TYPE;
        v_UUUID                      spriden.spriden_id%TYPE;
        v_Class_Level                VARCHAR2 (2);
        v_Academic_Level             VARCHAR2 (2);

        v_Country_of_Citizenship     VARCHAR2 (64);
        v_Visa_Status                VARCHAR2 (64);

        v_Cell_Number                VARCHAR2 (64);
        v_Cumulative_GPA             VARCHAR2 (64);
        v_Financial_Hold             VARCHAR2 (64);
        v_Academic_Hold              VARCHAR2 (64);

        v_Major_1                    VARCHAR2 (64);
        v_Major_2                    VARCHAR2 (64);
        v_Option_1                   VARCHAR2 (64);
        v_Option_2                   VARCHAR2 (64);
        v_Expected_Graduation_Date   DATE;
        v_Prefered_Name              VARCHAR2 (128);

        v_Emergency_Contact          VARCHAR2 (512);
        --v_Campus_Address             VARCHAR2 (512);
        --v_Permanent_Address          VARCHAR2 (512);

        v_Campus_Address_Line_1      VARCHAR2 (75);
        v_Campus_Address_Line_2      VARCHAR2 (75);
        v_Campus_Address_Line_3      VARCHAR2 (75);
        v_Campus_City                VARCHAR2 (50);
        v_Campus_State               VARCHAR2 (3);
        v_Campus_Zip                 VARCHAR2 (30);
        v_Campus_Country             VARCHAR2 (50);
        v_Perm_Address_Line_1        VARCHAR2 (75);
        v_Perm_Address_Line_2        VARCHAR2 (75);
        v_Perm_Address_Line_3        VARCHAR2 (75);
        v_Perm_City                  VARCHAR2 (50);
        v_Perm_State                 VARCHAR2 (3);
        v_Perm_Zip                   VARCHAR2 (30);
        v_Perm_Country               VARCHAR2 (50);
    BEGIN
        IN_DATA :=
            UTL_FILE.FOPEN (gv_directory_name,
                            v_in_file_name,
                            'r',
                            32767);

        OUT_DATA :=
            UTL_FILE.FOPEN (gv_directory_name,
                            v_out_file_name,
                            'w',
                            32767);

        UTL_FILE.PUT_LINE (OUT_DATA, v_header);

        IF UTL_FILE.is_open (IN_DATA)
        THEN
            LOOP
                BEGIN
                    --FileReadPhase
                    UTL_FILE.GET_LINE (IN_DATA, v_filedata, 256);
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        DBMS_OUTPUT.PUT_LINE (
                            'STATUS - End of File or No Data Found');
                        --   || SUBSTR (SQLERRM, 1, 200));
                        --GOTO finish_process;
                        EXIT;
                    WHEN OTHERS
                    THEN
                        DBMS_OUTPUT.PUT_LINE (
                               'ERROR - Unhandeled Exception in FileReadPhase '
                            || SUBSTR (SQLERRM, 1, 200));
                END;

                BEGIN
                    v_newline := SUBSTR (v_filedata, 1, 256);

                    IF v_newline IS NULL
                    THEN
                        EXIT;
                    END IF;

                    --remove possible line feed from end of v_newline
                    v_newline := TRIM (CHR (13) FROM v_newline);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        DBMS_OUTPUT.PUT_LINE (
                               'ERROR - Unhandeled Exception in NewLinePhase '
                            || SUBSTR (SQLERRM, 1, 200));
                END;

                BEGIN
                    --BannerSearchPhase

                    --get student pidm
                    SELECT spriden_id, spriden_pidm
                      INTO v_UUUID, v_pidm
                      FROM spriden
                     WHERE     spriden_change_ind IS NULL
                           AND UPPER (spriden_id) = UPPER (v_newline);
                EXCEPTION
                    WHEN VALUE_ERROR
                    THEN
                        DBMS_OUTPUT.PUT_LINE (
                               'ERROR - Error in parameters '
                            || SUBSTR (SQLERRM, 1, 200));
                        v_pidm := NULL;
                        v_UUUID := NULL;
                    WHEN NO_DATA_FOUND
                    THEN
                        DBMS_OUTPUT.PUT_LINE (
                               'ERROR - student PIDM not found for '
                            || UPPER (v_newline));
                        v_pidm := NULL;
                        v_UUUID := NULL;
                    WHEN TOO_MANY_ROWS
                    THEN
                        DBMS_OUTPUT.PUT_LINE (
                               'ERROR - Multiple PIDMs'
                            || SUBSTR (SQLERRM, 1, 200));
                        v_pidm := NULL;
                        v_UUUID := NULL;
                    WHEN OTHERS
                    THEN
                        DBMS_OUTPUT.PUT_LINE (
                               'ERROR - Unhandeled Exception in BannerSearchPhase'
                            || SUBSTR (SQLERRM, 1, 200));
                END;

                --set variables
                IF v_pidm IS NOT NULL
                THEN
                    v_Academic_Level := f_student_level (v_pidm, v_term_code);
                    v_Class_Level :=
                        f_class_calc_fnc (v_pidm,
                                          v_Academic_Level,
                                          CASANDRA.F_FETCH_TERM);

                    v_Country_of_Citizenship :=
                        F_GET_DESC ('STVNATN', f_student_natn (v_pidm));
                    v_Visa_Status := f_student_visa (v_pidm);

                    v_Cell_Number :=
                        f_student_phone (p_pidm        => v_pidm,
                                         p_tele_code   => 'MOB');

                    v_Cumulative_GPA :=
                        f_parse (f_concat_as_of_cum_gpa (v_pidm,
                                                         v_term_code,
                                                         v_Academic_Level,
                                                         'O'),
                                 5,
                                 '{');

                    v_Financial_Hold := f_holds_financial (v_pidm);
                    v_Academic_Hold := f_holds_academic (v_pidm);

                    v_Expected_Graduation_Date :=
                        f_student_record (v_pidm,
                                          v_term_code,
                                          v_Major_1,
                                          v_Major_2);

                    --v_Major_1 := v_Major_1;
                    --v_Major_2 := v_Major_2;

                    v_Option_1 := f_student_resd (v_pidm, v_term_code);
                    v_Option_2 :=
                        f_get_desc_fnc (
                            'STVCAMP',
                            z_campus_magic_q.f_calc_majority_campus_code (
                                v_term_code,
                                v_pidm),
                            30);

                    v_Prefered_Name :=
                        BANINST1.z_f_get_preferred_name (v_pidm, 'FL');
                    v_Emergency_Contact := f_student_emergency (v_pidm);

                    p_student_address (v_pidm,
                                       'MA',
                                       NULL,
                                       v_Campus_Address_Line_1,
                                       v_Campus_Address_Line_2,
                                       v_Campus_Address_Line_3,
                                       v_Campus_City,
                                       v_Campus_State,
                                       v_Campus_Zip,
                                       v_Campus_Country);

                    v_Campus_Country :=
                        F_GET_DESC ('STVNATN', v_Campus_Country);

                    p_student_address (v_pidm,
                                       'PR',
                                       NULL,
                                       v_Perm_Address_Line_1,
                                       v_Perm_Address_Line_2,
                                       v_Perm_Address_Line_3,
                                       v_Perm_City,
                                       v_Perm_State,
                                       v_Perm_Zip,
                                       v_Perm_Country);

                    v_Perm_Country := F_GET_DESC ('STVNATN', v_Perm_Country);

                    BEGIN
                        v_filedata :=
                               v_UUUID
                            || v_delim
                            || v_Class_Level
                            || v_delim
                            || v_Academic_Level
                            || v_delim
                            || v_Country_of_Citizenship
                            || v_delim
                            || v_Visa_Status
                            || v_delim
                            || v_Cell_Number
                            || v_delim
                            || v_Cumulative_GPA
                            || v_delim
                            || v_Financial_Hold
                            || v_delim
                            || v_Academic_Hold
                            || v_delim
                            || v_Major_1
                            || v_delim
                            || v_Major_2
                            || v_delim
                            || v_Option_1
                            || v_delim
                            || v_Option_2
                            || v_delim
                            || v_Expected_Graduation_Date
                            || v_delim
                            || v_Prefered_Name
                            || v_delim
                            || v_Emergency_Contact
                            -- || v_delim
                            -- || v_Campus_Address
                            -- || v_delim
                            -- || v_Permanent_Address
                            || v_delim
                            || v_Campus_Address_Line_1
                            || v_delim
                            || v_Campus_Address_Line_2
                            || v_delim
                            || v_Campus_Address_Line_3
                            || v_delim
                            || v_Campus_City
                            || v_delim
                            || v_Campus_State
                            || v_delim
                            || v_Campus_Zip
                            || v_delim
                            || v_Campus_Country
                            || v_delim
                            || v_Perm_Address_Line_1
                            || v_delim
                            || v_Perm_Address_Line_2
                            || v_delim
                            || v_Perm_Address_Line_3
                            || v_delim
                            || v_Perm_City
                            || v_delim
                            || v_Perm_State
                            || v_delim
                            || v_Perm_Zip
                            || v_delim
                            || v_Perm_Country;

                        UTL_FILE.put_line (OUT_DATA, v_filedata);
                        v_rec_count := v_rec_count + 1;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            DBMS_OUTPUT.put_line (
                                   'TDEXPORT - Bad row creation in file: '
                                || SQLERRM);
                    END;
                END IF;
            END LOOP;

           <<finish_process>>
            DBMS_OUTPUT.PUT_LINE (
                'STATUS - Total Records Processed - ' || v_rec_count);

            UTL_FILE.FCLOSE (IN_DATA);
            UTL_FILE.FCLOSE (OUT_DATA);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                'TDEXPORT - Unhandeled Exception Out of Phase: ' || SQLERRM);
    END;



    PROCEDURE p_applications_manager
    AS
    BEGIN
        p_extract_sis_user_info_core;
        p_extract_hr_user_info_core;
        p_extract_sis_user_info_custom;
    END;

    /**
    * Translates the Banner suffix field to a TD accepted value
    *
    * Name Suffix
    * SEVIS-Required Codes Code Description
    * I First
    * II Second
    * III Third
    * IV Fourth
    * Jr. Junior
    * Sr. Senior
    *
    * @param    p_name_suffix   Banner suffix to parse
    * @return   rtn_td_suffix   TD acceptable suffix value
    */
    FUNCTION f_isss_translate_suffix (
        p_name_suffix   spbpers.spbpers_name_suffix%TYPE)
        RETURN VARCHAR2
    AS
        lv_td_suffix   VARCHAR2 (5);
    BEGIN
        lv_td_suffix :=
            CASE
                WHEN p_name_suffix IS NULL
                THEN
                    NULL
                WHEN TRIM (UPPER (p_name_suffix)) IN ('I', '1', '1ST')
                THEN
                    'I'
                WHEN TRIM (UPPER (p_name_suffix)) IN ('II',
                                                      '11',
                                                      '2',
                                                      '2ND')
                THEN
                    'II'
                WHEN TRIM (UPPER (p_name_suffix)) IN ('III',
                                                      '111',
                                                      '3',
                                                      '3RD')
                THEN
                    'III'
                WHEN TRIM (UPPER (p_name_suffix)) IN ('IV', '4', '4TH')
                THEN
                    'IV'
                WHEN TRIM (UPPER (p_name_suffix)) IN ('JR',
                                                      'J R',
                                                      'JR.',
                                                      'JUN',
                                                      'JUN.',
                                                      'JUNIOR')
                THEN
                    'Jr.'
                WHEN TRIM (UPPER (p_name_suffix)) IN ('SR',
                                                      'S R',
                                                      'SR.',
                                                      'SEN',
                                                      'SEN.',
                                                      'SENIOR')
                THEN
                    'Sr.'
                ELSE
                    NULL
            END;

        RETURN lv_td_suffix;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Translating Name Suffix: '
                || SQLERRM);
            RAISE;
    END f_isss_translate_suffix;


    /**
    * Translates the Banner level_code to a TD accepted value
    *
    * Undergraduate Level
    * SEVIS-Required Codes Code Description
    * 01 Freshman/First Year
    * 02 Sophomore
    * 03 Junior
    * 04 Senior
    * 05 Undergraduate, Unspecified
    * 06 Undergraduate Non-Degree Seeking
    *
    * @param    p_banner_class_code   Banner class code to parse
    * @return   rtn_td_ug_level       TD acceptable undergraduate level code
    */
    FUNCTION f_isss_translate_ug_level (p_banner_class_code VARCHAR2)
        RETURN VARCHAR2
    AS
        rtn_td_ug_level   VARCHAR2 (5);
    BEGIN
        rtn_td_ug_level :=
            CASE
                WHEN p_banner_class_code IS NULL THEN NULL
                WHEN p_banner_class_code = 'GR' THEN NULL
                WHEN p_banner_class_code = 'FR' THEN '01'
                WHEN p_banner_class_code = 'SO' THEN '02'
                WHEN p_banner_class_code = 'JR' THEN '03'
                WHEN p_banner_class_code = 'SR' THEN '04'
                ELSE '05'
            END;

        RETURN rtn_td_ug_level;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Translating Undergraduate Level: '
                || SQLERRM);
            RAISE;
    END f_isss_translate_ug_level;

    /**
    * Translates the Banner degree_code to a TD accepted education level
    *
    * Education Level
    * SEVIS-Required Codes Code Description
    * 03 Associate's
    * 04 Bachelor's
    * 05 Master's
    * 06 Doctorate
    * 07 Language training
    * 08 High school
    * 09 Flight school
    * 10 Vocational school
    * 11 Other
    *
    * @param    p_banner_degree_code     Banner degree code to parse
    * @return   rtn_td_education_level   TD acceptable education level code
    */
    FUNCTION f_isss_translate_ed_level (p_banner_degree_code VARCHAR2)
        RETURN VARCHAR2
    AS
        const_xlbl_code   CONSTANT VARCHAR2 (7) := 'TDXDEGC';
        rtn_td_ed_level            VARCHAR2 (2);
    BEGIN
        SELECT sorxref_edi_value     sevis_education_level
          INTO rtn_td_ed_level
          FROM sorxref
         WHERE     sorxref_xlbl_code = const_xlbl_code
               AND sorxref_banner_value = p_banner_degree_code;

        RETURN rtn_td_ed_level;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            rtn_td_ed_level := NULL;
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - No SOAXREF (TDXDEGC) value found for Banner Degree Code '
                || p_banner_degree_code);
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Translating Undergraduate Level: '
                || SQLERRM);
            RAISE;
    END f_isss_translate_ed_level;

    /**
    * Retrieves the TD translated SEVIS-Required Code
    *
    * Visa Type
    * SEVIS-Required Codes Code Description
    * 01 F-1
    * 04 F-2
    * 03 J-1
    * 06 J-2
    * 02 M-1
    * 05 M-2
    *
    * When the visa type code is any other type, the code is returned untranslated.
    *
    * @param    p_pidm     student pidm for lookup
    * @return   rtn_visa   TD acceptable SEVIS visa code
    */
    FUNCTION f_isss_visa (p_pidm gorvisa.gorvisa_pidm%TYPE)
        RETURN VARCHAR2
    IS
        rtn_visa   VARCHAR2 (2);
    BEGIN
        SELECT DECODE (gorvisa_vtyp_code,
                       'F1', '01',
                       'F2', '04',
                       'J1', '03',
                       'J2', '06',
                       gorvisa_vtyp_code)
          INTO rtn_visa
          FROM gorvisa
         WHERE     gorvisa_pidm = p_pidm
               AND gorvisa_seq_no = (SELECT MAX (bravo.gorvisa_seq_no)
                                       FROM gorvisa bravo
                                      WHERE bravo.gorvisa_pidm = p_pidm);

        RETURN rtn_visa;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving ISSS Visa: '
                || SQLERRM);
            RAISE;
    END f_isss_visa;

    /**
    * Retrieves the time status for a given term
    *
    * @param    p_pidm            student pidm for lookup
    * @param    p_term_code       term code for lookup
    * @return   rtn_time_status   time status code and description
    */
    FUNCTION f_student_time_status (
        p_pidm        sfrthst.sfrthst_pidm%TYPE,
        p_term_code   sfrthst.sfrthst_term_code%TYPE)
        RETURN VARCHAR2
    IS
        rtn_time_status   VARCHAR2 (2);
    BEGIN
        SELECT sfrthst_tmst_code || ' - ' || stvtmst_desc
          INTO rtn_time_status
          FROM sfrthst JOIN stvtmst ON sfrthst_tmst_code = stvtmst_code
         WHERE     sfrthst_pidm = p_pidm
               AND sfrthst_tmst_date =
                   (SELECT MAX (foxtrot.sfrthst_tmst_date)
                      FROM sfrthst foxtrot
                     WHERE     foxtrot.sfrthst_pidm = sfrthst.sfrthst_pidm
                           AND foxtrot.sfrthst_term_code = p_term_code);


        RETURN rtn_time_status;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Time Status: '
                || SQLERRM);
            RAISE;
    END f_student_time_status;

    /**
    * Retrieves date from graduation application
    *
    * @param    p_pidm              student pidm for lookup
    * @param    p_date              date for lookup
    * @return   rtn_exp_grad_date   date for graduation
    */
    FUNCTION f_student_grad_date (
        p_pidm   shrdgmr.shrdgmr_pidm%TYPE,
        p_date   shrdgmr.shrdgmr_grad_date%TYPE DEFAULT SYSDATE)
        RETURN DATE
    IS
        rtn_exp_grad_date   VARCHAR2 (1);
    BEGIN
        SELECT MIN (shrdgmr_grad_date)
          INTO rtn_exp_grad_date
          FROM shrdgmr
         WHERE shrdgmr_pidm = p_pidm AND shrdgmr_grad_date >= SYSDATE;

        RETURN rtn_exp_grad_date;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Graduation Date: '
                || SQLERRM);
            RAISE;
    END f_student_grad_date;

    /**
    * Retrieves academic standing
    *
    * @param    p_pidm                  student pidm for lookup
    * @param    p_term_code             term_code for lookup
    * @return   rtn_academic_standing   most recent standing since term_code
    */
    FUNCTION f_student_academic_standing (
        p_pidm        shrttrm.shrttrm_pidm%TYPE,
        p_term_code   shrttrm.shrttrm_term_code%TYPE)
        RETURN VARCHAR2
    IS
        rtn_academic_standing   VARCHAR2 (128);
    BEGIN
        SELECT shrttrm_astd_code_end_of_term || ' - ' || stvastd_desc
          INTO rtn_academic_standing
          FROM shrttrm
               LEFT JOIN stvastd
                   ON shrttrm_astd_code_end_of_term = stvastd_code
         WHERE     shrttrm_pidm = p_pidm
               AND shrttrm_term_code =
                   (SELECT MAX (golf.shrttrm_term_code)
                      FROM shrttrm golf
                     WHERE     golf.shrttrm_term_code <= p_term_code
                           AND golf.shrttrm_pidm = shrttrm.shrttrm_pidm);

        RETURN rtn_academic_standing;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving Academic Standing: '
                || SQLERRM);
            RAISE;
    END f_student_academic_standing;

    /**
    * Retrieves the credit count for all classes in term
    *
    * @param    p_pidm             student pidm for lookup
    * @param    p_term_code        term code for lookup
    * @return   rtn_credit_count   count of credits
    */
    FUNCTION f_credits_term_total (
        p_pidm        sfrstcr.sfrstcr_pidm%TYPE,
        p_term_code   sfrstcr.sfrstcr_term_code%TYPE)
        RETURN NUMBER
    IS
        rtn_credit_count   NUMBER (7, 3);
    BEGIN
        SELECT COALESCE (SUM (sfrstcr_credit_hr), 0)     credit_hours_total
          INTO rtn_credit_count
          FROM sfrstcr
               JOIN ssbsect
                   ON     ssbsect_crn = sfrstcr_crn
                      AND ssbsect_term_code = sfrstcr_term_code
         WHERE     sfrstcr_term_code = p_term_code
               AND sfrstcr_rsts_code IN (SELECT stvrsts_code
                                           FROM stvrsts
                                          WHERE stvrsts_incl_sect_enrl = 'Y')
               AND sfrstcr_pidm = p_pidm;

        RETURN rtn_credit_count;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving credit count: '
                || SQLERRM);
            RAISE;
    END f_credits_term_total;

    /**
    * Retrieves the credit count for main campus classes in term
    *
    * @param    p_pidm             student pidm for lookup
    * @param    p_term_code        term code for lookup
    * @return   rtn_credit_count   count of credits
    */
    FUNCTION f_credits_campus (p_pidm        sfrstcr.sfrstcr_pidm%TYPE,
                               p_term_code   sfrstcr.sfrstcr_term_code%TYPE)
        RETURN NUMBER
    IS
        rtn_credit_count   NUMBER (7, 3);
    BEGIN
        SELECT COALESCE (SUM (sfrstcr_credit_hr), 0)     credit_hours_online
          INTO rtn_credit_count
          FROM sfrstcr
               JOIN ssbsect
                   ON     ssbsect_crn = sfrstcr_crn
                      AND ssbsect_term_code = sfrstcr_term_code
         WHERE     sfrstcr_term_code = p_term_code
               AND sfrstcr_rsts_code IN (SELECT stvrsts_code
                                           FROM stvrsts
                                          WHERE stvrsts_incl_sect_enrl = 'Y')
               AND ssbsect_camp_code = 'M' --campus_code for Logan Main Campus
               AND sfrstcr_pidm = p_pidm;

        RETURN rtn_credit_count;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving credit count: '
                || SQLERRM);
            RAISE;
    END f_credits_campus;

    /**
    * Retrieves the credit count for online classes in term
    *
    * @param    p_pidm             student pidm for lookup
    * @param    p_term_code        term code for lookup
    * @return   rtn_credit_count   count of credits
    */
    FUNCTION f_credits_online (p_pidm        sfrstcr.sfrstcr_pidm%TYPE,
                               p_term_code   sfrstcr.sfrstcr_term_code%TYPE)
        RETURN NUMBER
    IS
        rtn_credit_count   NUMBER (7, 3);
    BEGIN
        SELECT COALESCE (SUM (sfrstcr_credit_hr), 0)     credit_hours_online
          INTO rtn_credit_count
          FROM sfrstcr
               JOIN ssbsect
                   ON     ssbsect_crn = sfrstcr_crn
                      AND ssbsect_term_code = sfrstcr_term_code
         WHERE     sfrstcr_term_code = p_term_code
               AND sfrstcr_rsts_code IN (SELECT stvrsts_code
                                           FROM stvrsts
                                          WHERE stvrsts_incl_sect_enrl = 'Y')
               AND ssbsect_insm_code IN ('I', 'WB', 'XO')
               AND sfrstcr_pidm = p_pidm;

        RETURN rtn_credit_count;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving credit count: '
                || SQLERRM);
            RAISE;
    END f_credits_online;

    /**
    * Retrieves the credit count for ieli classes in term
    *
    * @param    p_pidm             student pidm for lookup
    * @param    p_term_code        term code for lookup
    * @return   rtn_credit_count   count of credits
    */
    FUNCTION f_credits_esl (p_pidm        sfrstcr.sfrstcr_pidm%TYPE,
                            p_term_code   sfrstcr.sfrstcr_term_code%TYPE)
        RETURN NUMBER
    IS
        rtn_credit_count   NUMBER (7, 3);
    BEGIN
        SELECT COALESCE (SUM (sfrstcr_credit_hr), 0)     credit_hours_ieli
          INTO rtn_credit_count
          FROM sfrstcr
               JOIN ssbsect
                   ON     ssbsect_crn = sfrstcr_crn
                      AND ssbsect_term_code = sfrstcr_term_code
         WHERE     sfrstcr_term_code = p_term_code
               AND sfrstcr_rsts_code IN (SELECT stvrsts_code
                                           FROM stvrsts
                                          WHERE stvrsts_incl_sect_enrl = 'Y')
               AND ssbsect_subj_code = 'IELI'
               AND sfrstcr_pidm = p_pidm;

        RETURN rtn_credit_count;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.PUT_LINE (
                   'ERROR - Unhandeled Exception Retrieving credit count: '
                || SQLERRM);
            RAISE;
    END f_credits_esl;

    /**
    * Extracts International Student data for use by Terra Dotta ISSS
    */
    PROCEDURE p_isss_extract_sis_user_info (
        p_override_term   VARCHAR2 DEFAULT NULL)
    IS
        v_delim                         VARCHAR2 (1) := CHR (9); --ASCII Character horizonal tab

        --PROCESSING VARIABLES
        id                              UTL_FILE.file_type;
        filedata                        VARCHAR2 (20000);

        CURSOR student_cur IS
            (SELECT spriden_pidm
                        pidm,
                    spriden_id
                        UUUID,
                    SUBSTR (spriden_last_name, 1, 50)
                        LAST_NAME,
                    SUBSTR (spriden_first_name, 1, 50)
                        FIRST_NAME,
                    SUBSTR (spriden_mi, 1, 50)
                        MIDDLE_NAME,
                    SUBSTR (goremal_email_address, 1, 250)
                        EMAIL,
                    TO_CHAR (spbpers_birth_date, 'mm/dd/yyyy')
                        DOB,
                    DECODE (spbpers_sex,  'M', 'M',  'F', 'F',  'O')
                        GENDER,
                    COALESCE (spbpers_confid_ind, 'N')
                        CONFIDENTIALITY_IND,
                    spbpers_name_suffix
                        banner_suffix,
                    (SELECT stvnatn_sevis_equiv
                       FROM stvnatn
                      WHERE stvnatn_code = gobintl_natn_code_birth)
                        BIRTH_COUNTRY,
                    (SELECT stvnatn_sevis_equiv
                       FROM stvnatn
                      WHERE stvnatn_code = gobintl_natn_code_legal)
                        CITIZENSHIP_COUNTRY,
                    (SELECT stvnatn_sevis_equiv
                       FROM stvnatn
                      WHERE stvnatn_code = gobintl_natn_code_legal)
                        PERM_RESIDENT_COUNTRY,
                    spriden_id
                        STUDENT_ID,
                    spbpers_mrtl_code
                        banner_mrtl_code,
                    spbpers_pref_first_name
                        PREFERRED_NAME,
                    spbpers_gndr_code
                        PREFERRED_GENDER,
                    CASE
                        WHEN gobintl_spon_code IS NOT NULL
                        THEN
                            gobintl_spon_code || ' - ' || stvspon_desc
                        ELSE
                            NULL
                    END
                        CUSTOM3,                                     --sponspr
                    gobintl_spouse_ind
                        CUSTOM4,                                      --spouse
                    gobintl_child_number
                        CUSTOM5,                                    --children
                    spbpers_citz_code || ' - ' || stvcitz_desc
                        CUSTOM8                                  --citizenship
               FROM (SELECT DISTINCT saradap_pidm     pidm
                       FROM saradap                       --admissions records
                      WHERE saradap_term_code_entry IN
                                (SELECT term_code
                                   FROM TABLE (F_LIST_ACTIVETERMS))
                     UNION
                     SELECT DISTINCT sfrstcr_pidm     pidm
                       FROM sfrstcr                     --registration records
                      WHERE sfrstcr_term_code IN
                                (SELECT term_code
                                   FROM TABLE (F_LIST_ACTIVETERMS)))
                    population
                    JOIN spriden
                        ON spriden_pidm = pidm AND spriden_change_ind IS NULL
                    LEFT JOIN spbpers ON spbpers_pidm = pidm
                    LEFT JOIN goremal
                        ON     goremal_pidm = pidm
                           AND goremal_status_ind = 'A'
                           AND goremal_preferred_ind = 'Y'
                    LEFT JOIN gobintl ON gobintl_pidm = pidm
                    LEFT JOIN stvspon ON gobintl_spon_code = stvspon_code
                    LEFT JOIN saradap
                        ON     saradap_pidm = pidm
                           AND saradap_appl_date =
                               (SELECT MAX (bravo.saradap_appl_date)
                                  FROM saradap bravo
                                 WHERE bravo.saradap_pidm =
                                       saradap.saradap_pidm)
                    LEFT JOIN stvcitz ON spbpers_citz_code = stvcitz_code
              WHERE     SARADAP_RESD_CODE = 'I'
                    OR GOBINTL_NATN_CODE_LEGAL <> 'US');

        cur                             INTEGER;
        ret                             INTEGER;

        --FILE PROCESSING VARIABLES
        v_directory                     VARCHAR2 (30) := gv_directory_name;
        v_file_name                     VARCHAR2 (30) := 'sis_user_info.txt';

        --EXTRACT VARIABLES
        --lv_UUUID                        spriden.spriden_id%TYPE;
        --lv_LAST_NAME                    VARCHAR2 (50);
        --lv_FIRST_NAME                   VARCHAR2 (50);
        --lv_MIDDLE_NAME                  VARCHAR2 (50);
        --lv_EMAIL                        VARCHAR2 (250);
        --lv_DOB                          DATE;
        --lv_GENDER                       VARCHAR2 (1);
        --lv_CONFIDENTIALITY_IND          VARCHAR2 (1);
        lv_HR_FLAG                      VARCHAR2 (1) := NULL; --TODO: work with Steven Clark to determine HR flag
        lv_SUFFIX                       VARCHAR2 (10);
        lv_VISA_TYPE                    VARCHAR2 (2);
        lv_MAJOR_CIP                    VARCHAR2 (7);
        lv_SECOND_MAJOR_CIP             VARCHAR2 (7);
        lv_MINOR_CIP                    VARCHAR2 (7);
        lv_EDUCATION_LEVEL              VARCHAR2 (2);
        --lv_BIRTH_COUNTRY                VARCHAR2 (2);
        --lv_CITIZENSHIP_COUNTRY          VARCHAR2 (2);
        lv_FOREIGN_PHONE_COUNTRY_CODE   VARCHAR2 (4) := NULL;
        lv_FOREIGN_PHONE                VARCHAR2 (20) := NULL;
        lv_US_PHONE                     VARCHAR2 (10);
        --lv_PERM_RESIDENT_COUNTRY        VARCHAR2 (2);

        lv_US_ADDRESS_LINE1             VARCHAR2 (64);
        lv_US_ADDRESS_LINE2             VARCHAR2 (64);
        lv_US_ADDRESS_CITY              VARCHAR2 (50);
        lv_US_ADDRESS_STATE             VARCHAR2 (2);
        lv_US_ADDRESS_ZIP               VARCHAR2 (5);
        lv_FOREIGN_ADDRESS_LINE1        VARCHAR2 (64);
        lv_FOREIGN_ADDRESS_LINE2        VARCHAR2 (64);
        lv_FOREIGN_ADDRESS_CITY         VARCHAR2 (50);
        lv_FOREIGN_ADDRESS_PROVINCE     VARCHAR2 (2);
        lv_FOREIGN_ADDRESS_POSTALCODE   VARCHAR2 (20);
        lv_FOREIGN_ADDRESS_COUNTRY      VARCHAR2 (2);
        lv_US_MAILING_ADDRESS_LINE1     VARCHAR2 (64);
        lv_US_MAILING_ADDRESS_LINE2     VARCHAR2 (64);
        lv_US_MAILING_ADDRESS_CITY      VARCHAR2 (50);
        lv_US_MAILING_ADDRESS_STATE     VARCHAR2 (2);
        lv_US_MAILING_ADDRESS_ZIP       VARCHAR2 (5);

        lv_MAJOR1_DEPT                  VARCHAR2 (500);
        lv_MAJOR2_DEPT                  VARCHAR2 (500) := NULL;
        lv_MAJOR1_DESC                  VARCHAR2 (500);
        lv_MAJOR2_DESC                  VARCHAR2 (500);
        lv_MINOR_DEPT                   VARCHAR2 (500) := NULL;
        lv_MINOR_DESC                   VARCHAR2 (500);
        lv_ENROLL_COLLEGE               VARCHAR2 (500);
        --lv_STUDENT_ID                   VARCHAR2 (500);
        lv_ADVISOR_NAME                 VARCHAR2 (500);
        lv_ADVISOR_EMAIL                VARCHAR2 (500);
        lv_LANGUAGE_TEST1               VARCHAR2 (500);                 --TODO
        lv_LANGUAGE_TEST2               VARCHAR2 (500);                 --TODO
        lv_CREDITS_TOTAL                NUMBER (11, 3);
        lv_CREDITS_CAMPUS               NUMBER (11, 3);
        lv_CREDITS_ONLINE               NUMBER (11, 3);
        lv_CREDITS_ESL                  NUMBER (11, 3);
        lv_FULL_TIME                    VARCHAR2 (500);
        lv_CREDITS_TERM                 VARCHAR2 (6) := CASANDRA.F_FETCH_TERM;
        lv_CREDITS_EARNED               NUMBER (11, 3);
        lv_UNDERGRAD_LEVEL              VARCHAR2 (2);
        lv_APPLIED_GRADUATION           VARCHAR2 (1);
        lv_GRAD_DATE                    DATE;
        lv_ACADEMIC_DEFICIENCY          VARCHAR2 (500);
        lv_FINANCIAL_HOLD               VARCHAR2 (64);
        lv_CONDUCT_HOLD                 VARCHAR2 (64);
        lv_CUM_GPA                      shrlgpa.SHRLGPA_GPA%TYPE;
        lv_ADMIT_TERM                   VARCHAR2 (500);
        lv_MARITAL_STATUS               VARCHAR2 (500);
        --lv_PREFERRED_NAME               VARCHAR2 (500);
        --lv_PREFERRED_GENDER             VARCHAR2 (500);
        lv_CUSTOM1                      VARCHAR2 (500);
        lv_CUSTOM2                      VARCHAR2 (500); --TODO work with Steven Clark to determine HR fields
        --lv_CUSTOM3                      VARCHAR2 (500);
        --lv_CUSTOM4                      VARCHAR2 (500);
        --lv_CUSTOM5                      VARCHAR2 (500);
        lv_CUSTOM6                      VARCHAR2 (500);
        lv_CUSTOM7                      VARCHAR2 (500);
        --lv_CUSTOM8                      VARCHAR2 (500);
        lv_CUSTOM9                      VARCHAR2 (500);
        --lv_CUSTOM10                     VARCHAR2 (500);

        --processing variables
        lv_term_code                    VARCHAR2 (6);
        --lv_pidm                         spriden.spriden_pidm%TYPE;
        lv_banner_line3                 VARCHAR2 (64);
        lv_banner_country               VARCHAR2 (64);
        lv_banner_level_code            VARCHAR2 (64);
        lv_banner_class_code            VARCHAR2 (64);
        lv_banner_degree_code           VARCHAR2 (64);
        lv_banner_exp_grad_date         DATE;
        lv_banner_app_grad_date         DATE;
    BEGIN
        id :=
            UTL_FILE.fopen (v_directory,
                            v_file_name,
                            'w',
                            20000);

        --  HEADER RECORD
        filedata :=
               'UUUID'
            || v_delim
            || 'LAST_NAME'
            || v_delim
            || 'FIRST_NAME'
            || v_delim
            || 'MIDDLE_NAME'
            || v_delim
            || 'EMAIL'
            || v_delim
            || 'DOB'
            || v_delim
            || 'GENDER'
            || v_delim
            || 'CONFIDENTIALITY_IND'
            || v_delim
            || 'HR_FLAG'
            || v_delim
            || 'SUFFIX'
            || v_delim
            || 'VISA_TYPE'
            || v_delim
            || 'MAJOR_CIP'
            || v_delim
            || 'SECOND_MAJOR_CIP'
            || v_delim
            || 'MINOR_CIP'
            || v_delim
            || 'EDUCATION_LEVEL'
            || v_delim
            || 'BIRTH_COUNTRY'
            || v_delim
            || 'CITIZENSHIP_COUNTRY'
            || v_delim
            || 'FOREIGN_PHONE_COUNTRY_CODE'
            || v_delim
            || 'FOREIGN_PHONE'
            || v_delim
            || 'US_PHONE'
            || v_delim
            || 'PERM_RESIDENT_COUNTRY'
            || v_delim
            || 'US_ADDRESS_LINE1'
            || v_delim
            || 'US_ADDRESS_LINE2'
            || v_delim
            || 'US_ADDRESS_CITY'
            || v_delim
            || 'US_ADDRESS_STATE'
            || v_delim
            || 'US_ADDRESS_ZIP'
            || v_delim
            || 'FOREIGN_ADDRESS_LINE1'
            || v_delim
            || 'FOREIGN_ADDRESS_LINE2'
            || v_delim
            || 'FOREIGN_ADDRESS_CITY'
            || v_delim
            || 'FOREIGN_ADDRESS_PROVINCE'
            || v_delim
            || 'FOREIGN_ADDRESS_POSTALCODE'
            || v_delim
            || 'FOREIGN_ADDRESS_COUNTRY'
            || v_delim
            || 'US_MAILING_ADDRESS_LINE1'
            || v_delim
            || 'US_MAILING_ADDRESS_LINE2'
            || v_delim
            || 'US_MAILING_ADDRESS_CITY'
            || v_delim
            || 'US_MAILING_ADDRESS_STATE'
            || v_delim
            || 'US_MAILING_ADDRESS_ZIP'
            || v_delim
            || 'MAJOR1_DEPT'
            || v_delim
            || 'MAJOR2_DEPT'
            || v_delim
            || 'MAJOR1_DESC'
            || v_delim
            || 'MAJOR2_DESC'
            || v_delim
            || 'MINOR_DEPT'
            || v_delim
            || 'MINOR_DESC'
            || v_delim
            || 'ENROLL_COLLEGE'
            || v_delim
            || 'STUDENT_ID'
            || v_delim
            || 'ADVISOR_NAME'
            || v_delim
            || 'ADVISOR_EMAIL'
            || v_delim
            || 'LANGUAGE_TEST1'
            || v_delim
            || 'LANGUAGE_TEST2'
            || v_delim
            || 'CREDITS_TOTAL'
            || v_delim
            || 'CREDITS_CAMPUS'
            || v_delim
            || 'CREDITS_ONLINE'
            || v_delim
            || 'CREDITS_ESL'
            || v_delim
            || 'FULL_TIME'
            || v_delim
            || 'CREDITS_TERM'
            || v_delim
            || 'CREDITS_EARNED'
            || v_delim
            || 'UNDERGRAD_LEVEL'
            || v_delim
            || 'APPLIED_GRADUATION'
            || v_delim
            || 'GRAD_DATE'
            || v_delim
            || 'ACADEMIC_DEFICIENCY'
            || v_delim
            || 'FINANCIAL_HOLD'
            || v_delim
            || 'CONDUCT_HOLD'
            || v_delim
            || 'CUM_GPA'
            || v_delim
            || 'ADMIT_TERM'
            || v_delim
            || 'MARITAL_STATUS'
            || v_delim
            || 'PREFERRED_NAME'
            || v_delim
            || 'PREFERRED_GENDER'
            || v_delim
            || 'CUSTOM1'
            || v_delim
            || 'CUSTOM2'
            || v_delim
            || 'CUSTOM3'
            || v_delim
            || 'CUSTOM4'
            || v_delim
            || 'CUSTOM5'
            || v_delim
            || 'CUSTOM6'
            || v_delim
            || 'CUSTOM7'
            || v_delim
            || 'CUSTOM8'
            || v_delim
            || 'CUSTOM9';

        --output header record
        UTL_FILE.put_line (id, filedata);

        --TERM CODE LOGIC
        IF p_override_term IS NULL
        THEN
            lv_term_code := CASANDRA.F_FETCH_TERM;
        ELSE
            lv_term_code := p_override_term;
        END IF;

        FOR student_rec IN student_cur
        LOOP
            BEGIN
                lv_SUFFIX :=
                    f_isss_translate_suffix (student_rec.banner_suffix);
                lv_VISA_TYPE := f_isss_visa (student_rec.pidm);
                lv_MARITAL_STATUS :=
                    F_GET_DESC ('STVMRTL', student_rec.banner_mrtl_code);

                p_student_address (student_rec.pidm,
                                   'MA',
                                   NULL,
                                   lv_US_ADDRESS_LINE1,
                                   lv_US_ADDRESS_LINE2,
                                   lv_banner_line3,
                                   lv_US_ADDRESS_CITY,
                                   lv_US_ADDRESS_STATE,
                                   lv_US_ADDRESS_ZIP,
                                   lv_banner_country);

                p_student_address (student_rec.pidm,
                                   'PR',
                                   NULL,
                                   lv_US_ADDRESS_LINE1,
                                   lv_US_ADDRESS_LINE2,
                                   lv_banner_line3,
                                   lv_US_ADDRESS_CITY,
                                   lv_US_ADDRESS_STATE,
                                   lv_US_ADDRESS_ZIP,
                                   lv_banner_country);

                BEGIN                         --foreign address country lookup
                    SELECT stvnatn_sevis_equiv
                      INTO lv_FOREIGN_ADDRESS_COUNTRY
                      FROM stvnatn
                     WHERE stvnatn_code = lv_banner_country;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        lv_FOREIGN_ADDRESS_COUNTRY := NULL;
                END;

                p_student_address (student_rec.pidm,
                                   'MA',
                                   NULL,
                                   lv_US_MAILING_ADDRESS_LINE1,
                                   lv_US_MAILING_ADDRESS_LINE2,
                                   lv_banner_line3,
                                   lv_US_MAILING_ADDRESS_CITY,
                                   lv_US_MAILING_ADDRESS_STATE,
                                   lv_US_MAILING_ADDRESS_ZIP,
                                   lv_banner_country);

                lv_US_PHONE :=
                    f_student_phone (p_pidm        => student_rec.pidm,
                                     p_tele_code   => 'MA');

                --STUDENT ACADEMICS BLOCK
                BEGIN
                    SELECT sgbstdn_levl_code
                               banner_level_code,
                           f_class_calc_fnc (PIDM        => sgbstdn_pidm,
                                             LEVL_CODE   => sgbstdn_levl_code,
                                             TERM_CODE   => lv_term_code)
                               class_code,
                           CASE
                               WHEN sgbstdn_coll_code_1 IS NOT NULL
                               THEN
                                      sgbstdn_coll_code_1
                                   || ' - '
                                   || stvcoll_desc
                               ELSE
                                   NULL
                           END
                               enroll_college,
                           CASE
                               WHEN sgbstdn_dept_code IS NOT NULL
                               THEN
                                   sgbstdn_dept_code || ' - ' || stvdept_desc
                               ELSE
                                   NULL
                           END
                               MAJOR1_DEPT,
                           sgbstdn_degc_code_1
                               degree_code,
                           --stvdegc_desc degree_desc,
                           CASE
                               WHEN sgbstdn_majr_code_1 IS NOT NULL
                               THEN
                                      sgbstdn_majr_code_1
                                   || ' - '
                                   || major1.stvmajr_desc
                               ELSE
                                   NULL
                           END
                               major1_desc,
                           major1.stvmajr_cipc_code
                               major1_cipc,
                           CASE
                               WHEN sgbstdn_majr_code_2 IS NOT NULL
                               THEN
                                      sgbstdn_majr_code_2
                                   || ' - '
                                   || major2.stvmajr_desc
                               ELSE
                                   NULL
                           END
                               major2_desc,
                           major2.stvmajr_cipc_code
                               major2_cipc,
                           CASE
                               WHEN sgbstdn_majr_code_minr_1 IS NOT NULL
                               THEN
                                      sgbstdn_majr_code_minr_1
                                   || ' - '
                                   || minor.stvmajr_desc
                               ELSE
                                   NULL
                           END
                               minor_desc,
                           minor.stvmajr_cipc_code
                               minor_cpic,
                           CASE
                               WHEN sgbstdn_leav_code IS NOT NULL
                               THEN
                                   sgbstdn_leav_code || ' - ' || stvleav_desc
                               ELSE
                                   NULL
                           END
                               leave_reason,
                           sgbstdn_exp_grad_date
                      INTO lv_banner_level_code,
                           lv_banner_class_code,
                           lv_ENROLL_COLLEGE,
                           lv_MAJOR1_DEPT,
                           lv_banner_degree_code,
                           lv_MAJOR1_DESC,
                           lv_MAJOR_CIP,
                           lv_MAJOR2_DESC,
                           lv_SECOND_MAJOR_CIP,
                           lv_MINOR_DESC,
                           lv_MINOR_CIP,
                           lv_CUSTOM9,                          --leave_reason
                           lv_banner_exp_grad_date
                      FROM sgbstdn
                           LEFT JOIN stvcoll
                               ON sgbstdn_coll_code_1 = stvcoll_code
                           LEFT JOIN stvdept
                               ON sgbstdn_dept_code = stvdept_code
                           LEFT JOIN stvdegc
                               ON sgbstdn_degc_code_1 = stvdegc_code
                           LEFT JOIN stvmajr major1
                               ON sgbstdn_majr_code_1 = major1.stvmajr_code
                           LEFT JOIN stvmajr major2
                               ON sgbstdn_majr_code_2 = major2.stvmajr_code
                           LEFT JOIN stvmajr minor
                               ON sgbstdn_majr_code_minr_1 =
                                  minor.stvmajr_code
                           LEFT JOIN stvleav
                               ON sgbstdn_leav_code = stvleav_code
                     WHERE     sgbstdn_term_code_eff =
                               (SELECT MAX (delta.sgbstdn_term_code_eff)
                                  FROM sgbstdn delta
                                 WHERE     delta.sgbstdn_pidm =
                                           sgbstdn.sgbstdn_pidm
                                       AND delta.sgbstdn_term_code_eff <=
                                           lv_term_code)
                           AND sgbstdn_pidm = student_rec.pidm;

                    lv_UNDERGRAD_LEVEL :=
                        f_isss_translate_ug_level (
                            p_banner_class_code   => lv_banner_class_code);

                    lv_EDUCATION_LEVEL :=
                        f_isss_translate_ed_level (
                            p_banner_degree_code   => lv_banner_degree_code);
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        lv_banner_level_code := NULL;
                        lv_banner_class_code := NULL;
                        lv_ENROLL_COLLEGE := NULL;
                        lv_MAJOR1_DEPT := NULL;
                        lv_banner_degree_code := NULL;
                        lv_MAJOR1_DESC := NULL;
                        lv_MAJOR_CIP := NULL;
                        lv_MAJOR2_DESC := NULL;
                        lv_SECOND_MAJOR_CIP := NULL;
                        lv_MINOR_DESC := NULL;
                        lv_MINOR_CIP := NULL;
                        lv_CUSTOM9 := NULL;
                        lv_UNDERGRAD_LEVEL := NULL;
                        lv_EDUCATION_LEVEL := NULL;
                        lv_banner_exp_grad_date := NULL;
                        DBMS_OUTPUT.put_line (
                               'ERROR: No student record found for '
                            || student_rec.UUUID);
                END;

                --STUDENT CUMULATIVE GPA BLOCK
                BEGIN
                    SELECT shrlgpa_hours_earned, shrlgpa_gpa
                      INTO lv_CREDITS_EARNED, lv_CUM_GPA
                      FROM shrlgpa
                     WHERE     shrlgpa_gpa_type_ind = 'O'    --overall credits
                           AND shrlgpa_levl_code = lv_banner_level_code
                           AND shrlgpa_pidm = student_rec.pidm;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        lv_CREDITS_EARNED := NULL;
                        lv_CUM_GPA := NULL;
                        DBMS_OUTPUT.put_line (
                               'ERROR: No student cumulative gpa found for '
                            || student_rec.UUUID);
                END;

                lv_banner_app_grad_date :=
                    f_student_grad_date (p_pidm => student_rec.pidm);

                --GRADUATION CALCULATIONS
                CASE
                    WHEN lv_banner_app_grad_date IS NOT NULL
                    THEN
                        lv_GRAD_DATE := lv_banner_app_grad_date;
                        lv_APPLIED_GRADUATION := 'Y';
                    ELSE
                        lv_APPLIED_GRADUATION := 'N';
                        lv_GRAD_DATE := lv_banner_exp_grad_date;
                END CASE;

                lv_CREDITS_TOTAL :=
                    f_credits_term_total (p_pidm        => student_rec.pidm,
                                          p_term_code   => lv_term_code);
                lv_CREDITS_CAMPUS :=
                    f_credits_campus (p_pidm        => student_rec.pidm,
                                      p_term_code   => lv_term_code);
                lv_CREDITS_ONLINE :=
                    f_credits_online (p_pidm        => student_rec.pidm,
                                      p_term_code   => lv_term_code);
                lv_CREDITS_ESL :=
                    f_credits_esl (p_pidm        => student_rec.pidm,
                                   p_term_code   => lv_term_code);
                lv_FULL_TIME :=
                    f_student_time_status (p_pidm        => student_rec.pidm,
                                           p_term_code   => lv_term_code);

                lv_ACADEMIC_DEFICIENCY :=
                    f_student_academic_standing (
                        p_pidm        => student_rec.pidm,
                        p_term_code   => lv_term_code);

                lv_FINANCIAL_HOLD :=
                    f_holds_financial (p_pidm => student_rec.pidm);
                lv_CONDUCT_HOLD :=
                    f_holds_conduct (p_pidm => student_rec.pidm);

                --STUDENT ADMISSIONS BLOCK
                BEGIN
                    SELECT saradap_term_code_entry
                               admit_term,
                           saradap_site_code || ' - ' || stvsite_desc
                               admit_site,
                           saradap_admt_code || ' - ' || stvadmt_desc
                               admit_type,
                           saradap_resd_code || ' - ' || stvresd_desc
                               admit_residence
                      INTO lv_ADMIT_TERM,
                           lv_CUSTOM1,
                           lv_CUSTOM6,
                           lv_CUSTOM7
                      FROM saradap
                           LEFT JOIN stvsite
                               ON saradap_site_code = stvsite_code
                           LEFT JOIN stvadmt
                               ON saradap_admt_code = stvadmt_code
                           LEFT JOIN stvresd
                               ON saradap_resd_code = stvresd_code
                     WHERE     saradap_appl_date =
                               (SELECT MAX (india.saradap_appl_date)
                                  FROM saradap india
                                 WHERE     india.saradap_appl_date <= SYSDATE
                                       AND india.saradap_pidm =
                                           saradap.saradap_pidm)
                           AND saradap_pidm = student_rec.pidm;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        lv_ADMIT_TERM := NULL;
                        lv_CUSTOM1 := NULL;
                        lv_CUSTOM6 := NULL;
                        lv_CUSTOM7 := NULL;
                        DBMS_OUTPUT.put_line (
                               'ERROR: No admissions record found for '
                            || student_rec.UUUID);
                END;

                --STUDENT ADVISOR BLOCK
                BEGIN
                    SELECT    spriden_id
                           || ' - '
                           || COALESCE (spbpers_pref_first_name,
                                        spriden_first_name)
                           || ' '
                           || spriden_last_name     advisor_name,
                           goremal_email_address    advisor_email
                      INTO lv_ADVISOR_NAME, lv_ADVISOR_EMAIL
                      FROM sgradvr
                           JOIN spriden
                               ON     spriden_pidm = sgradvr_advr_pidm
                                  AND spriden_change_ind IS NULL
                           LEFT JOIN goremal
                               ON     goremal_pidm = sgradvr_advr_pidm
                                  AND goremal_status_ind = 'A'
                                  AND goremal_preferred_ind = 'Y'
                           LEFT JOIN spbpers
                               ON spbpers_pidm = sgradvr_advr_pidm
                     WHERE     sgradvr_term_code_eff =
                               (SELECT MAX (sgradvr_term_code_eff)
                                  FROM sgradvr juliett
                                 WHERE     juliett.sgradvr_prim_ind = 'Y'
                                       AND juliett.sgradvr_pidm =
                                           sgradvr.sgradvr_pidm)
                           AND sgradvr_prim_ind = 'Y'
                           AND sgradvr_pidm = student_rec.pidm;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        lv_ADVISOR_NAME := NULL;
                        lv_ADVISOR_EMAIL := NULL;
                        DBMS_OUTPUT.put_line (
                               'ERROR: No admissions record found for '
                            || student_rec.UUUID);
                END;

                filedata :=
                       student_rec.UUUID
                    || v_delim
                    || student_rec.LAST_NAME
                    || v_delim
                    || student_rec.FIRST_NAME
                    || v_delim
                    || student_rec.MIDDLE_NAME
                    || v_delim
                    || student_rec.EMAIL
                    || v_delim
                    || student_rec.DOB
                    || v_delim
                    || student_rec.GENDER
                    || v_delim
                    || student_rec.CONFIDENTIALITY_IND
                    || v_delim
                    || lv_HR_FLAG
                    || v_delim
                    || lv_SUFFIX
                    || v_delim
                    || lv_VISA_TYPE
                    || v_delim
                    || lv_MAJOR_CIP
                    || v_delim
                    || lv_SECOND_MAJOR_CIP
                    || v_delim
                    || lv_MINOR_CIP
                    || v_delim
                    || lv_EDUCATION_LEVEL
                    || v_delim
                    || student_rec.BIRTH_COUNTRY
                    || v_delim
                    || student_rec.CITIZENSHIP_COUNTRY
                    || v_delim
                    || lv_FOREIGN_PHONE_COUNTRY_CODE
                    || v_delim
                    || lv_FOREIGN_PHONE
                    || v_delim
                    || lv_US_PHONE
                    || v_delim
                    || student_rec.PERM_RESIDENT_COUNTRY
                    || v_delim
                    || lv_US_ADDRESS_LINE1
                    || v_delim
                    || lv_US_ADDRESS_LINE2
                    || v_delim
                    || lv_US_ADDRESS_CITY
                    || v_delim
                    || lv_US_ADDRESS_STATE
                    || v_delim
                    || lv_US_ADDRESS_ZIP
                    || v_delim
                    || lv_FOREIGN_ADDRESS_LINE1
                    || v_delim
                    || lv_FOREIGN_ADDRESS_LINE2
                    || v_delim
                    || lv_FOREIGN_ADDRESS_CITY
                    || v_delim
                    || lv_FOREIGN_ADDRESS_PROVINCE
                    || v_delim
                    || lv_FOREIGN_ADDRESS_POSTALCODE
                    || v_delim
                    || lv_FOREIGN_ADDRESS_COUNTRY
                    || v_delim
                    || lv_US_MAILING_ADDRESS_LINE1
                    || v_delim
                    || lv_US_MAILING_ADDRESS_LINE2
                    || v_delim
                    || lv_US_MAILING_ADDRESS_CITY
                    || v_delim
                    || lv_US_MAILING_ADDRESS_STATE
                    || v_delim
                    || lv_US_MAILING_ADDRESS_ZIP
                    || v_delim
                    || lv_MAJOR1_DEPT
                    || v_delim
                    || lv_MAJOR2_DEPT
                    || v_delim
                    || lv_MAJOR1_DESC
                    || v_delim
                    || lv_MAJOR2_DESC
                    || v_delim
                    || lv_MINOR_DEPT
                    || v_delim
                    || lv_MINOR_DESC
                    || v_delim
                    || lv_ENROLL_COLLEGE
                    || v_delim
                    || student_rec.STUDENT_ID
                    || v_delim
                    || lv_ADVISOR_NAME
                    || v_delim
                    || lv_ADVISOR_EMAIL
                    || v_delim
                    || lv_LANGUAGE_TEST1
                    || v_delim
                    || lv_LANGUAGE_TEST2
                    || v_delim
                    || lv_CREDITS_TOTAL
                    || v_delim
                    || lv_CREDITS_CAMPUS
                    || v_delim
                    || lv_CREDITS_ONLINE
                    || v_delim
                    || lv_CREDITS_ESL
                    || v_delim
                    || lv_FULL_TIME
                    || v_delim
                    || lv_CREDITS_TERM
                    || v_delim
                    || lv_CREDITS_EARNED
                    || v_delim
                    || lv_UNDERGRAD_LEVEL
                    || v_delim
                    || lv_APPLIED_GRADUATION
                    || v_delim
                    || lv_GRAD_DATE
                    || v_delim
                    || lv_ACADEMIC_DEFICIENCY
                    || v_delim
                    || lv_FINANCIAL_HOLD
                    || v_delim
                    || lv_CONDUCT_HOLD
                    || v_delim
                    || lv_CUM_GPA
                    || v_delim
                    || lv_ADMIT_TERM
                    || v_delim
                    || lv_MARITAL_STATUS
                    || v_delim
                    || student_rec.PREFERRED_NAME
                    || v_delim
                    || student_rec.PREFERRED_GENDER
                    || v_delim
                    || lv_CUSTOM1
                    || v_delim
                    || lv_CUSTOM2
                    || v_delim
                    || student_rec.CUSTOM3
                    || v_delim
                    || student_rec.CUSTOM4
                    || v_delim
                    || student_rec.CUSTOM5
                    || v_delim
                    || lv_CUSTOM6
                    || v_delim
                    || lv_CUSTOM7
                    || v_delim
                    || student_rec.CUSTOM8
                    || v_delim
                    || lv_CUSTOM9;

                UTL_FILE.put_line (id, filedata);
            EXCEPTION
                WHEN OTHERS
                THEN
                    DBMS_OUTPUT.put_line (
                        'TDEXPORT - Bad row creation in file: ' || SQLERRM);
            END;
        END LOOP;

        UTL_FILE.fclose (id);
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'TDEXPORT - UNKNOWN ISSS ERROR: ' || SQLERRM);
    END;
END z_terra_dotta_interface;
/