require 'rake'

desc 'Run everything'
task :setup do
  Rake::Task["install"].invoke
  Rake::Task["configure"].invoke
end

desc 'Run all install tasks'
task :install do
  Rake::Task["install:binaries"].invoke
  Rake::Task["install:homebrew"].invoke
  Rake::Task["install:oh_my_zsh"].invoke
end

desc 'Run all configuration tasks'
task :configure do
  Rake::Task["configure:git"].invoke
  Rake::Task["configure:osx"].invoke
  Rake::Task["configure:tmux"].invoke
  Rake::Task["configure:vim"].invoke
  Rake::Task["configure:zsh"].invoke
end

namespace :install do
  desc 'Install homebrew and useful packages'
  task :homebrew do
    run %{ bash homebrew/install.sh }
  end

  desc 'Install oh my zsh, pure prompt and syntax highlighter'
  task :oh_my_zsh do
    run %{ bash zsh/script/install_plugins.sh }
  end

  desc 'Copy binaries to home folder'
  task :binaries do
    run %{ cp -Pa bin/. #{ENV["HOME"]}/.bin/ }
  end
end

namespace :configure do
  desc 'Configure git related dotfiles'
  task :git do
    link_files(files_in_folder('git/*'))
    configure_git_user
  end

  desc 'Configure OSX (run once)'
  task :osx do
    if RUBY_PLATFORM.downcase.include?("darwin")
      run %{ bash osx/osx.sh }
    end
  end

  desc 'Configure TMUX'
  task :tmux do
    link_files(files_in_folder('tmux/*'))
  end

  desc 'Configure Vim with Vundler and plugins'
  task :vim do
    link_files(files_in_folder('vim/*'))
    install_vim_plugins
  end

  desc 'Configure ZSH and bootstrap aliases, functions, etc'
  task :zsh do
    switch_to_zsh
    cp_files(files_in_folder('zsh/*'))
  end
end

private
# General functions
def run(cmd)
  system "#{cmd}" unless ENV['DEBUG']
end

# Git configuration
def configure_git_user
  git_user_settings_file = "#{ENV['HOME']}/.gitconfig.user"
  unless File.exists?(git_user_settings_file) && !proceed?("Do you want to configure your git user attributes?")
    name, email = ask_github_name_and_email
    File.write(git_user_settings_file, "[user]\n  name = #{name}\n  email = #{email}")
  end
end

def ask_github_name_and_email
  print ' - What is your github author name?: '
  name = STDIN.gets.chomp
  print ' - What is your github author email?: '
  email = STDIN.gets.chomp
  return name, email
end

# Vim configuration
def install_vim_plugins
  backup_file("vim", nil, "#{ENV['HOME']}/.vim")
  run %{ bash vim/script/install_plugins.sh }
end

# Zsh/bash switching
def switch_to_zsh
  run %{ chsh -s `which zsh` } if !ENV["SHELL"] =~ /zsh/
end

def switch_to_bash
  run %{ chsh -s `which bash` } if !ENV["SHELL"] =~ /bash/
end

# File operation helpers
def file_operation(filepath, method = :symlink)
  file = filepath.split('/').last
  source = "#{ENV["PWD"]}/#{filepath}"
  target = "#{ENV["HOME"]}/.#{file}"
  backup_file(file, source, target)
  method == :symlink ? run(%{ ln -nfs "#{source}" "#{target}" }) : run(%{ cp -f "#{source}" "#{target}" })
end

def backup_file(file, source, target)
  run %{ mkdir -p $HOME/.backup } unless File.exists?("#{ENV['HOME']}/.backup")
  if File.exists?(target) && (!File.symlink?(target) || (File.symlink?(target) && File.readlink(target) != source))
    run %{ mv "$HOME/.#{file}" "$HOME/.backup/.#{file}" }
  end
end

def cp_files(files)
  files.each { |file| cp_file(file) }
end

def cp_file(file)
  file_operation(file, :copy)
end

def link_file(file)
  file_operation(file, :symlink)
end

def link_files(files)
  files.each { |file| link_file(file) }
end

def files_in_folder(folder)
  Dir[folder].select { |f| File.file?(f) }
end

def proceed?(action)
  print "#{action} (y/n): "
  $stdin.gets.chomp == 'y'
end
