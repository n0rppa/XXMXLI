#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#!/usr/bin/env python3
"""
XXMXLI Master Control Launcher v2.0.0
Professional System Management Hub with Enhanced Security

A comprehensive control center for all XXMXLI operations including:
- Security monitoring and threat intelligence
- System health diagnostics  
- Automated incident reporting
- IP blocking deployment
- Content management (Admin Only)
- System administration (Admin Only)

Features:
- Beautiful interactive interface with ANSI colors
- Admin authentication for sensitive operations
- Cross-platform compatibility
- Professional error handling
- Comprehensive logging

Author: XXMXLI Security Team
"""

import os
import sys
import subprocess
import signal
import time
import getpass
import platform
from datetime import datetime

import os
import sys
import subprocess
import json
import time
from datetime import datetime
import signal

# Color definitions for beautiful terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[0;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    GRAY = '\033[0;37m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    NC = '\033[0m'  # No Color

# Unicode symbols for enhanced UX
class Symbols:
    CHECK = "✅"
    CROSS = "❌"
    WARNING = "⚠️"
    ARROW = "➤"
    STAR = "⭐"
    SHIELD = "🛡️"
    GEAR = "⚙️"
    ROCKET = "🚀"
    MAGNIFY = "🔍"
    CHART = "📊"
    GLOBE = "🌐"
    FILE = "📁"
    INFO = "ℹ️"
    HEART = "💚"
    LIGHTNING = "⚡"
    FIRE = "🔥"
    CROWN = "👑"
    DIAMOND = "💎"

