# requires to include Schemable
# requires to include Buildable

module JsonSchema
  module Validations
    module Validatable

      HASH_SUBSCHEMA_KEYS = [
        :additionalProperties,
        :contains,
        :definitions,
        :dependencies,
        :else,
        :if,
        :items,
        :not,
        :properties,
        :then
      ].freeze

      NONE_SUBSCHEMA_HASH_KEYS_WITH_UNKNOWN_KEYS = [
        :patternProperties
      ]

      ARRAY_SUBSCHEMA_KEYS = [
        :allOf,
        :anyOf,
        :items,
        :oneOf
      ].freeze

      BURY_ERRORS_PROC = Proc.new do |errors_to_bury, errors_hash, obj_path|
        SuperHash::Helpers.flatten_to_root(errors_to_bury).each do |relative_path, errors_array|
          path = (obj_path || []) + (relative_path.to_s.split('.')).map{|i| Integer(i) rescue i.to_sym }
          SuperHash::Helpers.bury(errors_hash, *path, errors_array)
        end
      end

      #override to implement schema errors
      def own_errors
        raise NoMethodError.new("need to override 'own_errors' method")
      end

      def add_subschema_errors(errors)
        #continue recurrsion for all subschema keys
        self.each do |key, value|
          if key == :additionalProperties
            next if !value.is_a?(::Hash)
            self[:additionalProperties]&.each do |k,v|
              v.errors(errors, self)
            end
          elsif key == :definitions
            self[:definitions]&.each do |k,v|
              v.errors(errors, self)
            end
          elsif key == :dependencies
            self[:dependencies]&.each do |k,v|
              next if !v.is_a?(::Hash)
              v.errors(errors, self)
            end
          elsif key == :properties
            self[:properties]&.each do |k,v|
              v.errors(errors, self)
            end
          else
            case value
            when ::Array
              next if !ARRAY_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
              value.each do |v|
                v.errors(errors, self)
              end
            else
              next if !HASH_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
              value.errors(errors, self)
            end
          end
        end
      end
      
      # recursively get errors
      def errors(errors={}, caller=nil)
        
        # check for errors and set them on the passed errors hash
        own_errors = self.own_errors
        BURY_ERRORS_PROC.call(own_errors, errors, self.meta[:path])

        # go recursive
        self.add_subschema_errors(errors)

        errors
      end

    end
  end
end