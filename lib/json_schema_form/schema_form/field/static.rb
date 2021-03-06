module SchemaForm
  module Field
    class Static < ::SuperHash::Hasher

      include ::SchemaForm::Field::Base
      include JsonSchema::StrictTypes::Null

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema(passthru)
        can_be_hidden = (passthru[:hideable_static_fields] || []).include?(self.key_name)
        can_be_hidden_on_create = (passthru[:hideable_on_create_static_fields] || []).include?(self.key_name)
        Dry::Schema.define(parent: super) do
          required(:type)
          required(:static).filled(Types::True)
          required(:displayProperties).hash do
            optional(:hidden).filled(:bool) if can_be_hidden
            optional(:hideOnCreate).maybe(:bool) if can_be_hidden_on_create
            required(:sort).filled(:integer)
          end
        end
      end

      def valid_for_locale?(locale = DEFAULT_LOCALE)
        true
      end

      def migrate!
        self[:$id] = "#/properties/#{self.meta[:path].last}"
      end

    end
  end
end