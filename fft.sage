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


# Fast polynomial multiplicaton using FFT
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
