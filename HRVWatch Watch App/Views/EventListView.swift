//import SwiftUI
//
//struct EventListView: View {
//    @ObservedObject private var connectivityHandler = WatchConnectivityHandler.shared
//
//    var body: some View {
//        NavigationView {
//            List(connectivityHandler.events) { event in
//                VStack(alignment: .leading) {
//                    Text("Event ID: \(event.id.uuidString.prefix(8))")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                    Text("Start: \(event.startTime.formatted())")
//                        .font(.subheadline)
//                    Text("End: \(event.endTime.formatted())")
//                        .font(.subheadline)
//                }
//                .padding()
//            }
//        }
//    }
//}

