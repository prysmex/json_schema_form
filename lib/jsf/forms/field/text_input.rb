module JSF
  module Forms
    module Field
      class TextInput < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Stringable
  
        set_strict_type('string')
  
        ##################
        ###VALIDATIONS####
        ##################
  
        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          extras = run_validation?(passthru, :extras, optional: true)

          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(eql?: 'text_input')
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
              end
              required(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:textarea).filled(:bool)
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            if extras
              optional(:extra).value(:array?).array(:str?).each(included_in?: %w[reports notes pictures])
            end
            required(:type)
          end
        end
  
        ##################
        #####METHODS######
        ##################

        def sample_value
          string_length = 8
          rand(36**string_length).to_s(36)
        end
  
      end
    end
  end
end