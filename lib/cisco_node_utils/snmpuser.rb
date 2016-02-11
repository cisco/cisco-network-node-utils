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

require_relative 'node_util'

module Cisco
  # SnmpUser - node utility class for SNMP user configuration management
  class SnmpUser < NodeUtil
    def initialize(name, groups, authproto, authpass, privproto,
                   privpass, localizedkey, engineid, instantiate=true)
      initialize_validator(name, groups, authproto, authpass, privproto,
                           privpass, engineid, instantiate)
      @name = name
      @engine_id = engineid

      @authproto = authproto
      @privproto = privproto
      @groups_arr = groups

      authprotostr = _auth_sym_to_str(authproto)
      privprotostr = _priv_sym_to_str(privproto)

      return unless instantiate
      # Config string syntax:
      # [no] snmp-server user <user> [group] ...
      #      [auth {md5|sha} <passwd1>
      #       [priv [aes-128] <passwd2>] [localizedkey] [engineID <id>]
      #      ]
      # Assume if multiple groups, apply all config to each
      groups = [''] if groups.empty?
      groups.each do |group|
        config_set('snmp_user', 'user', '',
                   name,
                   group,
                   authpass.empty? ? '' : "auth #{authprotostr} #{authpass}",
                   privpass.empty? ? '' : "priv #{privprotostr} #{privpass}",
                   localizedkey ? 'localizedkey' : '',
                   engineid.empty? ? '' : "engineID #{engineid}")
      end
    end

    def initialize_validator(name, groups, authproto, authpass, privproto,
                             privpass, engineid, instantiate)
      fail TypeError unless name.is_a?(String) &&
                            groups.is_a?(Array) &&
                            authproto.is_a?(Symbol) &&
                            authpass.is_a?(String) &&
                            privproto.is_a?(Symbol) &&
                            privpass.is_a?(String) &&
                            engineid.is_a?(String)
      fail ArgumentError if name.empty?
      # empty password but protocol provided = bad
      # non-empty password and no protocol provided = bad
      if authpass.empty?
        fail ArgumentError if [:sha, :md5].include?(authproto) && instantiate
      else
        fail ArgumentError unless [:sha, :md5].include?(authproto)
      end
      if privpass.empty?
        fail ArgumentError if [:des, :aes128].include?(privproto) && instantiate
      else
        fail ArgumentError unless [:des, :aes128].include?(privproto)
      end
    end

    def self.users
      users_hash = {}
      # config_get returns hash if 1 user, array if multiple, nil if none
      users = config_get('snmp_user', 'user')
      return users_hash if users.nil?
      users.each do |user|
        # n7k has enforcepriv, use-ipv*acl, avoid them
        next if user[/(enforcePriv|use-ipv4acl|use-ipv6acl)/]
        user_var_hash = _get_snmp_user_parse(user)
        name = user_var_hash[:name]
        engineid = user_var_hash[:engineid]
        if engineid.empty?
          index = name
        else
          index = name + ' ' + engineid
        end
        auth = user_var_hash[:auth]
        priv = user_var_hash[:priv]
        groups_arr = []
        # take care of multiple groups here
        # if the name already exists in hash
        # get all the previous properties
        if users_hash.key?(index)
          groups_arr = users_hash[index].groups
          auth = users_hash[index].auth_protocol
          priv = users_hash[index].priv_protocol
        end

        # add the group to the array
        groups_arr << _get_group_arr(user_var_hash)
        users_hash[index] = SnmpUser.new(name, groups_arr.flatten, auth,
                                         '', priv, '', false,
                                         engineid,
                                         false)
      end
      users_hash
    end

    def destroy
      # The parser doesn't care what the real value is but need to come to the
      # end of the parser chain. Hence we just pass in some fake values for
      # auth method and password
      unless auth_password.nil? || auth_password.empty?
        auth_str = "auth #{_auth_sym_to_str(auth_protocol)} #{auth_password}"
        local_str = 'localizedkey'
      end
      unless priv_password.nil? || priv_password.empty?
        priv_str = "priv #{_priv_sym_to_str(priv_protocol)} #{priv_password}"
      end
      config_set('snmp_user', 'user', 'no',
                 @name, '', auth_str, priv_str, local_str,
                 @engine_id.empty? ? '' : "engineID #{@engine_id}")
      SnmpUser.users.delete(@name + ' ' + @engine_id)
    end

    attr_reader :name

    def groups
      @groups_arr
    end

    def self.default_groups
      [config_get_default('snmp_user', 'group')]
    end

    def auth_protocol
      @authproto
    end

    def self.default_auth_protocol
      _auth_str_to_sym(config_get_default('snmp_user', 'auth_protocol'))
    end

    def self.default_auth_password
      config_get_default('snmp_user', 'auth_password')
    end

    def self.auth_password(name, engine_id)
      if engine_id.empty?
        users = config_get('snmp_user', 'auth_password')
        return nil if users.nil? || users.empty?
        users.each_entry { |user| return user[1] if user[0] == name }
      else
        users = config_get('snmp_user', 'auth_password_with_engine_id')
        return nil if users.nil? || users.empty?
        users.each_entry do |user|
          return user[1] if user[0] == name && user[2] == engine_id
        end
      end
      nil
    end

    def auth_password
      SnmpUser.auth_password(@name, @engine_id)
    end

    def priv_protocol
      @privproto
    end

    def self.priv_password(name, engine_id)
      if engine_id.empty?
        users = config_get('snmp_user', 'priv_password')
        unless users.nil? || users.empty?
          users.each_entry { |user| return user[1] if user[0] == name }
        end
      else
        users = config_get('snmp_user', 'priv_password_with_engine_id')
        unless users.nil? || users.empty?
          users.each_entry do |user|
            return user[1] if user[0] == name && user[2] == engine_id
          end
        end
      end
      nil
    end

    def priv_password
      SnmpUser.priv_password(@name, @engine_id)
    end

    def self.default_priv_protocol
      _priv_str_to_sym(config_get_default('snmp_user', 'priv_protocol'))
    end

    def self.default_priv_password
      config_get_default('snmp_user', 'priv_password')
    end

    attr_reader :engine_id

    def self.default_engine_id
      config_get_default('snmp_user', 'engine_id')
    end

    # Passwords are hashed and so cannot be retrieved directly, but can be
    # checked for equality. This is done by creating a fake user with the
    # password and then comparing the hashes
    def auth_password_equal?(input_pw, is_localized=false)
      input_pw = input_pw.to_s unless input_pw.is_a?(String)
      # If we provide no password, and no password present, it's a match!
      return true if input_pw.empty? && auth_protocol == :none
      # If we provide no password, but a password is present, or vice versa...
      return false if input_pw.empty? || auth_protocol == :none
      # OK, we have an input password, and a password is configured
      current_pw = auth_password
      if current_pw.nil?
        fail "SNMP user #{@name} #{@engine_id} has auth #{auth_protocol} " \
             "but no password?\n" + @@node.show('show run snmp all')
      end

      if is_localized
        # In this case, the password is already hashed.
        hashed_pw = input_pw
      else
        # In this case passed in password is clear text while the running
        # config is hashed value. We need to hash the passed in clear text.

        # Create dummy user
        config_set('snmp_user', 'user', '', 'dummy_user', '',
                   "auth #{_auth_sym_to_str(auth_protocol)} #{input_pw}",
                   '', '',
                   @engine_id.empty? ? '' : "engineID #{@engine_id}")

        # Retrieve password hashes
        hashed_pw = SnmpUser.auth_password('dummy_user', @engine_id)
        if hashed_pw.nil?
          fail "SNMP dummy user #{dummy_user} #{@engine_id} was configured " \
               "but password is missing?\n" + @@node.show('show run snmp all')
        end

        # Delete dummy user
        config_set('snmp_user', 'user', 'no', 'dummy_user', '',
                   "auth #{_auth_sym_to_str(auth_protocol)} #{hashed_pw}",
                   '', 'localizedkey',
                   @engine_id.empty? ? '' : "engineID #{@engine_id}")
      end
      hashed_pw == current_pw
    end

    # Passwords are hashed and so cannot be retrieved directly, but can be
    # checked for equality. This is done by creating a fake user with the
    # password and then comparing the hashes
    def priv_password_equal?(input_pw, is_localized=false)
      input_pw = input_pw.to_s unless input_pw.is_a?(String)
      # If no input password, and no password present, true!
      return true if input_pw.empty? && priv_protocol == :none
      # Otherwise, if either one is missing, false!
      return false if input_pw.empty? || priv_protocol == :none
      # Otherwise, we have both input and configured passwords to compare
      current_pw = priv_password
      if current_pw.nil?
        fail "SNMP user #{@name} #{@engine_id} has priv #{priv_protocol} " \
             "but no password?\n" + @@node.show('show run snmp all')
      end

      if is_localized
        # In this case, the password is already hashed.
        hashed_pw = input_pw
      else
        # In this case passed in password is clear text while the running
        # config is hashed value. We need to hash the passed in clear text.

        # Create dummy user
        config_set('snmp_user', 'user', '', 'dummy_user', '',
                   "auth #{_auth_sym_to_str(auth_protocol)} #{input_pw}",
                   "priv #{_priv_sym_to_str(priv_protocol)} #{input_pw}",
                   '',
                   @engine_id.empty? ? '' : "engineID #{@engine_id}")

        # Retrieve password hashes
        dummyau = SnmpUser.auth_password('dummy_user', @engine_id)
        hashed_pw = SnmpUser.priv_password('dummy_user', @engine_id)
        if hashed_pw.nil?
          fail "SNMP dummy user #{dummy_user} #{@engine_id} was configured " \
               "but password is missing?\n" + @@node.show('show run snmp all')
        end

        # Delete dummy user
        config_set('snmp_user', 'user', 'no', 'dummy_user', '',
                   "auth #{_auth_sym_to_str(auth_protocol)} #{dummyau}",
                   "priv #{_priv_sym_to_str(priv_protocol)} #{hashed_pw}",
                   'localizedkey',
                   @engine_id.empty? ? '' : "engineID #{@engine_id}")
      end
      hashed_pw == current_pw
    end

    private

    def self._get_snmp_user_parse(user)
      user_var = {}
      lparams = user.split
      name = lparams[0]
      engineid_index = lparams.index('engineID')
      auth_index = lparams.index('auth')
      priv_index = lparams.index('priv')
      # engineID always comes after engineid_index
      engineid = engineid_index.nil? ? '' : lparams[engineid_index + 1]
      # authproto always comes after auth_index
      aut = auth_index.nil? ? '' : lparams[auth_index + 1]
      # privproto always comes after priv_index if priv exists
      pri = priv_index.nil? ? '' : lparams[priv_index + 1]
      # for the empty priv protocol default
      pri = 'des' unless pri.empty? || pri == 'aes-128'
      auth = _auth_str_to_sym(aut)
      priv = _priv_str_to_sym(pri)
      user_var[:name] = name
      user_var[:engineid] = engineid
      user_var[:auth] = auth
      user_var[:priv] = priv
      user_var[:auth_index] = auth_index
      user_var[:engineid_index] = engineid_index
      # group may or may not exist but it is always after name
      # lparams[1] can be group, it is not known here,
      # but will be determined in the _get_group_arr method
      user_var[:group] = lparams[1]
      user_var
    end

    def self._get_group_arr(user_var_hash)
      user_groups = []
      auth_index = user_var_hash[:auth_index]
      engineid_index = user_var_hash[:engineid_index]
      # after the name it can be group or auth or engineID
      # so filter it properly
      user_groups << user_var_hash[:group] unless auth_index == 1 ||
                                                  engineid_index == 1
      user_groups
    end

    def _auth_sym_to_str(sym)
      case sym
      when :sha
        return 'sha'
      when :md5
        return 'md5'
      else
        return ''
      end
    end

    def _priv_sym_to_str(sym)
      case sym
      when :des
        return '' # no protocol specified defaults to DES
      when :aes128
        return 'aes-128'
      else
        return ''
      end
    end

    def _auth_str_to_sym(str)
      SnmpUser._auth_str_to_sym(str)
    end

    # must be class method b/c it's used by default methods
    def self._auth_str_to_sym(str)
      case str
      when /sha/i
        return :sha
      when /md5/i
        return :md5
      else
        return :none
      end
    end

    def _priv_str_to_sym(str)
      SnmpUser._priv_str_to_sym(str)
    end

    def self._priv_str_to_sym(str)
      case str
      when /des/i
        return :des
      when /aes/i
        return :aes128
      else
        return :none
      end
    end
  end
end
