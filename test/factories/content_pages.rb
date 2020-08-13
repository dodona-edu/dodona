# == Schema Information
#
# Table name: activities
#
#  id                      :integer          not null, primary key
#  name_nl                 :string(255)
#  name_en                 :string(255)
#  description_nl_present  :boolean
#  description_en_present  :boolean
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  path                    :string(255)
#  description_format      :string(255)
#  repository_id           :integer
#  judge_id                :integer
#  status                  :integer          default("ok")
#  access                  :integer          default("public"), not null
#  programming_language_id :bigint
#  search                  :string(4096)
#  access_token            :string(16)       not null
#  repository_token        :string(64)       not null
#  allow_unsafe            :boolean          default(FALSE), not null
#  type                    :string(255)      default("Exercise"), not null
#

require File.dirname(__FILE__) + '/../testhelpers/stub_helper.rb'
using StubHelper

FactoryBot.define do
  factory :content_page do
    access { 'public' }
    status { 'ok' }

    sequence(:path) { |n| "content_page#{n}" }

    association :repository, factory: %i[repository git_stubbed]

    transient do
      name { nil }
      description_html_stubbed { nil }
      description_md_stubbed { nil }
    end

    after :create do |content, c|
      if c.description_html_stubbed
        content.description_format = 'html'
        stub_status(content, 'ok')
        content.stubs(:description_localized).returns(c.description_html_stubbed)
      elsif c.description_md_stubbed
        content.description_format = 'md'
        stub_status(content, 'ok')
        content.stubs(:description_localized).returns(c.description_md_stubbed)
      end
    end

    trait :config_stubbed do
      after :build do |content|
        content.stubs(:update_config)
        content.stubs(:config)
      end
    end

    trait :valid do
      config_stubbed
      after :build do |content|
        content.update(status: :ok)
        stub_status(content, 'ok')
      end
    end

    trait :description_html do
      valid
      description_format { 'html' }
      description_en_present { true }
      description_nl_present { true }
      after :build do |content|
        content.stubs(:description_localized).returns <<~EOS
          <h2 id="los-deze-oefening-op">Los deze oefening op</h2>
          <p><img src="media/img.jpg" alt="media-afbeelding"/>
          <a href="https://google.com">LMGTFY</a>
          <a href="../123455/">Volgende oefening</a></p>
        EOS
      end
    end

    trait :description_md do
      valid
      description_format { 'md' }
      description_en_present { true }
      description_nl_present { true }
      after :build do |exercise|
        exercise.stubs(:description_localized).returns <<~EOS
          ## Los deze oefening op
          ![media-afbeelding](media/img.jpg)
          [LMGTFY](https://google.com)
          [Volgende oefening](../123455/)
        EOS
      end
    end
  end
end
