package GOALS::Controller::Audio;
use Moose;
use namespace::autoclean;
use Catalyst 'Redirect';
use File::Temp;
use File::Path 'make_path';
use File::Copy;
use DateTime::Format::Strptime;


BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

GOALS::Controller::Audio - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched GOALS::Controller::Audio in Audio.');
}


sub wav : Path('wav') : Args(3) {

	my $self = shift;
	my $c = shift;

	# Handle URLs in following form:
	# audio/wav/2/2012-07-03T10:22:22.000/2012-07-03T10:23:44.000
	# This means that they can be cached easily
	# Timestamps are in the timezone of the audio recording
	# TODO Add support for UTC timestamps
	
	# Convert arguments into a hash
	my @arg_keys = qw(channel_id start_iso end_iso);
	my %args;
	@args{@arg_keys} = @_;
	
	# Validate parameters
	$c->forward(
		'validate_audio_params',
		[%args]
	) or die;

	# Get/Create cached audio file
	my $cache_file = $c->forward(
		'generate_audio',
		[%args]
	);
	
	# Redirect to it's URL
	if (-f $cache_file) {
		
		my $uri = sprintf(
			"%s/cache/audio/wav/%d/%s/%s.wav",
			$c->config->{clip_url_prefix} || '',
			$args{channel_id},
			$c->stash->{start_dt}->strftime("%Y-%m-%dT%H:%M:%S.%3NZ"),
			$c->stash->{end_dt}->strftime("%Y-%m-%dT%H:%M:%S.%3NZ"),
		); 
	
		$c->log->info("serving from cache");
		$c->log->info("redirecting to $uri");
		
		return $c->response->redirect($uri);
	}
	else {
		# TODO:
		# Return graceful error
		# Unable to find and serve the audio	
	}

}



sub waveform : Path('waveform') : Args(6) {

	my $self = shift;
	my $c = shift;

	# Handle URLs in following form:
	# audio/wav/2/2012-07-03T10:22:22.000/2012-07-03T10:23:44.000/height/width/rrggbb
	# This means that they can be cached easily
	# Timestamps are in the timezone of the audio recording
	# TODO: Add support for UTC timestamps
	
	# Convert remaining arguments into a hash
	my @arg_keys = qw(channel_id start_iso end_iso width_pixels height_pixels colour_rrggbb);
	my %args;
	@args{@arg_keys} = @_;
	
	$c->forward(
		'validate_waveform_params',
		[%args]
	) or die;

	my $cache_file = $c->forward(
		'generate_waveform',
		[%args]
	);
	
	if (-f $cache_file) {
		
		my $uri = sprintf(
			"%s/audio/waveform/%u/%s/%s/%u/%u/%s.png",
			'/cache',
			$args{channel_id},
			$c->stash->{start_dt}->strftime("%Y-%m-%dT%H:%M:%S.%3NZ"),
			$c->stash->{end_dt}->strftime("%Y-%m-%dT%H:%M:%S.%3NZ"),
			$args{width_pixels},
			$args{height_pixels},
			$args{colour_rrggbb},
		); 
	
		$c->log->info("serving waveform from cache");
		$c->log->info("redirecting to $uri");
		
		return $c->response->redirect($uri);
	}
	else {
		# TODO:
		# Handle error gracefully - unable to serve waveform
	}
}



