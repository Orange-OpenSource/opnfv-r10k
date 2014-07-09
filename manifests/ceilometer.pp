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
# The profile to install the telemetry service
#
class opensteak::ceilometer {
  # Recupere le password pour les services
  $password = hiera('mysql-service-password')
  
  # Recupere l'adresse ip de management
  $management_address = hiera('ip-management')
  
  # Recupere le mot de passe mongo
  $mongo_password = hiera('ceilometer-mongo-password')

  class { '::ceilometer::keystone::auth':
    password         => hiera('ceilometer-password'),
    public_address   => hiera('ip-management'),
    admin_address    => hiera('ip-management'),
    internal_address => hiera('ip-management'),
    region           => hiera('region'),
  }
  
  class { '::ceilometer::agent::central':
  }
  
  class { '::ceilometer::expirer':
    time_to_live => '2592000'
  }
  
  class { '::ceilometer::alarm::notifier':
  }
  
  class { '::ceilometer::alarm::evaluator':
  }
  
  class { '::ceilometer::collector': 
  }
  
  class { '::ceilometer':
    metering_secret => hiera('ceilometer-metering-secret'),
    debug           => hiera('debug'),
    verbose         => hiera('verbose'),
    rabbit_hosts    => [$management_address],
    rabbit_userid   => 'rabbit',
    rabbit_password => hiera('rabbitmq-password'),
  }
  
  class { '::ceilometer::api':
    enabled           => true,
    keystone_host     => hiera('ip-management'),
    keystone_password => hiera('ceilometer-password'),
    host              => hiera('ip-management'),
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
  
  mongodb_database { 'ceilometer':
    ensure  => present,
    tries   => 20,
    require => Class['mongodb::server'],
  } 
  
  mongodb_user { 'ceilometer':
    ensure        => present,
    password_hash => mongodb_password('ceilometer', 'password'),
    database      => 'ceilometer',
    roles         => ['readWrite', 'dbAdmin'],
    tries         => 10,
    require       => [Class['mongodb::server'], Class['mongodb::client']],
  }
  
  Class['::mongodb::server'] -> Class['::mongodb::client'] -> Exec['ceilometer-dbsync']
}
