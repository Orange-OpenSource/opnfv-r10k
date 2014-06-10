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
class opensteak::neutron {
  # Recupere le password pour les services
  $password = hiera('mysql-service-password')

  # Recupere l'adresse ip de management
  $management_address = hiera('ip-management')
  
  ::sysctl::value { 'net.ipv4.ip_forward': 
    value     => '1',
  }

  ::sysctl::value { 'net.ipv4.conf.all.rp_filter': 
    value     => '0',
  }

  ::sysctl::value { 'net.ipv4.conf.default.rp_filter': 
    value     => '0',
  }


  class { '::neutron::plugins::ml2':
    type_drivers          => ['vlan','flat'],
    flat_networks         => ['physnet1'],
    tenant_network_types  => ['vlan'],
    network_vlan_ranges   => ['physnet2:701:899'],
    enable_security_group => true,
    firewall_driver       => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
    require               => Package['neutron-plugin-openvswitch', 'neutron-plugin-linuxbridge'],
  }

  # Ajout config ovs
  class { '::neutron::config':
    plugin_ml2_config =>
    {
      'ovs/enable_tunneling'    => { value  => 'False' },
      'ovs/integration_bridge'  => { value  => 'br-int' },
      'ovs/bridge_mappings'     => { value  => 'physnet1:br-ex,physnet2:br-vm' },
    }
  }

  package { 'neutron-plugin-openvswitch':
    ensure  => present,
  }

  package { 'neutron-plugin-linuxbridge':
    ensure  => present,
  }

  class { '::neutron':
    enabled               => true,
    bind_host             => hiera('ip-management'),
    rabbit_host           => hiera('ip-management'),
    core_plugin           => 'ml2',
    service_plugins       => ['router','vpnaas','firewall'],
    allow_overlapping_ips => true,
    rabbit_user           => 'rabbit',
    rabbit_password       => hiera('rabbitmq-password'),
    debug                 => hiera('debug'),
    verbose               => hiera('verbose'),
  }

  class { '::neutron::keystone::auth':
    password         => hiera('neutron-password'),
    public_address   => hiera('ip-management'),
    admin_address    => hiera('ip-management'),
    internal_address => hiera('ip-management'),
    region           => hiera('region'),
  }

  class { '::neutron::server':
    auth_host           => hiera('ip-management'),
    auth_password       => hiera('neutron-password'),
    database_connection => "mysql://neutron:${password}@${management_address}/neutron",
    enabled             => true,
    sync_db             => true,
    mysql_module        => '2.2',
  }

  class { '::neutron::server::notifications':
    nova_url            => "http://${management_address}:8774/v2",
    nova_admin_auth_url => "http://${management_address}:35357/v2.0",
    nova_admin_password => hiera('nova-password'),
    nova_region_name    => hiera('region'),
  }

  # Initialise la BDD
  class { '::neutron::db::mysql':
    password      => hiera('mysql-service-password'),
    allowed_hosts => hiera('mysql-allowed-hosts'),
    mysql_module  => '2.2',
  }

  class { '::neutron::agents::ovs': 
    bridge_mappings   => ['physnet1:br-ex', 'physnet2:br-vm'],
    bridge_uplinks    => ['br-ex:em2', 'br-vm:em5'],
  }

  class { '::neutron::agents::dhcp':
    debug   => hiera('debug'),
  }

  # Uncomment if VPN agent not used
  # See https://bugs.launchpad.net/ubuntu/+source/neutron/+bug/1303876
#  class { '::neutron::agents::l3': 
#    debug   => hiera('debug'),
#  }

  # Ajoute le VPNaaS
  class { '::neutron::agents::vpnaas': }

  # Ajoute le FWaaS
  class { '::neutron::services::fwaas': 
    vpnaas_agent_package => true,
  }

  class { '::neutron::agents::metadata':
    auth_password => hiera('neutron-password'),
    shared_secret => hiera('neutron-shared-secret'),
    auth_url      => "http://${management_address}:35357/v2.0",
    debug         => hiera('debug'),
    auth_region   => hiera('region'),
    metadata_ip   => hiera('ip-management'),
  }
}
