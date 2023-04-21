import SwiftUI
import PassKit

struct CheckoutView: View {
    @ObservedObject var eventVM: EventViewModel
    @State var ticketQuantity: Int = 1
    @State var show21Prompt: Bool = false
    @State var showPaymentSuccess = false
    @State var error: Error?
    
    @StateObject var applePayModel = StripeApplePay()
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            // MARK: Guest Info
            Section {
                if eventVM.nTicketsAvailableForPurchase >= 1{
                    Stepper("\(eventVM.nTicketsInCart) Tickets", value: $ticketQuantity, in: 1...eventVM.nTicketsAvailableForPurchase) { _ in
                        eventVM.updateCart(nTickets: ticketQuantity)
                    }
                }
            } header: {
                Text("Guest Info")
            } footer: {
                if let guestsAllowed = eventVM.event.nGuestsAllowed, guestsAllowed > 0 {
                    Text("Each attendee can bring \(guestsAllowed) guest(s). If your guest has a Tango account, you can add them to the event after checkout.")
                }
            }
            
            // MARK: Payment Summary
            if let paymentItems = eventVM.event.paymentItems {
                Section("Payment Summary") {
                    ForEach(0..<paymentItems.count, id: \.self) { idx in
                        let item = paymentItems[idx]
                        paymentItemRow(item: item, quantity: $ticketQuantity)
                    }.listRowSeparator(.hidden, edges: [.top])
                    HStack {
                        Text("Total (\(ticketQuantity))")
                            .bold()
                        Spacer()
                        Text(String(format: "$%.2f", eventVM.cartTotal))
                            .bold()
                    }
                }
            }
            
            // MARK: Pay Button
            Section {
                ApplePayButton(action: {
//                    show21Prompt.toggle()
                    // call our pay method
                    let secret = BackendModel.shared.fetchPaymentIntent { secret in
                        // secret seems to have correct fmt
                        applePayModel.pay(clientSecret: secret)
                    }
                })
                .listRowInsets(EdgeInsets())
            }
            .alert(isPresented: $show21Prompt) {
                Alert(title: Text("Notice"), message: Text("By continuing, you understand that all guests must be 21+ and present valid ID at the event or may be denied entry"), primaryButton: .cancel(Text("Cancel")), secondaryButton: .default(Text("Continue")) {
                        eventVM.getTicket() { result in
                            switch result {
                            case .success(_):
                                self.showPaymentSuccess.toggle()
                            case .failure(let error):
                                self.error = error
                            }
                        }
                })
            }
            .errorAlert(error: $error)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Checkout")
        .fullScreenCover(isPresented: $showPaymentSuccess, onDismiss: { presentationMode.wrappedValue.dismiss() }) {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 72))
                    .foregroundColor(.tangoBluePrimary)
                Text("Success")
                    .fontWeight(.medium)
                    .font(.largeTitle)
                    .foregroundColor(.tangoBluePrimary)
                Text("Can't wait! You should receive a confirmation email shortly.")
                    .padding(.horizontal, 30)
                    .multilineTextAlignment(.center)
                Button {
                    showPaymentSuccess.toggle()
                } label: {
                    Text("Done")
                }
                .accentColor(.tangoBluePrimary)
                .buttonStyle(.borderedProminent)
                Spacer()
                Spacer()
            }
        }
    }
}

struct paymentItemRow: View {
    var item: PaymentItem?
    @Binding var quantity: Int
    var leftText = ""
    var rightText = ""
    var font: Font = .body
    
    var body: some View {
        HStack {
            Text(item?.description ?? leftText)
                .font(font)
            Spacer()
            if let item = self.item {
                Text(String(format: "$%.2f ea", item.price))
                    .font(font)
            } else {
                Text(rightText)
                    .font(font)
            }
        }
    }
}

struct ApplePayButton: UIViewRepresentable {
    var action: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        context.coordinator.action = action
    }
    
    func makeUIView(context: Context) -> PKPaymentButton {
        context.coordinator.button
        //        return PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .black)
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        var button = PKPaymentButton(paymentButtonType: .continue, paymentButtonStyle: .automatic)
        
        init(action: @escaping () -> Void) {
            self.action = action
            super.init()
            
            button.addTarget(self, action: #selector(callback(_:)), for: .touchUpInside)
        }
        
        @objc
        func callback(_ sender: Any) {
            action()
        }
    }
}


struct CheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CheckoutView(eventVM: dummies.upcomingEventVM)
        }
    }
}
