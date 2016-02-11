# Cisco node helper class. Abstracts away the details of the underlying
# transport (whether NXAPI or some other future transport) and provides
# various convenient helper methods.
#
# December 2014, Glenn F. Matthews
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

require 'singleton'

require 'cisco_nxapi'
require_relative 'command_reference'

# Add node management classes and APIs to the Cisco namespace.
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
      @clierror = clierror.rstrip if clierror.kind_of? String
      @previous = previous
    end

    def to_s
      "CliError: '#{@command}' rejected with message:\n'#{@clierror}'"
    end
  end

  # class Cisco::Node
  # Singleton representing the network node (switch/router) that is
  # running this code. The singleton is lazily instantiated, meaning that
  # it doesn't exist until some client requests it (with Node.instance())
  class Node
    include Singleton

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
    #                     {name: "green", vrf: "one"})
    def config_get(feature, name, *args)
      fail 'lazy_connect specified but did not request connect' unless @cmd_ref
      ref = @cmd_ref.lookup(feature, name)

      return ref.default_value if ref.default_only?

      begin
        token = ref.config_get_token(*args)
      rescue IndexError
        # IndexError: no entry for config_get_token
        token = nil
      end
      if token.nil?
        # Just get the whole output
        return massage(show(ref.config_get, :structured), ref)
      elsif token[0].kind_of?(Regexp)
        return massage(Cisco.find_ascii(show(ref.config_get, :ascii),
                                        token[-1],
                                        *token[0..-2]), ref)
      else
        return massage(
          config_get_handle_structured(token,
                                       show(ref.config_get, :structured)),
          ref)
      end
    end

    # Attempt to massage the given value into the format specified by the
    # given CmdRef object.
    def massage(value, ref)
      CiscoLogger.debug "Massaging '#{value}' (#{value.inspect})"
      if value.is_a?(Array) && !ref.multiple
        fail "Expected zero/one value but got '#{value}'" if value.length > 1
        value = value[0]
      end
      if (value.nil? || value.empty?) && ref.default_value? && ref.auto_default
        CiscoLogger.debug "Default: #{ref.default_value}"
        return ref.default_value
      end
      return value unless ref.kind
      case ref.kind
      when :boolean
        if value.nil? || value.empty?
          value = false
        elsif /^no / =~ value
          value = false
        else
          value = true
        end
      when :int
        value = value.to_i unless value.nil?
      when :string
        value = '' if value.nil?
        value = value.to_s.strip
      end
      CiscoLogger.debug "Massaged to '#{value}'"
      value
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
      fail 'lazy_connect specified but did not request connect' unless @cmd_ref
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
      fail 'lazy_connect specified but did not request connect' unless @cmd_ref
      ref = @cmd_ref.lookup(feature, name)
      config(ref.config_set(*args))
    end

    # Clear the cache of CLI output results.
    #
    # If cache_auto is true (default) then this will be performed automatically
    # whenever a config_set() is called, but providers may also call this
    # to explicitly force the cache to be cleared.
    def cache_flush
      @client.cache_flush
    end

    # Here and below are implementation details and private APIs that most
    # providers shouldn't need to know about or use.

    attr_reader :cmd_ref, :client

    # For unit testing - we won't know the node connection info at load time.
    @lazy_connect = false

    class << self
      attr_reader :lazy_connect
    end

    class << self
      attr_writer :lazy_connect
    end

    def initialize
      @client = nil
      @cmd_ref = nil
      connect unless self.class.lazy_connect
    end

    def to_s
      @client.to_s
    end

    # "hidden" API - used for UT but shouldn't be used elsewhere
    def connect(*args)
      @client = CiscoNxapi::NxapiClient.new(*args)
      # Hard-code platform and cli for now
      @cmd_ref = CommandReference.new(product:  product_id,
                                      platform: :nexus,
                                      cli:      true)
      cache_flush
    end

    # TODO: remove me
    def reload
      @client.reload
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

    # Helper method for config_get().
    # @param token [Array, Hash] lookup sequence
    # @param result [Array, Hash] structured output from node
    def config_get_handle_structured(token, result)
      token.each do |t|
        # if token is a hash and result is an array, check each
        # array index (which should return another hash) to see if
        # it contains the matching key/value pairs specified in token,
        # and return the first match (or nil)
        if t.kind_of?(Hash)
          fail "Expected array, got #{result.class}" unless result.is_a? Array
          result = result.select { |x| t.all? { |k, v| x[k] == v } }
          fail "Multiple matches found for #{t}" if result.length > 1
          fail "No match found for #{t}" if result.length == 0
          result = result[0]
        else # result is array or hash
          fail "No key \"#{t}\" in #{result}" if result[t].nil?
          result = result[t]
        end
      end
      result
    rescue RuntimeError
      # TODO: logging user story, Syslog isn't available here
      # Syslog.debug(e.message)
      nil
    end

    # Send a config command to the device.
    # In general, clients should use config_set() rather than calling
    # this function directly.
    #
    # @raise [Cisco::CliError] if any command is rejected by the device.
    def config(commands)
      CiscoLogger.debug("CLI Sent to device: #{commands}")
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
      o = config_get('show_version', 'header')
      fail 'failed to retrieve operating system information' if o.nil?
      o.split("\n")[0]
    end

    # @return [String] such as "6.0(2)U5(1) [build 6.0(2)U5(0.941)]"
    def os_version
      config_get('show_version', 'version')
    end

    # @return [String] such as "Nexus 3048 Chassis"
    def product_description
      config_get('show_version', 'description')
    end

    # @return [String] such as "N3K-C3048TP-1GE"
    def product_id
      if @cmd_ref
        return config_get('inventory', 'productid')
      else
        # We use this function to *find* the appropriate CommandReference
        entries = show('show inventory', :structured)
        return entries['TABLE_inv']['ROW_inv'][0]['productid']
      end
    end

    # @return [String] such as "V01"
    def product_version_id
      config_get('inventory', 'versionid')
    end

    # @return [String] such as "FOC1722R0ET"
    def product_serial_number
      config_get('inventory', 'serialnum')
    end

    # @return [String] such as "bxb-oa-n3k-7"
    def host_name
      config_get('show_version', 'host_name')
    end

    # @return [String] such as "example.com"
    def domain_name
      config_get('dnsclient', 'domain_name')
    end

    # @return [Integer] System uptime, in seconds
    def system_uptime
      cache_flush
      t = config_get('show_system', 'uptime')
      fail 'failed to retrieve system uptime' if t.nil?
      # time units: t = ["0", "23", "15", "49"]
      t.map!(&:to_i)
      d, h, m, s = t
      (s + 60 * (m + 60 * (h + 24 * (d))))
    end

    # @return [String] timestamp of last reset time
    def last_reset_time
      config_get('show_version', 'last_reset_time')
    end

    # @return [String] such as "Reset Requested by CLI command reload"
    def last_reset_reason
      config_get('show_version', 'last_reset_reason')
    end

    # @return [Float] combined user/kernel CPU utilization
    def system_cpu_utilization
      output = config_get('system', 'resources')
      fail 'failed to retrieve cpu utilization' if output.nil?
      output['cpu_state_user'].to_f + output['cpu_state_kernel'].to_f
    end

    # @return [String] such as
    #   "bootflash:///n3000-uk9-kickstart.6.0.2.U5.0.941.bin"
    def boot
      config_get('show_version', 'boot_image')
    end

    # @return [String] such as
    #   "bootflash:///n3000-uk9.6.0.2.U5.0.941.bin"
    def system
      config_get('show_version', 'system_image')
    end
  end

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
    return nil if body.nil? || regex_query.nil?

    # get subconfig
    parent_cfg.each { |p| body = find_subconfig(body, p) }
    if body.nil? || body.empty?
      return nil
    else
      # find matches and return as array of String if it only does one
      # match in the regex. Otherwise return array of array
      match = body.split("\n").map { |s| s.scan(regex_query) }
      match = match.flatten(1)
      return nil if match.empty?
      match = match.flatten if match[0].is_a?(Array) && match[0].length == 1
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
    return nil if body.nil? || regex_query.nil?

    rows = body.split("\n")
    match_row_index = rows.index { |row| regex_query =~ row }
    return nil if match_row_index.nil?

    cur = match_row_index + 1
    subconfig = []

    until (/\A\s+.*/ =~ rows[cur]).nil? || cur == rows.length
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
