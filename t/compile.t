#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

use_ok( 'Net::Azure::StorageClient' );
use_ok( 'Net::Azure::StorageClient::Blob' );

