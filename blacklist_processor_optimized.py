#!/usr/bin/env python3
"""
XXMXLI Enhanced IP Blacklist Processor v2.0
Optimized for performance, reliability, and maintainability

Features:
- Async processing for better performance
- Comprehensive error handling with retries
- Configuration file support (JSON/YAML)
- Color-coded logging output
- Progress indicators and statistics
- Timeout protection for network operations
- Memory-efficient processing of large files
"""

import asyncio
import json
import yaml
import sys
import os
import time
import ipaddress
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Set, Optional, Tuple
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor, as_completed
import aiohttp
import aiofiles
from tqdm import tqdm
import logging
import argparse

# Color codes for enhanced output
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'
    
    @staticmethod
    def disable():
        """Disable colors for non-terminal output"""
        Colors.RED = ''
        Colors.GREEN = ''
        Colors.YELLOW = ''
        Colors.BLUE = ''
        Colors.PURPLE = ''
        Colors.CYAN = ''
        Colors.WHITE = ''
        Colors.BOLD = ''
        Colors.UNDERLINE = ''
        Colors.END = ''

# Check if output is to terminal
if not sys.stdout.isatty():
    Colors.disable()

@dataclass
class ProcessingStats:
    """Statistics tracking for the processing operation"""
    total_sources: int = 0
    successful_sources: int = 0
    failed_sources: int = 0
    total_ips: int = 0
    unique_ips: int = 0
    duplicates_removed: int = 0
    invalid_ips: int = 0
    processing_time: float = 0.0
    memory_usage_mb: float = 0.0

class ConfigManager:
    """Configuration management with multiple format support"""
    
    def __init__(self, config_dir: Path = None):
        self.config_dir = config_dir or Path(__file__).parent / "config"
        self.config = self.load_configuration()
    
    def load_configuration(self) -> dict:
        """Load configuration from JSON, YAML, or use defaults"""
        
        # Try JSON first
        json_config = self.config_dir / "blacklist_processor.json"
        if json_config.exists():
            try:
                with open(json_config, 'r') as f:
                    config = json.load(f)
                    print(f"{Colors.GREEN}✓{Colors.END} Configuration loaded from JSON")
                    return config
            except Exception as e:
                print(f"{Colors.YELLOW}⚠{Colors.END} JSON config error: {e}")
        
        # Try YAML
        yaml_config = self.config_dir / "blacklist_processor.yaml"
        if yaml_config.exists():
            try:
                with open(yaml_config, 'r') as f:
                    config = yaml.safe_load(f)
                    print(f"{Colors.GREEN}✓{Colors.END} Configuration loaded from YAML")
                    return config
            except Exception as e:
                print(f"{Colors.YELLOW}⚠{Colors.END} YAML config error: {e}")
        
        # Default configuration
        print(f"{Colors.YELLOW}⚠{Colors.END} Using default configuration")
        return {
            "sources": [
                {
                    "name": "Emerging Threats",
                    "url": "https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt",
                    "format": "plain",
                    "timeout": 30,
                    "retry_count": 3
                },
                {
                    "name": "Spamhaus DROP",
                    "url": "https://www.spamhaus.org/drop/drop.txt",
                    "format": "cidr_comment",
                    "timeout": 30,
                    "retry_count": 3
                }
            ],
            "processing": {
                "max_concurrent_downloads": 5,
                "max_ips_output": 100000,
                "chunk_size": 1000,
                "memory_limit_mb": 512,
                "timeout_seconds": 60
            },
            "output": {
                "formats": ["javascript", "json", "csv"],
                "javascript_file": "assets/security/blocked_ips.js",
                "json_file": "assets/security/blocked_ips.json",
                "csv_file": "assets/security/blocked_ips.csv"
            },
            "logging": {
                "level": "INFO",
                "file": "logs/blacklist_processor.log",
                "max_size_mb": 10,
                "backup_count": 5
            }
        }

