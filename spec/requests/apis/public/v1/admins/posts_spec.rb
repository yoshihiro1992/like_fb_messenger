require 'spec_helper'

describe Public::V1::Admins::Posts, type: :request do
  def check_post_record_created
    expect {
      post url, params
    }.to change(postable_type, :count).by(1)
    post = postable_type.find_by(chat_direct_with_admin_room: chat_room)
    expect(post).to be_truthy
    case postable_type
    when ChatDirectWithAdminFromAdminMessage
      expect(post.message).to eq message
    when ChatDirectWithAdminFromAdminStamp
      expect(post.stamp_id).to eq stamp_id
    when ChatDirectWithAdminFromAdminImage
      # TODO: compare file content.
      # Probably ImageUploader convert image, so image file is changed.
      expect(post.image.file.to_file.path.gsub(/\/.+\//,'')).to eq image.original_filename
    end
  end

  def check_chat_post_cache_created
    expect {
      post url, params
    }.to change(ChatPostCache, :count).by(1)
    post_cache = ChatPostCache.find_by(chat_room: chat_room, sender_id: admin['admin']['id'], sender_type: 'Admin')
    post = postable_type.find_by(chat_direct_with_admin_room: chat_room)
    expect(post_cache).to be_truthy
    expect(post_cache.posted_at).to eq post.created_at
    expect(post_cache.postable_type).to eq postable_type.to_s
    case postable_type
    when ChatDirectWithAdminFromAdminMessage
      expect(post_cache.message).to eq post.message
    when ChatDirectWithAdminFromAdminStamp
      expect(post_cache.stamp_id).to eq post.stamp_id
    when ChatDirectWithAdminFromAdminImage
      # TODO: compare file content.
      # Probably ImageUploader convert image, so image file is changed.
      expect(post_cache.image.file.to_file.path.gsub(/\/.+\//,'')).to eq post.image.file.to_file.path.gsub(/\/.+\//,'')
    end
  end

  def check_chat_room_index_cache_updated
    room_cache = ChatRoomIndexCache.find_by(chat_room: chat_room)
    post = postable_type.find_by(chat_direct_with_admin_room: chat_room)
    expect(room_cache.last_sent_at).to eq post.created_at
    case postable_type
    when ChatDirectWithAdminFromAdminMessage
      expect(room_cache.last_sent_message).to eq post.message
    when ChatDirectWithAdminFromAdminStamp
      expect(room_cache.last_sent_message).to eq I18n.t('chat_room_index_cache.last_sent_message_template.stamp_sent', name: admin['admin']['name'])
    when ChatDirectWithAdminFromAdminImage
      expect(room_cache.last_sent_message).to eq I18n.t('chat_room_index_cache.last_sent_message_template.image_sent', name: admin['admin']['name'])
    end
  end

  def check_chat_post_json_response
    expect(json['chat_post']['postable_type']).to eq postable_type.to_s
    expect(json['chat_post']['chat_room_id']).to eq chat_room.id
    expect(json['chat_post']['sender']['id']).to eq admin['admin']['id']
    expect(json['chat_post']['sender']['last_name']).to eq admin['admin']['last_name']
    expect(json['chat_post']['sender']['first_name']).to eq admin['admin']['first_name']
    expect(json['chat_post']['sender']['type']).to eq 'Admin'
    case json['chat_post']['postable_type']
    when 'ChatDirectWithAdminFromAdminMessage'
      expect(json['chat_post']['message']).to eq message
    when 'ChatDirectWithAdminFromAdminStamp'
      expect(json['chat_post']['stamp_id']).to eq stamp_id
    when 'ChatDirectWithAdminFromAdminImage'
      post_cache = ChatPostCache.find_by(chat_room: chat_room, sender_id: admin['admin']['id'], sender_type: 'Admin')
      expect(json['chat_post']['image']['image']['url']).to eq "/uploads/chat_post_cache/image/#{post_cache.id}/#{image.original_filename}"
    end
  end

  let(:access_token) { 'accesstoken' }
  let(:admin) do
    { 'admin' =>
      {
        'id' => 1,
        'first_name' => 'first_name',
        'last_name' => 'last_name',
        'name' => 'last_name first_name',
        'access_token' => access_token
      }
    }
  end
  let(:users) do
    { 'users' =>
      [
        {
          'id' => 1,
          'first_name' => 'first_name1',
          'last_name' => 'last_name1',
          'name' => 'last_name1 first_name1'
        }
      ]
    }
  end
  let(:chat_room) do
    chat_room = create(:chat_direct_with_admin_room, admin_id: admin['admin']['id'], user_id: users['users'][0]['id'])
    chat_room.cache!(name: "#{users['users'][0]['name']} / #{admin['admin']['name']}")
    chat_room
  end

  describe 'POST /' do
    let(:url) { '/v1/admins/posts' }
    before do
      allow_any_instance_of(RequlMobileAdminsApi).to receive(:request)
        .with(:get,
              "#{RequlMobileAdminsApi::INTERNAL_BASE_URL}/v1/admins/me",
              { access_token: access_token, application_token: RequlMobileAdminsApi::APPLICATION_TOKEN })
        .and_return(admin)
    end
    context 'content_type is message' do
      let(:params) { { content_type: 'message', room_id: chat_room.id, message: message, access_token: access_token } }
      let(:postable_type) { ChatDirectWithAdminFromAdminMessage }
      context 'message is present' do
        let(:message) { 'chat message' }
        it 'returns status code 201' do
          post url, params
          expect(response.status).to eq 201
        end
        it 'creates ChatDirectWithAdminFromAdminMessage record' do
          check_post_record_created
        end
        it 'creates ChatPostCache record' do
          check_chat_post_cache_created
        end
        it 'updates ChatRoomIndexCache record' do
          post url, params
          check_chat_room_index_cache_updated
        end
        it 'returns json response' do
          post url, params
          check_chat_post_json_response
        end
      end
      context 'message is blank' do
        let(:message) { '' }
        before do
          post url, params
        end
        it { expect(response.status).to eq 400 }
      end
    end
    context 'content_type is stamp' do
      let(:params) { { content_type: 'stamp', room_id: chat_room.id, stamp_id: stamp_id, access_token: access_token } }
      let(:postable_type) { ChatDirectWithAdminFromAdminStamp }
      context 'stamp_id is present' do
        let(:stamp_id) { 1 }
        it 'returns status code 201' do
          post url, params
          expect(response.status).to eq 201
        end
        it 'creates ChatDirectWithAdminFromAdminStamp record' do
          check_post_record_created
        end
        it 'creates ChatPostCache record' do
          check_chat_post_cache_created
        end
        it 'updates ChatRoomIndexCache record' do
          post url, params
          check_chat_room_index_cache_updated
        end
        it 'returns json response' do
          post url, params
          check_chat_post_json_response
        end
      end
      context 'stamp_id is blank' do
        let(:stamp_id) { nil }
        before do
          post url, params
        end
        it { expect(response.status).to eq 400 }
      end
    end
    context 'content_type is image' do
      let(:params) { { content_type: 'image', room_id: chat_room.id, image: image, access_token: access_token } }
      let(:postable_type) { ChatDirectWithAdminFromAdminImage }
      context 'image is present' do
        let(:image) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'images', 'finc_logo.jpg'), 'image/jpeg') }
        it 'returns status code 201' do
          post url, params
          expect(response.status).to eq 201
        end
        it 'creates ChatDirectWithAdminFromAdminImage record' do
          check_post_record_created
        end
        it 'creates ChatPostCache record' do
          check_chat_post_cache_created
        end
        it 'updates ChatRoomIndexCache record' do
          post url, params
          check_chat_room_index_cache_updated
        end
        it 'returns json response' do
          post url, params
          check_chat_post_json_response
        end
      end
      context 'image is blank' do
        let(:image) { nil }
        before do
          post url, params
        end
        it { expect(response.status).to eq 400 }
      end
    end
  end
end
