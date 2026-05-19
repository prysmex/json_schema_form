# frozen_string_literal: true

# Allows activating cache at a global level (not all cache is tied to this)
module JSF
  class Current < ActiveSupport::CurrentAttributes
    attribute :use_cache, default: -> { false }
  end
end