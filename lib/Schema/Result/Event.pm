package Schema::Result::Event;

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

Schema::Result::Event

=cut

__PACKAGE__->table("events");

=head1 ACCESSORS

=head2 event_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 event_input_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 event_timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 event_type

  data_type: 'enum'
  extra: {list => ["on","off","instance"]}
  is_nullable: 0

=head2 status

  data_type: 'enum'
  default_value: 'new'
  extra: {list => ["new","open","exported","deleted"]}
  is_nullable: 0

=head2 update_timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "event_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "event_input_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "event_timestamp",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "event_type",
  {
    data_type => "enum",
    extra => { list => ["on", "off", "instance"] },
    is_nullable => 0,
  },
  "status",
  {
    data_type => "enum",
    default_value => "new",
    extra => { list => ["new", "open", "exported", "deleted"] },
    is_nullable => 0,
  },
  "update_timestamp",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("event_id");

=head1 RELATIONS

=head2 clips

Type: has_many

Related object: L<Schema::Result::Clip>

=cut

__PACKAGE__->has_many(
  "clips",
  "Schema::Result::Clip",
  { "foreign.event_id" => "self.event_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 event_input

Type: belongs_to

Related object: L<Schema::Result::EventInput>

=cut

__PACKAGE__->belongs_to(
  "event_input",
  "Schema::Result::EventInput",
  { event_input_id => "event_input_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-07-11 17:01:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hAO7crslahXiMvJDX/bttg


__PACKAGE__->many_to_many(
	'channels',
	'channel_events',
	'channel'
);








# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
