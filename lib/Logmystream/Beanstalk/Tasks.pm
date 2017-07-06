package Logmystream::Beanstalk::Tasks;
use Moose;
use Beanstalk::Client;
use Data::Dumper;
use namespace::autoclean;

our $VERSION = 1.21;

# Changes
#
# v1.20 - option to disable metadata processing added
# v1.21 - process pcm to wav or flac depending on option
#         make waveform generation optional


has 'beanstalk' => (
	is       => 'ro',
	init_arg => undef,
	default  => sub {
		Beanstalk::Client->new();
	},
);

has 'ttr' => (
	is => 'ro',
	default => 600,
);

has 'process_metadata' => (
	is => 'rw',
	default => 1,
);

has 'process_waveform' => (
	is => 'rw',
	default => 1,
);




sub queue_capture_end_of_period {

	# Pass a Logmystream::Capture::Files object as an argument
	my $self = shift;
	my $f = shift;
	my @actions;

	if($f->audio_extension eq 'aac') {
		push(@actions, 'aac_to_m4a');
	}

	if($f->audio_extension eq 'pcm') {

		if($f->storage_format eq 'flac') {
			print "chaining pcm_to_flac conversion\n";
			push(@actions, 'pcm_to_flac');
		}
		else {
			print "chaining pcm_to_wav conversion\n";
			push(@actions, 'pcm_to_wav');
		}
	}

	if($self->process_metadata) {
		push(@actions, 'process_metadata');
	}

	if($self->process_waveform) {
		push(@actions, 'generate_waveform');
	}

	if($f->storage_location eq 's3') {
		push(@actions, 's3_upload', 'delete_local_files');
	}

	my $params = {
		audio_file           => $f->generate_path('audio'),
		local_base           => $f->local_base,
		channel_id           => $f->channel_id,
		period_start_epoch   => $f->period_start_epoch,
		next_actions         => \@actions,
	};

	if($self->process_waveform) {
		$params->{waveform_file} = $f->generate_path('waveform');
	}

	if($self->process_metadata) {
		$params->{stream_metadata_file} = $f->generate_path('stream_metadata');
		$params->{metadata_file}        = $f->generate_path('metadata');
	}


	if($f->storage_location eq 's3') {
		$params->{remote_audio_file}    = $f->generate_remote_path('audio');
		$params->{remote_waveform_file} = $f->generate_remote_path('waveform');
		$params->{remote_metadata_file} = $f->generate_remote_path('metadata');
	}

	$self->queue_next_task($params);
}


sub queue_task {

	my $self = shift;
	my $args = shift;

	$self->beanstalk->use($args->{action});
	my $job = $self->beanstalk->put(
		{ ttr => $self->ttr },
		%{$args}
	);

	print "inserted $args->{action} task:" . $job->id . "\n";
	return $job->id;
}


sub get_task {

	my $self = shift;
	my $queue = shift;
	my $job;

	print "waiting for $queue job...\n";
	$self->beanstalk->watch($queue);

	# Keep waiting until we get a job
	until($job) {
		$job = $self->beanstalk->reserve(600);
	}

	my $job_id = $job->id;
	print "got job:$job_id\n";

	my %args = $job->args;
	print Dumper \%args;

	return $job;
}


sub queue_next_task {

	my $self = shift;
	my $params = shift;

	if(my $action = shift(@{$params->{next_actions}})) {
		$params->{action} = $action;
		return $self->queue_task($params);
	}

	return;
}




# as per https://metacpan.org/pod/Moose::Manual::BestPractices
__PACKAGE__->meta->make_immutable;
1;

