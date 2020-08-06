module JsonSchemaForm
  module Document
    class Extras < ::SuperHash::Hasher

      attribute? :images, default: ->(instance) { [].freeze }
      attribute? :score, default: ->(instance) { nil }
      attribute? :failed, default: ->(instance) { nil }
      attribute? :notes, default: ->(instance) { nil }
      attribute? :action_ids, default: ->(instance) { [].freeze }

    end
  end
end