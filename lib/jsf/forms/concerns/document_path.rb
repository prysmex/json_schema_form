# frozen_string_literal: true

module JSF
  module Forms
    module Concerns

      # Converts a schema path into a document path
      #
      module DocumentPath

        # Returns the path where the data of the field is in a JSF::Forms::Document
        # It supports both properties inside the schema or properties added by a JSF::Forms::Form
        # inside '$defs'
        #
        # @example
        #   {
        #     $defs: {
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
        def document_path(section_indices: nil)
          section_indices = section_indices.dup if section_indices.is_a?(::Array)
          schema_path = meta[:path]
          root_form = root_parent
          doc_path = []

          schema_path.each_with_index.inject(root_form) do |current_schema, (key, i)|
            next_schema = current_schema[key]

            # if a '$defs' we must add the key of the 'JSF::Forms::Field::Shared'
            # that matches
            if key == '$defs'
              target_form = next_schema[schema_path[i + 1]]

              shared_field = nil
              root_form.each_form do |form|
                form.properties.each_value do |prop|
                  next unless prop.is_a?(JSF::Forms::Field::Shared) &&
                              prop.shared_def == target_form # match the field

                  shared_field = prop
                  break
                end
                break if shared_field
              end

              unless shared_field
                raise StandardError.new("JSF::Forms::Field::Shared not found for property: #{key_name}")
              end

              doc_path.push(shared_field.key_name)
            elsif current_schema.is_a?(JSF::Forms::Section)

              if section_indices.present? # rubocop:disable Style/GuardClause
                doc_path.push(current_schema.key_name)
                val = section_indices.is_a?(::Array) ? section_indices.shift : section_indices
                doc_path.push(val)
              else
                # we cannot know array index
                raise StandardError.new('fields nested under a JSF::Forms::Section do not support document_path')
              end
            end

            next_schema
          end

          # add own key name
          doc_path.push(key_name)
          doc_path
        end

      end

    end
  end
end