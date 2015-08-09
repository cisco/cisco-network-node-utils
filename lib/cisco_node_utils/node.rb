# Cisco node helper class. Abstracts away the details of the underlying
# transport (whether NXAPI or some other future transport) and provides
# various convenient helper methods.
#
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

require 'singleton'

require 'cisco_nxapi'
require File.join(File.dirname(__FILE__), 'command_reference')

module Cisco
  # Error class raised by the config_set and config_get APIs if the
  # device encounters an issue trying to act on the requested CLI.
  #
  # command - the specific CLI that was rejected
  # clierror - any error string from the device
  class CliError < RuntimeError
    attr_reader :command, :clierror, :previous
    def initialize(command, clierror, previous)
      @command = command
      @clierror = clierror
      @previous = previous
    end

    def message
      "CliError: '#{@command}' rejected with message:\n'#{@clierror}'"
    end
  end

  # class Cisco::Node
  # Singleton representing the network node (switch/router) that is
  # running this code. The singleton is lazily instantiated, meaning that
  # it doesn't exist until some client requests it (with Node.instance())

  class Node
    include Singleton

    # BEGIN NODE API
    # This is most of what a client/provider should need to code against.
    # Actual implementations of these methods are later in this file.

    # Convenience wrapper for show(command, :structured).
    # Uses CommandReference to look up the given show command and key
    # of interest, executes that command, and returns the value corresponding
    # to that key.
    #
    # @raise [IndexError] if the given (feature, name) pair is not in the
    #        CommandReference data or if the data doesn't have values defined
    #        for the 'config_get' and 'config_get_token' fields.
    # @raise [Cisco::CliError] if the given command is rejected by the device.
    #
    # @param feature [String]
    # @param name [String]
    # @return [String]
    # @example config_get("show_version", "system_image")
    def config_get(feature, name)
    end

    # Uses CommandReference to lookup the default value for a given
    # feature and feature property.
    #
    # @raise [IndexError] if the given (feature, name) pair is not in the
    #        CommandReference data or if the data doesn't have values defined
    #        for the 'default_value' field.
    # @param feature [String]
    # @param name [String]
    # @return [String]
    # @example config_get_default("vtp", "file")
    def config_get_default(feature, name)
    end

    # Uses CommandReference to look up the given config command(s) of interest
    # and then applies the configuration.
    #
    # @raise [IndexError] if no relevant cmd_ref config_set exists
    # @raise [ArgumentError] if too many or too few args are provided.
    # @raise [Cisco::CliError] if any command is rejected by the device.
    #
    # @param feature [String]
    # @param name [String]
    # @param args [*String] zero or more args to be substituted into the cmdref.
    # @example config_set("vtp", "domain", "example.com")
    def config_set(feature, name, *args)
    end

    # Clear the cache of CLI output results.
    #
    # If cache_auto is true (default) then this will be performed automatically
    # whenever a config_set() is called, but providers may also call this
    # to explicitly force the cache to be cleared.
    def cache_flush
    end

    # END NODE API
    # Here and below are implementation details and private APIs that most
    # providers shouldn't need to know about or use.

    attr_reader :cmd_ref, :client

    # For unit testing - we won't know the node connection info at load time.
    @@lazy_connect = false

    def Node.lazy_connect=(val)
      @@lazy_connect = val
    end

    def initialize
      @client = nil
      @cmd_ref = nil
      connect unless @@lazy_connect
    end

    def to_s
      @client.to_s
    end

    # "hidden" API - used for UT but shouldn't be used elsewhere
    def connect(*args)
      @client = CiscoNxapi::NxapiClient.new(*args)
      @cmd_ref = CommandReference::CommandReference.new(product_id)
      cache_flush
    end

    # TODO: remove me
    def reload
      @client.reload
    end

    # hidden as well
    attr_reader :client

    def cache_flush
      @client.cache_flush
    end

    def cache_enable?
      @client.cache_enable?
    end

    def cache_enable=(enable)
      @client.cache_enable = enable
    end

    def cache_auto?
      @client.cache_auto?
    end

    def cache_auto=(enable)
      @client.cache_auto = enable
    end

    # Helper method for converting token strings to regexps. This helper
    # facilitates non-standard regexp options like ignore-case.
    # Example inputs:
    #  token = ["/%s/i", "/%s foo %s/", "/zzz/i"]
    #  args = ["LoopBack2", "no", "bar"]
    # Expected outputs:
    #         [/LoopBack2/i, /no foo bar/, /zzz/i]
    #
    def token_str_to_regexp(token, args)
      unless args[0].is_a? Hash
        expected_args = token.join.scan(/%/).length
        raise "Given #{args.length} args, but token #{token} requires " +
          "#{expected_args}" unless args.length == expected_args
      end
      # replace all %s with *args
      token.map! { |str| sprintf(str, *args.shift(str.scan(/%/).length)) }
      # convert all to Regexp objects
      token.map! { |str|
        if str[-2..-1] == '/i'
          Regexp.new(str[1..-3], Regexp::IGNORECASE)
        else
          Regexp.new(str[1..-2])
        end
      }
      token
    end

    # Helper method to replace <> place holders in the config_get_token
    # and config_get_token_append yaml entries.
    #
    # @param regexp [String][Array] regexp entry with <> placeholders
    # @param values [Hash] Hash of named values to replace each <>
    # @return [String]
    def replace_token_ids(regexp, values)
      final = replace_token_ids_string(regexp, values) if regexp.is_a?(String)
      final = replace_token_ids_array(regexp, values) if regexp.is_a?(Array)
      final
    end

    # @param regexp [String] regexp entry with <> placeholders
    # @param values [Hash] Hash of named values to replace each <>
    # @return [String]
    def replace_token_ids_string(regexp, values)
      replace = regexp.scan(/<(\S+)>/).flatten.map(&:to_sym)
      replace.each do |item|
        regexp = regexp.sub "<#{item}>",
          values[item].to_s if values.key?(item)
      end
      # Only return lines that actually replaced ids or did not have any
      # ids to replace. Implicit nil returned if not.
      return regexp if /<\S+>/.match(regexp).nil?
    end

    # @param regexp [Array] regexp entry with <> placeholders
    # @param values [Hash] Hash of named values to replace each <>
    # @return [String]
    def replace_token_ids_array(regexp, values)
      final_regexp = []
      regexp.each do |line|
        final_regexp.push(replace_token_ids_string(line, values))
      end
      final_regexp
    end

    # Helper method to build a multi-line config_get_token if
    # the feature, name contains a config_get_token_append entry.
    #
    # @param feature [String]
    # @param ref [CommandReference::CmdRef]
    # @return [String, Array]
    def build_config_get_token(feature, ref, args)
      raise "lazy_connect specified but did not request connect" unless @cmd_ref
      # Why clone token? A bug in some ruby versions caused token to convert
      # to type Regexp unexpectedly. The clone hard copy resolved it.

      # If the options are presented as type Hash process as
      # key-value replacement pairs
      return ref.config_get_token.clone unless args[0].is_a?(Hash)
      options = args[0]
      token = []
      # Use _template yaml entry if config_get_token_append
      if ref.to_s[/config_get_token_append/]
        # Get yaml feature template:
        template = @cmd_ref.lookup(feature, "_template")
        # Process config_get_token: from template:
        token.push(replace_token_ids(template.config_get_token, options))
        # Process config_get_token_append sequence: from template:
        template.config_get_token_append.each do |line|
          token.push(replace_token_ids(line, options))
        end
        # Add feature->property config_get_token append line
        token.push(ref.config_get_token_append)
      else
        token.push(replace_token_ids(ref.config_get_token, options))
      end
      token.flatten!
      token.compact!
      token
    end

    # Helper method to use the feature, name config_get
    # if present else use feature, "template" config_get
    #
    # @param feature [String]
    # @param ref [CommandReference::CmdRef]
    # @param type [Symbol]
    # @return [String, Array]
    def build_config_get(feature, ref, type)
      raise "lazy_connect specified but did not request connect" unless @cmd_ref
      # Use feature name config_get string if present
      # else use feature template: config_get
      if ref.hash.key?("config_get")
        return show(ref.config_get, type)
      else
        template = @cmd_ref.lookup(feature, "_template")
        return show(template.config_get, type)
      end
    end

    # Helper method to build a multi-line config_set if
    # the feature, name contains a config_get_set_append
    # yaml entry.
    #
    # @param feature [String]
    # @param ref [CommandReference::CmdRef]
    # @return [String, Array]
    def build_config_set(feature, ref, args)
      raise "lazy_connect specified but did not request connect" unless @cmd_ref
      # If the options are presented as type Hash process as
      # key-value replacement pairs
      return ref.config_set unless args[0].is_a?(Hash)
      options = args[0]
      config_set = []
      # Use _template yaml entry if config_set_append
      if ref.to_s[/config_set_append/]
        # Get yaml feature template:
        template = @cmd_ref.lookup(feature, "_template")
        # Process config_set: from template:
        config_set.push(replace_token_ids(template.config_set, options))
        # Process config_set_append sequence: from template:
        template.config_set_append.each do |line|
          config_set.push(replace_token_ids(line, options))
        end
        # Add feature->property config_set append line
        config_set.push(replace_token_ids(ref.config_set_append, options))
      else
        config_set.push(replace_token_ids(ref.config_set, options))
      end
      config_set.flatten!
      config_set.compact!
      config_set
    end

    # Convenience wrapper for show(command, :structured).
    # Uses CommandReference to look up the given show command and key
    # of interest, executes that command, and returns the value corresponding
    # to that key.
    #
    # @raise [IndexError] if the given (feature, name) pair is not in the
    #        CommandReference data or if the data doesn't have values defined
    #        for the 'config_get' and (optional) 'config_get_token' fields.
    # @raise [Cisco::CliError] if the given command is rejected by the device.
    #
    # @param feature [String]
    # @param name [String]
    # @return [String, Hash, Array]
    # @example config_get("show_version", "system_image")
    # @example config_get("ospf", "router_id",
    #                      {:name => "green", :vrf => "one"})
    def config_get(feature, name, *args)
      raise "lazy_connect specified but did not request connect" unless @cmd_ref
      ref = @cmd_ref.lookup(feature, name)

      begin
        token = build_config_get_token(feature, ref, args)
      rescue IndexError, TypeError
        # IndexError if value is not set, TypeError if set to nil explicitly
        token = nil
      end
      if token.kind_of?(String) and token[0] == '/' and token[-1] == '/'
        raise RuntimeError unless args.length == token.scan(/%/).length
        # convert string to regexp and replace %s with args
        token = Regexp.new(sprintf(token, *args)[1..-2])
        text = build_config_get(feature, ref, :ascii)
        return Cisco.find_ascii(text, token)
      elsif token.kind_of?(String)
        hash = build_config_get(feature, ref, :structured)
        return hash[token]

      elsif token.kind_of?(Array)
        # Array of /regexps/ -> ascii, array of strings/ints -> structured
        if token[0].kind_of?(String) and
           token[0][0] == '/' and
           (token[0][-1] == '/' or token[0][-2..-1] == '/i')

          token = token_str_to_regexp(token, args)
          text = build_config_get(feature, ref, :ascii)
          return Cisco.find_ascii(text, token[-1], *token[0..-2])

        else
          result = build_config_get(feature, ref, :structured)
          begin
            token.each do |token|
              # if token is a hash and result is an array, check each
              # array index (which should return another hash) to see if
              # it contains the matching key/value pairs specified in token,
              # and return the first match (or nil)
              if token.kind_of?(Hash)
                raise "Expected array, got #{result.class}" unless result.kind_of?(Array)
                result = result.select { |x| token.all? { |k, v| x[k] == v } }
                raise "Multiple matches found for #{token}" if result.length > 1
                raise "No match found for #{token}" if result.length == 0
                result = result[0]
              else # result is array or hash
                raise "No key \"#{token}\" in #{result}" if result[token].nil?
                result = result[token]
              end
            end
            return result
          rescue Exception => e
            # TODO: logging user story, Syslog isn't available here
            # Syslog.debug(e.message)
            return nil
          end
        end
      elsif token.nil?
        return show(ref.config_get, :structured)
      end
      raise TypeError("Unclear to handle config_get_token #{token}")
    end

    # Uses CommandReference to lookup the default value for a given
    # feature and feature property.
    #
    # @raise [IndexError] if the given (feature, name) pair is not in the
    #        CommandReference data or if the data doesn't have values defined
    #        for the 'default_value' field.
    # @param feature [String]
    # @param name [String]
    # @return [String]
    # @example config_get_default("vtp", "file")
    def config_get_default(feature, name)
      raise "lazy_connect specified but did not request connect" unless @cmd_ref
      ref = @cmd_ref.lookup(feature, name)
      ref.default_value
    end

    # Uses CommandReference to look up the given config command(s) of interest
    # and then applies the configuration.
    #
    # @raise [IndexError] if no relevant cmd_ref config_set exists
    # @raise [ArgumentError] if too many or too few args are provided.
    # @raise [Cisco::CliError] if any command is rejected by the device.
    #
    # @param feature [String]
    # @param name [String]
    # @param args [*String] zero or more args to be substituted into the cmdref.
    # @example config_set("vtp", "domain", "example.com")
    # @example config_set("ospf", "router_id",
    #  {:name => "green", :vrf => "one", :state => "",
    #   :router_id => "192.0.0.1"})
    def config_set(feature, name, *args)
      raise "lazy_connect specified but did not request connect" unless @cmd_ref
      ref = @cmd_ref.lookup(feature, name)
      config_set = build_config_set(feature, ref, args)
      if config_set.is_a?(String)
        param_count = config_set.scan(/%/).length
      elsif config_set.is_a?(Array)
        param_count = config_set.join(" ").scan(/%/).length
      else
        raise TypeError, "%{config_set.class} not supported for config_set"
      end
      unless args[0].is_a? Hash
        if param_count != args.length
          raise ArgumentError.new("Wrong number of params - expected: " +
                                "#{param_count} actual: #{args.length}")
        end
      end
      if config_set.is_a?(String)
        config(sprintf(config_set, *args))
      elsif config_set.is_a?(Array)
        new_config_set = []
        config_set.each do |line|
          param_count = line.scan(/%/).length
          if param_count > 0
            new_config_set << sprintf(line, *args)
            args = args[param_count..-1]
          else
            new_config_set << line
          end
        end
        config(new_config_set)
      end
    end

    # Send a config command to the device.
    # In general, clients should use config_set() rather than calling
    # this function directly.
    #
    # @raise [Cisco::CliError] if any command is rejected by the device.
    def config(commands)
      @client.config(commands)
    rescue CiscoNxapi::CliError => e
      raise Cisco::CliError.new(e.input, e.clierror, e.previous)
    end

    # Send a show command to the device.
    # In general, clients should use config_get() rather than calling
    # this function directly.
    #
    # @raise [Cisco::CliError] if any command is rejected by the device.
    def show(command, type=:ascii)
      @client.show(command, type)
    rescue CiscoNxapi::CliError => e
      raise Cisco::CliError.new(e.input, e.clierror, e.previous)
    end

    # @return [String] such as "Cisco Nexus Operating System (NX-OS) Software"
    def os
       o = config_get("show_version", "header")
       raise "failed to retrieve operating system information" if o.nil?
       o.split("\n")[0]
    end

    # @return [String] such as "6.0(2)U5(1) [build 6.0(2)U5(0.941)]"
    def os_version
      config_get("show_version", "version")
    end

    # @return [String] such as "Nexus 3048 Chassis"
    def product_description
      config_get("show_version", "description")
    end

    # @return [String] such as "N3K-C3048TP-1GE"
    def product_id
      if @cmd_ref
        return config_get("inventory", "productid")
      else
        # We use this function to *find* the appropriate CommandReference
        entries = show("show inventory", :structured)
        return entries["TABLE_inv"]["ROW_inv"][0]["productid"]
      end
    end

    # @return [String] such as "V01"
    def product_version_id
      config_get("inventory", "versionid")
    end

    # @return [String] such as "FOC1722R0ET"
    def product_serial_number
      config_get("inventory", "serialnum")
    end

    # @return [String] such as "bxb-oa-n3k-7"
    def host_name
      config_get("show_version", "host_name")
    end

    # @return [String] such as "example.com"
    def domain_name
      result = config_get("domain_name", "domain_name")
      if result.nil?
        return ""
      else
        return result[0]
      end
    end

    # @return [Integer] System uptime, in seconds
    def system_uptime
      cache_flush
      t = config_get("show_system", "uptime")
      raise "failed to retrieve system uptime" if t.nil?
      t = t.shift
      # time units: t = ["0", "23", "15", "49"]
      t.map!(&:to_i)
      d, h, m, s = t
      (s + 60 * (m + 60 * (h + 24 * (d))))
    end

    # @return [String] timestamp of last reset time
    def last_reset_time
      output = config_get("show_version", "last_reset_time")
      return "" if output.nil?
      # NX-OS may provide leading/trailing whitespace:
      # " Sat Oct 25 00:39:25 2014\n"
      # so be sure to strip() it down to the actual string.
      output.strip
    end

    # @return [String] such as "Reset Requested by CLI command reload"
    def last_reset_reason
      config_get("show_version", "last_reset_reason")
    end

    # @return [Float] combined user/kernel CPU utilization
    def system_cpu_utilization
      output = config_get("system", "resources")
      raise "failed to retrieve cpu utilization" if output.nil?
      output["cpu_state_user"].to_f + output["cpu_state_kernel"].to_f
    end

    # @return [String] such as
    #   "bootflash:///n3000-uk9-kickstart.6.0.2.U5.0.941.bin"
    def boot
      config_get("show_version", "boot_image")
    end

    # @return [String] such as
    #   "bootflash:///n3000-uk9.6.0.2.U5.0.941.bin"
    def system
      config_get("show_version", "system_image")
    end
  end

  # Convenience wrapper for find_ascii. Operates under the assumption
  # that there will be zero or one matches for the given query
  # and returns the match string (or "") rather than an array.
  #
  # @raise [RuntimeError] if more than one match is found.
  #
  # @param body [String] The body of text to search
  # @param regex_query [Regex] The regular expression to match
  # @param parents [*Regex] zero or more regular expressions defining
  #                the parent configs to filter by.
  # @return [String] the matching (sub)string or "" if no match.
  #
  # @example Get the domain name if any
  #   domain_name = find_one_ascii(running_cfg, "ip domain-name (.*)")
  #   => 'example.com'
  def find_one_ascii(body, regex_query, *parent_cfg)
    matches = find_ascii(body, regex_query, *parent_cfg)
    return "" if matches.nil?
    raise RuntimeError if matches.length > 1
    matches[0]
  end
  module_function :find_one_ascii

  # Method for working with hierarchical show command output such as
  # "show running-config". Searches the given multi-line string
  # for all matches to the given regex_query. If parents is provided,
  # the matches will be filtered to only those that are located "under"
  # the given parent sequence (as determined by indentation).
  #
  # @param body [String] The body of text to search
  # @param regex_query [Regex] The regular expression to match
  # @param parents [*Regex] zero or more regular expressions defining
  #                the parent configs to filter by.
  # @return [[String], nil] array of matching (sub)strings, else nil.
  #
  # @example Find all OSPF router names in the running-config
  #   ospf_names = find_ascii(running_cfg, /^router ospf (\d+)/)
  #
  # @example Find all address-family types under the given BGP router
  #   bgp_afs = find_ascii(show_run_bgp, /^address-family (.*)/,
  #                        /^router bgp #{ASN}/)
  def find_ascii(body, regex_query, *parent_cfg)
    return nil if body.nil? or regex_query.nil?

    # get subconfig
    parent_cfg.each { |p| body = find_subconfig(body, p) }
    if body.nil?
      return nil
    else
      # find matches and return as array of String if it only does one
      # match in the regex. Otherwise return array of array
      match = body.split("\n").map { |s| s.scan(regex_query) }
      match = match.flatten(1)
      return nil if match.empty?
      match = match.flatten if match[0].is_a?(Array) and match[0].length == 1
      return match
    end
  end
  module_function :find_ascii

  # Returns the subsection associated with the given
  # line of config
  # @param [String] the body of text to search
  # @param [Regex] the regex key of the config for which
  # to retrieve the subsection
  # @return [String, nil] the subsection of body, de-indented
  # appropriately, or nil if no such subsection exists.
  def find_subconfig(body, regex_query)
    return nil if body.nil? or regex_query.nil?

    rows = body.split("\n")
    match_row_index = rows.index { |row| regex_query =~ row }
    return nil if match_row_index.nil?

    cur = match_row_index+1
    subconfig = []

    until (/\A\s+.*/ =~ rows[cur]).nil? or cur == rows.length
      subconfig << rows[cur]
      cur += 1
    end
    return nil if subconfig.empty?
    # Strip an appropriate minimal amount of leading whitespace from
    # all lines in the subconfig
    min_leading = subconfig.map { |line| line[/\A */].size }.min
    subconfig = subconfig.map { |line| line[min_leading..-1] }
    subconfig.join("\n")
  end
  module_function :find_subconfig
end
