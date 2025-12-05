# frozen_string_literal: true

module JSF

  # Use this basic class as ActiveSupport::Cache::MemoryStore is not compatible with complex objects
  # such as Proc
  class SimpleLRUCache
    # @param [Integer] max_size
    def initialize(max_size = 20)
      @max_size = max_size
      clear
    end

    # Write an entry to the cache
    #
    # @param [*] key
    # @param [*] value
    #
    # @return [TrueClass]
    def write(key, value) # rubocop:disable Naming/PredicateMethod
      if @store.key?(key)
        @order.delete(key) # Remove existing key to update its position
      elsif @store.size >= @max_size
        lru_key = @order.shift # Evict the least recently used key
        @store.delete(lru_key)
      end

      @store[key] = value
      @order << key # Mark as most recently used
      true # same behavior as Rails' cache
    end

    # Read an entry from the cache
    # @param [*] key
    # @return [*]
    def read(key)
      return unless @store.key?(key)

      @order.delete(key) # Update usage order
      @order << key
      @store[key]
    end

    # Fetch or store the result of the block
    # @param [*] key
    # @param [Boolean] skip_nil
    # @return [*]
    def fetch(key, skip_nil: false)
      return read(key) if @store.key?(key)

      value = yield if block_given?
      return if skip_nil && value.nil?

      write(key, value)
      value
    end

    # @return [void]
    def clear
      @store = {}
      @order = [] # Tracks keys in usage order
    end
  end

end