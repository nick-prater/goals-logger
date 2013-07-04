package NPB::jackd;

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


use warnings;
use strict;
use Proc::Simple;
use Log::Log4perl;

my $DEFAULT_JACKD_PATH = 'jackd';
my $DEFAULT_LOG_PATH = '/dev/stdout';


sub new {

	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	my %args  = @_;
	my $log = Log::Log4perl::get_logger();


	$self->{log_path}   = $args{log_path}   || $DEFAULT_LOG_PATH;
	$self->{jackd_path} = $args{jackd_path} || $DEFAULT_JACKD_PATH;

	# Rotter process will be managed using Proc::Simple
	$self->{proc} = Proc::Simple->new() or do {
		$log->error("failed to create new Proc::Simple object");
		return undef;
	};
	$self->{proc}->kill_on_destroy(1);
	$self->{proc}->redirect_output($self->{log_path});
	
	$log->debug("new NPB::jackd object initialised ok");
		
	bless ($self, $class);
	return $self;
};


sub start {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	my @command = (
		$self->{jackd_path},
		'--realtime-priority', '80',
		'-d', 'firewire',
		'--period', '2048',
		'--nperiods', '5',
		'--rate', '44100',
	);

	$log->debug("starting jackd with following arguments: ", join(' ', @command));
	
	$self->{proc}->start(@command) or do {
		$log->error("ERROR starting jackd process: $!");
		return 0;
	};	

	return 1;
};


sub stop {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	$log->info("killing jackd process");
	$self->{proc}->kill;
	
	my $max_wait_seconds = 10;
		
	while($self->{proc}->poll && $max_wait_seconds) {
		$log->debug("jack process is still running - waiting up to $max_wait_seconds seconds");
		sleep 1;
		$max_wait_seconds --;
	}
	
	if($self->{proc}->poll) {
		$log->info("jackd process is still running after sending kill signal");
		$log->info("sending SIGTERM as last resort");
		$self->{proc}->kill('TERM');
	}
	
	unless($self->{proc}->poll) {
		$log->info("jackd process has been terminated");
	}
};



sub is_alive {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	# TODO check that jack connections are correctly processed
	
	my $alive = $self->{proc} && $self->{proc}->poll;
	return $alive;
};



sub DESTROY {

	# This is called automatically when the object is destroyed
	# and is used to make sure we don't leave any lingering processes
	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	$log->debug("NPB::jackd DESTROY method called");
	if($self->{proc} && $self->{proc}->poll) {
		$self->{stop};
	}
}



1;
