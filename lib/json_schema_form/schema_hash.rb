require 'super_hash'

# base class
class SchemaHash < Hash#ActiveSupport::HashWithIndifferentAccess
  include ::SuperHash::Hasher
end