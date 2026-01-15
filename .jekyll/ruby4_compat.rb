# Ruby 4.0 Compatibility Patch - Loaded very early
# This patch fixes the 'untaint' and 'tainted?' method issues in Liquid 4.0.3
# Both methods were removed in Ruby 4.0

if RUBY_VERSION >= "4.0.0"
  # Add taint/untaint methods as no-ops - must be defined before Liquid loads
  # Add to Object so it works for all objects including nil
  class Object
    def untaint
      self
    end unless method_defined?(:untaint)
    
    def taint
      self
    end unless method_defined?(:taint)
    
    def tainted?
      false
    end unless method_defined?(:tainted?)
  end
end
