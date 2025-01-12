require 'uri'

class OtcMarketsController < ApplicationController
  def show
    attempts_left ||= 3
    response = Faraday.get(market_variables_url, params.slice(:lang), 'Cookie' => request.headers['HTTP_COOKIE'])
    if response.status.to_i % 100 == 4
      head response.status
    else
      response.assert_success!
      @data = JSON.load(response.body).deep_symbolize_keys
    end
  rescue Faraday::Error::TimeoutError => e
    (attempts_left -= 1) > 0 ? retry : raise
  end

  private

  def market_variables_url
    url = URI.parse(ENV.fetch('PLATFORM_ROOT_URL'))
    url = URI.join(url, '/otc_markets/')
    URI.join(url, params[:otc_market_id] + '.json')
  end
end
