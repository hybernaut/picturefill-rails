require 'picturefill/view_helper'
require 'picturefill/config'

require 'picturefill/engine' if defined?(::Rails::Engine)

module Picturefill
  
  extend Config
  
  class << self  
    def initialize attrs={}
      attrs = Picturefill.options.merge(attrs)
      Config::VALID_OPTION_KEYS.each do |key|
        instance_variable_set("@#{key}".to_sym, attrs[key])
      end
    end
  end  
  
end
