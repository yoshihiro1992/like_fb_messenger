class RequlMobileUsersApi
  BASE_URL = "#{Settings.requl_mobile.api_base_url}"
  INTERNAL_BASE_URL = "#{Settings.requl_mobile.api_base_url}/internal"
  APPLICATION_TOKEN = Settings.requl_mobile.application_token

  def initialize(access_token)
    @access_token = access_token
  end

  def me(version = :v3)
    url = "#{BASE_URL}/#{version}/me"
    response = request(:get, url, { access_token: @access_token })
    if response.has_key?('user')
      response['user']
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def user_info(user_id, version: :v3)
    url = "#{BASE_URL}/#{version}/users/#{user_id}"
    response = request(:get, url, { access_token: @access_token, user_id: user_id })
    if response.has_key?('user')
      response['user']
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def mutually_follow?(target_user_id, version: :v1)
    url = "#{INTERNAL_BASE_URL}/#{version}/follows/confirm_mutually_follow"
    request(:get, url, { access_token: @access_token, target_user_id: target_user_id })
  end

  def candidates(page = 1, version: :v1)
    url = "#{INTERNAL_BASE_URL}/#{version}/follows/mutually_follows_list"
    request(:get, url, { access_token: @access_token, page: page })
  end

  class << self
    def users(ids, version: :v1)
      url = "#{INTERNAL_BASE_URL}/#{version}/users/list"
      JSON.parse(HTTParty.send(:get, url, { body: { user_ids: ids, application_token: APPLICATION_TOKEN }}).body)
    end
  end

  private

    def request(method, url, params)
      JSON.parse(HTTParty.send(method, url, { body: params }).body)
    end
end
