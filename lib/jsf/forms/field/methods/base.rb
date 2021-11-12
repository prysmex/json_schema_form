module JSF
  module Forms
    module Field
      module Methods

        #
        # Defines the base methods for any JSF::Forms::Field class
        # It also includes other core modules
        #
        module Base
  
          def self.included(base)
            require 'dry-schema'

            base.include JSF::Core::Schemable
            base.include JSF::Validations::Validatable
            base.include JSF::Forms::Field::Methods::InstanceMethods
          end
    
        end
    
        module InstanceMethods

          ##################
          ###VALIDATIONS####
          ##################

          # @param passthru [Hash{Symbol => *}]
          def errors(**passthru)
            errors = JSF::Validations::DrySchemaValidatable::CONDITIONAL_SCHEMA_ERRORS_PROC.call(
              passthru,
              self
            )

            # ToDo add error to base
            if run_validation?(passthru, self, :hidden_and_required)
              if self.hideOnCreate? && self.required?
                add_error_on_path(
                  errors,
                  ['base'],
                  'cannot be hideOnCreate and required'
                )
              end
            end

            super.merge(errors)
          end

          # @param passthru[Hash{Symbol => *}]
          def validation_schema(passthru)
            Dry::Schema.JSON do
              config.validate_keys = true
              optional(:$id).filled{ str? & format?(/\A#\/properties\/(?:\w|-)+\z/) }
              optional(:'$schema').filled(:string)
              optional(:title).maybe(:string)
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

          # Get hidden display property
          #
          # @return [Boolean] true when hidden
          def hidden?
            !!self.dig(:displayProperties, :hidden)
          end

          # Set hidden display property
          #
          # @param [Boolean]
          # @return [Boolean]
          def hidden=(value)
            SuperHash::Utils.bury(self, :displayProperties, :hidden, value)
          end

          # Get hideOnCreate display property
          #
          # @return [Boolean] value
          def hideOnCreate?
            !!self.dig(:displayProperties, :hideOnCreate)
          end

          # Set hidden display property
          #
          # @param [Boolean] value
          # @return [Boolean]
          def hideOnCreate=(value)
            SuperHash::Utils.bury(self, :displayProperties, :hideOnCreate, value)
          end

          # Get sort value
          #
          # @return [<Type>] <description>
          def sort
            self.dig(:displayProperties, :sort)
          end

          # Set sort value
          #
          # @return [<Type>] <description>
          def sort=(value)
            SuperHash::Utils.bury(self, :displayProperties, :sort, value)
          end
          
          # get the field's i18n label
          #
          # @param [String,Symbol] locale
          # @return [String]
          def i18n_label(locale = DEFAULT_LOCALE)
            self.dig(:displayProperties, :i18n, :label, locale)
          end
    
          # set the field's i18n label
          #
          # @param [String,Symbol] locale
          # @param [String] locale
          # @return [String]
          def set_label_for_locale(label, locale = DEFAULT_LOCALE)
            SuperHash::Utils.bury(self, :displayProperties, :i18n, :label, locale, label)
          end

          # Returns the path where the data of the field is in a JSF::Forms::Document
          # It supports both properties inside the schema or properties added by a JSF::Forms::Form
          # inside 'definitions'
          #
          # @example
          #   {
          #     definitions: {
          #       some_key_2: {
          #         properties: {
          #           migrated_hazards9999: {}
          #         },
          #         allOf: [
          #           {
          #             then: {
          #               properties: {
          #                 other_hazards_9999: {}
          #               }
          #             }
          #           }
          #         ]
          #       }
          #     },
          #     properties: {
          #       some_key_2_9999: { ref: :some_key_2}
          #     }
          #   }
          #
          # @return [Array<String>]
          def document_path
            path = self.meta[:path]
            new_path = []
        
            if path[0] == 'definitions' # fields inside 'definitions'
              root_form = self.root_parent
              component_field = nil
              root_form.schema_form_iterator do |_, form|
                found_prop = form.properties.find do |key, prop|
                  next unless prop.is_a?(JSF::Forms::Field::Component)
                  prop.component_definition == root_form.dig(*path.slice(0..1)) #match the field
                end
                if found_prop
                  component_field = found_prop[1]
                  break
                end
              end
              raise StandardError.new("JSF::Forms::Field::Component not found for property: #{self.key_name}") unless component_field
              new_path.push(component_field.key_name)
            end
    
            new_path.push(self.key_name)
            new_path
          end

          # Removes all keys that are not part of the JsonSchema spec
          #
          # @todo should this be renamed?
          #
          # @return [void]
          def compile!
            self.delete(:displayProperties)
          end
    
        end

      end
    end
  end
end