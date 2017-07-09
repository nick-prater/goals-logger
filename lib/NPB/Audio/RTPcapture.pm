package NPB::Audio::RTPcapture;


=head1 AUTHOR

Nick Prater

=head1 LICENCE

This file is part of GOALS-logger, a broadcast audio logging system.

Copyright (C) 2017 NP Broadcast Limited.

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



use warnings;
use strict;
use Proc::Simple;
use Log::Log4perl;
use IO::Handle;

STDERR->autoflush(1);
STDOUT->autoflush(1);

my $DEFAULT_ROTTER_PATH = '/home/npb-audio/goals-logger/script/rtp_capture';
my $DEFAULT_LOG_PATH = '/dev/stdout';


sub new {

	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	my %args  = @_;
	my $log = Log::Log4perl::get_logger();

	# Get/Set parameters
	$self->{rotter_path} = $args{rotter_path} || $DEFAULT_ROTTER_PATH;
	$self->{log_path}    = $args{log_path} || $DEFAULT_LOG_PATH;
	$self->{config_file} = $args{config_file} or die "no configuration file provided";
	$self->{recording}   = $args{recording} // 1;

	# Rotter process will be managed using Proc::Simple
	$self->{proc} = Proc::Simple->new() or do {
		$log->error("failed to create new Proc::Simple object");
		return undef;
	};
	$self->{proc}->kill_on_destroy(1);

	# We'll rely on systemd to capture output
	#$self->{proc}->redirect_output($self->{log_path});
	
	$log->debug("new NPB::Audio::RTPcapture object initialised ok");
		
	bless ($self, $class);
	return $self;
};


sub mute {
	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	$log->info("muting");
	$self->{recording} = 0;
	$self->send_signal('USR1');
}


sub unmute {
	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	$log->info("unmuting");
	$self->{recording} = 1;
	$self->send_signal('USR2');
}


sub send_signal {

	my $self = shift;
	my $signal = shift;
	my $log = Log::Log4perl::get_logger();

	# Using the obvious Proc::Simple->kill method fails
	# as it seems to signal the whole child process group, rather
	# than just the rtp_capture process. So we do it manually...
	$log->debug("signalling $signal to pid " . $self->{proc}->pid);
	kill $signal => $self->{proc}->pid;
}


sub recording {
	my $self = shift;
	return $self->{recording};
}


sub start {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	my @command = (
		$self->{rotter_path},
		$self->{config_file},
	);
	
	$log->debug("starting rtp_capture with following arguments: ", join(' ', @command));
	
	$self->{proc}->start(@command) or do {
		$log->error("ERROR starting rtp_capture process: $!");
		return 0;
	};	

	return 1;
};


sub stop {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	$log->info("killing rtp_capture process");
	$self->{proc}->kill;
	
	my $max_wait_seconds = 10;
		
	while($self->{proc}->poll && $max_wait_seconds) {
		$log->debug("rtp_dump process is still running - waiting up to $max_wait_seconds seconds");
		sleep 1;
		$max_wait_seconds --;
	}
	
	if($self->{proc}->poll) {
		$log->info("rtp_dump process is still running after sending kill signal");
		$log->info("sending SIGTERM as last resort");
		$self->{proc}->kill('TERM');
	}
	
	unless($self->{proc}->poll) {
		$log->info("rtp_dump process has been terminated");
	}
};



sub is_alive {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	my $alive = $self->{proc} && $self->{proc}->poll;
	return $alive;
};



sub DESTROY {

	# This is called automatically when the object is destroyed
	# and is used to make sure we don't leave any lingering processes
	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	$log->debug("NPB::Audio::RTPcapture DESTROY method called");
	if($self->{proc} && $self->{proc}->poll) {
		$self->{stop};
	}
}



1;
