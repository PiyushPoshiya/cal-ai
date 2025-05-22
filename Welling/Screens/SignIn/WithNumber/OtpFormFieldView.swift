//
//  OtpFormFieldView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-26.
//

import SwiftUI
import Combine

struct OtpFormFieldView: View {
    //MARK -> PROPERTIES
    
    enum FocusPin: Equatable {
        case  pinOne, pinTwo, pinThree, pinFour, pinFive, pinSix
    }
    
    @FocusState private var pinFocusState : FocusPin?
    @Binding var pinOne: String
    @Binding var pinTwo: String
    @Binding var pinThree: String
    @Binding var pinFour: String
    @Binding var pinFive: String
    @Binding var pinSix: String
    
    
    //MARK -> BODY
    var body: some View {
        VStack {
            HStack(spacing:15, content: {
                TextField("", text: $pinOne)
                    .modifier(OtpModifer(pin:$pinOne))
                    .onChange(of:pinOne){ newPinOne in
                        if (newPinOne.count == 1) {
                            pinFocusState = .pinTwo
                        }
                    }
                    .focused($pinFocusState, equals: .pinOne)
                
                TextField("", text:  $pinTwo)
                    .modifier(OtpModifer(pin:$pinTwo))
                    .onChange(of:pinTwo){ newPinTwo in
                        if (newPinTwo.count == 1) {
                            pinFocusState = .pinThree
                        }else {
                            if (newPinTwo.count == 0) {
                                pinFocusState = .pinOne
                            }
                        }
                    }
                    .focused($pinFocusState, equals: .pinTwo)
                
                
                TextField("", text:$pinThree)
                    .modifier(OtpModifer(pin:$pinThree))
                    .onChange(of:pinThree){ newPinThree in
                        if (newPinThree.count == 1) {
                            pinFocusState = .pinFour
                        }else {
                            if (newPinThree.count == 0) {
                                pinFocusState = .pinTwo
                            }
                        }
                    }
                    .focused($pinFocusState, equals: .pinThree)
                
                
            TextField("", text:$pinFour)
                .modifier(OtpModifer(pin:$pinFour))
                .onChange(of:pinFour) { newPinFour in
                    if (newPinFour.count == 1) {
                        pinFocusState = .pinFive
                    }else {
                        if (newPinFour.count == 0) {
                            pinFocusState = .pinFour
                        }
                    }
                }
                .focused($pinFocusState, equals: .pinFour)
                
                
                TextField("", text:$pinFive)
                    .modifier(OtpModifer(pin:$pinFive))
                    .onChange(of:pinFive) { newPinFive in
                        if (newPinFive.count == 1) {
                            pinFocusState = .pinSix
                        } else {
                            if (newPinFive.count == 0) {
                                pinFocusState = .pinFour
                            }
                        }
                    }
                    .focused($pinFocusState, equals: .pinFive)
                
                
                TextField("", text:$pinSix)
                    .modifier(OtpModifer(pin:$pinSix))
                    .onChange(of:pinSix){ newValue in
                        if (newValue.count == 0) {
                            pinFocusState = .pinFive
                        }
                    }
                    .focused($pinFocusState, equals: .pinSix)
                
                
            })
            .padding(.vertical)
        }
        
    }
}

struct OtpModifer: ViewModifier {
    
    @Binding var pin : String
    
    var textLimt = 1
    
    func limitText(_ upper : Int) {
        if pin.count > upper {
            self.pin = String(pin.prefix(upper))
        }
    }
    
    
    //MARK -> BODY
    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .onReceive(Just(pin)) {_ in limitText(textLimt)}
            .frame(width: 45, height: 45)
            .border(.black)
    }
}
