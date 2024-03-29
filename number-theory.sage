# Chinese Remainder Theorem
def crt(a_i, m_i):
    if len(a_i)!=len(m_i):
        raise Exception("error, a_i and m_i must be of the same length")

    M=1
    for i in range(len(m_i)):
        M = M * m_i[i]

    x = 0
    for i in range(len(a_i)):
        M_i = M/m_i[i]
        y_i = Integer(mod(M_i^-1, m_i[i]))
        x = x + a_i[i] * M_i * y_i
    return mod(x, M)

# gcd, using Binary Euclidean algorithm
def gcd(a, b):
    g=1
    # random_elementove powers of two from the gcd
    while mod(a, 2)==0 and mod(b, 2)==0:
        a=a/2
        b=b/2
        g=2*g
    # at least one of a and b is now odd
    while a!=0:
        while mod(a, 2)==0:
            a=a/2
        while mod(b, 2)==0:
            b=b/2
        # now both a and b are odd
        if a>=b:
            a = (a-b)/2
        else:
            b = (b-a)/2

    return g*b

def gcd_recursive(a, b):
    if mod(a, b)==0:
        return b
    return gcd_recursive(b, mod(a,b))


# Extended Euclidean algorithm
# Inputs: a, b
# Outputs: r, x, y, such that r = gcd(a, b) = x*a + y*b
def egcd(a, b):
    s=0
    s_=1
    t=1
    t_=0
    r=b
    r_=a
    while r!=0:
        q = r_ // r
        (r_,r) = (r,r_ - q*r)
        (s_,s) = (s,s_ - q*s)
        (t_,t) = (t,t_ - q*t)
    
    d = r_
    x = s_
    y = t_
    
    return d, x, y

def egcd_recursive(a, b):
    if b==0:
        return a, 1, 0

    g, x, y = egcd_recursive(b, a%b)
    return g, y, x - (a//b) * y

# Inverse modulo N, using the Extended Euclidean algorithm
def inv_mod(a, N):
    g, x, y = egcd(a, N)
    if g != 1:
        raise Exception("inv_mod err, g!=1")
    return mod(x, N)

# Tests

#####
# Chinese Remainder Theorem tests
a_i = [5, 3, 10]
m_i = [7, 11, 13]
assert crt(a_i, m_i) == 894

a_i = [3, 8]
m_i = [13, 17]
assert crt(a_i, m_i) == 42


#####
# gcd, using Binary Euclidean algorithm tests
assert gcd(21, 12) == 3
assert gcd(1_426_668_559_730, 810_653_094_756) == 1_417_082

assert gcd_recursive(21, 12) == 3

#####
# Extended Euclidean algorithm tests
assert egcd(7, 19) == (1, -8, 3)
assert egcd_recursive(7, 19) == (1, -8, 3)

#####
# Inverse modulo N tests
assert inv_mod(7, 19) == 11
