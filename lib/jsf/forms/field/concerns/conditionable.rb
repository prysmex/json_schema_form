# frozen_string_literal: true

module JSF
  module Forms
    module Field
      module Concerns
        module Conditionable
          def prepend_property(*, **, &)
            @meta[:parent].prepend_conditional_property(*, dependent_on: key_name, **, &)
          end

          def append_property(*, **, &)
            @meta[:parent].append_conditional_property(*, dependent_on: key_name, **, &)
          end

          def insert_property_at_index(*, **, &)
            @meta[:parent].insert_conditional_property_at_index(*, dependent_on: key_name, **, &)
          end

          def find_or_add_condition(*, &)
            @meta[:parent].find_or_add_condition(key_name, *, &)
          end

          # delegate
          def example(*)
            @meta[:parent].example(*)
          end
        end
      end
    end
  end
end