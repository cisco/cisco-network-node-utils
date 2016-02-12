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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/platform'

# TestPlatform - Minitest for Platform class
class TestPlatform < CiscoTestCase
  def test_system_image
    s = @device.cmd('show version | i image').scan(/ (\S+)$/).flatten.first
    assert_equal(s, Platform.system_image)
  end

  def test_packages
    # [['pack1', 'state1'], ['pack2', 'state2'], ...]
    # 'state' should always be a variant of Active or Inactive
    pkgs = @device.cmd('sh inst patch | no-more')
           .scan(/\n(\S+)\s+(\S*[aA]ctive.*)\n/)
    # convert to hash with key pkg_name and value pkg_state
    pkg_hsh = {}
    pkgs.each { |p| pkg_hsh[p[0]] = p[1].downcase }
    assert_equal(pkg_hsh, Platform.packages)
  end

  def test_hardware_type
    s = @device.cmd('sh ver | no-m').scan(/Hardware\n\s+(.*)\n/).flatten.first
    # hardware type returns a different value depending on whether you use the
    # ascii or show output of nxapi, but show appears to be substring of ascii
    assert(s.include?(Platform.hardware_type),
           "Expected '#{s}' to contain '#{Platform.hardware_type}'")
  end

  def test_cpu
    s = @device.cmd('sh ver | no-m').scan(
      /Hardware\n\s+.*\n\s+(.*) with/).flatten.first
    assert_equal(s, Platform.cpu)
  end

  def test_memory
    arr = @device.cmd('sh sys reso').scan(
      /(\S+) total.* (\S+) used.* (\S+) free/).flatten
    mem_hsh = { 'total' => arr[0],
                'used'  => arr[1],
                'free'  => arr[2] }
    # used and free memory change rapidly, compare total and sums of free + used
    assert_equal(mem_hsh['total'], Platform.memory['total'])
    assert_equal(mem_hsh['used'].to_i + mem_hsh['free'].to_i,
                 Platform.memory['used'].to_i + Platform.memory['free'].to_i)
    # assert(Platform.memory.has_key?('used'),
    #        "Platform memory has no key 'used'")
    # assert(Platform.memory.has_key?('free'),
    #        "Platform memory has no key 'free'")
  end

  def test_board
    s = @device.cmd('sh ver | no-m').scan(/Board ID (\S+)/).flatten.first
    assert_equal(s, Platform.board)
  end

  def test_uptime
    s = @device.cmd('sh ver | no-m').scan(/uptime is (.*)/).flatten.first
    # compare without seconds
    assert_equal(s.gsub(/\d+ sec/, ''), Platform.uptime.gsub(/\d+ sec/, ''))
  end

  def test_last_reset
    s = @device.cmd('sh ver | no-m').scan(/usecs after\s+(.*)/).flatten.first
    assert_equal(s, Platform.last_reset)
  end

  def test_reset_reason
    s = @device.cmd('sh ver | no-m').scan(/Reason: (.*)/).flatten.first
    assert_equal(s, Platform.reset_reason)
  end

  # switch#show inventory
  # NAME: "Chassis",  DESCR: "Nexus9000 C9396PX Chassis"
  # PID: N9K-C9396PX         ,  VID: V02 ,  SN: xxxxxxxxxxx
  #
  # NAME: "Slot 1",  DESCR: "1/10G SFP+ Ethernet Module"
  # PID: N9K-C9396PX         ,  VID: V02 ,  SN: xxxxxxxxxxx
  #
  # NAME: "Slot 2",  DESCR: "40G Ethernet Expansion Module"
  # PID: N9K-M12PQ           ,  VID: V01 ,  SN: xxxxxxxxxxx
  # (...)
  # NAME: "Power Supply 1",  DESCR: "Nexus9000 C9396PX Chassis Power Supply"
  # PID: N9K-PAC-650W        ,  VID: V01 ,  SN: xxxxxxxxxxx
  # (...)
  # NAME: "Fan 1",  DESCR: "Nexus9000 C9396PX Chassis Fan Module"
  # PID: N9K-C9300-FAN2      ,  VID: V01 ,  SN: N/A
  #
  # Everything from DESCR onwards follows the same general format so we
  # can define a single base regexp and extend it as needed for Chassis, Slot,
  # Power Supply, and Fan inventory entries.
  def inv_cmn_re
    /.*DESCR:\s+"(.*)"\s*\nPID:\s+(\S+).*VID:\s+(\S+).*SN:\s+(\S+)/
  end

  def test_chassis
    arr = @device.cmd('sh inv | no-m').scan(/NAME:\s+"Chassis"#{inv_cmn_re}/)
    arr = arr.flatten
    # convert to hash
    chas_hsh = { 'descr' => arr[0],
                 'pid'   => arr[1],
                 'vid'   => arr[2],
                 'sn'    => arr[3],
    }
    assert_equal(chas_hsh, Platform.chassis)
  end

  def test_slots
    slots_arr_arr = @device.cmd('sh inv | no-m')
                    .scan(/NAME:\s+"(Slot \d+)"#{inv_cmn_re}/)
    # convert to array of slot hashes
    slots_hsh_hsh = {}
    slots_arr_arr.each do |slot|
      slots_hsh_hsh[slot[0]] = { 'descr' => slot[1],
                                 'pid'   => slot[2],
                                 'vid'   => slot[3],
                                 'sn'    => slot[4],
      }
    end
    assert_equal(slots_hsh_hsh, Platform.slots)
  end

  def test_power_supplies
    pwr_arr_arr = @device.cmd('sh inv | no-m')
                  .scan(/NAME:\s+"(Power Supply \d+)"#{inv_cmn_re}/)
    refute_empty(pwr_arr_arr,
                 'Regex scan failed to match show inventory output')

    # convert to array of power supply hashes
    pwr_hsh_hsh = {}
    pwr_arr_arr.each do |pwr|
      pwr_hsh_hsh[pwr[0]] = { 'descr' => pwr[1],
                              'pid'   => pwr[2],
                              'vid'   => pwr[3],
                              'sn'    => pwr[4],
      }
    end
    assert_equal(pwr_hsh_hsh, Platform.power_supplies)
  end

  def test_fans
    fan_arr_arr = @device.cmd('sh inv | no-m')
                  .scan(/NAME:\s+"(Fan \d+)"#{inv_cmn_re}/)
    refute_empty(fan_arr_arr,
                 'Regex scan failed to match show inventory output')

    # convert to array of fan hashes
    fan_hsh_hsh = {}
    fan_arr_arr.each do |fan|
      fan_hsh_hsh[fan[0]] = { 'descr' => fan[1],
                              'pid'   => fan[2],
                              'vid'   => fan[3],
                              'sn'    => fan[4],
      }
    end
    assert_equal(fan_hsh_hsh, Platform.fans)
  end

  def test_virtual_services
    skip('Skip test: No virtual-services installed') unless
      @device.cmd('show virtual-service list')[/Name\s+Status\s+Package Name/]

    # this would be beyond ugly to parse from ascii, utilize config_get
    vir_arr = node.config_get('virtual_service', 'services')
    vir_arr = [vir_arr] if vir_arr.is_a? Hash
    # convert to expected format
    vir_hsh_hsh = {}
    unless vir_arr.nil?
      vir_arr.each do |serv|
        # rubocop:disable Style/AlignHash
        vir_hsh_hsh[serv['name']] = {
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
    end
    assert_equal(vir_hsh_hsh, Platform.virtual_services)
  end
end
