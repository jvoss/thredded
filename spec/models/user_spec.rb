# frozen_string_literal: true
require 'spec_helper'

describe User, '.to_s' do
  it "raises error so we're forced to configure and use it correctly" do
    user = build(:user, name: 'Joseph')
    expect { user.to_s }.to raise_error(/deliberate/i)
  end
end

describe User, '.thredded_display_name' do
  before { allow_any_instance_of(User).to receive(:to_s, &:name) }
  it 'returns the users name' do
    expect(build(:user, name: 'Joseph').thredded_display_name).to eq('Joseph')
  end

  it 'raises exception if nil' do
    user = build(:user, name: nil)
    expect(user).to receive(:name).and_return(nil)
    expect { user.thredded_display_name }.to raise_error(/nil.*configure/)
  end

  it 'raises exception if empty string' do
    user = build(:user, name: '')
    expect { user.thredded_display_name }.to raise_error(/nil.*configure/)
  end

  context 'when display method specified' do
    it 'calls method' do
      user = build(:user, name: 'Eric', email: 'eric@gmail.com')
      expect(Thredded).to receive(:user_display_name_method).at_least(:once).and_return(:email)
      expect(user.thredded_display_name).to eq 'eric@gmail.com'
    end

    it 'calls method but raises exception if nil' do
      user = build(:user, name: 'Eric', email: nil)
      expect(user).to receive(:email).and_return(nil)
      expect(Thredded).to receive(:user_display_name_method).at_least(:once).and_return(:email)
      expect { user.thredded_display_name }.to raise_error(/nil.*configure/)
    end
  end

  it 'works for the null user' do
    expect(Thredded::NullUser.new.thredded_display_name).to be_a(String)
  end
end

describe User, 'on deletion' do
  let!(:user) { create(:user) }
  let!(:user_preference) { create(:user_preference, user: user) }
  let!(:user_messageboard_preference) { create(:user_messageboard_preference, user: user) }
  let!(:notifications_for_followed_topics) { create(:notifications_for_followed_topics, user: user) }
  let!(:notifications_for_private_topics) { create(:notifications_for_private_topics, user: user) }
  let!(:messageboard_notifications_for_followed_topics) do
    create(:messageboard_notifications_for_followed_topics, user: user)
  end

  it 'cascades' do
    User.find(user.id).destroy
    expect { user_preference.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { user_messageboard_preference.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { notifications_for_followed_topics.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { notifications_for_private_topics.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { messageboard_notifications_for_followed_topics.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
