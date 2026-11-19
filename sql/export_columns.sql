-- Finder / FDB — 16 core tables, schema-only, read-only.
-- Execute manually in Google BigQuery; this query reads metadata only.
-- Save the output as a schema catalog for SQL study.
SELECT
  table_name,
  ordinal_position,
  column_name,
  data_type,
  is_nullable
FROM `fdb-sql-lab.fdb.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN (
  'New_Company',
  'New_Member',
  'News',
  'CompanyNews',
  'New_Company_news',
  'BaseClassificationModel',
  'BaseClassificationRelationModel',
  'BaseClassificationCompanyModel',
  'New_Tag',
  'New_Company_Tag',
  'BaseEvent',
  'BaseEvent_investors',
  'BaseEvent_grantors',
  'New_Funding_Round',
  'New_Funding_Round_known_investors',
  'New_Funding_Round_unknown_investors'
)
ORDER BY table_name, ordinal_position;
