class JudgesController < ApplicationController
  before_action :set_judge, only: [:show, :edit, :update, :destroy]

  # GET /judges
  # GET /judges.json
  def index
    @judges = Judge.all
  end

  # GET /judges/1
  # GET /judges/1.json
  def show
  end

  # GET /judges/new
  def new
    @judge = Judge.new
  end

  # GET /judges/1/edit
  def edit
  end

  # POST /judges
  # POST /judges.json
  def create
    @judge = Judge.new(judge_params)

    respond_to do |format|
      if @judge.save
        format.html { redirect_to @judge, notice: 'Judge was successfully created.' }
        format.json { render :show, status: :created, location: @judge }
      else
        format.html { render :new }
        format.json { render json: @judge.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /judges/1
  # PATCH/PUT /judges/1.json
  def update
    respond_to do |format|
      if @judge.update(judge_params)
        format.html { redirect_to @judge, notice: 'Judge was successfully updated.' }
        format.json { render :show, status: :ok, location: @judge }
      else
        format.html { render :edit }
        format.json { render json: @judge.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /judges/1
  # DELETE /judges/1.json
  def destroy
    @judge.destroy
    respond_to do |format|
      format.html { redirect_to judges_url, notice: 'Judge was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_judge
      @judge = Judge.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def judge_params
      params.require(:judge).permit(:name, :image, :path)
    end
end
