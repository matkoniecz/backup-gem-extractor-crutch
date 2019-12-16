require_relative '../lib/backup_restore'

def existing_file
  "#{File.dirname(__FILE__)}/diff_spec.rb"
end

def existing_folder_a
  "#{File.dirname(__FILE__)}/changed"
end

def existing_folder_b
  "#{File.dirname(__FILE__)}/renamed"
end

def nonexisting_folder_a
  "#{File.dirname(__FILE__)}/NONEXISTING FOLDER A"
end

def nonexisting_folder_b
  "#{File.dirname(__FILE__)}/NONEXISTING FOLDER B"
end

describe do
  it "warns about unpacking to nonexisting folder" do
    expect { BackupRestore.validate_folder_parameters(existing_folder_b, nonexisting_folder_b) }.to raise_exception BackupRestore::PreconditionFailed
  end
  it "warns about unpacking from nonexisting archive root" do
    expect { BackupRestore.validate_folder_parameters(nonexisting_folder_a, existing_folder_b) }.to raise_exception BackupRestore::PreconditionFailed
  end
  it "warns about unpacking to file, rather than folder" do
    expect { BackupRestore.validate_folder_parameters(existing_folder_b, existing_file) }.to raise_exception BackupRestore::PreconditionFailed
  end
  it "warns about unpacking from file, rather than folder" do
    expect { BackupRestore.validate_folder_parameters(existing_file, existing_folder_b) }.to raise_exception BackupRestore::PreconditionFailed
  end
  it "does not warn on valid parameters" do
    expect { BackupRestore.validate_folder_parameters(existing_folder_a, existing_folder_b) }.not_to raise_error
  end
end
