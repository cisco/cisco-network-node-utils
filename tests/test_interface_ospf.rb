# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/cisco_cmn_utils", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/interface_ospf", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/router_ospf", __FILE__)

include Cisco

class TestInterfaceOspf < CiscoTestCase
  def routerospf_router_destroy(router)
    router.destroy
  end

  def routerospf_routers_destroy(routers)
    routers.each { |name, router|
      routerospf_router_destroy(router)
    }
  end

  def interface_switchport_enable(ifname, enable)
    @device.cmd("configure terminal")
    @device.cmd("interface #{ifname}")
    if enable == true
      @device.cmd("switchport")
    else
      @device.cmd("no switchport")
    end
    @device.cmd("end")
    node.cache_flush
  end

  def interfaceospf_interface_destroy(interface)
    interface.destroy
  end

  def interfaceospf_interfaces_destroy(interfaces)
    interfaces.each { |name, interface|
      interfaceospf_interface_destroy(interface)
    }
  end

  def get_interfaceospf_match_line(name, pattern)
    s = @device.cmd("show run interface all | " +
                    "sec \"interface .#{name[1..-1]}$\" | no-more")
    line = pattern.match(s)
    line
  end

  def create_routerospf(ospfname="ospfTest")
    @device.cmd("configure terminal")
    @device.cmd("feature ospf")
    @device.cmd("end")
    node.cache_flush
    routerospf = RouterOspf.new(ospfname, false)
  end

  def create_interfaceospf(routerospf, ifname=interfaces[0], area="0.0.0.0")
    interface_switchport_enable(ifname, false)
    interfaceospf = InterfaceOspf.new(ifname, routerospf.name, area)
  end

  def interface_ethernet_default(ethernet_id=interfaces_id[0])
    @device.cmd("configure terminal")
    @device.cmd("default interface ethernet #{ethernet_id}")
    @device.cmd("end")
    node.cache_flush
  end

  def test_interfaceospf_collection_empty
    @device.cmd("configure terminal")
    @device.cmd("no feature ospf")
    @device.cmd("feature ospf")
    @device.cmd("router ospf TestOSPF")
    @device.cmd("end")
    node.cache_flush

    routers = RouterOspf.routers()
    routers.each do |name, router|
      interfaces = InterfaceOspf.interfaces(router.name)
      assert_empty(interfaces,
                   "InterfaceOspf collection is not empty")
    end
    routerospf_routers_destroy(routers)
  end

  def test_interfaceospf_collection_not_empty
    ifname1 = interfaces[1].downcase
    ifname2 = interfaces[2].downcase
    ospf1 = "TestOSPF"
    ospf2 = "bxb300"
    # pre-configure
    interface_switchport_enable(ifname1, false)
    interface_switchport_enable(ifname2, false)
    @device.cmd("configure terminal")
    @device.cmd("no feature ospf")
    @device.cmd("feature ospf")
    @device.cmd("router ospf #{ospf1}")
    @device.cmd("interface #{ifname1}")
    @device.cmd("ip router ospf #{ospf1} area 0.0.0.0")
    @device.cmd("router ospf #{ospf2}")
    @device.cmd("interface #{ifname2}")
    @device.cmd("ip router ospf #{ospf2} area 10.6.6.1")
    @device.cmd("end")
    node.cache_flush

    routers = RouterOspf.routers()
    # validate the collection
    routers.each do |name, router|
      interfaces = InterfaceOspf.interfaces(router.name)
      refute_empty(interfaces,
                   "InterfaceOspf collection is empty")
      assert_equal(1, interfaces.size(),
                   "InterfaceOspf collection (#{interfaces}) size is not 1")
      interfaces.each do | ifname, interface|
        pattern = (/\s+ip router ospf #{router.name} area #{interface.area}/)
        line = get_interfaceospf_match_line(ifname, pattern)
        refute_nil(line, "Error: ip router ospf #{router.name} " +
                   "area #{interface.area} not found under #{ifname}")
        # using default check, since not configured anything
        assert_equal(node.config_get_default("interface_ospf", "cost"),
                     interface.cost,
                     "Error: get cost failed")
        assert_equal(node.config_get_default("interface_ospf",
                                             "hello_interval"),
                     interface.hello_interval,
                     "Error: get hello interval failed")
        assert_equal(node.config_get_default("interface_ospf",
                                             "dead_interval"),
                     interface.dead_interval,
                     "Error: get dead interval failed")
        assert_equal(node.config_get_default("interface_ospf",
                                             "passive_interface"),
                     interface.passive_interface,
                     "Error: passive interface get failed")
        assert_equal(node.config_get_default("interface_ospf",
                                             "message_digest"),
                     interface.message_digest,
                     "Error: message digest get failed")
        assert_equal(node.config_get_default("interface_ospf",
                                             "message_digest_key_id"),
                     interface.message_digest_key_id,
                     "Error: message digest key get failed")
      end
      interfaceospf_interfaces_destroy(interfaces)
    end
    routerospf_routers_destroy(routers)
    interface_ethernet_default(interfaces_id[2])
    interface_ethernet_default(interfaces_id[1])
  end

  def test_interfaceospf_create_routerospf_nil
    assert_raises(TypeError) do
      ospf = InterfaceOspf.new(interfaces[0], nil, "0.0.0.0")
    end
  end

  def test_interfaceospf_create_interface_name_zero_length
    name = "ospfTest"
    ospf = RouterOspf.new(name)
    assert_raises(ArgumentError) do
      interface = InterfaceOspf.new("", ospf.name, "0.0.0.0")
    end
    routerospf_router_destroy(ospf)
  end

  def test_interfaceospf_create_interface_area_zero_length
    name = "ospfTest"
    ospf = RouterOspf.new(name)
    assert_raises(ArgumentError) do
      interface = InterfaceOspf.new(interfaces[0], ospf.name, "")
    end
    routerospf_router_destroy(ospf)
  end

  def test_routerospf_create_valid
    ospf = create_routerospf
    ifname = interfaces[1]
    area = "0.0.0.0"
    interface_switchport_enable(ifname, false)
    interface = InterfaceOspf.new(ifname, ospf.name, area)
    pattern = (/\s+ip router ospf #{ospf.name} area #{area}/)
    line = get_interfaceospf_match_line(ifname, pattern)
    refute_nil(line, "Error: 'ip router ospf #{ospf.name} area #{area}' " +
               "not configured")
    assert_equal(ifname.downcase, interface.interface.name,
                 "Error: interface name get value mismatch ")
    assert_equal(area, interface.area,
                 "Error: area get value mismatch ")
    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default(interfaces_id[1])
  end

  def test_interfaceospf_destroy
    ifname = interfaces[1]
    area = "0.0.0.0"
    ospf = create_routerospf
    interface = create_interfaceospf(ospf, ifname, area)
    interface.destroy
    pattern = (/\s+ip router ospf #{ospf.name} area #{area}/)
    line = get_interfaceospf_match_line(ifname, pattern)
    assert_nil(line, "Error: 'ip router ospf #{ospf.name} area #{area}' " +
               "not destroyed")
    # check all the attributes are set to default.
    pattern = (/^\s+ip ospf cost \S+/)
    line = get_interfaceospf_match_line(ifname, pattern)
    assert_nil(line,
               "Error: 'ip ospf #{ospf.name} cost' not removed")

    pattern = (/^\s+ip ospf hello-interval \S+/)
    line = get_interfaceospf_match_line(ifname, pattern)
    assert_nil(line,
               "Error: 'ip ospf #{ospf.name} hello-interval' not removed")

    # with default CLI still shows the value
    pattern = (/^\s+ip ospf dead-interval \S+/)
    line = get_interfaceospf_match_line(ifname, pattern)
    assert_nil(line,
               "Error: 'ip ospf #{ospf.name} dead-interval' not removed")

    pattern = (/^\s+ip ospf passive-interface/)
    line = get_interfaceospf_match_line(ifname, pattern)
    assert_nil(line,
               "Error: 'ip ospf #{ospf.name} passive interface' not removed")

    routerospf_router_destroy(ospf)
    interface_ethernet_default(interfaces_id[1])
  end

  def test_routerospf_get_parent
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    assert_equal(ospf.name, interface.ospf_name)
    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_cost_invalid_range
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    # upper range
    assert_raises(CliError) do
      interface.cost = 65536
    end
    # lower range just removes the config.
    # assert_raises(RuntimeError) do
    #  interface.cost = 0
    # end
    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_cost
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    cost = 1000
    # set with value
    interface.cost = cost
    pattern = (/\s+ip ospf cost #{cost}/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line,
               "Error: cost missing in CLI")
    assert_equal(cost, interface.cost,
                 "Error: cost get value mismatch")
    # set default
    interface.cost = interface.default_cost
    pattern = (/\s+ip ospf cost(.*)/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    assert_nil(line,
               "Error: default cost set failed")
    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_hello_interval_invalid_range
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    # upper range
    assert_raises(CliError) do
      interface.hello_interval = 65536
    end
    # lower range
    assert_raises(CliError) do
      interface.hello_interval = 0
    end
    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_hello_interval
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    interval = 90
    # set with value
    interface.hello_interval = interval
    pattern = (/\s+ip ospf hello-interval #{interval}/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line,
               "Error: hello-interval missing in CLI")
    assert_equal(interval, interface.hello_interval,
                 "Error: hello-interval get value mismatch")

    # set default, when we set default CLI does not show it
    interface.hello_interval = interface.default_hello_interval
    pattern = (/\s+ip ospf hello-interval(.*)/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    assert_nil(line,
               "Error: default hello-interval set failed")
    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_dead_interval_invalid_range
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    ref = cmd_ref.lookup("interface_ospf", "dead_interval")
    assert(ref, "Error, reference not found for dead_interval")

    # upper range
    assert_raises(CliError) do
      interface.dead_interval = 262141
    end
    # lower range
    assert_raises(CliError) do
      interface.dead_interval = 0
    end
    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_dead_interval
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    interval = 150
    # set with value
    interface.dead_interval = interval
    pattern = (/\s+ip ospf dead-interval #{interval}/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line,
               "Error: dead-interval missing in CLI")
    assert_equal(interval, interface.dead_interval,
                 "Error: dead-interval get value mismatch")
    # set default, the CLI shows with default value
    interface.dead_interval = interface.default_dead_interval
    pattern = (/^\s+ip ospf dead-interval #{interface.default_dead_interval}/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line,
               "Error: default dead-interval set failed")
    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_passive_interface
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    # set with value
    interface.passive_interface = true
    pattern = (/\s+ip ospf passive-interface/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line, "Error: passive interface enable missing in CLI")
    assert(interface.passive_interface,
           "Error: passive interface get value mismatch")

    # get default and set
    interface.passive_interface = interface.default_passive_interface
    node.cache_flush()
    pattern = (/\s+no ip ospf passive-interface/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line,
               "Error: default passive interface set failed")
    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_create_valid_multiple
    # ospf and interfaces[0]
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    pattern = (/\s+ip router ospf #{ospf.name} area #{interface.area}/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line, "Error: 'ip router ospf #{ospf.name} default area' " +
               "not configured")

    # ospf and interfaces_id[2]
    ifname = interfaces[2]
    area = "1.1.1.1"
    interface1 = create_interfaceospf(ospf, ifname, area)
    pattern = (/\s+ip router ospf #{ospf.name} area #{area}/)
    line = get_interfaceospf_match_line(ifname, pattern)
    refute_nil(line,
               "Error: 'ip router ospf #{ospf.name} area #{area}' not configured")
    interfaceospf_interface_destroy(interface)
    interfaceospf_interface_destroy(interface1)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
    interface_ethernet_default(interfaces_id[2])
  end

  def test_interfaceospf_create_multiple_delete_one
    # ospf and interfaces[0]
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    # ospf and interfaces_id[2]
    ifname = interfaces[2]
    area = "1.1.1.1"
    interface1 = create_interfaceospf(ospf, ifname, area)
    assert_equal(ifname.downcase, interface1.interface.name,
                 "Error: 'ip router ospf #{ospf.name} area #{area}' " +
                 "not configured")

    # delete ospf instance from interfaces_id[2]
    interface1.destroy
    pattern = (/\s+ip router ospf #{ospf.name} area #{area}/)
    line = get_interfaceospf_match_line(ifname, pattern)
    assert_nil(line,
               "Error: 'ip router ospf #{ospf.name} area #{area}' not deleted")

    # check other interface association still exist.
    pattern = (/\s+ip router ospf #{ospf.name} area #{interface.area}/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line,
               "Error: 'ip router ospf #{ospf.name} default area' " +
               "not configured")

    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
    interface_ethernet_default(interfaces_id[2])
  end

  def test_interfaceospf_collection_multiple_interface
    s = @device.cmd("conf t ; int port-channel 42 ; descr foo ; end")
    known_failure = s[/ERROR:.*port channel not present/]
    refute(known_failure, "ERROR: port channel not present")

    ospf_h = Hash.new { |h, k| h[k] = {} }
    ospf_h["ospfTest"] = {
      interfaces[0].downcase => {
        :area => "0.0.0.0", :cost => 10, :hello => 30, :dead => 120,
        :pass => true,
      },
      interfaces[1].downcase => {
        :area => "1.1.1.38", :dead => 40, :pass => false,
      },
      "vlan101" => {
        :area => "2.2.2.101", :cost => 5, :hello => 20, :dead => 80,
        :pass => true,
      },
    }
    ospf_h["TestOspfInt"] = {
      interfaces[2].downcase => {
        :area => "0.0.0.19",
      },
      "vlan290" => {
        :area => "2.2.2.29", :cost => 200, :hello => 30, :dead => 120,
        :pass => true,
      },
      "port-channel100" => {
        :area => "3.2.2.29", :cost => 25, :hello => 50, :dead => 200,
        :pass => false,
      },
    }
    # enable feature ospf
    @device.cmd("configure terminal")
    @device.cmd("no feature ospf")   # cleanup prev configs
    @device.cmd("feature ospf")
    @device.cmd("feature interface-vlan")
    @device.cmd("default interface interfaces[0] ")
    @device.cmd("default interface interfaces[1] ")
    @device.cmd("default interface interfaces[2] ")
    @device.cmd("end")

    # pre-configure
    ospf_h.each do | k, v|
      # puts "TEST: pre-config hash key : #{k}"
      @device.cmd("configure terminal")
      @device.cmd("router ospf #{k}")
      @device.cmd("end")
      v.each do | k1, v1|
        # puts "TEST: pre-config k1: v1 '#{k1} : #{v1}'"
        @device.cmd("configure terminal")
        @device.cmd("interface #{k1}")
        if !(/^ethernet\d.\d/).match(k1.to_s).nil? ||
           !(/^port-channel\d/).match(k1.to_s).nil?
          @device.cmd("no switchport")
          # puts "switchport disable: #{k1}"
        end
        # puts "k1: #{k1}, k:  #{k},   area   #{v1[:area]}"
        @device.cmd("ip router ospf #{k} area #{v1[:area]}")
        @device.cmd("ip ospf cost #{v1[:cost]}") unless v1[:cost].nil?
        @device.cmd("ip ospf hello-interval #{v1[:hello]}") unless v1[:hello].nil?
        @device.cmd("ip ospf dead-interval #{v1[:dead]}") unless v1[:dead].nil?
        @device.cmd("ip ospf passive-interface") if !v1[:pass].nil? &&
                                                    v1[:pass] == true
        @device.cmd("exit")
      end
      @device.cmd("end")
    end
    node.cache_flush

    routers = RouterOspf.routers()
    # validate the collection
    routers.each do | name, router|
      interfaces = InterfaceOspf.interfaces(router.name)
      refute_empty(interfaces, "InterfaceOspf collection is empty")
      assert_includes(ospf_h, name)
      ospfh = ospf_h.fetch(name)
      assert_equal(ospfh.size(), interfaces.size(),
                   "InterfaceOspf #{name} collection size mismatch")
      interfaces.each do | ifname, interface |
        assert_includes(ospfh, ifname)
        hv = ospfh.fetch(ifname)
        pattern = (/\s+ip router ospf #{name} area #{hv[:area]}/)
        line = get_interfaceospf_match_line(ifname, pattern)
        refute_nil(line, "Error: ip router ospf #{name} area #{hv[:area]} "+
                   "not found under #{ifname}")

        # check the cost
        if hv[:cost].nil?
          # using default check, since not configured anything
          assert_equal(node.config_get_default("interface_ospf", "cost"),
                       interface.cost,
                       "Error: get default cost failed")
        else
          assert_equal(hv[:cost], interface.cost,
                       "Error: get cost failed")
        end
        # check the hello
        if hv[:hello].nil?
          assert_equal(node.config_get_default("interface_ospf",
                                               "hello_interval"),
                       interface.hello_interval,
                       "Error: get default hello interval failed")
        else
          assert_equal(hv[:hello], interface.hello_interval,
                       "Error: get hello interval failed")
        end
        # check the dead
        if hv[:dead].nil?
          assert_equal(node.config_get_default("interface_ospf",
                                               "dead_interval"),
                       interface.dead_interval,
                       "Error: get dead interval failed")
        else
          assert_equal(hv[:dead], interface.dead_interval,
                       "Error: get dead interval failed")
        end
        # check passive interface
        if hv[:pass].nil?
          assert_equal(node.config_get_default("interface_ospf",
                                               "passive_interface"),
                       interface.passive_interface,
                       "Error: passive interface get failed")
        else
          assert_equal(hv[:pass], interface.passive_interface,
                       "Error: passive interface get failed")
        end
      end
      # cleanup interfaces
      # node.debug=true
      interfaceospf_interfaces_destroy(interfaces)
      # node.debug=true
      interfaces=nil
    end # interfaces hash
    # clean up
    routerospf_routers_destroy(routers)
    routers=nil

    # disable feature interface-vlan
    @device.cmd("configure terminal")
    @device.cmd("no feature interface-vlan")
    @device.cmd("end")
    # clean up port channel
    ospf_h.each do | k, v|
      v.each do | k1, v1|
        unless (/^port-channel\d/).match(k1.to_s).nil?
          @device.cmd("configure terminal")
          @device.cmd("no interface #{k1}")
          @device.cmd("end")
        end
      end # v each
    end # ospf_h each
    node.cache_flush

    interface_ethernet_default(interfaces_id[0])
    interface_ethernet_default(interfaces_id[1])
    interface_ethernet_default(interfaces_id[2])
  end

  def test_interfaceospf_message_digest
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    # set with value
    interface.message_digest = true
    pattern = (/^\s+ip ospf authentication message-digest$/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line,
               "Error: message digest enable missing in CLI")
    assert(interface.message_digest,
           "Error: message digest get value mismatch")

    # get default and set
    interface.message_digest = interface.default_message_digest
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    assert_nil(line,
               "Error: default message digest set failed")
    refute(interface.message_digest,
           "Error: message digest get value mismatch")
    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_message_digest_key
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    # auth params
    keyid = 1
    algo = :md5
    encr = :cleartext

    # set with value
    interface.message_digest_key_set(keyid, algo, encr, "test123")
    # need to revist TODO
    pattern = (/^\s+ip ospf message-digest-key #{keyid} md5 \S \S+$/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line,
               "Error: message digest authentication with cleartext " +
               "missing in CLI")
    # TODO: assert(interface.message_digest,
    #             "Error: message digest get value mismatch")
    # check key id exist
    assert_equal(keyid, interface.message_digest_key_id,
                 "Error: message digest key #{keyid} not present")
    # save encrypted password
    md = /3 (\S+)$/.match(line.to_s)
    encrypted_password = md.to_s.split(" ").last
    assert_equal(encrypted_password, interface.message_digest_password)

    # Check other attributes:
    assert_equal(algo, interface.message_digest_algorithm_type)
    assert_equal(:"3des", interface.message_digest_encryption_type)

    # unconfigure auth
    keyid = interface.default_message_digest_key_id
    encr = :cleartext
    interface.message_digest_key_set(keyid, algo, encr, "test123")
    pattern = (/^\s+ip ospf message-digest-key #{keyid} .+/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    assert_nil(line,
               "Error: message digest authentication still present in CLI")
    assert_equal(interface.message_digest_key_id,
                 interface.default_message_digest_key_id)
    assert_equal(interface.message_digest_algorithm_type,
                 interface.default_message_digest_algorithm_type)
    assert_equal(interface.message_digest_encryption_type,
                 interface.default_message_digest_encryption_type)

    # update enc with 3DES
    keyid = 1
    encr = :"3des"
    interface.message_digest_key_set(keyid, algo, encr, encrypted_password)
    pattern = (/^\s+ip ospf message-digest-key #{keyid} md5 3 \S+$/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line,
               "Error: message digest authentication with 3DES missing " +
               "in CLI")
    assert_equal(keyid, interface.message_digest_key_id)
    assert_equal(algo, interface.message_digest_algorithm_type)
    assert_equal(encr, interface.message_digest_encryption_type)
    assert_equal(encrypted_password, interface.message_digest_password)

    # update enc with cisco type 7
    keyid = 1
    encr = :cisco_type_7
    interface.message_digest_key_set(keyid, algo, encr, encrypted_password)
    pattern = (/^\s+ip ospf message-digest-key #{keyid} md5 7 \S+$/)
    line = get_interfaceospf_match_line(interface.interface.name, pattern)
    refute_nil(line,
               "Error: message digest authentication with cisco type 7 " +
               "missing in CLI")
    assert_equal(keyid, interface.message_digest_key_id)
    assert_equal(algo, interface.message_digest_algorithm_type)
    assert_equal(encr, interface.message_digest_encryption_type)

    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_message_digest_key_invalid_password
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    # blank password
    keyid = 1
    algo = :md5
    encr = :cleartext
    password = ""
    assert_raises(ArgumentError) do
      interface.message_digest_key_set(keyid, algo, encr, password)
    end

    # mismatch password and encryption
    encr = :"3des"
    password = "test123"
    assert_raises(CliError) do
      interface.message_digest_key_set(keyid, algo, encr, password)
    end

    interfaceospf_interface_destroy(interface)
    routerospf_router_destroy(ospf)
    interface_ethernet_default()
  end

  def test_interfaceospf_nonexistent
    # If the interface does exist but the OSPF instance does not, this is OK
    @device.cmd("configure terminal")
    @device.cmd("interface loopback122")
    @device.cmd("end")
    node.cache_flush
    interface = InterfaceOspf.new("loopback122", "nonexistentOspf", "0")

    assert_equal(interface.area, "0")
    assert_equal(interface.hello_interval, interface.default_hello_interval)

    interface.destroy

    # If the interface doesn't exist, InterfaceOspf should raise an error
    @device.cmd("configure terminal")
    @device.cmd("no interface loopback122")
    @device.cmd("end")
    node.cache_flush
    assert_raises(RuntimeError) do
      interface = InterfaceOspf.new("loopback122", "nonexistentOspf", "0")
    end
  end
end
