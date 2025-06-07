# Geolocation on ATProto: Current Approaches and Schemas

## Official ATProto Lexicon (Bluesky)
As of mid-2025, the **official AT Protocol lexicons** (the `app.bsky.*` schemas maintained by Bluesky) do **not include any dedicated geolocation or address fields** in standard record types like posts or profiles. There is no built-in “location” property on posts or user profiles. Instead, ATProto’s extensible schema system (Lexicon) allows developers to define **custom record types or embedded objects** for location data. This means any geolocation support on ATProto so far has come from community-defined schemas rather than the core Bluesky types.

Notably, Bluesky has recognized the need for location features and helped kickstart community efforts (via the AT Protocol Community Fund) to develop standard location schemas. However, until those are widely adopted, the official lexicon itself remains location-agnostic.

## Community Lexicon Extensions for Location (Smoke Signal & Lexicon Community)
The most significant work on ATProto geolocation is happening in the **Lexicon Community** initiative led by Nick Gerakines (creator of Smoke Signal, an events app). This effort defines *new lexicon schemas* under the `community.lexicon...` namespace to represent locations. These schemas are used as **embedded objects** within other records (such as event posts), or as standalone records for location entries. Key pieces of this community-defined “location lexicon” include: 

- **Geographic Coordinates (`community.lexicon.location.geo`)** – Represents a physical point via WGS84 coordinates. This schema requires `latitude` and `longitude` (stored as strings), with optional `altitude` and a `name` field (e.g. a label for the place). It’s essentially a lat/long pair object.
- **Street Address (`community.lexicon.location.address`)** – A structured address object for physical locations. It includes fields like `country` (2–10 char country code or name), `locality` (city/town), `region` (state/province), `street`, `postalCode`, and an optional `name`. This can capture a full postal address.
- **Foursquare Venue (`community.lexicon.location.fsq`)** – A venue/place reference tying into Foursquare’s open POI dataset. It stores an `fsq_place_id` (identifier for a venue in Foursquare’s OS Places data) plus optional `latitude`, `longitude`, and `name`. This lets applications include a known place by ID, without storing full address details, while still optionally carrying coordinates or a place name.
- **H3 Geocell (`community.lexicon.location.hthree`)** – Represents a location by an **H3 geoindex** (a hexagonal geospatial indexing system). The schema simply has a `value` (the H3 index string) and an optional `name` label. Using an H3 cell can denote a coarse area or region in a standardized way. (It was renamed “hthree” because NSIDs cannot start with a digit.)

These location objects are **not posted on their own** in the main feed; rather they are used inside other records. For example, the **Smoke Signal event record** (`community.lexicon.calendar.event`) includes a `locations` property, which is an array of a **union** of location types. Each event can list one or more locations, each of which may be: a full address, a geo coordinate, a Foursquare venue, an H3 index, or even a URI.

In practice, this means an event post can carry structured location data. For instance, an in-person event might embed a `location.address` (with street and city) or a `location.fsq` object (pointing to a venue ID) in its record. Virtual events could use a special URI subtype for an online meeting link instead. The `$type` field on each location object distinguishes which schema it is (e.g. `$type: "community.lexicon.location.geo"` for coordinates).

**Summary of this approach:** The Lexicon Community approach treats geolocation as **embedded objects** within records. The location data is *structured and strongly typed* via custom lexicon definitions (effectively **lexicon extensions**), rather than just free-text or tags. Apps that support these schemas can recognize the `$type` and parse out coordinates or addresses accordingly. The use of community NSIDs (like `community.lexicon.location.*`) is a coordinated effort to standardize across projects, so that all apps can share a common way to represent “where”. This is becoming a **de-facto standard** for ATProto geodata moving forward, with Bluesky’s team blessing the effort via the community fund.

## Example Projects and How They Store Location Data

[Content continues...]

(Full text truncated for brevity in this preview, but will be included in the saved file)