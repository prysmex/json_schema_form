module JSF
  module Forms
    
    #
    # Represents a placeholder for a form that may be referenced
    #
    class ComponentRef < BaseHash

      include JSF::Core::Schemable
      include JSF::Validations::Validatable

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema(passthru)
        skip_ref_presence = !run_validation?(passthru, self, :ref_presence)

        Dry::Schema.JSON do
          config.validate_keys = true
          if skip_ref_presence
            required(:$ref).maybe{ int? }
          else
            required(:$ref).filled{ int? }
          end
        end
      end

      # @param passthru [Hash{Symbol => *}]
      def errors(**passthru)
        errors = JSF::Validations::DrySchemaValidatable::SCHEMA_ERRORS_PROC.call(validation_schema(passthru), self)
        super.merge(errors)
      end

      ##############
      ###METHODS####
      ##############

      # Finds the component pair inside the 'properties' key
      # 
      # @note it assumes components are at root schema
      #
      # @return [NilClass, JSF::Forms::Field::Component]
      def component
        parent = self.root_parent
        return unless parent

        parent[:properties]&.find do |k,v|
          v.is_a?(JSF::Forms::Field::Component) &&
          self[:$ref] == v.component_ref_id
        end&.last
      end

    end

  end
end