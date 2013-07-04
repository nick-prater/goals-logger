package NPB::jackd::Connection;

use strict;
use warnings;
use Log::Log4perl;

my $DEFAULT_JACKLSP_PATH = 'jack_lsp';
my $DEFAULT_JACKCONNECT_PATH = 'jack_connect';
my $DEFAULT_JACKDISCONNECT_PATH = 'jack_disconnect';


sub new {

        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};
        my %args  = @_;
        my $log = Log::Log4perl::get_logger();

        $self->{jacklsp_path}        = $args{jacklsp_path}        || $DEFAULT_JACKLSP_PATH;
        $self->{jackconnect_path}    = $args{jackconnect_path}    || $DEFAULT_JACKCONNECT_PATH;
        $self->{jackdisconnect_path} = $args{jackdisconnect_path} || $DEFAULT_JACKDISCONNECT_PATH;
	$self->{connections} = {};

        $log->debug("new NPB::jackd::Connection object initialised ok");

        bless ($self, $class);
        return $self;
}



sub query {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();

	$log->debug('querying jack connections with jack_lsp:');

	open (JACK_LSP, '-|', $self->{jacklsp_path}, '-c') or do {
		$log->error("Error opening jack_lsp pipe");
		return undef;
	};

	my %connections;
	my $x;

	while(<JACK_LSP>) {

		chomp;
		#$log->debug(">> $_");

		if( my ($y) = m/\s+(.+)$/ ) {
			# We have a destination
			$x or next; # do we have a source?
			push(@{$connections{$x}}, $y);
		}
		else {
			# We have a new source
			$connections{$_} = [];
			$x = $_;
		}
	}

	$self->{connections} = \%connections;
	close JACK_LSP;

	# Debugging
	#foreach my $x(sort keys %connections) {
	#	foreach my $y(sort @{$connections{$x}}) {
	#		$log->debug("$x -> $y");
	#	}
	#}
}


sub is_connected {
	
	my $self = shift;
	my $log = Log::Log4perl::get_logger();
	my $x = shift;
	my $y = shift;

	unless($x && $y) {
		$log->error("is_connected() called without valid arguments");
		return undef;
	};

	my $ys = $self->{connections}->{$x};

	unless( $ys && ref($ys) eq 'ARRAY' ) {
		$log->debug("jack port $x does not exist");
		return 0;
	}

	foreach(@{$ys}) {
		if( $_ eq $y ) {
			$log->debug("jack port $x IS CONNECTED to $y");
			return 1;
		}
	}

	$log->debug("jack port $x is NOT CONNECTED to $y");

	return 0;
}


sub connect {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();
	my $x = shift;
	my $y = shift;

	$log->debug("connecting jack ports $x -> $y");

	my $rv = not system(
		$self->{jackconnect_path},
		$x,
		$y,
	);

	$rv or $log->error("ERROR connecting jack ports $x->$y");

	return $rv;
}


sub disconnect {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();
	my $x = shift;
	my $y = shift;

	$log->debug("disconnecting jack ports $x -> $y");

	my $rv = not system(
		$self->{jackdisconnect_path},
		$x,
		$y,
	);

	$rv or $log->error("ERROR disconnecting jack ports $x->$y");

	return $rv;
}


sub disconnect_all {

	my $self = shift;
	my $log = Log::Log4perl::get_logger();
	my $x = shift;

	$log->debug("disconnecting all ports connected to $x");

	unless($x) {
		$log->error("disconnect_all() called without valid arguments");
		return undef;
	};

	my $ys = $self->{connections}->{$x};

	unless( $ys && ref($ys) eq 'ARRAY' ) {
		$log->debug("jack port $x does not exist");
		return undef;
	}

	foreach my $y(@{$ys}) {
		$self->disconnect($x, $y);
	}

	return 1;
}
	

1;
