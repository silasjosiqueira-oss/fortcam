import { create } from "zustand";
import { authAPI } from "@/lib/api";

interface User {
  id: number;
  name: string;
  email: string;
  role: string;
  tenant_id: number | null;
}

interface AuthStore {
  user: User | null;
  token: string | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<User>;
  logout: () => void;
  loadUser: () => Promise<User | null>;
}

export const useAuthStore = create<AuthStore>((set) => ({
  user: null,
  token: typeof window !== "undefined" ? localStorage.getItem("token") : null,
  loading: false,

  login: async (email, password) => {
    set({ loading: true });
    try {
      const res = await authAPI.login(email, password);
      const token = res.data.access_token;
      localStorage.setItem("token", token);
      const me = await authAPI.me();
      set({ token, user: me.data, loading: false });
      return me.data;
    } catch (err) {
      set({ loading: false });
      throw err;
    }
  },

  logout: () => {
    localStorage.removeItem("token");
    set({ user: null, token: null });
    window.location.href = "/login";
  },

  loadUser: async () => {
    const token = localStorage.getItem("token");
    if (!token) return null;
    try {
      const me = await authAPI.me();
      set({ user: me.data, token });
      return me.data;
    } catch {
      localStorage.removeItem("token");
      set({ user: null, token: null });
      return null;
    }
  },
}));