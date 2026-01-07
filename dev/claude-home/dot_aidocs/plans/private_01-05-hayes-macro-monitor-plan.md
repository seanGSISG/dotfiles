# Hayes Macro Monitor - Implementation Plan

> A self-hosted dashboard implementing Arthur Hayes' macro trading framework for monitoring crypto risk-on/risk-off conditions.

## Executive Summary

This project builds a real-time monitoring dashboard that tracks the key signals from Hayes' "Suavemente" thesis (January 2026):

1. **Oil prices** - Must stay flat/falling for continued money printing
2. **10-Year Treasury Yield** - Danger zone at ~5%
3. **MOVE Index** - Bond volatility; spike = imminent policy reversal
4. **ZEC/BTC Ratio** - Privacy narrative beta play
5. **Gas Price 10% Rule** - Election predictor

**Target Server:** MS-01 (10.10.10.5) - Intel i9, 94GB RAM

---

## Phase 1: Infrastructure Setup

### 1.1 Directory Structure

```
/home/adminuser/dev/github/hayes-macro-monitor/
├── CLAUDE.md                           # Project documentation
├── .env                                 # Secrets (gitignored)
├── .env.example                         # Template for secrets
├── .gitignore
├── docker-compose.yml                   # Service orchestration
├── docs/
│   └── plans/
│       └── plan.md                      # This file
├── app/
│   ├── Dockerfile                       # Python fetcher container
│   ├── requirements.txt                 # Python dependencies
│   ├── main.py                          # Data fetcher service
│   ├── signals.py                       # Signal calculation logic
│   ├── sources/
│   │   ├── __init__.py
│   │   ├── yahoo.py                     # Yahoo Finance adapter
│   │   ├── fred.py                      # FRED API adapter (MOVE, yields)
│   │   └── eia.py                       # EIA gas prices adapter
│   └── tests/
│       ├── __init__.py
│       └── test_signals.py              # Unit tests for signal logic
├── grafana/
│   ├── provisioning/
│   │   ├── dashboards/
│   │   │   ├── dashboard.yml            # Dashboard provisioning config
│   │   │   └── hayes-monitor.json       # Pre-built dashboard
│   │   └── datasources/
│   │       └── datasource.yml           # InfluxDB datasource config
│   └── grafana.ini                      # Custom Grafana settings (optional)
└── scripts/
    ├── setup.sh                         # Initial setup script
    └── backup.sh                        # Data backup script
```

### 1.2 Create .env Configuration

**File: `.env`**

```bash
# InfluxDB Configuration
INFLUXDB_ADMIN_USER=admin
INFLUXDB_ADMIN_PASSWORD=<generate-32-char-password>
INFLUXDB_ORG=hayes-monitor
INFLUXDB_BUCKET=macro_signals
INFLUXDB_ADMIN_TOKEN=<generate-64-char-token>

# Grafana Configuration
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=<generate-32-char-password>

# External API Keys (optional, for enhanced data)
FRED_API_KEY=<your-fred-api-key>

# Application Settings
FETCH_INTERVAL_SECONDS=60
LOG_LEVEL=INFO
```

**Steps:**
1. Generate secure passwords: `openssl rand -base64 32`
2. Generate token: `openssl rand -hex 32`
3. Register for FRED API key at https://fred.stlouisfed.org/docs/api/api_key.html

### 1.3 Create .env.example Template

**File: `.env.example`**

```bash
# Copy this file to .env and fill in values
# DO NOT commit .env to version control

# InfluxDB Configuration
INFLUXDB_ADMIN_USER=admin
INFLUXDB_ADMIN_PASSWORD=changeme
INFLUXDB_ORG=hayes-monitor
INFLUXDB_BUCKET=macro_signals
INFLUXDB_ADMIN_TOKEN=changeme

# Grafana Configuration
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=changeme

# External API Keys
FRED_API_KEY=

# Application Settings
FETCH_INTERVAL_SECONDS=60
LOG_LEVEL=INFO
```

### 1.4 Create .gitignore

**File: `.gitignore`**

```
.env
*.pyc
__pycache__/
.pytest_cache/
*.log
data/
```

---

## Phase 2: Docker Compose Configuration

### 2.1 Main Docker Compose File

**File: `docker-compose.yml`**

