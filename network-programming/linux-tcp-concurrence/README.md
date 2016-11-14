1. linux平台上的TCP并发服务（8学时）
掌握基本套接字函数使用方法、TCP协议工作原理、并发服务原理和编程方法。实验内容：在linux平台上实现1个TCP并发服务器，至少可以为10个客户端同时提供服务。
(1) 基于TCP套接字编写服务器端程序代码，然后编译和调试；
(2) 服务器程序要达到：可以绑定从终端输入的IP地址和端口；可以显示每一个进程的进程号；可以显示当前并发执行的进程数量；可以根据客户机要求的服务时间确定进程的生存时间。
(3) 基于TCP套接字编写客户端程序代码，然后编译和调试；
(4) 客户端程序要达到：可以从终端输入服务器的IP地址和端口；可以从终端输入对服务器的服务时间要求。
(5) 联调服务器和客户端，服务器每收到一个连接就新建一个子进程，在子进程中接收客户端的服务时间请求，根据所请求的时间进行延时，然后终止子进程。如：客户端请求服务10s，则服务器的子进程运行10s，然后结束。
(6) 服务器要清除因并发服务而产生的僵尸进程。



---

Linux 高性能服务器编程
75 -- 创建 socket
值得指出的是，自 Linux 内核版本 2.6.17 起，type 参数可以接收上述服务类型与下面两个重要的标志相与的值： SOCK_NONBLOCK 和 SOCK_CLOEXEC。他们分别表示将新创建的 socket 设置为非阻塞的，以及用 fork 调用创建子进程时在子进程中关闭该 socket。
126
对 accept、send 和 recv 而言，事件未发生时 errno 通常被设置成 EAGAIN(再来一次) 或者 EWOULDBLOCK(期望阻塞)；对 connect 而言，errno 则被设置成 EINPROGRESS(在处理中)。
I/O 复用函数本身是阻塞的，它们能提高程序效率的原因在于它们具有同时监听多个 I/O 事件的能力。
SIGIO 信号可以用来报告 I/O 事件。可以为一个目标文件描述符指定宿主进程，那么被指定的宿主进程将捕捉到 SIGIO 信号。这样，当目标文件描述符上有事件发生时，SIGIO 信号的信号处理函数将被出发，也就可以在该信号处理函数中对目标文件描述符执行非阻塞 I/O 操作了。
同步 I/O 模型要求用户代码自行执行 I/O 操作(将数据从内核缓冲区读入用户缓冲区，或将数据从用户缓冲区写入内核缓冲区)；异步 I/O 机制仄由内核来执行 I/O 操作(数据在内核缓冲区和用户缓冲区之间的移动是由内核在“后台”完成的)同步 I/O 向应用程序通知的是就绪事件，而异步 I/O 向应用程序通知的是 I/O 完成事件。
267 -- 在进程间传递文件描述符
由于 fork 调用之后，父进程中打开的文件描述符在子进程中仍然保持打开，所以文件描述符可以很方便地从父进程传递到子进程。需要注意的是，传递一个文件描述符并不是传递一个文件描述符的值，而是要在接收进程中创建一个新的文件描述符，并且该文件描述符和发送进程中被传递的文件描述符指向内核中相同的文件表项。