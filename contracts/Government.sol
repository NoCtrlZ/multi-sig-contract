pragma solidity 0.6.0;

import './RingSig.sol';

contract Government {
    mapping(bytes32 => Proposal) proposals;
    bytes32[] proposalIndex;

    struct Proposal {
        string proposalTitle;
        bytes32 proposalHash;
        bool isApproved;
        RingSig ringsig;
        uint256 deadline;
        address proposer;
        uint256 threshold;
    }

    // check whether proposal hash is not exist and pulic key x y is same length
    modifier isValidProposal(uint256[] memory _publicKeysX, uint256[] memory _publicKeysY, bytes32 proposalHash) {
        require(0 == uint256(proposals[proposalHash].proposalHash) && _publicKeysX.length == _publicKeysY.length);
        _;
    }

    modifier beforeDeadline(bytes32 _proposalHash) {
        require(proposals[_proposalHash].deadline > now);
        _;
    }

    modifier multiSigned(RingSig _multiSig, uint256[2] memory _tagPoint, uint256[] memory _ctlist) {
        require(_multiSig.getTagsCount() < _multiSig.threshold());

        require(_multiSig.isSignatureValid(_tagPoint, _ctlist));
        _multiSig.addTag(_tagPoint[0]);

        if(_multiSig.getTagsCount() >= _multiSig.threshold()) {
            _;
        }
    }

    // Initialize proposal with public key and deadline
    function propose(
        string memory proposalTitle,
        uint256[] memory _publicKeysX,
        uint256[] memory _publicKeysY,
        uint256 deadline
    )
    public
    isValidProposal(_publicKeysX, _publicKeysY, keccak256(abi.encodePacked(proposalTitle)))
    {
        bytes32 proposalHash = keccak256(abi.encodePacked(proposalTitle));
        uint256 threshold = _publicKeysX.length / 2;
        proposals[proposalHash] = Proposal (
            proposalTitle,
            proposalHash,
            false,
            new RingSig(_publicKeysX, _publicKeysY, threshold, proposalHash),
            deadline,
            msg.sender,
            threshold
        );
        proposalIndex.push(proposalHash);
    }

    function agree(bytes32 _proposalHash, uint256[2] memory _tagPoint, uint256[] memory ctlist)
    public
    beforeDeadline(_proposalHash)
    multiSigned(
        proposals[_proposalHash].ringsig,
        _tagPoint,
        ctlist
    )
    {
        proposals[_proposalHash].isApproved = true;
    }
}
