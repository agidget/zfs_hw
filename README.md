#ZFS

##Описание домашнего задания
1. Определить алгоритм с наилучшим сжатием
Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);
Создать 4 файловых системы на каждой применить свой алгоритм сжатия;
Для сжатия использовать либо текстовый файл, либо группу файлов:
2. Определить настройки пула
С помощью команды zfs import собрать pool ZFS;
Командами zfs определить настройки:
    - размер хранилища;
    - тип pool;
    - значение recordsize;
    - какое сжатие используется;
    - какая контрольная сумма используется.
3. Работа со снапшотами
скопировать файл из удаленной директории.   https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing 
восстановить файл локально. zfs receive
найти зашифрованное сообщение в файле secret_message

##0. Подготовка виртуальной машины
Тк у Centos7 проблемы с монтированием папок (требуется обновление ядра - https://www.puppeteers.net/blog/fixing-vagrant-vbguest-for-the-centos-7-base-box/), то при `vagrant up` выходит ошибка монтирования. Поэтому для подготовки стенда используется затем команда `vagrant provision` для запуска скрипта.
```
vagrant up
vagrant provision
vagrant ssh
sudo -i
```

##1. Определить алгоритм с наилучшим сжатием
Смотрим список всех дисков, которые есть в виртуальной машине:
```bash
[root@localhost ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk 
sdc      8:32   0  512M  0 disk 
sdd      8:48   0  512M  0 disk 
sde      8:64   0  512M  0 disk 
sdf      8:80   0  512M  0 disk 
sdg      8:96   0  512M  0 disk 
sdh      8:112  0  512M  0 disk 
sdi      8:128  0  512M  0 disk 
```
Создаём пул из 4 дисков в режиме RAID 1:
```bash
[root@localhost ~]# zpool create otus1 mirror /dev/sd{b,c}
[root@localhost ~]# zpool create otus2 mirror /dev/sd{d,e}
[root@localhost ~]# zpool create otus3 mirror /dev/sd{f,g}
[root@localhost ~]# zpool create otus4 mirror /dev/sd{h,i}
```
Смотрим информацию о пулах:
```bash
[root@localhost ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   100K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M   100K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   100K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M   100K   480M        -         -     0%     0%  1.00x    ONLINE  -
```
Добавим разные алгоритмы сжатия в каждую файловую систему и проверим:
```bash
[root@localhost ~]# zfs set compression=lzjb otus1
[root@localhost ~]# zfs set compression=lz4 otus2
[root@localhost ~]# zfs set compression=gzip-9 otus3
[root@localhost ~]# zfs set compression=zle otus4
[root@localhost ~]# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
```
Скачаем один и тот же текстовый файл во все пулы и проверим: 
```bash
[root@localhost ~]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
--2023-01-03 10:36:16--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus1/pg2600.converter.log’

100%[==============================================================================================================================>] 40,894,017  1.44MB/s   in 39s    

2023-01-03 10:36:57 (1.00 MB/s) - ‘/otus1/pg2600.converter.log’ saved [40894017/40894017]

--2023-01-03 10:36:57--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus2/pg2600.converter.log’

100%[==============================================================================================================================>] 40,894,017   952KB/s   in 47s    

2023-01-03 10:37:45 (850 KB/s) - ‘/otus2/pg2600.converter.log’ saved [40894017/40894017]

--2023-01-03 10:37:45--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus3/pg2600.converter.log’

100%[==============================================================================================================================>] 40,894,017   790KB/s   in 54s    

2023-01-03 10:38:40 (736 KB/s) - ‘/otus3/pg2600.converter.log’ saved [40894017/40894017]

--2023-01-03 10:38:40--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus4/pg2600.converter.log’

100%[==============================================================================================================================>] 40,894,017  1002KB/s   in 39s    

2023-01-03 10:39:21 (1022 KB/s) - ‘/otus4/pg2600.converter.log’ saved [40894017/40894017]

[root@localhost ~]# ls -l /otus*
/otus1:
total 22036
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus2:
total 17981
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus3:
total 10953
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus4:
total 39963
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log
```
Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:
```bash
[root@localhost ~]# zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.7M   330M     21.5M  /otus1
otus2  17.7M   334M     17.6M  /otus2
otus3  10.8M   341M     10.7M  /otus3
otus4  39.2M   313M     39.0M  /otus4

[root@localhost ~]# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.81x                  -
otus2  compressratio         2.22x                  -
otus3  compressratio         3.63x                  -
otus4  compressratio         1.00x                  -
```
Получается, что алгоритм gzip-9 самый эффективный по сжатию. 


##2.Определение настроек пула
Скачиваем архив в домашний каталог и разархивируем его:
```bash
[root@localhost ~]# wget -O archive.tar.gz --no-check-certificate https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download
2023-01-03 10:47:25 (479 KB/s) - ‘archive.tar.gz’ saved [7275140/7275140]
[1]+  Done                    wget -O archive.tar.gz --no-check-certificate https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg

[root@localhost ~]# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```
Проверим, возможно ли импортировать данный каталог в пул:
```bash
[root@localhost ~]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                         ONLINE
          mirror-0                   ONLINE
            /root/zpoolexport/filea  ONLINE
            /root/zpoolexport/fileb  ONLINE
```
Сделаем импорт данного пула к нам в ОС:
```bash
[root@localhost ~]# zpool import -d zpoolexport/ otus
[root@localhost ~]# zpool status
  pool: otus
 state: ONLINE
status: Some supported features are not enabled on the pool. The pool can
        still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(5) for details.
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```
Проверим различные параметры пула:
- тип пула:
```bash
[root@localhost ~]# zfs get type otus
NAME  PROPERTY  VALUE       SOURCE
otus  type      filesystem  -
```
- кол-во доступного места:
```bash
[root@localhost ~]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
```
- recordsize (specifies a suggested block size for files in the file system):
```bash
[root@localhost ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
```
- тип сжатия:
```bash
[root@localhost ~]# zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
```
- тип контрольной суммы:
```bash
[root@localhost ~]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```

##3.Работа со снапшотами
Скачаем файл:
```bash
[root@localhost ~]# wget -O otus_task2.file --no-check-certificate https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download
2023-01-03 11:14:48 (358 KB/s) - ‘otus_task2.file’ saved [5432736/5432736]
[1]+  Done                    wget -O otus_task2.file --no-check-certificate https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG
```
Восстановим файловую систему из снапшота:
```bash
zfs receive otus/test@today < otus_task2.file
```
Ищем в каталоге /otus/test файл с именем “secret_message” и смотрим содержимое:
```bash
[root@localhost ~]# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
[root@localhost ~]# cat /otus/test/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome
```