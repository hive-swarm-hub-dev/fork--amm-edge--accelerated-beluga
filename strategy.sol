// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AMMStrategyBase} from "./AMMStrategyBase.sol";
import {IAMMStrategy, TradeInfo} from "./IAMMStrategy.sol";

contract Strategy is AMMStrategyBase {
    uint256 public constant BASE = 65 * BPS;
    uint256 public constant T1 = 280 * BPS;
    uint256 public constant T2 = 600 * BPS;
    uint256 public constant T3 = 1000 * BPS;
    uint256 public constant DECAY = 30 * BPS;

    function afterInitialize(uint256, uint256) external override returns (uint256, uint256) {
        slots[0] = BASE;
        return (BASE, BASE);
    }

    function afterSwap(TradeInfo calldata trade) external override returns (uint256, uint256) {
        uint256 fee = slots[0];
        uint256 ratio = wdiv(trade.amountY, trade.reserveY);
        if (ratio > 7 * WAD / 100) {
            if (fee < T3) fee = T3;
        } else if (ratio > 3 * WAD / 100) {
            if (fee < T2) fee = T2;
        } else if (ratio > 12 * WAD / 1000) {
            if (fee < T1) fee = T1;
        } else if (fee > BASE) {
            fee = fee > BASE + DECAY ? fee - DECAY : BASE;
        }
        slots[0] = fee;
        return (fee, fee);
    }

    function getName() external pure override returns (string memory) {
        return "WidenTarget3Tier";
    }
}
