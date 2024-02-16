module JSF
  module Forms

    class Condition < BaseHash

      include JSF::Core::Schemable
      include JSF::Validations::Validatable
      include JSF::Validations::DrySchemaValidatable
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

      def dry_schema(passthru={})

        prop = self.condition_property_key || '__key_placeholder__'

        Dry::Schema.JSON do
          config.validate_keys = true
        
          before(:key_validator) do |result|
            hash = result.to_h
            hash['then'] = {} if hash.key?('then')
            hash
          end
        
          required(:if).hash do
            required(:required).value(:array?).array(:str?)
            required(:properties).filled(:hash) do
              required(prop.to_sym).filled(:hash) do # ToDo this key is always valid if present, can be improved
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
            optional(:type)
          end
        end
      end

      # # @param passthru [Hash{Symbol => *}]
      # def errors(**passthru)
      #   super
      # end

      ##################
      #####METHODS######
      ##################

      # @return [NilClass, String]
      def condition_property_key
        dig('if', 'properties')&.keys&.first
      end

      # @return [NilClass, String]
      def condition_property
        self.meta[:parent]&.dig(:properties, condition_property_key)
      end

      # @return [Boolean]
      def negated
        !!dig('if', 'properties', condition_property_key)&.key?('not')
      end

      # @return [nil, 'enum', 'const', 'not_enum', 'not_const']
      def condition_type
        hash = dig('if', 'properties', condition_property_key)
        return unless hash

        if hash.key?('not')
          "not_#{hash['not'].keys.first}"
        else
          hash.keys.first
        end
      end

      # @return [NilClass, String]
      def value
        path = JSF::Forms::Form::CONDITION_TYPE_TO_PATH.call(condition_type)
        dig('if', 'properties', condition_property_key, *path)
      end

      # Sets a new value for the condition_property_key
      #
      # @param [String, Boolean, Number] value
      # @param ['const', 'enum']
      #
      # @return [void]
      def set_value(value, key: condition_property_key, type: self.condition_type)
        dig('if', 'properties', key)&.clear
        path = JSF::Forms::Form::CONDITION_TYPE_TO_PATH.call(type)
        SuperHash::Utils.bury(self, 'if', 'properties', key, *path, value)
      end

      # Takes a document or a part of a document (for nested hashes like JSF::Forms::Section) and
      # evaluates if the condition passes. It supports passing a block which will yield data for
      # easy evaluation
      #
      # @param [Hash{String}] local_document must have the root key that will be evaluated
      # @return [Boolean]
      def evaluate(local_document)
        condition_prop = self.condition_property
        key = self.condition_property_key
        value = local_document[key]
        fake_hash = {"#{key}" => value}
        
        if block_given?
          # support custom evaluation
          yield(self[:if], fake_hash, condition_prop)
        else
          return false if negated && value.nil?
          JSONSchemer.schema(self[:if]).valid?(fake_hash) # need to call as_json to self and value?
        end
      end

    end

  end
end