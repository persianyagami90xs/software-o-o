class PackageController < ApplicationController

  before_filter :set_beta_warning
  before_filter :set_search_options, :only => [:show, :categories]
  before_filter :prepare_appdata, :set_categories

  def show
    required_parameters :package
    @pkgname = params[:package]
    raise MissingParameterError, "Invalid parameter package" unless valid_package_name? @pkgname
    
    @search_term = params[:search_term]
    @base_appdata_project = "openSUSE:Factory"

    @packages = Seeker.prepare_result("\"#{@pkgname}\"", nil, nil, nil, nil)
    @pkgname.downcase!
    # only show rpms
    @packages = @packages.select{|p| p.first.type != 'ymp'}
    @default_project = @baseproject || @template.default_baseproject
    @default_project_name = @distributions.select{|d| d[:project] == @default_project}.first[:name]
    @default_repo = @distributions.select{|d| d[:project] == @default_project}.first[:repository]
    if (@packages.select{|s| s.project == "#{@default_project}:Update"}.size >0)
      @default_package = @packages.select{|s| s.project == "#{@default_project}:Update"}.first
    elsif (@packages.select{|s| s.project == "#{@default_project}:NonFree"}.size >0)
      @default_package = @packages.select{|s| s.project == "#{@default_project}:NonFree"}.first
    else
      @default_package = @packages.select{|s| s.project == (@default_project)}.first
    end

    pkg_appdata = @appdata[:apps].select{|app| app[:pkgname] == @pkgname}
    if ( !pkg_appdata.first.blank? )
      @name = pkg_appdata.first[:name]
      @appcategories = pkg_appdata.first[:categories]
      @homepage = pkg_appdata.first[:homepage]
    end

    #TODO: get distro spezific screenshot, cache from debshots etc.
    @screenshot = "http://screenshots.debian.net/screenshot/" + @pkgname

    #TODO: sort out tumbleweed packages as seperate repo, maybe obs can mark that as seperate baseproject? 
    @packages.each do |package|
      if ( package.repository.match(/openSUSE_Tumbleweed/) || (package.project == "openSUSE:Tumbleweed") )
        package.baseproject = "openSUSE:Tumbleweed"
      end

    end
  end


  def categories
  end


  def category
    required_parameters :category
    @category = params[:category]
    raise MissingParameterError, "Invalid parameter category" unless valid_package_name? @category

    mapping = @main_sections.select{|s| s[:name] == @category }
    categories = ( mapping.blank? ? [@category] : mapping.first[:categories] )

    app_pkgs = @appdata[:apps].select{|app| !( app[:categories] & categories ).blank? }
    @packagenames = app_pkgs.map{|p| p[:pkgname]}.uniq

    app_categories = app_pkgs.map{|p| p[:categories]}.flatten
    @related_categories = app_categories.uniq.map{|c| {:name => c, :weight => app_categories.select {|v| v == c }.size } }
    @related_categories = @related_categories.sort_by { |c| c[:weight] }.reverse.reject{|c| categories.include? c[:name] }
    @related_categories = @related_categories.reject{|c| ["GNOME", "KDE", "Qt", "GTK"].include? c[:name] }

    render 'search/find'
  end


  private 

  def set_categories
    @main_sections = [
      {:name => "Games", :categories => ["Game"]},
      {:name => "Education", :categories => ["Education"]},
      {:name => "Development", :categories => ["Development"]},
      {:name => "Office", :categories => ["Office"]},
      {:name => "Tools", :categories => [ "Network", "Settings", "System", "Utility"]},
      {:name => "Multimedia", :categories => ["AudioVideo", "Audio", "Video", "Graphics"]},
    ]
  end

end
 
