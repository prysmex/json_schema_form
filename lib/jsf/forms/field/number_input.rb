module JSF
  module Forms
    module Field
      class NumberInput < BaseHash

        include ::JSF::Forms::Field::Methods::Base
        include JSF::Core::Type::Numberable
  
        set_strict_type('number')
  
        ##################
        ###VALIDATIONS####
        ##################
  
        def validation_schema(passthru)
          Dry::Schema.define(parent: super) do
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
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            optional(:extra).value(:array?).array(:str?).each(included_in?: ['reports', 'notes', 'pictures']) if passthru[:is_inspection] || passthru[:is_shared]
            required(:type)
          end
        end
  
        ##############
        ###METHODS####
        ##############
  
      end
    end
  end
end