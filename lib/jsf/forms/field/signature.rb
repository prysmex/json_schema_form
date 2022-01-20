module JSF
  module Forms
    module Field
      class Signature < BaseHash

        include ::JSF::Forms::Field::Methods::Base
        # include JSF::Core::Type::Objectable

        set_strict_type('object')
  
        ##################
        ###VALIDATIONS####
        ##################
  
        def validation_schema(passthru)
          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              optional(:hideOnCreate).filled(:bool)
              optional(:hidden).filled(:bool)
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              required(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:component).value(included_in?: ['signature'])
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            required(:properties).hash do
              required(:db_id).hash do
                required(:type).value(included_in?: ['number'])
              end
              required(:name).hash do
                required(:type).value(included_in?: ['string'])
              end
              required(:signature).hash do
                required(:type).value(included_in?: ['string'])
                required(:format).value(included_in?: ['uri'])
              end
            end
            optional(:extra).value(:array?).array(:str?).each(included_in?: ['reports', 'notes', 'pictures']) if passthru[:is_inspection] || passthru[:is_shared]
            required(:required).value(:array, min_size?: 0, max_size?: 3).each(:str?)
            required(:type)
          end
        end

        ##################
        #####METHODS######
        ##################

      end
    end
  end
end