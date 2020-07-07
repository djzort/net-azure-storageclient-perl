#!/bin/false

use strict;
use warnings;

package Net::Azure::StorageClient::Blob::Thread;

use parent qw/Net::Azure::StorageClient::Blob/;
use threads;
use Thread::Semaphore;

use namespace::clean;

sub download_use_thread {
    my ( $self, $args ) = @_;
    my $thread = $args->{ thread } || 10;
    my $semaphore = Thread::Semaphore->new( $thread );
    my $download_items = $args->{ download_items };
    my $params = $args->{ params };
    my $container_name = $args->{ container_name };
    my %th;
    for my $key ( keys %$download_items ) {
        my $item;
        if ( $self->{ container_name } ) {
            $item = $key;
        } else {
            $item = $container_name . '/' . $key,
        }
        $th{ $key } = threads->new(\&_download,
                                    $self,
                                    $item,
                                    $download_items->{ $key },
                                    $params,
                                    $semaphore );
    }
    my @responses;
    for my $key ( keys %$download_items ) {
        my ( $res ) = $th{ $key }->join();
        push ( @responses, $res );
    }
    return @responses;
}

sub _download {
    my ( $self, $from, $to, $params, $semaphore ) = @_;
    $semaphore->down();
    $params->{ force } = 1;
    my $res = $self->download( $from, $to, $params );
    $semaphore->up();
    return $res;
}

sub upload_use_thread {
    my ( $self, $args ) = @_;
    my $thread = $args->{ thread } || 10;
    my $semaphore = Thread::Semaphore->new( $thread );
    my $upload_items = $args->{ upload_items };
    my $params = $args->{ params };
    my %th;
    for my $key ( keys %$upload_items ) {
        $th{ $key } = threads->new(\&_upload,
                                    $self,
                                    $key,
                                    $upload_items->{ $key },
                                    $params,
                                    $semaphore );
    }
    my @responses;
    for my $key ( keys %$upload_items ) {
        my ( $res ) = $th{ $key }->join();
        push ( @responses, $res );
    }
    return @responses;
}

sub _upload {
    my ( $self, $from, $to, $params, $semaphore ) = @_;
    $semaphore->down();
    $params->{ force } = 1;
    my $res = $self->upload( $from, $to, $params );
    $semaphore->up();
    return $res;
}

1;
