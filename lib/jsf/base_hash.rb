require 'super_hash'

# base class used for all schema objects inside this gem
# it includes `SuperHash::Hasher` and inherits from  `ActiveSupport::HashWithIndifferentAccess`
# This makes it much por simpler since we do not need to worry about handling strings and symbols

module JSF
  class BaseHash < ActiveSupport::HashWithIndifferentAccess
    include SuperHash::Hasher
  
    # prevent bug when an attribute has a default Proc and the attribute is a string but passed value
    # is a symbol
    #
    # @example
    #   attribute 'allOf', default: ->(data) { [].freeze } # passed data => {allOf: []}
    def initialize(init_value, options={})
      init_value&.transform_keys!{|k| convert_key(k) }
      super(init_value, options)
    end
  
    # ensure key is string since the beggining since :SuperHash::Hasher methods are called
    # before ActiveSupport::HashWithIndifferentAccess logic happens.
    #
    # @see []= (super runs after validation and other logic)
    def []=(key, value, **params)
      super(convert_key(key), convert_value(value), **params)
    end
  
  end
end