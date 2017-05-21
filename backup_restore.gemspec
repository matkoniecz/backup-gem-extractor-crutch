Gem::Specification.new do |s|
  s.name        = 'backup_restore'
  s.version     = '0.0.0'
  s.date        = '2017-05-21'
  s.summary     = "Script for unpacking backups produced by the backup gem."
  s.description = "Script for unpacking backups produced by the backup gem. See https://github.com/backup/backup-features/issues/28 for discussion about this feature in backup gem itself. "
  s.authors     = ["Mateusz Konieczny"]
  s.email       = 'matkoniecz@gmail.com'
  s.files       = Dir.glob('lib/*.rb')
  s.homepage    = 'https://github.com/matkoniecz/backup-gem-extractor-crutch'
  s.license     = 'GPL-3.0'
end
