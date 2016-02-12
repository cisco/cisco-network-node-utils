# Alex Hunsberger, Mar 2015
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

require_relative 'node_util'

module Cisco
  # Platform - class for gathering platform hardware and software information
  class Platform < NodeUtil
    # ex: 'n3500-uk9.6.0.2.A3.0.40.bin'
    def self.system_image
      config_get('show_version', 'boot_image')
    end

    # Returns package hash with state values
    # Ex: { 'n3000-uk9.6.0.2.U1.1.CSCaa12345.bin' => 'inactive committed',
    #       'n3000-uk9.6.0.2.U1.1.CSCaa12346.bin' => 'active', }
    def self.packages
      pkgs = config_get('images', 'packages')
      return {} if pkgs.nil?
      pkg_hsh = {}
      pkgs.each { |p| pkg_hsh[p[0]] = p[1].downcase }
      pkg_hsh
    end

    # Ex: 'Cisco Nexus3064 Chassis ("48x10GE + 16x10G/4x40G Supervisor")'
    def self.hardware_type
      config_get('show_version', 'description')
    end

    # Ex: 'Intel(R) Celeron(R) CPU P450'
    def self.cpu
      config_get('show_version', 'cpu')
    end

    # Return hash with keys "total", "used", "free"
    # Ex: { 'total' => '16402252K',
    #       'used'  => '5909004K',
    #       'free'  => '10493248K' }
    def self.memory
      total = config_get('memory', 'total')
      used = config_get('memory', 'used')
      free = config_get('memory', 'free')

      fail 'failed to retrieve platform memory information' if
        total.nil? || used.nil? || free.nil?

      {
        'total' => total,
        'used'  => used,
        'free'  => free,
      }
    end

    # Ex: 'Processor Board ID FOC15430TEY'
    def self.board
      config_get('show_version', 'board')
    end

    # Ex: '1 day(s), 21 hour(s), 46 minute(s), 54 second(s)'
    def self.uptime
      u = config_get('show_version', 'uptime')
      fail 'failed to retrieve platform uptime' if u.nil?
      u
    end

    # Ex: '23113 usecs after  Mon Jul  1 15:24:29 2013'
    def self.last_reset
      config_get('show_version', 'last_reset_time')
    end

    # Ex: 'Reset Requested by CLI command reload'
    def self.reset_reason
      config_get('show_version', 'last_reset_reason')
    end

    # Returns chassis hash with keys "descr", "pid", "vid", "sn"
    # Ex: { 'descr' => 'Nexus9000 C9396PX Chassis',
    #       'pid'   => 'N9K-C9396PX',
    #       'vid'   => 'V02',
    #       'sn'    => 'SAL1812NTBP' }
    def self.chassis
      node.cache_flush # TODO: investigate why this is needed
      chas = config_get('inventory', 'chassis')
      return nil if chas.nil?
      {
        'descr' => chas['desc'].tr('"', ''),
        'pid'   => chas['productid'],
        'vid'   => chas['vendorid'],
        'sn'    => chas['serialnum'],
      }
    end

    # Returns hash of hashes with inner keys "name", "descr", "pid", "vid", "sn"
    # Ex: { 'Slot 1' => { 'descr' => '1/10G SFP+ Ethernet Module',
    #                     'pid'   => 'N9K-C9396PX',
    #                     'vid'   => 'V02',
    #                     'sn'    => 'SAL1812NTBP' },
    #       'Slot 2' => { ... }}
    def self.inventory_of(type)
      node.cache_flush # TODO: investigate why this is needed
      inv = config_get('inventory', 'all')
      return {} if inv.nil?
      inv.select! { |x| x['name'].include? type }
      return {} if inv.empty?
      # match desired output format
      inv_hsh = {}
      inv.each do |s|
        inv_hsh[s['name'].tr('"', '')] = { 'descr' => s['desc'].tr('"', ''),
                                           'pid'   => s['productid'],
                                           'vid'   => s['vendorid'],
                                           'sn'    => s['serialnum'] }
      end
      inv_hsh
    end

    # Returns array of hashes with keys "name", "descr", "pid", "vid", "sn"
    def self.slots
      Platform.inventory_of('Slot')
    end

    # Returns array of hashes with keys "name", "descr", "pid", "vid", "sn"
    def self.power_supplies
      Platform.inventory_of('Power Supply')
    end

    # Returns array of hashes with keys "name", "descr", "pid", "vid", "sn"
    def self.fans
      Platform.inventory_of('Fan')
    end

    # Returns hash of hashes with inner keys "state", "application", ...
    # Ex: { 'chef' => {
    #        'package_info' => { 'name'     => 'n3k_chef.ova',
    #                            'path'     => 'bootflash:/n3k_chef.ova' },
    #        'application'  => { 'name'     => 'ChefAgent',
    #                            'version'  => '0.1',
    #                            'descr'    => 'Cisco Chef Agent' },
    #        'signing'      => { 'key_type' => 'Cisco development key',
    #                            'method'   => 'SHA-1' }
    #        'licensing'    => { 'name'     => 'none',
    #                            'version'  => 'none' }
    #        'reservation'  => { 'disk'     => '111 MB',
    #                            'memory'   => '0 MB',
    #                            'cpu'      => '0% system CPU' }},
    #      { ... }}
    def self.virtual_services
      virts = config_get('virtual_service', 'services')
      return [] if virts.nil?
      # NXAPI returns hash instead of array if there's only 1
      virts = [virts] if virts.is_a? Hash
      # convert to expected format
      virts_hsh = {}
      virts.each do |serv|
        # rubocop:disable Style/AlignHash
        virts_hsh[serv['name']] = {
          'package_info' => { 'name'     => serv['package_name'],
                              'path'     => serv['ova_path'],
          },
          'application'  => { 'name'     => serv['application_name'],
                              'version'  => serv['application_version'],
                              'descr'    => serv['application_description'],
          },
          'signing'      => { 'key_type' => serv['key_type'],
                              'method'   => serv['signing_method'],
          },
          'licensing'    => { 'name'     => serv['licensing_name'],
                              'version'  => serv['licensing_version'],
          },
          'reservation'  => { 'disk'     => serv['disk_reservation'],
                              'memory'   => serv['memory_reservation'],
                              'cpu'      => serv['cpu_reservation'],
          },
        }
        # rubocop:enable Style/AlignHash
      end
      virts_hsh
    end
  end
end
