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

      ,a.id AS salesforce_school_id
FROM ktx_analytics.dbo.nsc_hs_grad_college_data nsc
LEFT JOIN ktx_analytics.dbo.sf_ktc_roster r
  ON nsc.[unique] = r.nsc_unique_identifier
LEFT JOIN ktx_analytics.dbo.nsc_college_code_crosswalk cw
  ON nsc.[college code] = cw.nsc_college_code
LEFT JOIN ktx_analytics.dbo.sf_account a
  ON cw.ipeds_unit_id = a.ncesid__c
 AND a.isdeleted = 0
WHERE nsc.[Record Found] = 'Y'
-- JOIN SF account to enrollments

/*
MATCH SF:
 - graduated enrollments
 - first enrollment

Q?
- would NSC_College_Data_Raw_HS_Grads better? (has college sequence)
- which schools aren't matching crosswalk/SF and why?
*/