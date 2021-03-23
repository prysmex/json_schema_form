module SchemaForm
  module Document
    class Meta < ::SuperHash::Hasher

      attribute? :coordinates, default: ->(instance) { {}.freeze }
      attribute? :timestamp, default: ->(instance) { nil }

    end
  end
end