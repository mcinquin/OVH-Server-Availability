#!/usr/bin/perl
###
# Version  Date      Author  Description
#----------------------------------------------
# 0.1      16/01/15  Shini   Initial version
# 0.2      17/01/15  Shini   Add checking for options
# 1.0      18/01/15  Shini   1.0 stable release
# 1.1      03/02/15  Shini   Minor fixes
# 1.2      22/11/15  Shini   Minor fixes
#
###


#Init
use strict;
use warnings;

use LWP::UserAgent;
use JSON;
use URI;
use Email::Send::SMTP::Gmail;
use Getopt::Long;
use Config::General;
use FindBin qw($Bin);
use lib "$Bin/../lib";

#Global Variables
my %map_dc_id = (
    'gra' => 'Gravelines',
    'rbx' => 'Roubaix',
    'sbg' => 'Strasbourg',
    'bhs' => 'Beauharnois',
);

my %map_server_id = (
    'KS-1' => '150sk10',
    'KS-2a' => '150sk20',
    'KS-2b' => '150sk21',
    'KS-2c' => '150sk22',
    'KS-3' => '150sk30',
    'KS-4' => '150sk40',
    'KS-5' => '150sk50',
    'KS-6' => '150sk60',
    'GAME-1' => '141game1',
    'GAME-2' => '141game2',
    'GAME-3' => '141game3',
    'BK-8T' => '141bk1',
    'BK-24T' => '141bk2',
    'SYS-IP-1' => '142sys4',
    'SYS-IP-2' => '142sys5',
    'SYS-IP-4' => '142sys5',
    'SYS-IP-5' => '142sys6',
    'SYS-IP-5S' => '142sys10',
    'SYS-IP-6' => '142sys7',
    'SYS-IP-6S' => '142sys9',
    'E3-SAT-1' => '143sys4',
    'E3-SSD-1' => '143sys13',
    'E3-SAT-2' => '143sys1',
    'E3-SSD-2' => '143sys10',
    'E3-SAT-3' => '143sys2',
    'E3-SSD-3' => '143sys11',
    'E3-SAT-4' => '143sys3',
    'E3-SSD-4' => '143sys12',
);


my %map_id_server = reverse(%map_server_id);

my $version = "1.2";
my $change_date = "22/11/2015";

my ($body, $mail, $error);
my $total = 0;
my $content;
my $url = 'https://ws.ovh.com/dedicated/r2/ws.dispatcher/getAvailability2';

my $conf = Config::General->new($Bin.'/config.ini');
my %options = $conf->getall;


#Checking options
if (defined($options{'mail'} eq '1' && !defined($options{'from'})) {
    print "Need --from option\n";
    exit 1;
}

if ($options{'mail'} eq '1' && !defined($options{'to'})) {
    print "Need --to option\n";
    exit 1;
}

if (defined($options{'mail'} eq '1' && !defined($options{'smtp-host'})) {
    print "Need --smtp-host option\n";
    exit 1;
}

if (defined($options{'smtp-user'}) && !defined($options{'smtp-password'})) {
    print "Need --smtp-password option\n";
    exit 1;
}

if (defined($options{'smtp-password'}) && !defined($options{'smtp-user'})) {
    print "Need --smtp-user option\n";
    exit 1;
}

if ($options{'auth'} eq 'LOGIN' && !defined($options{'smtp-user'}) || !defined($options{'smtp-password'})) {
    print "Need --smtp-user and --smtp-password options\n";
    exit 1;
}

#SMTP connection
if ($options{'mail'} eq '1') {
    ($mail,$error)=Email::Send::SMTP::Gmail->new(-smtp=>$options{'smtp-host'},
                                                 -login=>$options{'smtp-user'},
                                                 -pass=>$options{'smtp-password'},
                                                 -layer=>$options{'layer'},
                                                 -timeout=>$options{'timeout'},
                                                 -debug=>$options{'debug'},
    );
    print "Session error: $error\n" unless ($mail!=-1);
    exit 1;
}


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
        exit 1;
    }
} else {
    print "Cannot connect to webpage\n";
    exit 1;
}


#JSON Parsing
my @servers = @{$content->{answer}->{availability}};
foreach my $server (@servers) {
    if ($server->{reference} =~ $map_server_id{$options{'server'}}) {
        $body = $map_id_server{$server->{reference}}."\n";
        $body .= "=" x length($map_id_server{$server->{reference}});
        $body .= "\n";
        foreach my $zone (@{$server->{zones}}) {
            if ($zone->{availability} !~ /unavailable|unknown/) {
                $body .= $map_dc_id{$zone->{zone}}.": Available\n";
                $total++;
            }
        }
    }
}


#Output
if ($total ne '0' && $options{'mail'} eq '1') {
die "Error sending email: $@" if $@;
    eval { $mail->send(-from=>$options{'from'}, -to=>$options{'to'}, -subject=>'OVH Servers Availalibility!',
                -body=>$body, -contenttype=>'text/plain',
    )};
    die "Error sending email: $@" if $@;
    $mail->bye;
} elsif ($total ne '0') {
    print $body;
}
