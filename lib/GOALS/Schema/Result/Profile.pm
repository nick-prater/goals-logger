use utf8;
package GOALS::Schema::Result::Profile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GOALS::Schema::Result::Profile

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

=head1 TABLE: C<profiles>

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

=head1 PRIMARY KEY

=over 4

=item * L</profile_id>

=back

=cut

__PACKAGE__->set_primary_key("profile_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<profile_code>

=over 4

=item * L</profile_code>

=back

=cut

__PACKAGE__->add_unique_constraint("profile_code", ["profile_code"]);

=head1 RELATIONS

=head2 buttons

Type: has_many

Related object: L<GOALS::Schema::Result::Button>

=cut

__PACKAGE__->has_many(
  "buttons",
  "GOALS::Schema::Result::Button",
  { "foreign.profile_id" => "self.profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 channels

Type: has_many

Related object: L<GOALS::Schema::Result::Channel>

=cut

__PACKAGE__->has_many(
  "channels",
  "GOALS::Schema::Result::Channel",
  { "foreign.profile_id" => "self.profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clips

Type: has_many

Related object: L<GOALS::Schema::Result::Clip>

=cut

__PACKAGE__->has_many(
  "clips",
  "GOALS::Schema::Result::Clip",
  { "foreign.profile_id" => "self.profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 playlists

Type: has_many

Related object: L<GOALS::Schema::Result::Playlist>

=cut

__PACKAGE__->has_many(
  "playlists",
  "GOALS::Schema::Result::Playlist",
  { "foreign.profile_id" => "self.profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-06-30 11:18:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oo/OItrv06kmZoo7RUlSAQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
