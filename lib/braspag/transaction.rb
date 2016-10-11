module Braspag
  class Transaction
    attr_accessor :soap_adapter, :response_handler, :transaction_param_builder

    def initialize(soap_adapter = SavonAdapter, response_handler = ResponseHandler.new, transaction_param_builder = TransactionParamBuilder)
      @soap_adapter = soap_adapter
      @response_handler = response_handler
      @transaction_param_builder = transaction_param_builder
    end

    def self.authorize(params)
      Braspag::Transaction.new.authorize(params)
    end

    def self.capture(params)
      Braspag::Transaction.new.capture(params)
    end

    def self.cancel(params)
      Braspag::Transaction.new.cancel(params)
    end

    def self.get_payment_status(params)
      Braspag::Transaction.new.get_payment_status(params)
    end

    def self.get_braspag_order_id(params)
      Braspag::Transaction.new.get_braspag_order_id(params)
    end

    def authorize(params)
      Braspag.steps_logger.info('Calling Braspag#authorize')
      request = Request.new(Braspag.transaction_wsdl, :authorize_transaction, build_authorize_credit_card_params(params)) do |request|
        request.on_success {|response| response_handler.authorize_transaction(response) }
        request.on_failure {|response| response_handler.handle_error(response) }
      end

      request.call
    end

    def capture(params)
      Braspag.steps_logger.info('Calling Braspag#capture')
      request = Request.new(Braspag.transaction_wsdl, :capture_credit_card_transaction, build_capture_credit_card_params(params)) do |request|
        request.on_success {|response| response_handler.capture_transaction(response) }
        request.on_failure {|response| response_handler.handle_error(response) }
      end

      request.call
    end

    def cancel(params)
      Braspag.steps_logger.info('Calling Braspag#cancel')
      request = Request.new(Braspag.transaction_wsdl, :void_credit_card_transaction, build_capture_credit_card_params(params)) do |request|
        request.on_success {|response| response_handler.void_transaction(response) }
        request.on_failure {|response| response_handler.handle_error(response) }
      end

      request.call
    end

    def get_payment_status(params)
      Braspag.steps_logger.info('Calling Braspag#get_payment_status')
      braspag_order_id_request = self.get_braspag_order_id(params)
      unless braspag_order_id_request.success?
        return response_handler.handle_error(braspag_order_id_request)
      end
      request = Request.new(Braspag.query_wsdl, :get_order_data, build_get_payment_status_params(params)) do |request|
        request.on_success {|response| response_handler.get_payment_status(response)}
        request.on_failure {|response| response_handler.handle_error(response)}
      end
      request.call
    end

    def get_braspag_order_id(params)
      Braspag.steps_logger.info('Calling Braspag#get_braspag_order_id')
      request = Request.new(Braspag.query_wsdl, :get_order_id_data, build_get_braspag_order_id_params(params)) do |request|
        request.on_success {|response| response_handler.get_braspag_order_id(response)}
        request.on_failure {|response| response_handler.handle_error(response)}
      end
      request.call
    end

    private

    def build_authorize_credit_card_params(params)
      transaction_param_builder.new(params).authorize
    end

    def build_capture_credit_card_params(params)
      transaction_param_builder.new(params).capture
    end

    def build_get_payment_status_params(params)
      transaction_param_builder.new(params).get_payment_status
    end

    def build_get_braspag_order_id_params(params)
      transaction_param_builder.new(params).get_braspag_order_id
    end
  end
end
