import unittest, operator
load("crypto.sage")


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
                Xs.insert(0, X) # add X at the begining of Xs array

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
