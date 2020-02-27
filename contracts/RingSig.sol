pragma solidity 0.6.0;

import "./LinkableRing.sol";

contract RingSig {
    using LinkableRing for LinkableRing.Data;

    constructor(
        uint256[] memory _publicKeysX,
        uint256[] memory _publicKeysY,
        uint256 _threshold,
        bytes32 _guid // some random bytes (unique)
    ) public {
        require(_publicKeysX.length == _publicKeysY.length);
        require(_publicKeysX.length >= _threshold);

        threshold = _threshold;
        ringData.initialize(_guid, _publicKeysX.length);
        for (uint i; i<_publicKeysX.length; i++) {
            ringData.addParticipant(_publicKeysX[i], _publicKeysY[i]);
        }
        assert(ringData.isFull());
    }

    uint256 public threshold;
    LinkableRing.Data ringData;

    modifier ringMultisigned(uint256[2] memory _tagPoint, uint256[] memory _ctlist) {
        require(getTagsCount() < threshold);

        require(isSignatureValid(_tagPoint, _ctlist));
        addTag(_tagPoint[0]);

        if(getTagsCount() >= threshold) {
            _;
        }
    }

    function addTag(uint256 tag_x) public {
        ringData.tagAdd(tag_x);
    }

    function getTagsCount() public view returns (uint256) {
        return ringData.tags.length;
    }

    function getPublicKeysCount() public view returns (uint256) {
        return ringData.pubkeys.length;
    }

    function getPublicKey(uint256 i) public view returns (uint256 x, uint256 y) {
        return (ringData.pubkeys[i].X, ringData.pubkeys[i].Y);
    }

    function getMessage() public view returns (bytes32) {
        return ringData.message();
    }

    function isSignatureValid(uint256[2] memory _tagPoint, uint256[] memory _ctlist) public view returns (bool) {
        return ringData.isSignatureValid(_tagPoint[0], _tagPoint[1], _ctlist);
    }
}