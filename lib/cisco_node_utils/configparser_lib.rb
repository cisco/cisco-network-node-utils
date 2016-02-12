# Shared Library to compare configurations.
#
# Copyright (c) 2013-2016 Cisco and/or its affiliates.
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
#
# Current      | Target       | Configuration Case
#  no  command |  no  command | to Match Existing
# ------------------------------------------
#  -      -    |  -      a    |        (no match or trans match)
#  -      -    |  y      a    | no match nor base match
#  -      a    |  -      a    | match
#  -      a    |  y      a    |        (base match)
#  y      a    |  -      a    |        (base match)
#  y      a    |  y      a    | match
#  -      b    |  -      a    | trans match
#  -      b    |  y      a    |        (base match)
#  y      b    |  -      a    |        (base match)
#  y      b    |  y      a    | trans match)

module Cisco
  module ConfigParser
    # Configuration class - helper for dealing with config CLI
    class Configuration
      attr_accessor :configuration

      # Constructor for Configuration
      #
      # @raise [ArgumentError] if config_str is not a String
      # @param config_str [String] to parse
      def initialize(config_str)
        unless config_str.kind_of? String
          fail ArgumentError, 'Argument is not a String.'
        end

        @configuration = {}
        @ordered_keys = []
        @indent = ''
        parse(config_str)
      end # initialize

      # build_min_config_hash
      #
      # Build a config hash of the minimum keys that would be needed to update
      # current config to all of the changes in the "must" config. Each hash key
      # is a configuration command; some keys have subconfigs which must be
      # checked before dismissing top-level keys as present. This method is
      # used primarily by the free-form command_config providers.
      #
      # @param current     [Hash] superset of running-config & must config
      # @param must        [Hash] pending config from recipe, manifest, etc
      # @param min_config  [Hash] in-progress recursion-built minimum config
      # @return min_config [Hash] in-progress recursion-built minimum config
      #
      def self.build_min_config_hash(current, must, min_config={})
        return {} if must.empty? # base case
        must.each do |k, v| # check each must{k} is present in current{}
          if current.key?(k) # if cmd is in current then compare subconfig
            min_config[k] = Configuration.new('')
            min_config[k].configuration =
              build_min_config_hash(current[k].configuration,
                                    v.configuration, {})
            if min_config[k].configuration.empty?
              # no differing subconfigs, so empty hash is returned
              min_config.delete(k)
            end
          else # command NOT in current, apply it + all subcommands
            min_config[k] = v
          end
        end
        min_config
      end # build_min_config_hash

      def self.config_hash_to_str(cmd_hash, str='')
        return '' if cmd_hash.empty?
        cmd_hash.each do |k, v|
          str += k + "\n"
          str += config_hash_to_str(v.configuration, '')
        end
        str
      end # config_hash_to_str

      # Get base command and prefix
      #
      # @param command [String]
      # @return [String, String] containing prefix (if any) and
      #         base command.
      def base_commands(command)
        prefix, base = command.match(/^(no )?(.*)$/).captures
        prefix = '' if prefix.nil?
        [prefix, base]
      end # base_commands

      # Compare ConfigParser::Configuration objects
      #
      # @param config [ConfigParser::Configuration] obj to search
      #        for match.
      # @return [String] containing match, empty if no match found.
      def compare_with(config)
        return nil if config.nil?
        existing = ''
        @ordered_keys.each do |config_line|
          command = config_line.strip
          submode = @configuration[command]
          fail StopIteration, 'Could not find submode.' if submode.nil?

          if special_command?(command)
            # match special exit/end command
            existing << config_line
            break
          elsif config.include_command?(command)
            # match whole command
            existing << config_line
            config_submode = config.submode_config(command)
            existing << submode.compare_with(config_submode)
            next
          end # if

          prefix, base = base_commands(command)
          if prefix != '' && !config.include_command?(base)
            existing << config_line
            next
          end
        end
        existing
      end # compare_with

      # @return [Array] containing command with leading/trailing
      #                 whitespace removed.
      def mode_configuration
        @ordered_keys.collect(&:strip)
      end # mode_configuration

      # Check command [Array] for test command
      #
      # @param command [String] test command
      # @return [Boolean] true if command found, else false
      def include_command?(command)
        commands = mode_configuration
        commands.include?(command)
      end # include_command?

      # Parse each config command line and create a
      # hash of ConfigParser::Configuration objects
      #
      # @param config_str [String] Config command
      def parse(config_str)
        config_str += "\n"
        config_str.gsub!(/^\s*$\n/, '')
        # ignore leading ! or # (comments)
        config_str.gsub!(/^\s*[!#].*$\n/, '')
        if config_str.match(/^ *\t/)
          highlight_str = config_str.gsub(/\t/, '[TAB]')
          fail "Tab character detected in indentation area:\n" + highlight_str
        end
        indent_level = config_str.match(/^\s*/)
        @indent = indent_level.to_s # capture indentation of level
        escaped_indent = Regexp.escape(@indent)
        # Find current configuration mode lines
        @ordered_keys = config_str.scan(/^#{escaped_indent}\S.*\n/)
        @ordered_keys.each do |config_line|
          command = config_line.strip
          escaped_cmd = Regexp.escape(config_line)
          submode_string = config_str.match(
            /^(?:#{escaped_cmd})((?:#{escaped_indent}\s.+\n)*)/).captures.join
          @configuration[command] = Configuration.new(submode_string)
        end
      end # parse

      # Process 'exit' and 'end' commands
      #
      # @param command [String] Configuration command.
      # @return [Boolean] true when command is
      #         'exit' or 'end', else false
      def special_command?(command)
        command =~ /^(?:exit|end)/
      end # special_command?

      # Fetch ConfigParser::Configuration object containing config_line
      #
      # @param config_line [String]
      # @return [ConfigParser::Configuration] containing config_line
      def submode_config(config_line)
        command = config_line.strip
        @configuration[command]
      end # submode_config

      private :base_commands, :parse, :special_command?
    end # Configuration
  end # ConfigParser
end # Cisco
