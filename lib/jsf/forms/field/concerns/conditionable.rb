module JSF
  module Forms
    module Field
      module Concerns
        module Conditionable
          def prepend_property(*args, **kwargs, &block)
            meta.dig(:parent).prepend_conditional_property(*args, dependent_on: key_name, **kwargs, &block)
          end

          def append_property(*args, **kwargs, &block)
            meta.dig(:parent).append_conditional_property(*args, dependent_on: key_name, **kwargs, &block)
          end

          def insert_property_at_index(*args, **kwargs, &block)
            meta.dig(:parent).insert_conditional_property_at_index(*args, dependent_on: key_name, **kwargs, &block)
          end

          def find_or_add_condition(*arguments, &block)
            meta.dig(:parent).find_or_add_condition(key_name, *arguments, &block)
          end

          # delegate
          def example(*arguments)
            meta.dig(:parent).example(*arguments)
          end
        end
      end
    end
  end
end