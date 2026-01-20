# frozen_string_literal: true

module JSF
  module Forms
    class Section < BaseHash

      include JSF::Core::Schemable
      include JSF::Validations::Validatable
      include JSF::Validations::DrySchemaValidatable
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

      def initialize(obj = {}, options = {}, *)
        options = {
          attributes_transform_proc: JSF::Forms::Section::ATTRIBUTE_TRANSFORM
        }.merge(options)

        super
      end

      ###############
      # VALIDATIONS #
      ###############

      # @param passthru [Hash{Symbol => *}] Options passed
      # @return [Dry::Schema::JSON] Schema
      def dry_schema(passthru)
        hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)

        self.class.cache(hide_on_create.to_s) do
          Dry::Schema.JSON do
            config.validate_keys = true

            before(:key_validator) do |result| # result.to_h (shallow dup)
              result.to_h.tap do |h|
                h['items'] = {} if h.key?('items')
              end
            end

            required(:displayProperties).hash do
              required(:component).value(eql?: 'section')
              optional(:hidden).filled(:bool)
              optional(:hideOnCreate).filled(:bool) if hide_on_create
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              optional(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            optional(:maxItems).filled(:integer)
            optional(:minItems).filled(:integer)
            required(:items).hash
            required(:type)
            optional(:$id).filled(:string)
            optional(:title).maybe(:string)
            # optional(:default)
          end
        end
      end

      def valid_for_locale?(locale = DEFAULT_LOCALE)
        !i18n_label(locale).to_s.empty? &&
          (
            form.nil? ||
            form.valid_for_locale?(locale)
          )
      end

      ###########
      # METHODS #
      ###########

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
        # dig(:displayProperties, :disableScoring) != true &&
        !!form&.scored?
      end

    end
  end
end