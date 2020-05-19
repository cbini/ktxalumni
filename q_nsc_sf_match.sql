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
LEFT JOIN ktx_analytics.dbo.sf_ktc_roster r
  ON nsc.[unique] = r.nsc_unique_identifier
-- JOIN nsc code to crosswalk
-- JOIN crosswalk to SF account