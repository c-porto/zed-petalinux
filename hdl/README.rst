Zynq Programmable Logic Design
====================================

.. contents:: Table of Contents
   :local:

Recreating the Project
----------------------
The Programmable Logic implementation is based on tcl scripts, aiming to facilitate version control and reusability. To recreate and build the project a Makefile is provided. The targets are ``xsa``, ``sdt`` and ``all``, with xsa being used to create the project, launch synthesis, launch implementation, writing the bitstream and exporting hardware platform. Target sdt generates the System Device Tree from the xsa file generated, this enables the integration with the newer yocto flow for AMD Xilinx layers. Target all simple runs both targets in sucession.

To run any target of the Makefile the Vivado environment should be sourced:

.. code-block:: bash

   source <vivado-path>/settings64.sh

To build all the artifacts run:

.. code-block:: bash

   make all

.. note:: The SDT target will only run on recent versions of Vivado, any version after 2024.2 should work fine.

Makefile Options
~~~~~~~~~~~~~~~~

Options for customizing the design are available below:

    * JOBS: Number of threads used by Vivado during runs.
    * PROJ_NAME: Name of the project, also names the block design and hardware files.
    * PLATFORM_NAME: Platform name, used for design customization
