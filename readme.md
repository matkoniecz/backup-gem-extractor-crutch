example of usage:

```
archive_storage_root = '/media/mateusz/Database/laptop_backup'
unpack_root = '/backup_test/'
puts "password?"

password = STDIN.noecho(&:gets).chomp

#unpacks archive named selected_system_settings from location specified in archive_storage_root
process_given_archive(archive_storage_root, 'selected_system_settings', unpack_root, password) 
#unpacks archive named music
process_given_archive(archive_storage_root, 'music', unpack_root, password)

#compares content of /home/mateusz/Music/ with /backup_test/home/mateusz/Music/ and prints mismatching files
compare('/home/mateusz/Music/', unpack_root)
```

At this moment this script is able to process basically only the archive format that I am using.

If you are interested in using this script with other configuration of backup gem - create an issue on bugtracker. It will bump rewriting this cript on my TODO list. PRs are obviously welcomed.