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
package NSMF::Server::Model::Agent;

use warnings;
use strict;
use v5.10;

use base qw(Data::ObjectDriver::BaseObject);

#
# NSMF INCLUDES
#
use NSMF::Server::Driver;

__PACKAGE__->install_properties({
    columns => [
        'agent_id', 
        'agent_name', 
        'agent_password',
        'agent_description',
        'agent_ip',
        'agent_active',
        'agent_network',
    ],
    datasource => 'nsmf_agent',
    primary_key => 'agent_id',
    driver => NSMF::Server::Driver->driver(),
});

1;
