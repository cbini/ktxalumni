--CREATE OR ALTER VIEW alumni.ktc_roster AS

SELECT *
FROM
    (
     SELECT c.id AS sf_contact_id
           ,c.School_Specific_ID__c AS school_specific_id
           ,c.FirstName AS first_name
           ,c.LastName AS last_name
           ,c.Gender__c AS gender
           ,c.Ethnicity__c AS ethnicity
           ,c.KIPP_HS_Class__c AS kipp_hs_class
           ,c.Current_KIPP_Student__c AS current_kipp_student
           ,c.Post_HS_Simple_Admin__c AS post_hs_simple_admin
           ,c.Currently_Enrolled_School__c AS currently_enrolled_school
           ,COALESCE(c.High_School_Graduated_From__c, c.Middle_School_Attended__c) AS terminal_school_name
           ,c.College_Status__c AS college_status
           ,c.Middle_School_Attended__c AS middle_school_attended
           ,c.High_School_Graduated_From__c AS high_school_graduated_from
           ,c.College_Graduated_From__c AS college_graduated_from
           ,c.Grade_Level__c AS terminal_grade_level
           ,c.KIPP_MS_Graduate__c AS is_kipp_ms_graduate
           ,c.KIPP_HS_Graduate__c AS is_kipp_hs_graduate
           ,c.Expected_HS_Graduation__c AS expected_hs_graduation_date
           ,c.Actual_HS_Graduation_Date__c AS actual_hs_graduation_date
           ,c.Expected_College_Graduation__c AS expected_college_graduation_date
           ,c.Actual_College_Graduation_Date__c AS actual_college_graduation_date
           ,c.Informed_Consent__c AS is_informed_consent
           ,c.Transcript_Release__c AS is_transcript_release
           ,c.Latest_Transcript__c AS latest_transcript_date
           ,c.Latest_FAFSA_Date__c AS latest_fafsa_date
           ,c.Latest_State_Financial_Aid_App_Date__c AS latest_state_financial_aid_app_date
           ,c.Cumulative_GPA__c AS cumulative_gpa
           ,c.Current_College_Semester_GPA__c AS current_college_semester_gpa
           ,c.College_Match_Display_GPA__c AS college_match_display_gpa
           ,c.Highest_ACT_Score__c AS highest_act_score
           ,c.College_Credits_Attempted__c AS college_credits_attempted
           ,c.Accumulated_Credits_College__c AS accumulated_credits_college
           ,c.MobilePhone AS mobile_phone
           ,c.HomePhone AS home_phone
           ,c.OtherPhone AS other_phone
           ,c.Email AS email
           ,c.Latest_Resume__c AS latest_resume_date
           ,c.Last_Outreach__c AS last_outreach_date
           ,c.Last_Successful_Contact__c AS last_successful_contact_date
           ,c.Last_Successful_Advisor_Contact__c AS last_successful_advisor_contact_date
           --,co.exitdate AS exit_date
           --,co.exitcode AS exit_code
           --,(gabby.utilities.GLOBAL_ACADEMIC_YEAR() - co.academic_year) + co.grade_level AS current_grade_level_projection
           --,(gabby.utilities.GLOBAL_ACADEMIC_YEAR() + 1) - DATEPART(YEAR, c.actual_hs_graduation_date_c) AS years_out_of_hs

           ,a.[Name] AS kipp_region_name
           
           ,rt.[Name] AS record_type_name

           ,u.id AS counselor_sf_id
           ,u.[name] AS counselor_name

           ,CASE
             WHEN c.KIPP_HS_Graduate__c = 1 THEN 'HSG'
             WHEN rt.[Name] = 'HS Student' AND c.Current_KIPP_Student__c = 'Current KIPP Student' THEN CONCAT('HS', c.Grade_Level__c)
             WHEN rt.[Name] = 'HS Student' AND c.KIPP_MS_Graduate__c = 1 AND c.KIPP_HS_Graduate__c = 0 THEN 'TAFHS'
             WHEN rt.[Name] IN ('College Student', 'Post-Education') AND c.KIPP_MS_Graduate__c = 1 AND c.KIPP_HS_Graduate__c = 0 THEN 'TAF'
            END AS ktc_status
     FROM KTX_Analytics.dbo.SF_Contact c
     JOIN KTX_Analytics.dbo.SF_RecordType rt
       ON c.RecordTypeId = rt.id
      AND rt.[Name] IN ('College Student', 'HS Student', 'MS Student', 'Post-Education')
     JOIN KTX_Analytics.dbo.SF_Account a
       ON c.KIPP_Region_School__c = a.Id
     LEFT JOIN KTX_Analytics.dbo.SF_User u
       ON c.OwnerId = u.id
     WHERE c.IsDeleted = 0
    ) sub
WHERE sub.ktc_status IS NOT NULL