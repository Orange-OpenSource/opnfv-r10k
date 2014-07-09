#
# Copyright (C) 2014 Orange Labs
# 
# This software is distributed under the terms and conditions of the 'Apache-2.0'
# license which can be found in the file 'LICENSE.txt' in this package distribution 
# or at 'http://www.apache.org/licenses/LICENSE-2.0'. 
#
# Authors: Arnaud Morin <arnaud1.morin@orange.com> 
#

#
# The profile to install the telemetry service agent on compute node
#
class opensteak::ceilometer-compute {  
  # Recupere l'adresse ip de management
  $management_address = hiera('ip-management')
    
  class { '::ceilometer':
    metering_secret => hiera('ceilometer-metering-secret'),
    debug           => hiera('debug'),
    verbose         => hiera('verbose'),
    rabbit_hosts    => [$management_address],
    rabbit_userid   => 'rabbit',
    rabbit_password => hiera('rabbitmq-password'),
  }
  
  class { '::ceilometer::db':
    database_connection => "mongodb://${management_address}:27017/ceilometer",
    mysql_module        => '2.2',
  }
  
  class { '::ceilometer::agent::auth':
    auth_url      => "http://${management_address}:5000/v2.0",
    auth_password => hiera('ceilometer-password'),
    auth_region   => hiera('region'),
  }
  -> class { '::ceilometer::agent::compute': }
}
