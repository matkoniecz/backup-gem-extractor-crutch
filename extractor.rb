# Encoding: utf-8
#Copyright (C) 2016 - GPLv3 - Mateusz Konieczny

require 'io/console'
require 'fileutils'

#some assumptions:
#archive is valid
#files are encrypted and archived with tar
#archives may be split

def debug(message, priority=:medium)
	if priority ==  :low
		return
	end
	puts message
end

def get_storage_folder(archive_storage_root, archive_name)
	debug("joining <#{archive_storage_root}> and <#{archive_name}>", :low)
	target = archive_storage_root + '/' + archive_name
	debug("looking for date folder in <#{target}>", :low)
	Dir.chdir(target)
	directory = Dir.glob('*').select {|f| File.directory? f}
	raise "unexpected multiple backups at once, not supposed to happen in my workflow" unless (directory.length == 1)
	target += '/' + directory[0] + '/'
	return target
end

#alternatives - see http://stackoverflow.com/questions/3159945/running-command-line-commands-within-ruby-script
def execute_command(command, unstandard_error_free_exit_codes=[])
	output = `#{command}`
	if $?.success? or unstandard_error_free_exit_codes.include?($?.exitstatus)
		debug('all done', :low)
	else
		raise "<#{command}> command had problem (<#{$?}> with output <#{output}>)"
	end
	return output
end

def extract_tar_file(file, target_folder=nil)
	command = "tar xf #{file}"
	if target_folder != nil
		command += " --preserve-permissions -C #{target_folder}"
	end
	execute_command(command)
end

def get_the_only_expected_file(filter='*')
	files = Dir.glob(filter)
	puts files
	if files.length != 1
		if files.length == 0
			puts 'no files found'
		else
			puts "files:"
		end
		for file in files
			puts file
		end
		raise "expected exactly one file, not handled!"
	end
	return files[0]
end

def uncrypt_archive(archive_storage_root, archive_name, password)
	storage = get_storage_folder(archive_storage_root, archive_name)
	output_archive = archive_name + '.tar'
	Dir.chdir(storage)
	command = "openssl aes-256-cbc -d -in #{archive_name}.tar.enc -k #{password} -out #{output_archive}"
	execute_command(command)
end

def extract_archive(archive_storage_root, archive_name, unpack_root)
	storage = get_storage_folder(archive_storage_root, archive_name)
	Dir.chdir(storage)
	debug("archive is stored at <#{storage}>")

	file = get_the_only_expected_file('*.tar')
	debug("extracting #{file}")
	extract_tar_file(file)
	folder_with_unpacked_archive = storage + archive_name
	debug("unpacked archive with second layer of archive is stored at <#{folder_with_unpacked_archive}>")	

	Dir.chdir(folder_with_unpacked_archive + '/archives/')
	file = get_the_only_expected_file('*.tar.gz')
	debug("extracting #{file}")
	extract_tar_file(file, unpack_root)

	Dir.chdir(storage)
	FileUtils.rm_rf(folder_with_unpacked_archive)
end

def is_unsplitting_necessary(archive_storage_root, archive_name)
	storage = get_storage_folder(archive_storage_root, archive_name)
	return File.exists?(storage + "#{archive_name}.tar.enc-aaa")
end

def unsplit_archive(archive_storage_root, archive_name)
	storage = get_storage_folder(archive_storage_root, archive_name)
	Dir.chdir(storage)
	execute_command("cat #{archive_name}.tar.enc-* > #{archive_name}.tar.enc")
end

def process_given_archive(archive_storage_root, archive_name, unpack_root, password)
	if(is_unsplitting_necessary(archive_storage_root, archive_name))
		unsplit_archive(archive_storage_root, archive_name)
	end
	uncrypt_archive(archive_storage_root, archive_name, password)
	extract_archive(archive_storage_root, archive_name, unpack_root)
	storage = get_storage_folder(archive_storage_root, archive_name)
	if(is_unsplitting_necessary(archive_storage_root, archive_name))
		FileUtils.rm_rf(storage+archive_name+".tar.enc")
	end
	FileUtils.rm_rf(storage+archive_name+".tar")
end

def compare(compared_path, unpack_root)
	command = "diff --brief -r #{compared_path} #{unpack_root+compared_path}"
	puts
	puts command
	returned = execute_command(command, [1])
	if returned == ""
		puts "everything is fine!"
	else
		puts returned
	end
end

def directory_size(path)
  size=0
  Dir.glob(File.join(path, '**', '*')) { |file| size+=File.size(file) }
  return size
end

def is_it_at_least_this_size_in_mb(path, mb)
	size = directory_size(path)
	return size > mb*1024*1024
end