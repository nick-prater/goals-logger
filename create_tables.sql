/* Run these SQL commands as mysql root user */


/* **************************************** */
/* *** THIS DELETES ANY EXISTING DATA!! *** */
/* **************************************** */

DROP DATABASE IF EXISTS goals;
DROP USER IF EXISTS 'goals'@'localhost';


CREATE DATABASE goals;
CREATE USER 'goals'@'localhost' IDENTIFIED BY 'mysql1625';
GRANT SELECT, INSERT, UPDATE, DELETE ON goals.* TO 'goals'@'localhost';
FLUSH PRIVILEGES;
USE goals;


/*  Using InnoDB tables rather than default MyISAM because they support
 *  automatic foreign key constraints. Catalyst
 *  relies on this to automatically set up the database access class
 *  and to cascade delete across tables.
 */

CREATE TABLE profiles(
  profile_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  profile_code CHAR(30) NOT NULL UNIQUE KEY,
  display_name VARCHAR(50) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/* For the future, allow arbitrary labels via a separate table, with history tracking */
CREATE TABLE channels(
  channel_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  source VARCHAR(50),                  /* e.g. alsa_pcm:capture_1  */
  source_label VARCHAR(50),            /* short label, e.g. COMM-1 */
  match_title VARCHAR(50),             /* e.g. Man U v Liverpool   */
  commentator VARCHAR(50),             /* e.g. Jim Proudfoot       */
  timezone VARCHAR(30) DEFAULT 'Europe/London' NOT NULL,
  profile_id INT UNSIGNED,
  recording ENUM('yes', 'no') NOT NULL DEFAULT 'yes',
  CONSTRAINT channels_fk1
    FOREIGN KEY (profile_id)
    REFERENCES profiles(profile_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `event_inputs` (
  `event_input_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(200) DEFAULT NULL,
  `input_type` enum('hardware_gpi') NOT NULL,
  `event_type` enum('audio_marker') NOT NULL,
  `channel_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`event_input_id`),
  KEY `event_inputs_fk1` (`channel_id`),
  CONSTRAINT `event_inputs_fk1` 
    FOREIGN KEY (`channel_id`) 
    REFERENCES `channels` (`channel_id`) 
    ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;


CREATE TABLE events(
  event_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  event_input_id INT UNSIGNED NOT NULL,
  event_timestamp TIMESTAMP NOT NULL DEFAULT 0,
  event_type ENUM('on', 'off', 'instance') NOT NULL,
  status ENUM('new', 'open', 'exported', 'deleted') NOT NULL DEFAULT 'new',
  update_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT events_fk1
    FOREIGN KEY (event_input_id)
    REFERENCES event_inputs (event_input_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE clips(
  /* This caches various items of metadata, so we still have a record of
     the clip origin, even if the original source events and channels have
     long-since changed or disappeared
   */
  clip_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  source ENUM('clip_editor', 'user_upload') DEFAULT 'clip_editor' NOT NULL,
  status ENUM('processing', 'complete', 'deleted') DEFAULT 'processing' NOT NULL,
  title VARCHAR(200),
  people VARCHAR(200),
  description VARCHAR(1000),
  out_cue VARCHAR(200),
  category ENUM('goal', 'half_time_report', 'full_time_report', 'interview', 'commercial', 'other') NOT NULL,
  language ENUM('english', 'spanish', 'mandarin', 'other'),
  duration_seconds INTEGER UNSIGNED,
  source_label VARCHAR(50),            /* short label, e.g. COMM-1 */
  match_title VARCHAR(50),             /* e.g. Man U v Liverpool   */
  commentator VARCHAR(50),             /* e.g. Jim Proudfoot       */
  channel_id INT UNSIGNED,
  event_id INT UNSIGNED,
  clip_start_timestamp TIMESTAMP NOT NULL DEFAULT 0,
  clip_end_timestamp TIMESTAMP NOT NULL DEFAULT 0,
  profile_id INT UNSIGNED,
  CONSTRAINT `clips_fk1` 
    FOREIGN KEY (`channel_id`) 
    REFERENCES `channels` (`channel_id`),
  CONSTRAINT `clips_fk2` 
    FOREIGN KEY (`event_id`) 
    REFERENCES `events` (`event_id`),
  CONSTRAINT `clips_fk3`
    FOREIGN KEY (profile_id)
    REFERENCES profiles(profile_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/* These correspond to hotkeys on the playout system */
CREATE TABLE buttons(
  button_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  clip_id INT UNSIGNED,
  profile_id INT UNSIGNED
  CONSTRAINT `buttons_fk1` 
    FOREIGN KEY (`clip_id`) 
    REFERENCES `clips` (`clip_id`),
  CONSTRAINT `buttons_fk2` 
    FOREIGN KEY (`profile_id`) 
    REFERENCES `profiles` (`profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/* At present this table is simply used to keep track of the 
 * database schema version we're at */
CREATE TABLE config(
  parameter_key VARCHAR(100) NOT NULL PRIMARY KEY,
  parameter_value VARCHAR(1023)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO config VALUES ('schema_version', '3');


/* Populate some test data */
INSERT INTO profiles VALUES(1, 'english', 'English');

INSERT INTO channels VALUES (1, NULL, 'C1', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (2, NULL, 'C2', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (3, NULL, 'C3', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (4, NULL, 'C4', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (5, NULL, 'C5', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (6, NULL, 'C6', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (7, NULL, 'spare1', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (8, NULL, 'spare2', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (9, NULL, 'spare3', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (10, NULL, 'spare4', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (11, NULL, 'spare5', NULL, NULL, NULL, 'Europe/London', 1);
INSERT INTO channels VALUES (12, NULL, 'spare6', NULL, NULL, NULL, 'Europe/London', 1);

INSERT INTO event_inputs VALUES (1, 'Marker Button 1', 'hardware_gpi', 'audio_marker', 1);
INSERT INTO event_inputs VALUES (2, 'Marker Button 2', 'hardware_gpi', 'audio_marker', 2);
INSERT INTO event_inputs VALUES (3, 'Marker Button 3', 'hardware_gpi', 'audio_marker', 3);
INSERT INTO event_inputs VALUES (4, 'Marker Button 4', 'hardware_gpi', 'audio_marker', 4);
INSERT INTO event_inputs VALUES (5, 'Marker Button 5', 'hardware_gpi', 'audio_marker', 5);
INSERT INTO event_inputs VALUES (6, 'Marker Button 6', 'hardware_gpi', 'audio_marker', 6);
INSERT INTO event_inputs VALUES (7, 'Marker Button 7', 'hardware_gpi', 'audio_marker', 7);
INSERT INTO event_inputs VALUES (8, 'Marker Button 8', 'hardware_gpi', 'audio_marker', 8);
INSERT INTO event_inputs VALUES (9, 'Marker Button 9', 'hardware_gpi', 'audio_marker', 9);
INSERT INTO event_inputs VALUES (10, 'Marker Button 10', 'hardware_gpi', 'audio_marker', 10);
INSERT INTO event_inputs VALUES (11, 'Marker Button 11', 'hardware_gpi', 'audio_marker', 11);
INSERT INTO event_inputs VALUES (12, 'Marker Button 12', 'hardware_gpi', 'audio_marker', 12);

/* start with 20 blank buttons */
INSERT INTO buttons VALUES(1,NULL,1);
INSERT INTO buttons VALUES(2,NULL,1);
INSERT INTO buttons VALUES(3,NULL,1);
INSERT INTO buttons VALUES(4,NULL,1);
INSERT INTO buttons VALUES(5,NULL,1);
INSERT INTO buttons VALUES(6,NULL,1);
INSERT INTO buttons VALUES(7,NULL,1);
INSERT INTO buttons VALUES(8,NULL,1);
INSERT INTO buttons VALUES(9,NULL,1);
INSERT INTO buttons VALUES(10,NULL,1);
INSERT INTO buttons VALUES(11,NULL,1);
INSERT INTO buttons VALUES(12,NULL,1);
INSERT INTO buttons VALUES(13,NULL,1);
INSERT INTO buttons VALUES(14,NULL,1);
INSERT INTO buttons VALUES(15,NULL,1);
INSERT INTO buttons VALUES(16,NULL,1);
INSERT INTO buttons VALUES(17,NULL,1);
INSERT INTO buttons VALUES(18,NULL,1);
INSERT INTO buttons VALUES(19,NULL,1);
INSERT INTO buttons VALUES(20,NULL,1);
