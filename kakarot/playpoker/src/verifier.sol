// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x159670b34f9ffb05fbe258a7037fcd6863d388cd656e1c22b0e29f29d5876b21), uint256(0x24f9a3eec11186f174fb0f69db999769e6b156c4909320055fc3cb42b7b82bd2));
        vk.beta = Pairing.G2Point([uint256(0x0324a851f87abfa841c6d6c68d96954a479c668066e57d066aa0e59ab9086f09), uint256(0x08ae9fcacd0b46a90efa670770b270471d9ec2cc6aa9694d46571d8d6b528bfa)], [uint256(0x0a08169512c250d94133e9ab66bb930238fe78f4e156b13599ce69eba7916397), uint256(0x07042d3a19d25dd4742b827c076e539cf3aecbe13fd855c814e60d0461b4b5c8)]);
        vk.gamma = Pairing.G2Point([uint256(0x0a307befba5819fd0072de010cc0f29905dad7bfdfff54a551dc9667217f089f), uint256(0x08ef4f3a0b946165af10ba4222700c12504da2dca9fd44be9f8ccefe2f9c802e)], [uint256(0x0a8c2c90f1062082edf10689c72ec0f79579caa8432ea982437f0c9a2d5480f3), uint256(0x06be19c0a3f9807011965233e7040cd3eefebdae8ba9fe3714a05d07a42ad92b)]);
        vk.delta = Pairing.G2Point([uint256(0x11caf95931576eb34acf4d992809129b1bd16f36802d317bd20f74033465d084), uint256(0x1fadd487fa8a1939a0ad5a24ceebe660d995cce9978bd2f07330beaa9630bbb8)], [uint256(0x1bf1ee1697a51466b552c8cb3d425c4d32b904d5877091952373194427c8b6df), uint256(0x1ddfea5073f713e528c2d10ab98261bd2606bf8def44446f3b8765a0549af766)]);
        vk.gamma_abc = new Pairing.G1Point[](20);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x24aa94f1aef630fe437a2d7d311c4769c412a5f925a71c695b431eba17f11ad0), uint256(0x167e7fd8710afd4110ce634b7e093b250b47c06c96d2b30099bd363804ac15ed));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x11e133a23f71873a905a531addb71c9f86b3e339367d7050ee0cf5638af9c8f1), uint256(0x048056b3dc27cf1a41c6b8580a25f885ba420d792fdd12a866752f447bc92cd9));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2e032a73a311928b17039f108289a77bc09c88b2b05b9c49c8fc48991dfb62f6), uint256(0x047d06a82ab9522881d92d3658b5dd3e5f39e6858ba9f8037ac784fcbc0fbbd3));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x14807d1affc3637d70b3e30065f5d10fb8a778947b21e3cdd2a758bb8c5b0293), uint256(0x2c459907abb90fd37a6a18b7c04281327d16e03bf46ce66d3983bace140aafb2));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x088e5a11010ec3fc6bc84ff6398a4b5102752ff11e15b880fee3ff2050efde9d), uint256(0x11912a342b5652c4880f1524cb3a53ace7d9727804921b239c1a512015664dee));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x010dc8da8da263ef7254434961b3d233eebedaac3619ef83bcf867ad4cef3991), uint256(0x21aa9bc46ca232a4299be6206952d7c46274985465f28bb6e9378e4c06186353));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0aab8e7fa6a6f3b801e27f6a7ecf6084c8e78c5e82024e1336914c1a2f875728), uint256(0x20a88292fa7f36a72b7fc944f04df576cff4b6f06012653191389c1a8db8ee8d));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2b0d4ba13c6498c9a3d9221be286c600db6a6c5806c1461e6637ac1b9a6941b9), uint256(0x139d7561d6187e9e5b3dfa3d74f53406a63d42b7a8eac90b6b96cb910d7285c1));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2ec009a77c49bf86959c8671a588a7fdb08c2661bdb6fbf2ad175e363cb31be7), uint256(0x12ed0b0e409cbc61001363b5df3016679b2176adbec83de8ba5b2f72635c186f));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x25a9af21d792061f41a105eb17c3d59f534d908b9f201b2bacf54c83c6b57e74), uint256(0x23a8fdebe401ac70f78c099ae1f8f1f777fccdbb53cecc212de141873d441ed9));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x024fdd26945e8afd417720a8ec17a3b46049c4ef26ad15ac3ea4e4a17e9fcd12), uint256(0x2712bddd0bc028c5e23243cbb2d38a6c5ecfd7fdf08f9e297238215f5a7e3728));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x256d321a96f85c02433b2165261171cdecdc24a5a048bc786065e3d39f3d2709), uint256(0x2cc3b81c15dc1b2cf60808f7114318a31c269e34eeeb9adba8a6a2cbbe897917));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x15c650017995449f4c675e95062eae848686de9e263052628cb6ff0af5971ee7), uint256(0x29a022c743bb8550e78e6b4d14b56c5cbba7d7f1f9ac39200d7080b8afb07ab1));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1ae844f94ff7452e8d01e822e8440c67d8bbca7f44bf0e3bc93fd944bd2521c1), uint256(0x20ebf7b38dcfac567ae0ebddb6eac1a4e460f309db768636124f04ce4d7ffcff));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x26b3a6e9d73fa2bfa483fc484ac7169d41db11745f5509d5b073e44e4469cef3), uint256(0x06466f1ae1f6c6166efa816f186be14ee9a0177af07a3e3b5ac538e6b09cff8b));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x2d970e677b78681c41aac3b7e758b02d759b798e4422bbdb25ed52780289be78), uint256(0x221e1379d2cfc1ce480ab1301ef8f3ebcc996d6300cfef8a56d524e56ba7915e));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x1391558346a5ab86bb9af6804ac584fa6bb6048aca94c0df76ee28c6c9d567d5), uint256(0x1ad6f2ef59544ad1b36d64922883660a92e5d7615b2bff637220ccbf2049cc60));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x03bbb5fbfcf8f5af2bc4ccc5934effd3c169baea602b8ea65118f24e5d2ba6d5), uint256(0x091bcf50ee8b99dc75483ad8f3abd62deb267c5bf67db2e9ed9dd93aaa2b3b71));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x247220fd4f3b512fe8948bc2e5df706c50d81cb498e593f6d0bab16e55e3ab27), uint256(0x2afe0499aaf162b32bfd4903879b40c1d37bd1611cb31d4e98d0bb5214776d30));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x010a84530ff5460522c4e9ba512306d44ff0a4e582aa8785dcc723c13a820bc7), uint256(0x2ebcccf03fbfb7b4c0f0511df7614e334379019efe7416e272cd359cfc297cfb));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[19] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](19);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
