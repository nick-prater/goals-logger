use utf8;
package GOALS::Schema::Result::Clip;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GOALS::Schema::Result::Clip

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

=head1 TABLE: C<clips>

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
  default_value: current_timestamp
  is_nullable: 0

=head2 clip_end_timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 profile_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 deleted_timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
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
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "clip_end_timestamp",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "profile_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "deleted_timestamp",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</clip_id>

=back

=cut

__PACKAGE__->set_primary_key("clip_id");

=head1 RELATIONS

=head2 buttons

Type: has_many

Related object: L<GOALS::Schema::Result::Button>

=cut

__PACKAGE__->has_many(
  "buttons",
  "GOALS::Schema::Result::Button",
  { "foreign.clip_id" => "self.clip_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 channel

Type: belongs_to

Related object: L<GOALS::Schema::Result::Channel>

=cut

__PACKAGE__->belongs_to(
  "channel",
  "GOALS::Schema::Result::Channel",
  { channel_id => "channel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 event

Type: belongs_to

Related object: L<GOALS::Schema::Result::Event>

=cut

__PACKAGE__->belongs_to(
  "event",
  "GOALS::Schema::Result::Event",
  { event_id => "event_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z8oBOWhW5c7w2Vb7SEms8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
