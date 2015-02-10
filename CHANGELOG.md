# Changelog

## 1.0.7 (February 10, 2015)
* fix delay in kqueue/epoll reactor shutdown when timers exist [#587]
* fix memory leak introduced in v1.0.5 [#586]
* expose EM.set_simultaneous_accept_count [#420]
* fix busy loop when EM.run and EM.next_tick are invoked from exception handler [#452]

## 1.0.6 (February 3, 2015)
* add support for Rubinius Process::Status [#568]
* small bugfixes for SmtpServer [#449]
* update buftok.rb [#547]
* fix assertion on Write() [#525]
* work around mkmf.rb bug preventing gem installation [#574]
* add pause/resume support to jruby reactor [#556]
* fix pure ruby reactor to use 127.0.0.1 instead of localhost [#439]
* fix compilation under macruby [#243]
* add chunked encoding to http client [#111]
* fix errors on win32 when dealing with pipes [1ea45498] [#105]

## 1.0.5 (February 2, 2015)
* use monotonic clocks on Linux, OS X, Solaris, and Windows [#563]
* use the rb_fd_* API to get autosized fd_sets [#502]
* add basic tests that the DNS resolver isn't leaking timers [#571]
* update to test-unit 2.x and improve various unit tests [#551]
* remove EventMachine_t::Popen code marked by ifdef OBSOLETE [#551]
* ruby 2.0 may fail at Queue.pop, so rescue and complain to $stderr [#551]
* set file handle to INVALID_HANDLE_VALUE after closing the file [#565]
* use `defined?` instead of rescuing NameError for flow control [#535]
* fix closing files and sockets on Windows [#564]
* fix file uploads in Windows [#562]
* catch failure to fork [#539]
* use chunks for SSL write [#545]

## 1.0.4 (December 19, 2014)
* add starttls_options to smtp server [#552]
* fix closesocket on windows [#497]
* fix build on ruby 2.2 [#503]
* fix build error on ruby 1.9 [#508]
* fix timer leak during dns resolution [#489]
* add concurrency validation to EM::Iterator [#468]
* add get_file_descriptor to get fd for a signature [#467]
* add EM.attach_server and EM.attach_socket_server [#465, #466]
* calling pause from receive_data takes effect immediately [#464]
* reactor_running? returns false after fork [#455]
* fix infinite loop on double close [edc4d0e6, #441, #445]
* fix compilation issue on llvm [#433]
* fix socket error codes on win32 [ff811a81]
* fix EM.stop latency when timers exist [8b613d05, #426]
* fix infinite loop when system time changes [1427a2c80, #428]
* fix crash when callin attach/detach in the same tick [#427]
* fix compilation issue on solaris [#416]

## 1.0.3 (March 8, 2013)
* EM.system was broken in 1.0.2 release [#413]

## 1.0.2 (March 8, 2013)
* binary win32 gems now include fastfilereader shim [#222]
* fix long-standing connection timeout issues [27fdd5b, igrigorik/em-http-request#222]
* http and line protocol cleanups [#193, #151]
* reactor return value cleanup [#225]
* fix double require from gemspec [#284]
* fix smtp server reset behavior [#351]
* fix EM.system argument handling [#322]
* ruby 1.9 compat in smtp server and stomp protocols [#349, #315]
* fix pause from post_init [#380]

## 1.0.1 (February 27, 2013)
* use rb_wait_for_single_fd() on ruby 2.0 to fix rb_thread_select() deprecation [#363]
* fix epoll/kqueue mode in ruby 2.0 by removing calls to rb_enable_interrupt() [#248, #389]
* fix memory leak when verifying ssl cerificates [#403]
* fix initial connection delay [#393, #374]
* fix build on windows [#371]
