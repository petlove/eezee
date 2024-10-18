# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'

module Eezee
  class Request
    ACCESSORS = %i[
      after
      before
      headers
      logger
      open_timeout
      params
      path
      payload
      protocol
      raise_error
      timeout
      url
      url_encoded
      preserve_url_params
      ddtrace
      retry_opts
    ].freeze

    RETRYABLE_EXCEPTIONS = [
      *Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS,
      Errno::ECONNRESET,
      Faraday::ConflictError,
      Faraday::ConnectionFailed
    ].uniq.freeze

    DEFAULT = {
      headers: {},
      logger: false,
      params: {},
      payload: {},
      raise_error: false,
      url_encoded: false,
      preserve_url_params: false,
      ddtrace: {},
      retry_opts: {
        max: 2,
        interval: 0.5,
        exceptions: RETRYABLE_EXCEPTIONS,
        methods: %i[delete get head options put],
        retry_statuses: [409, 429]
      }
    }.freeze

    attr_accessor(*(ACCESSORS | %i[uri method]))

    def initialize(options = {})
      setup!(options)
    end

    def log
      Eezee::Logger.request(self, @method.to_s.upcase)
    end

    def attributes
      ACCESSORS.each_with_object({}) { |accessor, obj| obj[accessor] = send(accessor) }
    end

    def before!(*params)
      hook!(:before, params)
    end

    def after!(*params)
      hook!(:after, params)
    end

    private

    def setup!(options = {})
      accessors!(DEFAULT.merge(options || {}))
      validate!
      build_urn!
      handle_query_params!
      handle_urn_params! unless @preserve_url_params
    end

    def hook!(hook, params)
      return unless send(hook).is_a?(Proc)

      send(hook).call(*params[0..(send(hook).parameters.length - 1)])
    end

    def validate!
      return if ENV['EEZEE_DISCARD_REQUEST_VALIDATIONS']

      raise Eezee::RequiredFieldError.new(self.class, :url) unless @url
    end

    def accessors!(params)
      params.slice(*ACCESSORS)
            .each { |k, v| instance_variable_set(:"@#{k}", v) }
    end

    def build_urn!
      @uri = [@protocol, [@url, @path].compact.join('/')].compact.join('://')
    end

    def handle_urn_params!
      return unless @params.is_a?(Hash)

      @params.filter { |k, _v| @uri.include?(":#{k}") }
             .each   { |k, v|  @uri.gsub!(":#{k}", v.to_s) }
             .then   { @uri.gsub!(/:[a-z_-]+/, '') }
             .then   { @uri.gsub!(%r{/$}, '') }
    end

    def handle_query_params!
      return unless @params.is_a?(Hash)

      @params.reject { |k, _v| @uri.include?(":#{k}") }
             .map    { |k, v|  "#{k}=#{v}" }
             .then   { |array| array.join('&') }
             .then   { |query| query unless query.empty? }
             .then   { |query| @uri = [@uri, query].compact.join('?') }
    end
  end
end
