# Plonk-CCS (https://eprint.iacr.org/2023/552) Sage prototype

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
#  F = GF(21888242871839275222246405745257275088696311157297823662689037894645226208583)


# The following CCS instance values have been provided by Carlos
# (https://github.com/CPerezz) and Edu (https://github.com/ed255),
# and this sage script was made to check the CCS relation.

## Checks performed by this Plonk/CCS instance:
# - binary check for x0, x1
# - 2*x2 + 2*x3 == x4
M0 = matrix([
    [F(0),   1, 0, 0, 0, 0, 0],
    [0,   0, 1, 0, 0, 0, 0],
    [0,   0, 0, 1, 0, 0, 0],
    [0,   0, 0, 0, 0, 0, 1],
    ])
M1 = matrix([
    [F(0),   1, 0, 0, 0, 0, 0],
    [0,   0, 1, 0, 0, 0, 0],
    [0,   0, 0, 0, 1, 0, 0],
    [0,   0, 0, 0, 0, 0, 1],
    ])
M2 = matrix([
    [F(0),   1, 0, 0, 0, 0, 0],
    [0,   0, 1, 0, 0, 0, 0],
    [0,   0, 0, 0, 0, 1, 0],
    [0,   0, 0, 0, 0, 0, 1],
    ])
M3 = matrix([
    [F(1), 0, 0, 0, 0, 0,   0],
    [1, 0, 0, 0, 0, 0,   0],
    [0, 0, 0, 0, 0, 0,   0],
    [0, 0, 0, 0, 0, 0,   0],
    ])
M4 = matrix([
    [F(0), 0, 0, 0, 0, 0,   0],
    [0, 0, 0, 0, 0, 0,   0],
    [2, 0, 0, 0, 0, 0,   0],
    [0, 0, 0, 0, 0, 0,   0],
    ])
M5 = matrix([
    [F(0), 0, 0, 0, 0, 0,   0],
    [0, 0, 0, 0, 0, 0,   0],
    [2, 0, 0, 0, 0, 0,   0],
    [0, 0, 0, 0, 0, 0,   0],
    ])
M6 = matrix([
    [F(-1), 0, 0, 0, 0, 0,   0],
    [-1, 0, 0, 0, 0, 0,   0],
    [-1, 0, 0, 0, 0, 0,   0],
    [0, 0, 0, 0, 0, 0,    0],
    ])
M7 = matrix([
    [F(0), 0, 0, 0, 0, 0,   0],
    [0, 0, 0, 0, 0, 0,   0],
    [0, 0, 0, 0, 0, 0,   0],
    [0, 0, 0, 0, 0, 0,   0],
    ])

z = [F(1), 0, 1, 2, 3, 10, 42]

print("z:", z)

assert len(z) == M0.ncols()

# CCS parameters
n = M0.ncols() # == len(z)
m = M0.nrows()
t=8
q=5
d=3
S = [[3,0,1], [4,0], [5,1], [6,2], [7]]
c = [1, 1, 1, 1, 1]

M = [M0,M1,M2,M3,M4,M5,M6,M7]

print("CCS values:")
print("n: %s, m: %s, t: %s, q: %s, d: %s" % (n, m, t, q, d))
print("M:", M)
print("z:", z)
print("S:", S)
print("c:", c)

# check CCS relation (this is agnostic to Plonk, for any CCS instance)
r = [F(0)] * m
for i in range(0, q):
    hadamard_output = [F(1)]*m
    for j in S[i]:
        hadamard_output = hadamard_product(hadamard_output,
                matrix_vector_product(M[j], z))

    r = vec_add(r, vec_elem_mul(hadamard_output, c[i]))

print("\nCCS relation check (∑ cᵢ ⋅ ◯ Mⱼ z == 0):", r == [0]*m)
assert r == [0]*m
