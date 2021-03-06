package GOALS::Controller::Channels;
 
use Moose;
use namespace::autoclean;
use File::Temp;
use File::Copy;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

GOALS::Controller::Channels - Catalyst Controller

=cut



sub base : Chained('/') : PathPart('channels') : CaptureArgs(0) {

	# This base method provides access to the channels record set
	my $self = shift;
	my $c = shift;

	$c->log->debug('running base method');

	$c->stash(
		rs => $c->model('DB::Channel'),
	);
}


sub base_channel : Chained('base') : PathPart('') : CaptureArgs(1) {
	
	# This base method extracts a specific channel from the record set
	my $self = shift;
	my $c = shift;
	my $channel_id = shift;

	$c->log->debug('running base_channel method');
	$c->log->debug("channel_id: $channel_id");

	my $channel = $c->stash->{rs}->find({
		channel_id => $channel_id
	}) or do {
		die "No such channel";
	};

	$c->stash(
		channel => $channel,
		channel_id => $channel_id,
	);
}



sub generate_channel_xml : Private {

	my $self = shift;
	my $c = shift;

	my @channels = $c->stash->{rs}->all;

	use XML::LibXML;

	my $xml = XML::LibXML::Document->createDocument();
        my $root = $xml->createElement('channels');
        $xml->setDocumentElement($root);
        
        $root->appendChild(
		$xml->createComment("Automatically generated by " . $c->uri_for('xml'))
	);
        
        foreach my $channel(@channels) {
        
		my $channel_xml = $xml->createElement('channel');
		$channel_xml->appendTextChild( 'channel_id' => $channel->channel_id );
		
		# Handle situation that source has not yet been defined
		if(defined $channel->source && $channel->recording eq 'yes') {
			$channel_xml->appendTextChild( 'source' => $channel->source );
		}
		
		my $archive = $xml->createElement('archive');
		$archive->setAttribute( 'format' => 'flac' );
		$channel_xml->appendChild($archive);		
		
		$root->appendChild($channel_xml);
        }

	$c->stash(
		channel_xml => $xml->toString(2)
	);
}



sub list_xml : Chained('base') : PathPart('xml') : Args(0) {

	my $self = shift;
	my $c = shift;
        $c->forward('generate_channel_xml');
	$c->response->content_type('application/xml');
	$c->response->body($c->stash->{channel_xml});
}	



sub list : Chained('base') : PathPart('list') : Args(0) {

	my $self = shift;
	my $c = shift;
	
	my @channels = $c->stash->{rs}->all;

	# Configure link to edit values
	foreach my $channel(@channels) {

		$channel->{edit_uri} = $c->uri_for(
			$c->controller('channels')->action_for(''),
			$channel->channel_id,
		);
	}

	$c->stash(
		channels => \@channels,
	);

	# uses default template /root/channels/list.tt
}



sub record : Chained('base') : PathPart('record') : Args(2) {

	my $self = shift;
	my $c = shift;
	my $start_stop = shift;
	my $channel_list = shift;

	# /record/start/1,2,3,4
	# /record/stop/5,6

	my %recording = (
		'start' => 'yes',
		'stop'  => 'no',
	);

	unless($recording{$start_stop}) {
		return $c->log->error("record method called without valid start/stop parameter");
	}

	my @channels = split(/,/, $channel_list);

	foreach my $channel_id(@channels) {

		my $channel = $c->stash->{rs}->find({
			channel_id => $channel_id
		}) or do {
			warn "No such channel";
			next;
		};

		$channel->update({
			recording => $recording{$start_stop}
		});
	}

	# Update XML file used by rot_manager
        $c->forward('write_channel_config');

	# Send user back to channel list
	return $c->res->redirect(
		$c->uri_for(
			$c->controller('Channels')->action_for('list'),
		)
	);
}


sub show : Chained('base_channel') : PathPart('') : Args(0) {

	my $self = shift;
	my $c = shift;

	$c->log->debug('running show method');

	$c->stash->{template} = 'channels/edit.tt';

	my $update_uri = $c->uri_for(
			$c->controller('channels')->action_for('update'),
			[ $c->stash->{channel_id} ],
	);

	my $cancel_uri = $c->uri_for(
		$c->controller('channels')->action_for('list'),
	);

	$c->stash(
		update_uri => $update_uri,
		cancel_uri => $cancel_uri,
	);

	$c->forward('/ui/get_available_profiles');
}


sub update : Chained('base_channel') : PathPart('update') : Args(0) {


	my $self = shift;
	my $c = shift;

	$c->log->debug('running edit method');

	if ($c->req->method eq 'POST') {

		my $params = $c->req->params;
		my $channel = $c->stash->{channel};

		$channel->update({
			source_label => $params->{source_label},
#			source       => $params->{source},
			match_title  => $params->{match_title},
			commentator  => $params->{commentator},
			profile_id   => $params->{profile_id},
		});

		# Update ini file used by studio player
		$c->forward('/button_box/refresh_sources_ini');
				
		# Send user back to channel list
		return $c->res->redirect(
			$c->uri_for(
				$c->controller('Channels')->action_for('list'),

			)
		);
	}
	else {
		$c->log->error("edit method called without POST");
	}
}



sub write_channel_config : Private {

	my $self = shift;
	my $c = shift;
	my $dest_path = $c->config->{rot_manager}->{channel_config_file};
		
        $c->forward('generate_channel_xml');

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
	print $fh $c->stash->{channel_xml} or do {
		$c->error("ERROR writing ini data to temporary file: $!");
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
