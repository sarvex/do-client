macro (fixup_compile_options_for_arm)
    # Special instructions for cross-compiling to arm-linux
    if (CMAKE_CXX_COMPILER MATCHES arm-linux OR CMAKE_CXX_COMPILER MATCHES aarch64-linux)
        message (STATUS "Detected ARM linux target")

        # Linux ARM cross-compiler is not picking up headers from /usr/local automatically.
        set (include_directories_for_arm
            "/usr/local/include"
            "${OPENSSL_ROOT_DIR}/include")

        # Disable incompatible ABI warnings that appear for STL calls due to ABI change in gcc 7.1
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-psabi")

        # Setup compile time definitions for static/dynamic linking of the standard c/c++ libs
        set (STATIC_CXX_RUNTIME_FLAG "-static-libstdc++")
        set (STATIC_CXX_RUNTIME_FLAG_MATCH "\\\-static\\\-libstdc\\\+\\\+")
        set (DYNAMIC_CXX_RUNTIME_FLAG "-lstdc++")
        set (DYNAMIC_CXX_RUNTIME_FLAG_MATCH "\\\-lstdc\\\+\\\+")

        if (USE_STATIC_CXX_RUNTIME)
            set (DESIRED_CXX_RUNTIME_FLAG ${STATIC_CXX_RUNTIME_FLAG})
            set (REPLACE_CXX_RUNTIME_FLAG ${DYNAMIC_CXX_RUNTIME_FLAG_MATCH})
        else ()
            set (DESIRED_CXX_RUNTIME_FLAG ${DYNAMIC_CXX_RUNTIME_FLAG})
            set (REPLACE_CXX_RUNTIME_FLAG ${STATIC_CXX_RUNTIME_FLAG_MATCH})
        endif ()

        set (cxx_variables
            CMAKE_CXX_FLAGS_DEBUG
            CMAKE_CXX_FLAGS_MINSIZEREL
            CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_RELWITHDEBINFO)

        # Replace the cxx compiler options
        foreach (variable ${cxx_variables})
            if (${variable} MATCHES "${REPLACE_CXX_RUNTIME_FLAG}")
                string (REGEX
                        REPLACE ${REPLACE_CXX_RUNTIME_FLAG}
                                ${DESIRED_CXX_RUNTIME_FLAG}
                                ${variable}
                                "${${variable}}")
            else ()
                set (${variable} "${${variable}} ${DESIRED_CXX_RUNTIME_FLAG}")
            endif ()
        endforeach ()

        message (STATUS "C compiler: ${CMAKE_C_COMPILER}")
        message (STATUS "CXX compiler: ${CMAKE_CXX_COMPILER}")
    endif ()
endmacro ()

# Credit: https://github.com/Azure/adu-private-preview/blob/master/src/agent/CMakeLists.txt
function (add_gitinfo_definitions target_name)

    # Pick up Git revision so we can report it in version information.

    include (FindGit)
    if (GIT_FOUND)
        execute_process (
            COMMAND ${GIT_EXECUTABLE} rev-parse --show-toplevel
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_ROOT
            OUTPUT_STRIP_TRAILING_WHITESPACE)
    endif ()
    if (GIT_ROOT)
        execute_process (
            COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            OUTPUT_VARIABLE DO_GIT_HEAD_REVISION OUTPUT_STRIP_TRAILING_WHITESPACE)
        execute_process (
            COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            OUTPUT_VARIABLE DO_GIT_HEAD_NAME OUTPUT_STRIP_TRAILING_WHITESPACE)

        target_compile_definitions (${target_name}
            PRIVATE
                DO_VER_GIT_HEAD_NAME="${DO_GIT_HEAD_NAME}"
                DO_VER_GIT_HEAD_REVISION="${DO_GIT_HEAD_REVISION}")
    else ()
        message (WARNING "Git version info not found, DO NOT release from this build tree!")
        target_compile_definitions (${target_name}
            PRIVATE
                DO_VER_GIT_HEAD_NAME=""
                DO_VER_GIT_HEAD_REVISION="")
    endif ()

endfunction ()

function (add_component_version_definitions target_name component_name maj_min_patch_ver)
    target_compile_definitions (${target_name}
        PRIVATE
            DO_VER_BUILDER_IDENTIFIER="${DO_BUILDER_IDENTIFIER}"
            DO_VER_BUILD_TIME="${DO_BUILD_TIMESTAMP}"
            DO_VER_COMPONENT_NAME="${component_name}"
            DO_VER_COMPONENT_VERSION="${maj_min_patch_ver}")

    add_gitinfo_definitions (${target_name})
endfunction ()

macro (add_do_version_lib target_name maj_min_patch_ver)
    set(DO_COMPONENT_NAME "${target_name}")
    set(DO_COMPONENT_VERSION "${maj_min_patch_ver}")

    # CMake requires us to specify the binary dir when the source dir is not a child of the current dir
    add_subdirectory(${do_project_root_SOURCE_DIR}/common ${CMAKE_CURRENT_BINARY_DIR}/common)
endmacro ()
