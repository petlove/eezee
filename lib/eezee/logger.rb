# frozen_string_literal: true

module Eezee
  module Logger
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
          headers: content.headers,
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
  end
end
