json.array!(@submissions) do |submission|
  json.partial! 'submission_basic', submission: submission
end
