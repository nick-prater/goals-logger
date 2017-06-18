
UPDATE config SET parameter_value = 5 WHERE parameter_key = 'schema_version';
ALTER TABLE clips ADD COLUMN deleted_timestamp TIMESTAMP NULL;


