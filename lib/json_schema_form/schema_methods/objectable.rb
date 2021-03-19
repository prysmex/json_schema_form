module JsonSchemaForm
  module SchemaMethods
    module Objectable

      ###property management###
  
      def add_property(id, definition)
        new_definition = {}.merge(definition)
        new_definition[:'$id'] = "/properties/#{id}" #TODO this currently only works for main form
        properties_hash = self[:properties]&.merge({}) || {}
        properties_hash[id] = new_definition
        self[:properties] = SuperHash::DeepKeysTransform.symbolize_recursive(properties_hash)
      end

      def remove_property(id)
        self[:properties] = self[:properties]&.reject do |k, v| 
          k == id
        end
      end

      ###required###
  
      def add_required_property(name)
        self[:required] = (self[:required] || []).push(name.to_s).uniq
      end
  
      def remove_required_property(name)
        self[:required] = self[:required]&.reject{|n| n == name.to_s }
      end

      ###general###

      # get properties
      def properties
        self[:properties]
      end

      # get dynamic properties
      def dynamic_properties(levels=nil)
        get_dynamic_forms(levels).map{|f| f[:properties]}.compact.reduce({}, :merge)
      end

      # get own and dynamic properties
      def merged_properties(levels=nil)
        (self[:properties] || {})
          .merge(self.dynamic_properties(levels))
      end
      
      # Lists the names of the properties defined in the schema
      def property_names
        self[:properties]&.keys || []
      end

      # Lists the names of the dynamic properties defined as sub-schemas
      def dynamic_property_names(levels=nil)
        self.dynamic_properties(levels).keys
      end

      # Lists the names of both dynamic and own properties
      def merged_property_names(levels=nil)
        self.merged_properties(levels).keys
      end
  
      # returns the property JSON definition inside the properties key
      def get_property(property)
        self.dig(:properties, property.to_sym)
      end

      def get_dynamic_property(property, levels=nil)
        dynamic_properties(levels).try(:[], property.to_sym)
      end

      def get_merged_property(property, levels=nil)
        merged_properties(levels).try(:[], property.to_sym)
      end

      # returns the property JSON definition inside the properties key
      def has_property?(property)
        !self.get_property(property).nil?
      end

      def has_dynamic_property?(property, levels=nil)
        !self.get_dynamic_property(property, levels).nil?
      end

      def has_merged_property?(property, levels=nil)
        !self.get_merged_property(property, levels).nil?
      end
  
      # returns the type of an property
      def property_type(property)
        get_property(property).try(:[], :type)
      end

      def dynamic_property_type(property, levels=nil)
        get_dynamic_property(property, levels=nil).try(:[], :type)
      end

      def merged_property_type(property, levels=nil)
        get_merged_property(property, levels=nil).try(:[], :type)
      end

      # Returns a Hash with property names and types
      def properties_type_mapping
        hash = {}
        property_names.each do |attr|
          hash[attr] = property_type(attr)
        end
        hash
      end

      def dynamic_properties_type_mapping(levels=nil)
        hash = {}
        dynamic_property_names(levels).each do |attr|
          hash[attr] = dynamic_property_type(attr, levels)
        end
        hash
      end

      def merged_properties_type_mapping(levels=nil)
        hash = {}
        merged_property_names(levels).each do |attr|
          hash[attr] = merged_property_type(attr, levels)
        end
        hash
      end

      #ToDo consider else key in allOf
      #ToDo consider root then and else keys
      def get_dynamic_forms(levels=nil, level=0)
        return [] if levels && level >= levels
        schemas_array=[]
        self[:allOf]&.each do |condition_subschema|
          subschema = condition_subschema[:then]
          if subschema
            schemas_array.push(subschema)
            schemas_array.concat(subschema.get_dynamic_forms(levels, level + 1))
          end
        end
        schemas_array
      end

    end
  end
end