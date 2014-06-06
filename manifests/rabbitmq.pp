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
#  The profile to install rabbitmq
#
class opensteak::rabbitmq {
  $management_address = hiera('ip-management')
  $epmd_listen_ip = hiera('ip-management')
  $inet_dist_use_interface = regsubst($management_address,'\.',',','G')

  class { '::rabbitmq':
    admin_enable            => false,
    delete_guest_user       => true,
    service_ensure          => 'running',
    port                    => '5672',
    config_cluster          => false,
    environment_variables   => {
      'RABBITMQ_NODE_IP_ADDRESS'  => hiera('ip-management'),
      'ERL_EPMD_ADDRESS'          => hiera('ip-management'),
    },
    config_kernel_variables => {
      'inet_dist_use_interface' => "{${inet_dist_use_interface}}",
    },
  }

  rabbitmq_user { 'rabbit':
    admin     => true,
    password  => hiera('rabbitmq-password'),
    provider  => 'rabbitmqctl',
    require   => Class['::rabbitmq'],
  }

  rabbitmq_user_permissions { 'rabbit@/':
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
  }

  rabbitmq_vhost { '/':
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }

  file { '/etc/init.d/rabbitmq-server':
    content => template("opensteak/rabbitmq-server.erb"),
    notify  => Service['rabbitmq-server'],
  }
}
