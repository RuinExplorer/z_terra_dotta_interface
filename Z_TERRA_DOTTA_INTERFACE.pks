/* Formatted on 5/21/2019 9:48:22 AM (QP5 v5.336) */
CREATE OR REPLACE PACKAGE BANINST1.z_terra_dotta_interface
AS
    /* STUDY ABROAD

    REFERENCES
    https://sites.google.com/a/terradotta.com/technical-documents/home/system-integration/integrating-with-sis-and-hr-systems/data-specifications
    https://tdsupport.force.com/support/articles/General/Data-Feed-File-Requirements
    https://tdsupport.force.com/support/5003300000wiIzd

    Core Data File? should be named sis_user_info_core.txt? and should contain only the following
    column headers/fields:
    ? UUUID
    ? First Name
    ? Last Name
    ? Middle Name
    ? Email
    ? DOB
    ? Gender
    ? Confidentiality Indicator

    2. Custom Data File ?should be named sis_user_info_custom.txt? and should contain the following
    column headers/fields:
    ? UUUID
    ? Class Level
    ? Academic Level
    ? Country of Citizenship
    ? Visa Status
    ? Cell Number
    ? Cumulative GPA
    ? Financial Hold
    ? Academic Hold
    ? Major 1
    ? Major 2
    ? Minor 1
    ? Minor 2
    ? Expected Graduation Date
    ? Preferred Name
    ? Emergency Contact
    ? Campus Address
    ? Permanent Address

    3. HR File ?should be named hr_user_info_core.txt ??and should contain only the following
    column headers/fields:
    ? UUUID
    ? First Name
    ? Last Name
    ? Middle Name
    ? Email

    */

    PROCEDURE p_extract_hr_user_info_core;

    PROCEDURE p_extract_sis_user_info_core;

    PROCEDURE p_extract_sis_user_info_custom;

    PROCEDURE p_applications_manager;

    --

    /* ISSS

    REFERENCES
    https://sites.google.com/terradotta.com/techdocs-new/integration-documentation/sishr-data-isss
    https://docs.google.com/spreadsheets/d/11YWsv1q50gwefqPiZOS4PKYN_3S8M2lCZp_JyGMiJRg/edit#gid=0

    */

    PROCEDURE p_isss_extract_sis_user_info;
--PROCEDURE p_isss_extract_hr_user_info;

--
END z_terra_dotta_interface;
/