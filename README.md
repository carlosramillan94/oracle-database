# Oracle Database container images

Sample container build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Database Online Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/index.html).

## How to build and run

This project offers sample Dockerfiles for:

* Oracle Database 19c (19.3.0) Enterprise Edition and Standard Edition 2

To assist in building the images, you can use the [buildContainerImage.sh](dockerfiles/buildContainerImage.sh) script. See below for instructions and usage.

The `buildContainerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` or `podman build` with their preferred set of parameters.

### Building Oracle Dartabase container images without .sh script

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have to run the **buildContainerImage.sh** script:

    docker build --force-rm=true --no-cache --build-arg DB_EDITION=se2 -t oracle:19c -f .

### Building Oracle Database container images

**IMPORTANT:** You will have to provide the installation binaries of Oracle Database and put them into the  `files` folder. You only need to provide the binaries for the edition you are going to install. The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html), make sure you use the linux link: *Linux x86-64*. The needed file is named *linuxx64_\<version\>_database.zip*. You also have to make sure to have internet connectivity for yum. Note that you must not uncompress the binaries. The script will handle that for you and fail if you uncompress them manually!

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have to run the **buildContainerImage.sh** script:

    [oracle@localhost dockerfiles]$ ./buildContainerImage.sh -h
    
    Usage: buildContainerImage.sh -v [version] -t [image_name:tag] [-e | -s | -x] [-i] [-o] [container build option]
    Builds a container image for Oracle Database.
    
    Parameters:
       -v: version to build
           Choose one of: 19.3.0
       -t: image_name:tag for the generated docker image
       -s: creates image based on 'Standard Edition 2'
       -i: ignores the MD5 checksums
       -o: passes on container build option

EXAMPLE: 

    ./buildContainerImage.sh -v 19.3.0 -t database:19.3.0-ee -s -i -o

**IMPORTANT:** The resulting images will be an image with the Oracle binaries installed. On first startup of the container a new database will be created, the following lines highlight when the database is ready to be used:

    #########################
    DATABASE IS READY TO USE!
    #########################

You may extend the image with your own Dockerfile and create the users and tablespaces that you may need.

The character set for the database is set during creating of the database. You can set the character set for the Standard Edition 2 during the first run of your container and may keep separate folders containing different tablespaces with different character sets.

**NOTE**: This section is intended for container images 19c. By default, SLIMMING is **true** to remove some components from the image with the intention of making the image slimmer. These removed components cause problems while patching after building patching extension. So, to use patching extension one should use additional build argument `-o '--build-arg SLIMMING=false'` while building the container image. Example command for building the container image is as follows:

    ./buildContainerImage.sh -e -v 21.3.0 -o '--build-arg SLIMMING=false'

### Running Oracle Database in a container

#### Running Oracle Database Standard Edition 2 in a container

To run your Oracle Database image use the `docker run` command as follows:

    docker run --name <container name> \
    -p <host port>:1521 -p <host port>:5500 \
    -e ORACLE_SID=<your SID> \
    -e ORACLE_PDB=<your PDB name> \
    -e ORACLE_PWD=<your database passwords> \
    -e INIT_SGA_SIZE=<your database SGA memory in MB> \
    -e INIT_PGA_SIZE=<your database PGA memory in MB> \
    -e ORACLE_EDITION=<your database edition> \
    -e ORACLE_CHARACTERSET=<your character set> \
    -e ENABLE_ARCHIVELOG=true \
    -v [<host mount point>:]/opt/oracle/oradata \
    oracle/database:19.3.0-ee
    
    Parameters:
       --name:        The name of the container (default: auto generated).
       -p:            The port mapping of the host port to the container port.
                      Two ports are exposed: 1521 (Oracle Listener), 5500 (OEM Express).
       -e ORACLE_SID: The Oracle Database SID that should be used (default: ORCLCDB).
       -e ORACLE_PDB: The Oracle Database PDB name that should be used (default: ORCLPDB1).
       -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDB_ADMIN password (default: auto generated).
       -e INIT_SGA_SIZE:
                      The total memory in MB that should be used for all SGA components (optional).
                      Supported 19.3 onwards.
       -e INIT_PGA_SIZE:
                      The target aggregate PGA memory in MB that should be used for all server processes attached to the instance (optional).
                      Supported 19.3 onwards.
       -e ORACLE_EDITION:
                      The Oracle Database Edition (enterprise/standard).
                      Supported 19.3 onwards.
       -e ORACLE_CHARACTERSET:
                      The character set to use when creating the database (default: AL32UTF8).
       -e ENABLE_ARCHIVELOG:
                      To enable archive log mode when creating the database (default: false).
                      Supported 19.3 onwards.
       -v /opt/oracle/oradata
                      The data volume to use for the database.
                      Has to be writable by the Unix "oracle" (uid: 54321) user inside the container!
                      If omitted the database will not be persisted over container recreation.
       -v /opt/oracle/scripts/startup | /docker-entrypoint-initdb.d/startup
                      Optional: A volume with custom scripts to be run after database startup.
                      For further details see the "Running scripts after setup and on startup" section below.
       -v /opt/oracle/scripts/setup | /docker-entrypoint-initdb.d/setup
                      Optional: A volume with custom scripts to be run after database setup.
                      For further details see the "Running scripts after setup and on startup" section below.

