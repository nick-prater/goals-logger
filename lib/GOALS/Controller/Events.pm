package GOALS::Controller::Events;
use Moose;
use namespace::autoclean;
use POSIX 'strftime';


BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

GOALS::Controller::Events - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
	my $self = shift;
	my $c = shift;
	my $rs = $c->model('DB::Event');

	my $response;
	my $event = $rs->find({
		event_id => 10
	});

	$response .=
		$event->event_timestamp->strftime('%d/%m/%Y %H:%M:%S') . "<br />" .
		$event->status . "<br />" .
		$event->event_input->name . "<br />" .
		$event->event_input->channel->commentator . "<br />";

	$c->response->body($response);
}



sub all :Path('all') :Args(0) {
	my $self = shift;
	my $c = shift;
	my $rs = $c->model('DB::Event');
	my $where = {};
	my $search_params = {};

	# Only show events for which we have audio
	my $audio_days = $c->config->{keep_audio_days} - 1;
	my $dt = DateTime->today->subtract(DateTime::Duration->new( days => $audio_days ));
	$where->{event_timestamp} = { '>' => $dt };

	# Restrict results by status, if parameter is supplied
	# multiple status values are comma separated
	if( $c->request->param('status') ) {
 		$c->log->debug("searching for events with status of: " . $c->request->param('status'));
		$where->{status} = [ split(',', $c->request->param('status')) ];
	};

	# Restrict results by channel_id, if parameter is supplied
	# multiple channel_id values are comma separated
	if( $c->request->param('channel_id') ) {
 		$c->log->debug("searching for events with channel_id of: " . $c->request->param('channel_id'));
		$where->{channel_id} = [ split(',', $c->request->param('channel_id')) ];
		$search_params->{join} = 'event_input';
	};

	my @events = $rs->search($where, $search_params);

	# Extract events into JSON structure
	# This ensures that every value we need is explicitly de-referenced
	my $json_data = {};
	foreach my $event(@events) {

		# Extract UTC iso timestamp
		$event->event_timestamp->set_time_zone('UTC');
		my $iso_timestamp = $event->event_timestamp->strftime('%Y-%m-%dT%H:%M:%S.%3NZ');

		# Set to channel timezone to extract local timestamp
		# TODO : Extract channel time zone (put into Channel model)
		$event->event_timestamp->set_time_zone('Europe/London');

		my %json_event = (
			id => $event->event_id,
			status => $event->status,
			event_date => $event->event_timestamp->strftime('%d/%m/%Y'),
			event_time => $event->event_timestamp->strftime('%H:%M:%S'),
			match => $event->event_input->channel->match_title,
			commentator => $event->event_input->channel->commentator,
			source_label => $event->event_input->channel->source_label,
			channel_id => $event->event_input->channel->channel_id,
			iso_timestamp => $iso_timestamp,
			local_iso_timestamp => $event->event_timestamp->strftime('%Y-%m-%dT%H:%M:%S.%3N'),
		);

		$json_data->{$event->event_id} = \%json_event;
	}

	$c->stash(
		events => \@events,
		template => 'events/index.tt',
		current_view => 'JSON',
		json_data => $json_data,
	)

}




sub add : Path('add') {

	my $self = shift;
	my $c = shift;
	my $event_input_id = shift;
	my $event_type = $c->request->param('event_type');
	my $timestamp = $c->request->param('timestamp');

	unless($event_input_id) {
		$c->error("mandatory event_input_id not supplied");
		die;
	}

	unless($event_type) {
		$event_type = 'instance';
		$c->log->debug("defaulting to event_type='$event_type'");
	}

	unless($timestamp) {
		$c->log->debug("defaulting to current timestamp");
		$timestamp = DateTime->now();
	}

	# We don't check that the specified event_id or event_type is valid
	# That is enforced by the database, which will raise an error.

	my $rs = $c->model('DB::Event');
	my $event = $rs->create({
		event_type => $event_type,
		event_input_id => $event_input_id,
		event_timestamp => $timestamp,
		status => 'new',
		update_timestamp => DateTime->now(),
	}) or do {
		$c->error("problem adding new event record: $!");
		die;
	};

	# We should return the event we added, but for now OK is fine
	$c->response->content_type('text/plain');
	$c->response->body("OK\nevent_id=" . $event->event_id);
}


sub delete : Path('delete') : Args(1) {

	my $self = shift;
	my $c = shift;
	my $event_id = shift;

	# Don't really delete, just mark as deleted
	$c->forward(
		'update_status',
		[ $event_id, 'deleted' ]
	);
}


