---
title: "典籍篇"
date: 2021-12-21
description: "开源文档典籍篇汇总"
lead: "聚社区之智，传技术之火"
disable_comments: false
authorbox: true
toc: false
mathjax: true
categories:
  - "开源文档"
tags:
  - "postgresql"

draft: true
---
[◀ 返回](/后端架构/后端架构-兵法篇/)
## postgresql 的组成结构

### 内存

- **Local memory area**:由每个后端进程分配给自己使用。

- **Share memory area**: 由 postgresql 服务器的所有进程使用。

![postgresql-memory](https://blowizer.oss-cn-beijing.aliyuncs.com/blog/%E6%95%B0%E6%8D%AE%E5%BA%93-PostgreSQL%E5%86%85%E5%AD%98%E7%BB%93%E6%9E%84.png)

- **work_mem**: 执行器执行 _order by_、_distinct_、_join tables_、*hash-join*操作时使用。

- **maintenance_work_mem**: _vacuum_ 归整、*reindex*重建索引，时使用。

- **temp_buffers**: 临时表使用。

- **shared_buffer_pool**: 从持久化的存储加载表页和索引页到此。

- **wal_buffer**: 防止服务异常停止导致数据没有落盘，创建了 wal 缓冲区，相当于 redo log。

- **commit log**: 记录所有的事务状态如:再处理，已提交、回退，保持事务的一致性。相当于 undo log。

### 进程

**PostgreSQL 采用 C/S 模式，系统为每个连接的客户端分配一个服务进程 Postgres**
![postgresql-process](https://blowizer.oss-cn-beijing.aliyuncs.com/blog/%E6%95%B0%E6%8D%AE%E5%BA%93-PostgreSQL%E8%BF%9B%E7%A8%8B.webp)

当运行 pg_ctl 命令进入 Postgres 程序时，其进程创建流程如下:
### PostMaster
![postgresql-process1](https://blowizer.oss-cn-beijing.aliyuncs.com/blog/%E6%95%B0%E6%8D%AE%E5%BA%93-PostgreSQ%E8%BF%9B%E7%A8%8B2.webp)

- **PostMaster**：进程是整个数据库实例的总控进程，负责启动关闭该数据实例。并且在服务进程出现错误时完成系统的恢复，还要在系统奔溃的时候重启系统。它是运行在服务器上的总控进程，同时也负责整个系统范围内的操作，例如中断操作与信号处理。但是 Postmaster 本身并不执行这些操作，而是指派一个子进程在适当的时间处理它们。Postmaster 进程在起始时会创建共享内存与信号库，用于与子进程的通信，同时也能在某个子进程奔溃的时候重置共享内存即可恢复。

*Postmaster 守护进程的执行流程如下*

![postgres-porcess2](https://blowizer.oss-cn-beijing.aliyuncs.com/blog/%E6%95%B0%E6%8D%AE%E5%BA%93-PostgreSQ%E8%BF%9B%E7%A8%8B2.webp)

### SysLogger
- **SysLogger**:（系统日志）进程,日志信息是数据库管理员获取数据库系统运行状态的有效手段。在数据库出现故障时，日志信息是非常有用的。把数据库日志信息集中输出到一个位置将极大方便管理员维护数据库系统。然而，日志输出将产生大量数据（特别是在比较高的调试级别上），单文件保存时不利于日志文件的操作。因此，在SysLogger的配置选项中可以设置日志文件的大小，SysLogger会在日志文件达到指定的大小时关闭当前日志文件，产生新的日志文件。

```shell
# - Where to Log -

log_destination = 'stderr'              # Valid values are combinations of
                                        # stderr, csvlog, jsonlog, syslog, and
                                        # eventlog, depending on platform.
                                        # csvlog and jsonlog require
                                        # logging_collector to be on.

# This is used when logging to stderr:
logging_collector = on          # Enable capturing of stderr, jsonlog,
                                        # and csvlog into log files. Required
                                        # to be on for csvlogs and jsonlogs.
                                        # (change requires restart)

# These are only used if logging_collector is on:
#log_directory = 'log'                  # directory where log files are written,
                                        # can be absolute or relative to PGDATA
#log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'        # log file name pattern,
                                        # can include strftime() escapes
#log_file_mode = 0600                   # creation mode for log files,
                                        # begin with 0 to use octal notation
#log_rotation_age = 1d                  # Automatic rotation of logfiles will
                                        # happen after that time.  0 disables.
#log_rotation_size = 10MB               # Automatic rotation of logfiles will
                                        # happen after that much log output.
                                        # 0 disables.
#log_truncate_on_rotation = off         # If on, an existing log file with the
                                        # same name as the new log file will be
                                        # truncated rather than appended to.
                                        # But such truncation only occurs on
                                        # time-driven rotation, not on restarts
                                        # or size-driven rotation.  Default is
                                        # off, meaning append to existing files
                                        # in all cases.

```
>**log_destination**：配置日志输出目标，根据不同的运行平台会设置不同的值，Linux下默认为stderr。
>
>**logging_collector**：是否开启日志收集器，当设置为on时启动日志功能；否则，系统将不产生系统日志辅助进程。
>
>**log_directory**：配置日志输出文件夹。
>
>**log_filename**s：配置日志文件名称命名规则。
>
>**log_rotation_size**：配置日志文件大小，当前日志文件达到这个大小时会被关闭，然后创建一个新的文件来作为当前日志文件。
### BgWriter
- **BgWriter**:（预写式日志）进程。把共享内存中的脏页写到磁盘上的进程。它的作用有两个：一是定期把脏数据从内存缓冲区刷出到磁盘中，减少查询时的阻塞；二是PG在定期作检查点时需要把所有脏页写出到磁盘，通过BgWriter预先写出一些脏页，可以减少设置检查点（CheckPoint，数据库恢复技术的一种）时要进行的IO操作，使系统的IO负载趋向平稳。BgWriter是PostgreSQL 8.0以后新加的特性，
```shell
# - Background Writer -
# 10-10000ms between rounds
bgwriter_delay = 200ms
# max buffers written/round, 0 disables
bgwriter_lru_maxpages = 100 
 # 0-10.0 multiplier on buffers scanned/round
bgwriter_lru_multiplier = 2.0
# measured in pages, 0 disables
bgwriter_flush_after = 0               

```
> **backgroud writer**:进程连续两次flush数据之间的时间的间隔。默认值是200，单位是毫秒。
>
> **bgwriter_lru_maxpages**：
backgroud writer进程每次写的最多数据量，默认值是100，单位buffers。如果脏数据量小于该数值时，写操作全部由backgroud writer进程完成；反之，大于该值时，大于的部分将有server process进程完成。设置该值为0时表示禁用backgroud writer写进程，完全有server process来完成；配置为-1时表示所有脏数据都由backgroud writer来完成。(这里不包括checkpoint操作)
>
> **bgwriter_lru_multiplier**：
这个参数表示每次往磁盘写数据块的数量，当然该值必须小于bgwriter_lru_maxpages。设置太小时需要写入的脏数据量大于每次写入的数据量，这样剩余需要写入磁盘的工作需要server process进程来完成，将会降低性能；值配置太大说明写入的脏数据量多于当时所需buffer的数量，方便了后面再次申请buffer工作，同时可能出现IO的浪费。该参数的默认值是2.0。
bgwriter的最大数据量计算方式：
`1000/bgwriter_delay*bgwriter_lru_maxpages*8K=最大数据量`
>
>**bgwriter_flush_after**：
数据页大小达到bgwriter_flush_after时触发BgWriter，默认是512KB。
### WalWriter
- **WalWriter**: 预写式日志WAL（Write Ahead Log，也称为Xlog）的中心思想是对数据文件的修改必须是只能发生在这些修改已经记录到日志之后，也就是先写日志后写数据（日志先行）。使用这种机制可以避免数据频繁的写入磁盘，可以减少磁盘I/O。数据库在宕机重启后可以运用这些WAL日志来恢复数据库。
```shell
#------------------------------------------------------------------------------
# WRITE AHEAD LOG
#------------------------------------------------------------------------------

# - Settings -

#wal_level = minimal                    # minimal, replica, or logical
                                        # (change requires restart)
#fsync = on                             # flush data to disk for crash safety
                                                # (turning this off can cause
                                                # unrecoverable data corruption)
#synchronous_commit = on                # synchronization level;
                                        # off, local, remote_write, remote_apply, or on
#wal_sync_method = fsync                # the default is the first option
                                        # supported by the operating system:
                                        #   open_datasync
                                        #   fdatasync (default on Linux)
                                        #   fsync
                                        #   fsync_writethrough
                                        #   open_sync
#full_page_writes = on                  # recover from partial page writes
#wal_compression = off                  # enable compression of full-page writes
#wal_log_hints = off                    # also do full page writes of non-critical updates
                                        # (change requires restart)
#wal_buffers = -1                       # min 32kB, -1 sets based on shared_buffers
                                        # (change requires restart)
#wal_writer_delay = 200ms               # 1-10000 milliseconds
#wal_writer_flush_after = 1MB           # measured in pages, 0 disables

#commit_delay = 0                       # range 0-100000, in microseconds
#commit_siblings = 5                    # range 1-1000
```
>**wal_level**：控制wal存储的级别。wal_level决定有多少信息被写入到WAL中。 默认值是最小的（minimal），其中只写入从崩溃或立即关机中恢复的所需信息。replica 增加 wal 归档信息 同时包括 只读服务器需要的信息。（9.6 中新增，将之前版本的 archive 和 hot_standby 合并） 
logical 主要用于logical decoding 场景
>
>**fsync**：该参数直接控制日志是否先写入磁盘。默认值是ON（先写入），表示更新数据写入磁盘时系统必须等待WAL的写入完成。可以配置该参数为OFF，表示更新数据写入磁盘完全不用等待WAL的写入完成。
>
>**synchronous_commit**：参数配置是否等待WAL完成后才返回给用户事务的状态信息。默认值是ON，表明必须等待WAL完成后才返回事务状态信息；配置成OFF能够更快地反馈回事务状态。
>
>**wal_sync_method**：WAL写入磁盘的控制方式，默认值是fsync，可选用值包括open_datasync、fdatasync、fsync_writethrough、fsync、open_sync。open_datasync和open_sync分别表示在打开WAL文件时使用O_DSYNC和O_SYNC标志；fdatasync和fsync分别表示在每次提交时调用fdatasync和fsync函数进行数据写入，两个函数都是把操作系统的磁盘缓存写回磁盘，但前者只写入文件的数据部分，而后者还会同步更新文件的属性；fsync_writethrough表示在每次提交并写回磁盘会保证操作系统磁盘缓存和内存中的内容一致。
>
>**full_page_writes**：表明是否将整个page写入WAL。
>
>**wal_buffers**：用于存放WAL数据的内存空间大小，系统默认值是64K，该参数还受wal_writer_delay、commit_delay两个参数的影响。 
>
>**wal_writer_delay**：WalWriter进程的写间隔时间，默认值是200毫秒，如果时间过长可能造成WAL缓冲区的内存不足；时间过短将会引起WAL的不断写入，增加磁盘I/O负担。 
>
>**wal_writer_flush_after**：指定 WAL 写入器刷写 WAL 的频繁程度，以卷为单位。 如果最近的刷写发生在 wal_writer_delay 之前，并且小于 wal_writer_flush_after WAL的值产生之后，那么WAL只会被写入操作系统，而不会被刷写到磁盘。 如果wal_writer_flush_after被设置为0，则WAL数据总是会被立即刷写。 如果指定值时没有单位，则以WAL块作为单位，即为XLOG_BLCKSZ字节，通常为8kB。 默认是1MB。
>
>**commit_delay**：表示一个已经提交的数据在WAL缓冲区中存放的时间，默认值是0毫秒，表示不用延迟；设置为非0值时事务执行commit后不会立即写入WAL中，而仍存放在WAL缓冲区中，等待WalWriter进程周期性地写入磁盘。
>
>**commit_siblings**：表示当一个事务发出提交请求时，如果数据库中正在执行的事务数量大于commit_siblings值，则该事务将等待一段时间（commit_delay的值）；否则该事务则直接写入WAL。系统默认值是5，该参数还决定了commit_delay的有效性。
>
>**wal_writer_flush_after**：当脏数据超过阈值时，会被刷出到磁盘。
### PgArch
- **PgArch**:（归档）进程,类似于Oracle数据库的ARCH归档进程，不同的是ARCH是吧redo log进行归档，PgArch是把WAL日志进行归档。再深入点，WAL日志会被循环使用，也就是说，过去的WAL日志会被新产生的日志覆盖，PgArch进程就是为了在覆盖前把WAL日志备份出来。归档日志的作用是为了数据库能够使用全量备份和备份后产生的归档日志，从而让数据库回到过去的任一时间点。PG从8.X版本开始提供的PITR（Point-In-Time-Recovery）技术，就是运用的归档日志。
```shell
# - Archiving -

#archive_mode = off             # enables archiving; off, on, or always
                                # (change requires restart)
#archive_command = ''           # command to use to archive a logfile segment
                                # placeholders: %p = path of file to archive
                                #               %f = file name only
                                # e.g. 'test ! -f /mnt/server/archivedir/%f && cp %p /mnt/server/archivedir/%f'
#archive_timeout = 0            # force a logfile segment switch after this
                                # number of seconds; 0 disables
```

>**archive_mode**：表示是否进行归档操作，可选择为off（关闭）、on（启动）和always（总是开启），默认值为off（关闭）。
>
>**archive_command**：由管理员设置的用于归档WAL日志的命令。在用于归档的命令中，预定义变量“%p”用来指代需要归档的WAL全路径文件名，“%f”表示不带路径的文件名（这里的路径都是相对于当前工作目录的路径）。每个WAL段文件归档时将调用archive_command所指定的命令。当归档命令返回0时，PostgreSQL就会认为文件被成功归档，然后就会删除或循环使用该WAL段文件。否则，如果返回一个非零值，PostgreSQL会认为文件没有被成功归档，便会周期性地重试直到成功。
>
>**archive_timeout**：表示归档周期，在超过该参数设定的时间时强制切换WAL段，默认值为0（表示禁用该功能）。
### AutoVacuum
- **AutoVacuum**:（系统自动清理）进程,在 PostgreSQL 数据库中，对表进行 DELETE 操作后，旧的数据并不会立即被删除，并且，在更新数据时，也并不会在旧的数据上做更新，而是新生成一行数据。旧的数据只是被标识为删除状态，只有在没有并发的其他事务读到这些旧数据时，他们才会被清除。这个清除工作就由 AutoVacuum 进程完成。
```shell
#------------------------------------------------------------------------------
# AUTOVACUUM PARAMETERS
#------------------------------------------------------------------------------

#autovacuum = on                        # Enable autovacuum subprocess?  'on'
                                        # requires track_counts to also be on.
#log_autovacuum_min_duration = -1       # -1 disables, 0 logs all actions and
                                        # their durations, > 0 logs only
                                        # actions running at least this number
                                        # of milliseconds.
#autovacuum_max_workers = 3             # max number of autovacuum subprocesses
                                        # (change requires restart)
#autovacuum_naptime = 1min              # time between autovacuum runs
#autovacuum_vacuum_threshold = 50       # min number of row updates before
                                        # vacuum
#autovacuum_analyze_threshold = 50      # min number of row updates before
                                        # analyze
#autovacuum_vacuum_scale_factor = 0.2   # fraction of table size before vacuum
#autovacuum_analyze_scale_factor = 0.1  # fraction of table size before analyze
#autovacuum_freeze_max_age = 200000000  # maximum XID age before forced vacuum
                                        # (change requires restart)
#autovacuum_multixact_freeze_max_age = 400000000        # maximum multixact age
                                        # before forced vacuum
                                        # (change requires restart)
#autovacuum_vacuum_cost_delay = 20ms    # default vacuum cost delay for
                                        # autovacuum, in milliseconds;
                                        # -1 means use vacuum_cost_delay
#autovacuum_vacuum_cost_limit = -1      # default vacuum cost limit for
                                        # autovacuum, -1 means use
                                        # vacuum_cost_limit
```
>**autovacuum**：是否启动系统自动清理功能，默认值为on。
>
>**log_autovacuum_min_duration**：这个参数用来记录 autovacuum 的执行时间，当 autovaccum 的执行时间超过 log_autovacuum_min_duration参数设置时，则autovacuum信息记录到日志里，默认为 "-1", 表示不记录。 
>
>**autovacuum_max_workers**：设置系统自动清理工作进程的最大数量。
>
>**autovacuum_naptime**：设置两次系统自动清理操作之间的间隔时间。
>
>**autovacuum_vacuum_threshold**和**autovacuum_analyze_threshold**：设置当表上被更新的元组数的阈值超过这些阈值时分别需要执行vacuum和analyze。
>
>**autovacuum_vacuum_scale_factor**和**autovacuum_analyze_scale_factor**：设置表大小的缩放系数。
>
>**autovacuum_freeze_max_age**：设置需要强制对数据库进行清理的XID上限值。
>
>**autovacuum_vacuum_cost_delay**：当autovacuum进程即将执行时，对 vacuum 执行 cost 进行评估，如果超过 autovacuum_vacuum_cost_limit设置值时，则延迟，这个延迟的时间即为 autovacuum_vacuum_cost_delay。如果值为 -1, 表示使用 vacuum_cost_delay 值，默认值为 20 ms。
>
>**autovacuum_vacuum_cost_limit**：这个值为 autovacuum 进程的评估阀值, 默认为 -1, 表示使用 "vacuum_cost_limit " 值，如果在执行 autovacuum 进程期间评估的cost 超过 autovacuum_vacuum_cost_limit, 则 autovacuum 进程则会休眠。
### Pgstat
- **Pgstat**:（统计收集）进程,做数据的统计收集工作。主要用于查询优化时的代价估算，包括一个表和索引进行了多少次的插入、更新、删除操作。磁盘块读写的次数、行的读次数。pg_statistic 中存储了 PgStat 收集的各类信息。
```shell
#------------------------------------------------------------------------------
# RUNTIME STATISTICS
#------------------------------------------------------------------------------

# - Query/Index Statistics Collector -

#track_activities = on
#track_counts = on
#track_io_timing = off
#track_functions = none                 # none, pl, all
#track_activity_query_size = 1024       # (change requires restart)
#stats_temp_directory = 'pg_stat_tmp'
```
>**track_activities**：表示是否对会话中当前执行的命令开启统计信息收集功能，该参数只对超级用户和会话所有者可见，默认值为on（开启）。
>
>**track_counts**：表示是否对数据库活动开启统计信息收集功能，由于在AutoVacuum自动清理进程中选择清理的数据库时，需要数据库的统计信息，因此该参数默认值为on。
>
>**track_io_timing**：定时调用数据块I/O，默认是off，因为设置为开启状态会反复的调用数据库时间，这给数据库增加了很多开销。只有超级用户可以设置
>
>**track_functions**：表示是否开启函数的调用次数和调用耗时统计。
>
>**track_activity_query_size**：设置用于跟踪每一个活动会话的当前执行命令的字节数，默认值为1024，只能在数据库启动后设置。
>
>**stats_temp_directory**：统计信息的临时存储路径。路径可以是相对路径或者绝对路径，参数默认为pg_stat_tmp，设置此参数可以减少数据库的物理I/O，提高性能。此参数只能在postgresql.conf文件或者服务器命令行中修改。

### CheckPoint
- **CheckPoint**:（检查点）进程,checkpoint 又名检查点，一般 checkpoint 会将某个时间点之前的脏数据全本刷新到磁盘，以实现数据的一致性与完整性。目前各个流行的关系型数据库都具备 checkpoint 功能，其主要目的是为了缩短崩溃恢复时间，以 Oracle 为例，在进行数据恢复时，会以最近的 Checkpoint 为参考点执行事务前滚。而在 WAL 机制的浅析中，也提过 PostgreSQL 在崩溃恢复时会以最近的 Checkpoint 为基础，不断应用之后的 WAL 日志。

```shell
# - Checkpoints -

#checkpoint_timeout = 5min              # range 30s-1d
#max_wal_size = 1GB
#min_wal_size = 80MB
#checkpoint_completion_target = 0.5     # checkpoint target duration, 0.0 - 1.0
#checkpoint_flush_after = 256kB         # measured in pages, 0 disables
#checkpoint_warning = 30s               # 0 disables
```

[参考地址](https://postgresqlco.nf/doc/zh/param/)

![image](https://blowizer.oss-cn-beijing.aliyuncs.com/blog/%E6%95%B0%E6%8D%AE%E5%BA%93-PostgreSQ%E8%BF%9B%E7%A8%8B3.webp)
---
[◀ 返回](/后端架构/后端架构-兵法篇/)