// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AMMStrategyBase} from "./AMMStrategyBase.sol";
import {IAMMStrategy, TradeInfo} from "./IAMMStrategy.sol";

contract Strategy is AMMStrategyBase {
    uint256 public constant BASE = 65 * BPS;
    uint256 public constant DECAY = 12 * BPS;

    function afterInitialize(uint256, uint256) external override returns (uint256, uint256) {
        slots[0] = BASE;
        slots[1] = 0;
        slots[2] = 0;
        return (BASE, BASE);
    }

    function afterSwap(TradeInfo calldata trade) external override returns (uint256, uint256) {
        uint256 fee = slots[0];
        uint256 burstCount = slots[1];
        uint256 lastBigTs = slots[2];

        uint256 ratio = wdiv(trade.amountY, trade.reserveY);
        if (ratio > 12 * WAD / 1000) {
            uint256 gap = trade.timestamp > lastBigTs ? trade.timestamp - lastBigTs : 0;
            if (gap < 50) {
                burstCount = burstCount + 1;
            } else {
                burstCount = 1;
            }
            slots[1] = burstCount;
            slots[2] = trade.timestamp;

            uint256 bump = 80 * BPS;
            if (burstCount >= 2) bump = 150 * BPS;
            if (burstCount >= 3) bump = 220 * BPS;
            fee = clampFee(fee + bump);
        } else if (fee > BASE) {
            fee = fee > BASE + DECAY ? fee - DECAY : BASE;
            if (burstCount > 0 && trade.timestamp > lastBigTs + 100) slots[1] = 0;
        }

        slots[0] = fee;
        return (fee, fee);
    }

    function getName() external pure override returns (string memory) {
        return "BurstDetect";
    }
}