sub purge_deleted : Local {

	my $self = shift;
	my $c = shift;

	# We don't remove 'deleted' event rows from the database immediately.
	# They are first just marked as status='deleted'. This gives an
	# opportunity for users to 'undelete' them.
	#
	# This method is called to remove the rows marked as deleted, after
	# a certain grace period has expired.

	# Pull grace period from configuration file, but fall back to a default
	my $keep_days = $c->config->{keep_deleted_events_days};
	unless (defined $keep_days) {
		$keep_days = 28;
	}

	my $delete_dt = DateTime->now->subtract( days => $keep_days );
	my $rs = $c->model('DB::Event');
	my $where = {};
	my $attributes = {};

	$c->log->debug(
		"purging from database events marked as 'deleted' prior to ".
		$delete_dt->strftime("%Y-%m-%dT%H:%M:%SZ")
	);

	$attributes->{join} = 'clips';
	$where->{'me.update_timestamp'} = { '<' => $delete_dt->strftime("%Y-%m-%d %H:%M:%S") };
	$where->{'me.status'} = 'deleted';
	$where->{'clips.clip_id'} = undef;

	my $events = $rs->search(
		$where,
		$attributes
	);
	$events->delete;

	# Return an OK
	$c->response->content_type('text/plain');
	$c->response->body("OK");
}


sub purge_expired : Local {

	my $self = shift;
	my $c = shift;

	# This removes event rows from the database a number of days
	# after their event_timestamp, defined in the keep_events_days configuration
	# parameter. Usually events will lose their relevance once audio has
	# been deleted, so there is no point in keeping them longer.
	# All events with an event_timestamp outside the keep_events_days
	# time period will be removed, regardless of their status.

	# Pull grace period from configuration file, but fall back to a default
	my $keep_days = $c->config->{keep_events_days};
	unless (defined $keep_days) {
		$keep_days = 90;
	}

	my $delete_dt = DateTime->now->subtract( days => $keep_days );
	my $rs = $c->model('DB::Event');
	my $where = {};
	my $attributes = {};

	$c->log->debug(
		"purging from database events prior to ".
		$delete_dt->strftime("%Y-%m-%dT%H:%M:%SZ")
	);

	$attributes->{join} = 'clips';
	$where->{'me.update_timestamp'} = { '<' => $delete_dt->strftime("%Y-%m-%d %H:%M:%S") };
	$where->{'clips.clip_id'} = undef;

	my $events = $rs->search(
		$where,
		$attributes
	);
	$events->delete;

	# Return an OK
	$c->response->content_type('text/plain');
	$c->response->body("OK");
}


sub open : Path('open') : Args(1) {

	my $self = shift;
	my $c = shift;
	my $event_id = shift;

	# Don't really delete, just mark as deleted
	$c->forward(
		'update_status',
		[ $event_id, 'open' ]
	);
}


sub exported : Path('exported') : Args(1) {

	my $self = shift;
	my $c = shift;
	my $event_id = shift;

	# Don't really delete, just mark as deleted
	$c->forward(
		'update_status',
		[ $event_id, 'exported' ]
	);
}


sub undelete : Path('undelete') : Args(1) {

	my $self = shift;
	my $c = shift;
	my $event_id = shift;

	# Don't really delete, just mark as deleted
	$c->forward(
		'update_status',
		[ $event_id, 'new' ]
	);
}


sub update_status : Path('update_status') : Args(2) {

	my $self = shift;
	my $c = shift;
	my $event_id = shift;
	my $status = shift;

	# Don't really delete, just mark as deleted
	# We don't check that the specified event_id or event_type is valid
	# That is enforced by the database, which will raise an error.
	$c->log->debug("setting status=$status for event_id=$event_id");

	my $rs = $c->model('DB::Event');

	my $event = $rs->find({
		event_id => $event_id
	}) or do {
		die "No such event";
	};

	# This logic shouldn't be here - it should be in the open() method
	# but we need to convert all these to a chained dispatch method,
	# splitting out the event lookup from the update call
	if($status eq 'open' && $event->status ne 'new') {
		# We should return the event, but for now OK is fine
		$c->response->content_type('text/plain');
		$c->response->body("UNCHANGED\nevent_id=" . $event->event_id);
		return;
	}

	$event->update({
		status => $status,
		update_timestamp => DateTime->now(),
	}) or do {
		$c->error("problem setting status=$status for event_id=$event_id");
		die;
	};

	if( $status ne 'exported' ) {
		# We should return the event we added, but for now OK is fine
		$c->response->content_type('text/plain');
		$c->response->body("OK\nevent_id=" . $event->event_id);
	}
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
