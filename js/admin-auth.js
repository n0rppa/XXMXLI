import { supabase } from './supabase-config.js';

// Admin access flag (set to true to disable for emergency). For emergency shutdown set true.
const ADMIN_ACCESS_DISABLED = true;

export const adminAuth = {
  // Check if user is authenticated and has admin role
  async checkAuth() {
    if (ADMIN_ACCESS_DISABLED) {
      return { authenticated: false, error: 'Admin access disabled' };
    }
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error || !session) {
      return { authenticated: false, error: 'Not authenticated' };
    }
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', session.user.id)
      .single();
    if (profileError || profile?.role !== 'admin') {
      return { authenticated: false, error: 'Unauthorized' };
    }
    return { authenticated: true, user: session.user };
  },

  // Login with email and password (will always fail when disabled)
  async login(email, password) {
    if (ADMIN_ACCESS_DISABLED) {
      throw new Error('Admin access disabled');
    }
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw new Error(error.message);
    const { authenticated, error: authError } = await this.checkAuth();
    if (!authenticated) {
      await supabase.auth.signOut();
      throw new Error(authError || 'Unauthorized access');
    }
    return data;
  },

  // Logout
  async logout() {
    const { error } = await supabase.auth.signOut();
    if (error) throw new Error(error.message);
  },

  // Get current user (will return null when disabled)
  async getCurrentUser() {
    if (ADMIN_ACCESS_DISABLED) return null;
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error || !session) return null;
    return session.user;
  }
};
