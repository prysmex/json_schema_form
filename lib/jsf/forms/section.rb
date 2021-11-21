module JSF
  module Forms
    class Section < BaseHash

      include JSF::Core::Schemable
      include JSF::Validations::Validatable
      include JSF::Core::Type::Arrayable
      include JSF::Core::Buildable
      include JSF::Forms::Concerns::DisplayProperties
      include JSF::Forms::Concerns::DocumentPath

      set_strict_type('array')

      ATTRIBUTE_TRANSFORM = ->(attribute, value, instance, init_options) {
        case instance
        when JSF::Forms::Section
          case attribute
          when 'items'
            return JSF::Forms::Form.new(value, init_options)
          end
        end

        raise StandardError.new("JSF::Forms::Section transform conditions not met: (attribute: #{attribute}, value: #{value}, meta: #{instance.meta})")
      }

      def initialize(obj={}, options={})
        options = {
          attributes_transform_proc: JSF::Forms::Section::ATTRIBUTE_TRANSFORM
        }.merge(options)
    
        super(obj, options)
      end

      ##################
      ###VALIDATIONS####
      ##################

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
          optional(:maxItems).filled(:integer)
          required(:items).hash do
            optional(:properties)
            optional(:allOf)
            optional(:required)
          end
          required(:type)
        end
      end

      def valid_for_locale?(locale = DEFAULT_LOCALE)
        !i18n_label(locale).to_s.empty? &&
          (
            form.nil? ||
            form.valid_for_locale?(locale)
          )
      end

      ##############
      ###METHODS####
      ##############

      def form
        self[:items]
      end

      # @return [Boolean]
      def repeatable?
        self[:maxItems] != 1
      end

      # Checks any subschema is scored
      #
      # @return [Boolean]
      def scored?
        !!form&.scored?
      end

    end
  end
end