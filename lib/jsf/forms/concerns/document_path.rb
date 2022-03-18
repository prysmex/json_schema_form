module JSF
  module Forms
    module Concerns

      # Converts a schema path into a document path
      #
      module DocumentPath

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

            # if a 'definitions' we must add the key of the 'JSF::Forms::Field::Shared'
            # that matches
            if key == 'definitions'
              target_form = next_schema[schema_path[i + 1]]
              
              shared_field = nil
              root_form.each_form do |form|
                found_prop = form.properties.find do |key, prop|
                  next unless prop.is_a?(JSF::Forms::Field::Shared)
                  prop.shared_definition == target_form #match the field
                end
                if found_prop
                  shared_field = found_prop[1]
                  break
                end
              end
              raise StandardError.new("JSF::Forms::Field::Shared not found for property: #{self.key_name}") unless shared_field
              document_path.push(shared_field.key_name)
            elsif current_schema.is_a?(JSF::Forms::Section)
              raise StandardError.new("fields nested under a JSF::Forms::Section do not support document_path") # we cannot know array index
            end

            next_schema
          end
  
          # add own key name
          document_path.push(self.key_name)
          document_path
        end

      end
      
    end
  end
end