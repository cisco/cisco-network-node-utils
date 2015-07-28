#
# NXAPI implementation of __CLASS_NAME__ class
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

require File.join(File.dirname(__FILE__), 'node')

module Cisco

class __CLASS_NAME__

  attr_reader :name

  # Establish connection to node
  @@node = Cisco::Node.instance

  # name: name of the router instance
  # instantiate: true = create router instance
  def initialize(name, instantiate=true)
    raise ArgumentError unless name.length > 0
    @name = name
    create if instantiate
  end

  # Create a hash of all current router instances.
  def __CLASS_NAME__.routers
    instances = @@node.config_get('__RESOURCE_NAME__', 'router')
    return {} if instances.nil?
    hash = {}
    instances.each do |name|
      hash[name] = __CLASS_NAME__.new(name, false)
    end
    return hash
  rescue Cisco::CliError => e
    # cmd will syntax reject when feature is not enabled
    raise unless e.clierror =~ /Syntax error/
    return {}
  end

  def feature_enabled
    feat =  @@node.config_get('__RESOURCE_NAME__', 'feature')
    return (!feat.nil? and !feat.empty?)
  rescue Cisco::CliError => e
    # This cmd will syntax reject if feature is not
    # enabled. Just catch the reject and return false.
    return false if e.clierror =~ /Syntax error/
    raise
  end

  def feature_enable
    @@node.config_set('__RESOURCE_NAME__', 'feature', {:state => ''})
  end

  def feature_disable
    @@node.config_set('__RESOURCE_NAME__', 'feature', {:state => 'no'})
  end

  # Enable feature and create router instance
  def create
    feature_enable unless feature_enabled
    __RESOURCE_NAME___router
  end

  # Destroy a router instance; disable feature on last instance
  def destroy
    ids = @@node.config_get('__RESOURCE_NAME__', 'router')
    return if ids.nil?
    if ids.size == 1
      feature_disable
    else
      __RESOURCE_NAME___router('no')
    end
  rescue Cisco::CliError => e
    # cmd will syntax reject when feature is not enabled
    raise unless e.clierror =~ /Syntax error/
  end

  def __RESOURCE_NAME___router(state='')
    @@node.config_set('__RESOURCE_NAME__', 'router', {:name => @name, :state => state})
  end

  # ----------
  # PROPERTIES
  # ----------

  # Property methods for boolean property
  def default___PROPERTY_BOOL__
    @@node.config_get_default('__RESOURCE_NAME__', '__PROPERTY_BOOL__')
  end

  def __PROPERTY_BOOL__
    state = @@node.config_get('__RESOURCE_NAME__', '__PROPERTY_BOOL__', {:name => @name})
    state ? true : false
  end

  def __PROPERTY_BOOL__=(state)
    state = (state ? '' : 'no')
    @@node.config_set('__RESOURCE_NAME__', '__PROPERTY_BOOL__', {:name => @name, :state => state})
  end

  # Property methods for integer property
  def default___PROPERTY_INT__
    @@node.config_get_default('__RESOURCE_NAME__', '__PROPERTY_INT__')
  end

  def __PROPERTY_INT__
    val = @@node.config_get('__RESOURCE_NAME__', '__PROPERTY_INT__', {:name => @name})
    val.nil? ? default___PROPERTY_INT__ : val.first.to_i
  end

  def __PROPERTY_INT__=(val)
    @@node.config_set('__RESOURCE_NAME__', '__PROPERTY_INT__', {:name => @name, :val => val})
  end

end
end
