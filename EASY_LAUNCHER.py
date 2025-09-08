#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================
XXMXLI INCIDENT REPORTER - DOUBLE-CLICK LAUNCHER (PYTHON)
================================================================
This Python script makes it super easy to run the incident reporter
Works on Windows, Linux, and macOS - just double-click!
================================================================
"""

import os
import sys
import subprocess
import platform

# Try to import tkinter, but make it optional
try:
    import tkinter as tk
    from tkinter import messagebox, simpledialog
    HAS_GUI = True
except ImportError:
    HAS_GUI = False

def show_gui_launcher():
    """Show a simple GUI launcher for non-technical users"""
    
    if not HAS_GUI:
        print("GUI not available - tkinter not installed")
        return False
    
    # Create main window
    root = tk.Tk()
    root.title("XXMXLI Incident Reporter - Easy Launcher")
    root.geometry("500x400")
    root.configure(bg='#001100')
    
    # Title
    title_label = tk.Label(root, text="XXMXLI Incident Reporter", 
                          font=("Arial", 16, "bold"), 
                          fg="#00ff00", bg="#001100")
    title_label.pack(pady=20)
    
    subtitle_label = tk.Label(root, text="Easy Security Monitoring Setup", 
                             font=("Arial", 12), 
                             fg="#ffffff", bg="#001100")
    subtitle_label.pack(pady=5)
    
    # Description
    desc_text = """This tool will automatically set up security monitoring
and incident reporting for your computer. It will report
any suspicious activity to the appropriate authorities."""
    
    desc_label = tk.Label(root, text=desc_text, 
                         font=("Arial", 10), 
                         fg="#cccccc", bg="#001100",
                         wraplength=400, justify="center")
    desc_label.pack(pady=20)
    
    # Buttons
    def setup_monitoring():
        result = messagebox.askyesno("Setup Monitoring", 
                                   "This will set up automatic security monitoring.\n"
                                   "Continue?")
        if result:
            try:
                # Run the Python incident reporter
                incident_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "automated_incident_reporter.py")
                subprocess.run([sys.executable, incident_path], check=True)
                messagebox.showinfo("Success", "Security monitoring has been set up!\n"
                                              "Your system is now protected.")
            except subprocess.CalledProcessError as e:
                messagebox.showerror("Error", f"Failed to set up monitoring:\n{e}")
            except FileNotFoundError:
                messagebox.showerror("Error", "automated_incident_reporter.py not found!\n"
                                            "Please ensure all files are in the same folder.")
        root.quit()
    
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
            # Run the incident reporter with parameters
            incident_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "automated_incident_reporter.py")
            cmd = [sys.executable, incident_path, "report",
                   "--type", incident_type.upper(),
                   "--severity", str(severity),
                   "--description", description]
            result = subprocess.run(
                cmd,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            
            messagebox.showinfo("Success", f"Incident reported successfully!\n\n{result.stdout}")
        except subprocess.CalledProcessError as e:
            messagebox.showerror("Error", f"Failed to report incident:\n{e}")
        except FileNotFoundError:
            messagebox.showerror("Error", "automated_incident_reporter.py not found!")
        
        root.quit()
    
    def show_help():
        help_text = """XXMXLI Incident Reporter Help

Setup Monitoring: Automatically configures your system to monitor
   for security threats and report them to authorities.

Report Incident: Manually report a security incident that you've
   discovered or experienced.

This tool reports incidents to:
* FBI Internet Crime Complaint Center (IC3)
* CISA (Cybersecurity & Infrastructure Security Agency)
* Europol European Cybercrime Centre (EC3)
* National Computer Emergency Response Teams

All reports are encrypted and sent through secure channels."""
        
        messagebox.showinfo("Help", help_text)
    
    # Create buttons with better styling
    button_frame = tk.Frame(root, bg="#001100")
    button_frame.pack(pady=30)
    
    setup_btn = tk.Button(button_frame, text="Set Up Monitoring", 
                         command=setup_monitoring,
                         font=("Arial", 12, "bold"),
                         bg="#00aa00", fg="white",
                         width=20, height=2)
    setup_btn.pack(pady=10)
    
    report_btn = tk.Button(button_frame, text="Report Incident", 
                          command=report_incident,
                          font=("Arial", 12),
                          bg="#aa6600", fg="white",
                          width=20, height=2)
    report_btn.pack(pady=10)
    
    help_btn = tk.Button(button_frame, text="Help", 
                        command=show_help,
                        font=("Arial", 10),
                        bg="#666666", fg="white",
                        width=20)
    help_btn.pack(pady=5)
    
    # Warning label
    warning_label = tk.Label(root, text="WARNING: This system reports incidents to law enforcement", 
                           font=("Arial", 8), 
                           fg="#ffaa00", bg="#001100")
    warning_label.pack(side="bottom", pady=10)
    
    # Start the GUI
    root.mainloop()
    return True

def show_cli_launcher():
    """Show command-line launcher for systems without GUI"""
    print("XXMXLI Incident Reporter - Cross-Platform Launcher")
    print("====================================================")
    print()
    print("Choose an option:")
    print("1. Set up automatic security monitoring")
    print("2. Report a security incident")
    print("3. Show help")
    print("0. Exit")
    print()
    
    while True:
        choice = input("Enter choice [0-3]: ").strip()
        
        if choice == '0':
            print("Goodbye!")
            return
        elif choice == '1':
            print("Setting up security monitoring...")
            try:
                incident_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "automated_incident_reporter.py")
                subprocess.run([sys.executable, incident_path], check=True)
                print("Security monitoring set up successfully!")
            except subprocess.CalledProcessError as e:
                print(f"Error setting up monitoring: {e}")
            except FileNotFoundError:
                print("Error: automated_incident_reporter.py not found!")
            return
        elif choice == '2':
            print("Manual incident reporting...")
            incident_type = input("Incident type (malware/intrusion/ddos/phishing/other): ").strip()
            severity = input("Severity (1-10): ").strip()
            description = input("Description: ").strip()
            
            try:
                incident_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "automated_incident_reporter.py")
                cmd = [sys.executable, incident_path, "report",
                       "--type", incident_type.upper(),
                       "--severity", severity,
                       "--description", description]
                subprocess.run(cmd, check=True)
                print("Incident reported successfully!")
            except subprocess.CalledProcessError as e:
                print(f"Error reporting incident: {e}")
            except FileNotFoundError:
                print("Error: automated_incident_reporter.py not found!")
            return
        elif choice == '3':
            print("\nXXMXLI Incident Reporter Help")
            print("=============================")
            print("This tool helps you report security incidents to authorities.")
            print("It can automatically monitor your system or manually report incidents.")
            print("Reports are sent to FBI IC3, CISA, Europol EC3, and national CERTs.")
            print()
        else:
            print("Invalid choice. Please enter 0-3.")

def main():
    """Main launcher function"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    print("XXMXLI Incident Reporter - Cross-Platform Launcher")
    print("====================================================")
    print()
    
    # Check command line arguments
    if len(sys.argv) > 1 and sys.argv[1] == "--cli":
        show_cli_launcher()
        return
    
    # Try GUI first if available
    if HAS_GUI:
        try:
            if show_gui_launcher():
                return
        except Exception as e:
            print(f"GUI failed: {e}")
            print("Falling back to command-line mode...")
    
    # Fallback to CLI
    show_cli_launcher()

if __name__ == "__main__":
    main()
