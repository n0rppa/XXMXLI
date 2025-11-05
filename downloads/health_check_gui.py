#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XXMXLI Health Check - GUI Version
Advanced System Health Monitoring Dashboard

This GUI application provides comprehensive system health monitoring with
beautiful visualizations and real-time diagnostics.

Features:
- Real-time system health dashboard
- Interactive diagnostic modules
- Performance monitoring with charts
- Health report generation
- System optimization recommendations
- Resource usage tracking
- Service status monitoring

Author: XXMXLI Security Team
"""

import os
import sys
import subprocess
import platform
import threading
import time
import shutil
import shlex
from datetime import datetime

# Optional psutil import with graceful fallback
try:
    import psutil  # type: ignore
    HAS_PSUTIL = True
except Exception:
    psutil = None  # type: ignore
    HAS_PSUTIL = False

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

class HealthCheckGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("XXMXLI System Health Monitor")
        self.root.geometry("1200x800")
        self.root.configure(bg='#0f1419')
        
        # Color scheme - health monitoring theme
        self.colors = {
            'bg': '#0f1419',
            'panel': '#1e2328',
            'dark_panel': '#151a1f',
            'healthy': '#00dd00',
            'warning': '#ffaa00',
            'critical': '#ff4444',
            'info': '#00aaff',
            'text': '#ffffff',
            'dim_text': '#cccccc',
            'button': '#003366',
            'button_hover': '#004488'
        }
        
        # System health data
        self.health_data = {
            'cpu_usage': 0,
            'memory_usage': 0,
            'disk_usage': 0,
            'network_usage': 0,
            'system_load': 0,
            'temperature': 0,
            'uptime': 0,
            'processes': 0,
            'overall_health': 100
        }
        
        # Monitoring state
        self.monitoring_active = False
        self.update_interval = 2000  # milliseconds
        
        # Initialize interface
        self.setup_styles()
        self.create_interface()
        # Notify if psutil is missing (reduced capabilities)
        if not HAS_PSUTIL:
            try:
                messagebox.showwarning(
                    "Limited Metrics",
                    "Python psutil package isn't available. The health monitor will run with limited metrics.\n\n"
                    "Install with: pip install psutil"
                )
            except Exception:
                pass
        self.start_monitoring()
        
    def setup_styles(self):
        """Configure GUI styles for health monitoring theme"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # Health monitoring theme styles
        style.configure('Title.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['healthy'],
                       font=('Arial', 18, 'bold'))
        
        style.configure('Heading.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['text'],
                       font=('Arial', 14, 'bold'))
        
        style.configure('Info.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['dim_text'],
                       font=('Arial', 10))
        
        style.configure('Health.TFrame',
                       background=self.colors['panel'],
                       relief='solid',
                       borderwidth=1)
        
        style.configure('Action.TButton',
                       background=self.colors['button'],
                       foreground=self.colors['text'],
                       font=('Arial', 10, 'bold'),
                       padding=8)
        
    def create_interface(self):
        """Create the main health monitoring interface"""
        
        # Header
        self.create_header()
        
        # System overview panel
        self.create_overview_panel()
        
        # Main content tabs
        self.create_main_tabs()
        
        # Status bar
        self.create_status_bar()
        
    def create_header(self):
        """Create header with title and health status"""
        header_frame = tk.Frame(self.root, bg=self.colors['bg'], height=80)
        header_frame.pack(fill='x', padx=10, pady=5)
        header_frame.pack_propagate(False)
        
        # Title
        title_label = ttk.Label(header_frame, text="XXMXLI SYSTEM HEALTH MONITOR",
                               style='Title.TLabel')
        title_label.pack(side='left', pady=10)
        
        # Health status indicator
        status_frame = tk.Frame(header_frame, bg=self.colors['bg'])
        status_frame.pack(side='right', pady=10)
        
        self.health_indicator = tk.Label(status_frame,
                                        text="HEALTHY",
                                        bg=self.colors['healthy'],
                                        fg='white',
                                        font=('Arial', 14, 'bold'),
                                        padx=20, pady=5)
        self.health_indicator.pack()
        
        # Health score
        self.health_score_label = tk.Label(status_frame,
                                          text="100%",
                                          bg=self.colors['bg'],
                                          fg=self.colors['healthy'],
                                          font=('Arial', 12, 'bold'))
        self.health_score_label.pack()
        
        # Subtitle
        subtitle_label = ttk.Label(header_frame, text="Real-Time System Diagnostics & Performance Analysis",
                                  style='Info.TLabel')
        subtitle_label.pack(anchor='w', padx=5)
        
    def create_overview_panel(self):
        """Create system overview panel with key metrics"""
        overview_frame = ttk.Frame(self.root, style='Health.TFrame')
        overview_frame.pack(fill='x', padx=10, pady=5)
        
        # Overview grid
        overview_grid = tk.Frame(overview_frame, bg=self.colors['panel'])
        overview_grid.pack(fill='x', padx=10, pady=10)
        
        # System metrics
        metrics = [
            ("CPU", "cpu_usage", "%", self.colors['info']),
            ("Memory", "memory_usage", "%", self.colors['warning']),
            ("Disk", "disk_usage", "%", self.colors['critical']),
            ("Network", "network_usage", "MB/s", self.colors['healthy']),
            ("Load", "system_load", "", self.colors['info']),
            ("Temp", "temperature", "°C", self.colors['warning']),
            ("Uptime", "uptime", "hrs", self.colors['healthy']),
            ("Processes", "processes", "", self.colors['dim_text'])
        ]
        
        for i, (title, key, unit, color) in enumerate(metrics):
            self.create_metric_widget(overview_grid, title, 
                                     self.health_data[key], unit, color, 
                                     i // 4, i % 4)
            
    def create_metric_widget(self, parent, title, value, unit, color, row, col):
        """Create individual health metric widget"""
        metric_frame = tk.Frame(parent, bg=self.colors['dark_panel'], 
                               relief='raised', borderwidth=1)
        metric_frame.grid(row=row, column=col, padx=3, pady=3, sticky='ew')
        parent.grid_columnconfigure(col, weight=1)
        
        # Title
        title_label = tk.Label(metric_frame, text=title,
                              bg=self.colors['dark_panel'],
                              fg=self.colors['dim_text'],
                              font=('Arial', 8, 'bold'))
        title_label.pack(pady=(3, 0))
        
        # Value with unit
        value_text = f"{value}{unit}" if unit else str(value)
        value_label = tk.Label(metric_frame, text=value_text,
                              bg=self.colors['dark_panel'],
                              fg=color,
                              font=('Arial', 12, 'bold'))
        value_label.pack(pady=(0, 3))
        
        # Store reference for updates
        setattr(self, f'metric_{title.lower()}_value', value_label)
        setattr(self, f'metric_{title.lower()}_unit', unit)
        
    def create_main_tabs(self):
        """Create main tabbed interface"""
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Create tabs
        self.create_realtime_tab()
        self.create_diagnostics_tab()
        self.create_performance_tab()
        self.create_services_tab()
        self.create_reports_tab()
        
    def create_realtime_tab(self):
        """Create real-time monitoring tab"""
        realtime_frame = ttk.Frame(self.notebook)
        self.notebook.add(realtime_frame, text="Real-Time Monitor")
        
        # Left panel - controls
        left_panel = ttk.Frame(realtime_frame, style='Health.TFrame')
        left_panel.pack(side='left', fill='y', padx=5, pady=5)
        
        ttk.Label(left_panel, text="MONITORING CONTROLS", style='Heading.TLabel').pack(pady=10)
        
        # Control buttons
        controls = [
            ("Start Monitoring", self.start_monitoring),
            ("Stop Monitoring", self.stop_monitoring),
            ("Quick Health Check", self.quick_health_check),
            ("Deep System Scan", self.deep_system_scan),
            ("Resource Analysis", self.resource_analysis),
            ("Generate Report", self.generate_health_report)
        ]
        
        for control_text, control_cmd in controls:
            btn = ttk.Button(left_panel, text=control_text,
                            command=control_cmd, style='Action.TButton')
            btn.pack(fill='x', padx=10, pady=3)
            
        # Monitoring settings
        ttk.Label(left_panel, text="SETTINGS", style='Heading.TLabel').pack(pady=(20, 10))
        
        ttk.Label(left_panel, text="Update Interval:", style='Info.TLabel').pack(anchor='w', padx=10)
        self.interval_var = tk.StringVar(value="2")
        interval_combo = ttk.Combobox(left_panel, textvariable=self.interval_var,
                                     values=["1", "2", "5", "10"], width=15)
        interval_combo.pack(padx=10, pady=2)
        
        # Right panel - real-time charts
        right_panel = ttk.Frame(realtime_frame, style='Health.TFrame')
        right_panel.pack(side='right', fill='both', expand=True, padx=5, pady=5)
        
        ttk.Label(right_panel, text="REAL-TIME SYSTEM METRICS", style='Heading.TLabel').pack(pady=5)
        
        if HAS_MATPLOTLIB:
            self.create_realtime_charts(right_panel)
        else:
            self.create_realtime_text(right_panel)
            
    def create_realtime_charts(self, parent):
        """Create real-time monitoring charts"""
        # Chart frame
        chart_frame = tk.Frame(parent, bg=self.colors['panel'])
        chart_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Create matplotlib figure
        self.realtime_fig, ((self.cpu_ax, self.mem_ax), (self.disk_ax, self.net_ax)) = plt.subplots(2, 2, figsize=(8, 6),
                                                                                                     facecolor=self.colors['panel'])
        
        # Configure dark theme for plots
        for ax in [self.cpu_ax, self.mem_ax, self.disk_ax, self.net_ax]:
            ax.set_facecolor(self.colors['dark_panel'])
            ax.tick_params(colors=self.colors['text'])
            ax.spines['bottom'].set_color(self.colors['text'])
            ax.spines['top'].set_color(self.colors['text'])
            ax.spines['left'].set_color(self.colors['text'])
            ax.spines['right'].set_color(self.colors['text'])
            
        # Initialize data arrays for real-time plotting
        self.time_data = list(range(60))
        self.cpu_data = [0] * 60
        self.mem_data = [0] * 60
        self.disk_data = [0] * 60
        self.net_data = [0] * 60
        
        # Create canvas
        self.realtime_canvas = FigureCanvasTkAgg(self.realtime_fig, chart_frame)
        self.realtime_canvas.get_tk_widget().pack(fill='both', expand=True)
        
        # Update charts
        self.update_realtime_charts()
        
    def create_realtime_text(self, parent):
        """Create text-based real-time monitoring"""
        text_frame = tk.Frame(parent, bg=self.colors['panel'])
        text_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        self.realtime_text = scrolledtext.ScrolledText(text_frame,
                                                      height=25,
                                                      bg='#000000',
                                                      fg='#00ff00',
                                                      font=('Courier', 10))
        self.realtime_text.pack(fill='both', expand=True)
        
    def create_diagnostics_tab(self):
        """Create system diagnostics tab"""
        diagnostics_frame = ttk.Frame(self.notebook)
        self.notebook.add(diagnostics_frame, text="System Diagnostics")
        
        # Diagnostics panel
        diag_panel = ttk.Frame(diagnostics_frame, style='Health.TFrame')
        diag_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(diag_panel, text="SYSTEM DIAGNOSTICS", style='Heading.TLabel').pack(pady=5)
        
        # Diagnostic modules
        modules_frame = tk.Frame(diag_panel, bg=self.colors['panel'])
        modules_frame.pack(fill='x', padx=10, pady=10)
        
        diagnostic_modules = [
            ("CPU Diagnostics", "Check processor health and performance", self.run_cpu_diagnostics),
            ("Memory Diagnostics", "Analyze RAM usage and memory leaks", self.run_memory_diagnostics),
            ("Disk Diagnostics", "Check disk health and space usage", self.run_disk_diagnostics),
            ("Network Diagnostics", "Analyze network connectivity and performance", self.run_network_diagnostics),
            ("Security Diagnostics", "Check system security status", self.run_security_diagnostics),
            ("Service Diagnostics", "Analyze running services and processes", self.run_service_diagnostics)
        ]
        
        for i, (module, description, command) in enumerate(diagnostic_modules):
            self.create_diagnostic_module(modules_frame, module, description, command, i // 2, i % 2)
            
        # Diagnostic output
        output_frame = ttk.Frame(diag_panel, style='Health.TFrame')
        output_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(output_frame, text="DIAGNOSTIC OUTPUT", style='Heading.TLabel').pack(pady=5)
        
        self.diagnostic_output = scrolledtext.ScrolledText(output_frame,
                                                          height=15,
                                                          bg='#000000',
                                                          fg='#ffffff',
                                                          font=('Courier', 9))
        self.diagnostic_output.pack(fill='both', expand=True, padx=10, pady=5)
        
    def create_diagnostic_module(self, parent, module, description, command, row, col):
        """Create diagnostic module widget"""
        module_frame = tk.Frame(parent, bg=self.colors['dark_panel'],
                               relief='raised', borderwidth=1)
        module_frame.grid(row=row, column=col, padx=5, pady=5, sticky='ew')
        parent.grid_columnconfigure(col, weight=1)
        
        # Module title
        title_label = tk.Label(module_frame, text=module,
                              bg=self.colors['dark_panel'],
                              fg=self.colors['text'],
                              font=('Arial', 11, 'bold'))
        title_label.pack(pady=5)
        
        # Description
        desc_label = tk.Label(module_frame, text=description,
                             bg=self.colors['dark_panel'],
                             fg=self.colors['dim_text'],
                             font=('Arial', 9),
                             wraplength=250)
        desc_label.pack(pady=2)
        
        # Run button
        run_btn = ttk.Button(module_frame, text="Run Diagnostic",
                            command=command, style='Action.TButton')
        run_btn.pack(pady=5)
        
    def create_performance_tab(self):
        """Create performance analysis tab"""
        performance_frame = ttk.Frame(self.notebook)
        self.notebook.add(performance_frame, text="Performance Analysis")
        
        # Performance panel
        perf_panel = ttk.Frame(performance_frame, style='Health.TFrame')
        perf_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(perf_panel, text="PERFORMANCE ANALYSIS", style='Heading.TLabel').pack(pady=5)
        
        if HAS_MATPLOTLIB:
            self.create_performance_charts(perf_panel)
        else:
            self.create_performance_text(perf_panel)
            
    def create_performance_charts(self, parent):
        """Create performance analysis charts"""
        chart_frame = tk.Frame(parent, bg=self.colors['panel'])
        chart_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Create performance figure
        self.perf_fig, ((self.load_ax, self.proc_ax), (self.io_ax, self.temp_ax)) = plt.subplots(2, 2, figsize=(10, 6),
                                                                                                 facecolor=self.colors['panel'])
        
        # Configure dark theme
        for ax in [self.load_ax, self.proc_ax, self.io_ax, self.temp_ax]:
            ax.set_facecolor(self.colors['dark_panel'])
            ax.tick_params(colors=self.colors['text'])
            for spine in ax.spines.values():
                spine.set_color(self.colors['text'])
                
        # Create canvas
        self.perf_canvas = FigureCanvasTkAgg(self.perf_fig, chart_frame)
        self.perf_canvas.get_tk_widget().pack(fill='both', expand=True)
        
        # Update performance charts
        self.update_performance_charts()
        
    def create_performance_text(self, parent):
        """Create text-based performance analysis"""
        text_frame = tk.Frame(parent, bg=self.colors['panel'])
        text_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        self.performance_text = scrolledtext.ScrolledText(text_frame,
                                                         height=25,
                                                         bg='#000000',
                                                         fg='#ffffff',
                                                         font=('Courier', 10))
        self.performance_text.pack(fill='both', expand=True)
        
    def create_services_tab(self):
        """Create services monitoring tab"""
        services_frame = ttk.Frame(self.notebook)
        self.notebook.add(services_frame, text="Services & Processes")
        
        # Services panel
        services_panel = ttk.Frame(services_frame, style='Health.TFrame')
        services_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(services_panel, text="SERVICES & PROCESSES MONITOR", style='Heading.TLabel').pack(pady=5)
        
        # Service controls
        controls_frame = tk.Frame(services_panel, bg=self.colors['panel'])
        controls_frame.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(controls_frame, text="Refresh Services",
                  command=self.refresh_services).pack(side='left', padx=5)
        ttk.Button(controls_frame, text="Show System Processes",
                  command=self.show_processes).pack(side='left', padx=5)
        ttk.Button(controls_frame, text="Resource Usage",
                  command=self.show_resource_usage).pack(side='left', padx=5)
        
        # Services list
        self.services_text = scrolledtext.ScrolledText(services_panel,
                                                      height=20,
                                                      bg='#000000',
                                                      fg='#ffffff',
                                                      font=('Courier', 9))
        self.services_text.pack(fill='both', expand=True, padx=10, pady=5)
        
    def create_reports_tab(self):
        """Create health reports tab"""
        reports_frame = ttk.Frame(self.notebook)
        self.notebook.add(reports_frame, text="Health Reports")
        
        # Reports panel
        reports_panel = ttk.Frame(reports_frame, style='Health.TFrame')
        reports_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(reports_panel, text="SYSTEM HEALTH REPORTS", style='Heading.TLabel').pack(pady=5)
        
        # Report controls
        report_controls = tk.Frame(reports_panel, bg=self.colors['panel'])
        report_controls.pack(fill='x', padx=10, pady=10)
        
        ttk.Button(report_controls, text="Generate Full Report",
                  command=self.generate_full_report).pack(side='left', padx=5)
        ttk.Button(report_controls, text="Quick Summary",
                  command=self.generate_quick_summary).pack(side='left', padx=5)
        ttk.Button(report_controls, text="Export Report",
                  command=self.export_health_report).pack(side='left', padx=5)
        
        # Report display
        self.report_display = scrolledtext.ScrolledText(reports_panel,
                                                       height=20,
                                                       bg='#000000',
                                                       fg='#ffffff',
                                                       font=('Courier', 10))
        self.report_display.pack(fill='both', expand=True, padx=10, pady=5)
        
    def create_status_bar(self):
        """Create bottom status bar"""
        status_frame = tk.Frame(self.root, bg=self.colors['dark_panel'], height=30)
        status_frame.pack(fill='x', side='bottom')
        status_frame.pack_propagate(False)
        
        self.status_label = tk.Label(status_frame, text="System Health Monitor Ready",
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
        """Start system health monitoring"""
        self.monitoring_active = True
        self.status_label.config(text="Health monitoring active")
        self.update_health_data()
        
    def stop_monitoring(self):
        """Stop system health monitoring"""
        self.monitoring_active = False
        self.status_label.config(text="Health monitoring stopped")
        
    def update_health_data(self):
        """Update system health data"""
        if self.monitoring_active:
            try:
                if HAS_PSUTIL:
                    # Get system metrics using psutil
                    self.health_data['cpu_usage'] = psutil.cpu_percent(interval=0.2)
                    self.health_data['memory_usage'] = psutil.virtual_memory().percent
                    root_path = os.path.abspath(os.sep)
                    self.health_data['disk_usage'] = psutil.disk_usage(root_path).percent
                    # Network usage (simplified)
                    try:
                        net_io = psutil.net_io_counters()
                        self.health_data['network_usage'] = (net_io.bytes_sent + net_io.bytes_recv) / (1024 * 1024)
                    except Exception:
                        self.health_data['network_usage'] = 0
                    # System load
                    if hasattr(os, 'getloadavg'):
                        try:
                            self.health_data['system_load'] = round(os.getloadavg()[0], 2)
                        except Exception:
                            self.health_data['system_load'] = round(self.health_data['cpu_usage'] / 100, 2)
                    else:
                        self.health_data['system_load'] = round(self.health_data['cpu_usage'] / 100, 2)
                    # Temperature (if available)
                    try:
                        if hasattr(psutil, 'sensors_temperatures'):
                            temps = psutil.sensors_temperatures()
                            if temps:
                                temp_values = []
                                for _, entries in temps.items():
                                    for entry in entries:
                                        if getattr(entry, 'current', None) is not None:
                                            temp_values.append(entry.current)
                                if temp_values:
                                    self.health_data['temperature'] = round(sum(temp_values) / len(temp_values), 1)
                                else:
                                    self.health_data['temperature'] = 0
                    except Exception:
                        self.health_data['temperature'] = 0
                    # Uptime
                    try:
                        boot_time = psutil.boot_time()
                        uptime_seconds = time.time() - boot_time
                        self.health_data['uptime'] = round(uptime_seconds / 3600, 1)
                    except Exception:
                        self.health_data['uptime'] = None
                    # Process count
                    try:
                        self.health_data['processes'] = len(psutil.pids())
                    except Exception:
                        self.health_data['processes'] = None
                else:
                    # Fallbacks without psutil (best-effort, may be limited)
                    self.health_data['cpu_usage'] = self._fallback_cpu_percent()
                    self.health_data['memory_usage'] = self._fallback_memory_percent()
                    try:
                        du = shutil.disk_usage(os.path.abspath(os.sep))
                        self.health_data['disk_usage'] = round((du.used / du.total) * 100, 1) if du.total else None
                    except Exception:
                        self.health_data['disk_usage'] = None
                    self.health_data['network_usage'] = 0
                    if hasattr(os, 'getloadavg'):
                        try:
                            self.health_data['system_load'] = round(os.getloadavg()[0], 2)
                        except Exception:
                            self.health_data['system_load'] = 0
                    else:
                        self.health_data['system_load'] = 0
                    self.health_data['temperature'] = 0
                    self.health_data['uptime'] = self._fallback_uptime_hours()
                    self.health_data['processes'] = self._fallback_process_count()
                
                # Calculate overall health score
                self.calculate_health_score()
                
                # Update UI
                self.update_metric_displays()
                
            except Exception as e:
                self.status_label.config(text=f"Error updating health data: {e}")
                
        # Schedule next update
        if self.monitoring_active:
            self.root.after(self.update_interval, self.update_health_data)
            
    def calculate_health_score(self):
        """Calculate overall system health score"""
        score = 100
        
        # CPU penalty
        if self.health_data['cpu_usage'] > 80:
            score -= 20
        elif self.health_data['cpu_usage'] > 60:
            score -= 10
            
        # Memory penalty
        if self.health_data['memory_usage'] > 90:
            score -= 25
        elif self.health_data['memory_usage'] > 75:
            score -= 15
            
        # Disk penalty
        if self.health_data['disk_usage'] > 95:
            score -= 30
        elif self.health_data['disk_usage'] > 85:
            score -= 15
            
        # Temperature penalty
        if self.health_data['temperature'] > 80:
            score -= 20
        elif self.health_data['temperature'] > 70:
            score -= 10
            
        self.health_data['overall_health'] = max(0, score)
        
    def update_metric_displays(self):
        """Update metric display widgets"""
        try:
            # Update overview metrics
            metrics = [
                ('cpu', self.health_data['cpu_usage'], '%'),
                ('memory', self.health_data['memory_usage'], '%'),
                ('disk', self.health_data['disk_usage'], '%'),
                ('network', None if self.health_data.get('network_usage') is None else round(self.health_data['network_usage'], 1), 'MB'),
                ('load', self.health_data['system_load'], ''),
                ('temp', self.health_data['temperature'], '°C'),
                ('uptime', self.health_data['uptime'], 'hrs'),
                ('processes', self.health_data['processes'], '')
            ]
            
            for name, value, unit in metrics:
                widget = getattr(self, f'metric_{name}_value', None)
                if widget:
                    if value is None:
                        display_value = 'N/A'
                    else:
                        display_value = f"{value}{unit}" if unit else str(value)
                    widget.config(text=display_value)
                    
                    # Update color based on health
                    if value is None:
                        color = self.colors['dim_text']
                    elif name == 'cpu':
                        color = self.get_health_color(value, 60, 80)
                    elif name == 'memory':
                        color = self.get_health_color(value, 75, 90)
                    elif name == 'disk':
                        color = self.get_health_color(value, 85, 95)
                    elif name == 'temp':
                        color = self.get_health_color(value, 70, 80)
                    else:
                        color = self.colors['healthy']
                        
                    widget.config(fg=color)
            
            # Update health indicator
            health_score = self.health_data['overall_health']
            self.health_score_label.config(text=f"{health_score}%")
            
            if health_score >= 80:
                self.health_indicator.config(text="HEALTHY", bg=self.colors['healthy'])
                self.health_score_label.config(fg=self.colors['healthy'])
            elif health_score >= 60:
                self.health_indicator.config(text="WARNING", bg=self.colors['warning'])
                self.health_score_label.config(fg=self.colors['warning'])
            else:
                self.health_indicator.config(text="CRITICAL", bg=self.colors['critical'])
                self.health_score_label.config(fg=self.colors['critical'])
                
            # Update real-time charts if available
            if HAS_MATPLOTLIB:
                self.update_realtime_data()
                
        except Exception as e:
            self.status_label.config(text=f"Error updating displays: {e}")
            
    def get_health_color(self, value, warning_threshold, critical_threshold):
        """Get color based on health thresholds"""
        if value is None:
            return self.colors['dim_text']
        if value >= critical_threshold:
            return self.colors['critical']
        elif value >= warning_threshold:
            return self.colors['warning']
        else:
            return self.colors['healthy']
            
    def update_realtime_data(self):
        """Update real-time chart data"""
        # Shift data arrays
        self.cpu_data = self.cpu_data[1:] + [self.health_data['cpu_usage']]
        self.mem_data = self.mem_data[1:] + [self.health_data['memory_usage']]
        self.disk_data = self.disk_data[1:] + [self.health_data['disk_usage']]
        self.net_data = self.net_data[1:] + [self.health_data['network_usage']]
        
    def update_realtime_charts(self):
        """Update real-time monitoring charts"""
        if HAS_MATPLOTLIB and self.monitoring_active:
            try:
                # Clear previous plots
                for ax in [self.cpu_ax, self.mem_ax, self.disk_ax, self.net_ax]:
                    ax.clear()
                    
                # Plot CPU usage
                self.cpu_ax.plot(self.time_data, self.cpu_data, color=self.colors['info'], linewidth=2)
                self.cpu_ax.set_title('CPU Usage (%)', color=self.colors['text'])
                self.cpu_ax.set_ylim(0, 100)
                self.cpu_ax.grid(True, alpha=0.3)
                
                # Plot Memory usage
                self.mem_ax.plot(self.time_data, self.mem_data, color=self.colors['warning'], linewidth=2)
                self.mem_ax.set_title('Memory Usage (%)', color=self.colors['text'])
                self.mem_ax.set_ylim(0, 100)
                self.mem_ax.grid(True, alpha=0.3)
                
                # Plot Disk usage
                self.disk_ax.plot(self.time_data, self.disk_data, color=self.colors['critical'], linewidth=2)
                self.disk_ax.set_title('Disk Usage (%)', color=self.colors['text'])
                self.disk_ax.set_ylim(0, 100)
                self.disk_ax.grid(True, alpha=0.3)
                
                # Plot Network usage
                self.net_ax.plot(self.time_data, self.net_data, color=self.colors['healthy'], linewidth=2)
                self.net_ax.set_title('Network Usage (MB)', color=self.colors['text'])
                self.net_ax.grid(True, alpha=0.3)
                
                # Update canvas
                self.realtime_canvas.draw()
                
            except Exception as e:
                self.status_label.config(text=f"Chart update error: {e}")
                
        # Schedule next update
        if self.monitoring_active:
            self.root.after(5000, self.update_realtime_charts)
            
    def update_performance_charts(self):
        """Update performance analysis charts"""
        if HAS_MATPLOTLIB:
            try:
                # Clear previous plots
                for ax in [self.load_ax, self.proc_ax, self.io_ax, self.temp_ax]:
                    ax.clear()
                    
                # System load over time
                load_history = [self.health_data['system_load']] * 24  # Simulate 24 hours
                hours = list(range(24))
                self.load_ax.plot(hours, load_history, color=self.colors['info'], linewidth=2)
                self.load_ax.set_title('System Load (24h)', color=self.colors['text'])
                self.load_ax.set_xlabel('Hours', color=self.colors['text'])
                self.load_ax.grid(True, alpha=0.3)
                
                # Process distribution
                processes = ['System', 'User', 'Background', 'Services']
                proc_counts = [25, 40, 20, 15]  # Simulated data
                colors = [self.colors['critical'], self.colors['warning'], self.colors['info'], self.colors['healthy']]
                self.proc_ax.pie(proc_counts, labels=processes, colors=colors, autopct='%1.1f%%')
                self.proc_ax.set_title('Process Distribution', color=self.colors['text'])
                
                # I/O Operations
                io_types = ['Read', 'Write', 'Network']
                io_values = [60, 40, 30]  # Simulated data
                self.io_ax.bar(io_types, io_values, color=[self.colors['healthy'], self.colors['warning'], self.colors['info']])
                self.io_ax.set_title('I/O Operations', color=self.colors['text'])
                self.io_ax.set_ylabel('Operations/sec', color=self.colors['text'])
                
                # Temperature history
                temp_history = [self.health_data['temperature']] * 12  # Simulate 12 hours
                temp_hours = list(range(12))
                self.temp_ax.plot(temp_hours, temp_history, color=self.colors['critical'], linewidth=2)
                self.temp_ax.set_title('Temperature (12h)', color=self.colors['text'])
                self.temp_ax.set_xlabel('Hours', color=self.colors['text'])
                self.temp_ax.set_ylabel('°C', color=self.colors['text'])
                self.temp_ax.grid(True, alpha=0.3)
                
                # Update canvas
                self.perf_canvas.draw()
                
            except Exception as e:
                self.status_label.config(text=f"Performance chart error: {e}")
                
    def update_time(self):
        """Update time display"""
        current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.time_label.config(text=current_time)
        self.root.after(1000, self.update_time)
        
    # Event handlers for all diagnostic functions
    def quick_health_check(self):
        """Run quick health check"""
        self.status_label.config(text="Running quick health check...")
        threading.Thread(target=self._quick_health_check_worker, daemon=True).start()
        
    def _quick_health_check_worker(self):
        """Background worker for quick health check"""
        try:
            # Prefer non-interactive full check flag when available
            stdout, stderr, rc = self._run_script_cross_platform('health-check.sh', ['--full'], timeout=120)
            output = stdout if stdout else stderr
            self.root.after(0, self._health_check_complete, output)
        except Exception as e:
            self.root.after(0, self._health_check_error, str(e))
            
    def _health_check_complete(self, output):
        """Handle health check completion"""
        self.status_label.config(text="Quick health check completed")
        self.diagnostic_output.insert('end', f"\n=== QUICK HEALTH CHECK ===\n{output}\n")
        self.diagnostic_output.see('end')
        
    def _health_check_error(self, error):
        """Handle health check error"""
        self.status_label.config(text="Health check failed")
        self.diagnostic_output.insert('end', f"\n=== HEALTH CHECK ERROR ===\n{error}\n")
        self.diagnostic_output.see('end')
        
    def deep_system_scan(self):
        """Run deep system scan"""
        if messagebox.askyesno("Deep System Scan", 
                              "Run comprehensive system scan?\nThis may take several minutes."):
            self.status_label.config(text="Running deep system scan...")
            threading.Thread(target=self._deep_scan_worker, daemon=True).start()
            
    def _deep_scan_worker(self):
        """Background worker for deep system scan"""
        try:
            # Execute the comprehensive run in one go using the CLI flag
            stdout, stderr, rc = self._run_script_cross_platform('health-check.sh', ['--full'], timeout=300)
            output = stdout if stdout else stderr
            self.root.after(0, self._deep_scan_progress, "Comprehensive Scan", output)
            self.root.after(0, self._deep_scan_complete)
        except Exception as e:
            self.root.after(0, self._deep_scan_error, str(e))

    # ---------- Cross-platform helpers and fallbacks ----------
    def _run_script_cross_platform(self, script_name, args=None, timeout=60):
        """Run a script across OSs safely. Returns (stdout, stderr, returncode).
        This will try multiple likely roots and set cwd to the project root
        (containing index.html) so that health-check.sh environment checks pass.
        """
        args = args or []
        # Candidate roots to locate script and choose cwd
        here = os.path.dirname(os.path.abspath(__file__))
        candidates = [
            here,
            os.path.normpath(os.path.join(here, '..')),
            os.path.normpath(os.path.join(here, '..', 'kotisivu')),
            os.path.normpath(os.path.join(here, 'downloads')),
            os.path.normpath(os.path.join(here, 'lataukset')),
        ]
        script_path = None
        cwd_root = None
        for root in candidates:
            try:
                cand = os.path.join(root, script_name)
                if os.path.isfile(cand):
                    script_path = cand
                # Prefer a directory with index.html as cwd
                if os.path.isfile(os.path.join(root, 'index.html')) and cwd_root is None:
                    cwd_root = root
            except Exception:
                continue
        # Fallbacks
        if script_path is None:
            # Last resort: assume alongside current file
            script_path = os.path.join(here, script_name)
        if cwd_root is None:
            # If no index.html found, use directory containing script
            cwd_root = os.path.dirname(script_path)
        system = platform.system()
        env = os.environ.copy()
        # Provide simple stdin automation for interactive scripts
        input_data = None
        if script_name == 'health-check.sh':
            # After completing a flagged action, script prompts to return to menu and then awaits a menu choice.
            # Send Enter to continue and 0 to exit cleanly.
            input_data = "\n0\n"
        try:
            if system == 'Windows':
                # Prefer PowerShell variant for security monitor if available
                if script_name == 'monitor_security.sh':
                    ps1 = os.path.join(SCRIPT_DIR, 'monitor_security.ps1')
                    if os.path.exists(ps1):
                        cmd = ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ps1] + args
                        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                              universal_newlines=True, timeout=timeout, env=env)
                        return proc.stdout, proc.stderr, proc.returncode
                # Try bash from PATH (Git Bash) if .sh
                if script_name.endswith('.sh'):
                    bash_exe = shutil.which('bash')
                    if bash_exe:
                        cmd = [bash_exe, script_path] + args
                        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                              universal_newlines=True, timeout=timeout, env=env)
                        return proc.stdout, proc.stderr, proc.returncode
                    # Try WSL
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
                # POSIX systems
                if script_name.endswith('.sh'):
                    cmd = ['bash', script_path] + args
                elif script_name.endswith('.py'):
                    cmd = [sys.executable or 'python3', script_path] + args
                else:
                    cmd = [script_path] + args
                proc = subprocess.run(cmd, cwd=cwd_root, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      universal_newlines=True, timeout=timeout, env=env, input=input_data)
                return proc.stdout, proc.stderr, proc.returncode
        except Exception as e:
            return '', f"Execution error: {e}", 1

    def _fallback_cpu_percent(self):
        try:
            if hasattr(os, 'getloadavg'):
                load1 = os.getloadavg()[0]
                cpus = os.cpu_count() or 1
                return max(0, min(100, round((load1 / cpus) * 100, 1)))
        except Exception:
            pass
        return None

    def _fallback_memory_percent(self):
        try:
            if os.path.exists('/proc/meminfo'):
                meminfo = {}
                with open('/proc/meminfo') as f:
                    for line in f:
                        parts = line.split(':')
                        if len(parts) >= 2:
                            key = parts[0].strip()
                            val = parts[1].strip().split()[0]
                            meminfo[key] = float(val)
                total = meminfo.get('MemTotal')
                available = meminfo.get('MemAvailable') or (meminfo.get('MemFree') or 0)
                if total:
                    used = total - available
                    return round((used / total) * 100, 1)
        except Exception:
            pass
        return None

    def _fallback_uptime_hours(self):
        try:
            if os.path.exists('/proc/uptime'):
                with open('/proc/uptime') as f:
                    seconds = float(f.read().split()[0])
                    return round(seconds / 3600, 1)
        except Exception:
            pass
        return None

    def _fallback_process_count(self):
        try:
            proc_dir = '/proc'
            if os.path.isdir(proc_dir):
                return sum(1 for name in os.listdir(proc_dir) if name.isdigit())
        except Exception:
            pass
        return None
            
    def _deep_scan_progress(self, module, output):
        """Handle deep scan progress update"""
        self.diagnostic_output.insert('end', f"\n=== {module} ===\n{output}\n")
        self.diagnostic_output.see('end')
        
    def _deep_scan_complete(self):
        """Handle deep scan completion"""
        self.status_label.config(text="Deep system scan completed")
        messagebox.showinfo("Scan Complete", "Deep system scan has been completed successfully!")
        
    def _deep_scan_error(self, error):
        """Handle deep scan error"""
        self.status_label.config(text="Deep scan failed")
        messagebox.showerror("Scan Error", f"Deep system scan failed: {error}")
        
    def resource_analysis(self):
        """Run resource usage analysis"""
        self.status_label.config(text="Analyzing resource usage...")
        # Safe accessors for possibly-None values
        def pct(v):
            return 'N/A' if v is None else f"{v}%"
        def val(v, unit=''):
            return 'N/A' if v is None else f"{v}{unit}"

        cpu = self.health_data.get('cpu_usage')
        mem = self.health_data.get('memory_usage')
        disk = self.health_data.get('disk_usage')
        load = self.health_data.get('system_load')
        uptime = self.health_data.get('uptime')
        procs = self.health_data.get('processes')
        temp = self.health_data.get('temperature')

        analysis = f"""
RESOURCE USAGE ANALYSIS
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

CPU ANALYSIS:
- Current Usage: {pct(cpu)}
- System Load: {val(load)}
- Status: {('Critical' if (cpu is not None and cpu > 80) else 'Normal')}

MEMORY ANALYSIS:
- Used: {pct(mem)}
- Available: {('N/A' if mem is None else f"{round(100 - mem, 1)}%")}
- Status: {('Critical' if (mem is not None and mem > 90) else 'Normal')}

DISK ANALYSIS:
- Used: {pct(disk)}
- Available: {('N/A' if disk is None else f"{round(100 - disk, 1)}%")}
- Status: {('Critical' if (disk is not None and disk > 95) else 'Normal')}

PROCESS ANALYSIS:
- Total Processes: {val(procs)}
- System Uptime: {val(uptime, ' hours')}

RECOMMENDATIONS:
"""
        
        if cpu is not None and cpu > 80:
            analysis += "- High CPU usage detected - check running processes\n"
        if mem is not None and mem > 90:
            analysis += "- High memory usage - consider closing applications\n"
        if disk is not None and disk > 95:
            analysis += "- Disk space critical - free up space immediately\n"
        if temp is not None and temp > 80:
            analysis += "- High temperature detected - check cooling system\n"
        
        if (self.health_data.get('overall_health') or 0) >= 80:
            analysis += "- System is operating normally\n"
            
        self.diagnostic_output.insert('end', analysis)
        self.diagnostic_output.see('end')
        
    def generate_health_report(self):
        """Generate comprehensive health report"""
        file_path = filedialog.asksaveasfilename(
            title="Save Health Report",
            defaultextension=".txt",
            filetypes=[("Text Files", "*.txt"), ("HTML Files", "*.html")]
        )
        
        if file_path:
            self.status_label.config(text="Generating health report...")
            threading.Thread(target=self._generate_report_worker, args=(file_path,), daemon=True).start()
            
    def _generate_report_worker(self, file_path):
        """Background worker for report generation"""
        try:
            report_content = f"""XXMXLI SYSTEM HEALTH REPORT
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Platform: {platform.system()} {platform.release()}

OVERALL HEALTH SCORE: {self.health_data['overall_health']}%

SYSTEM METRICS:
- CPU Usage: {self.health_data['cpu_usage']}%
- Memory Usage: {self.health_data['memory_usage']}%
- Disk Usage: {self.health_data['disk_usage']}%
- Network Usage: {self.health_data['network_usage']} MB
- System Load: {self.health_data['system_load']}
- Temperature: {self.health_data['temperature']}°C
- Uptime: {self.health_data['uptime']} hours
- Running Processes: {self.health_data['processes']}

HEALTH STATUS:
"""
            
            if self.health_data['overall_health'] >= 80:
                report_content += "✓ System is healthy and operating normally\n"
            elif self.health_data['overall_health'] >= 60:
                report_content += "⚠ System has minor issues that should be addressed\n"
            else:
                report_content += "✗ System has critical issues requiring immediate attention\n"
                
            report_content += f"""
DETAILED ANALYSIS:
- CPU: {'Optimal' if self.health_data['cpu_usage'] < 60 else 'High Usage'}
- Memory: {'Optimal' if self.health_data['memory_usage'] < 75 else 'High Usage'}
- Disk: {'Optimal' if self.health_data['disk_usage'] < 85 else 'Space Warning'}
- Temperature: {'Normal' if self.health_data['temperature'] < 70 else 'High Temperature'}

RECOMMENDATIONS:
- Monitor resource usage regularly
- Keep system updated and secure
- Maintain adequate free disk space
- Ensure proper cooling and ventilation
"""
            
            with open(file_path, 'w') as f:
                f.write(report_content)
                
            self.root.after(0, self._report_generation_complete, file_path)
        except Exception as e:
            self.root.after(0, self._report_generation_error, str(e))
            
    def _report_generation_complete(self, file_path):
        """Handle report generation completion"""
        self.status_label.config(text="Health report generated successfully")
        messagebox.showinfo("Report Generated", f"Health report saved to:\n{file_path}")
        
    def _report_generation_error(self, error):
        """Handle report generation error"""
        self.status_label.config(text="Report generation failed")
        messagebox.showerror("Generation Error", f"Failed to generate report: {error}")
        
    # Placeholder implementations for diagnostic modules
    def run_cpu_diagnostics(self):
        """Run CPU diagnostics"""
        self.diagnostic_output.insert('end', f"\n=== CPU DIAGNOSTICS ===\nRunning CPU diagnostics...\n")
        self.diagnostic_output.see('end')
        
    def run_memory_diagnostics(self):
        """Run memory diagnostics"""
        self.diagnostic_output.insert('end', f"\n=== MEMORY DIAGNOSTICS ===\nRunning memory diagnostics...\n")
        self.diagnostic_output.see('end')
        
    def run_disk_diagnostics(self):
        """Run disk diagnostics"""
        self.diagnostic_output.insert('end', f"\n=== DISK DIAGNOSTICS ===\nRunning disk diagnostics...\n")
        self.diagnostic_output.see('end')
        
    def run_network_diagnostics(self):
        """Run network diagnostics"""
        self.diagnostic_output.insert('end', f"\n=== NETWORK DIAGNOSTICS ===\nRunning network diagnostics...\n")
        self.diagnostic_output.see('end')
        
    def run_security_diagnostics(self):
        """Run security diagnostics"""
        self.diagnostic_output.insert('end', f"\n=== SECURITY DIAGNOSTICS ===\nRunning security diagnostics...\n")
        self.diagnostic_output.see('end')
        
    def run_service_diagnostics(self):
        """Run service diagnostics"""
        self.diagnostic_output.insert('end', f"\n=== SERVICE DIAGNOSTICS ===\nRunning service diagnostics...\n")
        self.diagnostic_output.see('end')
        
    def refresh_services(self):
        """Refresh services list"""
        self.services_text.delete('1.0', 'end')
        self.services_text.insert('end', "Refreshing services list...\n")
        
    def show_processes(self):
        """Show system processes"""
        self.services_text.delete('1.0', 'end')
        self.services_text.insert('end', "Loading system processes...\n")
        
    def show_resource_usage(self):
        """Show detailed resource usage"""
        self.services_text.delete('1.0', 'end')
        self.services_text.insert('end', "Loading resource usage details...\n")
        
    def generate_full_report(self):
        """Generate full health report"""
        self.report_display.delete('1.0', 'end')
        self.report_display.insert('end', "Generating full system health report...\n")
        
    def generate_quick_summary(self):
        """Generate quick health summary"""
        summary = f"""QUICK HEALTH SUMMARY
Generated: {datetime.now().strftime('%H:%M:%S')}

Overall Health: {self.health_data['overall_health']}%
CPU: {self.health_data['cpu_usage']}%
Memory: {self.health_data['memory_usage']}%
Disk: {self.health_data['disk_usage']}%

Status: {'HEALTHY' if self.health_data['overall_health'] >= 80 else 'NEEDS ATTENTION'}
"""
        
        self.report_display.delete('1.0', 'end')
        self.report_display.insert('end', summary)
        
    def export_health_report(self):
        """Export health report to file"""
        file_path = filedialog.asksaveasfilename(
            title="Export Health Report",
            defaultextension=".txt",
            filetypes=[("Text Files", "*.txt")]
        )
        
        if file_path:
            try:
                content = self.report_display.get('1.0', 'end')
                with open(file_path, 'w') as f:
                    f.write(content)
                messagebox.showinfo("Export Complete", f"Report exported to {file_path}")
            except Exception as e:
                messagebox.showerror("Export Error", f"Failed to export report: {e}")
                
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
    app = HealthCheckGUI()
    app.run()

if __name__ == "__main__":
    main()
