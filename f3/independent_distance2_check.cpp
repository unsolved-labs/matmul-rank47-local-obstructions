// Independent complete F3 support-distance-two verifier for R006.
//
// This implementation intentionally differs from verify_distance2_parallel.py:
// - it uses a fixed 2256-variable sign space rather than renumbering active
//   support entries;
// - it uses 36-word rows and its own exact GF(2) elimination;
// - it parses only a minimal text interchange emitted by
//   export_distance2_inputs.py, so no mathematical logic is shared there.
//
// Compile: g++ -O3 -std=c++20 -fopenmp -o independent_distance2_check \
//          f3/independent_distance2_check.cpp

#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#ifdef _OPENMP
#include <omp.h>
#endif

namespace {

constexpr int D = 16;
constexpr int R = 47;
constexpr int Q = 3;
constexpr int NVARS = Q * R * D;  // 2256 fixed possible factor-sign variables
constexpr int WORDS = (NVARS + 63) / 64;

struct Coord {
    int a{}, b{}, c{};
};

struct Edit {
    int q{}, r{}, i{};
};

using FactorRow = std::array<std::uint8_t, D>;
using Factor = std::array<FactorRow, R>;
using Support = std::array<Factor, Q>;

struct Row {
    std::array<std::uint64_t, WORDS> bits{};
    bool rhs = false;
};

struct Input {
    Support support{};
    std::vector<Coord> base_certificate;
    std::array<std::vector<Coord>, NVARS> dedicated{};
    std::array<bool, NVARS> has_dedicated{};
    int dedicated_count = 0;
};

int edit_index(int q, int r, int i) {
    return (q * R + r) * D + i;
}

Edit decode_edit(int x) {
    Edit e;
    e.i = x % D;
    x /= D;
    e.r = x % R;
    e.q = x / R;
    return e;
}

bool target(int a, int b, int c) {
    const int i = a / 4;
    const int j = a % 4;
    const int j2 = b / 4;
    const int k = b % 4;
    return j == j2 && c == 4 * k + i;
}

void toggle(Support& M, Edit e) {
    M[e.q][e.r][e.i] ^= 1U;
}

void xor_row(Row& a, const Row& b) {
    for (int w = 0; w < WORDS; ++w) a.bits[w] ^= b.bits[w];
    a.rhs = (a.rhs != b.rhs);
}

bool row_zero(const Row& r) {
    for (std::uint64_t w : r.bits) {
        if (w != 0) return false;
    }
    return true;
}

int highest_bit(const Row& r) {
    for (int w = WORDS - 1; w >= 0; --w) {
        const std::uint64_t x = r.bits[w];
        if (x != 0) {
            return 64 * w + (63 - __builtin_clzll(x));
        }
    }
    return -1;
}

void set_bit(Row& r, int bit) {
    r.bits[bit / 64] ^= (std::uint64_t{1} << (bit % 64));
}

// Return false only when this coordinate does not yield one of the necessary
// parity equations used by R006. A zero row with rhs=1 is a direct
// contradiction and is represented normally.
bool parity_equation(const Support& M, Coord x, Row& out) {
    out = Row{};
    std::array<int, R> terms{};
    int k = 0;
    for (int r = 0; r < R; ++r) {
        if (M[0][r][x.a] && M[1][r][x.b] && M[2][r][x.c]) {
            terms[k++] = r;
        }
    }

    const int t = target(x.a, x.b, x.c) ? 1 : 0;
    if (k == 0) {
        if (t == 1) {
            out.rhs = true;
            return true;
        }
        return false;
    }
    if (k > 4) return false;

    int neg = (t - k) % 3;
    if (neg < 0) neg += 3;
    if (neg > k || neg + 3 <= k) return false;

    for (int z = 0; z < k; ++z) {
        const int r = terms[z];
        set_bit(out, edit_index(0, r, x.a));
        set_bit(out, edit_index(1, r, x.b));
        set_bit(out, edit_index(2, r, x.c));
    }
    out.rhs = (neg & 1) != 0;
    return true;
}

bool affects(const Support& M, Edit e, const std::vector<Coord>& coords) {
    for (const Coord& x : coords) {
        const int v[3] = {x.a, x.b, x.c};
        if (v[e.q] != e.i) continue;
        bool other_active = true;
        for (int q = 0; q < Q; ++q) {
            if (q == e.q) continue;
            if (!M[q][e.r][v[q]]) {
                other_active = false;
                break;
            }
        }
        if (other_active) return true;
    }
    return false;
}

bool certificate_holds(const Support& M, const std::vector<Coord>& coords) {
    Row sum{};
    for (const Coord& x : coords) {
        Row eq{};
        if (!parity_equation(M, x, eq)) return false;
        xor_row(sum, eq);
    }
    return row_zero(sum) && sum.rhs;
}

bool contradiction(const Support& M) {
    std::array<Row, NVARS> pivots{};
    std::array<bool, NVARS> has{};
    has.fill(false);

    for (int a = 0; a < D; ++a) {
        for (int b = 0; b < D; ++b) {
            for (int c = 0; c < D; ++c) {
                Row row{};
                if (!parity_equation(M, Coord{a, b, c}, row)) continue;
                if (row_zero(row)) {
                    if (row.rhs) return true;
                    continue;
                }

                while (!row_zero(row)) {
                    const int p = highest_bit(row);
                    if (!has[p]) {
                        pivots[p] = row;
                        has[p] = true;
                        break;
                    }
                    xor_row(row, pivots[p]);
                }
                if (row_zero(row) && row.rhs) return true;
            }
        }
    }
    return false;
}

Input read_input(const std::string& path) {
    std::ifstream in(path);
    if (!in) throw std::runtime_error("cannot open " + path);

    Input data;
    std::string tag;
    int rank = 0;
    in >> tag >> rank;
    if (!in || tag != "R" || rank != R) throw std::runtime_error("bad rank header");

    for (int n = 0; n < Q * R; ++n) {
        int q = -1, r = -1;
        std::string bits;
        in >> tag >> q >> r >> bits;
        if (!in || tag != "F" || q < 0 || q >= Q || r < 0 || r >= R ||
            static_cast<int>(bits.size()) != D) {
            throw std::runtime_error("bad factor row");
        }
        for (int i = 0; i < D; ++i) {
            if (bits[i] != '0' && bits[i] != '1') throw std::runtime_error("bad factor bit");
            data.support[q][r][i] = static_cast<std::uint8_t>(bits[i] - '0');
        }
    }

    int base_n = 0;
    in >> tag >> base_n;
    if (!in || tag != "B" || base_n <= 0) throw std::runtime_error("bad base certificate header");
    data.base_certificate.reserve(base_n);
    for (int n = 0; n < base_n; ++n) {
        Coord x;
        in >> tag >> x.a >> x.b >> x.c;
        if (!in || tag != "C") throw std::runtime_error("bad base coordinate");
        data.base_certificate.push_back(x);
    }

    int dedicated_n = 0;
    in >> tag >> dedicated_n;
    if (!in || tag != "D" || dedicated_n < 0 || dedicated_n > NVARS) {
        throw std::runtime_error("bad dedicated certificate header");
    }
    data.dedicated_count = dedicated_n;
    for (int n = 0; n < dedicated_n; ++n) {
        Edit e;
        int m = 0;
        in >> tag >> e.q >> e.r >> e.i >> m;
        if (!in || tag != "E" || e.q < 0 || e.q >= Q || e.r < 0 || e.r >= R ||
            e.i < 0 || e.i >= D || m <= 0) {
            throw std::runtime_error("bad dedicated certificate entry");
        }
        const int idx = edit_index(e.q, e.r, e.i);
        if (data.has_dedicated[idx]) throw std::runtime_error("duplicate dedicated certificate");
        data.has_dedicated[idx] = true;
        data.dedicated[idx].reserve(m);
        for (int j = 0; j < m; ++j) {
            Coord x;
            in >> tag >> x.a >> x.b >> x.c;
            if (!in || tag != "C") throw std::runtime_error("bad dedicated coordinate");
            data.dedicated[idx].push_back(x);
        }
    }

    std::string extra;
    if (in >> extra) throw std::runtime_error("unexpected trailing input");
    return data;
}

}  // namespace

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "usage: independent_distance2_check INPUT.txt\n";
        return 2;
    }

    try {
        const Input input = read_input(argv[1]);
        const long long pair_total = static_cast<long long>(NVARS) * (NVARS - 1) / 2;
        long long preserved = 0;
        long long fresh = 0;
        long long survivors = 0;
        long long cert_failures = 0;
        long long dedicated_used = 0;

#pragma omp parallel for schedule(dynamic, 1) reduction(+ : preserved, fresh, survivors, cert_failures, dedicated_used)
        for (int first = 0; first < NVARS; ++first) {
            Support M = input.support;
            const Edit e1 = decode_edit(first);
            const bool needs_dedicated = affects(M, e1, input.base_certificate);
            const std::vector<Coord>* cert = &input.base_certificate;
            if (needs_dedicated) {
                ++dedicated_used;
                if (!input.has_dedicated[first]) {
                    ++cert_failures;
                    continue;
                }
                cert = &input.dedicated[first];
            }

            toggle(M, e1);
            if (!certificate_holds(M, *cert)) {
                ++cert_failures;
                continue;
            }

            for (int second = first + 1; second < NVARS; ++second) {
                const Edit e2 = decode_edit(second);
                if (!affects(M, e2, *cert)) {
                    ++preserved;
                    continue;
                }
                ++fresh;
                toggle(M, e2);
                if (!contradiction(M)) ++survivors;
                toggle(M, e2);
            }
        }

        std::cout << "INDEPENDENT CXX COMPLETE SWEEP\n";
        std::cout << "all_first_edits " << NVARS << "\n";
        std::cout << "dedicated_first_certificates " << dedicated_used << "\n";
        std::cout << "distance2_pairs_total " << pair_total << "\n";
        std::cout << "pairs_certified_by_preserved_certificate " << preserved << "\n";
        std::cout << "pairs_requiring_fresh_global_parity_check " << fresh << "\n";
        std::cout << "certificate_failures " << cert_failures << "\n";
        std::cout << "consistent_pair_count " << survivors << "\n";

        if (dedicated_used != input.dedicated_count || cert_failures != 0 ||
            preserved + fresh != pair_total || survivors != 0) {
            return 1;
        }
        std::cout << "INDEPENDENT CXX R006 F3 DISTANCE-2 CHECK PASSED\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "error: " << e.what() << "\n";
        return 2;
    }
}
