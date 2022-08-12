# toy implementation of BLS signatures

load("bls12-381.sage")
from hashlib import sha256

def hash(m):
    h_output = sha256(str(m).encode('utf-8'))
    return int(h_output.hexdigest(), 16)

def hash_to_point(m):
    # WARNING this hash-to-point approach should not be used!
    h = hash(m)
    return G2 * h


pairing = Pairing()

class Signer:
    def __init__(self):
        self.sk = F1.random_element()
        self.pk = self.sk * G1

    def sign(self, m):
        H = hash_to_point(m)
        return self.sk * H

def verify(pk, s, m):
    H = hash_to_point(m)
    return pairing.pair(G1, s) == pairing.pair(pk, H)

def aggr(points):
    R = 0
    for i in range(len(points)):
        R = R + points[i]
    return R


m = 1234

# single signature & verification
user0 = Signer()
s = user0.sign(m)
v = verify(user0.pk, s, m)
assert v


# BLS signature aggregation
n = 10
users = [None]*n
pks = [None]*n
sigs = [None]*n
for i in range(n):
    users[i] = Signer()
    pks[i] = users[i].pk
    sigs[i] = users[i].sign(m)

# aggregate sigs & pks
s_aggr = aggr(sigs)
pk_aggr = aggr(pks)

# verify aggregated signature
v = verify(pk_aggr, s_aggr, m)
assert v
