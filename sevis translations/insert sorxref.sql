/* Formatted on 5/24/2019 1:32:39 PM (QP5 v5.336) */

--load tb_sevis_degrees first!

SELECT * FROM stvxlbl;

INSERT INTO stvxlbl (stvxlbl_code,
                     stvxlbl_desc,
                     stvxlbl_activity_date,
                     stvxlbl_system_req_ind)
     VALUES ('TDXDEGC',
             'Terra Dotta ISSS - Degrees',
             SYSDATE,
             'N');

SELECT * FROM sorxref where sorxref_xlbl_code = 'TDXDEGC';

INSERT INTO sorxref (SORXREF_XLBL_CODE,
                     SORXREF_EDI_VALUE,
                     SORXREF_EDI_STANDARD_IND,
                     SORXREF_DISP_WEB_IND,
                     SORXREF_ACTIVITY_DATE,
                     SORXREF_EDI_QLFR,
                     SORXREF_DESC,
                     SORXREF_BANNER_VALUE,
                     SORXREF_PESC_XML_IND)
    SELECT 'TDXDEGC',
           sevis_code,
           'Y',
           'Y',
           SYSDATE,
           degree_code,
           degree_desc,
           degree_code,
           'N'
      FROM tb_sevis_degrees;