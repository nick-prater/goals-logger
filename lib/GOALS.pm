package GOALS;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
	Session
	Session::Store::FastMmap
	Session::State::Cookie
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in goals.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'GOALS',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);


# Allow static serving of any file extensions
# Otherwise html files are banned!
GOALS->config->{static}->{ignore_extensions} = [
   
];

# Start the application
__PACKAGE__->setup();


=head1 NAME

GOALS - Catalyst based application

=head1 SYNOPSIS

    script/goals_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<GOALS::Controller::Root>, L<Catalyst>

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

1;
