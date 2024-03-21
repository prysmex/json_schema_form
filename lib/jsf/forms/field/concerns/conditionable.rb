# frozen_string_literal: true

module JSF
  module Forms
    module Field
      module Concerns
        module Conditionable
          def prepend_property(*, **, &)
            meta.dig(:parent).prepend_conditional_property(*, dependent_on: key_name, **, &)
          end

          def append_property(*, **, &)
            meta.dig(:parent).append_conditional_property(*, dependent_on: key_name, **, &)
          end

          def insert_property_at_index(*, **, &)
            meta.dig(:parent).insert_conditional_property_at_index(*, dependent_on: key_name, **, &)
          end

          def find_or_add_condition(*, &)
            meta.dig(:parent).find_or_add_condition(key_name, *, &)
          end

          # delegate
          def example(*)
            meta.dig(:parent).example(*)
          end
        end
      end
    end
  end
end