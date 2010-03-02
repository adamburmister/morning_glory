namespace :cloudfront do

  desc "Bump the revision value used for ENV['RAILS_ASSET_ID'] value"
  task :bump_revision do
    # TODO: SVN update the following file first
    require "config/initializers/#{Rails.env}_cdn_revision"

    # Store the previous revision so we can delete the bucket from S3 later after deploy
    PREV_CDN_REVISION = CDN_REVISION[Rails.env] || 0

    # Increment the revision counter
    ENV['RAILS_ASSET_ID'] = 'REV_' + (PREV_CDN_REVISION.gsub('REV_', '').to_i + 1).to_s

    # Write it to the initalizer and commit to svn
    filename = File.join(Rails.root, "config/initializers/#{Rails.env}_cdn_revision.rb")
    f = File.open(filename, 'w')
    f.puts "CDN_REVISION['#{Rails.env}'] = '#{ENV['RAILS_ASSET_ID']}'"

    puts "Committing updated revision counter #{filename} to #{ENV['RAILS_ASSET_ID']}" 
    system "svn ci -m 'bumped Revision to #{ENV['RAILS_ASSET_ID']}' #{filename}"
  end

  desc "Compile Sass stylesheets"
  task :sass => :environment do
    if defined? Sass
      puts "Compiling Sass stylesheets"
      Sass::Plugin.update_stylesheets
    end
  end

  desc "Deploy assets to S3"
  task :deploy => [:environment, :sass, :update_revision] do |t, args|
    require 'aws/s3'
    require 'ftools'
    
    if %w(production staging).include?(Rails.env) == false
        puts "You can only upload to the CDN for staging or production environments. (Found #{Rails.env})"
        return
    end
    
    SYNC_DIRECTORY  = File.join(Rails.root, 'public')
    TEMP_DIRECTORY  = File.join(Rails.root, 'tmp', 'cloudfront_cache', Rails.env, ENV['RAILS_ASSET_ID']);
    DIRECTORIES     = %w(images javascripts stylesheets)
    CONTENT_TYPES   = {:jpg => 'image/jpeg',
                       :png => 'image/png',
                       :gif => 'image/gif',
                       :css => 'text/css',
                       :js  => 'text/javascript'}
    REGEX_ROOT_RELATIVE_URL = /url\((\'|\")?(\/+.*(\.gif|\.png|\.jpg|\.jpeg))\1?\)/
    BUCKET          = S3_CONFIG['bucket']
    
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

    begin
      puts "Deleting previous CDN revision #{BUCKET}/#{PREV_CDN_REVISION}"
      if AWS::S3::S3Object.exists? PREV_CDN_REVISION
        AWS::S3::S3Object.find(PREV_CDN_REVISION, BUCKET).objects.each do |object|
          object.delete
        end
      end
    rescue
    end

    puts "Deleting cache files from #{TEMP_DIRECTORY}"
    FileUtils.rm_r TEMP_DIRECTORY
    
  end
end
