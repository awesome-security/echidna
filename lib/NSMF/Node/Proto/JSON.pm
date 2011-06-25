#
# This file is part of the NSM framework
#
# Copyright (C) 2010-2011, Edward Fjellskål <edwardfjellskaal@gmail.com>
#                          Eduardo Urias    <windkaiser@gmail.com>
#                          Ian Firns        <firnsy@securixlive.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License Version 2 as
# published by the Free Software Foundation.  You may not use, modify or
# distribute this program under any other version of the GNU General
# Public License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
package NSMF::Node::Proto::JSON;

use warnings;
use strict;
use v5.10;

#
# PERL INCLUDES
#
use Compress::Zlib;
use Data::Dumper;
use JSON;
use MIME::Base64;
use POE;

#
# NSMF INCLUDES
#
use NSMF::Util;
use NSMF::Common::Logger;

#
# GLOBALS
#
my $instance;
my $logger = NSMF::Common::Logger->new();

sub instance {
    unless ($instance) {
        my ($class) = @_;
        return bless({}, $class);
    }

    return $instance;
}

sub states {
    my ($self) = @_;

    return if (ref($self) ne __PACKAGE__ );

    return [
        'dispatcher',

        ## Authentication
        'authenticate',
        'identify',

        # -> To Server
        'send_ping',
        'send_pong',

        # -> From Server
        'got_ping',
        'got_pong',
    ];
}

sub dispatcher {
    my ($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];
    my $self = shift;

    $logger->warn('  [error] Response is Empty') if ( ! defined($request) );

    my $json = {};

    eval {
        $json = decode_json($request);
    };

    if ( $@ ) {
        return;
    }

    my $method = $self->jsonrpc_result_method($json);
    my $action = "";

    given($heap->{stage}) {
        when(/REQ/) {
            given($method) {
                when(/^authenticate/i) {
                    if ( defined($json->{result}) ) {
                        $action = 'identify';
                        $logger->debug('  [response] = OK ACCEPTED');
                    }
                    elsif ( defined($json->{error}) ) {
                        $logger->debug('  [response] = NOT ACCEPTED');
                        return;
                    }
                    else {
                        $logger->debug(Dumper($json));
                        $logger->debug("  UNKOWN AUTH RESPONSE: $request");
                        return;
                    }
                }
                default: {
                    $logger->debug("  UNKOWN RESPONSE: $request");
                    return;
                }
            }
        }
        when(/SYN/i) {
            given($method) {
                when(/^identify/i) {
                    if ( defined($json->{result}) ) {
                        $heap->{stage} = 'EST';
                        $logger->debug('  [response] = OK ACCEPTED');
                        $kernel->yield('run');
                        $kernel->delay('send_ping' => 3);
                        return;
                    }
                    else {
                        $logger->debug('  [response] = UNSUPPORTED');
                        return;
                    }
                }
                default: {
                    $logger->debug("  UNKOWN RESPONSE: $request");
                    return;
                }
            }
        }
        when(/EST/i) {
            given($method) {
                when(/^ping/i) {
                    if ( defined($json->{result}) )
                    {
                        $action = 'got_pong';
                    }
                    else
                    {
                        $action = "got_ping";
                    }
                }
                default: {
                    $logger->debug(" UNKNOWN RESPONSE: $request");
                    return;
                }
            }
        }
    }

    $kernel->yield($action) if $action;
}

################ AUTHENTICATE ###################
sub authenticate {
    my ($kernel, $heap, $response) = @_[KERNEL, HEAP, ARG0];
    my $self = shift;

    $heap->{stage} = 'REQ';
    my $agent    = $heap->{agent};
    my $secret   = $heap->{secret};

    my $payload = $self->jsonrpc_method_create("authenticate", {
        "agent" => $agent,
        "secret" => $secret
    });

    $heap->{server}->put(encode_json($payload));
}

sub identify {
    my ($kernel, $heap, $response) = @_[KERNEL, HEAP, ARG0];
    my $self = shift;

    my $nodename = $heap->{nodename};

    my $payload = $self->jsonrpc_method_create("identify", {
        "module" => $nodename,
        "netgroup" => "test"
    });

    $logger->debug('-> Identifying ' . $nodename);

    $logger->fatal('Nodename, Secret not defined on Identification Stage') if ( ! defined_args($nodename) );

    $heap->{stage} = 'SYN';     
    $heap->{server}->put(encode_json($payload));
}

################ END AUTHENTICATE ##################

################ KEEP ALIVE ###################
sub send_ping {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $self = shift;

    return if $heap->{shutdown};

    # Verify Established Connection
    return if ( $heap->{stage} ne 'EST' );

    $logger->debug('    -> Sending PING..');

    my $ping_sent = time();

    my $payload = $self->jsonrpc_method_create("ping", {
        "timestamp" => $ping_sent
    });

    $heap->{server}->put(encode_json($payload));
    $heap->{ping_sent} = $ping_sent;
}

sub send_pong {
    my ($kernel, $heap, $response) = @_[KERNEL, HEAP, ARG0];

    # Verify Established Connection
    return if ( $heap->{stage} ne 'EST' );

    my $ping_time = time();
    $heap->{server}->put("PONG " .$ping_time. " NSMF/1.0\r\n");
    $logger->debug('    -> Sending PONG..');
    $heap->{ping_sent} = $ping_time;
}

sub got_ping {
    my ($kernel, $heap, $response) = @_[KERNEL, HEAP, ARG0];

    # Verify Established Connection
    return if ( $heap->{stage} ne 'EST' );

    $logger->debug('    <- Got PING ');
    $heap->{ping_recv} = time();

    $kernel->yield('send_pong');
}

sub got_pong {
    my ($kernel, $heap, $response) = @_[KERNEL, HEAP, ARG0];

    # Verify Established Connection
    return if ( $heap->{stage} ne 'EST' );

    $heap->{pong_recv} = time();

    my $latency = $heap->{pong_recv} - $heap->{ping_sent};

    $logger->debug('    <- Got PONG ' . (($latency > 3) ? ( "Latency (" .$latency. "s)" ) : ""));

    $kernel->delay(send_ping => 60);
}

################ END KEEP ALIVE ###################

# PRIVATE TODO

sub jsonrpc_method_create
{
    my ($self, $method, $params) = @_;

    my $id = int(rand(65536));

    while ( defined($self->{json_method_map}->{$id}) )
    {
        $id = int(rand(65536));
    }

    $self->{json_method_map}->{$id} = $method;

    return {
        "jsonrpc" => "2.0",
        "method" => $method,
        "params" => $params // '',
        "id" => $id
    };
}

sub jsonrpc_result_method
{
    my ($self, $json) = @_;

    if ( ! defined_args($json->{id}) &&
         ! defined_args($json->{method}) )
    {
        return "";
    }

    my $method = "";

    if ( defined($self->{json_method_map}->{$json->{id}}) )
    {
        $method = $self->{json_method_map}->{$json->{id}};
        delete($self->{json_method__map}->{$json->{id}});
    }
    elsif ( defined($json->{method}) )
    {
        $method = $json->{method};
    }

    return $method;
}

1;