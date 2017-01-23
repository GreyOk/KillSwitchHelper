  # project name
  project (KillSwitchHelper)

  # uninstall target
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

  # the oldest stable cmake version to require
  cmake_minimum_required (VERSION 2.6)

  # tell cmake where its modules can be found in our project directory (vala modules)
  #list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
  #list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/src)

  # where we install data directory (if we have any)
  set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")

  # what to call that directory where we install data too
  set (PKGDATADIR "${DATADIR}/KillSwitchHelper")

  set (EXEC_NAME "KillSwitchHelper")
  set (EXEC_NAME2 "killswitchhelperhelper")
  set (RELEASE_NAME "An application for helping graphically with removing and re-adding network routes.")
  set (VERSION "0.1")
  set (VERSION_INFO "First release")

  # Translation files
  set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}")
  add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
  #add_subdirectory (po)

  # we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
  find_package(PkgConfig)

  # now let's actually check for the required dependencies
  pkg_check_modules(DEPS REQUIRED gtk+-3.0 gio-2.0 polkit-gobject-1)

  add_definitions(${DEPS_CFLAGS})
  link_libraries(${DEPS_LIBRARIES})
  link_directories(${DEPS_LIBRARY_DIRS})

  # make sure we have vala
  find_package(Vala REQUIRED)
  # make sure we use vala
  include(ValaVersion)
  # make sure it's the desired version of vala
  ensure_vala_version("0.16" MINIMUM)

  # files we want to compile
  include(ValaPrecompile)
  vala_precompile(VALA_C ${EXEC_NAME}
      src/Widgets/KillSwitchHelperMainWindow.vala
      src/KillSwitchHelper.vala
      CUSTOM_VAPIS
        src/vapi/polkit-gobject-1.vapi

  # tell what libraries to use when compiling
  PACKAGES
      gtk+-3.0
      gio-2.0
      posix
  )

  # tell cmake what to call the executable we just made
  add_executable(${EXEC_NAME} ${VALA_C})
  target_compile_options (${EXEC_NAME} PUBLIC -fPIE)

  vala_precompile(VALA_C ${EXEC_NAME2}
      src/killswitchhelperhelper.vala
      CUSTOM_VAPIS
        src/vapi/polkit-gobject-1.vapi

  # tell what libraries to use when compiling
  PACKAGES
      gtk+-3.0
      gio-2.0
      posix
  )

  # tell cmake what to call the executable we just made
  add_executable(${EXEC_NAME2} ${VALA_C})
  # add the option to suppress incompatible pointer type warnings that arise in the C compiler
  # caused by the Vala variable conversion use in 'SubprocessLauncher.spawnv'
  target_compile_options (${EXEC_NAME2} PUBLIC -Wno-incompatible-pointer-types -fPIE)

  # install the binaries we just made
  install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
  install (TARGETS ${EXEC_NAME2} RUNTIME DESTINATION bin)
  #add_custom_command(TARGET ${EXEC_NAME2}
  #                 POST_BUILD
  #                 COMMAND sudo chown root ${EXEC_NAME2}
  #                 COMMAND sudo chmod 4755 ${EXEC_NAME2}
  #                 COMMENT "Provide sudo password to properly install the 'Kill Switch Helper' helper."
  #)
  # install the polkit action file
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/killswitchhelper.execute.iproute.policy DESTINATION /usr/share/polkit-1/actions/)

  # install the Glade file for the GUI
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/KillSwitchHelper/KillSwitchHelper.glade PERMISSIONS WORLD_READ WORLD_WRITE DESTINATION ${PKGDATADIR})

  # install our .desktop file so the Applications menu will see it
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/KillSwitchHelper.desktop DESTINATION ${DATADIR}/applications/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/KillSwitchHelper:KillSwitchHelper.desktop DESTINATION ${DATADIR}/app-install/desktop/)

  # install the application icons
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/16/killswitchhelper.png DESTINATION ${DATADIR}/icons/gnome/16x16/apps/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/24/killswitchhelper.png DESTINATION ${DATADIR}/icons/gnome/24x24/apps/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/32/killswitchhelper.png DESTINATION ${DATADIR}/icons/gnome/32x32/apps/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/48/killswitchhelper.png DESTINATION ${DATADIR}/icons/gnome/48x48/apps/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/128/killswitchhelper.png DESTINATION ${DATADIR}/icons/gnome/128x128/apps/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/256/killswitchhelper.png DESTINATION ${DATADIR}/icons/gnome/256x256/apps/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/256/killswitchhelper.svg DESTINATION ${DATADIR}/pixmaps/)

  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/16/killswitchhelper.svg DESTINATION ${DATADIR}/icons/elementary/apps/16/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/24/killswitchhelper.svg DESTINATION ${DATADIR}/icons/elementary/apps/24/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/32/killswitchhelper.svg DESTINATION ${DATADIR}/icons/elementary/apps/32/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/48/killswitchhelper.svg DESTINATION ${DATADIR}/icons/elementary/apps/48/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/128/killswitchhelper.svg DESTINATION ${DATADIR}/icons/elementary/apps/128/)
  install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/256/killswitchhelper.svg DESTINATION ${DATADIR}/icons/elementary/apps/256/)

  # Final script after everything has been compiled
  install (CODE "MESSAGE(\"Proceeding to properly install the privileged helper with adequate owners and permissions.\")" SCRIPT "${CMAKE_SOURCE_DIR}/PostInstall.cmake")
