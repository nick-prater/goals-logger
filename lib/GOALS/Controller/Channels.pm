package GOALS::Controller::Channels;

use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

GOALS::Controller::Channels - Catalyst Controller

=cut



sub base : Chained('/') : PathPart('channels') : CaptureArgs(0) {

	my $self = shift;
	my $c = shift;

	$c->log->debug('running base method');

	$c->stash(
		rs => $c->model('DB::AudioInput'),
	);
}


sub base_channel : Chained('base') : PathPart('') : CaptureArgs(1) {

	my $self = shift;
	my $c = shift;
	my $channel_id = shift;

	$c->log->debug('running base_channel method');
	$c->log->debug("channel_id: $channel_id");

	my $channel = $c->stash->{rs}->find({
		audio_input_id => $channel_id
	}) or do {
		die "No such channel";
	};

	$c->stash(
		channel => $channel,
		channel_id => $channel_id,
	);
}


sub list : Chained('base') : PathPart('') : Args(0) {

	my $self = shift;
	my $c = shift;

	$c->log->debug('running list_all method');

	my @channels = $c->stash->{rs}->all;

	# Configure link to click to edit values
	foreach my $channel(@channels) {

		$channel->{edit_uri} = $c->uri_for(
			$c->controller('channels')->action_for(''),
			$channel->audio_input_id,
		);
	}

	$c->stash(
		channels => \@channels,
	);

	# uses default template /root/channels/list.tt
}


sub show : Chained('base_channel') : PathPart('') : Args(0) {

	my $self = shift;
	my $c = shift;

	$c->log->debug('running show method');

	$c->stash->{template} = 'channels/channel.tt';

	my $update_uri = $c->uri_for(
			$c->controller('channels')->action_for('update'),
			[ $c->stash->{channel_id} ],
	);

	$c->stash(
		update_uri  => $update_uri,
	);

	$c->log->debug("setting update uri: $update_uri");
}



sub update : Chained('base_channel') : PathPart('update') : Args(0) {


	my $self = shift;
	my $c = shift;

	$c->log->debug('running edit method');

	$c->stash->{template} = 'channels/channel.tt';

	# Our Bits
	if ($c->req->method eq 'POST') {

		my $params = $c->req->params;
		my $channel = $c->stash->{channel};

		$channel->update({
			source_label => $params->{source_label},
			source       => $params->{source},
		});

		# Send user back to channel list
		return $c->res->redirect(
			$c->uri_for(
				$c->controller('Channels')->action_for(''),

			)
		);

	}
	else {
		$c->log->debug("edit method called without POST");
	}

}





=head1 AUTHOR

Nick Prater,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
