A menu bar Mac app "Commonbase Mac"

Exposes a global right-click that allows you to save highlighted text, an area selection of a screen, or a full screen to a Postgres ledger. 

On right-click, it gets the Foremost application and the file path or URL, if available. 

On left click of the Commonbase at Mac menu, it opens up a SwiftUI that has a Ledger tab, a Graph tab, and a Search tab. 

The Ledger tab shows a list of all entries in the ledger, with the most recent at the top. Each entry shows a preview of the content, and clicking on it opens up a detail view with the full content and metadata.

There is an entry page modal that you can get to by clicking on an item in the ledger or on the graph that opens up the full-screen image or the text and a URL that you can click to go back to where you found it. For example, if it was a highlighted line of text in a Visual Studio Code file, it would open Visual Studio Code to that file. If it's a YouTube URL that you took a screenshot of, it would open Google Chrome to that URL, etc. 

The Graph tab shows a visual representation of the relationships between entries in the ledger, using a graph layout. Nodes represent entries, and edges represent relationships (links) between them.

Graph uses UMAP clustering. 

Each item is stored in a PG vector database using OpenAI embeddings. 

The search tab allows you to use full text search or semantic search to find items that you've saved. 


Requires:
- A Postgres database with the pgvector extension enabled.
- OpenAI API key for generating embeddings.
- SwiftUI for the Mac app interface.

