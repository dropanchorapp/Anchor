    }
}

#Preview {
    CheckInView()
        .environment(AuthStore(authService: MockATProtoAuthService(), credentialsStorage: MockCredentialsStorage()))
        .environment(CheckInStore(checkinService: MockAnchorPDSService(), postService: MockBlueskyPostService(), locationService: MockLocationService(), nearbyService: MockNearbyPlacesService()))
} 