```yaml
version: '3.8'

services:
  influxdb:
    image: influxdb:2.7
    container_name: hayes_influxdb
    restart: unless-stopped
    ports:
      - "8086:8086"
    environment:
      - DOCKER_INFLUXDB_INIT_MODE=setup
      - DOCKER_INFLUXDB_INIT_USERNAME=${INFLUXDB_ADMIN_USER}
      - DOCKER_INFLUXDB_INIT_PASSWORD=${INFLUXDB_ADMIN_PASSWORD}
      - DOCKER_INFLUXDB_INIT_ORG=${INFLUXDB_ORG}
      - DOCKER_INFLUXDB_INIT_BUCKET=${INFLUXDB_BUCKET}
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=${INFLUXDB_ADMIN_TOKEN}
    volumes:
      - influxdb_data:/var/lib/influxdb2
      - influxdb_config:/etc/influxdb2
    healthcheck:
      test: ["CMD", "influx", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  grafana:
    image: grafana/grafana:10.2.3
    container_name: hayes_grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SERVER_ROOT_URL=http://10.10.10.5:3000
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    depends_on:
      influxdb:
        condition: service_healthy

  fetcher:
    build:
      context: ./app
      dockerfile: Dockerfile
    container_name: hayes_fetcher
    restart: unless-stopped
    environment:
      - INFLUXDB_URL=http://influxdb:8086
      - INFLUXDB_TOKEN=${INFLUXDB_ADMIN_TOKEN}
      - INFLUXDB_ORG=${INFLUXDB_ORG}
      - INFLUXDB_BUCKET=${INFLUXDB_BUCKET}
      - FRED_API_KEY=${FRED_API_KEY}
      - FETCH_INTERVAL_SECONDS=${FETCH_INTERVAL_SECONDS}
      - LOG_LEVEL=${LOG_LEVEL}
    depends_on:
      influxdb:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://influxdb:8086/health')"]
      interval: 60s
      timeout: 10s
      retries: 3

volumes:
  influxdb_data:
  influxdb_config:
  grafana_data:

networks:
  default:
    name: hayes_network
```

### 2.2 Key Docker Compose Features

| Feature | Implementation | Rationale |
|---------|---------------|-----------|
| Health checks | InfluxDB ping before Grafana/fetcher start | Prevents race conditions |
| Volume persistence | Named volumes for data | Survives container rebuilds |
| Environment interpolation | `${VAR}` syntax | Secrets not in compose file |
| Restart policy | `unless-stopped` | Auto-recovery on failure |
| Network isolation | Named network `hayes_network` | Service discovery by hostname |

---

## Phase 3: Data Fetcher Application

### 3.1 Python Dependencies

**File: `app/requirements.txt`**

```
yfinance==0.2.36
pandas==2.1.4
influxdb-client==1.40.0
fredapi==0.5.1
requests==2.31.0
python-dotenv==1.0.0
schedule==1.2.1
structlog==24.1.0
```

### 3.2 Dockerfile

**File: `app/Dockerfile`**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run as non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

CMD ["python", "-u", "main.py"]
```

### 3.3 Yahoo Finance Adapter

**File: `app/sources/yahoo.py`**

```python
"""
Yahoo Finance data adapter for market data.

Tickers:
- CL=F: WTI Crude Oil Futures
- ^TNX: 10-Year Treasury Yield (returned as percentage, e.g., 4.5 = 4.5%)
- ^VIX: CBOE Volatility Index (proxy for MOVE when unavailable)
- ZEC-USD: Zcash
- BTC-USD: Bitcoin
- ETH-USD: Ethereum
"""

import yfinance as yf
import pandas as pd
from datetime import datetime, timedelta
import structlog

logger = structlog.get_logger()

TICKERS = {
    'oil_wti': 'CL=F',
    'yield_10y': '^TNX',
    'vix': '^VIX',
    'zec_usd': 'ZEC-USD',
    'btc_usd': 'BTC-USD',
    'eth_usd': 'ETH-USD',
}


def fetch_current_prices() -> dict:
    """
    Fetch current prices for all tracked tickers.

    Returns:
        dict with keys matching TICKERS keys and float values.
        Returns None for any ticker that fails to fetch.
    """
    results = {}
    ticker_list = list(TICKERS.values())

    try:
        # Fetch 2 days to handle weekends/holidays
        data = yf.download(
            ticker_list,
            period='2d',
            interval='1m',
            progress=False,
            threads=True,
        )

        if data.empty:
            logger.warning("yahoo_empty_response", msg="Market may be closed")
            return None

        # Get most recent close price for each ticker
        for name, ticker in TICKERS.items():
            try:
                if len(ticker_list) > 1:
                    price = data['Close'][ticker].dropna().iloc[-1]
                else:
                    price = data['Close'].dropna().iloc[-1]
                results[name] = float(price)
            except (KeyError, IndexError) as e:
                logger.warning("ticker_fetch_failed", ticker=ticker, error=str(e))
                results[name] = None

    except Exception as e:
        logger.error("yahoo_fetch_error", error=str(e))
        return None

    return results


def fetch_january_baseline(year: int = None) -> dict:
    """
    Fetch average prices for January of the given year.
    Used for the 10% rule calculation.

    Args:
        year: Year to fetch January data for. Defaults to current year.

    Returns:
        dict with average January prices for oil and gas proxies.
    """
    if year is None:
        year = datetime.now().year

    start_date = f"{year}-01-01"
    end_date = f"{year}-01-31"

    try:
        data = yf.download(
            ['CL=F'],  # Oil as gas proxy
            start=start_date,
            end=end_date,
            progress=False,
        )

        if data.empty:
            logger.warning("january_baseline_empty", year=year)
            return None

        return {
            'oil_january_avg': float(data['Close'].mean()),
            'baseline_year': year,
        }

    except Exception as e:
        logger.error("january_baseline_error", error=str(e))
        return None
