module Braspag
  CAPTURE_TRANSACTION_SUCCESS_STATUS = "0"
  VOID_TRANSACTION_SUCCESS_STATUS = "0"
  AUTHORIZE_TRANSACTION_SUCCESS_STATUS = ["0", "1"]
  TRANSACTION_STATUS_CODE_DESCRIPTION = {
    "0" => "undefined",
    "1" => "captured",
    "2" => "authorized",
    "3" => "unauthorized",
    "4" => "canceled",
    "5" => "refunded",
    "6" => "waiting",
    "7" => "desqualified"
  }

  class ResponseHandler
    def authorize_transaction(response)
      Braspag.steps_logger.info('ResponseHandler#authorize_transaction')
      data = response.body[:authorize_transaction_response][:authorize_transaction_result]

      if data[:success]
        payment_data_response = data[:payment_data_collection][:payment_data_response]
        status =  payment_data_response[:status]

        if AUTHORIZE_TRANSACTION_SUCCESS_STATUS.include? status
          respond_with_success(payment_data_response.merge(data[:order_data]))
        else
          respond_with_failure(data)
        end

      else
        respond_with_failure(data)
      end
    end

    def capture_transaction(response)
      Braspag.steps_logger.info('ResponseHandler#capture_transaction')
      data = response.body[:capture_credit_card_transaction_response][:capture_credit_card_transaction_result]

      if data[:success]
        data_collection = data[:transaction_data_collection][:transaction_data_response]

        if data_collection[:status] == CAPTURE_TRANSACTION_SUCCESS_STATUS
          respond_with_success(data_collection)
        else
          respond_with_failure(data)
        end

      else
        respond_with_failure(data)
      end
    end

    def void_transaction(response)
      Braspag.steps_logger.info('ResponseHandler#void_transaction')
      data = response.body[:void_credit_card_transaction_response][:void_credit_card_transaction_result]

      if data[:success]
        data_collection = data[:transaction_data_collection][:transaction_data_response]

        if data_collection[:status] == VOID_TRANSACTION_SUCCESS_STATUS
          respond_with_success(data_collection)
        else
          respond_with_failure(data_collection)
        end

      else
        respond_with_failure_transaction(data)
      end
    end

    def get_credit_card(response)
      data = response.body[:get_credit_card_response][:get_credit_card_result]
      credit_card_response_for(data)
    end

    def save_credit_card(response)
      data = response.body[:save_credit_card_response][:save_credit_card_result]
      credit_card_response_for(data)
    end

    def get_payment_status(response)
      data = response.body[:get_order_data_response][:get_order_data_result]
      if data[:success]
        transaction = data[:transaction_data_collection][:order_transaction_data_response]
        if transaction.present?
          respond_with_success(payment_status: TRANSACTION_STATUS_CODE_DESCRIPTION[transaction[:status]])
        else
          respond_with_failure(data.merge({error_message: "No transaction response"}))
        end
      else
        respond_with_failure(data)
      end
    end

    def get_braspag_order_id(response)
      data = response.body[:get_order_id_data_response][:get_order_id_data_result]
      if data[:success]
        transaction_response = data[:order_id_data_collection].try(:[], :order_id_transaction_response)
        if transaction_response.present? && transaction_response.count > 0
          respond_with_success(braspag_order_id: transaction_response.first[:braspag_order_id])
        else
          respond_with_failure(data.merge({error_message: "No transaction response"}))
        end
      else
        respond_with_failure(data)
      end
    end

    def handle_error(response)
      Braspag.steps_logger.info('ResponseHandler#handle_error')
      OpenStruct.new(:success? => false, :data => response)
    end

    private

    def respond_with_failure_transaction(data)
      Braspag.steps_logger.info('ResponseHandler#respond_with_failure_transaction')

      error_report = data[:error_report_data_collection][:error_report_data_response]
      respond_with_failure({:return_code => error_report[:error_code], :return_message => error_report[:error_message]})
    end

    def credit_card_response_for(data)
      if data[:success]
        OpenStruct.new(:success? => true, :data => data)
      else
        error_report = data[:error_report_collection][:error_report]
        OpenStruct.new(:success? => false, :error_code => error_report[:error_code], :error_message => error_report[:error_message])
      end
    end

    def respond_with_success(data)
      OpenStruct.new(:success? => true, :data => data)
    end

    def respond_with_failure(data)
      Braspag.steps_logger.info('ResponseHandler#respond_with_failure')
      data[:error_report_data_collection] ||= { error_report_data_response: { error_code: 'nil', error_message: 'nil' }}
      data_response = data[:error_report_data_collection][:error_report_data_response]

      OpenStruct.new(:success? => false,
                     :error_code => data_response[:error_code],
                     :error_message => data_response[:error_message],
                     :error_data => data)
    end
  end
end
