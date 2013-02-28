# Changelog

## 1.0.1 (February 27, 2013)
* use rb_wait_for_single_fd() on ruby 2.0 to fix rb_thread_select() deprecation
* fix epoll/kqueue mode in ruby 2.0 by removing calls to rb_enable_interrupt() [#248, #389]
* fix memory leak when verifying ssl cerificates [#403]
* fix initial connection delay [#393, #374]
