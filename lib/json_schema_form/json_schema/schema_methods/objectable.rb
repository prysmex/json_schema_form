module JsonSchema
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
        unless self[:properties].nil?
          self[:properties] = self[:properties].reject do |k, v| 
            k == id.to_sym
          end
        end
      end

      ###required###
  
      def add_required_property(name)
        return if name.nil?
        self[:required] = (self[:required] || []).push(name.to_s).uniq
      end
  
      def remove_required_property(name)
        return if self[:required].nil?
        self[:required] = self[:required]&.reject{|n| n == name.to_s }
      end

      ###general###


    end
  end
end