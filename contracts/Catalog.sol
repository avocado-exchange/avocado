pragma solidity ^0.4.18;

contract Catalog {

  uint constant quorum = 3;
  uint public nextSongIndexToAssign = 0;
  uint public nextChunkServerIndexToAssign = 0;

  mapping (uint => address) songIndexToOwner;
  mapping (uint => Listing) songIndexToListing;
  mapping (uint => ChunkServer) indexToChunkServer;
  mapping (address => ChunkServer) addressToChunkServer;

  struct ChunkServer {
    address account;
    bytes32 hostname;
    uint256 lastSeenTime;
  }

  struct Listing {
    address seller;
    uint256 cost;
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
    uint format;
    bytes32 filename;

    bytes32 title;
    bytes32 album;
    bytes32 artist;
    bytes32 genre;
    uint year;
    uint length;

    // not needed for now
    //bytes32 albumArtist;
    //bytes32 composer;
    //int trackNum;
    //int discNum;

    /* ChunkServer info */
    address[] csSubmittedRandomness;
    uint numRandomness;
    uint256 randomness;
  }

  function Catalog() public {

  }

  function listSong(uint256 cost, uint format, bytes32 filename, bytes32 title,
    bytes32 artist, bytes32 album, bytes32 genre, uint year, uint length,
    uint numChunks)
    public returns (uint) {
    uint newIndex = nextSongIndexToAssign;
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
    return newIndex;
  }

  function chunkServerJoin(bytes32 hostname) public {
    ChunkServer storage server = addressToChunkServer[msg.sender];
    require(server.lastSeenTime == 0x0);
    server.hostname = hostname;
    server.lastSeenTime = now;
  }

  function chunkServerSubmitRandomness(uint256 randomness, uint song) public {
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

  function revealChunks(bytes32 key1, bytes32 key2, uint song) public {
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
