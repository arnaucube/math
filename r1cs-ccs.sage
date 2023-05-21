# R1CS-to-CCS (https://eprint.iacr.org/2023/552) Sage prototype

# utils
def matrix_vector_product(M, v):
    n = M.nrows()
    r = [F(0)] * n
    for i in range(0, n):
        for j in range(0, M.ncols()):
            r[i] += M[i][j] * v[j]
    return r
def hadamard_product(a, b):
    n = len(a)
    r = [None] * n
    for i in range(0, n):
        r[i] = a[i] * b[i]
    return r
def vec_add(a, b):
    n = len(a)
    r = [None] * n
    for i in range(0, n):
        r[i] = a[i] + b[i]
    return r
def vec_elem_mul(a, s):
    r = [None] * len(a)
    for i in range(0, len(a)):
        r[i] = a[i] * s
    return r
# end of utils


# can use any finite field, using a small one for the example
F = GF(101)

# R1CS matrices for: x^3 + x + 5 = y (example from article
# https://www.vitalik.ca/general/2016/12/10/qap.html )
A = matrix([
    [F(0), 1, 0, 0, 0, 0],
    [0, 0, 0, 1, 0, 0],
    [0, 1, 0, 0, 1, 0],
    [5, 0, 0, 0, 0, 1],
    ])
B = matrix([
    [F(0), 1, 0, 0, 0, 0],
    [0, 1, 0, 0, 0, 0],
    [1, 0, 0, 0, 0, 0],
    [1, 0, 0, 0, 0, 0],
    ])
C = matrix([
    [F(0), 0, 0, 1, 0, 0],
    [0, 0, 0, 0, 1, 0],
    [0, 0, 0, 0, 0, 1],
    [0, 0, 1, 0, 0, 0],
    ])

print("R1CS matrices:")
print("A:", A)
print("B:", B)
print("C:", C)


z = [F(1), 3, 35, 9, 27, 30]
print("z:", z)

assert len(z) == A.ncols()

n = A.ncols() # == len(z)
m = A.nrows()
#  l = len(io) # not used for now

# check R1CS relation
Az = matrix_vector_product(A, z)
Bz = matrix_vector_product(B, z)
Cz = matrix_vector_product(C, z)
print("\nR1CS relation check (Az ∘ Bz == Cz):", hadamard_product(Az, Bz) == Cz)
assert hadamard_product(Az, Bz) == Cz


# Translate R1CS into CCS:
print("\ntranslate R1CS into CCS:")

# fixed parameters (and n, m, l are direct from R1CS)
t=3
q=2
d=2
S1=[0,1]
S2=[2]
S = [S1, S2]
c0=1
c1=-1
c = [c0, c1]

M = [A, B, C]

print("CCS values:")
print("n: %s, m: %s, t: %s, q: %s, d: %s" % (n, m, t, q, d))
print("M:", M)
print("z:", z)
print("S:", S)
print("c:", c)

# check CCS relation (this is agnostic to R1CS, for any CCS instance)
r = [F(0)] * m
for i in range(0, q):
    hadamard_output = [F(1)]*m
    for j in S[i]:
        hadamard_output = hadamard_product(hadamard_output,
                matrix_vector_product(M[j], z))

    r = vec_add(r, vec_elem_mul(hadamard_output, c[i]))

print("\nCCS relation check (∑ cᵢ ⋅ ◯ Mⱼ z == 0):", r == [0]*m)
assert r == [0]*m
