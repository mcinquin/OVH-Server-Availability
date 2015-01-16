#!/usr/bin/perl
###
# Version  Date      Author  Description
#----------------------------------------------
# 1.0      16/01/15  Shini   Initial version
#
###
# GPL Licence 2.0.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation ; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, see <http://www.gnu.org/licenses>.


#Init
use strict;
use warnings;

use Data::Dumper;
use LWP::UserAgent;
use JSON;
use URI;
use Email::Send::SMTP::Gmail;
use Getopt::Long;


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


my $body;
my $total;
my $content;
my $url = 'https://ws.ovh.com/dedicated/r2/ws.dispatcher/getAvailability2';
my %options = (
    "smtp-host" => undef, "smtp-port" => undef, "smtp-user" => undef, "smtp-password" => undef, "to" => undef,
    "from" => undef, "zone" => undef, "server" => undef, "layer" => undef,
);
my $version = "0.1";
my $change_date = "16/01/2015";

#Parameters
Getopt::Long::Configure('bundling');
GetOptions(
    "server=s"        => \$options{'server'},
    "zone=s"          => \$options{'zone'},
    "from=s"          => \$options{'from'},
    "to=s"            => \$options{'to'},
    "smtp-user=s"     => \$options{'smtp-user'},
    "smtp-password=s" => \$options{'smtp-password'},
    "smtp-host=s"     => \$options{'smtp-host'},
    "smtp-port=i"     => \$options{'smtp-port'},
    "auth=s"          => \$options{'auth'},
    "layer=s"         => \$options{'layer'},
);

#SMTP connection
my ($mail,$error)=Email::Send::SMTP::Gmail->new(-smtp=>$options{'smtp-host'},
                                                -login=>$options{'smtp-user'},
                                                -pass=>$options{'smtp-password'},
                                                -layer=>$options{'layer'},
);
print "Session error: $error" unless ($mail!=-1);



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
my @servers = @{$content->{answer}->{availability}};
foreach my $server (@servers) {
    if ($server->{reference} =~ $map_server_id{$options{'server'}}) {
        $body = $map_id_server{$server->{reference}}."\n";
        $body .= "=" x length($map_id_server{$server->{reference}});
        $body .= "\n";
        foreach my $zone (@{$server->{zones}}) {
            if ($zone->{availability} =~ /unavailable|unknown/) {
                $body .= $map_dc_id{$zone->{zone}}." : Available\n";
                $total++;
            }
        }
    }
}
if ($total ne '0') {
    $mail->send(-from=>$options{'from'}, -to=>$options{'to'}, -subject=>'OVH Servers Availalibility!',
                -body=>$body, -contenttype=>'text/plain',
    );
}
$mail->bye;
