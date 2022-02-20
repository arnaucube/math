load("number-theory.sage")

#####
# Chinese Remainder Theorem tests
a_i = [5, 3, 10]
m_i = [7, 11, 13]
M = 1001
assert crt(a_i, m_i, M) == 894

a_i = [3, 8]
m_i = [13, 17]
M = 221
assert crt(a_i, m_i, M) == 42


#####
# gcd, using Binary Euclidean algorithm tests
assert gcd(21, 12) == 3
assert gcd(1_426_668_559_730, 810_653_094_756) == 1_417_082

#####
# Extended Euclidean algorithm tests
assert egcd(7, 19) == (1, -8, 3)

#####
# Inverse modulo N tests
assert inv_mod(7, 19) == 11
