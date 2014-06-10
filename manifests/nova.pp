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
# The puppet module to set up a Nova Compute node
#
class opensteak::nova {
  # Recupere le password pour les services
  $password = hiera('mysql-service-password')

  # Recupere l'adresse ip de management
  $management_address = hiera('ip-management')

  class { '::nova':
    sql_connection     => "mysql://nova:${password}@${management_address}/nova",
    glance_api_servers => "http://${management_address}:9292",
    rabbit_hosts       => [$management_address],
    rabbit_userid      => 'rabbit',
    rabbit_password    => hiera('rabbitmq-password'),
    debug              => hiera('debug'),
    verbose            => hiera('verbose'),
    mysql_module       => '2.2',
  }

  class { '::nova::api':
    admin_password                        => hiera('nova-password'),
    api_bind_address                      => hiera('ip-management'),
    metadata_listen                       => hiera('ip-management'),
    auth_host                             => hiera('ip-management'),
    enabled                               => true,
    neutron_metadata_proxy_shared_secret  => hiera('neutron-shared-secret'),
  }

  class { [
    '::nova::scheduler',
    '::nova::cert',
    '::nova::consoleauth',
    '::nova::conductor',
  ]:
    enabled => true,
  }

  class { '::nova::objectstore':
    enabled       => true,
    bind_address  => hiera('ip-management'),
  }


  class { '::nova::compute::neutron': }

  class { '::nova::network::neutron':
    neutron_admin_password => hiera('neutron-password'),
    neutron_region_name    => hiera('region'),
    neutron_admin_auth_url => "http://${management_address}:35357/v2.0",
    neutron_url            => "http://${management_address}:9696",
  }

  class { '::nova::compute::libvirt': 
    vncserver_listen  => '0.0.0.0',
  }

  # Soit vncproxy (avec novnc)
  # Soit spiceproxy (avec spice-html5)

  # novnc
  # TODO : il y a un bug sur novnc :
  # https://ask.openstack.org/en/question/9850/console-instance-not-accepting-char/
  # https://github.com/kanaka/noVNC/issues/331
  # Corrige mais pas encore dispo sur ubuntu

  # Si novnc, ne pas oublier de passer vnc_enable a true
  class { '::nova::compute':
    enabled                       => true,
    vnc_enabled                   => true,
    vncserver_proxyclient_address => hiera('ip-management'),
    vncproxy_host                 => hiera('horizon-fqdn'),
    vnc_keymap                    => 'fr',
  }
  
  class { '::nova::vncproxy':
    enabled => true,
    host    => hiera('ip-public'),
  }

  package { 'nova-novncproxy':
    ensure  => present,
  }

  package { 'nova-spiceproxy':
    ensure  => absent,
  }

  # spice
  # Si novnc, ne pas oublier de passer vnc_enable a true
  #  class { '::nova::compute':
  #    enabled                       => true,
  #    vnc_enabled                   => false,
  #  }
  #
  #  class { '::nova::compute::spice':
  #    keymap                      => 'fr-fr',
  #    server_proxyclient_address  => hiera('ip-management'),
  #    server_listen               => hiera('ip-management'),
  #    proxy_host                  => hiera('horizon-fqdn'),
  #    proxy_protocol              => 'http',
  #    require                     => Package['nova-spiceproxy'],
  #  }
  #
  #  package { 'nova-novncproxy':
  #    ensure  => absent,
  #  }
  #  package { 'nova-spiceproxy':
  #    ensure  => present,
  #  }
  
  nova_config{
    'DEFAULT/my_ip': value => hiera('ip-management');
  }

  # Initialise la BDD
  class { '::nova::db::mysql':
    password      => hiera('mysql-service-password'),
    allowed_hosts => hiera('mysql-allowed-hosts'),
    mysql_module  => '2.2',
  }

  class { '::nova::keystone::auth':
    password         => hiera('nova-password'),
    public_address   => hiera('ip-management'),
    admin_address    => hiera('ip-management'),
    internal_address => hiera('ip-management'),
    region           => hiera('region'),
    cinder           => true,
  }
}
