Note: currently it assumes that it was encrypted with OpenSSL 1.1+

Revert 3424c70 if that is not true and encrypted with an earlier OpenSSL.

## purpose

[Backup gem](https://github.com/backup/backup) is a decent tool to create archives for storage. Unfortunately built-in restore tool is [missing and unlikely to appear](https://github.com/backup/backup-features/issues/28). This script was created to automate extraction of my backups. It is used to

 - automate restore after data loss
 - automate restoration and comparison of files after creating backup (to check whatever backup was generated correctly)

## install

```
gem install --user-install backup_restore
```

## use

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

## tests

Use `rspec` to run tests.

## similar tools

I was unable to find any tool like this, that is why I created this script.

## website

Currently at [https://github.com/matkoniecz/backup-gem-extractor-crutch](https://github.com/matkoniecz/backup-gem-extractor-crutch)
