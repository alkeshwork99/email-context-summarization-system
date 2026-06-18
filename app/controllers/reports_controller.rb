class ReportsController < ApplicationController
  before_action :authenticate_request

  def firm
    return forbidden unless current_accountant.admin?

    add_request_span_attributes("report.type" => "firm")
    render json: ReportService.firm_summary_report(current_accountant)
  end

  def global
    return forbidden unless current_accountant.superuser?

    add_request_span_attributes("report.type" => "global")
    render json: ReportService.global_summary_report
  end
end
