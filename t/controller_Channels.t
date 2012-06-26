use strict;
use warnings;
use Test::More;


use Catalyst::Test 'GOALS';
use GOALS::Controller::Channels;

ok( request('/channels')->is_success, 'Request should succeed' );
done_testing();
