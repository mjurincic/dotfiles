require 'rake'

namespace :configure do
  task :homebrew do
    run %{ bash homebrew/install.sh }
  end

  task :binaries do
    run %{ cp -Pa bin/. #{ENV["HOME"]}/.bin/ }
  end

  task :osx do
    if RUBY_PLATFORM.downcase.include?("darwin")
      run %{ bash osx/osx.sh }
    end
  end

  task :git do
    link_files(Dir['git/*'])
    configure_git_user
  end

  task :tmux do
    link_files(Dir['tmux/*'])
  end

  task :vim do
    link_files(Dir['vim/vimrc'])
    install_vim_plugins
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
  run %{ bash vim/install_plugins.sh }
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

def link_file(file)
  file_operation(file, :symlink)
end

def link_files(files)
  files.each { |file| link_file(file) }
end

def proceed?(action)
  print "#{action} (y/n): "
  $stdin.gets.chomp == 'y'
end
