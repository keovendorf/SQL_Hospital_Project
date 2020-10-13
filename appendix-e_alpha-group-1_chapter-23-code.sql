CREATE VIEW chp_23_data_load_vw 
AS
/*Base diagnosis sample of all ubjects who have been diagnosed with AFIB/RVR*/
WITH base_table AS 
(SELECT distinct a.subject_id, a.hadm_id
FROM diagnoses_icd a
JOIN (select * from noteevents
WHERE category = 'Discharge summary'
  AND text like '%rvr%'
  OR category = 'Discharge summary'
  AND text LIKE '%rapid ventricular response%') b ON a.subject_id=b.subject_id
WHERE a.ICD9_CODE = '42731'
)

/*Charted events made smaller*/
, small_events AS
(SELECT * 
	FROM chartevents
	WHERE hadm_id in 
				(SELECT DISTINCT hadm_id FROM base_table)
	AND itemid in (580,581,763,762,920,211,51,52,455,456,678,679,646,834,20001)
)

, base_events_pivot AS
(SELECT a.hadm_id, a.subject_id, 
	ROUND(cast(AVG(CASE 
			WHEN b.itemid = '762' THEN b.valuenum
            ELSE NULL
            END) as signed),0) AS admit_weight
	, ROUND(cast(AVG(CASE 
			WHEN b.itemid = '52' THEN b.valuenum
            ELSE NULL
            END) as signed),0) AS Arterial_BP_Mean
	, ROUND(cast(AVG(CASE 
			WHEN b.itemid = '211' THEN b.valuenum
            ELSE NULL
            END) as signed),0) AS avg_heart_rate
	, ROUND(cast(AVG(CASE 
			WHEN b.itemid = '646' THEN b.valuenum
            ELSE NULL
            END) as signed),0) AS SpO2
	, ROUND(cast(AVG(CASE 
			WHEN b.itemid = '678' THEN b.valuenum
            ELSE NULL
            END)as signed),0) AS avg_temp_farenheit
	, ROUND(cast(AVG(CASE 
			WHEN b.itemid = '834' THEN b.valuenum
            ELSE NULL
            END) as signed),0) AS SaO2
	, ROUND(cast(AVG(CASE 
			WHEN b.itemid = '920' THEN b.valuenum
            ELSE NULL
            END) as signed),0) AS admit_height
FROM base_table a 
JOIN small_events b ON a.hadm_id = b.hadm_id
GROUP BY a.hadm_id, a.subject_id
)
, labs_pivot AS
(SELECT a.hadm_id, a.subject_id, 
	MAX(CASE 
		WHEN b.itemid = 50862 THEN b.valuenum 
		ELSE NULL 
		END) AS Albumin,
	MAX(CASE 
		WHEN b.itemid = 50882 THEN b.valuenum 
		ELSE NULL 
		END) AS Bicarbonate,
	MAX(CASE 
		WHEN b.itemid = 50893 THEN b.valuenum 
		ELSE NULL 
		END) AS Calcium,
	MAX(CASE 
		WHEN b.itemid = 50902 THEN b.valuenum 
		ELSE NULL 
		END) AS Chloride,
	MAX(CASE 
		WHEN b.itemid = 51081 THEN b.valuenum 
		ELSE NULL 
		END) AS Creatinine_Serum,
	MAX(CASE 
		WHEN b.itemid = 50915 THEN b.valuenum 
		ELSE NULL 
		END) AS d_dimer,
	MAX(CASE 
		WHEN b.itemid = 50809 THEN b.valuenum 
		ELSE NULL 
		END) AS Glucose,
	MAX(CASE 
		WHEN b.itemid = 50935 THEN b.valuenum 
		ELSE NULL 
		END) AS Haptoglobin,
	MAX(CASE 
		WHEN b.itemid = 51221 THEN b.valuenum 
		ELSE NULL 
		END) AS Hematocrit,
	MAX(CASE 
		WHEN b.itemid = 51237 THEN b.valuenum 
		ELSE NULL 
		END) AS INR,
	MAX(CASE 
		WHEN b.itemid = 50813 THEN b.valuenum 
		ELSE NULL 
		END) AS Lactate,
	MAX(CASE 
		WHEN b.itemid = 50954 THEN b.valuenum 
		ELSE NULL 
		END) AS LDH,
	MAX(CASE 
		WHEN b.itemid = 51240 THEN b.valuenum 
		ELSE NULL 
		END) AS Platelets,
	MAX(CASE 
		WHEN b.itemid = 50960 THEN b.valuenum 
		ELSE NULL 
		END) AS Magnesium,
	MAX(CASE 
		WHEN b.itemid = 50970 THEN b.valuenum 
		ELSE NULL 
		END) AS Phosphate,
	MAX(CASE 
		WHEN b.itemid = 50833 THEN b.valuenum 
		ELSE NULL 
		END) AS Potassium,
	MAX(CASE 
		WHEN b.itemid = 51099 THEN b.valuenum 
		ELSE NULL 
		END) AS Protein_Creatinine_Ratio,
	MAX(CASE 
		WHEN b.itemid = 51274 THEN b.valuenum 
		ELSE NULL 
		END) AS PT,
	MAX(CASE 
		WHEN b.itemid = 51275 THEN b.valuenum 
		ELSE NULL 
		END) AS PTT,
	MAX(CASE 
		WHEN b.itemid = 50983 THEN b.valuenum 
		ELSE NULL 
		END) AS Sodium,
	MAX(CASE 
		WHEN b.itemid = 51100 THEN b.valuenum 
		ELSE NULL 
		END) AS Sodium_Urine,
	MAX(CASE 
		WHEN b.itemid = 51102 THEN b.valuenum 
		ELSE NULL 
		END) AS Total_Protein_Urine,
	MAX(CASE 
		WHEN b.itemid = 51106 THEN b.valuenum 
		ELSE NULL 
		END) AS Urine_Creatinine,
	MAX(CASE 
		WHEN b.itemid = 51516 THEN b.valuenum 
		ELSE NULL 
		END) AS WBC
FROM base_table a 
JOIN labevents b ON a.hadm_id = b.hadm_id
GROUP BY a.hadm_id, a.subject_id
)

/***********************************************/
/*********         Final View     **************/
/***********************************************/


SELECT base.subject_id, base.hadm_id, adm.ADMITTIME, adm.DISCHTIME,adm.admission_type, adm.language, adm.religion, adm.marital_status, adm.ethnicity, pat.gender, pat.DOB, year(pat.dob)-year(admittime) AS age
		,pat.DOD, pivot.admit_height, pivot.admit_weight, pivot.Arterial_BP_Mean, pivot.avg_heart_rate, pivot.SpO2, pivot.avg_temp_farenheit, pivot.SaO2
        , lab.Albumin, lab.Bicarbonate, lab.Calcium, lab.Chloride, lab.Creatinine_Serum, lab.d_dimer, lab.Glucose, lab.Haptoglobin, lab.Hematocrit, lab.INR, lab.Lactate, lab.LDH, lab.Platelets, lab.Magnesium,
        lab.Phosphate, lab.Potassium, lab.Protein_Creatinine_Ratio, lab.PT, lab.PTT, lab.Sodium, lab.Sodium_Urine, lab.Total_Protein_Urine, lab.Urine_Creatinine, lab.WBC        
FROM base_table base
JOIN admissions adm on base.hadm_id=adm.hadm_id
JOIN patients pat ON base.subject_id=pat.subject_id
JOIN base_events_pivot pivot on base.hadm_id=pivot.hadm_id
JOIN labs_pivot lab on base.hadm_id=lab.hadm_id
