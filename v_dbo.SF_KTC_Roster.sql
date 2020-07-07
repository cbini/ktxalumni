CREATE OR ALTER VIEW dbo.SF_KTC_Roster AS

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

,enrollments AS (
  SELECT enr.student__c AS salesforce_contact_id
        ,ROW_NUMBER() OVER(
           PARTITION BY enr.student__c 
             ORDER BY COALESCE(enr.actual_end_date__c, SYSDATETIME()) DESC) AS rn_enr

        ,a.[name] AS school_name

        ,sch.region_initial
        ,sch.school_id
  FROM ktx_analytics.dbo.sf_enrollment_c enr
  JOIN ktx_analytics.dbo.sf_account a
    ON enr.school__c = a.id
   AND a.billingstate = 'TX'
  LEFT JOIN school_identifiers sch
    ON a.[name] = sch.school
  WHERE enr.account_type__c = 'KIPP High School'
    AND enr.status__c <> 'Did Not Enroll'
    AND enr.isdeleted = 0
 )

SELECT sub.salesforce_contact_id
      ,sub.school_specific_id
      ,sub.first_name
      ,sub.last_name
      ,sub.ktc_status
      ,sub.kipp_region_name
      ,sub.currently_enrolled_school
      ,sub.kipp_hs_class
      ,sub.record_type_name
      ,sub.current_kipp_student
      ,sub.post_hs_simple_admin
      ,sub.counselor_sf_id
      ,sub.counselor_name
      ,sub.gender
      ,sub.ethnicity
      ,sub.birthdate
      ,sub.mobile_phone
      ,sub.home_phone
      ,sub.other_phone
      ,sub.email
      ,sub.terminal_school_name
      ,sub.terminal_grade_level
      ,sub.middle_school_attended
      ,sub.high_school_graduated_from
      ,sub.college_graduated_from
      ,sub.is_kipp_ms_graduate
      ,sub.is_kipp_hs_graduate
      ,sub.expected_hs_graduation_date
      ,sub.actual_hs_graduation_date
      ,sub.college_status
      ,sub.cumulative_gpa
      ,sub.current_college_semester_gpa
      ,sub.college_credits_attempted
      ,sub.accumulated_credits_college
      ,sub.expected_college_graduation_date
      ,sub.actual_college_graduation_date
      ,sub.latest_transcript_date
      ,sub.is_informed_consent
      ,sub.is_transcript_release
      ,sub.highest_act_score
      ,sub.college_match_display_gpa
      ,sub.latest_resume_date
      ,sub.latest_fafsa_date
      ,sub.latest_state_financial_aid_app_date
      ,sub.last_outreach_date
      ,sub.last_successful_contact_date
      ,sub.last_successful_advisor_contact_date
      ,sub.school_id
           + sub.school_specific_id_clean
           + sub.region_initial
               AS nsc_unique_identifier
FROM
    (
     SELECT c.id AS salesforce_contact_id
           ,c.school_specific_id__c AS school_specific_id
           ,c.firstname AS first_name
           ,c.lastname AS last_name
           ,c.gender__c AS gender
           ,c.ethnicity__c AS ethnicity
           ,c.birthdate
           ,c.kipp_hs_class__c AS kipp_hs_class
           ,c.current_kipp_student__c AS current_kipp_student
           ,c.post_hs_simple_admin__c AS post_hs_simple_admin
           ,c.currently_enrolled_school__c AS currently_enrolled_school
           ,c.college_status__c AS college_status
           ,c.middle_school_attended__c AS middle_school_attended
           ,c.high_school_graduated_from__c AS high_school_graduated_from
           ,c.college_graduated_from__c AS college_graduated_from
           ,c.grade_level__c AS terminal_grade_level
           ,c.kipp_ms_graduate__c AS is_kipp_ms_graduate
           ,c.kipp_hs_graduate__c AS is_kipp_hs_graduate
           ,c.expected_hs_graduation__c AS expected_hs_graduation_date
           ,c.actual_hs_graduation_date__c AS actual_hs_graduation_date
           ,c.expected_college_graduation__c AS expected_college_graduation_date
           ,c.actual_college_graduation_date__c AS actual_college_graduation_date
           ,c.informed_consent__c AS is_informed_consent
           ,c.transcript_release__c AS is_transcript_release
           ,c.latest_transcript__c AS latest_transcript_date
           ,c.latest_fafsa_date__c AS latest_fafsa_date
           ,c.latest_state_financial_aid_app_date__c AS latest_state_financial_aid_app_date
           ,c.cumulative_gpa__c AS cumulative_gpa
           ,c.current_college_semester_gpa__c AS current_college_semester_gpa
           ,c.college_match_display_gpa__c AS college_match_display_gpa
           ,c.highest_act_score__c AS highest_act_score
           ,c.college_credits_attempted__c AS college_credits_attempted
           ,c.accumulated_credits_college__c AS accumulated_credits_college
           ,c.mobilephone AS mobile_phone
           ,c.homephone AS home_phone
           ,c.otherphone AS other_phone
           ,c.email AS email
           ,c.latest_resume__c AS latest_resume_date
           ,c.last_outreach__c AS last_outreach_date
           ,c.last_successful_contact__c AS last_successful_contact_date
           ,c.last_successful_advisor_contact__c AS last_successful_advisor_contact_date
           ,COALESCE(c.high_school_graduated_from__c, c.middle_school_attended__c) AS terminal_school_name
           ,CASE
             WHEN c.school_specific_id__c IS NULL THEN NULL
             ELSE RIGHT(CONCAT('000000', c.school_specific_id__c), 6) 
            END AS school_specific_id_clean

           ,a.[name] AS kipp_region_name
           
           ,rt.[name] AS record_type_name

           ,u.id AS counselor_sf_id
           ,u.[name] AS counselor_name

           ,enr.region_initial
           ,enr.school_id

           ,CASE
             WHEN c.kipp_hs_graduate__c = 1 THEN 'HSG'
             WHEN rt.[name] = 'HS Student' AND c.current_kipp_student__c = 'Current KIPP Student' THEN CONCAT('HS', c.grade_level__c)
             WHEN rt.[name] = 'HS Student' AND c.current_kipp_student__c = 'Not Enrolled at a KIPP School' AND c.kipp_ms_graduate__c = 1 THEN 'KMSA'
             WHEN rt.[name] IN ('College Student', 'Post-Education') AND c.kipp_ms_graduate__c = 1 THEN 'KMSA'
            END AS ktc_status
     FROM KTX_Analytics.dbo.sf_contact c
     JOIN KTX_Analytics.dbo.sf_recordtype rt
       ON c.recordtypeid = rt.id
      AND rt.[name] IN ('College Student', 'HS Student', 'MS Student', 'Post-Education')
     JOIN ktx_analytics.dbo.sf_account a
       ON c.kipp_region_school__c = a.id
     LEFT JOIN ktx_analytics.dbo.sf_user u
       ON c.ownerid = u.id
     LEFT JOIN enrollments enr
       ON c.id = enr.salesforce_contact_id
      AND enr.rn_enr = 1
     WHERE c.isdeleted = 0
    ) sub
