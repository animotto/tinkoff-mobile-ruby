# frozen_string_literal: true

require 'net/http'
require 'json'

module TinkoffMobile
  ##
  # API
  class API
    URI_BASE = 'https://www.tinkoff.ru'
    URI_MOBILE = "#{URI_BASE}/api/mobile-operator"
    URI_SESSION = "#{URI_MOBILE}/util/session"
    URI_SESSION_STATUS = "#{URI_MOBILE}/util/session_status"
    URI_SIGNUP_PHONE = "#{URI_MOBILE}/auth/signup_by_phone_web"
    URI_CONFIRM_SIGNUP_PHONE = "#{URI_MOBILE}/auth/confirm_signup_by_phone_web"
    URI_CONTRACTS_INFO = "#{URI_MOBILE}/user/contracts_info"
    URI_SUBSCRIBER_SERVICES = "#{URI_MOBILE}/user/subscriber_services"
    URI_BUNDLE_ACCOUNTS = "#{URI_MOBILE}/user/bundle_accounts"
    URI_AUTO_PAYMENTS = "#{URI_MOBILE}/payment/get_autopayments"

    PLATFORM = 'web'
    ORIGIN = 'web,ib5,platform'
    APP_NAME = 'mvno'

    attr_accessor :session_id

    def initialize
      uri = URI.parse(URI_BASE)
      @client = Net::HTTP.new(uri.host, uri.port)
      @client.use_ssl = uri.instance_of?(URI::HTTPS)
    end

    ##
    # Returns new session ID
    def session
      data = request(
        URI_SESSION,
        {
          'origin' => ORIGIN,
          'platform' => PLATFORM,
          'appName' => APP_NAME
        }
      )
      @session_id = data['moSessionId']
      data
    end

    ##
    # Returns session status
    def session_status
      request(
        URI_SESSION_STATUS,
        {
          'testSessionId' => @session_id,
          'platform' => PLATFORM,
          'origin' => ORIGIN,
          'appName' => APP_NAME
        }
      )
    end

    ##
    # Signups by phone number (MSISDN)
    def signup_by_phone(phone)
      data = request(
        URI_SIGNUP_PHONE,
        {
          'moSessionId' => @session_id,
          'onContact' => false,
          'msisdn' => phone,
          'platform' => PLATFORM,
          'origin' => ORIGIN,
          'appName' => APP_NAME
        }
      )
      @confirm_id = data['confirmationId']
      data
    end

    ##
    # Confirms signup by phone number (MSISDN) with SMS code (two factor authentication)
    def confirm_signup_by_phone(code)
      request(
        URI_CONFIRM_SIGNUP_PHONE,
        {
          'moSessionId' => @session_id,
          'code' => code,
          'confirmationId' => @confirm_id,
          'platform' => PLATFORM,
          'origin' => ORIGIN,
          'appName' => APP_NAME
        }
      )
    end

    ##
    # Returns contracts info
    def contracts_info
      request(
        URI_CONTRACTS_INFO,
        {
          'moSessionId' => @session_id,
          'platform' => PLATFORM,
          'origin' => ORIGIN,
          'appName' => APP_NAME
        }
      )
    end

    ##
    # Returns subscriber services
    def subscriber_services
      request(
        URI_SUBSCRIBER_SERVICES,
        {
          'moSessionId' => @session_id,
          'platform' => PLATFORM,
          'origin' => ORIGIN,
          'appName' => APP_NAME
        }
      )
    end

    ##
    # Returns auto payments
    def autopayments(phone)
      request(
        URI_AUTO_PAYMENTS,
        {
          'moSessionId' => @session_id,
          'phoneNumber' => phone,
          'platform' => PLATFORM,
          'origin' => ORIGIN,
          'appName' => APP_NAME
        }
      )
    end

    ##
    # Returns bundle accounts
    def bundle_accounts
      request(
        URI_BUNDLE_ACCOUNTS,
        {
          'moSessionId' => @session_id,
          'platform' => PLATFORM,
          'origin' => ORIGIN,
          'appName' => APP_NAME
        }
      )
    end

    private

    def get(path, params = {})
      uri = URI.parse(path)
      uri.query = URI.encode_www_form(params)
      response = @client.get(uri)
      response.body
    end

    def request(path, params = {})
      response = get(path, params)
      data = JSON.parse(response)
      raise APIError.new(data), data['code'] unless data['resultCode'] == 'OK'

      data['payload']
    end
  end

  ##
  # API Error
  class APIError < StandardError
    attr_reader :result_code, :code, :message, :payload

    def initialize(data)
      super
      @result_code = data['resultCode']
      @code = @message = data['code']
      @result_message = data['message']
      @payload = data['payload']
    end

    def to_s
      "#{@code} (#{@result_message})"
    end
  end
end
