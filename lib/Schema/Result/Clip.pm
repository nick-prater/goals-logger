package Schema::Result::Clip;

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

Schema::Result::Clip

=cut

__PACKAGE__->table("clips");

=head1 ACCESSORS

=head2 clip_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 source

  data_type: 'enum'
  default_value: 'clip_editor'
  extra: {list => ["clip_editor","user_upload"]}
  is_nullable: 0

=head2 status

  data_type: 'enum'
  default_value: 'processing'
  extra: {list => ["processing","complete","deleted"]}
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 people

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 1000

=head2 out_cue

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 category

  data_type: 'enum'
  extra: {list => ["goal","half_time_report","full_time_report","interview","commercial","other"]}
  is_nullable: 0

=head2 language

  data_type: 'enum'
  extra: {list => ["english","spanish","mandarin","other"]}
  is_nullable: 1

=head2 duration_seconds

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

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

=head2 channel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 event_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 clip_start_timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 clip_end_timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 profile_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "clip_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "source",
  {
    data_type => "enum",
    default_value => "clip_editor",
    extra => { list => ["clip_editor", "user_upload"] },
    is_nullable => 0,
  },
  "status",
  {
    data_type => "enum",
    default_value => "processing",
    extra => { list => ["processing", "complete", "deleted"] },
    is_nullable => 0,
  },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "people",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 1000 },
  "out_cue",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "category",
  {
    data_type => "enum",
    extra => {
      list => [
        "goal",
        "half_time_report",
        "full_time_report",
        "interview",
        "commercial",
        "other",
      ],
    },
    is_nullable => 0,
  },
  "language",
  {
    data_type => "enum",
    extra => { list => ["english", "spanish", "mandarin", "other"] },
    is_nullable => 1,
  },
  "duration_seconds",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "source_label",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "match_title",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "commentator",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "channel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "event_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "clip_start_timestamp",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "clip_end_timestamp",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "profile_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("clip_id");

=head1 RELATIONS

=head2 buttons

Type: has_many

Related object: L<Schema::Result::Button>

=cut

__PACKAGE__->has_many(
  "buttons",
  "Schema::Result::Button",
  { "foreign.clip_id" => "self.clip_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 channel

Type: belongs_to

Related object: L<Schema::Result::Channel>

=cut

__PACKAGE__->belongs_to(
  "channel",
  "Schema::Result::Channel",
  { channel_id => "channel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 event

Type: belongs_to

Related object: L<Schema::Result::Event>

=cut

__PACKAGE__->belongs_to(
  "event",
  "Schema::Result::Event",
  { event_id => "event_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-09-09 13:51:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gyvigr9SKh9kOC7a8pl2Yg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
