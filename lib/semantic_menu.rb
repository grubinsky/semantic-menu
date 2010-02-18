require 'rubygems'
require 'action_view'
require 'active_support'

class MenuItem
  include ActionView::Helpers::TagHelper,
          ActionView::Helpers::UrlHelper
  
  attr_accessor :children, :link
  cattr_accessor :level_class_prefix
  
  def initialize(title, link, level, link_opts={}, li_opts={}, sub_ul_opts={})
    @title, @link, @level, @link_opts, @li_opts, @sub_ul_opts = title, link, level, link_opts, li_opts, sub_ul_opts
    @children = []
  end
  
  def add(title, link, link_opts={}, li_opts={}, sub_ul_opts={}, &block)
    returning(MenuItem.new(title, link, @level +1, link_opts, li_opts, sub_ul_opts)) do |adding|
      @children << adding
      yield adding if block_given?
    end
  end
  
  def to_s
    opts = active? ? {:class => 'active'} : {}
    content_tag :li, link_to(@title, @link, @link_opts) + child_output, opts.merge(@li_opts)
  end
  
  def level_class
    prefix = @@level_class_prefix || "menu_level"
    [prefix, @level].join('_')
  end
  
  def child_output
    children.empty? ? '' : content_tag(:ul, @children.collect(&:to_s).join, {:class => level_class}.merge(@sub_ul_opts))
  end
  
  def active?
    children.any?(&:active?) || on_current_page?
  end
  
  def on_current_page?
    current_page?(@link)
  end
  
  cattr_accessor :controller
  def controller # make it available to current_page? in UrlHelper
    @@controller
  end
end

class SemanticMenu < MenuItem
  
  def initialize(controller, opts={},&block)
   @@controller = controller
   @@level_class_prefix = opts.delete(:level_class_prefix)
    @opts       = {:class => 'menu'}.merge opts
    @level      = 0
    @children   = []
    
    yield self if block_given?
  end

  def to_s
    content_tag(:ul, @children.collect(&:to_s).join, @opts)
  end
end

# Yep, monkey patch ActionView's UrlHelper
# All that changes here is s/@controller/controller
module ActionView
  module Helpers #:nodoc:
    module UrlHelper
      def current_page?(options)
        url_string = CGI.unescapeHTML(url_for(options))
        request = controller.request
        # We ignore any extra parameters in the request_uri if the 
        # submitted url doesn't have any either.  This lets the function
        # work with things like ?order=asc 
        if url_string.index("?")
          request_uri = request.request_uri
        else
          request_uri = request.request_uri.split('?').first
        end
        if url_string =~ /^\w+:\/\//
          url_string == "#{request.protocol}#{request.host_with_port}#{request_uri}"
        else
          url_string == request_uri
        end
      end
    end
  end
end
