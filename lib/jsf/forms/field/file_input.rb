module JSF
  module Forms
    module Field
      class FileInput < BaseHash

        include ::JSF::Forms::Field::Methods::Base
        include JSF::Core::Type::Arrayable
  
        set_strict_type('array')
  
        ##################
        ###VALIDATIONS####
        ##################
  
        def validation_schema(passthru)
          is_inspection = passthru[:is_inspection]

          Dry::Schema.define(parent: super) do
            required(:type)
            required(:uniqueItems)
            optional(:maxItems)
            required(:items).hash do
              required(:'type').filled(Types::String.enum('string'))
              required(:format).filled(Types::String.enum('uri'))
            end
            required(:displayProperties).hash do
              optional(:hideOnCreate).filled(:bool)
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
              required(:sort).filled(:integer)
              optional(:hidden).filled(:bool)
            end
            required(:extra).value(:array?).array(:str?).each(included_in?: ['actions', 'failed', 'notes', 'pictures', 'score']) if is_inspection
          end
        end
  
        ##################
        #####METHODS######
        ##################
  
        def migrate!
        end
  
      end
    end
  end
end