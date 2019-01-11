# SSH client library.
#
# November 2014, Glenn F. Matthews
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

require_relative '../client'
require 'json'

include Cisco::Logger

# Class representing an SSH client connecting to a nx-os device.
class Cisco::Client::SSH < Cisco::Client
  register_client(self)

  # Constructor for Client. This connects to the
  # device via ssh
  def initialize(**kwargs)
    # rubocop:disable Style/HashSyntax
    super(data_formats: [:nxapi_structured, :cli],
          platform:     :nexus,
          **kwargs)
    @verify_host_key = (Gem.loaded_specs['net-ssh'].version < Gem::Version.create('4.2.0')) ? :paranoid : :verify_host_key
    @host = kwargs[:host]
    @username = kwargs[:username]
    @password = kwargs[:password]
    @port = kwargs[:port] || 22
    @timeout = kwargs[:timeout] || 30
  end

  def self.validate_args(**kwargs)
    super
  end

  # Clear the cache of CLI output results.
  #
  # If cache_auto is true (default) then this will be performed automatically
  # whenever a set() is called, but providers may also call this
  # to explicitly force the cache to be cleared.
  def cache_flush
    @cache_hash = {
      'cli_conf'       => {},
      'cli_show'       => {},
      'cli_show_ascii' => {},
    }
  end

  # Configure the given CLI command(s) on the device.
  #
  # @raise [RequestNotSupported] if this client doesn't support CLI config
  #
  # @param data_format one of Cisco::DATA_FORMATS. Default is :cli
  # @param context [String, Array<String>] Zero or more configuration commands
  #   used to enter the desired CLI sub-mode
  # @param values [String, Array<String>] One or more commands
  #   to enter within the CLI sub-mode.
  # @param kwargs data-format-specific args
  def set(data_format: :cli,
          context: nil,
          values: nil,
          **_kwargs)
    # we don't currently support nxapi_structured for configuration
    fail Cisco::RequestNotSupported if data_format == :nxapi_structured
    context = if context
                munge_to_array(context.unshift('conf t'))
              else
                munge_to_array('conf t')
              end
    values = munge_to_array(values)
    super
    req('cli_conf', context + values)
  end

  # Get the given state from the device.
  #
  # Unlike set() this will not clear the CLI cache;
  # multiple calls with the same parameters may return cached data
  # rather than querying the device repeatedly.
  #
  # @raise [Cisco::RequestNotSupported] if
  #   structured output is requested but the given command can't provide it.
  # @raise [Cisco::CliError] if the command is rejected by the device
  #
  # @param data_format one of Cisco::DATA_FORMATS. Default is :cli
  # @param command [String] the show command to execute
  # @param context [String, Array<String>] Context to refine the results
  # @param value [String] Specific key to look up
  # @param kwargs data-format-specific args
  # @return [String, Hash]
  def get(data_format: :cli,
          command:     nil,
          context:     nil,
          value:       nil,
          **_kwargs)
    context = munge_to_array(context)
    super
    if data_format == :cli
      output = req('cli_show_ascii', command)
      return self.class.filter_cli(cli_output: output,
                                   context:    context,
                                   value:      value)
    elsif data_format == :nxapi_structured
      output = req('cli_show', command + ' | json')
      output = JSON.parse(output)
      return self.class.filter_data(data: output,
                                    keys: context + munge_to_array(value))
    else
      fail TypeError
    end
  end

  # Sends a request to the device and returns the output of the request or
  # handles errors that happen.
  # @raise Cisco::ClientError (should never occur)
  # @raise Cisco::RequestNotSupported
  # @raise Cisco::RequestFailed if any command is rejected as invalid
  #
  # @param type ["cli_show", "cli_show_ascii"] Specifies the type of command
  #             to be executed.
  # @param command_or_list [String, Array<String>] The command or array of
  #                        commands which should be run.
  # @return [Hash, Array<Hash>] output when type == "cli_show"
  # @return [String, Array<String>] output when type == "cli_show_ascii"
  def req(type, command_or_list)
    if command_or_list.is_a?(Array)
      command = command_or_list.join(' ; ')
    else
      command = command_or_list
      command_or_list = [command]
    end

    debug("Input (#{type}): \'#{command}\'")
    if cache_enable? && @cache_hash[type] && @cache_hash[type][command]
      return @cache_hash[type][command]
    end

    # send the request and get the response
    debug("Sending SSH request to device at #{@address}")
    response = Net::SSH.start(@host, @username, password: @password, port: @port, timeout: @timeout, @verify_host_key => false) do |connection|
                connection.exec!(command)
               end

    output = parse_response(response)
    output = '' if output.empty?

    @cache_hash[type][command] = output if cache_enable?
    output
  end
  private :req

  def parse_response(response)
    output = response
  end
  private :parse_response
end
