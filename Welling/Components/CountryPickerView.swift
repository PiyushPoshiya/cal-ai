//
//  CountryPickerView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-25.
//

import SwiftUI

struct CountryPickerView: View {
    @State var presentCountryPickerSheet: Bool = false
    @Binding var selectedCountry: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Country")
                    .fontWithLineHeight(Theme.Text.tinyMedium)
                    .opacity(0.75)
                Text(selectedCountry)
                    .fontWithLineHeight(Theme.Text.mediumMedium)
            }
            .frame(alignment: .leading)
            Spacer()
            ColoredIconView(imageName: "nav-arrow-down")
        }
        .wellingTextFieldStyleWithTitle(focused: false)
        .sheet(isPresented: $presentCountryPickerSheet) {
            CountryPickerSheetView(selectedCountry: $selectedCountry)
                .presentationDetents([.large])
        }
        .onTapGesture {
            presentCountryPickerSheet = true
        }
    }
}

struct CountryPickerSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCountry: String
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(alignment: .center) {
                    Text("Country")
                        .fontWithLineHeight(Theme.Text.h5)
                }
                HStack {
                    IconButtonView("xmark", showBackgroundColor: true) {
                        dismiss()
                    }
                    
                    Spacer()
                }
            }
            .navbar()
            
            ScrollView {
                LazyVStack {
                    ForEach(Self.countries, id: \.hashValue) { country in
                        Button {
                           selectedCountry = country
                        } label: {
                            HStack {
                                Text(country)
                                    .fontWithLineHeight(Theme.Text.mediumMedium)
                                    .foregroundStyle(Theme.Colors.TextNeutral9)
                                Spacer()
                                
                                if selectedCountry == country {
                                    ColoredIconView(imageName: "check-circle")
                                }
                            }
                            .padding(.vertical, Theme.Spacing.small)
                        }
                        .background(Theme.Colors.SurfacePrimary100)
                        .tag(country)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xlarge)
            .padding(.vertical, Theme.Spacing.xlarge)
            .background(Theme.Colors.SurfacePrimary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
            .padding(.horizontal, Theme.Spacing.horizontalPadding)
        }
        .background(Theme.Colors.SurfaceNeutral05)
    }
    
    static let countries: [String] = ["Afghanistan","Åland Islands","Albania","Algeria","American Samoa","Andorra","Angola","Anguilla","Antarctica","Antigua and Barbuda","Argentina","Armenia","Aruba","Australia","Austria","Azerbaijan","Bahamas","Bahrain","Bangladesh","Barbados","Belarus","Belgium","Belize","Benin","Bermuda","Bhutan","Bolivia","Bosnia and Herzegovina","Botswana","Bouvet Island","Brazil","British Indian Ocean Territory","Brunei Darussalam","Bulgaria","Burkina Faso","Burundi","Cambodia","Cameroon","Canada","Cape Verde","Cayman Islands","Central African Republic","Chad","Chile","China","Christmas Island","Cocos (Keeling) Islands","Colombia","Comoros","Congo","Congo, The Democratic Republic of the","Cook Islands","Costa Rica","Cote D'Ivoire","Croatia","Cuba","Cyprus","Czech Republic","Denmark","Djibouti","Dominica","Dominican Republic","Ecuador","Egypt","El Salvador","Equatorial Guinea","Eritrea","Estonia","Ethiopia","Falkland Islands (Malvinas)","Faroe Islands","Fiji","Finland","France","French Guiana","French Polynesia","French Southern Territories","Gabon","Gambia","Georgia","Germany","Ghana","Gibraltar","Greece","Greenland","Grenada","Guadeloupe","Guam","Guatemala","Guernsey","Guinea","Guinea-Bissau","Guyana","Haiti","Heard Island and Mcdonald Islands","Holy See (Vatican City State)","Honduras","Hong Kong","Hungary","Iceland","India","Indonesia","Iran, Islamic Republic Of","Iraq","Ireland","Isle of Man","Israel","Italy","Jamaica","Japan","Jersey","Jordan","Kazakhstan","Kenya","Kiribati","Korea, Democratic People'S Republic of","Korea, Republic of","Kuwait","Kyrgyzstan","Lao People'S Democratic Republic","Latvia","Lebanon","Lesotho","Liberia","Libyan Arab Jamahiriya","Liechtenstein","Lithuania","Luxembourg","Macao","Macedonia, The Former Yugoslav Republic of","Madagascar","Malawi","Malaysia","Maldives","Mali","Malta","Marshall Islands","Martinique","Mauritania","Mauritius","Mayotte","Mexico","Micronesia, Federated States of","Moldova, Republic of","Monaco","Mongolia","Montserrat","Morocco","Mozambique","Myanmar","Namibia","Nauru","Nepal","Netherlands","Netherlands Antilles","New Caledonia","New Zealand","Nicaragua","Niger","Nigeria","Niue","Norfolk Island","Northern Mariana Islands","Norway","Oman","Pakistan","Palau","Palestinian Territory, Occupied","Panama","Papua New Guinea","Paraguay","Peru","Philippines","Pitcairn","Poland","Portugal","Puerto Rico","Qatar","Reunion","Romania","Russian Federation","RWANDA","Saint Helena","Saint Kitts and Nevis","Saint Lucia","Saint Pierre and Miquelon","Saint Vincent and the Grenadines","Samoa","San Marino","Sao Tome and Principe","Saudi Arabia","Senegal","Serbia and Montenegro","Seychelles","Sierra Leone","Singapore","Slovakia","Slovenia","Solomon Islands","Somalia","South Africa","South Georgia and the South Sandwich Islands","Spain","Sri Lanka","Sudan","Suriname","Svalbard and Jan Mayen","Swaziland","Sweden","Switzerland","Syrian Arab Republic","Taiwan, Province of China","Tajikistan","Tanzania, United Republic of","Thailand","Timor-Leste","Togo","Tokelau","Tonga","Trinidad and Tobago","Tunisia","Turkey","Turkmenistan","Turks and Caicos Islands","Tuvalu","Uganda","Ukraine","United Arab Emirates","United Kingdom","United States","United States Minor Outlying Islands","Uruguay","Uzbekistan","Vanuatu","Venezuela","Viet Nam","Virgin Islands, British","Virgin Islands, U.S.","Wallis and Futuna","Western Sahara","Yemen","Zambia","Zimbabwe"]
}

#Preview {
    CountryPickerView(selectedCountry: .constant("Afghanistan"))
}
