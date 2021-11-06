require 'super_hash'

# base class used for all schema objects inside this gem
# it includes `SuperHash::Hasher` and inherits from  `ActiveSupport::HashWithIndifferentAccess`
# This makes it much por simpler since we do not need to worry about handling strings and symbols

module JSF
  class BaseHash < ActiveSupport::HashWithIndifferentAccess
    include SuperHash::Hasher

    attr_reader :init_options
  
    # prevent bug when an attribute has a default Proc and the attribute is a string but passed value
    # is a symbol
    #
    # @example
    #   attribute 'allOf', default: ->(data) { [].freeze } # passed data => {allOf: []}
    def initialize(init_value, init_options={})

      # save init_options so we can pass them on @#dup
      @init_options = init_options

      init_value&.transform_keys!{|k| convert_key(k) } unless init_value.is_a?(ActiveSupport::HashWithIndifferentAccess)
      super(init_value, init_options)
    end
  
    # ensure key is string since the beggining since :SuperHash::Hasher methods are called
    # before ActiveSupport::HashWithIndifferentAccess logic happens.
    #
    # @see []= (super runs after validation and other logic)
    def []=(key, value, **params)
      super(convert_key(key), convert_value(value), **params)
    end

    # ActiveSupport::HashWithIndifferentAccess has its own implementation of dup,
    # which ignores all instance variables. We need that all 'dup' instances are
    # exactaly the same, so we ensure they are initialized the same way the original
    # instance was, mainly by passing init_options
    #
    # @override
    #
    # @see https://github.com/rails/rails/blob/v6.1.4.1/activesupport/lib/active_support/hash_with_indifferent_access.rb#L254
    #
    def dup
      self.class.new(self.to_hash, self.init_options).tap do |new_hash|
        set_defaults(new_hash)
      end
    end
  
  end
end