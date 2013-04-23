# NAME

Cot - super lightweight perl framework based on Plack

# SYNOPSIS

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

# DESCRIPTION

Cot is super lightweight perl framework base on Plack!
you can extend Cot by using many plugins.





You can initialize application skelton using cotto utility executable.

    % cot init Test
    % cd ./Test
    % cot run

# METHODS

## get

Receive GET request:

    use Cot;

    get '/api/echo' => sub {
        my $self = shift;
        #code
    };

## post

Receive POST request:

    use Cot;

    post '/api/echo' => sub {
        my $self = shift;
        #code
    };

## any

Receive any HTTP request:

    use Cot;

    any '/api/echo' => sub {
        my $self = shift;
        #code
    };

## static

Serve static files:

    use Cot;

    static => '/ui';

## run

Up the Plack execution loop.
You can set [plackup](http://search.cpan.org/perldoc?plackup) arguments.

    use Cot;

    run("--port 5001 -R");

# Context METHODS

## req

__req__ is a [Plack::Request](http://search.cpan.org/perldoc?Plack::Request) Object. You can call all methods of Plack::Request.

    use Cot;

    get '/test' => sub {
        my $self = shift;
        my $req = $self->req;
        my $test = $req->param('test');
    };

## res

__res__ is a [Plack::Response](http://search.cpan.org/perldoc?Plack::Response) Object. You can call all methods of Plack::Response.

    use Cot;

    get '/test' => sub {
        my $self = shift;
        $self->res->status(200);
        $self->res->headers({'Content-Type' => 'text/plain' });
        $self->res->body($self->config->{sample});
    };

## path\_info

__path\_info__ is PATH\_INFO Array ref object.

    use Cot;

    # if called /test/hello
    get '/test' => sub {
        my $self = shift;
        my $info = $self->path_info->[0]; #hello
        ...
    };

## env

__env__ is Plack environment variable.

    use Cot;

    get '/test' => sub {
        my $self = shift;
        my $remote_addr = $self->env->{REMOTE_ADDR}; # same as $self->req->address
        ...
    };

## uri

__uri__ is requested URI string

    use Cot;

    # if called /test/hello/myname
    get '/test' => sub {
        my $self = shift;
        my $uri = $self->uri; # /test/hello/myname
        ...
    };

# ENV

You can set ENVIRONMENT variables for change behaviour.

## COT\_ROOT

Default value is "__.__". For example mod\_perl configuration, you can set

    PerlSetEnv COT_ROOT /www/TestApp/

## COT\_ENV

Default value is __developement__. You can change COT\_ENV for configration.

    #!/bin/sh
    export COT_ENV=production
    cot run

## COT\_DIRECTORYINDEX

Default value is none. If you use __static__ method, automatically serve DIRECTORYINDEX

    #!/bin/sh
    export DIRECTORYINDEX=index.html:index.xhtml
    cot run

# PLUGINS

Cot has plaggable interface. For default install only [Cot::Plugin::Config](http://search.cpan.org/perldoc?Cot::Plugin::Config) can be used.

config file($ENV{COT\_ROOT}/config.yaml):

    developement:
      hello: world

application code:

    use Cot;
    use Cot::Plugin qw/Config/;
    # or use Cot::Plugin::Config;

    get "/" => sub {
       my $self = shift;
       my $hello = $c->config->{'hello'}; # world
       ...
    };

# AUTHORS

This module has been written by Yusuke Shibata <shibata@yusukeshibata.jp> and others,
see the AUTHORS file that comes with this distribution for details.

# SOURCE CODE

The source code for this module is hosted on GitHub
[https://github.com/yusukeshibata/Cot](https://github.com/yusukeshibata/Cot).  Feel free to fork the repository and
submit pull requests!

# DEPENDENCIES

The following modules are mandatory (Cot cannot run without them):

- [YAML](http://search.cpan.org/perldoc?YAML)
- [Plack](http://search.cpan.org/perldoc?Plack)

# LICENSE

Copyright (C) Yusuke Shibata

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yusuke Shibata <shibata@yusukeshibata.jp>
