module JsonSchemaForm
  module Type
    class Object < Base

      PROPERTIES_PROC = ->(instance, value) {
        value.transform_values do |definition|
          BUILDER.call(definition, instance)
        end
      }

      All_OF_PROC = ->(instance, value) {
        value.map do |obj|
          schema_object = JsonSchemaForm::Type::Object.new(
            obj[:then].merge(skip_required_attrs: [:type]), 
            instance
          )
          obj.merge({
            then: schema_object
          })
        end
      }

      attribute :type, {
        type: Types::String.enum('object')
      }
      attribute :required, type: Types::Array.default([].freeze)
      attribute :properties, type: Types::Hash.default({}.freeze), transform: PROPERTIES_PROC
      attribute? :allOf, type: Types::Array.default([].freeze).of(
        Types::Hash.schema(
          if: Types::Hash,
          then: Types::Hash
        )
      ), transform: All_OF_PROC

      def validations
        hash = super
        self[:properties].each do|k,v|
          hash[k] = v.validations
        end
        hash.compact
      end

      ###property management###
  
      def add_property(id, definition)
        new_definition = {}.merge(definition)
        new_definition[:'$id'] = "/properties/#{id}"

        hash = self[:properties]
        hash[id] = new_definition
        self[:properties] = self.symbolize_recursive(hash)
      end

      ###required###
  
      def add_required_property(name)
        self[:required] = self[:required].push(name.to_s).uniq
      end
  
      def remove_required_property(name)
        self[:required] = self[:required].reject{|n| n == name.to_s }
      end

      ###general###
      
      # Lists the names of the properties defined in the schema
      def property_names
        self&.dig(:properties, :keys) || []
      end
  
      # Returns a Hash with property names and types
      def properties_type_mapping
        hash = {}
        property_names.each do |attr|
          hash[attr] = property_type(attr)
        end
        hash
      end
  
      # returns the property JSON definition inside the properties key
      def get_property(property)
        self&.dig(:properties, property.to_sym)
      end

      # returns the property JSON definition inside the properties key
      def has_property?(property)
        !self&.dig(:properties, property.to_sym).nil?
      end

      def remove_property(id)
        self[:properties] = self[:properties].reject do |k, v| 
          k == id
        end
      end
  
      # returns the type of an property
      def property_type(property)
        get_property(property)[:type]
      end
  
      def validations_for_property(property)
        get_property(property).validations
      end

    end
  end
end