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
import shlex
from typing import List, Tuple
from tkinter import filedialog

# Try to import tkinter, but make it optional
try:
    import tkinter as tk
    from tkinter import messagebox, simpledialog
    HAS_GUI = True
except ImportError:
    HAS_GUI = False

def _python_exec() -> str:
    """Return the preferred python executable path (robust on Windows)."""
    # Prefer the running interpreter to avoid PATH ambiguity
    return sys.executable or 'python'

def _incident_script_path() -> str:
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "automated_incident_reporter.py")

def _validate_environment() -> Tuple[bool, str]:
    """Check that required files and directories exist and are writable."""
    script_path = _incident_script_path()
    if not os.path.isfile(script_path):
        return False, f"Missing required script: {script_path}"
    reports_dir = os.path.join(os.path.dirname(script_path), 'reports')
    try:
        os.makedirs(reports_dir, exist_ok=True)
        test_file = os.path.join(reports_dir, '.write_test')
        with open(test_file, 'w') as f: f.write('ok')
        os.remove(test_file)
    except Exception as e:
        return False, f"Cannot write to reports directory: {e}"
    return True, "Environment OK"

def _build_command(base_args: List[str]) -> List[str]:
    """Return a sanitized command list (never include empty strings)."""
    return [arg for arg in base_args if isinstance(arg, str) and arg.strip()]

def _run_command(cmd: List[str]) -> Tuple[int, str, str]:
    """Execute a command capturing stdout/stderr. Returns (code, out, err)."""
    try:
        completed = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return completed.returncode, completed.stdout, completed.stderr
    except FileNotFoundError as e:
        return 127, '', f"Executable not found: {e}"
    except Exception as e:
        return 1, '', f"Unexpected error launching command: {e}"

def _pretty_error_dialog(title: str, body: str):
    if HAS_GUI:
        try:
            messagebox.showerror(title, body)
            return
        except Exception:
            pass
    print(f"[ERROR] {title}:\n{body}")

def _report_incident_cli(incident_type: str, severity: int, description: str) -> Tuple[bool, str]:
    script = _incident_script_path()
    cmd = _build_command([_python_exec(), script, 'report', '--type', incident_type.upper(), '--severity', str(severity), '--description', description])
    code, out, err = _run_command(cmd)
    if code == 0:
        return True, out or 'Incident reported.'
    # Detect argument parsing error (exit 2 typical from argparse for bad usage)
    hint = ''
    if code == 2 or 'usage:' in err.lower():
        hint = '\nHint: Required flags --type --severity --description must all be provided and severity 1-10.'
    return False, f"Command failed (exit {code}).\nCMD: {' '.join(shlex.quote(c) for c in cmd)}\nSTDOUT:\n{out}\nSTDERR:\n{err}{hint}"

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
                ok, msg = _validate_environment()
                if not ok:
                    _pretty_error_dialog("Environment Error", msg)
                else:
                    cmd = _build_command([_python_exec(), _incident_script_path(), 'setup'])
                    code, out, err = _run_command(cmd)
                    if code == 0:
                        messagebox.showinfo("Success", "Security monitoring has been set up!\nYour system is now protected.")
                    else:
                        _pretty_error_dialog("Setup Failed", f"Exit {code}\nSTDOUT:\n{out}\nSTDERR:\n{err}")
            except Exception as e:
                _pretty_error_dialog("Unexpected", str(e))
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
        
        ok, msg = _validate_environment()
        if not ok:
            _pretty_error_dialog("Environment Error", msg)
            return
        # Ask for evidence files (optional)
        evidence_files = []
        if messagebox.askyesno("Evidence", "Attach evidence files (logs, screenshots)?"):
            files = filedialog.askopenfilenames(title="Select evidence files")
            evidence_files = list(files)

        # Dry run?
        dry_run = messagebox.askyesno("Dry Run", "Perform a dry run (no submission)?")

        # Extend command manually to pass evidence & dry-run since _report_incident_cli currently encapsulates logic
        script = _incident_script_path()
        base_cmd = [_python_exec(), script, 'report', '--type', incident_type.upper(), '--severity', str(severity), '--description', description]
        for ev in evidence_files:
            base_cmd += ['--evidence', ev]
        if dry_run:
            base_cmd.append('--dry-run')
        code, out, err = _run_command(base_cmd)
        success = code == 0
        info = out if success else f"Exit {code}\nSTDOUT:\n{out}\nSTDERR:\n{err}"
        if success:
            messagebox.showinfo("Success", info)
        else:
            _pretty_error_dialog("Failed to Report", info)
        
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
            ok, msg = _validate_environment()
            if not ok:
                print(f"Environment error: {msg}")
            else:
                code, out, err = _run_command(_build_command([_python_exec(), _incident_script_path(), 'setup']))
                if code == 0:
                    print("Security monitoring set up successfully!")
                else:
                    print(f"Setup failed (exit {code})\nSTDOUT:\n{out}\nSTDERR:\n{err}")
            return
        elif choice == '2':
            print("Manual incident reporting...")
            incident_type = input("Incident type (malware/intrusion/ddos/phishing/other): ").strip()
            severity = input("Severity (1-10): ").strip()
            description = input("Description: ").strip()
            add_evidence = input("Add evidence files? (y/N): ").strip().lower() == 'y'
            evidence_args = []
            if add_evidence:
                print("Enter evidence file paths (blank line to finish):")
                while True:
                    p = input("Evidence path: ").strip()
                    if not p:
                        break
                    evidence_args += ['--evidence', p]
            dry_run = input("Dry run (no submission)? (y/N): ").strip().lower() == 'y'
            
            ok, msg = _validate_environment()
            if not ok:
                print(f"Environment error: {msg}")
            else:
                cmd = [_python_exec(), _incident_script_path(), 'report', '--type', incident_type.upper(), '--severity', severity, '--description', description]
                cmd += evidence_args
                if dry_run:
                    cmd.append('--dry-run')
                code, out, err = _run_command(cmd)
                if code == 0:
                    print("Incident reported successfully!\n" + out)
                else:
                    print(f"Report failed (exit {code})\nSTDOUT:\n{out}\nSTDERR:\n{err}")
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
