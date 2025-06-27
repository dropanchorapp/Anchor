<!--
Downloaded via https://llm.codes by @steipete on June 27, 2025 at 02:36 PM
Source URL: https://developer.apple.com/documentation/swiftui
Total pages processed: 187
URLs filtered: Yes
Content de-duplicated: Yes
Availability strings filtered: Yes
Code blocks only: No
-->

# https://developer.apple.com/documentation/swiftui

Framework

# SwiftUI

Declare the user interface and behavior for your app on every platform.

## Overview

SwiftUI provides views, controls, and layout structures for declaring your app’s user interface. The framework provides event handlers for delivering taps, gestures, and other types of input to your app, and tools to manage the flow of data from your app’s models down to the views and controls that users see and interact with.

Define your app structure using the `App` protocol, and populate it with scenes that contain the views that make up your app’s user interface. Create your own custom views that conform to the `View` protocol, and compose them with SwiftUI views for displaying text, images, and custom shapes using stacks, lists, and more. Apply powerful modifiers to built-in views and your own views to customize their rendering and interactivity. Share code between apps on multiple platforms with views and controls that adapt to their context and presentation.

You can integrate SwiftUI views with objects from the UIKit, AppKit, and WatchKit frameworks to take further advantage of platform-specific functionality. You can also customize accessibility support in SwiftUI, and localize your app’s interface for different languages, countries, or cultural regions.

### Featured samples

![An image with a background of Mount Fuji, and in the foreground screenshots of the landmark detail view for Mount Fuji in the Landmarks app, in an iPad and iPhone.\\
\\
Landmarks: Building an app with Liquid Glass \\
\\
Enhance your app experience with system-provided and custom Liquid Glass.\\
\\
](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)

![\\
\\
Destination Video \\
\\
Leverage SwiftUI to build an immersive media experience in a multiplatform app.\\
\\
](https://developer.apple.com/documentation/visionOS/destination-video)

![\\
\\
BOT-anist \\
\\
Build a multiplatform app that uses windows, volumes, and animations to create a robot botanist’s greenhouse.\\
\\
](https://developer.apple.com/documentation/visionOS/BOT-anist)

![A screenshot displaying the document launch experience on iPad with a robot and plant accessory to the left and right of the title view, respectively.\\
\\
Building a document-based app with SwiftUI \\
\\
Create, save, and open documents in a multiplatform app.\\
\\
](https://developer.apple.com/documentation/swiftui/building-a-document-based-app-with-swiftui)

## Topics

### Essentials

Adopting Liquid Glass

Find out how to bring the new material to your app.

Learning SwiftUI

Discover tips and techniques for building multiplatform apps with this set of conceptual articles and sample code.

Exploring SwiftUI Sample Apps

Explore these SwiftUI samples using Swift Playgrounds on iPad or in Xcode to learn about defining user interfaces, responding to user interactions, and managing data flow.

SwiftUI updates

Learn about important changes to SwiftUI.

Landmarks: Building an app with Liquid Glass

Enhance your app experience with system-provided and custom Liquid Glass.

### App structure

Define the entry point and top-level structure of your app.

Declare the user interface groupings that make up the parts of your app.

Display user interface content in a window or a collection of windows.

Display unbounded content in a person’s surroundings.

Enable people to open and manage documents.

Enable people to move between different parts of your app’s view hierarchy within a scene.

Present content in a separate view that offers focused interaction.

Provide immediate access to frequently used commands and controls.

Enable people to search for text or other content within your app.

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

### Data and storage

Manage the data that your app uses to drive its interface.

Share data throughout a view hierarchy using the environment.

Indicate configuration preferences from views to their container views.

Store data for use across sessions of your app.

### Views

Define the visual elements of your app using a hierarchy of views.

Adjust the characteristics of views in a hierarchy.

Apply built-in and custom appearances and behaviors to different types of views.

Create smooth visual updates in response to state changes.

Display formatted text and get text input from the user.

Add images and symbols to your app’s user interface.

Display values and get user selections.

Provide space-efficient, context-dependent access to commands and controls.

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

Enhance your views with graphical effects and customized drawings.

### View layout

Arrange views inside built-in layout containers like stacks and grids.

Make fine adjustments to alignment, spacing, padding, and other layout parameters.

Place views in custom arrangements and create animated transitions between layout types.

Display a structured, scrollable column of information.

Display selectable, sortable data arranged in rows and columns.

Present views in different kinds of purpose-driven containers, like forms or control groups.

Enable people to scroll to content that doesn’t fit in the current display.

### Event handling

Define interactions from taps, clicks, and swipes to fine-grained gestures.

Respond to input from a hardware device, like a keyboard or a Touch Bar.

Enable people to move or duplicate items by issuing Copy and Paste commands.

Enable people to move or duplicate items by dragging them from one location to another.

Identify and control which visible object responds to user interaction.

React to system events, like opening a URL.

### Accessibility

Make your SwiftUI apps accessible to everyone, including people with disabilities.

Enhance the legibility of content in your app’s interface.

Improve access to actions that your app can undertake.

Describe interface elements to help people understand what they represent.

Enable users to navigate to specific user interface elements using rotors.

### Framework integration

Add AppKit views to your SwiftUI app, or use SwiftUI views in your AppKit app.

Add UIKit views to your SwiftUI app, or use SwiftUI views in your UIKit app.

Add WatchKit views to your SwiftUI app, or use SwiftUI views in your WatchKit app.

Use SwiftUI views that other Apple frameworks provide.

### Tool support

Generate dynamic, interactive previews of your custom views.

Expose custom views and modifiers in the Xcode library.

Measure and improve your app’s responsiveness.

---

# https://developer.apple.com/documentation/swiftui/app

- SwiftUI
- App

Protocol

# App

A type that represents the structure and behavior of an app.

@MainActor @preconcurrency
protocol App

## Mentioned in

Migrating to the SwiftUI life cycle

## Overview

Create an app by declaring a structure that conforms to the `App` protocol. Implement the required `body` computed property to define the app’s content:

@main
struct MyApp: App {
var body: some Scene {
WindowGroup {
Text("Hello, world!")
}
}
}

Precede the structure’s declaration with the @main attribute to indicate that your custom `App` protocol conformer provides the entry point into your app. The protocol provides a default implementation of the `main()` method that the system calls to launch your app. You can have exactly one entry point among all of your app’s files.

Compose the app’s body from instances that conform to the `Scene` protocol. Each scene contains the root view of a view hierarchy and has a life cycle managed by the system. SwiftUI provides some concrete scene types to handle common scenarios, like for displaying documents or settings. You can also create custom scenes.

@main
struct Mail: App {
var body: some Scene {
WindowGroup {
MailViewer()
}
Settings {
SettingsView()
}
}
}

You can declare state in your app to share across all of its scenes. For example, you can use the `StateObject` attribute to initialize a data model, and then provide that model on a view input as an `ObservedObject` or through the environment as an `EnvironmentObject` to scenes in the app:

@main
struct Mail: App {
@StateObject private var model = MailModel()

var body: some Scene {
WindowGroup {
MailViewer()
.environmentObject(model) // Passed through the environment.
}
Settings {
SettingsView(model: model) // Passed as an observed object.
}
}
}

A type conforming to this protocol inherits `@preconcurrency @MainActor` isolation from the protocol if the conformance is included in the type’s base declaration:

struct MyCustomType: Transition {
// `@preconcurrency @MainActor` isolation by default
}

Isolation to the main actor is the default, but it’s not required. Declare the conformance in an extension to opt out of main actor isolation:

extension MyCustomType: Transition {
// `nonisolated` by default
}

## Topics

### Implementing an app

`var body: Self.Body`

The content and behavior of the app.

**Required**

`associatedtype Body : Scene`

The type of scene representing the content of the app.

### Running an app

`init()`

Creates an instance of the app using the body that you define for its content.

`static func main()`

Initializes and runs the app.

## See Also

### Creating an app

Destination Video

Leverage SwiftUI to build an immersive media experience in a multiplatform app.

Hello World

Use windows, volumes, and immersive spaces to teach people about the Earth.

Backyard Birds: Building an app with SwiftData and widgets

Create an app with persistent data, interactive widgets, and an all new in-app purchase experience.

Food Truck: Building a SwiftUI multiplatform app

Create a single codebase and app target for Mac, iPad, and iPhone.

Fruta: Building a Feature-Rich App with SwiftUI

Create a shared codebase to build a multiplatform app that offers widgets and an App Clip.

Use a scene-based life cycle in SwiftUI while keeping your existing codebase.

---

# https://developer.apple.com/documentation/swiftui/view

- SwiftUI
- View

Protocol

# View

A type that represents part of your app’s user interface and provides modifiers that you use to configure views.

@MainActor @preconcurrency
protocol View

## Mentioned in

Declaring a custom view

Configuring views

Reducing view modifier maintenance

Migrating to the SwiftUI life cycle

Displaying data in lists

## Overview

You create custom views by declaring types that conform to the `View` protocol. Implement the required `body` computed property to provide the content for your custom view.

struct MyView: View {
var body: some View {
Text("Hello, World!")
}
}

Assemble the view’s body by combining one or more of the built-in views provided by SwiftUI, like the `Text` instance in the example above, plus other custom views that you define, into a hierarchy of views. For more information about creating custom views, see Declaring a custom view.

The `View` protocol provides a set of modifiers — protocol methods with default implementations — that you use to configure views in the layout of your app. Modifiers work by wrapping the view instance on which you call them in another view with the specified characteristics, as described in Configuring views. For example, adding the `opacity(_:)` modifier to a text view returns a new view with some amount of transparency:

Text("Hello, World!")
.opacity(0.5) // Display partially transparent text.

The complete list of default modifiers provides a large set of controls for managing views. For example, you can fine tune Layout modifiers, add Accessibility modifiers information, and respond to Input and event modifiers. You can also collect groups of default modifiers into new, custom view modifiers for easy reuse.

A type conforming to this protocol inherits `@preconcurrency @MainActor` isolation from the protocol if the conformance is declared in its original declaration. Isolation to the main actor is the default, but it’s not required. Declare the conformance in an extension to opt-out the isolation.

## Topics

### Implementing a custom view

`var body: Self.Body`

The content and behavior of the view.

**Required** Default implementations provided.

`associatedtype Body : View`

The type of view representing the body of this view.

**Required**

Applies a modifier to a view and returns a new view.

Generate dynamic, interactive previews of your custom views.

### Configuring view elements

Make your SwiftUI apps accessible to everyone, including people with disabilities.

Configure a view’s foreground and background styles, controls, and visibility.

Manage the rendering, selection, and entry of text in your view.

Add and configure supporting views, like toolbars and context menus.

Configure charts that you declare with Swift Charts.

### Drawing views

Apply built-in styles to different types of views.

Tell a view how to arrange itself within a view hierarchy by adjusting its size, position, alignment, padding, and so on.

Affect the way the system draws a view, for example by scaling or masking a view, or by applying graphical effects.

### Providing interactivity

Supply actions for a view to perform in response to user input and system events.

Enable people to search for content in your app.

Define additional views for the view to present under specified conditions.

Access storage and provide child views with configuration data.

### Deprecated modifiers

Review unsupported modifiers and their replacements.

### Instance Methods

Adds multiple accessibility actions to the view with a specific category. Actions allow assistive technologies, such as VoiceOver, to interact with the view by invoking the action and are grouped by their category. When multiple action modifiers with an equal category are applied to the view, the actions are combined together.

Defines a region in which default accessibility focus is evaluated by assigning a value to a given accessibility focus state binding.

Beta

`func accessibilityScrollStatus(_:isEnabled:)`

Changes the announcement provided by accessibility technologies when a user scrolls a scroll view within this view.

The view modifier that can be applied to `AccessoryWidgetGroup` to specify the shape the three content views will be masked with. The value of `style` is set to `.automatic`, which is `.circular` by default.

Sets the button’s style.

Sets the style to be used by the button. (see `PKAddPassButtonStyle`).

Configures gestures in this view hierarchy to handle events that activate the containing window.

Constrains this view’s dimensions to the specified 3D aspect ratio.

Configures the view’s icon for purposes of navigation.

`func attributedTextFormattingDefinition(_:)`

Apply a text formatting definition to all nested editor views.

Presents a modal view that enables users to add devices to their organization.

Adds the background extension effect to the view. The view will be duplicated into mirrored copies which will be placed around the view on any edge with available safe area. Additionally, a blur effect will be applied on top to blur out the copies.

Ensures that the view is always visible to the user, even when other content is occluding it, like 3D models.

Displays a certificate sheet using the provided certificate trust.

`func chart3DPose(_:)` Beta

Sets the visibility of the z axis.

Configures the z-axis for 3D charts in the view.

`func chartZAxisLabel(_:position:alignment:spacing:)`

Adds z axis label for charts in the view. It effects 3D charts only.

Modally present UI which allows the user to select which contacts your app has access to.

Sets a particular container value of a view.

`func contentToolbar(for:content:)`

Populates the toolbar of the specified content view type with the views you provide.

A `continuityDevicePicker` should be used to discover and connect nearby continuity device through a button interface or other form of activation. On tvOS, this presents a fullscreen continuity device picker experience when selected. The modal view covers as much the screen of `self` as possible when a given condition is true.

`func controlWidgetActionHint(_:)`

The action hint of the control described by the modified label.

`func controlWidgetStatus(_:)`

The status of the control described by the modified label.

Declares the view as dependent on the entitlement of an In-App Purchase product, and returns a modified view.

Whether the alert or confirmation dialog prevents the app from being quit/terminated by the system or app termination menu item.

Adds to a `DocumentLaunchView` actions that accept a list of selected files as their parameter.

Configures a drag session.

A container with draggable views. The drag payload is based on the current selection.

`func dragContainer(for:id:in:selection:_:)`

A container with single item selection and draggable views. The drag payload is based on the current selection and provided identifiers.

A container with draggable views. The drag payload is identifiable. To form the payload, use the identifier of the dragged view inside the container.

`func dragContainer(for:in:selection:_:)`

A container with multiple selection and draggable views. The drag payload is identifiable and is based on the current selection.

Describes the way dragged previews are visually composed.

Activates this view as the source of a drag and drop operation. A view can be dragged separately, or as an element of a drag container.

Inside a drag container, activates this view as the source of a drag and drop operation. Supports lazy drag containers.

Activates this view as the source of a drag-and-drop operation.

Configures a drop session.

Defines the destination of a drag and drop operation that provides a drop operation proposal and handles the dropped content with a closure that you specify.

Describes the way previews for a drop are composed.

Sets the style for forms in a view hierarchy.

Presents a modal view while the game synced directory loads.

Fills the view’s background with a custom glass background effect and container-relative rounded rectangle shape.

Fills the view’s background with a custom glass background effect and a shape that you specify.

Applies the Liquid Glass effect to a view.

Associates an identity value to Liquid Glass effects defined within this view.

Associates a glass effect transition with any glass effects defined within this view.

Associates any Liquid Glass effects defined within this view to a union with the provided identifier.

Specifies how a view should be associated with the current SharePlay group activity.

Assigns a hand gesture shortcut to the modified control.

Sets the behavior of the hand pointer while the user is interacting with the view.

Specifies the game controllers events which should be delivered through the GameController framework when the view, or one of its descendants has focus.

Specifies the game controllers events which should be delivered through the GameController framework when the view or one of its descendants has focus.

Asynchronously requests permission to read a data type that requires per-object authorization (such as vision prescriptions).

Requests permission to read the specified HealthKit data types.

Requests permission to save and read the specified HealthKit data types.

Sets the generation style for an image playground.

Policy determining whether to support the usage of people in the playground or not.

Presents the system sheet to create images from the specified input.

Add menu items to open immersive spaces from a media player’s environment picker.

Add a function to call before initiating a purchase from StoreKit view within this view, providing a set of options for the purchase.

Presents a visual picker interface that contains events and images that a person can select to retrieve more information.

Set the spacing between the icon and title in labels.

Set the width reserved for icons in labels.

Sets a style for labeled content.

Controls the visibility of labels of any controls contained within this view.

A modifier for the default line height in the view hierarchy.

Sets the insets of rows in a list on the specified edges.

Changes the visibility of the list section index.

Set the section margins for the specific edges.

Applies a managed content style to the view.

Allows this view to be manipulated using common hand gestures.

Applies the given 3D affine transform to the view and allows it to be manipulated using common hand gestures.

Allows the view to be manipulated using a manipulation gesture attached to a different view.

Adds a manipulation gesture to this view without allowing this view to be manipulable itself.

Uses the given keyframes to animate the camera of a `Map` when the given trigger value changes.

Configures all Map controls in the environment to have the specified visibility

Configures all `Map` views in the associated environment to have standard size and position controls

Specifies the selection accessory to display for a `MapFeature`

Specifies a custom presentation for the currently selected feature.

Specifies which map features should have selection disabled.

Presents a map item detail popover.

Presents a map item detail sheet.

Creates a mapScope that SwiftUI uses to connect map controls to an associated map.

Specifies the map style to be used.

Identifies this view as the source of a navigation transition, such as a zoom transition.

Sets an explicit active appearance for materials in this view.

A modifier for the default text alignment strategy in the view hierarchy.

Configures whether navigation links show a disclosure indicator.

Sets the navigation transition style for this view.

Registers a handler to invoke in response to the specified app intent that your app receives.

Called when a user has entered or updated a coupon code. This is required if the user is being asked to provide a coupon code.

Called when a payment method has changed and asks for an update payment request. If this modifier isn’t provided Wallet will assume the payment method is valid.

Called when a user selected a shipping address. This is required if the user is being asked to provide a shipping contact.

Called when a user selected a shipping method. This is required if the user is being asked to provide a shipping method.

`func onCameraCaptureEvent(isEnabled:defaultSoundDisabled:action:)`

Used to register an action triggered by system capture events.

`func onCameraCaptureEvent(isEnabled:defaultSoundDisabled:primaryAction:secondaryAction:)`

Used to register actions triggered by system capture events.

Specifies an action to perform on each update of an ongoing dragging operation activated by `draggable(_:)` or other drag modifiers.

Specifies an action to perform on each update of an ongoing drop operation activated by `dropDestination(_:)` or other drop modifiers.

`func onGeometryChange3D(for:of:action:)`

Returns a new view that arranges to call `action(value)` whenever the value computed by `transform(proxy)` changes, where `proxy` provides access to the view’s 3D geometry properties.

Add an action to perform when a purchase initiated from a StoreKit view within this view completes.

Add an action to perform when a user triggers the purchase button on a StoreKit view within this view.

`func onMapCameraChange(frequency:_:)`

Performs an action when Map camera framing changes

Sets an `OpenURLAction` that prefers opening URL with an in-app browser. It’s equivalent to calling `.onOpenURL(_:)`

`func onWorldRecenter(action:)`

Adds an action to perform when recentering the view with the digital crown.

Sets the action on the PayLaterView. See `PKPayLaterAction`.

Sets the display style on the PayLaterView. See `PKPayLaterDisplayStyle`.

Sets the features that should be allowed to show on the payment buttons.

Sets the style to be used by the button. (see `PayWithApplePayButtonStyle`).

Presents a popover tip on the modified view.

`func postToPhotosSharedAlbumSheet(isPresented:items:photoLibrary:defaultAlbumIdentifier:completion:)`

Presents an “Add to Shared Album” sheet that allows the user to post the given items to a shared album.

Selects a subscription offer to apply to a purchase that a customer makes from a subscription store view, a store view, or a product view.

`func preferredWindowClippingMargins(_:_:)`

Requests additional margins for drawing beyond the bounds of the window.

Changes the way the enclosing presentation breaks through content occluding it.

Whether a presentation prevents the app from being terminated/quit by the system or app termination menu item.

Configure the visibility of labels displaying an in-app purchase product description within the view.

Adds a standard border to an in-app purchase product’s icon .

Sets the style for In-App Purchase product views within a view.

Adds gestures that control the position and direction of a virtual camera.

Controls the frame sizing and content alignment behavior for `RealityView`

Rotates a view with impacts to its frame in a containing layout

`func rotation3DLayout(_:axis:)`

`func safeAreaBar(edge:alignment:spacing:content:)`

Renders the provided content appropriately to be displayed as a custom bar.

Scales this view to fill its parent.

Scales this view to fit its parent.

Disables any scroll edge effects for scroll views within this hierarchy.

Configures the scroll edge effect style for scroll views within this hierarchy.

Enables or disables scrolling in scrollable views when using particular inputs.

Configures the behavior for search in the toolbar.

`func sectionIndexLabel(_:)`

Sets the label that is used in a section index to point to this section, typically only a single character long.

Sets the style used for displaying the control (see `SignInWithAppleButton.Style`).

Adds secondary views within the 3D bounds of this view.

Uses the specified preference value from the view to produce another view occupying the same 3D space of the first view.

Specifies the visibility of auxiliary buttons that store view and subscription store view instances may use.

Declares the view as dependent on an In-App Purchase product and returns a modified view.

Declares the view as dependent on a collection of In-App Purchase products and returns a modified view.

Selects the introductory offer eligibility preference to apply to a purchase a customer makes from a subscription store view.

Selects a promotional offer to apply to a purchase a customer makes from a subscription store view.

Deprecated

Declares the view as dependent on the status of an auto-renewable subscription group, and returns a modified view.

Configures subscription store view instances within a view to use the provided button label.

`func subscriptionStoreControlBackground(_:)`

Set a standard effect to use for the background of subscription store view controls within the view.

Sets a view to use to decorate individual subscription options within a subscription store view.

Sets the control style for subscription store views within a view.

Sets the control style and control placement for subscription store views within a view.

Sets the style subscription store views within this view use to display groups of subscription options.

Sets the background style for picker items of the subscription store view instances within a view.

Sets the background shape and style for subscription store view picker items within a view.

Configures a view as the destination for a policy button action in subscription store views.

Configures a URL as the destination for a policy button action in subscription store views.

Sets the style for the and buttons within a subscription store view.

Sets the primary and secondary style for the and buttons within a subscription store view.

Adds an action to perform when a person uses the sign-in button on a subscription store view within a view.

Sets the color rendering mode for symbol images.

Sets the variable value mode mode for symbol images within this view.

Sets the behavior for tab bar minimization.

Adds a tabletop game to a view.

Supplies a closure which returns a new interaction whenever needed.

`func textContentType(_:)`

Sets the text content type for this view, which the system uses to offer suggestions while the user enters text on macOS.

Define which system text formatting controls are available.

Returns a new view such that any text views within it will use `renderer` to draw themselves.

Sets the direction of a selection or cursor relative to a text character.

Sets the tip’s view background to a style. Currently this only applies to inline tips, not popover tips.

Sets the corner radius for an inline tip view.

Sets the size for a tip’s image.

Sets the style for a tip’s image.

Sets the given style for TipView within the view hierarchy.

Hides an individual view within a control group toolbar item.

Presents a picker that selects a collection of transactions.

Provides a task to perform before this view appears

Presents a translation popover when a given condition is true.

Adds a task to perform before this view appears or when the translation configuration changes.

Adds a task to perform before this view appears or when the specified source or target languages change.

Sets the style to be used by the button. (see `PKIdentityButtonStyle`).

Determines whether horizontal swipe gestures trigger backward and forward page navigation.

Specifies the visibility of the webpage’s natural background color within this view.

Adds an item-based context menu to a WebView, replacing the default set of context menu items.

Determines whether a web view can display content full screen.

Determines whether pressing a link displays a preview of the destination for the link.

Determines whether magnify gestures change the view’s magnification.

Adds an action to be performed when a value, created from a scroll geometry, changes.

Enables or disables scrolling in web views when using particular inputs.

Associates a binding to a scroll position with the web view.

Determines whether to allow people to select or otherwise interact with text.

Sets the window anchor point used when the size of the view changes such that the window must resize.

Configures the visibility of the window toolbar when the window enters full screen mode.

Presents a preview of the workout contents as a modal sheet

A modifier for the default text writing direction strategy in the view hierarchy.

Specifies whether the system should show the Writing Tools affordance for text input views affected by the environment.

Specifies the Writing Tools behavior for text and text input in the environment.

## Relationships

### Inherited By

- `DynamicViewContent`
- `InsettableShape`
- `NSViewControllerRepresentable`
- `NSViewRepresentable`
- `Shape`
- `ShapeView`
- `UIViewControllerRepresentable`
- `UIViewRepresentable`
- `WKInterfaceObjectRepresentable`

### Conforming Types

- `AngularGradient`
- `AnyShape`
- `AnyView`
- `AsyncImage`
- `Button`
- `ButtonBorderShape`
- `ButtonStyleConfiguration.Label`
- `Canvas`
Conforms when `Symbols` conforms to `View`.

- `Capsule`
- `Circle`
- `Color`
- `ColorPicker`
- `ContainerRelativeShape`
- `ContentUnavailableView`
- `ControlGroup`
- `ControlGroupStyleConfiguration.Content`
- `ControlGroupStyleConfiguration.Label`
- `DatePicker`
- `DatePickerStyleConfiguration.Label`
- `DebugReplaceableView`
- `DefaultButtonLabel`
- `DefaultDateProgressLabel`
- `DefaultDocumentGroupLaunchActions`
- `DefaultSettingsLinkLabel`
- `DefaultShareLinkLabel`
- `DefaultTabLabel`
- `DefaultWindowVisibilityToggleLabel`
- `DisclosureGroup`
- `DisclosureGroupStyleConfiguration.Content`
- `DisclosureGroupStyleConfiguration.Label`
- `Divider`
- `DocumentLaunchView`
- `EditButton`
- `EditableCollectionContent`
Conforms when `Content` conforms to `View`, `Data` conforms to `Copyable`, and `Data` conforms to `Escapable`.

- `Ellipse`
- `EllipticalGradient`
- `EmptyView`
- `EquatableView`
- `FillShapeView`
- `ForEach`
Conforms when `Data` conforms to `RandomAccessCollection`, `ID` conforms to `Hashable`, and `Content` conforms to `View`.

- `Form`
- `FormStyleConfiguration.Content`
- `Gauge`
- `GaugeStyleConfiguration.CurrentValueLabel`
- `GaugeStyleConfiguration.Label`
- `GaugeStyleConfiguration.MarkedValueLabel`
- `GaugeStyleConfiguration.MaximumValueLabel`
- `GaugeStyleConfiguration.MinimumValueLabel`
- `GeometryReader`
- `GeometryReader3D`
- `GlassBackgroundEffectConfiguration.Content`
- `GlassEffectContainer`
- `Grid`
Conforms when `Content` conforms to `View`.

- `GridRow`
Conforms when `Content` conforms to `View`.

- `Group`
Conforms when `Content` conforms to `View`.

- `GroupBox`
- `GroupBoxStyleConfiguration.Content`
- `GroupBoxStyleConfiguration.Label`
- `GroupElementsOfContent`
- `GroupSectionsOfContent`
- `HSplitView`
- `HStack`
- `HelpLink`
- `Image`
- `KeyframeAnimator`
- `Label`
- `LabelStyleConfiguration.Icon`
- `LabelStyleConfiguration.Title`
- `LabeledContent`
Conforms when `Label` conforms to `View` and `Content` conforms to `View`.

- `LabeledContentStyleConfiguration.Content`
- `LabeledContentStyleConfiguration.Label`
- `LabeledControlGroupContent`
- `LabeledToolbarItemGroupContent`
- `LazyHGrid`
- `LazyHStack`
- `LazyVGrid`
- `LazyVStack`
- `LinearGradient`
- `Link`
- `List`
- `Menu`
- `MenuButton`
- `MenuStyleConfiguration.Content`
- `MenuStyleConfiguration.Label`
- `MeshGradient`
- `ModifiedContent`
Conforms when `Content` conforms to `View` and `Modifier` conforms to `ViewModifier`.

- `MultiDatePicker`
- `NavigationLink`
- `NavigationSplitView`
- `NavigationStack`
- `NavigationView`
- `NewDocumentButton`
- `OffsetShape`
- `OutlineGroup`
Conforms when `Data` conforms to `RandomAccessCollection`, `ID` conforms to `Hashable`, `Parent` conforms to `View`, `Leaf` conforms to `View`, and `Subgroup` conforms to `View`.

- `OutlineSubgroupChildren`
- `PasteButton`
- `Path`
- `PhaseAnimator`
- `Picker`
- `PlaceholderContentView`
- `PresentedWindowContent`
- `PreviewModifierContent`
- `PrimitiveButtonStyleConfiguration.Label`
- `ProgressView`
- `ProgressViewStyleConfiguration.CurrentValueLabel`
- `ProgressViewStyleConfiguration.Label`
- `RadialGradient`
- `Rectangle`
- `RenameButton`
- `RotatedShape`
- `RoundedRectangle`
- `ScaledShape`
- `ScrollView`
- `ScrollViewReader`
- `SearchUnavailableContent.Actions`
- `SearchUnavailableContent.Description`
- `SearchUnavailableContent.Label`
- `Section`
Conforms when `Parent` conforms to `View`, `Content` conforms to `View`, and `Footer` conforms to `View`.

- `SectionConfiguration.Actions`
- `SecureField`
- `SettingsLink`
- `ShareLink`
- `Slider`
- `Spacer`
- `Stepper`
- `StrokeBorderShapeView`
- `StrokeShapeView`
- `SubscriptionView`
- `Subview`
- `SubviewsCollection`
- `SubviewsCollectionSlice`
- `TabContentBuilder.Content`
- `TabView`
- `Table`
- `Text`
- `TextEditor`
- `TextField`
- `TextFieldLink`
- `TimelineView`
Conforms when `Schedule` conforms to `TimelineSchedule` and `Content` conforms to `View`.

- `Toggle`
- `ToggleStyleConfiguration.Label`
- `TransformedShape`
- `TupleView`
- `UnevenRoundedRectangle`
- `VSplitView`
- `VStack`
- `ViewThatFits`
- `WindowVisibilityToggle`
- `ZStack`
- `ZStackContent3D`
Conforms when `Content` conforms to `View`.

## See Also

### Creating a view

Define views and assemble them into a view hierarchy.

`struct ViewBuilder`

A custom parameter attribute that constructs views from closures.

---

# https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass

- SwiftUI
- Landmarks: Building an app with Liquid Glass Beta

Sample Code

# Landmarks: Building an app with Liquid Glass

Enhance your app experience with system-provided and custom Liquid Glass.

Download

Xcode 26.0+Beta

## Overview

Landmarks is a SwifUI app that demonstrates how to use the new dynamic and expressive design feature, Liquid Glass. The Landmarks app lets people explore interesting sites around the world. Whether it’s a national park near their home or a far-flung location on a different continent, the app provides a way for people to organize and mark their adventures and receive custom activity badges along the way. Landmarks runs on iPad, iPhone, and Mac.

Landmarks uses a `NavigationSplitView` to organize and navigate to content in the app, and demonstrates several key concepts to optimize the use of Liquid Glass:

- Stretching content behind the sidebar and inspector with the background extension effect.

- Extending horizontal scroll views under a sidebar or inspector.

- Leveraging the system-provided glass effect in toolbars.

- Applying Liquid Glass effects to custom interface elements and animations.

- Building a new app icon with Icon Composer.

The sample also demonstrates several techniques to use when changing window sizes, and for adding global search.

## Apply a background extension effect

The sample applies a background extension effect to the featured landmark header in the top view, and the main image in the landmark detail view. This effect extends and blurs the image under the sidebar and inspector when they’re open, creating a full edge-to-edge experience.

To achieve this effect, the sample creates and configures an `Image` that extends to both the leading and trailing edges of the containing view, and applies the `backgroundExtensionEffect()` modifier to the image. For the featured image, the sample adds an overlay with a headline and button after the modifier, so that only the image extends under the sidebar and inspector.

For more information, see Landmarks: Applying a background extension effect.

## Extend horizontal scrolling under the sidebar

Within each continent section in `LandmarksView`, an instance of `LandmarkHorizontalListView` shows a horizontally scrolling list of landmark views. When open, the landmark views can scroll underneath the sidebar or inspector.

To achieve this effect, the app aligns the scroll views next to the leading and trailing edges of the containing view.

For more information, see Landmarks: Extending horizontal scrolling under a sidebar or inspector.

## Refine the Liquid Glass in the toolbar

In `LandmarkDetailView`, the sample adds toolbar items for:

- sharing a landmark

- adding or removing a landmark from a list of Favorites

- adding or removing a landmark from Collections

- showing or hiding the inspector

The system applies Liquid Glass to toolbar items automatically:

The sample also organizes the toolbar into related groups, instead of having all the buttons in one group. For more information, see Landmarks: Refining the system provided Liquid Glass effect in toolbars.

## Display badges with Liquid Glass

Badges provide people with a visual indicator of the activities they’ve recorded in the Landmarks app. When a person completes all four activities for a landmark, they earn that landmark’s badge. The sample uses custom Liquid Glass elements with badges, and shows how to coordinate animations with Liquid Glass.

To create a custom Liquid Glass badge, Landmarks uses a view with an `Image` to display a system symbol image for the badge. The badge has a background hexagon `Image` filled with a custom color. The badge view uses the `glassEffect(_:in:isEnabled:)` modifier to apply Liquid Glass to the badge.

To demonstrate the morphing effect that the system provides with Liquid Glass animations, the sample organizes the badges and the toggle button into a `GlassEffectContainer`, and assigns each badge a unique `glassEffectID(_:in:)`.

For more information, see Landmarks: Displaying custom activity badges. For information about building custom views with Liquid Glass, see Applying Liquid Glass to custom views.

## Create the app icon with Icon Composer

Landmarks includes a dynamic and expressive app icon composed in Icon Composer. You build app icons with four layers that the system uses to produce specular highlights when a person moves their device, so that the icon responds as if light was reflecting off the glass. The Settings app allows people to personalize the icon by selecting light, dark, clear, or tinted variants of your app icon as well.

For more information on creating a new app icon, see Creating your app icon using Icon Composer.

## Topics

### App features

Landmarks: Applying a background extension effect

Configure an image to blur and extend under a sidebar or inspector panel.

Landmarks: Extending horizontal scrolling under a sidebar or inspector

Improve your horizontal scrollbar’s appearance by extending it under a sidebar or inspector.

Landmarks: Refining the system provided Liquid Glass effect in toolbars

Organize toolbars into related groupings to improve their appearance and utility.

Landmarks: Displaying custom activity badges

Provide people with a way to mark their adventures by displaying animated custom activity badges.

## See Also

### Essentials

Adopting Liquid Glass

Find out how to bring the new material to your app.

Learning SwiftUI

Discover tips and techniques for building multiplatform apps with this set of conceptual articles and sample code.

Exploring SwiftUI Sample Apps

Explore these SwiftUI samples using Swift Playgrounds on iPad or in Xcode to learn about defining user interfaces, responding to user interactions, and managing data flow.

SwiftUI updates

Learn about important changes to SwiftUI.

Beta Software

This documentation contains preliminary information about an API or technology in development. This information is subject to change, and software implemented according to this documentation should be tested with final operating system software.

Learn more about using Apple's beta software

---

# https://developer.apple.com/documentation/swiftui/app-organization

Collection

- SwiftUI
- App organization

API Collection

# App organization

Define the entry point and top-level structure of your app.

## Overview

Describe your app’s structure declaratively, much like you declare a view’s appearance. Create a type that conforms to the `App` protocol and use it to enumerate the Scenes that represent aspects of your app’s user interface.

SwiftUI enables you to write code that works across all of Apple’s platforms. However, it also enables you to tailor your app to the specific capabilities of each platform. For example, if you need to respond to the callbacks that the system traditionally makes on a UIKit, AppKit, or WatchKit app’s delegate, define a delegate object and instantiate it in your app structure using an appropriate delegate adaptor property wrapper, like `UIApplicationDelegateAdaptor`.

For platform-specific design guidance, see Getting started in the Human Interface Guidelines.

## Topics

### Creating an app

Destination Video

Leverage SwiftUI to build an immersive media experience in a multiplatform app.

Hello World

Use windows, volumes, and immersive spaces to teach people about the Earth.

Backyard Birds: Building an app with SwiftData and widgets

Create an app with persistent data, interactive widgets, and an all new in-app purchase experience.

Food Truck: Building a SwiftUI multiplatform app

Create a single codebase and app target for Mac, iPad, and iPhone.

Fruta: Building a Feature-Rich App with SwiftUI

Create a shared codebase to build a multiplatform app that offers widgets and an App Clip.

Migrating to the SwiftUI life cycle

Use a scene-based life cycle in SwiftUI while keeping your existing codebase.

`protocol App`

A type that represents the structure and behavior of an app.

### Targeting iOS and iPadOS

`UILaunchScreen`

The user interface to show while an app launches.

`UILaunchScreens`

The user interfaces to show while an app launches in response to different URL schemes.

`struct UIApplicationDelegateAdaptor`

A property wrapper type that you use to create a UIKit app delegate.

### Targeting macOS

`struct NSApplicationDelegateAdaptor`

A property wrapper type that you use to create an AppKit app delegate.

### Targeting watchOS

`struct WKApplicationDelegateAdaptor`

A property wrapper that is used in `App` to provide a delegate from WatchKit.

`struct WKExtensionDelegateAdaptor`

A property wrapper type that you use to create a WatchKit extension delegate.

### Targeting tvOS

Creating a tvOS media catalog app in SwiftUI

Build standard content lockups and rows of content shelves for your tvOS app.

### Handling system recenter events

`enum WorldRecenterPhase`

A type that represents information associated with a phase of a system recenter event. Values of this type are passed to the closure specified in View.onWorldRecenter(action:).

Beta

## See Also

### App structure

Declare the user interface groupings that make up the parts of your app.

Display user interface content in a window or a collection of windows.

Display unbounded content in a person’s surroundings.

Enable people to open and manage documents.

Enable people to move between different parts of your app’s view hierarchy within a scene.

Present content in a separate view that offers focused interaction.

Provide immediate access to frequently used commands and controls.

Enable people to search for text or other content within your app.

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

---

# https://developer.apple.com/documentation/swiftui/scenes

Collection

- SwiftUI
- Scenes

API Collection

# Scenes

Declare the user interface groupings that make up the parts of your app.

## Overview

A scene represents a part of your app’s user interface that has a life cycle that the system manages. An `App` instance presents the scenes it contains, while each `Scene` acts as the root element of a `View` hierarchy.

The system presents scenes in different ways depending on the type of scene, the platform, and the context. A scene might fill the entire display, part of the display, a window, a tab in a window, or something else. In some cases, your app might also be able to display more than one instance of the scene at a time, like when a user simultaneously opens multiple windows based on a single `WindowGroup` declaration in your app. For more information about the primary built-in scene types, see Windows and Documents.

You configure scenes using modifiers, similar to how you configure views. For example, you can adjust the appearance of the window that contains a scene — if the scene happens to appear in a window — using the `windowStyle(_:)` modifier. Similarly, you can add menu commands that become available when the scene is in the foreground on certain platforms using the `commands(content:)` modifier.

## Topics

### Creating scenes

`protocol Scene`

A part of an app’s user interface with a life cycle managed by the system.

`struct SceneBuilder`

A result builder for composing a collection of scenes into a single composite scene.

### Monitoring scene life cycle

`var scenePhase: ScenePhase`

The current phase of the scene.

`enum ScenePhase`

An indication of a scene’s operational state.

### Managing a settings window

`struct Settings`

A scene that presents an interface for viewing and modifying an app’s settings.

`struct SettingsLink`

A view that opens the Settings scene defined by an app.

`struct OpenSettingsAction`

An action that presents the settings scene for an app.

`var openSettings: OpenSettingsAction`

A Settings presentation action stored in a view’s environment.

### Building a menu bar

Building and customizing the menu bar with SwiftUI

Provide a seamless, cross-platform user experience by building a native menu bar for iPadOS and macOS.

### Creating a menu bar extra

`struct MenuBarExtra`

A scene that renders itself as a persistent control in the system menu bar.

Sets the style for menu bar extra created by this scene.

`protocol MenuBarExtraStyle`

A specification for the appearance and behavior of a menu bar extra scene.

### Creating watch notifications

`struct WKNotificationScene`

A scene which appears in response to receiving the specified category of remote or local notifications.

## See Also

### App structure

Define the entry point and top-level structure of your app.

Display user interface content in a window or a collection of windows.

Display unbounded content in a person’s surroundings.

Enable people to open and manage documents.

Enable people to move between different parts of your app’s view hierarchy within a scene.

Present content in a separate view that offers focused interaction.

Provide immediate access to frequently used commands and controls.

Enable people to search for text or other content within your app.

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

---

# https://developer.apple.com/documentation/swiftui/windows

Collection

- SwiftUI
- Windows

API Collection

# Windows

Display user interface content in a window or a collection of windows.

## Overview

The most common way to present a view hierarchy in your app’s interface is with a `WindowGroup`, which produces a platform-specific behavior and appearance.

On platforms that support it, people can open multiple windows from the group simultaneously. Each window relies on the same root view definition, but retains its own view state. On some platforms, you can also supplement your app’s user interface with a single-instance window using the `Window` scene type.

Configure windows using scene modifiers that you add to the window declaration, like `windowStyle(_:)` or `defaultPosition(_:)`. You can also indicate how to configure new windows that you present from a view hierarchy by adding the `presentedWindowStyle(_:)` view modifier to a view in the hierarchy.

For design guidance, see Windows in the Human Interface Guidelines.

## Topics

### Essentials

Customizing window styles and state-restoration behavior in macOS

Configure how your app’s windows look and function in macOS to provide an engaging and more coherent experience.

Bringing multiple windows to your SwiftUI app

Compose rich views by reacting to state changes and customize your app’s scene presentation and behavior on iPadOS and macOS.

### Creating windows

`struct WindowGroup`

A scene that presents a group of identically structured windows.

`struct Window`

A scene that presents its content in a single, unique window.

`struct UtilityWindow`

A specialized window scene that provides secondary utility to the content of the main scenes of an application.

`protocol WindowStyle`

A specification for the appearance and interaction of a window.

Sets the style for windows created by this scene.

### Styling the associated toolbar

Sets the style for the toolbar defined within this scene.

Sets the label style of items in a toolbar and enables user customization.

Sets the label style of items in a toolbar.

`protocol WindowToolbarStyle`

A specification for the appearance and behavior of a window’s toolbar.

### Opening windows

Presenting windows and spaces

Open and close the scenes that make up your app’s interface.

`var supportsMultipleWindows: Bool`

A Boolean value that indicates whether the current platform supports opening multiple windows.

`var openWindow: OpenWindowAction`

A window presentation action stored in a view’s environment.

`struct OpenWindowAction`

An action that presents a window.

`struct PushWindowAction`

An action that opens the requested window in place of the window the action is called from.

### Closing windows

`var dismissWindow: DismissWindowAction`

A window dismissal action stored in a view’s environment.

`struct DismissWindowAction`

An action that dismisses a window associated to a particular scene.

`var dismiss: DismissAction`

An action that dismisses the current presentation.

`struct DismissAction`

An action that dismisses a presentation.

`struct DismissBehavior`

Programmatic window dismissal behaviors.

### Sizing a window

Positioning and sizing windows

Influence the initial geometry of windows that your app presents.

`func defaultSize(_:)`

Sets a default size for a window.

Sets a default width and height for a window.

Sets a default size for a volumetric window.

Sets the kind of resizability to use for a window.

`struct WindowResizability`

The resizability of a window.

Specifies how windows derived form this scene should determine their size when zooming.

`struct WindowIdealSize`

A type which defines the size a window should use when zooming.

### Positioning a window

Sets a default position for a window.

`struct WindowLevel`

The level of a window.

Sets the window level of this scene.

`struct WindowLayoutRoot`

A proxy which represents the root contents of a window.

`struct WindowPlacement`

A type which represents a preferred size and position for a window.

Defines a function used for determining the default placement of windows.

Provides a function which determines a placement to use when windows of a scene zoom.

`struct WindowPlacementContext`

A type which represents contextual information used for sizing and positioning windows.

`struct WindowProxy`

The proxy for an open window in the app.

`struct DisplayProxy`

A type which provides information about display hardware.

### Configuring window visibility

`struct WindowVisibilityToggle`

A specialized button for toggling the visibility of a window.

Sets the default launch behavior for this scene.

Sets the restoration behavior for this scene.

`struct SceneLaunchBehavior`

The launch behavior for a scene.

`struct SceneRestorationBehavior`

The restoration behavior for a scene.

Sets the preferred visibility of the non-transient system views overlaying the app.

Configures the visibility of the window toolbar when the window enters full screen mode.

`struct WindowToolbarFullScreenVisibility`

The visibility of the window toolbar with respect to full screen mode.

### Managing window behavior

`struct WindowManagerRole`

Options for defining how a scene’s windows behave when used within a managed window context, such as full screen mode and Stage Manager.

Configures the role for windows derived from `self` when participating in a managed window context, such as full screen or Stage Manager.

`struct WindowInteractionBehavior`

Options for enabling and disabling window interaction behaviors.

Configures the dismiss functionality for the window enclosing `self`.

Configures the full screen functionality for the window enclosing `self`.

Configures the minimize functionality for the window enclosing `self`.

Configures the resize functionality for the window enclosing `self`.

Configures the behavior of dragging a window by its background.

### Interacting with volumes

Adds an action to perform when the viewpoint of the volume changes.

Specifies which viewpoints are supported for the window bar and ornaments in a volume.

`struct VolumeViewpointUpdateStrategy`

A type describing when the action provided to `onVolumeViewpointChange(updateStrategy:initial:_:)` should be called.

`struct Viewpoint3D`

A type describing what direction something is being viewed from.

`enum SquareAzimuth`

A type describing what direction something is being viewed from along the horizontal plane and snapped to 4 directions.

`struct WorldAlignmentBehavior`

A type representing the world alignment behavior for a scene.

Specifies how a volume should be aligned when moved in the world.

`struct WorldScalingBehavior`

Specifies the scaling behavior a window should have within the world.

Specify the world scaling behavior for the window.

`struct WorldScalingCompensation`

Indicates whether returned metrics will take dynamic scaling into account.

The current limitations of the device tracking the user’s surroundings.

`struct WorldTrackingLimitation`

A structure to represent limitations of tracking the user’s surroundings.

`struct SurfaceSnappingInfo`

A type representing information about the window scenes snap state.

Beta

### Deprecated Types

`enum ControlActiveState`

The active appearance expected of controls in a window.

Deprecated

## See Also

### App structure

Define the entry point and top-level structure of your app.

Declare the user interface groupings that make up the parts of your app.

Display unbounded content in a person’s surroundings.

Enable people to open and manage documents.

Enable people to move between different parts of your app’s view hierarchy within a scene.

Present content in a separate view that offers focused interaction.

Provide immediate access to frequently used commands and controls.

Enable people to search for text or other content within your app.

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

---

# https://developer.apple.com/documentation/swiftui/immersive-spaces

Collection

- SwiftUI
- Immersive spaces

API Collection

# Immersive spaces

Display unbounded content in a person’s surroundings.

## Overview

Use an immersive space in visionOS to present SwiftUI views outside of any containers. You can include any views in a space, although you typically use a `RealityView` to present RealityKit content.

You can request one of three styles of spaces with the `immersionStyle(selection:in:)` scene modifier:

- The `mixed` style blends your content with passthrough. This enables you to place virtual objects in a person’s surroundings.

- The `full` style displays only your content, with passthrough turned off. This enables you to completely control the visual experience, like when you want to transport people to a new world.

- The `progressive` style completely replaces passthrough in a portion of the display. You might use this style to keep people grounded in the real world while displaying a view into another world.

When you open an immersive space, the system continues to display all of your app’s windows, but hides windows from other apps. The system supports displaying only one space at a time across all apps, so your app can only open a space if one isn’t already open.

## Topics

### Creating an immersive space

`struct ImmersiveSpace`

A scene that presents its content in an unbounded space.

`struct ImmersiveSpaceContentBuilder`

A result builder for composing a collection of immersive space elements.

Sets the style for an immersive space.

`protocol ImmersionStyle`

The styles that an immersive space can have.

`var immersiveSpaceDisplacement: Pose3D`

The displacement that the system applies to the immersive space when moving the space away from its default position, in meters.

`struct ImmersiveEnvironmentBehavior`

The behavior of the system-provided immersive environments when a scene is opened by your app.

Beta

`struct ProgressiveImmersionAspectRatio` Beta

### Opening an immersive space

`var openImmersiveSpace: OpenImmersiveSpaceAction`

An action that presents an immersive space.

`struct OpenImmersiveSpaceAction`

### Closing the immersive space

`var dismissImmersiveSpace: DismissImmersiveSpaceAction`

An immersive space dismissal action stored in a view’s environment.

`struct DismissImmersiveSpaceAction`

An action that dismisses an immersive space.

### Hiding upper limbs during immersion

Sets the preferred visibility of the user’s upper limbs, while an `ImmersiveSpace` scene is presented.

### Adjusting content brightness

Sets the content brightness of an immersive space.

`struct ImmersiveContentBrightness`

The content brightness of an immersive space.

### Responding to immersion changes

Performs an action when the immersion state of your app changes.

`struct ImmersionChangeContext`

A structure that represents a state of immersion of your app.

### Adding menu items to an immersive space

Add menu items to open immersive spaces from a media player’s environment picker.

### Handling remote immersive spaces

`struct RemoteImmersiveSpace`

A scene that presents its content in an unbounded space on a remote device.

`struct RemoteDeviceIdentifier`

An opaque type that identifies a remote device displaying scene content in a `RemoteImmersiveSpace`.

## See Also

### App structure

Define the entry point and top-level structure of your app.

Declare the user interface groupings that make up the parts of your app.

Display user interface content in a window or a collection of windows.

Enable people to open and manage documents.

Enable people to move between different parts of your app’s view hierarchy within a scene.

Present content in a separate view that offers focused interaction.

Provide immediate access to frequently used commands and controls.

Enable people to search for text or other content within your app.

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

---

# https://developer.apple.com/documentation/swiftui/documents

Collection

- SwiftUI
- Documents

API Collection

# Documents

Enable people to open and manage documents.

## Overview

Create a user interface for opening and editing documents using the `DocumentGroup` scene type.

You initialize the scene with a model that describes the organization of the document’s data, and a view hierarchy that SwiftUI uses to display the document’s contents to the user. You can use either a value type model, which you typically store as a structure, that conforms to the `FileDocument` protocol, or a reference type model you store in a class instance that conforms to the `ReferenceFileDocument` protocol. You can also use SwiftData-backed documents using an initializer like `init(editing:contentType:editor:prepareDocument:)`.

SwiftUI supports standard behaviors that users expect from a document-based app, appropriate for each platform, like multiwindow support, open and save panels, drag and drop, and so on. For related design guidance, see Patterns in the Human Interface Guidelines.

## Topics

### Creating a document

Building a document-based app with SwiftUI

Create, save, and open documents in a multiplatform app.

Building a document-based app using SwiftData

Code along with the WWDC presenter to transform an app with SwiftData.

`struct DocumentGroup`

A scene that enables support for opening, creating, and saving documents.

### Storing document data in a structure instance

`protocol FileDocument`

A type that you use to serialize documents to and from file.

`struct FileDocumentConfiguration`

The properties of an open file document.

### Storing document data in a class instance

`protocol ReferenceFileDocument`

A type that you use to serialize reference type documents to and from file.

`struct ReferenceFileDocumentConfiguration`

The properties of an open reference file document.

`var undoManager: UndoManager?`

The undo manager used to register a view’s undo operations.

### Accessing document configuration

`var documentConfiguration: DocumentConfiguration?`

The configuration of a document in a `DocumentGroup`.

`struct DocumentConfiguration`

### Reading and writing documents

`struct FileDocumentReadConfiguration`

The configuration for reading file contents.

`struct FileDocumentWriteConfiguration`

The configuration for serializing file contents.

### Opening a document programmatically

`var newDocument: NewDocumentAction`

An action in the environment that presents a new document.

`struct NewDocumentAction`

An action that presents a new document.

`var openDocument: OpenDocumentAction`

An action in the environment that presents an existing document.

`struct OpenDocumentAction`

An action that presents an existing document.

### Configuring the document launch experience

`struct DocumentGroupLaunchScene`

A launch scene for document-based applications.

`struct DocumentLaunchView`

A view to present when launching document-related user experience.

`struct DocumentLaunchGeometryProxy`

A proxy for access to the frame of the scene and its title view.

`struct DefaultDocumentGroupLaunchActions`

The default actions for the document group launch scene and the document launch view.

`struct NewDocumentButton`

A button that creates and opens new documents.

`protocol DocumentBaseBox`

A Box that allows setting its Document base not requiring the caller to know the exact types of the box and its base.

### Renaming a document

`struct RenameButton`

A button that triggers a standard rename action.

`func renameAction(_:)`

Sets a closure to run for the rename action.

`var rename: RenameAction?`

An action that activates the standard rename interaction.

`struct RenameAction`

An action that activates a standard rename interaction.

## See Also

### App structure

Define the entry point and top-level structure of your app.

Declare the user interface groupings that make up the parts of your app.

Display user interface content in a window or a collection of windows.

Display unbounded content in a person’s surroundings.

Enable people to move between different parts of your app’s view hierarchy within a scene.

Present content in a separate view that offers focused interaction.

Provide immediate access to frequently used commands and controls.

Enable people to search for text or other content within your app.

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

---

# https://developer.apple.com/documentation/swiftui/navigation

Collection

- SwiftUI
- Navigation

API Collection

# Navigation

Enable people to move between different parts of your app’s view hierarchy within a scene.

## Overview

Use navigation containers to provide structure to your app’s user interface, enabling people to easily move among the parts of your app.

For example, people can move forward and backward through a stack of views using a `NavigationStack`, or choose which view to display from a tab bar using a `TabView`.

Configure navigation containers by adding view modifiers like `navigationSplitViewStyle(_:)` to the container. Use other modifiers on the views inside the container to affect the container’s behavior when showing that view. For example, you can use `navigationTitle(_:)` on a view to provide a toolbar title to display when showing that view.

## Topics

### Essentials

Understanding the navigation stack

Learn about the navigation stack, links, and how to manage navigation types in your app’s structure.

### Presenting views in columns

Bringing robust navigation structure to your SwiftUI app

Use navigation links, stacks, destinations, and paths to provide a streamlined experience for all platforms, as well as behaviors such as deep linking and state restoration.

Migrating to new navigation types

Improve navigation behavior in your app by replacing navigation views with navigation stacks and navigation split views.

`struct NavigationSplitView`

A view that presents views in two or three columns, where selections in leading columns control presentations in subsequent columns.

Sets the style for navigation split views within this view.

Sets a fixed, preferred width for the column containing this view.

Sets a flexible, preferred width for the column containing this view.

`struct NavigationSplitViewVisibility`

The visibility of the leading columns in a navigation split view.

`struct NavigationLink`

A view that controls a navigation presentation.

### Stacking views in one column

`struct NavigationStack`

A view that displays a root view and enables you to present additional views over the root view.

`struct NavigationPath`

A type-erased list of data representing the content of a navigation stack.

Associates a destination view with a presented data type for use within a navigation stack.

Associates a destination view with a binding that can be used to push the view onto a `NavigationStack`.

`func navigationDestination<D, C>(item: Binding<Optional<D>>, destination: (D) -> C) -> some View`

Associates a destination view with a bound value for use within a navigation stack or navigation split view

### Managing column collapse

`struct NavigationSplitViewColumn`

A view that represents a column in a navigation split view.

### Setting titles for navigation content

`func navigationTitle(_:)`

Configures the view’s title for purposes of navigation, using a string binding.

`func navigationSubtitle(_:)`

Configures the view’s subtitle for purposes of navigation.

`func navigationDocument(_:)`

Configures the view’s document for purposes of navigation.

`func navigationDocument(_:preview:)`

### Configuring the navigation bar

Hides the navigation bar back button for the view.

Configures the title display mode for this view.

`struct NavigationBarItem`

A configuration for a navigation bar that represents a view at the top of a navigation stack.

### Configuring the sidebar

`var sidebarRowSize: SidebarRowSize`

The current size of sidebar rows.

`enum SidebarRowSize`

The standard sizes of sidebar rows.

### Presenting views in tabs

Enhancing your app’s content with tab navigation

Keep your app content front and center while providing quick access to navigation using the tab bar.

`struct TabView`

A view that switches between multiple child views using interactive user interface elements.

`struct Tab`

The content for a tab and the tab’s associated tab item in a tab view.

`struct TabRole`

A value that defines the purpose of the tab.

`struct TabSection`

A container that you can use to add hierarchy within a tab view.

Sets the style for the tab view within the current environment.

### Configuring a tab bar

Adds a custom header to the sidebar of a tab view.

Adds a custom footer to the sidebar of a tab view.

Adds a custom bottom bar to the sidebar of a tab view.

`struct AdaptableTabBarPlacement`

A placement for tabs in a tab view using the adaptable sidebar style.

`var tabBarPlacement: TabBarPlacement?`

The current placement of the tab bar.

`struct TabBarPlacement`

A placement for tabs in a tab view.

`var isTabBarShowingSections: Bool`

A Boolean value that determines whether a tab view shows the expanded contents of a tab section.

`struct TabBarMinimizeBehavior` Beta

`enum TabViewBottomAccessoryPlacement`

A placement of the bottom accessory in a tab view. You can use this to adjust the content of the accessory view based on the placement.

Beta

### Configuring a tab

Adds custom actions to a section.

`struct TabPlacement`

A place that a tab can appear.

`struct TabContentBuilder`

A result builder that constructs tabs for a tab view that supports programmatic selection. This builder requires that all tabs in the tab view have the same selection type.

`protocol TabContent`

A type that provides content for programmatically selectable tabs in a tab view.

`struct AnyTabContent`

Type erased tab content.

### Enabling tab customization

Specifies the customizations to apply to the sidebar representation of the tab view.

`struct TabViewCustomization`

The customizations a person makes to an adaptable sidebar tab view.

`struct TabCustomizationBehavior`

The customization behavior of customizable tab view content.

### Displaying views in multiple panes

`struct HSplitView`

A layout container that arranges its children in a horizontal line and allows the user to resize them using dividers placed between them.

`struct VSplitView`

A layout container that arranges its children in a vertical line and allows the user to resize them using dividers placed between them.

### Deprecated Types

`struct NavigationView`

A view for presenting a stack of views that represents a visible path in a navigation hierarchy.

Deprecated

Sets the tab bar item associated with this view.

## See Also

### App structure

Define the entry point and top-level structure of your app.

Declare the user interface groupings that make up the parts of your app.

Display user interface content in a window or a collection of windows.

Display unbounded content in a person’s surroundings.

Enable people to open and manage documents.

Present content in a separate view that offers focused interaction.

Provide immediate access to frequently used commands and controls.

Enable people to search for text or other content within your app.

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

---

# https://developer.apple.com/documentation/swiftui/modal-presentations

Collection

- SwiftUI
- Modal presentations

API Collection

# Modal presentations

Present content in a separate view that offers focused interaction.

## Overview

To draw attention to an important, narrowly scoped task, you display a modal presentation, like an alert, popover, sheet, or confirmation dialog.

In SwiftUI, you create a modal presentation using a view modifier that defines how the presentation looks and the condition under which SwiftUI presents it. SwiftUI detects when the condition changes and makes the presentation for you. Because you provide a `Binding` to the condition that initiates the presentation, SwiftUI can reset the underlying value when the user dismisses the presentation.

For design guidance, see Modality in the Human Interface Guidelines.

## Topics

### Configuring a dialog

`struct DialogSeverity`

The severity of an alert or confirmation dialog.

### Showing a sheet, cover, or popover

Presents a sheet when a binding to a Boolean value that you provide is true.

Presents a sheet using the given item as a data source for the sheet’s content.

Presents a modal view that covers as much of the screen as possible when binding to a Boolean value you provide is true.

Presents a modal view that covers as much of the screen as possible using the binding you provide as a data source for the sheet’s content.

Presents a popover using the given item as a data source for the popover’s content.

Presents a popover when a given condition is true.

`enum PopoverAttachmentAnchor`

An attachment anchor for a popover.

### Adapting a presentation size

Specifies how to adapt a presentation to horizontally and vertically compact size classes.

Specifies how to adapt a presentation to compact size classes.

`struct PresentationAdaptation`

Strategies for adapting a presentation to a different size class.

Sets the sizing of the containing presentation.

`protocol PresentationSizing`

A type that defines the size of the presentation content and how the presentation size adjusts to its content’s size changing.

`struct PresentationSizingRoot`

A proxy to a view provided to the presentation with a defined presentation size.

`struct PresentationSizingContext`

Contextual information about a presentation.

### Configuring a sheet’s height

Sets the available detents for the enclosing sheet.

Sets the available detents for the enclosing sheet, giving you programmatic control of the currently selected detent.

Configures the behavior of swipe gestures on a presentation.

Sets the visibility of the drag indicator on top of a sheet.

`struct PresentationDetent`

A type that represents a height where a sheet naturally rests.

`protocol CustomPresentationDetent`

The definition of a custom detent with a calculated height.

`struct PresentationContentInteraction`

A behavior that you can use to influence how a presentation responds to swipe gestures.

### Styling a sheet and its background

Requests that the presentation have a specific corner radius.

Sets the presentation background of the enclosing sheet using a shape style.

Sets the presentation background of the enclosing sheet to a custom view.

Controls whether people can interact with the view behind a presentation.

`struct PresentationBackgroundInteraction`

The kinds of interaction available to views behind a presentation.

### Presenting an alert

`struct AlertScene`

A scene that renders itself as a standalone alert dialog.

`func alert(_:isPresented:actions:)`

Presents an alert when a given condition is true, using a text view for the title.

`func alert(_:isPresented:presenting:actions:)`

Presents an alert using the given data to produce the alert’s content and a text view as a title.

Presents an alert when an error is present.

`func alert(_:isPresented:actions:message:)`

Presents an alert with a message when a given condition is true using a text view as a title.

`func alert(_:isPresented:presenting:actions:message:)`

Presents an alert with a message using the given data to produce the alert’s content and a text view for a title.

Presents an alert with a message when an error is present.

### Getting confirmation for an action

`func confirmationDialog(_:isPresented:titleVisibility:actions:)`

Presents a confirmation dialog when a given condition is true, using a text view for the title.

`func confirmationDialog(_:isPresented:titleVisibility:presenting:actions:)`

Presents a confirmation dialog using data to produce the dialog’s content and a text view for the title.

`func dismissalConfirmationDialog(_:shouldPresent:actions:)`

Presents a confirmation dialog when a dismiss action has been triggered.

### Showing a confirmation dialog with a message

`func confirmationDialog(_:isPresented:titleVisibility:actions:message:)`

Presents a confirmation dialog with a message when a given condition is true, using a text view for the title.

`func confirmationDialog(_:isPresented:titleVisibility:presenting:actions:message:)`

Presents a confirmation dialog with a message using data to produce the dialog’s content and a text view for the message.

`func dismissalConfirmationDialog(_:shouldPresent:actions:message:)`

### Configuring a dialog

Configures the icon used by dialogs within this view.

Configures the icon used by alerts.

Sets the severity for alerts.

Enables user suppression of dialogs and alerts presented within `self`, with a default suppression message on macOS. Unused on other platforms.

Enables user suppression of an alert with a custom suppression message.

`func dialogSuppressionToggle(_:isSuppressed:)`

Enables user suppression of dialogs and alerts presented within `self`, with a custom suppression message on macOS. Unused on other platforms.

### Exporting to file

`func fileExporter(isPresented:document:contentType:defaultFilename:onCompletion:)`

Presents a system interface for exporting a document that’s stored in a value type, like a structure, to a file on disk.

`func fileExporter(isPresented:documents:contentType:onCompletion:)`

Presents a system interface for exporting a collection of value type documents to files on disk.

`func fileExporter(isPresented:document:contentTypes:defaultFilename:onCompletion:onCancellation:)`

Presents a system interface for allowing the user to export a `FileDocument` to a file on disk.

`func fileExporter(isPresented:documents:contentTypes:onCompletion:onCancellation:)`

Presents a system dialog for allowing the user to export a collection of documents that conform to `FileDocument` to files on disk.

Presents a system interface allowing the user to export a `Transferable` item to file on disk.

Presents a system interface allowing the user to export a collection of items to files on disk.

`func fileExporterFilenameLabel(_:)`

On macOS, configures the `fileExporter` with a label for the file name field.

### Importing from file

Presents a system interface for allowing the user to import multiple files.

Presents a system interface for allowing the user to import an existing file.

Presents a system dialog for allowing the user to import multiple files.

### Moving a file

Presents a system interface for allowing the user to move an existing file to a new location.

Presents a system interface for allowing the user to move a collection of existing files to a new location.

Presents a system dialog for allowing the user to move an existing file to a new location.

Presents a system dialog for allowing the user to move a collection of existing files to a new location.

### Configuring a file dialog

On macOS, configures the `fileExporter`, `fileImporter`, or `fileMover` to provide a refined URL search experience: include or exclude hidden files, allow searching by tag, etc.

`func fileDialogConfirmationLabel(_:)`

On macOS, configures the the `fileExporter`, `fileImporter`, or `fileMover` with a custom confirmation button label.

On macOS, configures the `fileExporter`, `fileImporter`, or `fileMover` to persist and restore the file dialog configuration.

Configures the `fileExporter`, `fileImporter`, or `fileMover` to open with the specified default directory.

On macOS, configures the `fileExporter`, `fileImporter`, or `fileMover` behavior when a user chooses an alias.

`func fileDialogMessage(_:)`

On macOS, configures the the `fileExporter`, `fileImporter`, or `fileMover` with a custom text that is presented to the user, similar to a title.

On macOS, configures the the `fileImporter` or `fileMover` to conditionally disable presented URLs.

`struct FileDialogBrowserOptions`

The way that file dialogs present the file system.

### Presenting an inspector

Inserts an inspector at the applied position in the view hierarchy.

Sets a fixed, preferred width for the inspector containing this view when presented as a trailing column.

Sets a flexible, preferred width for the inspector in a trailing-column presentation.

### Dismissing a presentation

`var isPresented: Bool`

A Boolean value that indicates whether the view associated with this environment is currently presented.

`var dismiss: DismissAction`

An action that dismisses the current presentation.

`struct DismissAction`

An action that dismisses a presentation.

Conditionally prevents interactive dismissal of presentations like popovers, sheets, and inspectors.

### Deprecated modal presentations

`struct Alert`

A representation of an alert presentation.

Deprecated

`struct ActionSheet`

A representation of an action sheet presentation.

## See Also

### App structure

Define the entry point and top-level structure of your app.

Declare the user interface groupings that make up the parts of your app.

Display user interface content in a window or a collection of windows.

Display unbounded content in a person’s surroundings.

Enable people to open and manage documents.

Enable people to move between different parts of your app’s view hierarchy within a scene.

Provide immediate access to frequently used commands and controls.

Enable people to search for text or other content within your app.

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

---

# https://developer.apple.com/documentation/swiftui/toolbars

Collection

- SwiftUI
- Toolbars

API Collection

# Toolbars

Provide immediate access to frequently used commands and controls.

## Overview

The system might present toolbars above or below your app’s content, depending on the platform and the context.

Add items to a toolbar by applying the `toolbar(content:)` view modifier to a view in your app. You can also configure the toolbar using view modifiers. For example, you can set the visibility of a toolbar with the `toolbar(_:for:)` modifier.

For design guidance, see Toolbars in the Human Interface Guidelines.

## Topics

### Populating a toolbar

`func toolbar(content:)`

Populates the toolbar or navigation bar with the specified items.

`struct ToolbarItem`

A model that represents an item which can be placed in the toolbar or navigation bar.

`struct ToolbarItemGroup`

A model that represents a group of `ToolbarItem` s which can be placed in the toolbar or navigation bar.

`struct ToolbarItemPlacement`

A structure that defines the placement of a toolbar item.

`protocol ToolbarContent`

Conforming types represent items that can be placed in various locations in a toolbar.

`struct ToolbarContentBuilder`

Constructs a toolbar item set from multi-expression closures.

`struct ToolbarSpacer`

A standard space item in toolbars.

Beta

`struct DefaultToolbarItem`

A toolbar item that represents a system component.

### Populating a customizable toolbar

Populates the toolbar or navigation bar with the specified items, allowing for user customization.

`protocol CustomizableToolbarContent`

Conforming types represent items that can be placed in various locations in a customizable toolbar.

`struct ToolbarCustomizationBehavior`

The customization behavior of customizable toolbar content.

`struct ToolbarCustomizationOptions`

Options that influence the default customization behavior of customizable toolbar content.

`struct SearchToolbarBehavior`

The behavior of a search field in a toolbar.

### Removing default items

Remove a toolbar item present by default

`struct ToolbarDefaultItemKind`

A kind of toolbar item a `View` adds by default.

### Setting toolbar visibility

Specifies the visibility of a bar managed by SwiftUI.

Specifies the preferred visibility of backgrounds on a bar managed by SwiftUI.

`struct ToolbarPlacement`

The placement of a toolbar.

`struct ContentToolbarPlacement`

### Specifying the role of toolbar content

Configures the semantic role for the content populating the toolbar.

`struct ToolbarRole`

The purpose of content that populates the toolbar.

### Styling a toolbar

`func toolbarBackground(_:for:)`

Specifies the preferred shape style of the background of a bar managed by SwiftUI.

Specifies the preferred color scheme of a bar managed by SwiftUI.

Specifies the preferred foreground style of bars managed by SwiftUI.

Sets the style for the toolbar defined within this scene.

`protocol WindowToolbarStyle`

A specification for the appearance and behavior of a window’s toolbar.

`var toolbarLabelStyle: ToolbarLabelStyle?`

The label style to apply to controls within a toolbar.

`struct ToolbarLabelStyle`

The label style of a toolbar.

`struct SpacerSizing`

A type which defines how spacers should size themselves.

### Configuring the toolbar title display mode

Configures the toolbar title display mode for this view.

`struct ToolbarTitleDisplayMode`

A type that defines the behavior of title of a toolbar.

### Setting the toolbar title menu

Configure the title menu of a toolbar.

`struct ToolbarTitleMenu`

The title menu of a toolbar.

### Creating an ornament

`func ornament(visibility:attachmentAnchor:contentAlignment:ornament:)`

Presents an ornament.

`struct OrnamentAttachmentAnchor`

An attachment anchor for an ornament.

## See Also

### App structure

Define the entry point and top-level structure of your app.

Declare the user interface groupings that make up the parts of your app.

Display user interface content in a window or a collection of windows.

Display unbounded content in a person’s surroundings.

Enable people to open and manage documents.

Enable people to move between different parts of your app’s view hierarchy within a scene.

Present content in a separate view that offers focused interaction.

Enable people to search for text or other content within your app.

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

---

# https://developer.apple.com/documentation/swiftui/search

Collection

- SwiftUI
- Search

API Collection

# Search

Enable people to search for text or other content within your app.

## Overview

To present a search field in your app, create and manage storage for search text and optionally for discrete search terms known as _tokens_. Then bind the storage to the search field by applying the searchable view modifier to a view in your app.

As people interact with the field, they implicitly modify the underlying storage and, thereby, the search parameters. Your app correspondingly updates other parts of its interface. To enhance the search interaction, you can also:

- Offer suggestions during search, for both text and tokens.

- Implement search scopes that help people to narrow the search space.

- Detect when people activate the search field, and programmatically dismiss the search field using environment values.

For design guidance, see Searching in the Human Interface Guidelines.

## Topics

### Searching your app’s data model

Adding a search interface to your app

Present an interface that people can use to search for content in your app.

Performing a search operation

Update search results based on search text and optional tokens that you store.

`func searchable(text:placement:prompt:)`

Marks this view as searchable, which configures the display of a search field.

`func searchable(text:tokens:placement:prompt:token:)`

Marks this view as searchable with text and tokens.

`func searchable(text:editableTokens:placement:prompt:token:)`

`struct SearchFieldPlacement`

The placement of a search field in a view hierarchy.

### Making search suggestions

Suggesting search terms

Provide suggestions to people searching for content in your app.

Configures the search suggestions for this view.

Configures how to display search suggestions within this view.

`func searchCompletion(_:)`

Associates a fully formed string with the value of this view when used as a search suggestion.

`func searchable(text:tokens:suggestedTokens:placement:prompt:token:)`

Marks this view as searchable with text, tokens, and suggestions.

`struct SearchSuggestionsPlacement`

The ways that SwiftUI displays search suggestions.

### Limiting search scope

Scoping a search operation

Divide the search space into a few broad categories.

Configures the search scopes for this view.

Configures the search scopes for this view with the specified activation strategy.

`struct SearchScopeActivation`

The ways that searchable modifiers can show or hide search scopes.

### Detecting, activating, and dismissing search

Managing search interface activation

Programmatically detect and dismiss a search field.

`var isSearching: Bool`

A Boolean value that indicates when the user is searching.

`var dismissSearch: DismissSearchAction`

An action that ends the current search interaction.

`struct DismissSearchAction`

An action that can end a search interaction.

`func searchable(text:isPresented:placement:prompt:)`

Marks this view as searchable with programmatic presentation of the search field.

`func searchable(text:tokens:isPresented:placement:prompt:token:)`

Marks this view as searchable with text and tokens, as well as programmatic presentation.

`func searchable(text:editableTokens:isPresented:placement:prompt:token:)`

`func searchable(text:tokens:suggestedTokens:isPresented:placement:prompt:token:)`

Marks this view as searchable with text, tokens, and suggestions, as well as programmatic presentation.

### Displaying toolbar content during search

Configures the search toolbar presentation behavior for any searchable modifiers within this view.

`struct SearchPresentationToolbarBehavior`

A type that defines how the toolbar behaves when presenting search.

### Searching for text in a view

Programmatically presents the find and replace interface for text editor views.

Prevents find and replace operations in a text editor.

Prevents replace operations in a text editor.

`struct FindContext`

The status of the find navigator for views which support text editing.

Beta

## See Also

### App structure

Define the entry point and top-level structure of your app.

Declare the user interface groupings that make up the parts of your app.

Display user interface content in a window or a collection of windows.

Display unbounded content in a person’s surroundings.

Enable people to open and manage documents.

Enable people to move between different parts of your app’s view hierarchy within a scene.

Present content in a separate view that offers focused interaction.

Provide immediate access to frequently used commands and controls.

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

---

# https://developer.apple.com/documentation/swiftui/app-extensions

Collection

- SwiftUI
- App extensions

API Collection

# App extensions

Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

## Overview

Use SwiftUI along with WidgetKit to add widgets to your app.

Widgets provide quick access to relevant content from your app. Define a structure that conforms to the `Widget` protocol, and declare a view hierarchy for the widget. Configure the views inside the widget as you do other SwiftUI views, using view modifiers, including a few widget-specific modifiers.

For design guidance, see Widgets in the Human Interface Guidelines.

## Topics

### Creating widgets

Building Widgets Using WidgetKit and SwiftUI

Create widgets to show your app’s content on the Home screen, with custom intents for user-customizable settings.

Creating a widget extension

Display your app’s content in a convenient, informative widget on various devices.

Keeping a widget up to date

Plan your widget’s timeline to show timely, relevant information using dynamic views, and update the timeline when things change.

Making a configurable widget

Give people the option to customize their widgets by adding a custom app intent to your project.

`protocol Widget`

The configuration and content of a widget to display on the Home screen or in Notification Center.

`protocol WidgetBundle`

A container used to expose multiple widgets from a single widget extension.

`struct LimitedAvailabilityConfiguration`

A type-erased widget configuration.

`protocol WidgetConfiguration`

A type that describes a widget’s content.

`struct EmptyWidgetConfiguration`

An empty widget configuration.

### Composing control widgets

`protocol ControlWidget`

The configuration and content of a control widget to display in system spaces such as Control Center, the Lock Screen, and the Action Button.

`protocol ControlWidgetConfiguration`

A type that describes a control widget’s content.

`struct EmptyControlWidgetConfiguration`

An empty control widget configuration.

`struct ControlWidgetConfigurationBuilder`

A custom attribute that constructs a control widget’s body.

`protocol ControlWidgetTemplate`

`struct EmptyControlWidgetTemplate`

An empty control widget template.

`struct ControlWidgetTemplateBuilder`

A custom attribute that constructs a control widget template’s body.

`func controlWidgetActionHint(_:)`

The action hint of the control described by the modified label.

`func controlWidgetStatus(_:)`

The status of the control described by the modified label.

### Labeling a widget

`func widgetLabel(_:)`

Returns a localized text label that displays additional content outside the accessory family widget’s main SwiftUI view.

Creates a label for displaying additional content outside an accessory family widget’s main SwiftUI view.

### Styling a widget group

The view modifier that can be applied to `AccessoryWidgetGroup` to specify the shape the three content views will be masked with. The value of `style` is set to `.automatic`, which is `.circular` by default.

### Controlling the accented group

Adds the view and all of its subviews to the accented group.

### Managing placement in the Dynamic Island

Specifies the vertical placement for a view of an expanded Live Activity that appears in the Dynamic Island.

## See Also

### App structure

Define the entry point and top-level structure of your app.

Declare the user interface groupings that make up the parts of your app.

Display user interface content in a window or a collection of windows.

Display unbounded content in a person’s surroundings.

Enable people to open and manage documents.

Enable people to move between different parts of your app’s view hierarchy within a scene.

Present content in a separate view that offers focused interaction.

Provide immediate access to frequently used commands and controls.

Enable people to search for text or other content within your app.

---

# https://developer.apple.com/documentation/swiftui/model-data

Collection

- SwiftUI
- Model data

API Collection

# Model data

Manage the data that your app uses to drive its interface.

## Overview

SwiftUI offers a declarative approach to user interface design. As you compose a hierarchy of views, you also indicate data dependencies for the views. When the data changes, either due to an external event or because of an action that the user performs, SwiftUI automatically updates the affected parts of the interface. As a result, the framework automatically performs most of the work that view controllers traditionally do.

The framework provides tools, like state variables and bindings, for connecting your app’s data to the user interface. These tools help you maintain a single source of truth for every piece of data in your app, in part by reducing the amount of glue logic you write. Select the tool that best suits the task you need to perform:

- Manage transient UI state locally within a view by wrapping value types as `State` properties.

- Share a reference to a source of truth, like local state, using the `Binding` property wrapper.

- Connect to and observe reference model data in views by applying the `Observable()` macro to the model data type. Instantiate an observable model data type directly in a view using a `State` property. Share the observable model data with other views in the hierarchy without passing a reference using the `Environment` property wrapper.

### Leveraging property wrappers

SwiftUI implements many data management types, like `State` and `Binding`, as Swift property wrappers. Apply a property wrapper by adding an attribute with the wrapper’s name to a property’s declaration.

@State private var isVisible = true // Declares isVisible as a state variable.

The property gains the behavior that the wrapper specifies. The state and data flow property wrappers in SwiftUI watch for changes in your data, and automatically update affected views as necessary. When you refer directly to the property in your code, you access the wrapped value, which for the `isVisible` state property in the example above is the stored Boolean.

if isVisible == true {
Text("Hello") // Only renders when isVisible is true.
}

Alternatively, you can access a property wrapper’s projected value by prefixing the property name with the dollar sign ( `$`). SwiftUI state and data flow property wrappers project a `Binding`, which is a two-way connection to the wrapped value, allowing another view to access and mutate a single source of truth.

Toggle("Visible", isOn: $isVisible) // The toggle can update the stored value.

For more information about property wrappers, see Property Wrappers in The Swift Programming Language.

## Topics

### Creating and sharing view state

Managing user interface state

Encapsulate view-specific data within your app’s view hierarchy to make your views reusable.

`struct State`

A property wrapper type that can read and write a value managed by SwiftUI.

`struct Bindable`

A property wrapper type that supports creating bindings to the mutable properties of observable objects.

`struct Binding`

A property wrapper type that can read and write a value owned by a source of truth.

### Creating model data

Managing model data in your app

Create connections between your app’s data model and views.

Migrating from the Observable Object protocol to the Observable macro

Update your existing app to leverage the benefits of Observation in Swift.

`@attached(member, names: named(_$observationRegistrar), named(access), named(withMutation), named(shouldNotifyObservers)) @attached(memberAttribute) @attached(extension, conformances: Observable) macro Observable()`

Defines and implements conformance of the Observable protocol.

Monitoring data changes in your app

Show changes to data in your app’s user interface by using observable objects.

`struct StateObject`

A property wrapper type that instantiates an observable object.

`struct ObservedObject`

A property wrapper type that subscribes to an observable object and invalidates a view whenever the observable object changes.

`protocol ObservableObject : AnyObject`

A type of object with a publisher that emits before the object has changed.

### Responding to data changes

`func onChange(of:initial:_:)`

Adds a modifier for this view that fires an action when a specific value changes.

Adds an action to perform when this view detects data emitted by the given publisher.

### Distributing model data throughout your app

Supplies an observable object to a view’s hierarchy.

Supplies an `ObservableObject` to a view subhierarchy.

`struct EnvironmentObject`

A property wrapper type for an observable object that a parent or ancestor view supplies.

### Managing dynamic data

`protocol DynamicProperty`

An interface for a stored variable that updates an external property of a view.

## See Also

### Data and storage

Share data throughout a view hierarchy using the environment.

Indicate configuration preferences from views to their container views.

Store data for use across sessions of your app.

---

# https://developer.apple.com/documentation/swiftui/environment-values

Collection

- SwiftUI
- Environment values

API Collection

# Environment values

Share data throughout a view hierarchy using the environment.

## Overview

Views in SwiftUI can react to configuration information that they read from the environment using an `Environment` property wrapper.

A view inherits its environment from its container view, subject to explicit changes from an `environment(_:_:)` view modifier, or by implicit changes from one of the many modifiers that operate on environment values. As a result, you can configure a entire hierarchy of views by modifying the environment of the group’s container.

You can find many built-in environment values in the `EnvironmentValues` structure. You can also create a custom `EnvironmentValues` property by defining a new property in an extension to the environment values structure and applying the `Entry()` macro to the variable declaration.

## Topics

### Accessing environment values

`struct Environment`

A property wrapper that reads a value from a view’s environment.

`struct EnvironmentValues`

A collection of environment values propagated through a view hierarchy.

### Creating custom environment values

`macro Entry()`

Creates an environment values, transaction, container values, or focused values entry.

`protocol EnvironmentKey`

A key for accessing values in the environment.

### Modifying the environment of a view

Places an observable object in the view’s environment.

Sets the environment value of the specified key path to the given value.

Transforms the environment value of the specified key path with the given function.

### Modifying the environment of a scene

Places an observable object in the scene’s environment.

## See Also

### Data and storage

Manage the data that your app uses to drive its interface.

Indicate configuration preferences from views to their container views.

Store data for use across sessions of your app.

---

# https://developer.apple.com/documentation/swiftui/preferences

Collection

- SwiftUI
- Preferences

API Collection

# Preferences

Indicate configuration preferences from views to their container views.

## Overview

Whereas you use the environment to configure the subviews of a view, you use preferences to send configuration information from subviews toward their container. However, unlike configuration information that flows down a view hierarchy from one container to many subviews, a single container needs to reconcile potentially conflicting preferences flowing up from its many subviews.

When you use the `PreferenceKey` protocol to define a custom preference, you indicate how to merge preferences from multiple subviews. You can then set a value for the preference on a view using the `preference(key:value:)` view modifier. Many built-in modifiers, like `navigationTitle(_:)`, rely on preferences to send configuration information to their container.

## Topics

### Setting preferences

Sets a value for the given preference.

Applies a transformation to a preference value.

### Creating custom preferences

`protocol PreferenceKey`

A named value produced by a view.

### Setting preferences based on geometry

Sets a value for the specified preference key, the value is a function of a geometry value tied to the current coordinate space, allowing readers of the value to convert the geometry to their local coordinates.

Sets a value for the specified preference key, the value is a function of the key’s current value and a geometry value tied to the current coordinate space, allowing readers of the value to convert the geometry to their local coordinates.

### Responding to changes in preferences

Adds an action to perform when the specified preference key’s value changes.

### Generating backgrounds and overlays from preferences

Reads the specified preference value from the view, using it to produce a second view that is applied as the background of the original view.

Reads the specified preference value from the view, using it to produce a second view that is applied as an overlay to the original view.

## See Also

### Data and storage

Manage the data that your app uses to drive its interface.

Share data throughout a view hierarchy using the environment.

Store data for use across sessions of your app.

---

# https://developer.apple.com/documentation/swiftui/persistent-storage

Collection

- SwiftUI
- Persistent storage

API Collection

# Persistent storage

Store data for use across sessions of your app.

## Overview

The operating system provides ways to store data when your app closes, so that when people open your app again later, they can continue working without interruption. The mechanism that you use depends on factors like what and how much you need to store, whether you need serialized or random access to the data, and so on.

You use the same kinds of storage in a SwiftUI app that you use in any other app. For example, you can access files on disk using the `FileManager` interface. However, SwiftUI also provides conveniences that make it easier to use certain kinds of persistent storage in a declarative environment. For example, you can use `FetchRequest` and `FetchedResults` to interact with a Core Data model.

## Topics

### Saving state across app launches

Restoring Your App’s State with SwiftUI

Provide app continuity for users by preserving their current activities.

The default store used by `AppStorage` contained within the view.

`struct AppStorage`

A property wrapper type that reflects a value from `UserDefaults` and invalidates a view on a change in value in that user default.

`struct SceneStorage`

A property wrapper type that reads and writes to persisted, per-scene storage.

### Accessing Core Data

Loading and Displaying a Large Data Feed

Consume data in the background, and lower memory use by batching imports and preventing duplicate records.

`var managedObjectContext: NSManagedObjectContext`

`struct FetchRequest`

A property wrapper type that retrieves entities from a Core Data persistent store.

`struct FetchedResults`

A collection of results retrieved from a Core Data store.

`struct SectionedFetchRequest`

A property wrapper type that retrieves entities, grouped into sections, from a Core Data persistent store.

`struct SectionedFetchResults`

A collection of results retrieved from a Core Data persistent store, grouped into sections.

## See Also

### Data and storage

Manage the data that your app uses to drive its interface.

Share data throughout a view hierarchy using the environment.

Indicate configuration preferences from views to their container views.

---

# https://developer.apple.com/documentation/swiftui/view-fundamentals

Collection

- SwiftUI
- View fundamentals

API Collection

# View fundamentals

Define the visual elements of your app using a hierarchy of views.

## Overview

Views are the building blocks that you use to declare your app’s user interface. Each view contains a description of what to display for a given state. Every bit of your app that’s visible to the user derives from the description in a view, and any type that conforms to the `View` protocol can act as a view in your app.

Compose a custom view by combining built-in views that SwiftUI provides with other custom views that you create in your view’s `body` computed property. Configure views using the view modifiers that SwiftUI provides, or by defining your own view modifiers using the `ViewModifier` protocol and the `modifier(_:)` method.

## Topics

### Creating a view

Declaring a custom view

Define views and assemble them into a view hierarchy.

`protocol View`

A type that represents part of your app’s user interface and provides modifiers that you use to configure views.

`struct ViewBuilder`

A custom parameter attribute that constructs views from closures.

### Modifying a view

Configuring views

Adjust the characteristics of a view by applying view modifiers.

Reducing view modifier maintenance

Bundle view modifiers that you regularly reuse into a custom view modifier.

Applies a modifier to a view and returns a new view.

`protocol ViewModifier`

A modifier that you apply to a view or another view modifier, producing a different version of the original value.

`struct EmptyModifier`

An empty, or identity, modifier, used during development to switch modifiers at compile time.

`struct ModifiedContent`

A value with a modifier applied to it.

`protocol EnvironmentalModifier`

A modifier that must resolve to a concrete modifier in an environment before use.

`struct ManipulableModifier` Beta

`struct ManipulableResponderModifier` Beta

`struct ManipulableTransformBindingModifier` Beta

`struct ManipulationGeometryModifier` Beta

`struct ManipulationGestureModifier` Beta

`struct ManipulationUsingGestureStateModifier` Beta

`enum Manipulable`

A namespace for various manipulable related types.

Beta

### Responding to view life cycle updates

Adds an action to perform before this view appears.

Adds an action to perform after this view disappears.

Adds an asynchronous task to perform before this view appears.

Adds a task to perform before this view appears or when a specified value changes.

### Managing the view hierarchy

Binds a view’s identity to the given proxy value.

Sets the unique tag value of this view.

Prevents the view from updating its child view when its new value is the same as its old value.

### Supporting view types

`struct AnyView`

A type-erased view.

`struct EmptyView`

A view that doesn’t contain any content.

`struct EquatableView`

A view type that compares itself against its previous value and prevents its child updating if its new value is the same as its old value.

`struct SubscriptionView`

A view that subscribes to a publisher with an action.

`struct TupleView`

A View created from a swift tuple of View values.

## See Also

### Views

Adjust the characteristics of views in a hierarchy.

Apply built-in and custom appearances and behaviors to different types of views.

Create smooth visual updates in response to state changes.

Display formatted text and get text input from the user.

Add images and symbols to your app’s user interface.

Display values and get user selections.

Provide space-efficient, context-dependent access to commands and controls.

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

Enhance your views with graphical effects and customized drawings.

---

# https://developer.apple.com/documentation/swiftui/view-configuration

Collection

- SwiftUI
- View configuration

API Collection

# View configuration

Adjust the characteristics of views in a hierarchy.

## Overview

SwiftUI enables you to tune the appearance and behavior of views using view modifiers.

Many modifiers apply to specific kinds of views or behaviors, but some apply more generally. For example, you can conditionally hide any view by dynamically setting its opacity, display contextual help when people hover over a view, or request the light or dark appearance for a view.

## Topics

### Hiding views

Sets the transparency of this view.

Hides this view unconditionally.

### Hiding system elements

Hides the labels of any controls contained within this view.

Controls the visibility of labels of any controls contained within this view.

`var labelsVisibility: Visibility`

The labels visibility set by `labelsVisibility(_:)`.

Sets the menu indicator visibility for controls within this view.

Sets the visibility of the status bar.

Sets the preferred visibility of the non-transient system views overlaying the app.

`enum Visibility`

The visibility of a UI element, chosen automatically based on the platform, current context, and other factors.

### Managing view interaction

Adds a condition that controls whether users can interact with this view.

`var isEnabled: Bool`

A Boolean value that indicates whether the view associated with this environment allows user interaction.

Sets a tag that you use for tracking interactivity.

Mark the receiver as their content might be invalidated.

### Providing contextual help

`func help(_:)`

Adds help text to a view using a text view that you provide.

### Detecting and requesting the light or dark appearance

Sets the preferred color scheme for this presentation.

`var colorScheme: ColorScheme`

The color scheme of this environment.

`enum ColorScheme`

The possible color schemes, corresponding to the light and dark appearances.

### Getting the color scheme contrast

`var colorSchemeContrast: ColorSchemeContrast`

The contrast associated with the color scheme of this environment.

`enum ColorSchemeContrast`

The contrast between the app’s foreground and background colors.

### Configuring passthrough

Applies an effect to passthrough video.

`struct SurroundingsEffect`

Effects that the system can apply to passthrough video.

`struct BreakthroughEffect` Beta

### Redacting private content

Designing your app for the Always On state

Customize your watchOS app’s user interface for continuous display.

Marks the view as containing sensitive, private user data.

Adds a reason to apply a redaction to this view hierarchy.

Removes any reason to apply a redaction to this view hierarchy.

`var redactionReasons: RedactionReasons`

The current redaction reasons applied to the view hierarchy.

`var isSceneCaptured: Bool`

The current capture state.

`struct RedactionReasons`

The reasons to apply a redaction to data displayed on screen.

## See Also

### Views

Define the visual elements of your app using a hierarchy of views.

Apply built-in and custom appearances and behaviors to different types of views.

Create smooth visual updates in response to state changes.

Display formatted text and get text input from the user.

Add images and symbols to your app’s user interface.

Display values and get user selections.

Provide space-efficient, context-dependent access to commands and controls.

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

Enhance your views with graphical effects and customized drawings.

---

# https://developer.apple.com/documentation/swiftui/view-styles

Collection

- SwiftUI
- View styles

API Collection

# View styles

Apply built-in and custom appearances and behaviors to different types of views.

## Overview

SwiftUI defines built-in styles for certain kinds of views and automatically selects the appropriate style for a particular presentation context. For example, a `Label` might appear as an icon, a string title, or both, depending on factors like the platform, whether the view appears in a toolbar, and so on.

You can override the automatic style by using one of the style view modifiers. These modifiers typically propagate throughout a container view, so that you can wrap a view hierarchy in a style modifier to affect all the views of the given type within the hierarchy.

Any of the style protocols that define a `makeBody(configuration:)` method, like `ToggleStyle`, also enable you to define custom styles. Create a type that conforms to the corresponding style protocol and implement its `makeBody(configuration:)` method. Then apply the new style using a style view modifier exactly like a built-in style.

## Topics

### Styling views with Liquid Glass

Applying Liquid Glass to custom views

Configure, combine, and morph views using Liquid Glass effects.

Landmarks: Building an app with Liquid Glass

Enhance your app experience with system-provided and custom Liquid Glass.

Applies the Liquid Glass effect to a view.

Beta

Returns a copy of the structure configured to be interactive.

`struct GlassEffectContainer`

A view that combines multiple Liquid Glass shapes into a single shape that can morph individual shapes into one another.

`struct GlassEffectTransition`

A structure that describes changes to apply when a glass effect is added or removed from the view hierarchy.

`struct GlassButtonStyle`

A button style that applies glass border artwork based on the button’s context.

### Styling buttons

`func buttonStyle(_:)`

Sets the style for buttons within this view to a button style with a custom appearance and standard interaction behavior.

`protocol ButtonStyle`

A type that applies standard interaction behavior and a custom appearance to all buttons within a view hierarchy.

`struct ButtonStyleConfiguration`

The properties of a button.

`protocol PrimitiveButtonStyle`

A type that applies custom interaction behavior and a custom appearance to all buttons within a view hierarchy.

`struct PrimitiveButtonStyleConfiguration`

Sets the style used for displaying the control (see `SignInWithAppleButton.Style`).

### Styling pickers

Sets the style for pickers within this view.

`protocol PickerStyle`

A type that specifies the appearance and interaction of all pickers within a view hierarchy.

Sets the style for date pickers within this view.

`protocol DatePickerStyle`

A type that specifies the appearance and interaction of all date pickers within a view hierarchy.

### Styling menus

Sets the style for menus within this view.

`protocol MenuStyle`

A type that applies standard interaction behavior and a custom appearance to all menus within a view hierarchy.

`struct MenuStyleConfiguration`

A configuration of a menu.

### Styling toggles

Sets the style for toggles in a view hierarchy.

`protocol ToggleStyle`

The appearance and behavior of a toggle.

`struct ToggleStyleConfiguration`

The properties of a toggle instance.

### Styling indicators

Sets the style for gauges within this view.

`protocol GaugeStyle`

Defines the implementation of all gauge instances within a view hierarchy.

`struct GaugeStyleConfiguration`

The properties of a gauge instance.

Sets the style for progress views in this view.

`protocol ProgressViewStyle`

A type that applies standard interaction behavior to all progress views within a view hierarchy.

`struct ProgressViewStyleConfiguration`

The properties of a progress view instance.

### Styling views that display text

Sets the style for labels within this view.

`protocol LabelStyle`

A type that applies a custom appearance to all labels within a view.

`struct LabelStyleConfiguration`

The properties of a label.

Sets the style for text fields within this view.

`protocol TextFieldStyle`

A specification for the appearance and interaction of a text field.

Sets the style for text editors within this view.

`protocol TextEditorStyle`

A specification for the appearance and interaction of a text editor.

`struct TextEditorStyleConfiguration`

The properties of a text editor.

### Styling collection views

Sets the style for lists within this view.

`protocol ListStyle`

A protocol that describes the behavior and appearance of a list.

Sets the style for tables within this view.

`protocol TableStyle`

A type that applies a custom appearance to all tables within a view.

`struct TableStyleConfiguration`

The properties of a table.

Sets the style for disclosure groups within this view.

`protocol DisclosureGroupStyle`

A type that specifies the appearance and interaction of disclosure groups within a view hierarchy.

### Styling navigation views

Sets the style for navigation split views within this view.

`protocol NavigationSplitViewStyle`

A type that specifies the appearance and interaction of navigation split views within a view hierarchy.

Sets the style for the tab view within the current environment.

`protocol TabViewStyle`

A specification for the appearance and interaction of a tab view.

### Styling groups

Sets the style for control groups within this view.

`protocol ControlGroupStyle`

Defines the implementation of all control groups within a view hierarchy.

`struct ControlGroupStyleConfiguration`

The properties of a control group.

Sets the style for forms in a view hierarchy.

`protocol FormStyle`

The appearance and behavior of a form.

`struct FormStyleConfiguration`

The properties of a form instance.

Sets the style for group boxes within this view.

`protocol GroupBoxStyle`

A type that specifies the appearance and interaction of all group boxes within a view hierarchy.

`struct GroupBoxStyleConfiguration`

The properties of a group box instance.

Sets the style for the index view within the current environment.

`protocol IndexViewStyle`

Defines the implementation of all `IndexView` instances within a view hierarchy.

Sets a style for labeled content.

`protocol LabeledContentStyle`

The appearance and behavior of a labeled content instance..

`struct LabeledContentStyleConfiguration`

The properties of a labeled content instance.

### Styling windows from a view inside the window

Sets the style for windows created by interacting with this view.

Sets the style for the toolbar in windows created by interacting with this view.

### Adding a glass background on views in visionOS

Fills the view’s background with an automatic glass background effect and container-relative rounded rectangle shape.

Fills the view’s background with an automatic glass background effect and a shape that you specify.

`enum GlassBackgroundDisplayMode`

The display mode of a glass background.

`protocol GlassBackgroundEffect`

A specification for the appearance of a glass background.

`struct AutomaticGlassBackgroundEffect`

The automatic glass background effect.

`struct GlassBackgroundEffectConfiguration`

A configuration used to build a custom effect.

`struct FeatheredGlassBackgroundEffect`

The feathered glass background effect.

`struct PlateGlassBackgroundEffect`

The plate glass background effect.

## See Also

### Views

Define the visual elements of your app using a hierarchy of views.

Adjust the characteristics of views in a hierarchy.

Create smooth visual updates in response to state changes.

Display formatted text and get text input from the user.

Add images and symbols to your app’s user interface.

Display values and get user selections.

Provide space-efficient, context-dependent access to commands and controls.

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

Enhance your views with graphical effects and customized drawings.

---

# https://developer.apple.com/documentation/swiftui/animations

Collection

- SwiftUI
- Animations

API Collection

# Animations

Create smooth visual updates in response to state changes.

## Overview

You tell SwiftUI how to draw your app’s user interface for different states, and then rely on SwiftUI to make interface updates when the state changes.

To avoid abrupt visual transitions when the state changes, add animation in one of the following ways:

- Animate all of the visual changes for a state change by changing the state inside a call to the `withAnimation(_:_:)` global function.

- Add animation to a particular view when a specific value changes by applying the `animation(_:value:)` view modifier to the view.

- Animate changes to a `Binding` by using the binding’s `animation(_:)` method.

SwiftUI animates the effects that many built-in view modifiers produce, like those that set a scale or opacity value. You can animate other values by making your custom views conform to the `Animatable` protocol, and telling SwiftUI about the value you want to animate.

When an animated state change results in adding or removing a view to or from the view hierarchy, you can tell SwiftUI how to transition the view into or out of place using built-in transitions that `AnyTransition` defines, like `slide` or `scale`. You can also create custom transitions.

For design guidance, see Motion in the Human Interface Guidelines.

## Topics

### Adding state-based animation to an action

Returns the result of recomputing the view’s body with the provided animation.

Returns the result of recomputing the view’s body with the provided animation, and runs the completion when all animations are complete.

`struct AnimationCompletionCriteria`

The criteria that determines when an animation is considered finished.

`struct Animation`

The way a view changes over time to create a smooth visual transition from one state to another.

### Adding state-based animation to a view

`func animation(_:)`

Applies the given animation to this view when this view changes.

Applies the given animation to this view when the specified value changes.

Applies the given animation to all animatable values within the `body` closure.

### Creating phase-based animation

Controlling the timing and movements of your animations

Build sophisticated animations that you control using phase and keyframe animators.

Animates effects that you apply to a view over a sequence of phases that change continuously.

Animates effects that you apply to a view over a sequence of phases that change based on a trigger.

`struct PhaseAnimator`

A container that animates its content by automatically cycling through a collection of phases that you provide, each defining a discrete step within an animation.

### Creating keyframe-based animation

Loops the given keyframes continuously, updating the view using the modifiers you apply in `body`.

Plays the given keyframes when the given trigger value changes, updating the view using the modifiers you apply in `body`.

`struct KeyframeAnimator`

A container that animates its content with keyframes.

`protocol Keyframes`

A type that defines changes to a value over time.

`struct KeyframeTimeline`

A description of how a value changes over time, modeled using keyframes.

`struct KeyframeTrack`

A sequence of keyframes animating a single property of a root type.

`struct KeyframeTrackContentBuilder`

The builder that creates keyframe track content from the keyframes that you define within a closure.

`struct KeyframesBuilder`

A builder that combines keyframe content values into a single value.

`protocol KeyframeTrackContent`

A group of keyframes that define an interpolation curve of an animatable value.

`struct CubicKeyframe`

A keyframe that uses a cubic curve to smoothly interpolate between values.

`struct LinearKeyframe`

A keyframe that uses simple linear interpolation.

`struct MoveKeyframe`

A keyframe that immediately moves to the given value without interpolating.

`struct SpringKeyframe`

A keyframe that uses a spring function to interpolate to the given value.

### Creating custom animations

`protocol CustomAnimation`

A type that defines how an animatable value changes over time.

`struct AnimationContext`

Contextual values that a custom animation can use to manage state and access a view’s environment.

`struct AnimationState`

A container that stores the state for a custom animation.

`protocol AnimationStateKey`

A key for accessing animation state values.

`struct UnitCurve`

A function defined by a two-dimensional curve that maps an input progress in the range \[0,1\] to an output progress that is also in the range \[0,1\]. By changing the shape of the curve, the effective speed of an animation or other interpolation can be changed.

`struct Spring`

A representation of a spring’s motion.

### Making data animatable

`protocol Animatable`

A type that describes how to animate a property of a view.

`struct AnimatableValues` Beta

`struct AnimatablePair`

A pair of animatable values, which is itself animatable.

`protocol VectorArithmetic`

A type that can serve as the animatable data of an animatable type.

`struct EmptyAnimatableData`

An empty type for animatable data.

### Updating a view on a schedule

Updating watchOS apps with timelines

Seamlessly schedule updates to your user interface, even while it’s inactive.

`struct TimelineView`

A view that updates according to a schedule that you provide.

`protocol TimelineSchedule`

A type that provides a sequence of dates for use as a schedule.

`typealias TimelineViewDefaultContext`

Information passed to a timeline view’s content callback.

### Synchronizing geometries

Defines a group of views with synchronized geometry using an identifier and namespace that you provide.

`struct MatchedGeometryProperties`

A set of view properties that may be synchronized between views using the `View.matchedGeometryEffect()` function.

`protocol GeometryEffect`

An effect that changes the visual appearance of a view, largely without changing its ancestors or descendants.

`struct Namespace`

A dynamic property type that allows access to a namespace defined by the persistent identity of the object containing the property (e.g. a view).

Isolates the geometry (e.g. position and size) of the view from its parent view.

### Defining transitions

`func transition(_:)`

Associates a transition with the view.

`protocol Transition`

A description of view changes to apply when a view is added to and removed from the view hierarchy.

`struct TransitionProperties`

The properties a `Transition` can have.

`enum TransitionPhase`

An indication of which the current stage of a transition.

`struct AsymmetricTransition`

A composite `Transition` that uses a different transition for insertion versus removal.

`struct AnyTransition`

A type-erased transition.

Modifies the view to use a given transition as its method of animating changes to the contents of its views.

`var contentTransition: ContentTransition`

The current method of animating the contents of views.

`var contentTransitionAddsDrawingGroup: Bool`

A Boolean value that controls whether views that render content transitions use GPU-accelerated rendering.

`struct ContentTransition`

A kind of transition that applies to the content within a single view, rather than to the insertion or removal of a view.

`struct PlaceholderContentView`

A placeholder used to construct an inline modifier, transition, or other helper type.

Sets the navigation transition style for this view.

`protocol NavigationTransition`

A type that defines the transition to use when navigating to a view.

Identifies this view as the source of a navigation transition, such as a zoom transition.

`protocol MatchedTransitionSourceConfiguration`

A configuration that defines the appearance of a matched transition source.

`struct EmptyMatchedTransitionSourceConfiguration`

An unstyled matched transition source configuration.

### Moving an animation to another view

Executes a closure with the specified transaction and returns the result.

Executes a closure with the specified transaction key path and value and returns the result.

Applies the given transaction mutation function to all animations used within the view.

Applies the given transaction mutation function to all animations used within the `body` closure.

`struct Transaction`

The context of the current state-processing update.

`macro Entry()`

Creates an environment values, transaction, container values, or focused values entry.

`protocol TransactionKey`

A key for accessing values in a transaction.

### Deprecated types

`protocol AnimatableModifier`

A modifier that can create another modifier with animation.

Deprecated

## See Also

### Views

Define the visual elements of your app using a hierarchy of views.

Adjust the characteristics of views in a hierarchy.

Apply built-in and custom appearances and behaviors to different types of views.

Display formatted text and get text input from the user.

Add images and symbols to your app’s user interface.

Display values and get user selections.

Provide space-efficient, context-dependent access to commands and controls.

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

Enhance your views with graphical effects and customized drawings.

---

# https://developer.apple.com/documentation/swiftui/text-input-and-output

Collection

- SwiftUI
- Text input and output

API Collection

# Text input and output

Display formatted text and get text input from the user.

## Overview

To display read-only text, or read-only text paired with an image, use the built-in `Text` or `Label` views, respectively. When you need to collect text input from the user, use an appropriate text input view, like `TextField` or `TextEditor`.

You add view modifiers to control the text’s font, selectability, alignment, layout direction, and so on. These modifiers also affect other views that display text, like the labels on controls, even if you don’t define an explicit `Text` view.

For design guidance, see Typography in the Human Interface Guidelines.

## Topics

### Displaying text

`struct Text`

A view that displays one or more lines of read-only text.

`struct Label`

A standard label for user interface items, consisting of an icon with a title.

Sets the style for labels within this view.

### Getting text input

Building rich SwiftUI text experiences

Build an editor for formatted text using SwiftUI text editor views and attributed strings.

`struct TextField`

A control that displays an editable text interface.

Sets the style for text fields within this view.

`struct SecureField`

A control into which people securely enter private text.

`struct TextEditor`

A view that can display and edit long-form text.

### Selecting text

Controls whether people can select text within this view.

`protocol TextSelectability`

A type that describes the ability to select text.

`struct TextSelection`

Represents a selection of text.

Sets the direction of a selection or cursor relative to a text character.

`var textSelectionAffinity: TextSelectionAffinity`

A representation of the direction or association of a selection or cursor relative to a text character. This concept becomes much more prominent when dealing with bidirectional text (text that contains both LTR and RTL scripts, like English and Arabic combined).

`enum TextSelectionAffinity`

`struct AttributedTextSelection`

Represents a selection of attributed text.

Beta

### Setting a font

Applying custom fonts to text

Add and use a font in your app that scales with Dynamic Type.

Sets the default font for text in this view.

Sets the font design of the text in this view.

Sets the font weight of the text in this view.

Sets the font width of the text in this view.

`var font: Font?`

The default font of this environment.

`struct Font`

An environment-dependent font.

### Adjusting text size

Applies a text scale to text in the view.

`func dynamicTypeSize(_:)`

Sets the Dynamic Type size within the view to the given value.

`var dynamicTypeSize: DynamicTypeSize`

The current Dynamic Type size.

`enum DynamicTypeSize`

A Dynamic Type size, which specifies how large scalable content should be.

`struct ScaledMetric`

A dynamic property that scales a numeric value.

`protocol TextVariantPreference`

A protocol for controlling the size variant of text views.

`struct FixedTextVariant`

The default text variant preference that chooses the largest available variant.

`struct SizeDependentTextVariant`

The size dependent variant preference allows the text to take the available space into account when choosing the variant to display.

### Controlling text style

Applies a bold font weight to the text in this view.

Applies italics to the text in this view.

Applies an underline to the text in this view.

Applies a strikethrough to the text in this view.

Sets a transform for the case of the text contained in this view when displayed.

`var textCase: Text.Case?`

A stylistic override to transform the case of `Text` when displayed, using the environment’s locale.

Modifies the fonts of all child views to use the fixed-width variant of the current font, if possible.

Modifies the fonts of all child views to use fixed-width digits, if possible, while leaving other characters proportionally spaced.

`protocol AttributedTextFormattingDefinition`

A protocol for defining how text can be styled in a certain context, e.g. a `TextEditor`.

`protocol AttributedTextValueConstraint`

A protocol for defining a constraint on the value of a certain attribute.

`enum AttributedTextFormatting`

A namespace for types related to attributed text formatting definitions.

### Managing text layout

Sets the truncation mode for lines of text that are too long to fit in the available space.

`var truncationMode: Text.TruncationMode`

A value that indicates how the layout truncates the last line of text to fit into the available space.

Sets whether text in this view can compress the space between characters when necessary to fit text in a line.

`var allowsTightening: Bool`

A Boolean value that indicates whether inter-character spacing should tighten to fit the text into the available space.

Sets the minimum amount that text in this view scales down to fit in the available space.

`var minimumScaleFactor: CGFloat`

The minimum permissible proportion to shrink the font size to fit the text into the available space.

Sets the vertical offset for the text relative to its baseline in this view.

Sets the spacing, or kerning, between characters for the text in this view.

Sets the tracking for the text in this view.

Sets whether this view mirrors its contents horizontally when the layout direction is right-to-left.

`enum TextAlignment`

An alignment position for text along the horizontal axis.

### Rendering text

Creating visual effects with SwiftUI

Add scroll effects, rich color treatments, custom transitions, and advanced effects using shaders and a text renderer.

`protocol TextAttribute`

A value that you can attach to text views and that text renderers can query.

Returns a new view such that any text views within it will use `renderer` to draw themselves.

`protocol TextRenderer`

A value that can replace the default text view rendering behavior.

`struct TextProxy`

A proxy for a text view that custom text renderers use.

### Limiting line count for multiline text

`func lineLimit(_:)`

Sets to a closed range the number of lines that text can occupy in this view.

Sets a limit for the number of lines text can occupy in this view.

`var lineLimit: Int?`

The maximum number of lines that text can occupy in a view.

### Formatting multiline text

Sets the amount of space between lines of text in this view.

`var lineSpacing: CGFloat`

The distance in points between the bottom of one line fragment and the top of the next.

Sets the alignment of a text view that contains multiple lines of text.

`var multilineTextAlignment: TextAlignment`

An environment value that indicates how a text view aligns its lines when the content wraps or contains newlines.

### Formatting date and time

`enum SystemFormatStyle`

A namespace for format styles that implement designs used across Apple’s platformes.

`struct TimeDataSource`

A source of time related data.

### Managing text entry

Sets whether to disable autocorrection for this view.

`var autocorrectionDisabled: Bool`

A Boolean value that determines whether the view hierarchy has auto-correction enabled.

Sets the keyboard type for this view.

Configures the behavior in which scrollable content interacts with the software keyboard.

`func textContentType(_:)`

Sets the text content type for this view, which the system uses to offer suggestions while the user enters text on macOS.

Sets how often the shift key in the keyboard is automatically enabled.

`struct TextInputAutocapitalization`

The kind of autocapitalization behavior applied during text input.

Associates a fully formed string with the value of this view when used as a text input suggestion

Configures the text input suggestions for this view.

Sets the text content type for this view, which the system uses to offer suggestions while the user enters text on a watchOS device.

Sets the text content type for this view, which the system uses to offer suggestions while the user enters text on an iOS or tvOS device.

`struct TextInputFormattingControlPlacement`

A structure defining the system text formatting controls available on each platform.

### Dictating text

Configures the dictation behavior for any search fields configured by the searchable modifier.

`struct TextInputDictationActivation`

`struct TextInputDictationBehavior`

### Configuring the Writing Tools behavior

Specifies the Writing Tools behavior for text and text input in the environment.

`struct WritingToolsBehavior`

The Writing Tools editing experience for text and text input.

### Specifying text equivalents

`func typeSelectEquivalent(_:)`

Sets an explicit type select equivalent text in a collection, such as a list or table.

### Localizing text

Preparing views for localization

Specify hints and add strings to localize your SwiftUI views.

`struct LocalizedStringKey`

The key used to look up an entry in a strings file or strings dictionary file.

`var locale: Locale`

The current locale that views should use.

`func typesettingLanguage(_:isEnabled:)`

Specifies the language for typesetting.

`struct TypesettingLanguage`

Defines how typesetting language is determined for text.

### Deprecated types

`enum ContentSizeCategory`

The sizes that you can specify for content.

Deprecated

## See Also

### Views

Define the visual elements of your app using a hierarchy of views.

Adjust the characteristics of views in a hierarchy.

Apply built-in and custom appearances and behaviors to different types of views.

Create smooth visual updates in response to state changes.

Add images and symbols to your app’s user interface.

Display values and get user selections.

Provide space-efficient, context-dependent access to commands and controls.

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

Enhance your views with graphical effects and customized drawings.

---

# https://developer.apple.com/documentation/swiftui/images

Collection

- SwiftUI
- Images

API Collection

# Images

Add images and symbols to your app’s user interface.

## Overview

Display images, including SF Symbols, images that you store in an asset catalog, and images that you store on disk, using an `Image` view.

For images that take time to retrieve — for example, when you load an image from a network endpoint — load the image asynchronously using `AsyncImage`. You can instruct that view to display a placeholder during the load operation.

For design guidance, see Images in the Human Interface Guidelines.

## Topics

### Creating an image

`struct Image`

A view that displays an image.

### Configuring an image

Fitting images into available space

Adjust the size and shape of images in your app’s user interface by applying view modifiers.

Scales images within the view according to one of the relative sizes available including small, medium, and large images sizes.

`var imageScale: Image.Scale`

The image scale for this environment.

`enum Scale`

A scale to apply to vector images relative to text.

`enum Orientation`

The orientation of an image.

`enum ResizingMode`

The modes that SwiftUI uses to resize an image to fit within its containing view.

### Loading images asynchronously

`struct AsyncImage`

A view that asynchronously loads and displays an image.

`enum AsyncImagePhase`

The current phase of the asynchronous image loading operation.

### Setting a symbol variant

Makes symbols within the view show a particular variant.

`var symbolVariants: SymbolVariants`

The symbol variant to use in this environment.

`struct SymbolVariants`

A variant of a symbol.

### Managing symbol effects

Returns a new view with a symbol effect added to it.

Returns a new view with its inherited symbol image effects either removed or left unchanged.

`struct SymbolEffectTransition`

Creates a transition that applies the Appear, Disappear, DrawOn or DrawOff symbol animation to symbol images within the inserted or removed view hierarchy.

### Setting symbol rendering modes

Sets the rendering mode for symbol images within this view.

`var symbolRenderingMode: SymbolRenderingMode?`

The current symbol rendering mode, or `nil` denoting that the mode is picked automatically using the current image and foreground style as parameters.

`struct SymbolRenderingMode`

A symbol rendering mode.

`struct SymbolColorRenderingMode`

A method of filling a layer in a symbol image.

Beta

`struct SymbolVariableValueMode`

A method of rendering the variable value of a symbol image.

### Rendering images from views

`class ImageRenderer`

An object that creates images from SwiftUI views.

## See Also

### Views

Define the visual elements of your app using a hierarchy of views.

Adjust the characteristics of views in a hierarchy.

Apply built-in and custom appearances and behaviors to different types of views.

Create smooth visual updates in response to state changes.

Display formatted text and get text input from the user.

Display values and get user selections.

Provide space-efficient, context-dependent access to commands and controls.

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

Enhance your views with graphical effects and customized drawings.

---

# https://developer.apple.com/documentation/swiftui/controls-and-indicators

Collection

- SwiftUI
- Controls and indicators

API Collection

# Controls and indicators

Display values and get user selections.

## Overview

SwiftUI provides controls that enable user interaction specific to each platform and context. For example, people can initiate events with buttons and links, or choose among a set of discrete values with different kinds of pickers. You can also display information to the user with indicators like progress views and gauges.

Use these built-in controls and indicators when composing custom views, and style them to match the needs of your app’s user interface. For design guidance, see Menus and actions, Selection and input, and Status in the Human Interface Guidelines.

## Topics

### Creating buttons

`struct Button`

A control that initiates an action.

`func buttonStyle(_:)`

Sets the style for buttons within this view to a button style with a custom appearance and standard interaction behavior.

Sets the border shape for buttons in this view.

Sets whether buttons in this view should repeatedly trigger their actions on prolonged interactions.

`var buttonRepeatBehavior: ButtonRepeatBehavior`

Whether buttons with this associated environment should repeatedly trigger their actions on prolonged interactions.

`struct ButtonBorderShape`

A shape used to draw a button’s border.

`struct ButtonRole`

A value that describes the purpose of a button.

`struct ButtonRepeatBehavior`

The options for controlling the repeatability of button actions.

`struct ButtonSizing` Beta

### Creating special-purpose buttons

`struct EditButton`

A button that toggles the edit mode environment value.

`struct PasteButton`

A system button that reads items from the pasteboard and delivers it to a closure.

`struct RenameButton`

A button that triggers a standard rename action.

### Linking to other content

`struct Link`

A control for navigating to a URL.

`struct ShareLink`

A view that controls a sharing presentation.

`struct SharePreview`

A representation of a type to display in a share preview.

`struct TextFieldLink`

A control that requests text input from the user when pressed.

`struct HelpLink`

A button with a standard appearance that opens app-specific help documentation.

### Getting numeric inputs

`struct Slider`

A control for selecting a value from a bounded linear range of values.

`struct Stepper`

A control that performs increment and decrement actions.

`struct Toggle`

A control that toggles between on and off states.

Sets the style for toggles in a view hierarchy.

### Choosing from a set of options

`struct Picker`

A control for selecting from a set of mutually exclusive values.

Sets the style for pickers within this view.

Sets the style for radio group style pickers within this view to be horizontally positioned with the radio buttons inside the layout.

Sets the default wheel-style picker item height.

`var defaultWheelPickerItemHeight: CGFloat`

The default height of an item in a wheel-style picker, such as a date picker.

Specifies the selection effect to apply to a palette item.

`struct PaletteSelectionEffect`

The selection effect to apply to a palette item.

### Choosing dates

`struct DatePicker`

A control for selecting an absolute date.

Sets the style for date pickers within this view.

`struct MultiDatePicker`

A control for picking multiple dates.

`var calendar: Calendar`

The current calendar that views should use when handling dates.

`var timeZone: TimeZone`

The current time zone that views should use when handling dates.

### Choosing a color

`struct ColorPicker`

A control used to select a color from the system color picker UI.

### Indicating a value

`struct Gauge`

A view that shows a value within a range.

Sets the style for gauges within this view.

`struct ProgressView`

A view that shows the progress toward completion of a task.

Sets the style for progress views in this view.

`struct DefaultDateProgressLabel`

The default type of the current value label when used by a date-relative progress view.

`struct DefaultButtonLabel`

The default label to use for a button.

Beta

### Indicating missing content

`struct ContentUnavailableView`

An interface, consisting of a label and additional content, that you display when the content of your app is unavailable to users.

### Providing haptic feedback

Plays the specified `feedback` when the provided `trigger` value changes.

`func sensoryFeedback(trigger:_:)`

Plays feedback when returned from the `feedback` closure after the provided `trigger` value changes.

Plays the specified `feedback` when the provided `trigger` value changes and the `condition` closure returns `true`.

`struct SensoryFeedback`

Represents a type of haptic and/or audio feedback that can be played.

### Sizing controls

`func controlSize(_:)`

Sets the size for controls within this view.

`enum ControlSize`

The size classes, like regular or small, that you can apply to controls within a view.

## See Also

### Views

Define the visual elements of your app using a hierarchy of views.

Adjust the characteristics of views in a hierarchy.

Apply built-in and custom appearances and behaviors to different types of views.

Create smooth visual updates in response to state changes.

Display formatted text and get text input from the user.

Add images and symbols to your app’s user interface.

Provide space-efficient, context-dependent access to commands and controls.

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

Enhance your views with graphical effects and customized drawings.

---

# https://developer.apple.com/documentation/swiftui/menus-and-commands

Collection

- SwiftUI
- Menus and commands

API Collection

# Menus and commands

Provide space-efficient, context-dependent access to commands and controls.

## Overview

Use a menu to provide people with easy access to common commands. You can add items to a macOS or iPadOS app’s menu bar using the `commands(content:)` scene modifier, or create context menus that people reveal near their current task using the `contextMenu(menuItems:)` view modifier.

Create submenus by nesting `Menu` instances inside others. Use a `Divider` view to create a separator between menu elements.

For design guidance, see Menus in the Human Interface Guidelines.

## Topics

### Building a menu bar

Building and customizing the menu bar with SwiftUI

Provide a seamless, cross-platform user experience by building a native menu bar for iPadOS and macOS.

### Creating a menu

Populating SwiftUI menus with adaptive controls

Improve your app by populating menus with controls and organizing your content intuitively.

`struct Menu`

A control for presenting a menu of actions.

Sets the style for menus within this view.

### Creating context menus

Adds a context menu to a view.

Adds a context menu with a custom preview to a view.

Adds an item-based context menu to a view.

### Defining commands

Adds commands to the scene.

Removes all commands defined by the modified scene.

Replaces all commands defined by the modified scene with the commands from the builder.

`protocol Commands`

Conforming types represent a group of related commands that can be exposed to the user via the main menu on macOS and key commands on iOS.

`struct CommandMenu`

Command menus are stand-alone, top-level containers for controls that perform related, app-specific commands.

`struct CommandGroup`

Groups of controls that you can add to existing command menus.

`struct CommandsBuilder`

Constructs command sets from multi-expression closures. Like `ViewBuilder`, it supports up to ten expressions in the closure body.

`struct CommandGroupPlacement`

The standard locations that you can place new command groups relative to.

### Getting built-in command groups

`struct SidebarCommands`

A built-in set of commands for manipulating window sidebars.

`struct TextEditingCommands`

A built-in group of commands for searching, editing, and transforming selections of text.

`struct TextFormattingCommands`

A built-in set of commands for transforming the styles applied to selections of text.

`struct ToolbarCommands`

A built-in set of commands for manipulating window toolbars.

`struct ImportFromDevicesCommands`

A built-in set of commands that enables importing content from nearby devices.

`struct InspectorCommands`

A built-in set of commands for manipulating inspectors.

`struct EmptyCommands`

An empty group of commands.

### Showing a menu indicator

Sets the menu indicator visibility for controls within this view.

`var menuIndicatorVisibility: Visibility`

The menu indicator visibility to apply to controls within a view.

### Configuring menu dismissal

Tells a menu whether to dismiss after performing an action.

`struct MenuActionDismissBehavior`

The set of menu dismissal behavior options.

### Setting a preferred order

Sets the preferred order of items for menus presented from this view.

`var menuOrder: MenuOrder`

The preferred order of items for menus presented from this view.

`struct MenuOrder`

The order in which a menu presents its content.

### Deprecated types

`struct MenuButton`

A button that displays a menu containing a list of choices when pressed.

Deprecated

`typealias PullDownButton` Deprecated

`struct ContextMenu`

A container for views that you present as menu items in a context menu.

## See Also

### Views

Define the visual elements of your app using a hierarchy of views.

Adjust the characteristics of views in a hierarchy.

Apply built-in and custom appearances and behaviors to different types of views.

Create smooth visual updates in response to state changes.

Display formatted text and get text input from the user.

Add images and symbols to your app’s user interface.

Display values and get user selections.

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

Enhance your views with graphical effects and customized drawings.

---

# https://developer.apple.com/documentation/swiftui/shapes

Collection

- SwiftUI
- Shapes

API Collection

# Shapes

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

## Overview

Draw shapes like circles and rectangles, as well as custom paths that define shapes of your own design. Apply styles that include environment-aware colors, rich gradients, and material effects to the foreground, background, and outline of your shapes.

If you need the efficiency or flexibility of immediate mode drawing — for example, to create particle effects — use a `Canvas` view instead.

## Topics

### Creating rectangular shapes

`struct Rectangle`

A rectangular shape aligned inside the frame of the view containing it.

`struct RoundedRectangle`

A rectangular shape with rounded corners, aligned inside the frame of the view containing it.

`enum RoundedCornerStyle`

Defines the shape of a rounded rectangle’s corners.

`struct UnevenRoundedRectangle`

A rectangular shape with rounded corners with different values, aligned inside the frame of the view containing it.

`struct RectangleCornerRadii`

Describes the corner radius values of a rounded rectangle with uneven corners.

### Creating circular shapes

`struct Circle`

A circle centered on the frame of the view containing it.

`struct Ellipse`

An ellipse aligned inside the frame of the view containing it.

`struct Capsule`

A capsule shape aligned inside the frame of the view containing it.

### Drawing custom shapes

`struct Path`

The outline of a 2D shape.

### Defining shape behavior

`protocol ShapeView`

A view that provides a shape that you can use for drawing operations.

`protocol Shape`

A 2D shape that you can use when drawing a view.

`struct AnyShape`

A type-erased shape value.

`enum ShapeRole`

Ways of styling a shape.

`struct StrokeStyle`

The characteristics of a stroke that traces a path.

`struct StrokeShapeView`

A shape provider that strokes its shape.

`struct StrokeBorderShapeView`

A shape provider that strokes the border of its shape.

`struct FillStyle`

A style for rasterizing vector shapes.

`struct FillShapeView`

A shape provider that fills its shape.

### Transforming a shape

`struct ScaledShape`

A shape with a scale transform applied to it.

`struct RotatedShape`

A shape with a rotation transform applied to it.

`struct OffsetShape`

A shape with a translation offset transform applied to it.

`struct TransformedShape`

A shape with an affine transform applied to it.

### Setting a container shape

Sets the container shape to use for any container relative shape within this view.

`protocol InsettableShape`

A shape type that is able to inset itself to produce another shape.

`struct ContainerRelativeShape`

A shape that is replaced by an inset version of the current container shape. If no container shape was defined, is replaced by a rectangle.

## See Also

### Views

Define the visual elements of your app using a hierarchy of views.

Adjust the characteristics of views in a hierarchy.

Apply built-in and custom appearances and behaviors to different types of views.

Create smooth visual updates in response to state changes.

Display formatted text and get text input from the user.

Add images and symbols to your app’s user interface.

Display values and get user selections.

Provide space-efficient, context-dependent access to commands and controls.

Enhance your views with graphical effects and customized drawings.

---

# https://developer.apple.com/documentation/swiftui/drawing-and-graphics

Collection

- SwiftUI
- Drawing and graphics

API Collection

# Drawing and graphics

Enhance your views with graphical effects and customized drawings.

## Overview

You create rich, dynamic user interfaces with the built-in views and Shapes that SwiftUI provides. To enhance any view, you can apply many of the graphical effects typically associated with a graphics context, like setting colors, adding masks, and creating composites.

When you need the flexibility of immediate mode drawing in a graphics context, use a `Canvas` view. This can be particularly helpful when you want to draw an extremely large number of dynamic shapes — for example, to create particle effects.

For design guidance, see Materials and Color in the Human Interface Guidelines.

## Topics

### Immediate mode drawing

Add Rich Graphics to Your SwiftUI App

Make your apps stand out by adding background materials, vibrancy, custom graphics, and animations.

`struct Canvas`

A view type that supports immediate mode drawing.

`struct GraphicsContext`

An immediate mode drawing destination, and its current state.

### Setting a color

`func tint(_:)`

Sets the tint color within this view.

`struct Color`

A representation of a color that adapts to a given context.

### Styling content

Adds a border to this view with the specified style and width.

Sets a view’s foreground elements to use a given style.

Sets the primary and secondary levels of the foreground style in the child view.

Sets the primary, secondary, and tertiary levels of the foreground style.

Sets the specified style to render backgrounds within the view.

`var backgroundStyle: AnyShapeStyle?`

An optional style that overrides the default system background style when set.

`protocol ShapeStyle`

A color or pattern to use when rendering a shape.

`struct AnyShapeStyle`

A type-erased ShapeStyle value.

`struct Gradient`

A color gradient represented as an array of color stops, each having a parametric location value.

`struct MeshGradient`

A two-dimensional gradient defined by a 2D grid of positioned colors.

`struct AnyGradient`

A color gradient.

`struct ShadowStyle`

A style to use when rendering shadows.

`struct Glass`

A structure that defines the configuration of the Liquid Glass material.

Beta

### Transforming colors

Brightens this view by the specified amount.

Sets the contrast and separation between similar colors in this view.

Inverts the colors in this view.

Adds a color multiplication effect to this view.

Adjusts the color saturation of this view.

Adds a grayscale effect to this view.

Applies a hue rotation effect to this view.

Adds a luminance to alpha effect to this view.

Sets an explicit active appearance for materials in this view.

`var materialActiveAppearance: MaterialActiveAppearance`

The behavior materials should use for their active state, defaulting to `automatic`.

`struct MaterialActiveAppearance`

The behavior for how materials appear active and inactive.

### Scaling, rotating, or transforming a view

Scales this view to fill its parent.

Scales this view to fit its parent.

`func scaleEffect(_:anchor:)`

Scales this view’s rendered output by the given amount in both the horizontal and vertical directions, relative to an anchor point.

Scales this view’s rendered output by the given horizontal and vertical amounts, relative to an anchor point.

Scales this view by the specified horizontal, vertical, and depth factors, relative to an anchor point.

`func aspectRatio(_:contentMode:)`

Constrains this view’s dimensions to the specified aspect ratio.

Rotates a view’s rendered output in two dimensions around the specified point.

Renders a view’s content as if it’s rotated in three dimensions around the specified axis.

Rotates the view’s content by the specified 3D rotation value.

`func rotation3DEffect(_:axis:anchor:)`

Rotates the view’s content by an angle about an axis that you specify as a tuple of elements.

Applies an affine transformation to this view’s rendered output.

Applies a 3D transformation to this view’s rendered output.

Applies a projection transformation to this view’s rendered output.

`struct ProjectionTransform`

`enum ContentMode`

Constants that define how a view’s content fills the available space.

### Masking and clipping

Masks this view using the alpha channel of the given view.

Clips this view to its bounding rectangular frame.

Sets a clipping shape for this view.

### Applying blur and shadows

Applies a Gaussian blur to this view.

Adds a shadow to this view.

`struct ColorMatrix`

A matrix to use in an RGBA color transformation.

### Applying effects based on geometry

Applies effects to this view, while providing access to layout information through a geometry proxy.

Applies effects to this view, while providing access to layout information through a 3D geometry proxy.

`protocol VisualEffect`

Visual Effects change the visual appearance of a view without changing its ancestors or descendents.

`struct EmptyVisualEffect`

The base visual effect that you apply additional effect to.

### Compositing views

Sets the blend mode for compositing this view with overlapping views.

Wraps this view in a compositing group.

Composites this view’s contents into an offscreen image before final display.

`enum BlendMode`

Modes for compositing a view with overlapping content.

`enum ColorRenderingMode`

The set of possible working color spaces for color-compositing operations.

`protocol CompositorContent` Beta

`struct CompositorContentBuilder`

A result builder for composing a collection of `CompositorContent` elements.

### Measuring a view

`struct GeometryReader`

A container view that defines its content as a function of its own size and coordinate space.

`struct GeometryReader3D`

`struct GeometryProxy`

A proxy for access to the size and coordinate space (for anchor resolution) of the container view.

`struct GeometryProxy3D`

A proxy for access to the size and coordinate space of the container view.

Assigns a name to the view’s coordinate space, so other code can operate on dimensions like points and sizes relative to the named space.

`enum CoordinateSpace`

A resolved coordinate space created by the coordinate space protocol.

`protocol CoordinateSpaceProtocol`

A frame of reference within the layout system.

`struct PhysicalMetric`

Provides access to a value in points that corresponds to the specified physical measurement.

`struct PhysicalMetricsConverter`

A physical metrics converter provides conversion between point values and their extent in 3D space, in the form of physical length measurements.

### Responding to a geometry change

`func onGeometryChange(for:of:action:)`

Adds an action to be performed when a value, created from a geometry proxy, changes.

### Accessing Metal shaders

Returns a new view that applies `shader` to `self` as a filter effect on the color of each pixel.

Returns a new view that applies `shader` to `self` as a geometric distortion effect on the location of each pixel.

Returns a new view that applies `shader` to `self` as a filter on the raster layer created from `self`.

`struct Shader`

A reference to a function in a Metal shader library, along with its bound uniform argument values.

`struct ShaderFunction`

A reference to a function in a Metal shader library.

`struct ShaderLibrary`

A Metal shader library.

### Accessing geometric constructs

`enum Axis`

The horizontal or vertical dimension in a 2D coordinate system.

`struct Angle`

A geometric angle whose value you access in either radians or degrees.

`struct UnitPoint`

A normalized 2D point in a view’s coordinate space.

`struct UnitPoint3D`

A normalized 3D point in a view’s coordinate space.

`struct Anchor`

An opaque value derived from an anchor source and a particular view.

`protocol DepthAlignmentID`

`struct Alignment3D`

An alignment in all three axes.

`struct GeometryProxyCoordinateSpace3D`

A representation of a `GeometryProxy3D` which can be used for `CoordinateSpace3D` based conversions.

## See Also

### Views

Define the visual elements of your app using a hierarchy of views.

Adjust the characteristics of views in a hierarchy.

Apply built-in and custom appearances and behaviors to different types of views.

Create smooth visual updates in response to state changes.

Display formatted text and get text input from the user.

Add images and symbols to your app’s user interface.

Display values and get user selections.

Provide space-efficient, context-dependent access to commands and controls.

Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

---

# https://developer.apple.com/documentation/swiftui/layout-fundamentals

Collection

- SwiftUI
- Layout fundamentals

API Collection

# Layout fundamentals

Arrange views inside built-in layout containers like stacks and grids.

## Overview

Use layout containers to arrange the elements of your user interface. Stacks and grids update and adjust the positions of the subviews they contain in response to changes in content or interface dimensions. You can nest layout containers inside other layout containers to any depth to achieve complex layout effects.

To finetune the position, alignment, and other elements of a layout that you build with layout container views, see Layout adjustments. To define custom layout containers, see Custom layout. For design guidance, see Layout in the Human Interface Guidelines.

## Topics

### Choosing a layout

Picking container views for your content

Build flexible user interfaces by using stacks, grids, lists, and forms.

### Statically arranging views in one dimension

Building layouts with stack views

Compose complex layouts from primitive container views.

`struct HStack`

A view that arranges its subviews in a horizontal line.

`struct VStack`

A view that arranges its subviews in a vertical line.

### Dynamically arranging views in one dimension

Grouping data with lazy stack views

Split content into logical sections inside lazy stack views.

Creating performant scrollable stacks

Display large numbers of repeated views efficiently with scroll views, stack views, and lazy stacks.

`struct LazyHStack`

A view that arranges its children in a line that grows horizontally, creating items only as needed.

`struct LazyVStack`

A view that arranges its children in a line that grows vertically, creating items only as needed.

`struct PinnedScrollableViews`

A set of view types that may be pinned to the bounds of a scroll view.

### Statically arranging views in two dimensions

`struct Grid`

A container view that arranges other views in a two dimensional layout.

`struct GridRow`

A horizontal row in a two dimensional grid container.

Tells a view that acts as a cell in a grid to span the specified number of columns.

Specifies a custom alignment anchor for a view that acts as a grid cell.

Asks grid layouts not to offer the view extra size in the specified axes.

Overrides the default horizontal alignment of the grid column that the view appears in.

### Dynamically arranging views in two dimensions

`struct LazyHGrid`

A container view that arranges its child views in a grid that grows horizontally, creating items only as needed.

`struct LazyVGrid`

A container view that arranges its child views in a grid that grows vertically, creating items only as needed.

`struct GridItem`

A description of a row or a column in a lazy grid.

### Layering views

Adding a background to your view

Compose a background behind your view and extend it beyond the safe area insets.

`struct ZStack`

A view that overlays its subviews, aligning them in both axes.

Controls the display order of overlapping views.

Layers the views that you specify behind this view.

Sets the view’s background to a style.

Sets the view’s background to the default background style.

`func background(_:in:fillStyle:)`

Sets the view’s background to an insettable shape filled with a style.

`func background(in:fillStyle:)`

Sets the view’s background to an insettable shape filled with the default background style.

Layers the views that you specify in front of this view.

Layers the specified style in front of this view.

Layers a shape that you specify in front of this view.

`var backgroundMaterial: Material?`

The material underneath the current view.

Sets the container background of the enclosing container using a view.

`struct ContainerBackgroundPlacement`

The placement of a container background.

### Automatically choosing the layout that fits

`struct ViewThatFits`

A view that adapts to the available space by providing the first child view that fits.

### Separators

`struct Spacer`

A flexible space that expands along the major axis of its containing stack layout, or on both axes if not contained in a stack.

`struct Divider`

A visual element that can be used to separate other content.

## See Also

### View layout

Make fine adjustments to alignment, spacing, padding, and other layout parameters.

Place views in custom arrangements and create animated transitions between layout types.

Display a structured, scrollable column of information.

Display selectable, sortable data arranged in rows and columns.

Present views in different kinds of purpose-driven containers, like forms or control groups.

Enable people to scroll to content that doesn’t fit in the current display.

---

# https://developer.apple.com/documentation/swiftui/layout-adjustments

Collection

- SwiftUI
- Layout adjustments

API Collection

# Layout adjustments

Make fine adjustments to alignment, spacing, padding, and other layout parameters.

## Overview

Layout containers like stacks and grids provide a great starting point for arranging views in your app’s user interface. When you need to make fine adjustments, use layout view modifiers. You can adjust or constrain the size, position, and alignment of a view. You can also add padding around a view, and indicate how the view interacts with system-defined safe areas.

To get started with a basic layout, see Layout fundamentals. For design guidance, see Layout in the Human Interface Guidelines.

## Topics

### Finetuning a layout

Laying out a simple view

Create a view layout by adjusting the size of views.

Inspecting view layout

Determine the position and extent of a view using Xcode previews or by adding temporary borders.

### Adding padding around a view

`func padding(_:)`

Adds a different padding amount to each edge of this view.

Adds an equal padding amount to specific edges of this view.

`func padding3D(_:)`

Pads this view using the edge insets you specify.

Adds padding to the specified edges of this view using an amount that’s appropriate for the current scene.

Adds a specified kind of padding to the specified edges of this view using an amount that’s appropriate for the current scene.

`struct ScenePadding`

The padding used to space a view from its containing scene.

### Influencing a view’s size

Positions this view within an invisible frame with the specified size.

Positions this view within an invisible frame with the specified depth.

Positions this view within an invisible frame having the specified size constraints.

Positions this view within an invisible frame having the specified depth constraints.

Positions this view within an invisible frame with a size relative to the nearest container.

Fixes this view at its ideal size.

Fixes this view at its ideal size in the specified dimensions.

Sets the priority by which a parent layout should apportion space to this child.

### Adjusting a view’s position

Making fine adjustments to a view’s position

Shift the position of a view by applying the offset or position modifier.

Positions the center of this view at the specified point in its parent’s coordinate space.

Positions the center of this view at the specified coordinates in its parent’s coordinate space.

Offset this view by the horizontal and vertical amount specified in the offset parameter.

Offset this view by the specified horizontal and vertical distances.

Brings a view forward in Z by the provided distance in points.

### Aligning views

Aligning views within a stack

Position views inside a stack using alignment guides.

Aligning views across stacks

Create a custom alignment and use it to align views across multiple stacks.

`func alignmentGuide(_:computeValue:)`

Sets the view’s horizontal alignment.

`struct Alignment`

An alignment in both axes.

`struct HorizontalAlignment`

An alignment position along the horizontal axis.

`struct VerticalAlignment`

An alignment position along the vertical axis.

`struct DepthAlignment`

An alignment position along the depth axis.

`protocol AlignmentID`

A type that you use to create custom alignment guides.

`struct ViewDimensions`

A view’s size and alignment guides in its own coordinate space.

`struct ViewDimensions3D`

A view’s 3D size and alignment guides in its own coordinate space.

`struct SpatialContainer`

A layout container that aligns overlapping content in 3D space.

Beta

### Setting margins

Configures the content margin for a provided placement.

`func contentMargins(_:_:for:)`

`struct ContentMarginPlacement`

The placement of margins.

### Staying in the safe areas

Expands the safe area of a view.

`func safeAreaInset(edge:alignment:spacing:content:)`

Shows the specified content beside the modified view.

`func safeAreaPadding(_:)`

Adds the provided insets into the safe area of this view.

`struct SafeAreaRegions`

A set of symbolic safe area regions.

### Setting a layout direction

Sets the behavior of this view for different layout directions.

`enum LayoutDirectionBehavior`

A description of what should happen when the layout direction changes.

`var layoutDirection: LayoutDirection`

The layout direction associated with the current environment.

`enum LayoutDirection`

A direction in which SwiftUI can lay out content.

`struct LayoutRotationUnaryLayout` Beta

### Reacting to interface characteristics

`var isLuminanceReduced: Bool`

A Boolean value that indicates whether the display or environment currently requires reduced luminance.

`var displayScale: CGFloat`

The display scale of this environment.

`var pixelLength: CGFloat`

The size of a pixel on the screen.

`var horizontalSizeClass: UserInterfaceSizeClass?`

The horizontal size class of this environment.

`var verticalSizeClass: UserInterfaceSizeClass?`

The vertical size class of this environment.

`enum UserInterfaceSizeClass`

A set of values that indicate the visual size available to the view.

### Accessing edges, regions, and layouts

`enum Edge`

An enumeration to indicate one edge of a rectangle.

`enum Edge3D`

An edge or face of a 3D volume.

`enum HorizontalEdge`

An edge on the horizontal axis.

`enum VerticalEdge`

An edge on the vertical axis.

`struct EdgeInsets`

The inset distances for the sides of a rectangle.

`struct EdgeInsets3D`

The inset distances for the faces of a 3D volume.

## See Also

### View layout

Arrange views inside built-in layout containers like stacks and grids.

Place views in custom arrangements and create animated transitions between layout types.

Display a structured, scrollable column of information.

Display selectable, sortable data arranged in rows and columns.

Present views in different kinds of purpose-driven containers, like forms or control groups.

Enable people to scroll to content that doesn’t fit in the current display.

---

# https://developer.apple.com/documentation/swiftui/custom-layout

Collection

- SwiftUI
- Custom layout

API Collection

# Custom layout

Place views in custom arrangements and create animated transitions between layout types.

## Overview

You can create complex view layouts using the built-in layout containers and layout view modifiers that SwiftUI provides. However, if you need behavior that you can’t achieve with the built-in layout tools, create a custom layout container type using the `Layout` protocol. A container that you define asks for the sizes of all its subviews, and then indicates where to place the subviews within its own bounds.

You can also create animated transitions among layout types that conform to the `Layout` procotol, including both built-in and custom layouts.

For design guidance, see Layout in the Human Interface Guidelines.

## Topics

### Creating a custom layout container

Composing custom layouts with SwiftUI

Arrange views in your app’s interface using layout tools that SwiftUI provides.

`protocol Layout`

A type that defines the geometry of a collection of views.

`struct LayoutSubview`

A proxy that represents one subview of a layout.

`struct LayoutSubviews`

A collection of proxy values that represent the subviews of a layout view.

### Configuring a custom layout

`struct LayoutProperties`

Layout-specific properties of a layout container.

`struct ProposedViewSize`

A proposal for the size of a view.

`struct ViewSpacing`

A collection of the geometric spacing preferences of a view.

### Associating values with views in a custom layout

Associates a value with a custom layout property.

`protocol LayoutValueKey`

A key for accessing a layout value of a layout container’s subviews.

### Transitioning between layout types

`struct AnyLayout`

A type-erased instance of the layout protocol.

`struct HStackLayout`

A horizontal container that you can use in conditional layouts.

`struct VStackLayout`

A vertical container that you can use in conditional layouts.

`struct ZStackLayout`

An overlaying container that you can use in conditional layouts.

`struct GridLayout`

A grid that you can use in conditional layouts.

## See Also

### View layout

Arrange views inside built-in layout containers like stacks and grids.

Make fine adjustments to alignment, spacing, padding, and other layout parameters.

Display a structured, scrollable column of information.

Display selectable, sortable data arranged in rows and columns.

Present views in different kinds of purpose-driven containers, like forms or control groups.

Enable people to scroll to content that doesn’t fit in the current display.

---

# https://developer.apple.com/documentation/swiftui/lists

Collection

- SwiftUI
- Lists

API Collection

# Lists

Display a structured, scrollable column of information.

## Overview

Use a list to display a one-dimensional vertical collection of views.

The list is a complex container type that automatically provides scrolling when it grows too large for the current display. You build a list by providing it with individual views for the rows in the list, or by using a `ForEach` to enumerate a group of rows. You can also mix these strategies, blending any number of individual views and `ForEach` constructs.

Use view modifiers to configure the appearance and behavior of a list and its rows, headers, sections, and separators. For example, you can apply a style to the list, add swipe gestures to individual rows, or make the list refreshable with a pull-down gesture. You can also use the configuration associated with Scroll views to control the list’s implicit scrolling behavior.

For design guidance, see Lists and tables in the Human Interface Guidelines.

## Topics

### Creating a list

Displaying data in lists

Visualize collections of data with platform-appropriate appearance.

`struct List`

A container that presents rows of data arranged in a single column, optionally providing the ability to select one or more members.

Sets the style for lists within this view.

### Disclosing information progressively

`struct OutlineGroup`

A structure that computes views and disclosure groups on demand from an underlying collection of tree-structured, identified data.

`struct DisclosureGroup`

A view that shows or hides another content view, based on the state of a disclosure control.

Sets the style for disclosure groups within this view.

### Configuring rows

Applies an inset to the rows in a list.

Requests that the containing list row use the provided hover effect.

Requests that the containing list row have its hover effect disabled.

`func listItemTint(_:)`

Sets a fixed tint color for content in a list.

`struct ListItemTint`

A tint effect configuration that you can apply to content in a list.

`var defaultMinListRowHeight: CGFloat`

The default minimum height of a row in a list.

### Configuring separators

Sets the tint color associated with a row.

Sets the tint color associated with a section.

Sets the display mode for the separator associated with this specific row.

Sets whether to hide the separator associated with a list section.

### Configuring headers

Sets the header prominence for this view.

`var headerProminence: Prominence`

The prominence to apply to section headers within a view.

`enum Prominence`

A type indicating the prominence of a view hierarchy.

`var defaultMinListHeaderHeight: CGFloat?`

The default minimum height of a header in a list.

### Configuring spacing

Sets the vertical spacing between two adjacent rows in a List.

`func listSectionSpacing(_:)`

Sets the spacing between adjacent sections in a `List` to a custom value.

`struct ListSectionSpacing`

The spacing options between two adjacent sections in a list.

### Configuring backgrounds

Places a custom background view behind a list row item.

Overrides whether lists and tables in this view have alternating row backgrounds.

`struct AlternatingRowBackgroundBehavior`

The styling of views with respect to alternating row backgrounds.

`var backgroundProminence: BackgroundProminence`

The prominence of the background underneath views associated with this environment.

`struct BackgroundProminence`

The prominence of backgrounds underneath other views.

### Displaying a badge on a list item

`func badge(_:)`

Generates a badge for the view from an integer value.

Specifies the prominence of badges created by this view.

`var badgeProminence: BadgeProminence`

The prominence to apply to badges associated with this environment.

`struct BadgeProminence`

The visual prominence of a badge.

### Configuring interaction

Adds custom swipe actions to a row in a list.

Adds a condition that controls whether users can select this view.

### Refreshing a list’s content

Marks this view as refreshable.

`var refresh: RefreshAction?`

A refresh action stored in a view’s environment.

`struct RefreshAction`

An action that initiates a refresh operation.

### Editing a list

Adds a condition for whether the view’s view hierarchy is movable.

Adds a condition for whether the view’s view hierarchy is deletable.

An indication of whether the user can edit the contents of a view associated with this environment.

`enum EditMode`

A mode that indicates whether the user can edit a view’s content.

`struct EditActions`

A set of edit actions on a collection of data that a view can offer to a user.

`struct EditableCollectionContent`

An opaque wrapper view that adds editing capabilities to a row in a list.

`struct IndexedIdentifierCollection`

A collection wrapper that iterates over the indices and identifiers of a collection together.

## See Also

### View layout

Arrange views inside built-in layout containers like stacks and grids.

Make fine adjustments to alignment, spacing, padding, and other layout parameters.

Place views in custom arrangements and create animated transitions between layout types.

Display selectable, sortable data arranged in rows and columns.

Present views in different kinds of purpose-driven containers, like forms or control groups.

Enable people to scroll to content that doesn’t fit in the current display.

---

# https://developer.apple.com/documentation/swiftui/tables

Collection

- SwiftUI
- Tables

API Collection

# Tables

Display selectable, sortable data arranged in rows and columns.

## Overview

Use a table to display multiple values across a collection of elements. Each element in the collection appears in a different row of the table, while each value for a given element appears in a different column. Narrow displays may adapt to show only the first column of the table.

When you create a table, you provide a collection of elements, and then tell the table how to find the needed value for each column. In simple cases, SwiftUI infers the element for each row, but you can also specify the row elements explicitly in more complex scenarios. With a small amount of additional configuration, you can also make the items in the table selectable, and the columns sortable.

Like a `List`, a table includes implicit vertical scrolling that you can configure using the view modifiers described in Scroll views. For design guidance, see Lists and tables in the Human Interface Guidelines.

## Topics

### Creating a table

Building a Great Mac App with SwiftUI

Create engaging SwiftUI Mac apps by incorporating side bars, tables, toolbars, and several other popular user interface elements.

`struct Table`

A container that presents rows of data arranged in one or more columns, optionally providing the ability to select one or more members.

Sets the style for tables within this view.

### Creating columns

`struct TableColumn`

A column that displays a view for each row in a table.

`protocol TableColumnContent`

A type used to represent columns within a table.

`struct TableColumnAlignment`

Describes the alignment of the content of a table column.

`struct TableColumnBuilder`

A result builder that creates table column content from closures.

`struct TableColumnForEach`

A structure that computes columns on demand from an underlying collection of identified data.

### Customizing columns

Controls the visibility of a `Table`’s column header views.

`struct TableColumnCustomization`

A representation of the state of the columns in a table.

`struct TableColumnCustomizationBehavior`

A set of customization behaviors of a column that a table can offer to a user.

### Creating rows

`struct TableRow`

A row that represents a data value in a table.

`protocol TableRowContent`

A type used to represent table rows.

`struct TableHeaderRowContent`

A table row that displays a single view instead of columned content.

`struct TupleTableRowContent`

A type of table column content that creates table rows created from a Swift tuple of table rows.

`struct TableForEachContent`

A type of table row content that creates table rows created by iterating over a collection.

`struct EmptyTableRowContent`

A table row content that doesn’t produce any rows.

`protocol DynamicTableRowContent`

A type of table row content that generates table rows from an underlying collection of data.

`struct TableRowBuilder`

A result builder that creates table row content from closures.

### Adding progressive disclosure

`struct DisclosureTableRow`

A kind of table row that shows or hides additional rows based on the state of a disclosure control.

`struct TableOutlineGroupContent`

An opaque table row type created by a table’s hierarchical initializers.

## See Also

### View layout

Arrange views inside built-in layout containers like stacks and grids.

Make fine adjustments to alignment, spacing, padding, and other layout parameters.

Place views in custom arrangements and create animated transitions between layout types.

Display a structured, scrollable column of information.

Present views in different kinds of purpose-driven containers, like forms or control groups.

Enable people to scroll to content that doesn’t fit in the current display.

---

# https://developer.apple.com/documentation/swiftui/view-groupings

Collection

- SwiftUI
- View groupings

API Collection

# View groupings

Present views in different kinds of purpose-driven containers, like forms or control groups.

## Overview

You can create groups of views that serve different purposes.

For example, a `Group` construct treats the specified views as a unit without imposing any additional layout or appearance characteristics. A `Form` presents a group of elements with a platform-specific appearance that’s suitable for gathering input from people.

For design guidance, see Layout in the Human Interface Guidelines.

## Topics

### Grouping views into a container

Creating custom container views

Access individual subviews to compose flexible container views.

`struct Group`

A type that collects multiple instances of a content type — like views, scenes, or commands — into a single unit.

`struct GroupElementsOfContent`

Transforms the subviews of a given view into a resulting content view.

`struct GroupSectionsOfContent`

Transforms the sections of a given view into a resulting content view.

### Organizing views into sections

`struct Section`

A container view that you can use to add hierarchy within certain views.

`struct SectionCollection`

An opaque collection representing the sections of view.

`struct SectionConfiguration`

Specifies the contents of a section.

### Iterating over dynamic data

`struct ForEach`

A structure that computes views on demand from an underlying collection of identified data.

`struct ForEachSectionCollection`

A collection which allows a view to be treated as a collection of its sections in a for each loop.

`struct ForEachSubviewCollection`

A collection which allows a view to be treated as a collection of its subviews in a for each loop.

`protocol DynamicViewContent`

A type of view that generates views from an underlying collection of data.

### Accessing a container’s subviews

`struct Subview`

An opaque value representing a subview of another view.

`struct SubviewsCollection`

An opaque collection representing the subviews of view.

`struct SubviewsCollectionSlice`

A slice of a SubviewsCollection.

Sets a particular container value of a view.

`struct ContainerValues`

A collection of container values associated with a given view.

`protocol ContainerValueKey`

A key for accessing container values.

### Grouping views into a box

`struct GroupBox`

A stylized view, with an optional label, that visually collects a logical grouping of content.

Sets the style for group boxes within this view.

### Grouping inputs

`struct Form`

A container for grouping controls used for data entry, such as in settings or inspectors.

Sets the style for forms in a view hierarchy.

`struct LabeledContent`

A container for attaching a label to a value-bearing view.

Sets a style for labeled content.

### Presenting a group of controls

`struct ControlGroup`

A container view that displays semantically-related controls in a visually-appropriate manner for the context

Sets the style for control groups within this view.

## See Also

### View layout

Arrange views inside built-in layout containers like stacks and grids.

Make fine adjustments to alignment, spacing, padding, and other layout parameters.

Place views in custom arrangements and create animated transitions between layout types.

Display a structured, scrollable column of information.

Display selectable, sortable data arranged in rows and columns.

Enable people to scroll to content that doesn’t fit in the current display.

---

# https://developer.apple.com/documentation/swiftui/scroll-views

Collection

- SwiftUI
- Scroll views

API Collection

# Scroll views

Enable people to scroll to content that doesn’t fit in the current display.

## Overview

When the content of a view doesn’t fit in the display, you can wrap the view in a `ScrollView` to enable people to scroll on one or more axes. Configure the scroll view using view modifiers. For example, you can set the visibility of the scroll indicators or the availability of scrolling in a given dimension.

You can put any view type in a scroll view, but you most often use a scroll view for a layout container with too many elements to fit in the display. For some container views that you put in a scroll view, like lazy stacks, the container doesn’t load views until they are visible or almost visible. For others, like regular stacks and grids, the container loads the content all at once, regardless of the state of scrolling.

Lists and Tables implicitly include a scroll view, so you don’t need to add scrolling to those container types. However, you can configure their implicit scroll views with the same view modifiers that apply to explicit scroll views.

For design guidance, see Scroll views in the Human Interface Guidelines.

## Topics

### Creating a scroll view

`struct ScrollView`

A scrollable view.

`struct ScrollViewReader`

A view that provides programmatic scrolling, by working with a proxy to scroll to known child views.

`struct ScrollViewProxy`

A proxy value that supports programmatic scrolling of the scrollable views within a view hierarchy.

### Managing scroll position

Associates a binding to a scroll position with a scroll view within this view.

Associates a binding to be updated when a scroll view within this view scrolls.

Associates an anchor to control which part of the scroll view’s content should be rendered by default.

Associates an anchor to control the position of a scroll view in a particular circumstance.

`struct ScrollAnchorRole`

A type defining the role of a scroll anchor.

`struct ScrollPosition`

A type that defines the semantic position of where a scroll view is scrolled within its content.

### Defining scroll targets

Sets the scroll behavior of views scrollable in the provided axes.

Configures the outermost layout as a scroll target layout.

`struct ScrollTarget`

A type defining the target in which a scroll view should try and scroll to.

`protocol ScrollTargetBehavior`

A type that defines the scroll behavior of a scrollable view.

`struct ScrollTargetBehaviorContext`

The context in which a scroll target behavior updates its scroll target.

`struct PagingScrollTargetBehavior`

The scroll behavior that aligns scroll targets to container-based geometry.

`struct ViewAlignedScrollTargetBehavior`

The scroll behavior that aligns scroll targets to view-based geometry.

`struct AnyScrollTargetBehavior`

A type-erased scroll target behavior.

`struct ScrollTargetBehaviorProperties`

Properties influencing the scroll view a scroll target behavior applies to.

`struct ScrollTargetBehaviorPropertiesContext`

The context in which a scroll target behavior can decide its properties.

### Animating scroll transitions

Applies the given transition, animating between the phases of the transition as this view appears and disappears within the visible region of the containing scroll view.

`enum ScrollTransitionPhase`

The phases that a view transitions between when it scrolls among other views.

`struct ScrollTransitionConfiguration`

The configuration of a scroll transition that controls how a transition is applied as a view is scrolled through the visible region of a containing scroll view or other container.

### Responding to scroll view changes

Adds an action to be performed when a value, created from a scroll geometry, changes.

Adds an action to be called with information about what views would be considered visible.

Adds an action to be called when the view crosses the threshold to be considered on/off screen.

`func onScrollPhaseChange(_:)`

Adds an action to perform when the scroll phase of the first scroll view in the hierarchy changes.

`struct ScrollGeometry`

A type that defines the geometry of a scroll view.

`enum ScrollPhase`

A type that describes the state of a scroll gesture of a scrollable view like a scroll view.

`struct ScrollPhaseChangeContext`

A type that provides you with more content when the phase of a scroll view changes.

### Showing scroll indicators

Flashes the scroll indicators of a scrollable view when it appears.

Flashes the scroll indicators of scrollable views when a value changes.

Sets the visibility of scroll indicators within this view.

`var horizontalScrollIndicatorVisibility: ScrollIndicatorVisibility`

The visibility to apply to scroll indicators of any horizontally scrollable content.

`var verticalScrollIndicatorVisibility: ScrollIndicatorVisibility`

The visiblity to apply to scroll indicators of any vertically scrollable content.

`struct ScrollIndicatorVisibility`

The visibility of scroll indicators of a UI element.

### Managing content visibility

Specifies the visibility of the background for scrollable views within this view.

Sets whether a scroll view clips its content to its bounds.

`struct ScrollContentOffsetAdjustmentBehavior`

A type that defines the different kinds of content offset adjusting behaviors a scroll view can have.

### Disabling scrolling

Disables or enables scrolling in scrollable views.

`var isScrollEnabled: Bool`

A Boolean value that indicates whether any scroll views associated with this environment allow scrolling to occur.

### Configuring scroll bounce behavior

Configures the bounce behavior of scrollable views along the specified axis.

`var horizontalScrollBounceBehavior: ScrollBounceBehavior`

The scroll bounce mode for the horizontal axis of scrollable views.

`var verticalScrollBounceBehavior: ScrollBounceBehavior`

The scroll bounce mode for the vertical axis of scrollable views.

`struct ScrollBounceBehavior`

The ways that a scrollable view can bounce when it reaches the end of its content.

### Configuring scroll edge effects

Configures the scroll edge effect style for scroll views within this hierarchy.

Beta

Disables any scroll edge effects for scroll views within this hierarchy.

`struct ScrollEdgeEffectStyle`

A structure that defines the style of pocket a scroll view will have.

`func safeAreaBar(edge:alignment:spacing:content:)`

Renders the provided content appropriately to be displayed as a custom bar.

### Interacting with a software keyboard

Configures the behavior in which scrollable content interacts with the software keyboard.

`var scrollDismissesKeyboardMode: ScrollDismissesKeyboardMode`

The way that scrollable content interacts with the software keyboard.

`struct ScrollDismissesKeyboardMode`

The ways that scrollable content can interact with the software keyboard.

### Managing scrolling for different inputs

Enables or disables scrolling in scrollable views when using particular inputs.

`struct ScrollInputKind`

Inputs used to scroll views.

`struct ScrollInputBehavior`

A type that defines whether input should scroll a view.

## See Also

### View layout

Arrange views inside built-in layout containers like stacks and grids.

Make fine adjustments to alignment, spacing, padding, and other layout parameters.

Place views in custom arrangements and create animated transitions between layout types.

Display a structured, scrollable column of information.

Display selectable, sortable data arranged in rows and columns.

Present views in different kinds of purpose-driven containers, like forms or control groups.

---

# https://developer.apple.com/documentation/swiftui/gestures

Collection

- SwiftUI
- Gestures

API Collection

# Gestures

Define interactions from taps, clicks, and swipes to fine-grained gestures.

## Overview

Respond to gestures by adding gesture modifiers to your views. You can listen for taps, drags, pinches, and other standard gestures.

You can also compose custom gestures from individual gestures using the `simultaneously(with:)`, `sequenced(before:)`, or `exclusively(before:)` modifiers, or combine gestures with keyboard modifiers using the `modifiers(_:)` modifier.

For design guidance, see Gestures in the Human Interface Guidelines.

## Topics

### Essentials

Adding interactivity with gestures

Use gesture modifiers to add interactivity to your app.

### Recognizing tap gestures

Adds an action to perform when this view recognizes a tap gesture.

`func onTapGesture(count:coordinateSpace:perform:)`

Adds an action to perform when this view recognizes a tap gesture, and provides the action with the location of the interaction.

`struct TapGesture`

A gesture that recognizes one or more taps.

`struct SpatialTapGesture`

A gesture that recognizes one or more taps and reports their location.

### Recognizing long press gestures

Adds an action to perform when this view recognizes a long press gesture.

Adds an action to perform when this view recognizes a remote long touch gesture. A long touch gesture is when the finger is on the remote touch surface without actually pressing.

`struct LongPressGesture`

A gesture that succeeds when the user performs a long press.

### Recognizing spatial events

`struct SpatialEventGesture`

A gesture that provides information about ongoing spatial events like clicks and touches.

`struct SpatialEventCollection`

A collection of spatial input events that target a specific view.

`enum Chirality`

The chirality, or handedness, of a pose.

### Recognizing gestures that change over time

`func gesture(_:)`

Attaches an `NSGestureRecognizerRepresentable` to the view.

Beta

Attaches a gesture to the view with a lower precedence than gestures defined by the view.

`struct DragGesture`

A dragging motion that invokes an action as the drag-event sequence changes.

`struct WindowDragGesture`

A gesture that recognizes the motion of and handles dragging a window.

`struct MagnifyGesture`

A gesture that recognizes a magnification motion and tracks the amount of magnification.

`struct RotateGesture`

A gesture that recognizes a rotation motion and tracks the angle of the rotation.

`struct RotateGesture3D`

A gesture that recognizes 3D rotation motion and tracks the angle and axis of the rotation.

`struct GestureMask`

Options that control how adding a gesture to a view affects other gestures recognized by the view and its subviews.

### Recognizing Apple Pencil gestures

Adds an action to perform after the user double-taps their Apple Pencil.

Adds an action to perform when the user squeezes their Apple Pencil.

`var preferredPencilDoubleTapAction: PencilPreferredAction`

The action that the user prefers to perform after double-tapping their Apple Pencil, as selected in the Settings app.

`var preferredPencilSqueezeAction: PencilPreferredAction`

The action that the user prefers to perform when squeezing their Apple Pencil, as selected in the Settings app.

`struct PencilPreferredAction`

An action that the user prefers to perform after double-tapping their Apple Pencil.

`struct PencilDoubleTapGestureValue`

Describes the value of an Apple Pencil double-tap gesture.

`struct PencilSqueezeGestureValue`

Describes the value of an Apple Pencil squeeze gesture.

`enum PencilSqueezeGesturePhase`

Describes the phase and value of an Apple Pencil squeeze gesture.

`struct PencilHoverPose`

A value describing the location and distance of an Apple Pencil hovering in the area above a view’s bounds.

### Combining gestures

Composing SwiftUI gestures

Combine gestures to create complex interactions.

Attaches a gesture to the view to process simultaneously with gestures defined by the view.

`struct SequenceGesture`

A gesture that’s a sequence of two gestures.

`struct SimultaneousGesture`

A gesture containing two gestures that can happen at the same time with neither of them preceding the other.

`struct ExclusiveGesture`

A gesture that consists of two gestures where only one of them can succeed.

### Defining custom gestures

Attaches a gesture to the view with a higher precedence than gestures defined by the view.

Assigns a hand gesture shortcut to the modified control.

Sets the screen edge from which you want your gesture to take precedence over the system gesture.

`protocol Gesture`

An instance that matches a sequence of events to a gesture, and returns a stream of values for each of its states.

`struct AnyGesture`

A type-erased gesture.

`struct HandActivationBehavior`

An activation behavior specific to hand-driven input.

`struct HandGestureShortcut`

Hand gesture shortcuts describe finger and wrist movements that the user can perform in order to activate a button or toggle.

### Managing gesture state

`struct GestureState`

A property wrapper type that updates a property while the user performs a gesture and resets the property

A gesture that updates the state provided by a gesture’s updating callback.

### Handling activation events

Configures whether gestures in this view hierarchy can handle events that activate the containing window.

### Deprecated gestures

`struct MagnificationGesture`

Deprecated

`struct RotationGesture`

## See Also

### Event handling

Respond to input from a hardware device, like a keyboard or a Touch Bar.

Enable people to move or duplicate items by issuing Copy and Paste commands.

Enable people to move or duplicate items by dragging them from one location to another.

Identify and control which visible object responds to user interaction.

React to system events, like opening a URL.

---

# https://developer.apple.com/documentation/swiftui/input-events

Collection

- SwiftUI
- Input events

API Collection

# Input events

Respond to input from a hardware device, like a keyboard or a Touch Bar.

## Overview

SwiftUI provides view modifiers that enable your app to listen for and react to various kinds of user input. For example, you can create keyboard shortcuts, respond to a form submission, or take input from the digital crown of an Apple Watch.

For design guidance, see Inputs in the Human Interface Guidelines.

## Topics

### Responding to keyboard input

Performs an action if the user presses a key on a hardware keyboard while the view has focus.

Performs an action if the user presses any key on a hardware keyboard while the view has focus.

Performs an action if the user presses one or more keys on a hardware keyboard while the view has focus.

`struct KeyPress`

### Creating keyboard shortcuts

`func keyboardShortcut(_:)`

Assigns a keyboard shortcut to the modified control.

Defines a keyboard shortcut and assigns it to the modified control.

`var keyboardShortcut: KeyboardShortcut?`

The keyboard shortcut that buttons in this environment will be triggered with.

`struct KeyboardShortcut`

Keyboard shortcuts describe combinations of keys on a keyboard that the user can press in order to activate a button or toggle.

`struct KeyEquivalent`

Key equivalents consist of a letter, punctuation, or function key that can be combined with an optional set of modifier keys to specify a keyboard shortcut.

`struct EventModifiers`

A set of key modifiers that you can add to a gesture.

### Responding to modifier keys

Performs an action whenever the user presses or releases a hardware modifier key.

Builds a view to use in place of the modified view when the user presses the modifier key(s) indicated by the given set.

### Responding to hover events

Adds an action to perform when the user moves the pointer over or away from the view’s frame.

`func onContinuousHover(coordinateSpace:perform:)`

Adds an action to perform when the pointer enters, moves within, and exits the view’s bounds.

`func hoverEffect(_:isEnabled:)`

Applies a hover effect to this view.

Adds a condition that controls whether this view can display hover effects.

`func defaultHoverEffect(_:)`

Sets the default hover effect to use for views within this view.

`var isHoverEffectEnabled: Bool`

A Boolean value that indicates whether the view associated with this environment allows hover effects to be displayed.

`enum HoverPhase`

The current hovering state and value of the pointer.

`struct HoverEffectPhaseOverride`

Options for overriding a hover effect’s current phase.

Beta

`struct OrnamentHoverContentEffect`

Presents an ornament on hover using a custom effect.

`struct OrnamentHoverEffect`

Presents an ornament on hover.

### Modifying pointer appearance

Sets the pointer style to display when the pointer is over the view.

`struct PointerStyle`

A style describing the appearance of the pointer (also called a cursor) when it’s hovered over a view.

Sets the visibility of the pointer when it’s over the view.

### Changing view appearance for hover events

`struct HoverEffect`

An effect applied when the pointer hovers over a view.

Applies a hover effect to this view, optionally adding it to a `HoverEffectGroup`.

Applies a hover effect to this view described by the given closure.

`protocol CustomHoverEffect`

A type that represents how a view should change when a pointer hovers over a view, or when someone looks at the view.

`struct ContentHoverEffect`

A `CustomHoverEffect` that applies effects to a view on hover using a closure.

`struct HoverEffectGroup`

Describes a grouping of effects that activate together.

Adds an implicit `HoverEffectGroup` to all effects defined on descendant views, so that all effects added to subviews activate as a group whenever this view or any descendant views are hovered.

Adds a `HoverEffectGroup` to all effects defined on descendant views, and activates the group whenever this view or any descendant views are hovered.

`struct GroupHoverEffect`

A `CustomHoverEffect` that activates a named group of effects.

`protocol HoverEffectContent`

A type that describes the effects of a view for a particular hover effect phase.

`struct EmptyHoverEffectContent`

An empty base effect that you use to build other effects.

Sets the behavior of the hand pointer while the user is interacting with the view.

`struct HandPointerBehavior`

A behavior that can be applied to the hand pointer while the user is interacting with a view.

### Responding to submission events

Adds an action to perform when the user submits a value to this view.

Prevents submission triggers originating from this view to invoke a submission action configured by a submission modifier higher up in the view hierarchy.

`struct SubmitTriggers`

A type that defines various triggers that result in the firing of a submission action.

### Labeling a submission event

Sets the submit label for this view.

`struct SubmitLabel`

A semantic label describing the label of submission within a view hierarchy.

### Responding to commands

Adds an action to perform in response to a move command, like when the user presses an arrow key on a Mac keyboard, or taps the edge of the Siri Remote when controlling an Apple TV.

Adds an action to perform in response to the system’s Delete command, or pressing either the ⌫ (backspace) or ⌦ (forward delete) keys while the view has focus.

Steps a value through a range in response to page up or page down commands.

Sets up an action that triggers in response to receiving the exit command while the view has focus.

Adds an action to perform in response to the system’s Play/Pause command.

Adds an action to perform in response to the given selector.

`enum MoveCommandDirection`

Specifies the direction of an arrow key movement.

### Controlling hit testing

Sets whether text in this view can compress the space between characters when necessary to fit text in a line.

Defines the content shape for hit testing.

Sets the content shape for this view.

`struct ContentShapeKinds`

A kind for the content shape of a view.

### Interacting with the Digital Crown

Specifies the visibility of Digital Crown accessory Views on Apple Watch.

Places an accessory View next to the Digital Crown on Apple Watch.

Tracks Digital Crown rotations by updating the specified binding.

`func digitalCrownRotation(detent:from:through:by:sensitivity:isContinuous:isHapticFeedbackEnabled:onChange:onIdle:)`

`struct DigitalCrownEvent`

An event emitted when the user rotates the Digital Crown.

`enum DigitalCrownRotationalSensitivity`

The amount of Digital Crown rotation needed to move between two integer numbers.

### Managing Touch Bar input

Sets the content that the Touch Bar displays.

Sets the Touch Bar content to be shown in the Touch Bar when applicable.

Sets principal views that have special significance to this Touch Bar.

Sets a user-visible string that identifies the view’s functionality.

Sets the behavior of the user-customized view.

`struct TouchBar`

A container for a view that you can show in the Touch Bar.

`enum TouchBarItemPresence`

Options that affect user customization of the Touch Bar.

### Responding to capture events

Used to register an action triggered by system capture events.

Used to register actions triggered by system capture events.

## See Also

### Event handling

Define interactions from taps, clicks, and swipes to fine-grained gestures.

Enable people to move or duplicate items by issuing Copy and Paste commands.

Enable people to move or duplicate items by dragging them from one location to another.

Identify and control which visible object responds to user interaction.

React to system events, like opening a URL.

---

# https://developer.apple.com/documentation/swiftui/clipboard

Collection

- SwiftUI
- Clipboard

API Collection

# Clipboard

Enable people to move or duplicate items by issuing Copy and Paste commands.

## Overview

When people issue standard Copy and Cut commands, they expect to move items to the system’s Clipboard, from which they can paste the items into another place in the same app or into another app. Your app can participate in this activity if you add view modifiers that indicate how to respond to the standard commands.

In your copy and paste modifiers, provide or accept types that conform to the `Transferable` protocol, or that inherit from the `NSItemProvider` class. When possible, prefer using transferable items.

## Topics

### Copying transferable items

Specifies a list of items to copy in response to the system’s Copy command.

Specifies an action that moves items to the Clipboard in response to the system’s Cut command.

Specifies an action that adds validated items to a view in response to the system’s Paste command.

### Copying items using item providers

Adds an action to perform in response to the system’s Copy command.

Adds an action to perform in response to the system’s Cut command.

`func onPasteCommand(of:perform:)`

Adds an action to perform in response to the system’s Paste command.

`func onPasteCommand(of:validator:perform:)`

Adds an action to perform in response to the system’s Paste command with items that you validate.

## See Also

### Event handling

Define interactions from taps, clicks, and swipes to fine-grained gestures.

Respond to input from a hardware device, like a keyboard or a Touch Bar.

Enable people to move or duplicate items by dragging them from one location to another.

Identify and control which visible object responds to user interaction.

React to system events, like opening a URL.

---

# https://developer.apple.com/documentation/swiftui/drag-and-drop

Collection

- SwiftUI
- Drag and drop

API Collection

# Drag and drop

Enable people to move or duplicate items by dragging them from one location to another.

## Overview

Drag and drop offers people a convenient way to move content from one part of your app to another, or from one app to another, using an intuitive dragging gesture. Support this feature in your app by adding view modifiers to potential source and destination views within your app’s interface.

In your modifiers, provide or accept types that conform to the `Transferable` protocol, or that inherit from the `NSItemProvider` class. When possible, prefer using transferable items.

For design guidance, see Drag and drop in the Human Interface Guidelines.

## Topics

### Essentials

Adopting drag and drop using SwiftUI

Enable drag-and-drop interactions in lists, tables and custom views.

Making a view into a drag source

Adopt draggable API to provide items for drag-and-drop operations.

### Configuring drag and drop behavior

`struct DragConfiguration`

The behavior of the drag, proposed by the dragging source.

Beta

`struct DropConfiguration`

Describes the behavior of the drop.

### Moving items

`struct DragSession`

Describes the ongoing dragging session.

`struct DropSession` Beta

### Moving transferable items

Activates this view as the source of a drag and drop operation.

Defines the destination of a drag and drop operation that handles the dropped content with a closure that you specify.

### Moving items using item providers

Provides a closure that vends the drag representation to be used for a particular data element.

`func onDrop(of:isTargeted:perform:)`

Defines the destination of a drag-and-drop operation that handles the dropped content with a closure that you specify.

`func onDrop(of:delegate:)`

Defines the destination of a drag and drop operation using behavior controlled by the delegate that you provide.

`protocol DropDelegate`

An interface that you implement to interact with a drop operation in a view modified to accept drops.

`struct DropProposal`

The behavior of a drop.

`enum DropOperation`

Operation types that determine how a drag and drop session resolves when the user drops a drag item.

`struct DropInfo`

The current state of a drop.

### Describing preview formations

`struct DragDropPreviewsFormation`

On macOS, describes the way the dragged previews are visually composed. Both drag sources and drop destination can specify their desired preview formation.

### Configuring spring loading

Sets the spring loading behavior this view.

`var springLoadingBehavior: SpringLoadingBehavior`

The behavior of spring loaded interactions for the views associated with this environment.

`struct SpringLoadingBehavior`

The options for controlling the spring loading behavior of views.

## See Also

### Event handling

Define interactions from taps, clicks, and swipes to fine-grained gestures.

Respond to input from a hardware device, like a keyboard or a Touch Bar.

Enable people to move or duplicate items by issuing Copy and Paste commands.

Identify and control which visible object responds to user interaction.

React to system events, like opening a URL.

---

# https://developer.apple.com/documentation/swiftui/focus

Collection

- SwiftUI
- Focus

API Collection

# Focus

Identify and control which visible object responds to user interaction.

## Overview

Focus indicates which element in the display receives the next input. Use view modifiers to indicate which views can receive focus, to detect which view has focus, and to programmatically control focus state.

For design guidance, see Focus and selection in the Human Interface Guidelines.

## Topics

### Essentials

Focus Cookbook: Supporting and enhancing focus-driven interactions in your SwiftUI app

Create custom focusable views with key-press handlers that accelerate keyboard input and support movement, and control focus programmatically.

### Indicating that a view can receive focus

Specifies if the view is focusable.

Specifies if the view is focusable, and if so, what focus-driven interactions it supports.

`struct FocusInteractions`

Values describe different focus interactions that a view can support.

### Managing focus state

Modifies this view by binding its focus state to the given state value.

Modifies this view by binding its focus state to the given Boolean state value.

`var isFocused: Bool`

Returns whether the nearest focusable ancestor has focus.

`struct FocusState`

A property wrapper type that can read and write a value that SwiftUI updates as the placement of focus within the scene changes.

`struct FocusedValue`

A property wrapper for observing values from the focused view or one of its ancestors.

`macro Entry()`

Creates an environment values, transaction, container values, or focused values entry.

`protocol FocusedValueKey`

A protocol for identifier types used when publishing and observing focused values.

`struct FocusedBinding`

A convenience property wrapper for observing and automatically unwrapping state bindings from the focused view or one of its ancestors.

Modifies this view by binding the focus state of the search field associated with the nearest searchable modifier to the given Boolean value.

Modifies this view by binding the focus state of the search field associated with the nearest searchable modifier to the given value.

### Exposing value types to focused views

Sets the focused value for the given object type.

`func focusedValue(_:_:)`

Modifies this view by injecting a value that you provide for use by other views whose state depends on the focused view hierarchy.

Sets the focused value for the given object type at a scene-wide scope.

`func focusedSceneValue(_:_:)`

Modifies this view by injecting a value that you provide for use by other views whose state depends on the focused scene.

`struct FocusedValues`

A collection of state exported by the focused view and its ancestors.

### Exposing reference types to focused views

`func focusedObject(_:)`

Creates a new view that exposes the provided object to other views whose whose state depends on the focused view hierarchy.

`func focusedSceneObject(_:)`

Creates a new view that exposes the provided object to other views whose whose state depends on the active scene.

`struct FocusedObject`

A property wrapper type for an observable object supplied by the focused view or one of its ancestors.

### Setting focus scope

Creates a focus scope that SwiftUI uses to limit default focus preferences.

Indicates that the view’s frame and cohort of focusable descendants should be used to guide focus movement.

### Controlling default focus

Indicates that the view should receive focus by default for a given namespace.

Defines a region of the window in which default focus is evaluated by assigning a value to a given focus state binding.

`struct DefaultFocusEvaluationPriority`

Prioritizations for default focus preferences when evaluating where to move focus in different circumstances.

### Resetting focus

`var resetFocus: ResetFocusAction`

An action that requests the focus system to reevaluate default focus.

`struct ResetFocusAction`

An environment value that provides the ability to reevaluate default focus.

### Configuring effects

Adds a condition that controls whether this view can display focus effects, such as a default focus ring or hover effect.

`var isFocusEffectEnabled: Bool`

A Boolean value that indicates whether the view associated with this environment allows focus effects to be displayed.

## See Also

### Event handling

Define interactions from taps, clicks, and swipes to fine-grained gestures.

Respond to input from a hardware device, like a keyboard or a Touch Bar.

Enable people to move or duplicate items by issuing Copy and Paste commands.

Enable people to move or duplicate items by dragging them from one location to another.

React to system events, like opening a URL.

---

# https://developer.apple.com/documentation/swiftui/system-events

Collection

- SwiftUI
- System events

API Collection

# System events

React to system events, like opening a URL.

## Overview

Specify view and scene modifiers to indicate how your app responds to certain system events. For example, you can use the `onOpenURL(perform:)` view modifier to define an action to take when your app receives a universal link, or use the `backgroundTask(_:action:)` scene modifier to specify an asynchronous task to carry out in response to a background task event, like the completion of a background URL session.

## Topics

### Sending and receiving user activities

Restoring Your App’s State with SwiftUI

Provide app continuity for users by preserving their current activities.

Advertises a user activity type.

Registers a handler to invoke in response to a user activity that your app receives.

### Sending and receiving URLs

`var openURL: OpenURLAction`

An action that opens a URL.

`struct OpenURLAction`

Registers a handler to invoke in response to a URL that your app receives.

### Handling external events

Specifies the external events for which SwiftUI opens a new instance of the modified scene.

Specifies the external events that the view’s scene handles if the scene is already open.

### Handling background tasks

Runs the specified action when the system provides a background task.

`struct BackgroundTask`

The kinds of background tasks that your app or extension can handle.

`struct SnapshotData`

The associated data of a snapshot background task.

`struct SnapshotResponse`

Your appplication’s response to a snapshot background task.

### Importing and exporting transferable items

Enables importing items from services, such as Continuity Camera on macOS.

Exports items for consumption by shortcuts, quick actions, and services.

Exports read-write items for consumption by shortcuts, quick actions, and services.

### Importing and exporting using item providers

Enables importing item providers from services, such as Continuity Camera on macOS.

Exports a read-only item provider for consumption by shortcuts, quick actions, and services.

Exports a read-write item provider for consumption by shortcuts, quick actions, and services.

## See Also

### Event handling

Define interactions from taps, clicks, and swipes to fine-grained gestures.

Respond to input from a hardware device, like a keyboard or a Touch Bar.

Enable people to move or duplicate items by issuing Copy and Paste commands.

Enable people to move or duplicate items by dragging them from one location to another.

Identify and control which visible object responds to user interaction.

---

# https://developer.apple.com/documentation/swiftui/accessibility-fundamentals

Collection

- SwiftUI
- Accessibility fundamentals

API Collection

# Accessibility fundamentals

Make your SwiftUI apps accessible to everyone, including people with disabilities.

## Overview

Like all Apple UI frameworks, SwiftUI comes with built-in accessibility support. The framework introspects common elements like navigation views, lists, text fields, sliders, buttons, and so on, and provides basic accessibility labels and values by default. You don’t have to do any extra work to enable these standard accessibility features.

SwiftUI also provides tools to help you enhance the accessibility of your app. To find out what enhancements you need, try using your app with accessibility features like VoiceOver, Voice Control, and Switch Control, or get feedback from users of your app that regularly use these features. Then use the accessibility view modifiers that SwiftUI provides to improve the experience. For example, you can explicitly add accessibility labels to elements in your UI using the `accessibilityLabel(_:)` or the `accessibilityValue(_:)` view modifier.

Customize your use of accessibility modifiers for all the platforms that your app runs on. For example, you may need to adjust the accessibility elements for a companion Apple Watch app that shares a common code base with an iOS app. If you integrate AppKit or UIKit controls in SwiftUI, expose any accessibility labels and make them accessible from your `NSViewRepresentable` or `UIViewRepresentable` views, or provide custom accessibility information if the underlying accessibility labels aren’t available.

For design guidance, see Accessibility in the Human Interface Guidelines.

## Topics

### Essentials

Creating Accessible Views

Make your app accessible to everyone by applying accessibility modifiers to your SwiftUI views.

### Creating accessible elements

Creates a new accessibility element, or modifies the `AccessibilityChildBehavior` of the existing accessibility element.

Replaces the existing accessibility element’s children with one or more new synthetic accessibility elements.

Replaces one or more accessibility elements for this view with new accessibility elements.

`struct AccessibilityChildBehavior`

Defines the behavior for the child elements of the new parent element.

### Identifying elements

Uses the string you specify to identify the view.

### Hiding elements

Specifies whether to hide this view from system accessibility features.

### Supporting types

`struct AccessibilityTechnologies`

Accessibility technologies available to the system.

`struct AccessibilityAttachmentModifier`

A view modifier that adds accessibility properties to the view

## See Also

### Accessibility

Enhance the legibility of content in your app’s interface.

Improve access to actions that your app can undertake.

Describe interface elements to help people understand what they represent.

Enable users to navigate to specific user interface elements using rotors.

---

# https://developer.apple.com/documentation/swiftui/accessible-appearance

Collection

- SwiftUI
- Accessible appearance

API Collection

# Accessible appearance

Enhance the legibility of content in your app’s interface.

## Overview

Make content easier for people to see by making it larger, giving it greater contrast, or reducing the amount of distracting motion.

For design guidance, see Accessibility in the Accessibility section of the Human Interface Guidelines.

## Topics

### Managing color

Sets whether this view should ignore the system Smart Invert setting.

`var accessibilityInvertColors: Bool`

Whether the system preference for Invert Colors is enabled.

`var accessibilityDifferentiateWithoutColor: Bool`

Whether the system preference for Differentiate without Color is enabled.

### Enlarging content

Adds a default large content view to be shown by the large content viewer.

Adds a custom large content view to be shown by the large content viewer.

`var accessibilityLargeContentViewerEnabled: Bool`

Whether the Large Content Viewer is enabled.

### Improving legibility

`var accessibilityShowButtonShapes: Bool`

Whether the system preference for Show Button Shapes is enabled.

`var accessibilityReduceTransparency: Bool`

Whether the system preference for Reduce Transparency is enabled.

`var legibilityWeight: LegibilityWeight?`

The font weight to apply to text.

`enum LegibilityWeight`

The Accessibility Bold Text user setting options.

### Minimizing motion

`var accessibilityDimFlashingLights: Bool`

Whether the setting to reduce flashing or strobing lights in video content is on. This setting can also be used to determine if UI in playback controls should be shown to indicate upcoming content that includes flashing or strobing lights.

`var accessibilityPlayAnimatedImages: Bool`

Whether the setting for playing animations in an animated image is on. When this value is false, any presented image that contains animation should not play automatically.

`var accessibilityReduceMotion: Bool`

Whether the system preference for Reduce Motion is enabled.

### Using assistive access

`var accessibilityAssistiveAccessEnabled: Bool`

A Boolean value that indicates whether Assistive Access is in use.

`struct AssistiveAccess`

A scene that presents an interface appropriate for Assistive Access on iOS and iPadOS. On other platforms, this scene is unused.

Beta

## See Also

### Accessibility

Make your SwiftUI apps accessible to everyone, including people with disabilities.

Improve access to actions that your app can undertake.

Describe interface elements to help people understand what they represent.

Enable users to navigate to specific user interface elements using rotors.

---

# https://developer.apple.com/documentation/swiftui/accessible-controls

Collection

- SwiftUI
- Accessible controls

API Collection

# Accessible controls

Improve access to actions that your app can undertake.

## Overview

Help people using assistive technologies to gain access to controls in your app.

For design guidance, see Accessibility in the Accessibility section of the Human Interface Guidelines.

## Topics

### Adding actions to views

Adds an accessibility action to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the action.

Adds multiple accessibility actions to the view.

`func accessibilityAction(named:_:)`

Adds an accessibility action labeled by the contents of `label` to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the action. When the action is performed, the `intent` will be invoked.

Adds an accessibility action representing `actionKind` to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the action. When the action is performed, the `intent` will be invoked.

`func accessibilityAction(named:intent:)`

Adds an accessibility action labeled `name` to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the action. When the action is performed, the `intent` will be invoked.

Adds an accessibility adjustable action to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the action.

Adds an accessibility scroll action to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the action.

Adds multiple accessibility actions to the view with a specific category. Actions allow assistive technologies, such as VoiceOver, to interact with the view by invoking the action and are grouped by their category. When multiple action modifiers with an equal category are applied to the view, the actions are combined together.

`struct AccessibilityActionKind`

The structure that defines the kinds of available accessibility actions.

`enum AccessibilityAdjustmentDirection`

A directional indicator you use when making an accessibility adjustment.

`struct AccessibilityActionCategory`

Designates an accessibility action category that is provided and named by the system.

### Offering Quick Actions to people

Adds a quick action to be shown by the system when active.

`protocol AccessibilityQuickActionStyle`

A type that describes the presentation style of an accessibility quick action.

### Making gestures accessible

`func accessibilityActivationPoint(_:)`

The activation point for an element is the location assistive technologies use to initiate gestures.

`func accessibilityActivationPoint(_:isEnabled:)`

`func accessibilityDragPoint(_:description:)`

The point an assistive technology should use to begin a drag interaction.

`func accessibilityDragPoint(_:description:isEnabled:)`

`func accessibilityDropPoint(_:description:)`

The point an assistive technology should use to end a drag interaction.

`func accessibilityDropPoint(_:description:isEnabled:)`

Explicitly set whether this accessibility element is a direct touch area. Direct touch areas passthrough touch events to the app rather than being handled through an assistive technology, such as VoiceOver. The modifier accepts an optional `AccessibilityDirectTouchOptions` option set to customize the functionality of the direct touch area.

Adds an accessibility zoom action to the view. Actions allow assistive technologies, such as VoiceOver, to interact with the view by invoking the action.

`struct AccessibilityDirectTouchOptions`

An option set that defines the functionality of a view’s direct touch area.

`struct AccessibilityZoomGestureAction`

Position and direction information of a zoom gesture that someone performs with an assistive technology like VoiceOver.

### Controlling focus

Modifies this view by binding its accessibility element’s focus state to the given boolean state value.

Modifies this view by binding its accessibility element’s focus state to the given state value.

`struct AccessibilityFocusState`

A property wrapper type that can read and write a value that SwiftUI updates as the focus of any active accessibility technology, such as VoiceOver, changes.

### Managing interactivity

Explicitly set whether this Accessibility element responds to user interaction and would thus be interacted with by technologies such as Switch Control, Voice Control or Full Keyboard Access.

## See Also

### Accessibility

Make your SwiftUI apps accessible to everyone, including people with disabilities.

Enhance the legibility of content in your app’s interface.

Describe interface elements to help people understand what they represent.

Enable users to navigate to specific user interface elements using rotors.

---

# https://developer.apple.com/documentation/swiftui/accessible-descriptions

Collection

- SwiftUI
- Accessible descriptions

API Collection

# Accessible descriptions

Describe interface elements to help people understand what they represent.

## Overview

SwiftUI can often infer some information about your user interface elements, but you can use accessibility modifiers to provide even more information for users that need it.

For design guidance, see Accessibility in the Accessibility section of the Human Interface Guidelines.

## Topics

### Applying labels

`func accessibilityLabel(_:)`

Adds a label to the view that describes its contents.

`func accessibilityLabel(_:isEnabled:)`

`func accessibilityInputLabels(_:)`

Sets alternate input labels with which users identify a view.

`func accessibilityInputLabels(_:isEnabled:)`

Pairs an accessibility element representing a label with the element for the matching content.

`enum AccessibilityLabeledPairRole`

The role of an accessibility element in a label / content pair.

### Describing values

`func accessibilityValue(_:)`

Adds a textual description of the value that the view contains.

`func accessibilityValue(_:isEnabled:)`

### Describing content

Sets an accessibility text content type.

Sets the accessibility level of this heading.

`enum AccessibilityHeadingLevel`

The hierarchy of a heading in relation other headings.

`struct AccessibilityTextContentType`

Textual context that assistive technologies can use to improve the presentation of spoken text.

### Describing charts

Adds a descriptor to a View that represents a chart to make the chart’s contents accessible to all users.

`protocol AXChartDescriptorRepresentable`

A type to generate an `AXChartDescriptor` object that you use to provide information about a chart and its data for an accessible experience in VoiceOver or other assistive technologies.

### Adding custom descriptions

`func accessibilityCustomContent(_:_:importance:)`

Add additional accessibility information to the view.

`struct AccessibilityCustomContentKey`

Key used to specify the identifier and label associated with an entry of additional accessibility information.

### Assigning traits to content

Adds the given traits to the view.

Removes the given traits from this view.

`struct AccessibilityTraits`

A set of accessibility traits that describe how an element behaves.

### Offering hints

`func accessibilityHint(_:)`

Communicates to the user what happens after performing the view’s action.

`func accessibilityHint(_:isEnabled:)`

### Configuring VoiceOver

Raises or lowers the pitch of spoken text.

Sets whether VoiceOver should always speak all punctuation in the text view.

Controls whether to queue pending announcements behind existing speech rather than interrupting speech in progress.

Sets whether VoiceOver should speak the contents of the text view character by character.

## See Also

### Accessibility

Make your SwiftUI apps accessible to everyone, including people with disabilities.

Enhance the legibility of content in your app’s interface.

Improve access to actions that your app can undertake.

Enable users to navigate to specific user interface elements using rotors.

---

# https://developer.apple.com/documentation/swiftui/accessible-navigation

Collection

- SwiftUI
- Accessible navigation

API Collection

# Accessible navigation

Enable users to navigate to specific user interface elements using rotors.

## Overview

An accessibility rotor is a shortcut that enables users to quickly navigate to specific elements of the user interface, and, optionally, to specific ranges of text within those elements.

The system automatically provides rotors for many navigable elements, but you can supply additional rotors for specific purposes, or replace system rotors when they don’t automatically pick up off-screen elements, like those far down in a `LazyVStack` or a `List`.

For design guidance, see Accessibility in the Accessibility section of the Human Interface Guidelines.

## Topics

### Working with rotors

`func accessibilityRotor(_:entries:)`

Create an Accessibility Rotor with the specified user-visible label, and entries generated from the content closure.

`func accessibilityRotor(_:entries:entryID:entryLabel:)`

Create an Accessibility Rotor with the specified user-visible label and entries.

`func accessibilityRotor(_:entries:entryLabel:)`

`func accessibilityRotor(_:textRanges:)`

Create an Accessibility Rotor with the specified user-visible label and entries for each of the specified ranges. The Rotor will be attached to the current Accessibility element, and each entry will go the specified range of that element.

### Creating rotors

`protocol AccessibilityRotorContent`

Content within an accessibility rotor.

`struct AccessibilityRotorContentBuilder`

Result builder you use to generate rotor entry content.

`struct AccessibilityRotorEntry`

A struct representing an entry in an Accessibility Rotor.

### Replacing system rotors

`struct AccessibilitySystemRotor`

Designates a Rotor that replaces one of the automatic, system-provided Rotors with a developer-provided Rotor.

### Configuring rotors

Defines an explicit identifier tying an Accessibility element for this view to an entry in an Accessibility Rotor.

Links multiple accessibility elements so that the user can quickly navigate from one element to another, even when the elements are not near each other in the accessibility hierarchy.

Sets the sort priority order for this view’s accessibility element, relative to other elements at the same level.

## See Also

### Accessibility

Make your SwiftUI apps accessible to everyone, including people with disabilities.

Enhance the legibility of content in your app’s interface.

Improve access to actions that your app can undertake.

Describe interface elements to help people understand what they represent.

---

# https://developer.apple.com/documentation/swiftui/appkit-integration

Collection

- SwiftUI
- AppKit integration

API Collection

# AppKit integration

Add AppKit views to your SwiftUI app, or use SwiftUI views in your AppKit app.

## Overview

Integrate SwiftUI with your app’s existing content using hosting controllers to add SwiftUI views into AppKit interfaces. A hosting controller wraps a set of SwiftUI views in a form that you can then add to your storyboard-based app.

You can also add AppKit views and view controllers to your SwiftUI interfaces. A representable object wraps the designated view or view controller, and facilitates communication between the wrapped object and your SwiftUI views.

For design guidance, see Designing for macOS in the Human Interface Guidelines.

## Topics

### Displaying SwiftUI views in AppKit

Unifying your app’s animations

Create a consistent UI animation experience across SwiftUI, UIKit, and AppKit.

`class NSHostingController`

An AppKit view controller that hosts SwiftUI view hierarchy.

`class NSHostingView`

An AppKit view that hosts a SwiftUI view hierarchy.

`class NSHostingMenu`

An AppKit menu with menu items that are defined by a SwiftUI View.

`struct NSHostingSizingOptions`

Options for how hosting views and controllers reflect their content’s size into Auto Layout constraints.

`class NSHostingSceneRepresentation`

An AppKit type that hosts and can present SwiftUI scenes

Beta

`struct NSHostingSceneBridgingOptions`

Options for how hosting views and controllers manage aspects of the associated window.

### Adding AppKit views to SwiftUI view hierarchies

`protocol NSViewRepresentable`

A wrapper that you use to integrate an AppKit view into your SwiftUI view hierarchy.

`struct NSViewRepresentableContext`

Contextual information about the state of the system that you use to create and update your AppKit view.

`protocol NSViewControllerRepresentable`

A wrapper that you use to integrate an AppKit view controller into your SwiftUI interface.

`struct NSViewControllerRepresentableContext`

Contextual information about the state of the system that you use to create and update your AppKit view controller.

### Adding AppKit gesture recognizers into SwiftUI view hierarchies

`protocol NSGestureRecognizerRepresentable`

A wrapper for an `NSGestureRecognizer` that you use to integrate that gesture recognizer into your SwiftUI hierarchy.

`struct NSGestureRecognizerRepresentableContext`

Contextual information about the state of the system that you use to create and update a represented gesture recognizer.

`struct NSGestureRecognizerRepresentableCoordinateSpaceConverter`

A structure used to convert locations to and from coordinate spaces in the hierarchy of the SwiftUI view associated with an `NSGestureRecognizerRepresentable`.

## See Also

### Framework integration

Add UIKit views to your SwiftUI app, or use SwiftUI views in your UIKit app.

Add WatchKit views to your SwiftUI app, or use SwiftUI views in your WatchKit app.

Use SwiftUI views that other Apple frameworks provide.

---

# https://developer.apple.com/documentation/swiftui/uikit-integration

Collection

- SwiftUI
- UIKit integration

API Collection

# UIKit integration

Add UIKit views to your SwiftUI app, or use SwiftUI views in your UIKit app.

## Overview

Integrate SwiftUI with your app’s existing content using hosting controllers to add SwiftUI views into UIKit interfaces. A hosting controller wraps a set of SwiftUI views in a form that you can then add to your storyboard-based app.

You can also add UIKit views and view controllers to your SwiftUI interfaces. A representable object wraps the designated view or view controller, and facilitates communication between the wrapped object and your SwiftUI views.

For design guidance, see the following sections in the Human Interface Guidelines:

- Designing for iOS

- Designing for iPadOS

- Designing for tvOS

## Topics

### Displaying SwiftUI views in UIKit

Using SwiftUI with UIKit

Learn how to incorporate SwiftUI views into a UIKit app.

Unifying your app’s animations

Create a consistent UI animation experience across SwiftUI, UIKit, and AppKit.

`class UIHostingController`

A UIKit view controller that manages a SwiftUI view hierarchy.

`struct UIHostingControllerSizingOptions`

Options for how a hosting controller tracks its content’s size.

`struct UIHostingConfiguration`

A content configuration suitable for hosting a hierarchy of SwiftUI views.

`protocol UIHostingSceneDelegate`

Extends `UIKit/UISceneDelegate` to bridge SwiftUI scenes.

Beta

### Adding UIKit views to SwiftUI view hierarchies

`protocol UIViewRepresentable`

A wrapper for a UIKit view that you use to integrate that view into your SwiftUI view hierarchy.

`struct UIViewRepresentableContext`

Contextual information about the state of the system that you use to create and update your UIKit view.

`protocol UIViewControllerRepresentable`

A view that represents a UIKit view controller.

`struct UIViewControllerRepresentableContext`

Contextual information about the state of the system that you use to create and update your UIKit view controller.

### Adding UIKit gesture recognizers into SwiftUI view hierarchies

`protocol UIGestureRecognizerRepresentable`

A wrapper for a `UIGestureRecognizer` that you use to integrate that gesture recognizer into your SwiftUI hierarchy.

`struct UIGestureRecognizerRepresentableContext`

Contextual information about the state of the system that you use to create and update a represented gesture recognizer.

`struct UIGestureRecognizerRepresentableCoordinateSpaceConverter`

A proxy structure used to convert locations to/from coordinate spaces in the hierarchy of the SwiftUI view associated with a `UIGestureRecognizerRepresentable`.

### Sharing configuration information

`typealias UITraitBridgedEnvironmentKey`

### Hosting an ornament in UIKit

`class UIHostingOrnament`

A model that represents an ornament suitable for being hosted in UIKit.

`class UIOrnament`

The abstract base class that represents an ornament.

## See Also

### Framework integration

Add AppKit views to your SwiftUI app, or use SwiftUI views in your AppKit app.

Add WatchKit views to your SwiftUI app, or use SwiftUI views in your WatchKit app.

Use SwiftUI views that other Apple frameworks provide.

---

# https://developer.apple.com/documentation/swiftui/watchkit-integration

Collection

- SwiftUI
- WatchKit integration

API Collection

# WatchKit integration

Add WatchKit views to your SwiftUI app, or use SwiftUI views in your WatchKit app.

## Overview

Integrate SwiftUI with your app’s existing content using hosting controllers to add SwiftUI views into WatchKit interfaces. A hosting controller wraps a set of SwiftUI views in a form that you can then add to your storyboard-based app.

You can also add WatchKit views and view controllers to your SwiftUI interfaces. A representable object wraps the designated view or view controller, and facilitates communication between the wrapped object and your SwiftUI views.

For design guidance, see Designing for watchOS in the Human Interface Guidelines.

## Topics

### Displaying SwiftUI views in WatchKit

`class WKHostingController`

A WatchKit interface controller that hosts a SwiftUI view hierarchy.

`class WKUserNotificationHostingController`

A WatchKit user notification interface controller that hosts a SwiftUI view hierarchy.

### Adding WatchKit views to SwiftUI view hierarchies

`protocol WKInterfaceObjectRepresentable`

A view that represents a WatchKit interface object.

`struct WKInterfaceObjectRepresentableContext`

Contextual information about the state of the system that you use to create and update your WatchKit interface object.

## See Also

### Framework integration

Add AppKit views to your SwiftUI app, or use SwiftUI views in your AppKit app.

Add UIKit views to your SwiftUI app, or use SwiftUI views in your UIKit app.

Use SwiftUI views that other Apple frameworks provide.

---

# https://developer.apple.com/documentation/swiftui/technology-specific-views

Collection

- SwiftUI
- Technology-specific views

API Collection

# Technology-specific views

Use SwiftUI views that other Apple frameworks provide.

## Overview

To access SwiftUI views that another framework defines, import both SwiftUI and the other framework into the file where you use the view. You can find the framework to import by looking at the availability information on the view’s documentation page.

For example, to use the `Map` view in your app, import both SwiftUI and MapKit.

import SwiftUI
import MapKit

struct MyMapView: View {
// Center the map on Joshua Tree National Park.
var region = MKCoordinateRegion(
center: CLLocationCoordinate2D(latitude: 34.011_286, longitude: -116.166_868),
span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
)

var body: some View {
Map(initialPosition: .region(region))
}
}

For design guidance, see Technologies in the Human Interface Guidelines.

## Topics

### Accessing Apple Pay and Wallet

A view that displays a button for identity verification.

Sets the button’s style.

Sets the style to be used by the button. (see `PKAddPassButtonStyle`).

Called when a user has entered or updated a coupon code. This is required if the user is being asked to provide a coupon code.

Called when a payment method has changed and asks for an update payment request. If this modifier isn’t provided Wallet will assume the payment method is valid.

Called when a user selected a shipping address. This is required if the user is being asked to provide a shipping contact.

Called when a user selected a shipping method. This is required if the user is being asked to provide a shipping method.

Sets the action on the PayLaterView. See `PKPayLaterAction`.

Sets the display style on the PayLaterView. See `PKPayLaterDisplayStyle`.

Sets the style to be used by the button. (see `PayWithApplePayButtonStyle`).

Sets the style to be used by the button. (see `PKIdentityButtonStyle`).

Provides a task to perform before this view appears

### Authorizing and authenticating

A SwiftUI view that displays an authentication interface.

`@MainActor @preconcurrency struct SignInWithAppleButton`

The view that creates the Sign in with Apple button for display.

Sets the style used for displaying the control (see `SignInWithAppleButton.Style`).

`var authorizationController: AuthorizationController`

A value provided in the SwiftUI environment that views can use to perform authorization requests.

`var webAuthenticationSession: WebAuthenticationSession`

A value provided in the SwiftUI environment that views can use to authenticate a user through a web service.

### Configuring Family Sharing

`@MainActor @preconcurrency struct FamilyActivityPicker`

A view in which users specify applications, web domains, and categories without revealing their choices to the app.

Presents an activity picker view as a sheet.

### Reporting on device activity

`@MainActor @preconcurrency struct DeviceActivityReport`

A view that reports the user’s application, category, and web domain activity in a privacy-preserving way.

### Working with managed devices

Applies a managed content style to the view.

Presents a modal view that enables users to add devices to their organization.

### Creating graphics

A SwiftUI view that displays a chart.

`@MainActor @preconcurrency struct SceneView`

A SwiftUI view for displaying 3D SceneKit content.

Deprecated

`@MainActor @preconcurrency struct SpriteView`

A SwiftUI view that renders a SpriteKit scene.

### Getting location information

`@MainActor @preconcurrency struct LocationButton`

A SwiftUI button that grants one-time location authorization.

A view that displays an embedded map interface.

Specifies the map style to be used.

Creates a mapScope that SwiftUI uses to connect map controls to an associated map.

Specifies which map features should have selection disabled.

Specifies the selection accessory to display for a `MapFeature`

Specifies a custom presentation for the currently selected feature.

Configures all `Map` views in the associated environment to have standard size and position controls

Configures all Map controls in the environment to have the specified visibility

Uses the given keyframes to animate the camera of a `Map` when the given trigger value changes.

`func onMapCameraChange(frequency:_:)`

Performs an action when Map camera framing changes

Presents a map item detail popover.

Presents a map item detail sheet.

### Displaying media

`@MainActor @preconcurrency struct CameraView`

A SwiftUI view into which a video stream or an image snapshot is rendered.

`@MainActor @preconcurrency struct NowPlayingView`

A view that displays the system’s Now Playing interface so that the user can control audio.

A view that displays content from a player and a native user interface to control playback.

A `continuityDevicePicker` should be used to discover and connect nearby continuity device through a button interface or other form of activation. On tvOS, this presents a fullscreen continuity device picker experience when selected. The modal view covers as much the screen of `self` as possible when a given condition is true.

Specifies the view that should act as the virtual camera for Apple Vision Pro 2D Persona stream.

### Selecting photos

A view that displays a Photos picker for choosing assets from the photo library.

Presents a Photos picker that selects a `PhotosPickerItem`.

Presents a Photos picker that selects a `PhotosPickerItem` from a given photo library.

Presents a Photos picker that selects a collection of `PhotosPickerItem`.

Presents a Photos picker that selects a collection of `PhotosPickerItem` from a given photo library.

Sets the accessory visibility of the Photos picker. Accessories include anything between the content and the edge, like the navigation bar or the sidebar.

Disables capabilities of the Photos picker.

Sets the mode of the Photos picker.

### Previewing content

Presents a Quick Look preview of the contents of a single URL.

Presents a Quick Look preview of the URLs you provide.

### Interacting with networked devices

A SwiftUI view that displays other devices on the network, and creates an encrypted connection to a copy of your app running on that device.

`var devicePickerSupports: DevicePickerSupportedAction`

Checks for support to present a DevicePicker.

### Configuring a Live Activity

The text color for the auxiliary action button that the system shows next to a Live Activity on the Lock Screen.

Sets the tint color for the background of a Live Activity that appears on the Lock Screen.

`var isActivityFullscreen: Bool`

A Boolean value that indicates whether the Live Activity appears in a full-screen presentation.

`var activityFamily: ActivityFamily`

The size family of the current Live Activity.

### Interacting with the App Store and Apple Music

Presents a StoreKit overlay when a given condition is true.

Display the refund request sheet for the given transaction.

Presents a sheet that enables users to redeem subscription offer codes that you configure in App Store Connect.

Initiates the process of presenting a sheet with subscription offers for Apple Music when the `isPresented` binding is `true`.

Declares the view as dependent on the entitlement of an In-App Purchase product, and returns a modified view.

Add a function to call before initiating a purchase from StoreKit view within this view, providing a set of options for the purchase.

Add an action to perform when a purchase initiated from a StoreKit view within this view completes.

Add an action to perform when a user triggers the purchase button on a StoreKit view within this view.

Adds a standard border to an in-app purchase product’s icon .

Sets the style for In-App Purchase product views within a view.

Configure the visibility of labels displaying an in-app purchase product description within the view.

Specifies the visibility of auxiliary buttons that store view and subscription store view instances may use.

Declares the view as dependent on an In-App Purchase product and returns a modified view.

Declares the view as dependent on a collection of In-App Purchase products and returns a modified view.

Declares the view as dependent on the status of an auto-renewable subscription group, and returns a modified view.

Configures subscription store view instances within a view to use the provided button label.

Sets a view to use to decorate individual subscription options within a subscription store view.

Sets the control style for subscription store views within a view.

Sets the control style and control placement for subscription store views within a view.

Sets the style subscription store views within this view use to display groups of subscription options.

Sets the background style for picker items of the subscription store view instances within a view.

Sets the background shape and style for subscription store view picker items within a view.

Configures a view as the destination for a policy button action in subscription store views.

Configures a URL as the destination for a policy button action in subscription store views.

Sets the style for the and buttons within a subscription store view.

Sets the primary and secondary style for the and buttons within a subscription store view.

Adds an action to perform when a person uses the sign-in button on a subscription store view within a view.

`func subscriptionStoreControlBackground(_:)`

Set a standard effect to use for the background of subscription store view controls within the view.

Selects a promotional offer to apply to a purchase a customer makes from a subscription store view.

Selects a subscription offer to apply to a purchase that a customer makes from a subscription store view, a store view, or a product view.

### Accessing health data

Asynchronously requests permission to read a data type that requires per-object authorization (such as vision prescriptions).

Requests permission to read the specified HealthKit data types.

Requests permission to save and read the specified HealthKit data types.

Presents a preview of the workout contents as a modal sheet

### Providing tips

Presents a popover tip on the modified view.

Sets the tip’s view background to a style. Currently this only applies to inline tips, not popover tips.

Sets the corner radius for an inline tip view.

Sets the size for a tip’s image.

Sets the given style for TipView within the view hierarchy.

Sets the style for a tip’s image.

### Showing a translation

Presents a translation popover when a given condition is true.

Adds a task to perform before this view appears or when the translation configuration changes.

Adds a task to perform before this view appears or when the specified source or target languages change.

### Presenting journaling suggestions

Presents a visual picker interface that contains events and images that a person can select to retrieve more information.

### Managing contact access

Modally present UI which allows the user to select which contacts your app has access to.

### Handling game controller events

Specifies the game controllers events which should be delivered through the GameController framework when the view, or one of its descendants has focus.

### Creating a tabletop game

Adds a tabletop game to a view.

Supplies a closure which returns a new interaction whenever needed.

### Configuring camera controls

`var realityViewCameraControls: CameraControls`

The camera controls for the reality view.

Adds gestures that control the position and direction of a virtual camera.

### Interacting with transactions

Presents a picker that selects a collection of transactions.

## See Also

### Framework integration

Add AppKit views to your SwiftUI app, or use SwiftUI views in your AppKit app.

Add UIKit views to your SwiftUI app, or use SwiftUI views in your UIKit app.

Add WatchKit views to your SwiftUI app, or use SwiftUI views in your WatchKit app.

---

# https://developer.apple.com/documentation/swiftui/previews-in-xcode

Collection

- SwiftUI
- Previews in Xcode

API Collection

# Previews in Xcode

Generate dynamic, interactive previews of your custom views.

## Overview

When you create a custom `View` with SwiftUI, Xcode can display a preview of the view’s content that stays up-to-date as you make changes to the view’s code. You use one of the preview macros — like `Preview(_:body:)` — to tell Xcode what to display. Xcode shows the preview in a canvas beside your code.

Different preview macros enable different kinds of configuration. For example, you can add traits that affect the preview’s appearance using the `Preview(_:traits:_:body:)` macro or add custom viewpoints for the preview using the `Preview(_:traits:body:cameras:)` macro. You can also check how your view behaves inside a specific scene type. For example, in visionOS you can use the `Preview(_:immersionStyle:traits:body:)` macro to preview your view inside an `ImmersiveSpace`.

You typically rely on preview macros to create previews in your code. However, if you can’t get the behavior you need using a preview macro, you can use the `PreviewProvider` protocol and its associated supporting types to define and configure a preview.

## Topics

### Essentials

Previewing your app’s interface in Xcode

Iterate designs quickly and preview your apps’ displays across different Apple devices.

### Creating a preview

Creates a preview of a SwiftUI view.

Creates a preview of a SwiftUI view using the specified traits.

Creates a preview of a SwiftUI view using the specified traits and custom viewpoints.

### Creating a preview in the context of a scene

Creates a preview of a SwiftUI view in an immersive space.

Creates a preview of a SwiftUI view in an immersive space with custom viewpoints.

Creates a preview of a SwiftUI view in a window.

Creates a preview of a SwiftUI view in a window with custom viewpoints.

### Defining a preview

`macro Previewable()`

Tag allowing a dynamic property to appear inline in a preview.

`protocol PreviewProvider`

A type that produces view previews in Xcode.

`enum PreviewPlatform`

Platforms that can run the preview.

Sets a user visible name to show in the canvas for a preview.

`protocol PreviewModifier`

A type that defines an environment in which previews can appear.

`struct PreviewModifierContent`

The type-erased content of a preview.

### Customizing a preview

Overrides the device for a preview.

`struct PreviewDevice`

A simulator device that runs a preview.

Overrides the size of the container for the preview.

Overrides the orientation of the preview.

`struct InterfaceOrientation`

The orientation of the interface from the user’s perspective.

### Setting a context

Declares a context for the preview.

`protocol PreviewContext`

A context type for use with a preview.

`protocol PreviewContextKey`

A key type for a preview context.

### Building in debug mode

`struct DebugReplaceableView`

Erases view opaque result types in debug builds.

Beta

## See Also

### Tool support

Expose custom views and modifiers in the Xcode library.

Measure and improve your app’s responsiveness.

---

# https://developer.apple.com/documentation/swiftui/xcode-library-customization

Collection

- SwiftUI
- Xcode library customization

# Xcode library customization

Expose custom views and modifiers in the Xcode library.

## Overview

You can add your custom SwiftUI views and view modifiers to Xcode’s library. This allows anyone developing your app or adopting your framework to access them by clicking the Library button (+) in Xcode’s toolbar. You can select and drag the custom library items into code, just like you would for system-provided items.

To add items to the library, create a structure that conforms to the `LibraryContentProvider` protocol and encapsulate any items you want to add as `LibraryItem` instances. Implement the doc://com.apple.documentation/documentation/DeveloperToolsSupport/LibraryContentProvider/views-25pdm computed property to add library items containing views. Implement the doc://com.apple.documentation/documentation/DeveloperToolsSupport/LibraryContentProvider/modifiers(base:)-4svii method to add items containing view modifiers. Xcode harvests items from all of the library content providers in your project as you work, and makes them available to you in its library.

## Topics

### Creating library items

`protocol LibraryContentProvider`

A source of Xcode library and code completion content.

`struct LibraryItem`

A single item to add to the Xcode library.

## See Also

### Tool support

Generate dynamic, interactive previews of your custom views.

Measure and improve your app’s responsiveness.

---

# https://developer.apple.com/documentation/swiftui/performance-analysis

Collection

- SwiftUI
- Performance analysis

# Performance analysis

Measure and improve your app’s responsiveness.

## Overview

Use Instruments to detect hangs and hitches in your app, and to analyze long view body updates and frequently occurring SwiftUI updates that can contribute to hangs and hitches.

## Topics

### Essentials

Understanding user interface responsiveness

Make your app more responsive by examining the event-handling and rendering loop.

Understanding hangs in your app

Determine the cause for delays in user interactions by examining the main thread and the main run loop.

Understanding hitches in your app

Determine the cause of interruptions in motion by examining the render loop.

### Analyzing SwiftUI performance

Understanding and improving SwiftUI performance

Identify and address long-running view updates, and reduce the frequency of updates.

## See Also

### Tool support

Generate dynamic, interactive previews of your custom views.

Expose custom views and modifiers in the Xcode library.

---

# https://developer.apple.com/documentation/swiftui/app)



---

# https://developer.apple.com/documentation/swiftui/view)



---

# https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/swiftui/building-a-document-based-app-with-swiftui)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/swiftui/app-organization)



---

# https://developer.apple.com/documentation/swiftui/scenes)



---

# https://developer.apple.com/documentation/swiftui/windows)



---

# https://developer.apple.com/documentation/swiftui/immersive-spaces)



---

# https://developer.apple.com/documentation/swiftui/documents)



---

# https://developer.apple.com/documentation/swiftui/navigation)



---

# https://developer.apple.com/documentation/swiftui/modal-presentations)



---

# https://developer.apple.com/documentation/swiftui/toolbars)



---

# https://developer.apple.com/documentation/swiftui/search)



---

# https://developer.apple.com/documentation/swiftui/app-extensions)



---

# https://developer.apple.com/documentation/swiftui/model-data)



---

# https://developer.apple.com/documentation/swiftui/environment-values)



---

# https://developer.apple.com/documentation/swiftui/preferences)



---

# https://developer.apple.com/documentation/swiftui/persistent-storage)



---

# https://developer.apple.com/documentation/swiftui/view-fundamentals)



---

# https://developer.apple.com/documentation/swiftui/view-configuration)



---

# https://developer.apple.com/documentation/swiftui/view-styles)



---

# https://developer.apple.com/documentation/swiftui/animations)



---

# https://developer.apple.com/documentation/swiftui/text-input-and-output)



---

# https://developer.apple.com/documentation/swiftui/images)



---

# https://developer.apple.com/documentation/swiftui/controls-and-indicators)



---

# https://developer.apple.com/documentation/swiftui/menus-and-commands)



---

# https://developer.apple.com/documentation/swiftui/shapes)



---

# https://developer.apple.com/documentation/swiftui/drawing-and-graphics)



---

# https://developer.apple.com/documentation/swiftui/layout-fundamentals)



---

# https://developer.apple.com/documentation/swiftui/layout-adjustments)



---

# https://developer.apple.com/documentation/swiftui/custom-layout)



---

# https://developer.apple.com/documentation/swiftui/lists)



---

# https://developer.apple.com/documentation/swiftui/tables)



---

# https://developer.apple.com/documentation/swiftui/view-groupings)



---

# https://developer.apple.com/documentation/swiftui/scroll-views)



---

# https://developer.apple.com/documentation/swiftui/gestures)



---

# https://developer.apple.com/documentation/swiftui/input-events)



---

# https://developer.apple.com/documentation/swiftui/clipboard)



---

# https://developer.apple.com/documentation/swiftui/drag-and-drop)



---

# https://developer.apple.com/documentation/swiftui/focus)



---

# https://developer.apple.com/documentation/swiftui/system-events)



---

# https://developer.apple.com/documentation/swiftui/accessibility-fundamentals)



---

# https://developer.apple.com/documentation/swiftui/accessible-appearance)



---

# https://developer.apple.com/documentation/swiftui/accessible-controls)



---

# https://developer.apple.com/documentation/swiftui/accessible-descriptions)



---

# https://developer.apple.com/documentation/swiftui/accessible-navigation)



---

# https://developer.apple.com/documentation/swiftui/appkit-integration)



---

# https://developer.apple.com/documentation/swiftui/uikit-integration)



---

# https://developer.apple.com/documentation/swiftui/watchkit-integration)



---

# https://developer.apple.com/documentation/swiftui/technology-specific-views)



---

# https://developer.apple.com/documentation/swiftui/previews-in-xcode)



---

# https://developer.apple.com/documentation/swiftui/xcode-library-customization)



---

# https://developer.apple.com/documentation/swiftui/performance-analysis)



---

# https://developer.apple.com/documentation/swiftui/migrating-to-the-swiftui-life-cycle

- SwiftUI
- App organization
- Migrating to the SwiftUI life cycle

Article

# Migrating to the SwiftUI life cycle

Use a scene-based life cycle in SwiftUI while keeping your existing codebase.

## Overview

Take advantage of the declarative syntax in SwiftUI and its compatibility with spatial frameworks by moving your app to the SwiftUI life cycle.

Moving to the SwiftUI life cycle requires several steps, including changing your app’s entry point, configuring the launch of your app, and monitoring life-cycle changes with the methods that SwiftUI provides.

### Change your app’s entry point

The UIKit framework defines the `AppDelegate` file as the entry point of your app with the annotation `@main`. For more information on `@main`, see the Attributes section in The Swift Programming Language. To indicate the entry of a SwiftUI app, you’ll need to create a new file that defines your app’s structure.

1. Open your project in Xcode.

4. Add `import SwiftUI` at the top of the file.

5. Annotate the app structure with the `@main` attribute to indicate the entry point of the SwiftUI app, as shown in the code snippet below.

Use following code to create the SwiftUI app structure. To learn more about this structure, follow the tutorial in Exploring the structure of a SwiftUI app.

import SwiftUI

@main
struct MyExampleApp: App {
var body: some Scene {
WindowGroup {
ContentView()
}
}
}

### Support app delegate methods

To continue using methods in your app delegate, use the `UIApplicationDelegateAdaptor` property wrapper. To tell SwiftUI about a delegate that conforms to the `UIApplicationDelegate` protocol, place this property wrapper inside your `App` declaration:

@main
struct MyExampleApp: App {
@UIApplicationDelegateAdaptor private var appDelegate: MyAppDelegate
var body: some Scene { ... }
}

This example marks a custom app delegate named `MyAppDelegate` as the delegate adaptor. Be sure to implement any necessary delegate methods in that type.

### Configure the launch of your app

If you’re migrating an app that contains storyboards to SwiftUI, make sure to remove them when they’re no longer needed.

2. Remove `Main.storyboard` from the project navigator.

3. Choose your app’s target.

4. Open the `Info.plist` file.

5. Remove the `Main storyboard file base name` key.

This figure shows the structure of the `Info.plist` file before removing these keys.

The scene delegate continues to be called after removing the keys from the `Info.plist` file, so you can still handle other scene-based life cycle changes in this file. If you were previously launching your app in your scene delegate, remove the `scene(_:willConnectTo:options:)` method from your scene delegate.

If you didn’t previously support scenes in your app and rely on your app delegate to respond to the launch of your app, ensure you’re no longer setting a root view controller in `application(_:didFinishLaunchingWithOptions:)`. Instead, return `true`.

### Monitor life cycle changes

You will no longer be able to monitor life-cycle changes in your app delegate due to the scene-based nature of SwiftUI (see `Scene`). Prefer to handle these changes in `ScenePhase`, the life cycle enumeration that SwiftUI provides to monitor the phases of a scene. Observe the `Environment` value to initiate actions when the phase changes.

@Environment(\.scenePhase) private var scenePhase

Interpret the value differently based on where you read it from. If you read the phase from inside a `View` instance, the value reflects the phase of the scene that contains the view. If you read the phase from within an `App` instance, the value reflects an aggregation of the phases of all of the scenes in your app.

To handle scene-based events with a scene delegate, provide your scene delegate to your SwiftUI app inside your app delegate. For more information, see the “Scene delegates” section of `UIApplicationDelegateAdaptor`.

For more information on handling scene-based life cycle events, see Managing your app’s life cycle.

## See Also

### Creating an app

Destination Video

Leverage SwiftUI to build an immersive media experience in a multiplatform app.

Hello World

Use windows, volumes, and immersive spaces to teach people about the Earth.

Backyard Birds: Building an app with SwiftData and widgets

Create an app with persistent data, interactive widgets, and an all new in-app purchase experience.

Food Truck: Building a SwiftUI multiplatform app

Create a single codebase and app target for Mac, iPad, and iPhone.

Fruta: Building a Feature-Rich App with SwiftUI

Create a shared codebase to build a multiplatform app that offers widgets and an App Clip.

`protocol App`

A type that represents the structure and behavior of an app.

---

# https://developer.apple.com/documentation/swiftui/app/body-swift.property

- SwiftUI
- App
- body

Instance Property

# body

The content and behavior of the app.

@SceneBuilder @MainActor @preconcurrency
var body: Self.Body { get }

**Required**

## Discussion

For any app that you create, provide a computed `body` property that defines your app’s scenes, which are instances that conform to the `Scene` protocol. For example, you can create a simple app with a single scene containing a single view:

@main
struct MyApp: App {
var body: some Scene {
WindowGroup {
Text("Hello, world!")
}
}
}

Swift infers the app’s `Body` associated type based on the scene provided by the `body` property.

## See Also

### Implementing an app

`associatedtype Body : Scene`

The type of scene representing the content of the app.

---

# https://developer.apple.com/documentation/swiftui/app/main()

#app-main)

- SwiftUI
- App
- main()

Type Method

# main()

Initializes and runs the app.

@MainActor @preconcurrency
static func main()

## Discussion

If you precede your `App` conformer’s declaration with the @main attribute, the system calls the conformer’s `main()` method to launch the app. SwiftUI provides a default implementation of the method that manages the launch process in a platform-appropriate way.

## See Also

### Running an app

`init()`

Creates an instance of the app using the body that you define for its content.

**Required**

---

# https://developer.apple.com/documentation/swiftui/scene

- SwiftUI
- Scene

Protocol

# Scene

A part of an app’s user interface with a life cycle managed by the system.

@MainActor @preconcurrency
protocol Scene

## Mentioned in

Building and customizing the menu bar with SwiftUI

Migrating to the SwiftUI life cycle

## Overview

You create an `App` by combining one or more instances that conform to the `Scene` protocol in the app’s `body`. You can use the built-in scenes that SwiftUI provides, like `WindowGroup`, along with custom scenes that you compose from other scenes. To create a custom scene, declare a type that conforms to the `Scene` protocol. Implement the required `body` computed property and provide the content for your custom scene:

struct MyScene: Scene {
var body: some Scene {
WindowGroup {
MyRootView()
}
}
}

A scene acts as a container for a view hierarchy that you want to display to the user. The system decides when and how to present the view hierarchy in the user interface in a way that’s platform-appropriate and dependent on the current state of the app. For example, for the window group shown above, the system lets the user create or remove windows that contain `MyRootView` on platforms like macOS and iPadOS. On other platforms, the same view hierarchy might consume the entire display when active.

Read the `scenePhase` environment value from within a scene or one of its views to check whether a scene is active or in some other state. You can create a property that contains the scene phase, which is one of the values in the `ScenePhase` enumeration, using the `Environment` attribute:

struct MyScene: Scene {
@Environment(\.scenePhase) private var scenePhase

// ...
}

The `Scene` protocol provides scene modifiers, defined as protocol methods with default implementations, that you use to configure a scene. For example, you can use the `onChange(of:perform:)` modifier to trigger an action when a value changes. The following code empties a cache when all of the scenes in the window group have moved to the background:

struct MyScene: Scene {
@Environment(\.scenePhase) private var scenePhase
@StateObject private var cache = DataCache()

var body: some Scene {
WindowGroup {
MyRootView()
}
.onChange(of: scenePhase) { newScenePhase in
if newScenePhase == .background {
cache.empty()
}
}
}
}

A type conforming to this protocol inherits `@preconcurrency @MainActor` isolation from the protocol if the conformance is included in the type’s base declaration:

struct MyCustomType: Transition {
// `@preconcurrency @MainActor` isolation by default
}

Isolation to the main actor is the default, but it’s not required. Declare the conformance in an extension to opt out of main actor isolation:

extension MyCustomType: Transition {
// `nonisolated` by default
}

## Topics

### Creating a scene

`var body: Self.Body`

The content and behavior of the scene.

**Required**

`associatedtype Body : Scene`

The type of scene that represents the body of this scene.

### Watching for changes

`func onChange(of:initial:_:)`

Adds an action to perform when the given value changes.

Specifies the external events for which SwiftUI opens a new instance of the modified scene.

### Creating background tasks

Runs the specified action when the system provides a background task.

### Managing app storage

The default store used by `AppStorage` contained within the scene and its view content.

### Setting commands

Adds commands to the scene.

Removes all commands defined by the modified scene.

Replaces all commands defined by the modified scene with the commands from the builder.

Defines a keyboard shortcut for opening new scene windows.

### Sizing and positioning the scene

Sets a default position for a window.

`func defaultSize(_:)`

Sets a default size for a window.

Sets a default width and height for a window.

Sets a default size for a volumetric window.

Defines a function used for determining the default placement of windows.

Sets the kind of resizability to use for a window.

Specifies how windows derived form this scene should determine their size when zooming.

Provides a function which determines a placement to use when windows of a scene zoom.

Configures the role for windows derived from `self` when participating in a managed window context, such as full screen or Stage Manager.

### Interacting with volumes

Specifies how a volume should be aligned when moved in the world.

Specify the world scaling behavior for the window.

### Configuring scene visibility

Sets the default launch behavior for this scene.

Sets the restoration behavior for this scene.

Sets the preferred visibility of the non-transient system views overlaying the app.

### Styling the scene

Sets the style for an immersive space.

Sets the preferred visibility of the user’s upper limbs, while an `ImmersiveSpace` scene is presented.

Sets the style for windows created by this scene.

Sets the window level of this scene.

Sets the style for the toolbar defined within this scene.

Sets the label style of items in a toolbar and enables user customization.

Sets the label style of items in a toolbar.

### Configuring a data model

Sets the model context in this scene’s environment.

Sets the model container and associated model context in this scene’s environment.

`func modelContainer(for:inMemory:isAutosaveEnabled:isUndoEnabled:onSetup:)`

Sets the model container in this scene for storing the provided model type, creating a new container if necessary, and also sets a model context for that container in this scene’s environment.

### Managing the environment

Places an observable object in the scene’s environment.

Sets the environment value of the specified key path to the given value.

Supplies an `ObservableObject` to a view subhierarchy.

Transforms the environment value of the specified key path with the given function.

### Interacting with dialogs

Configures the icon used by alerts.

Sets the severity for alerts.

Enables user suppression of an alert with a custom suppression message.

`func dialogSuppressionToggle(_:isSuppressed:)`

### Supporting drag behavior

Configures the behavior of dragging a window by its background.

### Deprecated symbols

Deprecated

### Instance Methods

Adds to a `DocumentGroupLaunchScene` actions that accept a list of selected files as their parameter.

Sets the content brightness of an immersive space.

Sets the immersive environment behavior that should apply when this scene opens.

Beta

Sets the style for menu bar extra created by this scene.

## Relationships

### Conforming Types

- `AlertScene`
- `AssistiveAccess`
- `DocumentGroup`
- `DocumentGroupLaunchScene`
- `Group`
Conforms when `Content` conforms to `Scene`.

- `ImmersiveSpace`
- `MenuBarExtra`
- `ModifiedContent`
Conforms when `Content` conforms to `Scene` and `Modifier` conforms to `_SceneModifier`.

- `RemoteImmersiveSpace`
- `Settings`
- `UtilityWindow`
- `WKNotificationScene`
- `Window`
- `WindowGroup`

## See Also

### Creating scenes

`struct SceneBuilder`

A result builder for composing a collection of scenes into a single composite scene.

---

# https://developer.apple.com/documentation/swiftui/stateobject

- SwiftUI
- StateObject

Structure

# StateObject

A property wrapper type that instantiates an observable object.

@MainActor @frozen @propertyWrapper @preconcurrency

## Overview

Use a state object as the single source of truth for a reference type that you store in a view hierarchy. Create a state object in an `App`, `Scene`, or `View` by applying the `@StateObject` attribute to a property declaration and providing an initial value that conforms to the `ObservableObject` protocol. Declare state objects as private to prevent setting them from a memberwise initializer, which can conflict with the storage management that SwiftUI provides:

class DataModel: ObservableObject {
@Published var name = "Some Name"
@Published var isEnabled = false
}

struct MyView: View {
@StateObject private var model = DataModel() // Create the state object.

var body: some View {
Text(model.name) // Updates when the data model changes.
MySubView()
.environmentObject(model)
}
}

SwiftUI creates a new instance of the model object only once during the lifetime of the container that declares the state object. For example, SwiftUI doesn’t create a new instance if a view’s inputs change, but does create a new instance if the identity of a view changes. When published properties of the observable object change, SwiftUI updates any view that depends on those properties, like the `Text` view in the above example.

### Share state objects with subviews

You can pass a state object into a subview through a property that has the `ObservedObject` attribute. Alternatively, add the object to the environment of a view hierarchy by applying the `environmentObject(_:)` modifier to a view, like `MySubView` in the above code. You can then read the object inside `MySubView` or any of its descendants using the `EnvironmentObject` attribute:

struct MySubView: View {
@EnvironmentObject var model: DataModel

var body: some View {
Toggle("Enabled", isOn: $model.isEnabled)
}
}

Get a `Binding` to the state object’s properties using the dollar sign ( `$`) operator. Use a binding when you want to create a two-way connection. In the above code, the `Toggle` controls the model’s `isEnabled` value through a binding.

### Initialize state objects using external data

When a state object’s initial state depends on data that comes from outside its container, you can call the object’s initializer explicitly from within its container’s initializer. For example, suppose the data model from the previous example takes a `name` input during initialization and you want to use a value for that name that comes from outside the view. You can do this with a call to the state object’s initializer inside an explicit initializer that you create for the view:

struct MyInitializableView: View {
@StateObject private var model: DataModel

init(name: String) {
// SwiftUI ensures that the following initialization uses the
// closure only once during the lifetime of the view, so
// later changes to the view's name input have no effect.
_model = StateObject(wrappedValue: DataModel(name: name))
}

var body: some View {
VStack {
Text("Name: \(model.name)")
}
}
}

Use caution when doing this. SwiftUI only initializes a state object the first time you call its initializer in a given view. This ensures that the object provides stable storage even as the view’s inputs change. However, it might result in unexpected behavior or unwanted side effects if you explicitly initialize the state object.

In the above example, if the `name` input to `MyInitializableView` changes, SwiftUI reruns the view’s initializer with the new value. However, SwiftUI runs the autoclosure that you provide to the state object’s initializer only the first time you call the state object’s initializer, so the model’s stored `name` value doesn’t change.

Explicit state object initialization works well when the external data that the object depends on doesn’t change for a given instance of the object’s container. For example, you can create two views with different constant names:

var body: some View {
VStack {
MyInitializableView(name: "Ravi")
MyInitializableView(name: "Maria")
}
}

### Force reinitialization by changing view identity

If you want SwiftUI to reinitialize a state object when a view input changes, make sure that the view’s identity changes at the same time. One way to do this is to bind the view’s identity to the value that changes using the `id(_:)` modifier. For example, you can ensure that the identity of an instance of `MyInitializableView` changes when its `name` input changes:

MyInitializableView(name: name)
.id(name) // Binds the identity of the view to the name property.

If you need the view to reinitialize state based on changes in more than one value, you can combine the values into a single identifier using a `Hasher`. For example, if you want to update the data model in `MyInitializableView` when the values of either `name` or `isEnabled` change, you can combine both variables into a single hash:

var hash: Int {
var hasher = Hasher()
hasher.combine(name)
hasher.combine(isEnabled)
return hasher.finalize()
}

Then apply the combined hash to the view as an identifier:

MyInitializableView(name: name, isEnabled: isEnabled)
.id(hash)

Be mindful of the performance cost of reinitializing the state object every time the input changes. Also, changing view identity can have side effects. For example, SwiftUI doesn’t automatically animate changes inside the view if the view’s identity changes at the same time. Also, changing the identity resets _all_ state held by the view, including values that you manage as `State`, `FocusState`, `GestureState`, and so on.

## Topics

### Creating a state object

Creates a new state object with an initial wrapped value.

### Getting the value

`var wrappedValue: ObjectType`

The underlying value referenced by the state object.

A projection of the state object that creates bindings to its properties.

## Relationships

### Conforms To

- `DynamicProperty`
- `Sendable`
- `SendableMetatype`

## See Also

### Creating model data

Managing model data in your app

Create connections between your app’s data model and views.

Migrating from the Observable Object protocol to the Observable macro

Update your existing app to leverage the benefits of Observation in Swift.

`@attached(member, names: named(_$observationRegistrar), named(access), named(withMutation), named(shouldNotifyObservers)) @attached(memberAttribute) @attached(extension, conformances: Observable) macro Observable()`

Defines and implements conformance of the Observable protocol.

Monitoring data changes in your app

Show changes to data in your app’s user interface by using observable objects.

`struct ObservedObject`

A property wrapper type that subscribes to an observable object and invalidates a view whenever the observable object changes.

`protocol ObservableObject : AnyObject`

A type of object with a publisher that emits before the object has changed.

---

# https://developer.apple.com/documentation/swiftui/observedobject

- SwiftUI
- ObservedObject

Structure

# ObservedObject

A property wrapper type that subscribes to an observable object and invalidates a view whenever the observable object changes.

@MainActor @propertyWrapper @preconcurrency @frozen

## Overview

Add the `@ObservedObject` attribute to a parameter of a SwiftUI `View` when the input is an `ObservableObject` and you want the view to update when the object’s published properties change. You typically do this to pass a `StateObject` into a subview.

The following example defines a data model as an observable object, instantiates the model in a view as a state object, and then passes the instance to a subview as an observed object:

class DataModel: ObservableObject {
@Published var name = "Some Name"
@Published var isEnabled = false
}

struct MyView: View {
@StateObject private var model = DataModel()

var body: some View {
Text(model.name)
MySubView(model: model)
}
}

struct MySubView: View {
@ObservedObject var model: DataModel

var body: some View {
Toggle("Enabled", isOn: $model.isEnabled)
}
}

When any published property of the observable object changes, SwiftUI updates any view that depends on the object. Subviews can also make updates to the model properties, like the `Toggle` in the above example, that propagate to other observers throughout the view hierarchy.

Don’t specify a default or initial value for the observed object. Use the attribute only for a property that acts as an input for a view, as in the above example.

## Topics

### Creating an observed object

`init(wrappedValue: ObjectType)`

Creates an observed object with an initial wrapped value.

`init(initialValue: ObjectType)`

Creates an observed object with an initial value.

### Getting the value

`var wrappedValue: ObjectType`

The underlying value that the observed object references.

A projection of the observed object that creates bindings to its properties.

`struct Wrapper`

A wrapper of the underlying observable object that can create bindings to its properties.

## Relationships

### Conforms To

- `DynamicProperty`
- `Sendable`
- `SendableMetatype`

## See Also

### Creating model data

Managing model data in your app

Create connections between your app’s data model and views.

Migrating from the Observable Object protocol to the Observable macro

Update your existing app to leverage the benefits of Observation in Swift.

`@attached(member, names: named(_$observationRegistrar), named(access), named(withMutation), named(shouldNotifyObservers)) @attached(memberAttribute) @attached(extension, conformances: Observable) macro Observable()`

Defines and implements conformance of the Observable protocol.

Monitoring data changes in your app

Show changes to data in your app’s user interface by using observable objects.

`struct StateObject`

A property wrapper type that instantiates an observable object.

`protocol ObservableObject : AnyObject`

A type of object with a publisher that emits before the object has changed.

---

# https://developer.apple.com/documentation/swiftui/environmentobject

- SwiftUI
- EnvironmentObject

Structure

# EnvironmentObject

A property wrapper type for an observable object that a parent or ancestor view supplies.

@MainActor @frozen @propertyWrapper @preconcurrency

## Overview

An environment object invalidates the current view whenever the observable object that conforms to `ObservableObject` changes. If you declare a property as an environment object, be sure to set a corresponding model object on an ancestor view by calling its `environmentObject(_:)` modifier.

## Topics

### Creating an environment object

`init()`

Creates an environment object.

### Getting the value

`var wrappedValue: ObjectType`

The underlying value referenced by the environment object.

A projection of the environment object that creates bindings to its properties using dynamic member lookup.

`struct Wrapper`

A wrapper of the underlying environment object that can create bindings to its properties using dynamic member lookup.

## Relationships

### Conforms To

- `DynamicProperty`
- `Sendable`
- `SendableMetatype`

## See Also

### Distributing model data throughout your app

Supplies an observable object to a view’s hierarchy.

Supplies an `ObservableObject` to a view subhierarchy.

---

# https://developer.apple.com/documentation/swiftui/app/body-swift.associatedtype

- SwiftUI
- App
- Body

Associated Type

# Body

The type of scene representing the content of the app.

associatedtype Body : Scene

**Required**

## Discussion

When you create a custom app, Swift infers this type from your implementation of the required `body` property.

## See Also

### Implementing an app

`var body: Self.Body`

The content and behavior of the app.

---

# https://developer.apple.com/documentation/swiftui/app/init()

#app-main)

- SwiftUI
- App
- init()

Initializer

# init()

Creates an instance of the app using the body that you define for its content.

@MainActor @preconcurrency
init()

**Required**

## Discussion

Swift synthesizes a default initializer for structures that don’t provide one. You typically rely on the default initializer for your app.

## See Also

### Running an app

`static func main()`

Initializes and runs the app.

---

# https://developer.apple.com/documentation/swiftui/backyard-birds-sample

- SwiftUI
- App organization
- Backyard Birds: Building an app with SwiftData and widgets

Sample Code

# Backyard Birds: Building an app with SwiftData and widgets

Create an app with persistent data, interactive widgets, and an all new in-app purchase experience.

Download

Xcode 15.1+

## Overview

Backyard Birds offers a rich environment in which you can watch the birds that visit your backyard garden. You can monitor their water and food supply to ensure they always have fresh water and plenty to eat, or upgrade the game using an in-app purchase to provide tastier food for the birds to eat.

The sample implements its data model using SwiftData for persistence, and integrates seamlessly with SwiftUI using the `Observable` protocol. The game’s widgets implement App Intents for interactive and configurable widgets. The in-app purchase experience uses the `ProductView` and `SubscriptionStoreView` from StoreKit.

You can access the source code for this sample on GitHub.

### Configure the sample code project

To configure the Backyard Birds app to run on your devices, follow these steps:

1. Open the project in Xcode 15 or later.

2. Edit the multiplatform target’s scheme, and on the Options tab, choose the `Store.storekit` file for StoreKit configuration.

3. Repeat the previous step for the watchOS target’s scheme.

4. Select the top-level Backyard Birds project.

5. For all targets, choose your team from the Team menu in the Signing & Capabilities pane so Xcode can automatically manage your provisioning profile.

### Create a data-driven app

The app defines its data model by conforming the model objects to `PersistentModel` using the `Model` macro. Using the `Attribute` macro with the `unique` option ensures that the `id` property is unique.

@Model public class BirdSpecies {
@Attribute(.unique) public var id: String
public var naturalScale: Double
public var isEarlyAccess: Bool
public var parts: [BirdPart]

@Relationship(deleteRule: .cascade, inverse: \Bird.species)
public var birds: [Bird] = []

public var info: BirdSpeciesInfo { BirdSpeciesInfo(rawValue: id) }

public init(info: BirdSpeciesInfo, naturalScale: Double = 1, isEarlyAccess: Bool = false, parts: [BirdPart]) {
self.id = info.rawValue
self.naturalScale = naturalScale
self.isEarlyAccess = isEarlyAccess
self.parts = parts
}
}

### Construct interactive widgets

Backyard Birds displays interactive widgets by presenting a `Button` to refill a backyard’s supplies when the water and food are running low. The app does this by placing a `Button` in the widget’s view, and passing a `ResupplyBackyardIntent` instance to the `init(intent:label:)` initializer:

Button(intent: ResupplyBackyardIntent(backyard: BackyardEntity(from: snapshot.backyard))) {
Label("Refill Water", systemImage: "arrow.clockwise")
.foregroundStyle(.secondary)
.frame(maxWidth: .infinity)
.padding(.vertical, 8)
.padding(.horizontal, 12)
.background(.quaternary, in: .containerRelative)
}

The app allows for configuration of the widget by implementing the `WidgetConfigurationIntent` protocol:

struct BackyardWidgetIntent: WidgetConfigurationIntent {
static let title: LocalizedStringResource = "Backyard"
static let description = IntentDescription("Keep track of your backyards.")

@Parameter(title: "Backyards", default: BackyardWidgetContent.all)
var backyards: BackyardWidgetContent

@Parameter(title: "Backyard")
var specificBackyard: BackyardEntity?

init(backyards: BackyardWidgetContent = .all, specificBackyard: BackyardEntity? = nil) {
self.backyards = backyards
self.specificBackyard = specificBackyard
}

init() {
}

static var parameterSummary: some ParameterSummary {
When(\.$backyards, .equalTo, BackyardWidgetContent.specific) {
Summary {
\.$backyards
\.$specificBackyard
}
} otherwise: {
Summary {
\.$backyards
}
}
}
}

### Provide a new in-app purchase experience

The sample app uses `ProductView` to display several different bird food upgrades available for purchase on a store shelf. To prominently feature an in-app purchase item, the app uses the `.productViewStyle(.large)` modifier:

ProductView(id: product.id) {
BirdFoodProductIcon(birdFood: birdFood, quantity: product.quantity)
.bestBirdFoodValueBadge()
}
.padding(.vertical)
.background(.background.secondary, in: .rect(cornerRadius: 20))
.productViewStyle(.large)

The Backyard Birds Pass page displays renewable subscriptions using the `SubscriptionStoreView` view. The app uses the `PassMarketingContent` view as the content of the `SubscriptionStoreView`:

SubscriptionStoreView(
groupID: passGroupID,
visibleRelationships: showPremiumUpgrade ? .upgrade : .all
) {
PassMarketingContent(showPremiumUpgrade: showPremiumUpgrade)
#if !os(watchOS)
.containerBackground(for: .subscriptionStoreFullHeight) {
SkyBackground()
}
#endif
}

## See Also

### Creating an app

Destination Video

Leverage SwiftUI to build an immersive media experience in a multiplatform app.

Hello World

Use windows, volumes, and immersive spaces to teach people about the Earth.

Food Truck: Building a SwiftUI multiplatform app

Create a single codebase and app target for Mac, iPad, and iPhone.

Fruta: Building a Feature-Rich App with SwiftUI

Create a shared codebase to build a multiplatform app that offers widgets and an App Clip.

Migrating to the SwiftUI life cycle

Use a scene-based life cycle in SwiftUI while keeping your existing codebase.

`protocol App`

A type that represents the structure and behavior of an app.

---

# https://developer.apple.com/documentation/swiftui/food_truck_building_a_swiftui_multiplatform_app

- SwiftUI
- Food Truck: Building a SwiftUI multiplatform app

Sample Code

# Food Truck: Building a SwiftUI multiplatform app

Create a single codebase and app target for Mac, iPad, and iPhone.

Download

Xcode 14.3+

## Overview

Using the Food Truck app, someone who operates a food truck can keep track of orders, discover the most-popular menu items, and check the weather at their destination. The sample implements the new `NavigationSplitView` to manage the app’s views, Layout modifiers to show the main interface and pending orders, Swift Charts to show trends, and `WeatherService` to get weather data. Food Truck also implements Live Activities to show the remaining order preparation time with ActivityKit on the lock screen, and with `DynamicIsland` on the home screen.

You can access the source code for this sample on GitHub.

The Food Truck sample project contains two types of app targets:

- Simple app target you can build using personal team signing. This app runs in Simulator, and only requires a standard Apple ID to install on a device. It includes in-app purchase, and a widget extension that enable users to add a widget to their iOS Home Screen or the macOS Notification Center.

- Full-featured Food Truck All app target. The full app runs in Simulator, and on devices with an Apple Developer membership. It also allows you to create and sign in with passkeys.

### Configure the sample code project

To configure the Food Truck app without an Apple Developer account, follow these steps:

1. In the Food Truck target’s Signing & Capabilities panes click Add Account, and log in with your Apple ID.

2. Chose Your Name (Personal Team) from the team menu for the Food Truck and Widgets targets.

3. Build and run your app.

To configure the Food Truck All app to run on your devices, follow these steps:

1. Open the sample with Xcode 14.3 or later.

2. Select the top-level Food Truck project.

3. For all targets, choose your team from the Team menu in the Signing & Capabilities pane, so Xcode can automatically manage your provisioning profile.

4. Add the Associated Domains capability, and specify your domain with the `webcredentials` service. For more information about the `webcredentials` service, see `Associated Domains Entitlement`.

5. Ensure an `apple-app-site-association` (AASA) file is present on your domain, in the `.well-known` directory, and it contains an entry for this app’s App ID for the `webcredentials` service. For more information about the `apple-app-site-association` file, see Supporting associated domains.

6. In the `AccountManager.swift` file, replace all occurrences of `example.com` with the name of your domain.

### Create a multiplatform app

Food Truck is a multiplatform app, and there are no separate targets to run on macOS or iOS. Instead, there is only one app target that builds for macOS, iPadOS, and iOS.

### Define a default navigation destination

The sample’s navigation interface consists of a `NavigationSplitView` with a `Sidebar` view, and a `NavigationStack`:

NavigationSplitView {
Sidebar(selection: $selection)
} detail: {
NavigationStack(path: $path) {
DetailColumn(selection: $selection, model: model)
}
}

At app launch, the sample presents the `TruckView` as the default view. The `Panel` enum encodes the views the user can select in the sidebar, and hence appear in the detail view. The value corresponding to `TruckView` is `.truck`, and the app sets this to be the default selection.

@State private var selection: Panel? = Panel.truck

### Construct a dynamic layout

In the Truck view, the New Orders panel shows the five most-recent orders, and each order shows a `DonutStackView`, which is a diagonal stack of donut thumbnails. The Layout modifiers protocol allows the app to define a `DiagonalDonutStackLayout` that arranges the donut thumbnails into the diagonal layout. The layout’s `placeSubviews(in:proposal:subviews:cache:)` implementation calculates the donuts’ positions.

for index in subviews.indices {
switch (index, subviews.count) {
case (_, 1):
subviews[index].place(
at: center,
anchor: .center,
proposal: ProposedViewSize(size)
)

case (_, 2):
let direction = index == 0 ? -1.0 : 1.0
let offsetX = minBound * direction * 0.15
let offsetY = minBound * direction * 0.20
subviews[index].place(
at: CGPoint(x: center.x + offsetX, y: center.y + offsetY),
anchor: .center,
proposal: ProposedViewSize(CGSize(width: size.width * 0.7, height: size.height * 0.7))
)
case (1, 3):
subviews[index].place(
at: center,
anchor: .center,
proposal: ProposedViewSize(CGSize(width: size.width * 0.65, height: size.height * 0.65))
)

case (_, 3):
let direction = index == 0 ? -1.0 : 1.0
let offsetX = minBound * direction * 0.15
let offsetY = minBound * direction * 0.23
subviews[index].place(
at: CGPoint(x: center.x + offsetX, y: center.y + offsetY),
anchor: .center,
proposal: ProposedViewSize(CGSize(width: size.width * 0.7, height: size.height * 0.65))
)

### Display a chart of popular items

The sample contains several charts. The most popular items are shown on the `TopFiveDonutsView`. This chart is implemented in `TopDonutSalesChart`, which uses a `BarMark` to construct a bar chart.

Chart {
ForEach(sortedSales) { sale in
BarMark(
x: .value("Donut", sale.donut.name),
y: .value("Sales", sale.sales)
)
.cornerRadius(6, style: .continuous)
.foregroundStyle(.linearGradient(colors: [Color("BarBottomColor"), .accentColor], startPoint: .bottom, endPoint: .top))
.annotation(position: .top, alignment: .top) {
Text(sale.sales.formatted())
.padding(.vertical, 4)
.padding(.horizontal, 8)
.background(.quaternary.opacity(0.5), in: Capsule())
.background(in: Capsule())
.font(.caption)
}
}
}

The _x_ axis of the chart shows labels with the names and thumbnails of the items that correspond to each data point.

.chartXAxis {
AxisMarks { value in
AxisValueLabel {
let donut = donutFromAxisValue(for: value)
VStack {
DonutView(donut: donut)
.frame(height: 35)

Text(donut.name)
.lineLimit(2, reservesSpace: true)
.multilineTextAlignment(.center)
}
.frame(idealWidth: 80)
.padding(.horizontal, 4)

}
}
}

### Obtain a weather forecast

The app shows a forecasted temperature graph in the Forecast panel in the Truck view. The app obtains this data from the WeatherKit framework.

.task(id: city.id) {
for parkingSpot in city.parkingSpots {
do {
let weather = try await WeatherService.shared.weather(for: parkingSpot.location)
condition = weather.currentWeather.condition

cloudCover = weather.currentWeather.cloudCover
temperature = weather.currentWeather.temperature
symbolName = weather.currentWeather.symbolName

let attribution = try await WeatherService.shared.attribution
attributionLink = attribution.legalPageURL
attributionLogo = colorScheme == .light ? attribution.combinedMarkLightURL : attribution.combinedMarkDarkURL

if willRainSoon == false {
spot = parkingSpot
break
}
} catch {
print("Could not gather weather information...", error.localizedDescription)
condition = .clear
willRainSoon = false
cloudCover = 0.15
}
}
}

### Configure the project for WeatherKit

The data from the `WeatherService` instance in WeatherKit requires additional configuration for the Food Truck All target. If you don’t configure WeatherKit, the sample will detect an error and use static data in the project instead.

1. Create a unique App ID on the Provisioning Portal, and select the WeatherKit service on the App Services tab.

2. In Xcode, for the Food Truck All target on the Signing & Capabilities tab, change the bundle ID to be the same as the App ID from step 1, and add the WeatherKit capability.

3. For the Widgets target on the Signing & Capabilities tab, change the bundle ID to make the part before `.Widgets` the same as the bundle ID for the Food Truck All target.

4. Wait 30 minutes while the service registers your app’s bundle ID.

5. Build and run the Food Truck All target.

### Track preparation time with Live Activity

The app allows the food truck operator to keep track of order preparation time, which is guaranteed to be 60 seconds or less. To facilitate this, the app implements a toolbar button on the order details screen for orders with `placed` status. Tapping this button changes the order status to `preparing`, and creates an `Activity` instance to start a Live Activity, which shows the countdown timer and order details on an iPhone lock screen.

let timerSeconds = 60
let activityAttributes = TruckActivityAttributes(
orderID: String(order.id.dropFirst(6)),
order: order.donuts.map(\.id),
sales: order.sales,
activityName: "Order preparation activity."
)

let future = Date(timeIntervalSinceNow: Double(timerSeconds))

let initialContentState = TruckActivityAttributes.ContentState(timerRange: Date.now...future)

let activityContent = ActivityContent(state: initialContentState, staleDate: Calendar.current.date(byAdding: .minute, value: 2, to: Date())!)

do {

pushType: nil)
print(" Requested MyActivity live activity. ID: \(myActivity.id)")
postNotification()
} catch let error {
print("Error requesting live activity: \(error.localizedDescription)")
}

The app also implements `DynamicIsland` to show the same information as on the lock screen in the Dynamic Island on iPhone 14 Pro devices.

DynamicIsland {
DynamicIslandExpandedRegion(.leading) {
ExpandedLeadingView()
}

DynamicIslandExpandedRegion(.trailing, priority: 1) {
ExpandedTrailingView(orderNumber: context.attributes.orderID, timerInterval: context.state.timerRange)
.dynamicIsland(verticalPlacement: .belowIfTooWide)
}
} compactLeading: {
Image("IslandCompactIcon")
.padding(4)
.background(.indigo.gradient, in: ContainerRelativeShape())

} compactTrailing: {
Text(timerInterval: context.state.timerRange, countsDown: true)
.monospacedDigit()
.foregroundColor(Color("LightIndigo"))
.frame(width: 40)
} minimal: {
Image("IslandCompactIcon")
.padding(4)
.background(.indigo.gradient, in: ContainerRelativeShape())
}
.contentMargins(.trailing, 32, for: .expanded)
.contentMargins([.leading, .top, .bottom], 6, for: .compactLeading)
.contentMargins(.all, 6, for: .minimal)
.widgetURL(URL(string: "foodtruck://order/\(context.attributes.orderID)"))

Tapping the same button again changes the status to `complete`, and ends the Live Activity. This removes the Live Activity from the lock screen and from the Dynamic Island.

Task {

// Check if this is the activity associated with this order.
if activity.attributes.orderID == String(order.id.dropFirst(6)) {
await activity.end(nil, dismissalPolicy: .immediate)
}
}
}

---

# https://developer.apple.com/documentation/swiftui/migrating-to-the-swiftui-life-cycle)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/swiftui/app/body-swift.property)



---

# https://developer.apple.com/documentation/swiftui/app/main())



---

# https://developer.apple.com/documentation/swiftui/scene)



---

# https://developer.apple.com/documentation/swiftui/stateobject)



---

# https://developer.apple.com/documentation/swiftui/observedobject)



---

# https://developer.apple.com/documentation/swiftui/environmentobject)



---

# https://developer.apple.com/documentation/swiftui/app/body-swift.associatedtype)



---

# https://developer.apple.com/documentation/swiftui/app/init())



---

# https://developer.apple.com/documentation/swiftui/backyard-birds-sample)



---

# https://developer.apple.com/documentation/swiftui/food_truck_building_a_swiftui_multiplatform_app)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/swiftui/documentgroup

- SwiftUI
- DocumentGroup

Structure

# DocumentGroup

A scene that enables support for opening, creating, and saving documents.

## Mentioned in

Building and customizing the menu bar with SwiftUI

## Overview

Use a `DocumentGroup` scene to tell SwiftUI what kinds of documents your app can open when you declare your app using the `App` protocol.

Initialize a document group scene by passing in the document model and a view capable of displaying the document type. The document types you supply to `DocumentGroup` must conform to `FileDocument` or `ReferenceFileDocument`. SwiftUI uses the model to add document support to your app. In macOS this includes document-based menu support, including the ability to open multiple documents. On iOS this includes a document browser that can navigate to the documents stored on the file system and multiwindow support:

@main
struct MyApp: App {
var body: some Scene {
DocumentGroup(newDocument: TextFile()) { configuration in
ContentView(document: configuration.$document)
}
}
}

Any time the configuration changes, SwiftUI updates the contents with that new configuration, similar to other parameterized builders.

### Viewing documents

If your app only needs to display but not modify a specific document type, you can use the file viewer document group scene. You supply the file type of the document, and a view that displays the document type that you provide:

@main
struct MyApp: App {
var body: some Scene {
DocumentGroup(viewing: MyImageFormatDocument.self) {
MyImageFormatViewer(image: $0.document)
}
}
}

### Supporting multiple document types

Your app can support multiple document types by adding additional document group scenes:

@main
struct MyApp: App {
var body: some Scene {
DocumentGroup(newDocument: TextFile()) { group in
ContentView(document: group.$document)
}
DocumentGroup(viewing: MyImageFormatDocument.self) { group in
MyImageFormatViewer(image: group.document)
}
}
}

### Accessing the document’s URL

If your app needs to know the document’s URL, you can read it from the `editor` closure’s `configuration` parameter, along with the binding to the document. When you create a new document, the configuration’s `fileURL` property is `nil`. Every time it changes, it is passed over to the `DocumentGroup` builder in the updated `configuration`. This ensures that the view you define in the closure always knows the URL of the document it hosts.

@main
struct MyApp: App {
var body: some Scene {
DocumentGroup(newDocument: TextFile()) { configuration in
ContentView(
document: configuration.$document,
fileURL: configuration.fileURL
)
}
}
}

The URL can be used, for example, to present the file path of the file name in the user interface. Don’t access the document’s contents or metadata using the URL because that can conflict with the management of the file that SwiftUI performs. Instead, use the methods that `FileDocument` and `ReferenceFileDocument` provide to perform read and write operations.

## Topics

### Creating a document group

`init(newDocument:editor:)`

Creates a document group for creating and editing file documents.

`init(viewing:viewer:)`

Creates a document group capable of viewing file documents.

### Editing a document backed by a persistent store

`init(editing:contentType:editor:prepareDocument:)`

Instantiates a document group for creating and editing documents that store a specific model type.

Instantiates a document group for creating and editing documents described by the last `Schema` in the migration plan.

### Viewing a document backed by a persistent store

`init(viewing:contentType:viewer:)`

Instantiates a document group for viewing documents that store a specific model type.

Instantiates a document group for viewing documents described by the last `Schema` in the migration plan.

## Relationships

### Conforms To

- `Scene`

## See Also

### Creating a document

Building a document-based app with SwiftUI

Create, save, and open documents in a multiplatform app.

Building a document-based app using SwiftData

Code along with the WWDC presenter to transform an app with SwiftData.

---

# https://developer.apple.com/documentation/swiftui/filedocument

- SwiftUI
- FileDocument

Protocol

# FileDocument

A type that you use to serialize documents to and from file.

@preconcurrency
protocol FileDocument : Sendable

## Overview

To store a document as a value type — like a structure — create a type that conforms to the `FileDocument` protocol and implement the required methods and properties. Your implementation:

- Provides a list of the content types that the document can read from and write to by defining `readableContentTypes`. If the list of content types that the document can write to is different from those that it reads from, you can optionally also define `writableContentTypes`.

- Loads documents from file in the `init(configuration:)` initializer.

- Stores documents to file by serializing their content in the `fileWrapper(configuration:)` method.

Ensure that types that conform to this protocol are `Sendable`. In particular, SwiftUI calls the protocol’s methods from different isolation domains. Don’t perform serialization and deserialization on `MainActor`.

## Topics

### Reading a document

`init(configuration: Self.ReadConfiguration) throws`

Creates a document and initializes it with the contents of a file.

**Required**

[`static var readableContentTypes: [UTType]`](https://developer.apple.com/documentation/swiftui/filedocument/readablecontenttypes)

The file and data types that the document reads from.

`typealias ReadConfiguration`

The configuration for reading document contents.

### Writing a document

Serializes a document snapshot to a file wrapper.

[`static var writableContentTypes: [UTType]`](https://developer.apple.com/documentation/swiftui/filedocument/writablecontenttypes)

The file types that the document supports saving or exporting to.

**Required** Default implementation provided.

`typealias WriteConfiguration`

The configuration for writing document contents.

## Relationships

### Inherits From

- `Sendable`
- `SendableMetatype`

## See Also

### Storing document data in a structure instance

`struct FileDocumentConfiguration`

The properties of an open file document.

---

# https://developer.apple.com/documentation/swiftui/referencefiledocument

- SwiftUI
- ReferenceFileDocument

Protocol

# ReferenceFileDocument

A type that you use to serialize reference type documents to and from file.

@preconcurrency
protocol ReferenceFileDocument : ObservableObject, Sendable

## Overview

To store a document as a reference type — like a class — create a type that conforms to the `ReferenceFileDocument` protocol and implement the required methods and properties. Your implementation:

- Provides a list of the content types that the document can read from and write to by defining `readableContentTypes`. If the list of content types that the document can write to is different from those that it reads from, you can optionally also define `writableContentTypes`.

- Loads documents from file in the `init(configuration:)` initializer.

- Stores documents to file by providing a snapshot of the document’s content in the `snapshot(contentType:)` method, and then serializing that content in the `fileWrapper(snapshot:configuration:)` method.

Ensure that types that conform to this protocol are `Sendable`. In particular, SwiftUI calls the protocol’s methods from different isolation domains. Don’t perform serialization and deserialization on `MainActor`.

final class PDFDocument: ReferenceFileDocument {
struct Storage {
var contents: Data
}

static let readableContentTypes: [UTType] = [.pdf]

guard let data = configuration.file.regularFileContents else {
throw CocoaError(.fileReadCorruptFile)
}
self.storage = .init(.init(contents: data))
}

storage.withLock { $0.contents }
}

return FileWrapper(regularFileWithContents: snapshot)
}
}

## Topics

### Reading a document

`init(configuration: Self.ReadConfiguration) throws`

Creates a document and initializes it with the contents of a file.

**Required**

[`static var readableContentTypes: [UTType]`](https://developer.apple.com/documentation/swiftui/referencefiledocument/readablecontenttypes)

The file and data types that the document reads from.

`typealias ReadConfiguration`

The configuration for reading document contents.

### Getting a snapshot

Creates a snapshot that represents the current state of the document.

`associatedtype Snapshot`

A type that represents the document’s stored content.

### Writing a document

Serializes a document snapshot to a file wrapper.

[`static var writableContentTypes: [UTType]`](https://developer.apple.com/documentation/swiftui/referencefiledocument/writablecontenttypes)

The file types that the document supports saving or exporting to.

**Required** Default implementation provided.

`typealias WriteConfiguration`

The configuration for writing document contents.

## Relationships

### Inherits From

- `ObservableObject`
- `Sendable`
- `SendableMetatype`

## See Also

### Storing document data in a class instance

`struct ReferenceFileDocumentConfiguration`

The properties of an open reference file document.

`var undoManager: UndoManager?`

The undo manager used to register a view’s undo operations.

---

# https://developer.apple.com/documentation/swiftui/documentgroup/init(editing:contenttype:editor:preparedocument:)

#app-main)

- SwiftUI
- DocumentGroup
- init(editing:contentType:editor:prepareDocument:)

Initializer

# init(editing:contentType:editor:prepareDocument:)

Instantiates a document group for creating and editing documents that store a specific model type.

SwiftDataSwiftUI

init(
editing modelType: any PersistentModel.Type,
contentType: UTType,

)

Available when `Document` is `ModelDocument` and `Content` conforms to `View`.

Show all declarations

## Parameters

`modelType`

The model type defining the schema used for each document.

`contentType`

The content type of the document. It should conform to `UTType.package`.

`editor`

The editing UI for the provided document.

`prepareDocument`

The optional closure that accepts `ModelContext` associated with the new document. Use this closure to set the document’s initial contents before it is displayed: insert preconfigured models in the provided `ModelContext`.

## Discussion

@main
struct Todo: App {
var body: some Scene {
DocumentGroup(editing: TodoItem.self, contentType: .todoItem) {
ContentView()
}
}
}

struct ContentView: View {
@Query var items: [TodoItem]

var body: some View {
List {
ForEach(items) { item in
@Bindable var item = item
Toggle(item.text, isOn: $item.isDone)
}
}
}
}

@Model
final class TodoItem {
var created: Date
var text: String
var isDone = false
}

extension UTType {
static var todoItem = UTType(exportedAs: "com.myApp.todoItem")
}

## See Also

### Editing a document backed by a persistent store

Instantiates a document group for creating and editing documents described by the last `Schema` in the migration plan.

---

# https://developer.apple.com/documentation/swiftui/building-a-document-based-app-with-swiftui

- SwiftUI
- Documents
- Building a document-based app with SwiftUI

Sample Code

# Building a document-based app with SwiftUI

Create, save, and open documents in a multiplatform app.

Download

Xcode 16.0+

## Overview

The Writing App sample builds a document-based app for iOS, iPadOS, and macOS. In the app definition, it has a `DocumentGroup` scene, and its document type conforms to the `FileDocument` protocol. People can create a writing app document, modify the title and contents of the document, and read the story in focus mode.

## Configure the sample code project

To build and run this sample on your device, select your development team for the project’s target using these steps:

1. Open the sample with the latest version of Xcode.

2. Select the top-level project.

3. For the project’s target, choose your team from the Team pop-up menu in the Signing & Capabilities pane to let Xcode automatically manage your provisioning profile.

## Define the app’s scene

A document-based SwiftUI app returns a `DocumentGroup` scene from its `body` property. The `newDocument` parameter that an app supplies to the document group’s `init(newDocument:editor:)` initializer conforms to either `FileDocument` or `ReferenceFileDocument`. In this sample, the document type conforms to `FileDocument`. The trailing closure of the initializer returns a view that renders the document’s contents:

@main
struct WritingApp: App {
var body: some Scene {
DocumentGroup(newDocument: WritingAppDocument()) { file in
StoryView(document: file.$document)
}
}
}

## Customize the iOS and iPadOS launch experience

You can update the default launch experience on iOS and iPadOS with a custom title, action buttons, and screen background. To add an action button with a custom label, use `NewDocumentButton` to replace the default label. You can customize the background in many ways such as adding a view or a `backgroundStyle` with an initializer, for example `init(_:backgroundStyle:_:backgroundAccessoryView:overlayAccessoryView:)`. This sample customizes the background of the title view, using the `init(_:_:background:)` initializer:

DocumentGroupLaunchScene("Writing App") {
NewDocumentButton("Start Writing")
} background: {
Image(.pinkJungle)
.resizable()
.scaledToFill()
.ignoresSafeArea()
}

You can also add accessories to the scene using initializers such as `init(_:_:background:backgroundAccessoryView:)` and `init(_:_:background:overlayAccessoryView:)` depending on the positioning.

overlayAccessoryView: { _ in
AccessoryView()
}

This sample contains two accessories in the overlay position that it defines in `AccessoryView`. It customizes the accessories by applying modifiers, including `offset(x:y:)` and `frame(width:height:alignment:)`.

ZStack {
Image(.robot)
.resizable()
.offset(x: size.width / 2 - 450, y: size.height / 2 - 300)
.scaledToFit()
.frame(width: 200)
.opacity(horizontal == .compact ? 0 : 1)
Image(.plant)
.resizable()
.offset(x: size.width / 2 + 250, y: size.height / 2 - 225)
.scaledToFit()
.frame(width: 200)
.opacity(horizontal == .compact ? 0 : 1)
}

To add both background and overlay accessories, use an initializer, such as `init(_:_:background:backgroundAccessoryView:overlayAccessoryView:)`. If you don’t provide any accessories, the system displays two faded sheets below the title view by default. In macOS, this sample displays the default system document browser on launch. You may wish to add an additional experience on launch.

## Create the data model

This sample has a data model that defines a story as a `String`, it initializes `story` with an empty string:

var story: String

init(text: String = "") {
self.story = text
}

## Adopt the file document protocol

The `WritingAppDocument` structure adopts the `FileDocument` protocol to serialize documents to and from files. The `readableContentTypes` property defines the types that the sample can read and write, specifically, the `.writingAppDocument` type:

static var readableContentTypes: [UTType] { [.writingAppDocument] }

The `init(configuration:)` initializer loads documents from a file. After reading the file’s data using the `file` property of the `configuration` input, it deserializes the data and stores it in the document’s data model:

init(configuration: ReadConfiguration) throws {
guard let data = configuration.file.regularFileContents,
let string = String(data: data, encoding: .utf8)
else {
throw CocoaError(.fileReadCorruptFile)
}
story = string
}

When a person writes a document, SwiftUI calls the `fileWrapper(configuration:)` function to serialize the data model into a `FileWrapper` value that represents the data in the file system:

let data = Data(story.utf8)
return .init(regularFileWithContents: data)
}

Because the document type conforms to `FileDocument`, this sample handles undo actions automatically.

## Export a custom document type

The app defines and exports a custom content type for the documents it creates. It declares this custom type in the project’s `Information Property List` file under the `UTExportedTypeDeclarations` key. This sample uses `com.example.writingAppDocument` as the identifier in the `Info.plist` file:

For convenience, you can also define the content type in code. For example:

extension UTType {
static var writingapp: UTType {
UTType(exportedAs: "com.example.writingAppDocument")
}
}

To make sure that the operating system knows that your application can open files with the format described in the `Info.plist`, it defines the file extension `story` for the content type. For more information about custom file and data types, see Defining file and data types for your app.

## See Also

#### Related samples

Building a document-based app using SwiftData

Code along with the WWDC presenter to transform an app with SwiftData.

#### Related articles

Defining file and data types for your app

Declare uniform type identifiers to support your app’s proprietary data formats.

Customizing a document-based app’s launch experience

Add unique elements to your app’s document launch scene.

#### Related videos

![\\
\\
Evolve your document launch experience](https://developer.apple.com/videos/play/wwdc2024/10132)

---

# https://developer.apple.com/documentation/swiftui/building-a-document-based-app-using-swiftdata

- SwiftUI
- Documents
- Building a document-based app using SwiftData

Sample Code

# Building a document-based app using SwiftData

Code along with the WWDC presenter to transform an app with SwiftData.

Download

Xcode 15.0+

## Overview

Learn how to use `@Query`, `@Bindable`, `.modelContainer`, the `.modelContext` environment variable, and `DocumentGroup` to integrate with the `SwiftData` framework.

## See Also

### Creating a document

Building a document-based app with SwiftUI

Create, save, and open documents in a multiplatform app.

`struct DocumentGroup`

A scene that enables support for opening, creating, and saving documents.

---

# https://developer.apple.com/documentation/swiftui/filedocumentconfiguration

- SwiftUI
- FileDocumentConfiguration

Structure

# FileDocumentConfiguration

The properties of an open file document.

## Overview

You receive an instance of this structure when you create a `DocumentGroup` with a value file type. Use it to access the document in your viewer or editor.

## Topics

### Getting and setting the document

`var document: Document`

The current document model.

### Getting document properties

`var fileURL: URL?`

The URL of the open file document.

`var isEditable: Bool`

A Boolean that indicates whether you can edit the document.

## See Also

### Storing document data in a structure instance

`protocol FileDocument`

A type that you use to serialize documents to and from file.

---

# https://developer.apple.com/documentation/swiftui/referencefiledocumentconfiguration

- SwiftUI
- ReferenceFileDocumentConfiguration

Structure

# ReferenceFileDocumentConfiguration

The properties of an open reference file document.

@MainActor @preconcurrency

## Overview

You receive an instance of this structure when you create a `DocumentGroup` with a reference file type. Use it to access the document in your viewer or editor.

## Topics

### Getting and setting the document

`var document: Document`

The current document model.

### Getting document properties

`var fileURL: URL?`

The URL of the open file document.

`var isEditable: Bool`

A Boolean that indicates whether you can edit the document.

## See Also

### Storing document data in a class instance

`protocol ReferenceFileDocument`

A type that you use to serialize reference type documents to and from file.

`var undoManager: UndoManager?`

The undo manager used to register a view’s undo operations.

---

# https://developer.apple.com/documentation/swiftui/environmentvalues/undomanager

- SwiftUI
- EnvironmentValues
- undoManager

Instance Property

# undoManager

The undo manager used to register a view’s undo operations.

var undoManager: UndoManager? { get }

## Discussion

This value is `nil` when the environment represents a context that doesn’t support undo and redo operations. You can skip registration of an undo operation when this value is `nil`.

## See Also

### Storing document data in a class instance

`protocol ReferenceFileDocument`

A type that you use to serialize reference type documents to and from file.

`struct ReferenceFileDocumentConfiguration`

The properties of an open reference file document.

---

# https://developer.apple.com/documentation/swiftui/environmentvalues/documentconfiguration

- SwiftUI
- EnvironmentValues
- documentConfiguration

Instance Property

# documentConfiguration

The configuration of a document in a `DocumentGroup`.

var documentConfiguration: DocumentConfiguration? { get }

## Discussion

The value is `nil` for views that are not enclosed in a `DocumentGroup`.

For example, if the app shows the document path in the footer of each document, it can get the URL from the environment:

struct ContentView: View {
@Binding var document: TextDocument
@Environment(\.documentConfiguration) private var configuration: DocumentConfiguration?

var body: some View {
…
Label(
configuration?.fileURL?.path ??
"", systemImage: "folder.circle"
)
}
}

## See Also

### Accessing document configuration

`struct DocumentConfiguration`

---

# https://developer.apple.com/documentation/swiftui/documentconfiguration

- SwiftUI
- DocumentConfiguration

Structure

# DocumentConfiguration

struct DocumentConfiguration

## Topics

### Getting configuration values

`var fileURL: URL?`

A URL of an open document.

`var isEditable: Bool`

A Boolean value that indicates whether you can edit the document.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`

## See Also

### Accessing document configuration

`var documentConfiguration: DocumentConfiguration?`

The configuration of a document in a `DocumentGroup`.

---

# https://developer.apple.com/documentation/swiftui/filedocumentreadconfiguration

- SwiftUI
- FileDocumentReadConfiguration

Structure

# FileDocumentReadConfiguration

The configuration for reading file contents.

struct FileDocumentReadConfiguration

## Topics

### Reading the content

`let contentType: UTType`

The expected uniform type of the file contents.

`let file: FileWrapper`

The file wrapper containing the document content.

## See Also

### Reading and writing documents

`struct FileDocumentWriteConfiguration`

The configuration for serializing file contents.

---

# https://developer.apple.com/documentation/swiftui/filedocumentwriteconfiguration

- SwiftUI
- FileDocumentWriteConfiguration

Structure

# FileDocumentWriteConfiguration

The configuration for serializing file contents.

struct FileDocumentWriteConfiguration

## Topics

### Writing the content

`let contentType: UTType`

The expected uniform type of the file contents.

`let existingFile: FileWrapper?`

The file wrapper containing the current document content. `nil` if the document is unsaved.

## See Also

### Reading and writing documents

`struct FileDocumentReadConfiguration`

The configuration for reading file contents.

---

# https://developer.apple.com/documentation/swiftui/environmentvalues/newdocument

- SwiftUI
- EnvironmentValues
- newDocument

Instance Property

# newDocument

An action in the environment that presents a new document.

var newDocument: NewDocumentAction { get }

## Discussion

Use the `newDocument` environment value to get the instance of the `NewDocumentAction` structure for a given `Environment`. Then call the instance to present a new document. You call the instance directly because it defines a `callAsFunction(_:)` method that Swift calls when you call the instance.

For example, you can define a button that creates a new document from the selected text:

struct NewDocumentFromSelection: View {
@FocusedBinding(\.selectedText) private var selectedText: String?
@Environment(\.newDocument) private var newDocument

var body: some View {
Button("New Document With Selection") {
newDocument(TextDocument(text: selectedText))
}
.disabled(selectedText?.isEmpty != false)
}
}

The above example assumes that you define a `TextDocument` that conforms to the `FileDocument` or `ReferenceFileDocument` protocol, and a `DocumentGroup` that handles the associated file type.

## See Also

### Opening a document programmatically

`struct NewDocumentAction`

An action that presents a new document.

`var openDocument: OpenDocumentAction`

An action in the environment that presents an existing document.

`struct OpenDocumentAction`

An action that presents an existing document.

---

# https://developer.apple.com/documentation/swiftui/newdocumentaction

- SwiftUI
- NewDocumentAction

Structure

# NewDocumentAction

An action that presents a new document.

@MainActor @preconcurrency
struct NewDocumentAction

## Overview

Use the `newDocument` environment value to get the instance of this structure for a given `Environment`. Then call the instance to present a new document. You call the instance directly because it defines a `callAsFunction(_:)` method that Swift calls when you call the instance.

For example, you can define a button that creates a new document from the selected text:

struct NewDocumentFromSelection: View {
@FocusedBinding(\.selectedText) private var selectedText: String?
@Environment(\.newDocument) private var newDocument

var body: some View {
Button("New Document With Selection") {
newDocument(TextDocument(text: selectedText))
}
.disabled(selectedText?.isEmpty != false)
}
}

The above example assumes that you define a `TextDocument` that conforms to the `FileDocument` or `ReferenceFileDocument` protocol, and a `DocumentGroup` that handles the associated file type.

## Topics

### Calling the action

`func callAsFunction(_:)`

Presents a new document window.

`func callAsFunction(contentType: UTType)`

Presents a new document window with preset contents.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`

## See Also

### Opening a document programmatically

`var newDocument: NewDocumentAction`

An action in the environment that presents a new document.

`var openDocument: OpenDocumentAction`

An action in the environment that presents an existing document.

`struct OpenDocumentAction`

An action that presents an existing document.

---

# https://developer.apple.com/documentation/swiftui/environmentvalues/opendocument

- SwiftUI
- EnvironmentValues
- openDocument

Instance Property

# openDocument

An action in the environment that presents an existing document.

var openDocument: OpenDocumentAction { get }

## Discussion

Use the `openDocument` environment value to get the instance of the `OpenDocumentAction` structure for a given `Environment`. Then call the instance to present an existing document. You call the instance directly because it defines a `callAsFunction(at:)` method that Swift calls when you call the instance.

For example, you can create a button that opens the document at the specified URL:

struct OpenDocumentButton: View {
var url: URL
@Environment(\.openDocument) private var openDocument

var body: some View {
Button(url.deletingPathExtension().lastPathComponent) {
Task {
do {
try await openDocument(at: url)
} catch {
// Handle error
}
}
}
}
}

The above example uses a `do-catch` statement to handle any errors that the open document action might throw. It also places the action inside a task and awaits the result because the action operates asynchronously.

To present an existing document, your app must define a `DocumentGroup` that handles the content type of the specified file. For a document that’s already open, the system brings the existing window to the front. Otherwise, the system opens a new window.

## See Also

### Opening a document programmatically

`var newDocument: NewDocumentAction`

An action in the environment that presents a new document.

`struct NewDocumentAction`

An action that presents a new document.

`struct OpenDocumentAction`

An action that presents an existing document.

---

# https://developer.apple.com/documentation/swiftui/opendocumentaction

- SwiftUI
- OpenDocumentAction

Structure

# OpenDocumentAction

An action that presents an existing document.

@MainActor
struct OpenDocumentAction

## Overview

Use the `openDocument` environment value to get the instance of this structure for a given `Environment`. Then call the instance to present an existing document. You call the instance directly because it defines a `callAsFunction(at:)` method that Swift calls when you call the instance.

For example, you can create a button that opens the document at the specified URL:

struct OpenDocumentButton: View {
var url: URL
@Environment(\.openDocument) private var openDocument

var body: some View {
Button(url.deletingPathExtension().lastPathComponent) {
Task {
do {
try await openDocument(at: url)
} catch {
// Handle error
}
}
}
}
}

The above example uses a `do-catch` statement to handle any errors that the open document action might throw. It also places the action inside a task and awaits the result because the action operates asynchronously.

To present an existing document, your app must define a `DocumentGroup` that handles the content type of the specified file. For a document that’s already open, the system brings the existing window to the front. Otherwise, the system opens a new window.

## Topics

### Calling the action

`func callAsFunction(at: URL) async throws`

Opens the document at the specified file URL.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`

## See Also

### Opening a document programmatically

`var newDocument: NewDocumentAction`

An action in the environment that presents a new document.

`struct NewDocumentAction`

An action that presents a new document.

`var openDocument: OpenDocumentAction`

An action in the environment that presents an existing document.

---

# https://developer.apple.com/documentation/swiftui/documentgrouplaunchscene

- SwiftUI
- DocumentGroupLaunchScene

Structure

# DocumentGroupLaunchScene

A launch scene for document-based applications.

## Overview

You can use this launch scene alongside `DocumentGroup` scenes. If you don’t implement a `DocumentGroup` in the app declaration, you can get the same design by implementing a `DocumentLaunchView`.

If you don’t provide the title of the scene, it displays the application name. If you don’t provide the actions builder, the scene has the default “Create Document” action that creates new documents. To customize the document launch experience, you can replace the standard screen background and title, add decorative views, and add custom actions.

A `DocumentGroupLaunchScene` configures the document browser on the bottom sheet to open content types from all the document groups in the app definition. A `DocumentGroupLaunchScene` also configures the document groups to create documents of the first content type that your application can create and write.

For more information, see `FileDocument.writableContentTypes` and `ReferenceFileDocument.writableContentTypes`.

## Topics

### Initializers

`init(_:_:background:)`

Creates a launch scene for document-based applications with a title, a set of actions, and a background.

`init(_:_:background:backgroundAccessoryView:)`

Creates a launch scene for document-based applications with a title, a set of actions, a background, and a background accessory view.

`init(_:_:background:backgroundAccessoryView:overlayAccessoryView:)`

`init(_:_:background:overlayAccessoryView:)`

Creates a launch scene for document-based applications with a title, a set of actions, a background, and an overlay accessory view.

`init(_:backgroundStyle:_:)`

Creates a launch scene for document-based applications with a title, a background style, and a set of actions.

`init(_:backgroundStyle:_:backgroundAccessoryView:)`

Creates a launch scene for document-based applications with a title, a background style, a set of actions, and a background accessory view.

`init(_:backgroundStyle:_:backgroundAccessoryView:overlayAccessoryView:)`

Creates a launch scene for document-based applications with a title, a background style, a set of actions, and background and overlay accessory views.

`init(_:backgroundStyle:_:overlayAccessoryView:)`

Creates a launch scene for document-based applications with a title, a background style, a set of actions, and an overlay accessory view.

## Relationships

### Conforms To

- `Scene`

## See Also

### Configuring the document launch experience

`struct DocumentLaunchView`

A view to present when launching document-related user experience.

`struct DocumentLaunchGeometryProxy`

A proxy for access to the frame of the scene and its title view.

`struct DefaultDocumentGroupLaunchActions`

The default actions for the document group launch scene and the document launch view.

`struct NewDocumentButton`

A button that creates and opens new documents.

`protocol DocumentBaseBox`

A Box that allows setting its Document base not requiring the caller to know the exact types of the box and its base.

---

# https://developer.apple.com/documentation/swiftui/documentlaunchview

- SwiftUI
- DocumentLaunchView

Structure

# DocumentLaunchView

A view to present when launching document-related user experience.

## Overview

Configure `DocumentLaunchView` to open and display files and trigger custom actions.

For example, an application that offers writing books can present the `DocumentLaunchView` as its launch view:

public import UniformTypeIdentifiers

struct BookEditorLaunchView: View {

var body: some View {
DocumentLaunchView(for: [.book]) {
NewDocumentButton("Start New Book")
} onDocumentOpen: { url in
BookEditor(url)
}
}
}

struct BookEditor: View {
init(_ url: URL) { }
}

extension UTType {
static var book = UTType(exportedAs: "com.example.bookEditor")
}

## Topics

### Initializers

`init(_:for:_:onDocumentOpen:)`

Creates a view to present when launching document-related user experiences using a localized title and custom actions.

`init(_:for:_:onDocumentOpen:background:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, and a background view.

`init(_:for:_:onDocumentOpen:background:backgroundAccessoryView:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, a background view, and a background accessory view.

`init(_:for:_:onDocumentOpen:background:backgroundAccessoryView:overlayAccessoryView:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, a background view, and accessory views.

`init(_:for:_:onDocumentOpen:background:overlayAccessoryView:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, a background view, and an overlay accessory view.

`init(_:for:_:onDocumentOpen:backgroundAccessoryView:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, and a background accessory view.

`init(_:for:_:onDocumentOpen:backgroundAccessoryView:overlayAccessoryView:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, and accessory views.

`init(_:for:_:onDocumentOpen:overlayAccessoryView:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, and an overlay accessory view.

`init(_:for:backgroundStyle:_:onDocumentOpen:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, and a background style.

`init(_:for:backgroundStyle:_:onDocumentOpen:backgroundAccessoryView:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, a background style, and a background accessory view.

`init(_:for:backgroundStyle:_:onDocumentOpen:backgroundAccessoryView:overlayAccessoryView:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, a background style, and accessory views.

`init(_:for:backgroundStyle:_:onDocumentOpen:overlayAccessoryView:)`

Creates a view to present when launching document-related user experiences using a localized title, custom actions, a background style, and an overlay accessory view.

### Instance Properties

`var body: some View`

The body of the view.

## Relationships

### Conforms To

- `View`

## See Also

### Configuring the document launch experience

`struct DocumentGroupLaunchScene`

A launch scene for document-based applications.

`struct DocumentLaunchGeometryProxy`

A proxy for access to the frame of the scene and its title view.

`struct DefaultDocumentGroupLaunchActions`

The default actions for the document group launch scene and the document launch view.

`struct NewDocumentButton`

A button that creates and opens new documents.

`protocol DocumentBaseBox`

A Box that allows setting its Document base not requiring the caller to know the exact types of the box and its base.

---

# https://developer.apple.com/documentation/swiftui/documentlaunchgeometryproxy

- SwiftUI
- DocumentLaunchGeometryProxy

Structure

# DocumentLaunchGeometryProxy

A proxy for access to the frame of the scene and its title view.

struct DocumentLaunchGeometryProxy

## Topics

### Instance Properties

`var frame: CGRect`

Frame of the document launch interface.

`var titleViewFrame: CGRect`

Frame of the title view within the interface.

## See Also

### Configuring the document launch experience

`struct DocumentGroupLaunchScene`

A launch scene for document-based applications.

`struct DocumentLaunchView`

A view to present when launching document-related user experience.

`struct DefaultDocumentGroupLaunchActions`

The default actions for the document group launch scene and the document launch view.

`struct NewDocumentButton`

A button that creates and opens new documents.

`protocol DocumentBaseBox`

A Box that allows setting its Document base not requiring the caller to know the exact types of the box and its base.

---

# https://developer.apple.com/documentation/swiftui/defaultdocumentgrouplaunchactions

- SwiftUI
- DefaultDocumentGroupLaunchActions

Structure

# DefaultDocumentGroupLaunchActions

The default actions for the document group launch scene and the document launch view.

struct DefaultDocumentGroupLaunchActions

## Overview

This `View` populates `DocumentGroupLaunchScene` and `DocumentLaunchView` with the default actions.

## Topics

### Initializers

`init()`

## Relationships

### Conforms To

- `View`

## See Also

### Configuring the document launch experience

`struct DocumentGroupLaunchScene`

A launch scene for document-based applications.

`struct DocumentLaunchView`

A view to present when launching document-related user experience.

`struct DocumentLaunchGeometryProxy`

A proxy for access to the frame of the scene and its title view.

`struct NewDocumentButton`

A button that creates and opens new documents.

`protocol DocumentBaseBox`

A Box that allows setting its Document base not requiring the caller to know the exact types of the box and its base.

---

# https://developer.apple.com/documentation/swiftui/newdocumentbutton

- SwiftUI
- NewDocumentButton

Structure

# NewDocumentButton

A button that creates and opens new documents.

## Overview

Use a new document button to give people the option to create documents in your app. In the following example, there are two new document buttons, both support `Text` labels. When the user taps or clicks the first button, the system creates a new document in the directory currently open in the document browser. The second button creates a new document from a template.

@State private var isTemplatePickerPresented = false
@State private var documentCreationContinuation:

var body: some Scene {
DocumentGroupLaunchScene("My Documents") {
NewDocumentButton("Start Writing…")
NewDocumentButton("Choose a Template", for: MyDocument.self) {
try await withCheckedThrowingContinuation { continuation in
documentCreationContinuation = continuation
isTemplatePickerPresented = true
}
}
.fullScreenCover(isPresented: $isTemplatePickerPresented) {
TemplatePicker(continuation: $documentCreationContinuation)
}
}
}

If you don’t provide a custom label, the system provides a button with the default “Create Document” label.

## Topics

### Initializers

`init(_:contentType:)`

Creates and opens new documents.

`init(_:contentType:prepareDocumentURL:)`

`init(_:for:contentType:prepareDocument:)`

## Relationships

### Conforms To

- `View`

## See Also

### Configuring the document launch experience

`struct DocumentGroupLaunchScene`

A launch scene for document-based applications.

`struct DocumentLaunchView`

A view to present when launching document-related user experience.

`struct DocumentLaunchGeometryProxy`

A proxy for access to the frame of the scene and its title view.

`struct DefaultDocumentGroupLaunchActions`

The default actions for the document group launch scene and the document launch view.

`protocol DocumentBaseBox`

A Box that allows setting its Document base not requiring the caller to know the exact types of the box and its base.

---

# https://developer.apple.com/documentation/swiftui/documentbasebox

- SwiftUI
- DocumentBaseBox

Protocol

# DocumentBaseBox

A Box that allows setting its Document base not requiring the caller to know the exact types of the box and its base.

## Topics

### Associated Types

`associatedtype Document`

The underlying document type.

**Required**

### Instance Properties

`var base: Self.Document?`

Updates the underlying document to a new value.

## See Also

### Configuring the document launch experience

`struct DocumentGroupLaunchScene`

A launch scene for document-based applications.

`struct DocumentLaunchView`

A view to present when launching document-related user experience.

`struct DocumentLaunchGeometryProxy`

A proxy for access to the frame of the scene and its title view.

`struct DefaultDocumentGroupLaunchActions`

The default actions for the document group launch scene and the document launch view.

`struct NewDocumentButton`

A button that creates and opens new documents.

---

# https://developer.apple.com/documentation/swiftui/renamebutton

- SwiftUI
- RenameButton

Structure

# RenameButton

A button that triggers a standard rename action.

## Overview

A rename button receives its action from the environment. Use the `renameAction(_:)` modifier to set the action. The system disables the button if you don’t define an action.

struct RowView: View {
@State private var text = ""
@FocusState private var isFocused: Bool

var body: some View {
TextField(text: $item.name) {
Text("Prompt")
}
.focused($isFocused)
.contextMenu {
RenameButton()
// ... your own custom actions
}
.renameAction { $isFocused = true }
}

When someone taps the rename button in the context menu, the rename action focuses the text field by setting the `isFocused` property to true.

You can use this button inside of a navigation title menu and the navigation title modifier automatically configures the environment with the appropriate rename action.

ContentView()
.navigationTitle($contentTitle) {
// ... your own custom actions
RenameButton()
}

## Topics

### Creating an rename button

`init()`

Creates a rename button.

## Relationships

### Conforms To

- `View`

## See Also

### Creating special-purpose buttons

`struct EditButton`

A button that toggles the edit mode environment value.

`struct PasteButton`

A system button that reads items from the pasteboard and delivers it to a closure.

---

# https://developer.apple.com/documentation/swiftui/view/renameaction(_:)

#app-main)

- SwiftUI
- View
- renameAction(\_:)

Instance Method

# renameAction(\_:)

Sets a closure to run for the rename action.

nonisolated

Show all declarations

## Parameters

`action`

A closure to run when renaming.

## Return Value

A view that has the specified rename action.

## Discussion

Use this modifier in conjunction with the `RenameButton` to implement standard rename interactions. A rename button receives its action from the environment. Use this modifier to customize the action provided to the rename button.

struct RowView: View {
@State private var text = ""
@FocusState private var isFocused: Bool

var body: some View {
TextField(text: $item.name) {
Text("Prompt")
}
.focused($isFocused)
.contextMenu {
RenameButton()
// ... your own custom actions
}
.renameAction { isFocused = true }
}

When the user taps the rename button in the context menu, the rename action focuses the text field by setting the `isFocused` property to true.

## See Also

### Renaming a document

`struct RenameButton`

A button that triggers a standard rename action.

`var rename: RenameAction?`

An action that activates the standard rename interaction.

`struct RenameAction`

An action that activates a standard rename interaction.

---

# https://developer.apple.com/documentation/swiftui/environmentvalues/rename

- SwiftUI
- EnvironmentValues
- rename

Instance Property

# rename

An action that activates the standard rename interaction.

var rename: RenameAction? { get }

## Discussion

Use the `renameAction(_:)` modifier to configure the rename action in the environment.

## See Also

### Renaming a document

`struct RenameButton`

A button that triggers a standard rename action.

`func renameAction(_:)`

Sets a closure to run for the rename action.

`struct RenameAction`

An action that activates a standard rename interaction.

---

# https://developer.apple.com/documentation/swiftui/renameaction

- SwiftUI
- RenameAction

Structure

# RenameAction

An action that activates a standard rename interaction.

struct RenameAction

## Overview

Use the `renameAction(_:)` modifier to configure the rename action in the environment.

## Topics

### Calling the action

`func callAsFunction()`

Triggers the standard rename action provided through the environment.

## See Also

### Renaming a document

`struct RenameButton`

A button that triggers a standard rename action.

`func renameAction(_:)`

Sets a closure to run for the rename action.

`var rename: RenameAction?`

An action that activates the standard rename interaction.

---

# https://developer.apple.com/documentation/swiftui/documentgroup)



---

# https://developer.apple.com/documentation/swiftui/filedocument)



---

# https://developer.apple.com/documentation/swiftui/referencefiledocument)



---

# https://developer.apple.com/documentation/swiftui/documentgroup/init(editing:contenttype:editor:preparedocument:)).

).#app-main)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/swiftui/building-a-document-based-app-using-swiftdata)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/swiftui/filedocumentconfiguration)



---

# https://developer.apple.com/documentation/swiftui/referencefiledocumentconfiguration)



---

# https://developer.apple.com/documentation/swiftui/environmentvalues/undomanager)



---

# https://developer.apple.com/documentation/swiftui/environmentvalues/documentconfiguration)

# The page you're looking for can't be found.

Search developer.apple.comSearch Icon

---

# https://developer.apple.com/documentation/swiftui/documentgroup).



---

# https://developer.apple.com/documentation/swiftui/documentconfiguration)



---

# https://developer.apple.com/documentation/swiftui/filedocumentreadconfiguration)



---

# https://developer.apple.com/documentation/swiftui/filedocumentwriteconfiguration)



---

# https://developer.apple.com/documentation/swiftui/environmentvalues/newdocument)



---

# https://developer.apple.com/documentation/swiftui/newdocumentaction)



---

# https://developer.apple.com/documentation/swiftui/environmentvalues/opendocument)



---

# https://developer.apple.com/documentation/swiftui/opendocumentaction)



---

# https://developer.apple.com/documentation/swiftui/documentgrouplaunchscene)



---

# https://developer.apple.com/documentation/swiftui/documentlaunchview)



---

# https://developer.apple.com/documentation/swiftui/documentlaunchgeometryproxy)



---

# https://developer.apple.com/documentation/swiftui/defaultdocumentgrouplaunchactions)



---

# https://developer.apple.com/documentation/swiftui/newdocumentbutton)



---

# https://developer.apple.com/documentation/swiftui/documentbasebox)



---

# https://developer.apple.com/documentation/swiftui/renamebutton)



---

# https://developer.apple.com/documentation/swiftui/view/renameaction(_:))



---

# https://developer.apple.com/documentation/swiftui/environmentvalues/rename)



---

# https://developer.apple.com/documentation/swiftui/renameaction)



---

# https://developer.apple.com/documentation/swiftui/uiapplicationdelegateadaptor

- SwiftUI
- UIApplicationDelegateAdaptor

Structure

# UIApplicationDelegateAdaptor

A property wrapper type that you use to create a UIKit app delegate.

@MainActor @preconcurrency @propertyWrapper

## Mentioned in

Migrating to the SwiftUI life cycle

## Overview

To handle app delegate callbacks in an app that uses the SwiftUI life cycle, define a type that conforms to the `UIApplicationDelegate` protocol, and implement the delegate methods that you need. For example, you can implement the `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` method to handle remote notification registration:

class MyAppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
func application(
_ application: UIApplication,
didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
// Record the device token.
}
}

Then use the `UIApplicationDelegateAdaptor` property wrapper inside your `App` declaration to tell SwiftUI about the delegate type:

@main
struct MyApp: App {
@UIApplicationDelegateAdaptor private var appDelegate: MyAppDelegate

var body: some Scene { ... }
}

SwiftUI instantiates the delegate and calls the delegate’s methods in response to life cycle events. Define the delegate adaptor only in your `App` declaration, and only once for a given app. If you declare it more than once, SwiftUI generates a runtime error.

If your app delegate conforms to the `ObservableObject` protocol, as in the example above, then SwiftUI puts the delegate it creates into the `Environment`. You can access the delegate from any scene or view in your app using the `EnvironmentObject` property wrapper:

@EnvironmentObject private var appDelegate: MyAppDelegate

This enables you to use the dollar sign ( `$`) prefix to get a binding to published properties that you declare in the delegate. For more information, see `projectedValue`.

### Scene delegates

Some iOS apps define a `UIWindowSceneDelegate` to handle scene-based events, like app shortcuts:

class MySceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
func windowScene(
_ windowScene: UIWindowScene,
performActionFor shortcutItem: UIApplicationShortcutItem

// Do something with the shortcut...

return true
}
}

You can provide this kind of delegate to a SwiftUI app by returning the scene delegate’s type from the `application(_:configurationForConnecting:options:)` method inside your app delegate:

extension MyAppDelegate {
func application(
_ application: UIApplication,
configurationForConnecting connectingSceneSession: UISceneSession,
options: UIScene.ConnectionOptions

let configuration = UISceneConfiguration(
name: nil,
sessionRole: connectingSceneSession.role)
if connectingSceneSession.role == .windowApplication {
configuration.delegateClass = MySceneDelegate.self
}
return configuration
}
}

When you configure the `UISceneConfiguration` instance, you only need to indicate the delegate class, and not a scene class or storyboard. SwiftUI creates and manages the delegate instance, and sends it any relevant delegate callbacks.

As with the app delegate, if you make your scene delegate an observable object, SwiftUI automatically puts it in the `Environment`, from where you can access it with the `EnvironmentObject` property wrapper, and create bindings to its published properties.

## Topics

### Creating a delegate adaptor

`init(_:)`

Creates a UIKit app delegate adaptor using an observable delegate.

### Getting the delegate adaptor

A projection of the observed object that provides bindings to its properties.

`var wrappedValue: DelegateType`

The underlying app delegate.

## Relationships

### Conforms To

- `DynamicProperty`
- `Sendable`
- `SendableMetatype`

## See Also

### Targeting iOS and iPadOS

`UILaunchScreen`

The user interface to show while an app launches.

`UILaunchScreens`

The user interfaces to show while an app launches in response to different URL schemes.

---

# https://developer.apple.com/documentation/swiftui/nsapplicationdelegateadaptor

- SwiftUI
- NSApplicationDelegateAdaptor

Structure

# NSApplicationDelegateAdaptor

A property wrapper type that you use to create an AppKit app delegate.

@MainActor @preconcurrency @propertyWrapper

## Mentioned in

Migrating to the SwiftUI life cycle

## Overview

To handle app delegate callbacks in an app that uses the SwiftUI life cycle, define a type that conforms to the `NSApplicationDelegate` protocol, and implement the delegate methods that you need. For example, you can implement the `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` method to handle remote notification registration:

class MyAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
func application(
_ application: NSApplication,
didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
// Record the device token.
}
}

Then use the `NSApplicationDelegateAdaptor` property wrapper inside your `App` declaration to tell SwiftUI about the delegate type:

@main
struct MyApp: App {
@NSApplicationDelegateAdaptor private var appDelegate: MyAppDelegate

var body: some Scene { ... }
}

SwiftUI instantiates the delegate and calls the delegate’s methods in response to life cycle events. Define the delegate adaptor only in your `App` declaration, and only once for a given app. If you declare it more than once, SwiftUI generates a runtime error.

If your app delegate conforms to the `ObservableObject` protocol, as in the example above, then SwiftUI puts the delegate it creates into the `Environment`. You can access the delegate from any scene or view in your app using the `EnvironmentObject` property wrapper:

@EnvironmentObject private var appDelegate: MyAppDelegate

This enables you to use the dollar sign ( `$`) prefix to get a binding to published properties that you declare in the delegate. For more information, see `projectedValue`.

## Topics

### Creating a delegate adaptor

`init(_:)`

Creates an AppKit app delegate adaptor using an observable delegate.

### Getting the delegate adaptor

A projection of the observed object that provides bindings to its properties.

`var wrappedValue: DelegateType`

The underlying delegate.

## Relationships

### Conforms To

- `DynamicProperty`
- `Sendable`
- `SendableMetatype`

---

# https://developer.apple.com/documentation/swiftui/wkapplicationdelegateadaptor

- SwiftUI
- WKApplicationDelegateAdaptor

Structure

# WKApplicationDelegateAdaptor

A property wrapper that is used in `App` to provide a delegate from WatchKit.

@MainActor @preconcurrency @propertyWrapper

## Mentioned in

Migrating to the SwiftUI life cycle

## Topics

### Creating a delegate adaptor

`init(_:)`

Creates an `WKApplicationDelegateAdaptor` using a WatchKit Application Delegate.

### Getting the delegate adaptor

A projection of the observed object that creates bindings to its properties using dynamic member lookup.

`var wrappedValue: DelegateType`

The underlying delegate.

## Relationships

### Conforms To

- `DynamicProperty`
- `Sendable`
- `SendableMetatype`

## See Also

### Targeting watchOS

`struct WKExtensionDelegateAdaptor`

A property wrapper type that you use to create a WatchKit extension delegate.

---

# https://developer.apple.com/documentation/swiftui/wkextensiondelegateadaptor

- SwiftUI
- WKExtensionDelegateAdaptor

Structure

# WKExtensionDelegateAdaptor

A property wrapper type that you use to create a WatchKit extension delegate.

@MainActor @preconcurrency @propertyWrapper

## Overview

To handle extension delegate callbacks in an extension that uses the SwiftUI life cycle, define a type that conforms to the `WKExtensionDelegate` protocol, and implement the delegate methods that you need. For example, you can implement the `didRegisterForRemoteNotifications(withDeviceToken:)` method to handle remote notification registration:

class MyExtensionDelegate: NSObject, WKExtensionDelegate, ObservableObject {
func didRegisterForRemoteNotifications(withDeviceToken: Data) {
// Record the device token.
}
}

Then use the `WKExtensionDelegateAdaptor` property wrapper inside your `App` declaration to tell SwiftUI about the delegate type:

@main
struct MyApp: App {
@WKExtensionDelegateAdaptor private var extensionDelegate: MyExtensionDelegate

var body: some Scene { ... }
}

SwiftUI instantiates the delegate and calls the delegate’s methods in response to life cycle events. Define the delegate adaptor only in your `App` declaration, and only once for a given extension. If you declare it more than once, SwiftUI generates a runtime error.

If your extension delegate conforms to the `ObservableObject` protocol, as in the example above, then SwiftUI puts the delegate it creates into the `Environment`. You can access the delegate from any scene or view in your extension using the `EnvironmentObject` property wrapper:

@EnvironmentObject private var extensionDelegate: MyExtensionDelegate

This enables you to use the dollar sign ( `$`) prefix to get a binding to published properties that you declare in the delegate. For more information, see `projectedValue`.

## Topics

### Creating a delegate adaptor

`init(_:)`

Creates a WatchKit extension delegate adaptor using an observable delegate.

### Getting the delegate adaptor

A projection of the observed object that provides bindings to its properties.

`var wrappedValue: DelegateType`

The underlying delegate.

## Relationships

### Conforms To

- `DynamicProperty`
- `Sendable`
- `SendableMetatype`

## See Also

### Targeting watchOS

`struct WKApplicationDelegateAdaptor`

A property wrapper that is used in `App` to provide a delegate from WatchKit.

---

# https://developer.apple.com/documentation/swiftui/creating-a-tvos-media-catalog-app-in-swiftui

- SwiftUI
- App organization
- Creating a tvOS media catalog app in SwiftUI

Sample Code

# Creating a tvOS media catalog app in SwiftUI

Build standard content lockups and rows of content shelves for your tvOS app.

Download

Xcode 16.0+

## Overview

This sample code project shows how to create the standard content lockups for tvOS, and provides best practices for building out rows of content shelves. It also includes examples for product pages, search views, and tab views, including the new sidebar adaptive tab view style that provides a sidebar in tvOS.

The sample project contains the following examples:

- `StackView` implements an example landing page for a content catalog app, defining several shelves with a showcase or hero header area above them. It also gives an example of an above- and below-the-fold switching animation.

- `ButtonsView` provides a showcase of the various button styles available in tvOS.

- `DescriptionView` provides an example of how to build a product page similar to those you see on the Apple TV app, with a custom material blur.

- `SearchView` shows an example of a simple search page using the `searchable(text:placement:prompt:)` and `searchSuggestions(_:)` modifiers.

- `SidebarContentView` shows how to make a sectioned sidebar using the new tab bar APIs in tvOS 18.

- `HeroHeaderView` gives an example of creating a material gradient to blur content in a certain area, fading it into unblurred content.

### Create content lockups

The `borderless` button style provides the primary lockup style you use in tvOS, including all the focus interactions and hover effects. The button’s title and any nearby section titles automatically move out of the way of the button’s image as it scales up on focus.

Provide a separate `Image` and `Text` view in the button’s label closure to ensure the correct vertical appearance. Using a `Label` usually results in a horizontal layout, and, depending on the current label style, may not give you the appearance you expect.

Button { /* action */ } label: {
Image("discovery_portrait")
.resizable()
.frame(width: 250, height: 375)
Text("Borderless Portrait")
}

By default, the button style locates the first `Image` within the button’s label and attaches a `highlight` hover effect to it, providing lift, a specular highlight, and gimbal motion effects.

To ensure the hover effect applies to exactly the right view, you can manually attach it to a particular subview of the button’s label using the `hoverEffect(_:)` modifier. For instance, to ensure an SF Symbols image hovers along with its background, do the following:

Button { /* action */ } label: {
Image(systemName: "person.circle")
.font(.title)
.background(Color.blue.grayscale(0.7))
.hoverEffect(.highlight)
Text("Shaped")
}
.buttonBorderShape(.circle)

You can also attach the hover effect to a custom view.

Button { /* action */ } label: {
CodeSampleArtwork(size: .appIconSize)
.frame(width: 400, height: 240)
.hoverEffect(.highlight)
Text("Custom Icon View")
}

### Show information-dense lockups

For lockups with more dense information, consider using the `card` button style, which provides a platter and a more subtle motion effect on focus. Providing containers with padding as the button’s label gives you something similar to the search result lockups on the Apple TV app.

Button { /* action */ } label: {
HStack(alignment: .top, spacing: 10) {
Image( . . . )
.resizable()
.aspectRatio(contentMode: .fit)
.clipShape(RoundedRectangle(cornerRadius: 12))

VStack(alignment: .leading) {
Text(asset.title)
.font(.body)
Text("Subtitle text goes here, limited to two lines.")
.font(.caption2)
.foregroundStyle(.secondary)
.lineLimit(2)
Spacer(minLength: 0)
HStack(spacing: 4) {
ForEach(1..<4) { _ in
Image(systemName: "ellipsis.rectangle.fill")
}
}
.foregroundStyle(.secondary)
}
}
.padding(12)
}

You can also use a custom `LabelStyle` to create a standard card-based lockup appearance while keeping your button’s declarations clean at the point of use.

struct CardOverlayLabelStyle: LabelStyle {

ZStack(alignment: .bottomLeading) {
configuration.icon
.resizable()
.aspectRatio(400/240, contentMode: .fit)
.overlay {
LinearGradient(
stops: [\
.init(color: .black.opacity(0.6), location: 0.1),\
.init(color: .black.opacity(0.2), location: 0.25),\
.init(color: .black.opacity(0), location: 0.4)\
],
startPoint: .bottom, endPoint: .top
)
}
.overlay {
RoundedRectangle(cornerRadius: 12)
.stroke(lineWidth: 2)
.foregroundStyle(.quaternary)
}

configuration.title
.font(.caption.bold())
.foregroundStyle(.secondary)
.padding(6)
}
.frame(maxWidth: 400)
}
}

Button { /* action */ } label: {
Label("Title at the bottom", image: "discovery_landscape")
}

### Display content shelves

Content shelves are usually horizontal stacks in scroll views.

Disabling scroll clipping is necessary to allow the focus effects to scale up and lift each lockup. Shelves typically contain only a single style of lockup, so assign your button style on the outside of the shelf container.

ScrollView(.horizontal) {
LazyHStack(spacing: 40) {
ForEach(Asset.allCases) { asset in
// . . .
}
}
}
.scrollClipDisabled()
.buttonStyle(.borderless)

To arrange your lockups nicely, use the `containerRelativeFrame(_:count:span:spacing:alignment:)` modifier to let SwiftUI determine the best size for each. You can specify how many lockups you want on the screen, and the amount of spacing your stack view provides. Then SwiftUI arranges the content so that the edges of the leading and trailing items align with the leading and trailing safe area insets of its container.

For borderless buttons, you can attach the modifier to the `Image` instance within the button’s label closure to make the image the source of the frame calculations and alignments.

asset.portraitImage
.resizable()
.aspectRatio(250 / 375, contentMode: .fit)
.containerRelativeFrame(.horizontal, count: 6, spacing: 40)
Text(asset.title)

### Show content above and below the fold

For a landing page you can implement above- and below-the-fold appearances through a combination of `ScrollTargetBehavior` and a background view with a gradient mask.

Define your showcase or header section as a stack with a container relative frame to make it take up a particular percentage of the available space. Attach a `focusSection()` modifier to the stack as well, so that its full width can act as a target for focus movement, which it then diverts to its content. Otherwise, moving focus up from the right side of the shelves below might fail, or might jump all the way to the tab bar because the focus engine searches for the nearest focusable view along a straight line from the currently focused item.

VStack(alignment: .leading) {
// Header content.
}
.frame(maxWidth: .infinity, alignment: .leading)
.focusSection()
.containerRelativeFrame(.vertical, alignment: .topLeading) {
length, _ in length * 0.8
}

The code above is the above-the-fold section. To detect when focus moves below the fold, use `onScrollVisibilityChange(threshold:_:)` to detect when the header view moves more than halfway off the screen.

.onScrollVisibilityChange { visible in
// When the header scrolls more than 50% offscreen, toggle
// to the below-the-fold state.
withAnimation {
belowFold = !visible
}
}

You can define the background of your landing page using a full-screen image with a material in an overlay. Then you can turn the material into a gradient by masking it with a `LinearGradient`, and you can adjust the opacity of that gradient’s stops according to the view’s above- or below-the-fold status.

Image("beach_landscape")
.resizable()
.aspectRatio(contentMode: .fill)
.overlay {
// Build the gradient material by filling an area with a material, and
// then masking that area using a linear gradient.
Rectangle()
.fill(.regularMaterial)
.mask {
LinearGradient(
stops: [\
.init(color: .black, location: 0.25),\
.init(color: .black.opacity(belowFold ? 1 : 0.3), location: 0.375),\
.init(color: .black.opacity(belowFold ? 1 : 0), location: 0.5)\
],
startPoint: .bottom, endPoint: .top
)
}
}
.ignoresSafeArea()

By adjusting the opacity of the gradient stops, rather than swapping out the mask view, you achieve a smooth animation between the above-the-fold appearance, where the material fades out above a certain height to reveal the image behind, and the below-the-fold appearance where the entire image blurs.

### Snap at the fold point

You can implement a custom `ScrollTargetBehavior` to create a fold-snapping effect. Then add a check to determine whether the target of a scroll event is crossing a fold threshold, and update that target to either the top of the page (if moving upward) or to the top of your first content shelf (if moving downward). With your view already tracking the above/below fold state, it can pass that information into the behavior to indicate which operation to check for.

ScrollView {
// . . .
}
.scrollTargetBehavior(
FoldSnappingScrollTargetBehavior(
aboveFold: !belowFold, showcaseHeight: showcaseHeight))

struct FoldSnappingScrollTargetBehavior: ScrollTargetBehavior {
var aboveFold: Bool
var showcaseHeight: CGFloat

func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
// The view is above the fold and not moving far enough down, so make no
// change.
if aboveFold && target.rect.minY < showcaseHeight * 0.3 {
return
}

// The view is below the fold, and the header isn't coming onscreen, so
// make no change.

return
}

// Upward movement: Require revealing over 30% of the header, or don't let
// the scroll go upward.
let showcaseRevealThreshold = showcaseHeight * 0.7
let snapToHideRange = showcaseRevealThreshold...showcaseHeight

if aboveFold || snapToHideRange.contains(target.rect.origin.y) {
// Snap to align the first content shelf at the top of the screen.
target.rect.origin.y = showcaseHeight
}
else {
// Snap upward to reveal the header.
target.rect.origin.y = 0
}
}
}

### Provide product highlight pages

It’s common for product pages to use a material gradient appearance with above- and below-the-fold snapping. You most likely need to tune the gradient a little differently to account for a taller bar of content at the bottom of the screen, but you typically want to keep the content’s showcase image, with a suitable blur, as a background for the view when scrolling below.

This makes each product’s page unique, with its defining artwork tinting the content. This is the same effect that root screen on the Apple TV uses — the system blurs the most recently displayed top-shelf image and uses it as the background of the tvOS home screen.

In your description view, you may want to display a stack of bordered buttons, and stretch each to the same width. SwiftUI implements bordered buttons by attaching a background to their labels, so increasing the size of the button view isn’t necessarily going to cause the background platter to grow. Instead, you need to specify that the _label content_ is able to expand, and its background then expands as well. Attaching a `frame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:alignment:)` modifier to the button’s label content achieves this for you.

VStack(spacing: 12) {
Button { /* action */ } label: {
Text("Sign Up")
.font(.body.bold())
.frame(maxWidth: .infinity)
}

Button { /* action */ } label: {
Text("Buy or Rent")
.font(.body.bold())
.frame(maxWidth: .infinity)
}

Button { /* action */ } label: {
Label("Add to Up Next", systemImage: "plus")
.font(.body.bold())
.frame(maxWidth: .infinity)
}
}

When displaying your content’s description, allow it to truncate on the page, and place it within a `Button` using the `.plain` style. People can then select it, and you can present the full description using an overlay view that you attach with the `fullScreenCover(isPresented:onDismiss:content:)` modifier.

.fullScreenCover(isPresented: $showDescription) {
VStack(alignment: .center) {
Text(loremIpsum)
.frame(maxWidth: 600)
}
}

### Search for content

For your search page, prefer using a `LazyVGrid` to contain your results, and a landscape orientation for the lockups themselves. This allows more content to appear onscreen at one time, with several rows of three to five items per row. A tall content container area makes it much easier to see the effects of changes to your search term.

The search implementation consists of simple view modifiers that function identically on each Apple platform. The `searchable(text:placement:prompt:)` modifier provides the entire search UI for you, binding the search field to the provided text. By attaching a `searchSuggestions(_:)` modifier, you can present a list of potential search keyword completions. These are commonly `Text` instances, but `Button` and `Label` also work.

Be sure to sort your search results so that the content of your grid is stable and predictable.

ScrollView(.vertical) {
LazyVGrid(
columns: Array(repeating: .init(.flexible(), spacing: 40), count: 4),
spacing: 40
) {
ForEach(/* matching assets, sorted */) { asset in
Button { /* action */ } label: {
asset.landscapeImage
.resizable()
.aspectRatio(16 / 9, contentMode: .fit)
Text(asset.title)
}
}
}
.buttonStyle(.borderless)
}
.scrollClipDisabled()
.searchable(text: $searchTerm)
.searchSuggestions {
ForEach(/* keywords matching search term */, id: \.self) { suggestion in
Text(suggestion)
}
}

---

