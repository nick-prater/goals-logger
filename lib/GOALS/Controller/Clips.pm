package GOALS::Controller::Clips;
use Moose;
use namespace::autoclean;
use JSON;
use File::Slurp;
use DateTime;
use DateTime::Format::Strptime;
use File::Copy;
use File::Find;
use Audio::Wav;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

GOALS::Controller::Clips - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched GOALS::Controller::Clips in Clips.');
}


sub delete : Path('delete') : Args(1) {

	my $self = shift;
	my $c = shift;
	my $clip_id = shift;
		
	# Deleting a clip really does delete it. Maybe in future we should
	# have a grace period and an undelete feature? Like we do for events.
	# The clips table already has a 'deleted' value for status. We would need
	# to add an update_timestamp field.
	
	$c->log->debug("deleting clip $clip_id");
	
	# Remove database record
	$c->log->debug("removing database record for clip $clip_id");
	my $rs = $c->model('DB::Clip');
	my $clip = $rs->find({
		clip_id => $clip_id
	}) or do {
		die "No such event";
	};
	
	my $profile_code = $clip->profile->profile_code;
	$c->log->debug("clip has profile code: $profile_code");
	
	$clip->delete or do {
		$c->error("problem deleting clip_id=$clip_id from database");
		die;
	};
	
	# Remove wav file
	my $clip_dir = $c->config->{clips_path} . "/$profile_code";
	unless( $clip_dir && -d $clip_dir ) {
		$c->error("ERROR: either clips_path is undefined in configuration file, or it is not a valid directory path");
		die;
	}
	
	my $clip_path = sprintf(
		"%s/%u.wav",
		$clip_dir,
		$clip_id
	);
	
	$c->log->debug("deleting file $clip_path");
	unlink($clip_path) or do {
		$c->error("ERROR deleting file $clip_path: $!");
		die;	
	};
	
	# We should return something more meaningful, but for now OK is fine
	$c->response->content_type('text/plain');
	$c->response->body("OK\nevent_id=" . $clip->clip_id);	
}


sub purge_deleted : Local {

	# This shouldn't normally be required, but is useful for cleaning up
	# old systems which never actually deleted clips from the database
	# or filesystem. More recent versions do this immediately the user
	# clicks 'delete'.
	#
	# When called, it removes all clip records where status='deleted'
	# and looks for all files in the clips directory matching /^\d+\.wav$/,
	# unlinking those that do not have a corresponding clip record.
	#
	# Note that Neil's playout directory uses the same directory to hold
	# ads and fillers. These shouldn't be named so that they collide with
	# the clips name format, but there is always that possibility. A 
	# separate directory would have been better, but the playout software
	# doesn't support that.
	
	my $self = shift;
	my $c = shift;
	my $clip_id = shift;
	
	# Purge database records
	my $rs = $c->model('DB::Clip');
	my $where = {};
	
	$c->log->debug("purging from database clips marked as 'deleted'");
	
	$where->{status} = 'deleted';
	my $clips = $rs->search($where);
	$clips->delete;
	
	# Purge filesystem
	my $clip_dir = $c->config->{clips_path};
	unless( $clip_dir && -d $clip_dir ) {
		$c->error("ERROR: either clips_path is undefined in configuration file, or it is not a valid directory path");
		die;
	}
	
	# Do a recursive search of clip dir
	$c->log->debug("recursively searching $clip_dir for clip audio files");
	find(
		sub {
			$c->log->debug("considering $File::Find::name");
		
			# Only process ordinary files
			-f $File::Find::name or next;
			
			# Only process files matching standard clip format
			my ($clip_id) = m/^(\d+)\.wav$/ or next;
			
			$c->log->debug("found audio file corresponding to clip_id $clip_id");

			# See if corresponding record exists in database
			my $clip = $rs->find({
				clip_id => $clip_id
			});
			
			# Delete file if it is no longer active
			if ($clip) {
				$c->log->debug("file maps to an active clip - OK");
			}
			else {
				$c->log->debug("file does not map to an active clip - deleting");
				unlink($File::Find::name) or do {
					$c->error("ERROR deleting $File::Find::name : $!");
				};
			}
		},
		$clip_dir
	);
	
	# We should return something more meaningful, but for now OK is fine
	$c->response->content_type('text/plain');
	$c->response->body("OK\n");
}


