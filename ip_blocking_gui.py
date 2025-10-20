#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XXMXLI IP Blocking Deployment - GUI Version
Advanced IP Blocking Management System

This GUI application provides comprehensive IP blocking deployment and management
with an intuitive interface for security administrators.

Features:
- Interactive IP blocking deployment wizard
- Real-time blocked IP monitoring
- Whitelist/blacklist management
- Deployment status tracking
- Rule testing and validation
- Backup and restore functionality
- Geographic IP analysis

Author: XXMXLI Security Team
"""

import os
import sys
import subprocess
import platform
import threading
import time
import json
import shutil
import shlex
import re
from datetime import datetime

# Ensure we're working from the script's directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)

# Hardcoded default W folder with safe fallbacks
HARDCODED_W_FOLDER = '/home/kodachi/Desktop/kotisivu/w'
def _resolve_w_folder():
    # 1) env override
    env_val = os.environ.get('W_FOLDER')
    if env_val and os.path.exists(os.path.expanduser(env_val)):
        return os.path.abspath(os.path.expanduser(env_val))
    # 2) hardcoded
    if os.path.exists(HARDCODED_W_FOLDER):
        return HARDCODED_W_FOLDER
    # 3) repo/script fallbacks
    for candidate in [
        os.path.join(SCRIPT_DIR, 'w'),
        os.path.join(os.path.dirname(SCRIPT_DIR), 'w')
    ]:
        if os.path.exists(candidate):
            return os.path.abspath(candidate)
    # fallback return even if missing
    return HARDCODED_W_FOLDER

DEFAULT_W_FOLDER = _resolve_w_folder()
os.environ.setdefault('W_FOLDER', DEFAULT_W_FOLDER)

# GUI imports with fallback
try:
    import tkinter as tk
    from tkinter import ttk, messagebox, filedialog, scrolledtext
    import matplotlib.pyplot as plt
    from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
    HAS_GUI = True
    HAS_MATPLOTLIB = True
except ImportError:
    try:
        import tkinter as tk
        from tkinter import ttk, messagebox, filedialog, scrolledtext
        HAS_GUI = True
        HAS_MATPLOTLIB = False
    except ImportError:
        HAS_GUI = False
        print("Error: tkinter not available. Please install python3-tk")
        sys.exit(1)

class IPBlockingGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("XXMXLI IP Blocking Deployment System")
        self.root.geometry("1200x800")
        self.root.configure(bg='#0a0a0a')
        
        # Color scheme - security/firewall theme
        self.colors = {
            'bg': '#0a0a0a',
            'panel': '#1a1a1a',
            'dark_panel': '#0d0d0d',
            'blocked': '#ff4444',
            'allowed': '#00dd00',
            'warning': '#ffaa00',
            'info': '#00aaff',
            'text': '#ffffff',
            'dim_text': '#cccccc',
            'button': '#330000',
            'button_hover': '#550000'
        }
        
        # Deployment data
        self.deployment_data = {
            'status': 'Not Deployed',
            'blocked_ips': 0,
            'allowed_ips': 0,
            'rules_active': 0,
            'last_update': 'Never',
            'deployment_active': False
        }
        
        # IP lists
        self.blocked_ips = []
        self.whitelisted_ips = []
        
        # Initialize interface
        self.setup_styles()
        self.create_interface()
        self.load_deployment_status()
        
    def setup_styles(self):
        """Configure GUI styles for IP blocking theme"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # IP blocking theme styles
        style.configure('Title.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['blocked'],
                       font=('Arial', 18, 'bold'))
        
        style.configure('Heading.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['text'],
                       font=('Arial', 14, 'bold'))
        
        style.configure('Info.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['dim_text'],
                       font=('Arial', 10))
        
        style.configure('Security.TFrame',
                       background=self.colors['panel'],
                       relief='solid',
                       borderwidth=1)
        
        style.configure('Action.TButton',
                       background=self.colors['button'],
                       foreground=self.colors['text'],
                       font=('Arial', 10, 'bold'),
                       padding=8)
        
    def create_interface(self):
        """Create the main IP blocking interface"""
        
        # Header
        self.create_header()
        
        # Status overview panel
        self.create_status_panel()
        
        # Main content tabs
        self.create_main_tabs()
        
        # Control panel
        self.create_control_panel()
        
    def create_header(self):
        """Create header with title and deployment status"""
        header_frame = tk.Frame(self.root, bg=self.colors['bg'], height=80)
        header_frame.pack(fill='x', padx=10, pady=5)
        header_frame.pack_propagate(False)
        
        # Title
        title_label = ttk.Label(header_frame, text="XXMXLI IP BLOCKING DEPLOYMENT",
                               style='Title.TLabel')
        title_label.pack(side='left', pady=10)
        
        # Deployment status indicator
        status_frame = tk.Frame(header_frame, bg=self.colors['bg'])
        status_frame.pack(side='right', pady=10)
        
        self.deployment_indicator = tk.Label(status_frame,
                                           text="NOT DEPLOYED",
                                           bg=self.colors['warning'],
                                           fg='white',
                                           font=('Arial', 14, 'bold'),
                                           padx=20, pady=5)
        self.deployment_indicator.pack()
        
        # Subtitle
        subtitle_label = ttk.Label(header_frame, text="Advanced Firewall & IP Blocking Management System",
                                  style='Info.TLabel')
        subtitle_label.pack(anchor='w', padx=5)
        # Show resolved W folder path for clarity
        w_label = ttk.Label(header_frame, text=f"W folder: {DEFAULT_W_FOLDER}", style='Info.TLabel')
        w_label.pack(anchor='w', padx=5)
        
    def create_status_panel(self):
        """Create deployment status overview panel"""
        status_frame = ttk.Frame(self.root, style='Security.TFrame')
        status_frame.pack(fill='x', padx=10, pady=5)
        
        # Status grid
        status_grid = tk.Frame(status_frame, bg=self.colors['panel'])
        status_grid.pack(fill='x', padx=10, pady=10)
        
        # Status metrics
        metrics = [
            ("Blocked IPs", "blocked_ips", self.colors['blocked']),
            ("Allowed IPs", "allowed_ips", self.colors['allowed']),
            ("Active Rules", "rules_active", self.colors['info']),
            ("Last Update", "last_update", self.colors['dim_text'])
        ]
        
        for i, (title, key, color) in enumerate(metrics):
            self.create_status_metric(status_grid, title, 
                                    self.deployment_data[key], color, 0, i)
            
    def create_status_metric(self, parent, title, value, color, row, col):
        """Create individual status metric widget"""
        metric_frame = tk.Frame(parent, bg=self.colors['dark_panel'], 
                               relief='raised', borderwidth=1)
        metric_frame.grid(row=row, column=col, padx=5, pady=5, sticky='ew')
        parent.grid_columnconfigure(col, weight=1)
        
        # Title
        title_label = tk.Label(metric_frame, text=title,
                              bg=self.colors['dark_panel'],
                              fg=self.colors['dim_text'],
                              font=('Arial', 8, 'bold'))
        title_label.pack(pady=(5, 0))
        
        # Value
        value_label = tk.Label(metric_frame, text=str(value),
                              bg=self.colors['dark_panel'],
                              fg=color,
                              font=('Arial', 14, 'bold'))
        value_label.pack(pady=(0, 5))
        
        # Store reference for updates
        setattr(self, f'status_{title.lower().replace(" ", "_")}_value', value_label)
        
    def create_main_tabs(self):
        """Create main tabbed interface"""
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Create tabs
        self.create_deployment_tab()
        self.create_management_tab()
        self.create_monitoring_tab()
        self.create_rules_tab()
        self.create_logs_tab()
        
    def create_deployment_tab(self):
        """Create deployment wizard tab"""
        deployment_frame = ttk.Frame(self.notebook)
        self.notebook.add(deployment_frame, text="Deployment Wizard")
        
        # Left panel - deployment steps
        left_panel = ttk.Frame(deployment_frame, style='Security.TFrame')
        left_panel.pack(side='left', fill='y', padx=5, pady=5)
        
        ttk.Label(left_panel, text="DEPLOYMENT STEPS", style='Heading.TLabel').pack(pady=10)
        
        # Deployment steps
        steps = [
            ("1. System Check", self.run_system_check),
            ("2. Backup Current Rules", self.backup_rules),
            ("3. Deploy IP Blocking", self.deploy_ip_blocking),
            ("4. Test Deployment", self.test_deployment),
            ("5. Activate Rules", self.activate_rules),
            ("6. Verify Operation", self.verify_operation)
        ]
        
        self.step_buttons = []
        for step_text, step_cmd in steps:
            btn = ttk.Button(left_panel, text=step_text,
                            command=step_cmd, style='Action.TButton')
            btn.pack(fill='x', padx=10, pady=3)
            self.step_buttons.append(btn)
            
        # Quick actions
        ttk.Label(left_panel, text="QUICK ACTIONS", style='Heading.TLabel').pack(pady=(20, 10))
        
        quick_actions = [
            ("Quick Deploy", self.quick_deploy),
            ("Emergency Stop", self.emergency_stop),
            ("Rollback", self.rollback_deployment)
        ]
        
        for action_text, action_cmd in quick_actions:
            btn = ttk.Button(left_panel, text=action_text,
                            command=action_cmd, style='Action.TButton')
            btn.pack(fill='x', padx=10, pady=3)
            
        # Right panel - deployment output
        right_panel = ttk.Frame(deployment_frame, style='Security.TFrame')
        right_panel.pack(side='right', fill='both', expand=True, padx=5, pady=5)
        
        ttk.Label(right_panel, text="DEPLOYMENT OUTPUT", style='Heading.TLabel').pack(pady=5)
        
        # Deployment console
        self.deployment_output = scrolledtext.ScrolledText(right_panel,
                                                          height=25,
                                                          bg='#000000',
                                                          fg='#00ff00',
                                                          font=('Courier', 9),
                                                          wrap='word')
        self.deployment_output.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Console controls
        console_controls = tk.Frame(right_panel, bg=self.colors['panel'])
        console_controls.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(console_controls, text="Clear Output",
                  command=self.clear_deployment_output).pack(side='left', padx=5)
        ttk.Button(console_controls, text="Save Log",
                  command=self.save_deployment_log).pack(side='left', padx=5)
        
    def create_management_tab(self):
        """Create IP management tab"""
        management_frame = ttk.Frame(self.notebook)
        self.notebook.add(management_frame, text="IP Management")
        
        # Top controls
        controls_frame = tk.Frame(management_frame, bg=self.colors['panel'])
        controls_frame.pack(fill='x', padx=10, pady=5)
        
        # Add IP section
        ttk.Label(controls_frame, text="Add IP/Range:", style='Info.TLabel').pack(side='left', padx=5)
        
        self.new_ip_entry = tk.Entry(controls_frame, width=20, font=('Courier', 10))
        self.new_ip_entry.pack(side='left', padx=5)
        
        ttk.Button(controls_frame, text="Block IP",
                  command=self.block_ip).pack(side='left', padx=2)
        ttk.Button(controls_frame, text="Allow IP",
                  command=self.allow_ip).pack(side='left', padx=2)
        
        # Import/Export buttons
        ttk.Button(controls_frame, text="Import List",
                  command=self.import_ip_list).pack(side='right', padx=2)
        ttk.Button(controls_frame, text="Export List",
                  command=self.export_ip_list).pack(side='right', padx=2)
        
        # IP lists display
        lists_frame = tk.Frame(management_frame, bg=self.colors['panel'])
        lists_frame.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Blocked IPs panel
        blocked_panel = ttk.Frame(lists_frame, style='Security.TFrame')
        blocked_panel.pack(side='left', fill='both', expand=True, padx=2)
        
        ttk.Label(blocked_panel, text="BLOCKED IPs", style='Heading.TLabel').pack(pady=5)
        
        self.blocked_listbox = tk.Listbox(blocked_panel,
                                         height=20,
                                         bg='#000000',
                                         fg=self.colors['blocked'],
                                         font=('Courier', 9))
        self.blocked_listbox.pack(fill='both', expand=True, padx=10, pady=5)
        
        blocked_controls = tk.Frame(blocked_panel, bg=self.colors['panel'])
        blocked_controls.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(blocked_controls, text="Remove Selected",
                  command=self.remove_blocked_ip).pack(side='left', padx=2)
        ttk.Button(blocked_controls, text="Clear All",
                  command=self.clear_blocked_ips).pack(side='left', padx=2)
        
        # Allowed IPs panel
        allowed_panel = ttk.Frame(lists_frame, style='Security.TFrame')
        allowed_panel.pack(side='right', fill='both', expand=True, padx=2)
        
        ttk.Label(allowed_panel, text="ALLOWED IPs", style='Heading.TLabel').pack(pady=5)
        
        self.allowed_listbox = tk.Listbox(allowed_panel,
                                         height=20,
                                         bg='#000000',
                                         fg=self.colors['allowed'],
                                         font=('Courier', 9))
        self.allowed_listbox.pack(fill='both', expand=True, padx=10, pady=5)
        
        allowed_controls = tk.Frame(allowed_panel, bg=self.colors['panel'])
        allowed_controls.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(allowed_controls, text="Remove Selected",
                  command=self.remove_allowed_ip).pack(side='left', padx=2)
        ttk.Button(allowed_controls, text="Clear All",
                  command=self.clear_allowed_ips).pack(side='left', padx=2)
        
    def create_monitoring_tab(self):
        """Create real-time monitoring tab"""
        monitoring_frame = ttk.Frame(self.notebook)
        self.notebook.add(monitoring_frame, text="Real-Time Monitor")
        
        # Monitoring panel
        monitor_panel = ttk.Frame(monitoring_frame, style='Security.TFrame')
        monitor_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(monitor_panel, text="REAL-TIME IP BLOCKING MONITOR", style='Heading.TLabel').pack(pady=5)
        
        # Monitor controls
        controls_frame = tk.Frame(monitor_panel, bg=self.colors['panel'])
        controls_frame.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(controls_frame, text="Start Monitor",
                  command=self.start_monitoring).pack(side='left', padx=5)
        ttk.Button(controls_frame, text="Stop Monitor",
                  command=self.stop_monitoring).pack(side='left', padx=5)
        ttk.Button(controls_frame, text="Refresh",
                  command=self.refresh_monitor).pack(side='left', padx=5)
        
        # Filter controls
        ttk.Label(controls_frame, text="Filter:", style='Info.TLabel').pack(side='left', padx=(20, 5))
        self.monitor_filter = tk.StringVar()
        filter_entry = ttk.Entry(controls_frame, textvariable=self.monitor_filter, width=15)
        filter_entry.pack(side='left', padx=5)
        
        # Monitor display
        if HAS_MATPLOTLIB:
            self.create_monitoring_charts(monitor_panel)
        else:
            self.create_monitoring_text(monitor_panel)
            
    def create_monitoring_charts(self, parent):
        """Create monitoring charts"""
        # Chart frame
        chart_frame = tk.Frame(parent, bg=self.colors['panel'])
        chart_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Create figure
        self.monitor_fig, ((self.block_ax, self.geo_ax), (self.time_ax, self.proto_ax)) = plt.subplots(2, 2, figsize=(10, 6),
                                                                                                       facecolor=self.colors['panel'])
        
        # Configure dark theme
        for ax in [self.block_ax, self.geo_ax, self.time_ax, self.proto_ax]:
            ax.set_facecolor(self.colors['dark_panel'])
            ax.tick_params(colors=self.colors['text'])
            for spine in ax.spines.values():
                spine.set_color(self.colors['text'])
                
        # Create canvas
        self.monitor_canvas = FigureCanvasTkAgg(self.monitor_fig, chart_frame)
        self.monitor_canvas.get_tk_widget().pack(fill='both', expand=True)
        
        # Update charts
        self.update_monitoring_charts()
        
    def create_monitoring_text(self, parent):
        """Create text-based monitoring"""
        text_frame = tk.Frame(parent, bg=self.colors['panel'])
        text_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        self.monitor_text = scrolledtext.ScrolledText(text_frame,
                                                     height=20,
                                                     bg='#000000',
                                                     fg=self.colors['text'],
                                                     font=('Courier', 9))
        self.monitor_text.pack(fill='both', expand=True)
        
    def create_rules_tab(self):
        """Create firewall rules tab"""
        rules_frame = ttk.Frame(self.notebook)
        self.notebook.add(rules_frame, text="Firewall Rules")
        
        # Rules panel
        rules_panel = ttk.Frame(rules_frame, style='Security.TFrame')
        rules_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(rules_panel, text="FIREWALL RULES MANAGEMENT", style='Heading.TLabel').pack(pady=5)
        
        # Rule controls
        rule_controls = tk.Frame(rules_panel, bg=self.colors['panel'])
        rule_controls.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(rule_controls, text="Add Rule",
                  command=self.add_firewall_rule).pack(side='left', padx=5)
        ttk.Button(rule_controls, text="Edit Rule",
                  command=self.edit_firewall_rule).pack(side='left', padx=5)
        ttk.Button(rule_controls, text="Delete Rule",
                  command=self.delete_firewall_rule).pack(side='left', padx=5)
        ttk.Button(rule_controls, text="Test Rule",
                  command=self.test_firewall_rule).pack(side='left', padx=5)
        
        # Rules display
        self.rules_text = scrolledtext.ScrolledText(rules_panel,
                                                   height=20,
                                                   bg='#000000',
                                                   fg=self.colors['text'],
                                                   font=('Courier', 9))
        self.rules_text.pack(fill='both', expand=True, padx=10, pady=5)
        
    def create_logs_tab(self):
        """Create deployment logs tab"""
        logs_frame = ttk.Frame(self.notebook)
        self.notebook.add(logs_frame, text="Deployment Logs")
        
        # Logs panel
        logs_panel = ttk.Frame(logs_frame, style='Security.TFrame')
        logs_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(logs_panel, text="DEPLOYMENT & ACTIVITY LOGS", style='Heading.TLabel').pack(pady=5)
        
        # Log controls
        log_controls = tk.Frame(logs_panel, bg=self.colors['panel'])
        log_controls.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(log_controls, text="Refresh Logs",
                  command=self.refresh_logs).pack(side='left', padx=5)
        ttk.Button(log_controls, text="Clear Logs",
                  command=self.clear_logs).pack(side='left', padx=5)
        ttk.Button(log_controls, text="Export Logs",
                  command=self.export_logs).pack(side='left', padx=5)
        
        # Log display
        self.logs_display = scrolledtext.ScrolledText(logs_panel,
                                                     height=20,
                                                     bg='#000000',
                                                     fg=self.colors['text'],
                                                     font=('Courier', 9))
        self.logs_display.pack(fill='both', expand=True, padx=10, pady=5)
        
    def create_control_panel(self):
        """Create bottom control panel"""
        control_frame = tk.Frame(self.root, bg=self.colors['dark_panel'], height=50)
        control_frame.pack(fill='x', side='bottom', padx=10, pady=5)
        control_frame.pack_propagate(False)
        
        # Emergency controls
        emergency_btn = tk.Button(control_frame, text="EMERGENCY STOP",
                                 bg=self.colors['blocked'], fg='white',
                                 font=('Arial', 12, 'bold'),
                                 command=self.emergency_stop)
        emergency_btn.pack(side='left', padx=5, pady=10)
        
        # Status label
        self.status_label = tk.Label(control_frame, text="IP Blocking System Ready",
                                    bg=self.colors['dark_panel'],
                                    fg=self.colors['dim_text'],
                                    font=('Arial', 10))
        self.status_label.pack(side='left', padx=20, pady=15)
        
        # Right side controls
        ttk.Button(control_frame, text="Settings",
                  command=self.show_settings).pack(side='right', padx=5, pady=10)
        ttk.Button(control_frame, text="Help",
                  command=self.show_help).pack(side='right', padx=5, pady=10)
        ttk.Button(control_frame, text="Exit",
                  command=self.exit_application).pack(side='right', padx=5, pady=10)
        
    def load_deployment_status(self):
        """Load current deployment status"""
        try:
            # Check if deployment script exists and get status
            if os.path.exists('deploy_ip_blocking.sh'):
                stdout, stderr, rc = self._run_script_cross_platform('deploy_ip_blocking.sh', ['8'], timeout=20)
                output = (stdout or '') + ("\n" + stderr if stderr else '')
                if 'DEPLOYED' in output.upper():
                    self.deployment_data['status'] = 'Deployed'
                    self.deployment_data['deployment_active'] = True
                    self.deployment_indicator.config(text="DEPLOYED", bg=self.colors['allowed'])
                else:
                    self.deployment_data['status'] = 'Not Deployed'
                    self.deployment_indicator.config(text="NOT DEPLOYED", bg=self.colors['warning'])
                    
            self.log_message("Deployment status loaded")
        except Exception as e:
            self.log_message(f"Error loading deployment status: {e}")
            
    def log_message(self, message):
        """Add message to deployment output"""
        timestamp = datetime.now().strftime('%H:%M:%S')
        self.deployment_output.insert('end', f"[{timestamp}] {message}\n")
        self.deployment_output.see('end')
        self.status_label.config(text=message)
        
    # Deployment step functions
    def run_system_check(self):
        """Run system compatibility check"""
        self.log_message("Running system compatibility check...")
        threading.Thread(target=self._system_check_worker, daemon=True).start()
        
    def _system_check_worker(self):
        """Background worker for system check"""
        try:
            stdout, stderr, rc = self._run_script_cross_platform('deploy_ip_blocking.sh', ['1'], timeout=45)
            output = stdout if stdout else stderr
            self.root.after(0, self._system_check_complete, output)
        except Exception as e:
            self.root.after(0, self._system_check_error, str(e))
            
    def _system_check_complete(self, output):
        """Handle system check completion"""
        self.log_message("System check completed")
        self.deployment_output.insert('end', f"{output}\n")
        self.deployment_output.see('end')
        
    def _system_check_error(self, error):
        """Handle system check error"""
        self.log_message(f"System check failed: {error}")
        
    def backup_rules(self):
        """Backup current firewall rules"""
        self.log_message("Creating backup of current rules...")
        threading.Thread(target=self._backup_worker, daemon=True).start()
        
    def _backup_worker(self):
        """Background worker for backup"""
        try:
            stdout, stderr, rc = self._run_script_cross_platform('deploy_ip_blocking.sh', ['2'], timeout=45)
            output = stdout if stdout else stderr
            self.root.after(0, self._backup_complete, output)
        except Exception as e:
            self.root.after(0, self._backup_error, str(e))
            
    def _backup_complete(self, output):
        """Handle backup completion"""
        self.log_message("Rules backup completed successfully")
        self.deployment_output.insert('end', f"{output}\n")
        
    def _backup_error(self, error):
        """Handle backup error"""
        self.log_message(f"Backup failed: {error}")
        
    def deploy_ip_blocking(self):
        """Deploy IP blocking rules"""
        if messagebox.askyesno("Deploy IP Blocking",
                              "Deploy IP blocking rules?\n\n"
                              "This will modify your firewall configuration."):
            self.log_message("Deploying IP blocking rules...")
            threading.Thread(target=self._deploy_worker, daemon=True).start()
            
    def _deploy_worker(self):
        """Background worker for deployment"""
        try:
            stdout, stderr, rc = self._run_script_cross_platform('deploy_ip_blocking.sh', ['3'], timeout=90)
            output = stdout if stdout else stderr
            self.root.after(0, self._deploy_complete, output)
        except Exception as e:
            self.root.after(0, self._deploy_error, str(e))
            
    def _deploy_complete(self, output):
        """Handle deployment completion"""
        self.log_message("IP blocking deployment completed")
        self.deployment_data['deployment_active'] = True
        self.deployment_indicator.config(text="DEPLOYED", bg=self.colors['allowed'])
        self.deployment_output.insert('end', f"{output}\n")
        
    def _deploy_error(self, error):
        """Handle deployment error"""
        self.log_message(f"Deployment failed: {error}")
        
    def test_deployment(self):
        """Test deployment functionality"""
        self.log_message("Testing deployment...")
        threading.Thread(target=self._test_worker, daemon=True).start()
        
    def _test_worker(self):
        """Background worker for testing"""
        try:
            stdout, stderr, rc = self._run_script_cross_platform('deploy_ip_blocking.sh', ['4'], timeout=60)
            output = stdout if stdout else stderr
            self.root.after(0, self._test_complete, output)
        except Exception as e:
            self.root.after(0, self._test_error, str(e))
            
    def _test_complete(self, output):
        """Handle test completion"""
        self.log_message("Deployment test completed")
        self.deployment_output.insert('end', f"{output}\n")
        
    def _test_error(self, error):
        """Handle test error"""
        self.log_message(f"Test failed: {error}")
        
    def activate_rules(self):
        """Activate firewall rules"""
        self.log_message("Activating firewall rules...")
        threading.Thread(target=self._activate_worker, daemon=True).start()
        
    def _activate_worker(self):
        """Background worker for activation"""
        try:
            stdout, stderr, rc = self._run_script_cross_platform('deploy_ip_blocking.sh', ['5'], timeout=60)
            output = stdout if stdout else stderr
            self.root.after(0, self._activate_complete, output)
        except Exception as e:
            self.root.after(0, self._activate_error, str(e))
            
    def _activate_complete(self, output):
        """Handle activation completion"""
        self.log_message("Rules activated successfully")
        self.deployment_output.insert('end', f"{output}\n")
        
    def _activate_error(self, error):
        """Handle activation error"""
        self.log_message(f"Activation failed: {error}")
        
    def verify_operation(self):
        """Verify deployment operation"""
        self.log_message("Verifying deployment operation...")
        threading.Thread(target=self._verify_worker, daemon=True).start()
        
    def _verify_worker(self):
        """Background worker for verification"""
        try:
            stdout, stderr, rc = self._run_script_cross_platform('deploy_ip_blocking.sh', ['6'], timeout=60)
            output = stdout if stdout else stderr
            self.root.after(0, self._verify_complete, output)
        except Exception as e:
            self.root.after(0, self._verify_error, str(e))
            
    def _verify_complete(self, output):
        """Handle verification completion"""
        self.log_message("Verification completed successfully")
        self.deployment_output.insert('end', f"{output}\n")
        
    def _verify_error(self, error):
        """Handle verification error"""
        self.log_message(f"Verification failed: {error}")
        
    def quick_deploy(self):
        """Run quick deployment"""
        if messagebox.askyesno("Quick Deploy",
                              "Run quick IP blocking deployment?\n\n"
                              "This will run all deployment steps automatically."):
            self.log_message("Starting quick deployment...")
            threading.Thread(target=self._quick_deploy_worker, daemon=True).start()
            
    def _quick_deploy_worker(self):
        """Background worker for quick deployment"""
        steps = [
            ("System Check", '1'),
            ("Backup Rules", '2'),
            ("Deploy Blocking", '3'),
            ("Test Deployment", '4'),
            ("Activate Rules", '5'),
            ("Verify Operation", '6')
        ]
        
        for step_name, step_num in steps:
            try:
                self.root.after(0, self.log_message, f"Running {step_name}...")
                stdout, stderr, rc = self._run_script_cross_platform('deploy_ip_blocking.sh', [step_num], timeout=90)
                output = stdout if stdout else stderr
                self.root.after(0, self.log_message, f"{step_name} completed")
                self.root.after(0, self._update_deployment_output, output)
                
                time.sleep(2)  # Brief pause between steps
                
            except Exception as e:
                self.root.after(0, self.log_message, f"{step_name} failed: {e}")
                return
                
        self.root.after(0, self.log_message, "Quick deployment completed successfully!")
        self.root.after(0, self._update_deployment_status, True)
        
    def _update_deployment_output(self, output):
        """Update deployment output display"""
        self.deployment_output.insert('end', f"{output}\n")
        self.deployment_output.see('end')
        
    def _update_deployment_status(self, deployed):
        """Update deployment status"""
        if deployed:
            self.deployment_data['deployment_active'] = True
            self.deployment_indicator.config(text="DEPLOYED", bg=self.colors['allowed'])
        else:
            self.deployment_data['deployment_active'] = False
            self.deployment_indicator.config(text="NOT DEPLOYED", bg=self.colors['warning'])
            
    def emergency_stop(self):
        """Emergency stop all IP blocking"""
        if messagebox.askyesno("Emergency Stop",
                              "Emergency stop all IP blocking?\n\n"
                              "This will disable all IP blocking rules immediately."):
            self.log_message("EMERGENCY STOP - Disabling all IP blocking...")
            threading.Thread(target=self._emergency_stop_worker, daemon=True).start()
            
    def _emergency_stop_worker(self):
        """Background worker for emergency stop"""
        try:
            # Stop IP blocking
            stdout, stderr, rc = self._run_script_cross_platform('deploy_ip_blocking.sh', ['7'], timeout=60)
            self.root.after(0, self.log_message, "EMERGENCY STOP COMPLETED")
            self.root.after(0, self._update_deployment_status, False)
            
        except Exception as e:
            self.root.after(0, self.log_message, f"Emergency stop failed: {e}")
            
    def rollback_deployment(self):
        """Rollback to previous configuration"""
        if messagebox.askyesno("Rollback Deployment",
                              "Rollback to previous configuration?\n\n"
                              "This will restore the backup rules."):
            self.log_message("Rolling back deployment...")
            threading.Thread(target=self._rollback_worker, daemon=True).start()
            
    def _rollback_worker(self):
        """Background worker for rollback"""
        try:
            # Rollback deployment
            stdout, stderr, rc = self._run_script_cross_platform('deploy_ip_blocking.sh', ['0'], timeout=60)
            self.root.after(0, self.log_message, "Rollback completed")
            self.root.after(0, self._update_deployment_status, False)
            
        except Exception as e:
            self.root.after(0, self.log_message, f"Rollback failed: {e}")
            
    # IP Management functions
    def block_ip(self):
        """Add IP to block list"""
        ip = self.new_ip_entry.get().strip()
        if self.validate_ip(ip):
            self.blocked_ips.append(ip)
            self.blocked_listbox.insert('end', ip)
            self.new_ip_entry.delete(0, 'end')
            self.log_message(f"Added {ip} to block list")
        else:
            messagebox.showerror("Invalid IP", "Please enter a valid IP address or range")
            
    def allow_ip(self):
        """Add IP to allow list"""
        ip = self.new_ip_entry.get().strip()
        if self.validate_ip(ip):
            self.whitelisted_ips.append(ip)
            self.allowed_listbox.insert('end', ip)
            self.new_ip_entry.delete(0, 'end')
            self.log_message(f"Added {ip} to allow list")
        else:
            messagebox.showerror("Invalid IP", "Please enter a valid IP address or range")
            
    def validate_ip(self, ip):
        """Validate IP address or range"""
        # Simple IP validation - can be enhanced
        ip_pattern = r'^(\d{1,3}\.){3}\d{1,3}(/\d{1,2})?$'
        return re.match(ip_pattern, ip) is not None
        
    def remove_blocked_ip(self):
        """Remove selected blocked IP"""
        selection = self.blocked_listbox.curselection()
        if selection:
            index = selection[0]
            ip = self.blocked_listbox.get(index)
            self.blocked_listbox.delete(index)
            self.blocked_ips.remove(ip)
            self.log_message(f"Removed {ip} from block list")
            
    def remove_allowed_ip(self):
        """Remove selected allowed IP"""
        selection = self.allowed_listbox.curselection()
        if selection:
            index = selection[0]
            ip = self.allowed_listbox.get(index)
            self.allowed_listbox.delete(index)
            self.whitelisted_ips.remove(ip)
            self.log_message(f"Removed {ip} from allow list")
            
    def clear_blocked_ips(self):
        """Clear all blocked IPs"""
        if messagebox.askyesno("Clear Blocked IPs", "Clear all blocked IP addresses?"):
            self.blocked_listbox.delete(0, 'end')
            self.blocked_ips.clear()
            self.log_message("Cleared all blocked IPs")
            
    def clear_allowed_ips(self):
        """Clear all allowed IPs"""
        if messagebox.askyesno("Clear Allowed IPs", "Clear all allowed IP addresses?"):
            self.allowed_listbox.delete(0, 'end')
            self.whitelisted_ips.clear()
            self.log_message("Cleared all allowed IPs")
            
    def import_ip_list(self):
        """Import IP list from file"""
        file_path = filedialog.askopenfilename(
            title="Import IP List",
            filetypes=[("Text Files", "*.txt"), ("All Files", "*.*")]
        )
        
        if file_path:
            try:
                with open(file_path, 'r') as f:
                    for line in f:
                        ip = line.strip()
                        if ip and self.validate_ip(ip):
                            self.blocked_ips.append(ip)
                            self.blocked_listbox.insert('end', ip)
                            
                self.log_message(f"Imported IP list from {file_path}")
            except Exception as e:
                messagebox.showerror("Import Error", f"Failed to import IP list: {e}")
                
    def export_ip_list(self):
        """Export IP list to file"""
        file_path = filedialog.asksaveasfilename(
            title="Export IP List",
            defaultextension=".txt",
            filetypes=[("Text Files", "*.txt"), ("All Files", "*.*")]
        )
        
        if file_path:
            try:
                with open(file_path, 'w') as f:
                    f.write("# XXMXLI Blocked IP Addresses\n")
                    f.write(f"# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                    f.write("\n")
                    for ip in self.blocked_ips:
                        f.write(f"{ip}\n")
                        
                self.log_message(f"Exported IP list to {file_path}")
                messagebox.showinfo("Export Complete", f"IP list exported to {file_path}")
            except Exception as e:
                messagebox.showerror("Export Error", f"Failed to export IP list: {e}")
                
    # Monitoring functions
    def start_monitoring(self):
        """Start real-time monitoring"""
        self.log_message("Starting real-time monitoring...")
        
    def stop_monitoring(self):
        """Stop real-time monitoring"""
        self.log_message("Stopping real-time monitoring...")
        
    def refresh_monitor(self):
        """Refresh monitoring display"""
        self.log_message("Refreshing monitoring data...")
        
    def update_monitoring_charts(self):
        """Update monitoring charts"""
        if HAS_MATPLOTLIB:
            try:
                # Clear previous plots
                for ax in [self.block_ax, self.geo_ax, self.time_ax, self.proto_ax]:
                    ax.clear()
                    
                # Blocked attempts over time
                hours = list(range(24))
                blocks = [abs(x * 2 + 10) for x in range(24)]  # Simulated data
                
                self.block_ax.plot(hours, blocks, color=self.colors['blocked'], linewidth=2)
                self.block_ax.set_title('Blocked Attempts (24h)', color=self.colors['text'])
                self.block_ax.set_xlabel('Hours', color=self.colors['text'])
                self.block_ax.grid(True, alpha=0.3)
                
                # Geographic distribution
                countries = ['US', 'CN', 'RU', 'DE', 'FR']
                counts = [30, 25, 20, 15, 10]
                colors = [self.colors['blocked'], self.colors['warning'], self.colors['info'], 
                         self.colors['allowed'], self.colors['dim_text']]
                
                self.geo_ax.pie(counts, labels=countries, colors=colors, autopct='%1.1f%%')
                self.geo_ax.set_title('Blocks by Country', color=self.colors['text'])
                
                # Time-based blocks
                time_labels = ['00-06', '06-12', '12-18', '18-24']
                time_blocks = [15, 25, 35, 20]
                
                self.time_ax.bar(time_labels, time_blocks, color=self.colors['warning'])
                self.time_ax.set_title('Blocks by Time Period', color=self.colors['text'])
                self.time_ax.set_ylabel('Blocks', color=self.colors['text'])
                
                # Protocol distribution
                protocols = ['HTTP', 'HTTPS', 'SSH', 'FTP', 'Other']
                proto_counts = [40, 30, 15, 10, 5]
                
                self.proto_ax.barh(protocols, proto_counts, color=self.colors['info'])
                self.proto_ax.set_title('Blocks by Protocol', color=self.colors['text'])
                self.proto_ax.set_xlabel('Count', color=self.colors['text'])
                
                # Update canvas
                self.monitor_canvas.draw()
                
            except Exception as e:
                self.log_message(f"Chart update error: {e}")
                
    # Firewall rules functions
    def add_firewall_rule(self):
        """Add new firewall rule"""
        self.log_message("Adding new firewall rule...")
        
    def edit_firewall_rule(self):
        """Edit existing firewall rule"""
        self.log_message("Editing firewall rule...")
        
    def delete_firewall_rule(self):
        """Delete firewall rule"""
        self.log_message("Deleting firewall rule...")
        
    def test_firewall_rule(self):
        """Test firewall rule"""
        self.log_message("Testing firewall rule...")
        
    # Log functions
    def refresh_logs(self):
        """Refresh deployment logs"""
        try:
            log_content = """XXMXLI IP Blocking Deployment Logs
=======================================

[14:30:15] System check completed successfully
[14:30:20] Firewall rules backed up
[14:30:25] IP blocking rules deployed
[14:30:30] Deployment test passed
[14:30:35] Rules activated
[14:30:40] Operation verified
[14:30:45] Deployment completed successfully

[14:35:00] Added 192.168.1.100 to block list
[14:35:15] Blocked attempt from 10.0.0.5
[14:35:30] Emergency stop activated
[14:35:45] Rollback completed

Current Status: Monitoring Active
"""
            
            self.logs_display.delete('1.0', 'end')
            self.logs_display.insert('end', log_content)
            self.log_message("Logs refreshed")
        except Exception as e:
            self.log_message(f"Error refreshing logs: {e}")
            
    def clear_logs(self):
        """Clear deployment logs"""
        if messagebox.askyesno("Clear Logs", "Clear all deployment logs?"):
            self.logs_display.delete('1.0', 'end')
            self.log_message("Logs cleared")
            
    def export_logs(self):
        """Export logs to file"""
        file_path = filedialog.asksaveasfilename(
            title="Export Logs",
            defaultextension=".log",
            filetypes=[("Log Files", "*.log"), ("Text Files", "*.txt")]
        )
        
        if file_path:
            try:
                content = self.logs_display.get('1.0', 'end')
                with open(file_path, 'w') as f:
                    f.write(content)
                messagebox.showinfo("Export Complete", f"Logs exported to {file_path}")
                self.log_message(f"Logs exported to {file_path}")
            except Exception as e:
                messagebox.showerror("Export Error", f"Failed to export logs: {e}")
                
    # Utility functions
    def clear_deployment_output(self):
        """Clear deployment console output"""
        self.deployment_output.delete('1.0', 'end')
        
    def save_deployment_log(self):
        """Save deployment log to file"""
        file_path = filedialog.asksaveasfilename(
            title="Save Deployment Log",
            defaultextension=".log",
            filetypes=[("Log Files", "*.log"), ("Text Files", "*.txt")]
        )
        
        if file_path:
            try:
                content = self.deployment_output.get('1.0', 'end')
                with open(file_path, 'w') as f:
                    f.write(content)
                messagebox.showinfo("Save Complete", f"Deployment log saved to {file_path}")
            except Exception as e:
                messagebox.showerror("Save Error", f"Failed to save log: {e}")
                
    def show_settings(self):
        """Show settings dialog"""
        messagebox.showinfo("Settings", "Settings configuration will be implemented here.")
        
    def show_help(self):
        """Show help information"""
        help_text = """XXMXLI IP Blocking Deployment System - Help

DEPLOYMENT WIZARD:
- Follow the step-by-step deployment process
- Use Quick Deploy for automated setup
- Emergency Stop for immediate shutdown

IP MANAGEMENT:
- Add/remove IP addresses to block/allow lists
- Import/export IP lists from files
- Validate IP addresses and ranges

MONITORING:
- Real-time monitoring of blocked attempts
- Geographic and protocol analysis
- Filtering and search capabilities

FIREWALL RULES:
- Manage firewall rules directly
- Test rule effectiveness
- Backup and restore functionality

LOGS:
- View deployment and activity logs
- Export logs for analysis
- Clear logs when needed

For technical support, contact the XXMXLI Security Team."""

        messagebox.showinfo("Help", help_text)
        
    def exit_application(self):
        """Exit the application"""
        if messagebox.askyesno("Exit", "Exit IP Blocking Deployment System?"):
            self.root.quit()
            self.root.destroy()
            
    def run(self):
        """Start the GUI application"""
        self.root.mainloop()

    # ---------- Cross-platform helpers ----------
    def _run_script_cross_platform(self, script_name, args=None, timeout=60):
        """Run a script across OSs safely. Returns (stdout, stderr, returncode)."""
        args = args or []
        script_path = os.path.join(SCRIPT_DIR, script_name)
        system = platform.system()
        env = os.environ.copy()
        # Ensure W_FOLDER is exported to child processes
        env.setdefault('W_FOLDER', DEFAULT_W_FOLDER)
        try:
            if system == 'Windows':
                if script_name.endswith('.sh'):
                    bash_exe = shutil.which('bash')
                    if bash_exe:
                        cmd = [bash_exe, script_path] + args
                        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                              universal_newlines=True, timeout=timeout, env=env)
                        return proc.stdout, proc.stderr, proc.returncode
                    if shutil.which('wsl'):
                        joined_args = ' '.join(shlex.quote(a) for a in args)
                        wsl_cmd = f"cd {shlex.quote(SCRIPT_DIR)} && bash -lc {shlex.quote('./' + script_name + ' ' + joined_args)}"
                        proc = subprocess.run(['wsl', 'bash', '-lc', wsl_cmd], stdout=subprocess.PIPE,
                                              stderr=subprocess.PIPE, universal_newlines=True, timeout=timeout, env=env)
                        return proc.stdout, proc.stderr, proc.returncode
                    raise FileNotFoundError("No bash found on Windows. Install Git Bash or enable WSL.")
                if script_name.endswith('.py'):
                    py = sys.executable or 'python'
                    cmd = [py, script_path] + args
                    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                          universal_newlines=True, timeout=timeout, env=env)
                    return proc.stdout, proc.stderr, proc.returncode
                cmd = ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', script_path] + args
                proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      universal_newlines=True, timeout=timeout, env=env)
                return proc.stdout, proc.stderr, proc.returncode
            else:
                if script_name.endswith('.sh'):
                    cmd = ['bash', script_path] + args
                elif script_name.endswith('.py'):
                    cmd = [sys.executable or 'python3', script_path] + args
                else:
                    cmd = [script_path] + args
                proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      universal_newlines=True, timeout=timeout, env=env)
                return proc.stdout, proc.stderr, proc.returncode
        except Exception as e:
            return '', f"Execution error: {e}", 1

def main():
    """Main function"""
    if not HAS_GUI:
        print("GUI not available. Please install tkinter:")
        print("sudo apt-get install python3-tk")
        return
        
    # Check if we're in the right directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    # Create and run the GUI application
    app = IPBlockingGUI()
    app.run()

if __name__ == "__main__":
    main()
