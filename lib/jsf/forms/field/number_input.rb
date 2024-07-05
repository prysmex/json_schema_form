# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class NumberInput < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Numberable

        set_strict_type('number')

        ###############
        # VALIDATIONS #
        ###############

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          extras = run_validation?(passthru, :extras, optional: true)

          self.class.cache("#{hide_on_create}#{extras}") do
            Dry::Schema.JSON(parent: super) do
              required(:displayProperties).hash do
                required(:component).value(eql?: 'number_input')
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
              optional(:extra).value(:array?).array(:str?).each(included_in?: %w[reports notes pictures]) if extras
              required(:type)
            end
          end
        end

        ###########
        # METHODS #
        ###########

        def sample_value
          rand(-1000...1000)
        end

      end
    end
  end
end