# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class Static < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Nullable

        set_strict_type('null')

        ###############
        # VALIDATIONS #
        ###############

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)

          Dry::Schema.JSON(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(eql?: 'static')
              optional(:hidden).filled(:bool)
              optional(:hideOnCreate).filled(:bool) if hide_on_create
              required(:sort).filled(:integer)
            end
            required(:type)
          end
        end

        def valid_for_locale?(_locale = DEFAULT_LOCALE)
          true
        end

        ###########
        # METHODS #
        ###########

        def sample_value
          nil
        end

      end
    end
  end
end