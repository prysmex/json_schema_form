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
            base.include JSF::Forms::Concerns::DisplayProperties
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

          # Returns true if field contributes to scoring
          #
          # @return [Boolean]
          def scored?
            # raise NoMethodError.new('this field does not implement scored?')
            false
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
            schema_path = self.meta[:path]
            root_form = self.root_parent
            document_path = []

            schema_path.each_with_index.inject(root_form) do |current_schema, (key, i)|
              next_schema = current_schema[key]

              # if a 'definitions' we must add the key of the 'JSF::Forms::Field::Component'
              # that matches
              if key == 'definitions'
                target_form = next_schema[schema_path[i + 1]]
                
                component_field = nil
                root_form.each_form do |form|
                  found_prop = form.properties.find do |key, prop|
                    next unless prop.is_a?(JSF::Forms::Field::Component)
                    prop.component_definition == target_form #match the field
                  end
                  if found_prop
                    component_field = found_prop[1]
                    break
                  end
                end
                raise StandardError.new("JSF::Forms::Field::Component not found for property: #{self.key_name}") unless component_field
                document_path.push(component_field.key_name)
              elsif current_schema.is_a?(JSF::Forms::Section)
                document_path.push(current_schema.key_name)
              end

              next_schema
            end
    
            # add own key name
            document_path.push(self.key_name)
            document_path
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