# Graph Report - scripts  (2026-05-19)

## Corpus Check
- 6 files · ~120,843 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 106 nodes · 151 edges · 20 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `097a0d89`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]

## God Nodes (most connected - your core abstractions)
1. `to_dict()` - 9 edges
2. `MessageStore` - 8 edges
3. `extractMediaInfo()` - 8 edges
4. `MediaDownloader` - 8 edges
5. `handleMessage()` - 7 edges
6. `main()` - 6 edges
7. `handleHistorySync()` - 6 edges
8. `Chat` - 5 edges
9. `format_message()` - 5 edges
10. `list_messages()` - 5 edges

## Surprising Connections (you probably didn't know these)
- `handleMessage()` --calls--> `extractMediaInfo()`  [EXTRACTED]
  whatsapp-mcp/whatsapp-bridge/main.go → whatsapp-mcp/whatsapp-bridge/main.go  _Bridges community 2 → community 8_
- `main()` --calls--> `handleMessage()`  [EXTRACTED]
  whatsapp-mcp/whatsapp-bridge/main.go → whatsapp-mcp/whatsapp-bridge/main.go  _Bridges community 8 → community 6_
- `startRESTServer()` --calls--> `downloadMedia()`  [EXTRACTED]
  whatsapp-mcp/whatsapp-bridge/main.go → whatsapp-mcp/whatsapp-bridge/main.go  _Bridges community 11 → community 0_
- `main()` --calls--> `startRESTServer()`  [EXTRACTED]
  whatsapp-mcp/whatsapp-bridge/main.go → whatsapp-mcp/whatsapp-bridge/main.go  _Bridges community 0 → community 6_
- `format_messages_list()` --calls--> `format_message()`  [EXTRACTED]
  whatsapp-mcp/whatsapp-mcp-server/whatsapp.py → whatsapp-mcp/whatsapp-mcp-server/whatsapp.py  _Bridges community 12 → community 4_

## Communities (21 total, 10 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.23
Nodes (10): DownloadMediaRequest, DownloadMediaResponse, analyzeOggOpus(), min(), placeholderWaveform(), sendWhatsAppMessage(), startRESTServer(), Message (+2 more)

### Community 1 - "Community 1"
Cohesion: 0.22
Nodes (5): Contact, download_media(), Search contacts by name or phone number., Download media from a message and return the local file path.          Args:, search_contacts()

### Community 3 - "Community 3"
Cohesion: 0.22
Nodes (9): Chat, get_chat(), get_contact_chats(), get_direct_chat_by_contact(), list_chats(), Get chats matching the specified criteria., Get all chats involving the contact.          Args:         jid: The contact's J, Get chat metadata by JID. (+1 more)

### Community 4 - "Community 4"
Cohesion: 0.25
Nodes (9): format_messages_list(), get_last_interaction(), get_message_context(), list_messages(), Message, MessageContext, Get messages matching the specified criteria with optional context., Get context around a specific message. (+1 more)

### Community 5 - "Community 5"
Cohesion: 0.25
Nodes (8): get_chat(), get_contact_chats(), list_chats(), Get all WhatsApp chats involving the contact., Helper to convert dataclasses to dicts recursively., Get WhatsApp chats matching specified criteria., Get WhatsApp chat metadata by JID., to_dict()

### Community 6 - "Community 6"
Cohesion: 0.43
Nodes (3): main(), NewMessageStore(), MessageStore

### Community 7 - "Community 7"
Cohesion: 0.29
Nodes (6): get_last_interaction(), Get most recent WhatsApp message involving the contact., Send a file such as a picture, raw audio, video or document via WhatsApp to the, Send any audio file as a WhatsApp audio message to the specified recipient. For, send_audio_message(), send_file()

### Community 8 - "Community 8"
Cohesion: 0.47
Nodes (4): extractTextContent(), GetChatName(), handleHistorySync(), handleMessage()

### Community 9 - "Community 9"
Cohesion: 0.5
Nodes (4): convert_to_opus_ogg(), convert_to_opus_ogg_temp(), Convert an audio file to Opus format in an Ogg container.          Args:, Convert an audio file to Opus format in an Ogg container and store in a temporar

### Community 12 - "Community 12"
Cohesion: 0.67
Nodes (3): format_message(), get_sender_name(), Print a single message with consistent formatting.

## Knowledge Gaps
- **31 isolated node(s):** `Message`, `SendMessageResponse`, `SendMessageRequest`, `DownloadMediaRequest`, `DownloadMediaResponse` (+26 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MessageStore` connect `Community 6` to `Community 0`, `Community 8`, `Community 11`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `MediaDownloader` connect `Community 2` to `Community 0`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `extractMediaInfo()` connect `Community 2` to `Community 0`, `Community 8`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **What connects `Message`, `SendMessageResponse`, `SendMessageRequest` to the rest of the system?**
  _31 weakly-connected nodes found - possible documentation gaps or missing edges._