#!/usr/bin/env ruby
#
# October 2015, Glenn F. Matthews
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

require_relative 'basetest'

# Test case for Cisco::Client::GRPC::Client class
class TestGRPC < TestCase
  @@client = nil # rubocop:disable Style/ClassVars

  def client
    unless @@client
      client = Cisco::Client::GRPC.new(address, username, password)
      client.cache_enable = true
      client.cache_auto = true
      @@client = client # rubocop:disable Style/ClassVars
    end
    @@client
  end

  def test_auth_failure
    assert_raises Cisco::Client::AuthenticationFailed do
      Cisco::Client::GRPC.new(address, username, 'wrong password')
    end
  end

  def test_connection_failure
    # Connecting to a port that's listening, but not gRPC is one failure path
    assert_raises Cisco::Client::ConnectionRefused do
      Cisco::Client::GRPC.new('127.0.0.1:22', 'user', 'pass')
    end
    # Connecting to a port that's not listening is a different failure path
    assert_raises Cisco::Client::ConnectionRefused do
      Cisco::Client::GRPC.new('127.0.0.1:0', 'user', 'pass')
    end
  end

  def test_config_string
    client.config("int gi0/0/0/0\ndescription panda\n")
    run = client.show('show run int gi0/0/0/0')
    assert_match(/description panda/, run)
  end

  def test_config_array
    client.config(['int gi0/0/0/0', 'description elephant'])
    run = client.show('show run int gi0/0/0/0')
    assert_match(/description elephant/, run)
  end

  def test_config_invalid
    e = assert_raises Cisco::Client::GRPC::CliError do
      client.config(['int gi0/0/0/0', 'wark', 'bark'])
    end
    # rubocop:disable Style/TrailingWhitespace
    assert_equal('The following commands were rejected:
  wark
  bark
with error:

!! SYNTAX/AUTHORIZATION ERRORS: This configuration failed due to
!! one or more of the following reasons:
!!  - the entered commands do not exist,
!!  - the entered commands have errors in their syntax,
!!  - the software packages containing the commands are not active,
!!  - the current user is not a member of a task-group that has 
!!    permissions to use the commands.

wark
bark

', e.message)
    # rubocop:enable Style/TrailingWhitespace
    # Unlike NXAPI, a gRPC config command is always atomic
    assert_empty(e.successful_input)
    assert_equal(%w(wark bark), e.rejected_input)
  end

  def test_show_ascii_default
    result = client.show('show debug')
    s = @device.cmd('show debug')
    # Strip the leading timestamp and trailing prompt from the telnet output
    s = s.split("\n")[2..-2].join("\n")
    assert_equal(s, result)
  end

  def test_show_ascii_invalid
    assert_raises Cisco::Client::GRPC::CliError do
      client.show('show fuzz')
    end
  end

  def test_show_ascii_incomplete
    assert_raises Cisco::Client::GRPC::CliError do
      client.show('show ')
    end
  end

  def test_show_ascii_explicit
    result = client.show('show debug', :ascii)
    s = @device.cmd('show debug')
    # Strip the leading timestamp and trailing prompt from the telnet output
    s = s.split("\n")[2..-2].join("\n")
    assert_equal(s, result)
  end

  def test_show_ascii_empty
    result = client.show('show debug | include foo | exclude foo', :ascii)
    assert_empty(result)
  end

  def test_show_ascii_cache
    result = client.show('show clock', :ascii)
    sleep 2
    assert_equal(result, client.show('show clock', :ascii))
  end

  # TODO: add structured output test cases (when supported on XR)

  def test_smart_create
    autoclient = Cisco::Client.create(address, username, password)
    assert_equal(Cisco::Client::GRPC, autoclient.class)
    assert(autoclient.supports?(:cli))
    refute(autoclient.supports?(:nxapi_structured))
    assert_equal(:ios_xr, autoclient.platform)
  end
end
