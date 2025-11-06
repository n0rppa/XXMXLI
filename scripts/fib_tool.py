#!/usr/bin/env python3
"""
Lightweight Fibonacci retracement tool using CoinGecko (no external deps).

Features:
- Fetches historical market data for one or more coins
- Computes min/max and standard Fibonacci retracement levels
- Classifies current price vs. levels into simple zones
- Optionally constructs 3 simple "pools" across multiple coins:
  Value (deep retrace), Neutral (mid), Momentum (shallow retrace/near highs)

Usage examples:
  python3 scripts/fib_tool.py --coin bitcoin --vs usd --days 90 --interval daily
  python3 scripts/fib_tool.py --coins bitcoin,ethereum,solana --days 180 --pools

Notes:
- No third-party libraries. Uses urllib only.
- CoinGecko free API; avoid large coin lists to respect rate limits.
"""

import argparse
import sys
import json
import time
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
from urllib.request import urlopen, Request
from urllib.parse import urlencode


API_BASE = "https://api.coingecko.com/api/v3"


@dataclass
class Series:
    coin: str
    vs: str
    days: int
    interval: str
    prices: List[Tuple[int, float]]  # (timestamp_ms, price)

    @property
    def current(self) -> Optional[float]:
        return self.prices[-1][1] if self.prices else None

    @property
    def low_high(self) -> Optional[Tuple[float, float]]:
        if not self.prices:
            return None
        values = [p for _, p in self.prices]
        low, high = min(values), max(values)
        return (low, high)


def http_get_json(path: str, params: Dict[str, str]) -> Dict:
    q = urlencode(params)
    url = f"{API_BASE}{path}?{q}"
    req = Request(url, headers={"User-Agent": "xxmxli-fib-tool/1.0"})
    with urlopen(req, timeout=20) as resp:
        if resp.status != 200:
            raise RuntimeError(f"HTTP {resp.status} for {url}")
        body = resp.read()
        return json.loads(body)


def fetch_market_chart(coin: str, vs: str, days: int, interval: str) -> Series:
    data = http_get_json(
        f"/coins/{coin}/market_chart",
        {"vs_currency": vs, "days": str(days), "interval": interval},
    )
    prices = data.get("prices", [])
    # Each item is [timestamp_ms, price]
    clean: List[Tuple[int, float]] = []
    for it in prices:
        try:
            ts = int(it[0])
            px = float(it[1])
            clean.append((ts, px))
        except Exception:
            continue
    return Series(coin=coin, vs=vs, days=days, interval=interval, prices=clean)


def fib_levels(low: float, high: float) -> Dict[str, float]:
    # Standard retracement levels from high back to low
    # 0% = high, 100% = low
    diff = high - low
    levels = {
        "0.0%": high,
        "23.6%": high - 0.236 * diff,
        "38.2%": high - 0.382 * diff,
        "50.0%": high - 0.5 * diff,
        "61.8%": high - 0.618 * diff,
        "78.6%": high - 0.786 * diff,
        "100%": low,
    }
    return levels


def nearest_level(levels: Dict[str, float], price: float) -> Tuple[str, float]:
    best_key = None
    best_val = None
    best_diff = float("inf")
    for k, v in levels.items():
        d = abs(price - v)
        if d < best_diff:
            best_key, best_val, best_diff = k, v, d
    return best_key or "", best_val if best_val is not None else float("nan")


def classify_zone(levels: Dict[str, float], price: float) -> str:
    # Zones by typical heuristic
    l0 = levels["0.0%"]
    l236 = levels["23.6%"]
    l382 = levels["38.2%"]
    l50 = levels["50.0%"]
    l618 = levels["61.8%"]
    l786 = levels["78.6%"]
    l100 = levels["100%"]
    if price >= l236:
        return "Momentum (near highs)"
    if l382 <= price < l236:
        return "Shallow retrace"
    if l50 <= price < l382:
        return "Mid retrace"
    if l618 <= price < l50:
        return "Deep retrace (value zone)"
    if l786 <= price < l618:
        return "Very deep retrace (high risk/reward)"
    if price < l786:
        return "Capitulation zone"
    return "Unclassified"


