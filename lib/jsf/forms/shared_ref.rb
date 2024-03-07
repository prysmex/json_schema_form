module JSF
  module Forms
    
    #
    # Represents a placeholder for a form that may be referenced
    #
    class SharedRef < BaseHash

      include JSF::Core::Schemable
      include JSF::Validations::Validatable
      include JSF::Validations::DrySchemaValidatable

      ##################
      ###VALIDATIONS####
      ##################

      # @param passthru [Hash{Symbol => *}] Options passed
      # @return [Dry::Schema::JSON] Schema
      def dry_schema(passthru)
        ref_presence = run_validation?(passthru, :ref_presence)

        Dry::Schema.JSON do
          config.validate_keys = true
          if ref_presence
            required(:$ref).filled{ int? }
          else
            required(:$ref).maybe{ int? }
          end
        end
      end

      # # @param passthru [Hash{Symbol => *}]
      # def errors(**passthru)
      #   super
      # end

      ##############
      ###METHODS####
      ##############

      # Finds the shared pair inside the 'properties' key
      # 
      # @note it assumes shareds are at root schema
      #
      # @return [NilClass, JSF::Forms::Field::Shared]
      def shared
        parent = self.root_parent
        return unless parent

        parent[:properties]&.find do |k,v|
          v.is_a?(JSF::Forms::Field::Shared) &&
          self.db_id == v.db_id
        end&.last
      end

      # Extracts the id from the json pointer
      #
      # @return [Integer]
      def db_id
        self[:$ref]
      end

      # Update the db id in the shared_def_pointer
      #
      # @param [Integer]
      # @return [void]
      def db_id=(id)
        self[:$ref] = id
      end

      # @return [Boolean]
      def valid_for_locale?(locale=nil)
        true
      end

    end

  end
end