sub generate_audio : Private {

	# Returns file path to cached audio file, which is
	# compiled if it doesn't already exist.
	# Returns false on error.
	my $self = shift;
	my $c = shift;
	my %args = @_;

	my $directory = sprintf(
		"%s/audio/wav/%d/%s",
		$c->config->{cache_path},
		$args{channel_id},
		$c->stash->{start_dt}->strftime("%Y-%m-%dT%H:%M:%S.%3NZ"),
	);
	my $cache_path = sprintf(
		"%s/%s.wav",
		$directory,
		$c->stash->{end_dt}->strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
	);
	
	# Success if cache file exists
	if (-e $cache_path) {
		$c->log->debug("using previously cached wav: $cache_path");
		return $cache_path;
	}

	unless(-d $directory) {
		$c->log->debug("creating destination directory");
		
		# We want these directories to be group-writeable,
		# so over-ride the umask, just for this operation, to be sure.
		my $old_umask = umask(002);
		make_path($directory) or do {
			$c->error("ERROR creating waveform directory: $!");
			die;
		};
		umask($old_umask);
	}
	
	# Otherwise create wav file afresh
	# Write initially to a temporary file, then do an
	# atomic rename to the desired filename to avoid
	# race confitions
	my $fh = File::Temp->new(
		DIR => $directory,
	) or do {
		$c->error("ERROR creating temporary file for wav: $!");
		die;
	};
	my $temp_path = $fh->filename;
	$c->log->debug("writing wav to temporary file " . $temp_path);
	
	my $audio_prefix = sprintf(
		"%s/%u/",
		$c->config->{audio_log_path},
		$args{channel_id}
	);
		
	# Generate waveform
	my @command = (
		$c->config->{rotjoin},
		'-p', $audio_prefix,
		'-f', 'wav',
		'-o', $temp_path,
		'-b', $c->stash->{start_dt}->strftime("%Y%m%d%H%M%S.%2N"),
		'-e', $c->stash->{end_dt}->strftime("%Y%m%d%H%M%S.%2N"),
	);

	$c->log->debug("running command: " . join(' ', @command));
	system(@command) and do {
		$c->error("ERROR running rotjoin command: $!");
		die;
	};
	
	$c->log->debug("completed running rotjoin command");
	
	# Set permissions so all can read
	chmod( 0664, $temp_path ) or do {
		$c->error("ERROR setting permissions on temporary file");
	};
	
	$c->log->debug("renaming temporary file $temp_path -> $cache_path");

	move($temp_path, $cache_path) or do {
		$c->error("ERROR renaming temporary file: $!");
		die;
	};
	
	return $cache_path;	
}



sub generate_waveform : Private {

	my $self = shift;
	my $c = shift;
	my %args = @_;

	my $directory = sprintf(
		"%s/audio/waveform/%u/%s/%s/%u/%u",
		$c->config->{cache_path},
		$args{channel_id},
		$c->stash->{start_dt}->strftime("%Y-%m-%dT%H:%M:%S.%3NZ"),
		$c->stash->{end_dt}->strftime("%Y-%m-%dT%H:%M:%S.%3NZ"),
		$args{width_pixels},
		$args{height_pixels},
	);
		
	my $cache_path = "$directory/$args{colour_rrggbb}.png";
	
	# If waveform is already cached, just return the path to it
	if (-e $cache_path) {
		$c->log->debug("using previously cached waveform: $cache_path");
		return $cache_path;
	}	
	
	# Otherwise create the waveform afresh
	
	# Ensure destination directory exists, create it if not
	$c->log->debug("waveform cache directory is: $directory");
	
	unless(-d $directory) {
		$c->log->debug("creating destination directory");
		# We want these directories to be group-writeable
		# so over-ride the umask for this operation only
		my $old_umask = umask(002);		
		make_path($directory) or do {
			$c->error("ERROR creating waveform directory: $!");
			die;
		};
		umask($old_umask);
	}
	
	# Write initially to a temporary file, then do an
	# atomic rename to the desired filename to avoid
	# race confitions
	my $fh = File::Temp->new(
		DIR => $directory,
	) or do {
		$c->error("ERROR creating temporary file for waveform: $!");
		die;
	};
	my $temp_path = $fh->filename;
	$c->log->debug("writing waveform to temporary file " . $temp_path);
	
	# Which audio file are we operating on?
	my $audio_file = $c->forward(
		'generate_audio',
		[%args]
	) or do {
		$c->error("unable to determine audio cache file");
		die;
	};
		
	# Generate waveform
	my @command = (
		$c->config->{audiograph},
		$audio_file,
		$temp_path,
		$args{width_pixels},
		$args{height_pixels},
		$args{colour_rrggbb},
	);

	$c->log->debug("running command: " . join(' ', @command));
	system(@command) and do {
		$c->error("ERROR running audiograph command: $!");
		die;
	};
	
	$c->log->debug("completed running audiograph command");
	
	# Set permissions so all can read
	chmod( 0664, $temp_path ) or do {
		$c->error("ERROR setting permissions on temporary file");
	};
	
	$c->log->debug("renaming temporary file $temp_path -> $cache_path");

	move($temp_path, $cache_path) or do {
		$c->error("ERROR renaming temporary file: $!");
		die;
	};
	
	return $cache_path;	
}


