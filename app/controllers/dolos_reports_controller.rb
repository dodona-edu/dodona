class DolosReportsController < ApplicationController
  def create
    export = Export.find(params[:export_id])

    authorize export, :show?
    return head :unprocessable_entity unless export.finished?

    response = HTTParty.post(
      'https://dolos.ugent.be/api/reports',
      body: {
        dataset: {
          zipfile: export.archive,
          name: export.archive.filename
        }
      }
    )

    render json: response
  end
end
