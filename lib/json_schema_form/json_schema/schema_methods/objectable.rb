# Methods for all schemas with json-schema 'object' type

module JsonSchema
  module SchemaMethods
    module Objectable

      #####################
      #property management#
      #####################

      # Adds a property to the 'properties' hash
      # @param id [Symbol] name of the property
      # @param definition [Hash] the schema to add
      # @param options[:required] [Boolean] if the property should be required
      # @return [Object] Property added
      def add_property(id, definition, options={})
        new_definition = {}.merge(definition)
        new_definition[:'$id'] = "#/properties/#{id}" #TODO this currently only works for main form
        properties_hash = self[:properties]&.merge({}) || {}
        properties_hash[id] = new_definition
        if options[:required]
          self[:required] = ((self[:required] || []) + [id]).uniq
        end
        self[:properties] = SuperHash::DeepKeysTransform.symbolize_recursive(properties_hash)
        self[:properties][id]
      end

      # Removes 'properties' and 'required' key
      # TODO handle if other property depends on this one
      # @return [Object] mutated self
      def remove_property(id)
        id = id.to_sym
        self[:properties] = self[:properties].reject{|k, v|  k == id } unless self[:properties].nil?
        self[:required] = self[:required].reject{|name| name == id} unless self[:required].nil?
        self
      end

      ##########
      #required#
      ##########
      
      # Adds a property to 'required' key
      # @param name [Symbol] name of key
      # @return [Array] required key
      def add_required_property(name)
        self[:required] = (self[:required] || []).push(name.to_s).uniq
      end
      
      # Removes a property to 'required' key
      # @param name [Symbol] name of key
      # @return [Array] required key
      def remove_required_property(name)
        self[:required] = self[:required].reject{|n| n == name.to_s } unless self[:required].nil?
        self[:required]
      end

    end
  end
end