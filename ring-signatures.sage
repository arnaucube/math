from hashlib import sha256

# Ring Signatures
# bLSAG: Back’s Linkable Spontaneous Anonymous Group signatures
#
# A Rust implementation of this scheme can be found at:
# https://github.com/arnaucube/ring-signatures-rs

def hashToPoint(a):
    # TODO use a proper hash-to-point
    h = sha256((str(a)).encode('utf-8'))
    r = int(h.hexdigest(), 16) * g
    return r

def hash(R, m, A, B, q):
    h = sha256((
        str(R) + str(m) + str(A) + str(B)
        ).encode('utf-8'))
    r = int(h.hexdigest(), 16)
    return int(mod(r, q))

def print_ring(a):
    print("ring of c's:")
    for i in range(len(a)):
        print(i, a[i])
    print("")

class Prover:
    def __init__(self, F, g):
        self.F = F # Z_p
        self.g = g # elliptic curve generator
        self.q = self.g.order() # order of group

    def new_key(self):
        self.w = int(self.F.random_element())
        self.K = self.g * self.w
        return self.K

    def sign(self, m, R):
        # determine pi (the position of signer's public key in R
        pi = -1
        for i in range(len(R)):
            if self.K == R[i]:
                pi = i
                break
        assert pi>=0

        a = int(self.F.random_element())
        r = [None] * len(R)
        # for i \in {1, 2, ..., n} \ {i=pi}
        for i in range(0, len(R)):
            if i==pi:
                continue

            r[i] = int(mod(int(self.F.random_element()), self.q))

        c = [None] * len(R)
        # c_{pi+1}
        pi1 = mod(pi + 1, len(R))
        c[pi1] = hash(R, m, a * self.g, hashToPoint(R[pi]) * a, self.q)

        key_image = self.w * hashToPoint(self.K)

        # do c_{i+1} from i=pi+1 to pi-1:
        for j in range(0, len(R)-1):
            i = mod(pi1+j, len(R))
            i1 = mod(pi1+j +1, len(R))

            c[i1] = hash(R, m, r[i] * self.g + c[i] * R[i], r[i] * hashToPoint(R[i]) + c[i] * key_image, self.q)

        # compute r_pi
        r[pi] = int(mod(a - c[pi] * self.w, self.q))
        print_ring(c)

        return [c[0], r]

def verify(g, R, m, key_image, sig):
    q = g.order()
    c1 = sig[0]
    r = sig[1]
    assert len(R) == len(r)

    # check that key_image \in G (EC), by l * key_image == 0
    assert q * key_image == 0 # in sage 0 EC point is represented as (0:1:0)


    # for i \in 1,2,...,n
    c = [None] * len(R)
    c[0] = c1
    for j in range(0, len(R)):
        i = mod(j, len(R))
        i1 = mod(j+1, len(R))
        c[i1] = hash(R, m, r[i] * g + c[i] * R[i], r[i] * hashToPoint(R[i]) + c[i] * key_image, q)

    print_ring(c)
    assert c1 == c[0]

# Tests
import unittest, operator

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
        def test_bLSAG_ring_of_5(self):
                test_bLSAG(5, 3)
        def test_bLSAG_ring_of_20(self):
                test_bLSAG(20, 14)

def test_bLSAG(ring_size, pi):
        print(f"[bLSAG] Testing with a ring of {ring_size} keys")
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
