CREATE TABLE TB_SEVIS_DEGREES
(
  SEVIS_CODE   VARCHAR2(2 CHAR),
  DEGREE_CODE  VARCHAR2(6 CHAR),
  DEGREE_DESC  VARCHAR2(30 CHAR)
)
LOGGING 
NOCOMPRESS 
NO INMEMORY
NOCACHE
RESULT_CACHE (MODE DEFAULT)
NOPARALLEL
MONITORING;


SET DEFINE OFF;
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BID', 'Bachelor of Interior Design');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', '00', 'Unknown (AH)');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('03', 'AGS', 'Associate of General Studies');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('03', 'APE', 'Associate of Pre-Engineering');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'NC', 'Not Complete');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'CONC', 'Concurrent Enrollment');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MED', 'Master of Education');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BBA', 'Bachelor of Business Administr');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BE', 'Bachelor of Engineering');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BEE', 'Bachelor of Electr Engineering');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BIS', 'Bachelor of Integrated Studies');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BTEC', 'Bachelor of Technology');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('06', 'JD', 'Juris Doctorate');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MDIV', 'Master of Divinity');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MEM', 'Master of Environmental Mgt');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MHA', 'Master of Healthcare Admin');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MPH', 'Master of Public Health');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MSW', 'Master of Social Work');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('03', 'AAAS', 'Associate of Arts and Sciences');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('06', 'MD', 'Doctor of Medicine');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('06', 'DVM', 'Doctor of Veterinary Med');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('06', 'DDS', 'Doctor of Dentistry');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'ASGS', 'Changed to AGS');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', '000000', 'Undeclared');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'PPRU', 'Pre-Program/Undergrad');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'PPRM', 'Pre-Program/Masters');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('06', 'PPRD', 'Pre-Program/Doctorate');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'NDUG', 'Non-Degree Program/Undergrad');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('06', 'NDGD', 'Non-Degree Program/Doctorate');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'NDGM', 'Non-Degree Program/Masters');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'NDPR', 'Non-Degree Program/Professiona');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'NDCT', 'Non-Degree Program/Certificate');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'NDEU', 'Non-Degree Endorsement/Undergr');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'NDEG', 'Non-Degree Endorsement/Grad');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('10', 'CERU', 'Certificate/Undergrad');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('10', 'CERG', 'Certificate/Graduate');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'DIPL', 'Diploma');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('03', 'AA', 'Associate of Arts');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('03', 'AS', 'Associate of Science');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('03', 'AAS', 'Associate of Applied Science');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BA', 'Bachelor of Arts');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BS', 'Bachelor of Science');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BFA', 'Bachelor of Fine Arts');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BLA', 'Bachelor of Landscape Arch');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'BM', 'Bachelor of Music');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MACC', 'Master of Accounting');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MAI', 'Master of Ag Industries');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MA', 'Master of Arts');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MBA', 'Master of Business Administrat');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MCED', 'Master of Community Econ Dev');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MCS', 'Master of Computer Science');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MDA', 'Master of Dietetics Administra');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'ME', 'Master of Engineering');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MES', 'Master of Engineering Science');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MFHD', 'Master of Family and Human Dev');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MFA', 'Master of Fine Arts');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MFMS', 'Master of Food Microbiology an');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MF', 'Master of Forestry');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MHE', 'Master of Health Education');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MIE', 'Master of Industrial Education');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MLA', 'Master of Landscape Arch');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MMA', 'Master of Mathematic');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MM', 'Master of Music');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MNR', 'Master of Natural Resources');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MPSH', 'Master of Prof Studies in Hort');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MRC', 'Master of Rehabilitation Couns');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MS', 'Master of Science');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MSLT', 'Master of Second Language Teac');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MSS', 'Master of Social Science');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'IE', 'Irrigation Engineer');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'EE', 'Electrical Engineer');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'CE', 'Civil Engineer');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'EDS', 'Educational Specialist');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('06', 'AUD', 'Doctor of Audiology');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('06', 'EDD', 'Doctor of Education');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('06', 'PHD', 'Doctor of Philosophy');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('03', 'ABUS', 'Associate of Business');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MMFT', 'Master Marriage Family Therapy');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('03', 'AB', 'Associate of Science/Business');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('03', 'AC', 'Associate of Science/Crim Just');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('10', 'CC', 'Certificate of Completion');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'ND', 'Non Degree');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MFSQ', 'Master of Food Safety&Quality');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'UNDE', 'Undeclared');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('04', 'ND2B', 'Non-Degree 2nd Bachelor');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'NRAC', 'Non-Regionally Accredited');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('10', 'CP', 'Certificate of Proficiency');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('10', 'CERP', 'Certificate of Proficiency');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'NDCE', 'Non-Degree Program/CEU');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MDATA', 'Master of Data Analytics');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MAS', 'Master of Aviation Science');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MHDF', 'Master Human Devt. Fam Studies');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MHR', 'Master of Human Resources');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'SPEA', 'Spec. Educational Admin.');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MHPR', 'Master of Health Promotion');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MFRP', 'Master of Fitness Promotion');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MMIS', 'Master of Mngmt Info Sys');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MLTI', 'Master of Inst Tech & Inst Des');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MAPE', 'Master of Applied Economics');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'POST', 'Post-HS College Credit');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'IPRG', 'In-Progress College Credit');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('11', 'LETR', 'Letter of Completion');
Insert into TB_SEVIS_DEGREES
   (SEVIS_CODE, DEGREE_CODE, DEGREE_DESC)
 Values
   ('05', 'MTEC', 'Master of Technical Commun');
COMMIT;
