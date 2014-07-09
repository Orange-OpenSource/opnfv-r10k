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
# node
#
node 'opensteak96.opensteak.fr' {
  Exec { path => '/usr/bin:/usr/sbin:/bin:/sbin' }
  class { '::ntp': }
  class { '::opensteak::rabbitmq': }    ->
  class { '::opensteak::mysql': }       ->
  class { '::opensteak::keystone': }    ->
  class { '::opensteak::glance': }      ->
  class { '::opensteak::cinder': }      ->
  class { '::opensteak::nova': }        ->
  class { '::opensteak::neutron': }     ->
  class { '::opensteak::horizon': }     ->
  class { '::opensteak::firewall': }    ->
  class { '::opensteak::mongodb': }     ->
  class { '::opensteak::ceilometer': }
}
