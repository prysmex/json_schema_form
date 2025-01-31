# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class Slideshow < BaseHash

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
          # exam = run_validation?(passthru, :exam, optional: true)

          self.class.cache(hide_on_create.to_s) do
            Dry::Schema.JSON(parent: super) do
              required(:displayProperties).hash do
                required(:component).value(eql?: 'slideshow')
                optional(:hidden).filled(:bool)
                optional(:hideOnCreate).filled(:bool) if hide_on_create
                required(:i18n).hash do
                  required(:label).hash do
                    AVAILABLE_LOCALES.each do |locale|
                      optional(locale.to_sym).maybe(:string)
                    end
                  end
                end
                required(:url).filled(:string)
                # optional(:pictures).value(:array?).array(:str?)
                required(:sort).filled(:integer)
                required(:visibility).hash do
                  required(:label).filled(:bool)
                end
              end
              required(:min).value(eql?: 0)
              # required(:max).value(eql?: 100)
              required(:type)
            end
          end
        end

        ###########
        # METHODS #
        ###########

        def sample_value
          rand(0..100)
        end

      end
    end
  end
end