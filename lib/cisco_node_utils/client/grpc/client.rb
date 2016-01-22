#!/usr/bin/env ruby
#
# October 2015, Glenn F. Matthews
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
require 'grpc'
require 'json'
require_relative 'ems_services'
require_relative 'client_errors'

include IOSXRExtensibleManagabilityService
include Cisco::Logger

# Client implementation using gRPC API for IOS XR
class Cisco::Client::GRPC < Cisco::Client
  register_client(self)

  attr_accessor :timeout

  def initialize(address, username, password)
    # TODO: remove if/when we have a local socket to use
    if address.nil? && ENV['NODE']
      address ||= ENV['NODE'].split(' ')[0]
      username ||= ENV['NODE'].split(' ')[1]
      password ||= ENV['NODE'].split(' ')[2]
    end
    super(address:      address,
          username:     username,
          password:     password,
          data_formats: [:cli],
          platform:     :ios_xr)
    @config = GRPCConfigOper::Stub.new(address, :this_channel_is_insecure)
    @exec = GRPCExec::Stub.new(address, :this_channel_is_insecure)

    # Make sure we can actually connect
    @timeout = 5
    begin
      get(command: 'show clock')
    rescue ::GRPC::BadStatus => e
      if e.code == ::GRPC::Core::StatusCodes::DEADLINE_EXCEEDED
        raise Cisco::Client::ConnectionRefused, e.details
      end
      raise
    end

    # Let commands in general take up to 2 minutes
    @timeout = 120
  end

  def validate_args(address, username, password)
    super
    fail TypeError, 'address must be specified' if address.nil?
    fail ArgumentError, 'port # required in address' unless address[/:/]
    # Connection to remote system - username and password are required
    fail TypeError, 'username must be specified' if username.nil?
    fail TypeError, 'password must be specified' if password.nil?
  end

  def cache_flush
    @cache_hash = {
      'cli_config'           => {},
      'show_cmd_text_output' => {},
      'show_cmd_json_output' => {},
    }
  end

  # Configure the given CLI command(s) on the device.
  #
  # @raise [RequestNotSupported] if this client doesn't support CLI config
  #
  # @param data_format one of Cisco::DATA_FORMATS. Default is :cli
  # @param context [Array<String>] Zero or more configuration commands used
  #                to enter the desired CLI sub-mode
  # @param values [Array<String>] One or more commands to enter within the
  #   CLI sub-mode.
  def set(data_format: :cli,
          context:     nil,
          values:      nil)
    context = munge_to_array(context)
    values = munge_to_array(values)
    super
    # IOS XR lets us concatenate submode commands together.
    # This makes it possible to guarantee we are in the correct context:
    #   context: ['foo', 'bar'], values: ['baz', 'bat']
    #   ---> values: ['foo bar baz', 'foo bar bat']
    # However, there's a special case for 'no' commands:
    #   context: ['foo', 'bar'], values: ['no baz']
    #   ---> values: ['no foo bar baz'] ---- the 'no' goes at the start
    context = context.join(' ')
    unless context.empty?
      values.map! do |cmd|
        match = cmd[/^\s*no\s+(.*)/, 1]
        if match
          cmd = "no #{context} #{match}"
        else
          cmd = "#{context} #{cmd}"
        end
        cmd
      end
    end
    # CliConfigArgs wants a newline-separated string of commands
    args = CliConfigArgs.new(cli: values.join("\n"))
    req(@config, 'cli_config', args)
  end

  def get(data_format: :cli,
          command:     nil,
          context:     nil,
          value:       nil)
    super
    fail ArgumentError if command.nil?
    args = ShowCmdArgs.new(cli: command)
    output = req(@exec, 'show_cmd_text_output', args)
    self.class.filter_cli(cli_output: output, context: context, value: value)
  end

  def req(stub, type, args)
    if cache_enable? && @cache_hash[type] && @cache_hash[type][args.cli]
      return @cache_hash[type][args.cli]
    end

    debug "Sending '#{type}' request:"
    if args.is_a?(ShowCmdArgs) || args.is_a?(CliConfigArgs)
      debug "  with cli: '#{args.cli}'"
    end
    response = stub.send(type, args,
                         timeout:  @timeout,
                         username: @username,
                         password: @password)
    output = ''
    # gRPC server may split the response into multiples
    response = response.is_a?(Enumerator) ? response.to_a : [response]
    debug "Got responses: #{response.map(&:class).join(', ')}"
    # Check for errors first
    handle_errors(args, response.select { |r| !r.errors.empty? })

    # If we got here, no errors occurred
    output = handle_response(args, response)

    @cache_hash[type][args.cli] = output if cache_enable? && !output.empty?
    return output
  rescue ::GRPC::BadStatus => e
    case e.code
    when ::GRPC::Core::StatusCodes::UNAVAILABLE
      raise Cisco::Client::ConnectionRefused, e.details
    when ::GRPC::Core::StatusCodes::UNAUTHENTICATED
      raise Cisco::Client::AuthenticationFailed, e.details
    else
      raise
    end
  end

  def handle_response(args, replies)
    klass = replies[0].class
    unless replies.all? { |r| r.class == klass }
      fail Cisco::Client::ClientError, 'reply class inconsistent: ' +
        replies.map(&:class).join(', ')
    end
    debug "Handling #{replies.length} '#{klass}' reply(s):"
    case klass.to_s
    when /ShowCmdTextReply/
      replies.each { |r| debug "  output:\n#{r.output}" }
      output = replies.map(&:output).join('')
      output = handle_text_output(args, output)
    when /ShowCmdJSONReply/
      # TODO: not yet supported by server to test against
      replies.each { |r| debug "  jsonoutput:\n#{r.jsonoutput}" }
      output = replies.map(&:jsonoutput).join("\n---\n")
    when /CliConfigReply/
      # nothing to process
      output = ''
    else
      fail Cisco::Client::ClientError, "unsupported reply class #{klass}"
    end
    debug "Success with output:\n#{output}"
    output
  end

  def handle_text_output(args, output)
    # For a successful show command, gRPC presents the output as:
    # \n--------- <cmd> ----------
    # \n<output of command>
    # \n\n

    # For an invalid CLI, gRPC presents the output as:
    # \n--------- <cmd> --------
    # \n<cmd>
    # \n<error output>
    # \n\n

    # Discard the leading whitespace, header, and trailing whitespace
    output = output.split("\n").drop(2)
    return '' if output.nil? || output.empty?

    # Now we have either [<output_line_1>, <output_line_2>, ...] or
    # [<cmd>, <error_line_1>, <error_line_2>, ...]
    if output[0].strip == args.cli.strip
      fail CliError.new(output.join("\n"), args.cli)
    end
    output.join("\n")
  end

  def handle_errors(args, error_responses)
    return if error_responses.empty?
    debug "#{error_responses.length} response(s) had errors:"
    error_responses.each { |r| debug "  error:\n#{r.errors}" }
    first_error = error_responses.first.errors
    # Conveniently for us, all *Reply protobufs in EMS have an errors field
    # Less conveniently, some are JSON and some are not.
    begin
      msg = JSON.parse(first_error)
      handle_json_error(msg)
    rescue JSON::ParserError
      handle_text_error(args, first_error)
    end
  end

  # Generate an error from a failed request
  def handle_text_error(args, msg)
    if /^Disallowed commands:/ =~ msg
      fail Cisco::Client::RequestNotSupported, msg
    else
      fail CliError.new(msg, args.cli)
    end
  end

  # Generate a CliError from a failed CliConfigReply
  def handle_json_error(msg)
    # {
    #   "cisco-grpc:errors": {
    #   "error": [
    #     {
    #       "error-type": "application",
    #       "error-tag": "operation-failed",
    #       "error-severity": "error",
    #       "error-message": "....",
    #     },
    #     {
    #       ...

    # {
    #   "cisco-grpc:errors": [
    #     {
    #       "error-type": "protocol",
    #       "error-message": "Failed authentication"
    #     }
    #   ]
    # }

    msg = msg['cisco-grpc:errors']
    msg = msg['error'] unless msg.is_a?(Array)
    msg.each do |m|
      type = m['error-type']
      message = m['error-message']
      if type == 'protocol' && message == 'Failed authentication'
        fail Cisco::Client::AuthenticationFailed, message
      elsif type == 'application'
        # Example message:
        # !! SYNTAX/AUTHORIZATION ERRORS: This configuration failed due to
        # !! one or more of the following reasons:
        # !!  - the entered commands do not exist,
        # !!  - the entered commands have errors in their syntax,
        # !!  - the software packages containing the commands are not active,
        # !!  - the current user is not a member of a task-group that has
        # !!    permissions to use the commands.
        #
        # foo
        # bar
        #
        match = /\n\n(.*)\n\n\Z/m.match(message)
        if match.nil?
          rejected = '(unknown, see error message)'
        else
          rejected = match[1].split("\n")
        end
        fail CliError.new(message, rejected)
      else
        fail Cisco::Client::ClientError, message
      end
    end
  end
end
