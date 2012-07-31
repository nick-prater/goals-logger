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

=head2 record_threshold_dbfs

  data_type: 'decimal'
  is_nullable: 1
  size: [6,3]

=head2 timezone

  data_type: 'varchar'
  default_value: 'Europe/London'
  is_nullable: 0
  size: 30

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
  "record_threshold_dbfs",
  { data_type => "decimal", is_nullable => 1, size => [6, 3] },
  "timezone",
  {
    data_type => "varchar",
    default_value => "Europe/London",
    is_nullable => 0,
    size => 30,
  },
);
__PACKAGE__->set_primary_key("channel_id");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-07-11 17:31:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NedQHMnt23sPAZbmqI1KyA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
