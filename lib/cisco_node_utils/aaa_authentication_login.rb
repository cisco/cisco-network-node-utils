#
# NXAPI implementation of AaaAuthenticationLogin class
#
# April 2015, Alex Hunsberger
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative 'node_util'

module Cisco
  # NXAPI implementation of AAA Authentication Login class
  class AaaAuthenticationLogin < NodeUtil
    # rubocop:disable DoubleNegation
    # There is no "feature aaa" or "aaa new-model" on nxos, and only one
    # instance which is always available
    def self.ascii_authentication
      !!config_get('aaa_authentication_login', 'ascii_authentication')
    end

    def self.ascii_authentication=(val)
      no_cmd = val ? '' : 'no'
      config_set('aaa_authentication_login',
                 'ascii_authentication', no_cmd)
    end

    def self.default_ascii_authentication
      config_get_default('aaa_authentication_login',
                         'ascii_authentication')
    end

    def self.chap
      !!config_get('aaa_authentication_login', 'chap')
    end

    def self.chap=(val)
      no_cmd = val ? '' : 'no'
      config_set('aaa_authentication_login', 'chap', no_cmd)
    end

    def self.default_chap
      config_get_default('aaa_authentication_login', 'chap')
    end

    def self.error_display
      !!config_get('aaa_authentication_login', 'error_display')
    end

    def self.error_display=(val)
      no_cmd = val ? '' : 'no'
      config_set('aaa_authentication_login', 'error_display', no_cmd)
    end

    def self.default_error_display
      config_get_default('aaa_authentication_login', 'error_display')
    end

    def self.mschap
      !!config_get('aaa_authentication_login', 'mschap')
    end

    def self.mschap=(val)
      no_cmd = val ? '' : 'no'
      config_set('aaa_authentication_login', 'mschap', no_cmd)
    end

    def self.default_mschap
      config_get_default('aaa_authentication_login', 'mschap')
    end

    def self.mschapv2
      !!config_get('aaa_authentication_login', 'mschapv2')
    end

    def self.mschapv2=(val)
      no_cmd = val ? '' : 'no'
      config_set('aaa_authentication_login', 'mschapv2', no_cmd)
    end

    def self.default_mschapv2
      config_get_default('aaa_authentication_login', 'mschapv2')
    end
  end
end