```

### 3.4 FRED API Adapter

**File: `app/sources/fred.py`**

```python
"""
FRED (Federal Reserve Economic Data) adapter.

Key Series:
- MOVE: ICE BofA MOVE Index (bond market volatility)
- DGS10: 10-Year Treasury Constant Maturity Rate
- GASREGW: US Regular All Formulations Retail Gasoline Prices (Weekly)
"""

import os
from datetime import datetime, timedelta
import structlog

logger = structlog.get_logger()

# Optional dependency - gracefully handle missing API key
try:
    from fredapi import Fred
    FRED_AVAILABLE = True
except ImportError:
    FRED_AVAILABLE = False
    logger.warning("fredapi_not_installed", msg="FRED data source unavailable")


SERIES = {
    'move_index': 'MOVE',          # ICE BofA MOVE Index
    'yield_10y_fred': 'DGS10',     # 10-Year Treasury Rate
    'gas_price_retail': 'GASREGW', # Weekly retail gas price
}


def get_fred_client():
    """Initialize FRED client with API key from environment."""
    api_key = os.getenv('FRED_API_KEY')
    if not api_key:
        logger.warning("fred_api_key_missing")
        return None
    if not FRED_AVAILABLE:
        return None
    return Fred(api_key=api_key)


def fetch_move_index() -> float:
    """
    Fetch the latest MOVE Index value.

    The MOVE Index measures US Treasury bond market volatility.
    Hayes identifies 140+ as elevated, 172 as panic level.

    Returns:
        float: Latest MOVE Index value, or None if unavailable.
    """
    client = get_fred_client()
    if not client:
        return None

    try:
        # MOVE Index updates daily, fetch last 7 days to ensure we get data
        end_date = datetime.now()
        start_date = end_date - timedelta(days=7)

        data = client.get_series(
            'MOVE',
            observation_start=start_date,
            observation_end=end_date,
        )

        if data.empty:
            logger.warning("move_index_empty")
            return None

        return float(data.dropna().iloc[-1])

    except Exception as e:
        logger.error("move_index_error", error=str(e))
        return None


def fetch_gas_price() -> float:
    """
    Fetch the latest US retail gasoline price.

    Used for the 10% rule: if gas rises 10%+ from January baseline
    in the 3 months preceding an election, incumbents lose.

    Returns:
        float: Latest gas price in USD/gallon, or None if unavailable.
    """
    client = get_fred_client()
    if not client:
        return None

    try:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=14)  # Weekly data

        data = client.get_series(
            'GASREGW',
            observation_start=start_date,
            observation_end=end_date,
        )

        if data.empty:
            logger.warning("gas_price_empty")
            return None

        return float(data.dropna().iloc[-1])

    except Exception as e:
        logger.error("gas_price_error", error=str(e))
        return None


def fetch_january_gas_baseline(year: int = None) -> float:
    """
    Fetch average January gas price for baseline comparison.

    Args:
        year: Year to fetch. Defaults to current year.

    Returns:
        float: Average January gas price, or None if unavailable.
    """
    client = get_fred_client()
    if not client:
        return None

    if year is None:
        year = datetime.now().year

    try:
        start_date = f"{year}-01-01"
        end_date = f"{year}-01-31"

        data = client.get_series(
            'GASREGW',
            observation_start=start_date,
            observation_end=end_date,
        )

        if data.empty:
            logger.warning("january_gas_empty", year=year)
            return None

        return float(data.mean())

    except Exception as e:
        logger.error("january_gas_error", error=str(e))
        return None
