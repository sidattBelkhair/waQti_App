import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401 && error.response?.data?.code === 'TOKEN_EXPIRED') {
      try {
        const refreshToken = localStorage.getItem('refreshToken');
        const res = await axios.post(`${API_URL}/auth/refresh-token`, { refreshToken });
        localStorage.setItem('accessToken', res.data.accessToken);
        error.config.headers.Authorization = `Bearer ${res.data.accessToken}`;
        return api(error.config);
      } catch {
        localStorage.clear();
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export const authAPI = {
  login: (data) => api.post('/auth/login', data),
  getProfile: () => api.get('/auth/profile'),
  logout: (refreshToken) => api.post('/auth/logout', { refreshToken }),
  createAdmin: (data) => api.post('/auth/create-admin', data),
};

export const etablissementAPI = {
  getAll: (params) => api.get('/etablissements', { params }),
  getById: (id) => api.get(`/etablissements/${id}`),
  update: (id, data) => api.put(`/etablissements/${id}`, data),
  getServices: (id) => api.get(`/etablissements/${id}/services`),
  getPersonnel: (id) => api.get(`/etablissements/${id}/personnel`),
  getAvis: (id) => api.get(`/etablissements/${id}/avis`),
};

export const adminAPI = {
  getStats: () => api.get('/admin/stats'),
  getEtablissements: (params) => api.get('/admin/etablissements', { params }),
  updateEtabStatut: (id, statut) => api.patch(`/admin/etablissements/${id}/statut`, { statut }),
  deleteEtablissement: (id) => api.delete(`/admin/etablissements/${id}`),
  getUsers: (params) => api.get('/admin/users', { params }),
  getUserById: (id) => api.get(`/admin/users/${id}`),
  updateUserStatut: (id, statut) => api.patch(`/admin/users/${id}/statut`, { statut }),
  deleteUser: (id) => api.delete(`/admin/users/${id}`),
};

export default api;