sub rename : Local : Args(1) {

	my $self = shift;
	my $c = shift;
	my $clip_id = shift;

	$c->log->debug("updating clip_id $clip_id");
	
	my $rs = $c->model('DB::Clip');
	
	my $clip = $rs->find({
		clip_id => $clip_id
	}) or do {
		die "No such clip";
	};

	# Trim whitespace and Log submitted data
	my $params = $c->request->body_params;
	foreach (keys %{$params}) {
		$params->{$_} = trim_whitespace( $params->{$_} );
		$c->log->debug("$_ :: $params->{$_}");
	}

	# Create a clip row - set to processing until we're ready with audio
	$clip->update({		
		title => $params->{title},
		people => $params->{people},
		description => $params->{description},
		out_cue => $params->{out_cue},
		category => $params->{category},
		language => $params->{language},
	}) or do {
		$c->error("ERROR updating clip");
		die;
	};
	
	# We should return the clip we altered, but for now OK is fine
	$c->response->content_type('text/plain');
	$c->response->body("OK\nclip_id=" . $clip->clip_id);	
}


sub update_status : Path('update_status') : Args(2) {

	my $self = shift;
	my $c = shift;
	my $id = shift;
	my $status = shift;

	# We don't check that the specified event_id or status is valid
	# That is enforced by the database, which will raise an error.
	$c->log->debug("setting status=$status for clip_id=$id");
	
	my $rs = $c->model('DB::Clip');
	
	my $clip = $rs->find({
		clip_id => $id
	}) or do {
		die "No such event";
	};
	
	$clip->update({
		status => $status,
	}) or do {
		$c->error("problem setting status=$status for clip_id=$id");
		die;	
	};
	
	# We should return the clip we altered, but for now OK is fine
	$c->response->content_type('text/plain');
	$c->response->body("OK\nevent_id=" . $clip->clip_id);
}




