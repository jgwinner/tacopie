###
# sources
###
set(tacopie_sources
  sources/network/common/tcp_socket.cpp
  sources/network/io_service.cpp
  sources/network/tcp_client.cpp
  sources/network/tcp_server.cpp
  sources/utils/error.cpp
  sources/utils/logger.cpp
  sources/utils/thread_pool.cpp)

if (MSVC)
  list(APPEND tacopie_sources
    sources/network/windows/windows_self_pipe.cpp
    sources/network/windows/windows_tcp_socket.cpp)
else()
  list(APPEND tacopie_sources
    sources/network/unix/unix_self_pipe.cpp
    sources/network/unix/unix_tcp_socket.cpp)
endif()

###
# includes
###
set(tacopie_includes ${PROJECT_SOURCE_DIR}/includes)
