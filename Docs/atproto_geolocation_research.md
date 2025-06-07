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

These location objects are **not posted on their own** in the main feed; rather they are used inside other records. For example, the **Smoke Signal event record** (`community.lexicon.calendar.event`) includes a `locations` property, which is an array of a **union** of location types. Each event can list one or more locations, each of which may be: a full address, a geo coordinate, a Foursquare venue, an H3 index, or even a URI. The lexicon defines this as: 

> `"locations": { "type": "array", "items": { "type": "union", "refs": [ ... "community.lexicon.location.address", "community.lexicon.location.fsq", "community.lexicon.location.geo", "community.lexicon.location.hthree", ... ] } }`

In practice, this means an event post can carry structured location data. For instance, an in-person event might embed a `location.address` (with street and city) or a `location.fsq` object (pointing to a venue ID) in its record. Virtual events could use a special URI subtype for an online meeting link instead. The `$type` field on each location object distinguishes which schema it is (e.g. `$type: "community.lexicon.location.geo"` for coordinates).

**Summary of this approach:** The Lexicon Community approach treats geolocation as **embedded objects** within records. The location data is *structured and strongly typed* via custom lexicon definitions (effectively **lexicon extensions**), rather than just free-text or tags. Apps that support these schemas can recognize the `$type` and parse out coordinates or addresses accordingly. The use of community NSIDs (like `community.lexicon.location.*`) is a coordinated effort to standardize across projects, so that all apps can share a common way to represent “where”. This is becoming a **de-facto standard** for ATProto geodata moving forward, with Bluesky’s team blessing the effort via the community fund.

## Example Projects and How They Store Location Data

### Smoke Signal (Events & RSVPs)
- An event record contains a `locations` array of objects (each with a `$type` of one of the community location schemas).
- Locations can be **physical or virtual**.
- Physical: use `address`, `geo`, `fsq`, `hthree`.
- Virtual: use a special URI subtype (e.g. Zoom link).
- Events also include `mode` (in-person/virtual/hybrid) and `status` (scheduled, postponed, etc.).
- All data is embedded in the event record (not separate).

### ATProto “Geo Marker” experiment
- Lexicon: `community.atproto.geomarker.marker`.
- A `marker` record has:
  - `location` (union: geo, address, fsq, hthree)
  - `label` (human-readable)
  - `relatedUris` (references to other posts)
- Useful for tagging multiple posts to a shared place.
- Record exists as its own post/entry, not inline.

### NoshDelivery (Merchant Locations)
- Record type: `xyz.noshdelivery.v0.merchant.location`.
- Uses embedded:
  - `address: community.lexicon.location.address`
  - `coordinates: community.lexicon.location.geo`
- Structured record for a restaurant location.
- Location is stored in a dedicated record per venue.

### Other Apps (Ouranos, Flashes, etc.)
- Ouranos: explored location-restricted posts.
- Flashes, Pinksky: interested in venue/photo tagging.
- Some users experimenting with embedded `geo` objects in post records (manually adding `$type` objects).
- Clients that support the schema can enhance display (e.g. map previews); others ignore unknown fields.

## Use of `$type` and Schema Details
Across these projects, a common pattern is emerging: **locations are stored as structured objects with a `$type` that identifies the schema**. The `$type` is usually a **namespaced identifier (NSID)** pointing to a lexicon definition. For community-driven schemas, that means types like `"community.lexicon.location.geo"` or `"...address"` etc.

Example:
```json
{
  "locations": [
    {
      "$type": "community.lexicon.location.geo",
      "latitude": "40.785091", 
      "longitude": "-73.968285",
      "name": "Central Park"
    }
  ]
}
```

Some projects use **custom collection record types** with their own `$type`, while others embed location directly in records. The fields are defined in lexicons, allowing schema validation and interop.

## Summary of Known Approaches

| Approach | Details |
|---------|---------|
| Embedded location objects in records | Most popular; used by Smoke Signal, photo apps. Uses `$type` and structured fields like `geo`, `address`. |
| Custom `$type` record for location | Used when the place is a standalone object (e.g. NoshDelivery). Often used with references from posts. |
| Lexicon extensions vs official schemas | All are lexicon extensions; none are in `app.bsky.*`. The community lexicon (`community.lexicon.location.*`) is becoming the default shared namespace. |
| Schema coverage | Latitude/Longitude, full addresses, FSQ IDs, H3 regions, URI links. |

## Geolocation in the ATProto Lexicon: Keyword Summary

| Field             | Description |
|------------------|-------------|
| `latitude`, `longitude` | String fields in `geo` schema |
| `altitude`       | Optional elevation |
| `name`           | Optional label for any place |
| `country`, `region`, `locality`, `street`, `postalCode` | Address fields |
| `fsq_place_id`   | Identifier for Foursquare POIs |
| `value`          | H3 index string in `hthree` schema |
| `locations`      | Used in event records, an array of location objects |
| `mode`, `status` | Metadata about events, not location-specific |

## Final Notes
Geolocation on ATProto is achieved through **custom `$type` objects** or records, with clear schemas and embedded structure. The **Lexicon Community** schemas have become the de-facto standard and are being adopted in multiple projects. Bluesky supports this direction via funding and encouragement of community-led schema standardization.