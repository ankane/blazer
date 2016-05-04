module Blazer
  class ChecksController < BaseController
    before_action :set_check, only: [:edit, :update, :destroy, :run]

    def index
      @checks = Blazer::Check.joins(:query).includes(:query).order("state, blazer_queries.name, blazer_checks.id").to_a
      @checks.select! { |c| "#{c.query.name} #{c.emails}".downcase.include?(params[:q]) } if params[:q]
    end

    def new
      @check = Blazer::Check.new
    end

    def create
      @check = Blazer::Check.new(check_params)
      # use creator_id instead of creator
      # since we setup association without checking if column exists
      @check.creator = blazer_user if @check.respond_to?(:creator_id=)

      if @check.save
        redirect_to run_check_path(@check)
      else
        render :new
      end
    end

    def update
      if @check.update(check_params)
        redirect_to run_check_path(@check)
      else
        render :edit
      end
    end

    def destroy
      @check.destroy
      redirect_to checks_path
    end

    def run
      @query = @check.query
    end

    private

    def check_params
      params.require(:check).permit(:query_id, :emails, :invert, :schedule)
    end

    def set_check
      @check = Blazer::Check.find(params[:id])
    end
  end
end
