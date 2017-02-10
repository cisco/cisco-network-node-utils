# March 2016, Glenn F. Matthews
#
# Copyright (c) 2016 Cisco and/or its affiliates.
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

require 'yaml'
require_relative 'logger'

module Cisco
  # Class representing the configuration environment
  class Environment
    @environments = {}
    @default_environment_name = 'default'

    # Autogenerate Cisco::Environment.default_environment_name and
    # Cisco::Environment.default_environment_name= class methods.
    class << self
      attr_accessor :default_environment_name
    end

    # We have three tiers of configuration:
    # 1) default (defined in this file)
    # 2) System-wide gem configuration in /etc/cisco_node_utils.yaml
    # 3) User configuration in ~/cisco_node_utils.yaml

    DEFAULT_ENVIRONMENT = {
      host:     nil, # localhost by default
      port:     nil, # only applicable to gRPC
      username: nil,
      password: nil,
      cookie:   nil, # only applicable to nxapi
    }

    def self.environments
      if @environments.empty?
        @environments = merge_config('/etc/cisco_node_utils.yaml',
                                     @environments)
        @environments = merge_config('~/cisco_node_utils.yaml',
                                     @environments)
        @environments.each do |name, config|
          Cisco::Logger.debug("Environment '#{name}': #{config}")
        end
      end
      @environments
    end

    def self.merge_config(path, current_config)
      data = data_from_file(path)
      data.each do |name, config|
        # in case config is nil:
        config ||= {}
        # in case current_config has no entry for this name:
        current_config[name] ||= DEFAULT_ENVIRONMENT.clone
        # merge it on in!
        current_config[name].merge!(strings_to_symbols(config))
      end
      current_config
    end

    def self.data_from_file(path)
      begin
        path = File.expand_path(path)
      rescue ArgumentError => e
        # Can happen if path includes '~' but $HOME is not defined
        Cisco::Logger.debug "Failed to load #{path}: #{e}"
        return {}
      end
      unless File.file?(path)
        Cisco::Logger.debug "No file found at #{path}"
        return {}
      end
      unless File.readable?(path)
        Cisco::Logger.debug "No permissions to read #{path}"
        return {}
      end
      YAML.load_file(path)
    rescue Psych::SyntaxError => e
      Cisco::Logger.error("Error loading #{path}: #{e}")
      {}
    end

    def self.strings_to_symbols(hash)
      Hash[hash.map { |k, v| [k.to_sym, v] }]
    end

    def self.environment(name=nil)
      name ||= @default_environment_name
      Cisco::Logger.debug("Getting environment '#{name}'")
      environments.fetch(name, DEFAULT_ENVIRONMENT)
    end
  end
end
