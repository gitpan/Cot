package Cot::Plugin;

use strict;
use warnings;
use 5.008005;
our $VERSION = "0.09";
$VERSION = eval $VERSION;
use Carp;

sub import {
    my $class = shift;
    my $pkg   = caller(0);
    if ( $class eq 'Cot::Plugin' ) {
        foreach (@_) {
            my $klass = "Cot::Plugin::$_";
            eval "require $klass" or croak "Plugin[$_] is not installed.";
            $klass->_regist($pkg);
        }
        return;
    }
    $class->_regist($pkg);
}

sub _regist {
    my ( $class, $pkg ) = @_;
    croak "$pkg is not Cot object[$class importing...]"
      unless $pkg->isa('Cot');
    $pkg->_register_plugin($class);
}
sub new { bless {}, shift; }

sub init {
    my ( $self, $c ) = @_;
}

1;
__END__

=encoding utf-8

=head1 NAME

Cot::Plugin - Cot plugin base module

=head1 SYNOPSIS

For example, Text::Xslate plugin is below(It's only a example!).

    use strict;
    use warnings;
    use parent Cot::Plugin;
    use Text::Xslate;

    ### "init" is initialize method only called once.

    sub init {
         my ( $self, $c ) = @_;
         # in "init" adding "tx" method to Cot context object.
         $c->tx($self);
    }

    ### define plugin methods

    # "tx" method can call "output";
    sub output {
        my $self          = shift;
        my $txfile        = shift;
        my $param         = shift;
        my $tx            = Text::Xslate->new;
        $tx->render( $txfile, $param );
     }
     1;
     __END__

You can use in a Cot application.

    use Cot;
    use Cot::Plugin qw/TX/;
    # or use Cot::Plugin::TX;

    get '/' => sub {
        my $self = shift;
        $self->res->status(200);
        $self->res->headers({'Content-Type' => 'text/plain' });

        # you can call "tx" plugin
        my $out = $self->tx->output('/path/to/template', { hello => 'world' });
        $self->res->body($out);
    };

=head1 DESCRIPTION

Cot::Plugin is base class of Plugins.

=head1 LICENSE

Copyright (C) Yusuke Shibata

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Shibata E<lt>shibata@yusukeshibata.jpE<gt>

