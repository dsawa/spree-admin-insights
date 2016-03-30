module Spree
  class PaymentMethodTransactionsReport < Spree::Report
    HEADERS = [:payment_method_name, :payment_count]

    def generate
      SpreeReportify::ReportDb[:spree_payment_methods___payment_methods].
      join(:spree_payments___payments, payment_method_id: :id).
      where(payments__created_at: @start_date..@end_date). #filter by params
      group(:payment_method_name)
    end

    def select_columns(dataset)
      dataset.select{[
        :payment_methods__name___payment_method_name,
        count(payments__payment_method_id).as(:payment_count)
      ]}
    end
  end
end
