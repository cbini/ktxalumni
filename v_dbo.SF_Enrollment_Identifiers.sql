CREATE OR ALTER VIEW dbo.SF_Enrollment_Identifiers AS

WITH enrollments AS (
  SELECT sub.salesforce_contact_id
        ,MAX(CASE WHEN sub.pursuing_degree_level = 'College' AND sub.rn_degree_desc = 1 THEN sub.enrollment_id END) AS college_enrollment_id
        ,MAX(CASE WHEN sub.pursuing_degree_level = 'Vocational' AND sub.rn_degree_desc = 1 THEN sub.enrollment_id END) AS vocational_enrollment_id
        ,MAX(CASE WHEN sub.pursuing_degree_level = 'Secondary' AND sub.rn_degree_desc = 1 THEN sub.enrollment_id END) AS secondary_enrollment_id
        ,MAX(CASE WHEN sub.pursuing_degree_level = 'Graduate' AND sub.rn_degree_desc = 1 THEN sub.enrollment_id END) AS graduate_enrollment_id
        ,MAX(CASE WHEN sub.pursuing_degree_level = 'College' AND sub.rn_degree_asc = 1 AND sub.is_ecc_dated = 1 THEN sub.enrollment_id END) AS ecc_enrollment_id
        ,MAX(CASE WHEN sub.rn_current = 1 THEN sub.enrollment_id END) AS curr_enrollment_id
  FROM
      (
       SELECT sub.salesforce_contact_id
             ,sub.enrollment_id
             ,sub.pursuing_degree_level
             ,CASE WHEN sub.ecc_date BETWEEN sub.enrollment_start_date AND sub.enrollment_actual_end_date THEN 1 ELSE 0 END AS is_ecc_dated
             ,ROW_NUMBER() OVER(
                PARTITION BY sub.salesforce_contact_id, sub.pursuing_degree_level
                  ORDER BY sub.enrollment_start_date ASC, sub.enrollment_actual_end_date ASC) AS rn_degree_asc
             ,ROW_NUMBER() OVER(
                PARTITION BY sub.salesforce_contact_id, sub.pursuing_degree_level
                  ORDER BY sub.is_graduated DESC, sub.enrollment_start_date DESC, sub.enrollment_actual_end_date DESC) AS rn_degree_desc
             ,ROW_NUMBER() OVER(
                PARTITION BY sub.salesforce_contact_id
                  ORDER BY sub.enrollment_start_date DESC, sub.enrollment_actual_end_date DESC) AS rn_current
       FROM
           (
            SELECT e.Student__c AS salesforce_contact_id
                  ,e.Id AS enrollment_id
                  ,e.Start_Date__c AS enrollment_start_date
                  ,COALESCE(e.Actual_End_Date__c, CONVERT(DATE, GETDATE())) AS enrollment_actual_end_date
                  ,CASE WHEN e.Status__c = 'Graduated' THEN 1 ELSE 0 END AS is_graduated
                  ,CASE
                    WHEN e.Pursuing_Degree_Type__c IN ('Bachelor''s (4-year)', 'Associate''s (2 year)') THEN 'College'
                    WHEN e.Pursuing_Degree_Type__c IN ('Master''s', 'MBA') THEN 'Graduate'
                    WHEN e.Pursuing_Degree_Type__c IN ('High School Diploma', 'GED') THEN 'Secondary'
                    WHEN e.Pursuing_Degree_Type__c = 'Elementary Certificate' THEN 'Primary'
                    WHEN e.Pursuing_Degree_Type__c = 'Certificate'
                     AND e.Account_Type__c NOT IN ('Traditional Public School', 'Alternative High School', 'KIPP School')
                         THEN 'Vocational'
                   END AS pursuing_degree_level

                  ,DATEFROMPARTS(DATEPART(YEAR,c.Actual_HS_Graduation_Date__c), 10, 31) AS ecc_date
            FROM dbo.SF_Enrollment_C e
            JOIN dbo.SF_Contact c
              ON e.Student__c = c.Id
             AND c.Isdeleted = 0
            WHERE e.IsDeleted = 0
              AND e.Status__c != 'Did Not Enroll'
           ) sub
      ) sub
  GROUP BY sub.salesforce_contact_id
 )

