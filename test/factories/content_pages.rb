# == Schema Information
#
# Table name: activities
#
#  id                      :integer          not null, primary key
#  access                  :integer          default("public"), not null
#  access_token            :string(16)       not null
#  allow_unsafe            :boolean          default(FALSE), not null
#  description_en_present  :boolean          default(FALSE)
#  description_format      :string(255)
#  description_nl_present  :boolean          default(FALSE)
#  draft                   :boolean          default(TRUE)
#  name_en                 :string(255)
#  name_nl                 :string(255)
#  path                    :string(255)
#  repository_token        :string(64)       not null
#  search                  :string(4096)
#  series_count            :integer          default(0), not null
#  status                  :integer          default("ok")
#  type                    :string(255)      default("Exercise"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  judge_id                :integer
#  programming_language_id :bigint
#  repository_id           :integer
#
# Indexes
#
#  fk_rails_f60feebafd                         (programming_language_id)
#  index_activities_on_judge_id                (judge_id)
#  index_activities_on_name_nl                 (name_nl)
#  index_activities_on_path_and_repository_id  (path,repository_id) UNIQUE
#  index_activities_on_repository_id           (repository_id)
#  index_activities_on_repository_token        (repository_token) UNIQUE
#  index_activities_on_status                  (status)
#
# Foreign Keys
#
#  fk_rails_...  (judge_id => judges.id)
#  fk_rails_...  (programming_language_id => programming_languages.id)
#  fk_rails_...  (repository_id => repositories.id)
#

require "#{File.dirname(__FILE__)}/../testhelpers/stub_helper.rb"
using StubHelper

FactoryBot.define do
  factory :content_page do
    access { 'public' }
    status { 'ok' }
    draft { false }

    sequence(:path) { |n| "content_page#{n}" }

    repository { Repository.find(1) } # load python repo fixture

    trait :generated_repo do
      repository factory: %i[repository git_stubbed]
    end

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
