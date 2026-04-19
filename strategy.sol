// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AMMStrategyBase} from "./AMMStrategyBase.sol";
import {IAMMStrategy, TradeInfo} from "./IAMMStrategy.sol";

contract Strategy is AMMStrategyBase {
    uint256 public constant BASE = 80 * BPS;

    function afterInitialize(uint256 initialX, uint256) external override returns (uint256, uint256) {
        slots[0] = initialX;
        return (BASE, BASE);
    }

    function afterSwap(TradeInfo calldata trade) external override returns (uint256, uint256) {
        uint256 baselineX = slots[0];
        uint256 rx = trade.reserveX;

        uint256 bidFee = BASE;
        uint256 askFee = BASE;

        if (rx < baselineX) {
            uint256 imbalance = baselineX - rx;
            uint256 ratio = wdiv(imbalance, baselineX);
            uint256 adj = wmul(ratio, bpsToWad(500));
            askFee = clampFee(BASE + adj);
        } else if (rx > baselineX) {
            uint256 imbalance = rx - baselineX;
            uint256 ratio = wdiv(imbalance, baselineX);
            uint256 adj = wmul(ratio, bpsToWad(500));
            bidFee = clampFee(BASE + adj);
        }

        return (bidFee, askFee);
    }

    function getName() external pure override returns (string memory) {
        return "InventorySkew80";
    }
}
