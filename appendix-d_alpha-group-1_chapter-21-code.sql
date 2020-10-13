-- Data extract for Chapter 21

WITH icustay_detail AS 
(
	SELECT i.subject_id,
		i.hadm_id,
		i.icustay_id,
        a.admission_type,
		p.gender,
        a.admittime,
		a.dischtime,
        prev_service,
        curr_service,
        p.dob,
		p.dod,
		DENSE_RANK() OVER (PARTITION BY a.subject_id ORDER BY a.admittime) AS hospstay_seq,
		ROUND((CAST(a.admittime AS DATE) - CAST(p.dob AS DATE)) / 365,2) AS age,
       	ROUND((CAST(dod AS DATE) - CAST(dischtime AS DATE)),2) AS days_till_death_after_discharge,
		CASE
			WHEN DENSE_RANK() OVER (PARTITION BY a.subject_id ORDER BY a.admittime) = 1 THEN 1
			ELSE 0 
			END AS first_hosp_stay,
		DENSE_RANK() OVER (PARTITION BY i.hadm_id ORDER BY i.intime) AS icustay_seq,
		CASE
			WHEN DENSE_RANK() OVER (PARTITION BY i.hadm_id ORDER BY i.intime) = 1 THEN 1
			ELSE 0 
			END AS first_icu_stay
	FROM icustays i
		INNER JOIN admissions a
			ON i.hadm_id = a.hadm_id
		INNER JOIN services s 
			ON i.hadm_id = s.hadm_id
		INNER JOIN patients p
			ON i.subject_id = p.subject_id
	ORDER BY i.subject_id
), 
lab_tests AS
(
	SELECT a.hadm_id, a.subject_id, 
		MAX(CASE 
			WHEN l.itemid = 50912 THEN l.valuenum 
			ELSE NULL 
			END) AS Creatinine,
		MAX(CASE 
			WHEN l.itemid = 50971 THEN l.valuenum 
			ELSE NULL 
			END) AS Potassium,
		MAX(CASE 
			WHEN l.itemid = 50983 THEN l.valuenum 
			ELSE NULL 
			END) AS Sodium,
		MAX(CASE 
			WHEN l.itemid = 50902 THEN l.valuenum 
			ELSE NULL 
			END) AS Chloride,
		MAX(CASE 
			WHEN l.itemid = 50882 THEN l.valuenum 
			ELSE NULL 
			END) AS Bicarbonate,
		MAX(CASE 
			WHEN l.itemid = 51480 THEN l.valuenum 
			ELSE NULL 
			END) AS Hematocrit,
		MAX(CASE 
			WHEN l.itemid = 51301 THEN l.valuenum 
			ELSE NULL 
			END) AS White_Blood_Cells,
		MAX(CASE 
			WHEN l.itemid = 51478 THEN l.valuenum 
			ELSE NULL 
			END) AS Glucose,
		MAX(CASE 
			WHEN l.itemid = 50960 THEN l.valuenum 
			ELSE NULL 
			END) AS Magnesium,
		MAX(CASE 
			WHEN l.itemid = 50893 THEN l.valuenum 
			ELSE NULL 
			END) AS Calcium,
		MAX(CASE 
			WHEN l.itemid = 50970 THEN l.valuenum 
			ELSE NULL 
			END) AS Phosphate,
		MAX(CASE 
			WHEN l.itemid = 50813 THEN l.valuenum 
			ELSE NULL 
			END) AS Lactate
	FROM admissions a 
		INNER JOIN labevents l
			ON a.hadm_id = l.hadm_id
	GROUP BY a.hadm_id, a.subject_id
),
vital_signs AS
(
	SELECT a.hadm_id, a.subject_id, 
		MAX(CASE 
			WHEN c.itemid = 220045 THEN c.valuenum 
			ELSE NULL 
			END) AS Heart_Rate,
		MAX(CASE 
			WHEN c.itemid = 618 THEN c.valuenum 
			ELSE NULL 
			END) AS Respiratory_Rate,
		MAX(CASE 
			WHEN c.itemid = 442 THEN c.valuenum 
			ELSE NULL 
			END) AS BP_Systolic,
		MAX(CASE 
			WHEN c.itemid = 443 THEN c.valuenum 
			ELSE NULL 
			END) AS BP_Mean,
		MAX(CASE 
			WHEN c.itemid = 678 THEN c.valuenum 
			ELSE NULL 
			END) AS SpO2,
		MAX(CASE 
			WHEN c.itemid = 645 THEN c.valuenum 
			ELSE NULL 
			END) AS Body_Temperature
	FROM admissions a 
		INNER JOIN chartevents c
			ON a.hadm_id = c.hadm_id
	GROUP BY a.hadm_id, a.subject_id
)
SELECT ic.subject_id,
	ic.hadm_id,
    icustay_id,
	age,
    gender, 
    admission_type,
    curr_service,
    heart_rate,
    respiratory_rate,
    bp_systolic,
    bp_mean,
    spo2,
    body_temperature,
    creatinine,
    potassium,
    sodium,
    chloride,
    bicarbonate,
    hematocrit,
    white_blood_cells,
    glucose,
    magnesium,
    calcium,
    phosphate,
    lactate,
	days_till_death_after_discharge,
    CASE
		WHEN (days_till_death_after_discharge > 0) AND (days_till_death_after_discharge < 31) THEN 1
        ELSE 0
        END AS died_within_30_days
FROM icustay_detail ic
	INNER JOIN lab_tests la
		ON ic.hadm_id = la.hadm_id
	INNER JOIN vital_signs vs
		ON ic.hadm_id = vs.hadm_id
WHERE (hospstay_seq = 1) AND 
	(icustay_seq = 1) AND
    (age >= 15)
ORDER BY subject_id;
