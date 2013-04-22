package Cot::Plugin::Config;

use strict;
use warnings;
use 5.008005;
our $VERSION = "0.01";
$VERSION = eval $VERSION;
use parent qw(Cot::Plugin);
use Cot::Config;

sub init {
    my ( $self, $c ) = @_;
    $c->config( Cot::Config->config );
}

1;
__END__

=encoding utf-8

=head1 NAME

Cot::Plugin::Config - Cot configuration plugin

=head1 SYNOPSIS

For example,

    use Cot;
    use Cot::Plugin::Config;

    get "/test" => sub {
        my $self = shift;
        my $db = $self->config->{'db'};
        ...
    };

Config yaml file($ENV{COT_ROOT}/config.yaml) is,

    development:
      db: dbi:mysql:diary:localhost

    production:
      db: dbi:mysql:diary:192.168.1.10

=head1 DESCRIPTION

Cot::Plugin::Config is an only build in Plugin is Cot framework.
You can descsribe Config file(B<config.yaml>) and call B<config> method of Cot object.
return the hash reference of B<config.yaml> file $ENV{COT_ENV} entries data.

=head1 LICENSE

Copyright (C) Yusuke Shibata

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Shibata E<lt>shibata@yusukeshibata.jpE<gt>