```

### 3.5 Signal Calculation Logic

**File: `app/signals.py`**

```python
"""
Hayes Macro Signal Calculations

Signal Framework (from "Suavemente" - January 2026):

1. DANGER ZONE SIGNALS:
   - 10Y Yield >= 4.8% (approaching 5% = Fed must act)
   - MOVE Index >= 140 (elevated volatility)
   - MOVE Index >= 172 (panic - policy reversal imminent)
   - Gas price 10%+ above January baseline (election risk)

2. OPPORTUNITY SIGNALS:
   - ZEC/BTC ratio (privacy narrative beta)
   - Low MOVE + expanding liquidity = risk-on

3. NEUTRAL/MONITORING:
   - Oil prices (must stay flat/falling for continued printing)
   - VIX as MOVE proxy when MOVE unavailable
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional
import structlog

logger = structlog.get_logger()


@dataclass
class DangerZoneStatus:
    """Encapsulates danger zone signal status."""
    is_danger: bool
    yield_danger: bool
    move_danger: bool
    move_panic: bool
    gas_10pct_rule: bool
    message: str


# Thresholds from Hayes' analysis
THRESHOLDS = {
    'yield_10y_danger': 4.8,      # Approaching 5% = danger
    'yield_10y_critical': 5.0,    # 5% = Fed must act
    'move_elevated': 140,          # Elevated bond volatility
    'move_panic': 172,             # Panic level (Liberation Day spike)
    'gas_10pct_rule': 0.10,       # 10% increase triggers political risk
}


def calculate_zec_btc_ratio(zec_price: float, btc_price: float) -> Optional[float]:
    """
    Calculate ZEC/BTC ratio.

    Hayes: "ZEC will become the privacy beta"
    Rising ratio = privacy narrative strengthening

    Args:
        zec_price: ZEC price in USD
        btc_price: BTC price in USD

    Returns:
        ZEC/BTC ratio as float, or None if inputs invalid.
    """
    if not zec_price or not btc_price or btc_price == 0:
        return None
    return zec_price / btc_price


def calculate_gas_10pct_rule(
    current_gas: float,
    january_baseline: float,
) -> tuple[float, bool]:
    """
    Calculate the 10% rule for gas prices.

    Hayes: "When national average price of gasoline rises 10% or more
    in the three months preceding an election versus the average price
    in January of the same calendar year, control switches teams."

    Args:
        current_gas: Current gas price
        january_baseline: Average January gas price

    Returns:
        Tuple of (percent_change, is_triggered)
    """
    if not current_gas or not january_baseline or january_baseline == 0:
        return (None, False)

    pct_change = (current_gas - january_baseline) / january_baseline
    is_triggered = pct_change >= THRESHOLDS['gas_10pct_rule']

    return (pct_change, is_triggered)


def evaluate_danger_zone(
    yield_10y: Optional[float],
    move_index: Optional[float],
    gas_pct_change: Optional[float],
) -> DangerZoneStatus:
    """
    Evaluate overall danger zone status.

    Danger zone = credit creation likely to slow = risk-off for crypto

    Args:
        yield_10y: 10-year Treasury yield as percentage (e.g., 4.5 = 4.5%)
        move_index: MOVE Index value
        gas_pct_change: Gas price percent change from January

    Returns:
        DangerZoneStatus with detailed breakdown
    """
    warnings = []

    # Yield check
    yield_danger = False
    if yield_10y is not None:
        if yield_10y >= THRESHOLDS['yield_10y_critical']:
            yield_danger = True
            warnings.append(f"10Y YIELD CRITICAL: {yield_10y:.2f}% (>= 5%)")
        elif yield_10y >= THRESHOLDS['yield_10y_danger']:
            yield_danger = True
            warnings.append(f"10Y yield elevated: {yield_10y:.2f}% (approaching 5%)")

    # MOVE check
    move_danger = False
    move_panic = False
    if move_index is not None:
        if move_index >= THRESHOLDS['move_panic']:
            move_danger = True
            move_panic = True
            warnings.append(f"MOVE PANIC: {move_index:.1f} (>= 172 = policy reversal imminent)")
        elif move_index >= THRESHOLDS['move_elevated']:
            move_danger = True
            warnings.append(f"MOVE elevated: {move_index:.1f} (>= 140)")

    # Gas 10% rule check
    gas_10pct = False
    if gas_pct_change is not None:
        if gas_pct_change >= THRESHOLDS['gas_10pct_rule']:
            gas_10pct = True
            warnings.append(f"GAS 10% RULE TRIGGERED: +{gas_pct_change*100:.1f}% from January")

    # Overall danger assessment
    is_danger = yield_danger or move_panic or gas_10pct

    if not warnings:
        message = "All clear - conditions support continued money printing"
    else:
        message = " | ".join(warnings)

    return DangerZoneStatus(
        is_danger=is_danger,
        yield_danger=yield_danger,
        move_danger=move_danger,
        move_panic=move_panic,
        gas_10pct_rule=gas_10pct,
        message=message,
    )


def calculate_all_signals(market_data: dict, baselines: dict) -> dict:
    """
    Calculate all signals from raw market data.

    Args:
        market_data: Dict with keys: oil_wti, yield_10y, move_index,
                     zec_usd, btc_usd, eth_usd, gas_price, vix
        baselines: Dict with keys: gas_january_baseline, oil_january_avg

    Returns:
        Dict with all calculated signals ready for InfluxDB
    """
    signals = {}

    # Pass through raw values
    for key in ['oil_wti', 'yield_10y', 'move_index', 'zec_usd',
                'btc_usd', 'eth_usd', 'gas_price', 'vix']:
        if key in market_data and market_data[key] is not None:
            signals[key] = market_data[key]

    # ZEC/BTC ratio
    zec_btc = calculate_zec_btc_ratio(
        market_data.get('zec_usd'),
        market_data.get('btc_usd'),
    )
    if zec_btc is not None:
        signals['zec_btc_ratio'] = zec_btc

    # ETH/BTC ratio (DeFi vs BTC relative strength)
    if market_data.get('eth_usd') and market_data.get('btc_usd'):
        signals['eth_btc_ratio'] = market_data['eth_usd'] / market_data['btc_usd']

    # Gas 10% rule
    gas_pct_change = None
    if market_data.get('gas_price') and baselines.get('gas_january_baseline'):
        gas_pct_change, gas_triggered = calculate_gas_10pct_rule(
            market_data['gas_price'],
            baselines['gas_january_baseline'],
        )
        if gas_pct_change is not None:
            signals['gas_pct_from_jan'] = gas_pct_change * 100  # Store as percentage
            signals['gas_10pct_triggered'] = 1 if gas_triggered else 0

    # Oil percent change from January
    if market_data.get('oil_wti') and baselines.get('oil_january_avg'):
        oil_pct = (market_data['oil_wti'] - baselines['oil_january_avg']) / baselines['oil_january_avg']
        signals['oil_pct_from_jan'] = oil_pct * 100

    # Danger zone evaluation
    danger = evaluate_danger_zone(
        market_data.get('yield_10y'),
        market_data.get('move_index'),
        gas_pct_change,
    )
    signals['danger_zone'] = 1 if danger.is_danger else 0
    signals['yield_danger'] = 1 if danger.yield_danger else 0
    signals['move_danger'] = 1 if danger.move_danger else 0
    signals['move_panic'] = 1 if danger.move_panic else 0

    logger.info(
        "signals_calculated",
        danger_zone=danger.is_danger,
        message=danger.message,
        signal_count=len(signals),
    )

    return signals
```

### 3.6 Main Application Entry Point

**File: `app/main.py`**

```python
"""
Hayes Macro Monitor - Data Fetcher Service

