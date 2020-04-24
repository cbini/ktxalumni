CREATE OR ALTER VIEW dbo.SF_TAF_Roster AS 

WITH enrollments AS (
  SELECT enr.Student__c AS salesforce_contact_id
        ,enr.Type__c AS enrollment_type
        ,enr.Status__c AS enrollment_status
        ,enr.Start_Date__c AS [enrollment_start_date]

        ,a.[Name] AS enrollment_name

        ,ROW_NUMBER() OVER(
           PARTITION BY enr.Student__c
             ORDER BY enr.Start_Date__c DESC) AS rn
  FROM dbo.SF_Enrollment_C enr
  JOIN dbo.SF_Account a
    ON enr.School__c = a.Id
  WHERE enr.IsDeleted = 0
 )

SELECT r.school_specific_id
      ,r.first_name
      ,r.last_name
      ,r.terminal_school_name
      ,r.kipp_hs_class
      ,r.expected_hs_graduation_date
      ,r.counselor_name
      ,r.home_phone
      ,r.mobile_phone
      ,r.other_phone
      ,r.email

      ,enr.enrollment_type
      ,enr.enrollment_name
      ,enr.enrollment_status
FROM dbo.SF_KTC_Roster r
LEFT JOIN enrollments enr
  ON r.salesforce_contact_id = enr.salesforce_contact_id
 AND enr.rn = 1
WHERE r.ktc_status IN ('TAF', 'TAFHS')