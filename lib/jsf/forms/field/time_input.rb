# frozen_string_literal: true

require 'time'

module JSF
  module Forms
    module Field
      class TimeInput < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Stringable

        set_strict_type('string')

        ###############
        # VALIDATIONS #
        ###############

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          extras = run_validation?(passthru, :extras, optional: true)

          Dry::Schema.JSON(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(eql?: 'time_input')
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
            required(:pattern).value(eql?: '^(?:(?:[0-1][0-9])|(?:[2][0-4])):[0-5][0-9](?::[0-5][0-9])?$')
            required(:type)
          end
        end

        ###########
        # METHODS #
        ###########

        def sample_value
          time = Time.now + rand(0...86_400)
          time.strftime('%H:%M:%S')
        end

      end
    end
  end
end