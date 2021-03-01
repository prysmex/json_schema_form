module JsonSchemaForm
  module JsonSchema
    module Validatable

      HASH_SUBSCHEMA_KEYS = [
        :properties, :if, :then, :else, :additionalProperties, :dependencies, :patternProperties,
        :contains,
        :not,
        :definitions
      ].freeze

      ARRAY_SUBSCHEMA_KEYS = [
        :allOf,
        :anyOf,
        :oneOf,
        :items
      ].freeze

      #override to implement schema errors
      def schema_instance_errors
        {}
      end

      def has_errors?
        schema_errors.empty?
      end
      
      # recursively get schema_errors
      def schema_errors(errors = {})

        # check for errors
        own_errors = schema_instance_errors
        
        #set the errors on the hash
        own_errors.flatten_to_root.each do |relative_path, errors_array|
          path = (self.meta[:path] || []) + relative_path.to_s.split('.')
          errors.bury(*(path + [errors_array]))
        end
        
        #continue recurrsion for al subschema keys
        self.each do |key, value|
          if key == :properties
            self[:properties]&.each do |k,v|
              v.schema_errors(errors)
            end
          elsif key == :definitions
            self[:definitions]&.each do |k,v|
              v.schema_errors(errors)
            end
          elsif key == :additionalProperties
            next if !value.is_a?(::Hash)
            self[:additionalProperties]&.each do |k,v|
              v.schema_errors(errors)
            end
          else
            case value
            when ::Array
              next if !ARRAY_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
              value.each do |v|
                v.schema_errors(errors)
              end
            else
              next if !HASH_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
              value&.schema_errors(errors)
            end
          end
        end

        errors
      end

    end
  end
end