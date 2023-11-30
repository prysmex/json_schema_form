require 'super_hash'

# base class used for all schema objects inside this gem
# it includes `SuperHash::Hasher` and inherits from  `ActiveSupport::HashWithIndifferentAccess`
# This makes it much por simpler since we do not need to worry about handling strings and symbols

module JSF

  HASH_SUBSCHEMA_KEYS = [
    'additionalProperties',
    'contains',
    'definitions',
    'dependencies',
    'else',
    'if',
    'items',
    'not',
    'properties',
    'then'
  ].freeze

  NONE_SUBSCHEMA_HASH_KEYS_WITH_UNKNOWN_KEYS = [
    'patternProperties'
  ]

  ARRAY_SUBSCHEMA_KEYS = [
    'allOf',
    'anyOf',
    'items',
    'oneOf'
  ].freeze

  class BaseHash < ActiveSupport::HashWithIndifferentAccess
    include SuperHash::Hasher

    attr_reader :init_options
  
    # prevent bug when an attribute has a default Proc and the attribute is a string but passed value
    # is a symbol
    #
    # @example
    #   attribute 'allOf', default: ->(data) { [].freeze } # passed data => {allOf: []}
    def initialize(init_value, init_options={})

      # save init_options so we can pass them on @#dup
      @init_options = init_options

      init_value&.transform_keys!{|k| convert_key(k) } unless init_value.is_a?(ActiveSupport::HashWithIndifferentAccess)
      super(init_value, init_options)
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
      # debugger
      new_hash = self.class.new(self.to_hash, self.init_options).tap do |new_hash|
        set_defaults(new_hash)
      end

      new_hash.each do |k,v|
        new_hash.delete(k) unless self.key?(k)
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
      _new_hash = ::Hash.new
      # set_defaults(_new_hash)

      each do |key, value|
        _new_hash[key] = convert_value(value, conversion: :to_hash)
      end
      _new_hash
    end

    # Executes a method recursively to object and all its subschemas
    #
    # @param [String, Symbol] method
    # @return [void]
    def send_recursive(method, *args, **kwargs, &block)

      send(method, *args, **kwargs, &block) if self.respond_to?(method)

      self.each do |key, value|

        if key == 'additionalProperties'
          next if !value.is_a?(::Hash)
          self[:additionalProperties]&.each do |k,v|
            v.send_recursive(method, *args, **kwargs, &block) if v.respond_to?(:send_recursive)
          end
        elsif key == 'definitions'
          self[:definitions]&.each do |k,v|
            v.send_recursive(method, *args, **kwargs, &block) if v.respond_to?(:send_recursive)
          end
        elsif key == 'dependencies'
          self[:dependencies]&.each do |k,v|
            next if !v.is_a?(::Hash)
            v.send_recursive(method, *args, **kwargs, &block) if v.respond_to?(:send_recursive)
          end
        elsif key == 'properties'
          self[:properties]&.each do |k,v|
            v.send_recursive(method, *args, **kwargs, &block) if v.respond_to?(:send_recursive)
          end
        else
          case value
          when ::Array
            next if !ARRAY_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
            value.each do |v|
              v.send_recursive(method, *args, **kwargs, &block) if v.respond_to?(:send_recursive)
            end
          else
            next if !HASH_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
            value.send_recursive(method, *args, **kwargs, &block) if value.respond_to?(:send_recursive)
          end
        end
      end
    end
  
  end
end