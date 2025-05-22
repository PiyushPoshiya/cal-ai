/*
See the License.txt file for this sample’s licensing information.
*/

import SwiftUI

struct ViewfinderView: View {
    @Binding var image: Image?
    
    ///MARK :- WEL-765: Camera in app should use the regular camera, not wide angle
    ///Task :- xlarge to none
    ///Date :- 27 August, 2024
    ///By Piyush Poshiya

    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
//                    .clipShape(RoundedRectangle(cornerRadius: Theme.Spacing.xlarge))
//                    .contentShape(RoundedRectangle(cornerRadius: Theme.Spacing.xlarge))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Spacing.none))
                    .contentShape(RoundedRectangle(cornerRadius: Theme.Spacing.none))
            }
        }
    }
}

struct ViewfinderView_Previews: PreviewProvider {
    static var previews: some View {
        ViewfinderView(image: .constant(Image(systemName: "pencil")))
    }
}
