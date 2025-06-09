# Comparing Anchor Check-ins vs. Geo Marker Strategy on ATProto

Location-aware apps on the AT Protocol can take different approaches to modeling geospatial data. Two emerging patterns are:

- **Anchor Check-ins**: a post-driven model with rich location embeds.
- **Geo Markers**: a place-driven model that links multiple resources to a location.

---

## 📍 Anchor Check-in Strategy

Anchor defines a custom check-in record (`app.dropanchor.checkin`) that contains structured geolocation and address data. This record is **embedded in a standard Bluesky post** using `app.bsky.embed.record`.

### Example:
- Check-in record contains:
  - `text`
  - `createdAt`
  - `locations` (array of geo/address objects)
- Feed post embeds the check-in by URI + optional CID.

### Pros:
- ✅ Feed-visible: check-ins appear like regular posts.
- ✅ Interactable: users can reply, like, repost.
- ✅ Self-contained: rich location metadata lives in one record.
- ✅ Simple user story: "I was here at this time."

### Cons:
- ❌ Location can't be reused/queried independently.
- ❌ Not optimized for geographic search or aggregation.

---

## 🗺️ Geo Marker Strategy

Geo Marker (from the ATProtocol-Community `atgeo-marker` project) creates a dedicated **Marker** record representing a geographic location. That record then **references other content** via `relatedUris`.

### Example:
- Marker contains:
  - `label`
  - `location` (geo/address/etc.)
  - `relatedUris`: one or more AT URIs pointing to posts, images, etc.

### Pros:
- ✅ Place-first design: location is a primary entity.
- ✅ Aggregates content from many authors.
- ✅ Great for map-based UIs and gazetteers.
- ✅ Can evolve into a geoindex or POI directory.

### Cons:
- ❌ Not directly visible in feeds.
- ❌ Indirect user interaction model.
- ❌ More complex UX to manage links between markers and posts.

---

## 🧠 TL;DR Strategy Comparison

| Feature                     | Anchor Check-in                           | Geo Marker                                |
|----------------------------|-------------------------------------------|-------------------------------------------|
| Feed-visible               | ✅ Yes                                     | ❌ No (unless posted manually)            |
| Embeds location            | ✅ Directly in record                      | ✅ Directly in marker                      |
| Links to other content     | ❌ Not natively                            | ✅ `relatedUris`                           |
| Ideal for                  | Social-style check-ins                    | Map-based place discovery                 |
| Record posted as           | `app.bsky.feed.post` + `embed.record`     | Standalone `marker` record                |

---

## Final Thoughts

Both strategies can co-exist and even complement each other:

- **Anchor check-ins** are ideal for time-stamped, user-centric posts.
- **Geo markers** are ideal for aggregating multiple posts by place.

Anchor could eventually **link to existing geo markers**, or even let users convert check-ins into markers if they become significant places.