class EnhancedLogger:
    """Enhanced logging with colors and file output"""
    
    def __init__(self, config: dict):
        self.config = config.get('logging', {})
        self.setup_logging()
    
    def setup_logging(self):
        """Setup logging configuration"""
        log_level = getattr(logging, self.config.get('level', 'INFO'))
        
        # Create logs directory if it doesn't exist
        log_file = Path(self.config.get('file', 'logs/blacklist_processor.log'))
        log_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Configure logging
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def info(self, message: str, color: str = Colors.BLUE):
        """Log info message with color"""
        print(f"{color}ℹ{Colors.END} {message}")
        self.logger.info(message)
    
    def success(self, message: str):
        """Log success message"""
        print(f"{Colors.GREEN}✓{Colors.END} {message}")
        self.logger.info(f"SUCCESS: {message}")
    
    def warning(self, message: str):
        """Log warning message"""
        print(f"{Colors.YELLOW}⚠{Colors.END} {message}")
        self.logger.warning(message)
    
    def error(self, message: str):
        """Log error message"""
        print(f"{Colors.RED}✗{Colors.END} {message}")
        self.logger.error(message)
    
    def critical(self, message: str):
        """Log critical message"""
        print(f"{Colors.RED}{Colors.BOLD}🔥{Colors.END} {message}")
        self.logger.critical(message)

