# frozen_string_literal: true

module JSF
  module Core

    # Contains a collection of modules that organize methods by 'type'
    # This is done so we can more selectively add methods to specific classes
    #
    module Type

      # Methods for all schemas with json-schema 'array' type
      #
      module Arrayable
      end

      # Methods for all schemas with json-schema 'boolean' type
      #
      module Booleanable
      end

      # Methods for all schemas with json-schema 'null' type
      #
      module Nullable
      end

      # Methods for all schemas with json-schema 'number' type
      #
      module Numberable
      end

      # Methods for all schemas with json-schema 'object' type
      #
      module Objectable

        #######################
        # property management #
        #######################

        # Adds a property to the 'properties' hash. If 'required' option is passed,
        # it will also add the property to the 'required' key
        #
        # @note if the property is already present, an error will be raised
        #
        # @param name [String,Symbol] name of the property
        # @param definition [Hash] the schema to add
        # @param options[:required] [Boolean] if the property should be required
        # @return [Object] added property
        def add_property(name, definition, options = {}, &)
          name = name.to_s
          self[:properties] ||= {}
          StandardError.new("key #{name} already exists") if self[:properties]&.key?(name)

          # definition = definition.deep_dup
          definition[:$id] = "#/properties/#{name}" # TODO: this currently only works for main form
          self[:properties].merge!({ name => definition })
          self[:properties] = self[:properties] # trigger transforms

          # add to required array
          (self[:required] ||= []).push(name) if options[:required]

          added_property = self[:properties][name]
          added_property.instance_exec(added_property, self, &) if block_given?
          # yield(added_property, name.to_s, self) if block_given?
          added_property
        end

        # Removes from 'properties' and 'required'
        #
        # @todo handle if other property depends on this one
        #
        # @param [String,Symbol]
        # @return [Object] mutated self
        def remove_property(id)
          id = id.to_s
          self[:properties].delete(id) if self[:properties]
          self[:required].reject! { |name| name == id } if self[:required]
          self
        end

        #########################
        # definition management #
        #########################

        # Adds a definition to the '$defs' hash
        #
        # @note if the definition is already present, an error will be raised
        #
        # @param id [String,Symbol] name of the property
        # @param definition [Hash] the schema to add
        # @param options[:required] [Boolean] if the property should be required
        # @return [Object] added property
        def add_def(id, definition)
          self[:$defs] ||= {}
          StandardError.new("key #{id} already exists") if self[:$defs].key?(id)

          # definition = definition.deep_dup
          self[:$defs].merge!({ id => definition })
          self[:$defs] = self[:$defs] # trigger transforms
          added_definition = self[:$defs][id]
          yield(added_definition, id.to_s, self) if block_given?
          added_definition
        end

        # Removes a definition from the '$defs' key
        #
        # @param [String,Symbol] key name of the key to remove
        # @return [Object] mutated self
        def remove_def(key)
          key = key.to_s
          self[:$defs].delete(key) if self[:$defs]
          self
        end

        ############
        # required #
        ############

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
          return unless self[:required]

          self[:required].reject! { |n| n == name.to_s }
        end

      end

      # Methods for all schemas with json-schema 'string' type
      #
      module Stringable
      end

    end
  end
end