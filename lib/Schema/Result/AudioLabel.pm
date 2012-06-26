package Schema::Result::AudioLabel;

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

Schema::Result::AudioLabel

=cut

__PACKAGE__->table("audio_labels");

=head1 ACCESSORS

=head2 audio_label_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 audio_input_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 label

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 label_type

  data_type: 'enum'
  extra: {list => ["match_name"]}
  is_nullable: 0

=head2 update_timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "audio_label_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "audio_input_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "label",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "label_type",
  {
    data_type => "enum",
    extra => { list => ["match_name"] },
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
__PACKAGE__->set_primary_key("audio_label_id");

=head1 RELATIONS

=head2 audio_input

Type: belongs_to

Related object: L<Schema::Result::AudioInput>

=cut

__PACKAGE__->belongs_to(
  "audio_input",
  "Schema::Result::AudioInput",
  { audio_input_id => "audio_input_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-05-31 14:24:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:61thQxWVpKxPRM8ae7IV3A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
