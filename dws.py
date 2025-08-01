#!/usr/bin/env python3
"""
Comprehensive IP Blacklist Processor for XXMXLI
Processes all IP blacklist files from the 'w' folder and generates JavaScript blocklist
"""

import os
import json
import ipaddress
import re
import gzip
import zipfile
from pathlib import Path
from datetime import datetime
import hashlib

# Configuration
BLACKLIST_SOURCE_DIR = Path('w')  # Your blacklist folder
OUTPUT_DIR = Path('assets/security')
JS_OUTPUT = OUTPUT_DIR / 'blocked_ips.js'
JSON_OUTPUT = OUTPUT_DIR / 'blocked_ips.json'
STATS_OUTPUT = OUTPUT_DIR / 'blacklist_stats.json'
LOG_OUTPUT = OUTPUT_DIR / 'processing_log.txt'

# File extensions to process
SUPPORTED_EXTENSIONS = {'.txt', '.ipset', '.list', '.csv', '.dat', '.conf'}
COMPRESSED_EXTENSIONS = {'.gz', '.zip'}

# Performance limits
MAX_IPS_IN_JS = 100000  # Limit for JavaScript file
MAX_NETWORK_EXPANSION = 1024  # Max IPs to expand from CIDR

class BlacklistProcessor:
    def __init__(self):
        self.all_ips = set()
        self.sources = {}
        self.errors = []
        self.stats = {
            'files_processed': 0,
            'files_skipped': 0,
            'total_lines_read': 0,
            'valid_ips_found': 0,
            'duplicate_ips': 0,
            'invalid_ips': 0
        }
        
    def log(self, message, level='INFO'):
        """Log message to console and file"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_entry = f"[{timestamp}] [{level}] {message}"
        print(log_entry)
        
        # Write to log file
        try:
            OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
            with open(LOG_OUTPUT, 'a', encoding='utf-8') as f:
                f.write(log_entry + '\n')
        except Exception as e:
            print(f"Failed to write to log file: {e}")
    
    def process_all_blacklists(self):
        """Main processing function"""
        self.log("=== Starting Comprehensive IP Blacklist Processing ===")
        self.log(f"Source directory: {BLACKLIST_SOURCE_DIR.absolute()}")
        
        if not BLACKLIST_SOURCE_DIR.exists():
            self.log(f"ERROR: Source directory {BLACKLIST_SOURCE_DIR} not found!", 'ERROR')
            return False
        
        # Clear previous log
        if LOG_OUTPUT.exists():
            LOG_OUTPUT.unlink()
        
        start_time = datetime.now()
        
        # Process all files recursively
        self._scan_directory(BLACKLIST_SOURCE_DIR)
        
        end_time = datetime.now()
        processing_time = (end_time - start_time).total_seconds()
        
        # Generate final statistics
        self.stats.update({
            'processing_time_seconds': processing_time,
            'unique_ips_total': len(self.all_ips),
            'sources_processed': len(self.sources),
            'errors_encountered': len(self.errors)
        })
        
        self.log(f"Processing completed in {processing_time:.2f} seconds")
        self.log(f"Total unique IPs: {len(self.all_ips):,}")
        self.log(f"Files processed: {self.stats['files_processed']}")
        self.log(f"Errors: {len(self.errors)}")
        
        return len(self.all_ips) > 0
    
    def _scan_directory(self, directory):
        """Recursively scan directory for blacklist files"""
        self.log(f"Scanning directory: {directory}")
        
        try:
            for item in directory.iterdir():
                if item.is_dir():
                    # Recursively process subdirectories
                    self._scan_directory(item)
                elif item.is_file():
                    self._process_file(item)
        except PermissionError:
            self.log(f"Permission denied accessing: {directory}", 'ERROR')
        except Exception as e:
            self.log(f"Error scanning directory {directory}: {e}", 'ERROR')
    
    def _process_file(self, file_path):
        """Process a single file"""
        try:
            # Check if file should be processed
            if not self._should_process_file(file_path):
                self.stats['files_skipped'] += 1
                return
            
            self.log(f"Processing: {file_path.relative_to(BLACKLIST_SOURCE_DIR)}")
            
            # Extract IPs from file
            file_ips, lines_read = self._extract_ips_from_file(file_path)
            
            if file_ips:
                # Store source information
                source_key = str(file_path.relative_to(BLACKLIST_SOURCE_DIR))
                self.sources[source_key] = {
                    'file_path': str(file_path),
                    'count': len(file_ips),
                    'size_bytes': file_path.stat().st_size,
                    'modified': datetime.fromtimestamp(file_path.stat().st_mtime).isoformat(),
                    'processed': datetime.now().isoformat(),
                    'lines_read': lines_read,
                    'file_hash': self._get_file_hash(file_path)
                }
                
                # Add to main collection
                old_count = len(self.all_ips)
                self.all_ips.update(file_ips)
                new_count = len(self.all_ips)
                
                duplicates = len(file_ips) - (new_count - old_count)
                self.stats['duplicate_ips'] += duplicates
                
                self.log(f"  ✅ Added {len(file_ips)} IPs ({duplicates} duplicates)")
                self.stats['files_processed'] += 1
            else:
                self.log(f"  ⚠️ No valid IPs found")
                self.stats['files_skipped'] += 1
                
        except Exception as e:
            error_msg = f"Error processing {file_path}: {str(e)}"
            self.errors.append(error_msg)
            self.log(error_msg, 'ERROR')
    
    def _should_process_file(self, file_path):
        """Check if file should be processed"""
        # Check extension
        ext = file_path.suffix.lower()
        if ext in COMPRESSED_EXTENSIONS:
            return True
        if ext in SUPPORTED_EXTENSIONS:
            return True
        
        # Check if filename suggests it's a blacklist
        name_lower = file_path.name.lower()
        blacklist_indicators = [
            'blacklist', 'blocklist', 'block', 'banned', 'malicious',
            'threat', 'bad', 'evil', 'spam', 'proxy', 'tor', 'vpn'
        ]
        
        if any(indicator in name_lower for indicator in blacklist_indicators):
            return True
        
        # Skip obviously non-blacklist files
        skip_indicators = [
            'readme', 'license', 'changelog', 'install', 'config',
            '.md', '.rst', '.pdf', '.doc', '.docx'
        ]
        
        if any(indicator in name_lower for indicator in skip_indicators):
            return False
        
        # If no extension and contains IP-like patterns, process it
        if not ext and self._file_contains_ips(file_path):
            return True
        
        return False
    
    def _file_contains_ips(self, file_path):
        """Quick check if file contains IP addresses"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                # Read first 1000 characters
                sample = f.read(1000)
                # Look for IP pattern
                ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
                return bool(re.search(ip_pattern, sample))
        except:
            return False
    
    def _extract_ips_from_file(self, file_path):
        """Extract IPs from a file"""
        ips = set()
        lines_read = 0
        
        try:
            content = self._read_file_content(file_path)
            
            for line in content.splitlines():
                lines_read += 1
                line = line.strip()
                
                # Skip empty lines and comments
                if not line or self._is_comment_line(line):
                    continue
                
                # Extract IPs from line
                line_ips = self._extract_ips_from_line(line)
                for ip in line_ips:
                    if self._is_valid_public_ip(ip):
                        ips.add(ip)
                        self.stats['valid_ips_found'] += 1
                    else:
                        self.stats['invalid_ips'] += 1
            
            self.stats['total_lines_read'] += lines_read
            return ips, lines_read
            
        except Exception as e:
            self.log(f"Error extracting IPs from {file_path}: {e}", 'ERROR')
            return set(), 0
    
    def _read_file_content(self, file_path):
        """Read file content, handling compression"""
        try:
            if file_path.suffix.lower() == '.gz':
                with gzip.open(file_path, 'rt', encoding='utf-8', errors='ignore') as f:
                    return f.read()
            elif file_path.suffix.lower() == '.zip':
                with zipfile.ZipFile(file_path, 'r') as zf:
                    # Read first text file in archive
                    for filename in zf.namelist():
                        if filename.lower().endswith(('.txt', '.list', '.csv')):
                            with zf.open(filename) as f:
                                return f.read().decode('utf-8', errors='ignore')
            else:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    return f.read()
        except Exception as e:
            self.log(f"Error reading {file_path}: {e}", 'ERROR')
            return ""
    
    def _is_comment_line(self, line):
        """Check if line is a comment"""
        comment_markers = ['#', '//', ';', '!', '--', '%', '*']
        return any(line.startswith(marker) for marker in comment_markers)
    
    def _extract_ips_from_line(self, line):
        """Extract IP addresses from a line"""
        ips = []
        
        # Clean the line
        line = re.sub(r'[,;|\t]+', ' ', line)  # Replace separators
        line = re.sub(r'["\']', '', line)       # Remove quotes
        line = re.sub(r'[(){}[\]]', '', line)   # Remove brackets
        
        # IP regex pattern (IPv4)
        ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
        
        # Find all potential IPs
        potential_ips = re.findall(ip_pattern, line)
        
        for ip in potential_ips:
            if self._is_valid_ip_format(ip):
                ips.append(ip)
        
        # Handle CIDR notation
        cidr_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}\b'
        cidrs = re.findall(cidr_pattern, line)
        
        for cidr in cidrs:
            try:
                network = ipaddress.ip_network(cidr, strict=False)
                if network.num_addresses <= MAX_NETWORK_EXPANSION:
                    # Expand small networks
                    for ip in network.hosts():
                        ips.append(str(ip))
                else:
                    # For large networks, add network and broadcast
                    ips.append(str(network.network_address))
                    if network.broadcast_address:
                        ips.append(str(network.broadcast_address))
            except:
                pass
        
        return ips
    
    def _is_valid_ip_format(self, ip_str):
        """Validate IP format"""
        try:
            parts = ip_str.split('.')
            if len(parts) != 4:
                return False
            
            for part in parts:
                num = int(part)
                if num < 0 or num > 255:
                    return False
            
            return True
        except:
            return False
    
    def _is_valid_public_ip(self, ip_str):
        """Check if IP is valid and public"""
        try:
            ip = ipaddress.ip_address(ip_str)
            
            # Skip private, loopback, and reserved addresses
            if (ip.is_private or ip.is_loopback or ip.is_reserved or 
                ip.is_multicast or ip.is_link_local):
                return False
            
            # Skip invalid ranges
            first_octet = int(str(ip).split('.')[0])
            if first_octet in [0, 127, 255]:
                return False
            
            return True
        except:
            return False
    
    def _get_file_hash(self, file_path):
        """Get SHA256 hash of file"""
        try:
            hash_sha256 = hashlib.sha256()
            with open(file_path, "rb") as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_sha256.update(chunk)
            return hash_sha256.hexdigest()[:16]  # First 16 chars
        except:
            return "unknown"
    
    def generate_outputs(self):
        """Generate all output files"""
        if not self.all_ips:
            self.log("No IPs to generate outputs for", 'WARNING')
            return False
        
        # Create output directory
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        
        # Convert to sorted list for consistency
        sorted_ips = sorted(self.all_ips, key=lambda x: ipaddress.ip_address(x))
        
        # Generate JavaScript file
        self._generate_javascript(sorted_ips)
        
        # Generate JSON file
        self._generate_json(sorted_ips)
        
        # Generate statistics file
        self._generate_stats()
        
        return True
    
    def _generate_javascript(self, sorted_ips):
        """Generate JavaScript blacklist file"""
        # Limit IPs for performance
        js_ips = sorted_ips[:MAX_IPS_IN_JS]
        
        js_content = f'''// XXMXLI Comprehensive IP Blacklist
// Auto-generated from {len(self.sources)} source files
// Generated: {datetime.now().isoformat()}
// Total IPs processed: {len(sorted_ips):,}
// IPs in this file: {len(js_ips):,}

const BLOCKED_IPS = {json.dumps(js_ips, indent=2)};

const BLACKLIST_CONFIG = {{
    generated: "{datetime.now().isoformat()}",
    total_ips_processed: {len(sorted_ips)},
    ips_in_file: {len(js_ips)},
    sources_count: {len(self.sources)},
    performance_limited: {len(sorted_ips) > MAX_IPS_IN_JS},
    version: "1.0",
    source_directory: "{BLACKLIST_SOURCE_DIR}",
    processing_stats: {json.dumps(self.stats, indent=4)}
}};

const TOP_SOURCES = {json.dumps(
    dict(sorted(self.sources.items(), key=lambda x: x[1]['count'], reverse=True)[:10]),
    indent=2
)};

// IP checking functions
function isIPBlocked(ip) {{
    if (!ip || typeof ip !== 'string') return false;
    return BLOCKED_IPS.includes(ip);
}}

// Binary search for large lists
function isIPBlockedFast(ip) {{
    if (!ip || typeof ip !== 'string') return false;
    
    let left = 0;
    let right = BLOCKED_IPS.length - 1;
    
    while (left <= right) {{
        const mid = Math.floor((left + right) / 2);
        const midIP = BLOCKED_IPS[mid];
        
        if (midIP === ip) return true;
        
        const ipNum = ipToNumber(ip);
        const midNum = ipToNumber(midIP);
        
        if (midNum < ipNum) {{
            left = mid + 1;
        }} else {{
            right = mid - 1;
        }}
    }}
    
    return false;
}}

// Convert IP to number for comparison
function ipToNumber(ip) {{
    const parts = ip.split('.');
    return (parseInt(parts[0]) << 24) + 
           (parseInt(parts[1]) << 16) + 
           (parseInt(parts[2]) << 8) + 
           parseInt(parts[3]);
}}

// Get comprehensive statistics
function getBlacklistStats() {{
    return {{
        config: BLACKLIST_CONFIG,
        top_sources: TOP_SOURCES,
        memory_usage_kb: Math.round(BLOCKED_IPS.length * 15 / 1024),
        recommended_function: BLOCKED_IPS.length > 10000 ? 'isIPBlockedFast' : 'isIPBlocked',
        coverage: {{
            percentage_loaded: Math.round((BLACKLIST_CONFIG.ips_in_file / BLACKLIST_CONFIG.total_ips_processed) * 100),
            total_available: BLACKLIST_CONFIG.total_ips_processed,
            currently_blocking: BLACKLIST_CONFIG.ips_in_file
        }}
    }};
}}

// Search functions
function searchBlockedIPs(query) {{
    if (!query) return [];
    const results = BLOCKED_IPS.filter(ip => ip.includes(query));
    return results.slice(0, 100); // Limit results
}}

function getIPRange(startIP, endIP) {{
    const start = ipToNumber(startIP);
    const end = ipToNumber(endIP);
    return BLOCKED_IPS.filter(ip => {{
        const num = ipToNumber(ip);
        return num >= start && num <= end;
    }});
}}

// Export for Node.js
if (typeof module !== 'undefined' && module.exports) {{
    module.exports = {{
        BLOCKED_IPS,
        BLACKLIST_CONFIG,
        TOP_SOURCES,
        isIPBlocked,
        isIPBlockedFast,
        getBlacklistStats,
        searchBlockedIPs,
        getIPRange
    }};
}}

// Initialize
console.log(`🛡️ XXMXLI Blacklist loaded: ${{BLOCKED_IPS.length.toLocaleString()}} IPs from ${{BLACKLIST_CONFIG.sources_count}} sources`);
{f"console.warn('⚠️ Performance mode: Only {MAX_IPS_IN_JS:,} of {len(sorted_ips):,} IPs loaded');" if len(sorted_ips) > MAX_IPS_IN_JS else ""}
'''
        
        with open(JS_OUTPUT, 'w', encoding='utf-8') as f:
            f.write(js_content)
        
        self.log(f"✅ JavaScript file generated: {JS_OUTPUT}")
        self.log(f"   IPs included: {len(js_ips):,} of {len(sorted_ips):,}")
    
    def _generate_json(self, sorted_ips):
        """Generate comprehensive JSON data file"""
        json_data = {
            'metadata': {
                'generated': datetime.now().isoformat(),
                'version': '1.0',
                'source_directory': str(BLACKLIST_SOURCE_DIR),
                'processor': 'XXMXLI Blacklist Processor'
            },
            'statistics': self.stats,
            'blocked_ips': {
                'total_count': len(sorted_ips),
                'ips': sorted_ips
            },
            'sources': self.sources,
            'errors': self.errors,
            'analysis': {
                'top_sources': sorted(
                    [(name, data['count']) for name, data in self.sources.items()],
                    key=lambda x: x[1],
                    reverse=True
                )[:20],
                'file_types': self._analyze_file_types(),
                'ip_distribution': self._analyze_ip_distribution(sorted_ips)
            }
        }
        
        with open(JSON_OUTPUT, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)
        
        self.log(f"✅ JSON file generated: {JSON_OUTPUT}")
    
    def _generate_stats(self):
        """Generate statistics summary file"""
        stats_data = {
            'last_update': datetime.now().isoformat(),
            'summary': {
                'total_blocked_ips': len(self.all_ips),
                'source_files_processed': len(self.sources),
                'processing_time_seconds': self.stats.get('processing_time_seconds', 0),
                'errors_encountered': len(self.errors)
            },
            'top_10_sources': sorted(
                [(name, data['count']) for name, data in self.sources.items()],
                key=lambda x: x[1],
                reverse=True
            )[:10],
            'processing_stats': self.stats,
            'file_distribution': self._analyze_file_types()
        }
        
        with open(STATS_OUTPUT, 'w', encoding='utf-8') as f:
            json.dump(stats_data, f, indent=2)
        
        self.log(f"✅ Statistics file generated: {STATS_OUTPUT}")
    
    def _analyze_file_types(self):
        """Analyze distribution of file types"""
        file_types = {}
        for source, data in self.sources.items():
            ext = Path(source).suffix.lower() or 'no_extension'
            if ext not in file_types:
                file_types[ext] = {'count': 0, 'ips': 0}
            file_types[ext]['count'] += 1
            file_types[ext]['ips'] += data['count']
        return file_types
    
    def _analyze_ip_distribution(self, sorted_ips):
        """Analyze IP address distribution"""
        if not sorted_ips:
            return {}
        
        # Count by first octet
        first_octets = {}
        for ip in sorted_ips[:10000]:  # Sample for performance
            first = ip.split('.')[0]
            first_octets[first] = first_octets.get(first, 0) + 1
        
        return {
            'sample_size': min(len(sorted_ips), 10000),
            'top_first_octets': sorted(
                first_octets.items(),
                key=lambda x: x[1],
                reverse=True
            )[:10]
        }

