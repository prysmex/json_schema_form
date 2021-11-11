module JSF
  module Core

    # Include this module to make your class 'buildable' (a recursive tree).
    # It sets the SuperHash's attributes with a transform Proc for each key that may contain a subschema.

    # It also defines a `attributes_transform` method (ultimately called by all attribute transforms), to allow a single entry point to
    # customize how an instance can 'build' its child subschemas. This is how JSF::Forms::Form
    # can easily customize how the schema tree is built.

    # It is important to note that all transform Procs are built so that the `attributes_transform` method always receive the
    # same arguments
    module Buildable

      def self.included(base)

        # Set all transforms for Hash keys
        base.update_attribute 'additionalProperties', transform: ADDITIONAL_PROPERTIES_TRANSFORM
        base.update_attribute 'contains', transform: CONTAINS_TRANSFORM
        base.update_attribute 'definitions', transform: DEFINITIONS_TRANSFORM
        base.update_attribute 'dependencies', transform: DEPENDENCIES_TRANSFORM
        base.update_attribute 'if', transform: IF_TRANSFORM
        base.update_attribute 'else', transform: ELSE_TRANSFORM
        base.update_attribute 'then', transform: THEN_TRANSFORM
        base.update_attribute 'not', transform: NOT_TRANSFORM
        base.update_attribute 'items', transform: ITEMS_TRANSFORM
        base.update_attribute 'properties', transform: PROPERTIES_TRANSFORM
        
        # Set all transforms for Array keys
        base.update_attribute 'allOf', transform: All_OF_TRANSFORM
        base.update_attribute 'anyOf', transform: ANY_OF_TRANSFORM
        base.update_attribute 'oneOf', transform: ONE_OF_TRANSFORM
      end

      # @param [Hash] init_value
      # @param [Hash] options SuperHash::Hasher options
      # @option options [Proc] :attributes_transform_proc
      def initialize(init_value={}, options={})
        @attributes_transform_proc = options.delete(:attributes_transform_proc)
        super(init_value, options)
      end

      # This method is called by CORE_TRANSFORM which is called by all attribute transforms
      # You can think of it as the last part of the transform for all schema attributes
      # It is useful if you want a specific attribute to have a specific class instance,
      # for example, instantiating JSF::Forms::Field classes
      #
      # @param attribute [String] name of the key
      # @param value [Object]
      # @param meta [Hash{Symbol}]
      # @return [Object] transformed value
      def attributes_transform(attribute, value, meta)
        if @attributes_transform_proc
          @attributes_transform_proc.call(attribute, value, self, {meta: meta})
        else
          self.class.new(value, {meta: meta})
        end
      end

      # Main proc called by all attribute transforms, it serves two purposes:
      #
      # - Builds meta hash
      # - Drying code
      #
      # It calls the attributes_transform, which can easily be overriden
      #
      # @param [String] name of the key
      # @param [Object] value
      # @param [Object] instance
      # @param [Array<String>] path
      CORE_TRANSFORM = ->(attribute, value, instance, path) {
        path = path.map{|i| i.is_a?(Symbol) ? i.to_s : i }
        meta = {
          parent: instance,
          is_subschema: true,
          path: (instance.meta[:path] || []) + path
        }
        instance.attributes_transform(attribute, value, meta)
      }

      ###################
      ##Hash transforms##
      ###################

      # SuperHash::Hasher attribute transform
      ADDITIONAL_PROPERTIES_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Hash
          instance.class::CORE_TRANSFORM.call(attribute, value, instance, [attribute])
        else
          value
        end
      }

      # SuperHash::Hasher attribute transform
      CONTAINS_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Hash
          instance.class::CORE_TRANSFORM.call(attribute, value, instance, [attribute])
        end
      }

      # SuperHash::Hasher attribute transform
      DEFINITIONS_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Hash
          value.inject({}) do |acum, (name, definition)|
            acum[name] = instance.class::CORE_TRANSFORM.call(
              attribute, 
              definition,
              instance,
              [:definitions, name]
            )
            acum
          end
        end
      }

      # SuperHash::Hasher attribute transform
      DEPENDENCIES_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Hash
          value.inject({}) do |acum, (name, definition)|
            if definition.is_a?(::Hash)
              acum[name] = instance.class::CORE_TRANSFORM.call(
                attribute, 
                definition,
                instance,
                [:dependencies, name]
              )
            else
              acum[name] = definition
            end
            acum
          end
        end
      }

      ELSE_TRANSFORM = CONTAINS_TRANSFORM

      IF_TRANSFORM = CONTAINS_TRANSFORM

      # SuperHash::Hasher attribute transform
      ITEMS_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Array
          value.map.with_index do |definition, index|
            instance.class::CORE_TRANSFORM.call(attribute, definition, instance, [attribute, index])
          end
        when ::Hash
          instance.class::CORE_TRANSFORM.call(attribute, value, instance, [attribute])
        end
      }

      NOT_TRANSFORM = CONTAINS_TRANSFORM

      # SuperHash::Hasher attribute transform
      PROPERTIES_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Hash
          value.inject({}) do |acum, (name, definition)|
            acum[name] = instance.class::CORE_TRANSFORM.call(
              attribute, 
              definition,
              instance,
              [:properties, name]
            )
            acum
          end
        end
      }

      THEN_TRANSFORM = CONTAINS_TRANSFORM

      ##################
      #Array Transforms#
      ##################

      # SuperHash::Hasher attribute transform
      All_OF_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Array
          value.map.with_index do |definition, index|
            instance.class::CORE_TRANSFORM.call(attribute, definition, instance, [attribute, index])
          end
        end
      }

      ANY_OF_TRANSFORM = All_OF_TRANSFORM

      ONE_OF_TRANSFORM = All_OF_TRANSFORM

    end
  end
end