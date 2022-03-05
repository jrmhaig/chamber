# frozen_string_literal: true

require 'chamber/namespace_set'
require 'chamber/filters/namespace_filter'
require 'chamber/filters/encryption_filter'
require 'chamber/filters/decryption_filter'
require 'chamber/filters/environment_filter'
require 'chamber/filters/secure_filter'
require 'chamber/filters/translate_secure_keys_filter'
require 'chamber/filters/insecure_filter'
require 'chamber/filters/failed_decryption_filter'
require 'chamber/refinements/enumerable'
require 'chamber/refinements/hash'

###
# Internal: Represents the base settings storage needed for Chamber.
#
module  Chamber
class   Settings
  using ::Chamber::Refinements::Hash

  attr_accessor :decryption_keys,
                :encryption_keys,
                :post_filters,
                :pre_filters,
                :secure_key_prefix
  attr_reader   :namespaces

  # rubocop:disable Metrics/ParameterLists
  def initialize(
                  decryption_keys:   {},
                  encryption_keys:   {},
                  namespaces:        [],
                  pre_filters:       [
                                       Filters::NamespaceFilter,
                                     ],
                  post_filters:      [
                                       Filters::DecryptionFilter,
                                       Filters::EnvironmentFilter,
                                       Filters::FailedDecryptionFilter,
                                       Filters::TranslateSecureKeysFilter,
                                     ],
                  secure_key_prefix: '_secure_',
                  settings:          {},
                  **_args
                )

    ::Chamber::Refinements::Enumerable.deep_validate_keys(settings, &:to_s)

    self.decryption_keys   = decryption_keys
    self.encryption_keys   = encryption_keys
    self.namespaces        = namespaces
    self.post_filters      = post_filters
    self.pre_filters       = pre_filters
    self.raw_data          = settings
    self.secure_key_prefix = secure_key_prefix
  end
  # rubocop:enable Metrics/ParameterLists

  ###
  # Internal: Converts a Settings object into a hash that is compatible as an
  # environment variable hash.
  #
  # Example:
  #
  #   settings = Settings.new settings: {
  #                             my_setting:     'my value',
  #                             my_sub_setting: {
  #                               my_sub_sub_setting_1: 'my sub value 1',
  #                               my_sub_sub_setting_2: 'my sub value 2',
  #                             }
  #   settings.to_environment
  #   # => {
  #     'MY_SETTING'                          => 'my value',
  #     'MY_SUB_SETTING_MY_SUB_SUB_SETTING_1' => 'my sub value 1',
  #     'MY_SUB_SETTING_MY_SUB_SUB_SETTING_2' => 'my sub value 2',
  #   }
  #
  # Returns a Hash sorted alphabetically by the names of the keys
  #
  def to_environment
    to_concatenated_name_hash('_').each_with_object({}) do |pair, env_hash|
      env_hash[pair[0].upcase] = pair[1].to_s
    end
  end

  ###
  # Internal: Converts a Settings object into a String with a format that will
  # work well when working with the shell.
  #
  # Examples:
  #
  #   Settings.new( settings: {
  #                   my_key:       'my value',
  #                   my_other_key: 'my other value',
  #                 } ).to_s
  #   # => 'MY_KEY="my value" MY_OTHER_KEY="my other value"'
  #
  def to_s(hierarchical_separator: '_',
           pair_separator:         ' ',
           value_surrounder:       '"',
           name_value_separator:   '=')
    pairs = to_concatenated_name_hash(hierarchical_separator).to_a.map do |key, value|
      "#{key.upcase}#{name_value_separator}#{value_surrounder}#{value}#{value_surrounder}"
    end

    pairs.join(pair_separator)
  end

  ###
  # Internal: Returns the Settings data as a Hash for easy manipulation.
  # Changes made to the hash will *not* be reflected in the original Settings
  # object.
  #
  # Returns a Hash
  #
  def to_hash
    data.to_hash.dup
  end

  ###
  # Internal: Returns a hash which contains the flattened name hierarchy of the
  # setting as the keys and the values of each setting as the value.
  #
  # Examples:
  #   Settings.new(settings: {
  #                  my_setting: 'value',
  #                  there:      'was not that easy?',
  #                  level_1:    {
  #                    level_2:    {
  #                      some_setting: 'hello',
  #                      another:      'goodbye',
  #                    },
  #                    body:       'gracias',
  #                  },
  #                }).to_flattened_name_hash
  #   # => {
  #     ['my_setting']                         => 'value',
  #     ['there']                              => 'was not that easy?',
  #     ['level_1', 'level_2', 'some_setting'] => 'hello',
  #     ['level_1', 'level_2', 'another']      => 'goodbye',
  #     ['level_1', 'body']                    => 'gracias',
  #   }
  #
  # Returns a Hash
  #
  def to_flattened_name_hash(hash = data, parent_keys = [])
    flattened_name_hash = {}

    hash.each_pair do |key, value|
      flattened_name_components = parent_keys.dup.push(key)

      if value.respond_to?(:each_pair)
        flattened_name_hash.merge! to_flattened_name_hash(value,
                                                          flattened_name_components)
      else
        flattened_name_hash[flattened_name_components] = value
      end
    end

    flattened_name_hash
  end

  def to_concatenated_name_hash(hierarchical_separator = '_')
    concatenated_name_hash = {}

    to_flattened_name_hash.each_pair do |flattened_name, value|
      concatenated_name = flattened_name.join(hierarchical_separator)

      concatenated_name_hash[concatenated_name] = value
    end

    concatenated_name_hash.sort
  end

  ###
  # Internal: Merges a Settings object with another Settings object or
  # a hash-like object.
  #
  # Also, if merging Settings, it will merge all other Settings data as well.
  #
  # Example:
  #
  #   settings        = Settings.new settings: { my_setting:        'my value' }
  #   other_settings  = Settings.new settings: { my_other_setting:  'my other value' }
  #
  #   settings.merge other_settings
  #
  #   settings
  #   # => {
  #     'my_setting'        => 'my value',
  #     'my_other_setting'  => 'my other value',
  #   }
  #
  # Returns a new Settings object
  #
  def merge(other)
    other_settings = case other
                     when Settings
                       other
                     when Hash
                       Settings.new(settings: other)
                     end

    # rubocop:disable Layout/LineLength
    Settings.new(
      encryption_keys: encryption_keys.any? ? encryption_keys : other_settings.encryption_keys,
      decryption_keys: decryption_keys.any? ? decryption_keys : other_settings.decryption_keys,
      namespaces:      (namespaces + other_settings.namespaces),
      settings:        raw_data.deep_merge(other_settings.raw_data),
    )
    # rubocop:enable Layout/LineLength
  end

  ###
  # Internal: Determines whether a Settings is equal to another hash-like
  # object.
  #
  # Returns a Boolean
  #
  def ==(other)
    to_hash == other.to_hash
  end

  ###
  # Internal: Determines whether a Settings is equal to another Settings.
  #
  # Returns a Boolean
  #
  def eql?(other)
    other.is_a?(Chamber::Settings) &&
    data        == other.data &&
    namespaces  == other.namespaces
  end

  def [](key)
    fail ::ArgumentError, 'Bracket access with anything other than a String is unsupported.' unless key.is_a?(::String)

    warn "WARNING: Accessing a non-existent key ('#{key}') with brackets will fail in Chamber 3.0.  See https://github.com/thekompanee/chamber/wiki/Upgrading-To-Chamber-3.0#bracket-access-now-fails-on-non-existent-keys for full details. Called from: '#{caller.to_a.first}'" unless data.has_key?(key) # rubocop:disable Layout/LineLength

    data.[](key)
  end

  def dig!(*args)
    args.inject(data) do |data_value, bracket_value|
      key = bracket_value.is_a?(::Symbol) ? bracket_value.to_s : bracket_value

      data_value.fetch(key)
    end
  end

  def dig(*args)
    dig!(*args)
  rescue ::KeyError, ::IndexError # rubocop:disable Lint/ShadowedException
    nil
  end

  def securable
    Settings.new(**metadata.merge(
                   settings:    raw_data,
                   pre_filters: [Filters::SecureFilter],
                 ))
  end

  def secure
    Settings.new(**metadata.merge(
                   settings:     raw_data,
                   pre_filters:  [Filters::EncryptionFilter],
                   post_filters: [Filters::TranslateSecureKeysFilter],
                 ))
  end

  def insecure
    Settings.new(**metadata.merge(
                   settings:     raw_data,
                   pre_filters:  [Filters::InsecureFilter],
                   post_filters: [Filters::TranslateSecureKeysFilter],
                 ))
  end

  protected

  def raw_data=(new_raw_data)
    @raw_data = new_raw_data.dup
  end

  def namespaces=(raw_namespaces)
    @namespaces = NamespaceSet.new(raw_namespaces)
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def raw_data
    @filtered_raw_data ||= pre_filters.inject(@raw_data) do |filtered_data, filter|
      filter.execute(**{ data: filtered_data }.merge(metadata))
    end
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def data
    @data ||= post_filters.inject(raw_data) do |filtered_data, filter|
      filter.execute(**{ data: filtered_data }.merge(metadata))
    end
  end

  def metadata
    {
      decryption_keys:   decryption_keys,
      encryption_keys:   encryption_keys,
      namespaces:        namespaces,
      secure_key_prefix: secure_key_prefix,
    }
  end
end
end
