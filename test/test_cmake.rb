require File.expand_path('../helper', __FILE__)

class TestCMake < TestCase
  attr_accessor :assets_path, :tar_path, :recipe

  def before_all
    super
    @assets_path = File.expand_path("../assets", __FILE__)
    @tar_path = File.expand_path("../../tmp/test-cmake-1.0.tar.gz", __FILE__)

    # remove any previous test files
    FileUtils.rm_rf("tmp")

    create_tar(@tar_path, @assets_path, "test-cmake-1.0")
    start_webrick(File.dirname(@tar_path))

    @recipe = MiniPortileCMake.new("test-cmake", "1.0").tap do |recipe|
      recipe.files << "http://localhost:#{HTTP_PORT}/#{ERB::Util.url_encode(File.basename(@tar_path))}"
      recipe.patch_files << File.join(@assets_path, "patch 1.diff")
      recipe.configure_options << "--option=\"path with 'space'\""
      git_dir = File.join(@assets_path, "git")
      with_custom_git_dir(git_dir) do
        recipe.cook
      end
    end
  end

  def after_all
    super
    stop_webrick
    # leave test files for inspection
  end

  def exe_name
    case
      when MiniPortile.windows? then "hello.exe"
      else "hello"
    end
  end

  def test_cmake_inherits_from_base
    assert(MiniPortileCMake <= MiniPortile)
  end

  def test_configure
    cmakecache = File.join(work_dir, "CMakeCache.txt")
    assert File.exist?(cmakecache), cmakecache

    assert_includes(IO.read(cmakecache), "CMAKE_INSTALL_PREFIX:PATH=#{recipe.path}")
  end

  def test_compile
    binary = File.join(work_dir, exe_name)
    assert File.exist?(binary), binary
  end

  def test_install
    binary = File.join(recipe.path, "bin", exe_name)
    assert File.exist?(binary), binary
  end
end
