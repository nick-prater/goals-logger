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

	use Data::Dumper;
	$c->log->warn(Dumper $data);

	my $rs = $c->model('DB::Playlist');
	my $playlist = $rs->create({
		name => $data->{name},
		data => encode_json($data->{playlist}),
		profile_id => $c->session->{profile_id},
	}) or do {
		$c->error("problem adding new playlist record: $!");
		die;
	};

	$c->response->content_type('text/plain');
	$c->response->body("OK\nplaylist_id=" . $playlist->playlist_id);
}



sub index :GET :Path :Args(0) {



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
