# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class Markdown < BaseHash

        KINDS = %w[none neutral positive caution negative].freeze

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Nullable

        set_strict_type(%w[string null]) # @deprecate null after migration

        ###############
        # VALIDATIONS #
        ###############

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)

          Dry::Schema.JSON(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(eql?: 'markdown')
              optional(:hidden).filled(:bool)
              optional(:hideOnCreate).filled(:bool) if hide_on_create
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              optional(:kind).value(included_in?: KINDS)
              optional(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            required(:format).filled(Types::String.enum('date-time'))
            required(:type).value(eql?: 'string')
          end
        end

        ###########
        # METHODS #
        ###########

        def sample_value
          half_range_seconds = 60 * 60 * 24 * 365
          range = (half_range_seconds * -1)...half_range_seconds
          seconds = rand(range)
          (Time.now + seconds).iso8601
        end

        def migrate!
          self['type'] = 'string'
        end

      end
    end
  end
end