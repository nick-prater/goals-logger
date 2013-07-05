package Schema::Result::Profile;

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

Schema::Result::Profile

=cut

__PACKAGE__->table("profiles");

=head1 ACCESSORS

=head2 profile_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 profile_code

  data_type: 'char'
  is_nullable: 0
  size: 30

=head2 display_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "profile_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "profile_code",
  { data_type => "char", is_nullable => 0, size => 30 },
  "display_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 50 },
);
__PACKAGE__->set_primary_key("profile_id");
__PACKAGE__->add_unique_constraint("profile_code", ["profile_code"]);

=head1 RELATIONS

=head2 buttons

Type: has_many

Related object: L<Schema::Result::Button>

=cut

__PACKAGE__->has_many(
  "buttons",
  "Schema::Result::Button",
  { "foreign.profile_id" => "self.profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 channels

Type: has_many

Related object: L<Schema::Result::Channel>

=cut

__PACKAGE__->has_many(
  "channels",
  "Schema::Result::Channel",
  { "foreign.profile_id" => "self.profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clips

Type: has_many

Related object: L<Schema::Result::Clip>

=cut

__PACKAGE__->has_many(
  "clips",
  "Schema::Result::Clip",
  { "foreign.profile_id" => "self.profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-09-09 14:29:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mDcfzDZf2bumcntbRxYHyQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
