# NTP Server provider class
#
# Jonathan Tripathy et al., September 2015
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
require_relative 'interface'
require 'resolv'

module Cisco
  # NtpServer - node utility class for NTP Server configuration management
  class NtpServer < NodeUtil
    attr_reader :key, :maxpoll, :minpoll, :prefer, :vrf

    def initialize(opts, instantiate=true)
      @ntpserver_id = opts['name']
      @key = opts['key']
      @minpoll = opts['minpoll']
      @maxpoll = opts['maxpoll']
      @prefer = opts['prefer'].nil? ? false : true
      @vrf = opts['vrf'].nil? ? 'default' : opts['vrf']

      hostname_regex = /^(?=.{1,255}$)[0-9A-Za-z]
      (?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?
      (?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$/x

      unless @ntpserver_id =~ Resolv::AddressRegex ||
             @ntpserver_id =~ hostname_regex
        fail ArgumentError,
             "Invalid value '#{@ntpserver_id}' \
        (Must be valid IPv4/IPv6 address or hostname)"
      end

      create if instantiate
    end

    def self.ntpservers
      keys = %w(name prefer vrf key minpoll maxpoll)
      hash = {}
      ntpservers_list = config_get('ntp_server', 'server')
      return hash if ntpservers_list.empty?

      ntpservers_list.each do |id|
        hash[id[0]] = NtpServer.new(Hash[keys.zip(id)], false)
      end

      hash
    end

    def ==(other)
      name == other.name && prefer == other.prefer
    end

    def create
      config_set('ntp_server', 'server', state: '', ip: @ntpserver_id,
                  prefer: (['true', true].include? @prefer) ? 'prefer' : '',
                  vrf: @vrf ? "use-vrf #{@vrf}" : '',
                  key: @key ? "key #{@key}" : '',
                  minpoll: @minpoll ? "minpoll #{@minpoll}" : '',
                  maxpoll: @maxpoll ? "maxpoll #{@maxpoll}" : '')
    end

    def destroy
      config_set('ntp_server', 'server',
                 state: 'no', ip: @ntpserver_id, prefer: '', vrf: '',
                 key: '', minpoll: '', maxpoll: '')
    end

    def name
      @ntpserver_id
    end
  end # class
end # module
