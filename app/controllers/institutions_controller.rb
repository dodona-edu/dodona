class InstitutionsController < ApplicationController
  def index
    authorize Institution
    @institutions = Institution.all.order(provider: :desc, name: :asc)
    @title = I18n.t('institutions.index.title')
  end
end
