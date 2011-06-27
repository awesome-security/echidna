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
package NSMF::Server::ConfigMngr;
    
use warnings;
use strict;
use v5.10;

#
# PERL INCLUDES
#
use Carp;
use YAML::Tiny;

#
# GLOBALS
#
our $debug;
my $instance;
my ($server, $settings);

sub instance {
    if ( ! defined($instance) ) {
        $instance = bless {
            config  => {},
        }, __PACKAGE__;
    }

    return $instance;
}

sub load {
    my ($self, $file) = @_;

    return if ( ref($self) ne __PACKAGE__ );

    __PACKAGE__->instance();

    my $yaml = YAML::Tiny->read($file);

    croak 'Could not parse configuration file.' unless $yaml;

    my $pages = @{ $yaml };

    croak 'No configuration pages available' if ( $pages == 0 );

    carp('Multiple configuration pages found. Using the first') if ( $pages > 1 );

    $self->{config}   = $yaml->[0];

    # configure defaults
    $self->{config}{name}                   //= 'NSMF Server';
    $self->{config}{network}{host}          //= 'localhost';
    $self->{config}{network}{port}          //= 10101;

    $self->{config}{log}{level}             //= 'info';
    $self->{config}{log}{timestamp}         //= 0;
    $self->{config}{log}{timestamp_format}  //= '%Y-%m-%d %H:%M:%S';
    $self->{config}{log}{warn_is_fatal}     //= 0;
    $self->{config}{log}{error_is_fatal}    //= 0;
    
    $self->{config}{protocol}               //= 'json';


    $self->{config}{modules}                //= [];
    map { $_ = lc $_ } @{ $self->{config}{modules} };

    $instance = $self;

    return $instance;
}

sub name {
    return $instance->{config}{name} // 'NSMFServer';
}

sub host {
    return $instance->{config}{network}{host} // croak '[!] No server defined.';
}

sub port {
    return $instance->{config}{network}{port} // croak '[!] No port defined.';
}

sub modules {
    my $self = shift;
    return if ( ref($self) ne __PACKAGE__ );

    return $instance->{config}{modules};
}

sub database {
    my $self = shift;
    return if ( ref($self) ne __PACKAGE__ );

    return $instance->{config}{database};
}

sub protocol {
    my $self = shift;
    return if ( ref($self) ne __PACKAGE__ );

    return $instance->{config}{protocol};
}

sub logging {
    my $self = shift;
    return if ( ref($self) ne __PACKAGE__ );

    return $instance->{config}{log};
}

1;
