pragma solidity 0.6.0;

library bn256g1 {
    uint256 internal constant FIELD_ORDER = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant GEN_ORDER = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    uint256 internal constant CURVE_B = 3;
    uint256 internal constant CURVE_A = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;

    struct Point {
        uint256 X;
        uint256 Y;
    }

    function genOrder() internal pure returns (uint256) {
        return GEN_ORDER;
    }

    function fieldOrder() internal pure returns (uint256) {
        return FIELD_ORDER;
    }

    function infinity() internal pure returns (Point memory) {
        return Point(0, 0);
    }

    function generator() internal pure returns (Point memory) {
        return Point(1, 2);
    }

    function equal(Point memory a, Point memory b) internal pure returns (bool) {
        return a.X == b.X && a.Y == b.Y;
    }

    function negate(Point memory p) internal pure returns (Point memory) {
        if(p.X == 0 && p.Y == 0) {
            return Point(0, 0);
        }
        return Point(p.X, FIELD_ORDER - (p.Y % FIELD_ORDER));
    }

    function hashToPoint(bytes32 s) internal view returns (Point memory) {
        uint256 beta = 0;
        uint256 y = 0;
        uint256 x = uint256(s) % GEN_ORDER;

        while( true ) {
            (beta, y) = findYforX(x);
            if(beta == mulmod(y, y, FIELD_ORDER)) {
                return Point(x, y);
            }

            x = addmod(x, 1, FIELD_ORDER);
        }
    }

    function findYforX(uint256 x) internal view returns (uint256, uint256) {
        uint256 beta = addmod(mulmod(mulmod(x, x, FIELD_ORDER), x, FIELD_ORDER), CURVE_B, FIELD_ORDER);
        uint256 y = expMod(beta, CURVE_A, FIELD_ORDER);
        return (beta, y);
    }

    function isInfinity(Point memory p) internal pure returns (bool) {
        return p.X == 0 && p.Y == 0;
    }

    function isOnCurve(Point memory p) internal pure returns (bool) {
        uint256 p_squared = mulmod(p.X, p.X, FIELD_ORDER);
        uint256 p_cubed = mulmod(p_squared, p.X, FIELD_ORDER);
        return addmod(p_cubed, CURVE_B, FIELD_ORDER) == mulmod(p.Y, p.Y, FIELD_ORDER);
    }

    function scalarBaseMult(uint256 x) internal view returns (Point memory r) {
        return scalarMult(generator(), x);
    }

    function pointAdd(Point memory p1, Point memory p2) internal view returns (Point memory r) {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0x80, r, 0x40)
            switch success case 0 { invalid() }
        }
        require(success);
    }

    function scalarMult(Point memory p, uint256 s) internal view returns (Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x60, r, 0x40)
            switch success case 0 { invalid() }
        }
        require(success);
    }

    function expMod(uint256 base, uint256 exponent, uint256 modulus)
        internal view returns (uint256 retval)
    {
        bool success;
        uint256[1] memory output;
        uint256[6] memory input;
        input[0] = 0x20;
        input[1] = 0x20;
        input[2] = 0x20;
        input[3] = base;
        input[4] = exponent;
        input[5] = modulus;
        assembly {
            success := staticcall(sub(gas(), 2000), 5, input, 0xc0, output, 0x20)
            switch success case 0 { invalid() }
        }
        require(success);
        return output[0];
    }
}
