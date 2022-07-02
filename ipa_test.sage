import unittest, operator
load("ipa.sage")

# Halo paper: https://eprint.iacr.org/2019/1021.pdf
# Bulletproofs paper: https://eprint.iacr.org/2017/1066.pdf

# Ethereum elliptic curve
p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
a = 0
b = 7
Fp = GF(p)
E = EllipticCurve(Fp, [a,b])
GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
g = E(GX,GY)
n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
h = 1
q = g.order()
Fq = GF(q)

# simplier curve values
#  p = 19
#  Fp = GF(p)
#  E = EllipticCurve(Fp,[0,3])
#  g = E(1, 2)
#  q = g.order()
#  Fq = GF(q)

print(E)
print(Fq)
assert is_prime(p)
assert is_prime(q)
assert g * q == 0

class TestUtils(unittest.TestCase):
        def test_vecs(self):
            a = [1, 2, 3, 4, 5]
            b = [1, 2, 3, 4, 5]

            c = vec_scalar_mul_field(a, 10)
            assert c == [10, 20, 30, 40, 50]

            c = inner_product_field(a, b)
            assert c == 55

            # check that <a, b> with b = (1, x, x^2, ..., x^{d-1}) is the same
            # than evaluating p(x) with coefficients a_i, at x
            a = [Fq(1), Fq(2), Fq(3), Fq(4), Fq(5), Fq(6), Fq(7), Fq(8)]
            z = Fq(3)
            b = powers_of(z, 8)
            c = inner_product_field(a, b)

            x = PolynomialRing(Fq, 'x').gen()
            px = 1 + 2*x + 3*x^2 + 4*x^3 + 5*x^4 + 6*x^5 + 7*x^6 + 8*x^7
            assert c == px(x=z)


class TestIPA_bulletproofs(unittest.TestCase):
        def test_inner_product(self):
            d = 8
            ipa = IPA_bulletproofs(Fq, E, g, d)

            # prover
            # p(x) = 1 + 2x + 3x² + 4x³ + 5x⁴ + 6x⁵ + 7x⁶ + 8x⁷
            a = [ipa.F(1), ipa.F(2), ipa.F(3), ipa.F(4), ipa.F(5), ipa.F(6), ipa.F(7), ipa.F(8)]
            x = ipa.F(3)
            b = powers_of(x, ipa.d) # = b
            
            # prover
            P = ipa.commit(a, b)
            print("commit", P)
            v = ipa.evaluate(a, b)
            print("v", v)

            # verifier
            #  r = int(ipa.F.random_element())

            # verifier generate random challenges {uᵢ} ∈ 𝕀 and U ∈ 𝔾
            U = ipa.E.random_element()
            k = int(math.log(d, 2))
            u = [None] * k
            for j in reversed(range(0, k)):
                u[j] = ipa.F.random_element()
                while (u[j] == 0): # prevent u[j] from being 0
                    u[j] = ipa.F.random_element()

            P = P + int(inner_product_field(a, b)) * U

            # prover
            a_ipa, b_ipa, G_ipa, H_ipa, L, R = ipa.ipa(a, b, u, U)

            # verifier
            print("P", P)
            print("a_ipa", a_ipa)
            verif = ipa.verify(P, a_ipa, v, b, u, U, L, R, b_ipa, G_ipa, H_ipa)
            print("Verification:", verif)
            assert verif == True


class TestIPA_halo(unittest.TestCase):
        def test_homomorphic_property(self):
            ipa = IPA_halo(Fq, E, g, 5)
            
            a = [1, 2, 3, 4, 5]
            b = [1, 2, 3, 4, 5]
            c = vec_add(a, b)
            assert c == [2,4,6,8,10]

            r = int(ipa.F.random_element())
            s = int(ipa.F.random_element())
            vc_a = ipa.commit(a, r)
            vc_b = ipa.commit(b, s)
            
            # com(a, r) + com(b, s) == com(a+b, r+s)
            expected_vc_c = ipa.commit(vec_add(a, b), r+s)
            vc_c = vc_a + vc_b
            assert vc_c == expected_vc_c

        def test_inner_product(self):
            d = 8
            ipa = IPA_halo(Fq, E, g, d)

            # prover
            # p(x) = 1 + 2x + 3x² + 4x³ + 5x⁴ + 6x⁵ + 7x⁶ + 8x⁷
            a = [ipa.F(1), ipa.F(2), ipa.F(3), ipa.F(4), ipa.F(5), ipa.F(6), ipa.F(7), ipa.F(8)]
            x = ipa.F(3)
            x_powers = powers_of(x, ipa.d) # = b
            
            # verifier
            r = int(ipa.F.random_element())

            # prover
            P = ipa.commit(a, r)
            print("commit", P)
            v = ipa.evaluate(a, x_powers)
            print("v", v)

            # verifier generate random challenges {uᵢ} ∈ 𝕀 and U ∈ 𝔾
            U = ipa.E.random_element()
            k = int(math.log(ipa.d, 2))
            u = [None] * k
            for j in reversed(range(0, k)):
                u[j] = ipa.F.random_element()
                while (u[j] == 0): # prevent u[j] from being 0
                    u[j] = ipa.F.random_element()

            P = P + int(v) * U

            # prover
            a_ipa, b_ipa, G_ipa, lj, rj, L, R = ipa.ipa(a, x_powers, u, U)

            # verifier
            print("P", P)
            print("a_ipa", a_ipa)
            print("\n Verify:")
            verif = ipa.verify(P, a_ipa, v, x_powers, r, u, U, lj, rj, L, R, b_ipa, G_ipa)
            assert verif == True


if __name__ == '__main__':
        unittest.main()
