#!/usr/bin/env ruby
#
# Basic unit test case class.
# December 2014, Glenn F. Matthews
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

# Minitest needs to have this path in order to discover our logging plugin
$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start do
  # Don't calculate coverage of our test code itself!
  add_filter '/tests/'
end

require 'rubygems'
gem 'minitest', '~> 5.0'
require 'minitest/autorun'
require 'net/telnet'
require_relative '../lib/cisco_node_utils/client'
require_relative '../lib/cisco_node_utils/command_reference'
require_relative '../lib/cisco_node_utils/logger'

# rubocop:disable Style/ClassVars
# We *want* the address/username/password class variables to be shared
# with all child classes, so that we only need to initialize them once.

# TestCase - common base class for all minitest cases in this module.
#   Most node utility tests should inherit from CiscoTestCase instead.
class TestCase < Minitest::Test
  # These variables can be set in one of three ways:
  # 1) ARGV:
  #   $ ruby basetest.rb -- address[:port] username password
  # 2) NODE environment variable
  #   $ export NODE="address[:port] username password"
  #   $ rake test
  # 3) At run time:
  #   $ rake test
  #   Enter address or hostname of node under test:
  @@address = nil
  @@username = nil
  @@password = nil

  def self.address
    @@address ||= ARGV[0]
    @@address ||= ENV['NODE'].split(' ')[0] if ENV['NODE']
    unless @@address
      print 'Enter address or hostname of node under test: '
      @@address = gets.chomp
    end
    @@address
  end

  def address
    self.class.address
  end

  def self.username
    @@username ||= ARGV[1]
    @@username ||= ENV['NODE'].split(' ')[1] if ENV['NODE']
    unless @@username
      print 'Enter username for node under test:           '
      @@username = gets.chomp
    end
    @@username
  end

  def username
    self.class.username
  end

  def self.password
    @@password ||= ARGV[2]
    @@password ||= ENV['NODE'].split(' ')[2] if ENV['NODE']
    unless @@password
      print 'Enter password for node under test:           '
      @@password = gets.chomp
    end
    @@password
  end

  def password
    self.class.password
  end

  def setup
    @device = Net::Telnet.new('Host'    => address.split(':')[0],
                              'Timeout' => 240,
                              # NX-OS has a space after '#', IOS XR does not
                              'Prompt'  => /[$%#>] *\z/n,
                             )
    begin
      @device.login('Name'        => username,
                    'Password'    => password,
                    # NX-OS uses 'login:' while IOS XR uses 'Username:'
                    'LoginPrompt' => /(?:[Ll]ogin|[Uu]sername)[: ]*\z/n,
                   )
    rescue Errno::ECONNRESET
      @device.close
      # TODO
      puts 'Connection reset by peer? Try again'
      sleep 1
      @device = Net::Telnet.new('Host'    => address.split(':')[0],
                                'Timeout' => 240,
                                # NX-OS has a space after '#', IOS XR does not
                                'Prompt'  => /[$%#>] *\z/n,
                               )
      @device.login('Name'        => username,
                    'Password'    => password,
                    # NX-OS uses 'login:' while IOS XR uses 'Username:'
                    'LoginPrompt' => /(?:[Ll]ogin|[Uu]sername)[: ]*\z/n,
                   )
    end
    @device.cmd('term len 0')
  rescue Errno::ECONNREFUSED
    puts 'Telnet login refused - please check that the IP address is correct'
    puts "  and that you have configured 'feature telnet' (NX-OS) or "
    puts "  'telnet ipv4 server...' (IOS XR) on the UUT"
    exit
  end

  def teardown
    @device.close unless @device.nil?
    @device = nil
  end

  def config(*args)
    # Send the entire config as one string but be sure not to return until
    # we are safely back out of config mode, i.e. prompt is
    # 'switch#' not 'switch(config)#' or 'switch(config-if)#' etc.
    @device.cmd('String' => "configure terminal\n" + args.join("\n") + "\nend",
                # NX-OS has a space after '#', IOS XR does not
                'Match'  => /^[^()]+[$%#>] *\z/n)
  rescue Net::ReadTimeout => e
    raise "Timeout when configuring:\n#{args.join("\n")}\n\n#{e}"
  end

  def assert_show_match(pattern: nil, command: nil, msg: nil)
    pattern ||= @default_output_pattern
    refute_nil(pattern)
    pattern = Cisco::Client.to_regexp(pattern)
    command ||= @default_show_command
    refute_nil(command)

    output = @device.cmd(command)
    msg = message(msg) do
      "Expected #{mu_pp pattern} to match " \
      "output of '#{mu_pp command}':\n#{output}"
    end
    assert pattern =~ output, msg
    pattern.match(output)
  end

  def refute_show_match(pattern: nil, command: nil, msg: nil)
    pattern ||= @default_output_pattern
    refute_nil(pattern)
    pattern = Cisco::Client.to_regexp(pattern)
    command ||= @default_show_command
    refute_nil(command)

    output = @device.cmd(command)
    msg = message(msg) do
      "Expected #{mu_pp pattern} to NOT match " \
      "output of '#{mu_pp command}':\n#{output}"
    end
    refute pattern =~ output, msg
  end
end
# rubocop:enable Style/ClassVars
