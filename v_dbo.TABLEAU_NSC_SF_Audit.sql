CREATE OR ALTER VIEW dbo.TABLEAU_NSC_SF_Audit AS

WITH school_identifiers AS (
  SELECT school_id
        ,LEFT(region, 1) AS region_initial
        ,CASE 
          WHEN school = 'KIPP Northeast College Prep' THEN 'KIPP Northeast College Preparatory' 
          WHEN school = 'KIPP Austin Brave' THEN 'KIPP Austin Brave High School'
          WHEN school = 'KIPP Connect High School' THEN 'KIPP CONNECT Houston High School'
          ELSE school 
         END AS school
  FROM ktx_analytics.dbo.school_names_table
  WHERE academic_year = (SELECT MAX([year]) AS max_year FROM ktx_analytics.dbo.flat_region_year_dates)
 )

,demographics AS (
  SELECT fkg.sex AS sex
        ,fkg.[aggregate race ethnicity] AS ethnicity
        ,fkg.[campus id]
           + fkg.[student id]
           + si.region_initial AS nsc_unique_identifier
  FROM ktx_analytics.dbo.flat_kipp_graduates fkg
  JOIN school_identifiers si
    ON fkg.[campus id] = si.school_id
 )

,nsc AS (
  SELECT nsc.[unique] AS nsc_unique_identifier
        ,nsc.[CO] AS nsc_cohort
        ,nsc.[first name] AS nsc_first_name
        ,nsc.[last name] AS nsc_last_name
        ,nsc.[college code] AS nsc_college_code
        ,nsc.[college name] AS nsc_college_name
        ,nsc.[college category] AS nsc_college_category
        ,nsc.[college type] AS nsc_college_type
        ,nsc.[enrollment start] AS nsc_enrollment_start
        ,COALESCE(nsc.[enrollment end], nsc.[college grad date]) AS nsc_enrollment_end
        ,nsc.[enrollment status] AS nsc_enrollment_status
        ,nsc.[graduated] AS nsc_graduated
        ,nsc.[college grad date] AS nsc_college_grad_date
        ,nsc.[degree title] AS nsc_degree_title
        ,nsc.[major] AS nsc_major

        ,a.id AS salesforce_school_id

        ,r.salesforce_contact_id
        ,r.kipp_region_name
        ,r.counselor_name
        ,r.ktc_status

        ,d.ethnicity
        ,d.sex

        ,ROW_NUMBER() OVER(
           PARTITION BY nsc.[unique]
             ORDER BY nsc.[graduated], DATEFROMPARTS(RIGHT(nsc.[enrollment start], 4), LEFT(nsc.[enrollment start], 2), 1)) AS rn_enrollment_order
  FROM ktx_analytics.dbo.nsc_hs_grad_college_data nsc
  LEFT JOIN ktx_analytics.dbo.nsc_college_code_crosswalk cw
    ON nsc.[college code] = cw.nsc_college_code
  LEFT JOIN ktx_analytics.dbo.sf_account a
    ON cw.ipeds_unit_id = a.ncesid__c
   AND a.isdeleted = 0
  LEFT JOIN ktx_analytics.dbo.sf_ktc_roster r
    ON nsc.[unique] = r.nsc_unique_identifier
  LEFT JOIN demographics d
    ON nsc.[unique] = d.nsc_unique_identifier
  WHERE nsc.[Record Found] = 'Y'
 )

,sf AS (
  SELECT enr.id AS salesforce_enrollment_id
        ,enr.[name] AS salesforce_enrollment_name
        ,enr.student__c AS salesforce_contact_id
        ,enr.school__c AS salesforce_school_id
        ,enr.status__c AS sf_status
        ,enr.account_type__c AS sf_account_type
        ,enr.pursuing_degree_type__c AS sf_pursuing_degree_type
        ,enr.major__c AS sf_major
        ,enr.actual_end_date__c AS sf_actual_end_date
        ,enr.nsc_verified__c AS sf_nsc_verified
        ,RIGHT(CONCAT('0', DATEPART(MONTH, enr.start_date__c)), 2) + '/'
           + CONVERT(VARCHAR(4), DATEPART(YEAR, enr.start_date__c)) AS sf_start_date
        ,RIGHT(CONCAT('0', DATEPART(MONTH, enr.actual_end_date__c)), 2) + '/'
           + CONVERT(VARCHAR(4), DATEPART(YEAR, enr.actual_end_date__c)) AS sf_actual_end

        ,r.nsc_unique_identifier
        ,r.first_name AS sf_first_name
        ,r.last_name AS sf_last_name
        ,r.counselor_name
        ,r.kipp_region_name
        ,r.ktc_status
        ,r.kipp_hs_class AS sf_cohort

        ,a.[name] AS sf_school_name

        ,d.ethnicity
        ,d.sex

        ,ROW_NUMBER() OVER(
           PARTITION BY enr.student__c
             ORDER BY enr.start_date__c) AS rn_enrollment_order
  FROM ktx_analytics.dbo.sf_enrollment_c enr
  JOIN ktx_analytics.dbo.sf_ktc_roster r
    ON enr.student__c = r.salesforce_contact_id
  JOIN ktx_analytics.dbo.sf_account a
    ON enr.school__c = a.id
  LEFT JOIN demographics d
    ON r.nsc_unique_identifier = d.nsc_unique_identifier
  WHERE enr.isdeleted = 0
    AND enr.type__c = 'College'
 )

