# Ruby 4.0 Compatibility Patch for Liquid
# This patch fixes the 'untaint' method issue in Liquid 4.0.3
# Define this immediately when file loads

if RUBY_VERSION >= "4.0.0"
  # Add untaint as a no-op method - must be defined before Liquid uses it
  class String
    def untaint
      self
    end unless method_defined?(:untaint)
  end
end
