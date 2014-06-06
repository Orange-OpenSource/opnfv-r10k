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
# The profile to set up neutron
#
class opensteak::neutron-agent {

  # Recupere l'adresse ip de management
  $ip_controller = hiera('ip-controller')

  ::sysctl::value { 'net.ipv4.ip_forward':
    value     => '1',
  }

  ::sysctl::value { 'net.ipv4.conf.all.rp_filter':
    value     => '0',
  }

  ::sysctl::value { 'net.ipv4.conf.default.rp_filter':
    value     => '0',
  }

  class { '::neutron':
    rabbit_host           => hiera('ip-controller'),
    core_plugin           => 'ml2',
    service_plugins       => ['router'],
    allow_overlapping_ips => true,
    rabbit_user           => 'rabbit',
    rabbit_password       => hiera('rabbitmq-password'),
    debug                 => hiera('debug'),
    verbose               => hiera('verbose'),
  }

  class { '::neutron::plugins::ml2':
    type_drivers          => ['vlan'],
    tenant_network_types  => ['vlan'],
    network_vlan_ranges   => ['physnet2:701:899'],
    enable_security_group => true,
    firewall_driver       => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
    require               => Package['neutron-plugin-openvswitch', 'neutron-plugin-linuxbridge', 'neutron-plugin-ml2'],
  }

  # Ajout config
  class { '::neutron::config':
    # Ajout config keystone
    server_config =>
    {
      'keystone_authtoken/auth_uri'           => { value => "http://${ip_controller}:5000" }, 
      'keystone_authtoken/auth_host'          => { value => hiera('ip-controller') }, 
      'keystone_authtoken/auth_protocol'      => { value => 'http' },
      'keystone_authtoken/auth_port'          => { value => '35357' },
      'keystone_authtoken/admin_tenant_name'  => { value => 'services' },
      'keystone_authtoken/admin_user'         => { value => 'neutron' },
      'keystone_authtoken/admin_password'     => { value => hiera('neutron-password') },
    },
    # Ajout config ovs
    plugin_ml2_config =>
    {
      'ovs/enable_tunneling'    => { value  => 'False' },
      'ovs/integration_bridge'  => { value  => 'br-int' },
      'ovs/bridge_mappings'     => { value  => 'physnet2:br-vm' },
    },
  }


  package { 'neutron-plugin-ml2':
    ensure  => present,
  }

  package { 'neutron-plugin-openvswitch':
    ensure  => present,
  }

  package { 'neutron-plugin-linuxbridge':
    ensure  => present,
  }


  class { '::neutron::agents::ovs': 
    bridge_mappings   => ['physnet2:br-vm'],
    bridge_uplinks    => ['br-vm:em5'],
  }
}
