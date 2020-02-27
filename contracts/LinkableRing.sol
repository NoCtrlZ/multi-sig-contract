pragma solidity 0.6.0;

import {bn256g1 as Curve} from './bn256g1.sol';

library LinkableRing {
    using Curve for Curve.Point;

    struct Data {
        Curve.Point hash;
        Curve.Point[] pubkeys;
        uint256[] tags;
        uint256 ringSize;
    }

    function message(Data storage self) internal view returns (bytes32) {
        require(isFull(self));
        return bytes32(self.hash.X);
    }

    function isDead(Data storage self) internal view returns (bool) {
        return self.hash.X == 0 || (self.tags.length >= self.ringSize && self.pubkeys.length >= self.ringSize);
    }

    function pubExists(Data storage self, uint256 pub_x) internal view returns (bool) {
        for(uint i = 0; i < self.pubkeys.length; i++) {
            if(self.pubkeys[i].X == pub_x) {
                return true;
            }
        }
        return false;
    }

    function tagExists(Data storage self, uint256 pub_x) internal view returns (bool) {
        for(uint i = 0; i < self.tags.length; i++) {
            if(self.tags[i] == pub_x) {
                return true;
            }
        }
        return false;
    }

    function isInitialized(Data storage self) internal view returns (bool) {
        return self.hash.X != 0;
    }

    function initialize(Data storage self, bytes32 guid, uint256 ringSize) internal returns (bool) {
        require(uint256(guid) != 0);
        require(self.hash.X == 0);

        self.hash.X = uint256(guid);
        self.ringSize = ringSize;

        return true;
    }

    function isFull(Data storage self) internal view returns (bool) {
        return self.pubkeys.length == self.ringSize;
    }

    function addParticipant(Data storage self, uint256 pub_x, uint256 pub_y)
        internal returns (bool)
    {
        require(!isFull(self));

        require(!pubExists(self, pub_x));

        Curve.Point memory pub = Curve.Point(pub_x, pub_y);
        require(pub.isOnCurve());

        self.hash.X = uint256(sha256(abi.encode(self.hash.X, pub.X, pub.Y)));
        self.pubkeys.push(pub);
        if(isFull(self)) {
            self.hash = Curve.hashToPoint(bytes32(self.hash.X));
        }

        return true;
    }

    function tagAdd(Data storage self, uint256 tag_x) internal {
        self.tags.push(tag_x);
    }

    function ringLink(uint256 previous_hash, uint256 cj, uint256 tj, Curve.Point memory tau, Curve.Point memory h, Curve.Point memory yj)
        internal view returns (uint256 ho)
    {
        Curve.Point memory yc = yj.scalarMult(cj);

        Curve.Point memory a = Curve.scalarBaseMult(tj).pointAdd(yc);

        Curve.Point memory b = h.scalarMult(tj).pointAdd(tau.scalarMult(cj));

        return uint256(sha256(abi.encode(previous_hash, a.X, a.Y, b.X, b.Y)));
    }

    function isSignatureValid(Data storage self, uint256 tag_x, uint256 tag_y, uint256[] memory ctlist)
        internal view returns (bool)
    {
        require(isFull(self));
        require(!tagExists(self, tag_x));

        uint256 hashout = uint256(sha256(abi.encode(self.hash.X, tag_x, tag_y)));
        uint256 csum = 0;

        for (uint i = 0; i < self.pubkeys.length; i++) {
            uint256 cj = ctlist[2*i] % Curve.genOrder();
            uint256 tj = ctlist[2*i+1] % Curve.genOrder();
            hashout = ringLink(hashout, cj, tj, Curve.Point(tag_x, tag_y), self.hash, self.pubkeys[i]);
            csum = addmod(csum, cj, Curve.genOrder());
        }

        hashout %= Curve.genOrder();
        return hashout == csum;
    }
}