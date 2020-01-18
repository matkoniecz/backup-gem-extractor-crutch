# Copyright (C) 2016 - GPLv3 - Mateusz Konieczny

require 'io/console'
require 'fileutils'

# some assumptions:
# this tool runs on Ubuntu
# archive is valid archive generated with backup gem
# files are encrypted and archived with tar
# archives may be split or not

class BackupRestore
  class PreconditionFailed < StandardError
  end
  def self.debug(message, priority = :medium)
    return if priority == :low
    return if priority == :medium
    puts message
  end

  def self.change_directory(target)
    Dir.chdir(target)
    return if File.identical?(target, Dir.getwd)
    raise "failed to change working directory to #{target} (it is #{Dir.getwd})"
  end

  def self.get_storage_folder(archive_storage_root, archive_name)
    debug("joining <#{archive_storage_root}> and <#{archive_name}>", :low)
    target = archive_storage_root + '/' + archive_name
    debug("looking for date folder in <#{target}>", :low)
    change_directory(target)
    directory = Dir.glob('*').select { |f| File.directory? f }
    if directory.length != 1
      puts "unexpected multiple backups at once in #{target}, or backup not found"
      puts "not supposed to happen in my workflow"
      puts "listing #{directory.length} directories, expected exactly 1:"
      directory.each do |file|
        puts file
      end
      raise "unhandled workflow"
    end
    target += '/' + directory[0] + '/'
    return target
  end

  # alternatives - see http://stackoverflow.com/questions/3159945/running-command-line-commands-within-ruby-script
  def self.execute_command(command, unstandard_error_free_exit_codes = [])
    output = `#{command}`
    if $?.success? || unstandard_error_free_exit_codes.include?($?.exitstatus)
      debug('all done', :low)
      return output
    end
    raise "<#{command}> command had problem (<#{$?}> with output <#{output}>). Working directory path was <#{Dir.getwd}>"
  end

  def self.extract_tar_file(file, target_folder = nil)
    command = "tar --extract --file=#{file}"
    unless target_folder.nil?
      command += " --preserve-permissions -C '#{target_folder}'"
      # -C
      # tar will change its current directory to dir before performing any operations
      # https://www.gnu.org/software/tar/manual/html_node/Option-Summary.html
    end
    # base test:
    # echo "tar: Removing leading \`/' from member names" | grep -v "tar: Removing leading \`/' from member names"
    # shell should get:
    # grep -v "tar: Removing leading \`/' from member names"
    # command += ' | grep -v "tar: Removing leading \`/\' from member names"'
    # the code above is not proper way to solve this, it will mess up errorcode (hide errors, grep will return error on lack of match)
    execute_command(command)
  end

  def self.get_the_only_expected_file(filter = '*')
    files = Dir.glob(filter)
    puts files
    if files.length != 1
      if files.empty?
        puts 'no files found'
      else
        puts "files:"
      end
      files.each do |file|
        puts file
      end
      raise "expected exactly one file, not handled!"
    end
    return files[0]
  end

  def self.uncrypt_archive(archive_storage_root, archive_name, password)
    storage = get_storage_folder(archive_storage_root, archive_name)
    output_archive = archive_name + '.tar'
    change_directory(storage)
    command = "openssl aes-256-cbc -d -in '#{archive_name}.tar.enc' -k '#{password}' -out '#{output_archive}'"
    execute_command(command)
  end

  def self.extract_archive(archive_storage_root, archive_name, unpack_root)
    debug("unpacking <#{archive_name}>", :high)

    storage = get_storage_folder(archive_storage_root, archive_name)
    change_directory(storage)
    debug("archive is stored at <#{storage}>")

    file = get_the_only_expected_file('*.tar')
    debug("extracting #{file}")
    extract_tar_file(file)
    folder_with_unpacked_archive = storage + archive_name
    debug("unpacked archive with second layer of archive is stored at <#{folder_with_unpacked_archive}>")

    change_directory(folder_with_unpacked_archive + '/archives/')
    file = get_the_only_expected_file('*.tar.gz')
    debug("extracting #{file}")
    extract_tar_file(file, unpack_root)

    change_directory(storage)
    FileUtils.rm_rf(folder_with_unpacked_archive)
  end

  def self.is_unsplitting_necessary(archive_storage_root, archive_name)
    storage = get_storage_folder(archive_storage_root, archive_name)
    return File.exist?(storage + "#{archive_name}.tar.enc-aaa")
  end

  def self.unsplit_archive(archive_storage_root, archive_name)
    storage = get_storage_folder(archive_storage_root, archive_name)
    change_directory(storage)
    if archive_name.include?(" ")
      raise "archive name was assumed to not have spaces but it is #{archive_name}"
    end
    execute_command("cat #{archive_name}.tar.enc-* > '#{archive_name}.tar.enc'")
  end

  def self.validate_folder_parameters(archive_storage_root, unpack_root)
    unless File.exist?(archive_storage_root)
      raise PreconditionFailed.new("archive_storage_root (<#{archive_storage_root}>) does not exists")
    end
    unless File.exist?(unpack_root)
      raise PreconditionFailed.new("unpack_root (<#{unpack_root}>) does not exists")
    end
    unless Dir.exist?(archive_storage_root)
      raise PreconditionFailed.new("archive_storage_root (<#{archive_storage_root}>) is a file, not directory")
    end
    unless Dir.exist?(unpack_root)
      raise PreconditionFailed.new("unpack_root (<#{unpack_root}>) is a file, not directory")
    end
  end

  def self.process_given_archive(archive_storage_root, archive_name, unpack_root, password)
    debug("processsing #{archive_name} in #{archive_storage_root} - extracting to #{unpack_root}", :high)
    validate_folder_parameters(archive_storage_root, unpack_root)
    # archive may be in form of
    # (1) file(s) $NAME.tar.enc-aaa, $NAME.tar.enc-aab, $NAME.tar.enc-aac ...
    # (2) single  $NAME.tar.enc
    if is_unsplitting_necessary(archive_storage_root, archive_name)
      unsplit_archive(archive_storage_root, archive_name)
    end

    # now $NAME.tar.enc exists with the entire archive
    uncrypt_archive(archive_storage_root, archive_name, password)
    # now $NAME.tar exists with the entire archive unencrypted

    # now $NAME.tar.enc can be now deleted if it was created
    # it MUST NOT be deleted if archive was not split - in that case
    # it is the original archive file!
    # it is deleted at this step to reduce peak memory consumption on disk
    # for unpacking large archives
    if is_unsplitting_necessary(archive_storage_root, archive_name)
      storage = get_storage_folder(archive_storage_root, archive_name)
      FileUtils.rm_rf(storage + archive_name + ".tar.enc")
    end

    extract_archive(archive_storage_root, archive_name, unpack_root)
    storage = get_storage_folder(archive_storage_root, archive_name)
    FileUtils.rm_rf(storage + archive_name + ".tar")
  end

  def self.compare(compared_path, unpack_root)
    text = compare_paths(compared_path, unpack_root)
    return text
  end

  class UnexpectedData < StandardError
    def self.initialize(message)
      super(message)
    end
  end

  def self.discard_unimportant(text, unimportant_paths_array, possible_prefix = [])
    possible_prefix << ""
    output = ""
    text.split("\n").each do |line|
      line.strip!
      unimportant = false
      unimportant_paths_array.each do |filter|
        possible_prefix.each do |prefix|
          r_filter = (Regexp.escape filter).gsub('/', '\/')
          r_prefix = (Regexp.escape prefix).gsub('/', '\/')
          if line =~ /\AOnly in (.+): (.+)\z/
            filepath_without_file, file = /\AOnly in (.+): (.+)\z/.match(line).captures
            filepath_without_file += '/' if filepath_without_file[-1] != '/'
            filepath = filepath_without_file + file
            unimportant = true if filepath =~ /\A#{r_prefix}#{r_filter}.*\z/
          elsif line =~ /\AFiles (.+) and (.+) differ\z/
            filepath_a, filepath_b = /\AFiles (.+) and (.+) differ\z/.match(line).captures
            unimportant = true if filepath_a =~ /\A#{r_prefix}#{r_filter}.*\z/
            unimportant = true if filepath_b =~ /\A#{r_prefix}#{r_filter}.*\z/
          elsif line =~ /\AFile (.+) is a fifo while file (.+) is a fifo\z/
            unimportant = true
          elsif line =~ /\AFile (.+) is a character special file while file (.+) is a character special file\z/
            unimportant = true
          elsif line == everything_is_fine_message.strip
            next
          elsif line == ""
            next
          else
            raise UnexpectedData, "unexpected line <#{line}>"
          end
        end
      end
      next if unimportant
      output += line + "\n"
    end
    puts
    return nil if output == ""
    return output.to_s
  end

  def self.everything_is_fine_or_unimportant_message
    "no important differences"
  end

  def self.compare_paths(path_to_backuped, backup_location)
    original = path_to_backuped
    restored = backup_location + path_to_backuped
    raise "missing folder for comparison: #{original}" unless Dir.exist?(original)
    raise "missing folder for comparison: #{restored}" unless Dir.exist?(restored)
    command = "diff --brief -r --no-dereference '#{original}' '#{restored}'"
    puts
    puts command
    puts
    returned = execute_command(command, [1])
    if returned == ""
      return everything_is_fine_message
    else
      return returned
    end
  end

  def self.everything_is_fine_message
    return "everything is fine!" + "\n"
  end
end
