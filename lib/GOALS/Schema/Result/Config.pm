use utf8;
package GOALS::Schema::Result::Config;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GOALS::Schema::Result::Config

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<config>

=cut

__PACKAGE__->table("config");

=head1 ACCESSORS

=head2 parameter_key

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 parameter_value

  data_type: 'varchar'
  is_nullable: 1
  size: 1023

=cut

__PACKAGE__->add_columns(
  "parameter_key",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "parameter_value",
  { data_type => "varchar", is_nullable => 1, size => 1023 },
);

=head1 PRIMARY KEY

=over 4

=item * L</parameter_key>

=back

=cut

__PACKAGE__->set_primary_key("parameter_key");


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-06-30 11:18:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6txWMuJUhIGE9WveZ3a0dQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