/* GRADUATES */
SELECT n.nsc_unique_identifier
      ,n.nsc_first_name AS student_first_name
      ,n.nsc_last_name AS student_last_name
      ,n.counselor_name
      ,n.kipp_region_name
      ,n.nsc_college_name AS college_name
      ,n.nsc_cohort AS cohort
      ,n.ethnicity
      ,n.sex

      ,n.salesforce_school_id AS nsc_school_id
      ,n.nsc_college_name
      ,n.nsc_degree_title
      ,n.nsc_enrollment_start
      ,n.nsc_enrollment_end

      ,e.salesforce_school_id AS enr_school_id
      ,e.sf_school_name
      ,e.sf_pursuing_degree_type
      ,e.sf_start_date
      ,e.sf_actual_end
      ,ISNULL(e.sf_nsc_verified, 0) AS sf_nsc_verified

      ,CASE WHEN e.sf_school_name IS NOT NULL THEN 1 ELSE 0 END AS is_record_match
      ,'Graduated' AS enrollment_type
      ,'NSC>SF' AS direction
FROM nsc n
LEFT JOIN sf e
  ON n.salesforce_contact_id = e.salesforce_contact_id
 AND n.salesforce_school_id = e.salesforce_school_id
 AND e.sf_status = 'Graduated'
WHERE n.nsc_graduated = 'Y'
  AND n.nsc_degree_title <> ''
UNION ALL
SELECT e.nsc_unique_identifier
      ,e.sf_first_name AS student_first_name
      ,e.sf_last_name AS student_last_name
      ,e.counselor_name
      ,e.kipp_region_name
      ,e.sf_school_name AS college_name
      ,e.sf_cohort AS cohort
      ,e.ethnicity
      ,e.sex

      ,n.salesforce_school_id AS nsc_school_id
      ,n.nsc_college_name
      ,n.nsc_degree_title
      ,n.nsc_enrollment_start
      ,n.nsc_enrollment_end

      ,e.salesforce_school_id AS enr_school_id
      ,e.sf_school_name
      ,e.sf_pursuing_degree_type
      ,e.sf_start_date
      ,e.sf_actual_end
      ,ISNULL(e.sf_nsc_verified, 0) AS sf_nsc_verified

      ,CASE WHEN n.nsc_college_name IS NOT NULL THEN 1 ELSE 0 END AS is_record_match
      ,'Graduated' AS enrollment_type
      ,'SF>NSC' AS direction
FROM sf e
LEFT JOIN nsc n
  ON e.salesforce_contact_id = n.salesforce_contact_id
 AND e.salesforce_school_id = n.salesforce_school_id
 AND n.nsc_graduated = 'Y'
 AND n.nsc_degree_title <> ''
WHERE e.nsc_unique_identifier IS NOT NULL
  AND e.sf_status = 'Graduated'

UNION ALL

/* FIRST ENROLLMENT */
SELECT n.nsc_unique_identifier
      ,n.nsc_first_name AS student_first_name
      ,n.nsc_last_name AS student_last_name
      ,n.counselor_name
      ,n.kipp_region_name
      ,n.nsc_college_name AS college_name
      ,n.nsc_cohort AS cohort
      ,n.ethnicity
      ,n.sex

      ,n.salesforce_school_id AS nsc_school_id
      ,n.nsc_college_name
      ,n.nsc_degree_title
      ,n.nsc_enrollment_start
      ,n.nsc_enrollment_end

      ,e.salesforce_school_id AS enr_school_id
      ,e.sf_school_name
      ,e.sf_pursuing_degree_type
      ,e.sf_start_date
      ,e.sf_actual_end
      ,ISNULL(e.sf_nsc_verified, 0) AS sf_nsc_verified

      ,CASE WHEN e.sf_school_name IS NOT NULL THEN 1 ELSE 0 END AS is_record_match
      ,'Matriculated' AS enrollment_type
      ,'NSC>SF' AS direction
FROM nsc n
LEFT JOIN sf e
  ON n.salesforce_contact_id = e.salesforce_contact_id
 AND e.rn_enrollment_order = 1
WHERE n.nsc_graduated = 'N'
  AND n.rn_enrollment_order = 1
UNION ALL
SELECT e.nsc_unique_identifier
      ,e.sf_first_name AS student_first_name
      ,e.sf_last_name AS student_last_name
      ,e.counselor_name
      ,e.kipp_region_name
      ,e.sf_school_name AS college_name
      ,e.sf_cohort AS cohort
      ,e.ethnicity
      ,e.sex

      ,n.salesforce_school_id AS nsc_school_id
      ,n.nsc_college_name
      ,n.nsc_degree_title
      ,n.nsc_enrollment_start
      ,n.nsc_enrollment_end

      ,e.salesforce_school_id AS enr_school_id
      ,e.sf_school_name
      ,e.sf_pursuing_degree_type
      ,e.sf_start_date
      ,e.sf_actual_end
      ,ISNULL(e.sf_nsc_verified, 0) AS sf_nsc_verified

      ,CASE WHEN n.nsc_college_name IS NOT NULL THEN 1 ELSE 0 END AS is_record_match
      ,'Matriculated' AS enrollment_type
      ,'SF>NSC' AS direction
FROM sf e
LEFT JOIN nsc n
  ON e.salesforce_contact_id = n.salesforce_contact_id
 AND n.nsc_graduated = 'N'
 AND n.rn_enrollment_order = 1
WHERE e.nsc_unique_identifier IS NOT NULL
  AND e.rn_enrollment_order = 1
