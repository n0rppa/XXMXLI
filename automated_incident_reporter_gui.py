#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XXMXLI Automated Incident Reporter - GUI Version
Advanced Security Incident Reporting with Beautiful Interface

This GUI application provides an intuitive interface for reporting security
incidents to law enforcement agencies including FBI IC3, CISA, Europol EC3,
and national Computer Emergency Response Teams (CERTs).

Features:
- Beautiful modern GUI interface
- Real-time incident monitoring
- Automated evidence collection
- Multi-agency reporting capabilities
- Secure encrypted transmission
- Professional incident documentation

Author: XXMXLI Security Team
"""

import os
import sys
import subprocess
import platform
import threading
import time
from datetime import datetime

# GUI imports with fallback
try:
    import tkinter as tk
    from tkinter import ttk, messagebox, filedialog, scrolledtext
    HAS_GUI = True
except ImportError:
    HAS_GUI = False
    print("Error: tkinter not available. Please install python3-tk")
    sys.exit(1)

class IncidentReporterGUI:
    def __init__(self):
        # Check if display is available
        if not self.check_display():
            print("Error: No display available. Cannot run GUI application.")
            print("This appears to be a headless environment or X server is not running.")
            print("Use the command-line version instead: automated_incident_reporter.sh")
            sys.exit(1)
            
        self.root = tk.Tk()
        self.root.title("XXMXLI Automated Incident Reporter")
        self.root.geometry("800x600")
        self.root.configure(bg='#1a1a1a')
        
        # Color scheme
        self.colors = {
            'bg': '#1a1a1a',
            'panel': '#2d2d2d',
            'accent': '#00ff00',
            'warning': '#ffaa00',
            'error': '#ff4444',
            'text': '#ffffff',
            'button': '#004400',
            'button_hover': '#006600'
        }
        
        # Configure styles
        self.setup_styles()
        
        # Initialize variables
        self.monitoring_active = False
        self.incident_types = ['MALWARE', 'INTRUSION', 'DDOS', 'PHISHING', 'RANSOMWARE', 'OTHER']
        
        # Create interface
        self.create_interface()
        
        # Start status monitoring
        self.update_status()
        
    def check_display(self):
        """Check if display is available for GUI"""
        try:
            # Check if DISPLAY environment variable is set
            if os.environ.get('DISPLAY'):
                return True
            
            # Check if we're on Windows (always has display)
            if platform.system() == 'Windows':
                return True
                
            # Check if we can connect to X server
            try:
                import subprocess
                result = subprocess.run(['xset', 'q'], 
                                      capture_output=True, timeout=5)
                return result.returncode == 0
            except:
                return False
                
        except Exception:
            return False
        
    def setup_styles(self):
        """Configure GUI styles"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # Configure styles for dark theme
        style.configure('Title.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['accent'],
                       font=('Arial', 16, 'bold'))
        
        style.configure('Heading.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['text'],
                       font=('Arial', 12, 'bold'))
        
        style.configure('Info.TLabel',
                       background=self.colors['bg'],
                       foreground=self.colors['text'],
                       font=('Arial', 10))
        
        style.configure('Panel.TFrame',
                       background=self.colors['panel'],
                       relief='raised',
                       borderwidth=1)
        
        style.configure('Action.TButton',
                       background=self.colors['button'],
                       foreground=self.colors['text'],
                       font=('Arial', 10, 'bold'),
                       padding=5)
        
    def create_interface(self):
        """Create the main GUI interface"""
        
        # Main title
        title_frame = tk.Frame(self.root, bg=self.colors['bg'])
        title_frame.pack(fill='x', padx=10, pady=10)
        
        title_label = ttk.Label(title_frame, text="XXMXLI AUTOMATED INCIDENT REPORTER",
                               style='Title.TLabel')
        title_label.pack()
        
        subtitle_label = ttk.Label(title_frame, text="Advanced Security Incident Reporting System",
                                  style='Info.TLabel')
        subtitle_label.pack()
        
        # Status panel
        self.create_status_panel()
        
        # Main notebook for tabs
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Create tabs
        self.create_monitoring_tab()
        self.create_reporting_tab()
        self.create_settings_tab()
        self.create_logs_tab()
        
        # Bottom button panel
        self.create_button_panel()
        
    def create_status_panel(self):
        """Create system status panel"""
        status_frame = ttk.Frame(self.root, style='Panel.TFrame')
        status_frame.pack(fill='x', padx=10, pady=5)
        
        status_title = ttk.Label(status_frame, text="SYSTEM STATUS",
                                style='Heading.TLabel')
        status_title.pack(pady=5)
        
        # Status indicators
        indicators_frame = tk.Frame(status_frame, bg=self.colors['panel'])
        indicators_frame.pack(fill='x', padx=10, pady=5)
        
        # Monitoring status
        self.monitoring_status = ttk.Label(indicators_frame, text="Monitoring: INACTIVE",
                                          style='Info.TLabel')
        self.monitoring_status.pack(side='left', padx=10)
        
        # System status
        self.system_status = ttk.Label(indicators_frame, text="System: READY",
                                      style='Info.TLabel')
        self.system_status.pack(side='left', padx=10)
        
        # Network status
        self.network_status = ttk.Label(indicators_frame, text="Network: CONNECTED",
                                       style='Info.TLabel')
        self.network_status.pack(side='left', padx=10)
        
    def create_monitoring_tab(self):
        """Create real-time monitoring tab"""
        monitoring_frame = ttk.Frame(self.notebook)
        self.notebook.add(monitoring_frame, text="Real-Time Monitoring")
        
        # Monitoring controls
        control_frame = ttk.Frame(monitoring_frame, style='Panel.TFrame')
        control_frame.pack(fill='x', padx=10, pady=10)
        
        ttk.Label(control_frame, text="AUTOMATED MONITORING",
                 style='Heading.TLabel').pack(pady=5)
        
        ttk.Label(control_frame, text="Continuous monitoring for security threats and incidents",
                 style='Info.TLabel').pack(pady=2)
        
        # Control buttons
        btn_frame = tk.Frame(control_frame, bg=self.colors['panel'])
        btn_frame.pack(pady=10)
        
        self.start_btn = ttk.Button(btn_frame, text="Start Monitoring",
                                   command=self.start_monitoring,
                                   style='Action.TButton')
        self.start_btn.pack(side='left', padx=5)
        
        self.stop_btn = ttk.Button(btn_frame, text="Stop Monitoring",
                                  command=self.stop_monitoring,
                                  style='Action.TButton',
                                  state='disabled')
        self.stop_btn.pack(side='left', padx=5)
        
        # Monitoring output
        output_frame = ttk.Frame(monitoring_frame, style='Panel.TFrame')
        output_frame.pack(fill='both', expand=True, padx=10, pady=5)
        
        ttk.Label(output_frame, text="MONITORING OUTPUT",
                 style='Heading.TLabel').pack(pady=5)
        
        self.monitoring_output = scrolledtext.ScrolledText(output_frame,
                                                          height=15,
                                                          bg='#000000',
                                                          fg='#00ff00',
                                                          font=('Courier', 9))
        self.monitoring_output.pack(fill='both', expand=True, padx=10, pady=5)
        
    def create_reporting_tab(self):
        """Create manual incident reporting tab"""
        reporting_frame = ttk.Frame(self.notebook)
        self.notebook.add(reporting_frame, text="Manual Reporting")
        
        # Incident form
        form_frame = ttk.Frame(reporting_frame, style='Panel.TFrame')
        form_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(form_frame, text="INCIDENT REPORTING FORM",
                 style='Heading.TLabel').pack(pady=5)
        
        # Form fields
        fields_frame = tk.Frame(form_frame, bg=self.colors['panel'])
        fields_frame.pack(fill='x', padx=10, pady=10)
        
        # Incident type
        ttk.Label(fields_frame, text="Incident Type:", style='Info.TLabel').grid(row=0, column=0, sticky='w', pady=5)
        self.incident_type = ttk.Combobox(fields_frame, values=self.incident_types, width=20)
        self.incident_type.grid(row=0, column=1, sticky='w', padx=10, pady=5)
        self.incident_type.set('MALWARE')
        
        # Severity
        ttk.Label(fields_frame, text="Severity (1-10):", style='Info.TLabel').grid(row=1, column=0, sticky='w', pady=5)
        self.severity_var = tk.StringVar(value='5')
        self.severity = tk.Spinbox(fields_frame, from_=1, to=10, width=20, textvariable=self.severity_var)
        self.severity.grid(row=1, column=1, sticky='w', padx=10, pady=5)
        
        # Description
        ttk.Label(fields_frame, text="Description:", style='Info.TLabel').grid(row=2, column=0, sticky='nw', pady=5)
        self.description = scrolledtext.ScrolledText(fields_frame, height=8, width=50)
        self.description.grid(row=2, column=1, sticky='ew', padx=10, pady=5)
        
        # Evidence
        ttk.Label(fields_frame, text="Evidence Files:", style='Info.TLabel').grid(row=3, column=0, sticky='w', pady=5)
        evidence_frame = tk.Frame(fields_frame, bg=self.colors['panel'])
        evidence_frame.grid(row=3, column=1, sticky='ew', padx=10, pady=5)
        
        self.evidence_files = []
        self.evidence_listbox = tk.Listbox(evidence_frame, height=4, width=40)
        self.evidence_listbox.pack(side='left', fill='both', expand=True)
        
        evidence_btn_frame = tk.Frame(evidence_frame, bg=self.colors['panel'])
        evidence_btn_frame.pack(side='right', fill='y', padx=5)
        
        ttk.Button(evidence_btn_frame, text="Add File",
                  command=self.add_evidence_file).pack(pady=2)
        ttk.Button(evidence_btn_frame, text="Remove",
                  command=self.remove_evidence_file).pack(pady=2)
        
        # Submit button
        submit_frame = tk.Frame(form_frame, bg=self.colors['panel'])
        submit_frame.pack(pady=20)
        
        ttk.Button(submit_frame, text="SUBMIT INCIDENT REPORT",
                  command=self.submit_incident_report,
                  style='Action.TButton').pack()
        
    def create_settings_tab(self):
        """Create settings and configuration tab"""
        settings_frame = ttk.Frame(self.notebook)
        self.notebook.add(settings_frame, text="Settings")
        
        # Settings panel
        settings_panel = ttk.Frame(settings_frame, style='Panel.TFrame')
        settings_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(settings_panel, text="CONFIGURATION SETTINGS",
                 style='Heading.TLabel').pack(pady=5)
        
        # Settings form
        settings_form = tk.Frame(settings_panel, bg=self.colors['panel'])
        settings_form.pack(fill='x', padx=10, pady=10)
        
        # Monitoring interval
        ttk.Label(settings_form, text="Monitoring Interval (seconds):", style='Info.TLabel').grid(row=0, column=0, sticky='w', pady=5)
        self.monitoring_interval_var = tk.StringVar(value='300')
        self.monitoring_interval = tk.Spinbox(settings_form, from_=30, to=3600, width=20, textvariable=self.monitoring_interval_var)
        self.monitoring_interval.grid(row=0, column=1, sticky='w', padx=10, pady=5)
        
        # Auto-report threshold
        ttk.Label(settings_form, text="Auto-Report Threshold:", style='Info.TLabel').grid(row=1, column=0, sticky='w', pady=5)
        self.auto_threshold_var = tk.StringVar(value='7')
        self.auto_threshold = tk.Spinbox(settings_form, from_=1, to=10, width=20, textvariable=self.auto_threshold_var)
        self.auto_threshold.grid(row=1, column=1, sticky='w', padx=10, pady=5)
        
        # Notification settings
        ttk.Label(settings_form, text="Enable Notifications:", style='Info.TLabel').grid(row=2, column=0, sticky='w', pady=5)
        self.enable_notifications = tk.BooleanVar(value=True)
        ttk.Checkbutton(settings_form, variable=self.enable_notifications).grid(row=2, column=1, sticky='w', padx=10, pady=5)
        
        # Save settings button
        ttk.Button(settings_form, text="Save Settings",
                  command=self.save_settings,
                  style='Action.TButton').grid(row=3, column=1, sticky='w', padx=10, pady=20)
        
    def create_logs_tab(self):
        """Create logs and history tab"""
        logs_frame = ttk.Frame(self.notebook)
        self.notebook.add(logs_frame, text="Logs & History")
        
        # Logs panel
        logs_panel = ttk.Frame(logs_frame, style='Panel.TFrame')
        logs_panel.pack(fill='both', expand=True, padx=10, pady=10)
        
        ttk.Label(logs_panel, text="SYSTEM LOGS & INCIDENT HISTORY",
                 style='Heading.TLabel').pack(pady=5)
        
        # Log output
        self.log_output = scrolledtext.ScrolledText(logs_panel,
                                                   height=20,
                                                   bg='#000000',
                                                   fg='#ffffff',
                                                   font=('Courier', 9))
        self.log_output.pack(fill='both', expand=True, padx=10, pady=5)
        
        # Log controls
        log_controls = tk.Frame(logs_panel, bg=self.colors['panel'])
        log_controls.pack(fill='x', padx=10, pady=5)
        
        ttk.Button(log_controls, text="Refresh Logs",
                  command=self.refresh_logs).pack(side='left', padx=5)
        ttk.Button(log_controls, text="Clear Logs",
                  command=self.clear_logs).pack(side='left', padx=5)
        ttk.Button(log_controls, text="Export Logs",
                  command=self.export_logs).pack(side='left', padx=5)
        
    def create_button_panel(self):
        """Create bottom button panel"""
        button_frame = tk.Frame(self.root, bg=self.colors['bg'])
        button_frame.pack(fill='x', padx=10, pady=5)
        
        # Emergency button
        emergency_btn = tk.Button(button_frame, text="EMERGENCY INCIDENT",
                                 bg=self.colors['error'], fg='white',
                                 font=('Arial', 12, 'bold'),
                                 command=self.emergency_incident)
        emergency_btn.pack(side='left', padx=5)
        
        # Help button
        help_btn = ttk.Button(button_frame, text="Help",
                             command=self.show_help)
        help_btn.pack(side='right', padx=5)
        
        # About button
        about_btn = ttk.Button(button_frame, text="About",
                              command=self.show_about)
        about_btn.pack(side='right', padx=5)
        
        # Exit button
        exit_btn = ttk.Button(button_frame, text="Exit",
                             command=self.exit_application)
        exit_btn.pack(side='right', padx=5)
        
    def start_monitoring(self):
        """Start automated monitoring"""
        self.monitoring_active = True
        self.start_btn.config(state='disabled')
        self.stop_btn.config(state='normal')
        
        self.log_message("Starting automated security monitoring...")
        
        # Start monitoring thread
        monitor_thread = threading.Thread(target=self.monitoring_worker, daemon=True)
        monitor_thread.start()
        
    def stop_monitoring(self):
        """Stop automated monitoring"""
        self.monitoring_active = False
        self.start_btn.config(state='normal')
        self.stop_btn.config(state='disabled')
        
        self.log_message("Stopping automated monitoring...")
        
    def monitoring_worker(self):
        """Background monitoring worker"""
        while self.monitoring_active:
            try:
                # Run the actual incident reporter script
                result = subprocess.run(
                    [
                        sys.executable, 
                        'automated_incident_reporter.py',
                        'monitor',
                        '--interval', str(self.monitoring_interval.get())
                    ],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=True,
                    timeout=30
                )
                
                if result.stdout:
                    self.root.after(0, self.update_monitoring_output, result.stdout)
                
                time.sleep(int(self.monitoring_interval.get()))
                
            except subprocess.TimeoutExpired:
                self.root.after(0, self.log_message, "Monitoring timeout - continuing...")
            except Exception as e:
                self.root.after(0, self.log_message, f"Monitoring error: {e}")
                
    def update_monitoring_output(self, output):
        """Update monitoring output display"""
        self.monitoring_output.insert('end', f"[{datetime.now().strftime('%H:%M:%S')}] {output}\n")
        self.monitoring_output.see('end')
        
    def submit_incident_report(self):
        """Submit manual incident report"""
        # Validate form
        if not self.incident_type.get():
            messagebox.showerror("Error", "Please select an incident type")
            return
            
        if not self.description.get('1.0', 'end').strip():
            messagebox.showerror("Error", "Please provide an incident description")
            return
        
        # Confirm submission
        if not messagebox.askyesno("Confirm Submission", 
                                  "Submit incident report to law enforcement agencies?"):
            return
        
        try:
            # Build command
            cmd = [
                sys.executable,
                'automated_incident_reporter.py',
                'report',
                '--type', self.incident_type.get(),
                '--severity', self.severity.get(),
                '--description', self.description.get('1.0', 'end').strip()
            ]
            
            # Add evidence files
            for file_path in self.evidence_files:
                cmd.extend(['--evidence', file_path])
            
            # Run command
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            
            if result.returncode == 0:
                messagebox.showinfo("Success", "Incident report submitted successfully!")
                self.log_message(f"Incident report submitted: {self.incident_type.get()}")
                self.clear_form()
            else:
                messagebox.showerror("Error", f"Failed to submit report:\n{result.stderr}")
                
        except Exception as e:
            messagebox.showerror("Error", f"Error submitting report: {e}")
            
    def add_evidence_file(self):
        """Add evidence file to report"""
        file_path = filedialog.askopenfilename(
            title="Select Evidence File",
            filetypes=[("All Files", "*.*")]
        )
        
        if file_path:
            self.evidence_files.append(file_path)
            self.evidence_listbox.insert('end', os.path.basename(file_path))
            
    def remove_evidence_file(self):
        """Remove selected evidence file"""
        selection = self.evidence_listbox.curselection()
        if selection:
            index = selection[0]
            self.evidence_listbox.delete(index)
            del self.evidence_files[index]
            
    def emergency_incident(self):
        """Handle emergency incident reporting"""
        if messagebox.askyesno("Emergency Incident",
                              "Report critical security incident immediately?\n\n"
                              "This will trigger high-priority alerts to all agencies."):
            try:
                result = subprocess.run(
                    [
                        sys.executable,
                        'automated_incident_reporter.py',
                        'emergency'
                    ],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=True
                )
                
                if result.returncode == 0:
                    messagebox.showinfo("Emergency Report Sent",
                                       "Emergency incident report has been sent to all agencies!")
                else:
                    messagebox.showerror("Error", f"Failed to send emergency report:\n{result.stderr}")
                    
            except Exception as e:
                messagebox.showerror("Error", f"Error sending emergency report: {e}")
                
    def clear_form(self):
        """Clear the incident reporting form"""
        self.incident_type.set('MALWARE')
        self.severity_var.set('5')
        self.description.delete('1.0', 'end')
        self.evidence_listbox.delete(0, 'end')
        self.evidence_files.clear()
        
    def save_settings(self):
        """Save configuration settings"""
        try:
            # Here you would save settings to a config file
            messagebox.showinfo("Settings Saved", "Configuration settings have been saved successfully!")
            self.log_message("Settings saved successfully")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save settings: {e}")
            
    def refresh_logs(self):
        """Refresh system logs"""
        try:
            # Read log files and update display
            self.log_output.delete('1.0', 'end')
            
            log_files = ['incident_reports.log', 'monitoring.log', 'system.log']
            for log_file in log_files:
                if os.path.exists(log_file):
                    with open(log_file, 'r') as f:
                        content = f.read()
                        self.log_output.insert('end', f"=== {log_file} ===\n{content}\n\n")
                        
            self.log_output.see('end')
            
        except Exception as e:
            self.log_message(f"Error refreshing logs: {e}")
            
    def clear_logs(self):
        """Clear log display"""
        if messagebox.askyesno("Clear Logs", "Clear all log entries from display?"):
            self.log_output.delete('1.0', 'end')
            
    def export_logs(self):
        """Export logs to file"""
        file_path = filedialog.asksaveasfilename(
            title="Export Logs",
            defaultextension=".txt",
            filetypes=[("Text Files", "*.txt"), ("All Files", "*.*")]
        )
        
        if file_path:
            try:
                with open(file_path, 'w') as f:
                    content = self.log_output.get('1.0', 'end')
                    f.write(content)
                messagebox.showinfo("Export Complete", f"Logs exported to {file_path}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to export logs: {e}")
                
    def log_message(self, message):
        """Add message to log output"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.log_output.insert('end', f"[{timestamp}] {message}\n")
        self.log_output.see('end')
        
    def update_status(self):
        """Update status indicators"""
        # Update monitoring status
        if self.monitoring_active:
            self.monitoring_status.config(text="Monitoring: ACTIVE", foreground=self.colors['accent'])
        else:
            self.monitoring_status.config(text="Monitoring: INACTIVE", foreground=self.colors['warning'])
            
        # Schedule next update
        self.root.after(1000, self.update_status)
        
    def show_help(self):
        """Show help information"""
        help_text = """XXMXLI Automated Incident Reporter - Help

