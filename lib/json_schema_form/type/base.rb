require_relative '../custom_struct'

module JsonSchemaForm
  module Type

    class Base < JsonSchemaForm::CustomStruct

      BUILDER = Proc.new do |obj, parent|

        klass_name = "JsonSchemaForm::Type::#{obj[:type].to_s.capitalize}"
        klass = Object.const_get(klass_name)
        type = Types.Constructor(klass) { |v| klass.new(v[:obj], v[:parent]) }
        type[{obj: obj, parent: parent}]
        # case obj[:type]
        # when 'string', :string
        #   JsonSchemaForm::Type::String.new(obj, parent)
        # when 'number', :number, 'integer', :integer
        #   JsonSchemaForm::Type::Number.new(obj, parent)
        # when 'boolean', :boolean
        #   JsonSchemaForm::Type::Boolean.new(obj, parent)
        # when 'array', :array
        #   JsonSchemaForm::Type::Array.new(obj, parent)
        # when 'object', :object
        #   JsonSchemaForm::Type::Object.new(obj, parent)
        # when 'null', :null
        #   JsonSchemaForm::Type::Null.new(obj, parent)
        # else
        #   raise StandardError.new('schema type is not valid')
        # end
      end

      attr_reader :parent

      def initialize(obj, parent=nil, &block)
        @parent = parent
        super(obj, &block)
      end

      attribute :'$id', {
        type: Types::String.default('http://example.com/example.json')
      }
      attribute :'$schema', {
        type: Types::String.default('http://json-schema.org/draft-07/schema#')
      }
      attribute :type, {
        type: Types::String.enum('array','boolean','null','number','object','string')
      }
      attribute? :title, {
        type: Types::String
      }
      attribute? :description, {
        type: Types::String,
        # default: ->(instance) { instance[:title] }
      }
      attribute? :default
      attribute? :examples

      def key_name
        self[:'$id']&.gsub(/^(.*[\\\/])/, '')
      end

      def required?
        if parent && parent[:type] == 'object'
          parent[:required].include?(key_name)
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