def analyze_coin(coin: str, vs: str, days: int, interval: str) -> Dict:
    series = fetch_market_chart(coin, vs, days, interval)
    if not series.prices:
        raise RuntimeError(f"No price data for {coin}")
    low_high = series.low_high
    if not low_high:
        raise RuntimeError(f"Unable to compute min/max for {coin}")
    low, high = low_high
    levels = fib_levels(low, high)
    current = series.current or float("nan")
    zone = classify_zone(levels, current)
    near_k, near_v = nearest_level(levels, current)
    return {
        "coin": coin,
        "vs": vs,
        "days": days,
        "interval": interval,
        "low": low,
        "high": high,
        "current": current,
        "levels": levels,
        "zone": zone,
        "nearest": {"level": near_k, "value": near_v},
    }


def construct_pools(results: List[Dict]) -> Dict[str, List[Dict]]:
    pools = {
        "Value": [],         # deep/very deep retrace
        "Neutral": [],       # mid retrace
        "Momentum": [],      # shallow/momentum
    }
    for r in results:
        z = r.get("zone", "")
        if "Deep retrace" in z or "Very deep" in z or "Capitulation" in z:
            pools["Value"].append(r)
        elif "Mid retrace" in z:
            pools["Neutral"].append(r)
        else:
            pools["Momentum"].append(r)
    # Sort each pool by distance to nearest level (tighter first)
    def dist(r: Dict) -> float:
        try:
            return abs((r["current"] or 0.0) - (r["nearest"]["value"] or 0.0))
        except Exception:
            return float("inf")
    for k in pools:
        pools[k].sort(key=dist)
    return pools


def print_human(results: List[Dict], pools: Optional[Dict[str, List[Dict]]] = None) -> None:
    for r in results:
        print(f"\n=== {r['coin']} / {r['vs']} — {r['days']}d {r['interval']} ===")
        print(f"Range: low={r['low']:.6g}, high={r['high']:.6g}")
        print(f"Current: {r['current']:.6g}")
        print("Fibonacci levels:")
        for k in ["0.0%","23.6%","38.2%","50.0%","61.8%","78.6%","100%"]:
            v = r['levels'][k]
            print(f"  {k:>5} -> {v:.6g}")
        near = r["nearest"]
        print(f"Nearest: {near['level']} @ {near['value']:.6g} | Zone: {r['zone']}")

    if pools is not None:
        print("\n=== Suggested Pools ===")
        for name in ["Value", "Neutral", "Momentum"]:
            items = pools.get(name, [])
            if not items:
                print(f"{name}: (none)")
                continue
            symbols = [f"{it['coin']} ({it['zone']})" for it in items]
            print(f"{name}: " + ", ".join(symbols))


def parse_args(argv: List[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Fibonacci retracement tool (CoinGecko)")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--coin", help="single coin id (e.g., bitcoin)")
    g.add_argument("--coins", help="comma-separated coin ids (e.g., bitcoin,ethereum,solana)")
    p.add_argument("--vs", default="usd", help="quote currency (default: usd)")
    p.add_argument("--days", type=int, default=90, help="lookback days (default: 90)")
    p.add_argument("--interval", choices=["daily", "hourly"], default="daily", help="data interval")
    p.add_argument("--pools", action="store_true", help="construct value/neutral/momentum pools (requires --coins)")
    p.add_argument("--json", action="store_true", help="output JSON instead of human text")
    return p.parse_args(argv)


def main(argv: List[str]) -> int:
    args = parse_args(argv)
    vs = args.vs
    days = args.days
    interval = args.interval

    coin_list: List[str]
    if args.coin:
        coin_list = [args.coin.strip()]
    else:
        coin_list = [c.strip() for c in (args.coins or "").split(",") if c.strip()]
        if not coin_list:
            print("No coins provided.", file=sys.stderr)
            return 2

    results: List[Dict] = []
    for i, coin in enumerate(coin_list):
        try:
            res = analyze_coin(coin, vs, days, interval)
            results.append(res)
        except Exception as e:
            print(f"Error analyzing {coin}: {e}", file=sys.stderr)
        # Be gentle if many coins
        if i < len(coin_list) - 1:
            time.sleep(0.3)

    if args.pools and len(coin_list) > 1:
        pools = construct_pools(results)
    else:
        pools = None

    if args.json:
        out = {"results": results, "pools": pools}
        print(json.dumps(out, indent=2))
    else:
        print_human(results, pools)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
