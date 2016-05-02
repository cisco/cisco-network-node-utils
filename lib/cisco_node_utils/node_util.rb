# September 2015, Glenn F. Matthews
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

require_relative 'node'
require_relative 'exceptions'

module Cisco
  # NodeUtil - generic functionality for node utility subclasses to use
  class NodeUtil
    def self.node
      @node ||= Cisco::Node.instance
    end

    def node
      self.class.node
    end

    def self.client
      node.client
    end

    def client
      node.client
    end

    def self.config_get(*args)
      node.config_get(*args)
    rescue Cisco::RequestFailed => e
      e2 = e.class.new("[#{self}] #{e}", **e.kwargs)
      e2.set_backtrace(e.backtrace)
      raise e2
    end

    def config_get(*args)
      node.config_get(*args)
    rescue Cisco::RequestFailed => e
      e2 = e.class.new("[#{self}] #{e}", **e.kwargs)
      e2.set_backtrace(e.backtrace)
      raise e2
    end

    def self.config_get_default(*args)
      node.config_get_default(*args)
    end

    def config_get_default(*args)
      node.config_get_default(*args)
    end

    def self.config_set(*args)
      node.config_set(*args)
    rescue Cisco::RequestFailed => e
      e2 = e.class.new("[#{self}] #{e}", **e.kwargs)
      e2.set_backtrace(e.backtrace)
      raise e2
    end

    def config_set(*args)
      node.config_set(*args)
    rescue Cisco::RequestFailed => e
      e2 = e.class.new("[#{self}] #{e}", **e.kwargs)
      e2.set_backtrace(e.backtrace)
      raise e2
    end

    def self.supports?(api)
      client.supports?(api)
    end

    def supports?(api)
      client.supports?(api)
    end

    def self.platform
      client.platform
    end

    def platform
      client.platform
    end

    def get(**kwargs)
      node.get(**kwargs)
    rescue Cisco::RequestFailed => e
      e2 = e.class.new("[#{self}] #{e}", **e.kwargs)
      e2.set_backtrace(e.backtrace)
      raise e2
    end

    def ios_xr?
      platform == :ios_xr
    end

    def nexus?
      platform == :nexus
    end
  end
end
