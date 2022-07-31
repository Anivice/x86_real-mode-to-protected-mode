cmake_minimum_required(VERSION 3.16)

set(SOURCE_ROOT_DIR "${CMAKE_SOURCE_DIR}")
set(BINARY_ROOT_DIR "${CMAKE_BINARY_DIR}")

################################
###### Default Executable ######
################################

include(modules/default_proj.cmake)

default_exec(QEMU_EXEC      "${QEMU_EXEC}"      "qemu-system-i386")
default_exec(DD_EXEC        "${DD_EXEC}"        "dd")
default_exec(CP_EXEC        "${CP_EXEC}"        "cp")
default_exec(GAS_EXEC       "${GAS_EXEC}"       "as")
default_exec(GLD_EXEC       "${GLD_EXEC}"       "ld")
default_exec(STRIP_EXEC     "${STRIP_EXEC}"     "strip")
default_exec(OBJCPY_EXEC    "${OBJCPY_EXEC}"    "objcopy")
default_exec(NM_EXEC        "${NM_EXEC}"        "nm")
default_exec(GREP_EXEC      "${GREP_EXEC}"      "grep")
default_exec(SORT_EXEC      "${SORT_EXEC}"      "sort")
default_exec(RM_EXEC        "${RM_EXEC}"        "rm")

default_flags(ADDITIONAL_QEMU_FLAG "${ADDITIONAL_QEMU_FLAG}"    "")
default_flags(GAS_FLAGS         "${GAS_FLAGS}"          "--32 -g")
default_flags(GAS_LDFLAGS       "${GAS_LDFLAGS}"        "-m elf_i386 -g")
default_flags(GCCFLAGS          "${GCCFLAGS}"           "-m32 -fno-builtin \
                                                         -fno-stack-protector \
                                                         -fomit-frame-pointer \
                                                         -fstrength-reduce -Wall -g")

string(REPLACE " " ";" ADDITIONAL_QEMU_FLAG    "${ADDITIONAL_QEMU_FLAG}")
string(REPLACE " " ";" GAS_FLAGS    "${GAS_FLAGS}")
string(REPLACE " " ";" GAS_LDFLAGS  "${GAS_LDFLAGS}")
string(REPLACE " " ";" GCCFLAGS     "${GCCFLAGS}")

# setup gas
LIST(APPEND CMAKE_MODULE_PATH "${SOURCE_ROOT_DIR}/modules")
include("${SOURCE_ROOT_DIR}/modules/setup_gas.cmake")

project(x86-asm ASM_AS ASM_NASM)

function(add_single_file diskname need_qemu)
    # Compile boot sector
    set_source_files_properties(${diskname}.s PROPERTIES LANGUAGE ASM_AS)
    add_executable(${diskname} src/${diskname}.s)
    target_compile_options(${diskname} PUBLIC --32 -g)
    target_link_options(${diskname} PUBLIC -Ttext 0x0000 -m elf_i386 -g)

    # strip boot sector
    add_custom_target(strip_${diskname} ALL
            # Make a copy of current object
            COMMAND ${SOURCE_ROOT_DIR}/script/strip_elf32.sh
                    ${diskname} ${OBJCPY_EXEC} ${DD_EXEC} ${RM_EXEC} ${GLD_EXEC}
            DEPENDS ${diskname}
            WORKING_DIRECTORY ${BINARY_ROOT_DIR})

    if (${need_qemu})
        # add QEMU boot
        add_custom_target(qemu_boot_${diskname}
                ${QEMU_EXEC} -drive file=${diskname}.bin,format=raw,index=0,media=disk -m 16M
                DEPENDS strip_${diskname}
                WORKING_DIRECTORY ${BINARY_ROOT_DIR})
    endif(${need_qemu})
endfunction()

add_single_file(asm_test    FALSE)
add_single_file(display     TRUE)
