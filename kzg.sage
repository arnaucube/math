# toy implementation of BLS signatures in Sage
#
# Scheme overview: https://arnaucube.com/blog/kzg-commitments.html
# Go implementation: https://github.com/arnaucube/kzg-commitments-study

load("bls12-381.sage")

e = Pairing()

def new_ts(l):
    Fr = GF(e.r)
    s = Fr.random_element()
    print("s", s)
    tauG1 = [None] * l
    tauG2 = [None] * l
    for i in range(0, l): # TODO probably duplicate G1 & G2 instead of first powering s^i and then * G_j
        sPow = Integer(s)^i
        tauG1[i] = sPow * e.G1
        tauG2[i] = sPow * e.G2

    return (tauG1, tauG2)

def commit(taus, p):
    return evaluate_at_tau(p, taus)

# evaluates p at tau
def evaluate_at_tau(p, taus):
    e = 0
    for i in range(0, len(p.list())):
        e = e + p[i] * taus[i]
    return e

def evaluation_proof(tau, p, z, y):
    # (p - y)
    n = p - y
    # (t - z)
    d = (t-z)
    # q, rem = n / d
    q = n / d
    print("q", q)
    q = q.numerator()
    den = q.denominator()
    print("q", q)
    print("den", den)
    # check that den = 1
    assert(den==1) # rem=0
    # proof: e = [q(t)]₁
    return evaluate_at_tau(q, tau)

def verify(tau, c, proof, z, y):
    # [t]₂ - [z]₂
    sz = tau[1] - z*e.G2

    # c - [y]₁
    cy = c - y*e.G1

    print("proof", proof)
    print("sz", sz)
    print("cy", cy)
    lhs = e.pair(proof, sz)
    rhs = e.pair(cy, e.G2)
    print("lhs", lhs)
    print("rhs", rhs)
    return lhs == rhs


(tauG1, tauG2) = new_ts(5)

R.<t> = PolynomialRing(e.F1)
p = t^3 + t + 5

c = commit(tauG1, p)

z = 3
y = p(z) # = 35

proof = evaluation_proof(tauG1, p, z, y)
print("proof", proof)

v = verify(tauG2, c, proof, z, y)
print(v)
assert(v)
