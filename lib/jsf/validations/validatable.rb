module JSF
  module Validations

    # Adds the ability to recursively build an errors hash by calling `errors`.
    # Each encountered subschema should respond to `own_errors` (by default not defined) and return its own errors hash.
    # The `errors` method will use the hash returned by `own_errors` to add the errors of all subschemas recursively.
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

      # @param [Hash] target_hash (hash to bury into)
      # @param [Hash] errors_hash
      # @param [Array<String>] obj_path
      # @return [void]
      BURY_subschema_ERRORS_PROC = Proc.new do |target_hash, errors_hash, obj_path|
        SuperHash::Utils.flatten_to_root(errors_hash).each do |error_path_str, errors_array|
          error_path = error_path_str.to_s.split('.')
          path = (obj_path || []) + error_path
          path.map!{|i| Integer(i) rescue i.to_sym }
          SuperHash::Utils.bury(target_hash, *path, errors_array)
        end
      end

      # recursively build errors hash
      #
      # @param passthru [Hash{Symbol => *}] options to be passed
      # @return [Hash] errors of instance and all sub instances
      def errors(passthru={})
        # check for errors and set them on the passed errors hash
        own_errors = self.own_errors(passthru)

        # go recursive
        bury_subschemas_errors(passthru, own_errors)

        own_errors
      end

      # override to implement schema errors
      #
      # @param passthru [Hash{Symbol => *}] options to be passed
      # @return [Hash{Symbol => *}] errors
      def own_errors(passthru={})
        raise NoMethodError.new("to use errors, you need to override 'own_errors' method and return a hash of errors")
      end

      private

      # Run errors in subschemas
      #
      # @param passthru [Hash{Symbol => *}] options to be passed
      # @param [Hash] [Hash{Symbol => *}] acum_errors
      # @return [void]
      def bury_subschemas_errors(passthru, own_errors)
        # continue recurrsion for all subschema keys
        self.each do |key, value|
          if key == 'additionalProperties'
            next if !value.is_a?(::Hash)
            self[:additionalProperties]&.each do |k,v|
              bury_subschema_errors(v, own_errors, passthru)
            end
          elsif key == 'definitions'
            self[:definitions]&.each do |k,v|
              bury_subschema_errors(v, own_errors, passthru)
            end
          elsif key == 'dependencies'
            self[:dependencies]&.each do |k,v|
              next if !v.is_a?(::Hash)
              bury_subschema_errors(v, own_errors, passthru)
            end
          elsif key == 'properties'
            self[:properties]&.each do |k,v|
              bury_subschema_errors(v, own_errors, passthru)
            end
          else
            case value
            when ::Array
              next if !ARRAY_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
              value.each do |v|
                bury_subschema_errors(v, own_errors, passthru)
              end
            else
              next if !HASH_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
              bury_subschema_errors(value, own_errors, passthru)
            end
          end
        end
      end

      # Wrapper method, used only to DRY code by not adding respond_to? validation many times
      def bury_subschema_errors(subschema, own_errors, passthru)
        return unless subschema.respond_to?(:errors)

        errors = subschema.errors(passthru)
        relative_path = subschema.meta[:path].slice((self.meta[:path].size)..-1)

        BURY_subschema_ERRORS_PROC.call(own_errors, errors, relative_path)
      end

    end
  end
end