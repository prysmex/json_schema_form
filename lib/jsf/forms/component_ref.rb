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
        errors = JSF::Validations::DrySchemaValidatable::CONDITIONAL_SCHEMA_ERRORS_PROC.call(
          passthru,
          self
        )

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
          self.db_id == v.db_id
        end&.last
      end

        # Extracts the id from the json pointer
        #
        # @return [Integer]
        def db_id
          self[:$ref]
        end

        # Update the db id in the component_definition_pointer
        #
        # @param [Integer]
        # @return [void]
        def db_id=(id)
          self[:$ref] = id
        end

    end

  end
end