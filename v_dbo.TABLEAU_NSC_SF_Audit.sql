CREATE OR ALTER VIEW dbo.TABLEAU_NSC_SF_Audit AS

WITH nsc_link AS (
  SELECT nsc.[unique] AS nsc_unique_identifier
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
        ,r.ktc_status
  FROM ktx_analytics.dbo.nsc_hs_grad_college_data nsc
  LEFT JOIN ktx_analytics.dbo.nsc_college_code_crosswalk cw
    ON nsc.[college code] = cw.nsc_college_code
  LEFT JOIN ktx_analytics.dbo.sf_account a
    ON cw.ipeds_unit_id = a.ncesid__c
   AND a.isdeleted = 0
  LEFT JOIN ktx_analytics.dbo.sf_ktc_roster r
    ON nsc.[unique] = r.nsc_unique_identifier
  WHERE nsc.[Record Found] = 'Y'
 )

,sf_enr AS (
  SELECT enr.id AS salesforce_enrollment_id
        ,enr.[name] AS salesforce_enrollment_name
        ,enr.student__c AS salesforce_contact_id
        ,enr.school__c AS salesforce_school_id
        ,enr.status__c AS sf_status
        ,enr.account_type__c AS sf_account_type
        ,enr.pursuing_degree_type__c AS sf_pursuing_degree_type
        ,enr.major__c AS sf_major
        ,enr.start_date__c AS sf_start_date
        ,enr.actual_end_date__c AS sf_actual_end_date
        ,enr.nsc_verified__c AS sf_nsc_verified
        ,RIGHT(CONCAT('0', DATEPART(MONTH, enr.actual_end_date__c)), 2) + '/'
           + CONVERT(VARCHAR(4), DATEPART(YEAR, enr.actual_end_date__c)) AS sf_actual_end

        ,r.nsc_unique_identifier
        ,r.first_name AS sf_first_name
        ,r.last_name AS sf_last_name
        ,r.ktc_status

        ,a.[name] AS sf_school_name
  FROM ktx_analytics.dbo.sf_enrollment_c enr
  JOIN ktx_analytics.dbo.sf_ktc_roster r
    ON enr.student__c = r.salesforce_contact_id
  JOIN ktx_analytics.dbo.sf_account a
    ON enr.school__c = a.id
  WHERE enr.isdeleted = 0
    AND enr.type__c = 'College'
 )

/* GRADUATES */
SELECT n.nsc_unique_identifier
      ,n.nsc_first_name AS student_first_name
      ,n.nsc_last_name AS student_last_name
      ,n.nsc_college_name AS college_name

      ,n.nsc_degree_title
      ,n.nsc_enrollment_start
      ,n.nsc_enrollment_end

      ,e.sf_pursuing_degree_type
      ,e.sf_start_date
      ,e.sf_actual_end
      ,ISNULL(e.sf_nsc_verified, 0) AS sf_nsc_verified

      ,CASE WHEN e.sf_school_name IS NOT NULL THEN 1 ELSE 0 END AS is_record_match
      ,'NSC>SF' AS direction
FROM nsc_link n
LEFT JOIN sf_enr e
  ON n.salesforce_contact_id = e.salesforce_contact_id
 AND n.salesforce_school_id = e.salesforce_school_id
WHERE n.nsc_graduated = 'Y'
  AND n.nsc_degree_title <> ''

UNION ALL

SELECT e.nsc_unique_identifier
      ,e.sf_first_name AS student_first_name
      ,e.sf_last_name AS student_last_name
      ,e.sf_school_name AS college_name

      ,n.nsc_degree_title
      ,n.nsc_enrollment_start
      ,n.nsc_enrollment_end

      ,e.sf_pursuing_degree_type
      ,e.sf_start_date
      ,e.sf_actual_end
      ,ISNULL(e.sf_nsc_verified, 0) AS sf_nsc_verified

      ,CASE WHEN n.nsc_college_name IS NOT NULL THEN 1 ELSE 0 END AS is_record_match
      ,'SF>NSC' AS direction
FROM sf_enr e
LEFT JOIN nsc_link n
  ON e.salesforce_contact_id = n.salesforce_contact_id
 AND e.salesforce_school_id = n.salesforce_school_id
 AND n.nsc_graduated = 'Y'
 AND n.nsc_degree_title <> ''
WHERE e.sf_status = 'Graduated'
  AND e.nsc_unique_identifier IS NOT NULL

/* FIRST ENROLLMENT */
-- ...

/*
Questions:
NEW
- ugrad only?
- why is there a discrepancy between number of students in SF vs NSC? who are they?
OLDER
- would [dbo].[NSC_College_Data_Raw_HS_Grads] better? (has college sequence)
- which schools aren't matching crosswalk/SF and why?

TODO
- Dashboard:
    * add KTX region/school
    * add KTC counselor
- match SF:
    * matriculated enrollment
- audit fields:
    * start date (first enrollment)
    * NSC query file (Flat_KIPP_Graduates) - does DOB match SalesForce?
*/