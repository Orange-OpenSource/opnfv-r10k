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
# The profile to install the Glance API and Registry services
#
class opensteak::glance {
  # Recupere le password pour les services
  $password = hiera('mysql-service-password')

  # Recupere l'adresse ip de management
  $management_address = hiera('ip-management')

  class { '::glance::api':
    keystone_password => hiera('glance-password'),
    auth_host         => hiera('ip-management'),
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    bind_host         => hiera('ip-management'),
    sql_connection    => "mysql://glance:${password}@${management_address}/glance",
    registry_host     => hiera('ip-management'),
    verbose           => hiera('verbose'),
    debug             => hiera('debug'),
    mysql_module      => '2.2',
  }

  class { '::glance::backend::file': 
    filesystem_store_datadir => hiera('glance-file-store-dir'),
  }

  class { '::glance::registry':
    keystone_password => hiera('glance-password'),
    sql_connection    => "mysql://glance:${password}@${management_address}/glance",
    auth_host         => hiera('ip-management'),
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    bind_host         => hiera('ip-management'),
    verbose           => hiera('verbose'),
    debug             => hiera('debug'),
    mysql_module      => '2.2',
  }

  class { '::glance::notify::rabbitmq': 
    rabbit_password => hiera('rabbitmq-password'),
    rabbit_userid   => 'rabbit',
    rabbit_host     => hiera('ip-management'),
  }

  # Initialise la BDD
  class { '::glance::db::mysql':
    password      => hiera('mysql-service-password'),
    allowed_hosts => hiera('mysql-allowed-hosts'),
    mysql_module  => '2.2',
  }

  class { '::glance::keystone::auth':
    password         => hiera('glance-password'),
    public_address   => hiera('ip-management'),
    admin_address    => hiera('ip-management'),
    internal_address => hiera('ip-management'),
    region           => hiera('region'),
  }
}
