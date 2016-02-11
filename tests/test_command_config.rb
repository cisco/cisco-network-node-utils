#!/usr/bin/env ruby
#
# Michael Wiebe, December 2014
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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/configparser_lib'
require 'timeout'
require 'yaml'

def load_yaml(test_type=:positive)
  if test_type == :positive
    path = File.expand_path('../cmd_config.yaml', __FILE__)
  elsif test_type == :negative
    path = File.expand_path('../cmd_config_invalid.yaml', __FILE__)
  else
    fail TypeError
  end
  YAML.load(File.read(path))
end

# TestCommandConfig - Minitest for ConfigParser module
class TestCommandConfig < CiscoTestCase
  include ConfigParser

  # ---------------------------------------------------------------------------
  # Helper Methods
  # ---------------------------------------------------------------------------

  def remove_whitespace(commands)
    commands.gsub(/^\s*$\n/, '')
  end # remove_whitespace

  def compare_with_results(desired_config_str, current_key)
    retrieve_command = 'show running all'
    running_config_str = node.show(retrieve_command)

    begin
      should_config = ConfigParser::Configuration.new(desired_config_str)
      running_config = ConfigParser::Configuration.new(running_config_str)
      existing = should_config.compare_with(running_config)
    rescue StopIteration => e
      puts e.what
    rescue ArgumentError => e
      puts e.what
    end
    # puts "Existing command block:\n#{existing}"
    assert_equal(existing.empty?, false,
                 "Error: Expected configuration \n'#{desired_config_str}'\n " \
                 "does not exist.\nHash Key: #{current_key}")
  end

  def send_device_config(config_cmd_hash)
    config_cmd_hash.each do |k, v|
      v.each_value do |v1|
        # Send commands
        cfg_cmd_str = "#{v1.gsub(/^/, '  ')}"
        cfg_string = remove_whitespace(cfg_cmd_str)
        # puts "cfg_string: \n||\n#{cfg_string}||\n"
        begin
          node.config(cfg_string)
          # make sure config is present in success case
          compare_with_results(v1, k)
        rescue CliError => e
          known_failure = e.message[/ERROR:.*port channel not present/]
          refute(known_failure, 'ERROR: port channel not present')
          raise
        end
      end
    end
  end

  def build_int_scale_config(add=true)
    add ? s = '' : s = 'no '
    current_interface = 0
    num_interfaces = 1024
    command_list = ''
    while current_interface < num_interfaces
      command_list += "#{s}interface loopback#{current_interface}\n"
      current_interface += 1
    end
    command_list
  end

  # ---------------------------------------------------------------------------
  # Test Case Methods
  # ---------------------------------------------------------------------------

  def test_valid_config
    cfg_hash = load_yaml
    begin
      send_device_config(cfg_hash)
    end
  end

  def test_valid_scale
    show_int_count = "show int brief | i '^\S+\s+--' | count"
    pre = @device.cmd(show_int_count)[/^(\d+)$/]

    # Add 1024 loopback interfaces
    cfg_hash_add = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    cfg_hash_add ['loopback-int-add']['command'] = "#{build_int_scale_config}"
    begin
      send_device_config(cfg_hash_add)
    rescue Timeout::Error
      puts "\n -- Long-running command, extending timeout +30 sec"
      sleep 30 # long-running command
      curr = @device.cmd('show int brief | count')[/^(\d+)$/]
      flunk('Timeout while creating 1024 loopback interfaces' \
            "(pre:#{pre} curr:#{curr}") unless pre == curr - 1024
    end

    # Remove 1024 loopback interfaces
    cfg_hash_remove = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    cfg_hash_remove['loopback-int-add']['command'] = \
      "#{build_int_scale_config(false)}"
    begin
      send_device_config(cfg_hash_remove)
    rescue Timeout::Error
      puts "\n -- Long-running command, extending timeout +30 sec"
      sleep 30 # long-running: n95 can take 70+ sec to remove all of these
      curr = @device.cmd(show_int_count)[/^(\d+)$/]
      flunk('Timeout while deleting 1024 loopback interfaces ' \
            "(pre:#{pre} curr:#{curr}") unless pre == curr
    end
  end

  def test_invalid_config
    cfg_hash = load_yaml(:negative)
    cfg_hash.each_value do |v|
      v.each_value do |v1|
        cfg_cmd_str = "#{v1.gsub(/^/, '  ')}\n"
        cfg_string = remove_whitespace(cfg_cmd_str)
        assert_raises(CliError) { node.config(cfg_string) }
      end
    end
  end

  def test_indent_with_tab
    assert_raises(RuntimeError,
                  'Should have caught TAB char in indent area') do
      Configuration.new("  \t  interface loopback10")
    end
  end

  def test_build_min_config_hash
    # 1. Get superset of running-config and agent-config
    # 2. From superset derive minimum needed for parity with running
    runn_str = "
     \ninterface loopback10
     \n  description foo
     \ninterface loopback11
     \ninterface loopback12
     \ninterface loopback13"
    runn_hash = Configuration.new(runn_str)

    agent_str = "
     \ninterface loopback10
     \n  description 10
     \ninterface loopback11
     \nno interface loopback12
     \ninterface loopback13"
    agent_hash = Configuration.new(agent_str)

    min_expected = ['interface loopback10',
                    'description 10',
                    'no interface loopback12',
                   ].join("\n")

    superset_str = agent_hash.compare_with(runn_hash)
    superset_hash = Configuration.new(superset_str)

    min_config_hash =
      Configuration.build_min_config_hash(superset_hash.configuration,
                                          agent_hash.configuration)
    min_config_str = Configuration.config_hash_to_str(min_config_hash)

    assert_equal(min_config_str.include?(min_expected), true,
                 "Error:\nExpected:\n#{min_expected}\n" \
                 "\nFound:\n#{min_config_str}")
  end
end