SELECT e.salesforce_contact_id
      ,e.college_enrollment_id AS ugrad_enrollment_id
      ,e.ecc_enrollment_id
      ,e.secondary_enrollment_id AS hs_enrollment_id
      ,e.vocational_enrollment_id AS cte_enrollment_id
      ,e.curr_enrollment_id
      ,e.graduate_enrollment_id

      ,ug.Pursuing_Degree_Type__c AS ugrad_pursuing_degree_type
      ,ug.Status__c AS ugrad_status
      ,ug.Start_Date__c AS ugrad_start_date
      ,ug.Actual_End_Date__c AS ugrad_actual_end_date
      ,ug.Anticipated_Graduation__c AS ugrad_anticipated_graduation
      ,ug.Account_Type__c AS ugrad_account_type
      ,ug.Major__c AS ugrad_major
      ,ug.Major_Area__c AS ugrad_major_area
      ,ug.College_Major_Declared__c AS ugrad_college_major_declared
      ,ug.Date_Last_Verified__c AS ugrad_date_last_verified
      ,uga.[Name] AS ugrad_school_name
      ,uga.BillingState AS ugrad_billing_state
      ,uga.NCESid__c AS ugrad_ncesid

      ,ecc.Pursuing_Degree_Type__c AS ecc_pursuing_degree_type
      ,ecc.Status__c AS ecc_status
      ,ecc.Start_Date__c AS ecc_start_date
      ,ecc.Actual_End_Date__c AS ecc_actual_end_date
      ,ecc.Anticipated_Graduation__c AS ecc_anticipated_graduation
      ,ecc.Account_Type__c AS ecc_account_type
      ,ecca.[Name] AS ecc_school_name
      ,ecca.Adjusted_6_year_minority_graduation_rate__c AS ecc_adjusted_6_year_minority_graduation_rate

      ,hs.Pursuing_Degree_Type__c AS hs_pursuing_degree_type
      ,hs.Status__c AS hs_status
      ,hs.Start_Date__c AS hs_start_date
      ,hs.Actual_End_Date__c AS hs_actual_end_date
      ,hs.Anticipated_Graduation__c AS hs_anticipated_graduation
      ,hs.Account_Type__c AS hs_account_type
      ,hsa.[Name] AS hs_school_name

      ,cte.Pursuing_Degree_Type__c AS cte_pursuing_degree_type
      ,cte.Status__c AS cte_status
      ,cte.Start_Date__c AS cte_start_date
      ,cte.Actual_End_Date__c AS cte_actual_end_date
      ,cte.Anticipated_Graduation__c AS cte_anticipated_graduation
      ,cte.Account_Type__c AS cte_account_type
      ,ctea.[Name] AS cte_school_name
      ,ctea.BillingState AS cte_billing_state
      ,ctea.NCESid__c AS cte_ncesid

      ,cur.Pursuing_Degree_Type__c AS cur_pursuing_degree_type
      ,cur.Status__c AS cur_status
      ,cur.Start_Date__c AS cur_start_date
      ,cur.Actual_End_Date__c AS cur_actual_end_date
      ,cur.Anticipated_Graduation__c AS cur_anticipated_graduation
      ,cur.Account_Type__c AS cur_account_type
      ,cura.[Name] AS cur_school_name
      ,cura.BillingState AS cur_billing_state
      ,cura.NCESid__c AS cur_ncesid
      ,cura.Adjusted_6_year_minority_graduation_rate__c AS cur_adjusted_6_year_minority_graduation_rate
FROM enrollments e
LEFT JOIN dbo.SF_Enrollment_C ug
  ON e.college_enrollment_id = ug.Id
LEFT JOIN dbo.SF_Account uga
  ON ug.School__c = uga.Id
LEFT JOIN dbo.SF_Enrollment_C ecc
  ON e.ecc_enrollment_id = ecc.Id
LEFT JOIN dbo.SF_Account ecca
  ON ecc.School__c = ecca.Id
LEFT JOIN dbo.SF_Enrollment_C hs
  ON e.secondary_enrollment_id = hs.Id
LEFT JOIN dbo.SF_Account hsa
  ON hs.School__c = hsa.Id
LEFT JOIN dbo.SF_Enrollment_C cte
  ON e.vocational_enrollment_id = cte.Id
LEFT JOIN dbo.SF_Account ctea
  ON cte.School__c = ctea.Id
LEFT JOIN dbo.SF_Enrollment_C cur
  ON e.curr_enrollment_id = cur.Id
LEFT JOIN dbo.SF_Account cura
  ON cur.School__c = cura.Id
