import SwiftUI
import AnchorKit

struct LocationPermissionView: View {
    @Environment(LocationService.self) private var locationService
    @State private var requestingPermission = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: locationService.isPermissionDenied ? "location.slash" : "location")
                .foregroundStyle(locationService.isPermissionDenied ? .red : .orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(locationService.isPermissionDenied ? "Location access denied" : "Location access needed")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if locationService.isPermissionDenied {
                    Text("Enable in System Settings > Privacy & Security > Location Services")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Enable location to find nearby places")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if locationService.shouldRequestPermission {
                Button("Enable") {
                    Task {
                        requestingPermission = true
                        _ = await locationService.requestLocationPermission()
                        requestingPermission = false
                    }
                }
                .buttonStyle(.bordered)
                .disabled(requestingPermission)
            } else if locationService.isPermissionDenied {
                Button("Open Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background((locationService.isPermissionDenied ? Color.red : Color.orange).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    LocationPermissionView()
        .environment(LocationService())
}