sub all : Path('all') : Args(0) {

	my $self = shift;
	my $c = shift;
	my $json_data = {};
	
	my $rs = $c->model('DB::Clip');
	my $where = {};
	my $search_params = {};
	
	# By default only show completed (and not processing or deleted) clips
	$where->{status} = ['complete'];

	# By default, don't return clips assigned to buttons
	$search_params->{join} = 'buttons';
	$where->{button_id} = undef;
	
	# Restrict results by profile_id, if parameter is supplied
	if( $c->request->param('profile_id') ) {
		$c->log->debug("searching for clips with profile_id: " . $c->request->param('profile_id'));
		$where->{'me.profile_id'} = $c->request->param('profile_id');
	}
	
	# Restrict results by status, if parameter is supplied
	# multiple status values are comma separated
	if( $c->request->param('status') ) {
 		$c->log->debug("searching for clips with status of: " . $c->request->param('status'));
		$where->{status} = [ split(',', $c->request->param('status')) ];
	};
	
	# Restrict results by channel_id, if parameter is supplied
	# multiple status values are comma separated
	if( $c->request->param('channel_id') ) {
		$c->log->debug("searching for clips with channel_id of: " . $c->request->param('channel_id'));
		
		my @channel_ids = split(',', $c->request->param('channel_id'));
		
		# If NULL is specified, replace with undef;
		foreach my $channel_id(@channel_ids) {
			$channel_id eq 'NULL' and $channel_id = undef;
		}		
		
 		$where->{channel_id} = [ @channel_ids ];
	};
	
	# Restrict results by channel_id, if parameter is supplied
	# multiple status values are comma separated
	if( $c->request->param('clip_id') ) {
 		$c->log->debug("searching for clips with clip_id of: " . $c->request->param('clip_id'));
		$where->{'me.clip_id'} = [ split(',', $c->request->param('clip_id')) ];
	};
	
	# Restrict results by category, if parameter is supplied
	# multiple status values are comma separated
	if( $c->request->param('category') ) {
 		$c->log->debug("searching for clips with category of: " . $c->request->param('category'));
		$where->{category} = [ split(',', $c->request->param('category')) ];
	};

	my @clips = $rs->search($where, $search_params);
	
	foreach my $clip(@clips) {
	
		# Normally display name of studio/audio source, unless it is a user upload,
		# which doesn't have an internal source or channel
		my $display_source = ($clip->source eq 'user_upload' ? 'user upload' : $clip->source_label);
	
		$json_data->{$clip->clip_id} = {
			clip_id => $clip->clip_id,
			title => $clip->title,
			status => $clip->status,
			category => $clip->category,
			duration_seconds => $clip->duration_seconds,
			match_title => $clip->match_title,
			commentator => $clip->commentator,
			source => $display_source,
		};
		
		# Set timezone, so we can extract time and date in channel's 
		# time zone. This should be pushed back into the DB model class.
		# This only applies to clips assigned to a channel. User uploads, for example,
		# do not have a time or timezone
		if( $clip->channel && $clip->clip_start_timestamp && $clip->channel->timezone ) {
			$clip->clip_start_timestamp->set_time_zone( $clip->channel->timezone );
		
			# Resulting display dates and times will be in the channel's time zone
			$json_data->{$clip->clip_id}->{display_date} = $clip->clip_start_timestamp->strftime('%a %d/%m/%Y');
			$json_data->{$clip->clip_id}->{display_time} = $clip->clip_start_timestamp->strftime('%H:%M:%S');
		}
		else {
			$json_data->{$clip->clip_id}->{display_date} = "";
			$json_data->{$clip->clip_id}->{display_time} = "";
		}
	}
	
	# Return status to page
	$c->stash(
		current_view => 'JSON',
		json_data => $json_data,
	);
}


sub upload : Path : Local {

	my $self = shift;
	my $c = shift;
	
	# Check we have an audio file to process
	my $upload = $c->request->upload('clip_file') or do {
		$c->error("ERROR: no upload file specified");
		die;
	};
	my $temp_audio_path = $upload->tempname or do {
		$c->error("ERROR: no upload temporary file found");
		die;
	};
	$c->log->debug("audio clip uploaded to temporary file: $temp_audio_path");
	
	
	# Validate audio. Determine $duration_seconds
	my $duration_seconds = $c->forward(
		'validate_wav',
		[ $temp_audio_path ]
	) or do {
		$c->error("ERROR determining uploaded WAV file duration");
		die;
	};
	
	# Trim whitespace and Log submitted data
	my $params = $c->request->body_params;
	foreach (keys %{$params}) {
		$params->{$_} = trim_whitespace( $params->{$_} );
		$c->log->debug("$_ :: $params->{$_}");
	}

	# Validate profile_code
	# As we use the submitted profile code to determine a
	# filesystem directory name, this is necessary to prevent
	# malicious behabviour
	my $profile_code = $params->{profile_code};
	my $profile_id = $c->forward(	'/ui/profile_id_from_code', [ $profile_code ] );
	unless($profile_id) {
		$c->error("ERROR: profile_code parameter is missing or invalid");
		die;
	}
	
	# Create a clip row - set to processing until we're ready with audio
	my $rs = $c->model('DB::Clip');
	my $clip = $rs->create({
		source => 'user_upload',
		status => 'processing',
		title => $params->{title},
		people => $params->{people},
		description => $params->{description},
		out_cue => $params->{out_cue},
		category => $params->{category},
		language => $params->{language},
		duration_seconds => $duration_seconds,
		profile_id => $params->{profile_id},
	}) or do {
		$c->error("ERROR inserting clip row in database");
		die;
	};

	$c->log->debug("inserted clip_id " . $clip->clip_id);
	
	# Move uploaded file to clips directory
	# Destination of clips is specified in global configuration file
	# combined with supplied profile code (which has been validated above)
	my $dest_dir = sprintf(
		"%s/%s",
		$c->config->{clips_path},
		$params->{profile_code},
	);
	unless( $dest_dir && -d $dest_dir ) {
		$c->error("ERROR: either clips_path is undefined in configuration file, or it is not a valid directory path");
		die;
	}
	
	my $audio_dest_path = sprintf(
		"%s/%u.wav",
		$dest_dir,
		$clip->clip_id
	);
	
	# Copy cached file to clips directory
	$c->log->debug("moving $temp_audio_path -> $audio_dest_path");
	copy($temp_audio_path, $audio_dest_path) or do {
		$c->error("error moving audio clip: $!");
		die;
	};
	
	# Update clip status to completed
	$c->log->debug("marking clip as completed");
	$clip->update({
		status => 'complete',
	}) or do {
		$c->error("ERROR updating clip status to completed");
	};
	
	# Return status to page
	$c->stash(
		current_view => 'JSON',
		json_data => { clip_id => $clip->clip_id },
	)	
}


