# amm-edge

Design a dynamic fee strategy for a constant-product AMM. The agent modifies
`strategy.sol` — a Solidity contract that sets bid/ask fees each trade — and
is scored on its average **edge** across 1,000 simulations against a 30 bps
normalizer AMM.

## Setup

1. **Read the in-scope files**:
   - `strategy.sol` — the Solidity strategy agents modify. Must define a
     `contract Strategy is AMMStrategyBase` with `afterInitialize`, `afterSwap`,
     and `getName` functions. You modify this.
   - `eval/eval.sh` — runs `amm-match run strategy.sol --simulations 1000`
     and prints the edge score. Do not modify.
   - `prepare.sh` — builds the Rust simulation engine and installs the
     Python package and solc. Do not modify.
   - `contracts/src/AMMStrategyBase.sol`, `contracts/src/IAMMStrategy.sol` —
     base contract and interface your strategy inherits. Reference only.
   - `amm_competition/`, `amm_sim_rs/`, `contracts/`, `tests/`, `pyproject.toml` —
     the simulation harness. Do not modify.

2. **Run prepare**: `bash prepare.sh` to build the Rust engine and install
   dependencies. First run takes a few minutes for the Rust build.

3. **Verify setup**: `amm-match --help` should work. `contracts/src/`
   should contain `AMMStrategyBase.sol` and `IAMMStrategy.sol`.

4. **Initialize results.tsv**: Create `results.tsv` with just the header row.

5. **Run baseline**: `bash eval/eval.sh` to establish the starting score
   (StarterStrategy — fixed 50 bps fees).

## The benchmark

Each simulation runs 10,000 steps of a constant-product AMM alongside a
fixed-fee "normalizer" AMM (30 bps). A fair price evolves via geometric
Brownian motion; arbitrageurs trade against mispricings; retail flow arrives
via Poisson and splits across AMMs optimally. Your strategy sets its own
bid/ask fees via `afterInitialize` (once) and `afterSwap` (after every trade
that hits your AMM). The score is mean edge across 1,000 such simulations
with hyperparameter variance on volatility, retail rate, and retail size.

**Edge** is defined per-trade using the fair price at trade time:
- For sells (AMM sells X): `edge += amount_x * fair_price - amount_y`
- For buys  (AMM buys  X): `edge += amount_y - amount_x * fair_price`

Retail trades produce positive edge; arbitrage trades produce negative edge.
Higher fees earn more per retail trade but lose volume to the normalizer and
leave larger arbitrageable spreads — there is no free lunch.

See `README.md` for the full math (price process, arbitrage, order routing)
and an example adaptive-fee strategy.

## Experimentation

**What you CAN do:**
- Modify `strategy.sol`. Any Solidity that compiles under 0.8.24, inherits
  `AMMStrategyBase`, and exports the three required functions is fair game.
- Use the 32 inherited storage slots (`slots[0..31]`) to keep state across
  trades (e.g., track recent trade sizes, moving averages, volatility proxies).
- Use the WAD helpers from `AMMStrategyBase` (`wmul`, `wdiv`, `sqrt`,
  `bpsToWad`, `clampFee`).

**What you CANNOT do:**
- Modify `eval/`, `prepare.sh`, `requirements.txt`, `program.md`, `README.md`,
  `pyproject.toml`, or anything under `amm_competition/`, `amm_sim_rs/`,
  `contracts/`, `tests/`.
- Return fees above 10% — `clampFee` caps the output.
- Declare new storage variables. Only the inherited `slots` array is allowed;
  the compiler rejects strategies that introduce extra storage slots.
- Use forbidden opcodes (BALANCE, EXTCODESIZE, CALL, DELEGATECALL, CREATE,
  SELFDESTRUCT, etc.); the compiler rejects these.

**The goal: maximize `edge`.** Higher is better. The 30 bps normalizer
typically scores around 250–350 edge; a naive fixed-fee strategy that
deviates from 30 bps scores meaningfully worse.

**Simplicity criterion**: All else being equal, simpler is better.

## Output format

    ---
    edge:            <average edge across 1000 simulations>
    correct:         1000
    total:           1000
