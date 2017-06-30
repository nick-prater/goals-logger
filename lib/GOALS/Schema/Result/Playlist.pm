use utf8;
package GOALS::Schema::Result::Playlist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GOALS::Schema::Result::Playlist

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

=head1 TABLE: C<playlists>

=cut

__PACKAGE__->table("playlists");

=head1 ACCESSORS

=head2 playlist_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 200

=head2 profile_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 is_deleted

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 update_timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 data

  data_type: 'json'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "playlist_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 200 },
  "profile_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "is_deleted",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "update_timestamp",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "data",
  { data_type => "json", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</playlist_id>

=back

=cut

__PACKAGE__->set_primary_key("playlist_id");

=head1 RELATIONS

=head2 profile

Type: belongs_to

Related object: L<GOALS::Schema::Result::Profile>

=cut

__PACKAGE__->belongs_to(
  "profile",
  "GOALS::Schema::Result::Profile",
  { profile_id => "profile_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-06-30 11:18:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A9b7wrcfOCE7tOb2HP/gZA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
