module JSF
  module Forms
    module Field
      class Markdown < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Nullable
  
        set_strict_type(['string', 'null']) # @deprecate null after migration
  
        ##################
        ###VALIDATIONS####
        ##################

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          exam = run_validation?(passthru, :exam, optional: true)

          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(eql?: 'markdown')
              optional(:hidden).filled(:bool)
              if hide_on_create
                optional(:hideOnCreate).filled(:bool)
              end
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
                if exam
                  required(:title).hash do
                    AVAILABLE_LOCALES.each do |locale|
                      optional(locale.to_sym).maybe(:string)
                    end
                  end
                end
              end
              required(:kind).maybe(:string)
              required(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            required(:format).filled(Types::String.enum('date-time'))
            required(:type)
          end
        end
  
        ##############
        ###METHODS####
        ##############

        def sample_value
          half_range_seconds = 60 * 60 * 24 * 365
          range = (half_range_seconds * -1)...half_range_seconds
          seconds = rand(range)
          (Time.now + seconds).iso8601
        end
  
      end
    end
  end
end