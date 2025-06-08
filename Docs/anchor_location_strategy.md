# ATProto Location Strategy for Anchor

## Objective
Enable geolocation and address data in check-ins posted by the Anchor app using the AT Protocol, while maintaining full compatibility with Bluesky's feed system.

---

## Final Strategy

### ✅ Post a standard `app.bsky.feed.post`
- Ensure check-ins show up in the Bluesky feed.
- Maintain compatibility with likes, replies, and reposts.
- Text content goes here.

### ✅ Embed location data via custom record
- Define a custom record: `app.dropanchor.checkin`
- This record contains detailed geolocation/address data using community lexicon types.
- It is embedded using `app.bsky.embed.record`.

---

## Example Feed Post
```json
{
  "$type": "app.bsky.feed.post",
  "text": "Checked in at Café de Plek 🍻",
  "createdAt": "2025-06-07T14:05:00Z",
  "embed": {
    "$type": "app.bsky.embed.record",
    "record": {
      "uri": "at://did:example/app.dropanchor.checkin/123",
      "cid": "bafyreigh2akiscaildc..."
    }
  }
}
```

## Example Embedded Check-in Record
```json
{
  "$type": "app.dropanchor.checkin",
  "text": "Café de Plek 🍻",
  "createdAt": "2025-06-07T14:05:00Z",
  "locations": [
    {
      "$type": "community.lexicon.location.geo",
      "latitude": "52.0705",
      "longitude": "4.3007",
      "name": "Voorburg"
    },
    {
      "$type": "community.lexicon.location.address",
      "street": "Julianalaan 1",
      "locality": "Voorburg",
      "region": "ZH",
      "country": "NL",
      "postalCode": "2273JA",
      "name": "Café de Plek"
    }
  ]
}
```

---

## Lexicon Summary

### Record Type: `app.dropanchor.checkin`
- `text`: short name/label for the check-in.
- `createdAt`: ISO 8601 datetime string.
- `locations`: array of union types (`geo`, `address`, etc.).

### Location Type Support:
- `community.lexicon.location.geo`
- `community.lexicon.location.address`
- Can be extended to support FSQ or H3 later.

---

## 🔐 Content Integrity with `cid`

### What is `cid`?
- A content hash of the embedded record.
- Ensures the embed refers to a specific, immutable version of the data.
- Helps clients verify the embed hasn't changed.

### How to use:
1. Post your `app.dropanchor.checkin` record using the repo API.
2. Retrieve the `uri` and `cid` from the response.
3. Include both in your `app.bsky.feed.post` embed.

### Is it required?
- ❌ No, it's optional.
- ✅ But it's good practice for cache consistency and correctness.

---

## Benefits of This Approach

- ✅ Fully compatible with Bluesky feed clients.
- ✅ Rich geodata support via lexicon extensions.
- ✅ Flexible and forward-compatible with potential venue support.
- ✅ Only one feed-visible post per check-in.

---

## Next Steps

1. ✅ Use `app.dropanchor.checkin` to store rich check-in data.
2. ✅ Post `app.bsky.feed.post` referencing your check-in via `embed.record`.
3. ✅ Include the `cid` when embedding to ensure content integrity.
4. ✅ Store lexicon JSON for `app.dropanchor.checkin` in a public repo.
5. ⬜ Optionally contribute to `lexicon-community` or promote adoption.