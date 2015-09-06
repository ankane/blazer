module Blazer
  class ChecksController < BaseController
    before_action :set_check, only: [:show, :edit, :update, :destroy, :run]

    def index
      @checks = Blazer::Check.joins(:blazer_query).includes(:blazer_query).order("state, blazer_queries.name, blazer_checks.id").to_a
      @checks.select! { |c| "#{c.blazer_query.name} #{c.emails}".downcase.include?(params[:q]) } if params[:q]
    end

    def new
      @check = Blazer::Check.new
    end

    def create
      @check = Blazer::Check.new(check_params)
      @check.creator = current_user if respond_to?(:current_user) && Blazer.user_class

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
      @query = @check.blazer_query
    end

    private

    def check_params
      params.require(:check).permit(:blazer_query_id, :emails)
    end

    def set_check
      @check = Blazer::Check.find(params[:id])
    end
  end
end
