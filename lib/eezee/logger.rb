# frozen_string_literal: true

module Eezee
  module Logger
    module_function

    # rubocop:disable Metrics/AbcSize
    def request(req, method, single_line_logger = false)
      return single_line_message('request', req.class, req, method) if single_line_logger

      message('request', req.class, req, method)
    end

    def response(res, single_line_logger = false)
      return single_line_message('response', res.class, res) if single_line_logger

      message('response', res.class, res)
    end

    def error(err, single_line_logger = false)
      return single_line_message('error', err.class, err.response) if single_line_logger

      message('error', err.class, err.response)
    end

    def log(message)
      "INFO -- #{message}"
    end

    def message(type, klass, content, method = nil)
      if type == 'request'
        p log("request: #{method} #{content.uri}")
        p log("request: HEADERS: #{content.headers&.to_json}") if content.headers
        p log("request: PAYLOAD: #{content.payload&.to_json}") if content.payload
        return nil
      end

      p log("#{type}: #{klass}") if type == 'error'
      p log("#{type}: SUCCESS: #{content.success?}")
      p log("#{type}: TIMEOUT: #{content.timeout?}")
      p log("#{type}: CODE: #{content.code}")
      p log("#{type}: BODY: #{content.body&.to_json}")
    end

    def single_line_message(type, klass, content, method = nil)
      if type == 'request'
        parts = ["request: #{method} #{content.uri}"]
        parts << "HEADERS: #{content.headers&.to_json}" if content.headers
        parts << "PAYLOAD: #{content.payload&.to_json}" if content.payload
        p log(parts.join(' '))
        return nil
      end

      parts = [
        "#{type}: SUCCESS: #{content.success?}",
        "TIMEOUT: #{content.timeout?}",
        "CODE: #{content.code}",
        "BODY: #{content.body&.to_json}"
      ]

      parts.unshift("#{type}: #{klass}") if type == 'error'
      p log(parts.join(' '))
    end
    # rubocop:enable Metrics/AbcSize
  end
end
