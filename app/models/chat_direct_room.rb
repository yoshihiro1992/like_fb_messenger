# == Schema Information
#
# Table name: chat_direct_rooms
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ChatDirectRoom < ActiveRecord::Base
  has_many :chat_direct_room_member, dependent: :destroy
  has_many :chat_direct_messages, dependent: :destroy
  has_many :chat_direct_images, dependent: :destroy
  has_many :chat_direct_stamp, dependent: :destroy
end
