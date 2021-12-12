pragma solidity >=0.5.0;

import {IKodiaqPair} from "../../interfaces/IKodiaqPair.sol";
import {IKodiaqFactory} from "../../interfaces/IKodiaqFactory.sol";
import {IKodiaqRouter} from "../../interfaces/IKodiaqRouter.sol";

library KodiaqLibrary {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "KodiaqLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "KodiaqLibrary: ZERO_ADDRESS");
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        return IKodiaqFactory(factory).getPair(token0, token1);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint112 reserveA, uint112 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint112 reserve0, uint112 reserve1, ) = IKodiaqPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "KodiaqLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "KodiaqLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * (reserveB)) / reserveA;
    }

    function getQuote(
        IKodiaqRouter router,
        uint256 inAmount,
        address inToken,
        address outToken
    ) internal view returns (uint256) {
        (uint112 inReserves, uint112 outReserves) = getReserves(router.factory(), inToken, outToken);
        return quote(inAmount, inReserves, outReserves);
    }
}
