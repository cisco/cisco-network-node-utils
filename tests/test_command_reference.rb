#!/usr/bin/env ruby
#
# November 2014, Glenn F. Matthews
#
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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

  # Extend standard Minitest error handling to report UnsupportedError as skip
  def capture_exceptions
    super do
      begin
        yield
      rescue Cisco::UnsupportedError => e
        skip(e.to_s)
      end
    end
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
    CommandReference.new(platform: :nexus, cli: true)
    CommandReference.new(platform: :nexus, product: 'N9K-C9396PX', cli: true)
    CommandReference.new(platform: :nexus, product: 'N7K-C7010', cli: true)
    CommandReference.new(platform: :nexus, product: 'N3K-C3064PQ-10GE',
                         cli: true)
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
  config_get: 'show feature'")
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
  config_get: 'show feature'
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
  config_get: show hello
  config_get_token: '/hello world/'
  config_set: [ \"hello\", \"world\" ]
  test_config_get_regex: '/hello world/'
  test_config_result:
    false: RuntimeError
    32: "Long VLAN name knob is not enabled"
    nil: ~
))
    reference = load_file
    ref = reference.lookup('test', 'name')
    type_check(ref.default_value, TrueClass)
    type_check(ref.config_get, String)
    type_check(ref.config_get_token, Array)
    type_check(ref.config_get_token[0], Regexp)
    type_check(ref.config_set, Array)
    type_check(ref.test_config_get_regex, Regexp)
    assert_raises(IndexError) { ref.test_config_get }
    type_check(ref.test_config_result(false), RuntimeError.class)
    type_check(ref.test_config_result(32), String)
    type_check(ref.test_config_result('nil'), NilClass)

    assert(ref.default_value?)
    assert(ref.config_get?)
    assert(ref.config_get_token?)
    assert(ref.config_set?)
  end

  def write_variants
    write("
name:
  default_value: 'generic'
  cli_nexus:
    default_value: 'NXAPI base'
    /N7K/:
      default_value: ~
    /N9K/:
      default_value: 'NXAPI N9K'
")
  end

  def test_load_generic
    write_variants
    reference = load_file
    assert_equal('generic', reference.lookup('test', 'name').default_value)
  end

  def test_load_n9k
    write_variants
    reference = load_file(platform: :nexus, product: 'N9K-C9396PX', cli: true)
    assert_equal('NXAPI N9K', reference.lookup('test', 'name').default_value)
  end

  def test_load_n7k
    write_variants
    reference = load_file(platform: :nexus, product: 'N7K-C7010', cli: true)
    assert_equal(nil, reference.lookup('test', 'name').default_value)
  end

  def test_load_n3k_3064
    write_variants
    reference = load_file(platform: :nexus, product: 'N3K-C3064PQ-10GE',
                          cli: true)
    assert_equal('NXAPI base', reference.lookup('test', 'name').default_value)
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
    refute(ref.config_get?)
    assert_raises(Cisco::UnsupportedError) { ref.config_get }

    # Because the whole file is excluded, we don't know which
    # attributes are 'valid' - so any attribute name is permitted:
    ref = reference.lookup('test', 'foobar')
    assert(ref.default_value?)
    assert_nil(ref.default_value)
    refute(ref.config_get?)
    assert_raises(Cisco::UnsupportedError) { ref.config_get }
  end

  def test_exclude_whole_item
    write_exclusions
    reference = load_file(product: 'N3K-C3172PQ')
    assert_equal(27, reference.lookup('test', 'rank').default_value)

    ref = reference.lookup('test', 'name')
    assert(ref.default_value?)
    assert_nil(ref.default_value)
    refute(ref.config_get?)
    assert_raises(Cisco::UnsupportedError) { ref.config_get }
  end

  def test_exclude_no_exclusion
    write_exclusions
    reference = load_file(product: 'N7K-C7010')
    assert_equal('hello',  reference.lookup('test', 'name').default_value)
    assert_equal(27, reference.lookup('test', 'rank').default_value)
  end

  def test_exclude_implicit
    write("
name:
  cli_nexus:
    default_value: 1
")
    reference = load_file(platform: 'nexus', cli: false)
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
    refute(ref.config_set?)
    assert_raises(Cisco::UnsupportedError) { ref.config_set }
  end

  def test_default_only_cleanup
    write("
name:
  default_only: 'x'
  config_set: 'foo'
")
    reference = load_file
    ref = reference.lookup('test', 'name')
    assert(ref.default_only?)
    assert(ref.default_value?)
    assert_equal('x', ref.default_value)
    refute(ref.config_set?)
    assert_raises(Cisco::UnsupportedError) { ref.config_set }

    write("
name2:
  config_set: 'foo'
  default_only: 'x'
")
    reference = load_file
    ref = reference.lookup('test', 'name2')
    assert(ref.default_only?)
    assert(ref.default_value?)
    assert_equal('x', ref.default_value)
    refute(ref.config_set?)
    assert_raises(Cisco::UnsupportedError) { ref.config_set }
  end

  def test_default_only_default_value
    write("
name:
  kind: int
  cli_nexus:
    default_value: 10
    config_set: 'hello'
  default_only: 0
")
    reference = load_file
    ref = reference.lookup('test', 'name')
    assert(ref.default_only?)
    assert(ref.default_value?)
    assert_equal(0, ref.default_value)
    refute(ref.config_set?)
    assert_raises(Cisco::UnsupportedError) { ref.config_set }

    reference = load_file(cli: true, platform: 'nexus')
    ref = reference.lookup('test', 'name')
    refute(ref.default_only?)
    assert(ref.default_value?)
    assert_equal(10, ref.default_value)
    assert(ref.config_set?)
    assert_raises(IndexError) { ref.config_get }
  end

  def test_config_get_token_hash_substitution
    write(%q(
name:
  config_get_token:
    ['/^router ospf <name>$/',
     '/^vrf <vrf>$/',
     '/^router-id (\S+)$/']
test2:
  config_get_token:
    ['abc <val1> def',
     'xyz <val2>']
))
    reference = load_file
    ref = reference.lookup('test', 'name')
    token = ref.config_get_token(name: 'red')
    assert_equal([/^router ospf red$/, /^router-id (\S+)$/],
                 token)
    token = ref.config_get_token(name: 'blue', vrf: 'green')
    assert_equal([/^router ospf blue$/, /^vrf green$/, /^router-id (\S+)$/],
                 token)
    ref = reference.lookup('test', 'test2')
    token = ref.config_get_token(val1: '1', val2: '2')
    assert_equal(['abc 1 def', 'xyz 2'], token)
    token = ref.config_get_token(val1: '1', extra_val: 'asdf')
    assert_equal(['abc 1 def'], token)
    token = ref.config_get_token(val2: '2')
    assert_equal(['xyz 2'], token)
    assert_raises(ArgumentError) { token = ref.config_get_token }
    assert_raises(ArgumentError) { token = ref.config_get_token(extra: 'x') }
  end

  def test_config_get_token_printf_substitution
    write("
name:
  config_get_token: ['/^interface %s$/i', '/^description (.*)/']
")
    reference = load_file
    ref = reference.lookup('test', 'name')
    token = ref.config_get_token('Ethernet1/1')
    assert_equal([%r{^interface Ethernet1/1$}i, /^description (.*)/],
                 token)
    # Negative tests - wrong # of args
    assert_raises(ArgumentError) { ref.config_get_token }
    assert_raises(ArgumentError) { ref.config_get_token('eth1/1', 'foo') }
  end
end
