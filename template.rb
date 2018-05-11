run 'pgrep spring | xargs kill -9'

# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'
ruby '#{RUBY_VERSION}'
#{"gem 'bootsnap', require: false" if Rails.version >= "5.2"}

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# BACK END
gem 'rails', '#{Rails.version}'
gem 'pg', '~> 0.21'
gem 'puma'
gem 'jbuilder', '~> 2.0'
gem 'figaro'
gem 'redis'
gem 'autoprefixer-rails'
gem 'devise'
gem 'faker', github: "stympy/faker"

# FRONT END
gem 'jquery-rails'
gem 'bootstrap', '~> 4.1.1'
gem 'font-awesome-sass', '~> 5.0.9'
gem 'sass-rails'
gem 'simple_form'
gem 'uglifier'

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'byebug'
end

group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
RUBY

# Ruby version
########################################
file '.ruby-version', RUBY_VERSION

# Procfile
########################################
file 'Procfile', <<-YAML
web: bundle exec puma -C config/puma.rb
YAML

# Spring conf file
########################################
# inject_into_file 'config/spring.rb', before: ').each { |path| Spring.watch(path) }' do
#   '  config/application.yml\n'
# end

# Assets
########################################
run 'rm app/assets/javascripts/application.js'
file 'app/assets/javascripts/application.js', <<-JS
//= require rails-ujs
//= require jquery3
//= require popper
//= require bootstrap
//= require_tree .
JS

# SCSS
#######################################
run 'mv app/assets/stylesheets/application.css'
file 'app/assets/stylesheets/application.scss' <<-CSS
@import "bootstrap";
@import "font-awesome-sprockets";
@import "font-awesome";
CSS

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate('simple_form:install', '--bootstrap')
  generate('devise:install')
  generate('devise User')
  rails_command('db:migrate')
  generate('devise:views')

  # CONFIG DEVISE
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb' <<-RUBY
  class ApplicationController < ActionController::Base
    before_action :configure_permitted_parameters, if: :devise_controller?

    # private

    # def configure_permitted_parameters
    #   devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    # end
  end
  RUBY

  # Figaro
  ########################################
  run 'bundle binstubs figaro'
  run 'bundle exec figaro install'

  # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit"
end
