module JSF
  module Forms
    module Field
      class Video < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Numberable
  
        set_strict_type('number')
  
        ##################
        ###VALIDATIONS####
        ##################
        
        def dry_schema(passthru)
          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(included_in?: ['video'])
              optional(:hidden).filled(:bool)
              optional(:hideOnCreate).filled(:bool)
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              # required(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            required(:min).value(included_in?: [0])
            required(:max).value(included_in?: [100])
            required(:type)
          end
        end
  
        ##############
        ###METHODS####
        ##############

        def sample_value
          rand(0..100)
        end

        def migrate!
          self['format'] = 'date-time'
          self['type'] = 'string'
        end
  
      end
    end
  end
end