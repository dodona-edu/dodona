json.ready @export.finished?
if @export.finished? && @export.archive.attached?
  json.url rails_blob_path(@export.archive, disposition: "attachment")
end
