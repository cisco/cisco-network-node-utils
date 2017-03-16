# Cisco folks can insert the appropriate license info here... :)

require_relative 'node_util'

module Cisco
  class SpanSession < NodeUtil
    attr_reader :session_id

    def initialize(session_id)
      validate_args(session_id)
    end

    def self.sessions
      hash = {}
      all = config_get('span_session', 'all_sessions')
      return hash if all.nil?

      all.each do |id|
        id = id.downcase
        hash[id] = SpanSession.new(id)
      end
      hash
    end

    def validate_args(session_id)
      fail TypeError unless session_id.is_a?(Integer)
      fail ArgumentError unless session_id >= 1 || session_id <= 32
      @session_id = session_id.downcase
      set_args_keys
    end

    def create
      config_set('span_session', 'create', @session_id)
    end

    def destroy
      config_set('span_session', 'destroy', @session_id)
    end

    
