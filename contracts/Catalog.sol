pragma solidity ^0.4.18;

contract Catalog {

  uint32 constant quorum = 3;
  uint32 public nextSongIndexToAssign = 0;
  uint32 public nextChunkServerIndexToAssign = 0;

  mapping (uint32 => address) songIndexToOwner;
  mapping (uint32 => Listing) songIndexToListing;
  mapping (uint32 => ChunkServer) indexToChunkServer;
  mapping (address => ChunkServer) addressToChunkServer;

  event SongListed(address indexed lister, uint32 songId);

  struct ChunkServer {
    address account;
    bytes32 hostname;
    uint256 lastSeenTime;
  }

  struct Listing {
    address seller;
    uint32 cost;
    bool isAvailable;
    bool isListed;
    bool isRandomnessReady;
    bytes32[] chunkHashes;
    bytes32 previewChunk1Hash;
    bytes32 previewChunk2Hash;
    bytes32 chunk1Key;
    bytes32 chunk2Key;
    uint numChunks;

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
    address[] csSubmittedRandomness;
    uint32 numRandomness;
    uint256 randomness;
  }

  function getListingName(uint32 songId) public view returns (bytes32) {
    if (songIndexToListing[songId].isListed) {
        return songIndexToListing[songId].title;
    } else {
        return "";
    }
  }

/*
  function getListingInfo(uint32 songId) public view returns (address, uint32, bool) {
    Listing storage listing = songIndexToListing[songId];
    require(listing.isListed);
    return (listing.seller, listing.cost, listing.isAvailable);
  }

  function getListingMetadata(uint32 songId) public view returns
  (uint32, bytes32, bytes32, bytes32, bytes32, bytes32, uint32, uint32) {
    Listing storage listing = songIndexToListing[songId];
    require(listing.isListed);

    return (listing.format, listing.filename, listing.title, listing.album,
    listing.artist, listing.genre, listing.year, listing.length);
  }
*/

  function Catalog() public {}

  function listSong(uint32 cost, uint32 format, bytes32 filename, bytes32 title,
    bytes32 artist, bytes32 album, bytes32 genre, uint32 year, uint32 length,
    uint32 numChunks)
    public returns (uint) {
    uint32 newIndex = nextSongIndexToAssign;
    nextSongIndexToAssign += 1;
    Listing storage listing = songIndexToListing[newIndex];

    // song has already been listed
    //require(!isListed);
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

    SongListed(msg.sender, newIndex);

    return newIndex;
  }

  function chunkServerJoin(bytes32 hostname) public {
    ChunkServer storage server = addressToChunkServer[msg.sender];
    require(server.lastSeenTime == 0x0);
    server.hostname = hostname;
    server.lastSeenTime = now;
  }

  function chunkServerSubmitRandomness(uint256 randomness, uint32 song) public {
    ChunkServer storage server = addressToChunkServer[msg.sender];
    require(server.lastSeenTime > 0x0);
    Listing storage listing = songIndexToListing[song];
    require(listing.isListed);
    require(listing.numRandomness < quorum);
    listing.csSubmittedRandomness.push(msg.sender);
    listing.numRandomness += 1;
    listing.randomness = listing.randomness ^ randomness;

    if (listing.numRandomness >= quorum) {
      uint256 chunk1 = listing.randomness % listing.numChunks;
      // bitshift for now I guess
      uint256 chunk2 = (listing.randomness ** 1024) % listing.numChunks;

      listing.previewChunk1Hash = listing.chunkHashes[chunk1];
      listing.previewChunk2Hash = listing.chunkHashes[chunk2];
    }

  }

  function revealChunks(bytes32 key1, bytes32 key2, uint32 song) public {
    Listing storage listing = songIndexToListing[song];
    require(listing.isListed);
    require(!listing.isAvailable);
    require(listing.seller == msg.sender);

    listing.chunk1Key = key1;
    listing.chunk2Key = key2;

    // TODO: should make sure chunkservers have the chunks first
    listing.isAvailable = true;
  }

}
