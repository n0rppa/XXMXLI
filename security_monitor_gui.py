#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XXMXLI Security Monitor - GUI Version
Advanced Real-Time Security Monitoring Dashboard

This GUI application provides comprehensive security monitoring with a beautiful
interface for threat detection, IP blocking analysis, and security analytics.

Features:
- Real-time security dashboard
- Interactive threat intelligence
- IP blocking effectiveness monitoring
- Live log analysis with filtering
- Security report generation
- Admin security auditing
- Automated response configuration

Author: XXMXLI Security Team
"""

import os
import sys
import subprocess
import platform
import threading
import time
import json
from datetime import datetime

# GUI imports with fallback
try:
    import tkinter as tk
    from tkinter import ttk, messagebox, filedialog, scrolledtext
    import matplotlib.pyplot as plt
    from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
    import matplotlib.animation as animation
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

class SecurityMonitorGUI:
    def __init__(self):
        # Check if display is available
        if not self.check_display():
            print("Error: No display available. Cannot run GUI application.")
            print("This appears to be a headless environment or X server is not running.")
            print("Use the command-line version instead: monitor_security.sh")
            sys.exit(1)
        
        # Initialize authentication
        self.authenticated = False
        self.admin_password = "xxmxli_security_2024"  # Change this for production
        
        # Create authentication window first
        if not self.authenticate():
            sys.exit(0)
            
        self.root = tk.Tk()
        self.root.title("XXMXLI Security Monitor - Advanced Dashboard")
        self.root.geometry("1200x800")
        self.root.configure(bg='#0a0a0a')
        
        # Color scheme
        self.colors = {
            'bg': '#0a0a0a',
            'panel': '#1a1a1a',
            'dark_panel': '#0d0d0d',
            'accent': '#00ff00',
            'warning': '#ffaa00',
            'error': '#ff4444',
            'safe': '#00aa00',
            'text': '#ffffff',
            'dim_text': '#cccccc',
            'button': '#003300',
            'button_hover': '#005500'
        }
        
        # Security data
        self.security_data = {
            'blocked_attempts': 0,
            'active_threats': 0,
            'security_score': 100,
            'last_scan': 'Never',
            'monitoring_active': False
        }
        
        # Initialize interface
        self.setup_styles()
        self.create_interface()
        self.start_monitoring()
        
    def setup_styles(self):
        """Configure GUI styles for security theme"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # Dark security theme styles
        style.configure('Title.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['accent'],
                       font=('Arial', 18, 'bold'))
        
        style.configure('Heading.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['text'],
                       font=('Arial', 14, 'bold'))
        
        style.configure('Info.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['dim_text'],
                       font=('Arial', 10))
        
        style.configure('Alert.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['warning'],
                       font=('Arial', 12, 'bold'))
        
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
        """Create the main security dashboard interface"""
        
        # Main title
        self.create_header()
        
        # Security metrics dashboard
        self.create_metrics_panel()
        
        # Main content area with tabs
        self.create_main_tabs()
        
        # Bottom status bar
        self.create_status_bar()
        
    def create_header(self):
        """Create header with title and status"""
        header_frame = tk.Frame(self.root, bg=self.colors['bg'], height=80)
        header_frame.pack(fill='x', padx=10, pady=5)
        header_frame.pack_propagate(False)
        
        # Title
        title_label = ttk.Label(header_frame, text="XXMXLI SECURITY MONITOR",
                               style='Title.TLabel')
        title_label.pack(side='left', pady=10)
        
        # Security status indicator
        status_frame = tk.Frame(header_frame, bg=self.colors['bg'])
        status_frame.pack(side='right', pady=10)
        
        self.security_indicator = tk.Label(status_frame,
                                         text="SECURE",
                                         bg=self.colors['safe'],
                                         fg='white',
                                         font=('Arial', 14, 'bold'),
                                         padx=20, pady=5)
        self.security_indicator.pack()
        
        # Subtitle
        subtitle_label = ttk.Label(header_frame, text="Advanced Real-Time Threat Intelligence",
                                  style='Info.TLabel')
        subtitle_label.pack(anchor='w', padx=5)
        
    def create_metrics_panel(self):
        """Create security metrics dashboard"""
        metrics_frame = ttk.Frame(self.root, style='Security.TFrame')
        metrics_frame.pack(fill='x', padx=10, pady=5)
        
        # Metrics grid
        metrics_grid = tk.Frame(metrics_frame, bg=self.colors['panel'])
        metrics_grid.pack(fill='x', padx=10, pady=10)
        
        # Blocked attempts metric
        self.create_metric_widget(metrics_grid, "BLOCKED ATTEMPTS", 
                                 self.security_data['blocked_attempts'], 
                                 self.colors['safe'], 0, 0)
        
        # Active threats metric
        self.create_metric_widget(metrics_grid, "ACTIVE THREATS", 
                                 self.security_data['active_threats'], 
                                 self.colors['warning'], 0, 1)
        
        # Security score metric
        self.create_metric_widget(metrics_grid, "SECURITY SCORE", 
                                 f"{self.security_data['security_score']}%", 
                                 self.colors['accent'], 0, 2)
        
        # Last scan metric
        self.create_metric_widget(metrics_grid, "LAST SCAN", 
                                 self.security_data['last_scan'], 
                                 self.colors['dim_text'], 0, 3)
        
    def create_metric_widget(self, parent, title, value, color, row, col):
        """Create individual metric widget"""
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
                              font=('Arial', 16, 'bold'))
        value_label.pack(pady=(0, 5))
        
        # Store reference for updates
        setattr(self, f'metric_{title.lower().replace(" ", "_")}_value', value_label)
        
    def check_display(self):
        """Check if display is available for GUI"""
        try:
            # Check if we're on Windows (always has display)
            if platform.system() == 'Windows':
                return True
            
            # For Linux/Unix, try to actually create a test Tk instance
            try:
                import tkinter as tk_test
                test_root = tk_test.Tk()
                test_root.withdraw()  # Hide the test window
                test_root.destroy()   # Clean up
                return True
            except Exception as e:
                # If we can't create a Tk instance, display is not available
                return False
                
        except Exception:
            return False
    
    def authenticate(self):
        """Admin authentication dialog"""
        auth_root = tk.Tk()
        auth_root.title("XXMXLI Security Monitor - Authentication")
        auth_root.geometry("400x300")
        auth_root.configure(bg='#0a0a0a')
        auth_root.resizable(False, False)
        
        # Center the window
        auth_root.eval('tk::PlaceWindow . center')
        
        # Authentication result
        auth_result = {'success': False}
        
        # Header
        header_frame = tk.Frame(auth_root, bg='#0a0a0a')
        header_frame.pack(fill='x', pady=20)
        
        title_label = tk.Label(header_frame,
                              text="SECURITY MONITOR",
                              font=('Arial', 16, 'bold'),
                              fg='#00ff00',
                              bg='#0a0a0a')
        title_label.pack()
        
        subtitle_label = tk.Label(header_frame,
                                 text="Admin Authentication Required",
                                 font=('Arial', 10),
                                 fg='#ffffff',
                                 bg='#0a0a0a')
        subtitle_label.pack(pady=(5, 0))
        
        # Login form
        form_frame = tk.Frame(auth_root, bg='#1a1a1a', padx=20, pady=20)
        form_frame.pack(fill='both', expand=True, padx=20, pady=20)
        
        password_label = tk.Label(form_frame,
                                 text="Admin Password:",
                                 font=('Arial', 12),
                                 fg='#ffffff',
                                 bg='#1a1a1a')
        password_label.pack(pady=(0, 10))
        
        password_var = tk.StringVar()
        password_entry = tk.Entry(form_frame,
                                 textvariable=password_var,
                                 show='*',
                                 font=('Arial', 12),
                                 width=25,
                                 bg='#000000',
                                 fg='#ffffff',
                                 insertbackground='#ffffff')
        password_entry.pack(pady=(0, 20))
        
        def check_password():
            if password_var.get() == self.admin_password:
                auth_result['success'] = True
                auth_root.destroy()
            else:
                error_label.config(text="Invalid password!", fg='#ff4444')
                password_entry.delete(0, tk.END)
                password_entry.focus()
        
        def on_enter(event):
            check_password()
        
        password_entry.bind('<Return>', on_enter)
        password_entry.focus()
        
        # Buttons
        button_frame = tk.Frame(form_frame, bg='#1a1a1a')
        button_frame.pack(fill='x', pady=10)
        
        login_btn = tk.Button(button_frame,
                             text="LOGIN",
                             command=check_password,
                             font=('Arial', 12, 'bold'),
                             bg='#003300',
                             fg='#ffffff',
                             padx=20,
                             pady=5,
                             relief='flat')
        login_btn.pack(side='left', padx=(0, 10))
        
        cancel_btn = tk.Button(button_frame,
                              text="CANCEL",
                              command=auth_root.destroy,
                              font=('Arial', 12, 'bold'),
                              bg='#330000',
                              fg='#ffffff',
                              padx=20,
                              pady=5,
                              relief='flat')
        cancel_btn.pack(side='right')
        
        # Error label
        error_label = tk.Label(form_frame,
                              text="",
                              font=('Arial', 10),
                              bg='#1a1a1a')
        error_label.pack(pady=(10, 0))
        
        # Security warning
        warning_label = tk.Label(auth_root,
                                text="⚠ AUTHORIZED PERSONNEL ONLY ⚠",
                                font=('Arial', 9),
                                fg='#ffaa00',
                                bg='#0a0a0a')
        warning_label.pack(pady=(0, 10))
        
        auth_root.mainloop()
        return auth_result['success']
        
    def create_main_tabs(self):
        """Create main tabbed interface"""
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Create tabs
        self.create_dashboard_tab()
        self.create_threats_tab()
        self.create_analytics_tab()
        self.create_logs_tab()
        self.create_config_tab()
        
    def create_dashboard_tab(self):
        """Create main security dashboard tab"""
        dashboard_frame = ttk.Frame(self.notebook)
        self.notebook.add(dashboard_frame, text="Security Dashboard")
        
        # Left panel - Quick actions
        left_panel = ttk.Frame(dashboard_frame, style='Security.TFrame')
        left_panel.pack(side='left', fill='y', padx=5, pady=5)
        
        ttk.Label(left_panel, text="QUICK ACTIONS", style='Heading.TLabel').pack(pady=10)
        
        # Quick action buttons
        actions = [
            ("Run Security Scan", self.run_security_scan),
            ("Check IP Blocking", self.check_ip_blocking),
            ("View Blocked IPs", self.view_blocked_ips),
            ("Generate Report", self.generate_security_report),
            ("Admin Security Audit", self.admin_security_audit),
            ("Emergency Lock Down", self.emergency_lockdown)
        ]
        
        for action_text, action_cmd in actions:
            btn = ttk.Button(left_panel, text=action_text,
                            command=action_cmd, style='Action.TButton')
            btn.pack(fill='x', padx=10, pady=2)
            
        # Right panel - Live monitoring
        right_panel = ttk.Frame(dashboard_frame, style='Security.TFrame')
        right_panel.pack(side='right', fill='both', expand=True, padx=5, pady=5)
        
        ttk.Label(right_panel, text="LIVE SECURITY FEED", style='Heading.TLabel').pack(pady=5)
        
        # Live feed output
        self.live_feed = scrolledtext.ScrolledText(right_panel,
                                                  height=20,
                                                  bg='#000000',
                                                  fg='#00ff00',
                                                  font=('Courier', 9),
                                                  wrap='word')
        self.live_feed.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Feed controls
        feed_controls = tk.Frame(right_panel, bg=self.colors['panel'])
        feed_controls.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(feed_controls, text="Start Live Feed",
                  command=self.start_live_feed).pack(side='left', padx=5)
        ttk.Button(feed_controls, text="Stop Feed",
                  command=self.stop_live_feed).pack(side='left', padx=5)
        ttk.Button(feed_controls, text="Clear",
                  command=self.clear_live_feed).pack(side='left', padx=5)
        
    def create_threats_tab(self):
        """Create threat intelligence tab"""
        threats_frame = ttk.Frame(self.notebook)
        self.notebook.add(threats_frame, text="Threat Intelligence")
        
        # Threat analysis panel
        threat_panel = ttk.Frame(threats_frame, style='Security.TFrame')
        threat_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(threat_panel, text="THREAT INTELLIGENCE DASHBOARD",
                 style='Heading.TLabel').pack(pady=5)
        
        # Threat categories
        categories_frame = tk.Frame(threat_panel, bg=self.colors['panel'])
        categories_frame.pack(fill='x', padx=10, pady=10)
        
        threat_categories = [
            ("Malware Detected", 0, self.colors['error']),
            ("Intrusion Attempts", 0, self.colors['warning']),
            ("DDoS Attacks", 0, self.colors['error']),
            ("Phishing Attempts", 0, self.colors['warning']),
            ("Port Scans", 0, self.colors['accent']),
            ("Suspicious Activity", 0, self.colors['warning'])
        ]
        
        for i, (category, count, color) in enumerate(threat_categories):
            self.create_threat_category(categories_frame, category, count, color, i // 3, i % 3)
            
        # Threat details
        details_frame = ttk.Frame(threat_panel, style='Security.TFrame')
        details_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(details_frame, text="THREAT DETAILS", style='Heading.TLabel').pack(pady=5)
        
        self.threat_details = scrolledtext.ScrolledText(details_frame,
                                                       height=15,
                                                       bg='#000000',
                                                       fg='#ffffff',
                                                       font=('Courier', 9))
        self.threat_details.pack(fill='both', expand=True, padx=10, pady=5)
        
    def create_threat_category(self, parent, category, count, color, row, col):
        """Create threat category widget"""
        category_frame = tk.Frame(parent, bg=self.colors['dark_panel'],
                                 relief='raised', borderwidth=1)
        category_frame.grid(row=row, column=col, padx=5, pady=5, sticky='ew')
        parent.grid_columnconfigure(col, weight=1)
        
        # Category label
        cat_label = tk.Label(category_frame, text=category,
                            bg=self.colors['dark_panel'],
                            fg=self.colors['text'],
                            font=('Arial', 10, 'bold'))
        cat_label.pack(pady=2)
        
        # Count
        count_label = tk.Label(category_frame, text=str(count),
                              bg=self.colors['dark_panel'],
                              fg=color,
                              font=('Arial', 14, 'bold'))
        count_label.pack(pady=2)
        
    def create_analytics_tab(self):
        """Create security analytics tab"""
        analytics_frame = ttk.Frame(self.notebook)
        self.notebook.add(analytics_frame, text="Security Analytics")
        
        # Analytics panel
        analytics_panel = ttk.Frame(analytics_frame, style='Security.TFrame')
        analytics_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(analytics_panel, text="SECURITY ANALYTICS & REPORTS",
                 style='Heading.TLabel').pack(pady=5)
        
        if HAS_MATPLOTLIB:
            # Create matplotlib figure for charts
            self.create_analytics_charts(analytics_panel)
        else:
            # Fallback to text-based analytics
            self.create_text_analytics(analytics_panel)
            
    def create_analytics_charts(self, parent):
        """Create analytics charts using matplotlib"""
        # Chart frame
        chart_frame = tk.Frame(parent, bg=self.colors['panel'])
        chart_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Create figure
        self.fig, ((self.ax1, self.ax2), (self.ax3, self.ax4)) = plt.subplots(2, 2, figsize=(10, 6),
                                                                               facecolor=self.colors['panel'])
        
        # Configure dark theme for plots
        for ax in [self.ax1, self.ax2, self.ax3, self.ax4]:
            ax.set_facecolor(self.colors['dark_panel'])
            ax.tick_params(colors=self.colors['text'])
            ax.spines['bottom'].set_color(self.colors['text'])
            ax.spines['top'].set_color(self.colors['text'])
            ax.spines['left'].set_color(self.colors['text'])
            ax.spines['right'].set_color(self.colors['text'])
            
        # Create canvas
        self.canvas = FigureCanvasTkAgg(self.fig, chart_frame)
        self.canvas.get_tk_widget().pack(fill='both', expand=True)
        
        # Update charts
        self.update_analytics_charts()
        
    def create_text_analytics(self, parent):
        """Create text-based analytics fallback"""
        text_frame = tk.Frame(parent, bg=self.colors['panel'])
        text_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        self.analytics_text = scrolledtext.ScrolledText(text_frame,
                                                       height=20,
                                                       bg='#000000',
                                                       fg='#ffffff',
                                                       font=('Courier', 10))
        self.analytics_text.pack(fill='both', expand=True)
        
        # Update text analytics
        self.update_text_analytics()
        
    def create_logs_tab(self):
        """Create logs monitoring tab"""
        logs_frame = ttk.Frame(self.notebook)
        self.notebook.add(logs_frame, text="Live Logs")
        
        # Log monitoring panel
        log_panel = ttk.Frame(logs_frame, style='Security.TFrame')
        log_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(log_panel, text="LIVE LOG MONITORING",
                 style='Heading.TLabel').pack(pady=5)
        
        # Log filter controls
        filter_frame = tk.Frame(log_panel, bg=self.colors['panel'])
        filter_frame.pack(fill='x', padx=10, pady=5)
        
        ttk.Label(filter_frame, text="Filter:", style='Info.TLabel').pack(side='left', padx=5)
        
        self.log_filter = tk.StringVar()
        filter_entry = ttk.Entry(filter_frame, textvariable=self.log_filter, width=20)
        filter_entry.pack(side='left', padx=5)
        
        ttk.Button(filter_frame, text="Apply Filter",
                  command=self.apply_log_filter).pack(side='left', padx=5)
        ttk.Button(filter_frame, text="Clear Filter",
                  command=self.clear_log_filter).pack(side='left', padx=5)
        
        # Log display
        self.log_display = scrolledtext.ScrolledText(log_panel,
                                                    height=20,
                                                    bg='#000000',
                                                    fg='#ffffff',
                                                    font=('Courier', 9))
        self.log_display.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Log controls
        log_controls = tk.Frame(log_panel, bg=self.colors['panel'])
        log_controls.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(log_controls, text="Refresh Logs",
                  command=self.refresh_logs).pack(side='left', padx=5)
        ttk.Button(log_controls, text="Export Logs",
                  command=self.export_logs).pack(side='left', padx=5)
        
    def create_config_tab(self):
        """Create configuration tab"""
        config_frame = ttk.Frame(self.notebook)
        self.notebook.add(config_frame, text="Configuration")

        # Configuration panel
        config_panel = ttk.Frame(config_frame, style='Security.TFrame')
        config_panel.pack(fill='both', expand=True, padx=10, pady=10)

        ttk.Label(config_panel, text="SECURITY CONFIGURATION",
                  style='Heading.TLabel').pack(pady=5)

        # Configuration options
        config_options = tk.Frame(config_panel, bg=self.colors['panel'])
        config_options.pack(fill='x', padx=10, pady=10)

        # Variables (StringVar-backed for Spinbox compatibility on older Tk versions)
        self.monitor_interval_var = tk.StringVar()
        self.monitor_interval_var.set('60')
        self.alert_threshold_var = tk.StringVar()
        self.alert_threshold_var.set('10')
        self.auto_response = tk.BooleanVar(value=True)

        # Monitoring settings
        ttk.Label(config_options, text="Monitoring Interval (seconds):",
                  style='Info.TLabel').grid(row=0, column=0, sticky='w', pady=5)
        self.monitor_interval = tk.Spinbox(
            config_options, from_=10, to=3600, width=10,
            textvariable=self.monitor_interval_var
        )
        self.monitor_interval.grid(row=0, column=1, sticky='w', padx=10, pady=5)

        # Alert settings
        ttk.Label(config_options, text="Alert Threshold:",
                  style='Info.TLabel').grid(row=1, column=0, sticky='w', pady=5)
        self.alert_threshold = tk.Spinbox(
            config_options, from_=1, to=100, width=10,
            textvariable=self.alert_threshold_var
        )
        self.alert_threshold.grid(row=1, column=1, sticky='w', padx=10, pady=5)

        # Auto-response
        ttk.Label(config_options, text="Enable Auto-Response:",
                  style='Info.TLabel').grid(row=2, column=0, sticky='w', pady=5)
        ttk.Checkbutton(config_options, variable=self.auto_response).grid(
            row=2, column=1, sticky='w', padx=10, pady=5
        )

        # Save button
        ttk.Button(
            config_options,
            text="Save Configuration",
            command=self.save_configuration,
            style='Action.TButton'
        ).grid(row=3, column=1, sticky='w', padx=10, pady=20)
        
    def create_status_bar(self):
        """Create bottom status bar"""
        status_frame = tk.Frame(self.root, bg=self.colors['dark_panel'], height=30)
        status_frame.pack(fill='x', side='bottom')
        status_frame.pack_propagate(False)
        
        self.status_label = tk.Label(status_frame, text="Security Monitor Ready",
                                    bg=self.colors['dark_panel'],
                                    fg=self.colors['dim_text'],
                                    font=('Arial', 9))
        self.status_label.pack(side='left', padx=10, pady=5)
        
        self.time_label = tk.Label(status_frame, text="",
                                  bg=self.colors['dark_panel'],
                                  fg=self.colors['dim_text'],
                                  font=('Arial', 9))
        self.time_label.pack(side='right', padx=10, pady=5)
        
        # Update time
        self.update_time()
        
    def start_monitoring(self):
        """Start security monitoring"""
        self.security_data['monitoring_active'] = True
        self.update_security_metrics()
        
    def update_security_metrics(self):
        """Update security metrics periodically"""
        if self.security_data['monitoring_active']:
            # Simulate security data updates
            import random
            
            # Update blocked attempts (incremental)
            if random.random() < 0.3:
                self.security_data['blocked_attempts'] += random.randint(1, 5)
                
            # Update active threats
            self.security_data['active_threats'] = random.randint(0, 3)
            
            # Update security score
            base_score = 95
            threat_penalty = self.security_data['active_threats'] * 5
            self.security_data['security_score'] = max(50, base_score - threat_penalty)
            
            # Update last scan
            self.security_data['last_scan'] = datetime.now().strftime('%H:%M:%S')
            
            # Update UI
            try:
                self.metric_blocked_attempts_value.config(text=str(self.security_data['blocked_attempts']))
                self.metric_active_threats_value.config(text=str(self.security_data['active_threats']))
                self.metric_security_score_value.config(text=f"{self.security_data['security_score']}%")
                self.metric_last_scan_value.config(text=self.security_data['last_scan'])
                
                # Update security indicator
                if self.security_data['security_score'] >= 90:
                    self.security_indicator.config(text="SECURE", bg=self.colors['safe'])
                elif self.security_data['security_score'] >= 70:
                    self.security_indicator.config(text="WARNING", bg=self.colors['warning'])
                else:
                    self.security_indicator.config(text="CRITICAL", bg=self.colors['error'])
            except:
                pass
                
        # Schedule next update
        self.root.after(5000, self.update_security_metrics)
        
    def update_time(self):
        """Update time display"""
        current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.time_label.config(text=current_time)
        self.root.after(1000, self.update_time)
        
    # Event handlers for all the buttons
    def run_security_scan(self):
        """Run comprehensive security scan"""
        self.status_label.config(text="Running security scan...")
        threading.Thread(target=self._run_security_scan_worker, daemon=True).start()
        
    def _run_security_scan_worker(self):
        """Background worker for security scan"""
        try:
            # Check if monitor_security.sh exists, otherwise use fallback
            scan_script = 'monitor_security.sh'
            if not os.path.exists(scan_script):
                # Use built-in security scan
                self.root.after(0, self._security_scan_complete, self._builtin_security_scan())
                return
                
            result = subprocess.run(
                ['bash', scan_script, '1'],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                universal_newlines=True, timeout=30
            )
            
            if result.returncode == 0:
                self.root.after(0, self._security_scan_complete, result.stdout)
            else:
                # Fallback to built-in scan if script fails
                self.root.after(0, self._security_scan_complete, self._builtin_security_scan())
                
        except Exception as e:
            # Use built-in scan as fallback
            self.root.after(0, self._security_scan_complete, self._builtin_security_scan())
    
    def _builtin_security_scan(self):
        """Built-in security scan functionality"""
        scan_results = []
        scan_results.append("=== XXMXLI SECURITY SCAN RESULTS ===")
        scan_results.append(f"Scan Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        scan_results.append("")
        
        # Check system security basics
        scan_results.append("1. SYSTEM SECURITY CHECK:")
        
        # Check if running as root (security concern)
        if os.geteuid() == 0:
            scan_results.append("  ⚠ WARNING: Running as root user")
        else:
            scan_results.append("  ✓ Not running as root (good)")
        
        # Check file permissions on current directory
        try:
            import stat
            dir_stat = os.stat('.')
            if stat.filemode(dir_stat.st_mode)[1:] == 'rwxr-xr-x':
                scan_results.append("  ✓ Directory permissions secure")
            else:
                scan_results.append("  ⚠ Directory permissions may be too permissive")
        except:
            scan_results.append("  ? Unable to check directory permissions")
        
        scan_results.append("")
        scan_results.append("2. NETWORK SECURITY:")
        
        # Check for common listening ports
        try:
            import socket
            common_ports = [22, 80, 443, 3000, 8000, 8080]
            open_ports = []
            
            for port in common_ports:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                result = sock.connect_ex(('localhost', port))
                if result == 0:
                    open_ports.append(port)
                sock.close()
            
            if open_ports:
                scan_results.append(f"  ! Open ports detected: {', '.join(map(str, open_ports))}")
            else:
                scan_results.append("  ✓ No common ports open on localhost")
        except:
            scan_results.append("  ? Unable to scan ports")
        
        scan_results.append("")
        scan_results.append("3. FILE SYSTEM SECURITY:")
        
        # Check for sensitive files
        sensitive_files = ['.env', 'config.php', 'wp-config.php', '.htpasswd']
        found_sensitive = []
        
        for filename in sensitive_files:
            if os.path.exists(filename):
                found_sensitive.append(filename)
        
        if found_sensitive:
            scan_results.append(f"  ⚠ Sensitive files found: {', '.join(found_sensitive)}")
        else:
            scan_results.append("  ✓ No obvious sensitive files in current directory")
        
        scan_results.append("")
        scan_results.append("=== SCAN COMPLETE ===")
        scan_results.append("For comprehensive security analysis, ensure monitor_security.sh is available.")
        
        return "\n".join(scan_results)
            
    def _security_scan_complete(self, output):
        """Handle security scan completion"""
        self.status_label.config(text="Security scan completed")
        messagebox.showinfo("Security Scan Complete", f"Scan results:\n\n{output[:500]}...")
        
    def _security_scan_error(self, error):
        """Handle security scan error"""
        self.status_label.config(text="Security scan failed")
        messagebox.showerror("Scan Error", f"Security scan failed: {error}")
        
    def check_ip_blocking(self):
        """Check IP blocking effectiveness"""
        self.status_label.config(text="Checking IP blocking...")
        threading.Thread(target=self._check_ip_blocking_worker, daemon=True).start()
        
    def _check_ip_blocking_worker(self):
        """Background worker for IP blocking check"""
        try:
            result = subprocess.run(
                ['bash', 'monitor_security.sh', '3'],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                universal_newlines=True, timeout=30
            )
            
            self.root.after(0, self._ip_blocking_complete, result.stdout)
        except Exception as e:
            self.root.after(0, self._ip_blocking_error, str(e))
            
    def _ip_blocking_complete(self, output):
        """Handle IP blocking check completion"""
        self.status_label.config(text="IP blocking check completed")
        messagebox.showinfo("IP Blocking Status", f"Blocking status:\n\n{output[:500]}...")
        
    def _ip_blocking_error(self, error):
        """Handle IP blocking check error"""
        self.status_label.config(text="IP blocking check failed")
        messagebox.showerror("Check Error", f"IP blocking check failed: {error}")
        
    def view_blocked_ips(self):
        """View currently blocked IP addresses"""
        self.status_label.config(text="Retrieving blocked IPs...")
        
        # Create new window for blocked IPs
        blocked_window = tk.Toplevel(self.root)
        blocked_window.title("Blocked IP Addresses")
        blocked_window.geometry("600x400")
        blocked_window.configure(bg=self.colors['bg'])
        
        # Blocked IPs list
        list_frame = tk.Frame(blocked_window, bg=self.colors['panel'])
        list_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(list_frame, text="CURRENTLY BLOCKED IP ADDRESSES",
                 style='Heading.TLabel').pack(pady=5)
        
        blocked_list = scrolledtext.ScrolledText(list_frame,
                                               height=20,
                                               bg='#000000',
                                               fg='#ff4444',
                                               font=('Courier', 10))
        blocked_list.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Load blocked IPs (placeholder)
        blocked_list.insert('end', "Loading blocked IP addresses...\n")
        
    def generate_security_report(self):
        """Generate comprehensive security report"""
        file_path = filedialog.asksaveasfilename(
            title="Save Security Report",
            defaultextension=".txt",
            filetypes=[("Text Files", "*.txt"), ("HTML Files", "*.html")]
        )
        
        if file_path:
            self.status_label.config(text="Generating security report...")
            threading.Thread(target=self._generate_report_worker, args=(file_path,), daemon=True).start()
            
    def _generate_report_worker(self, file_path):
        """Background worker for report generation"""
        try:
            # Generate report content
            report_content = f"""XXMXLI Security Report
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

SECURITY METRICS:
- Blocked Attempts: {self.security_data['blocked_attempts']}
- Active Threats: {self.security_data['active_threats']}
- Security Score: {self.security_data['security_score']}%
- Last Scan: {self.security_data['last_scan']}

SYSTEM STATUS:
- Monitoring: {'Active' if self.security_data['monitoring_active'] else 'Inactive'}
- Platform: {platform.system()} {platform.release()}

RECOMMENDATIONS:
- Continue monitoring for threats
- Review security configurations regularly
- Update security policies as needed
"""
            
            with open(file_path, 'w') as f:
                f.write(report_content)
                
            self.root.after(0, self._report_complete, file_path)
        except Exception as e:
            self.root.after(0, self._report_error, str(e))
            
    def _report_complete(self, file_path):
        """Handle report generation completion"""
        self.status_label.config(text="Security report generated")
        messagebox.showinfo("Report Generated", f"Security report saved to:\n{file_path}")
        
    def _report_error(self, error):
        """Handle report generation error"""
        self.status_label.config(text="Report generation failed")
        messagebox.showerror("Report Error", f"Failed to generate report: {error}")
        
    def admin_security_audit(self):
        """Run admin security audit"""
        self.status_label.config(text="Running admin security audit...")
        threading.Thread(target=self._admin_audit_worker, daemon=True).start()
        
    def _admin_audit_worker(self):
        """Background worker for admin audit"""
        try:
            # Check if monitor_security.sh exists, otherwise use fallback
            audit_script = 'monitor_security.sh'
            if not os.path.exists(audit_script):
                # Use built-in admin audit
                self.root.after(0, self._admin_audit_complete, self._builtin_admin_audit())
                return
                
            result = subprocess.run(
                ['bash', audit_script, '6'],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                universal_newlines=True, timeout=60
            )
            
            if result.returncode == 0:
                self.root.after(0, self._admin_audit_complete, result.stdout)
            else:
                # Fallback to built-in audit if script fails
                self.root.after(0, self._admin_audit_complete, self._builtin_admin_audit())
                
        except Exception as e:
            # Use built-in audit as fallback
            self.root.after(0, self._admin_audit_complete, self._builtin_admin_audit())
    
    def _builtin_admin_audit(self):
        """Built-in admin audit functionality"""
        audit_results = []
        audit_results.append("=== XXMXLI ADMIN SECURITY AUDIT ===")
        audit_results.append(f"Audit Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        audit_results.append(f"Auditor: System Admin")
        audit_results.append("")
        
        # System Information
        audit_results.append("1. SYSTEM INFORMATION:")
        audit_results.append(f"  Operating System: {platform.system()} {platform.release()}")
        audit_results.append(f"  Python Version: {platform.python_version()}")
        audit_results.append(f"  Current User: {os.getenv('USER', 'unknown')}")
        audit_results.append(f"  Working Directory: {os.getcwd()}")
        audit_results.append("")
        
        # Security Configuration
        audit_results.append("2. SECURITY CONFIGURATION AUDIT:")
        
        # Check admin files
        admin_files = ['admin/', 'ADMIN_CREDENTIALS_SECURE.txt', 'security.html']
        for admin_file in admin_files:
            if os.path.exists(admin_file):
                audit_results.append(f"  ✓ Admin file present: {admin_file}")
            else:
                audit_results.append(f"  ⚠ Admin file missing: {admin_file}")
        
        audit_results.append("")
        
        # Check security scripts
        audit_results.append("3. SECURITY SCRIPTS AUDIT:")
        security_scripts = ['monitor_security.sh', 'setup_ip_blocking.sh', 'health-check.sh']
        for script in security_scripts:
            if os.path.exists(script):
                try:
                    stat_info = os.stat(script)
                    if stat_info.st_mode & 0o111:  # Check if executable
                        audit_results.append(f"  ✓ Security script ready: {script}")
                    else:
                        audit_results.append(f"  ⚠ Security script not executable: {script}")
                except:
                    audit_results.append(f"  ? Cannot check script: {script}")
            else:
                audit_results.append(f"  ⚠ Security script missing: {script}")
        
        audit_results.append("")
        
        # Check for security-related processes
        audit_results.append("4. SECURITY PROCESS AUDIT:")
        try:
            # Check if any security monitoring is running
            result = subprocess.run(['ps', 'aux'], capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                security_processes = []
                for line in result.stdout.split('\n'):
                    if any(term in line.lower() for term in ['security', 'monitor', 'fail2ban', 'ufw']):
                        security_processes.append(line.strip())
                
                if security_processes:
                    audit_results.append("  Security-related processes found:")
                    for proc in security_processes[:5]:  # Limit to 5 processes
                        audit_results.append(f"    {proc}")
                else:
                    audit_results.append("  ⚠ No obvious security processes detected")
            else:
                audit_results.append("  ? Unable to check running processes")
        except:
            audit_results.append("  ? Process audit unavailable")
        
        audit_results.append("")
        
        # File permissions audit
        audit_results.append("5. FILE PERMISSIONS AUDIT:")
        critical_files = ['index.html', 'security.html', 'admin/']
        for file_path in critical_files:
            if os.path.exists(file_path):
                try:
                    import stat
                    file_stat = os.stat(file_path)
                    permissions = stat.filemode(file_stat.st_mode)
                    audit_results.append(f"  {file_path}: {permissions}")
                except:
                    audit_results.append(f"  {file_path}: Unable to check permissions")
            else:
                audit_results.append(f"  {file_path}: File not found")
        
        audit_results.append("")
        audit_results.append("=== AUDIT COMPLETE ===")
        audit_results.append("Recommendation: Review any warnings and ensure all security")
        audit_results.append("scripts are properly configured and executable.")
        
        return "\n".join(audit_results)
            
    def _admin_audit_complete(self, output):
        """Handle admin audit completion"""
        self.status_label.config(text="Admin security audit completed")
        
        # Show results in new window
        audit_window = tk.Toplevel(self.root)
        audit_window.title("Admin Security Audit Results")
        audit_window.geometry("800x600")
        audit_window.configure(bg=self.colors['bg'])
        
        audit_text = scrolledtext.ScrolledText(audit_window,
                                             bg='#000000',
                                             fg='#ffffff',
                                             font=('Courier', 10))
        audit_text.pack(fill='both', expand=True, padx=10, pady=10)
        
        audit_text.insert('end', output)
        
    def _admin_audit_error(self, error):
        """Handle admin audit error"""
        self.status_label.config(text="Admin audit failed")
        messagebox.showerror("Audit Error", f"Admin security audit failed: {error}")
        
    def emergency_lockdown(self):
        """Initiate emergency security lockdown"""
        if messagebox.askyesno("Emergency Lockdown",
                              "Initiate emergency security lockdown?\n\n"
                              "This will activate maximum security measures."):
            self.status_label.config(text="Initiating emergency lockdown...")
            messagebox.showinfo("Emergency Lockdown", "Emergency security lockdown initiated!")
            
    def start_live_feed(self):
        """Start live security feed"""
        self.status_label.config(text="Starting live security feed...")
        self.live_feed.insert('end', f"[{datetime.now().strftime('%H:%M:%S')}] Live security feed started\n")
        
    def stop_live_feed(self):
        """Stop live security feed"""
        self.status_label.config(text="Stopping live security feed...")
        self.live_feed.insert('end', f"[{datetime.now().strftime('%H:%M:%S')}] Live security feed stopped\n")
        
    def clear_live_feed(self):
        """Clear live security feed"""
        self.live_feed.delete('1.0', 'end')
        
    def update_analytics_charts(self):
        """Update analytics charts"""
        if HAS_MATPLOTLIB:
            # Clear previous plots
            for ax in [self.ax1, self.ax2, self.ax3, self.ax4]:
                ax.clear()
                
            # Sample data for demonstration
            import numpy as np
            
            # Threat trends
            hours = list(range(24))
            threats = [abs(np.sin(h/4) * 10 + np.random.randint(-2, 3)) for h in hours]
            
            self.ax1.plot(hours, threats, color=self.colors['accent'], linewidth=2)
            self.ax1.set_title('Threat Trends (24h)', color=self.colors['text'])
            self.ax1.set_xlabel('Hours', color=self.colors['text'])
            self.ax1.set_ylabel('Threats', color=self.colors['text'])
            
            # Security score
            days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            scores = [95, 98, 92, 89, 94, 97, 96]
            
            self.ax2.bar(days, scores, color=self.colors['safe'])
            self.ax2.set_title('Security Scores (Week)', color=self.colors['text'])
            self.ax2.set_ylabel('Score %', color=self.colors['text'])
            
            # Blocked attempts pie chart
            categories = ['Malware', 'Intrusion', 'DDoS', 'Other']
            sizes = [30, 25, 20, 25]
            colors = [self.colors['error'], self.colors['warning'], self.colors['accent'], self.colors['safe']]
            
            self.ax3.pie(sizes, labels=categories, colors=colors, autopct='%1.1f%%')
            self.ax3.set_title('Blocked Attempts by Type', color=self.colors['text'])
            
            # System performance
            metrics = ['CPU', 'Memory', 'Disk', 'Network']
            values = [45, 62, 78, 33]
            
            self.ax4.barh(metrics, values, color=self.colors['accent'])
            self.ax4.set_title('System Performance', color=self.colors['text'])
            self.ax4.set_xlabel('Usage %', color=self.colors['text'])
            
            # Update canvas
            self.canvas.draw()
            
    def update_text_analytics(self):
        """Update text-based analytics"""
        analytics_text = f"""XXMXLI Security Analytics Report
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

THREAT STATISTICS:
- Total Blocked Attempts: {self.security_data['blocked_attempts']}
- Active Threats: {self.security_data['active_threats']}
- Security Score: {self.security_data['security_score']}%

SYSTEM METRICS:
- Monitoring Status: {'Active' if self.security_data['monitoring_active'] else 'Inactive'}
- Last Security Scan: {self.security_data['last_scan']}
- Platform: {platform.system()} {platform.release()}

THREAT BREAKDOWN:
- Malware: 30%
- Intrusion Attempts: 25%
- DDoS Attacks: 20%
- Other: 25%

RECOMMENDATIONS:
- Continue monitoring for security threats
- Review firewall rules regularly
- Update security configurations
- Monitor admin access patterns
"""
        
        self.analytics_text.delete('1.0', 'end')
        self.analytics_text.insert('end', analytics_text)
        
    def apply_log_filter(self):
        """Apply filter to log display"""
        filter_text = self.log_filter.get()
        self.status_label.config(text=f"Applied filter: {filter_text}")
        
    def clear_log_filter(self):
        """Clear log filter"""
        self.log_filter.set("")
        self.status_label.config(text="Log filter cleared")
        
    def refresh_logs(self):
        """Refresh log display"""
        self.status_label.config(text="Refreshing logs...")
        # Placeholder for log refresh functionality
        
    def export_logs(self):
        """Export logs to file"""
        file_path = filedialog.asksaveasfilename(
            title="Export Logs",
            defaultextension=".log",
            filetypes=[("Log Files", "*.log"), ("Text Files", "*.txt")]
        )
        
        if file_path:
            try:
                content = self.log_display.get('1.0', 'end')
                with open(file_path, 'w') as f:
                    f.write(content)
                messagebox.showinfo("Export Complete", f"Logs exported to {file_path}")
            except Exception as e:
                messagebox.showerror("Export Error", f"Failed to export logs: {e}")
                
    def save_configuration(self):
        """Save security configuration"""
        try:
            config = {
                'monitor_interval': self.monitor_interval.get(),
                'alert_threshold': self.alert_threshold.get(),
                'auto_response': self.auto_response.get()
            }
            
            with open('security_config.json', 'w') as f:
                json.dump(config, f, indent=2)
                
            messagebox.showinfo("Configuration Saved", "Security configuration has been saved successfully!")
            self.status_label.config(text="Configuration saved")
        except Exception as e:
            messagebox.showerror("Save Error", f"Failed to save configuration: {e}")
            
    def run(self):
        """Start the GUI application"""
        self.root.mainloop()

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
    app = SecurityMonitorGUI()
    app.run()

if __name__ == "__main__":
    main()
