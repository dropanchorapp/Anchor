# Location Data on AT Protocol – Technical Implementation Overview

## Overview

This document summarizes the current progress and technical implementation of native location support on the AT Protocol (used by Bluesky), with a focus on interoperability, schema design, and integration for app developers.

---

## Community Fund Project: Native Location Data

**Initiators**: Boris Mann and Nick Gerakines  
**Funding**: $15K from Skyseed Fund  
**Goal**: Open infrastructure for geolocation across AT Protocol apps  
**Status**: Actively developed with community input

---

## Key Lexicons for Location

### 1. `community.lexicon.location.fsq`
- Links to Foursquare OS Places ID
- Optional lat/long + name
- Designed for lightweight venue tagging

### 2. `community.lexicon.location.geo`
- Lat/lon representation (WGS84)
- Optional altitude/name

### 3. `community.lexicon.location.address`
- ISO country code, locality, street, postal code, etc.

### 4. `community.lexicon.location.h3` *(Planned)*
- Uses H3 geospatial index for coarse location sharing

---

## Data Handling Strategy

- No mass import of 100M FSQ records into a repo
- Records created *on-demand* for venues
- Each venue record has a resolvable AT URI
- Lexicons published and discoverable via DNS

---

## APIs and Tools Being Developed

- Venue search API (likely FSQ/OSM backend)
- UI widget for place picking
- Indexer watching firehose for location-tagged posts
- Map visualization of posts
- Custom feed generator for geo-feeds

---

## Applications and Integration

- **Smoke Signal**: First app integrating venue tagging using `location.fsq`
- Future clients expected to support geo-tagging (e.g. Pinksky, Flashes)

---

## Considerations for OSM-Based Apps

- No native OSM lexicon yet (you could propose `community.lexicon.location.osm`)
- OSM nodes/ways/relations are unique within type, not globally
- Use type + ID to identify elements (e.g. node/12345)
- Optionally use `wikidata=*` for stable cross-dataset linking
- FSQ IDs are static; OSM data is actively maintained

---

## Mapping FSQ to OSM

- No public API mapping FSQ <-> OSM
- Manual matching via name, lat/lon, category is possible
- Wikidata can sometimes serve as a bridge (if both FSQ and OSM elements link to same QID)

---

## Open APIs Serving FSQ OS Places

- **No full Overpass-like API exists for FSQ data**
- Community project: [FSQ OS Places in PMTiles](https://github.com/wipfli/foursquare-os-places-pmtiles)
- **Stadia Maps**: Geocoding/autocomplete API with FSQ OS integration

---

## Best Practices & Future Direction

- Use community lexicons to ensure interoperability
- Follow ATGeo and Lexicon Community discussions
- Focus is on public location data (private geo data not yet supported)
- Propose or contribute to OSM-based extensions if needed

---

## Resources

- [Project Announcement](https://atprotocol.dev/location-data-on-at-protocol-the-second-community-fund-project/)
- [Lexicon Community](https://github.com/bluesky-social/lexicons)
- [FSQ OS Places](https://docs.foursquare.com/data-products/docs/os-places)
- [Stadia FSQ Beta](https://stadiamaps.com/news/geocoding-foursquare-beta/)
- [PMTiles FSQ OS Places](https://github.com/wipfli/foursquare-os-places-pmtiles)