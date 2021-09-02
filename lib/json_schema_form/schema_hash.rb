require 'super_hash'

# base class
class SchemaHash < Hash#ActiveSupport::HashWithIndifferentAccess
  include ::SuperHash::Hasher

  def initialize(init_value=nil, options={})
    super(init_value, options)
  end

end