module JSF
  module Forms
    module Field
      class Signature < BaseHash

        include JSF::Forms::Field::Concerns::Base
        # include JSF::Core::Type::Objectable

        set_strict_type('object')
  
        ##################
        ###VALIDATIONS####
        ##################

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          extras = run_validation?(passthru, :extras, optional: true)

          Dry::Schema.JSON(parent: super) do
            required(:displayProperties).hash do
              if hide_on_create
                optional(:hideOnCreate).filled(:bool)
              end
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
              required(:component).value(eql?: 'signature')
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            required(:properties).hash do
              required(:db_identifier).hash do
                required(:type).value(eql?: 'number')
              end
              required(:name).hash do
                required(:type).value(eql?: 'string')
              end
              required(:signature).hash do
                required(:type).value(eql?: 'string')
                required(:format).value(eql?: 'uri')
                required(:pattern).value(eql?: '^http')
              end
            end
            required(:additionalProperties).value(eql?: false)
            if extras
              optional(:extra).value(:array?).array(:str?).each(included_in?: %w[reports notes pictures])
            end
            required(:required).value(:array, min_size?: 0, max_size?: 3).each(:str?)
            required(:type)
          end
        end

        ##################
        #####METHODS######
        ##################

        def sample_value
          string_length = 8
          string = rand(36**string_length).to_s(36)

          {
            'db_identifier' => 2,
            'name' => string,
            'signature' => "https://picsum.photos/#{rand(10...500)}",
          }
        end

      end
    end
  end
end