def main():
    """Main execution function"""
    print("🚀 XXMXLI Comprehensive IP Blacklist Processor")
    print("=" * 60)
    
    # Initialize processor
    processor = BlacklistProcessor()
    
    # Process all blacklists
    success = processor.process_all_blacklists()
    
    if success:
        # Generate output files
        if processor.generate_outputs():
            print("\n" + "=" * 60)
            print("🎉 PROCESSING COMPLETED SUCCESSFULLY!")
            print("=" * 60)
            print(f"📊 Final Statistics:")
            print(f"   • Total unique IPs: {len(processor.all_ips):,}")
            print(f"   • Source files: {len(processor.sources)}")
            print(f"   • Processing time: {processor.stats.get('processing_time_seconds', 0):.2f}s")
            print(f"   • Files processed: {processor.stats['files_processed']}")
            print(f"   • Files skipped: {processor.stats['files_skipped']}")
            print(f"   • Errors: {len(processor.errors)}")
            
            print(f"\n📁 Output Files:")
            print(f"   • JavaScript: {JS_OUTPUT}")
            print(f"   • JSON Data: {JSON_OUTPUT}")
            print(f"   • Statistics: {STATS_OUTPUT}")
            print(f"   • Processing Log: {LOG_OUTPUT}")
            
            if processor.errors:
                print(f"\n⚠️ Errors encountered:")
                for error in processor.errors[:5]:
                    print(f"   • {error}")
                if len(processor.errors) > 5:
                    print(f"   • ... and {len(processor.errors) - 5} more (see log file)")
            
            print(f"\n🔒 Ready to deploy comprehensive IP blocking!")
            
        else:
            print("❌ Failed to generate output files")
            return 1
    else:
        print("❌ Failed to process blacklists")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())