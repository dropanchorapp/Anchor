# Building a Foursquare Clone on AT Protocol: A Technical Deep Dive

*What it really takes to create location-aware social apps on Bluesky's decentralized infrastructure*

You want to build the next Foursquare. You've heard about AT Protocol's extensibility and Bluesky's growing ecosystem, and you're wondering: could this decentralized social platform be the foundation for innovative location-based experiences?

The short answer is yes—but you'll be building on community extensions, not official features, and the path involves some crucial architectural decisions that will shape your entire app. After diving deep into the technical realities of building location features on AT Protocol, here's what you need to know before writing your first line of code.

I'm currently building [Anchor](https://github.com/tijs/anchor), an open-source federated social check-in app, specifically to explore what's possible with location features on AT Protocol. It's as much a learning exercise as it is a product—a way to stress-test the emerging location infrastructure and understand the real tradeoffs involved in building location-aware apps on decentralized social networks. The insights in this article come from actually implementing these systems, not just reading the documentation.

## The Current Location Landscape on AT Protocol

First, some context: **Bluesky itself has zero built-in location features**. The official `app.bsky.*` schemas contain no geolocation fields, no venue tagging, no "check-in" record types. This isn't an oversight—it's by design. AT Protocol was built with extensibility at its core, allowing developers to define custom record types through a system called Lexicon.