Once the container has been started and the database created you can connect to it just like to any other database:

    sqlplus sys/<your password>@//localhost:1521/<your SID> as sysdba
    sqlplus system/<your password>@//localhost:1521/<your SID>
    sqlplus pdbadmin/<your password>@//localhost:1521/<Your PDB name>

The Oracle Database inside the container also has Oracle Enterprise Manager Express configured. To access OEM Express, start your browser and follow the URL:

    https://localhost:5500/em/

**NOTE**: Oracle Database bypasses file system level caching for some of the files by using the `O_DIRECT` flag. It is not advised to run the container on a file system that does not support the `O_DIRECT` flag.

#### Selecting the Edition (Supported from 19.3.0 release)

The edition of the database can be changed during runtime by passing the ORACLE_EDITION parameter to the `docker run` command. Therefore, an enterprise container image can be used to run standard edition database and vice-versa. You can find the edition of the running database in the output line:

    ORACLE EDITION:

This parameter modifies the software home binaries but it doesn't have any effect on the datafiles. So, if existing datafiles are reused to bring up the database, the same ORACLE_EDITION must be passed as the one used to create the datafiles for the first time.

#### Setting the SGA and PGA memory (Supported from 19.3.0 release)

The SGA and PGA memory can be set during the first time when database is created by passing the INIT_SGA_SIZE and INIT_PGA_SIZE parameters respectively to the `docker run` command. The user must provide the values in MB and without any units appended to the values (For example: -e INIT_SGA_SIZE=1536). These parameters are optional and dbca calculates these values if they aren't provided.

In case these parameters are passed to the `docker run` command while reusing existing datafiles, even though these values would be visible in the container environment, they would not be set inside the database. The values used at the time of database creation will be used.

#### Changing the admin accounts passwords

On the first startup of the container, a random password will be generated for the database if not provided. The user has to mandatorily change the password after the database is created and the corresponding container is healthy.

The password for those accounts can be changed via the `docker exec` command. **Note**, the container has to be running:

    docker exec <container name> ./setPassword.sh <your password>

This new password will be used afterwards.
#### Enabling archive log mode while creating the database

Archive mode can be enabled during the first time when database is created by setting ENABLE_ARCHIVELOG to `true` and passing it to `docker run` command. Archive logs are stored at the directory location: `/opt/oracle/oradata/$ORACLE_SID/archive_logs` inside the container.

In case this parameter is set `true` and passed to `docker run` command while reusing existing datafiles, even though this parameter would be visible as set to `true` in the container environment, this would not be set inside the database. The value used at the time of database creation will be used.

### Running SQL*Plus in a container

You may use the same container image you used to start the database, to run `sqlplus` to connect to it, for example:

    docker run --rm -ti oracle/database:19.3.0-ee sqlplus pdbadmin/<yourpassword>@//<db-container-ip>:1521/ORCLPDB1

Another option is to use `docker exec` and run `sqlplus` from within the same container already running the database:

    docker exec -ti <container name> sqlplus pdbadmin@ORCLPDB1

### Running scripts after setup and on startup

The container images can be configured to run scripts after setup and on startup. Currently `sh` and `sql` extensions are supported.
For post-setup scripts just mount the volume `/opt/oracle/scripts/setup` or extend the image to include scripts in this directory.
For post-startup scripts just mount the volume `/opt/oracle/scripts/startup` or extend the image to include scripts in this directory.
Both of those locations are also represented under the symbolic link `/docker-entrypoint-initdb.d`. This is done to provide
synergy with other database container images. The user is free to decide whether to put the setup and startup scripts
under `/opt/oracle/scripts` or `/docker-entrypoint-initdb.d`.

After the database is setup and/or started the scripts in those folders will be executed against the database in the container.
SQL scripts will be executed as sysdba, shell scripts will be executed as the current user. To ensure proper order it is
recommended to prefix your scripts with a number. For example `01_users.sql`, `02_permissions.sql`, etc.

**Note:** The startup scripts will also be executed after the first time database setup is complete.

The example below mounts the local directory myScripts to `/opt/oracle/myScripts` which is then searched for custom startup scripts:

    docker run --name oracle-ee -p 1521:1521 -v /home/oracle/myScripts:/opt/oracle/scripts/startup -v /home/oracle/oradata:/opt/oracle/oradata oracle/database:19.3.0-ee

## Known issues

* The [`overlay` storage driver](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/) on CentOS has proven to run into Docker bug #25409. We recommend using `btrfs` or `overlay2` instead. For more details see issue #317.

## License

To download and run Oracle Database, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleDatabase](./) repository required to build the container images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright

Copyright (c) 2014,2021 Oracle and/or its affiliates.