sub create : Path : Local {

	my $self = shift;
	my $c = shift;
	
	# Parse submitted JSON structure
	my $json = JSON->new;
	my $body = File::Slurp::read_file($c->request->body);
	my $params = $json->decode( $body ) or do {
		$c->error("ERROR: didm't receive valid JSON data");
		die;
	};
	
	# Trim whitespace and Log submitted data
	foreach (keys %{$params}) {
		$params->{$_} = trim_whitespace( $params->{$_} );
		$c->log->debug("$_ :: $params->{$_}");
	}

	# Validate profile_code
	# As we use the submitted profile code to determine a
	# filesystem directory name, this is necessary to prevent
	# malicious behabviour
	my $profile_code = $params->{profile_code};
	my $profile_id = $c->forward(	'/ui/profile_id_from_code', [ $profile_code ] );
	unless($profile_id) {
		$c->error("ERROR: profile_code parameter is missing or invalid");
		die;
	}
	
	# Look up relevant channel data;
	my $channel;
	if( $params->{channel_id} ) {
		my $channel_rs = $c->model('DB::Channel');
		$channel = $channel_rs->find({
			channel_id => $params->{channel_id}
		});
	};
	unless ($channel) {
		$c->error("unable to find channel record associated with this clip, populating channel fields with nulls");
		die;
	}
	
	# TODO:
	# Look up relevant event data to check timestamp for sanity
	# It's possible for a user to start editing a given audio event, but then navigate
	# to a completely different piece of audio. We should check that the audio clip time
	# is vaguely sane for the event being associated.
	
	# Convert timestamps from channel timezone to UTC
	my $start_dt = iso_parameter_to_dt($params->{start_iso}, $channel->timezone) or do {
		$c->error("ERROR parsing start_iso timestamp parameter");
		die;
	};
	my $end_dt = iso_parameter_to_dt($params->{end_iso}, $channel->timezone) or do {
		$c->error("ERROR parsing end_iso timestamp parameter");
		die;
	};
	$start_dt->set_time_zone('UTC');
	$end_dt->set_time_zone('UTC');	
	$c->stash(
		start_dt => $start_dt,
		end_dt => $end_dt,
	);
	
	# Create a clip row - set to processing until we're ready with audio
	my $rs = $c->model('DB::Clip');
	my $clip = $rs->create({
		source => 'clip_editor',
		status => 'processing',
		title => $params->{title},
		people => $params->{people},
		description => $params->{description},
		out_cue => $params->{out_cue},
		category => $params->{category},
		language => $params->{language},
		duration_seconds => int($params->{duration_seconds}),
		source_label => $channel->source_label,
		match_title => $channel->match_title,
		commentator => $channel->commentator,
		channel_id => $params->{channel_id},
		event_id => $params->{event_id},
		clip_start_timestamp => $start_dt,
		clip_end_timestamp => $end_dt,
		profile_id => $params->{profile_id},
	}) or do {
		$c->error("ERROR inserting clip row in database");
		die;
	};

	$c->log->debug("inserted clip_id " . $clip->clip_id);
		
	# Create Audio
	my $audio_cache_path = $c->forward(
		'/audio/generate_audio',
		[ channel_id => $params->{channel_id} ]
	) or do {
		$c->error("unable to prepare requested audio file");
		die;
	};
	
	# Destination of clips is specified in global configuration file
	my $dest_dir = $c->config->{clips_path} . '/' . $profile_code;
	unless( $dest_dir && -d $dest_dir ) {
		$c->error("ERROR: either clips_path is undefined in configuration file, or it is not a valid directory path");
		die;
	}
	
	my $audio_dest_path = sprintf(
		"%s/%u.wav",
		$dest_dir,
		$clip->clip_id
	);
	
	# Copy cached file to clips directory
	$c->log->debug("copying $audio_cache_path -> $audio_dest_path");
	copy($audio_cache_path, $audio_dest_path) or do {
		$c->error("error copying audio clip: $!");
		die;
	};
	
	# Update clip status to completed
	$c->log->debug("marking clip as completed");
	$clip->update({
		status => 'complete',
	}) or do {
		$c->error("ERROR updating clip status to completed");
	};
	
	# Mark event as 'exported' if this clip related to an event
	if( $params->{event_id} ) {
		$c->forward ("/events/exported/" . $params->{event_id} );
	}
	
	# Return status to page
	$c->stash(
		current_view => 'JSON',
		json_data => { clip_id => $clip->clip_id },
	)
}



