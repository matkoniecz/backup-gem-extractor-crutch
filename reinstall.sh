rm *.gem
gem build *.gemspec
gem install --user-install *.gem
sudo gem install --user-install *.gem
rspec

# gem push backup_restore-*.*.*.gem
