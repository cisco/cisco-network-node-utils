# NTP Authentication key provider class
#
# Rick Sherman et al., April 2017
#
# Copyright (c) 2014-2017 Cisco and/or its affiliates.
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

require_relative 'node'

module Cisco
  # NtpAuthKey - node utility class for NTP authentication-key management
  class NtpAuthKey < NodeUtil
    attr_reader :algorithm, :mode, :password

    def initialize(opts, instantiate=true)
      @algorithm = opts['algorithm'].nil? ? 'md5' : opts['algorithm']
      @key = opts['name']
      @mode = opts['mode'].nil? ? '7' : opts['mode']
      @password = opts['password']

      create if instantiate
    end

    def self.ntpkeys
      keys = %w(name algorithm password mode)
      hash = {}
      ntp_auth_key_list = config_get('ntp_auth_key', 'key')
      return hash if ntp_auth_key_list.empty?

      ntp_auth_key_list.each do |id|
        hash[id[0]] = NtpAuthKey.new(Hash[keys.zip(id)], false)
      end

      hash
    end

    def ==(other)
      name == other.name
    end

    def create
      config_set('ntp_auth_key', 'key', state: '', key: @key,
                  algorithm: @algorithm, password: @password, mode: @mode)
    end

    def destroy
      # There appears to be a bug in NXOS that requires the password be passed
      config_set('ntp_auth_key', 'key', state: 'no', key: @key,
                  algorithm: @algorithm, password: @password, mode: @mode)
    end

    def name
      @key
    end
  end # class
end # module
