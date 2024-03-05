json.ready @export.finished?
json.url rails_blob_path(@export.archive, disposition: 'attachment') if @export.finished? && @export.archive.attached?
