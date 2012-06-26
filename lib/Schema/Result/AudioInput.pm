package Schema::Result::AudioInput;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PassphraseColumn");

=head1 NAME

Schema::Result::AudioInput

=cut

__PACKAGE__->table("audio_inputs");

=head1 ACCESSORS

=head2 audio_input_id

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

=head2 record_threshold_dbfs

  data_type: 'decimal'
  is_nullable: 1
  size: [6,3]

=cut

__PACKAGE__->add_columns(
  "audio_input_id",
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
  "record_threshold_dbfs",
  { data_type => "decimal", is_nullable => 1, size => [6, 3] },
);
__PACKAGE__->set_primary_key("audio_input_id");

=head1 RELATIONS

=head2 audio_input_events

Type: has_many

Related object: L<Schema::Result::AudioInputEvent>

=cut

__PACKAGE__->has_many(
  "audio_input_events",
  "Schema::Result::AudioInputEvent",
  { "foreign.audio_input_id" => "self.audio_input_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 audio_labels

Type: has_many

Related object: L<Schema::Result::AudioLabel>

=cut

__PACKAGE__->has_many(
  "audio_labels",
  "Schema::Result::AudioLabel",
  { "foreign.audio_input_id" => "self.audio_input_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-05-31 14:24:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UIy3K+V1NBKJKmJpeg8Plg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
