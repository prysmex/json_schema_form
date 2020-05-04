module JsonSchemaForm
  module Type
    class Object < Base

      PROPERTIES_PROC = ->(instance, value) {
        hash = {}
        value.each do |name, definition|
          property = BUILDER.call(definition, instance)
          hash[name] = property
          hash.singleton_class.define_method("#{PREFIX}#{name}".to_sym) do
            property
          end
        end
        hash
      }

      attribute :required, type: Types::Array.default([].freeze)
      attribute :properties, type: Types::Hash.default({}.freeze), transform: PROPERTIES_PROC

      def validations
        hash = super
        self[:properties].each do|k,v|
          hash[k] = v.validations
        end
        hash.compact
      end

      ###property management###
  
      def add_property(id, definition)
        hash = {}
        hash[id] = definition
        hash = self[:properties].as_json.merge(hash)
        self[:properties] = self.class.deep_symbolize!(hash)
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
        self[:properties].try(:keys) || []
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
        self[:properties].try(:[], property.to_sym)
      end

      # returns the property JSON definition inside the properties key
      def has_property?(property)
        self[:properties].try(:[], property.to_sym).present?
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