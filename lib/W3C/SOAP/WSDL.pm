package W3C::SOAP::WSDL;

# Created on: 2012-05-27 18:57:16
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

extends 'W3C::SOAP::Client';

our $VERSION     = version->new('0.0.6');

sub _request {
    my ($self, $action, @args) = @_;
    my $meta      = $self->meta;
    my $method    = $self->_get_operation_method($action);
    my $operation = $method->wsdl_operation;
    my $resp;

    if ( $method->has_in_class && $method->has_in_attribute ) {
        my $class = $method->in_class;
        my $att   = $method->in_attribute;
        my $xsd   = $class->new(
            $att => @args == 1 ? $args[0] : {@args},
        );
        my $xsd_ns = $xsd->xsd_ns;
        if ( $xsd_ns !~ m{/$} ) {
            $xsd_ns .= '/';
        }
        $resp = $self->request( "$xsd_ns$operation" => $xsd );
    }
    else {
        $resp = $self->request( $operation, @args );
    }

    if ( $method->has_out_class && $method->has_out_attribute ) {
        my $class = $method->out_class;
        my $att   = $method->out_attribute;
        return $class->new($resp)->$att;
    }
    else {
        return $resp;
    }
}

sub _get_operation_method {
    my ($self, $action) = @_;

    my $method = $self->meta->get_method($action);
    return $method if $method && $method->meta->name eq 'W3C::SOAP::WSDL::Meta::Method';

    for my $super ( $self->meta->superclasses ) {
        next unless $super->can('_get_operation_method');
        $method = $super->_get_operation_method($action);
        return $method if $method && $method->meta->name eq 'W3C::SOAP::WSDL::Meta::Method';
    }

    confess "Could not find any methods called $action!";
}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL - A SOAP WSDL Client object

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL version 0.0.6.


=head1 SYNOPSIS

   use W3C::SOAP::WSDL;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Inherits from L<W3C::SOAP::Client>

=head1 SUBROUTINES/METHODS

=over 4

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
