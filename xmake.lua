package("libapng")

    set_homepage("https://wiki.mozilla.org/APNG_Specification")
    set_description("The official PNG reference library with apng patch")

    set_sourcedir(path.join(os.scriptdir(), "./"))
    set_license("libpng-2.0")

    add_deps("zlib")
    if is_host("windows") then
        add_deps("cmake")
    end

    on_install("windows", function (package)
        local configs = {"-DPNG_TESTS=OFF",
                         "-DPNG_SHARED=" .. (package:config("shared") and "ON" or "OFF"),
                         "-DPNG_STATIC=" .. (package:config("shared") and "OFF" or "ON"),
                         "-DPNG_DEBUG=" .. (package:debug() and "ON" or "OFF")}
        import("package.tools.cmake").install(package, configs)
    end)

    on_install("mingw@msys", function (package)
        local mkFile = "scripts/makefile.gcc"
        local zlib = package:dep("zlib")
        io.gsub(mkFile, "\nZLIBINC =.-\n",      "\nZLIBINC=" .. (os.args(path.join(zlib:installdir(), "include"))) .. "\n")
        io.gsub(mkFile, "\nZLIBLIB =.-\n",      "\nZLIBLIB=" .. (os.args(path.join(zlib:installdir(), "lib"))) .. "\n")
        import("package.tools.make").build(package, {"-f", "scripts/makefile.gcc", "libpng.a"})
        os.cp("libpng.a", package:installdir("lib"))
        os.cp("*.h", package:installdir("include"))
    end)

    on_install("macosx", "linux", function (package)
        local configs = {"--disable-dependency-tracking", "--disable-silent-rules"}
        if package:config("shared") then
            table.insert(configs, "--enable-shared=yes")
            table.insert(configs, "--enable-static=no")
        else
            table.insert(configs, "--enable-static=yes")
            table.insert(configs, "--enable-shared=no")
        end
        import("package.tools.autoconf").install(package, configs)
    end)

    on_install("iphoneos", "android@linux,macosx", function (package)
        import("package.tools.autoconf")
        local zlib = package:dep("zlib")
        local envs = autoconf.buildenvs(package)
        if zlib then
            -- we need patch cflags to cppflags for supporting zlib on android ndk
            -- @see https://github.com/xmake-io/xmake/issues/1126
            envs.CPPFLAGS = (envs.CFLAGS or "") .. " -I" .. os.args(path.join(zlib:installdir(), "include"))
            envs.LDFLAGS = (envs.LDFLAGS or "") .. " -L" .. os.args(path.join(zlib:installdir(), "lib"))
        end
        local configs = {"--disable-dependency-tracking", "--disable-silent-rules"}
        if package:config("shared") then
            table.insert(configs, "--enable-shared=yes")
            table.insert(configs, "--enable-static=no")
        else
            table.insert(configs, "--enable-static=yes")
            table.insert(configs, "--enable-shared=no")
        end
        autoconf.install(package, configs, {envs = envs})
    end)

    on_test(function (package)
        assert(package:has_cfuncs("png_create_read_struct", {includes = "png.h"}))
    end)