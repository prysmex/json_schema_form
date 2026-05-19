# frozen_string_literal: true

# Allows activating cache at a global level (not all cache is tied to this)
module JSF
  module Current
    def self.use_cache
      Thread.current[:jsf_use_cache]
    end

    # @param value [Boolean]
    def self.use_cache=(value)
      Thread.current[:jsf_use_cache] = value
    end
  end
end