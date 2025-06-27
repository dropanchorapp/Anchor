# MV Pattern Architecture Guidelines

*SwiftUI-native architecture using Model-View patterns*

## Core Principles

- **No ViewModels.** Use `@Observable` classes for business logic
- **Views own UI state.** Use `@State` for temporary concerns  
- **Stores handle operations.** Create focused `@Observable` classes
- **Environment for sharing.** Use `@Environment` across view hierarchies

## Basic Structure

### Store (Business Logic)
```swift
@Observable
class ProductStore {
    private(set) var products: [Product] = []
    private(set) var isLoading = false
    
    func loadProducts() async { /* ... */ }
    func deleteProduct(_ product: Product) { /* ... */ }
}
```

### View (UI + Local State)
```swift
struct ProductListView: View {
    @State private var store = ProductStore()
    @State private var showingSheet = false
    
    var body: some View {
        List(store.products) { ProductRow(product: $0) }
            .task { await store.loadProducts() }
    }
}
```

## Property Wrapper Guide

| Use Case | Wrapper | Example |
|----------|---------|---------|
| Create store | `@State` | `@State private var store = ProductStore()` |
| Share store | `@Environment` | `@Environment(ProductStore.self) private var store` |
| UI state | `@State` | `@State private var showingSheet = false` |
| Settings | `@AppStorage` | `@AppStorage("theme") var theme = "light"` |

## Project Organization

```
AppName/
├── Features/
│   ├── Products/
│   │   ├── ProductListView.swift
│   │   └── ProductStore.swift
│   └── Settings/
├── Shared/
│   ├── Components/
│   └── Services/
└── Resources/
```

## Dependency Injection

### App Setup
```swift
@main
struct MyApp: App {
    @State private var productStore = ProductStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(productStore)
        }
    }
}
```

## SwiftData Integration

### Hybrid Pattern: @Query + Store
```swift
@Observable
class CheckinStore {
    private let modelContext: ModelContext
    private let locationService: LocationService
    
    func dropAnchor(message: String) async throws {
        let location = try await locationService.getCurrentLocation()
        let checkin = Checkin(location: location, message: message)
        modelContext.insert(checkin)
        try modelContext.save()
    }
}

struct CheckinListView: View {
    @Query private var checkins: [Checkin]  // Display
    @Environment(CheckinStore.self) private var store  // Operations
    
    var body: some View {
        List(checkins) { CheckinRow(checkin: $0) }
            .toolbar {
                Button("Add") { Task { try? await store.dropAnchor(message: "Here!") } }
            }
    }
}
```

### Simple Cases: Direct ModelContext
```swift
struct SimpleListView: View {
    @Query private var items: [Item]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List(items) { Text($0.name) }
            .toolbar {
                Button("Add") {
                    modelContext.insert(Item(name: "New"))
                    try? modelContext.save()
                }
            }
    }
}
```

## State Management Patterns

### Loading States
```swift
@Observable
class Store {
    enum State { case idle, loading, loaded, failed(Error) }
    private(set) var state: State = .idle
}
```

### Form Handling
```swift
struct AddView: View {
    @Environment(Store.self) private var store
    @State private var name = ""
    @State private var isSubmitting = false
    
    private func save() async {
        isSubmitting = true
        await store.save(name: name)
        isSubmitting = false
    }
}
```

## Testing

Test stores, not views:
```swift
@Test
func testProductStore() async {
    let store = ProductStore()
    await store.loadProducts()
    #expect(store.products.count > 0)
}
```

## Decision Guide

**Use Store when:**
- Business logic beyond CRUD
- Multi-step operations  
- External API calls
- Complex validation
- Error handling needed

**Use ModelContext directly when:**
- Simple CRUD operations
- No validation rules
- No external dependencies

## Anti-Patterns

❌ ViewModels for simple views  
❌ UI state in stores  
❌ @Observable for simple data models  
❌ Over-engineering simple operations

## Key Takeaways

1. **@Observable replaces ViewModels** for business logic
2. **@State handles UI concerns** within views  
3. **@Query for display, Store for operations** with SwiftData
4. **Feature-based organization** over type-based
5. **Start simple** - add complexity only when needed