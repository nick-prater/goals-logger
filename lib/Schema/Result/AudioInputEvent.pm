package Schema::Result::AudioInputEvent;

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

Schema::Result::AudioInputEvent

=cut

__PACKAGE__->table("audio_input_events");

=head1 ACCESSORS

=head2 audio_input_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 event_input_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "audio_input_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "event_input_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-05-31 14:24:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fYG8ztnNDa+DrcG0X+Rd7A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
