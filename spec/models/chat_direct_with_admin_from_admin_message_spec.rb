# == Schema Information
#
# Table name: chat_direct_with_admin_from_admin_messages
#
#  id                             :integer          not null, primary key
#  message                        :text(65535)      not null
#  chat_direct_with_admin_room_id :integer          not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#
# Indexes
#
#  direct_admin_message_from_admin  (chat_direct_with_admin_room_id)
#

require 'rails_helper'

RSpec.describe ChatDirectWithAdminFromAdminMessage, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
