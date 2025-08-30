#!/usr/bin/env python3
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
import tkinter as tk
from tkinter import messagebox, simpledialog

def show_gui_launcher():
    """Show a simple GUI launcher for non-technical users"""
    
    # Create main window
    root = tk.Tk()
    root.title("XXMXLI Incident Reporter - Easy Launcher")
    root.geometry("500x400")
    root.configure(bg='#001100')
    
    # Title
    title_label = tk.Label(root, text="🚀 XXMXLI Incident Reporter", 
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
                subprocess.run([sys.executable, "automated_incident_reporter.py"], 
                             check=True, cwd=os.path.dirname(__file__))
                messagebox.showinfo("Success", "✅ Security monitoring has been set up!\n"
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
            cmd = [sys.executable, "automated_incident_reporter.py", "report",
                   "--type", incident_type.upper(),
                   "--severity", str(severity),
                   "--description", description]
            
            result = subprocess.run(cmd, check=True, capture_output=True, text=True,
                                  cwd=os.path.dirname(__file__))
            
            messagebox.showinfo("Success", f"✅ Incident reported successfully!\n\n{result.stdout}")
        except subprocess.CalledProcessError as e:
            messagebox.showerror("Error", f"Failed to report incident:\n{e}")
        except FileNotFoundError:
            messagebox.showerror("Error", "automated_incident_reporter.py not found!")
        
        root.quit()
    
    def show_help():
        help_text = """XXMXLI Incident Reporter Help

🛡️ Setup Monitoring: Automatically configures your system to monitor
   for security threats and report them to authorities.

📞 Report Incident: Manually report a security incident that you've
   discovered or experienced.

This tool reports incidents to:
• FBI Internet Crime Complaint Center (IC3)
• CISA (Cybersecurity & Infrastructure Security Agency)
• Europol European Cybercrime Centre (EC3)
• National Computer Emergency Response Teams

All reports are encrypted and sent through secure channels."""
        
        messagebox.showinfo("Help", help_text)
    
    # Create buttons with better styling
    button_frame = tk.Frame(root, bg="#001100")
    button_frame.pack(pady=30)
    
    setup_btn = tk.Button(button_frame, text="🛡️ Set Up Monitoring", 
                         command=setup_monitoring,
                         font=("Arial", 12, "bold"),
                         bg="#00aa00", fg="white",
                         width=20, height=2)
    setup_btn.pack(pady=10)
    
    report_btn = tk.Button(button_frame, text="📞 Report Incident", 
                          command=report_incident,
                          font=("Arial", 12),
                          bg="#aa6600", fg="white",
                          width=20, height=2)
    report_btn.pack(pady=10)
    
    help_btn = tk.Button(button_frame, text="❓ Help", 
                        command=show_help,
                        font=("Arial", 10),
                        bg="#666666", fg="white",
                        width=20)
    help_btn.pack(pady=5)
    
    # Warning label
    warning_label = tk.Label(root, text="⚠️ This system reports incidents to law enforcement", 
                           font=("Arial", 8), 
                           fg="#ffaa00", bg="#001100")
    warning_label.pack(side="bottom", pady=10)
    
    # Start the GUI
    root.mainloop()

def main():
    """Main launcher function"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    print("🚀 XXMXLI Incident Reporter - Cross-Platform Launcher")
    print("====================================================")
    print()
    
    # Check if we're in a terminal or GUI environment
    if len(sys.argv) > 1 and sys.argv[1] == "--gui":
        # Force GUI mode
        try:
            show_gui_launcher()
        except ImportError:
            print("GUI mode not available (tkinter not installed)")
            print("Falling back to command-line mode...")
            subprocess.run([sys.executable, "automated_incident_reporter.py"])
    elif os.environ.get("DISPLAY") and platform.system() != "Windows":
        # Linux/Unix with GUI
        try:
            show_gui_launcher()
        except Exception:
            # Fallback to command-line
            subprocess.run([sys.executable, "automated_incident_reporter.py"])
    elif platform.system() == "Windows":
        # Windows - try GUI first
        try:
            show_gui_launcher()
        except Exception:
            # Fallback to command-line
            subprocess.run([sys.executable, "automated_incident_reporter.py"])
    else:
        # Terminal mode
        subprocess.run([sys.executable, "automated_incident_reporter.py"])

if __name__ == "__main__":
    main()
