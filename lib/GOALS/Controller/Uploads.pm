package GOALS::Controller::Uploads;
use Moose;
use namespace::autoclean;
use Logmystream::Beanstalk::Tasks;
use JSON::MaybeXS;
use Digest::SHA qw(hmac_sha256_base64);
use LWP::UserAgent;
use Time::Piece;
use File::Copy;
use File::Temp;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

GOALS::Controller::Uploads - Catalyst Controller

=head1 DESCRIPTION

This Catalyst Controller is rather too specific to a particular client application, but
illustrates how a list of content ids can be retrieved from remote server. These are
used by the application as possible upload destinations for audio clips.

=head1 METHODS

=cut


# Sample data:
my $SAMPLE_DATA = [
          {
            'notes' => 'upload to S3 with AWS CLI: $ aws s3 cp [asset.mp3] s3://[bucket_path] --acl bucket-owner-fullcontrol',
            'startTimeUTC' => {
                                'timezone_type' => 3,
                                'timezone' => 'UTC',
                                'date' => '2017-07-03 20:15:03.000000'
                              },
            'mediaContentId' => 'TEST-ONDEMAND-b8f9cc20-0f02-4d83-8e05-fced4109f10a',
            'programId' => '0fc33ce0-642e-4581-8922-2ccaddac1872',
            'live_title' => 'Generated Live Match Media Content - 2017-07-03T20:15:03.613Z',
            'bucket' => 's3://media-content-catalog-assets/external/talksport/uploads/TEST-ONDEMAND-b8f9cc20-0f02-4d83-8e05-fced4109f10a',
            'booth' => 'Bundesliga 6',
            'title' => 'Generated OnDemand Match Media Content - 2017-07-03T20:15:03.613Z'
          },
          {
            'programId' => '188def77-102c-43b1-863e-c49f98f61e7a',
            'startTimeUTC' => {
                                'date' => '2017-07-03 21:45:03.000000',
                                'timezone' => 'UTC',
                                'timezone_type' => 3
                              },
            'mediaContentId' => 'TEST-ONDEMAND-71760e7a-23d3-42e5-a48e-846a6d8ea7ad',
            'notes' => 'upload to S3 with AWS CLI: $ aws s3 cp [asset.mp3] s3://[bucket_path] --acl bucket-owner-fullcontrol',
            'bucket' => 's3://media-content-catalog-assets/external/talksport/uploads/TEST-ONDEMAND-71760e7a-23d3-42e5-a48e-846a6d8ea7ad',
            'live_title' => 'Generated Live Match Media Content - 2017-07-03T21:45:03.613Z',
            'booth' => 'Bundesliga 6',
            'title' => 'Generated OnDemand Match Media Content - 2017-07-03T21:45:03.613Z'
          },
          {
            'booth' => 'Bundesliga 3',
            'title' => 'Generated OnDemand Match Media Content - 2017-07-03T07:15:03.613Z',
            'notes' => 'upload to S3 with AWS CLI: $ aws s3 cp [asset.mp3] s3://[bucket_path] --acl bucket-owner-fullcontrol',
            'mediaContentId' => 'TEST-ONDEMAND-992fd70b-6e1b-4bca-a4e1-67efe8975847',
            'startTimeUTC' => {
                                'timezone_type' => 3,
                                'date' => '2017-07-03 07:15:03.000000',
                                'timezone' => 'UTC'
                              },
            'programId' => '193c2a94-0d1f-4af0-8086-459b75b9fe0d',
            'live_title' => 'Generated Live Match Media Content - 2017-07-03T07:15:03.613Z',
            'bucket' => 's3://media-content-catalog-assets/external/talksport/uploads/TEST-ONDEMAND-992fd70b-6e1b-4bca-a4e1-67efe8975847'
          },
          {
            'live_title' => 'Generated Live Match Media Content - 2017-07-03T19:45:03.613Z',
            'bucket' => 's3://media-content-catalog-assets/external/talksport/uploads/TEST-ONDEMAND-f91a0206-647b-4494-b8b6-f0cee55764c5',
            'notes' => 'upload to S3 with AWS CLI: $ aws s3 cp [asset.mp3] s3://[bucket_path] --acl bucket-owner-fullcontrol',
            'startTimeUTC' => {
                                'date' => '2017-07-03 19:45:03.000000',
                                'timezone' => 'UTC',
                                'timezone_type' => 3
                              },
            'mediaContentId' => 'TEST-ONDEMAND-f91a0206-647b-4494-b8b6-f0cee55764c5',
            'programId' => '1a52eba8-e3a9-4ea0-976b-b0c44329374f',
            'title' => 'Generated OnDemand Match Media Content - 2017-07-03T19:45:03.613Z',
            'booth' => 'Bundesliga 4'
          },
          {
            'startTimeUTC' => {
                                'date' => '2017-07-03 22:45:03.000000',
                                'timezone' => 'UTC',
                                'timezone_type' => 3
                              },
            'mediaContentId' => 'TEST-ONDEMAND-27bf6658-e7a8-43c5-849d-da3040322bd9',
            'programId' => '285053c9-8d54-4cad-bc06-a3f6d16043a8',
            'notes' => 'upload to S3 with AWS CLI: $ aws s3 cp [asset.mp3] s3://[bucket_path] --acl bucket-owner-fullcontrol',
            'bucket' => 's3://media-content-catalog-assets/external/talksport/uploads/TEST-ONDEMAND-27bf6658-e7a8-43c5-849d-da3040322bd9',
            'live_title' => 'Generated Live Match Media Content - 2017-07-03T22:45:03.613Z',
            'booth' => 'Bundesliga 6',
            'title' => 'Generated OnDemand Match Media Content - 2017-07-03T22:45:03.613Z'
          }
];



