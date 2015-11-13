SET(APP_DIR "${CMAKE_SOURCE_DIR}/app")
SET(APP_DIR "${CMAKE_SOURCE_DIR}/app")
SET(APP_SOURCE_DIR "${APP_DIR}/src")
FILE(GLOB_RECURSE APP_SOURCE
    "${APP_SOURCE_DIR}/*.h"
    "${APP_SOURCE_DIR}/*.cpp"
)

# OS X app bundle configuration, must happen before the executable is added
IF(APPLE)
	# Configure icons
    SET(MACOSX_ICON_FILES "${APP_DIR}/resources/graphics/icons/AppIcon.icns" "${APP_DIR}/resources/graphics/icons/DocIcon.icns")
    SET(APP_SOURCE ${APP_SOURCE} ${MACOSX_ICON_FILES})
    SET_SOURCE_FILES_PROPERTIES(${MACOSX_ICON_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

	# Configure button bitmaps etc.
	FILE(GLOB_RECURSE MACOSX_IMAGE_FILES
        "${APP_DIR}/resources/graphics/images/*.png"
	)
    SET(APP_SOURCE ${APP_SOURCE} ${MACOSX_IMAGE_FILES})
    SET_SOURCE_FILES_PROPERTIES(${MACOSX_IMAGE_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/images)

    FILE(GLOB_RECURSE MACOSX_FONT_FILES
        "${APP_DIR}/resources/fonts/*.*"
    )
    SET(APP_SOURCE ${APP_SOURCE} ${MACOSX_FONT_FILES})
    SET_SOURCE_FILES_PROPERTIES(${MACOSX_FONT_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/fonts)

	# Configure game resources
	# Collect all game resources
	FILE(GLOB_RECURSE MACOSX_QUAKE_FILES
        "${APP_DIR}/resources/games/Quake/*.*"
	)
    SET(APP_SOURCE ${APP_SOURCE} ${MACOSX_QUAKE_FILES})
    SET_SOURCE_FILES_PROPERTIES(${MACOSX_QUAKE_FILES} PROPERTIES  MACOSX_PACKAGE_LOCATION Resources/games/Quake)

	FILE(GLOB_RECURSE MACOSX_QUAKE2_FILES
        "${APP_DIR}/resources/games/Quake2/*.*"
	)
    SET(APP_SOURCE ${APP_SOURCE} ${MACOSX_QUAKE2_FILES})
    SET_SOURCE_FILES_PROPERTIES(${MACOSX_QUAKE2_FILES} PROPERTIES  MACOSX_PACKAGE_LOCATION Resources/games/Quake2)

	FILE(GLOB_RECURSE MACOSX_HEXEN2_FILES
        "${APP_DIR}/resources/games/Hexen2/*.*"
	)
    SET(APP_SOURCE ${APP_SOURCE} ${MACOSX_HEXEN2_FILES})
    SET_SOURCE_FILES_PROPERTIES(${MACOSX_HEXEN2_FILES} PROPERTIES  MACOSX_PACKAGE_LOCATION Resources/games/Hexen2)

	FILE(GLOB_RECURSE MACOSX_GAME_CONFIG_FILES
        "${APP_DIR}/resources/games/*.cfg"
	)
    SET(APP_SOURCE ${APP_SOURCE} ${MACOSX_GAME_CONFIG_FILES})
	SET_SOURCE_FILES_PROPERTIES(${MACOSX_GAME_CONFIG_FILES} PROPERTIES  MACOSX_PACKAGE_LOCATION Resources/games)

	# Configure shaders
	# Collect all shaders
	FILE(GLOB_RECURSE MACOSX_SHADER_FILES
        "${APP_DIR}/resources/shader/*.fragsh"
        "${APP_DIR}/resources/shader/*.vertsh"
	)
	SET_SOURCE_FILES_PROPERTIES(${MACOSX_SHADER_FILES} PROPERTIES  MACOSX_PACKAGE_LOCATION Resources/shader)
    SET(APP_SOURCE ${APP_SOURCE} ${MACOSX_SHADER_FILES})
ENDIF()

# Set up resource compilation for Windows
IF(WIN32)
    # CONFIGURE_FILE("${APP_SOURCE_DIR}/TrenchBroom.rc.in" "${CMAKE_CURRENT_BINARY_DIR}/TrenchBroom.rc" @ONLY)
    IF(MSVC)
        SET(APP_SOURCE ${APP_SOURCE} "${APP_SOURCE_DIR}/TrenchBroom.rc")
    ELSEIF(MINGW)
        SET(CMAKE_RC_COMPILER_INIT windres)
        ENABLE_LANGUAGE(RC)
        SET(CMAKE_RC_COMPILE_OBJECT "<CMAKE_RC_COMPILER> <FLAGS> <DEFINES> -i <SOURCE> -o <OBJECT>")
    ENDIF()
ENDIF()

ADD_EXECUTABLE(TrenchBroom WIN32 MACOSX_BUNDLE ${APP_SOURCE})
TARGET_LINK_LIBRARIES(TrenchBroom glew common ${wxWidgets_LIBRARIES} ${FREETYPE_LIBRARIES} ${FREEIMAGE_LIBRARIES})
SET_TARGET_PROPERTIES(TrenchBroom PROPERTIES COMPILE_DEFINITIONS "GLEW_STATIC")

# Create the cmake script for version management
FIND_PACKAGE(Git)
CONFIGURE_FILE("${CMAKE_SOURCE_DIR}/cmake/Version.cmake.in" "${CMAKE_CURRENT_BINARY_DIR}/Version.cmake" @ONLY)
ADD_TARGET_PROPERTY(TrenchBroom INCLUDE_DIRECTORIES ${CMAKE_CURRENT_BINARY_DIR})
ADD_CUSTOM_TARGET(version ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_BINARY_DIR}/Version.cmake")
ADD_DEPENDENCIES(TrenchBroom version)

# Generate help documents
SET(APP_HELP_SOURCE_DIR "${APP_DIR}/resources/documentation/help")
SET(APP_HELP_TARGET_DIR "${CMAKE_CURRENT_BINARY_DIR}/help")
ADD_CUSTOM_COMMAND(TARGET TrenchBroom PRE_BUILD 
    COMMAND ${CMAKE_COMMAND} -E make_directory "${APP_HELP_TARGET_DIR}"
    COMMAND pandoc -s --toc --toc-depth=2 --template ${APP_HELP_SOURCE_DIR}/template.html -c default.css -o ${APP_HELP_TARGET_DIR}/index.html ${APP_HELP_SOURCE_DIR}/index.md
    COMMAND ${CMAKE_COMMAND} -E copy "${APP_HELP_SOURCE_DIR}/default.css" "${APP_HELP_TARGET_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${APP_HELP_SOURCE_DIR}/images/" "${APP_HELP_TARGET_DIR}/images"
)

# Copy some Windows-specific resources
IF(WIN32)
	# Copy Windows icons to target dir
	ADD_CUSTOM_COMMAND(TARGET TrenchBroom PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "${APP_DIR}/resources/graphics/icons/TrenchBroom.ico" "${CMAKE_CURRENT_BINARY_DIR}"
        COMMAND ${CMAKE_COMMAND} -E copy "${APP_DIR}/resources/graphics/icons/TrenchBroomDoc.ico" "${CMAKE_CURRENT_BINARY_DIR}"
	)

    # Copy DLLs to app directory
	ADD_CUSTOM_COMMAND(TARGET TrenchBroom POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy_directory "${LIB_BIN_DIR}/win32" "$<TARGET_FILE_DIR:TrenchBroom>"
	)
ENDIF()

# Properly link to OpenGL libraries on Linux
IF(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    FIND_PACKAGE(OpenGL)
    TARGET_LINK_LIBRARIES(TrenchBroom ${OPENGL_LIBRARIES})
ENDIF()

# Set up the resources and DLLs for the executable
IF(WIN32 OR ${CMAKE_SYSTEM_NAME} MATCHES "Linux")
	# Copy button images to resources directory
	ADD_CUSTOM_COMMAND(TARGET TrenchBroom POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${APP_DIR}/resources/graphics/images" "$<TARGET_FILE_DIR:TrenchBroom>/Resources/images"
	)

    # Copy fonts to resources directory
    ADD_CUSTOM_COMMAND(TARGET TrenchBroom POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${APP_DIR}/resources/fonts" "$<TARGET_FILE_DIR:TrenchBroom>/Resources/fonts"
    )

	# Copy game files to resources directory
	ADD_CUSTOM_COMMAND(TARGET TrenchBroom POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${APP_DIR}/resources/games/" "$<TARGET_FILE_DIR:TrenchBroom>/Resources/games"
	)

	# Copy shader files to resources directory
	ADD_CUSTOM_COMMAND(TARGET TrenchBroom POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${APP_DIR}/resources/shader" "$<TARGET_FILE_DIR:TrenchBroom>/Resources/shader"
	)
ENDIF()

# Common CPack configuration
GET_APP_VERSION("${APP_DIR}" CPACK_PACKAGE_VERSION_MAJOR CPACK_PACKAGE_VERSION_MINOR CPACK_PACKAGE_VERSION_PATCH)
GET_BUILD_ID("${GIT_EXECUTABLE}" "${CMAKE_SOURCE_DIR}" APP_VERSION_BUILD_ID)
GET_BUILD_PLATFORM(APP_PLATFORM_NAME)
SET(APP_PACKAGE_FILE_NAME "TrenchBroom-${APP_PLATFORM_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}-${APP_VERSION_BUILD_ID}-${CMAKE_BUILD_TYPE}")
SET(APP_PACKAGE_DIR_NAME "$ENV{DROPBOX}/TrenchBroom/")
SET(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
SET(CPACK_PACKAGE_FILE_NAME ${APP_PACKAGE_FILE_NAME})
SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "TrenchBroom Level Editor")
SET(CPACK_PACKAGE_VENDOR "Kristian Duske")

IF(APPLE)
    # Configure variables that are substituted into the plist
    # Set CFBundleExecutable
    SET_TARGET_PROPERTIES(TrenchBroom PROPERTIES MACOSX_BUNDLE_EXECUTABLE_NAME "${OUTPUT_NAME}")
    # Set CFBundleName, which controls the application menu label
    SET_TARGET_PROPERTIES(TrenchBroom PROPERTIES MACOSX_BUNDLE_BUNDLE_NAME "TrenchBroom")
    # Set CFBundleShortVersionString to "2.0.0". This is displayed in the Finder and Spotlight.
    SET_TARGET_PROPERTIES(TrenchBroom PROPERTIES MACOSX_BUNDLE_SHORT_VERSION_STRING "${CPACK_PACKAGE_VERSION}")
    # Set CFBundleVersion to the git revision. Apple docs say it should be "three non-negative, period-separated integers with the first integer being greater than zero"
    SET_TARGET_PROPERTIES(TrenchBroom PROPERTIES MACOSX_BUNDLE_BUNDLE_VERSION "${APP_VERSION_BUILD_ID}")

    # Set the path to the plist template
    SET_TARGET_PROPERTIES(TrenchBroom PROPERTIES MACOSX_BUNDLE_INFO_PLIST "${APP_DIR}/resources/mac/TrenchBroom-Info.plist")

    # Configure the XCode generator project
    SET_XCODE_ATTRIBUTES(TrenchBroom)
ENDIF()

# Platform specific CPack configuration
IF(WIN32)
    IF(MSVC)
        # SET(CMAKE_INSTALLL_DEBUG_LIBRARIES OFF)
        # INCLUDE(InstallRequiredSystemLibraries)
    ENDIF(MSVC)

    FILE(GLOB WIN_LIBS "${LIB_BIN_DIR}/win32/*.dll")
    IF(CMAKE_BUILD_TYPE STREQUAL "Debug")
        LIB_TO_DLL(${WX_cored} _vc100 WIN_LIB_WX_core)
        LIB_TO_DLL(${WX_based} _vc100 WIN_LIB_WX_base)
        LIB_TO_DLL(${WX_advd}  _vc100 WIN_LIB_WX_adv)
        LIB_TO_DLL(${WX_gld}   _vc100 WIN_LIB_WX_gl)
    ELSE()
        LIB_TO_DLL(${WX_core} _vc100 WIN_LIB_WX_core)
        LIB_TO_DLL(${WX_base} _vc100 WIN_LIB_WX_base)
        LIB_TO_DLL(${WX_adv}  _vc100 WIN_LIB_WX_adv)
        LIB_TO_DLL(${WX_gl}   _vc100 WIN_LIB_WX_gl)
    ENDIF()

    INSTALL(TARGETS TrenchBroom RUNTIME DESTINATION . COMPONENT TrenchBroom)
    INSTALL(FILES
        ${WIN_LIB_WX_core}
        ${WIN_LIB_WX_base}
        ${WIN_LIB_WX_adv}
        ${WIN_LIB_WX_gl}
        DESTINATION . COMPONENT TrenchBroom)
    INSTALL(FILES
        ${WIN_LIBS}
        DESTINATION . COMPONENT TrenchBroom)
    INSTALL(DIRECTORY
        "${APP_DIR}/resources/graphics/images"
        "${APP_DIR}/resources/games"
        "${APP_DIR}/resources/shader"
        DESTINATION Resources COMPONENT TrenchBroom)
    SET(CPACK_GENERATOR "ZIP")
    SET(CPACK_INCLUDE_TOPLEVEL_DIRECTORY FALSE)

    # A custom target to copy the release build to a Dropbox folder
    ADD_CUSTOM_TARGET(publish ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_BINARY_DIR}/${APP_PACKAGE_FILE_NAME}.zip" "${APP_PACKAGE_DIR_NAME}")

    # Create a script to create a new build and publish it
    CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/cmake/publish-dropbox.bat.in ${CMAKE_CURRENT_BINARY_DIR}/publish-dropbox.bat @ONLY)
    CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/cmake/generate-changelog.bat.in ${CMAKE_CURRENT_BINARY_DIR}/generate-changelog.bat @ONLY)
ELSEIF(APPLE)
    INSTALL(TARGETS TrenchBroom BUNDLE DESTINATION . COMPONENT TrenchBroom)
    SET(CPACK_GENERATOR "DragNDrop")

    # A custom target to copy the release build to a Dropbox folder
    ADD_CUSTOM_TARGET(publish ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_BINARY_DIR}/${APP_PACKAGE_FILE_NAME}.dmg" "${APP_PACKAGE_DIR_NAME}")

    # Create a script to create a new build and publish it
    CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/cmake/publish-dropbox.sh.in ${CMAKE_CURRENT_BINARY_DIR}/publish-dropbox.sh @ONLY)
    CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/cmake/generate-changelog.sh.in ${CMAKE_CURRENT_BINARY_DIR}/generate-changelog.sh @ONLY)
ENDIF()
INCLUDE(CPack)
