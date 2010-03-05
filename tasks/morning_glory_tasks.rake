require File.dirname(__FILE__) + "/../lib/morning_glory"

namespace :mg do
  namespace :cloudfront do
  
  begin
    MORNING_GLORY_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/morning_glory.yml")
  rescue
  end
  
  def check_enabled_for_rails_env
    if MORNING_GLORY_CONFIG[Rails.env]['enabled'] != true
        raise "Deployment is disabled for this environment (#{Rails.env}). Specify an alternative environment with RAILS_ENV={environment name}."
    end
  end
    
  desc "Bump the revision value used for ENV['RAILS_ASSET_ID'] value"
  task :bump_revision do
    check_enabled_for_rails_env
    
    prev = MORNING_GLORY_CONFIG[Rails.env]['revision'].to_i || 0
    
    # Increment the revision counter
    ENV['RAILS_ASSET_ID'] = MORNING_GLORY_CONFIG[Rails.env]['revision'] = CLOUDFRONT_REVISION_PREFIX + (prev + 1).to_s
    
    # Store the previous revision so we can delete the bucket from S3 later after deploy
    PREV_CDN_REVISION = CLOUDFRONT_REVISION_PREFIX + prev.to_s
    
    File.open("#{RAILS_ROOT}/config/morning_glory.yml", 'w') { |f| YAML.dump(MORNING_GLORY_CONFIG, f) }
    
    # puts "Committing updated CDN revision counter for #{Rails.env} to #{ENV['RAILS_ASSET_ID']}" 
    # system "svn ci -m 'bumped #{Rails.env} CDN revision number to #{ENV['RAILS_ASSET_ID']}'"
  end

  desc "Compile Sass stylesheets"
  task :sass => :environment do
    if defined? Sass
      puts "Compiling Sass stylesheets"
      Sass::Plugin.update_stylesheets
    end
  end

  desc "Deploy assets to S3"
  task :deploy => [:environment, :sass, :bump_revision] do |t, args|
    require 'aws/s3'
    require 'ftools'
    
    check_enabled_for_rails_env
    
    BUCKET          = MORNING_GLORY_CONFIG[Rails.env]['bucket'] || Rails.env    
    SYNC_DIRECTORY  = File.join(Rails.root, 'public')
    TEMP_DIRECTORY  = File.join(Rails.root, 'tmp', 'cache', 'morning_glory_cloudfront_cache', Rails.env, ENV['RAILS_ASSET_ID']);
    DIRECTORIES     = MORNING_GLORY_CONFIG[Rails.env]['asset_directories'] || %w(images javascripts stylesheets)
    CONTENT_TYPES   = MORNING_GLORY_CONFIG[Rails.env]['content_types'] || {
                        :jpg => 'image/jpeg',
                        :png => 'image/png',
                        :gif => 'image/gif',
                        :css => 'text/css',
                        :js  => 'text/javascript'
                      }
    # REGEX_ROOT_RELATIVE_URL = /url\((\'|\")?(\/+.*(\.gif|\.png|\.jpg|\.jpeg))\1?\)/
    REGEX_ROOT_RELATIVE_URL = /url\((\'|\")?(\/+.*(#{CONTENT_TYPES.keys.map { |k| '\.' + k.to_s }.join(',')}))\1?\)/
    
    # Copy all the assets into the temp directory for processing
    File.makedirs TEMP_DIRECTORY if !FileTest::directory?(TEMP_DIRECTORY)
    puts "Copying files to working directory for cache-busting-renaming"
    DIRECTORIES.each do |directory|
      Dir[File.join(SYNC_DIRECTORY, directory, '**', "*.{#{CONTENT_TYPES.keys.join(',')}}")].each do |file|
        file_path = file.gsub(/.*public\//, "")
        temp_file_path = File.join(TEMP_DIRECTORY, file_path)

        File.makedirs(File.dirname(temp_file_path)) if !FileTest::directory?(File.dirname(temp_file_path))
        
        puts "   Copied to #{temp_file_path}"
        FileUtils.copy file, temp_file_path
      end
    end

    puts "Replacing image references within CSS files"
    DIRECTORIES.each do |directory|
      Dir[File.join(TEMP_DIRECTORY, directory, '**', "*.{css}")].each do |file|
        puts "   renaming image references within #{file}"
        buffer = File.new(file,'r').read.gsub(REGEX_ROOT_RELATIVE_URL) { |m| m.insert m.index('(') + 1, '/'+ENV['RAILS_ASSET_ID'] }
        File.open(file,'w') {|fw| fw.write(buffer)}
      end
    end

    # TODO: Update references within JS files
    
    AWS::S3::Base.establish_connection!(
      :access_key_id     => S3_CONFIG['access_key_id'],
      :secret_access_key => S3_CONFIG['secret_access_key']
    )

    begin
      puts "Creating #{BUCKET}"
      AWS::S3::Bucket.create(BUCKET)

      # Uncomment the following line to log deployments to the S3 bucket
      # AWS::S3::Bucket.enable_logging_for(BUCKET)

      puts "Uploading files to S3 #{BUCKET}"
      DIRECTORIES.each do |directory|
        Dir[File.join(TEMP_DIRECTORY, directory, '**', "*.{#{CONTENT_TYPES.keys.join(',')}}")].each do |file|
          file_path = file.gsub(/.*#{TEMP_DIRECTORY}\//, "")
          file_path = File.join(ENV['RAILS_ASSET_ID'], file_path)
          file_ext = file.split(/\./)[-1].to_sym
          
          puts "   uploading to #{file_path}"
          AWS::S3::S3Object.store(file_path, open(file), BUCKET,
            :access => :public_read,
            :content_type => CONTENT_TYPES[file_ext])
        end
      end

      if MORNING_GLORY_CONFIG[Rails.env]['delete_prev_rev'] == true
        # TODO: Figure out how to delete from the S3 bucket
        puts "Deleting previous CDN revision #{BUCKET}/#{PREV_CDN_REVISION}"
        AWS::S3::Bucket.find(BUCKET).objects(:prefix => PREV_CDN_REVISION).each do |object|
          puts "   deleting #{object.key}"
          object.delete
        end
      end
    rescue
      raise
    ensure
      puts "Deleting temp cache files in #{TEMP_DIRECTORY}"
      FileUtils.rm_r TEMP_DIRECTORY
    end
  end
  end
end
