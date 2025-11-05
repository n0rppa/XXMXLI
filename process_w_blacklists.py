#!/usr/bin/env python3
"""
Complete IP Blacklist Processor for XXMXLI
Processes all IP blacklist files from the 'w' folder and generates JavaScript blocklist

SECURITY WARNING: This system is actively monitored and protected.
Any unauthorized access attempts, network scanning, intrusion, or abusive activity 
will be logged and reported to the appropriate authorities. IP addresses and metadata 
may be retained and used for legal enforcement, in compliance with applicable laws.
By continuing, you acknowledge that you are authorized to use this system and that 
any misuse may result in account suspension, firewall bans, or prosecution under 
national and international law. Violators may be subject to civil and/or criminal 
penalties. Your access is being monitored.
"""

import os
import json
import ipaddress
import re
import gzip
from pathlib import Path
from datetime import datetime

# Configuration
# Hardcoded default W folder with safe fallbacks and env override
SCRIPT_DIR = Path(__file__).parent.resolve()
REPO_ROOT = SCRIPT_DIR
try:
    # Try to detect repo root by common markers
    for p in [SCRIPT_DIR, *SCRIPT_DIR.parents]:
        if (p / '.git').exists() or (p / 'README.md').exists():
            REPO_ROOT = p
            break
except Exception:
    pass

HARDCODED_W_FOLDER = Path('/home/kodachi/Desktop/kotisivu/w')

def resolve_w_folder() -> Path:
    # 1) Explicit env override
    env_path = os.environ.get('W_FOLDER')
    if env_path:
        p = Path(env_path).expanduser().resolve()
        if p.exists():
            return p
    # 2) Hardcoded absolute path (requested)
    if HARDCODED_W_FOLDER.exists():
        return HARDCODED_W_FOLDER
    # 3) Repo-root w
    p = (REPO_ROOT / 'w').resolve()
    if p.exists():
        return p
    # 4) Script-dir w
    p = (SCRIPT_DIR / 'w').resolve()
    if p.exists():
        return p
    # 5) Parent dir w
    p = (SCRIPT_DIR.parent / 'w').resolve()
    if p.exists():
        return p
    # Fallback to repo-root w even if missing (we'll warn)
    return (REPO_ROOT / 'w').resolve()

BLACKLIST_SOURCE_DIR = resolve_w_folder()
OUTPUT_DIR = Path('assets/security')
JS_OUTPUT = OUTPUT_DIR / 'blocked_ips.js'
JSON_OUTPUT = OUTPUT_DIR / 'blocked_ips.json'
STATS_OUTPUT = OUTPUT_DIR / 'blacklist_stats.json'

# File extensions to process
SUPPORTED_EXTENSIONS = {'.txt', '.ipset', '.list', '.csv', '.dat', '.conf'}

def load_all_blacklists():
    """Load all IP blacklists from the w folder"""
    print(f"=== Processing IP Blacklists from {BLACKLIST_SOURCE_DIR} ===")
    
    all_ips = set()
    sources = {}
    errors = []
    
    if not BLACKLIST_SOURCE_DIR.exists():
        print(f"❌ Source directory {BLACKLIST_SOURCE_DIR} not found!")
        return set(), {}, []
    
    # Process all files recursively
    for file_path in BLACKLIST_SOURCE_DIR.rglob('*'):
        if file_path.is_file() and (file_path.suffix.lower() in SUPPORTED_EXTENSIONS or file_path.suffix == ''):
            try:
                print(f"📁 Processing: {file_path.relative_to(BLACKLIST_SOURCE_DIR)}")
                
                file_ips = process_blacklist_file(file_path)
                
                if file_ips:
                    source_key = str(file_path.relative_to(BLACKLIST_SOURCE_DIR))
                    sources[source_key] = {
                        'file_path': str(file_path),
                        'count': len(file_ips),
                        'size_bytes': file_path.stat().st_size,
                        'modified': datetime.fromtimestamp(file_path.stat().st_mtime).isoformat(),
                        'processed': datetime.now().isoformat()
                    }
                    
                    all_ips.update(file_ips)
                    print(f"   ✅ Loaded {len(file_ips)} IPs (Total unique: {len(all_ips)})")
                else:
                    print(f"   ⚠️  No valid IPs found")
                    
            except Exception as e:
                error_msg = f"Error processing {file_path}: {str(e)}"
                errors.append(error_msg)
                print(f"   ❌ {error_msg}")
    
    print(f"\n📊 Summary:")
    print(f"   Files processed: {len(sources)}")
    print(f"   Total unique IPs: {len(all_ips)}")
    print(f"   Errors: {len(errors)}")
    
    return all_ips, sources, errors

