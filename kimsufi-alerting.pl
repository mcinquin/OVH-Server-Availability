#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use LWP::UserAgent;
use JSON;
use URI;


my $content;
my $url = 'https://ws.ovh.com/dedicated/r2/ws.dispatcher/getAvailability2';

#User Agent Creation
my $ua = LWP::UserAgent->new( keep_alive => '1', protocols_allowed => ['https'], timeout => '10');

#URI Creation
my $uri = URI->new($url);

#Web Page connection
my $req = HTTP::Request->new( GET => $uri);
my $response = $ua->request($req);

#JSON Decoding
if ($response->is_success) {
    my $json = JSON->new;

    eval {
        $content = $json->decode($response->content);
    };

    if ($@) {
        print "Cannot decode json response\n";
    }
} else {
    print "Cannot connect to webpage\n";
}

#JSON Parsing
