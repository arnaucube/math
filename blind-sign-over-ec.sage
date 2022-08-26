# Implementation of: https://sci-hub.se/10.1109/iccke.2013.6682844
# more details at: https://arnaucube.com/blog/blind-signatures-ec.html#the-scheme
# A Go implementation of this schema can be found at: https://github.com/arnaucube/go-blindsecp256k1

from hashlib import sha256

def hash(m):
    h_output = sha256(str(m).encode('utf-8'))
    return int(h_output.hexdigest(), 16)



class User:
    def __init__(self, F, G):
        self.F = F # Z_q
        self.G = G # elliptic curve generator

    def blind_msg(self, m, R_):
        self.a = self.F.random_element()
        self.b = self.F.random_element()
        self.R = self.a * R_ + self.b * self.G
        m_ = self.F(self.a)^(-1) * self.F(self.R.xy()[0]) * self.F(hash(m))
        return m_

    def unblind_sig(self, s_):
        s = self.a * s_ + self.b
        return (self.R, s)


class Signer:
    def __init__(self, F, G):
        self.F = F # Z_q
        self.G = G # elliptic curve generator

        # gen Signer's key pair
        self.d = self.F.random_element()
        self.Q = self.G * self.d


    def new_request_params(self):
        self.k = self.F.random_element()
        R_ = self.G * self.k
        return R_

    def blind_sign(self, m_):
        return self.d * m_ + self.k

def verify(G, Q, sig, m):
    (R, s) = sig
    return s*G == R + (Fq(R.xy()[0]) * Fq(hash(m))) * Q



# ethereum elliptic curve
p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F # base field
a = 0
b = 7
F = GF(p) # base field
E = EllipticCurve(F, [a,b])
GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
g = E(GX,GY)
n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
q = g.order() # order of Fp
assert is_prime(p)
assert is_prime(q)
Fq = GF(q) # scalar field



# protocol flow:

user = User(Fq, g)
signer = Signer(Fq, g)

R_ = signer.new_request_params()

m = 12345 # user's message
m_ = user.blind_msg(m, R_)

s_ = signer.blind_sign(m_)

sig = user.unblind_sig(s_)

v = verify(g, signer.Q, sig, m)
print(v)
assert v
