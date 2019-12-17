# frozen_string_literal: true

module Katinguele
  class Configuration
    attr_reader :services

    def initialize
      @services = {}
    end

    def add_service(name, options)
      return unless name && options

      @services[name] = Request.new(options)
    end

    def find_service(name)
      @services[name]
    end

    def request_by(request, options)
      return request.tap { request.setup!(options) } if request

      Request.new(options) if options&.any?
    end
  end
end