package GOALS::Controller::Playlists;
use Moose;
use namespace::autoclean;
use JSON::MaybeXS;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

GOALS::Controller::Playlists - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut



sub add :POST :Local :Args(0) {

	my $self = shift;
	my $c = shift;
	my $data = $c->request->body_data;
	my $rs = $c->model('DB::Playlist');
	my $playlist;

	use Data::Dumper;
	$c->log->warn(Dumper $data);

	if($data->{playlist_id}) {

		$c->log->info("Updating existing playlist");
		$playlist = $rs->find({
			playlist_id => $data->{playlist_id},
			profile_id => $c->session->{profile_id},
		}) or do {
			die "trying to update a playlist, but it does not exist for this profile";
		};

		$playlist->update({
			name => $data->{name},
			data => encode_json($data->{playlist}),
		});
	}
	else {
		$c->log->info("creating new playlist record");
		$playlist = $rs->create({
			name => $data->{name},
			data => encode_json($data->{playlist}),
			profile_id => $c->session->{profile_id},
		}) or do {
			$c->error("problem adding new playlist record: $!");
			die;
		};
	}

	$c->stash(
		current_view => 'JSON',
		json_data => {
			name        => $playlist->name,
			playlist_id => $playlist->id,
		},
	);
}


sub edit :GET :Path :Args(1) {

	my $self = shift;
	my $c = shift;
	my $playlist_id = shift;
	my $rs = $c->model('DB::Playlist');

	my $playlist = $rs->find({
		playlist_id => $playlist_id,
		profile_id => $c->session->{profile_id},
	}) or do {
		die "No such playlist for this profile";
	};

	$c->forward('GOALS::Controller::UI', 'get_available_channels');
	$c->forward('GOALS::Controller::UI', 'get_available_categories');

	$c->stash(
		clip_url_prefix => $c->config->{clip_url_prefix} || '',
		build_playlist  => 1,
		playlist        => $playlist,
		template        => 'ui/assign_clips.tt',
	)
}




sub index :GET :Path :Args(0) {

	my $self = shift;
	my $c = shift;

	my $rs = $c->model('DB::Playlist');
	my @playlists = $rs->all;

	# Configure link to edit values
	foreach my $playlist(@playlists) {

		$playlist->{edit_uri} = $c->uri_for(
			$c->controller('playlists')->action_for(''),
			$playlist->playlist_id,
		);
	}

	$c->stash(
		channels => \@playlists,
		template => "/root/playlists/list.tt",
	);
}




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

__PACKAGE__->meta->make_immutable;

1;
