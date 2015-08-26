#
# NXAPI implementation of RouterOspfVrf class
#
# Mike Wiebe, March 2015
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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
require File.join(File.dirname(__FILE__), 'router_ospf')

module Cisco
class RouterOspfVrf
  attr_reader :name, :parent

  OSPF_AUTO_COST = {
    :mbps => "Mbps",
    :gbps => "Gbps",
  }

  OSPF_LOG_ADJACENCY = {
    :none   => "none",
    :log    => "",
    :detail => "detail",
  }

  @@node = Cisco::Node.instance

  def initialize(router, name, instantiate=true)
    raise TypeError if router.nil?
    raise TypeError if name.nil?
    raise ArgumentError unless router.length > 0
    raise ArgumentError unless name.length > 0
    @router = router
    @name = name
    @parent = {}
    @get_args = @set_args = (@name == "default") ?
      { :name => @router } : { :name => @router, :vrf => @name }

    create if instantiate
  end

  # Create a hash of all router ospf vrf instances
  def RouterOspfVrf.vrfs
    hash_final = {}
    RouterOspf.routers.each do |instance|
      name = instance[0]
      vrf_ids = @@node.config_get("ospf", "vrf", { :name => name })
      hash_tmp = { name =>
        { 'default' => RouterOspfVrf.new(name, 'default', false) } }
      unless vrf_ids.nil?
        vrf_ids.each do |vrf|
          hash_tmp[name][vrf] = RouterOspfVrf.new(name, vrf, false)
        end
      end
      hash_final.merge!(hash_tmp)
    end
    hash_final
  end

  # Create one router ospf vrf instance
  def create
    @parent = RouterOspf.new(@router)
    @@node.config_set("ospf", "vrf", { :name  => @router,
                                       :state => "",
                                       :vrf   => @name }) if
                                      @name != "default"
  end

  # Destroy one router ospf vrf instance
  def destroy
    raise RuntimeError if @name == "default"
    @@node.config_set("ospf", "vrf", { :name  => @router,
                                       :state => "no",
                                       :vrf   => @name })
  end

  # Helper method to delete @set_args hash keys
  def set_args_keys_delete(list)
    list.each { |key| @set_args.delete(key) }
  end

  def auto_cost
    match = @@node.config_get("ospf", "auto_cost", @get_args)
    return default_auto_cost if match.nil?
    # Multiple matches are possible but the first match is used.
    # This can be removed when rally defect DE3614 is resolved.
    match[0].last.nil? ?
      [match[0].first.to_i, OSPF_AUTO_COST[:mbps]] :
      [match[0].first.to_i, match[0].last]
  end

  def auto_cost_set(cost, type)
    @set_args[:cost], @set_args[:type] = cost, OSPF_AUTO_COST[type]
    @@node.config_set("ospf", "auto_cost", @set_args)
    set_args_keys_delete([:cost, :type])
  end

  def default_auto_cost
    @@node.config_get_default("ospf", "auto_cost")
  end

  def default_metric
    match = @@node.config_get("ospf", "default_metric", @get_args)
    match.nil? ? default_default_metric : match.first.to_i
  end

  def default_metric=(metric)
    if metric == default_default_metric
      @set_args[:state], @set_args[:metric] = "no", ""
    else
      @set_args[:state], @set_args[:metric] = "", metric
    end
    @@node.config_set("ospf", "default_metric", @set_args)
    set_args_keys_delete([:state, :metric])
  end

  def default_default_metric
    @@node.config_get_default("ospf", "default_metric")
  end

  def log_adjacency
    match = @@node.config_get("ospf", "log_adjacency", @get_args)
    return default_log_adjacency if match.nil?
    # Multiple matches are possible but the first match is used.
    # This can be removed when rally defect DE3614 is resolved.
    match[0].flatten.last.nil? ? :log : :detail
  end

  def log_adjacency=(type)
    case type
    when :none
        @set_args[:state], @set_args[:type] = "no", ""
    when :log, :detail
        @set_args[:state], @set_args[:type] = "", OSPF_LOG_ADJACENCY[type]
    end
    @@node.config_set("ospf", "log_adjacency", @set_args)
    set_args_keys_delete([:state, :type])
  end

  def default_log_adjacency
    @@node.config_get_default("ospf", "log_adjacency")
  end

  def router_id
    match = @@node.config_get("ospf", "router_id", @get_args)
    match.nil? ? default_router_id : match.first
  end

  def router_id=(router_id)
    router_id == default_router_id ?
      (@set_args[:state], @set_args[:router_id] = "no", "") :
      (@set_args[:state], @set_args[:router_id] = "", router_id)

    @@node.config_set("ospf", "router_id", @set_args)
    set_args_keys_delete([:state, :router_id])
  end

  def default_router_id
    @@node.config_get_default("ospf", "router_id")
  end

  def timer_throttle_lsa
    match = @@node.config_get("ospf", "timer_throttle_lsa", @get_args)
    (match.nil? or match.first.nil?) ? default_timer_throttle_lsa :
      match.first.collect(&:to_i)
  end

  def timer_throttle_lsa_start
    start, hold, max = timer_throttle_lsa
    return default_timer_throttle_lsa_start if start.nil?
    start
  end

  def timer_throttle_lsa_hold
    start, hold, max = timer_throttle_lsa
    return default_timer_throttle_lsa_hold if hold.nil?
    hold
  end

  def timer_throttle_lsa_max
    start, hold, max = timer_throttle_lsa
    return default_timer_throttle_lsa_max if max.nil?
    max
  end

  def timer_throttle_lsa_set(start, hold, max)
    @set_args[:start], @set_args[:hold], @set_args[:max] = start, hold, max
    @@node.config_set("ospf", "timer_throttle_lsa", @set_args)
    set_args_keys_delete([:start, :hold, :max])
  end

  def default_timer_throttle_lsa
    [default_timer_throttle_lsa_start,
     default_timer_throttle_lsa_hold,
     default_timer_throttle_lsa_max]
  end

  def default_timer_throttle_lsa_start
    @@node.config_get_default("ospf", "timer_throttle_lsa_start")
  end

  def default_timer_throttle_lsa_hold
    @@node.config_get_default("ospf", "timer_throttle_lsa_hold")
  end

  def default_timer_throttle_lsa_max
    @@node.config_get_default("ospf", "timer_throttle_lsa_max")
  end

  def timer_throttle_spf
    match = @@node.config_get("ospf", "timer_throttle_spf", @get_args)
    (match.nil? or match.first.nil?) ? default_timer_throttle_spf :
      match.first.collect(&:to_i)
  end

  def timer_throttle_spf_start
    start, hold, max = timer_throttle_spf
    return default_timer_throttle_spf_start if start.nil?
    start
  end

  def timer_throttle_spf_hold
    start, hold, max = timer_throttle_spf
    return default_timer_throttle_spf_hold if hold.nil?
    hold
  end

  def timer_throttle_spf_max
    start, hold, max = timer_throttle_spf
    return default_timer_throttle_spf_max if max.nil?
    max
  end

  def timer_throttle_spf_set(start, hold, max)
    @set_args[:start], @set_args[:hold], @set_args[:max] = start, hold, max
    @@node.config_set("ospf", "timer_throttle_spf", @set_args)
    set_args_keys_delete([:start, :hold, :max])
  end

  def default_timer_throttle_spf
    [default_timer_throttle_spf_start,
     default_timer_throttle_spf_hold,
     default_timer_throttle_spf_max]
  end

  def default_timer_throttle_spf_start
    @@node.config_get_default("ospf", "timer_throttle_spf_start")
  end

  def default_timer_throttle_spf_hold
    @@node.config_get_default("ospf", "timer_throttle_spf_hold")
  end

  def default_timer_throttle_spf_max
    @@node.config_get_default("ospf", "timer_throttle_spf_max")
  end
end
end
