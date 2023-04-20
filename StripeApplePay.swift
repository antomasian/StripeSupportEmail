import Foundation
import StripeApplePay
import PassKit
import os

class BackendModel {
    // You can replace this with your own backend URL.
    // Visit https://glitch.com/edit/#!/stripe-integration-tester and click "remix".
    static let backendAPIURL = URL(string: "https://stripeapplepay-nwda4pvhcq-uc.a.run.app")!
    //URL(string: "https://stripe-integration-tester.glitch.me")!

//    static let returnURL = "stp-integration-tester://stripe-redirect"

    public static let shared = BackendModel()

    func fetchPaymentIntent(completion: @escaping (String?) -> Void) {
        let params = ["integration_method": "Apple Pay"]
        getAPI(method: "create_pi", params: params) { (json) in
            guard let paymentIntentClientSecret = json["paymentIntent"] as? String else {
                completion(nil)
                return
            }
            completion(paymentIntentClientSecret)
        }
    }

    func loadPublishableKey(completion: @escaping (String) -> Void) {
        let params = ["integration_method": "Apple Pay"]
        getAPI(method: "get_pub_key", params: params) { (json) in
          if let publishableKey = json["publishableKey"] as? String {
            completion(publishableKey)
          } else {
            assertionFailure("Could not fetch publishable key from backend")
          }
        }
    }

    private func getAPI(method: String, params: [String: Any] = [:], completion: @escaping ([String: Any]) -> Void) {
        var request = URLRequest(url: Self.backendAPIURL.appendingPathComponent(method))
        request.httpMethod = "POST"

        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, _, error) in
          guard let unwrappedData = data,
                let json = try? JSONSerialization.jsonObject(with: unwrappedData, options: []) as? [String: Any] else {
            if let data = data {
                print(String(decoding: data, as: UTF8.self))
            } else {
                print(error ?? NSError())  // swiftlint:disable:this discouraged_direct_init
            }
            return
          }
          DispatchQueue.main.async {
            completion(json)
          }
        })
        task.resume()
    }
}

class StripeApplePay : NSObject, ObservableObject, ApplePayContextDelegate {

    @Published var paymentStatus: STPApplePayContext.PaymentStatus?
    @Published var lastPaymentError: Error?
    var clientSecret: String?
    let logger = Logger(subsystem: BUNDLE_ID, category: "StripeApplePay")

    func pay(clientSecret: String?) {
        self.clientSecret = clientSecret
        // Configure our Apple Pay payment request object
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: "merchant.tangosocial.tango", country: "US", currency: "USD")
        
        // displayed to user on payment sheet
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Banana", amount: NSDecimalNumber(string: "0.25")),
            PKPaymentSummaryItem(label: "Apple", amount: NSDecimalNumber(string: "0.10"))
        ]
        
        // Present Apple Pay Context
        let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self)
        applePayContext?.presentApplePay()
    }
    
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        // Payment method was created -> confirm our PaymentIntent
        print("payment method is \(paymentMethod)")
        if (self.clientSecret != nil) {
            // Call the completion block w the clientSecret
            print("Received clientSecret \(self.clientSecret)")
            completion(clientSecret, nil)
        } else {
            completion(nil, NSError())
        }
    }
    
    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Error?) {
        // Get the payment status or error
        self.paymentStatus = status
        self.lastPaymentError = error
        self.logger.error("payment error: \(error)")
        print("payment status: \(status)")
        
        switch status {
        case .success:
            // Payment succeeded, show a receipt view
            print("payment status: \(status)")
            break
        case .error:
            // Payment failed, show the error
            print("payment status: \(status)")
            break
        case .userCancellation:
            // User canceled the payment
            print("payment status: \(status)")
            break
        }
    }
    
    
}
