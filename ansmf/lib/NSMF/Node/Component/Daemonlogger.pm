package NSMF::Node::Daemonlogger;

use strict;
use v5.10;

# NSMF::Node Subclass
use base qw(NSMF::Node);

# NSMF Imports
use NSMF;
use NSMF::Net;
use NSMF::Common::Util;

# POE Imports
use POE;

# Misc
use Data::Dumper;
our $VERSION = '0.1';

# These are POE elements that help us interact with the POE Kernel and Heap storage
#my ($kernel, $heap);

sub new {
    my $class = shift;
    my $node = $class->SUPER::new;
    $node->{__data} = {};

    return $node;
}

# Here is your main()
sub run {
    my ($self, $kernel, $heap) = @_;

    # This provides the necessary data to the Node module for use of the put method
    $self->register($kernel, $heap);

    # At this point the Node is already authenticated so we can begin our work
    print_status("Running Daemonlogger processing..");

    # Hello world!
    $self->hello();

    #
    $pcapdir = $self->{__settings}->{pcapdir};

    # PUT is our send method, reuses the $heap->{server}->put that we provided to the super class with the $self->register method
    #print_status("Sending a custom ping!");
    #$self->put("PING " .time(). " NSMF/1.0");

    # We should start a "loop" that look for requests from the
    # nsmf-server requesting that we carve out sessions from pcap files
    # if we do, we should execute something like:
    #  /usr/sbin/tcpdump -r /nsm_data/*hostname*/dailylogs/2011-03-13/pcap.1299974402
    #   -w /nsm_data/tmp/213.166.161.154:48103_209.85.149.139:80-6.raw 
    #    host 209.85.149.139 and host 213.166.161.154 and port 80 and port 48103 and proto 6
    #
    # First off, we need to identify the start date too search from and the stop date...
    # Then we would would search for the first pcap file based on `stat` output of the
    # available pcap files in the date dir.. say: .../dailylogs/2011-03-13/pcap.*
    # that would contain the start of the session that we are looking for.
    # If we have to span a range of dates, say 2011-03-13 14 and 15, we would search
    # all relevant pcap files in 2011-03-13, then all pcaps in 2011-03-14 and then
    # again only the relevant pcaps in 2011-03-15.
    # Example (last modified time):
    # $ stat /nsm_data/*hostname*/dailylogs/2011-03-04/*
    # ...
    # Modify: 2011-03-04 10:00:38.541205494 +0000
    # ...
    # Modify: 2011-03-04 13:08:28.777725132 +0000
    # ...
    # Modify: 2011-03-04 14:58:04.229224910 +0000
    # ...
    # Modify: 2011-03-04 21:10:34.469205846 +0000
    # ...
    #
    # So, if one would look for a session that took place at 15:45 and lasted for 1 minute,
    # one would just parse the pcap file that had timestamp "2011-03-04 14:58:04" (as it
    # holds all pcap data until the next file at created at "2011-03-04 21:10:34".
    #
    # Next, if one would look for a sesison that started at 12:58 and ended at 18:22,
    # one would parse the pcap files with timestamp "2011-03-04 10:00:38" (it holds
    # the start of the session), then "2011-03-04 13:08:28" (it holds data from the
    # middle of the the session), and finaly "2011-03-04 14:58:04" as it would
    # hold the last data up ontil the end of the session.
    # If we where to go from one day to the next, we would do the same, just in
    # the dir for the next day.

}

sub  hello {
    print_status "Hello World from Daemonlogger Node!";
}
1;
