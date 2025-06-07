# Geolocation on ATProto: Current Approaches and Schemas

## Official ATProto Lexicon (Bluesky)

As of mid-2025, the official AT Protocol lexicons (the `app.bsky.*` schemas maintained by Bluesky) **do not include any dedicated geolocation or address fields** in standard record types like posts or profiles. There is no built-in "location" property on posts or user profiles. Instead, ATProto's extensible schema system (Lexicon) allows developers to define custom record types or embedded objects for location data. This means any geolocation support on ATProto so far has come from community-defined schemas rather than the core Bluesky types.

Notably, Bluesky has recognized the need for location features and helped kickstart community efforts (via the AT Protocol Community Fund) to develop standard location schemas. However, until those are widely adopted, the official lexicon itself remains location-agnostic.

## Community Lexicon Extensions for Location (Smoke Signal & Lexicon Community)

The most significant work on ATProto geolocation is happening in the **Lexicon Community** initiative led by Nick Gerakines (creator of Smoke Signal, an events app). This effort defines new lexicon schemas under the `community.lexicon...` namespace to represent locations. These schemas are used as embedded objects within other records (such as event posts), or as standalone records for location entries. Key pieces of this community-defined "location lexicon" include:

• **Geographic Coordinates** (`community.lexicon.location.geo`) – Represents a physical point via WGS84 coordinates¹ ². This schema requires `latitude` and `longitude` (stored as strings), with optional `altitude` and a `name` field (e.g. a label for the place)³ ⁴. It's essentially a lat/long pair object.

• **Street Address** (`community.lexicon.location.address`) – A structured address object for physical locations. It includes fields like `country` (2–10 char country code or name), `locality` (city/town), `region` (state/province), `street`, `postalCode`, and an optional `name`⁵. This can capture a full postal address.

• **Foursquare Venue** (`community.lexicon.location.fsq`) – A venue/place reference tying into Foursquare's open POI dataset. It stores an `fsq_place_id` (identifier for a venue in Foursquare's OS Places data) plus optional `latitude`, `longitude`, and `name`⁶. This lets applications include a known place by ID, without storing full address details, while still optionally carrying coordinates or a place name.

• **H3 Geocell** (`community.lexicon.location.hthree`) – Represents a location by an H3 geoindex (a hexagonal geospatial indexing system). The schema simply has a `value` (the H3 index string) and an optional `name` label⁷. Using an H3 cell can denote a coarse area or region in a standardized way. (It was renamed "hthree" because NSIDs cannot start with a digit.)

These location objects are not posted on their own in the main feed; rather they are used inside other records. For example, the Smoke Signal event record (`community.lexicon.calendar.event`) includes a `locations` property, which is an array of a union of location types⁸. Each event can list one or more locations, each of which may be: a full address, a geo coordinate, a Foursquare venue, an H3 index, or even a URI. The lexicon defines this as:

```json
"locations": { 
    "type": "array", 
    "items": { 
        "type": "union", 
        "refs": [ 
            ... "community.lexicon.location.address", 
            "community.lexicon.location.fsq", 
            "community.lexicon.location.geo", 
            "community.lexicon.location.hthree", 
            ... 
        ] 
    } 
}
```

In practice, this means an event post can carry structured location data. For instance, an in-person event might embed a `location.address` (with street and city) or a `location.fsq` object (pointing to a venue ID) in its record. Virtual events could use a special URI subtype for an online meeting link instead. The `$type` field on each location object distinguishes which schema it is (e.g. `$type: "community.lexicon.location.geo"` for coordinates)⁹.

**Summary of this approach:** The Lexicon Community approach treats geolocation as embedded objects within records. The location data is structured and strongly typed via custom lexicon definitions (effectively lexicon extensions), rather than just free-text or tags. Apps that support these schemas can recognize the `$type` and parse out coordinates or addresses accordingly. The use of community NSIDs (like `community.lexicon.location.*`) is a coordinated effort to standardize across projects, so that all apps can share a common way to represent "where". This is becoming a de-facto standard for ATProto geodata moving forward, with Bluesky's team blessing the effort via the community fund.

## Example Projects and How They Store Location Data