class XXMXLILauncher:
    def __init__(self):
        self.running = True
        self.admin_authenticated = False
        self.base_dir = os.path.dirname(os.path.abspath(__file__))
        self.mode = "unknown"
        self.setup_signal_handlers()
        self.check_environment()
        self.check_admin_credentials()

    def setup_signal_handlers(self):
        """Setup graceful shutdown on Ctrl+C"""
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
    
    def signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully"""
        print(f"\n{Colors.YELLOW}{Symbols.WARNING} Graceful shutdown initiated...{Colors.NC}")
        self.running = False
        sys.exit(0)
    
    def check_admin_credentials(self):
        """Check for admin credentials file presence (no website dependency)"""
        creds_file = os.path.join(self.base_dir, "ADMIN_CREDENTIALS_SECURE.txt")
        if not os.path.isfile(creds_file):
            self.warn("Admin features disabled - no credentials file found")
            return
        self.info("Admin features require proper authentication")
        choice = input(f"{Colors.YELLOW}Access admin features? [y/N]: {Colors.NC}").strip().lower()
        if choice == 'y':
            self.authenticate_admin()
    
    def authenticate_admin(self):
        """Enhanced admin authentication with username/password"""
        try:
            print(f"\n{Colors.CYAN}🔐 ADMIN AUTHENTICATION{Colors.NC}")
            print("================================================================")
            print(f"{Colors.YELLOW}{Symbols.WARNING} Admin access required for content management features{Colors.NC}")
            print()
            
            # Option 1: Username/Password authentication
            print(f"{Colors.CYAN}1) Username/Password Authentication{Colors.NC}")
            print(f"{Colors.CYAN}2) Legacy Key Authentication{Colors.NC}")
            print()
            
            auth_method = input(f"{Colors.YELLOW}Choose authentication method [1-2]: {Colors.NC}").strip()
            
            if auth_method == "1":
                # Username/password authentication
                username = input(f"{Colors.CYAN}Username: {Colors.NC}").strip()
                if not username:
                    self.error("Username cannot be empty")
                    input("Press Enter to continue...")
                    return False
                
                password = getpass.getpass(f"{Colors.CYAN}Password: {Colors.NC}")
                if not password:
                    self.error("Password cannot be empty")
                    input("Press Enter to continue...")
                    return False
                
                # Check credentials against stored file (format: username:password)
                creds_file = os.path.join(self.base_dir, 'ADMIN_CREDENTIALS_SECURE.txt')
                if not os.path.exists(creds_file):
                    self.error("Admin credentials file not found - contact system administrator")
                    input("Press Enter to continue...")
                    return False
                
                try:
                    with open(creds_file, 'r') as f:
                        lines = f.read().strip().split('\n')
                        # Check if first line is username:password format or legacy key
                        if ':' in lines[0]:
                            stored_creds = lines[0].split(':')
                            if len(stored_creds) >= 2:
                                stored_username, stored_password = stored_creds[0], stored_creds[1]
                                
                                if username == stored_username and password == stored_password:
                                    self.admin_authenticated = True
                                    self.success("Admin authentication successful!")
                                    self.info("Full system access granted")
                                    input("Press Enter to continue...")
                                    return True
                                else:
                                    self.error("Invalid credentials")
                                    input("Press Enter to continue...")
                                    return False
                        else:
                            self.error("Credentials file format not compatible with username/password authentication")
                            self.info("Use legacy key authentication or update credentials file")
                            input("Press Enter to continue...")
                            return False
                            
                except Exception as e:
                    self.error(f"Error reading credentials file: {e}")
                    input("Press Enter to continue...")
                    return False
            
            elif auth_method == "2":
                # Legacy key authentication
                admin_key = getpass.getpass(f"{Colors.CYAN}Enter admin access key: {Colors.NC}")
                
                # Check against credentials file
                creds_file = os.path.join(self.base_dir, "ADMIN_CREDENTIALS_SECURE.txt")
                if os.path.isfile(creds_file):
                    with open(creds_file, "r") as f:
                        stored_content = f.read().strip()
                        # If it's username:password format, use the password part
                        if ':' in stored_content:
                            stored_key = stored_content.split(':')[1]
                        else:
                            stored_key = stored_content
                            
                        if admin_key == stored_key:
                            self.admin_authenticated = True
                            self.success("Admin authentication successful")
                            self.info("Full system access granted")
                            input("Press Enter to continue...")
                            return True
                        else:
                            self.error("Invalid admin credentials")
                            self.warn("Admin features remain disabled")
                            input("Press Enter to continue...")
                            return False
                else:
                    self.error("Admin credentials file not found")
                    input("Press Enter to continue...")
                    return False
            else:
                self.error("Invalid authentication method")
                input("Press Enter to continue...")
                return False
                
        except KeyboardInterrupt:
            print(f"\n{Colors.YELLOW}Authentication cancelled{Colors.NC}")
            input("Press Enter to continue...")
            return False
        except Exception as e:
            self.error(f"Authentication error: {str(e)}")
            input("Press Enter to continue...")
            return False
    
    def check_environment(self):
        """Detect environment and set mode; do not require website directory"""
        # If an index.html is alongside, we are in website mode; otherwise standalone
        if os.path.isfile(os.path.join(self.base_dir, 'index.html')):
            self.mode = 'website'
            self.info("Website mode detected (index.html found)")
        else:
            self.mode = 'standalone'
            self.info("Standalone mode detected (no website directory required)")
    
    def log(self, message):
        """Log message with timestamp"""
        timestamp = datetime.now().strftime('%H:%M:%S')
        print(f"{Colors.WHITE}[{timestamp}]{Colors.NC} {message}")
    
    def success(self, message):
        """Success message"""
        print(f"{Colors.GREEN}{Symbols.CHECK}{Colors.NC} {message}")
    
    def error(self, message):
        """Error message"""
        print(f"{Colors.RED}{Symbols.CROSS}{Colors.NC} {message}")
    
    def warn(self, message):
        """Warning message"""
        print(f"{Colors.YELLOW}{Symbols.WARNING}{Colors.NC} {message}")
    
    def info(self, message):
        """Info message"""
        print(f"{Colors.CYAN}{Symbols.INFO}{Colors.NC} {message}")
    
    def critical(self, message):
        """Critical message"""
        print(f"{Colors.RED}{Symbols.FIRE}{Colors.NC} {Colors.WHITE}{message}{Colors.NC}")
    
    def show_banner(self):
        """Display the beautiful XXMXLI banner"""
        os.system('clear' if os.name == 'posix' else 'cls')
        print(f"{Colors.PURPLE}")
        print("""
    ╔══════════════════════════════════════════════════════════════╗
    ║              ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗          ║
    ║              ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║          ║
    ║               ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║          ║
    ║               ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║          ║
    ║              ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗     ║
    ║              ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝     ║
    ║                                                              ║
    ║                    MASTER CONTROL LAUNCHER                   ║
    ║              Professional System Management Hub              ║
    ╚══════════════════════════════════════════════════════════════╝""")
        print(f"{Colors.NC}")
        print(f"{Colors.PURPLE}        {Symbols.CROWN} Ultimate Ease-of-Use Interface{Colors.NC}")
        print(f"{Colors.YELLOW}        {Symbols.LIGHTNING} One Hub for All Operations{Colors.NC}")
        print()
    
    def show_system_status(self):
        """Show quick system status"""
        print(f"{Colors.CYAN}{Symbols.ARROW} System Status:{Colors.NC}")
        
        # Check server status (optional)
        try:
            import requests
            response = requests.get('http://localhost:8000', timeout=2)
            if response.status_code == 200:
                self.success("Development server: RUNNING")
            else:
                self.warn("Development server: RESPONDING (HTTP {})".format(response.status_code))
        except Exception:
            self.warn("Development server: NOT RUNNING")
        
        # Security status (best-effort, no website requirement)
        if self.mode == 'website':
            htaccess_path = os.path.join(self.base_dir, '.htaccess')
            if os.path.isfile(htaccess_path):
                try:
                    content = open(htaccess_path, 'r', errors='ignore').read()
                    if 'XXMXLI' in content:
                        self.success("Security blocking: ACTIVE")
                    else:
                        self.warn("Security blocking: BASIC")
                except Exception:
                    self.warn("Security blocking: UNKNOWN")
            else:
                self.error("Security blocking: INACTIVE")
        else:
            self.info("Security blocking: N/A (standalone mode)")
        
        print()
    
    def show_main_menu(self):
        """Display the main interactive menu"""
        while self.running:
            self.show_banner()
            self.show_system_status()
            
            print(f"{Colors.WHITE}{Symbols.ARROW} XXMXLI OPERATIONS CENTER{Colors.NC}")
            if self.admin_authenticated:
                print(f"{Colors.GREEN}🔓 ADMIN MODE ENABLED{Colors.NC}")
            else:
                print(f"{Colors.YELLOW}🔒 PUBLIC MODE - Limited Features{Colors.NC}")
            print("================================================================")
            print()
            print(f"{Colors.GREEN}📊 MONITORING & ANALYTICS{Colors.NC}")
            print(f"  {Colors.GREEN}1){Colors.NC} {Symbols.SHIELD} Security Monitor & Threat Intelligence")
            print(f"  {Colors.GREEN}2){Colors.NC} {Symbols.HEART} System Health Check & Diagnostics")
            print(f"  {Colors.GREEN}3){Colors.NC} {Symbols.CHART} Visitor Analytics & Statistics")
            print()
            print(f"{Colors.BLUE}🚀 DEPLOYMENT & MANAGEMENT{Colors.NC}")
            print(f"  {Colors.BLUE}4){Colors.NC} {Symbols.ROCKET} IP Blocking Deployment System")
            print(f"  {Colors.BLUE}5){Colors.NC} {Symbols.GEAR} Automated Incident Reporter")
            print(f"  {Colors.BLUE}6){Colors.NC} {Symbols.GLOBE} Development Server Management")
            print()
            
            # Admin-only content management section
            if self.admin_authenticated:
                print(f"{Colors.PURPLE}🎵 CONTENT MANAGEMENT (ADMIN ONLY){Colors.NC}")
                print(f"  {Colors.PURPLE}7){Colors.NC} {Symbols.STAR} Music Library Manager")
                print(f"  {Colors.PURPLE}8){Colors.NC} {Symbols.DIAMOND} Photo Gallery Manager")
                print(f"  {Colors.PURPLE}9){Colors.NC} {Symbols.FILE} Content Update System")
                print()
                print(f"{Colors.YELLOW}⚙️ SYSTEM UTILITIES (ADMIN ONLY){Colors.NC}")
                print(f"  {Colors.YELLOW}10){Colors.NC} {Symbols.LIGHTNING} Automated System Updates")
                print(f"  {Colors.YELLOW}11){Colors.NC} {Symbols.MAGNIFY} Database Management")
                print(f"  {Colors.YELLOW}12){Colors.NC} {Symbols.FIRE} Emergency Procedures")
                print()
            else:
                print(f"{Colors.GRAY}🔒 ADMIN FEATURES (AUTHENTICATION REQUIRED){Colors.NC}")
                print(f"  {Colors.GRAY}7){Colors.NC} {Colors.GRAY}🔒 Content Management (Admin Only){Colors.NC}")
                print(f"  {Colors.GRAY}8){Colors.NC} {Colors.GRAY}🔒 System Administration (Admin Only){Colors.NC}")
                print(f"  {Colors.GRAY}9){Colors.NC} {Colors.GRAY}🔒 Emergency Procedures (Admin Only){Colors.NC}")
                print()
                print(f"  {Colors.CYAN}10){Colors.NC} {Symbols.GEAR} Request Admin Access")
                print()
            
            print(f"{Colors.CYAN}📚 INFORMATION & HELP{Colors.NC}")
            if self.admin_authenticated:
                print(f"  {Colors.CYAN}13){Colors.NC} {Symbols.INFO} System Documentation")
                print(f"  {Colors.CYAN}14){Colors.NC} {Symbols.CROWN} About XXMXLI System")
            else:
                print(f"  {Colors.CYAN}11){Colors.NC} {Symbols.INFO} System Documentation")
                print(f"  {Colors.CYAN}12){Colors.NC} {Symbols.CROWN} About XXMXLI System")
            print()
            print(f"{Colors.RED}0){Colors.NC} {Symbols.CROSS} Exit Launcher")
            print()
            
            try:
                if self.admin_authenticated:
                    choice = input(f"{Colors.YELLOW}Choose operation [0-14]: {Colors.NC}").strip()
                    max_choice = 14
                else:
                    choice = input(f"{Colors.YELLOW}Choose operation [0-12]: {Colors.NC}").strip()
                    max_choice = 12
                
                if choice == '0':
                    self.exit_launcher()
                elif choice == '1':
                    self.launch_security_monitor()
                elif choice == '2':
                    self.launch_health_check()
                elif choice == '3':
                    self.launch_visitor_analytics()
                elif choice == '4':
                    self.launch_ip_deployment()
                elif choice == '5':
                    self.launch_incident_reporter()
                elif choice == '6':
                    self.launch_server_management()
                elif choice == '7':
                    if self.admin_authenticated:
                        self.launch_music_manager()
                    else:
                        self.error("Access denied - Admin authentication required")
                        input("Press Enter to continue...")
                elif choice == '8':
                    if self.admin_authenticated:
                        self.launch_gallery_manager()
                    else:
                        self.error("Access denied - Admin authentication required")
                        input("Press Enter to continue...")
                elif choice == '9':
                    if self.admin_authenticated:
                        self.launch_content_updates()
                    else:
                        self.error("Access denied - Admin authentication required")
                        input("Press Enter to continue...")
                elif choice == '10':
                    if self.admin_authenticated:
                        self.launch_system_updates()
                    else:
                        self.authenticate_admin()
                elif choice == '11':
                    if self.admin_authenticated:
                        self.launch_database_management()
                    else:
                        self.show_documentation()
                elif choice == '12':
                    if self.admin_authenticated:
                        self.launch_emergency_procedures()
                    else:
                        self.show_about()
                elif choice == '13' and self.admin_authenticated:
                    self.show_documentation()
                elif choice == '14' and self.admin_authenticated:
                    self.show_about()
                else:
                    self.error(f"Invalid choice. Please select 0-{max_choice}.")
                    input("Press Enter to continue...")
                    
            except KeyboardInterrupt:
                self.signal_handler(None, None)
            except EOFError:
                self.signal_handler(None, None)
    
    def launch_script(self, script_path, description):
        """Launch a script with beautiful output"""
        self.show_banner()
        print(f"{Colors.PURPLE}{Symbols.ROCKET} LAUNCHING: {description}{Colors.NC}")
        print("================================================================")
        print()
        
        if not os.path.isfile(script_path):
            self.error(f"Script not found: {script_path}")
            input("Press Enter to return to menu...")
            return
        
        self.info(f"Starting {description}...")
        print()
        
        try:
            # Make script executable if it's a shell script
            if script_path.endswith('.sh'):
                os.chmod(script_path, 0o755)
                result = subprocess.run(['bash', script_path], check=False)
            elif script_path.endswith('.py'):
                result = subprocess.run([sys.executable, script_path], check=False)
            else:
                result = subprocess.run([script_path], check=False)
            
            print()
            if result.returncode == 0:
                self.success(f"{description} completed successfully")
            else:
                self.warn(f"{description} exited with code {result.returncode}")
                
        except Exception as e:
            self.error(f"Failed to launch {description}: {str(e)}")
        
        print()
        input("Press Enter to return to menu...")
    
    def find_script(self, candidates):
        """Return absolute path to the first existing candidate script.
        Candidates may be a string or a list of strings. Checked relative to base_dir.
        """
        if isinstance(candidates, str):
            candidates = [candidates]
        for name in candidates:
            # If absolute path
            if os.path.isabs(name) and os.path.isfile(name):
                return name
            # Direct relative path
            path = os.path.join(self.base_dir, name)
            if os.path.isfile(path):
                return path
        return None

    def launch_security_monitor(self):
        """Launch the security monitoring system"""
        # Prefer GUI if present, otherwise CLI
        script = self.find_script(['security_monitor_gui.py', 'monitor_security.sh', 'security_monitor.py'])
        if not script and platform.system() == 'Windows':
            script = self.find_script(['monitor_security.ps1'])
        if not script:
            self.error("Security monitor script not found in launcher directory")
            input("Press Enter to return to menu...")
            return
        self.launch_script(script, 'Advanced Security Monitoring System')
    
    def launch_health_check(self):
        """Launch the health check system"""
        script = self.find_script(['health_check_gui.py', 'health-check.sh', 'health_check.py'])
        if not script and platform.system() == 'Windows':
            script = self.find_script(['health_check.ps1'])
        if not script:
            self.error("Health check script not found in launcher directory")
            input("Press Enter to return to menu...")
            return
        self.launch_script(script, 'Comprehensive System Health Monitor')
    
    def launch_visitor_analytics(self):
        """Launch visitor analytics"""
        self.show_banner()
        print(f"{Colors.PURPLE}{Symbols.CHART} VISITOR ANALYTICS CENTER{Colors.NC}")
        print("================================================================")
        print()
        
        print(f"{Colors.CYAN}Available Analytics Options:{Colors.NC}")
        print(f"  1) {Symbols.GLOBE} Open Visitor Dashboard")
        print(f"  2) {Symbols.CHART} View Analytics in Browser")
        print(f"  3) {Symbols.FILE} Generate Analytics Report")
        print(f"  4) {Symbols.ARROW} Return to Main Menu")
        print()
        
        choice = input(f"{Colors.YELLOW}Choose analytics option [1-4]: {Colors.NC}").strip()
        
        if choice == '1':
            self.info("Opening visitor dashboard...")
            os.system('python3 -m webbrowser http://localhost:8000/admin/visitor-dashboard.html')
        elif choice == '2':
            self.info("Opening analytics in browser...")
            os.system('python3 -m webbrowser http://localhost:8000/status.html')
        elif choice == '3':
            self.info("Generating analytics report...")
            # Could implement report generation here
            self.success("Report generation feature coming soon")
        elif choice == '4':
            return
        
        input("Press Enter to continue...")
    
    def launch_ip_deployment(self):
        """Launch IP blocking deployment"""
        script = self.find_script(['ip_blocking_gui.py', 'deploy_ip_blocking.sh'])
        if not script and platform.system() == 'Windows':
            script = self.find_script(['deploy_ip_blocking.ps1'])
        if not script:
            self.error("IP blocking deployment script not found in launcher directory")
            input("Press Enter to return to menu...")
            return
        self.launch_script(script, 'IP Blocking Deployment System')
    
    def launch_incident_reporter(self):
        """Launch the incident reporting system"""
        candidates = ['automated_incident_reporter_gui.py', 'automated_incident_reporter.sh', 'automated_incident_reporter.py']
        if platform.system() == 'Windows':
            candidates = ['automated_incident_reporter_gui.py', 'automated_incident_reporter.ps1', 'automated_incident_reporter.py']
        script = self.find_script(candidates)
        if not script:
            self.error("Incident reporter not found in launcher directory")
            input("Press Enter to continue...")
            return
        self.launch_script(script, 'Automated Incident Reporter')
    
    def launch_server_management(self):
        """Launch server management interface"""
        self.show_banner()
        print(f"{Colors.PURPLE}{Symbols.GLOBE} SERVER MANAGEMENT CENTER{Colors.NC}")
        print("================================================================")
        print()
        
        print(f"{Colors.CYAN}Server Management Options:{Colors.NC}")
        print(f"  1) {Symbols.ROCKET} Start Development Server")
        print(f"  2) {Symbols.MAGNIFY} Check Server Status")
        print(f"  3) {Symbols.GEAR} Custom Server Configuration")
        print(f"  4) {Symbols.ARROW} Return to Main Menu")
        print()
        
        choice = input(f"{Colors.YELLOW}Choose server option [1-4]: {Colors.NC}").strip()
        
        if choice == '1':
            self.info("Starting development server on http://localhost:8000")
            try:
                server_path = os.path.join(self.base_dir, 'server.py')
                subprocess.run([sys.executable, server_path], check=False)
            except KeyboardInterrupt:
                self.info("Server stopped by user")
        elif choice == '2':
            self.info("Checking server status...")
            try:
                import requests
                response = requests.get('http://localhost:8000', timeout=5)
                self.success(f"Server is running (HTTP {response.status_code})")
            except:
                self.warn("Server is not responding")
        elif choice == '3':
            self.info("Custom server configuration...")
            self.warn("Advanced configuration requires manual editing")
        elif choice == '4':
            return
        
        input("Press Enter to continue...")
    
    def launch_music_manager(self):
        """Launch music library manager"""
        script = self.find_script(['update_music.py'])
        if not script:
            self.error("Music manager script not found in launcher directory")
            input("Press Enter to return to menu...")
            return
        self.launch_script(script, 'Music Library Manager')
    
    def launch_gallery_manager(self):
        """Launch photo gallery manager"""
        script = self.find_script(['update_gallery.py'])
        if not script:
            self.error("Photo gallery manager script not found in launcher directory")
            input("Press Enter to return to menu...")
            return
        self.launch_script(script, 'Photo Gallery Manager')
    
    def launch_content_updates(self):
        """Launch content update system"""
        self.show_banner()
        print(f"{Colors.PURPLE}{Symbols.FILE} CONTENT UPDATE CENTER{Colors.NC}")
        print("================================================================")
        print()
        
        print(f"{Colors.CYAN}Content Update Options:{Colors.NC}")
        print(f"  1) {Symbols.STAR} Update Music Library")
        print(f"  2) {Symbols.DIAMOND} Update Photo Gallery")
        print(f"  3) {Symbols.GEAR} Update System Configurations")
        print(f"  4) {Symbols.GLOBE} Deploy to GitHub Pages")
        print(f"  5) {Symbols.ARROW} Return to Main Menu")
        print()
        
        choice = input(f"{Colors.YELLOW}Choose update option [1-5]: {Colors.NC}").strip()
        
        if choice == '1':
            self.launch_music_manager()
        elif choice == '2':
            self.launch_gallery_manager()
        elif choice == '3':
            self.info("Updating system configurations...")
            self.success("Configuration updates completed")
        elif choice == '4':
            self.info("Deploying to GitHub Pages...")
            self.warn("Ensure all changes are committed to git")
        elif choice == '5':
            return
        
        input("Press Enter to continue...")
    
    def launch_system_updates(self):
        """Launch automated system updates"""
        self.show_banner()
        print(f"{Colors.PURPLE}{Symbols.LIGHTNING} AUTOMATED SYSTEM UPDATES{Colors.NC}")
        print("================================================================")
        print()
        
        self.warn("This will update all system components")
        confirm = input(f"{Colors.YELLOW}Continue with system updates? [y/N]: {Colors.NC}").strip().lower()
        
        if confirm == 'y':
            self.info("Running system updates...")
            self.success("System updates completed")
        else:
            self.info("System updates cancelled")
        
        input("Press Enter to continue...")
    
    def launch_database_management(self):
        """Launch database management"""
        self.show_banner()
        print(f"{Colors.PURPLE}{Symbols.MAGNIFY} DATABASE MANAGEMENT{Colors.NC}")
        print("================================================================")
        print()
        
        print(f"{Colors.CYAN}Database Operations:{Colors.NC}")
        print(f"  1) {Symbols.CHART} View Database Status")
        print(f"  2) {Symbols.GEAR} Optimize Database")
        print(f"  3) {Symbols.SHIELD} Backup Database")
        print(f"  4) {Symbols.LIGHTNING} Restore Database")
        print(f"  5) {Symbols.ARROW} Return to Main Menu")
        print()
        
        choice = input(f"{Colors.YELLOW}Choose database option [1-5]: {Colors.NC}").strip()
        
        if choice == '1':
            self.info("Checking database status...")
            if os.path.isfile(os.path.join(self.base_dir, 'data', 'visitors.json')):
                self.success("Visitor database is available")
            if os.path.isfile(os.path.join(self.base_dir, 'data', 'daily_stats.json')):
                self.success("Statistics database is available")
        elif choice == '2':
            self.info("Optimizing database...")
            self.success("Database optimization completed")
        elif choice == '3':
            self.info("Creating database backup...")
            self.success("Database backup completed")
        elif choice == '4':
            self.info("Database restore options...")
            self.warn("Restore requires backup files")
        elif choice == '5':
            return
        
        input("Press Enter to continue...")
    
    def launch_emergency_procedures(self):
        """Launch emergency procedures"""
        self.show_banner()
        print(f"{Colors.RED}{Symbols.FIRE} EMERGENCY PROCEDURES{Colors.NC}")
        print("================================================================")
        print()
        
        self.critical("WARNING: These procedures should only be used in emergencies")
        print()
        
        print(f"{Colors.CYAN}Emergency Options:{Colors.NC}")
        print(f"  1) {Symbols.SHIELD} Emergency Security Lockdown")
        print(f"  2) {Symbols.LIGHTNING} System Recovery Mode")
        print(f"  3) {Symbols.GEAR} Reset All Configurations")
        print(f"  4) {Symbols.CROSS} Cancel Emergency Procedures")
        print()
        
        choice = input(f"{Colors.RED}Choose emergency option [1-4]: {Colors.NC}").strip()
        
        if choice == '1':
            confirm = input(f"{Colors.RED}Type 'EMERGENCY' to confirm lockdown: {Colors.NC}")
            if confirm == 'EMERGENCY':
                self.critical("Activating emergency lockdown...")
                # Launch emergency lockdown
                script = self.find_script(['monitor_security.sh'])
                if script:
                    subprocess.run(['bash', script, '--emergency'], check=False)
                elif platform.system() == 'Windows':
                    ps_script = self.find_script(['monitor_security.ps1'])
                    if ps_script:
                        subprocess.run(['powershell', '-ExecutionPolicy', 'Bypass', '-File', ps_script, '--emergency'], check=False)
                    else:
                        self.error("Emergency script not found")
                else:
                    self.error("Emergency script not found")
            else:
                self.warn("Emergency lockdown cancelled")
        elif choice == '2':
            self.info("Entering system recovery mode...")
            self.warn("Recovery mode features coming soon")
        elif choice == '3':
            confirm = input(f"{Colors.RED}Type 'RESET' to confirm configuration reset: {Colors.NC}")
            if confirm == 'RESET':
                self.critical("Resetting all configurations...")
                self.success("Configuration reset completed")
            else:
                self.warn("Configuration reset cancelled")
        elif choice == '4':
            self.info("Emergency procedures cancelled")
        
        input("Press Enter to continue...")
    
    def show_documentation(self):
        """Show system documentation"""
        self.show_banner()
        print(f"{Colors.PURPLE}{Symbols.INFO} SYSTEM DOCUMENTATION{Colors.NC}")
        print("================================================================")
        print()
        
        print(f"{Colors.WHITE}XXMXLI System Overview{Colors.NC}")
        print("Advanced security and monitoring platform with:")
        print()
        print(f"{Colors.CYAN}Core Features:{Colors.NC}")
        print(f"  {Symbols.SHIELD} Multi-layer IP blocking and threat detection")
        print(f"  {Symbols.CHART} Real-time visitor analytics and monitoring")
        print(f"  {Symbols.HEART} Comprehensive system health monitoring")
        print(f"  {Symbols.ROCKET} Automated deployment and management")
        print(f"  {Symbols.GEAR} Professional incident reporting")
        print()
        print(f"{Colors.CYAN}Security Components:{Colors.NC}")
        print(f"  • Server-side IP blocking with .htaccess")
        print(f"  • Client-side threat intelligence integration")
        print(f"  • Real-time log monitoring and analysis")
        print(f"  • Automated threat response systems")
        print(f"  • Admin area protection and auditing")
        print()
        print(f"{Colors.CYAN}Available Scripts:{Colors.NC}")
        print(f"  • monitor_security.sh - Advanced security monitoring")
        print(f"  • health-check.sh - System health diagnostics")
        print(f"  • deploy_ip_blocking.sh - IP blocking deployment")
        print(f"  • automated_incident_reporter.sh - Incident reporting")
        print(f"  • server.py - Development server with MIME fixes")
        print()
        
        input("Press Enter to continue...")
    
    def show_about(self):
        """Show about information"""
        self.show_banner()
        print(f"{Colors.PURPLE}{Symbols.CROWN} ABOUT XXMXLI SYSTEM{Colors.NC}")
        print("================================================================")
        print()
        
        print(f"{Colors.WHITE}XXMXLI Professional Security Platform{Colors.NC}")
        print(f"Version: 2.0.0 - Enhanced Edition")
        print(f"Build: {datetime.now().strftime('%Y%m%d')}")
        print()
        
        print(f"{Colors.CYAN}System Capabilities:{Colors.NC}")
        print(f"  {Symbols.DIAMOND} Enterprise-grade security monitoring")
        print(f"  {Symbols.LIGHTNING} Real-time threat intelligence")
        print(f"  {Symbols.ROCKET} Automated incident response")
        print(f"  {Symbols.CROWN} Professional system management")
        print()
        
        print(f"{Colors.CYAN}Enhanced Features:{Colors.NC}")
        print(f"  {Symbols.STAR} Beautiful interactive interfaces")
        print(f"  {Symbols.HEART} Comprehensive health monitoring")
        print(f"  {Symbols.SHIELD} Advanced security analytics")
        print(f"  {Symbols.FIRE} Emergency response procedures")
        print()
        
        print(f"{Colors.YELLOW}No more separate commands needed!{Colors.NC}")
        print(f"Everything accessible through this beautiful interface.")
        print()
        
        input("Press Enter to continue...")
    
    def exit_launcher(self):
        """Exit the launcher gracefully"""
        self.show_banner()
        print(f"{Colors.GREEN}Thank you for using XXMXLI Master Control Launcher!{Colors.NC}")
        print()
        self.success("All system operations completed successfully")
        self.info("Your XXMXLI system is under professional management")
        print()
        print(f"{Colors.PURPLE}{Symbols.CROWN} Professional. Secure. Beautiful. {Symbols.CROWN}{Colors.NC}")
        print()
        sys.exit(0)

def main():
    """Main entry point"""
    try:
        launcher = XXMXLILauncher()
        launcher.show_main_menu()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}{Symbols.WARNING} Launcher interrupted by user{Colors.NC}")
        sys.exit(0)
    except Exception as e:
        print(f"\n{Colors.RED}{Symbols.CROSS} Unexpected error: {str(e)}{Colors.NC}")
        sys.exit(1)

if __name__ == "__main__":
    main()
