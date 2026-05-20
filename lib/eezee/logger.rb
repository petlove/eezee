# frozen_string_literal: true

module Eezee
  module Logger
    SENSITIVE_HEADERS = %w[Authorization Ocp-Apim-Subscription-Key].freeze

    module_function

    def request(req, method)
      message('request', req, method)
      nil
    end

    def response(res)
      message('response', res)
    end

    def error(err)
      message('error', err.response, nil, err.class)
    end

    def message(type, content, method = nil, klass = nil)
      if type == 'request'
        log_hash = {
          type: 'request',
          method: method,
          uri: content.uri,
          headers: filter_headers(content.headers),
          payload: content.payload
        }.compact

        p log_hash.to_json
        return nil
      end

      log_hash = {
        type: type,
        klass: klass,
        success: content.success?,
        timeout: content.timeout?,
        code: content.code,
        body: content.body
      }.compact

      p log_hash.to_json
    end

    def filter_headers(headers)
      return headers unless headers.is_a?(Hash)

      headers.to_h do |key, value|
        SENSITIVE_HEADERS.any? { |s| s.casecmp(key.to_s).zero? } ? [key, '[FILTERED]'] : [key, value]
      end
    end
  end
end
