package Logmystream::Capture::Files;

use Moose;
use POSIX 'strftime';
use File::Path 'make_path';
use namespace::autoclean;

our $VERSION = 1.02;
has 'channel_id'              => (is => 'ro', required => 1);
has 'audio_extension'         => (is => 'ro', required => 1);
has 'storage_extension'       => (is => 'ro', default => '.wav');
has 'local_base'              => (is => 'ro', required => 1);
has 'storage_location'        => (is => 'ro', default => 'local');  # can be 's3' or 'local'
has 'period_seconds'          => (is => 'ro', default => 3600);
has 'storage_format'          => (is => 'ro', default => 'wav');
has 'period_start_epoch'      => (is => 'ro', default => 0, writer => 'set_period_start_epoch');
has 'next_period_start_epoch' => (is => 'ro', default => 0, writer => 'set_next_period_start_epoch');


sub start_period {

	my $self = shift;
	$self->set_period_start_epoch(int(time / $self->period_seconds) * $self->period_seconds);
	$self->set_next_period_start_epoch($self->period_start_epoch + $self->period_seconds);
	return $self->period_start_epoch;
}


sub open_audio_fh {
	my $self = shift;
	my $fh = $self->generate_fh('audio') or return undef;
	binmode $fh;
	return $fh;
}


sub open_stream_metadata_fh {
	my $self = shift;
	return $self->generate_fh('stream_metadata');
}


sub generate_fh {

	my $self = shift;
	my $type = shift;
	my $fh;
	my $path = $self->generate_path($type);

	print "opening $type file: $path\n";
	open($fh, ">>", $path) or do {
		warn "ERROR opening $type file $!";
		return undef;
	};

	return $fh;
}


sub generate_extension {

	my $self = shift;
	my $type = shift;

	for($type) {
		m/^audio$/           and return $self->audio_extension;
		m/^waveform$/        and return 'png';
		m/^stream_metadata$/ and return 'stream.metadata';
		m/^metadata$/        and return 'json';
	}

	# Default extension is the type
	return $type;
}


sub generate_path {

	# Returns the filename for the specified content type, in
	# the context of the current period. Calls generate_dir() to
	# create the directory path if it doesn't already exist
	my $self = shift;
	my $type = shift;
	my $extension = $self->generate_extension($type);

	# We use a predictable file name, even for files that will be
	# uploaded to S3 so that we can append to them if recording is
	# interrupted and then restarted during a recording period
	my $path;
	if($self->storage_location eq 's3') {
		$path = sprintf(
			"%s/%s.%s.%s.%s",
			$self->generate_dir($type),
			$self->channel_id,
			$type,
			strftime("%Y-%m-%d.%H%M", gmtime($self->period_start_epoch)),
			$extension,
		);
	}
	else {
		$path = sprintf(
			"%s/%s.%s",
			$self->generate_dir($type),
			strftime("%H%M", gmtime($self->period_start_epoch)),
			$extension,
		);
	}

	return $path;
}


sub generate_remote_path {

	my $self = shift;
	my $type = shift;
	my $extension = $self->generate_extension($type);

	$self->storage_location eq 'local' and return undef;

	my $path = sprintf(
		"/media/%s/%s/%s/%s.%s",
		$self->channel_id,
		strftime("%Y-%m-%d", gmtime($self->period_start_epoch)),
		$type,
		strftime("%H%M", gmtime($self->period_start_epoch)),
		$extension,
	);

	return $path;
}


sub generate_dir {

	# Creates the current local directory, for the specified path,
	# if it doesn't already exist
	# returns the full directory path name

	my $self = shift;
	my $type = shift; # (audio|waveform|metadata)

	# local files: /my/local/path/media/miskin_radio/2014-07-10/audio
	# s3 files:    /my/local/path/media/upload_queue
	my $path;
	if($self->storage_location eq 's3') {
		$path = sprintf(
			"%s/media/%s",
			$self->local_base,
			'upload_queue'
		);
	}
	else {
		$path = sprintf(
			"%s/media/%s/%s/%s",
			$self->local_base,
			$self->channel_id,
			strftime("%Y-%m-%d", gmtime($self->period_start_epoch)),
			$self->generate_subdir($type),
		);
	}

	-d $path or make_path($path) or do {
		print "ERROR making path $path: $!";
	};

	return $path;
}


sub generate_subdir {

	# Locally stored files are separated into subdirectories for
	# different types, such as waveform, audio and metadata.
	# This method generates the subdirectory name to be used as the
	# final part of the local storage path.

	my $self = shift;
	my $type = shift;

	for($type) {
		m/^stream_metadata$/ and return 'metadata';
	};

	# Default is the type itself
	return $type;
}





# As per https://metacpan.org/pod/Moose::Manual::BestPractices
__PACKAGE__->meta->make_immutable;
1;


