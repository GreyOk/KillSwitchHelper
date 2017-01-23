set (EXEC_NAME2 "killswitchhelperhelper")
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/KillSwitchHelper")
get_filename_component(PARENT_DIR ${CMAKE_CURRENT_SOURCE_DIR} DIRECTORY)

execute_process(COMMAND sudo rm -f ${CMAKE_INSTALL_PREFIX}/bin/${EXEC_NAME2}
                COMMAND sudo cp -p ${EXEC_NAME2} ${CMAKE_INSTALL_PREFIX}/bin/killswitchhelperhelper
                COMMAND sudo rm -v -rf ${PKGDATADIR}
                COMMAND sudo cp -rp ${PARENT_DIR}/data/KillSwitchHelper ${DATADIR}
)
