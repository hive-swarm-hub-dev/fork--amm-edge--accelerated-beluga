// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {AMMStrategyBase} from "./AMMStrategyBase.sol";
import {IAMMStrategy, TradeInfo} from "./IAMMStrategy.sol";
contract Strategy is AMMStrategyBase {
    uint256 public constant BASE = 30 * BPS;
    uint256 public constant THR = 4 * WAD / 1000;
    uint256 public constant SCALE = 140;
    uint256 public constant DRIFT_THR = 50 * BPS;
    uint256 public constant DRIFT_SCALE = 30;

    function afterInitialize(uint256 ix, uint256) external override returns (uint256, uint256) {
        slots[0] = BASE; slots[1] = ix; return (BASE, BASE);
    }

    function afterSwap(TradeInfo calldata trade) external override returns (uint256, uint256) {
        uint256 fee = slots[0];
        uint256 ix = slots[1];
        uint256 rx = trade.reserveX;
        uint256 driftX = rx > ix ? wdiv(rx - ix, ix) : wdiv(ix - rx, ix);

        uint256 ratio = wdiv(trade.amountY, trade.reserveY);
        if (ratio > THR) {
            uint256 bump = ratio * SCALE / 100;
            uint256 t = clampFee(BASE + bump);
            if (fee < t) fee = t;
        }
        // additional widen on inventory drift
        if (driftX > DRIFT_THR) {
            uint256 dbump = driftX * DRIFT_SCALE / 100;
            uint256 dt = clampFee(BASE + dbump);
            if (fee < dt) fee = dt;
        } else if (ratio <= THR && fee > BASE) {
            uint256 nf = fee * 85 / 100;
            fee = nf > BASE ? nf : BASE;
        }
        slots[0] = fee;
        return (fee, fee);
    }
    function getName() external pure override returns (string memory) { return "DriftOverlay"; }
}