This means any location functionality you build will be using **community-driven extensions** rather than official features. The most significant work is happening through the [Lexicon Community initiative](https://github.com/lexicon-community/lexicon), led by Nick Gerakines (creator of Smoke Signal, an events app on AT Protocol). This effort, funded by Bluesky's Community Fund, has defined standardized location schemas under the `community.lexicon.location.*` namespace.

These community schemas cover the essential building blocks:

- **Geographic Coordinates** (`community.lexicon.location.geo`) - WGS84 lat/long with optional altitude
- **Street Addresses** (`community.lexicon.location.address`) - Structured postal addresses  
- **Foursquare Venues** (`community.lexicon.location.fsq`) - References to Foursquare's open POI dataset
- **H3 Geocells** (`community.lexicon.location.hthree`) - Hexagonal geospatial indexing for area-based tagging

If you missed the earlier exploration of how these schemas work in practice, I recommend reading ["The Missing Piece: How Location Data is Coming to the AT Protocol"](https://medium.com/@_tijs/the-missing-piece-how-location-data-is-coming-to-the-at-protocol-9858160c2634) for the full context.

## Defining Your Custom Check-in Schema

For a Foursquare-style app, you'll need to define custom lexicon records for check-ins. I've explored some architectural patterns in ["Two Ways to Build Location on ATProto: Geo Markers vs. Embedded Check-ins"](https://medium.com/@_tijs/two-ways-to-build-location-on-atproto-geo-markers-vs-embedded-check-ins-7b8dfea0f5f5), but the core approach involves creating custom records that embed the community location schemas:

```json
{
  "$type": "app.yourapp.checkin", 
  "venue": "Blue Bottle Coffee",
  "rating": 4,
  "comment": "Perfect cortado!",
  "locations": [
    {
      "$type": "community.lexicon.location.fsq",
      "fsq_place_id": "4b8c3d1af964a5201f5633e3",
      "name": "Blue Bottle Coffee"
    },
    {
      "$type": "community.lexicon.location.address",
      "street": "66 Mint St",
      "locality": "San Francisco",
      "region": "CA",
      "country": "US"
    }
  ]
}
```

This gives you a foundation to build on, but once you have your basic check-in schema defined, the next critical decisions involve where to host this data and how to process it efficiently.

## The Custom PDS Question

Here's where things get interesting. Should you run your own Personal Data Server (PDS), or use Bluesky's hosted infrastructure? This decision has major implications for your app's capabilities and operational complexity.

### Custom Record Support: Not a Blocker

First, let's dispel a common misconception: **you don't strictly need a custom PDS to publish custom record types**. Even Bluesky's hosted PDS (like `bsky.social`) will accept and store unknown record types. As Bluesky developer yamarten confirmed in [GitHub Discussion #3159](https://github.com/bluesky-social/atproto/discussions/3159): "In theory, PDS does not have lexicon-specific functions, so all data can be stored in any single PDS… no implementation [yet] to impose restrictions on unknown lexicon."

When you post a custom record to a hosted PDS that doesn't recognize your schema, it simply marks the validation status as "unknown" but stores all the data. Your location check-ins will federate across the network just like any other record. (You can see examples of how custom records appear in the network using tools like [this lexicon explorer](https://ufos.microcosm.blue/collection/?nsid=app.dropanchor.checkin) showing our experimental Anchor check-ins.)

### Why Go Custom Anyway?

So why consider the operational overhead of running your own PDS? Several compelling reasons emerge for location-based apps:

**Full Data Ownership**: Your users' precise location histories reside on infrastructure you control. For privacy-sensitive location data, this is huge. You can establish clear privacy policies and ensure location data isn't mined beyond your app's intent.

**Custom Validation and Processing**: A custom PDS lets you validate location data on write, perform geocoding/reverse-geocoding automatically, compute place-based aggregates in real-time, or trigger location-based notifications. Imagine auto-tagging photos with venue data or alerting friends when someone checks in nearby.

**Enhanced Moderation**: You can implement location-specific policies—perhaps blocking check-ins in sensitive areas, requiring approval for certain venues, or automatically moderating content based on location context.

**Custom Authentication**: Integrate with existing systems via SSO, implement invite-only access for private communities, or create seamless onboarding flows specific to your app.

### Resource Requirements: Lighter Than You Think

The good news? Running an AT Protocol PDS is surprisingly lightweight. The [official self-hosting guide](https://atproto.com/guides/self-hosting) suggests **1 CPU core, 1GB RAM, and ~20GB storage** can serve 1-20 users comfortably. This isn't just theory—developers like [Justin Garrison have successfully run PDSes on Raspberry Pi devices](https://justingarrison.com/blog/2024-12-02-run-a-bluesky-pds-from-home/) at home.

For your Foursquare clone serving hundreds of users, a modest VPS (2-4 CPU cores, 4-8GB RAM) should suffice. The key insight: AT Protocol's architecture offloads the heavy lifting (global indexing, feed generation) to separate services, keeping PDSes focused on individual user data.

Storage grows with user-generated content, especially images. Text check-ins are tiny, but if users upload venue photos, plan accordingly or configure external blob storage (S3, etc.).

AT Protocol separates concerns between **Personal Data Servers** (which store individual user repositories) and **Feed Generators** (which create algorithmic timelines by indexing content across the network). Your PDS handles authentication, data storage, and serving your users' posts. Feed generators are separate services that consume the network's "firehose" of updates to build curated feeds like "trending venues near you" or "friends' recent check-ins."

Feed generators have more variable resource needs than PDSes. A simple feed indexing just your app's records might run on the same server as your PDS. But if you want to process the entire network's firehose for sophisticated location-based algorithms, expect to need dedicated infrastructure with multiple CPU cores and significant memory.

## A Practical Approach

While exploring AT Protocol for our experimental Anchor app, I've learned a few things about what works and what doesn't. If you're thinking about building a Foursquare clone, here's what seems to be the most pragmatic path:

**Start with hosted infrastructure.** Don't run your own PDS on day one—use `bsky.social` or another hosted provider. You'll have enough complexity just getting your location schemas right and building a client that works. The hosted PDS will store your custom check-in records just fine, even if it marks them as "unknown."

**Focus on the client experience first.** Your biggest challenge isn't technical—it's that existing Bluesky clients won't display your location data meaningfully. You need to build something that makes check-ins compelling enough that people want to use your app instead of just posting text updates.

**Feed generators are easier than you think.** Once you have check-ins flowing, a basic "nearby activity" feed is surprisingly straightforward to build. The [starter kit](https://github.com/bluesky-social/feed-generator) gets you 80% there, and you're just filtering for your record types and adding spatial queries.

**Custom PDS when it matters.** Move to your own infrastructure when you need location-specific processing—automatic venue detection, privacy controls, or real-time friend notifications. Not before.

The temptation is to over-engineer the backend early. Resist it. Your users care about discovering cool places and sharing experiences, not your elegant federation architecture.

## The Client Support Reality Check

Here's the challenging part: **current Bluesky clients won't display your location data in any meaningful way**. The official app simply doesn't know how to render `app.yourapp.checkin` records beyond showing a generic embedded card.

This means you'll need to:

1. **Build your own client** that understands your location schemas and renders them richly (maps, venue info, etc.)
2. **Plan for graceful degradation** where your check-ins appear as regular posts with text descriptions in unsupported clients
3. **Consider building web embeds** or browser extensions that enhance the official client experience

The silver lining? AT Protocol's self-describing data means any client *could* add support for your schemas. If your app gains traction, third-party clients might implement location features, truly leveraging the protocol's interoperability goals.

## Federation and Network Effects

One of AT Protocol's most powerful aspects is how your custom data federates seamlessly. Your location check-ins will sync across the network, reaching users on different PDSes and appearing in various clients (even if not rendered specially).

This creates interesting possibilities:
- Other apps could embed your venue data in their posts
- Map applications could aggregate check-ins from multiple location apps
- Travel apps could reference your place database
- Photo apps could auto-tag locations using your venue IDs

Your location data becomes part of the broader decentralized social graph, not trapped in a proprietary silo.

## Technical Considerations

**Lexicon Design**: Use the community location schemas (`community.lexicon.location.*`) for interoperability, but don't hesitate to define app-specific fields. Your check-in record might include ratings, photos, or social features beyond basic location data.

**Performance**: Location queries can be expensive. Consider implementing spatial databases (PostGIS) for complex geo-queries, or using services like H3 indexing for efficient area-based lookups.

**Privacy**: Location is sensitive data. Implement granular privacy controls, allow users to "blur" locations or share only city-level data, and consider automatically expiring precise location data after time.

**Offline Support**: Mobile apps need to handle network failures gracefully. Design your check-in flow to queue location posts for later sync when connectivity returns.

## The Path Forward

Building a location-based app on AT Protocol requires embracing its extensible, federated nature rather than fighting it. You're not just building an app—you're contributing to a growing ecosystem of location-aware decentralized social tools.

The current landscape is early but promising. Community location standards exist and work today. Multiple projects are experimenting with different approaches. The infrastructure (PDSes, feed generators) is proven and surprisingly affordable to operate.

Beyond the embedded check-in approach I've focused on here, there are other interesting patterns emerging. The geo markers concept—where places become first-class entities that aggregate content—offers a different way to think about location-based social networking. I explore this approach in detail in ["Two Ways to Build Location on ATProto: Geo Markers vs. Embedded Check-ins"](https://medium.com/@_tijs/two-ways-to-build-location-on-atproto-geo-markers-vs-embedded-check-ins-7b8dfea0f5f5), and it might be exactly what your use case needs.

The main challenges are around client support and user adoption, not technical limitations. If you can build compelling location experiences and drive adoption, the protocol's openness means other developers can build on your work, creating network effects that no single company could achieve alone.

For developers with solid technical skills, now is an excellent time to experiment with location features on AT Protocol. The foundation is solid, the community is supportive, and there's plenty of room for innovation in this space.

The question isn't whether you can build a Foursquare clone on AT Protocol—it's whether you're ready to help define what location-based social networking looks like in a decentralized world.

---

*If you found this technical dive helpful, please give it a clap 👏 to help other developers discover these insights about building on AT Protocol. The more people experimenting with location features on decentralized social infrastructure, the richer this ecosystem becomes.*

## References

- [Lexicon Community Repository](https://github.com/lexicon-community/lexicon) - Community location schemas
- [ATProto Geo Marker Project](https://github.com/ATProtocol-Community/atgeo-marker) - Place-first architecture example
- [Smoke Signal](https://smokesignal.events) - Events app using location lexicons
- [AT Protocol Documentation](https://atproto.com) - Official protocol specs and guides
- [Bluesky Developer Docs](https://docs.bsky.app) - API references and hosting guides