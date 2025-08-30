#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================
XXMXLI INCIDENT REPORTER - SELF-CONTAINED EASY LAUNCHER
================================================================
This Python script is completely self-contained and works independently.
No other files needed - just download and run!
Works on Windows, Linux, and macOS - just double-click!
================================================================
"""

import os
import sys
import subprocess
import platform
import json
import time
from datetime import datetime

# Try to import tkinter, but make it optional
try:
    import tkinter as tk
    from tkinter import messagebox, simpledialog, scrolledtext
    HAS_GUI = True
except ImportError:
    HAS_GUI = False

class XXMXLIIncidentReporter:
    """Self-contained incident reporter with built-in functionality"""
    
    def __init__(self):
        self.script_dir = os.path.dirname(os.path.abspath(__file__)) if '__file__' in globals() else os.getcwd()
        self.log_file = os.path.join(self.script_dir, "xxmxli_incidents.log")
        
    def log_message(self, message):
        """Log a message with timestamp"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_entry = f"[{timestamp}] {message}\n"
        
        try:
            with open(self.log_file, 'a', encoding='utf-8') as f:
                f.write(log_entry)
        except Exception as e:
            print(f"Warning: Could not write to log file: {e}")
        
        print(f"[{timestamp}] {message}")
    
    def setup_monitoring(self):
        """Set up basic security monitoring"""
        self.log_message("Setting up XXMXLI security monitoring...")
        
        # Create a basic monitoring configuration
        config = {
            "monitoring_enabled": True,
            "setup_time": datetime.now().isoformat(),
            "system_info": {
                "platform": platform.system(),
                "release": platform.release(),
                "machine": platform.machine(),
                "python_version": platform.python_version()
            },
            "last_check": datetime.now().isoformat()
        }
        
        config_file = os.path.join(self.script_dir, "xxmxli_config.json")
        try:
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
            self.log_message("Configuration file created successfully")
        except Exception as e:
            self.log_message(f"Warning: Could not create config file: {e}")
        
        self.log_message("Security monitoring setup completed!")
        return True
    
    def report_incident(self, incident_type, severity, description):
        """Report a security incident"""
        timestamp = datetime.now().isoformat()
        
        incident = {
            "timestamp": timestamp,
            "type": incident_type.upper(),
            "severity": int(severity),
            "description": description,
            "system_info": {
                "platform": platform.system(),
                "release": platform.release(),
                "machine": platform.machine()
            },
            "reporter": "XXMXLI Easy Launcher",
            "status": "logged"
        }
        
        # Log the incident
        self.log_message(f"INCIDENT REPORT: {incident_type} (Severity: {severity})")
        self.log_message(f"Description: {description}")
        
        # Save incident to file
        incidents_file = os.path.join(self.script_dir, "xxmxli_incidents.json")
        incidents = []
        
        # Load existing incidents
        try:
            if os.path.exists(incidents_file):
                with open(incidents_file, 'r') as f:
                    incidents = json.load(f)
        except Exception as e:
            self.log_message(f"Warning: Could not load existing incidents: {e}")
        
        # Add new incident
        incidents.append(incident)
        
        # Save incidents
        try:
            with open(incidents_file, 'w') as f:
                json.dump(incidents, f, indent=2)
            self.log_message("Incident saved to local database")
        except Exception as e:
            self.log_message(f"Warning: Could not save incident: {e}")
        
        # Simulate reporting to authorities
        self.log_message("Incident logged locally - use proper reporting channels for real incidents:")
        self.log_message("• FBI IC3: https://www.ic3.gov/")
        self.log_message("• CISA: https://www.cisa.gov/report")
        self.log_message("• Europol EC3: https://www.europol.europa.eu/report-a-crime")
        
        return True
    
    def check_system_status(self):
        """Check basic system status"""
        self.log_message("Checking system status...")
        
        status = {
            "timestamp": datetime.now().isoformat(),
            "platform": platform.system(),
            "python_version": platform.python_version(),
            "disk_usage": self.get_disk_usage(),
            "memory_info": self.get_memory_info(),
            "network_status": self.check_network()
        }
        
        return status
    
    def get_disk_usage(self):
        """Get basic disk usage information"""
        try:
            import shutil
            total, used, free = shutil.disk_usage(self.script_dir)
            return {
                "total_gb": round(total / (1024**3), 2),
                "used_gb": round(used / (1024**3), 2),
                "free_gb": round(free / (1024**3), 2),
                "usage_percent": round((used / total) * 100, 2)
            }
        except Exception as e:
            return {"error": str(e)}
    
    def get_memory_info(self):
        """Get basic memory information"""
        try:
            if platform.system() == "Windows":
                # Simple Windows memory check
                result = subprocess.run(['wmic', 'OS', 'get', 'TotalVisibleMemorySize', '/value'], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    for line in result.stdout.split('\n'):
                        if 'TotalVisibleMemorySize=' in line:
                            total_kb = int(line.split('=')[1])
                            return {"total_gb": round(total_kb / (1024**2), 2)}
            else:
                # Unix-like systems
                with open('/proc/meminfo', 'r') as f:
                    meminfo = f.read()
                    for line in meminfo.split('\n'):
                        if 'MemTotal:' in line:
                            total_kb = int(line.split()[1])
                            return {"total_gb": round(total_kb / (1024**2), 2)}
        except Exception as e:
            return {"error": str(e)}
        
        return {"status": "unknown"}
    
    def check_network(self):
        """Check basic network connectivity"""
        try:
            # Simple ping test
            if platform.system() == "Windows":
                result = subprocess.run(['ping', '-n', '1', '8.8.8.8'], 
                                      capture_output=True, timeout=5)
            else:
                result = subprocess.run(['ping', '-c', '1', '8.8.8.8'], 
                                      capture_output=True, timeout=5)
            
            return {"status": "connected" if result.returncode == 0 else "disconnected"}
        except Exception as e:
            return {"status": "unknown", "error": str(e)}

def show_gui_launcher():
    """Show a self-contained GUI launcher"""
    
    if not HAS_GUI:
        print("GUI not available - tkinter not installed")
        return False
    
    reporter = XXMXLIIncidentReporter()
    
    # Create main window
    root = tk.Tk()
    root.title("XXMXLI Incident Reporter - Self-Contained Launcher")
    root.geometry("600x500")
    root.configure(bg='#001100')
    
    # Title
    title_label = tk.Label(root, text="XXMXLI Security Monitor", 
                          font=("Arial", 16, "bold"), 
                          fg="#00ff00", bg="#001100")
    title_label.pack(pady=20)
    
    subtitle_label = tk.Label(root, text="Self-Contained Security Tool - No Dependencies", 
                             font=("Arial", 12), 
                             fg="#ffffff", bg="#001100")
    subtitle_label.pack(pady=5)
    
    # Status display
    status_frame = tk.Frame(root, bg="#001100")
    status_frame.pack(pady=10, fill="x", padx=20)
    
    status_text = scrolledtext.ScrolledText(status_frame, height=8, width=70,
                                          bg="#000000", fg="#00ff00",
                                          font=("Courier", 9))
    status_text.pack(fill="both", expand=True)
    
    def update_status():
        status_text.delete("1.0", tk.END)
        status_text.insert(tk.END, "XXMXLI Security Monitor - System Status\n")
        status_text.insert(tk.END, "=" * 50 + "\n\n")
        
        status = reporter.check_system_status()
        status_text.insert(tk.END, f"Timestamp: {status['timestamp']}\n")
        status_text.insert(tk.END, f"Platform: {status['platform']}\n")
        status_text.insert(tk.END, f"Python Version: {status['python_version']}\n")
        
        if 'error' not in status['disk_usage']:
            disk = status['disk_usage']
            status_text.insert(tk.END, f"Disk Usage: {disk['used_gb']}GB / {disk['total_gb']}GB ({disk['usage_percent']}%)\n")
        
        if 'error' not in status['memory_info']:
            mem = status['memory_info']
            if 'total_gb' in mem:
                status_text.insert(tk.END, f"Total Memory: {mem['total_gb']}GB\n")
        
        net = status['network_status']
        status_text.insert(tk.END, f"Network: {net['status']}\n")
        
        status_text.insert(tk.END, f"\nLog File: {reporter.log_file}\n")
        status_text.insert(tk.END, f"Working Directory: {reporter.script_dir}\n")
    
    # Update status initially
    update_status()
    
    # Buttons
    def setup_monitoring():
        result = messagebox.askyesno("Setup Monitoring", 
                                   "This will set up local security monitoring.\n"
                                   "Continue?")
        if result:
            try:
                if reporter.setup_monitoring():
                    messagebox.showinfo("Success", "Security monitoring has been set up!\n"
                                                  "Check the log file for details.")
                    update_status()
            except Exception as e:
                messagebox.showerror("Error", f"Failed to set up monitoring:\n{e}")
    
    def report_incident():
        # Simple incident reporting form
        incident_type = simpledialog.askstring("Incident Type", 
                                              "What type of incident?\n"
                                              "(malware, intrusion, ddos, phishing, other)")
        if not incident_type:
            return
            
        severity = simpledialog.askinteger("Severity", 
                                         "Severity level (1-10, where 10 is critical)?",
                                         minvalue=1, maxvalue=10)
        if not severity:
            return
            
        description = simpledialog.askstring("Description", 
                                           "Describe what happened:")
        if not description:
            return
        
        try:
            if reporter.report_incident(incident_type, severity, description):
                messagebox.showinfo("Success", "Incident logged locally!\n\n"
                                              "For real incidents, please report to:\n"
                                              "• FBI IC3: https://www.ic3.gov/\n"
                                              "• CISA: https://www.cisa.gov/report")
                update_status()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to report incident:\n{e}")
    
    def show_help():
        help_text = """XXMXLI Self-Contained Security Monitor

This tool is completely self-contained and requires no additional files.

Features:
• Setup Monitoring: Configures local security monitoring
• Report Incident: Logs security incidents locally
• System Status: Shows basic system information

Files Created:
• xxmxli_config.json: Configuration settings
• xxmxli_incidents.log: Activity log
• xxmxli_incidents.json: Incident database

For real security incidents, use official reporting channels:
• FBI IC3: https://www.ic3.gov/
• CISA: https://www.cisa.gov/report
• Europol EC3: https://www.europol.europa.eu/report-a-crime

This tool provides local logging and basic monitoring only."""
        
        help_window = tk.Toplevel(root)
        help_window.title("Help")
        help_window.geometry("500x400")
        help_window.configure(bg="#001100")
        
        help_text_widget = scrolledtext.ScrolledText(help_window, bg="#000000", fg="#ffffff",
                                                   font=("Arial", 10), wrap=tk.WORD)
        help_text_widget.pack(fill="both", expand=True, padx=10, pady=10)
        help_text_widget.insert("1.0", help_text)
        help_text_widget.config(state=tk.DISABLED)
    
    # Create buttons with better styling
    button_frame = tk.Frame(root, bg="#001100")
    button_frame.pack(pady=20)
    
    setup_btn = tk.Button(button_frame, text="Set Up Monitoring", 
                         command=setup_monitoring,
                         font=("Arial", 12, "bold"),
                         bg="#00aa00", fg="white",
                         width=20, height=2)
    setup_btn.grid(row=0, column=0, padx=10, pady=5)
    
    report_btn = tk.Button(button_frame, text="Report Incident", 
                          command=report_incident,
                          font=("Arial", 12),
                          bg="#aa6600", fg="white",
                          width=20, height=2)
    report_btn.grid(row=0, column=1, padx=10, pady=5)
    
    refresh_btn = tk.Button(button_frame, text="Refresh Status", 
                           command=update_status,
                           font=("Arial", 10),
                           bg="#0066aa", fg="white",
                           width=20)
    refresh_btn.grid(row=1, column=0, padx=10, pady=5)
    
    help_btn = tk.Button(button_frame, text="Help", 
                        command=show_help,
                        font=("Arial", 10),
                        bg="#666666", fg="white",
                        width=20)
    help_btn.grid(row=1, column=1, padx=10, pady=5)
    
    # Warning label
    warning_label = tk.Label(root, text="Self-contained tool - No external dependencies required", 
                           font=("Arial", 8), 
                           fg="#ffaa00", bg="#001100")
    warning_label.pack(side="bottom", pady=10)
    
    # Start the GUI
    root.mainloop()
    return True

def show_cli_launcher():
    """Show command-line launcher for systems without GUI"""
    reporter = XXMXLIIncidentReporter()
    
    print("XXMXLI Self-Contained Security Monitor")
    print("=" * 50)
    print()
    print("Choose an option:")
    print("1. Set up security monitoring")
    print("2. Report a security incident")
    print("3. Check system status")
    print("4. Show help")
    print("0. Exit")
    print()
    
    while True:
        choice = input("Enter choice [0-4]: ").strip()
        
        if choice == '0':
            print("Goodbye!")
            return
        elif choice == '1':
            print("Setting up security monitoring...")
            try:
                if reporter.setup_monitoring():
                    print("Security monitoring set up successfully!")
            except Exception as e:
                print(f"Error setting up monitoring: {e}")
            return
        elif choice == '2':
            print("Manual incident reporting...")
            incident_type = input("Incident type (malware/intrusion/ddos/phishing/other): ").strip()
            
            try:
                severity = int(input("Severity (1-10): ").strip())
                if not 1 <= severity <= 10:
                    print("Severity must be between 1 and 10")
                    continue
            except ValueError:
                print("Invalid severity. Please enter a number between 1 and 10.")
                continue
            
            description = input("Description: ").strip()
            
            if not incident_type or not description:
                print("Incident type and description are required.")
                continue
            
            try:
                if reporter.report_incident(incident_type, severity, description):
                    print("Incident logged successfully!")
            except Exception as e:
                print(f"Error reporting incident: {e}")
            return
        elif choice == '3':
            print("Checking system status...")
            try:
                status = reporter.check_system_status()
                print(f"Platform: {status['platform']}")
                print(f"Python: {status['python_version']}")
                
                if 'error' not in status['disk_usage']:
                    disk = status['disk_usage']
                    print(f"Disk: {disk['used_gb']}GB / {disk['total_gb']}GB used")
                
                net = status['network_status']
                print(f"Network: {net['status']}")
                
            except Exception as e:
                print(f"Error checking status: {e}")
            
            input("\nPress Enter to continue...")
        elif choice == '4':
            print("\nXXMXLI Self-Contained Security Monitor")
            print("=" * 40)
            print("This tool is completely self-contained and requires no additional files.")
            print()
            print("Features:")
            print("• Local security monitoring setup")
            print("• Incident logging and tracking")
            print("• Basic system status checking")
            print()
            print("For real security incidents, use official channels:")
            print("• FBI IC3: https://www.ic3.gov/")
            print("• CISA: https://www.cisa.gov/report")
            print("• Europol EC3: https://www.europol.europa.eu/report-a-crime")
            print()
            input("Press Enter to continue...")
        else:
            print("Invalid choice. Please enter 0-4.")

def main():
    """Main launcher function - completely self-contained"""
    
    print("XXMXLI Self-Contained Security Monitor")
    print("=" * 50)
    print("No external files required - runs independently!")
    print()
    
    # Check command line arguments
    if len(sys.argv) > 1 and sys.argv[1] == "--cli":
        show_cli_launcher()
        return
    
    # Try GUI first if available
    if HAS_GUI:
        try:
            # Check if display is available (for headless systems)
            try:
                test_root = tk.Tk()
                test_root.withdraw()
                test_root.destroy()
                
                if show_gui_launcher():
                    return
            except Exception as e:
                print(f"GUI not available ({e}), using command-line mode...")
        except Exception as e:
            print(f"GUI failed: {e}")
            print("Falling back to command-line mode...")
    
    # Fallback to CLI
    show_cli_launcher()

if __name__ == "__main__":
    main()
