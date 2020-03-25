FactoryBot.define do
  factory :annotation do
    line_nr { 1 }
    annotation_text { 'This code does not contain the right parameters' }
    submission
    user
  end
end
