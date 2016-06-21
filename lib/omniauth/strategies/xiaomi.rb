require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Xiaomi < OmniAuth::Strategies::OAuth2

      option :name, "xiaomi"

      option :client_options, {
          :site          => 'https://hmservice.mi-ae.com.cn',
          :authorize_url => 'https://account.xiaomi.com/oauth2/authorize',
          :token_url     => 'https://account.xiaomi.com/oauth2/token'
      }

      option :response_type, 'code'
      option :authorize_options, %i(scope response_type redirect_uri)

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
            :raw_info => raw_info
        }
      end

      def raw_info
        @raw_info ||= MultiJson.load(access_token.get('/user/info/getData').body)
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
    end
  end
end
