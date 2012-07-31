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

Nick Prater,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


__PACKAGE__->config({
	expose_stash => 'json_data',
});

1;
