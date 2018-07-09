#!/usr/bin/perl
###
# Version  Date      Author  Description
#----------------------------------------------
# 0.1      16/01/15  Shini   Initial version
# 0.2      17/01/15  Shini   Add checking for options
# 1.0      18/01/15  Shini   1.0 stable release
# 1.1      03/02/15  Shini   Minor fixes
# 1.2      22/11/15  Shini   Minor fixes
# 1.3      03/03/16  Shini   Update servers list
# 1.4      09/07/18  Shini   Update servers and zones lists
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
    'par' => 'Paris',
    'fra' => 'Francfort',
    'syd' => 'Sydney',
    'vin' => 'Vint Hill',
    'hil' => 'Hillsboro',
    'waw' => 'Warsaw',
    'rbx-hz' => 'Roubaix HardZone',
    'lon' => 'Londres',
    'sgp' => 'Singapour'
);

my %map_server_id = (
    'KS-1' => '1801sk12',
    'KS-2' => '1801sk13',
    'KS-3' => '1801sk14',
    'KS-4' => '1801sk15',
    'KS-5' => '1801sk16',
    'KS-6' => '1801sk17',
    'KS-7' => '1801sk18',
    'KS-8' => '1801sk19',
    'KS-9' => '1801sk20',
    'KS-10' => '1801sk21',
    'KS-11' => '1801sk22',
    'KS-12' => '1801sk23',
    'GAME-1' => '1801sysgame04',
    'GAME-2' => '1801sysgame05',
    'GAME-3' => '1801sysgame06',
    'OP-SAT-1-32' => '1801sys46',
    'OP-SAT-2-128' => '1801sys52',
    'E3-SAT-1-16' => '1801sys45',
    'E3-SAT-1-32' => '1801sys48',
    'E3-SSD-1-32' => '1801sys47',
    'E3-SSD3-16' => '1801sys221',
    'E3-SAT3-16' => '1801sys22',
    'E3-SSD-5-32' => '1801sys13',
    'E3-SAT-3-32' => '1801sys01',
    'E3-SAT3-32' => '1801sys23',
    'I7-SSD-1-32' => '1801sys16',
    'E3-SAT-2-32' => '1801sys011',
    'E3-SAT-2-32' => '1801sys50',
    'E3-SSD-2-32' => '1801sys49',
    'E5v3-SAT-1-32' => '1801sys24',
    'E5-SAT-1-64' => '1801sys53',
    'E5-SSD-1-64' => '1801sys54',
    'E5v3-SSD-1-32' => '1801sys242',
    'E5-SAT-2-64' => '1801sys56',
    'E5-SSD-2-64' => '1801sys55',
    'ARM-2T' => '1801armada01',
    'ARM-4T' => '1801armada02',
    'ARM-6T' => '1801armada03',
    'E5-SSD-3-64' => '1801sys57',
    'E5-SSD-1-128' => '1801sys58',
    'E5-SSD-1-192' => '1801sys59',
    'E5-SSD-1-256' => '1801sys60',
    'E5-SSD-2-128' => '1801sys61'
);


my %map_id_server = reverse(%map_server_id);

my $version = "1.4";
my $change_date = "09/07/2018";

my ($body, $mail, $error);
my $total = 0;
my $content;
my $url = 'https://ws.ovh.com/dedicated/r2/ws.dispatcher/getAvailability2';

my $conf = Config::General->new($Bin.'/config.ini');
my %options = $conf->getall;


#Checking options
if (defined($options{'mail'} eq '1') && !defined($options{'from'})) {
    print "Need --from option\n";
    exit 1;
}

if ($options{'mail'} eq '1' && !defined($options{'to'})) {
    print "Need --to option\n";
    exit 1;
}

if (defined($options{'mail'} eq '1') && !defined($options{'smtp-host'})) {
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
my $ua = LWP::UserAgent->new( keep_alive => '1', protocols_allowed => ['https'], timeout => '20');


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
