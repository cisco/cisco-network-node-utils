#!/usr/bin/env ruby
#
# Unit testing for CommandReference and CmdRef classes.
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

require 'minitest/autorun'
require 'tempfile'
require File.expand_path("../../lib/cisco_node_utils/command_reference", __FILE__)

class TestCmdRef < MiniTest::Unit::TestCase
  include CommandReference

  def setup
    @input_file = Tempfile.new('test.yaml')
  end

  def teardown
    @input_file.close!
  end

  def load_file
    CommandReference.new("", [@input_file.path])
  end

  def write(string)
    @input_file.write(string + "\n")
    @input_file.flush
  end

  def test_load_empty_file
    # should load successfully but yield an empty hash
    reference = load_file
    assert(reference.empty?)
  end

  def test_load_whitespace_only
    write("   ")
    reference = load_file
    assert(reference.empty?)
  end

  def test_load_not_valid_yaml
    # The control characters embedded below are not permitted in YAML.
    # Syck (in older Ruby versions) will incorrectly accept these
    # while parsing the file, but our CmdRef constructor will eventually
    # reject the data.
    # Psych (in newer Ruby versions) will correctly reject
    # this data at parse time.
    write("
feature\a\e:
  name\b\f:
    default_value:\vtrue")
    assert_raises(RuntimeError) do
      load_file
    end
  end

  def test_load_feature_no_name
    # should error out
    write("feature:")
    assert_raises(RuntimeError) do
      load_file
    end
  end

  def test_load_feature_name_no_data
    write("
feature:
  name:")
    assert_raises(RuntimeError) do
      reference = load_file
    end
  end

  def test_load_feature_name_default
    write("
feature:
  name:
    default_value: true")
    reference = load_file
    assert(!reference.empty?)
    ref = reference.lookup("feature", "name")
    assert_equal(true, ref.default_value)
  end

  def test_load_duplicate_feature
    write("
feature:
  name:
    default_value: false
feature:
  name:
    config_get: 'show feature'
")
    assert_raises(RuntimeError) do
      reference = load_file
    end
  end

  def test_load_duplicate_name
    write("
feature:
  name:
    default_value: false
  name:
    config_get: 'show feature'")
    assert_raises(RuntimeError) do
      reference = load_file
    end
  end

  def test_load_duplicate_param
    write("
feature:
  name:
    default_value: false
    default_value: true")
    assert_raises(RuntimeError) do
      reference = load_file
    end
  end

  def test_load_unsupported_key
    write("
feature:
  name:
    config_get: 'show feature'
    what_is_this: \"I don't even\"")
    assert_raises(RuntimeError) do
      reference = load_file
    end
  end

=begin
  # Alphabetization of features is not enforced at this time.
  def test_load_features_unalphabetized
    write("
zzz:
  name:
    default_value: true
zzy:
  name:
    default_value: false")
    self.assert_raises(RuntimeError) do
      reference = load_file
    end
  end
=end

  def type_check(obj, cls)
    assert(obj.is_a?(cls), "#{obj} should be #{cls} but is #{obj.class}")
  end

  def test_load_types
    write("
feature:
  name:
    default_value: true
    config_get: show hello
    config_get_token: !ruby/regexp '/hello world/'
    config_set: [ \"hello\", \"world\" ]
    test_config_get_regex: !ruby/regexp '/hello world/'
")
    reference = load_file
    ref = reference.lookup("feature", "name")
    type_check(ref.default_value, TrueClass)
    type_check(ref.config_get, String)
    type_check(ref.config_get_token, Regexp)
    type_check(ref.config_set, Array)
    type_check(ref.test_config_get_regex, Regexp)
  end

  def test_load_common
    reference = CommandReference.new("")
    assert(reference.files.any? { |filename| /common.yaml/ =~ filename })
    refute(reference.files.any? { |filename| /n9k.yaml/ =~ filename })
    refute(reference.files.any? { |filename| /n7k.yaml/ =~ filename })
    refute(reference.files.any? { |filename| /n3064.yaml/ =~ filename })
    # Some spot checks
    type_check(reference.lookup("vtp", "feature").config_get_token, String)
    type_check(reference.lookup("vtp", "version").default_value, Integer)
  end

  def test_load_n9k
    reference = CommandReference.new("N9K-C9396PX")
    assert(reference.files.any? { |filename| /common.yaml/ =~ filename })
    assert(reference.files.any? { |filename| /n9k.yaml/ =~ filename })
    refute(reference.files.any? { |filename| /n7k.yaml/ =~ filename })
    refute(reference.files.any? { |filename| /n3064.yaml/ =~ filename })
  end

  def test_load_n7k
    reference = CommandReference.new("N7K-C7010")
    assert(reference.files.any? { |filename| /common.yaml/ =~ filename })
    refute(reference.files.any? { |filename| /n9k.yaml/ =~ filename })
    assert(reference.files.any? { |filename| /n7k.yaml/ =~ filename })
    refute(reference.files.any? { |filename| /n3064.yaml/ =~ filename })
  end

  def test_load_n3k_3064
    reference = CommandReference.new("N3K-C3064PQ-10GE")
    assert(reference.files.any? { |filename| /common.yaml/ =~ filename })
    refute(reference.files.any? { |filename| /n9k.yaml/ =~ filename })
    refute(reference.files.any? { |filename| /n7k.yaml/ =~ filename })
    assert(reference.files.any? { |filename| /n3064.yaml/ =~ filename })
  end
end
