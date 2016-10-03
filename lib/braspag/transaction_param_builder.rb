module Braspag
  class TransactionParamBuilder
    attr_accessor :params

    def initialize(params)
      @params = params
    end

    def authorize
      { "request" => {
          "RequestId" => SecureRandom.uuid,
          "OrderData" => {"MerchantId" => Braspag.merchant_id, "OrderId" => params["OrderId"]},
          "CustomerIdentity" => params["CustomerIdentity"],
          "PaymentDataCollection" => Braspag.payment_data_request_xml_builder.new(params),
          "CustomerData" => {
            "CustomerName" => params["CustomerName"],
            "CustomerIdentity" => params["CustomerIdentity"],
            "CustomerEmail" => params["CustomerEmail"]
          },
          "CustomerAddressData" => {
            "Street" => params["Street"],
            "ZipCode" => params["ZipCode"],
            "City" => params["City"],
            "State"=> params["State"],
            "Country" => params["Country"]
          },
          "Version" => 1 }
      }
    end

    def capture
      { "request" => {
        "RequestId" => SecureRandom.uuid,
        "Version" => 1,
        "MerchantId" => Braspag.merchant_id,
        "TransactionDataCollection" => {
          "TransactionDataRequest" => {
            "BraspagTransactionId" => params["BraspagTransactionId"],
            "Amount" => params["Amount"]
          },
        }
      }
      }
    end

    def get_payment_status
      {
        "orderDataRequest" => {
          "RequestId" => SecureRandom.uuid,
          "Version" => 1,
          "MerchantId" => Braspag.merchant_id,
          "BraspagOrderId" => params["BraspagOrderId"]
        }
      }
    end

    def get_braspag_order_id
      {
        "orderIdDataRequest" => {
          "RequestId" => SecureRandom.uuid,
          "Version" => 1,
          "MerchantId" => Braspag.merchant_id,
          "OrderId" => params["OrderId"]
        }
      }
    end

  end
end
