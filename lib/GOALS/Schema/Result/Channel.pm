use utf8;
package GOALS::Schema::Result::Channel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GOALS::Schema::Result::Channel

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

=head1 TABLE: C<channels>

=cut

__PACKAGE__->table("channels");

=head1 ACCESSORS

=head2 channel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 source

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 source_label

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 match_title

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 commentator

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 timezone

  data_type: 'varchar'
  default_value: 'Europe/London'
  is_nullable: 0
  size: 30

=head2 profile_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 recording

  data_type: 'enum'
  default_value: 'yes'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "channel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "source",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "source_label",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "match_title",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "commentator",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "timezone",
  {
    data_type => "varchar",
    default_value => "Europe/London",
    is_nullable => 0,
    size => 30,
  },
  "profile_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "recording",
  {
    data_type => "enum",
    default_value => "yes",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</channel_id>

=back

=cut

__PACKAGE__->set_primary_key("channel_id");

=head1 RELATIONS

=head2 clips

Type: has_many

Related object: L<GOALS::Schema::Result::Clip>

=cut

__PACKAGE__->has_many(
  "clips",
  "GOALS::Schema::Result::Clip",
  { "foreign.channel_id" => "self.channel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 event_inputs

Type: has_many

Related object: L<GOALS::Schema::Result::EventInput>

=cut

__PACKAGE__->has_many(
  "event_inputs",
  "GOALS::Schema::Result::EventInput",
  { "foreign.channel_id" => "self.channel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/uTeREkEp2v3kDm4dSkGZA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
