package GOALS::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

GOALS::Controller::Root - Root Controller for GOALS

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
	my ( $self, $c ) = @_;
	$c->log->debug('no language profile specified');	
	return $c->response->redirect('/ui/player');
}


sub profile_index :Path :Args(1) {
	my ( $self, $c, $profile_code ) = @_;
	$c->log->debug('language profile ' . $profile_code);
    
	# Validate profile id, populate stash and session with result
	my $profile_id = $c->forward('/ui/profile_id_from_code', [$profile_code]);
	unless($profile_id) {
		$c->error("invalid profile_code supplied");
		die;
	}
	
	$c->session(
		profile_code => $profile_code,
		profile_id   => $profile_id,
		profile_name => $c->stash->{profile_name},
	);
	$c->session->{njp} = 'NJP';
	
	return $c->response->redirect("/ui/player/$profile_code");
}




=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}



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
