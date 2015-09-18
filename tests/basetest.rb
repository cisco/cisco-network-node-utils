#!/usr/bin/env ruby
#
# Basic unit test case class.
# December 2014, Glenn F. Matthews
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

require 'rubygems'
gem 'minitest', '>= 2.5.1', '< 5.0.0'
require 'minitest/autorun'
require 'net/telnet'
require 'test/unit'
begin
  require 'cisco_nxapi'
rescue LoadError
  require File.expand_path('../../../cisco_nxapi/lib/cisco_nxapi')
end

# TestCase - common base class for all minitest cases in this module.
#   Most node utility tests should inherit from CiscoTestCase instead.
class TestCase < Test::Unit::TestCase
  # rubocop:disable Style/ClassVars
  @@address = nil
  @@username = nil
  @@password = nil
  # rubocop:enable Style/ClassVars

  def process_arguments
    if ARGV.length != 3 && ARGV.length != 4
      puts 'Usage:'
      puts '  ruby test_nxapi.rb [options] -- <address> <username> <password> [debug]'
      exit
    end

    # Record the version of Ruby we got invoked with.
    puts "\nRuby Version - #{RUBY_VERSION}"

    # rubocop:disable Style/ClassVars
    @@address = ARGV[0]
    @@username = ARGV[1]
    @@password = ARGV[2]
    # rubocop:enable Style/ClassVars

    return unless ARGV.length == 4
    if ARGV[3] == 'debug'
      CiscoLogger.debug_enable
    else
      puts "Only 'debug' is allowed"
      exit
    end
  end

  # setup-once params
  def address
    process_arguments unless @@address
    @@address
  end

  def username
    process_arguments unless @@username
    @@username
  end

  def password
    process_arguments unless @@password
    @@password
  end

  def setup
    @device = Net::Telnet.new('Host' => address, 'Timeout' => 240)
    @device.login(username, password)
  rescue Errno::ECONNREFUSED
    puts 'Connection refused - please check that the IP address is correct'
    puts "  and that you have enabled 'feature telnet' on the UUT"
    exit
  end

  def teardown
    @device.close unless @device.nil?
    GC.start
  end

  def test_placeholder
    # needed so that we don't get a "no tests were specified" error
  end
end