class BlacklistProcessor:
    """Enhanced IP blacklist processor with async operations"""
    
    def __init__(self, config_dir: Path = None):
        self.config_manager = ConfigManager(config_dir)
        self.config = self.config_manager.config
        self.logger = EnhancedLogger(self.config)
        self.stats = ProcessingStats()
        self.ip_set: Set[str] = set()
        self.source_info: Dict[str, dict] = {}
        # Hardcode/default W folder path for any local file-based sources to use
        self.DEFAULT_W_FOLDER = self._resolve_w_folder()
        os.environ.setdefault('W_FOLDER', str(self.DEFAULT_W_FOLDER))
        self.logger.info(f"W folder set to: {self.DEFAULT_W_FOLDER}", Colors.CYAN)

    def _resolve_w_folder(self) -> Path:
        script_dir = Path(__file__).parent.resolve()
        repo_root = script_dir
        try:
            for p in [script_dir, *script_dir.parents]:
                if (p / '.git').exists() or (p / 'README.md').exists():
                    repo_root = p
                    break
        except Exception:
            pass
        hardcoded = Path('/home/kodachi/Desktop/kotisivu/w')
        # Priority: env > hardcoded > repo_root/w > script_dir/w > parent/w
        env_val = os.environ.get('W_FOLDER')
        if env_val and Path(env_val).expanduser().exists():
            return Path(env_val).expanduser().resolve()
        if hardcoded.exists():
            return hardcoded.resolve()
        if (repo_root / 'w').exists():
            return (repo_root / 'w').resolve()
        if (script_dir / 'w').exists():
            return (script_dir / 'w').resolve()
        if (script_dir.parent / 'w').exists():
            return (script_dir.parent / 'w').resolve()
        return (repo_root / 'w').resolve()
        
    async def download_source(self, session: aiohttp.ClientSession, source: dict) -> Tuple[str, List[str]]:
        """Download a single blacklist source with retries"""
        source_name = source['name']
        url = source['url']
        timeout = source.get('timeout', 30)
        retry_count = source.get('retry_count', 3)
        
        self.logger.info(f"Downloading: {source_name}", Colors.CYAN)
        
        for attempt in range(retry_count):
            try:
                timeout_obj = aiohttp.ClientTimeout(total=timeout)
                async with session.get(url, timeout=timeout_obj) as response:
                    if response.status == 200:
                        content = await response.text()
                        ips = self.parse_content(content, source.get('format', 'plain'))
                        
                        self.source_info[source_name] = {
                            'url': url,
                            'status': 'success',
                            'ip_count': len(ips),
                            'download_time': time.time()
                        }
                        
                        self.logger.success(f"{source_name}: {len(ips)} IPs downloaded")
                        return source_name, ips
                    else:
                        raise aiohttp.ClientResponseError(
                            request_info=response.request_info,
                            history=response.history,
                            status=response.status
                        )
                        
            except asyncio.TimeoutError:
                self.logger.warning(f"{source_name}: Timeout (attempt {attempt + 1}/{retry_count})")
                if attempt == retry_count - 1:
                    break
                await asyncio.sleep(2 ** attempt)  # Exponential backoff
                
            except Exception as e:
                self.logger.error(f"{source_name}: Download failed - {str(e)}")
                if attempt == retry_count - 1:
                    break
                await asyncio.sleep(2 ** attempt)
        
        # Mark as failed
        self.source_info[source_name] = {
            'url': url,
            'status': 'failed',
            'ip_count': 0,
            'error': str(e) if 'e' in locals() else 'Unknown error'
        }
        
        self.logger.error(f"{source_name}: All download attempts failed")
        return source_name, []
    
    def parse_content(self, content: str, format_type: str = 'plain') -> List[str]:
        """Parse content based on format type"""
        ips = []
        
        try:
            lines = content.strip().split('\n')
            
            for line in lines:
                line = line.strip()
                
                # Skip empty lines and comments
                if not line or line.startswith('#') or line.startswith(';'):
                    continue
                
                if format_type == 'cidr_comment':
                    # Format: "IP/CIDR ; comment"
                    if ';' in line:
                        ip_part = line.split(';')[0].strip()
                    else:
                        ip_part = line
                elif format_type == 'plain':
                    ip_part = line
                else:
                    ip_part = line
                
                # Extract IP from the line
                ip = self.extract_ip(ip_part)
                if ip:
                    ips.append(ip)
                    
        except Exception as e:
            self.logger.error(f"Content parsing error: {e}")
        
        return ips
    
    def extract_ip(self, line: str) -> Optional[str]:
        """Extract and validate IP address from line"""
        try:
            # Clean the line
            line = line.strip()
            
            # Handle different formats
            if '/' in line:
                # CIDR notation - extract network
                network = ipaddress.ip_network(line, strict=False)
                return str(network.network_address)
            else:
                # Single IP
                ip = ipaddress.ip_address(line)
                # Skip localhost and private IPs
                if ip.is_private or ip.is_loopback:
                    return None
                return str(ip)
                
        except (ipaddress.AddressValueError, ValueError):
            # Try to extract IP pattern from line
            import re
            ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
            match = re.search(ip_pattern, line)
            if match:
                try:
                    ip = ipaddress.ip_address(match.group())
                    if not (ip.is_private or ip.is_loopback):
                        return str(ip)
                except ipaddress.AddressValueError:
                    pass
            return None
    
    async def process_sources(self) -> ProcessingStats:
        """Process all blacklist sources asynchronously"""
        start_time = time.time()
        sources = self.config.get('sources', [])
        max_concurrent = self.config.get('processing', {}).get('max_concurrent_downloads', 5)
        
        self.stats.total_sources = len(sources)
        
        self.logger.info(f"Starting processing of {len(sources)} sources", Colors.PURPLE)
        
        # Create semaphore to limit concurrent downloads
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def download_with_semaphore(session, source):
            async with semaphore:
                return await self.download_source(session, source)
        
        # Download all sources concurrently
        connector = aiohttp.TCPConnector(limit=max_concurrent)
        timeout = aiohttp.ClientTimeout(total=60)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            tasks = [download_with_semaphore(session, source) for source in sources]
            
            # Process with progress bar
            with tqdm(total=len(sources), desc="Downloading sources", 
                     bar_format=f"{Colors.CYAN}{{l_bar}}{{bar}}{{r_bar}}{Colors.END}") as pbar:
                
                for coro in asyncio.as_completed(tasks):
                    source_name, ips = await coro
                    
                    if ips:
                        # Add IPs to set (automatic deduplication)
                        initial_count = len(self.ip_set)
                        self.ip_set.update(ips)
                        new_ips = len(self.ip_set) - initial_count
                        
                        self.stats.successful_sources += 1
                        self.stats.total_ips += len(ips)
                        self.stats.duplicates_removed += len(ips) - new_ips
                        
                        self.logger.success(f"{source_name}: +{new_ips} unique IPs")
                    else:
                        self.stats.failed_sources += 1
                    
                    pbar.update(1)
        
        # Final statistics
        self.stats.unique_ips = len(self.ip_set)
        self.stats.processing_time = time.time() - start_time
        
        return self.stats
    
    def generate_outputs(self):
        """Generate output files in multiple formats"""
        output_config = self.config.get('output', {})
        formats = output_config.get('formats', ['javascript'])
        
        # Limit IPs for performance
        max_ips = self.config.get('processing', {}).get('max_ips_output', 100000)
        ip_list = list(self.ip_set)[:max_ips]
        
        self.logger.info(f"Generating outputs in {len(formats)} formats", Colors.PURPLE)
        
        if 'javascript' in formats:
            self.generate_javascript_output(ip_list, output_config.get('javascript_file'))
        
        if 'json' in formats:
            self.generate_json_output(ip_list, output_config.get('json_file'))
        
        if 'csv' in formats:
            self.generate_csv_output(ip_list, output_config.get('csv_file'))
    
    def generate_javascript_output(self, ip_list: List[str], output_file: str):
        """Generate optimized JavaScript output"""
        if not output_file:
            return
        
        # Create output directory
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Sort IPs for binary search optimization
        sorted_ips = sorted(ip_list, key=lambda x: ipaddress.ip_address(x))
        
        js_content = f'''// XXMXLI Enhanced IP Blacklist - Auto Generated v2.0
// Generated: {datetime.now().isoformat()}
// Total unique IPs: {len(sorted_ips):,}
// Sources processed: {self.stats.successful_sources}/{self.stats.total_sources}
// Processing time: {self.stats.processing_time:.2f}s

const BLOCKED_IPS = {json.dumps(sorted_ips, separators=(',', ':'))};

const BLACKLIST_CONFIG = {{
    generated: "{datetime.now().isoformat()}",
    version: "2.0",
    total_ips: {len(sorted_ips)},
    sources_processed: {self.stats.successful_sources},
    sources_failed: {self.stats.failed_sources},
    processing_time_seconds: {self.stats.processing_time:.2f},
    duplicates_removed: {self.stats.duplicates_removed},
    performance_optimized: true
}};

const BLACKLIST_SOURCES = {json.dumps(self.source_info, separators=(',', ':'))};

// Optimized IP checking with binary search
function isIPBlocked(ip) {{
    if (!ip || typeof ip !== 'string') return false;
    
    // Binary search for O(log n) performance
    let left = 0;
    let right = BLOCKED_IPS.length - 1;
    
    while (left <= right) {{
        const mid = Math.floor((left + right) / 2);
        const midIP = BLOCKED_IPS[mid];
        
        if (midIP === ip) return true;
        
        // Compare IPs numerically
        const ipNum = ipToNumber(ip);
        const midIPNum = ipToNumber(midIP);
        
        if (midIPNum < ipNum) {{
            left = mid + 1;
        }} else {{
            right = mid - 1;
        }}
    }}
    
    return false;
}}

// Convert IP to number for comparison
function ipToNumber(ip) {{
    return ip.split('.').reduce((acc, octet) => (acc << 8) + parseInt(octet), 0) >>> 0;
}}

// Quick check for common patterns
function isIPBlockedFast(ip) {{
    if (!ip || typeof ip !== 'string') return false;
    return BLOCKED_IPS.includes(ip);
}}

// Get blacklist statistics
function getBlacklistStats() {{
    return {{
        total_ips: BLACKLIST_CONFIG.total_ips,
        generated: BLACKLIST_CONFIG.generated,
        sources: BLACKLIST_CONFIG.sources_processed,
        version: BLACKLIST_CONFIG.version
    }};
}}

// Module exports for Node.js
if (typeof module !== 'undefined' && module.exports) {{
    module.exports = {{
        BLOCKED_IPS,
        BLACKLIST_CONFIG,
        BLACKLIST_SOURCES,
        isIPBlocked,
        isIPBlockedFast,
        getBlacklistStats
    }};
}}

// Browser initialization
if (typeof window !== 'undefined') {{
    console.log(`🛡️ XXMXLI Blacklist v2.0 loaded: ${{BLOCKED_IPS.length.toLocaleString()}} IPs`);
    console.log(`⚡ Performance: Binary search enabled for O(log n) lookups`);
    console.log(`📊 Sources: ${{BLACKLIST_CONFIG.sources_processed}} successful, ${{BLACKLIST_CONFIG.sources_failed}} failed`);
}}
'''
        
        try:
            with open(output_path, 'w') as f:
                f.write(js_content)
            self.logger.success(f"JavaScript output: {output_file}")
        except Exception as e:
            self.logger.error(f"JavaScript output failed: {e}")
    
    def generate_json_output(self, ip_list: List[str], output_file: str):
        """Generate JSON output"""
        if not output_file:
            return
        
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        json_data = {
            "metadata": {
                "generated": datetime.now().isoformat(),
                "version": "2.0",
                "total_ips": len(ip_list),
                "sources_processed": self.stats.successful_sources,
                "sources_failed": self.stats.failed_sources,
                "processing_time_seconds": round(self.stats.processing_time, 2)
            },
            "blocked_ips": sorted(ip_list, key=lambda x: ipaddress.ip_address(x)),
            "sources": self.source_info
        }
        
        try:
            with open(output_path, 'w') as f:
                json.dump(json_data, f, indent=2)
            self.logger.success(f"JSON output: {output_file}")
        except Exception as e:
            self.logger.error(f"JSON output failed: {e}")
    
    def generate_csv_output(self, ip_list: List[str], output_file: str):
        """Generate CSV output"""
        if not output_file:
            return
        
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        try:
            with open(output_path, 'w') as f:
                f.write("ip_address,source,date_added\n")
                for ip in sorted(ip_list, key=lambda x: ipaddress.ip_address(x)):
                    f.write(f"{ip},multiple,{datetime.now().date()}\n")
            self.logger.success(f"CSV output: {output_file}")
        except Exception as e:
            self.logger.error(f"CSV output failed: {e}")
    
    def print_statistics(self):
        """Print final processing statistics"""
        print(f"\n{Colors.PURPLE}{Colors.BOLD}📊 PROCESSING STATISTICS{Colors.END}")
        print("=" * 50)
        print(f"{Colors.GREEN}✓ Successful sources:{Colors.END} {self.stats.successful_sources}/{self.stats.total_sources}")
        print(f"{Colors.RED}✗ Failed sources:{Colors.END} {self.stats.failed_sources}")
        print(f"{Colors.BLUE}📊 Total IPs collected:{Colors.END} {self.stats.total_ips:,}")
        print(f"{Colors.CYAN}🔄 Duplicates removed:{Colors.END} {self.stats.duplicates_removed:,}")
        print(f"{Colors.GREEN}✨ Unique IPs:{Colors.END} {self.stats.unique_ips:,}")
        print(f"{Colors.YELLOW}⏱️ Processing time:{Colors.END} {self.stats.processing_time:.2f}s")
        
        if self.stats.processing_time > 0:
            ips_per_second = self.stats.total_ips / self.stats.processing_time
            print(f"{Colors.PURPLE}🚀 Processing rate:{Colors.END} {ips_per_second:,.0f} IPs/second")
        
        print("")

