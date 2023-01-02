# The code of this file has been adapted from:
# https://github.com/osirislab/CSAW-CTF-2021-Finals/blob/main/crypto/aBoLiSh_taBLeS/chal.sage
#  
# ## Example of usage:
#   load("bls12-381.sage")
#   e = Pairing()
#   assert e.pair(e.G1 * 3, e.G2 * 2) == e.pair(e.G1, e.G2)^6


class Pairing():
    def __init__(self):
        # BLS12-381 Parameters
        # https://github.com/zkcrypto/bls12_381
        self.p = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
        self.r = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
        self.h1 = 0x396c8c005555e1568c00aaab0000aaab
        self.h2 = 0x5d543a95414e7f1091d50792876a202cd91de4547085abaa68a205b2e5a7ddfa628f1cb4d9e82ef21537e293a6691ae1616ec6e786f0c70cf1c38e31c7238e5

        # Define base fields
        self.F1 = GF(self.p)
        F2.<u> = GF(self.p^2, x, x^2 + 1)
        self.u = u
        self.F2 = F2
        F12.<w> = GF(self.p^12, x, x^12 - 2*x^6 + 2)
        self.w = w
        self.F12 = F12

        # Define the Elliptic Curves
        self.E1 = EllipticCurve(self.F1, [0, 4])
        self.E2 = EllipticCurve(F2, [0, 4*(1 + self.u)])
        self.E12 = EllipticCurve(F12, [0, 4])

        # Generator of order r in E1 / F1
        G1x = 0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb
        G1y = 0x8b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1
        self.G1 = self.E1(G1x, G1y)

        # Generator of order r in E2 / F2
        G2x0 = 0x24aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8
        G2x1 = 0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e
        G2y0 = 0xce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801
        G2y1 = 0x606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be
        self.G2 = self.E2(G2x0 + self.u*G2x1, G2y0 + self.u*G2y1)


    def lift_E1_to_E12(self, P):
        """
        Lift point on E/F_q to E/F_{q^12} using the natural lift
        """
        assert P.curve() == self.E1, "Attempting to lift a point from the wrong curve."
        return self.E12(P)

    def lift_E2_to_E12(self, P):
        """
        Lift point on E/F_{q^2} to E/F_{q_12} through the sextic twist
        """
        assert P.curve() == self.E2, "Attempting to lift a point from the wrong curve."
        xs, ys = [c.polynomial().coefficients() for c in (self.h2*P).xy()]
        nx = self.F12(xs[0] - xs[1] + self.w ^ 6*xs[1])
        ny = self.F12(ys[0] - ys[1] + self.w ^ 6*ys[1])
        return self.E12(nx / (self.w ^ 2), ny / (self.w ^ 3))

    def pair(self, A, B):
        A = self.lift_E1_to_E12(A)
        B = self.lift_E2_to_E12(B)
        return A.ate_pairing(B, self.r, 12, self.E12.trace_of_frobenius())

