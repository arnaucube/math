# Sage impl of the powers of tau,
# a Go implementation can be found at: https://github.com/arnaucube/eth-kzg-ceremony-alt


load("bls12-381.sage") # file from https://github.com/arnaucube/math/blob/master/bls12-381.sage
e = Pairing()

def new_empty_SRS(nG1, nG2):
    g1s = [None] * nG1
    g2s = [None] * nG2
    for i in range(0, nG1):
        g1s[i] = e.G1
    for i in range(0, nG2):
        g2s[i] = e.G2

    return [g1s, g2s]

def new_tau(random):
    return e.F1(random)

def compute_contribution(new_tau, prev_srs):
    g1s = [None] * len(prev_srs[0])
    g2s = [None] * len(prev_srs[1])
    srs = [g1s, g2s]
    Q = e.r

	# compute [τ'⁰]₁, [τ'¹]₁, [τ'²]₁, ..., [τ'ⁿ⁻¹]₁, where n = len(prev_srs.G1s)
    for i in range(0, len(prev_srs[0])):
        srs[0][i] = (new_tau^i) * prev_srs[0][i]
    
    # compute [τ'⁰]₂, [τ'¹]₂, [τ'²]₂, ..., [τ'ⁿ⁻¹]₂, where n = len(prev_srs.G2s)
    for i in range(0, len(prev_srs[1])):
        srs[1][i] = (new_tau^i) * prev_srs[1][i]

    return srs

def generate_proof(tau, prev_srs, new_srs):
    # g_1^{tau'} = g_1^{p * tau} = SRS_G1s[1] * p
    g1_ptau = prev_srs[0][1] * tau
    # g_2^{p}
    g2_p = tau * e.G2
    return [g1_ptau, g2_p]

def verify(prev_srs, new_srs, proof):
    # 1. check that elements of the newSRS are valid points
    for i in range(0, len(new_srs[0])-1):
        assert new_srs[0][i] != None
        assert new_srs[0][i] != e.E1(0)
        assert new_srs[0][i] in e.E1

    for i in range(0, len(new_srs[1])-1):
        assert new_srs[1][i] != None
        assert new_srs[1][i] != e.E2(0)
        assert new_srs[1][i] in e.E2

    # 2. check proof.G1PTau == newSRS.G1Powers[1]
    assert proof[0] == new_srs[0][1]

    # 3. check newSRS.G1s[1] (g₁^τ'), is correctly related to prev_srs.G1s[1] (g₁^τ)
	#   e([τ]₁, [p]₂) == e([τ']₁, [1]₂)
    assert e.pair(prev_srs[0][1], proof[1]) == e.pair(new_srs[0][1], e.G2)

    # 4. check newSRS following the powers of tau structure
    # i) e([τ'ⁱ]₁, [τ']₂) == e([τ'ⁱ⁺¹]₁, [1]₂), for i ∈ [1, n−1]
    for i in range(0, len(new_srs[0])-1):
        assert e.pair(new_srs[0][i], new_srs[1][1]) == e.pair(new_srs[0][i+1], e.G2)

    # ii) e([τ']₁, [τ'ʲ]₂) == e([1]₁, [τ'ʲ⁺¹]₂), for j ∈ [1, m−1]
    for i in range(0, len(new_srs[1])-1):
        assert e.pair(new_srs[0][1], new_srs[1][i]) == e.pair(e.G1, new_srs[1][i+1])





(prev_srs) = new_empty_SRS(5, 3)

random = 12345
tau = new_tau(random)

new_srs = compute_contribution(tau, prev_srs)

proof = generate_proof(tau, prev_srs, new_srs)

verify(prev_srs, new_srs, proof)
