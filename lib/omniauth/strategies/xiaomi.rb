require 'cgi'
require 'uri'
require 'oauth2'
require 'omniauth'
require 'timeout'
require 'securerandom'
require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    
    class Response < ::OAuth2::Response

      # The HTTP response body
      def body
        unless response.body.index('&&&START&&&').nil?
          response.body.gsub!(/&&&START&&&/, '')
          @token_request = MultiJson.load(response.body)
        end
        response.body || ''
      end

    end

    class Client < ::OAuth2::Client
   
      def request(verb, url, opts = {}) # rubocop:disable CyclomaticComplexity, MethodLength, Metrics/AbcSize
        connection.response :logger, ::Logger.new($stdout) if ENV['OAUTH_DEBUG'] == 'true'

        opts[:params] = opts[:params].merge({:client_id => id}) if opts[:params]
        url = connection.build_url(url, opts[:params]).to_s
        response = connection.run_request(verb, url, opts[:body], opts[:headers]) do |req|
          yield(req) if block_given?
        end
        response = Response.new(response, :parse => opts[:parse])

        case response.status
        when 301, 302, 303, 307
          opts[:redirect_count] ||= 0
          opts[:redirect_count] += 1
          return response if opts[:redirect_count] > options[:max_redirects]
          if response.status == 303
            verb = :get
            opts.delete(:body)
          end
          request(verb, response.headers['location'], opts)
        when 200..299, 300..399
          # on non-redirecting 3xx statuses, just return the response
          response
        when 400..599
          error = Error.new(response)
          fail(error) if opts.fetch(:raise_errors, options[:raise_errors])
          response.error = error
          response
        else
          error = Error.new(response)
          fail(error, "Unhandled status code value of #{response.status}")
        end
      end

      def get_token(params, access_token_opts = {}, access_token_class = ::OAuth2::AccessToken) # rubocop:disable Metrics/AbcSize
        opts = {:raise_errors => options[:raise_errors], :parse => params.delete(:parse)}
        if options[:token_method] == :post
          headers = params.delete(:headers)
          opts[:body] = params
          opts[:headers] = {'Content-Type' => 'application/x-www-form-urlencoded'}
          opts[:headers].merge!(headers) if headers
        else
          opts[:params] = params
        end
        response = request(options[:token_method], token_url, opts)
        error = Error.new(response)
        fail(error) if options[:raise_errors] && !(response.parsed.is_a?(Hash) && response.parsed['access_token'])
        access_token_class.from_hash(self, response.parsed.merge(access_token_opts))
      end

    end

    class Xiaomi < OmniAuth::Strategies::OAuth2

      option :client_options, {
          :site          => 'https://hmservice.mi-ae.com.cn',
          :authorize_url => 'https://account.xiaomi.com/oauth2/authorize',
          :token_url     => 'https://account.xiaomi.com/oauth2/token',
          :token_method  => :get
      }

      option :response_type, 'code'
      option :authorize_options, %i(response_type redirect_uri)
      option :token_options, %i(client_secret)

      uid do
        raw_info['data']['userid'].to_s
      end

      info do
        {
            :name         => raw_info['data']['username'],
            :gender       => raw_info['data']['gender'],
            :age          => raw_info['data']['age'],
            :steps_goal   => raw_info['data']['stepsGoal'],
            :weight_goal  => raw_info['data']['weightGoal'],
            :weight       => raw_info['data']['weight'],
            :height       => raw_info['data']['height'],
            :weight_unit  => raw_info['data']['weightUnit'],
            :unit         => raw_info['data']['unit']
        }
      end

      extra do
        {
            :raw_info => raw_info, 
            :mac_key  => access_token.params['mac_key']
        }
      end

      def client
        Client.new(options.client_id, options.client_secret, deep_symbolize(options.client_options))
      end

      def raw_info
        time = Time.now 
        data_request_url = "/user/info/getData"
        data_request_url << "?appid=#{ENV['XIAOMI_OAUTH_KEY']}"
        data_request_url << "&third_appid=#{ENV['XIAOMI_THIRD_APPID']}"
        data_request_url << "&third_appsecret=#{ENV['XIAOMI_THIRD_APPSECRET']}"
        data_request_url << "&mac_key=#{access_token.params['mac_key']}"
        data_request_url << "&call_id=#{time.to_time.to_i}"
        data_request_url << "&fromdate=#{time}"
        data_request_url << "&todate=#{time}"
        data_request_url << "&access_token=#{access_token.token}"
        data_request_url << "&v=1.0"
        data_request_url << "&l=english"
        @raw_info ||= MultiJson.load(access_token.get(data_request_url, options).body)
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
    end
  end
end

OmniAuth.config.add_camelization 'xiaomi', 'Xiaomi'