sub set_audio_timezone : Private {

	my $self = shift;
	my $c = shift;
	my $channel_id = shift;
	
	# TODO: Set timezone based on the channel. But for now, all our channels are in London
	# Timezone is overridden if timestamp ends in Z, inidicating UTC
	my $timezone = 'Europe/London';
	
	$c->stash(
		audio_timezone => $timezone,
	);
	
	return $timezone;
}


sub validate_audio_params : Private {

	# Validate arguments specifying audio.
	# They are used to translate to a filesystem path, so we want 
	# to be strict, to prevent access to other parts of the filesystem.
	# dies on error, returns true if all OK
	# supplied start_iso and end_iso are converted to DataTime objects
	# and placed on the stash.

	my $self = shift;
	my $c = shift;
	my %args = @_;
	my $start_dt;
	my $end_dt;

	unless( $args{channel_id} && $args{channel_id} =~ m/^\d+$/ ) {
		$c->error("invalid channel_id received");
		die;
	}

	my $audio_timezone = $c->forward(
		'set_audio_timezone',
		[$args{channel_id}]
	);
	
	unless( $start_dt = iso_parameter_to_dt($args{start_iso}, $audio_timezone)) {
		$c->error("invalid start timestamp received");
		die;
	}

	unless( $end_dt = iso_parameter_to_dt($args{end_iso}, $audio_timezone)) {
		$c->error("invalid end timestamp received");
		die;
	}
	
	# Audio is stored in UTC so translate DateTime to this zone
	# Keep track of originally 
	$start_dt->set_time_zone('UTC');
	$end_dt->set_time_zone('UTC');
	
	# Check end timestamp is actually after beginning timestamp
	unless($start_dt < $end_dt) {
		$c->error("start_timestamp is not before end_timestamp");
		die;
	}	
	
	# Check duration of specified audio to prevent crazy time spans being requested
	my $duration_dt = $end_dt->subtract_datetime_absolute($start_dt);
	my $duration_seconds = $duration_dt->in_units('seconds');
	my $max_seconds = $c->config->{max_audio_clip_duration_seconds} || 3600;
	unless( $duration_seconds <= $max_seconds ) {
		$c->error("specified audio duration ($duration_seconds seconds) exceeds maximum of $max_seconds seconds");
		die;
	}
	
	# Stash these useful values in case we need them again
	# Saves calculating them twice
	$c->stash(
		start_dt => $start_dt,
		end_dt => $end_dt,
		duration_dt => $duration_dt,
	);

	$c->log->debug("audio parameters are valid");
	$c->log->debug("           channel_id : $args{channel_id}" );
	$c->log->debug("      start timestamp : $args{start_iso}"  );
	$c->log->debug("        end timestamp : $args{end_iso}"    );
	$c->log->debug("  start timestamp UTC : " . $start_dt->strftime("%Y-%m-%dT%H:%M:%S.%3NZ") );
	$c->log->debug("    end timestamp UTC : " . $end_dt->strftime("%Y-%m-%dT%H:%M:%S.%3NZ")   );
	$c->log->debug("calculated duration as $duration_seconds seconds");
	$c->log->debug("maximum permitted duration is $max_seconds seconds");
	
	return 1;
}



sub validate_waveform_params : Private {

	# Validate arguments specifying waveform.
	# They are used to translate to a filesystem path, so we want 
	# to be strict, to prevent access to other parts of the filesystem.
	# dies on error, returns true if all OK
	# Maximum time span is limited by the maximum audio timespan
	
	my $self = shift;
	my $c = shift;
	my %args = @_;
	
	# We require, as a base, the same parameters as audio
	$c->forward(
		'validate_audio_params',
		[%args]
	) or die;
	
	# Plus some graphic-specific ones...
	unless( $args{width_pixels} && $args{width_pixels} =~ m/^\d+$/ ) {
		$c->error("invalid width received");
		die;
	}
	
	unless( $args{height_pixels} && $args{height_pixels} =~ m/^\d+$/ ) {
		$c->error("invalid height received");
		die;
	}
	
	unless( $args{colour_rrggbb} && $args{colour_rrggbb} =~ m/^[[:xdigit:]]{6}+$/ ) {
		$c->error("invalid colour received");
		die;
	}
	
	$c->log->debug("waveform parameters are valid");
	$c->log->debug("  width           : $args{width_pixels} pixels" );
	$c->log->debug("  height          : $args{height_pixels} pixels");
	$c->log->debug("  colour (RRGGBB) : $args{colour_rrggbb}");
	
	return 1;
}
	


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
