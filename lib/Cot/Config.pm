package Cot::Config;

use strict;
use warnings;
use 5.008005;
our $VERSION = "0.01";
$VERSION = eval $VERSION;
use YAML ();
use File::Spec;
use constant CONFIG_FILENAME => 'config.yaml';
use vars qw(%CONFIG);

sub _root {
    $ENV{COT_ROOT} || '.';
}

sub loadconfig {
    my $class = shift;
    return if $CONFIG{ $class->_root };
    my $configpath = File::Spec->catfile( $class->_root, CONFIG_FILENAME );
    return unless ( -f $configpath );
    my $c = YAML::LoadFile($configpath);
    foreach ( keys %$c ) {
        $CONFIG{ $class->_root } ||= {};
        $CONFIG{ $class->_root }->{$_} = $c->{$_};
    }
}

sub config {
    my $class = shift;
    $CONFIG{ $class->_root }->{ $ENV{COT_ENV} || "development" };
}

sub BEGIN {
    __PACKAGE__->loadconfig;
}

1;
__END__

=encoding utf-8

=head1 NAME

Cot - It's new $module

=head1 SYNOPSIS

    use Cot;

=head1 DESCRIPTION

Cot is ...

=head1 LICENSE

Copyright (C) Yusuke Shibata

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Shibata E<lt>shibata@yusukeshibata.jpE<gt>

