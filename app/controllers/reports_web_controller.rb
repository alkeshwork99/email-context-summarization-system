class ReportsWebController < WebController
  before_action :authenticate_web_request

  def firm
    unless current_accountant.admin?
      return render "errors/forbidden", status: :forbidden
    end

    add_request_span_attributes("report.type" => "firm")
    @report = ReportService.firm_summary_report(current_accountant)
  end

  def global
    unless current_accountant.superuser?
      return render "errors/forbidden", status: :forbidden
    end

    add_request_span_attributes("report.type" => "global")
    @reports = ReportService.global_summary_report
  end
end