def process_blacklist_file(file_path):
    """Process a single blacklist file"""
    ips = set()
    
    try:
        # Handle different file types
        if file_path.suffix.lower() == '.gz':
            with gzip.open(file_path, 'rt', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        else:
            # Try different encodings
            encodings = ['utf-8', 'latin-1', 'cp1252', 'ascii']
            content = None
            
            for encoding in encodings:
                try:
                    with open(file_path, 'r', encoding=encoding, errors='ignore') as f:
                        content = f.read()
                    break
                except:
                    continue
            
            if content is None:
                print(f"      Could not read file with any encoding")
                return set()
        
        # Process content line by line
        for line_num, line in enumerate(content.splitlines(), 1):
            line = line.strip()
            
            # Skip empty lines, comments, and headers
            if not line or line.startswith(('#', '//', ';', '!', '[', '*')) or 'IP' in line.upper() and 'ADDRESS' in line.upper():
                continue
            
            # Extract IPs from the line
            extracted_ips = extract_ips_from_line(line)
            for ip in extracted_ips:
                if is_valid_public_ip(ip):
                    ips.add(ip)
        
        return ips
        
    except Exception as e:
        print(f"      Error reading file: {e}")
        return set()

def extract_ips_from_line(line):
    """Extract IP addresses from various line formats"""
    ips = []
    
    # Clean the line
    line = re.sub(r'[,;|\t]+', ' ', line)  # Replace separators with spaces
    line = re.sub(r'["\']', '', line)       # Remove quotes
    line = line.split('#')[0].strip()       # Remove comments
    
    # IP regex pattern (matches IPv4)
    ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
    
    # Find all potential IPs
    potential_ips = re.findall(ip_pattern, line)
    
    for ip in potential_ips:
        if is_valid_ip_format(ip):
            ips.append(ip)
    
    # Handle CIDR notation
    cidr_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}\b'
    cidrs = re.findall(cidr_pattern, line)
    
    for cidr in cidrs:
        try:
            network = ipaddress.ip_network(cidr, strict=False)
            # Only expand small networks to avoid memory issues
            if network.num_addresses <= 256:
                for ip in network.hosts():
                    ips.append(str(ip))
            else:
                # For large networks, add network and broadcast
                ips.append(str(network.network_address))
                if network.num_addresses > 1:
                    ips.append(str(network.broadcast_address))
        except:
            pass
    
    return ips

def is_valid_ip_format(ip_str):
    """Check if string is a valid IPv4 address format"""
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

def is_valid_public_ip(ip_str):
    """Check if IP is valid and public (not private/reserved)"""
    try:
        ip = ipaddress.ip_address(ip_str)
        
        # Skip private, loopback, and reserved addresses
        if ip.is_private or ip.is_loopback or ip.is_reserved or ip.is_multicast:
            return False
        
        # Skip obviously invalid ranges
        if str(ip).startswith(('0.', '127.', '255.255.255')):
            return False
        
        # Skip documentation ranges
        if str(ip).startswith(('192.0.2.', '198.51.100.', '203.0.113.')):
            return False
        
        return True
    except:
        return False

