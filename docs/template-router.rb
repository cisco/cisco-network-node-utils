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

require_relative 'node_util'

module Cisco
  # X__CLASS_NAME__X - node utility class for X__CLASS_NAME__X config mgmt.
  class X__CLASS_NAME__X < NodeUtil
    attr_reader :name

    # name: name of the router instance
    # instantiate: true = create router instance
    def initialize(name, instantiate=true)
      fail ArgumentError unless name.length > 0
      @name = name
      create if instantiate
    end

    # Create a hash of all current router instances.
    def self.routers
      instances = config_get('X__RESOURCE_NAME__X', 'router')
      return {} if instances.nil?
      hash = {}
      instances.each do |name|
        hash[name] = X__CLASS_NAME__X.new(name, false)
      end
      return hash
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    def feature_enabled
      config_get('X__RESOURCE_NAME__X', 'feature')
    rescue Cisco::CliError => e
      # This cmd will syntax reject if feature is not
      # enabled. Just catch the reject and return false.
      return false if e.clierror =~ /Syntax error/
      raise
    end

    def feature_enable
      config_set('X__RESOURCE_NAME__X', 'feature', state: '')
    end

    def feature_disable
      config_set('X__RESOURCE_NAME__X', 'feature', state: 'no')
    end

    # Enable feature and create router instance
    def create
      feature_enable unless feature_enabled
      X__RESOURCE_NAME__X_router
    end

    # Destroy a router instance; disable feature on last instance
    def destroy
      ids = config_get('X__RESOURCE_NAME__X', 'router')
      return if ids.nil?
      if ids.size == 1
        feature_disable
      else
        X__RESOURCE_NAME__X_router('no')
      end
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
    end

    def X__RESOURCE_NAME__X_router(state='')
      config_set('X__RESOURCE_NAME__X', 'router', name: @name, state: state)
    end

    # ----------
    # PROPERTIES
    # ----------

    # Property methods for boolean property
    def default_X__PROPERTY_BOOL__X
      config_get_default('X__RESOURCE_NAME__X', 'X__PROPERTY_BOOL__X')
    end

    def X__PROPERTY_BOOL__X
      config_get('X__RESOURCE_NAME__X', 'X__PROPERTY_BOOL__X', name: @name)
    end

    def X__PROPERTY_BOOL__X=(state)
      state = (state ? '' : 'no')
      config_set('X__RESOURCE_NAME__X', 'X__PROPERTY_BOOL__X',
                 name: @name, state: state)
    end

    # Property methods for integer property
    def default_X__PROPERTY_INT__X
      config_get_default('X__RESOURCE_NAME__X', 'X__PROPERTY_INT__X')
    end

    def X__PROPERTY_INT__X
      config_get('X__RESOURCE_NAME__X', 'X__PROPERTY_INT__X', name: @name)
    end

    def X__PROPERTY_INT__X=(val)
      config_set('X__RESOURCE_NAME__X', 'X__PROPERTY_INT__X',
                 name: @name, val: val)
    end
  end
end
