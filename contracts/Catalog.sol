pragma solidity ^0.4.21;

contract Catalog {

  struct SongMetadata {
    bytes32 format;
    bytes32 filetype;
    bytes32 filename;

    bytes32 title;
    bytes32 album;
    bytes32 artist;
    bytes32 albumArtist;
    bytes32 composer;
    bytes32 genre;
    bytes32 year;

    int trackNum;
    int discNum;

  }
  struct Listing {
    address contract;
    uint cost;
    SongMetadata meta;
  }

  function Catalog() {

  }

}
