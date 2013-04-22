#!/usr/bin/env perl -w

use Cot;

get '/' => sub {
    my $self = shift;
    $self->res->status(200);
    $self->res->headers( { 'Content-Type' => 'text/plain', } );
    $self->res->body('Hello world!');
};

run;
