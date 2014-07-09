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
# MongoDB installation
#
class opensteak::mongodb {

  class { '::mongodb::server':
    bind_ip => ['127.0.0.1', hiera('ip-management')],
  }

  class { '::mongodb::client': }
}
