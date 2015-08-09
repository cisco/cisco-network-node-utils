# Platform provider class
#
# Alex Hunsberger, Mar 2015
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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

require File.join(File.dirname(__FILE__), 'node')

class Platform
  @@node = Cisco::Node.instance

  # ex: 'n3500-uk9.6.0.2.A3.0.40.bin'
  def Platform.system_image
    @@node.config_get("show_version", "boot_image")
  end

  # returns package hash with state values
  # ex: { 'n3000-uk9.6.0.2.U1.1.CSCaa12345.bin' => 'inactive committed',
  #       'n3000-uk9.6.0.2.U1.1.CSCaa12346.bin' => 'active', }
  def Platform.packages
    pkgs = @@node.config_get("images", "packages")
    return {} if pkgs.nil?
    pkg_hsh = {}
    pkgs.each { |p|
      pkg_hsh[p[0]] = p[1].downcase
    }
    pkg_hsh
  end

  # ex: 'Cisco Nexus3064 Chassis ("48x10GE + 16x10G/4x40G Supervisor")'
  def Platform.hardware_type
    @@node.config_get("show_version", "description")
  end

  # ex: 'Intel(R) Celeron(R) CPU P450'
  def Platform.cpu
    @@node.config_get("show_version", "cpu")
  end

  # return hash with keys "total", "used", "free"
  # ex: { 'total' => '16402252K',
  #       'used'  => '5909004K',
  #       'free'  => '10493248K' }
  def Platform.memory
    total = @@node.config_get("memory", "total")
    used = @@node.config_get("memory", "used")
    free = @@node.config_get("memory", "free")

    raise "failed to retrieve platform memory information" if
      total.nil? or used.nil? or free.nil?

    { 'total' => total.first,
      'used'  => used.first,
      'free'  => free.first, }
  end

  # ex: 'Processor Board ID FOC15430TEY'
  def Platform.board
    @@node.config_get("show_version", "board")
  end

  # ex: '1 day(s), 21 hour(s), 46 minute(s), 54 second(s)'
  def Platform.uptime
    u = @@node.config_get("show_version", "uptime")
    raise "failed to retrieve platform uptime" if u.nil?
    u.first
  end

  # ex: '23113 usecs after  Mon Jul  1 15:24:29 2013'
  def Platform.last_reset
    r = @@node.config_get("show_version", "last_reset_time")
    r.nil? ? nil : r.strip
  end

  # ex: 'Reset Requested by CLI command reload'
  def Platform.reset_reason
    @@node.config_get("show_version", "last_reset_reason")
  end

  # returns chassis hash with keys "descr", "pid", "vid", "sn"
  # ex: { 'descr' => 'Nexus9000 C9396PX Chassis',
  #       'pid'   => 'N9K-C9396PX',
  #       'vid'   => 'V02',
  #       'sn'    => 'SAL1812NTBP' }
  def Platform.chassis
    chas = @@node.config_get("inventory", "chassis")
    return nil if chas.nil?
    { 'descr' => chas['desc'].tr('"', ''),
      'pid'   => chas['productid'],
      'vid'   => chas['vendorid'],
      'sn'    => chas['serialnum'], }
  end

  # returns hash of hashes with inner keys "name", "descr", "pid", "vid", "sn"
  # ex: { 'Slot 1' => { 'descr' => '1/10G SFP+ Ethernet Module',
  #                     'pid'   => 'N9K-C9396PX',
  #                     'vid'   => 'V02',
  #                     'sn'    => 'SAL1812NTBP' },
  #       'Slot 2' => { ... }}
  def Platform.inventory_of(type)
    @@node.cache_flush # TODO: investigate why this is needed
    inv = @@node.config_get("inventory", "all")
    return {} if inv.nil?
    inv.select! { |x| x['name'].include? type }
    return {} if inv.empty?
    # match desired output format
    inv_hsh = {}
    inv.each { |s|
      inv_hsh[s['name'].tr('"', '')] = { 'descr' => s['desc'].tr('"', ''),
                                         'pid'   => s['productid'],
                                         'vid'   => s['vendorid'],
                                         'sn'    => s['serialnum'] }
    }
    inv_hsh
  end

  # returns array of hashes with keys "name", "descr", "pid", "vid", "sn"
  def Platform.slots
    Platform.inventory_of('Slot')
  end

  # returns array of hashes with keys "name", "descr", "pid", "vid", "sn"
  def Platform.power_supplies
    Platform.inventory_of('Power Supply')
  end

  # returns array of hashes with keys "name", "descr", "pid", "vid", "sn"
  def Platform.fans
    Platform.inventory_of('Fan')
  end

  # returns hash of hashes with inner keys "state", "application", ...
  # ex: { 'chef' => {
  #        'package_info' => { 'name'     => 'n3k_chanm_chef.ova',
  #                            'path'     => 'bootflash:/n3k_chanm_chef.ova' },
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
  def Platform.virtual_services
    virts = @@node.config_get("virtual_service", "services")
    return [] if virts.nil?
    # NXAPI returns hash instead of array if there's only 1
    virts = [virts] if virts.is_a? Hash
    # convert to expected format
    virts_hsh = {}
    virts.each { |serv|
      virts_hsh[serv['name']] = {
        'package_info' => { 'name'     => serv['package_name'],
                            'path'     => serv['ova_path'], },
        'application'  => { 'name'     => serv['application_name'],
                            'version'  => serv['application_version'],
                            'descr'    => serv['application_description'], },
        'signing'      => { 'key_type' => serv['key_type'],
                            'method'   => serv['signing_method'], },
        'licensing'    => { 'name'     => serv['licensing_name'],
                            'version'  => serv['licensing_version'], },
        'reservation'  => { 'disk'     => serv['disk_reservation'],
                            'memory'   => serv['memory_reservation'],
                            'cpu'      => serv['cpu_reservation'], },
      }
    }
    virts_hsh
  end
end
