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
  def test_image_version
    case platform
    when :ios_xr
      refute_empty(Platform.image_version)

    when :nexus
      # Supported Images:
      # N3/9k: 7.0(3)I2(*), 7.0(3)I3(1)
      # N7k:   7.3(1)D1(1)
      # N5/6k: 7.3(0)N1(1)

      in_pat = '(^  NXOS: version |^  system:    version)'
      s = @device.cmd("show version | i '#{in_pat}'")

      out_pat = %r{/(\d\.\d\(\d\)[IDN])\d\(\d\)/}
      show = s.match(out_pat).to_s
      plat = Platform.image_version.match(out_pat).to_s
      assert_equal(show, plat)
    end
  end

  def test_system_image
    if platform == :ios_xr
      assert_nil(Platform.system_image)
    elsif platform == :nexus
      s = @device.cmd('show version | inc image | exc kickstart').scan(/ (\S+)$/).flatten.first
      assert_equal(s, Platform.system_image)
    end
  end

  def test_packages
    # [['pack1', 'state1'], ['pack2', 'state2'], ...]
    # 'state' should always be a variant of Active or Inactive
    pkgs = @device.cmd('sh inst patch')
           .scan(/\n(\S+)\s+(\S*[aA]ctive.*)/)
    # convert to hash with key pkg_name and value pkg_state
    pkg_hsh = {}
    pkgs.each { |p| pkg_hsh[p[0]] = p[1].downcase }
    assert_equal(pkg_hsh, Platform.packages)
  end

  def test_hardware_type
    if platform == :ios_xr
      s = @device.cmd('show inv | inc "Rack 0"').scan(/DESCR: "(.*)"/)
    elsif platform == :nexus
      s = @device.cmd('sh ver').scan(/Hardware\n\s+(.*)\n/)
    end
    s = s.flatten.first
    refute_empty(Platform.hardware_type)
    # hardware type returns a different value depending on whether you use the
    # ascii or show output of nxapi, but show appears to be substring of ascii
    assert(s.include?(Platform.hardware_type),
           "Expected '#{s}' to contain '#{Platform.hardware_type}'")
  end

  def test_cpu
    s = @device.cmd('sh ver').scan(
      /Hardware\n\s+.*\n\s+(.*) with/).flatten.first
    assert_equal(s, Platform.cpu)
  end

  def test_memory
    if platform == :ios_xr
      arr = @device.cmd('sh mem summ').scan(
        /Physical Memory: (\S+) total.*\((\S+) available/).flatten
      mem_hsh = { 'total' => arr[0],
                  'used'  => nil,
                  'free'  => arr[1] }
    elsif platform == :nexus
      arr = @device.cmd('sh sys reso').scan(
        /(\S+) total.* (\S+) used.* (\S+) free/).flatten
      mem_hsh = { 'total' => arr[0],
                  'used'  => arr[1],
                  'free'  => arr[2] }
    end
    assert_equal(mem_hsh['total'], Platform.memory['total'])
    if platform == :nexus
      # used and free mem change rapidly, compare total and sums of free + used
      assert_equal(mem_hsh['used'].to_i + mem_hsh['free'].to_i,
                   Platform.memory['used'].to_i + Platform.memory['free'].to_i)
    end
    assert(Platform.memory.key?('used'),
           "Platform memory has no key 'used'")
    assert(Platform.memory.key?('free'),
           "Platform memory has no key 'free'")
  end

  def test_board
    s = @device.cmd('sh ver').scan(/Board ID (\S+)/).flatten.first
    assert_equal(s, Platform.board)
  end

  def test_uptime
    s = @device.cmd('sh ver').scan(/uptime is (.*)/).flatten.first
    # compare without seconds
    assert_equal(s.gsub(/\d+ sec/, ''), Platform.uptime.gsub(/\d+ sec/, ''))
  end

  def test_reset_reason
    s = @device.cmd('sh ver').scan(/Reason: (.*)/).flatten.first
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
  #
  # On some platforms, some fields may be empty:
  # NAME: "Chassis",  DESCR: "NX-OSv Chassis"
  # PID: N9K-NXOSV           ,  VID:     ,  SN:
  def inv_cmn_re(name_expr)
    /NAME:\s+"#{name_expr}",\s+
     DESCR:\s+"(.*)"\s*
     \n
     PID:\s+(\S*)\s*,\s*
     VID:\s+(\S*)\s*,\s*
     SN:\s+(\S*)\s*
     $/x
  end

  def test_chassis
    arr = @device.cmd('sh inv').scan(inv_cmn_re('Chassis'))
    arr = arr.flatten
    # convert to hash
    chas_hsh = { 'descr' => arr[0],
                 'pid'   => arr[1],
                 'vid'   => arr[2],
                 'sn'    => arr[3],
    } unless arr.empty?
    assert_equal(chas_hsh, Platform.chassis)
  end

  def test_slots
    slots_arr_arr = @device.cmd('sh inv').scan(inv_cmn_re('(Slot\s+\d+)'))
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
    pwr_arr_arr = @device.cmd('sh inv')
                  .scan(inv_cmn_re('(Power\s+Supply\s+\d+)'))

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
    fan_arr_arr = @device.cmd('sh inv').scan(inv_cmn_re('(Fan\s+\d+)'))

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
    if validate_property_excluded?('virtual_service', 'services')
      assert_nil(node.config_get('virtual_service', 'services'))
      return
    end
    # Only run this test if a virtual-service is installed
    if config('show virtual-service global')[/services installed : 0$/]
      skip('This test requires a virtual-service to be installed')
    end
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
