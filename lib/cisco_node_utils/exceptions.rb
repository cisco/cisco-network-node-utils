# March 2016, Glenn F. Matthews
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

# Add generic exception classes to the Cisco module
# The hierarchy is:
# RuntimeError
#   Cisco::CiscoError
#     Cisco::ClientError
#       Cisco::ConnectionRefused
#       Cisco::AuthenticationFailed
#     Cisco::RequestFailed
#       Cisco::CliError
#       Cisco::RequestNotSupported
#     Cisco::UnsupportedError
module Cisco
  # Generic class for exceptions raised by this module
  class CiscoError < RuntimeError
    attr_reader :kwargs

    def initialize(message=nil, **kwargs)
      @kwargs = kwargs
      super(message)
    end

    def respond_to?(method_sym, include_private=false)
      @kwargs.key?(method_sym) ? true : super
    end

    def method_missing(method_sym, *args, **kwargs, &block)
      @kwargs.key?(method_sym) ? @kwargs[method_sym] : super
    end
  end

  # Exception class for fundamental client failures
  class ClientError < CiscoError
  end

  # ConnectionRefused means the server isn't listening
  class ConnectionRefused < ClientError
  end

  # AuthenticationFailed means we were able to connect but not login
  class AuthenticationFailed < ClientError
  end

  # Exception class for failures of a specific request to the client
  class RequestFailed < CiscoError
  end

  # Extension of RequestFailed class specifically for CLI errors
  class CliError < RequestFailed
    def initialize(message=nil,
                   clierror:         nil,
                   rejected_input:   nil,
                   successful_input: [],
                   **kwargs)
      unless message
        if rejected_input.is_a?(Array)
          if rejected_input.length > 1
            message = "The following commands were rejected:\n"
            message += "  #{rejected_input.join("\n  ")}\n"
          else
            message = "The command '#{rejected_input.first}' was rejected "
          end
        else
          message = "The command '#{rejected_input}' was rejected "
        end
        message += "with error:\n#{clierror}"
      end
      super(message,
            :clierror => clierror,
            :rejected_input => rejected_input,
            :successful_input => successful_input,
            **kwargs)
    end
  end

  # RequestNotSupported means we made a request that was validly
  # constructed but includes options that are unsupported.
  #
  # An example would be requesting structured output on a CLI command
  # that only supports ASCII output.
  class RequestNotSupported < RequestFailed
  end

  # Exception class raised by CommandReference to indicate that
  # a particular feature/attribute is explicitly excluded on the given node.
  class UnsupportedError < CiscoError
    def initialize(feature, name, oper=nil, msg=nil)
      message = "Feature '#{feature}'"
      message += ", attribute '#{name}'" unless name.nil?
      message += ", operation '#{oper}'" unless oper.nil?
      message += ' is unsupported on this node'
      message += ": #{msg}" unless msg.nil?
      super(message, feature: feature, name: name, oper: oper)
    end
  end
end
