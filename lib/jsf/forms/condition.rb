module JSF
  module Forms

    class Condition < BaseHash

      include JSF::Core::Schemable
      include JSF::Validations::Validatable
      include JSF::Core::Buildable

      ATTRIBUTE_TRANSFORM = ->(attribute, value, instance, init_options) {
        case instance
        when JSF::Forms::Condition
          case attribute
          when 'if'
            return JSF::Schema.new(value, init_options)
          when 'then'
            return JSF::Forms::Form.new(value, init_options)
          end
        end

        raise StandardError.new("JSF::Forms::Condition transform conditions not met: (attribute: #{attribute}, value: #{value}, meta: #{instance.meta})")
      }

      def initialize(obj={}, options={})
        options = {
          attributes_transform_proc: JSF::Forms::Condition::ATTRIBUTE_TRANSFORM
        }.merge(options)
    
        super(obj, options)
      end

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema(passthru={})

        prop = self.condition_property_key || '__key_placeholder__'

        Dry::Schema.JSON do
          config.validate_keys = true
        
          before(:key_validator) do |result|
            hash = result.to_h
            hash['then'] = {} if hash.key?('then')
            hash
          end
        
          required(:if).hash do
            required(:properties).filled(:hash) do
              required(prop.to_sym).filled(:hash) do #this key is always valid if present
                optional(:const)
                optional(:enum).value(:array, min_size?: 1)# unless field.is_a?(JSF::Forms::Field::NumberInput)
                optional(:not).filled(:hash) do
                  optional(:const)
                  optional(:enum).value(:array, min_size?: 1)# unless field.is_a?(JSF::Forms::Field::NumberInput)
                end
              end
            end
          end
          required(:then).hash do
            optional(:properties)
            optional(:allOf)
            optional(:required)
          end
        end
      end

      # @param passthru [Hash{Symbol => *}]
      def errors(**passthru)
        errors = JSF::Validations::DrySchemaValidatable::CONDITIONAL_SCHEMA_ERRORS_PROC.call(
          passthru,
          self
        )

        super.merge(errors)
      end

      ##################
      #####METHODS######
      ##################

      def condition_property_key
        self.dig('if', 'properties')&.keys&.first
      end

      def condition_property
        self.meta[:parent]&.dig(:properties, condition_property_key)
      end

    end

  end
end