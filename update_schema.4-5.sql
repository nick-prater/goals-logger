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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE clip_categories(
  clip_category_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  category_code VARCHAR(30) NOT NULL,
  display_name VARCHAR(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO clip_categories(clip_category_id, category_code, display_name) VALUES
  (1, 'goal', 'Goal'),
  (2, 'half_time_report', 'Half-Time'),
  (3, 'full_time_report', 'Full-Time'),
  (4, 'interview', 'Interview'),
  (5, 'commercial', 'Commercial'),
  (6, 'other', 'Other'),
  (7, 'package', 'Package');

ALTER TABLE clips ADD COLUMN category_id INT UNSIGNED
  NOT NULL
  DEFAULT 6;

ALTER TABLE clips ADD CONSTRAINT clips_fk4
  FOREIGN KEY (category_id)
  REFERENCES clip_categories(clip_category_id);

UPDATE clips SET category_id = category+0;
ALTER TABLE clips DROP COLUMN category;

