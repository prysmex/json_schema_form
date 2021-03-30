module SchemaForm
  module Field
    class Static < ::SuperHash::Hasher

      include ::SchemaForm::Field::Base
      include JsonSchema::StrictTypes::Null

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema(passthru)
        Dry::Schema.define(parent: super) do
          required(:type)
          required(:static).filled(Types::True)
          required(:displayProperties).hash do
            optional(:hiddenOnCreate).maybe(:bool)
            required(:sort).filled(:integer)
          end
        end
      end

      def valid_for_locale?(locale = :es)
        true
      end

    end
  end
end