async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="XXMXLI Enhanced IP Blacklist Processor v2.0")
    parser.add_argument("--config-dir", type=Path, help="Configuration directory path")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")
    parser.add_argument("--no-colors", action="store_true", help="Disable colored output")
    
    args = parser.parse_args()
    
    if args.no_colors:
        Colors.disable()
    
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    
    print(f"{Colors.PURPLE}{Colors.BOLD}")
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║              XXMXLI IP BLACKLIST PROCESSOR v2.0              ║")
    print("║          Enhanced Performance • Better Error Handling        ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print(f"{Colors.END}\n")
    
    try:
        processor = BlacklistProcessor(args.config_dir)
        
        # Process sources
        stats = await processor.process_sources()
        
        # Generate outputs
        processor.generate_outputs()
        
        # Print statistics
        processor.print_statistics()
        
        if stats.failed_sources > 0:
            print(f"{Colors.YELLOW}⚠ Warning: {stats.failed_sources} sources failed to download{Colors.END}")
            return 1
        else:
            print(f"{Colors.GREEN}🎉 All processing completed successfully!{Colors.END}")
            return 0
            
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}⚠ Operation cancelled by user{Colors.END}")
        return 130
    except Exception as e:
        print(f"\n{Colors.RED}💥 Fatal error: {e}{Colors.END}")
        return 1

if __name__ == "__main__":
    # Run the async main function
    exit_code = asyncio.run(main())
    sys.exit(exit_code)