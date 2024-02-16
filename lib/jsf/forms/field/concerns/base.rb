module JSF
  module Forms
    module Field
      module Concerns

        #
        # Defines the base methods for any JSF::Forms::Field class
        # It also includes other core modules
        #
        module Base
  
          def self.included(base)
            # require 'dry-schema'

            base.include JSF::Core::Schemable
            base.include JSF::Validations::Validatable
            base.include JSF::Validations::DrySchemaValidatable
            base.include JSF::Forms::Field::Concerns::InstanceMethods
            base.include JSF::Forms::Field::Concerns::Conditionable
            base.include JSF::Forms::Concerns::DisplayProperties
            base.include JSF::Forms::Concerns::DocumentPath
          end
    
        end
    
        module InstanceMethods

          ##################
          ###VALIDATIONS####
          ##################

          # @param passthru [Hash{Symbol => *}]
          def errors(**passthru)
            errors_hash = super

            # if run_validation?(passthru, :hidden_and_required)
            #   if self.hidden? && self.required?
            #     add_error_on_path(
            #       errors_hash,
            #       ['base'],
            #       'cannot be hidden and required'
            #     )
            #   end
            # end

            # if run_validation?(passthru, :hide_on_create_and_required)
            #   if self.hideOnCreate? && self.required?
            #     add_error_on_path(
            #       errors_hash,
            #       ['base'],
            #       'cannot be hideOnCreate and required'
            #     )
            #   end
            # end

            if (
              self.key?('default') &&
              run_validation?(passthru, :verify_default) &&
              !JSONSchemer.schema(self.as_json).valid?(self['default'])
            )
              add_error_on_path(
                errors_hash,
                ['default'],
                'invalid value'
              )
            end

            errors_hash
          end

          # @param passthru[Hash{Symbol => *}]
          def dry_schema(passthru)
            Dry::Schema.JSON do
              config.validate_keys = true
              optional(:$id).filled{ str? & format?(/\A#\/properties\/(?:\w|-)+\z/) }
              optional(:'$schema').filled(:string)
              optional(:title).maybe(:string)
              optional(:default)
            end
          end

          # Check if field is valid for a locale
          # The simplest case is where the label exists, but each field
          # may implement more validations
          #
          # @param [String,Symbol] locale
          # @return [Boolean]
          def valid_for_locale?(locale = DEFAULT_LOCALE)
            !i18n_label(locale).to_s.empty?
          end

          ##############
          ###METHODS####
          ##############

          # Returns true if field contributes to scoring
          #
          # @return [Boolean]
          def scored?
            false
          end

          # Removes all keys that are not part of the JsonSchema spec
          #
          # @todo should this be renamed?
          #
          # @return [void]
          def legalize!
            self.delete(:displayProperties)
            self
          end
    
        end

      end
    end
  end
end