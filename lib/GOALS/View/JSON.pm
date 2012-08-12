package GOALS::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

=head1 NAME

GOALS::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<GOALS>

=head1 DESCRIPTION

Catalyst JSON View.

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


__PACKAGE__->config({
	expose_stash => 'json_data',
});

1;
