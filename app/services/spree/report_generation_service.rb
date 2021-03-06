module Spree
  class ReportGenerationService

    REPORTS = {
      finance_analysis:           [
                                    :payment_method_transactions, :payment_method_transactions_conversion_rate,
                                    :sales_performance, :shipping_cost, :sales_tax
                                  ],
      product_analysis:           [
                                    :cart_additions, :cart_removals, :cart_updations,
                                    :product_views, :product_views_to_cart_additions,
                                    :product_views_to_purchases, :unique_purchases,
                                    :best_selling_products, :returned_products
                                  ],
      promotion_analysis:         [:promotional_cost, :annual_promotional_cost],
      trending_search_analysis:   [:trending_search],
      user_analysis:              [:user_pool, :users_not_converted, :users_who_recently_purchased]
    }

    def self.generate_report(report_name, options)
      klass = Spree.const_get((report_name.to_s + '_report').classify)
      resource = klass.new(options)
      dataset = resource.generate
      total_records = resource.select_columns(dataset).count
      if resource.no_pagination?
        result_set = dataset
      else
        result_set = resource.select_columns(dataset.limit(options['records_per_page'], options['offset'])).all
      end
      options['no_pagination'] = resource.no_pagination?.to_s unless options['no_pagination'] == 'true'
      [headers(klass, resource, report_name), result_set, total_pages(total_records, options['records_per_page'], options['no_pagination']), search_attributes(klass), resource.chart_json, resource]
    end

    def self.download(options = {}, headers, stats)
      ::CSV.generate(options) do |csv|
        csv << headers.map { |head| head[:name] }
        stats.each do |record|
          csv << headers.map { |head| record[head[:value]] }
        end
      end
    end

    def self.search_attributes(klass)
      search_attributes = {}
      klass::SEARCH_ATTRIBUTES.each do |key, value|
        search_attributes[key] = value.to_s.humanize
      end
      search_attributes
    end

    def self.total_pages(total_records, records_per_page, no_pagination)
      if no_pagination != 'true'
        total_pages = total_records / records_per_page
        if total_records % records_per_page == 0
          total_pages -= 1
        end
        total_pages
      end
    end

    def self.headers(klass, resource, report_name)
      klass::HEADERS.keys.map do |header|
        {
          name: Spree.t(header.to_sym, scope: [:insight, report_name]),
          value: header,
          sorted: resource.try(:header_sorted?, header) ? resource.sortable_type.to_s : nil,
          type: klass::HEADERS[header],
          sortable: header.in?(klass::SORTABLE_ATTRIBUTES)
        }
      end
    end

  end
end
