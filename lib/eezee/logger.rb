# frozen_string_literal: true

module Eezee
  module Logger
    module_function

    # rubocop:disable Metrics/AbcSize
    def request(req, method)
      message('request', req.class, req, method)
      nil
    end

    def response(res)
      message('response', res.class, res)
    end

    def error(err)
      message('error', err.class, err.response)
    end

    def log(message)
      "INFO = #{message}"
    end

    def message(type, klass, content, method = nil)
      if type == 'request'
        log_hash = {
          type: 'request',
          method: method,
          uri: content.uri,
          headers: content.headers,
          payload: content.payload
        }.compact
        p log(log_hash.to_json)
        return nil
      end

      log_hash = {
        type: type,
        klass: (klass if type == 'error'),
        success: content.success?,
        timeout: content.timeout?,
        code: content.code,
        body: content.body
      }.compact

      p log(log_hash.to_json)
    end
    # rubocop:enable Metrics/AbcSize
  end
end
