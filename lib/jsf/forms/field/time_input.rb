require 'time'

module JSF
  module Forms
    module Field
      class TimeInput < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Stringable
  
        set_strict_type('string')
  
        ##################
        ###VALIDATIONS####
        ##################
        
        def dry_schema(passthru)
          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(included_in?: ['time_input'])
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
            if passthru[:extras]
              optional(:extra).value(:array?).array(:str?).each(included_in?: ['reports', 'notes', 'pictures'])
            end
            required(:pattern).value(eql?: '^(?:(?:[0-1][0-9])|(?:[2][0-4])):[0-5][0-9](?::[0-5][0-9])?$')
            required(:type)
          end
        end
  
        ##############
        ###METHODS####
        ##############

        def sample_value
          time = Time.now + rand(0...86400)
          time.strftime('%H:%M:%S')
        end
  
      end
    end
  end
end