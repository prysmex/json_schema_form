module JSF
  module Forms
    module Field
      class Section < BaseHash

        include ::JSF::Forms::Field::Methods::Base
        include JSF::Core::Type::Arrayable
        include JSF::Core::Buildable

        set_strict_type('array')

        ATTRIBUTE_TRANSFORM = ->(attribute, value, instance, init_options) {
          case instance
          when JSF::Forms::Field::Section
            case attribute
            when 'items'
              return JSF::Forms::Form.new(value, init_options)
            end
          end
  
          raise StandardError.new("JSF::Forms::Field::Section transform conditions not met: (attribute: #{attribute}, value: #{value}, meta: #{instance.meta})")
        }

        def initialize(obj={}, options={})
          options = {
            attributes_transform_proc: JSF::Forms::Field::Section::ATTRIBUTE_TRANSFORM
          }.merge(options)
      
          super(obj, options)
        end

        def validation_schema(passthru)
          is_inspection = passthru[:is_inspection]

          Dry::Schema.define(parent: super) do

            before(:key_validator) do |result|
              hash = result.to_h
              hash['items'] = {} if hash.key?('items')
              hash
            end

            required(:displayProperties).hash do
              optional(:hidden).filled(:bool)
              optional(:hideOnCreate).filled(:bool)
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              required(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              optional(:useSection).value(eql?: true)
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            required(:extra).value(:array?).array(:str?).each(included_in?: ['actions', 'failed', 'notes', 'pictures', 'score']) if is_inspection
            required(:items).hash do
              optional(:properties)
              optional(:allOf)
              optional(:required)
            end
            required(:type)
          end
        end

      end
    end
  end
end