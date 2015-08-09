#!/usr/bin/env ruby
#
# One-stop shop for running all of our current test cases.
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

# Basic sanity
require File.expand_path("../test_command_reference", __FILE__)
require File.expand_path("../test_node", __FILE__)
require File.expand_path("../test_node_ext", __FILE__)

# Feature tests - please keep in alphabetical order
require File.expand_path("../test_command_config", __FILE__)
require File.expand_path("../test_interface", __FILE__)
require File.expand_path("../test_interface_ospf", __FILE__)
require File.expand_path("../test_interface_svi", __FILE__)
require File.expand_path("../test_interface_switchport", __FILE__)
require File.expand_path("../test_platform", __FILE__)
require File.expand_path("../test_router_ospf", __FILE__)
require File.expand_path("../test_router_ospf_vrf", __FILE__)
require File.expand_path("../test_snmpcommunity", __FILE__)
require File.expand_path("../test_snmpgroup", __FILE__)
require File.expand_path("../test_snmpserver", __FILE__)
require File.expand_path("../test_snmpuser", __FILE__)
require File.expand_path("../test_tacacs_server", __FILE__)
require File.expand_path("../test_tacacs_server_host", __FILE__)
require File.expand_path("../test_vlan", __FILE__)
require File.expand_path("../test_vtp", __FILE__)
require File.expand_path("../test_yum", __FILE__)
