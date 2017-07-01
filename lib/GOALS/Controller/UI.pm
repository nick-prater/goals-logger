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
	my $self = shift;
	my $c = shift;

	# It is now mandatory to have session data to define our profile
	unless( $c->session->{profile_code} ) {
		$c->log->warn("ERROR: profile not defined in session data");
		$c->response->redirect('/');
	}

	$c->forward('get_available_channels');
	$c->forward('get_available_start_dates');
	$c->forward('get_available_categories');

	$c->stash(
		max_clip_seconds => $c->config->{max_audio_clip_duration_seconds} || 3600
	);
}


sub upload_clip : Local {
	my $self = shift;
	my $c = shift;

	$c->forward('get_available_categories');

	unless( $c->session->{profile_id} ) {
		$c->log->warn("upload_clip called without a valid session profile_id");
		$c->response->redirect('/');
	};
}


sub build_playlist : Local {
	my $self = shift;
	my $c = shift;

	unless( $c->session->{profile_id} ) {
		$c->log->warn("build_playlist called without a valid session profile_id");
		$c->response->redirect('/');
	};

	$c->forward('get_available_channels');
	$c->forward('get_available_categories');
	$c->forward('get_available_languages');

	$c->stash(
		clip_url_prefix => $c->config->{clip_url_prefix} || '',
		build_playlist  => 1,
		template        => 'ui/assign_clips.tt',
		clip            => {category => 7},
	);
}


sub assign_clips : Local {
	my $self = shift;
	my $c = shift;

	unless( $c->session->{profile_id} ) {
		$c->log->warn("assign_clips called without a valid session profile_id");
		$c->response->redirect('/');
	};

	$c->forward('get_available_channels');
	$c->forward('get_buttons');
	$c->forward('get_available_categories');

	# Setting this on the stash configures the hotkey page
	# to assign a single clip, then return.
	$c->stash(
		assign_clip_id  => $c->request->param('clip_id') || 0,
		clip_url_prefix => $c->config->{clip_url_prefix} || '',
		hotkeys         => 1,
	);
}


sub rename_clip : Local : Args(1) {

	my $self = shift;
	my $c = shift;
	my $clip_id = shift;

	my $rs = $c->model('DB::Clip');

	my $clip = $rs->find({
		clip_id => $clip_id
	}) or do {
		die "No such clip";
	};

	# Populate stash, and hence form, with current values
	$c->stash(
		clip => {
			id          => $clip_id,
			title       => $clip->title,
			people      => $clip->people,
			description => $clip->description,
			out_cue     => $clip->out_cue,
			category    => $clip->category_id,
			language    => $clip->language,
		}
	);

	$c->forward('get_available_categories');
	$c->forward('get_available_languages');
}


sub get_buttons : Private {

	my ( $self, $c ) = @_;

	my @records = $c->model('DB::Button')->search(
		{
			profile_id => $c->session->{profile_id},
		},
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


sub get_available_profiles : Private {

	# Grab all channels and put them on the stash
	# used to populate source selector within player
	my ( $self, $c ) = @_;
	my $rs = $c->model('DB::Profile');
	my @results = $rs->all;

	# Explicitly dereference into a hash
	my %profiles;
	foreach my $result(@results) {
		$profiles{ $result->profile_id } = $result->display_name;
	}

	$c->stash(
		profiles => \%profiles,
	);
}


sub get_available_profile_codes : Private {

	# Grab all channels and put them on the stash
	# used to populate source selector within player
	my ( $self, $c ) = @_;
	my $rs = $c->model('DB::Profile');
	my @results = $rs->all;

	# Explicitly dereference into a hash
	my %profiles;
	foreach my $result(@results) {
		$profiles{ $result->profile_code } = $result->display_name;
	}

	$c->stash(
		profile_codes => \%profiles,
	);
}


sub get_available_channels : Private {

	# Grab all channels and put them on the stash
	# used to populate source selector within player
	my $self = shift;
	my $c = shift;

	my $rs = $c->model('DB::Channel');
	my $where = {};

	$where->{profile_id} = $c->session->{profile_id};

	my @channels = $rs->search($where);

	$c->stash(
		channels => \@channels
	);
}


sub get_available_start_dates : Private {

	my ( $self, $c ) = @_;
	my $days = $c->config->{keep_audio_days};
	my @dates = ();

	my $dt = DateTime->today;
	my $one_day_dt = DateTime::Duration->new( days => 1 );

	while( $days ) {
		my $dt_clone = $dt->clone;
		$dt_clone->set_time_zone('Europe/London');
		$dt_clone->truncate(to => 'day');

		push(@dates, $dt_clone);

		$dt -= $one_day_dt;
		$days --
	}

	$c->stash(
		start_dates => \@dates
	);
}


sub get_available_categories : Private {

	my $self = shift;
	my $c = shift;
	my $rs = $c->model('DB::ClipCategory');
	my @results = $rs->all;

	# Explicitly dereference into a hash
	my %categories;
	foreach my $result(@results) {
		$categories{ $result->clip_category_id } = $result->display_name;
	}

	$c->stash(
		categories => \%categories
	)
}


sub get_available_languages : Private {

	my $self = shift;
	my $c = shift;

	my $default = $c->config->{default_language} || 'english';

	$c->stash(
		languages => {

			'english'  => 'English',
			'spanish'  => 'Spanish',
			'mandarin' => 'Mandarin',
			'other'    => 'Other',
		},
		default_language => $default,
	);
}


sub profile_id_from_code : Private {

	my $self = shift;
	my $c = shift;
	my $profile_code = shift;

	# Must have a profile code
	$profile_code or return undef;

	$c->log->debug("looking up profile_code: $profile_code");
	my $rs = $c->model('DB::Profile');
	my $profile = $rs->find({
		profile_code => $profile_code
	}) or do {
		$c->log->error("ERROR: no such profile");
		return undef;
	};

	$c->log->debug("profile_id: " . $profile->profile_id);
	$c->log->debug("display_name: " . $profile->display_name);

	# Populate stash, and hence form, with current values
	$c->stash(
		profile_code => $profile->profile_code,
		profile_id   => $profile->profile_id,
		profile_name => $profile->display_name,
	);

	return $profile->profile_id;
}


sub profile_code_from_id : Private {

	my $self = shift;
	my $c = shift;
	my $profile_id = shift;

	# Must have a profile code
	$profile_id or return undef;

	$c->log->debug("looking up profile_id: $profile_id");
	my $rs = $c->model('DB::Profile');
	my $profile = $rs->find({
		profile_id => $profile_id
	}) or do {
		$c->log->error("ERROR: no such profile");
		return undef;
	};

	$c->log->debug("profile_id: " . $profile->profile_id);
	$c->log->debug("display_name: " . $profile->display_name);

	# Populate stash, and hence form, with current values
	$c->stash(
		profile_code => $profile->profile_code,
		profile_id   => $profile->profile_id,
		profile_name => $profile->display_name,
	);

	return $profile->profile_code;
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
