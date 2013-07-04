package Schema::Result::Channel;

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

Schema::Result::Channel

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
  is_nullable: 1

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
    is_nullable => 1,
  },
  "recording",
  {
    data_type => "enum",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("channel_id");

=head1 RELATIONS

=head2 profile

Type: belongs_to

Related object: L<Schema::Result::Profile>

=cut

__PACKAGE__->belongs_to(
  "profile",
  "Schema::Result::Profile",
  { profile_id => "profile_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 clips

Type: has_many

Related object: L<Schema::Result::Clip>

=cut

__PACKAGE__->has_many(
  "clips",
  "Schema::Result::Clip",
  { "foreign.channel_id" => "self.channel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 event_inputs

Type: has_many

Related object: L<Schema::Result::EventInput>

=cut

__PACKAGE__->has_many(
  "event_inputs",
  "Schema::Result::EventInput",
  { "foreign.channel_id" => "self.channel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-09-09 11:27:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OP4mFIOrkqQGB1nEfqZh0g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
