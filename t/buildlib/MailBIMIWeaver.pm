package MailBIMIWeaver;
use Moo;
use Class::Load ':all';
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Nested;
use Try::Tiny;

use feature qw{ postderef signatures };;
no warnings qw{ experimental::postderef experimental::signatures };

with 'Pod::Weaver::Role::Section';

sub weave_section {
  my($self, $document, $input) = @_;

  my @section_parts;

  # Find the class name we are building for
  my $ppi = $input->{ppi_document};
  return unless ref $ppi eq 'PPI::Document';
  my $node = $ppi->find_first('PPI::Statement::Package');
  my $class_name = $node->namespace if $node;
  return unless $class_name;

  # Load the class and get its meta data
  my $meta;
  try {
    local @INC=('blib',@INC);
    load_class( $class_name );
    $meta = Class::MOP::Class->initialize( $class_name );
  };
  return unless $meta;

  return unless ref $meta;
  return if $meta->isa('Moose::Meta::Role');
  my @attributes = $meta->get_all_attributes;
  if( @attributes ) {
    foreach my $attribute (@attributes) {
      next unless ref $attribute;
      next if $attribute->name =~ /^_/;
      my $moo_attribute = %{Moo->_constructor_maker_for($class_name)}{attribute_specs}->{$attribute->name};
      my $attribute_type = 'attributes';
      $attribute_type = 'options' if $attribute->name =~ /^CACHE_BACKEND$/;
      $attribute_type = 'options' if $attribute->name =~ /^OPT_/;
      $attribute_type = $moo_attribute->{pod_section} if exists $moo_attribute->{pod_section};
      my @attribute_parts;
      my @definition;
      push @definition, 'is='.$attribute->{is} if $attribute_type eq 'attribute';
      push @definition, 'required' if $attribute->{required} && $attribute_type eq 'attribute';
      push @attribute_parts, Pod::Elemental::Element::Pod5::Ordinary->new({ content => join(' ',@definition) }) if @definition;
      if ($attribute->{documentation}) {
        push @attribute_parts, Pod::Elemental::Element::Pod5::Ordinary->new({ content => $attribute->{documentation} });
      }
      push @section_parts, {
        attribute_type => $attribute_type,
        element => Pod::Elemental::Element::Nested->new({
          command => 'head2',
          content => $attribute->name,
          children => \@attribute_parts,
        }),
      };
    }
  }

  @section_parts = sort { $a->{element}->{content} cmp $b->{element}->{content} } @section_parts;

  foreach my $type ( qw{ inputs attributes options } ) {
    my @relevant_elements = map{ $_->{element} } grep { $_->{attribute_type} eq $type} @section_parts;
    next unless @relevant_elements;
    push @{$document->children},  Pod::Elemental::Element::Nested->new({
      command => 'head1',
      content => uc $type,
      children => \@relevant_elements,
    });
  }
}

__PACKAGE__->meta->make_immutable;
__END__
