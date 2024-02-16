module JSF
  module Validations

    # Adds the ability to recursively build an errors hash by calling `errors`.
    # Each encountered subschema should respond to `errors`.
    #
    # requirements:
    #
    # - `JSF::Core::Schemable`
    # - `JSF::Core::Buildable`

    module Validatable

      # @note
      # Override this method to implement own errors,
      # always call super to support:
      #
      # - recursive errors
      # - ensuring errors is a ActiveSupport::HashWithIndifferentAccess
      #
      # @todo implement
      #
      # @example 
      # schema.errors(
      #   recursive: true,
      #   if: [(instance, key)->{ false }]
      #   proc: nil
      # )
      #
      # @param [Proc] if
      # @param [Proc] unless
      # @param [Boolean] recursive if true, calls errors for all subschemas
      # @param passthru [Hash{Symbol => *}] options to be passed
      # @return [ActiveSupport::HashWithIndifferentAccess]
      def errors(recursive: true, **passthru)
        passthru[:recursive] = recursive # add to passthru

        errors_hash = if recursive
          subschemas_errors(**passthru)
        else
          ActiveSupport::HashWithIndifferentAccess.new({})
        end

        instance_exec(errors_hash, &passthru[:proc]) if passthru[:proc].is_a? Proc

        errors_hash
      end
      
      private
      
      # Builds errors hash for all subschemas. It support two keys to
      # filter which subschemas' errors will be called
      #
      # @param [Proc] if
      # @param [Proc] unless
      # @param passthru [Hash{Symbol => *}] options to be passed
      # @return [ActiveSupport::HashWithIndifferentAccess]
      def subschemas_errors(**passthru)
        acum_subschemas_errors = {}

        # recursively yield all subschemas
        send_recursive(:tap) do |subschema|
          next if self == subschema # skip own call
          next unless subschema.respond_to?(:errors)

          subschema_errors = subschema.errors(**passthru, recursive: false)
          next if subschema_errors.empty?
  
          relative_path = subschema.meta[:path].slice((self.meta[:path].size)..-1)
          
          # create path if it does not exists
          if acum_subschemas_errors.dig(*relative_path).nil?
            SuperHash::Utils.bury(acum_subschemas_errors, *relative_path, {})
          end
  
          # merge new errors
          acum_subschemas_errors.dig(*relative_path).merge!(subschema_errors)
        end

        ActiveSupport::HashWithIndifferentAccess.new(acum_subschemas_errors)
      end
      
      # Utility to safely add an error on a nested path
      #
      # @param [Hash] errors_hash
      # @param [Array<String,Symbol>] path
      # @param [String] str error to add
      # @return [String] added error
      def add_error_on_path(errors_hash, path, str)
        current = errors_hash
        path.each.with_index do |key, i|
          if (i + 1) == path.size
            current[key] ||= []
            current[key] << str
          else
            current[key] ||= {}
            current = current[key]
          end
        end
        str
      end

      # # passthru utils

      # # Util for safely checking if a key with an array contains an element
      # #
      # # @param [Hash] passthru errors passthru hash
      # # @param [Symbol] passthru hash key
      # # @param [] value
      # # @return [Boolean]
      # def key_contains?(passthru, key, value)
      #   !!passthru[key]&.include?(value)
      # end

      # Util that determines if a validation should run
      # Use this method inside the +errors+ method when overriding it
      #
      # @param [Hash] passthru errors passthru hash
      # @param [Symbol] validation_key error specific key
      # @retunr [Boolean]
      def run_validation?(passthru, validation_key)
        return false if passthru.key?(:if) && !passthru[:if].call(self, validation_key)
        return false if passthru[:unless]&.call(self, validation_key)
        true
      end

    end
  end
end