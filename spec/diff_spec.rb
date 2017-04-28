require_relative '../extractor'
require 'fileutils'

def simulated_backup_location(name)
  dir = File.dirname(__FILE__)
  simulated_backup_location = "#{dir}/#{name}/copy"
  return simulated_backup_location
end

def run_test_named(name)
  dir = File.dirname(__FILE__)
  target = "#{simulated_backup_location(name)}/#{dir}/#{name}/before/"
  FileUtils.mkdir_p(target)
  FileUtils.copy_entry("#{dir}/#{name}/after/", target)
  returned = compare_paths("#{dir}/#{name}/before/", simulated_backup_location(name))
  FileUtils.remove_dir(target)
  return returned
end

def expected_message_for_differing_file(test_name, file)
  return "Files #{File.dirname(__FILE__)}/#{test_name}/before/#{file} and #{simulated_backup_location(test_name)}#{File.dirname(__FILE__)}/#{test_name}/before/#{file} differ\n"
end

def expected_message_for_renamed_file(test_name, old_filename, new_filename)
  deleted = expected_message_for_deleted_file(test_name, old_filename)
  created = expected_message_for_created_file(test_name, new_filename)
  return created + deleted
end

def expected_message_for_deleted_file(test_name, file)
  dir = "#{File.dirname(__FILE__)}/#{test_name}/before"
  return expected_message_for_file_only_in(dir, file)
end

def expected_message_for_created_file(test_name, file)
  dir = "#{simulated_backup_location(test_name)}#{File.dirname(__FILE__)}/#{test_name}/before"
  return expected_message_for_file_only_in(dir, file)
end

def expected_message_for_file_only_in(dir, file)
  return "Only in #{dir}/: #{file}\n"
end

describe do
  it "should return happy message on unchanged" do
    expect(run_test_named('unchanged')).to eq everything_is_fine_message
  end

  it "should return happy message on unchanged and do not crash on spaces in filepaths" do
    expect(run_test_named('empty folder with space in name')).to eq everything_is_fine_message
  end

  it "should report changed files" do
    test_name = 'changed'
    expect(run_test_named(test_name)).to eq expected_message_for_differing_file(test_name, 'changed.txt') + expected_message_for_differing_file(test_name, 'unimportant changed.txt')
  end

  it "unimportant filter should not crash on empty input" do
    expect(discard_unimportant("", [])).to eq nil
  end

  it "should not report files marked as unimportant" do
    test_name = 'changed'
    diff = run_test_named(test_name)
    dir = File.dirname(__FILE__) + "/#{test_name}/before/"
    expect(discard_unimportant(diff, ['unimportant changed.txt'], [dir])).to eq expected_message_for_differing_file(test_name, 'changed.txt')
  end

  it 'should report changed file with + * and UTF-8 in filename' do
    test_name = 'changed, * and ? and URF-8 in name'
    expect(run_test_named(test_name)).to eq expected_message_for_differing_file(test_name, '*?+ZAŻÓŁĆGEŚLĄJAŹŃzażółćgęśląjażń.txt')
  end

  it 'should report changed file in multilevel folder structure' do
    test_name = 'changed, multilevel folder structure'
    expect(run_test_named(test_name)).to eq expected_message_for_differing_file(test_name, 'a/b/changed.txt')
  end

  it "should report deleted file" do
    test_name = 'deleted file'
    diff = run_test_named(test_name)
    expect(diff).to eq expected_message_for_deleted_file(test_name, 'graphic file.png')
  end

  it "should not report ignored deleted file" do
    test_name = 'deleted file'
    diff = run_test_named(test_name)
    location = File.dirname(__FILE__) + "/#{test_name}/before/graphic file.png"
    puts location
    expect(discard_unimportant(diff, [location])).to eq nil
  end

  test_name = 'created file'
  it "should report #{test_name}" do
    expect(run_test_named(test_name)).to eq expected_message_for_created_file(test_name, 'HTMLFile.html')
  end

  it "should report renamed files" do
    test_name = 'renamed'
    expect(run_test_named('renamed')).to eq expected_message_for_renamed_file(test_name, 'old_name.txt', 'new_name.txt')
  end

  it 'should report renamed files, with : and \ in name' do
    test_name = 'renamed, : and \ in name'
    expect(run_test_named(test_name)).to eq expected_message_for_renamed_file(test_name, 'old name.txt', 'new name with : and \.txt')
  end

  it "should not choke on special files" do
    diff = "File /home/mateusz/.config/bcompare/BCLOCK_0 is a fifo while file /media/mateusz/Database/backup_test_tmp_folder/home/mateusz/.config/bcompare/BCLOCK_0 is a fifo\n"
    discard_unimportant(diff, ['/unexisting/path'])
    diff = "File /var/spool/postfix/dev/random is a character special file while file /media/mateusz/Database/tmp/gem_unpack/var/spool/postfix/dev/random is a character special file\n"
    discard_unimportant(diff, ['/unexisting/path'])
  end

  it "should choke on nonsense" do
    expect { discard_unimportant("lalaland", ['/unexisting/path']) }.to raise_error UnexpectedData
  end
end