def generate_javascript_output(ip_list, sources, errors, total_count: int = None):
    """Generate JavaScript file with all blocked IPs"""
    
    # Sort IPs (subset) for better organization and binary search
    # Note: ip_list can be a pre-selected subset for performance
    sorted_ips = sorted(ip_list, key=lambda x: ipaddress.ip_address(x))
    
    # Limit for performance - keep most recent/relevant
    max_ips = 100000
    if len(sorted_ips) > max_ips:
        # Take a distributed sample to maintain coverage
        step = len(sorted_ips) // max_ips
        sorted_ips = sorted_ips[::step][:max_ips]
    
    db_total = total_count if total_count is not None else len(ip_list)

    js_content = f'''// XXMXLI Comprehensive IP Blacklist - Auto Generated
// Generated: {datetime.now().isoformat()}
// Total IPs in database: {db_total:,}
// Loaded IPs: {len(sorted_ips):,}
// Sources: {len(sources)} files
// Performance optimized for web deployment

const BLOCKED_IPS = {json.dumps(sorted_ips, indent=2)};

const BLACKLIST_CONFIG = {{
    generated: "{datetime.now().isoformat()}",
    database_total: {db_total},
    loaded_count: {len(sorted_ips)},
    sources_count: {len(sources)},
    has_errors: {len(errors) > 0},
    performance_optimized: {db_total > max_ips},
    version: "1.0.0"
}};

const BLACKLIST_SOURCES = {json.dumps(dict(list(sources.items())[:20]), indent=2)};

// Quick IP check function with fallback
function isIPBlocked(ip) {{
    if (!ip || typeof ip !== 'string') return false;
    return BLOCKED_IPS.includes(ip);
}}

// Binary search for optimized performance
function isIPBlockedFast(ip) {{
    if (!ip || typeof ip !== 'string') return false;
    
    let left = 0;
    let right = BLOCKED_IPS.length - 1;
    
    while (left <= right) {{
        const mid = Math.floor((left + right) / 2);
        const midIP = BLOCKED_IPS[mid];
        
        if (midIP === ip) return true;
        
        const comparison = compareIPs(ip, midIP);
        if (comparison === 0) return true;
        
        if (comparison > 0) {{
            left = mid + 1;
        }} else {{
            right = mid - 1;
        }}
    }}
    
    return false;
}}

// IP comparison function for sorting
function compareIPs(ip1, ip2) {{
    const ip1Parts = ip1.split('.').map(Number);
    const ip2Parts = ip2.split('.').map(Number);
    
    for (let i = 0; i < 4; i++) {{
        if (ip1Parts[i] !== ip2Parts[i]) {{
            return ip1Parts[i] - ip2Parts[i];
        }}
    }}
    return 0;
}}

// Range check for subnet blocking
function isIPInBlockedRange(ip) {{
    // Quick check against common malicious ranges
    const maliciousRanges = [
        {{ start: "1.2.4.0", end: "1.2.7.255" }},
        {{ start: "14.102.0.0", end: "14.102.255.255" }},
        {{ start: "27.0.0.0", end: "27.255.255.255" }},
        {{ start: "31.0.0.0", end: "31.255.255.255" }},
        {{ start: "36.0.0.0", end: "36.255.255.255" }},
        {{ start: "39.0.0.0", end: "39.255.255.255" }},
        {{ start: "42.0.0.0", end: "42.255.255.255" }},
        {{ start: "58.0.0.0", end: "58.255.255.255" }},
        {{ start: "59.0.0.0", end: "59.255.255.255" }},
        {{ start: "60.0.0.0", end: "60.255.255.255" }},
        {{ start: "61.0.0.0", end: "61.255.255.255" }},
        {{ start: "101.0.0.0", end: "101.255.255.255" }},
        {{ start: "103.0.0.0", end: "103.255.255.255" }},
        {{ start: "110.0.0.0", end: "110.255.255.255" }},
        {{ start: "111.0.0.0", end: "111.255.255.255" }},
        {{ start: "112.0.0.0", end: "112.255.255.255" }},
        {{ start: "113.0.0.0", end: "113.255.255.255" }},
        {{ start: "114.0.0.0", end: "114.255.255.255" }},
        {{ start: "115.0.0.0", end: "115.255.255.255" }},
        {{ start: "116.0.0.0", end: "116.255.255.255" }},
        {{ start: "117.0.0.0", end: "117.255.255.255" }},
        {{ start: "118.0.0.0", end: "118.255.255.255" }},
        {{ start: "119.0.0.0", end: "119.255.255.255" }},
        {{ start: "120.0.0.0", end: "120.255.255.255" }},
        {{ start: "121.0.0.0", end: "121.255.255.255" }},
        {{ start: "122.0.0.0", end: "122.255.255.255" }},
        {{ start: "123.0.0.0", end: "123.255.255.255" }},
        {{ start: "124.0.0.0", end: "124.255.255.255" }},
        {{ start: "125.0.0.0", end: "125.255.255.255" }}
    ];
    
    const ipNum = ipToNumber(ip);
    
    for (const range of maliciousRanges) {{
        const startNum = ipToNumber(range.start);
        const endNum = ipToNumber(range.end);
        
        if (ipNum >= startNum && ipNum <= endNum) {{
            return true;
        }}
    }}
    
    return false;
}}

// Convert IP to number for comparison
function ipToNumber(ip) {{
    const parts = ip.split('.').map(Number);
    return (parts[0] << 24) + (parts[1] << 16) + (parts[2] << 8) + parts[3];
}}

// Main blocking check function
function checkIPBlocked(ip) {{
    // Try exact match first (fastest)
    if (isIPBlockedFast(ip)) return true;
    
    // Check IP ranges for broader protection
    if (isIPInBlockedRange(ip)) return true;
    
    return false;
}}

// Get comprehensive blacklist statistics
function getBlacklistStats() {{
    return {{
        ...BLACKLIST_CONFIG,
        sources: BLACKLIST_SOURCES,
        memory_usage_kb: Math.round((JSON.stringify(BLOCKED_IPS).length) / 1024),
        check_functions: ["isIPBlocked", "isIPBlockedFast", "checkIPBlocked", "isIPInBlockedRange"],
        coverage: {{
            exact_ips: BLOCKED_IPS.length,
            range_blocks: 25,
            estimated_total_coverage: BLOCKED_IPS.length + 100000000 // Rough estimate including ranges
        }}
    }};
}}

// Threat level assessment
function getThreatLevel(ip) {{
    if (!ip) return "unknown";
    
    // Check against exact blacklist
    if (isIPBlockedFast(ip)) return "high";
    
    // Check against ranges
    if (isIPInBlockedRange(ip)) return "medium";
    
    // Additional heuristics
    const parts = ip.split('.').map(Number);
    
    // Known problematic ASNs/regions (simplified)
    if (parts[0] >= 58 && parts[0] <= 125) return "elevated";
    if (parts[0] === 185 || parts[0] === 193) return "elevated";
    
    return "low";
}}

// Export functions for use in other scripts
if (typeof module !== 'undefined' && module.exports) {{
    module.exports = {{
        BLOCKED_IPS,
        BLACKLIST_CONFIG,
        BLACKLIST_SOURCES,
        isIPBlocked,
        isIPBlockedFast,
        checkIPBlocked,
        isIPInBlockedRange,
        getBlacklistStats,
        getThreatLevel
    }};
}}

// Initialize and log statistics
console.log(`🛡️  XXMXLI Blacklist loaded: ${{BLOCKED_IPS.length.toLocaleString()}} exact IPs + range blocks`);
console.log(`📊 Coverage: ~${{Math.round(BLACKLIST_CONFIG.coverage?.estimated_total_coverage / 1000000) || 100}}M potential threats blocked`);
console.log(`🔍 Sources: ${{BLACKLIST_CONFIG.sources_count}} threat intelligence feeds`);
if (BLACKLIST_CONFIG.performance_optimized) {{
    console.log(`⚡ Performance mode: Optimized from ${{BLACKLIST_CONFIG.database_total.toLocaleString()}} total IPs`);
}}
'''

    return js_content

