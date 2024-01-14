// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { IDai } from "./interfaces/IDai.sol";
import { ILido } from "./interfaces/ILido.sol";
import { IUsdt } from "./interfaces/IUsdt.sol";
import { IUSDC } from "./interfaces/IUSDC.sol";
import { ICurve3Pool } from "./interfaces/ICurve3Pool.sol";
import { IDssPsm } from "./interfaces/IDssPsm.sol";
import { IDsrManager } from "./interfaces/IDsrManager.sol";
import { IWithdrawalQueueERC721 } from "./interfaces/IWithdrawalQueueERC721.sol";

// Ethereum Constants
IDai constant Dai = IDai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
ILido constant LIDO = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
IUSDC constant USDC = IUSDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
IUsdt constant Usdt = IUsdt(0xdAC17F958D2ee523a2206206994597C13D831ec7);

ICurve3Pool constant CURVE_3POOL = ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
IDssPsm constant PSM = IDssPsm(0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A);

IDsrManager constant DSR_MANAGER = IDsrManager(0x373238337Bfe1146fb49989fc222523f83081dDb);
IWithdrawalQueueERC721 constant LIDO_WITHDRAWAL_ERC721 =
    IWithdrawalQueueERC721(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1);

// Ethereum Goerli Constants
// IDai constant Dai = IDai(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);
// ILido constant LIDO = ILido(0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F);
// IUSDC constant USDC = IUSDC(0x6Fb5ef893d44F4f88026430d82d4ef269543cB23);
// IUsdt constant Usdt = IUsdt(0x5858f25cc225525A7494f76d90A6549749b3030B); // need to be tradeable for Dai on curve

// ICurve3Pool constant CURVE_3POOL = ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7); // Unfortunately, curve
// is not supported on goerli, thus, Usdt deposits are not supported
// IDssPsm constant PSM = IDssPsm(0xb480B8dD5A232Cb7B227989Eacda728D1F247dB6);

// IDsrManager constant DSR_MANAGER = IDsrManager(0xF7F0de3744C82825D77EdA8ce78f07A916fB6bE7);
// IWithdrawalQueueERC721 constant LIDO_WITHDRAWAL_ERC721 =
//     IWithdrawalQueueERC721(0xCF117961421cA9e546cD7f50bC73abCdB3039533);

uint256 constant _RAY = 10 ** 27;
