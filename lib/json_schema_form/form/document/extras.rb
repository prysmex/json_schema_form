module JsonSchemaForm
  module Document
    class Extras < ::SuperHash::Hasher

      attribute? :pictures, default: ->(instance) { [].freeze }
      attribute? :score, default: ->(instance) { nil }
      attribute? :failed, default: ->(instance) { nil }
      attribute? :notes, default: ->(instance) { nil }
      attribute? :report_ids, default: ->(instance) { [].freeze }
      attribute? :action_ids, default: ->(instance) { [].freeze }

    end
  end
end