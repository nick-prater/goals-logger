use warnings;
use strict;
use Plack::Builder;
use lib '/home/npb-audio/goals-logger/lib';
use GOALS;

my $app = GOALS->psgi_app(@_);

builder {
	enable "Plack::Middleware::ReverseProxy";
	$app;
}
