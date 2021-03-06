class MyGengoLocaleDownloader

  require "zip/zip"

  def initialize(token, project, requested_language="en", tmp_dir="tmp/locale")
    @requested_language=requested_language
    @dir = tmp_dir
    @locale_dir = "#{Rails.root}/config/locales"
    @token=token
    @project = project

    Dir.mkdir(@dir) if !Dir.exists?(@dir)
  end

  def download_locale_files
    res = download_zip_file(@project, @requested_language, @token)
    requested_file_name = save_to_tmp_file(res)
    unzip_files(requested_file_name, @locale_dir)
  end

  protected

  def save_to_tmp_file(res)
    requested_file_name="#{@dir}/#{@requested_language}.zip"
    open("#{requested_file_name}", "wb") { |file|
      file.write(res.body)
    }
    requested_file_name
  end


  def download_zip_file(project, requested_language, token)
    url = URI.parse("https://mygengo.com/string/p/#{project}/export/language/#{requested_language}/#{token}")
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port, :use_ssl=>true) { |http|
      http.request(req)
    }
    res
  end

  def unzip_files(requested_file_name, locale_dir)
    Zip::ZipFile.foreach(requested_file_name) { |zipfile|
      zipfile.to_s =~ /(.{2})\/(.+).yaml/
      language = $1
      file = $2
      if language and file
        name = "#{locale_dir}/#{file}.#{language}.yml"
        File.delete(name) if File.exists?(name)
        zipfile.extract(name)
        puts "extracted #{name}"
      else
        puts "unexpected name format"
      end

    }
  end

end