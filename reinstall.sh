rm *.gem
gem build *.gemspec
gem install --user-install *.gem
