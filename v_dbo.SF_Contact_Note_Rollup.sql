CREATE OR ALTER VIEW dbo.SF_Contact_Note_Rollup AS

SELECT salesforce_contact_id
      ,academic_year
      ,contact_term
      ,[Academic]
      ,[Behavioral]
      ,[Benchmark]
      ,[BenchmarkFollowUp]
      ,[Career]
      ,[CoachingIntervention]
      ,[CollegePlacement]
      ,[Financial]
      ,[Logistical]
      ,[MotivationalMessage]
      ,[Placement]
      ,[PulseCheck]
      ,[Social]
FROM
    (
     SELECT c.Contact__c AS salesforce_contact_id
           ,CASE 
             WHEN MONTH(c.Date__c) >= 7 THEN YEAR(c.Date__c)
             WHEN MONTH(c.Date__c) < 7 THEN YEAR(c.Date__c) - 1
            END AS academic_year
           ,CASE 
             WHEN MONTH(c.Date__c) >= 7 THEN 'Fall'
             WHEN MONTH(c.Date__c) < 7 THEN 'Spring'
            END AS contact_term
           ,1 AS N

           ,REPLACE(REPLACE(REPLACE(s.[value], ' ', ''), '-', ''), '/', '') AS contact_subject
     FROM dbo.SF_contact_note_c c
     CROSS APPLY STRING_SPLIT(c.Category__c, ';') s
     WHERE c.IsDeleted = 0
    ) sub
PIVOT(
  SUM(N)
  FOR contact_subject IN ([Academic]
                         ,[Behavioral]
                         ,[Benchmark]
                         ,[BenchmarkFollowUp]
                         ,[Career]
                         ,[CoachingIntervention]
                         ,[CollegePlacement]
                         ,[Financial]
                         ,[Logistical]
                         ,[MotivationalMessage]
                         ,[Placement]
                         ,[PulseCheck]
                         ,[Social])
 ) p