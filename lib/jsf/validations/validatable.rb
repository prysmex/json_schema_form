module JSF
  module Validations

    # Adds the ability to recursively build an errors hash by calling `errors`.
    # Each encountered subschema should respond to `errors`.
    #
    # requirements:
    #
    # - `JSF::Core::Schemable`
    # - `JSF::Core::Buildable`

    module Validatable

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

      # @note
      # Override this method to implement own errors,
      # always call super to support:
      #
      # - recursive errors
      # - ensuring errors is a ActiveSupport::HashWithIndifferentAccess
      #
      # @todo implement
      #
      # @example 
      # schema.errors(
      #   recursive: true,
      #   if: [(instance, key)->{ false }]
      # )
      #
      # @param [Proc] if
      # @param [Proc] unless
      # @param [Proc] if_subschema
      # @param [Proc] unless_subschema
      # @param [Boolean] recursive if true, calls errors for all subschemas
      # @param passthru [Hash{Symbol => *}] options to be passed
      # @return [ActiveSupport::HashWithIndifferentAccess]
      def errors(recursive: true, **passthru)
        passthru[:recursive] = recursive
        return ActiveSupport::HashWithIndifferentAccess.new({}) unless recursive

        subschemas_errors(**passthru)
      end
      
      private
      
      # Builds errors hash for all subschemas. It support two keys to
      # filter which subschemas' errors will be called
      #
      # @param [Proc] if
      # @param [Proc] unless
      # @param [Proc] if_subschema
      # @param [Proc] unless_subschema
      # @param passthru [Hash{Symbol => *}] options to be passed
      # @return [ActiveSupport::HashWithIndifferentAccess]
      def subschemas_errors(**passthru)

        acum_subschemas_errors = {}
        # continue recurrsion for all subschema keys
        self.each do |key, value|

          # skip conditionally based on passed proc
          next if passthru.key?(:if_subschema) && !passthru[:if_subschema].call(schema_instance, key)
          next if passthru[:unless_subschema]&.call(schema_instance, validation_key)

          if key == 'additionalProperties'
            next if !value.is_a?(::Hash)
            self[:additionalProperties]&.each do |k,v|
              bury_subschema_errors(v, acum_subschemas_errors, passthru)
            end
          elsif key == 'definitions'
            self[:definitions]&.each do |k,v|
              bury_subschema_errors(v, acum_subschemas_errors, passthru)
            end
          elsif key == 'dependencies'
            self[:dependencies]&.each do |k,v|
              next if !v.is_a?(::Hash)
              bury_subschema_errors(v, acum_subschemas_errors, passthru)
            end
          elsif key == 'properties'
            self[:properties]&.each do |k,v|
              bury_subschema_errors(v, acum_subschemas_errors, passthru)
            end
          else
            case value
            when ::Array
              next if !ARRAY_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
              value.each do |v|
                bury_subschema_errors(v, acum_subschemas_errors, passthru)
              end
            else
              next if !HASH_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
              bury_subschema_errors(value, acum_subschemas_errors, passthru)
            end
          end
        end

        ActiveSupport::HashWithIndifferentAccess.new(acum_subschemas_errors)
      end

      # Wrapper method, used only to DRY code
      #
      # - prevent adding respond_to? for each call
      # - buries subschema errors
      #
      # @return [void]
      def bury_subschema_errors(subschema, acum_subschemas_errors, passthru)
        return unless subschema.respond_to?(:errors)

        subschema_errors = subschema.errors(**passthru)
        return if subschema_errors.empty?

        relative_path = subschema.meta[:path].slice((self.meta[:path].size)..-1)
        
        # create path if it does not exists
        if acum_subschemas_errors.dig(*relative_path).nil?
          SuperHash::Utils.bury(acum_subschemas_errors, *relative_path, {})
        end

        # merge new errors
        acum_subschemas_errors.dig(*relative_path).merge!(subschema_errors)
      end
      
      # Utility to safely add an error on a nested path
      #
      # @param [Hash] errors_hash
      # @param [Array<String,Symbol>] path
      # @param [String] str error to add
      # @return [String] added error
      def add_error_on_path(errors_hash, path, str)
        current = errors_hash
        path.each.with_index do |key, i|
          if (i + 1) == path.size
            current[key] ||= []
            current[key] << str
          else
            current[key] ||= {}
            current = current[key]
          end
        end
        str
      end

      # passthru utils

      # Util for safely checking if a key with an array contains an element
      #
      # @param [Hash] passthru errors passthru hash
      # @param [Symbol] passthru hash key
      # @param [] value
      # @return [Boolean]
      def key_contains?(passthru, key, value)
        !!passthru[key]&.include?(value)
      end

      # Util that determines if a validation should run
      # Use this method inside the +errors+ method when overriding it
      #
      # @param [Hash] passthru errors passthru hash
      # @param [BaseHash] schema_instance
      # @param [Symbol] validation_key error specific key
      # @retunr [Boolean]
      def run_validation?(passthru, schema_instance, validation_key)
        return false if passthru.key?(:if) && !passthru[:if].call(schema_instance, validation_key)
        return false if passthru[:unless]&.call(schema_instance, validation_key)
        true
      end

    end
  end
end