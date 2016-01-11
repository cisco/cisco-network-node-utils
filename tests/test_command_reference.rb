#!/usr/bin/env ruby
#
# November 2014, Glenn F. Matthews
#
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
#

require_relative 'basetest'

require 'tempfile'
require_relative '../lib/cisco_node_utils/command_reference'

# TestCmdRef - Minitest for CommandReference and CmdRef classes.
class TestCmdRef < Minitest::Test
  include Cisco

  def setup
    @input_file = Tempfile.new('test.yaml')
  end

  def teardown
    @input_file.close!
  end

  def load_file(**args)
    CommandReference.new(**args, :files => [@input_file.path])
  end

  def write(string)
    @input_file.write(string + "\n")
    @input_file.flush
  end

  def test_data_sanity
    # Make sure the actual YAML in our library loads for various platforms
    CommandReference.new

    CommandReference.new(platform:     :nexus,
                         data_formats: [:nxapi_structured, :cli])

    CommandReference.new(platform:     :nexus,
                         product:      'N9K-C9396PX',
                         data_formats: [:nxapi_structured, :cli])

    CommandReference.new(platform:     :nexus,
                         product:      'N7K-C7010',
                         data_formats: [:nxapi_structured, :cli])

    CommandReference.new(platform:     :nexus,
                         product:      'N3K-C3064PQ-10GE',
                         data_formats: [:nxapi_structured, :cli])

    CommandReference.new(platform:     :ios_xr,
                         data_formats: [:cli])

    CommandReference.new(platform:     :ios_xr,
                         product:      'R-IOSXRV9000-CH',
                         data_formats: [:cli])
  end

  def test_load_empty_file
    # should load successfully but yield an empty hash
    reference = load_file
    assert_empty(reference)
  end

  def test_load_whitespace_only
    write('   ')
    reference = load_file
    assert_empty(reference)
  end

  def test_load_not_valid_yaml
    # The control characters embedded below are not permitted in YAML.
    write("
name\a\e\b\f:
  default_value:\vtrue")
    assert_raises(RuntimeError) { load_file }
  end

  def test_load_feature_name_no_data
    write("
name:")
    assert_raises(RuntimeError) do
      load_file
    end
  end

  def test_load_feature_name_default
    write("
name:
  default_value: true")
    reference = load_file
    assert(!reference.empty?)
    ref = reference.lookup('test', 'name')
    assert_equal(true, ref.default_value)
  end

  def test_load_duplicate_name
    write("
name:
  default_value: false
name:
  get_command: 'show feature'")
    assert_raises(RuntimeError) { load_file }
  end

  def test_load_duplicate_param
    write("
name:
  default_value: false
  default_value: true")
    assert_raises(RuntimeError) { load_file }
  end

  def test_load_unsupported_key
    write("
name:
  get_command: 'show feature'
  what_is_this: \"I don't even\"")
    assert_raises(RuntimeError) { load_file }
  end

  def test_load_unalphabetized
    write("
name_b:
  default_value: true
name_a:
  default_value: false")
    assert_raises(RuntimeError) { load_file }
  end

  def type_check(obj, cls)
    assert(obj.is_a?(cls), "#{obj} should be #{cls} but is #{obj.class}")
  end

  def test_load_types
    write(%q(
name:
  default_value: true
  get_command: show hello
  get_context: '/hello/i'
  get_value: '/world/'
  set_context: [ \"hello\", \"world\" ]
  set_value:
    - \"hello\"
    - \"world\"
  test_get_value: '/hello world/'
  test_config_result:
    false: RuntimeError
    32: "Long VLAN name knob is not enabled"
    nil: ~
))
    reference = load_file
    ref = reference.lookup('test', 'name')
    type_check(ref.default_value, TrueClass)
    type_check(ref.get_command, String)
    type_check(ref.get_context, Array)
    type_check(ref.get_context[0], Regexp)
    type_check(ref.get_value, Array)
    type_check(ref.get_value[0], Regexp)
    type_check(ref.set_context, Array)
    type_check(ref.set_context[0], String)
    type_check(ref.set_value, Array)
    type_check(ref.set_value[0], String)
    type_check(ref.test_get_value, Regexp)
    assert_raises(IndexError) { ref.test_get_command }
    type_check(ref.test_config_result(false), RuntimeError.class)
    type_check(ref.test_config_result(32), String)
    type_check(ref.test_config_result('nil'), NilClass)

    assert(ref.default_value?)
    assert(ref.get_command?)
    assert(ref.get_context?)
    assert(ref.get_value?)
    assert(ref.getter?)
    assert(ref.set_context?)
    assert(ref.set_value?)
    assert(ref.setter?)
  end

  def write_variants
    write("
name:
  default_value: 'generic'
  nexus:
    default_value: 'NXAPI base'
    /N7K/:
      default_value: ~
    /N9K/:
      default_value: 'NXAPI N9K'
  ios_xr:
    /XRV9000/:
      default_value: ~
    else:
      default_value: 'gRPC base'
")
  end

  def test_load_generic
    write_variants
    # Neither NXAPI nor gRPC
    reference = load_file
    assert_equal('generic', reference.lookup('test', 'name').default_value)
  end

  def test_load_n9k
    write_variants
    reference = load_file(platform:     :nexus,
                          product:      'N9K-C9396PX',
                          data_formats: [:nxapi_structured, :cli])
    assert_equal('NXAPI N9K', reference.lookup('test', 'name').default_value)
  end

  def test_load_n7k
    write_variants
    reference = load_file(platform:     :nexus,
                          product:      'N7K-C7010',
                          data_formats: [:nxapi_structured, :cli])
    assert_equal(nil, reference.lookup('test', 'name').default_value)
  end

  def test_load_n3k_3064
    write_variants
    reference = load_file(platform:     :nexus,
                          product:      'N3K-C3064PQ-10GE',
                          data_formats: [:nxapi_structured, :cli])
    assert_equal('NXAPI base', reference.lookup('test', 'name').default_value)
  end

  def test_load_ios_xr_xrv9k
    write_variants
    reference = load_file(platform:     :ios_xr,
                          product:      'R-IOSXRV9000-CH',
                          data_formats: [:cli])
    assert_nil(reference.lookup('test', 'name').default_value)
  end

  def test_load_ios_xr_generic
    write_variants
    reference = load_file(platform:     :ios_xr,
                          data_formats: [:cli])
    assert_equal('gRPC base', reference.lookup('test', 'name').default_value)
  end

  def write_exclusions
    write("
_exclude:
  - /N9K/

name:
  _exclude: [/C30../, /C31../]
  default_value: hello

rank:
  default_value: 27
")
  end

  def test_exclude_whole_file
    write_exclusions
    reference = load_file(product: 'N9K-C9396PX')

    ref = reference.lookup('test', 'name')
    # default_value is nil for an unsupported property
    assert(ref.default_value?, 'default_value? returned false')
    assert_nil(ref.default_value)
    refute(ref.getter?)
    assert_raises(Cisco::UnsupportedError) { ref.getter }
    refute(ref.setter?)
    assert_raises(Cisco::UnsupportedError) { ref.setter }

    # Because the whole file is excluded, we don't know which
    # attributes are 'valid' - so any attribute name is permitted:
    ref = reference.lookup('test', 'foobar')
    assert(ref.default_value?)
    assert_nil(ref.default_value)
    refute(ref.getter?)
    assert_raises(Cisco::UnsupportedError) { ref.getter }
    refute(ref.setter?)
    assert_raises(Cisco::UnsupportedError) { ref.setter }
  end

  def test_exclude_whole_item
    write_exclusions
    reference = load_file(product: 'N3K-C3172PQ')
    assert_equal(27, reference.lookup('test', 'rank').default_value)

    ref = reference.lookup('test', 'name')
    assert(ref.default_value?)
    assert_nil(ref.default_value)
    refute(ref.getter?)
    assert_raises(Cisco::UnsupportedError) { ref.getter }
    refute(ref.setter?)
    assert_raises(Cisco::UnsupportedError) { ref.setter }
  end

  def test_exclude_no_exclusion
    write_exclusions
    reference = load_file(product: 'N7K-C7010')
    assert_equal('hello',  reference.lookup('test', 'name').default_value)
    assert_equal(27, reference.lookup('test', 'rank').default_value)
  end

  def test_exclude_implicit
    # TODO: something is hinky with this test.
    write("
name:
  cli:
    default_value: 1
")
    reference = load_file(platform: 'nexus', data_formats: [])
    ref = reference.lookup('test', 'name')
    assert(ref.default_value?)
    assert_nil(ref.default_value)
  end

  def test_default_only
    write("
name:
  default_only: 'x'
")
    reference = load_file
    ref = reference.lookup('test', 'name')
    assert(ref.default_only?)
    assert(ref.default_value?)
    assert_equal('x', ref.default_value)
    refute(ref.getter?)
    assert_raises(Cisco::UnsupportedError) { ref.getter }
    refute(ref.setter?)
    assert_raises(Cisco::UnsupportedError) { ref.setter }
  end

  def test_default_only_cleanup
    write("
name:
  default_only: 'x'
  set_value: 'foo'
")
    reference = load_file
    ref = reference.lookup('test', 'name')
    assert(ref.default_only?)
    assert(ref.default_value?)
    assert_equal('x', ref.default_value)
    refute(ref.set_value?)
    assert_raises(Cisco::UnsupportedError) { ref.set_value }
    refute(ref.setter?)
    assert_raises(Cisco::UnsupportedError) { ref.setter }

    write("
name2:
  set_value: 'foo'
  default_only: 'x'
")
    reference = load_file
    ref = reference.lookup('test', 'name2')
    assert(ref.default_only?)
    assert(ref.default_value?)
    assert_equal('x', ref.default_value)
    refute(ref.set_value?)
    assert_raises(Cisco::UnsupportedError) { ref.set_value }
    refute(ref.setter?)
    assert_raises(Cisco::UnsupportedError) { ref.setter }
  end

  def test_default_only_default_value
    write("
name:
  kind: int
  nexus:
    default_value: 10
    set_value: 'hello'
  default_only: 0
")
    reference = load_file
    ref = reference.lookup('test', 'name')
    assert(ref.default_only?)
    assert(ref.default_value?)
    assert_equal(0, ref.default_value)
    refute(ref.set_value?)
    assert_raises(Cisco::UnsupportedError) { ref.set_value }
    refute(ref.setter?)
    assert_raises(Cisco::UnsupportedError) { ref.setter }

    reference = load_file(data_formats: [:nxapi_structured, :cli],
                          platform:     'nexus')
    ref = reference.lookup('test', 'name')
    refute(ref.default_only?)
    assert(ref.default_value?)
    assert_equal(10, ref.default_value)
    assert(ref.set_value?)
    assert(ref.setter?)
    assert_raises(IndexError) { ref.get_value }
  end

  def test_getter_hash_substitution
    write(%q(
name:
  get_context:
    ['/^router ospf <name>$/',
     '/^vrf <vrf>$/']
  get_value: '/^router-id (\S+)$/'
))
    reference = load_file
    ref = reference.lookup('test', 'name')
    token = ref.getter(name: 'red')
    assert_equal([/^router ospf red$/, /^router-id (\S+)$/],
                 token)
    token = ref.getter(name: 'blue', vrf: 'green')
    assert_equal([/^router ospf blue$/, /^vrf green$/, /^router-id (\S+)$/],
                 token)
    # TODO: add negative tests?
  end

  def test_getter_printf_substitution
    write("
name:
  get_context: '/^interface %s$/i'
  get_value: '/^description (.*)/'
")
    reference = load_file
    ref = reference.lookup('test', 'name')
    token = ref.getter('Ethernet1/1')
    assert_equal([%r{^interface Ethernet1/1$}i, /^description (.*)/],
                 token)
    # Negative tests - wrong # of args
    assert_raises(ArgumentError) { ref.getter }
    assert_raises(ArgumentError) { ref.getter('eth1/1', 'foo') }
  end
end
