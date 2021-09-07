module JSF
  module Validations

    # requires to include Schemable
    # requires to include Buildable

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

      # @param [Hash] own_errors
      # @param [Hash] acum_errors
      # @param [Array<String>] obj_path
      # @return [void]
      BURY_ERRORS_PROC = Proc.new do |own_errors, acum_errors, obj_path|
        SuperHash::Utils.flatten_to_root(own_errors).each do |relative_path, errors_array|
          path = (obj_path || []) + (relative_path.to_s.split('.'))
          path.map!{|i| Integer(i) rescue i.to_sym }
          SuperHash::Utils.bury(acum_errors, *path, errors_array)
        end
      end

      # recursively build errors hash
      #
      # @param [Hash] passthru options to be passed
      # @param [Hash] acum_errors
      # @return [Hash] errors of instance and all sub instances
      def errors(passthru={}, acum_errors={})
        
        # check for errors and set them on the passed errors hash
        own_errors = self.own_errors(passthru)
        BURY_ERRORS_PROC.call(own_errors, acum_errors, self.meta[:path])

        # go recursive
        subschemas_errors(passthru, acum_errors)

        acum_errors
      end

      # override to implement schema errors
      # @param [Hash] passthru options to be passed
      # @return [Hash] errors
      def own_errors(passthru)
        raise NoMethodError.new("need to override 'own_errors' method")
      end

      private

      # Run errors in subschemas
      #
      # @param [Hash] passthru options to be passed
      # @param [Hash] acum_errors
      # @return [void]
      def subschemas_errors(passthru, acum_errors)
        # continue recurrsion for all subschema keys
        self.each do |key, value|
          if key == 'additionalProperties'
            next if !value.is_a?(::Hash)
            self[:additionalProperties]&.each do |k,v|
              call_subschema_errors(v, acum_errors, passthru)
            end
          elsif key == 'definitions'
            self[:definitions]&.each do |k,v|
              call_subschema_errors(v, acum_errors, passthru)
            end
          elsif key == 'dependencies'
            self[:dependencies]&.each do |k,v|
              next if !v.is_a?(::Hash)
              call_subschema_errors(v, acum_errors, passthru)
            end
          elsif key == 'properties'
            self[:properties]&.each do |k,v|
              call_subschema_errors(v, acum_errors, passthru)
            end
          else
            case value
            when ::Array
              next if !ARRAY_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
              value.each do |v|
                call_subschema_errors(v, acum_errors, passthru)
              end
            else
              next if !HASH_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
              call_subschema_errors(value, acum_errors, passthru)
            end
          end
        end
      end

      # Wrapper method, used only to DRY code by not adding respond_to? validation many times
      #
      def call_subschema_errors(subschema, errors, passthru)
        subschema.errors(passthru, errors) if subschema.respond_to?(:errors)
      end

    end
  end
end