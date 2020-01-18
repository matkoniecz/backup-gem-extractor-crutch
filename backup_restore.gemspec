Gem::Specification.new do |s|
  s.name        = 'backup_restore'
  s.version     = '0.0.5'
  s.summary     = "Script for unpacking backups produced by the backup gem."
  s.description = "Script for unpacking backups produced by the backup gem. See https://github.com/backup/backup-features/issues/28 for discussion about this feature in backup gem itself. "
  s.authors     = ["Mateusz Konieczny"]
  s.email       = 'matkoniecz@gmail.com'
  s.files       = Dir.glob('lib/*.rb')
  s.homepage    = 'https://github.com/matkoniecz/backup-gem-extractor-crutch'
  s.license     = 'GPL-3.0'

  s.add_development_dependency 'matkoniecz-ruby-style'
end

=begin
how to release new gem version:

rm *.gem
gem build *.gemspec
gem install --user-install *.gem
gem push *.gem
=end
