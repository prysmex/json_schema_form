require_relative '../super_hash'
# require 'dry-schema'

module JsonSchemaForm
  module Type

    class Base < JsonSchemaForm::SuperHash

      instance_variable_set('@allow_dynamic_attributes', true)
      attr_reader :meta

      BUILDER = Proc.new do |obj, meta|

        klass_name = "JsonSchemaForm::Type::#{obj[:type].to_s.split('_').collect(&:capitalize).join}"
        klass = Object.const_get(klass_name)
        type = Types.Constructor(klass) { |v| klass.new(v[:obj], v[:meta]) }
        type[{obj: obj, meta: meta}]
        # case obj[:type]
        # when 'string', :string
        #   JsonSchemaForm::Type::String.new(obj, meta)
        # when 'number', :number, 'integer', :integer
        #   JsonSchemaForm::Type::Number.new(obj, meta)
        # when 'boolean', :boolean
        #   JsonSchemaForm::Type::Boolean.new(obj, meta)
        # when 'array', :array
        #   JsonSchemaForm::Type::Array.new(obj, meta)
        # when 'object', :object
        #   JsonSchemaForm::Type::Object.new(obj, meta)
        # when 'null', :null
        #   JsonSchemaForm::Type::Null.new(obj, meta)
        # else
        #   raise StandardError.new('schema type is not valid')
        # end
      end

      def initialize(obj, meta={}, &block)
        @meta = meta
        super(obj, &block)
      end

      attribute? :'$id', {
        default: ->(instance) { 'http://example.com/example.json' }
      }
      attribute? :'$schema', {
        default: ->(instance) { 'http://json-schema.org/draft-07/schema#' }
      }

      def validation_schema
        Dry::Schema.JSON do
          #config.validate_keys = true
          required(:type).filled(:string).value(included_in?: [
            'array','boolean','null','number','object','string'
          ])
          required(:'$id').filled(:string)
          required(:'$schema').filled(:string)
          optional(:title).maybe(:string)
          optional(:description).maybe(:string)
          optional(:default)
          optional(:examples)
        end
      end

      def valid?
        errors.empty?
      end

      def errors
        validation_schema.(validation_hash).errors.to_h
      end

      def validation_hash
        self.as_json
      end

      def key_name
        self[:'$id']&.gsub(/^(.*[\\\/])/, '')
      end

      def required?
        if meta.dig(:parent, :type) == 'object'
          meta.dig(:parent, :required).include?(key_name)
        end
      end

      def validations
        {
          required: required?
        }
      end

      private

    end
  end
end