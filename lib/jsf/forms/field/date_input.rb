module JSF
  module Forms
    module Field
      class DateInput < BaseHash

        include ::JSF::Forms::Field::Methods::Base
        include JSF::Core::Type::Stringable
  
        set_strict_type('string')
  
        ##################
        ###VALIDATIONS####
        ##################
        
        def validation_schema(passthru)
          is_inspection = passthru[:is_inspection]

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
            required(:extra).value(:array?).array(:str?).each(included_in?: ['actions', 'failed', 'notes', 'pictures', 'score']) if is_inspection
            required(:format).filled(Types::String.enum('date-time'))
            required(:type)
          end
        end
  
        ##############
        ###METHODS####
        ##############
  
        def migrate!
        end
  
      end
    end
  end
end