package W3C::SOAP::Document;

# Created on: 2012-05-27 19:26:43
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp qw/carp croak cluck confess longmess/;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use TryCatch;
use URI;
use W3C::SOAP::Utils qw/normalise_ns ns2module/;
use W3C::SOAP::Exception;
use XML::LibXML;

our $VERSION     = version->new('0.02');

has string => (
    is         => 'rw',
    isa        => 'Str',
);
has location => (
    is         => 'rw',
    isa        => 'Str',
);
has xml => (
    is       => 'ro',
    isa      => 'XML::LibXML::Document',
    required => 1,
);
has xpc => (
    is         => 'ro',
    isa        => 'XML::LibXML::XPathContext',
    builder    => '_xpc',
    clearer    => 'clear_xpc',
    predicate  => 'has_xpc',
    lazy_build => 1,
);
has target_namespace => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_target_namespace',
    predicate  => 'has_target_namespace',
    lazy_build => 1,
);
has ns_module_map => (
    is        => 'rw',
    isa       => 'HashRef[Str]',
    required  => 1,
    predicate => 'has_ns_module_map',
);
has module => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_module',
    builder   => '_module',
    lazy_build => 1,
);
has module_base => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_module_base',
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args
        = !@args     ? {}
        : @args == 1 ? $args[0]
        :              {@args};

    delete $args->{module_base} if ! defined $args->{module_base};

    if ( $args->{string} ) {
        try {
            $args->{xml} = XML::LibXML->load_xml(string => $args->{string});
        }
        catch($e) {
            chomp $e;
            W3C::SOAP::Exception::XML->throw( error => $e, faultstring => $e );
        }
    }
    elsif ( $args->{location} ) {
        try {
            $args->{xml} = XML::LibXML->load_xml(location => $args->{location});
        }
        catch($e) {
            chomp $e;
            W3C::SOAP::Exception::XML->throw( error => $e, faultstring => $args->{location} );
        }
    }

    return $class->$orig($args);
};

sub _xpc {
    my ($self) = @_;
    my $xpc = XML::LibXML::XPathContext->new($self->xml);
    $xpc->registerNs(xs   => 'http://www.w3.org/2001/XMLSchema');
    $xpc->registerNs(xsd  => 'http://www.w3.org/2001/XMLSchema');
    $xpc->registerNs(wsdl => 'http://schemas.xmlsoap.org/wsdl/');
    $xpc->registerNs(wsp  => 'http://schemas.xmlsoap.org/ws/2004/09/policy');
    $xpc->registerNs(wssp => 'http://www.bea.com/wls90/security/policy');
    $xpc->registerNs(soap => 'http://schemas.xmlsoap.org/wsdl/soap/');

    return $xpc;
}

my $anon = 0;
sub _target_namespace {
    my ($self) = @_;
    my $ns  = $self->xml->getDocumentElement->getAttribute('targetNamespace');
    my $xpc = $self->xpc;
    $xpc->registerNs(ns => $ns) if $ns;

    $ns ||= $self->location || 'NsAnon' . $anon++;

    return $ns;
}

sub _module {
    my ($self) = @_;
    my $ns = $self->target_namespace;

    if ( $self->has_module_base ) {
        $self->ns_module_map->{normalise_ns($self->target_namespace)}
            = $self->module_base . '::' . ns2module($self->target_namespace);
    }

    if ( !$self->ns_module_map->{normalise_ns($ns)} && $self->ns_module_map->{$ns} ) {
        $self->ns_module_map->{normalise_ns($ns)} = $self->ns_module_map->{$ns};
    }

    confess "Trying to get module mappings when none specified!\n" if !$self->has_ns_module_map;
    confess "No mapping specified for the namespace ", $ns, "!\n"  if !$self->ns_module_map->{normalise_ns($ns)};

    return $self->ns_module_map->{normalise_ns($ns)};
}

1;

__END__

=head1 NAME

W3C::SOAP::Document - Object to represent an XML Document

=head1 VERSION

This documentation refers to W3C::SOAP::Document version 0.02.

=head1 SYNOPSIS

   use W3C::SOAP::Document;

   # Instanciate a new document from a string
   my $xml = W3C::SOAP::Document( string => $string );

   # From a url or file
   my $xml = W3C::SOAP::Document->new( location => 'http://eg.com/schema.xsd' );

=head1 DESCRIPTION

C<W3C::SOAP::Document> takes an XML document from a string/file/url/L<XML::LibXML>
object and parses it to extract the important information about the document. This
the base class for L<W3C::SOAP::XSD::Document> and L<W3C::SOAP::WSDL::Document>.

=head1 SUBROUTINES/METHODS

=over 4

=item C<new ( location => ... || string => ... || xml => ... )>

Creates a new C<W3C::SOAP::Document> object.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
