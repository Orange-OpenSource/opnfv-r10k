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
# Firewall installation
#
class opensteak::firewall {
  
  class { '::firewall': }

  firewall { "0001 DROP tout traffic venant des VM":
    iniface  => hiera('if-public'),
    action => 'drop',
    src_range => hiera('ip-vm-range'),
  }
}