• **Smoke Signal (Events & RSVPs):** As mentioned, Smoke Signal was the first to push location lexicons. An event record contains a `locations` array of objects (each with a `$type` of one of the community location schemas)⁹. Originally, Smoke Signal had its own NSIDs (`events.smokesignal.*`), but it is migrating to the shared `community.lexicon` types for broader interoperability. In Smoke Signal, locations can be physical or virtual. A physical location would use an address or FSQ entry (with coordinates/address fields), whereas a virtual event might use a URI object (e.g. a link to a Zoom meeting). The schema also tracks an event's `mode` (in-person/virtual/hybrid) and `status` (scheduled, postponed, etc.), indicating how the location should be interpreted. All of this is stored as part of the event record (not a separate record), so that an event post is self-contained with its location info embedded in the JSON.

• **ATProto "Geo Marker" experiment:** Another community experiment is an app/lexicon called `atgeo-marker` (gazetteer markers) which defines a **"Marker" record** that ties content to a location. In that lexicon, a marker record has a `location` field which is a union of the same `address/geo/fsq/hthree` types¹¹, plus a human-readable `label` and references to other posts or entries associated with that place¹² ¹³. This suggests an approach where location is a first-class piece of content: for example, a user could create a "geo marker" record for Central Park with a label, the coordinates or venue ID for Central Park, and a list of related posts. The marker itself is a separate record (with its own `$type` `community.atprotocol.geomarker.marker`) that can be indexed for building feeds or maps of posts by location¹⁴ ¹¹. This is still experimental, but it shows how separate records could be used to aggregate or share location data across multiple posts.

• **NoshDelivery (Merchant Locations):** An example from outside the social feed context is the NoshDelivery demo, which defines a custom record type `xyz.noshdelivery.v0.merchant.location` to represent a restaurant's location. This record uses custom `$type` (`xyz.noshdelivery...location`) and includes fields for address and coordinates, reusing the community lexicon schemas for those sub-objects¹⁵. Specifically, the merchant location record has an `address: community.lexicon.location.address` and `coordinates: community.lexicon.location.geo` field, along with other info like `name` and `timezone`¹⁶. Here, geolocation is stored as part of a separate object/record (one per venue) rather than embedded in a user's post. A delivery app or directory could query these location records to get structured address and lat/long for each merchant. This highlights that some projects define their own record collections for places, especially when location is a primary piece of data (not just metadata on a social post). The use of the community lexicon types ensures compatibility – any client that understands the standard `location.address` and `location.geo` schemas can interpret the content of these records¹⁵.

• **Other Apps (BlueSky clients and offshoots):** A few third-party Bluesky clients have toyed with location features. For example, the web client **Ouranos** was noted for experimenting with "location-restricted" posts or feeds. This hints that a post could be made visible only to people in a certain area (likely by tagging it with a location and filtering on the client side). Any such experiment would likely rely on the same lexicon extensions (e.g. attaching a `location.geo` or `location.hthree` to a post to denote the region). Similarly, photo-sharing apps like **Pinksky** or **Flashes** have expressed interest in venue tagging for photos. Until the official app supports it, these apps could add a custom embed or record – e.g. an embed of type `location.fsq` to tag a venue in a photo post – or simply include the location objects in a post record (since posts can technically carry extra fields by schema extension). Indeed, developers have begun doing ad-hoc tests: one Bluesky user shared a "basic attempt at using lexicon.community to embed location data" in a post¹⁷, meaning they manually included a location object in their post record. Such posts appear normally in clients that don't know about the schema (the unknown fields are ignored), but enhanced clients could read the coordinates and perhaps display a map preview or filter content by distance.

## Use of `$type` and Schema Details

Across these projects, a common pattern is emerging: **locations are stored as structured objects with a `$type` that identifies the schema.** The `$type` is usually a namespaced identifier (NSID) pointing to a lexicon definition. For community-driven schemas, that means types like `"community.lexicon.location.geo"` or `"...address"` etc. The presence of `$type` in the JSON allows any ATProto client or service to recognize the data format and validate or process it according to the lexicon. For example, an event record's JSON might include an element like:

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

