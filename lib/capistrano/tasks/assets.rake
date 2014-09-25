#Note: 
# 特点：
#   × 避免每次编译
#   × 避免每次上传
#
# when: invoke this after :updating
#
namespace :load do
  task :assets_defaults do
    set :enable_locally_compile_assets, fetch(:enable_locally_compile_assets, %w{production staging online}.include?(fetch(:rails_env).to_s))
    set :check_assets_paths, fetch(:check_assets_paths, %w{app/assets lib/assets vendor/assets})
    set :shared_assets_path, fetch(:shared_assets_path, shared_path.join('assets'))
    set :assets_version_file, fetch(:assets_version_file, shared_path.join("assets_version"))
    set :keep_assets_versions, fetch(:keep_assets_versions, 3)
    set :force_assets_compile, fetch(:force_assets_compile, false)
  end
end

namespace :deploy do
  desc "compiles assets locally then rsync, advanced, more complex!"
  task :compile_assets_locally=>'load:assets_defaults' do
    if fetch(:enable_locally_compile_assets)
      begin
        pwd = Dir.pwd
        Dir.chdir rake_root
        #check git assets changes between these revisions
        last_revision = fetch(:previous_revision)
        to_revision = fetch(:current_revision)
        same_revision = last_revision && last_revision == to_revision
        #if has changes, 'git diff --quiet ...' return 1, 'system' cmd result to false
        diff_cmd = "git diff --quiet #{last_revision} #{to_revision} -- #{fetch(:check_assets_paths).join(' ')}"
        if fetch(:force_assets_compile) || !last_revision || (not same_revision and !system(diff_cmd))
          #require recompilation!
          #run_locally do
            #execute "bundle exec rake assets:precompile"
          #end
          system "bundle exec rake assets:precompile"
          assets_dir = fetch(:shared_assets_path).join(to_revision)
          on roles(:app) do |role|
            if test "[ -d #{assets_dir} ]"
              execute :echo, "Rm old existed #{assets_dir} to use new one!"
              execute :rm, "-fr #{assets_dir}"
            end
            execute :mkdir, '-pv', fetch(:shared_assets_path)
            run_locally do
              execute "rsync -av public/assets/ #{role.user}@#{role.hostname}:#{assets_dir}" 
            end
            execute :ln, '-s', assets_dir, release_path.join('public', 'assets')
            #record this revision as current working assets verion
            execute :echo, "-n #{to_revision} > #{fetch(:assets_version_file)}"

            #rm too old versions, one command???
            old_versions = capture("/bin/ls -t #{fetch(:shared_assets_path)}").chomp.split[fetch(:keep_assets_versions)..-1]||[]
            if old_versions.size > 0
              old_items = "#{fetch(:shared_assets_path)}/{#{old_versions.join(',')}}" 
              execute :rm, '-fr', old_items
            end
          end
          run_locally do
            execute "rm -fr public/assets"
          end
        else #link to last working revision assets if found
          on roles(:app) do
            current_assets_version = File.read(fetch(:assets_version_file))
            assets_dir = fetch(:shared_assets_path).join(current_assets_version) 
            unless test "[ -d #{assets_dir} ]"
              error "No found assets dir: #{assets_dir}!" #Never happen?
            end
            execute :ln, '-s', assets_dir, release_path.join('public', 'assets')
          end
        end
      ensure
        Dir.chdir pwd
      end
    end #of first if
  end
end
