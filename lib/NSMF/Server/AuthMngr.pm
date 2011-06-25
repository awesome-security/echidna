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
package NSMF::Server::AuthMngr;

use warnings;
use strict;
use v5.10;

#
# PERL INCLUDES
#
use Carp;

#
# NSMF INCLUDES
#
use NSMF::Server::Model::Agent;

sub authenticate {
    my ($self, $agent_name, $key) = @_;
    
    my $agent = NSMF::Server::Model::Agent->search({
        agent_name => $agent_name,
    })->next;

    if ($agent and ref($agent) eq 'NSMF::Server::Model::Agent') {

        if ($agent->agent_password eq $key) {
            return 1;
        }
        else { 
            croak { status => 'error', message => 'Incorrect Password' };
        }
    } 
    else {
        croak {status => 'error', message => 'Agent Not Found'};
    }
}


1;
