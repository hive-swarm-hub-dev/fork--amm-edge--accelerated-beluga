// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {AMMStrategyBase} from "./AMMStrategyBase.sol";
import {IAMMStrategy, TradeInfo} from "./IAMMStrategy.sol";
contract Strategy is AMMStrategyBase {
    uint256 public constant BASE = 29 * BPS;
    function afterInitialize(uint256, uint256) external override returns (uint256, uint256) {
        slots[0] = BASE; return (BASE, BASE);
    }
    function afterSwap(TradeInfo calldata trade) external override returns (uint256, uint256) {
        uint256 fee = slots[0];
        uint256 spot = wdiv(trade.reserveY, trade.reserveX);
        uint256 xAsY = wmul(trade.amountX, spot);
        // For AMM-buys-X, amountX is gross; for AMM-sells-X, amountX is net.
        // Adjust: for isBuy, multiply xAsY by 1.05 to compensate fee on input
        if (trade.isBuy) xAsY = xAsY * 105 / 100;
        uint256 a = trade.amountY > xAsY ? trade.amountY : xAsY;
        uint256 r = a / (24 * WAD);
        uint256 bump = r * 36 * BPS;
        if (r == 1) {
            if (a < 26 * WAD) bump = bump / 4;
            else if (a < 35 * WAD) bump = bump / 2;
            else if (a < 42 * WAD) bump = bump * 3 / 4;
        }
        if (r == 2 && a < 60 * WAD) bump = bump * 3 / 4;
        if (r == 3 && a < 95 * WAD) bump = bump * 7 / 8;
        if (r == 4 && a < 110 * WAD) bump = bump * 15 / 16;
        uint256 target = clampFee(BASE + bump);
        if (fee < target) fee = target;
        else if (fee > BASE) {
            uint256 nf = fee * 85 / 100; fee = nf > BASE ? nf : BASE;
        }
        slots[0] = fee; return (fee, fee);
    }
    function getName() external pure override returns (string memory) { return "BuyBoost"; }
}
