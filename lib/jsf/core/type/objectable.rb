# Methods for all schemas with json-schema 'object' type

module JSF
  module Core
    module Type
      module Objectable

        #####################
        #property management#
        #####################
  
        # Adds a property to the 'properties' hash
        #
        # @param id [String,Symbol] name of the property
        # @param definition [Hash] the schema to add
        # @param options[:required] [Boolean] if the property should be required
        # @return [Object] Property added
        def add_property(id, definition, options={})
          id = id.to_s
          dup_definition = definition.deep_dup
          dup_definition[:'$id'] = "#/properties/#{id}" #TODO this currently only works for main form
          self[:properties] = (self[:properties] || {}).merge({id => dup_definition})
          
          # add to required array
          if options[:required]
            self[:required] = ((self[:required] || []) + [id]).uniq
          end
          self[:properties][id]
        end
  
        # Removes from 'properties' and 'required'
        #
        # @todo handle if other property depends on this one
        #
        # @param [String,Symbol]
        # @return [Object] mutated self
        def remove_property(id)
          id = id.to_s
          self[:properties] = self[:properties].reject{|k, v|  k == id } unless self[:properties].nil?
          self[:required] = self[:required].reject{|name| name == id} unless self[:required].nil?
          self
        end
  
        ##########
        #required#
        ##########
        
        # Adds a property to 'required' key
        #
        # @param name [Symbol] name of key
        # @return [Array] required key
        def add_required(name)
          self[:required] = (self[:required] || []).push(name.to_s).uniq
        end
        
        # Removes a property to 'required' key
        #
        # @param name [Symbol] name of key
        # @return [Array] required key
        def remove_required(name)
          self[:required] = self[:required].reject{|n| n == name.to_s } unless self[:required].nil?
          self[:required]
        end
  
      end
    end
  end
end