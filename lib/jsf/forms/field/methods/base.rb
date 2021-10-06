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
          def own_errors(passthru={})
            JSF::Validations::DrySchemaValidatable::SCHEMA_ERRORS_PROC.call(
              validation_schema(passthru),
              self
            )
          end

          # @param passthru[Hash{Symbol => *}]
          def validation_schema(passthru)
            Dry::Schema.JSON do
              config.validate_keys = true
              optional(:$id).filled(:string)
              optional(:title).maybe(:string)
              optional(:'$schema').filled(:string)
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
          def hiddenOnCreate=(value)
            SuperHash::Utils.bury(self, :displayProperties, :hideOnCreate, value)
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
          # It supports both properties inside the schema or properties added by a shared
          # schema inside definitions
          #
          # @example
          #   {
          #     definitions: {
          #       shared_schema_template_2: {
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
          #       shared_schema_template_2_9999: { ref: :shared_schema_template_2}
          #     }
          #   }
          #
          # @return [Array<String>]
          def document_path
            path = self.meta[:path]
            new_path = []
    
            is_shared_schema_template_field = path[0] == 'definitions'
    
            if is_shared_schema_template_field
              root_form = self.root_parent
              field = nil
              root_form.schema_form_iterator(skip_when_false: true) do |_, form|
                field = form.properties.find do |key, prop|
                  next unless prop.is_a?(JSF::Forms::Field::Component)
                  prop.component_definition == root_form.dig(*path.slice(0..1))
                end
                field = field[1] if field
                !field
              end
              new_path.push(field.key_name)
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