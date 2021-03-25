module SchemaForm
  module Field
    class Info < ::SuperHash::Hasher

      include ::SchemaForm::Field::Base
      include JsonSchema::StrictTypes::Null

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema(passthru)
        Dry::Schema.define(parent: super) do
          required(:type)
          required(:displayProperties).hash do
            optional(:hiddenOnCreate).maybe(:bool)
            required(:pictures).value(:array?).array(:str?)
            required(:i18n).hash do
              required(:label).hash do
                optional(:es).maybe(:string)
                optional(:en).maybe(:string)
              end
            end
            required(:visibility).hash do
              required(:label).filled(:bool)
            end
            required(:kind).filled(:string)
            required(:useInfo).filled(:bool)
            required(:icon).filled(:string)
            required(:sort).filled(:integer)
            required(:hidden).filled(:bool)
          end
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