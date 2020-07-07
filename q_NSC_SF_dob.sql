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
  SELECT fkg.[First Name] AS first_name
        ,fkg.[Last Name] AS last_name
        ,CONVERT(DATE, fkg.DOB) AS nsc_query_dob
        ,fkg.[campus id]
           + fkg.[student id]
           + si.region_initial AS nsc_unique_identifier
  FROM ktx_analytics.dbo.flat_kipp_graduates fkg
  JOIN school_identifiers si
    ON fkg.[campus id] = si.school_id
 )

SELECT *
      ,CASE 
        WHEN sub.salesforce_contact_id IS NOT NULL THEN 1 
        ELSE 0 
       END AS sf_match
FROM
    (
     SELECT d.nsc_unique_identifier
           ,d.first_name
           ,d.last_name
           ,d.nsc_query_dob

           ,r.salesforce_contact_id
           ,r.birthdate AS sf_dob

           ,CASE 
             WHEN d.nsc_query_dob = r.birthdate THEN 1 
             ELSE 0 
            END AS dob_match
     FROM demographics d
     LEFT JOIN ktx_analytics.dbo.sf_ktc_roster r
       ON d.nsc_unique_identifier = r.nsc_unique_identifier
    ) sub
WHERE dob_match = 0
ORDER BY sf_match DESC