package NPB::Audio::Rotter;

use warnings;
use strict;
use Proc::Simple;
use Log::Log4perl;

my $DEFAULT_ROTTER_PATH = 'rotter';
my $DEFAULT_LOG_PATH = '/dev/stdout';


sub new {

	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	my %args  = @_;
	my $log = Log::Log4perl::get_logger();

	# Set and validate number of channels
	$self->{ports} = $args{ports};
	unless($self->{ports}) {
		$log->error("tried to create a new NPB::Audio::Rotter instance without specifying JACK ports to use");
		return undef;
	}
	
	$self->{channel_count} = scalar( @{$self->{ports}} );
	if ($self->{channel_count} > 2) {
		$log->warn("rotter only supports stereo or mono recording, yet more than two ports were specified");
		$log->warn("will use first two specified ports and ignore the rest");
		$self->{channel_count} = 2;
	}
	
	# Get/Set remaining recording parameters
	# Sample rate is determined by that of the JACK server
	$self->{rotter_path} = $args{rotter_path} || $DEFAULT_ROTTER_PATH;
	$self->{format} = $args{format} || 'flac';
	$self->{layout} = $args{layout} || '%Y-%m-%d/%H%M.flac';
	$self->{root_path} = $args{root_path} || '/tmp';
	$self->{jack_client_name} = $args{jack_client_name} || '';
	$self->{log_path} = $args{log_path} || $DEFAULT_LOG_PATH;

	# Rotter process will be managed using Proc::Simple
	$self->{proc} = Proc::Simple->new() or do {
		$log->error("failed to create new Proc::Simple object");
		return undef;
	};
	$self->{proc}->kill_on_destroy(1);
	$self->{proc}->redirect_output($self->{log_path});
	
	$log->debug("new NPB::Audio::Rotter object initialised ok");
		
	bless ($self, $class);
	return $self;
};


sub start {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	my @command = (
		$self->{rotter_path},
		'-f', $self->{format},
		'-c', $self->{channel_count},
		'-L', $self->{layout},
		'-j',        # Don't automatically start jackd
		'-p', 60,    # create files of 1 minute duration
		'-u',        # use UTC times for file names
		'-l', $self->{ports}[0],
	);
	
	# Add second channel if recording stereo
	if( $self->{channel_count} > 1 ) {
		push(@command, '-r', $self->{ports}[1]);
	};
	
	# Add custom client name if defined
	if( $self->{jack_client_name} ) {
		push(@command, '-n', $self->{jack_client_name});
	}
	
	# Finally add root path for output files
	push(@command, $self->{root_path});
	
	$log->debug("starting rotter with following arguments: ", join(' ', @command));
	
	$self->{proc}->start(@command) or do {
		$log->error("ERROR starting rotter process: $!");
		return 0;
	};	

	return 1;
};


sub stop {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	$log->info("killing rotter process ", $self->{jack_client_name});
	$self->{proc}->kill;
	
	my $max_wait_seconds = 10;
		
	while($self->{proc}->poll && $max_wait_seconds) {
		$log->debug("rotter process is still running - waiting up to $max_wait_seconds seconds");
		sleep 1;
		$max_wait_seconds --;
	}
	
	if($self->{proc}->poll) {
		$log->info("rotter process is still running after sending kill signal");
		$log->info("sending SIGTERM as last resort");
		$self->{proc}->kill('TERM');
	}
	
	unless($self->{proc}->poll) {
		$log->info("rotter process has been terminated");
	}
};



sub is_alive {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	# TODO check that jack connections are correctly routed
	
	my $alive = $self->{proc} && $self->{proc}->poll;
	return $alive;
};



sub DESTROY {

	# This is called automatically when the object is destroyed
	# and is used to make sure we don't leave any lingering processes
	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	$log->debug("NPB::Audio::Rotter DESTROY method called");
	if($self->{proc} && $self->{proc}->poll) {
		$self->{stop};
	}
}



1;
