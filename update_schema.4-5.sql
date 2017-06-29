UPDATE config SET parameter_value = 5 WHERE parameter_key = 'schema_version';

ALTER TABLE clips ADD COLUMN deleted_timestamp TIMESTAMP NULL;

ALTER TABLE clips MODIFY profile_id INT UNSIGNED NOT NULL;
ALTER TABLE buttons MODIFY profile_id INT UNSIGNED NOT NULL;
ALTER TABLE channels MODIFY profile_id INT UNSIGNED NOT NULL;

CREATE TABLE playlists(
  playlist_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL DEFAULT '',
  profile_id INT UNSIGNED NOT NULL,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  update_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  data JSON NOT NULL,
  FOREIGN KEY (profile_id) REFERENCES profiles (profile_id)
);


