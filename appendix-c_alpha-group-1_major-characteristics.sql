-- Major Characteristics of MIMIC-III

-- Code used to extract data related to Figure 1: Top Five Patient Diagnoses 

SELECT diagnosis, COUNT(diagnosis) AS count_of_diagnosis
FROM admissions
GROUP BY diagnosis
ORDER BY count_of_diagnosis DESC
LIMIT 5;

-- Code used to extract data related to Figure 2: Top Ten Procedures for a Diagnosis of Pneumonia 

WITH pneumonia_diagnosis AS 
(
	SELECT diagnosis, a.subject_id, a.hadm_id, icd9_code
    FROM admissions a
		INNER JOIN procedures_icd p 
			ON a.hadm_id = p.hadm_id
    WHERE diagnosis = 'PNEUMONIA'
)
SELECT short_title, COUNT(short_title) AS count_of_procedure
FROM pneumonia_diagnosis pd
	INNER JOIN d_icd_procedures d
		ON pd.icd9_code = d.icd9_code
GROUP BY short_title
ORDER BY count_of_procedure DESC
LIMIT 10;

-- Code used to extract data related to Figure 3: Overview of Deaths by Service 

WITH service_deaths AS
(
	SELECT 	CURR_SERVICE, 
			GENDER,
			COUNT(CURR_SERVICE) AS service_count, 
			SUM(HOSPITAL_EXPIRE_FLAG) AS number_of_deaths,
            ROUND(SUM(HOSPITAL_EXPIRE_FLAG) / COUNT(CURR_SERVICE), 2) AS percent_died
	FROM admissions a
		JOIN patients p 
			ON a.subject_id = p.subject_id
		JOIN services s 
			ON p.subject_id = s.subject_id
	GROUP BY CURR_SERVICE, GENDER 
	ORDER BY CURR_SERVICE, GENDER DESC
)
SELECT CURR_SERVICE,
	GENDER,
    service_count,
    number_of_deaths,
    percent_died
FROM service_deaths
ORDER BY CURR_SERVICE, GENDER DESC;

-- Code used to extract data related to Figure 4: Overview of First-Visit Plastic Services

WITH first_admit AS
(
  SELECT
      p.subject_id, p.dob,
      MIN(a.admittime) AS first_admittime
      , MIN( ROUND( (cast(admittime as date) - cast(dob as date)) / 365,2) )
          AS first_admit_age
  FROM patients p
  JOIN admissions a  ON p.subject_id = a.subject_id
  -- To include diagnosis filter via ICD9 Code
  -- JOIN diagnoses_icd icd ON icd.sujbect_id = p.subject_id
  -- If we want to add Diagnosis filter 
  -- WHERE a.diagnosis like '%RENAL%'
  -- WHERE icd.icd9_code = X
  -- AND a.hospital_expire_flag = '1'
  GROUP BY p.subject_id, p.dob
  ORDER BY p.subject_id
)
, age as
(
  SELECT
      subject_id, dob
      , first_admittime, first_admit_age
      , CASE
          WHEN first_admit_age > 100
              then '>89'
         WHEN first_admit_age >70 
             THEN '71-89'
         WHEN first_admit_age > 50
            THEN '51-70'
         WHEN first_admit_age > 30
            THEN '31-50'
          WHEN first_admit_age >= 14
              THEN 'adult'
          WHEN first_admit_age <= 1
              THEN 'infant'
          ELSE 'adolescent'
          END AS age_group
  FROM first_admit
)
select 
-- icd.icd9_code, icd._description
s.curr_service as Service, age_group AS Age_Group
  , count(a.subject_id) as Nbr_Of_Patients
from services s JOIN age a ON a.subject_id = s.subject_id
group by s.curr_service, age_group
ORDER BY s.curr_service;

-- Code used to extract data related to hospital deaths. Finding average hospital stay and most common diagnosis among deceased

USE mimic_iii_project;

CREATE VIEW mortality_analysis_vw 
AS

WITH dx_query AS 
(SELECT LEFT(YEAR(a.ADMITTIME),3) AS DECADE, b.ICD9_CODE, count(b.ICD9_CODE) as dx_count, c.gender
FROM admissions a
JOIN diagnoses_icd b ON a.HADM_ID=b.HADM_ID
JOIN PATIENTS c ON a.SUBJECT_ID=c.SUBJECT_ID
WHERE a.HOSPITAL_EXPIRE_FLAG = 1
GROUP BY LEFT(YEAR(a.ADMITTIME),3), b.ICD9_CODE, c.gender
ORDER BY LEFT(YEAR(a.ADMITTIME),3), c.gender
)

, days_query AS
(SELECT DISTINCT LEFT(YEAR(a.ADMITTIME),3) AS DECADE, ROUND(AVG(datediff(a.DISCHTIME, a.ADMITTIME)),2) avg_days_since_admission, b.gender
FROM admissions a
JOIN PATIENTS b ON a.SUBJECT_ID=b.SUBJECT_ID
WHERE HOSPITAL_EXPIRE_FLAG = 1
GROUP BY LEFT(YEAR(a.ADMITTIME),3), b.gender
ORDER by LEFT(YEAR(a.ADMITTIME),3), b.gender
)

select a.decade, a.gender, a.avg_days_since_admission, c.short_title, b.dx_count
from days_query a
JOIN dx_query b on a.decade=b.decade AND b.gender=a.gender
JOIN D_ICD_DIAGNOSES c ON b.ICD9_CODE=c.ICD9_CODE
WHERE b.dx_count = (SELECT MAX(dx_count) FROM dx_query WHERE decade=b.decade AND gender=b.gender)
ORDER BY a.decade,a.gender;

-- Code used to extract data related to ICD9_CODEs and their associated diagnoses and procedures

SELECT
     u.icd9_code,
     d_icd_d.short_title AS diagnoses_short,
     d_icd_d.long_title AS diagnoses_long,
     d_icd_p.short_title AS procedure_short,
     d_icd_p.long_title AS procedure_long
FROM
    ( SELECT icd9_code FROM diagnoses_icd UNION
      SELECT icd9_code FROM d_icd_diagnoses UNION
      SELECT icd9_code FROM d_icd_procedures
    ) AS u
  LEFT OUTER JOIN diagnoses_icd AS d_icd
    ON d_icd.icd9_code = u.icd9_code
  LEFT OUTER JOIN d_icd_diagnoses AS d_icd_d
    ON d_icd_d.icd9_code = u.icd9_code
  LEFT OUTER JOIN d_icd_procedures AS d_icd_p
    ON d_icd_p.icd9_code = u.icd9_code;