package Cot;

use strict;
use warnings;
use 5.008005;
our $VERSION = "0.09";
$VERSION = eval $VERSION;
use File::Spec;
use Plack::Request;
use Plack::Runner;
use Plack::App::File;
use Carp;
use vars qw($AUTOLOAD %POOL);

sub import {
    my $class = shift;
    my $pkg   = caller(0);
    strict->import;
    warnings->import;
    {
        no strict 'refs';
        push @{"$pkg\::ISA"}, $class;
    }
    for my $func (qw/run get post put patch delete options any static plugin/) {
        no strict 'refs';
        *{"$pkg\::$func"} = \&{"_export_$func"};
    }
}

sub _register_plugin {
    my ( $class, $plugin_klass ) = @_;
    $plugin_klass->new->init( $class->_app );
}

sub _root {
    $ENV{COT_ROOT} || '.';
}

sub _app {
    my $class = shift;
    $POOL{ $class->_root } || $class->new;
}

sub new {
    my $class = shift;
    my $self  = bless {
        controller => {},
        plugins    => [],
    }, $class;
    $POOL{ $class->_root } = $self;
}

# get '/' => sub { my $c = shift; }
sub _method {
    my ( $class, $path, $sub, @methods ) = @_;
    foreach (@methods) {
        $class->_app->{controller}->{$_} ||= {};
        $class->_app->{controller}->{$_}->{$path} = $sub;
    }
}

sub _export_plugin {
    my @plugins = @_;
    my $class   = caller(0);
    foreach (@_) {
        my $klass = "Cot::Plugin::$_";
        eval "require $klass" or croak "Plugin[$_] is not installed.";
        $klass->_regist($class);
    }
}

sub _export_get {
    my ( $path, $sub ) = @_;
    my $class = caller(0);
    $class->_method( $path, $sub, 'get' );
}

sub _export_post {
    my ( $path, $sub ) = @_;
    my $class = caller(0);
    $class->_method( $path, $sub, 'post' );
}

sub _export_put {
    my ( $path, $sub ) = @_;
    my $class = caller(0);
    $class->_method( $path, $sub, 'put' );
}

sub _export_delete {
    my ( $path, $sub ) = @_;
    my $class = caller(0);
    $class->_method( $path, $sub, 'delete' );
}

sub _export_patch {
    my ( $path, $sub ) = @_;
    my $class = caller(0);
    $class->_method( $path, $sub, 'patch' );
}

sub _export_options {
    my ( $path, $sub ) = @_;
    my $class = caller(0);
    $class->_method( $path, $sub, 'options' );
}

sub _export_any {
    my ( $path, $sub ) = @_;
    my $class = caller(0);
    $class->_method( $path, $sub, 'get', 'post', 'put', 'patch', 'options',
        'delete' );
}

sub _export_static {
    my ($path)     = @_;
    my $class      = caller(0);
    my $controller = $class->_app->{controller};
    $controller->{get} ||= {};
    $controller->{get}->{$path} = \&_static;
}

sub _static {
    my $self      = shift;
    my $path_info = $self->env->{PATH_INFO};
    my $path =
      File::Spec->catfile( $ENV{DOCUMENT_ROOT} || 'public', $path_info );
    if ( !-e $path ) {
        $self->notfound_response;
    }
    elsif ( -d $path ) {
        if ( $path_info =~ /.*\/$/ ) {
            my @di = split( /:/, $ENV{COT_DIRECTORYINDEX} || '' );
            foreach my $di (@di) {
                my $index = File::Spec->catfile( $path, $di );
                if ( -f $index ) {
                    my $file =
                      Plack::App::File->new( file => $index )
                      ->call( $self->env );
                    $self->res->status( $file->[0] );
                    $self->res->headers( $file->[1] );
                    $self->res->body( $file->[2] );
                    return;
                }
            }
            $self->forbidden_response;
        }
        else {
            $self->redirect_response( $path_info . '/' );
        }
    }
    else {
        my $file = Plack::App::File->new( file => $path )->call( $self->env );
        $self->res->status( $file->[0] );
        $self->res->headers( $file->[1] );
        $self->res->body( $file->[2] );
    }

}

