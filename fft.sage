# Primitive Root of Unity
def get_primitive_root_of_unity(F, n):
    # using the method described by Thomas Pornin in
    # https://crypto.stackexchange.com/a/63616
    q = F.order()
    for k in range(q):
        if k==0:
            continue
        g = F(k)
        #  g = F.random_element()
        if g==0:
            continue
        w = g ^ ((q-1)/n)
        if w^(n/2) != 1:
            return g, w

# Roots of Unity
def get_nth_roots_of_unity(n, primitive_w):
    w = [0]*n
    for i in range(n):
        w[i] = primitive_w^i
    return w


# fft (Fast Fourier Transform) returns:
# - nth roots of unity
# - Vandermonde matrix for the nth roots of unity
# - Inverse Vandermonde matrix
def fft(F, n):
    g, primitive_w = get_primitive_root_of_unity(F, n)

    w = get_nth_roots_of_unity(n, primitive_w)

    ft = matrix(F, n)
    for j in range(n):
        row = []
        for k in range(n):
            row.append(primitive_w^(j*k))
        ft.set_row(j, row)
    ft_inv = ft^-1
    return w, ft, ft_inv


# Fast polynomial multiplication using FFT
def poly_mul(fa, fb, F, n):
    w, ft, ft_inv = fft(F, n)

    # compute evaluation points from polynomials fa & fb at the roots of unity
    a_evals = []
    b_evals = []
    for i in range(n):
        a_evals.append(fa(w[i]))
        b_evals.append(fb(w[i]))

    # multiply elements in a_evals by b_evals
    c_evals = map(operator.mul, a_evals, b_evals)
    c_evals = vector(c_evals)

    # using FFT, convert the c_evals into fc(x)
    fc_coef = c_evals*ft_inv
    fc2=P(fc_coef.list())
    return fc2, c_evals


# Tests

#####
# Roots of Unity test:
q = 17
F = GF(q)
n = 4
g, primitive_w = get_primitive_root_of_unity(F, n)
print("generator:", g)
print("primitive_w:", primitive_w)

w = get_nth_roots_of_unity(n, primitive_w)
print(f"{n}th roots of unity: {w}")
assert w == [1, 13, 16, 4]


#####
# FFT test:

def isprime(num):
    for n in range(2,int(num^1/2)+1):
        if num%n==0:
            return False
    return True

# list valid values for q
for i in range(20):
    if isprime(8*i+1):
        print("q =", 8*i+1)

q = 41
F = GF(q)
n = 4
# q needs to be a prime, s.t. q-1 is divisible by n
assert (q-1)%n==0
print("q =", q, "n = ", n)

# ft: Vandermonde matrix for the nth roots of unity
w, ft, ft_inv = fft(F, n)
print("nth roots of unity:", w)
print("Vandermonde matrix:")
print(ft)

fa_eval = vector([3,4,5,9])
print("fa_eval:", fa_eval)

# interpolate f_a(x)
fa_coef = ft_inv * fa_eval
print("fa_coef:", fa_coef)

P.<x> = PolynomialRing(F)
fa = P(list(fa_coef))
print("f_a(x):", fa)

# check that evaluating fa(x) at the roots of unity returns the expected values of fa_eval
for i in range(len(fa_eval)):
    assert fa(w[i]) == fa_eval[i]

# go from coefficient form to evaluation form
fa_eval2 = ft * fa_coef
print("fa_eval'", fa_eval)
assert fa_eval2 == fa_eval


# Fast polynomial multiplication using FFT
print("\n---------")
print("---Fast polynomial multiplication using FFT")

n = 8
# q needs to be a prime, s.t. q-1 is divisible by n
assert (q-1)%n==0
print("q =", q, "n = ", n)

fa=P([1,2,3,4])
fb=P([1,2,3,4])
fc_expected = fa*fb
print("fc expected result:", fc_expected) # expected result
print("fc expected coef", fc_expected.coefficients())

fc, c_evals = poly_mul(fa, fb, F, n)
print("c_evals=(a_evals*b_evals)=", c_evals)
print("fc:", fc)
assert fc_expected == fc
