package Schema::Result::Config;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Schema::Result::Config

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
__PACKAGE__->set_primary_key("parameter_key");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-09-09 11:27:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FeBAq+WeUVNqOwejFsV5CA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
