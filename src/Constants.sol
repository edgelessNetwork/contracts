// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IDAI } from "./interfaces/IDAI.sol";
import { ILido } from "./interfaces/ILido.sol";
import { IUSDT } from "./interfaces/IUSDT.sol";
import { IUSDC } from "./interfaces/IUSDC.sol";
import { ICurve3Pool } from "./interfaces/ICurve3Pool.sol";
import { IDssPsm } from "./interfaces/IDssPsm.sol";
import { IDsrManager } from "./interfaces/IDsrManager.sol";
import { IWithdrawalQueueERC721 } from "./interfaces/IWithdrawalQueueERC721.sol";

IDAI constant DAI = IDAI(0x6B175474E89094C44Da98b954EedeAC495271d0F);
ILido constant LIDO = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
IUSDC constant USDC = IUSDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
IUSDT constant USDT = IUSDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);

ICurve3Pool constant CURVE_3POOL = ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
IDssPsm constant PSM = IDssPsm(0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A);

IDsrManager constant DSR_MANAGER = IDsrManager(0x373238337Bfe1146fb49989fc222523f83081dDb);
IWithdrawalQueueERC721 constant LIDO_WITHDRAWAL_ERC721 =
    IWithdrawalQueueERC721(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1);

uint256 constant _RAY = 10 ** 27;
