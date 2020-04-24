CREATE OR ALTER VIEW dbo.SF_Application_Identifiers AS

SELECT sub.salesforce_contact_id
      ,sub.application_id
      ,sub.match_type
      ,sub.application_admission_type
      ,sub.application_submission_status
      ,sub.starting_application_status
      ,sub.application_status
      ,sub.honors_special_program_name
      ,sub.honors_special_program_status
      ,sub.matriculation_decision
      ,sub.primary_reason_for_not_attending
      ,sub.financial_aid_eligibility
      ,sub.unmet_need
      ,sub.efc_from_fafsa
      ,sub.transfer_application
      ,sub.created_date
      ,sub.type_for_roll_ups
      ,sub.application_name
      ,sub.application_account_type
      ,sub.application_enrollment_status
      ,sub.application_pursuing_degree_type
      ,CASE WHEN sub.type_for_roll_ups = 'College' AND sub.application_account_type LIKE '%4 yr' THEN 1 ELSE 0 END AS is_4yr_college
      ,CASE WHEN sub.type_for_roll_ups = 'College' AND sub.application_account_type LIKE '%2 yr' THEN 1 ELSE 0 END AS is_2yr_college
      ,CASE WHEN sub.type_for_roll_ups = 'Alternative Program' THEN 1 ELSE 0 END AS is_cte
      ,CASE WHEN sub.application_admission_type = 'Early Action' THEN 1 ELSE 0 END AS is_early_action
      ,CASE WHEN sub.application_admission_type = 'Early Decision' THEN 1 ELSE 0 END AS is_early_decision
      ,CASE WHEN sub.application_admission_type IN ('Early Action', 'Early Decision') THEN 1 ELSE 0 END AS is_early_actiondecision
      ,CASE WHEN sub.application_submission_status = 'Submitted' THEN 1 ELSE 0 END AS is_submitted
      ,CASE WHEN sub.application_status = 'Accepted' THEN 1 ELSE 0 END AS is_accepted
      ,CASE WHEN sub.match_type IN ('Likely Plus', 'Target', 'Reach') THEN 1 ELSE 0 END AS is_ltr
      ,CASE WHEN sub.starting_application_status = 'Wishlist' THEN 1 ELSE 0 END AS is_wishlist
      ,CASE WHEN sub.honors_special_program_name = 'EOF' AND sub.honors_special_program_status IN ('Applied', 'Accepted') THEN 1 ELSE 0 END AS is_eof_applied
      ,CASE WHEN sub.honors_special_program_name = 'EOF' AND sub.honors_special_program_status = 'Accepted' THEN 1 ELSE 0 END AS is_eof_accepted
FROM
    (
     SELECT app.Applicant__c AS salesforce_contact_id
           ,app.Id AS application_id
           ,app.Match_Type__c AS match_type
           ,app.Application_Admission_Type__c AS application_admission_type
           ,NULL AS application_submission_status
           ,COALESCE(app.Starting_Application_Status__c, app.Application_Status__c) AS starting_application_status
           ,app.Application_Status__c AS application_status
           ,app.Honors_Special_Program_Name__c AS honors_special_program_name
           ,app.Honors_Special_Program_Status__c AS honors_special_program_status
           ,NULL AS matriculation_decision
           ,app.Primary_reason_for_not_attending__c AS primary_reason_for_not_attending
           ,app.Financial_Aid_Eligibility__c AS financial_aid_eligibility
           ,app.Unmet_Need__c AS unmet_need
           ,app.EFC_from_FAFSA__c AS efc_from_fafsa
           ,app.Transfer_Application__c AS transfer_application
           ,app.CreatedDate AS created_date
           ,NULL AS type_for_roll_ups

           ,acc.[Name] AS application_name
           ,acc.[Type] AS application_account_type

           ,enr.Status__c AS application_enrollment_status
           ,enr.Pursuing_Degree_Type__c AS application_pursuing_degree_type
     FROM dbo.SF_Application_C app
     JOIN dbo.SF_Account acc
       ON app.School__c = acc.id
      AND acc.IsDeleted = 0
     JOIN dbo.SF_Contact c
       ON app.Applicant__c = c.id
     LEFT JOIN dbo.SF_Enrollment_C enr
       ON app.Applicant__c = enr.Student__c
      AND app.School__c = enr.School__c
      AND c.KIPP_HS_Class__c = YEAR(enr.Start_Date__c)
      AND enr.IsDeleted = 0
     WHERE app.IsDeleted = 0
    ) sub
