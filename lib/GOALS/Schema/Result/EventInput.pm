use utf8;
package GOALS::Schema::Result::EventInput;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GOALS::Schema::Result::EventInput

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

=head1 TABLE: C<event_inputs>

=cut

__PACKAGE__->table("event_inputs");

=head1 ACCESSORS

=head2 event_input_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 input_type

  data_type: 'enum'
  extra: {list => ["hardware_gpi"]}
  is_nullable: 0

=head2 event_type

  data_type: 'enum'
  extra: {list => ["audio_marker"]}
  is_nullable: 0

=head2 channel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "event_input_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "input_type",
  {
    data_type => "enum",
    extra => { list => ["hardware_gpi"] },
    is_nullable => 0,
  },
  "event_type",
  {
    data_type => "enum",
    extra => { list => ["audio_marker"] },
    is_nullable => 0,
  },
  "channel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</event_input_id>

=back

=cut

__PACKAGE__->set_primary_key("event_input_id");

=head1 RELATIONS

=head2 channel

Type: belongs_to

Related object: L<GOALS::Schema::Result::Channel>

=cut

__PACKAGE__->belongs_to(
  "channel",
  "GOALS::Schema::Result::Channel",
  { channel_id => "channel_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

=head2 events

Type: has_many

Related object: L<GOALS::Schema::Result::Event>

=cut

__PACKAGE__->has_many(
  "events",
  "GOALS::Schema::Result::Event",
  { "foreign.event_input_id" => "self.event_input_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-06-30 11:18:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sDkkDHdM4xoPLcfgNFlyow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
