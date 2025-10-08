# frozen_string_literal: true

require 'faraday'
require 'faraday/net_http_persistent'
require 'faraday/retry'
require 'json'

module Eezee
  module Client
    module Requester
      METHODS = %i[get post patch put delete].freeze

      def self.extended(base)
        METHODS.each do |method|
          base.send(
            :define_singleton_method,
            method,
            ->(options = {}) { eezee_client_request(options, method) }
          )
        end
      end

      def eezee_client_request(options, method)
        request = build_final_request(options, method)

        build_faraday_client(request)
          .then { |client| build_faraday_request(request, client, method) }
          .then { |response| Eezee::Response.new(response) }
          .tap  { |response| response.log if request.logger }
          .tap  { |response| request.after!(request, response, nil) }
      rescue Faraday::Error => e
        response = Eezee::Response.new(e)
        error = Eezee::RequestErrorFactory.build(request, response)
        error.log if request.logger
        return response if rescue_faraday_error?(request, response, error)

        raise error
      end

      def build_final_request(options, method)
        build_eezee_request_lazy

        Eezee.configuration
             .request_by(eezee_options[:request], options)
             .tap do |request|
          request.before!(request)
          request.method = method
          request.log if request.logger
        end
      end

      def build_eezee_request_lazy
        return unless eezee_options.dig(:service_options, :lazy)

        build_eezee_request(force: true)
      end

      def rescue_faraday_error?(req, res, err)
        req.after!(req, res, err) || (err.is_a?(Eezee::TimeoutError) && !req.raise_error)
      end

      def build_faraday_request(req, client, method)
        path = req.uri.sub("#{client.url_prefix.to_s}/", '')

        client.send(method, path) do |faraday_req|
          faraday_req.headers = req.headers if req.headers
          faraday_req.options[:open_timeout] = req.open_timeout if req.open_timeout
          faraday_req.options[:timeout] = req.timeout if req.timeout
          faraday_req.request :url_encoded if req.url_encoded
          build_faraday_request_body(faraday_req, req)
        end
      end

      def build_faraday_request_body(faraday_req, req)
        return unless req.payload

        faraday_req.body = req.payload

        return if req.url_encoded
        return if req.headers[:'Content-Type'] == 'application/xml'

        faraday_req.body = faraday_req.body.to_json
      end

      def build_faraday_client(request)
        @faraday_clients ||= {}
        url = "#{request.protocol}://#{request.url.to_s}"

        @faraday_clients[url] ||= Faraday.new(url) do |config|
          faraday_client_options!(config, request)
        end
      end

      def faraday_client_options!(config, request) # rubocop:disable Metrics
        config.request :url_encoded if request.url_encoded
        config.use(Faraday::Retry::Middleware, **request.retry_opts)
        config.use(Faraday::Response::RaiseError) if request.raise_error
        config.headers = request.headers if request.headers
        config.options[:open_timeout] = request.open_timeout if request.open_timeout
        config.options[:timeout] = request.timeout if request.timeout
        config.adapter :net_http_persistent do |http|
          http.idle_timeout = 30
        end
        config.use(:ddtrace, request.ddtrace) if request.ddtrace.any?
      end
    end
  end
end
