from hashlib import sha256

# Implementation of Sigma protocol & OR proofs


def hash_two_points(a, b):
    h = sha256((str(a)+str(b)).encode('utf-8'))
    return int(h.hexdigest(), 16)

def generic_verify(g, X, A, c, z):
    return g * int(z) == X * int(c) + A

###
# Sigma protocol interactive
###

class Prover_interactive:
    def __init__(self, F, g):
        self.F = F # Z_q
        self.g = g # elliptic curve generator

    def new_key(self):
        self.w = self.F.random_element()
        X = self.g * int(self.w)
        return X

    def new_commitment(self):
        self.a = self.F.random_element()
        A = self.g * int(self.a)
        return A

    def gen_proof(self, c):
        return int(self.a) + int(c) * int(self.w)

class Verifier_interactive:
    def __init__(self, F, g):
        self.F = F
        self.g = g

    def new_challenge(self, A):
        self.A = A
        self.c = self.F.random_element()
        return self.c
    
    def verify(self, X, z):
        return self.g * int(z) == X * int(self.c) + self.A


###
# Sigma protocol non-interactive
###
class Prover:
    def __init__(self, F, g):
        self.F = F # Z_p
        self.g = g # elliptic curve generator

    def new_key(self):
        self.w = self.F.random_element()
        X = self.g * int(self.w)
        return X

    def gen_proof(self, X):
        a = self.F.random_element()
        A = self.g * int(a)
        c = hash_two_points(A, X)
        z = int(a) + c * int(self.w)
        return A, z


class Verifier:
    def __init__(self, F, g):
        self.F = F
        self.g = g

    def verify(self, X, A, z):
        c = hash_two_points(A, X)
        return self.g * int(z) == X * c + A

class Simulator:
    def __init__(self, F, g):
        self.F = F
        self.g = g

    def simulate(self, X):
        c = self.F.random_element()
        z = self.F.random_element()
        #  A = g * int(z) + X*(-int(c))
        A = g * int(z) - X * int(c)
        return A, c, z

###
# OR proof (with 2 parties)
###

class ORProver_2parties:
    def __init__(self, F, g):
        self.F = F # Z_p
        self.g = g # elliptic curve generator

    def new_key(self):
        self.w = self.F.random_element()
        X = self.g * int(self.w)
        return X

    def gen_commitments(self, xs):
        # gen commitment A
        self.a = self.F.random_element()
        A = self.g * int(self.a)

        # run the simulator for 1-b
        sim = Simulator(self.F, self.g)
        A_1, c_1, z_1 = sim.simulate(xs[1])

        self.A_1 = A_1
        self.c_1 = c_1
        self.z_1 = z_1

        return [A, A_1]

    def gen_proof(self, s):
        # split the challenge s = c xor c_1
        c = int(s) ^^ int(self.c_1)
        # compute z
        z = int(self.a) + int(c) * int(self.w)
        # note, here the order of the returned elements is always the same, in
        # a real-world implementation would be shuffled
        return [c, self.c_1], [z, self.z_1]

class ORVerifier_2parties:
    def __init__(self, F, g):
        self.F = F
        self.g = g

    def new_challenge(self, As):
        self.As = As
        self.s = self.F.random_element()
        return self.s

    def verify(self, Xs, cs, zs):
        assert self.s == int(cs[0]) ^^ int(cs[1])
        assert self.g * int(zs[0]) == Xs[0] * int(cs[0]) + self.As[0]
        assert self.g * int(zs[1]) == Xs[1] * int(cs[1]) + self.As[1]

###
# OR proof (with n parties)
###

class ORProver:
    def __init__(self, F, g):
        self.F = F # Z_p
        self.g = g # elliptic curve generator

    def new_key(self):
        self.w = self.F.random_element()
        X = self.g * int(self.w)
        return X

    def gen_commitments(self, xs):
        # gen commitment A
        self.a = self.F.random_element()
        A = self.g * int(self.a)
        self.As = [A]


        # run the simulator for the rest of Xs
        sim = Simulator(self.F, self.g)
        self.cs = []
        self.zs = []
        for i in range(1, len(xs)):
            A_1, c_1, z_1 = sim.simulate(xs[i])
            self.As.append(A_1)
            self.cs.append(c_1)
            self.zs.append(z_1)

        return self.As

    def gen_proof(self, s):
        # split the challenge s = c xor c_1 xor c_2 xor ... xor c_n
        c = int(s)
        for i in range(len(self.cs)):
            c = c ^^ int(self.cs[i])

        self.cs.insert(0, c) # add c at the beginning of cs array

        # compute z
        z = int(self.a) + int(c) * int(self.w)
        self.zs.insert(0, z) # add z at the beginning of zs array

        # note, here the order of the returned elements is always the same, in
        # a real-world implementation would be shuffled
        return self.cs, self.zs

