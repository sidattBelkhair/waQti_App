module.exports = (io) => {
  io.on('connection', (socket) => {
    console.log('[Socket] Connecte: ' + socket.id);

    socket.on('join_service', (serviceId) => {
      socket.join('service_' + serviceId);
      console.log('[Socket] ' + socket.id + ' -> service_' + serviceId);
    });

    socket.on('join_user', (userId) => {
      socket.join('user_' + userId);
      console.log('[Socket] ' + socket.id + ' -> user_' + userId);
    });

    socket.on('leave_service', (serviceId) => {
      socket.leave('service_' + serviceId);
    });

    socket.on('leave_user', (userId) => {
      socket.leave('user_' + userId);
    });

    socket.on('disconnect', () => {
      console.log('[Socket] Deconnecte: ' + socket.id);
    });
  });
};
