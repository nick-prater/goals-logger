package GOALS::View::HTML;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

GOALS::View::HTML - TT View for GOALS

=head1 DESCRIPTION

TT View for GOALS.

=head1 SEE ALSO

L<GOALS>

=head1 AUTHOR

Nick Prater,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
