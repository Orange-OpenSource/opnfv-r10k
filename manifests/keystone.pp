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
# The profile to install the Keystone service
#
class opensteak::keystone {
  # Recupere le password pour les services
  $password = hiera('mysql-service-password')

  # Recupere l'adresse ip de management
  $management_address = hiera('ip-management')

  # Initialise la BDD
  class { '::keystone::db::mysql':
    password      => hiera('mysql-service-password'),
    allowed_hosts => hiera('mysql-allowed-hosts'),
    mysql_module  => '2.2',
  }

  class { '::keystone':
    verbose           => hiera('verbose'),
    debug             => hiera('debug'),
    admin_token       => hiera('keystone-admin-token'),
    sql_connection    => "mysql://keystone:${password}@${management_address}/keystone",
    mysql_module      => '2.2',
    public_bind_host  => hiera('ip-management'),
    admin_bind_host   => hiera('ip-management'),
  }

  class { '::keystone::roles::admin':
    email        => hiera('keystone-admin-mail'),
    password     => hiera('keystone-admin-password'),
    admin_tenant => 'admin',
  }

  class { 'keystone::endpoint':
    public_address   => hiera('ip-management'),
    admin_address    => hiera('ip-management'),
    internal_address => hiera('ip-management'),
    region           => hiera('region'),
  }
}
