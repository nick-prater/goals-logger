package GOALS::Controller::Button_Box;
use Moose;
use namespace::autoclean;
use File::Temp;
use File::Copy;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

GOALS::Controller::Button_Box - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched GOALS::Controller::Button_Box in Button_Box.');
}


sub audio : Local : Args(1) {

	# Returns a redirect to the button's audio, if any
	my $self = shift;
	my $c = shift;
	my $button_id = shift;

	$c->log->debug("directing to audio for button $button_id");
	
	my $rs = $c->model('DB::Button')->find(
		{ button_id => $button_id }
	) or do {
		$c->error("unable to find button_id $button_id in database");
		die;
	};
	
	my $clip_id = $rs->clip_id;
	
	# Respond according to whether a button has a clip assigned or not
	if($clip_id) {
		my $prefix = $c->config->{clip_url_prefix} || '';
		my $url = "$prefix/clip/$clip_id.wav";
		$c->log->debug("button $button_id maps to clip_id $clip_id");
		$c->log->debug("redirecting to $url");
		$c->response->redirect($url);		
	}
	else {
		$c->log->debug("button $button_id does not map to a clip - sending 204 No content response");
		$c->response->status(204);	
	}	
}


sub clear_button : Local : Args(1) {

	my $self = shift;
	my $c = shift;
	my $button_id = shift;

	$c->log->debug("clearing button_id $button_id");
	
	my $rs = $c->model('DB::Button')->find(
		{ button_id => $button_id }
	) or do {
		$c->error("unable to find button_id $button_id in database");
		die;
	};
	
	$rs->update({
		clip_id => undef
	});
	
	$c->forward('refresh_buttons_config');
	$c->detach('buttons_json');
}


sub assign : Local : Args(2) {

	my $self = shift;
	my $c = shift;
	my $button_id = shift;
	my $clip_id = shift;
	
	$c->log->debug("assigning clip $clip_id to button $button_id");
	
	my $rs = $c->model('DB::Button')->find(
		{ button_id => $button_id }
	) or do {
		$c->error("unable to find button_id $button_id in database");
		die;
	};
	
	$rs->update({
		clip_id => $clip_id
	}) or do {
		$c->error("error assigning clip to button");
		die;
	};
	
	$c->forward('refresh_buttons_config');
	
	$c->detach('buttons_json');
}


sub buttons_json : Local {

	# Returns JSON data to populate button-box assignment page
	my $self = shift;
	my $c = shift;
	my %json_data;
	
	$c->forward('get_hotkeys');
	
	foreach my $button( @{$c->stash->{hotkey_buttons}} ) {
	
		$json_data{$button->button_id} = {
			button_id => $button->id,
			clip_id => $button->clip_id,
			title => ($button->clip ? $button->clip->title : undef),
			duration_seconds => ($button->clip ? $button->clip->duration_seconds : undef),
		};
	}
	
	$c->stash(
		current_view => 'JSON',
		json_data => \%json_data,
	);
}


sub refresh_buttons_config : Private {

	my $self = shift;
	my $c = shift;
	my $ini = '';
	
	$c->forward('get_hotkeys');
	
	# Create output in the form:
	#[Button 1]
	#File=2102 liverpool 6-1 brighton.wav
	#Text=Liverpool 6 - 1 Brighton
	#
	#[Button 2]
	#File=
	#Text=
	
	foreach my $button( @{$c->stash->{hotkey_buttons}} ) {
	
		my $path = $button->clip ? sprintf("%s.wav", $button->clip_id) : '';
		$ini .= "[Button " . $button->button_id . "]\r\n";
		$ini .= "File=$path\r\n";
		$ini .= "Text=" . ($button->clip ? $button->clip->title : '') . "\r\n";
		$ini .= "\r\n";
	}
	
	$c->stash(
		ini_data => $ini,
	);
	
	# Write ini configuration data to file
	if( my $dest_path = $c->config->{playout_buttons_ini_path} ) {
		$c->forward(
			'write_ini',
			[ $c->config->{playout_buttons_ini_path} ]
		);
	}
	else {
		$c->log->warn("not writing ini file to disk as playout_buttons_ini_path is not defined in global configuration");
	}
}


sub buttons_ini : Local {

	my $self = shift;
	my $c = shift;
	my $ini = '';
	
	$c->forward('refresh_buttons_config');
	
	# Output ini file to browser
	$c->response->content_type('text/plain');
	$c->response->body($c->stash->{ini_data});
}



sub sources_ini : Local {

	my $self = shift;
	my $c = shift;

	$c->forward('refresh_sources_ini');
	
	# Output ini file to browser
	$c->response->content_type('text/plain');
	$c->response->body($c->stash->{ini_data});
}


sub refresh_sources_ini : Private {

	my $self = shift;
	my $c = shift;
	my $ini = '';

	$c->forward('get_sources');
	
	# Output ini file in the form:
	#[Button 1]
	#Text=Test Label
	#
	#[Button 2]
	#Text=Tony Incenzo QPR

	foreach my $channel( @{$c->stash->{channels}} ) {
		my $label = sprintf(
			"%s %s",
			 $channel->commentator || '',
			 $channel->match_title || '',
		);
		$ini .= "[Button " . $channel->channel_id . "]\r\n";
		$ini .= "Text=$label\r\n";	
	}

	$c->stash(
		ini_data => $ini,
	);
	
	# Write ini configuration data to file
	if( my $dest_path = $c->config->{playout_labels_ini_path} ) {
		$c->forward(
			'write_ini',
			[ $c->config->{playout_labels_ini_path} ]
		);
	}
	else {
		$c->log->warn("not writing ini file to disk as playout_labels_ini_path is not defined in global configuration");
	}
}


sub get_hotkeys : Private {

	my $self = shift;
	my $c = shift;

	my @records = $c->model('DB::Button')->search(
		{ },
		{
			order_by => { -asc => 'button_id'},
			join => 'clip',
		}
	);
	
	$c->stash(
		hotkey_buttons => \@records,
	);
}


sub get_sources : Private {

	my $self = shift;
	my $c = shift;
	
	my @channels = $c->model('DB::Channel')->search(
		{ },
		{
			order_by => { -asc => 'channel_id'},
		}
	);

	$c->stash(
		channels => \@channels,
	);
}



sub write_ini : Private {

	my $self = shift;
	my $c = shift;
	my $dest_path = shift;
		
	# Write initially to a temporary file, then do an
	# atomic rename to the desired filename to avoid
	# race confitions
	my $fh = File::Temp->new(
	) or do {
		$c->error("ERROR creating temporary file for ini file: $!");
		die;
	};
	my $temp_path = $fh->filename;
	$c->log->debug("writing ini to temporary file " . $temp_path);
	
	# Output data to file
	print $fh $c->stash->{ini_data} or do {
		$c->error("ERROR writing ini data to temporart file: $!");
		die;
	};
	
	# Close file to flush buffer
	close $fh or do {
		$c->error("ERROR closing temporary file: $!");
		die;
	};
	
	# Set permissions so all can read
	chmod( 0664, $temp_path ) or do {
		$c->error("ERROR setting permissions on temporary file");
	};
	
	$c->log->debug("renaming temporary file $temp_path -> $dest_path");

	move($temp_path, $dest_path) or do {
		$c->error("ERROR renaming temporary file: $!");
		die;
	};
	
	return 1;
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
