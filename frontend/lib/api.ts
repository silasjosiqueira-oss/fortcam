import axios from "axios";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

const api = axios.create({
  baseURL: API_URL,
  headers: { "Content-Type": "application/json" },
});

// Interceptor: adiciona token em todas as requisicoes
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Interceptor: redireciona para login se 401
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem("token");
      window.location.href = "/login";
    }
    return Promise.reject(err);
  }
);

// AUTH
export const authAPI = {
  login: (email: string, password: string) =>
    api.post("/api/v1/auth/login", { email, password }),
  me: () => api.get("/api/v1/auth/me"),
};

// DASHBOARD
export const dashboardAPI = {
  stats: () => api.get("/api/v1/events/dashboard"),
  lastEvent: () => api.get("/api/v1/events/last"),
};

// EVENTOS
export const eventsAPI = {
  list: (params?: { plate?: string; status?: string; limit?: number }) =>
    api.get("/api/v1/events/", { params }),
};

// WHITELIST
export const whitelistAPI = {
  list: () => api.get("/api/v1/whitelist/"),
  add: (data: { plate: string; owner_name: string; time_start: string; time_end: string }) =>
    api.post("/api/v1/whitelist/", data),
  update: (id: number, data: any) => api.put(`/api/v1/whitelist/${id}`, data),
  remove: (id: number) => api.delete(`/api/v1/whitelist/${id}`),
  check: (plate: string) => api.get(`/api/v1/whitelist/check/${plate}`),
};

// CAMERAS
export const camerasAPI = {
  list: () => api.get("/api/v1/cameras/"),
};

// PORTAO
export const gateAPI = {
  command: (camera_id: number, action: "open" | "close") =>
    api.post("/api/v1/gate/command", { camera_id, action }),
};

export default api;