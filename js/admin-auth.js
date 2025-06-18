import { supabase } from './supabase-config.js';

export const adminAuth = {
  // Check if user is authenticated and has admin role
  async checkAuth() {
    const { data: { session }, error } = await supabase.auth.getSession();
    
    if (error || !session) {
      return { authenticated: false, error: 'Not authenticated' };
    }
    
    // Check if user has admin role
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

  // Login with email and password
  async login(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    
    if (error) {
      throw new Error(error.message);
    }
    
    // Check admin role after login
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
    if (error) {
      throw new Error(error.message);
    }
  },

  // Get current user
  async getCurrentUser() {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error || !session) {
      return null;
    }
    return session.user;
  }
};