class ORVerifier:
    def __init__(self, F, g):
        self.F = F
        self.g = g

    def new_challenge(self, As):
        self.As = As
        self.s = self.F.random_element()
        return self.s

    def verify(self, Xs, cs, zs):
        # check s == c_0 xor c_1 xor c_2 xor ... xor c_n
        computed_s = int(cs[0])
        for i in range(1, len(cs)):
            computed_s = computed_s ^^ int(cs[i])

        assert self.s == computed_s

        # check g*z == X*c + A (in multiplicative notation would g^z ==X^c * A)
        for i in range(len(Xs)):
            assert self.g * int(zs[i]) == Xs[i] * int(cs[i]) + self.As[i]



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

class TestSigmaProtocol(unittest.TestCase):
        def test_interactive(self):
                alice = Prover_interactive(F, g)

                # Alice generates witness w & statement X
                X = alice.new_key()
                assert X == alice.g * int(alice.w)

                # Alice generates the commitment A
                A = alice.new_commitment()
                assert A == alice.g * int(alice.a)

                # Bob generates the challenge (and stores A)
                bob = Verifier_interactive(F, g)
                c = bob.new_challenge(A)

                # Alice generates the proof
                z = alice.gen_proof(c)

                # Bob verifies the proof
                assert bob.verify(X, z)

                # check with the generic_verify function
                assert generic_verify(g, X, A, c, z)

        def test_non_interactive(self):
                alice = Prover(F, g)

                # Alice generates witness w & statement X
                X = alice.new_key()
                assert X == alice.g * int(alice.w)

                # Alice generates the proof
                A, z = alice.gen_proof(X)

                # Bob generates the challenge
                bob = Verifier(F, g)

                # Bob verifies the proof
                assert bob.verify(X, A, z)

                # check with the generic_verify function
                c = hash_two_points(A, X)
                assert generic_verify(g, X, A, c, z)

        def test_simulator(self):
                sim = Simulator(F, g)

                # set a public key X, for which we don't know w
                unknown_w = 3
                X = g * unknown_w

                # simulate for X
                A, c, z = sim.simulate(X)

                # verify the simulated proof
                assert generic_verify(g, X, A, c, z)

class TestORProof(unittest.TestCase):
        def test_2_parties(self):
                # set a public key X, for which we don't know w
                unknown_w = 3
                X_1 = g * unknown_w

                alice = ORProver_2parties(F, g)

                # Alice generates key pair
                X = alice.new_key()
                Xs = [X, X_1]
                # Alice generates commitments (internally running the simulator)
                As = alice.gen_commitments(Xs)

                # Bob generates the challenge (and stores As)
                bob = ORVerifier_2parties(F, g)
                s = bob.new_challenge(As)

                # Alice generates the ORproof
                cs, zs = alice.gen_proof(s)

                # Bob verifies the proofs
                bob.verify(Xs, cs, zs)

        def test_n_parties(self):
                # set n public keys X, for which we don't know w
                Xs = []
                for i in range(10):
                        X_i = g * i
                        Xs.append(X_i)

                alice = ORProver(F, g)

                # Alice generates key pair
                X = alice.new_key()
                Xs.insert(0, X) # add X at the beginning of Xs array

                # Alice generates commitments (internally running the simulator)
                As = alice.gen_commitments(Xs)

                # Bob generates the challenge (and stores As)
                bob = ORVerifier(F, g)
                s = bob.new_challenge(As)

                # Alice generates the ORproof
                cs, zs = alice.gen_proof(s)

                # Bob verifies the proofs
                bob.verify(Xs, cs, zs)

if __name__ == '__main__':
        unittest.main()