# This is duplicated in Controller::Audio - needs to be split out
sub iso_parameter_to_dt {

	my $iso = shift;
	my $timezone = shift;
	
	$iso or return undef;
	$iso =~	m/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ?$/ or return undef;
	
	# Does it end with Z, indicating UTC time?
	$iso =~ s/Z$// and $timezone = 'UTC';
	$timezone or return undef;
			
	my $strp = DateTime::Format::Strptime->new(
		pattern   => '%FT%T.%3N',
		time_zone => $timezone,
	);

	return $strp->parse_datetime( $iso );
}


sub trim_whitespace {
	
	my $text = shift;
	$text =~ s/^\s*//s;
	$text =~ s/\s*$//s;
	return $text;
}


sub validate_wav : Private {

	# Given the path of a WAV file, open it and return the
	# duration in seconds, or undef on error

	my $self = shift;
	my $c = shift;
	my $path = shift;

	$c->log->debug("opening $path");
	
	my $wav = Audio::Wav->read($path) or do {
		$c->error("ERROR reading WAV file");
		return undef;
	};

	# Debugging - dump info
	my $info = $wav->get_info;
	foreach my $key(keys %{$info}) {
		$c->log->debug("$key :: $info->{$key}");
	}
	
	# Debugging - dump detailsmy $info = $wav->get_info;
	my $details = $wav->details;
	foreach my $key(keys %{$details}) {
		$key eq 'info' and next; # already dumped above
		$c->log->debug("$key :: $details->{$key}");
	}

	my $duration_seconds = $wav->length_seconds;
	$c->log->debug("duration :: $duration_seconds seconds");
	
	return $duration_seconds;
}



=head1 AUTHOR

Nick Prater

=head1 LICENCE

This file is part of GOALS-logger, a broadcast audio logging system.

Copyright (C) 2012 NP Broadcast Limited.

GOALS-logger is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GOALS-logger is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with GOALS-logger.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;

1;
