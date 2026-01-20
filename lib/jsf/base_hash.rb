# frozen_string_literal: true

require 'super_hash'

# base class used for all schema objects inside this gem
# it includes `SuperHash::Hasher` and inherits from  `ActiveSupport::HashWithIndifferentAccess`
# This makes it much por simpler since we do not need to worry about handling strings and symbols

module JSF

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
    include SuperHash::Hasher::IndifferentAccess

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