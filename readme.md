to install run

```
gem install --user-install backup_restore
```

example of usage:

```
require 'backup_restore'
archive_storage_root = '/media/mateusz/Database/laptop_backup'
unpack_root = '/backup_test/'
puts "password?"

password = STDIN.noecho(&:gets).chomp

#unpacks archive named music from location specified in archive_storage_root
BackupRestore.process_given_archive(archive_storage_root, 'music', unpack_root, password)

#compares content of /home/mateusz/Music/ with /backup_test/home/mateusz/Music/ and prints mismatching files
BackupRestore.compare('/home/mateusz/Music/', unpack_root)
```

At this moment this script is able to process basically only the archive format that I am using.

If you are interested in using this script with other configuration of backup gem - create an issue on the bugtracker. PRs are obviously welcomed.