sub media_codes :Local :Args(0) {

	# This is rather specific to a particular client application
	# But it retrieves a list of possible Content ids which can be
	# used for upload of audio to third-party systems

	my $self = shift;
	my $c = shift;


	# For test - return dummy data
	#$c->response->content_type('application/json');
	#$c->response->body(encode_json($SAMPLE_DATA));
	#sleep 3;
	#return;

	my $api_user = $c->config->{tibus_user};
	my $api_key = $c->config->{tibus_key};
	my $api_secret = $c->config->{tibus_secret};
	my $url = $c->config->{tibus_url};

	# Validation
	unless($api_user)   { die "missing tibus_user configuration key"   }
	unless($api_key)    { die "missing tibus_key configuration key"    }
	unless($api_secret) { die "missing tibus_secret configuration key" }
	unless($url)        { die "missing tibus_url configuration key"    }

	my $timestamp = gmtime->datetime;
	my $signature = hmac_sha256_base64("$api_user|$timestamp", $api_secret);

	# Pad signature
	while (length($signature) % 4) {
		$signature .= '=';
	}

	my $ua = LWP::UserAgent->new(
        	agent => 'NPBroadcast-GOALS/0.1'
	);
	my $request = HTTP::Request->new(
        	GET => $url,
	        [
        	        'X-AUTH-TOKEN' => $api_key,
                	'X-AUTH-SIGNATURE' => $signature,
	                'X-AUTH-TIMESTAMP' => $timestamp,
        	]
	);

	$c->log->info("making http request to $url");
	my $response = $ua->request($request);

	if(!$response->is_success) {
        	$c->log->error("Request failed: " . $response->status_line);
		$c->log->error($response->as_string);
        	die "Failed to retrieve data from remote server";
	}

	if($response->header('Content-Type') ne 'application/json') {
		$c->log->error("was expecting content-type 'application/json' but received: " . $response->header('Content-Type'));
		die "Unexpected content type from remote server";
	}

	$c->log->info("JSON response received OK - passing on to client:");
	#$c->log->info($response->content);

	$c->response->content_type('application/json');
	$c->response->body($response->content);
}



sub post :Local {

	my $self = shift;
	my $c = shift;
	my $params = $c->request->body_params;

	# Check we have an audio file to process
	my $upload = $c->request->upload('clip_file') or do {
		return $c->error("ERROR: no upload file specified");
	};
	my $temp_audio_path = $upload->tempname or do {
		return $c->error("ERROR: no upload temporary file found");
	};
	$c->log->debug("audio clip uploaded to temporary file: $temp_audio_path");

	# Extract media code info
	$params->{media_code} or do {
		return $c->error("ERROR: no media_code supplied");
	};
	my $media_code = decode_json($params->{media_code}) or do {
		return $c->error("ERROR: failed to decode json media code");
	};

	# Extract upload bucket
	my $bucket = $media_code->{bucket} or do {
		return $c->error("ERROR: no bucket argument supplied");
	};
	$bucket =~ s|^s3://||i; # Strip any leading 's3://' prefix;

	# Set proprietary media flag if specified
	if($params->{proprietary_content}) {
		# Force to boolean value
		$media_code->{proprietary} = !!$params->{proprietary_content};
	}

	# move file
	my $tmp = File::Temp->new(
		DIR => $c->config->{upload_queue_path},
		SUFFIX => '.wav',
		UNLINK => 0,
	);
	my $local_path = $tmp->filename;
	my ($local_name) = $local_path =~ m|.+/(.+)$|;

	$c->log->info("moving upload $temp_audio_path -> $local_path");
	move($temp_audio_path => $local_path) or do {
		$c->log->error("Failed to move $temp_audio_path -> $local_path : $!");
		die "ERROR moving audio file to upload queue";
	};

	# queue task
	my $task = Logmystream::Beanstalk::Tasks->new;
	my $task_params = {
		audio_file        => $local_path,
		remote_audio_file => $local_name,
		s3_bucket         => $bucket,
		mediaspec         => $media_code,
		next_actions      => ['wav_to_flac', 's3_upload', 'notify_upload'],
		options => {
			s3_upload => {
				delete_after_upload => 1
			},
		},
	};

	my $job_id = $task->queue_next_task($task_params);

	# Return status to page
	$c->log->debug("Upload queued OK, job_id: $job_id");
	$c->stash(
		current_view => 'JSON',
		json_data => { job_id => $job_id },
	)
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