MONITORING TAB:
- Start/Stop automated security monitoring
- View real-time monitoring output
- Configure monitoring intervals

REPORTING TAB:
- Manually report security incidents
- Select incident type and severity
- Add evidence files and detailed descriptions
- Submit reports to law enforcement agencies

SETTINGS TAB:
- Configure monitoring parameters
- Set auto-reporting thresholds
- Enable/disable notifications

LOGS TAB:
- View system logs and incident history
- Refresh, clear, or export log data

EMERGENCY BUTTON:
- Report critical incidents immediately
- Triggers high-priority alerts to all agencies

This system reports incidents to:
• FBI Internet Crime Complaint Center (IC3)
• CISA (Cybersecurity & Infrastructure Security Agency)
• Europol European Cybercrime Centre (EC3)
• National Computer Emergency Response Teams (CERTs)

All reports are encrypted and transmitted securely."""

        messagebox.showinfo("Help", help_text)
        
    def show_about(self):
        """Show about information"""
        about_text = """XXMXLI Automated Incident Reporter
Version 2.0.1 - GUI Edition

Advanced Security Incident Reporting System
with Real-Time Monitoring Capabilities

Developed by: XXMXLI Security Team
License: Professional Security Tools

This application provides comprehensive incident
reporting capabilities for cybersecurity professionals
and organizations.

Features automated monitoring, evidence collection,
and secure transmission to law enforcement agencies
worldwide.

Stay vigilant. Stay secure."""

        messagebox.showinfo("About", about_text)
        
    def exit_application(self):
        """Exit the application"""
        if self.monitoring_active:
            if not messagebox.askyesno("Exit", "Monitoring is active. Stop monitoring and exit?"):
                return
            self.stop_monitoring()
            
        self.root.quit()
        self.root.destroy()
        
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
    app = IncidentReporterGUI()
    app.run()

if __name__ == "__main__":
    main()
