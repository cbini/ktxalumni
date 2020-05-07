WITH enrollments AS (
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
  WHERE academic_year = (SELECT MAX([year]) AS max_year
                         FROM ktx_analytics.dbo.flat_region_year_dates
                         WHERE SYSDATETIME() BETWEEN [start_date] AND end_date)
 )

,student_roster AS (
  SELECT sub.salesforce_contact_id
        ,sub.school_id
           + sub.school_specific_id_clean
           + sub.region_initial
             AS nsc_unique_identifier
  FROM
      (
       SELECT sf.salesforce_contact_id
             ,CASE
               WHEN sf.school_specific_id IS NULL THEN NULL
               ELSE RIGHT(CONCAT('000000', sf.school_specific_id), 6) 
              END AS school_specific_id_clean

             ,sch.school_id
             ,sch.region_initial
       FROM ktx_analytics.dbo.sf_ktc_roster sf
       JOIN enrollments enr
         ON sf.salesforce_contact_id = enr.salesforce_contact_id
        AND enr.rn_enr = 1
       LEFT JOIN school_identifiers sch
         ON enr.school_name = sch.school
      ) sub
 )

SELECT nsc.[unique]
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

      ,r.salesforce_contact_id
FROM ktx_analytics.dbo.nsc_hs_grad_college_data nsc
LEFT JOIN student_roster r
  ON nsc.[unique] = r.nsc_unique_identifier
