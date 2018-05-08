pragma solidity ^0.4.18;

contract Catalog {

  uint32 constant quorum = 1;
  uint32 public nextSongIndexToAssign = 0;
  uint32 public nextChunkServerIndexToAssign = 0;

  mapping (uint32 => address) songIndexToOwner;
  mapping (uint32 => Listing) songIndexToListing;
  mapping (uint32 => ChunkServer) indexToChunkServer;
  mapping (address => ChunkServer) addressToChunkServer;

  event SongListed(address lister, uint32 songId);
  event SongPublished(uint32 songId);
  event RandomnessReady(uint ch1, uint ch2, bytes32[] chunkServers);
  event ListingPurchased(address buyer, uint32 songId, address seller);

  struct ChunkServer {
    address account;
    bytes32 hostname;
    uint256 lastSeenTime;
  }

  struct Listing {
    address seller;
    /* cost is in wei */
    uint32 cost;
    bool isAvailable;
    bool isListed;
    bool randomnessReady;
    bytes32[] chunkHashes;
    bytes32 previewChunk1Hash;
    bytes32 previewChunk2Hash;
    bytes32 chunk1Key;
    bytes32 chunk2Key;
    uint numChunks;
    bool hasChunks;

    /* Song metadata */
    // 0 is mp3
    uint32 format;
    bytes32 filename;

    bytes32 title;
    bytes32 album;
    bytes32 artist;
    bytes32 genre;
    uint32 year;
    uint32 length;

    // not needed for now
    //bytes32 albumArtist;
    //bytes32 composer;
    //int trackNum;
    //int discNum;

    /* ChunkServer info */
    bytes32[] csSubmittedRandomness;
    uint32 numRandomness;
    uint32 randomness;
  }

  function getListingName(uint32 songId) public view returns (bytes32) {
    if (songIndexToListing[songId].isListed) {
        return songIndexToListing[songId].title;
    } else {
        return "Missing title";
    }
  }

/*
  function getListingInfo(uint32 songId) public view returns (address, uint32, bool) {
    Listing storage listing = songIndexToListing[songId];
    require(listing.isListed);
    return (listing.seller, listing.cost, listing.isAvailable);
  }
*/
  function getListingMetadata(uint32 songId) public view returns
  (bytes32, bytes32, bytes32, bytes32, bytes32, uint32, uint32) {

    if (songIndexToListing[songId].isListed) {
    return (songIndexToListing[songId].filename, songIndexToListing[songId].title,
      songIndexToListing[songId].album, songIndexToListing[songId].artist,
      songIndexToListing[songId].genre, songIndexToListing[songId].year,
      songIndexToListing[songId].length);

    } else {
      revert();
    }

  }
  function Catalog() public {}

  function listSong(uint32 cost, uint32 format, bytes32 filename, bytes32 title,
    bytes32 artist, bytes32 album, bytes32 genre, uint32 year, uint32 length,
    uint32 numChunks)
    public returns (bytes32) {
    uint32 newIndex = nextSongIndexToAssign;
    nextSongIndexToAssign += 1;
    Listing storage listing = songIndexToListing[newIndex];

    listing.seller = msg.sender;
    listing.cost = cost;
    listing.numChunks = numChunks;

    listing.isListed = true;
    listing.format = format;
    listing.filename = filename;
    listing.title = title;
    listing.artist = artist;
    listing.album = album;
    listing.genre = genre;
    listing.year = year;
    listing.length = length;
    listing.hasChunks = false;
    listing.randomness = length;

    SongListed(msg.sender, newIndex);

    return listing.title;
  }

  function chunkServerJoin(bytes32 hostname) public {
    ChunkServer storage server = addressToChunkServer[msg.sender];
    require(server.lastSeenTime == 0x0);
    server.hostname = hostname;
    server.lastSeenTime = now;
  }

  function chunkServerSubmitRandomness(uint32 randomness, uint32 song) public {
    ChunkServer storage server = addressToChunkServer[msg.sender];
    require(server.lastSeenTime > 0x0);
    Listing storage listing = songIndexToListing[song];
    require(listing.isListed);
    require(listing.numRandomness < quorum);
    require(listing.hasChunks);
    listing.csSubmittedRandomness.push(server.hostname);
    listing.numRandomness += 1;
    listing.randomness = listing.randomness ^ randomness;

    if (listing.numRandomness >= quorum) {
        listing.randomnessReady = true;
    }

    if (listing.randomnessReady && listing.hasChunks) {
      uint chunk1 = listing.randomness % listing.numChunks;
      // bitshift for now I guess
      uint chunk2 = (listing.randomness ** 1024) % listing.numChunks;
    
      RandomnessReady(chunk1, chunk2, listing.csSubmittedRandomness);

      listing.previewChunk1Hash = listing.chunkHashes[chunk1];
      listing.previewChunk2Hash = listing.chunkHashes[chunk2];
    }
  }

  function publishChunks(uint32 song, bytes32[] hashes) public {
    Listing storage listing = songIndexToListing[song];
    require(listing.isListed);
    require(!listing.isAvailable);
    require(listing.seller == msg.sender);
    listing.chunkHashes = hashes;
    listing.hasChunks = true;

    SongPublished(song);

    /*
    if (listing.randomnessReady) {
      uint chunk1 = listing.randomness % listing.numChunks;
      // bitshift for now I guess
      uint chunk2 = (listing.randomness ** 1024) % listing.numChunks;

      listing.previewChunk1Hash = listing.chunkHashes[chunk1];
      listing.previewChunk2Hash = listing.chunkHashes[chunk2];
    }*/
  }

  function revealChunks(bytes32 key1, bytes32 key2, uint32 song) public {
    Listing storage listing = songIndexToListing[song];
    require(listing.isListed);
    require(listing.hasChunks);
    require(!listing.isAvailable);
    require(listing.seller == msg.sender);

    listing.chunk1Key = key1;
    listing.chunk2Key = key2;

    // TODO: should make sure chunkservers have the chunks first
    listing.isAvailable = true;
  }

  function isListingAvailable(uint32 song) view public returns (bool) {
    return songIndexToListing[song].isAvailable;
  }

  function purchaseSong(uint32 song) public payable {
    Listing storage listing = songIndexToListing[song];
    require(listing.isListed);
    require(listing.hasChunks);
    require(listing.isAvailable);

    require(msg.value > listing.cost);
    ListingPurchased(msg.sender, song, listing.seller);
    listing.seller.transfer(msg.value);

  }

}
