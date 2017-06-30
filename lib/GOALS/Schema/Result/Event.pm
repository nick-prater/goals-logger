use utf8;
package GOALS::Schema::Result::Event;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GOALS::Schema::Result::Event

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

=head1 TABLE: C<events>

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
  default_value: current_timestamp
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
    default_value => \"current_timestamp",
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

=head1 PRIMARY KEY

=over 4

=item * L</event_id>

=back

=cut

__PACKAGE__->set_primary_key("event_id");

=head1 RELATIONS

=head2 clips

Type: has_many

Related object: L<GOALS::Schema::Result::Clip>

=cut

__PACKAGE__->has_many(
  "clips",
  "GOALS::Schema::Result::Clip",
  { "foreign.event_id" => "self.event_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 event_input

Type: belongs_to

Related object: L<GOALS::Schema::Result::EventInput>

=cut

__PACKAGE__->belongs_to(
  "event_input",
  "GOALS::Schema::Result::EventInput",
  { event_input_id => "event_input_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-06-30 11:18:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:f/shMzn1k55ShTpxTRlU2w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
