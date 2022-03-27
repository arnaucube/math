import unittest, operator
load("ring-signatures.sage")

# ethereum elliptic curve
p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
a = 0
b = 7
F = GF(p)
E = EllipticCurve(F, [a,b])
GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
g = E(GX,GY)
n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
h = 1
q = g.order()
assert is_prime(p)
assert is_prime(q)
assert g * q == 0


class TestRingSignatures(unittest.TestCase):
        def test_blSAG_ring_of_5(self):
                test_blSAG(5, 3)
        def test_blSAG_ring_of_20(self):
                test_blSAG(20, 14)

def test_blSAG(ring_size, pi):
        print(f"[blSAG] Testing with a ring of {ring_size} keys")
        prover = Prover(F, g)
        n = ring_size
        R = [None] * n

        # generate prover's key pair
        K_pi = prover.new_key()

        # generate other n public keys
        for i in range(0, n):
            R[i] = g * i

        # set K_pi
        R[pi] = K_pi

        # sign m
        m = 1234
        print("sign")
        sig = prover.sign(m, R)

        print("verify")
        key_image = prover.w * hashToPoint(prover.K)
        verify(g, R, m, key_image, sig)

if __name__ == '__main__':
        unittest.main()
