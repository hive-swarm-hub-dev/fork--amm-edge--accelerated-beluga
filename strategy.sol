// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AMMStrategyBase} from "./AMMStrategyBase.sol";
import {IAMMStrategy, TradeInfo} from "./IAMMStrategy.sol";

contract Strategy is AMMStrategyBase {
    uint256 public constant BASE = 29 * BPS;
    uint256 public constant BIG = 30 * WAD;

    function afterInitialize(uint256 ix, uint256 iy) external override returns (uint256, uint256) {
        slots[0] = BASE;
        slots[1] = wdiv(iy, ix);
        slots[2] = 0;
        slots[3] = 0;
        return (BASE, BASE);
    }

    function afterSwap(TradeInfo calldata trade) external override returns (uint256, uint256) {
        uint256 fee = slots[0];
        uint256 fairEst = slots[1];
        uint256 negEdgeBudget = slots[2];

        uint256 spot = wdiv(trade.reserveY, trade.reserveX);

        uint256 r = trade.amountY / (24 * WAD);
        uint256 bump = r * 36 * BPS;
        uint256 target = clampFee(BASE + bump);
        if (fee < target) fee = target;

        if (trade.amountY > BIG) {
            slots[1] = spot;
            negEdgeBudget = 0;
        } else {
            uint256 yAtFair = wmul(trade.amountX, fairEst);
            bool wasNegative;
            if (trade.isBuy) {
                wasNegative = trade.amountY > yAtFair;
            } else {
                wasNegative = trade.amountY < yAtFair;
            }
            if (wasNegative) {
                negEdgeBudget = negEdgeBudget < 5 ? negEdgeBudget + 1 : 5;
                if (negEdgeBudget >= 3) {
                    uint256 t2 = clampFee(BASE + 100 * BPS);
                    if (fee < t2) fee = t2;
                }
            } else {
                negEdgeBudget = negEdgeBudget > 0 ? negEdgeBudget - 1 : 0;
            }
        }

        if (fee > target && fee > BASE) {
            uint256 nf = fee * 85 / 100;
            fee = nf > BASE ? nf : BASE;
        }

        slots[0] = fee;
        slots[2] = negEdgeBudget;
        return (fee, fee);
    }

    function getName() external pure override returns (string memory) {
        return "EdgeSign";
    }
}
