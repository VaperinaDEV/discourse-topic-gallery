# frozen_string_literal: true

describe "Topic Gallery", type: :system do
  fab!(:user)
  fab!(:topic)

  let(:gallery_page) { PageObjects::Pages::TopicGallery.new }

  before { SiteSetting.topic_gallery_enabled = true }

  it "displays the topic title on the gallery page" do
    sign_in(user)
    gallery_page.visit_gallery(topic)

    expect(gallery_page).to have_topic_title(topic.title)
    expect(gallery_page).to have_gallery_container
  end

  it "can be accessed from any topic" do
    sign_in(user)
    visit("/t/#{topic.slug}/#{topic.id}")

    page.visit("/t/#{topic.slug}/#{topic.id}/gallery")

    expect(page).to have_current_path("/t/#{topic.slug}/#{topic.id}/gallery")
    expect(gallery_page).to have_topic_title(topic.title)
  end
end