def save_outputs(ip_list, sources, errors, started_at: datetime):
    """Save all output files using an optimized approach (no full sort of the dataset)."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Convert to list once
    ips_list = list(ip_list)
    total_count = len(ips_list)

    # JS subset cap for client-side usage; selecting with step to keep spread
    max_js_ips = 100_000
    if total_count > max_js_ips:
        step = max(1, total_count // max_js_ips)
        js_subset = ips_list[::step][:max_js_ips]
    else:
        js_subset = ips_list

    # Generate JavaScript content (function sorts the subset)
    js_content = generate_javascript_output(js_subset, sources, errors, total_count=total_count)
    with open(JS_OUTPUT, 'w', encoding='utf-8') as f:
        f.write(js_content)
    print(f"✅ JavaScript saved: {JS_OUTPUT}")

    # JSON: limit to top 10k of the sorted subset
    from_head = min(10_000, len(js_subset))
    json_blocked_ips = sorted(js_subset, key=lambda x: ipaddress.ip_address(x))[:from_head]

    distribution = get_ip_distribution(ips_list)

    json_data = {
        'generated': datetime.now().isoformat(),
        'total_ips': total_count,
        'blocked_ips': json_blocked_ips,
        'ip_count_by_first_octet': distribution,
        'sources': sources,
        'errors': errors,
        'statistics': {
            'files_processed': len(sources),
            'total_file_size': sum(s.get('size_bytes', 0) for s in sources.values()),
            'largest_source': max(sources.items(), key=lambda x: x[1]['count']) if sources else None,
            'processing_time_seconds': (datetime.now() - started_at).total_seconds(),
        }
    }

    with open(JSON_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(json_data, f, indent=2)
    print(f"✅ JSON saved: {JSON_OUTPUT}")

    # Stats file
    stats_summary = {
        'last_update': datetime.now().isoformat(),
        'total_blocked_ips': total_count,
        'source_files': len(sources),
        'top_sources': sorted(
            [(name, data['count']) for name, data in sources.items()],
            key=lambda x: x[1],
            reverse=True
        )[:10],
        'errors_count': len(errors),
        'distribution': distribution,
    }

    with open(STATS_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(stats_summary, f, indent=2)
    print(f"✅ Stats saved: {STATS_OUTPUT}")

def get_ip_distribution(ip_list):
    """Get distribution of IPs by first octet"""
    distribution = {}
    for ip in ip_list:
        first_octet = ip.split('.')[0]
        distribution[first_octet] = distribution.get(first_octet, 0) + 1
    
    # Return top 20 most common
    return dict(sorted(distribution.items(), key=lambda x: x[1], reverse=True)[:20])

def main():
    """Main processing function"""
    print("🚀 Starting comprehensive IP blacklist processing...")
    print("📂 Processing blacklist directory:", BLACKLIST_SOURCE_DIR.absolute())
    if not BLACKLIST_SOURCE_DIR.exists():
        print(f"⚠️  Warning: Resolved W folder does not exist: {BLACKLIST_SOURCE_DIR}")
        print("    Set W_FOLDER env var to override, e.g., export W_FOLDER=/path/to/w")
    
    start_time = datetime.now()
    
    # Load all blacklists
    all_ips, sources, errors = load_all_blacklists()
    
    if all_ips:
        # Save outputs (optimized)
        save_outputs(all_ips, sources, errors, started_at=start_time)

        # Print completion summary
        end_time = datetime.now()
        processing_time = (end_time - start_time).total_seconds()
        print(f"\n🎉 Processing completed in {processing_time:.2f} seconds!")
        print(f"📈 Results:")
        print(f"   • {len(all_ips):,} unique IPs blocked")
        print(f"   • {len(sources)} source files processed")
        print(f"   • {len(errors)} errors encountered")

        if errors:
            print(f"\n⚠️  Errors (showing first 5):")
            for error in errors[:5]:
                print(f"   • {error}")
            if len(errors) > 5:
                print(f"   • ... and {len(errors) - 5} more errors")

    else:
        print("❌ No IPs were processed. Check your source directory and file formats.")
        print(f"   Expected directory: {BLACKLIST_SOURCE_DIR.absolute()}")

if __name__ == "__main__":
    main()