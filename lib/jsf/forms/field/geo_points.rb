module JSF
  module Forms
    module Field
      class GeoPoints < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Stringable

        set_strict_type('array')

        ##################
        ###VALIDATIONS####
        ##################

        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          extras = run_validation?(passthru, :extras, optional: true)

          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(included_in?: ['geopoints'])
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
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            if extras
              optional(:extra).value(:array?).array(:str?).each(included_in?: ['reports', 'notes', 'pictures'])
            end
            required(:items).hash do
              required(:required).value(included_in?: [['lat', 'lng']])
              required(:properties).hash do
                required(:lat).hash do
                  required(:type).value(included_in?: ['number'])
                  required(:minimum).value(included_in?: [-90])
                  required(:maximum).value(included_in?: [90])
                end
                required(:lng).hash do
                  required(:type).value(included_in?: ['number'])
                  required(:minimum).value(included_in?: [-180])
                  required(:maximum).value(included_in?: [180])
                end
              end
              required(:'type').filled(Types::String.enum('object'))
            end
            optional(:maxItems)
            optional(:minItems)
            required(:type)
          end
        end

        ##################
        #####METHODS######
        ##################

        def sample_value
          min = self['minItems'] || 1

          (0...min).each_with_object([]) do |_, acum|
            acum.push({
              'lat' => rand(-90..90),
              'lng' => rand(-180..180)
            })
          end
        end

      end
    end
  end
end