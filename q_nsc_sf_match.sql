WITH cur_year AS (
  SELECT MAX([year]) AS max_year
  FROM ktx_analytics.dbo.flat_region_year_dates
  WHERE SYSDATETIME() BETWEEN [start_date] AND end_date
 )

,school_identifiers AS (
  SELECT school_id
        ,LEFT(region, 1) AS region_initial
        ,CASE 
          WHEN school = 'KIPP Northeast College Prep' THEN 'KIPP Northeast College Preparatory' 
          WHEN school = 'KIPP Austin Brave' THEN 'KIPP Austin Brave High School'
          WHEN school = 'KIPP Connect High School' THEN 'KIPP CONNECT Houston High School'
          ELSE school 
         END AS school
  FROM ktx_analytics.dbo.school_names_table
  WHERE academic_year = (SELECT max_year FROM cur_year)
 )

,enrollments AS (
  SELECT enr.student__c AS salesforce_contact_id
        ,ROW_NUMBER() OVER(
           PARTITION BY enr.student__c 
             ORDER BY COALESCE(enr.actual_end_date__c, SYSDATETIME()) DESC) AS rn_enr

        ,a.[name] AS school_name
  FROM ktx_analytics.dbo.sf_enrollment_c enr
  JOIN ktx_analytics.dbo.sf_account a
    ON enr.school__c = a.id
  WHERE enr.account_type__c = 'KIPP High School'
    AND enr.status__c <> 'Did Not Enroll'
    AND enr.isdeleted = 0
 )

,student_roster AS (
  SELECT sf.salesforce_contact_id
        ,sf.school_specific_id
        ,sf.first_name
        ,sf.last_name
        ,RIGHT(CONCAT('000000', sf.school_specific_id), 6) AS mod_school_specific_id

        ,enr.school_name
        
        ,sch.school_id
        ,sch.region_initial

        ,sch.school_id
          + RIGHT(CONCAT('000000', sf.school_specific_id), 6)
          + sch.region_initial
          AS nsc_unique_identifier

  FROM ktx_analytics.dbo.sf_ktc_roster sf
  JOIN enrollments enr
    ON sf.salesforce_contact_id = enr.salesforce_contact_id
   AND enr.rn_enr = 1
  LEFT JOIN school_identifiers sch
    ON enr.school_name = sch.school
  --WHERE sf.ktc_status = 'HSG'
 )

SELECT r.*

      ,SUBSTRING(nsc.[unique], 4, 6) AS correct_student_id
      ,nsc.[unique]
      ,nsc.[record found]
      ,nsc.[first name]
      ,nsc.[last name]
      ,nsc.[college code]
      ,nsc.[college name]
      ,nsc.[college category]
      ,nsc.[college type]
      ,nsc.[enrollment start]
      ,nsc.[enrollment end]
      ,nsc.[enrollment status]
      ,nsc.graduated
      ,nsc.[college grad date]
      ,nsc.[degree title]
      ,nsc.major
FROM ktx_analytics.dbo.nsc_hs_grad_college_data nsc
LEFT JOIN student_roster r
  ON nsc.[unique] = r.nsc_unique_identifier
