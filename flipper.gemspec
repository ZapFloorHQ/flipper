# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

plugin_files = []
plugin_test_files = []

Dir['flipper-*.gemspec'].map do |gemspec|
  spec = Bundler.load_gemspec(gemspec)
  plugin_files << spec.files
  plugin_test_files << spec.files
end

ignored_files = plugin_files
ignored_files << Dir['script/*']
ignored_files << '.gitignore'
ignored_files << 'Guardfile'
ignored_files.flatten!.uniq!

ignored_test_files = plugin_test_files
ignored_test_files.flatten!.uniq!

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = 'support@flippercloud.io'
  gem.summary       = 'Feature flipper for ANYTHING'
  gem.homepage      = 'https://www.flippercloud.io/docs'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split("\n") - ignored_files + ['lib/flipper/version.rb']
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n") - ignored_test_files
  gem.name          = 'flipper'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'concurrent-ruby', '< 2'
  gem.add_dependency 'brow', '~> 0.4.1'
end