Fetches market data from multiple sources and writes to InfluxDB
for visualization in Grafana.

Data Sources:
- Yahoo Finance: Oil, yields, crypto prices
- FRED: MOVE Index, gas prices (requires API key)

Update Frequency:
- Market data: Every 60 seconds (configurable)
- January baselines: Once per day at midnight
"""

import os
import sys
import time
from datetime import datetime, timezone
import structlog
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

from sources.yahoo import fetch_current_prices, fetch_january_baseline
from sources.fred import fetch_move_index, fetch_gas_price, fetch_january_gas_baseline
from signals import calculate_all_signals

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.BoundLogger,
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
)
logger = structlog.get_logger()


# Configuration from environment
INFLUXDB_URL = os.getenv('INFLUXDB_URL', 'http://localhost:8086')
INFLUXDB_TOKEN = os.getenv('INFLUXDB_TOKEN')
INFLUXDB_ORG = os.getenv('INFLUXDB_ORG', 'hayes-monitor')
INFLUXDB_BUCKET = os.getenv('INFLUXDB_BUCKET', 'macro_signals')
FETCH_INTERVAL = int(os.getenv('FETCH_INTERVAL_SECONDS', '60'))


class MacroMonitor:
    """Main monitoring service."""

    def __init__(self):
        self.client = None
        self.write_api = None
        self.baselines = {}
        self.last_baseline_date = None

    def connect_influxdb(self) -> bool:
        """Establish connection to InfluxDB."""
        try:
            self.client = InfluxDBClient(
                url=INFLUXDB_URL,
                token=INFLUXDB_TOKEN,
                org=INFLUXDB_ORG,
            )
            self.write_api = self.client.write_api(write_options=SYNCHRONOUS)

            # Verify connection
            health = self.client.health()
            if health.status == "pass":
                logger.info("influxdb_connected", url=INFLUXDB_URL)
                return True
            else:
                logger.error("influxdb_unhealthy", status=health.status)
                return False

        except Exception as e:
            logger.error("influxdb_connection_failed", error=str(e))
            return False

    def update_baselines(self, force: bool = False):
        """
        Update January baseline values.
        Called once per day or on startup.
        """
        today = datetime.now().date()

        if not force and self.last_baseline_date == today:
            return  # Already updated today

        logger.info("updating_baselines", year=today.year)

        # Yahoo Finance oil baseline
        yahoo_baseline = fetch_january_baseline(today.year)
        if yahoo_baseline:
            self.baselines.update(yahoo_baseline)

        # FRED gas baseline
        gas_baseline = fetch_january_gas_baseline(today.year)
        if gas_baseline:
            self.baselines['gas_january_baseline'] = gas_baseline

        self.last_baseline_date = today
        logger.info("baselines_updated", baselines=self.baselines)

    def fetch_all_data(self) -> dict:
        """Fetch data from all sources."""
        data = {}

        # Yahoo Finance data
        yahoo_data = fetch_current_prices()
        if yahoo_data:
            data.update(yahoo_data)

        # FRED data (optional, requires API key)
        move = fetch_move_index()
        if move is not None:
            data['move_index'] = move

        gas = fetch_gas_price()
        if gas is not None:
            data['gas_price'] = gas

        return data

    def write_signals(self, signals: dict):
        """Write calculated signals to InfluxDB."""
        if not signals:
            logger.warning("no_signals_to_write")
            return

        try:
            point = Point("market_signals")

            for key, value in signals.items():
                if value is not None:
                    point = point.field(key, float(value))

            point = point.time(datetime.now(timezone.utc))

            self.write_api.write(bucket=INFLUXDB_BUCKET, org=INFLUXDB_ORG, record=point)
            logger.info("signals_written", count=len(signals))

        except Exception as e:
            logger.error("write_failed", error=str(e))

    def run_once(self):
        """Execute one fetch-calculate-write cycle."""
        # Update baselines if needed (daily)
        self.update_baselines()

        # Fetch raw market data
        market_data = self.fetch_all_data()
        if not market_data:
            logger.warning("no_market_data", msg="Markets may be closed")
            return

        # Calculate signals
        signals = calculate_all_signals(market_data, self.baselines)

        # Write to InfluxDB
        self.write_signals(signals)

        # Log summary
        logger.info(
            "cycle_complete",
            oil=market_data.get('oil_wti'),
            yield_10y=market_data.get('yield_10y'),
            move=market_data.get('move_index'),
            zec_btc=signals.get('zec_btc_ratio'),
            danger_zone=signals.get('danger_zone'),
        )

    def run(self):
        """Main run loop."""
        logger.info(
            "starting_monitor",
            influxdb_url=INFLUXDB_URL,
            fetch_interval=FETCH_INTERVAL,
        )

        # Wait for InfluxDB to be ready
        retries = 0
        while not self.connect_influxdb():
            retries += 1
            if retries > 10:
                logger.error("influxdb_connection_exhausted")
                sys.exit(1)
            logger.info("waiting_for_influxdb", retry=retries)
            time.sleep(5)

        # Initial baseline fetch
        self.update_baselines(force=True)

        # Main loop
        while True:
            try:
                self.run_once()
            except Exception as e:
                logger.error("run_cycle_error", error=str(e))

            time.sleep(FETCH_INTERVAL)


if __name__ == "__main__":
    monitor = MacroMonitor()
    monitor.run()
```

### 3.7 Unit Tests

**File: `app/tests/test_signals.py`**

```python
"""Unit tests for signal calculations."""

import pytest
from signals import (
    calculate_zec_btc_ratio,
    calculate_gas_10pct_rule,
    evaluate_danger_zone,
    calculate_all_signals,
    THRESHOLDS,
)


class TestZecBtcRatio:
    def test_normal_calculation(self):
        ratio = calculate_zec_btc_ratio(50.0, 100000.0)
        assert ratio == pytest.approx(0.0005)

    def test_zero_btc_returns_none(self):
        assert calculate_zec_btc_ratio(50.0, 0) is None

    def test_none_inputs_returns_none(self):
        assert calculate_zec_btc_ratio(None, 100000.0) is None
        assert calculate_zec_btc_ratio(50.0, None) is None


class TestGas10PctRule:
    def test_below_threshold(self):
        pct, triggered = calculate_gas_10pct_rule(3.30, 3.20)
        assert pct == pytest.approx(0.03125)
        assert triggered is False

    def test_at_threshold(self):
        pct, triggered = calculate_gas_10pct_rule(3.52, 3.20)
        assert triggered is True

    def test_above_threshold(self):
        pct, triggered = calculate_gas_10pct_rule(4.00, 3.20)
        assert pct == pytest.approx(0.25)
        assert triggered is True


class TestDangerZone:
    def test_all_clear(self):
        status = evaluate_danger_zone(4.0, 100.0, 0.05)
        assert status.is_danger is False
        assert status.yield_danger is False
        assert status.move_danger is False

    def test_yield_danger(self):
        status = evaluate_danger_zone(4.9, 100.0, 0.05)
        assert status.is_danger is True
        assert status.yield_danger is True

    def test_move_elevated(self):
        status = evaluate_danger_zone(4.0, 150.0, 0.05)
        assert status.move_danger is True
        assert status.move_panic is False

    def test_move_panic(self):
        status = evaluate_danger_zone(4.0, 175.0, 0.05)
        assert status.move_danger is True
        assert status.move_panic is True
        assert status.is_danger is True

    def test_gas_10pct_triggered(self):
        status = evaluate_danger_zone(4.0, 100.0, 0.15)
        assert status.gas_10pct_rule is True
        assert status.is_danger is True


class TestCalculateAllSignals:
    def test_full_data(self):
        market_data = {
            'oil_wti': 75.0,
            'yield_10y': 4.5,
            'move_index': 120.0,
            'zec_usd': 50.0,
            'btc_usd': 100000.0,
            'eth_usd': 4000.0,
            'gas_price': 3.50,
            'vix': 18.0,
        }
        baselines = {
            'gas_january_baseline': 3.20,
            'oil_january_avg': 72.0,
        }

        signals = calculate_all_signals(market_data, baselines)

        assert 'zec_btc_ratio' in signals
        assert 'eth_btc_ratio' in signals
        assert 'gas_pct_from_jan' in signals
        assert 'oil_pct_from_jan' in signals
        assert 'danger_zone' in signals
```

---

## Phase 4: Grafana Configuration

### 4.1 Datasource Provisioning

**File: `grafana/provisioning/datasources/datasource.yml`**

```yaml
apiVersion: 1

datasources:
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    jsonData:
      version: Flux
      organization: ${INFLUXDB_ORG}
      defaultBucket: ${INFLUXDB_BUCKET}
    secureJsonData:
      token: ${INFLUXDB_ADMIN_TOKEN}
    isDefault: true
```

### 4.2 Dashboard Provisioning Config

**File: `grafana/provisioning/dashboards/dashboard.yml`**

```yaml
apiVersion: 1

providers:
  - name: 'Hayes Monitor'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /etc/grafana/provisioning/dashboards
```

### 4.3 Pre-Built Dashboard JSON

**File: `grafana/provisioning/dashboards/hayes-monitor.json`**

This file will be a complete Grafana dashboard JSON export containing:

```json
{
  "dashboard": {
    "id": null,
    "uid": "hayes-macro-monitor",
    "title": "Hayes Macro Monitor",
    "tags": ["macro", "crypto", "trading"],
    "timezone": "browser",
    "refresh": "1m",
    "panels": [
      {
        "id": 1,
        "title": "DANGER ZONE STATUS",
        "type": "stat",
        "gridPos": { "h": 4, "w": 24, "x": 0, "y": 0 },
        "description": "Red = Risk-off conditions (credit slowdown likely)",
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "mode": "absolute",
              "steps": [
                { "color": "green", "value": null },
                { "color": "red", "value": 1 }
              ]
            },
            "mappings": [
              { "type": "value", "options": { "0": { "text": "ALL CLEAR - HODL/BUY" } } },
              { "type": "value", "options": { "1": { "text": "DANGER ZONE - RISK OFF" } } }
            ]
          }
        },
        "targets": [
          {
            "query": "from(bucket: \"macro_signals\") |> range(start: -5m) |> filter(fn: (r) => r._field == \"danger_zone\") |> last()"
          }
        ]
      },
      {
        "id": 2,
        "title": "10-Year Treasury Yield",
        "type": "gauge",
        "gridPos": { "h": 8, "w": 6, "x": 0, "y": 4 },
        "description": "Danger at 4.8%, Critical at 5.0%",
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 3,
            "max": 6,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                { "color": "green", "value": null },
                { "color": "yellow", "value": 4.5 },
                { "color": "orange", "value": 4.8 },
                { "color": "red", "value": 5.0 }
              ]
            }
          }
        }
      },
      {
        "id": 3,
        "title": "MOVE Index (Bond Volatility)",
        "type": "gauge",
        "gridPos": { "h": 8, "w": 6, "x": 6, "y": 4 },
        "description": "Elevated: 140, Panic: 172",
        "fieldConfig": {
          "defaults": {
            "min": 50,
            "max": 200,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                { "color": "green", "value": null },
                { "color": "yellow", "value": 120 },
                { "color": "orange", "value": 140 },
                { "color": "red", "value": 172 }
              ]
            }
          }
        }
      },
      {
        "id": 4,
        "title": "Gas Price (10% Rule)",
        "type": "gauge",
        "gridPos": { "h": 8, "w": 6, "x": 12, "y": 4 },
        "description": "% change from January baseline. 10%+ = election risk",
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": -20,
            "max": 30,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                { "color": "green", "value": null },
                { "color": "yellow", "value": 5 },
                { "color": "red", "value": 10 }
              ]
            }
          }
        }
      },
      {
        "id": 5,
        "title": "WTI Crude Oil",
        "type": "gauge",
        "gridPos": { "h": 8, "w": 6, "x": 18, "y": 4 },
        "description": "Oil must stay flat/falling for continued printing",
        "fieldConfig": {
          "defaults": {
            "unit": "currencyUSD",
            "min": 50,
            "max": 120
          }
        }
      },
      {
        "id": 6,
        "title": "ZEC/BTC Ratio (Privacy Beta)",
        "type": "timeseries",
        "gridPos": { "h": 8, "w": 12, "x": 0, "y": 12 },
        "description": "Hayes: 'ZEC will become the privacy beta'",
        "fieldConfig": {
          "defaults": {
            "custom": {
              "drawStyle": "line",
              "lineWidth": 2
            }
          }
        }
      },
      {
        "id": 7,
        "title": "Yield & MOVE Trend",
        "type": "timeseries",
        "gridPos": { "h": 8, "w": 12, "x": 12, "y": 12 },
        "description": "Track yield and volatility trends",
        "fieldConfig": {
          "overrides": [
            {
              "matcher": { "id": "byName", "options": "yield_10y" },
              "properties": [{ "id": "custom.axisPlacement", "value": "left" }]
            },
            {
              "matcher": { "id": "byName", "options": "move_index" },
              "properties": [{ "id": "custom.axisPlacement", "value": "right" }]
            }
          ]
        }
      },
      {
        "id": 8,
        "title": "Crypto Prices",
        "type": "timeseries",
        "gridPos": { "h": 8, "w": 24, "x": 0, "y": 20 },
        "description": "BTC, ETH, ZEC price trends"
      }
    ]
  }
}
```

*Note: Full JSON will be ~500 lines with complete Flux queries for each panel.*

---

## Phase 5: Deployment

### 5.1 Setup Script

**File: `scripts/setup.sh`**

```bash
#!/bin/bash
set -e

echo "=== Hayes Macro Monitor Setup ==="

# Check for .env file
if [ ! -f .env ]; then
    echo "Creating .env from template..."
    cp .env.example .env

    # Generate secure values
    INFLUX_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
    INFLUX_TOKEN=$(openssl rand -hex 32)
    GRAFANA_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)

    # Replace placeholders
    sed -i "s/INFLUXDB_ADMIN_PASSWORD=changeme/INFLUXDB_ADMIN_PASSWORD=$INFLUX_PASS/" .env
    sed -i "s/INFLUXDB_ADMIN_TOKEN=changeme/INFLUXDB_ADMIN_TOKEN=$INFLUX_TOKEN/" .env
    sed -i "s/GF_SECURITY_ADMIN_PASSWORD=changeme/GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_PASS/" .env

    echo ""
    echo "Generated credentials (save these!):"
    echo "  InfluxDB Password: $INFLUX_PASS"
    echo "  InfluxDB Token: $INFLUX_TOKEN"
    echo "  Grafana Password: $GRAFANA_PASS"
    echo ""
fi

# Build and start services
echo "Building and starting services..."
docker compose up -d --build

# Wait for services
echo "Waiting for services to start..."
sleep 15

# Health check
echo "Checking service health..."
curl -s http://localhost:8086/health | jq .
curl -s http://localhost:3000/api/health | jq .

echo ""
echo "=== Setup Complete ==="
echo "Grafana: http://10.10.10.5:3000"
echo "InfluxDB: http://10.10.10.5:8086"
echo ""
echo "Default Grafana login: admin / (see .env for password)"
```

### 5.2 Backup Script

**File: `scripts/backup.sh`**

```bash
#!/bin/bash
set -e

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up to $BACKUP_DIR..."

# InfluxDB backup
docker exec hayes_influxdb influx backup /tmp/backup
docker cp hayes_influxdb:/tmp/backup "$BACKUP_DIR/influxdb"

# Grafana backup (dashboards, etc.)
docker cp hayes_grafana:/var/lib/grafana "$BACKUP_DIR/grafana"

echo "Backup complete: $BACKUP_DIR"
```

---

## Phase 6: Deployment Checklist

### 6.1 Pre-Deployment

- [ ] SSH into MS-01: `ssh user@10.10.10.5`
- [ ] Verify Docker installed: `docker --version`
- [ ] Verify Docker Compose: `docker compose version`
- [ ] Clone/copy project to `~/docker/hayes-monitor`
- [ ] Register for FRED API key (optional but recommended for MOVE Index)

### 6.2 Deployment Steps

1. **Initialize environment:**
   ```bash
   cd ~/docker/hayes-monitor
   chmod +x scripts/*.sh
   ./scripts/setup.sh
   ```

2. **Verify services running:**
   ```bash
   docker compose ps
   docker compose logs -f fetcher
   ```

3. **Access Grafana:**
   - URL: `http://10.10.10.5:3000`
   - Login with credentials from `.env`
   - Dashboard should auto-provision

4. **Verify data flow:**
   - Check InfluxDB: `http://10.10.10.5:8086`
   - Query: `from(bucket: "macro_signals") |> range(start: -1h)`

### 6.3 Post-Deployment

- [ ] Set up Grafana alerts for danger zone conditions
- [ ] Configure notification channels (email, Slack, Discord)
- [ ] Add dashboard to Grafana favorites
- [ ] Test backup script: `./scripts/backup.sh`

---

## Phase 7: Maintenance

### 7.1 Common Operations

**View logs:**
```bash
docker compose logs -f fetcher
docker compose logs -f influxdb
```

**Restart after config change:**
```bash
docker compose restart fetcher
```

**Update images:**
```bash
docker compose pull
docker compose up -d
```

**Full rebuild:**
```bash
docker compose down
docker compose up -d --build
```

### 7.2 Troubleshooting

| Issue | Solution |
|-------|----------|
| No data appearing | Check fetcher logs; verify market hours |
| MOVE Index missing | Verify FRED_API_KEY in .env |
| Connection refused | Check docker network; verify service health |
| High memory usage | Reduce InfluxDB retention policy |

---

## Appendix A: Signal Reference

### A.1 Hayes Thesis Summary

| Condition | Implication | Action |
|-----------|-------------|--------|
| Low yields + Low MOVE + Flat oil | Money printing continues | Risk-on: Long BTC, ETH, ZEC |
| Yields approaching 5% | Fed pressure increasing | Reduce risk exposure |
| MOVE > 140 | Elevated volatility | Caution |
| MOVE > 172 | Panic - policy reversal imminent | Expect market bottom soon |
| Gas +10% from January | Election risk for incumbents | Political volatility |

### A.2 Data Source Details

| Signal | Source | Update Frequency | Notes |
|--------|--------|-----------------|-------|
| WTI Oil | Yahoo Finance (CL=F) | Real-time | Futures contract |
| 10Y Yield | Yahoo (^TNX) / FRED (DGS10) | Real-time / Daily | Yahoo preferred |
| MOVE Index | FRED (MOVE) | Daily | Requires API key |
| Gas Price | FRED (GASREGW) | Weekly | US national average |
| BTC/ETH/ZEC | Yahoo Finance | Real-time | -USD pairs |
| VIX | Yahoo Finance (^VIX) | Real-time | MOVE proxy |

---

## Appendix B: Cost Considerations

**Resource Usage (MS-01):**
- CPU: <1% (fetcher runs every 60s)
- RAM: ~500MB (InfluxDB + Grafana + Python)
- Storage: ~10MB/month (time-series data)

**External Services:**
- FRED API: Free (requires registration)
- Yahoo Finance: Free (unofficial API via yfinance)

---

*Plan Version: 1.0*
*Created: 2026-01-05*
*Based on: Arthur Hayes "Suavemente" (January 5, 2026)*
