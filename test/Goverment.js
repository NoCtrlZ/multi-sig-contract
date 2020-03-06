const { BigInteger } = require('./jsproover-mixbytes/prover/bigInteger/bigInteger');
const { ECCurve } = require('./jsproover-mixbytes/prover/curve/curve');

const secureRandom = require("secure-random");
const BN = require("bn.js");
const ethereumjs_util = require("ethereumjs-util");

const Government = artifacts.require("Goverment");