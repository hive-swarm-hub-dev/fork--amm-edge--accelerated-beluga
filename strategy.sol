// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AMMStrategyBase} from "./AMMStrategyBase.sol";
import {IAMMStrategy, TradeInfo} from "./IAMMStrategy.sol";

contract Strategy is AMMStrategyBase {
    uint256 public constant BASE = 65 * BPS;
    uint256 public constant BUMP = 80 * BPS;
    uint256 public constant DECAY = 10 * BPS;

    function afterInitialize(uint256, uint256) external override returns (uint256, uint256) {
        slots[0] = BASE;
        return (BASE, BASE);
    }

    function afterSwap(TradeInfo calldata trade) external override returns (uint256, uint256) {
        uint256 fee = slots[0];
        uint256 ratio = wdiv(trade.amountY, trade.reserveY);
        if (ratio > WAD / 100) {
            fee = clampFee(fee + BUMP);
        } else if (fee > BASE) {
            fee = fee > BASE + DECAY ? fee - DECAY : BASE;
        }
        slots[0] = fee;
        return (fee, fee);
    }

    function getName() external pure override returns (string memory) {
        return "WidenBurst65";
    }
}
