package GOALS::Controller::UI;
use Moose;
use namespace::autoclean;
use DateTime;
use DateTime::Duration;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

GOALS::Controller::UI - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched GOALS::Controller::UI in UI.');
}


sub player : Local {
	my ( $self, $c ) = @_;
	$c->forward('get_available_channels');
	$c->forward('get_available_start_dates');
}


sub upload_clip : Local {
	my $self = shift;
	my $c = shift;
}


sub assign_clips : Local {
	my $self = shift;
	my $c = shift;
	$c->forward('get_available_channels');
	$c->forward('get_buttons');
	
	# Setting this on the stash configures the hotkey page
	# to assign a single clip, then return.
	$c->stash(
		assign_clip_id  => $c->request->param('clip_id') || 0,
		clip_url_prefix => $c->config->{clip_url_prefix}
	)		

}


sub get_buttons : Private {

	my ( $self, $c ) = @_;
	
	my @records = $c->model('DB::Button')->search(
		{ },
		{
			order_by => { -asc => 'button_id'},
			join => 'clip'
		}
		
	);
		
	# Split buttons into rows
	my @buttons;
	my $y = 0;
	$buttons[$y] = [];
	my $row = $buttons[$y];
	
	foreach my $button(@records) {
	
		push(@{$row}, $button);
		
		if(scalar(@{$row}) >= $c->config->{buttons_per_row}) {
			$y ++;
			$buttons[$y] = [];
			$row = $buttons[$y];	
		}
	}
	
	$c->stash(
		buttons => \@buttons
	);

}


sub get_available_channels : Private {

	# Grab all channels and put them on the stash
	# used to populate source selector within player
	my ( $self, $c ) = @_;
	my $rs = $c->model('DB::Channel');
	my @channels = $rs->all;
	$c->stash(
		channels => \@channels
	);
}


sub get_available_start_dates : Private {

	my ( $self, $c ) = @_;
	my $days = $c->config->{keep_audio_days};
	my @dates = ();
	
	my $dt = DateTime->today;
	$dt->set_time_zone('Europe/London');
	
	my $one_day_dt = DateTime::Duration->new( days => 1 );
		
	while( $days ) {
		push(@dates, $dt->clone);		
		$dt -= $one_day_dt;
		$days --
	}

	$c->stash(
		start_dates => \@dates
	);
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
