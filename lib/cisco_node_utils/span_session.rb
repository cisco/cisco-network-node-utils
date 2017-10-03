# Insert appropriate license here
require_relative 'node_util'
require_relative 'interface'

module Cisco
  # node utils class for SPAN (switchport analyzer) sessions
  class SpanSession < NodeUtil
    attr_reader :session_id

    def initialize(session_id, instantiate=true)
      validate_args(session_id.to_i)
      create if instantiate
    end

    def self.sessions
      hash = {}
      all = config_get('span_session', 'all_sessions')
      return hash if all.nil?

      all.each do |id|
        hash[id] = SpanSession.new(id, false)
      end
      hash
    end

    def validate_args(session_id)
      fail TypeError unless session_id.is_a?(Integer)
      @session_id = session_id
    end

    def create
      config_set('span_session', 'create', id: @session_id)
    end

    def destroy
      config_set('span_session', 'destroy', id: @session_id)
    end

    def description
      config_get('span_session', 'description', id: @session_id)
    end

    def description=(val)
      val = val.to_s
      if val.empty?
        config_set('span_session', 'description', id: @session_id,
                    state: 'no', description: '')
      else
        config_set('span_session', 'description', id: @session_id,
                    state: '', description: val)
      end
    end

    def destination
      config_get('span_session', 'destination', id: @session_id).downcase
    end

    def destination=(int)
      # fail if int is not a valid interface
      fail TypeError unless Interface.interfaces.key?(int.downcase)
      config_set('span_session', 'destination', state: '', id: @session_id,
                 intf_name: int)
    end

    def session_id
      config_get('span_session', 'session_id')
    end

    def session_id=(id)
      fail TypeError unless id.is_a?(Integer)
      config_set('span_session', 'session_id', id: id, state: '')
    end

    def shutdown
      config_get('span_session', 'shutdown', id: @session_id)
    end

    def shutdown=(bool)
      fail TypeError unless bool.is_a?(Boolean)
      config_set('span_session', 'shutdown', id: @session_id, shutdown: bool)
    end

    def source_interfaces
      ints = config_get('span_session', 'source_interfaces', id: @session_id)
      intf = []
      ints.each { |i| intf << i.map(&:downcase) }
      intf
    end

    def source_interfaces=(sources)
      fail TypeError unless sources.is_a?(Hash)
      delta_hash = Utils.delta_add_remove(sources.to_a, source_interfaces.to_a,
                                          :updates_not_allowed)
      return if delta_hash.values.flatten.empty?
      [:remove, :add].each do |action|
        delta_hash[action].each do |name, dir|
          state = (action == :add) ? '' : 'no'
          config_set('span_session', 'source_interfaces', id: @session_id,
                     state: state, int_name: name, direction: dir)
        end
      end
    end

    def default_source_interfaces
      config_get_default('span_session', 'source_interfaces')
    end

    def source_vlans
      v = config_get('span_session', 'source_vlans', id: @session_id)
      v.empty? ? v : [Utils.normalize_range_array(v[0]), v[1]]
    end

    def source_vlans=(sources)
      fail TypeError unless sources.is_a?(Hash)
      is = Utils.dash_range_to_elements(source_vlans[0]) unless
        source_vlans.empty?
      should = Utils.dash_range_to_elements(sources[:vlans])
      direction = sources[:direction]
      delta_hash = Utils.delta_add_remove(should, is)
      [:add, :remove].each do |action|
        delta_hash[action].each do |vlans|
          state = (action == :add) ? '' : 'no'
          config_set('span_session', 'source_vlans',
                     id: @session_id, state: state,
                     vlans: vlans, direction: direction)
        end
      end
    end

    def default_source_vlans
      config_get_default('span_session', 'source_vlans')
    end

    def type
      config_get('span_session', 'type', id: @session_id)
    end

    def type=(str)
      valid_types = ['local', 'rspan', 'erspan-source']
      fail TypeError unless valid_types.include?(str)
      destroy # need to destroy session before changing type
      if str.empty?
        config_set('span_session', 'type', id: @session_id, type: 'local')
      else
        config_set('span_session', 'type', id: @session_id, type: str)
      end
    end
  end # class
end # module