sub app {
    my ( $class, $env ) = @_;
    my $self        = $class->_app;
    my @path_info   = ();
    my $req         = Plack::Request->new($env);
    my $method      = lc( $req->method );
    my $path        = $req->uri->path;
    my @path        = File::Spec->splitdir($path);
    my $controllers = $self->{controller}->{$method} || {};
    my $controller;

    for ( ; ; ) {
        my $u = File::Spec->catdir(@path);
        $controller = $controllers->{$u} and last;
        last unless scalar(@path);
        unshift @path_info, pop(@path);
    }
    $self->{req}       = $req;
    $self->{env}       = $env;
    $self->{res}       = $req->new_response;
    $self->{path}      = $path;
    $self->{path_info} = \@path_info;
    $controller ? &{ \&$controller }($self) : $self->forbidden_response;
    $self->res->finalize;
}
sub req       { shift->{req}; }
sub res       { shift->{res}; }
sub env       { shift->{env}; }
sub path      { shift->{path}; }
sub path_info { shift->{path_info}; }

sub forbidden_response {
    my $self = shift;
    $self->res->status(403);
    $self->res->body('forbidden');
}

sub notfound_response {
    my $self = shift;
    $self->res->status(404);
    $self->res->body('not found');
}

sub redirect_response {
    my ( $self, $url ) = @_;
    $self->res->redirect($url);
}

sub AUTOLOAD {
    my $self   = shift;
    my $caller = caller(0);
    ( my $method = $AUTOLOAD ) =~ s/.*:://;
    croak(" App can be extended only by Plugins [ !$caller->$method ] ")
      unless ( $caller->isa('Cot::Plugin') );
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        $self->{$method} = $_[0] if ( $_[0] );
        return $self->{$method};
    };
    $self->$method(@_);
}

sub DESTROY { }

sub _export_run {
    my @argv   = @_;
    my $class  = caller(0);
    my $runner = Plack::Runner->new;
    if ( scalar @argv ) {
        @argv = split( /\s+/, $argv[0] ) if ( scalar @argv == 1 );
        $runner->parse_options(@argv);
    }
    my $app = sub { $class->app(shift); };
    $runner->run($app);
}

1;
__END__

=encoding utf-8

=head1 NAME

Cot - super lightweight perl framework based on Plack

=head1 SYNOPSIS

    #!/usr/bin/env perl -w

    use Cot;

    get '/' => sub {
        my $self = shift;
        $self->res->status(200);
        $self->res->headers( { 'Content-Type' => 'text/plain', } );
        $self->res->body('Hello world!');
    };

    run;

The above is a basic but functional web app created with Cot.

=head1 DESCRIPTION

Cot is super lightweight perl framework base on Plack!
you can extend Cot by using many plugins.



You can initialize application skelton using cotto utility executable.

    % cot init Test
    % cd ./Test
    % cot run

=head1 METHODS

=head2 plugin

Added plugins to Cot App.

    use Cot;

    plugin qw/Config Session/;

=head2 get

Receive GET request:

    use Cot;

    get '/api/echo' => sub {
        my $self = shift;
        #code
    };

=head2 post

Receive POST request:

    use Cot;

    post '/api/echo' => sub {
        my $self = shift;
        #code
    };

=head2 put

Receive PUT request:

    use Cot;

    put '/api/echo' => sub {
        my $self = shift;
        #code
    };

=head2 delete

Receive DELETE request:

    use Cot;

    delete '/api/echo' => sub {
        my $self = shift;
        #code
    };

=head2 options

Receive OPTIONS request:

    use Cot;

    options '/api/echo' => sub {
        my $self = shift;
        #code
    };

=head2 patch

Receive PATCH request:

    use Cot;

    patch '/api/echo' => sub {
        my $self = shift;
        #code
    };

