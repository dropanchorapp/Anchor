import SwiftUI
import AnchorKit

struct LocationPermissionView: View {
    @Environment(LocationService.self) private var locationService
    @State private var requestingPermission = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.slash")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Location access needed")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("Enable location to find nearby places")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Enable") {
                Task {
                    requestingPermission = true
                    await locationService.requestLocationPermission()
                    requestingPermission = false
                }
            }
            .buttonStyle(.bordered)
            .disabled(requestingPermission)
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    LocationPermissionView()
        .environment(LocationService())
} 