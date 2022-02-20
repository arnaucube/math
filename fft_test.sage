load("fft.sage")

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

a = vector([3,4,5,9])
print("a:", a)

# interpolate f_a(x)
fa_coef = ft_inv * a
print("fa_coef:", fa_coef)

P.<x> = PolynomialRing(F)
fa = P(list(fa_coef))
print("f_a(x):", fa)

# check that evaluating fa(x) at the roots of unity returns the expected values of a
for i in range(len(a)):
    assert fa(w[i]) == a[i]



# Fast polynomial multiplicaton using FFT
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