=head2 any

Receive any HTTP request:

    use Cot;

    any '/api/echo' => sub {
        my $self = shift;
        #code
    };

=head2 static

Serve static files:

    use Cot;

    static => '/ui';

=head2 run

Up the Plack execution loop.
You can set L<plackup> arguments.

    use Cot;

    run("-- port 5001 -R public");

=head2 forbidden_response

    use Cot;

    get '/secret' => sub {
        $self->res->status(403);
        $self->res->body('forbidden');
    };

same as below.

    use Cot;

    get '/secret' => sub {
        $self->forbidden_response;
    };

=head2 notfound_response

    use Cot;

    get '/secret' => sub {
        $self->res->status(404);
        $self->res->body('notfound');
    };

same as below.

    use Cot;

    get '/secret' => sub {
        $self->notfound_response;
    };

=head2 redirect_response

    use Cot;

    get '/secret' => sub {
        $self->res->redirect('/', 301);
    };

same as below.

    use Cot;

    get '/secret' => sub {
        $self->redirect_response;
    };

=head1 Context METHODS

=head2 req

B<req> is a L<Plack::Request> Object. You can call all methods of Plack::Request.

    use Cot;

    get '/test' => sub {
        my $self = shift;
        my $req = $self->req;
        my $test = $req->param('test');
    };

=head2 res

B<res> is a L<Plack::Response> Object. You can call all methods of Plack::Response.

    use Cot;

    get '/test' => sub {
        my $self = shift;
        $self->res->status(200);
        $self->res->headers({'Content-Type' => 'text/plain' });
        $self->res->body($self->config->{sample});
    };

=head2 path_info

B<path_info> is PATH_INFO Array ref object.

    use Cot;

    # if called /test/hello
    get '/test' => sub {
        my $self = shift;
        my $info = $self->path_info->[0]; #hello
        ...
    };

=head2 env

B<env> is Plack environment variable.

    use Cot;

    get '/test' => sub {
        my $self = shift;
        my $remote_addr = $self->env->{REMOTE_ADDR}; # same as $self->req->address
        ...
    };

=head2 path

B<path> is requested PATH string

    use Cot;

    # if called /test/hello/myname
    get '/test' => sub {
        my $self = shift;
        my $path = $self->path; # /test/hello/myname
        ...
    };

=head1 ENV

You can set ENVIRONMENT variables for change behaviour.

=head2 COT_ROOT

Default value is " B <.>". For example mod_perl configuration, you can set

    PerlSetEnv COT_ROOT /www/TestApp/

=head2 COT_ENV

Default value is B<developement>. You can change COT_ENV for configration.

    #!/bin/sh
    export COT_ENV=production
    cot run

=head2 COT_DIRECTORYINDEX

Default value is none. If you use B<static> method, automatically serve DIRECTORYINDEX

   #!/bin/sh
   export DIRECTORYINDEX=index.html:index.xhtml
   cot run

=head1 PLUGINS

Cot has plaggable interface. For default install only L<Cot::Plugin::Config> can be used.

config file($ENV{COT_ROOT}/config.yaml):

    developement:
      hello: world

application code:

    use Cot;
    use Cot::Plugin qw/Config/;
    # or use Cot::Plugin::Config;

    get '/' => sub {
       my $self = shift;
       my $hello = $c->config->{'hello'}; # world
       ...
    };

=head1 AUTHORS

This module has been written by Yusuke Shibata <shibata@yusukeshibata.jp> and others,
see the AUTHORS file that comes with this distribution for details.

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<https://github.com/yusukeshibata/Cot>.  Feel free to fork the repository and
submit pull requests!

=head1 DEPENDENCIES

The following modules are mandatory (Cot cannot run without them):

=over 8

=item L<YAML>

=item L<Plack>

=back

=head1 LICENSE

Copyright (C) Yusuke Shibata

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Shibata E<lt>shibata@yusukeshibata.jpE<gt>