This self-describing approach (including the type inline) is how ATProto handles extension data in general⁹ ¹⁰. Some projects use custom collection record types with their own `$type` (e.g. `xyz.noshdelivery.v0.merchant.location` for a restaurant location record)¹⁸, whereas others embed location as a field inside another record. In both cases, the actual geospatial fields – latitude, longitude, street, city, etc. – are defined in the lexicon schema so that they're consistent across uses.

It's worth noting that **no one is simply shoving raw location strings into existing fields** or co-opting the limited embed types for geodata. Instead, developers either:

• **Extend the schema via new properties/embeds:** e.g. adding a `locations` field or a custom embed in a post that carries a location object. Because lexicons are shareable, an app could define an embed subtype for location, but in practice the community has rallied around making location its own object type (as above) rather than an opaque media embed.

• **Use separate records:** creating a dedicated record for a location (which can then be referenced by URI in posts or feeds). This is seen in the geomarker and merchant examples. A post could, for instance, include an AT URI link to a `...marker` record or a venue record, instead of embedding all details directly. The union approach in Smoke Signal's event schema even allows an AT URI reference as one variant for a location – meaning you could point to another record that holds the location info¹⁹.

## Summary of Known Approaches

• **Embedded location objects in records:** Most projects (especially social apps like events or photo apps) favor embedding location data within the record JSON. They define new lexicon object types (with custom `$type`) for things like coordinates or venues, and then add a field in their main record schema to include those. Example: Smoke Signal events have a `locations` field that can contain a geo object, address object, etc.⁹. The objects are defined by community lexicon extensions (not by Bluesky's default schemas).

• **Custom `$type` record for location:** Some use cases create an entire record type for a location or place. These are essentially separate objects in the ATProto repo (with their own collection). The record's `$type` might be app-specific (e.g. `xyz.noshdelivery...location`) and its schema includes fields for coordinates/address. Often even these leverage the community's standard types internally (as seen with NoshDelivery reusing `location.address` and `location.geo` inside its record)¹⁵. Separate records make sense if you want to reference the same location in multiple posts or maintain a database of places on ATProto.

• **Lexicon extensions vs. official schemas:** All current geolocation implementations are effectively lexicon extensions. Developers either register a new NSID under their control (like `events.smokesignal...` or `xyz.noshdelivery...`) or contribute to a shared one (`community.lexicon.location.*`). The trend now is toward the latter – using the community-defined schemas so that many apps can interoperate. Bluesky's docs explicitly encourage using custom schemas for new features, and location is following this path. There is not yet an official "app.bsky.location" type in the Bluesky namespace, but the community lexicon could eventually be adopted or referenced by official clients.

• **Schema details (coordinates, addresses, etc.):** The geolocation schemas generally cover:

- **Point coordinates:** Latitude/Longitude (strings to preserve precision)³, optional altitude.
- **Place names:** Optional `name` field to label the location (e.g. venue name or description)⁴.
- **Full addresses:** Structured fields as described (country, region, city, street, postal code)²⁰.
- **Place IDs:** A field for external or canonical IDs (e.g. `fsq_place_id` for Foursquare venues)²¹.
- **Area codes:** Use of H3 indexing for region-level tagging⁷.
- **URI for virtual locations:** A way to include URLs for online events or maps (in Smoke Signal's lexicon, a sub-type handles a URI link as a location) – not shown above, but implied as one option.

These schemas do not typically include things like bounding boxes or geojson shapes – they focus on point locations or single places. If needed, those could be added via new lexicon types, but currently point-centric data (and linking to POI databases) is the priority.

In summary, **geolocation on ATProto is being enabled through community-driven lexicon extensions.** Projects like Smoke Signal have pioneered a set of schemas for coordinates, addresses, and venues, which are now being adopted in other experimental apps and even funded for broader infrastructure. Each project might store the data slightly differently – some embed a location object directly in a post or event record, while others create separate records for places – but all share the concept of using a `$type`-tagged object to represent location in a standard way. This ensures that as support grows, any client that knows the lexicon can read the geodata.

## Geolocation in the ATProto Lexicon: Keyword Summary

To date, the **official lexicon keywords** related to location are minimal, since core schemas have none. The terms you'll encounter come from the community lexicons:

- **`location`** – used in community NSIDs (e.g. `community.lexicon.location.*`) to namespace all place-related types.
- **`latitude`, `longitude`** – string fields in the geo schema³.
- **`altitude`** – optional string in geo schema (not widely used yet)²².
- **address fields** like `street`, `locality`, `region`, etc., in the address schema²⁰.
- **`fsq_place_id`** – the field for a Foursquare place identifier in the venue schema²¹.
- **`hthree` / `value`** – the H3 index field in the H3 schema⁷.
- **`locations` (plural)** – the array property in some records (like events) that holds one or more location objects⁸.
- **`mode` / `status`** – not location data per se, but related metadata in Smoke Signal's event model to describe how the location works (in-person vs virtual, event status).
- **No reserved keywords in core lexicon** – The official ATProto schemas don't include any reserved keys like "geo" or "location". All such usage is in userland. Even the `$geo` concept has been discussed informally (e.g. whether to prefix geo fields with `$`), but currently the implementations use explicit schemas instead.

Going forward, as the community lexicon stabilizes, we may see Bluesky clients officially recognize these types or even incorporate them. In the meantime, **geolocation on ATProto is achieved via custom `$type` records or objects,** with schemas covering coordinates and addresses as described. The use of lexicon extensions allows multiple projects to converge on a common approach to location tagging on the decentralized social web.

## Sources

• AT Protocol Community Fund announcement – "bringing location data to ATProto" (plans for geo and venue lexicons)
• Smoke Signal update – introduction of event Locations (virtual or physical) and address/lat-long schema plans
• Lexicon Community schema definitions for geo coordinates and address objects³ ²³
• Lexicon Community schema for Foursquare venue (FSQ ID + optional coords/name)⁶ and H3 geolocation code⁷
• Event record schema illustrating use of a union of location types (`address|fsq|geo|hthree`) in a locations list⁹
• GeoMarker lexicon showing a separate marker record with a location union field (address/geo/fsq/h3) and label¹³ ¹¹
• NoshDelivery example using a custom location record with `address` and `coordinates` fields referencing the community lexicon types¹⁵.

---

### References

¹ ² ³ ⁴ ²² **GitHub** - <https://github.com/lexicon-community/lexicon/blob/1a8b319c00b2b57bf2cd5b011e7c0ce9bcafac0e/community/lexicon/location/geo.json>

⁵ ²⁰ ²³ **GitHub** - <https://github.com/mary-ext/atcute/blob/1fd2796a5ff6b32bf40748d9cea95d154395b216/packages/definitions/lexicon-community/lib/lexicons/types/community/lexicon/location/address.ts>

⁶ ²¹ **GitHub** - <https://github.com/mary-ext/atcute/blob/1fd2796a5ff6b32bf40748d9cea95d154395b216/packages/definitions/lexicon-community/lib/lexicons/types/community/lexicon/location/fsq.ts>

⁷ **GitHub** - <https://github.com/mary-ext/atcute/blob/1fd2796a5ff6b32bf40748d9cea95d154395b216/packages/definitions/lexicon-community/lib/lexicons/types/community/lexicon/location/hthree.ts>

⁸ ⁹ ¹⁹ **GitHub** - <https://github.com/lexicon-community/lexicon/blob/1a8b319c00b2b57bf2cd5b011e7c0ce9bcafac0e/community/lexicon/calendar/event.json>

¹⁰ **GitHub** - <https://github.com/mary-ext/atcute/blob/1fd2796a5ff6b32bf40748d9cea95d154395b216/packages/definitions/lexicon-community/lib/lexicons/types/community/lexicon/location/geo.ts>

¹¹ ¹² ¹³ ¹⁴ **GitHub** - <https://github.com/ATProtocol-Community/atgeo-marker/blob/f575139d7266522c50a9f084d6685b66139c3c5e/lexicons/community/atprotocol/geomarker.json>

¹⁵ ¹⁶ ¹⁸ **GitHub** - <https://github.com/ivanvpan/atmerchant/blob/a26a31f9ba5c38095fb4ac89f3497c40256099ea/packages/lexicon/src/types/xyz/noshdelivery/v0/merchant/location.ts>

¹⁷ **Brian M (@bamnet.bsky.social) - Bluesky** - <https://bsky.app/profile/bamnet.bsky.social>
