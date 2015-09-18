#!/usr/bin/env ruby
#
# One-stop shop for running all of our current BGP test cases.
# August 2015, Jie Yang
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

require 'rubygems'
gem 'minitest', '>= 2.5.1', '< 5.0.0'
require 'minitest/autorun'

# BGP Feature tests - we keep the tests in logical order
require File.expand_path('../test_router_bgp', __FILE__)
require File.expand_path('../test_bgp_af', __FILE__)
require File.expand_path('../test_bgp_neighbor', __FILE__)
require File.expand_path('../test_bgp_neighbor_af', __FILE__)
