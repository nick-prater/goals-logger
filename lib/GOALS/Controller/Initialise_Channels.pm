package GOALS::Controller::Initialise_Channels;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

GOALS::Controller::Initialise_Channels - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller used to populate GOALS database with audio port names
from the local JACK audio server.


=head2 index

=cut

sub index :Path :Args(0) {
	my ( $self, $c ) = @_;

	my @jack_ports = $self->get_jack_source_ports($c);
	unless(@jack_ports) {
		$c->error("unable to find any JACK audio sources");
		die;
	};

	my $channels = $c->model('DB::Channel');

	# Staring with channel_id = 1, assign each JACK port in turn to
	# a channel, creating new channels if required
	$c->log->debug("updating/inserting channels for JACK ports");
	my $channel_id = 0;
	my $insert_count = 0;
	my $update_count = 0;

	foreach my $port(@jack_ports) {

		$channel_id ++;

		$c->log->debug("processing channel_id $channel_id");

		my $record = $channels->find({
			channel_id => $channel_id
		});

		if($record) {
			$c->log->debug("found existing channel with channel_id=$channel_id");
			$c->log->debug("updating with source: $port");
			$record->update({
				source => $port,
			}) or do {
				$c->error("unable to update channel with channel_id $channel_id");
				next;
			};
			
			$update_count ++;
		}
		else {
			$c->log->debug("inserting new channel with channel_id=$channel_id");
			$channels->create({
				channel_id => $channel_id,
				source => $port,
			}) or do {
				$c->error("unable to insert new channel with channel_id $channel_id");
				next;
			};
			
			$insert_count ++;
		}

	}

	$c->log->debug("updated $update_count channel records");
	$c->log->debug("inserted $insert_count channel records");
	
	# After update, forward to channel list to display the result of any changes
	return $c->res->redirect(
		$c->uri_for('/channels')
	);
}



sub get_jack_source_ports {

	# Uses jacK_lsp utility to extract a list of available JACK audio sources
	# In JACK terminology, these are _outputs_ (from the JACK audio server).
	#
	# TODO
	# This is really a data source, so for ease of re-use should be contained
	# within it's own Model class, rather than lazily lumped inside this controller.
	
	# We could use Inline::C and use the C api, but easier to parse
	# the output from one of the command line jack utilities.

	my $self = shift;
	my $c = shift;
	my $port;      # placeholder while extracting jack_lsp output
	my $direction; # placeholder while extracting jacK_lsp output
	my @ports;

	$c->log->debug("extracting list of JACK input channels on this system using jack_lsp");
	open(my $fh, "jack_lsp -p -t 2>&1 |") or do {
		$c->log->error("ERROR opening filehandle for jack_lsp: $!");
		return undef;	
	};

	while(<$fh>) {

		# We process output of `jack_lsp -p` line-by-line.
		# Typical output is:
		#
		#  system:capture_1
		#         properties: output,physical,terminal,
		#  system:capture_2
		#         properties: output,physical,terminal,
		#  system:playback_1
		#	  properties: input,physical,terminal,
		#  system:playback_2
		#         properties: input,physical,terminal,
	
		# Remove any trailing newline
		chomp($_);
		$c->log->debug("[$_]");		
		
		m/^jack server is not running/ ||
		m/^JACK server not running/ and do {
			$c->error("JACK audio server is not running");
			close $fh;
			return ();
		};
		
		m/^\w+\:\w+/ and do {
		
			$port = $_;
			$c->log->debug("found JACK port: $port");
			next;
		};

		m/^\s+properties\:.*output/ and do {
		
			# Properties line say we have an output port
			# Only valid if we have previously identified the port name
			unless($port) {
				$c->log->error("unexpected response from jack_lsp: received properties without a port name");
				next;
			}
			
			$direction = 'output';
			next;
		};
	
		m/^\s+.*audio$/ and do {
		
			# Type line says that we have an audio port
			unless($port) {
				$c->log->error("unexpected response from jack_lsp: received audio type without a port name");
				next;
			}
			unless($direction) {
				$c->log->error("unexpected response from jack_lsp: received audio type without a type");
				next;
			}
			push(@ports, $port);
			$c->log->debug("identified as JACK audio output port (source)");
		};
	
		$port = undef;
		$direction = undef;
	}

	$c->log->debug(sprintf(
		"identified %u JACK audio sources",
		scalar(@ports)
	));
	
	close $fh;
	
	return @ports;
}









=head1 AUTHOR

Nick Prater,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
