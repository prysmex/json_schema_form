# frozen_string_literal: true

require 'super_hash'

# base class used for all schema objects inside this gem
# it includes `SuperHash::Hasher` and inherits from  `ActiveSupport::HashWithIndifferentAccess`
# This makes it much por simpler since we do not need to worry about handling strings and symbols

module JSF

  # Use this basic class as ActiveSupport::Cache::MemoryStore is not compatible with complex objects
  # such as Proc
  class SimpleLRUCache
    # @param [Integer] max_size
    def initialize(max_size = 20)
      @max_size = max_size
      clear
    end

    # Write an entry to the cache
    def write(key, value)
      if @store.key?(key)
        @order.delete(key) # Remove existing key to update its position
      elsif @store.size >= @max_size
        lru_key = @order.shift # Evict the least recently used key
        @store.delete(lru_key)
      end

      @store[key] = value
      @order << key # Mark as most recently used
    end

    # Read an entry from the cache
    def read(key)
      return unless @store.key?(key)

      @order.delete(key) # Update usage order
      @order << key
      @store[key]
    end

    # Fetch or store the result of the block
    def fetch(key)
      return read(key) if @store.key?(key)

      value = yield if block_given?
      write(key, value)
      value
    end

    def clear
      @store = {}
      @order = [] # Tracks keys in usage order
    end
  end

  CACHE = SimpleLRUCache.new

  HASH_SUBSCHEMA_KEYS = [
    'additionalProperties',
    'contains',
    '$defs',
    'dependentSchemas',
    'else',
    'if',
    'items',
    'not',
    'properties',
    'then'
  ].freeze

  NONE_SUBSCHEMA_HASH_KEYS_WITH_UNKNOWN_KEYS = [
    'patternProperties'
  ].freeze

  ARRAY_SUBSCHEMA_KEYS = %w[
    allOf
    anyOf
    oneOf
    prefixItems
  ].freeze

  class BaseHash < ActiveSupport::HashWithIndifferentAccess
    include SuperHash::Hasher

    attr_reader :init_options

    # prevent bug when an attribute has a default Proc and the attribute is a string but passed value
    # is a symbol
    #
    # @example
    #   attribute 'allOf', default: ->(data) { [].freeze } # passed data => {allOf: []}
    def initialize(init_value, init_options = {})
      # save init_options so we can pass them on @#dup
      @init_options = init_options

      unless init_value.is_a?(ActiveSupport::HashWithIndifferentAccess)
        init_value&.transform_keys! { |k| convert_key(k) }
      end
      super
    end

    # ensure key is string since the beggining since :SuperHash::Hasher methods are called
    # before ActiveSupport::HashWithIndifferentAccess logic happens.
    #
    # @see []= (super runs after validation and other logic)
    def []=(key, value, **params)
      super(convert_key(key), convert_value(value), **params)
    end

    # ActiveSupport::HashWithIndifferentAccess has its own implementation of dup,
    # which ignores all instance variables. We need that all 'dup' instances are
    # exactaly the same, so we ensure they are initialized the same way the original
    # instance was, mainly by passing init_options and removing keys added by SuperHash attributes API
    #
    # @override
    #
    # @see https://github.com/rails/rails/blob/v6.1.4.1/activesupport/lib/active_support/hash_with_indifferent_access.rb#L254
    #
    def dup
      new_hash = self.class.new(to_hash, init_options)
      set_defaults(new_hash)

      new_hash.each_key do |k|
        new_hash.delete(k) unless key?(k)
      end

      new_hash
    end

    # Commented set_defaults method because it caused SuperHash attributes default values to be added
    # when calling to_hash
    #
    # @override
    #
    # Convert to a regular hash with string keys.
    def to_hash
      new_hash = {}
      # set_defaults(new_hash)

      each do |key, value|
        new_hash[key] = convert_value(value, conversion: :to_hash)
      end

      new_hash
    end

    # Executes a method recursively to object and all its subschemas
    #
    # @param [String, Symbol] method
    # @return [void]
    def send_recursive(method, ...)
      send(method, ...) if respond_to?(method)

      each do |key, value|
        if key == 'additionalProperties'
          next if !value.is_a?(::Hash)

          self[:additionalProperties]&.each_value do |v|
            v.send_recursive(method, ...) if v.respond_to?(:send_recursive)
          end
        elsif key == '$defs'
          self[:$defs]&.each_value do |v|
            v.send_recursive(method, ...) if v.respond_to?(:send_recursive)
          end
        elsif key == 'dependentSchemas'
          self[:dependentSchemas]&.each_value do |v|
            next if !v.is_a?(::Hash)

            v.send_recursive(method, ...) if v.respond_to?(:send_recursive)
          end
        elsif key == 'properties'
          self[:properties]&.each_value do |v|
            v.send_recursive(method, ...) if v.respond_to?(:send_recursive)
          end
        else
          case value
          when ::Array
            next if !ARRAY_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema

            value.each do |v|
              v.send_recursive(method, ...) if v.respond_to?(:send_recursive)
            end
          else
            next if !HASH_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema

            value.send_recursive(method, ...) if value.respond_to?(:send_recursive)
          end
        end
      end
    end

  end
end