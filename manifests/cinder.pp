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
# The profile to install the volume service
#
class opensteak::cinder {
  # Recupere le password pour les services
  $password = hiera('mysql-service-password')
  
  # Recupere l'adresse ip de management
  $management_address = hiera('ip-management')

  # Recupere l'adresse ip pour tgt (iscsi target daemon)
  $tgt_listen_ip = hiera('ip-management')

  class { '::cinder':
    sql_connection    => "mysql://cinder:${password}@${management_address}/cinder",
    rabbit_host       => hiera('ip-management'),
    rabbit_userid     => 'rabbit',
    rabbit_password   => hiera('rabbitmq-password'),
    debug             => hiera('debug'),
    verbose           => hiera('verbose'),
    mysql_module      => '2.2',
  }

  class { '::cinder::volume': }

  class { '::cinder::volume::iscsi':
    iscsi_ip_address  => hiera('ip-management'),
    volume_group      => hiera('cinder-vg-name'),
  }

  class { '::cinder::glance':
    glance_api_servers  => "${management_address}:9292",
    glance_api_version  => '1',
  }

  # Initialise la BDD
  class { '::cinder::db::mysql':
    password      => hiera('mysql-service-password'),
    allowed_hosts => hiera('mysql-allowed-hosts'),
    mysql_module  => '2.2',
  }

  class { '::cinder::keystone::auth':
    password         => hiera('cinder-password'),
    public_address   => hiera('ip-management'),
    admin_address    => hiera('ip-management'),
    internal_address => hiera('ip-management'),
    region           => hiera('region'),
  }

  class { '::cinder::api':
    keystone_password   => hiera('cinder-password'),
    keystone_auth_host  => hiera('ip-management'),
    enabled             => true,
    bind_host           => hiera('ip-management'),
  }

  class { '::cinder::scheduler':
    scheduler_driver => 'cinder.scheduler.filter_scheduler.FilterScheduler',
    enabled          => true,
  }

  # On a besoin de sheepdog
  # voir ici : https://lists.launchpad.net/openstack/msg21163.html
  package { 'sheepdog':
    ensure => 'present',
  }

  # Mise a jour du fichier init de tgt
  file { '/etc/init/tgt.conf':
    content => template("opensteak/tgt.conf.erb"),
    notify  => Service['tgt'],
  }
}
