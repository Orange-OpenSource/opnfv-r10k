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
class opensteak::nova-compute {
  # Recupere l'adresse ip du controller
  # parfois utile dans certaines variables
  $ip_controller = hiera('ip-controller')

  class { '::nova':
    glance_api_servers => "http://${ip_controller}:9292",
    rabbit_hosts       => [$ip_controller],
    rabbit_userid      => 'rabbit',
    rabbit_password    => hiera('rabbitmq-password'),
    debug              => hiera('debug'),
    verbose            => hiera('verbose'),
    mysql_module       => '2.2',
  }

  class { '::nova::compute::neutron': }

  class { '::nova::network::neutron':
    neutron_admin_password => hiera('neutron-password'),
    neutron_region_name    => hiera('region'),
    neutron_admin_auth_url => "http://${ip_controller}:35357/v2.0",
    neutron_url            => "http://${ip_controller}:9696",
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
    enabled => false,
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
}
